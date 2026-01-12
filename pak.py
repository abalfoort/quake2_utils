#!/usr/bin/env python3
"""PAK utility: create, list, and unpack Quake .pak files.

Usage examples:
        # Create a pak from a directory
        python3 pak.py -p mypak.pak ./subdir

        # List pak(s) (filter supports glob or regex)
        python3 pak.py -l mypak.pak
        python3 pak.py -l "*.pak" -f "*.bsp"

        # Unpack one or more pak files into OUT_DIR. To avoid ambiguity with
        # the `-u` argument's positional values, pass `-f` before `-u`:
        python3 pak.py -f "*.bsp" -u "*.pak" outdir

Behavior:
- Inputs for `-p/--pak` are subdirectories (walked recursively) or file/glob
    patterns; the current working directory is used as the root for stored
    names and for pattern expansion.
- `-l/--list` accepts one or more pak file paths or glob patterns.
- `-u/--unpak` accepts one or more pak file paths or glob patterns followed by
    an output directory: `-u PAK [PAK ...] OUT_DIR`.
- The `-f/--filter` option restricts which pak-internal file names are
    displayed or extracted; it accepts a regex or a glob pattern (e.g. "*.bsp").
- Each input subdirectory prefix is automatically stripped from stored names.
- When creating a pak file, names are ASCII-encoded; names longer than 56
    bytes cause an error.
- When listing or unpacking, names are decoded as UTF-8 with replacement for
    invalid sequences. Invalid UTF-8 byte positions in stored names are shown
    when `-v/--verbose` is used.

- Short flags:
    -p == --pak
    -l == --list
    -u == --unpak
    -h == --help
    -v == --verbose
"""
import os
import struct
import argparse
import sys
import glob
import re
import fnmatch

NAME_SIZE = 56

def collect_inputs(inputs, root):
    """Return list of (fullpath, input_rel_dir) for all files under each input directory.

    'root' is expected to be the current working directory.
    Each returned tuple includes the absolute file path and the input dir path
    relative to 'root' (used as the strip-prefix).

    This function also accepts glob patterns (e.g. "*.pak") and individual file
    paths. If an input expands to a file, that file is returned with its
    containing directory used as the strip-prefix. If a pattern matches zero
    paths the function exits with an error.
    """
    files = []
    for inp in inputs:
        # If the input contains glob characters, expand relative to root
        pattern = inp
        if not os.path.isabs(pattern):
            pattern = os.path.join(root, pattern)
        matches = glob.glob(pattern)
        # If no glob characters matched anything, treat the literal path
        if not matches:
            matches = [pattern]

        for match in matches:
            full_dir = match
            if not os.path.exists(full_dir):
                print(f"Error: path not found: {full_dir}", file=sys.stderr)
                sys.exit(1)
            # If match is a file, use its directory as the strip-prefix and
            # add the file itself to the list. If it's a directory, walk it.
            if os.path.isfile(full_dir):
                input_rel = os.path.relpath(os.path.dirname(full_dir), root).replace(os.sep, '/')
                files.append((os.path.join(os.path.dirname(full_dir),
                                           os.path.basename(full_dir)),
                                           input_rel))
            else:
                if not os.path.isdir(full_dir):
                    print(f"Error: '{inp}' is not a directory; "
                           "inputs must be subdirectories of the current directory",
                           file=sys.stderr)
                    sys.exit(1)
                # compute input directory path relative to root, using forward slashes
                input_rel = os.path.relpath(full_dir, root).replace(os.sep, '/')
                for dirpath, _, filenames in os.walk(full_dir):
                    for fn in filenames:
                        files.append((os.path.join(dirpath, fn), input_rel))
    # dedupe and preserve deterministic order
    uniq = []
    seen = set()
    for full, inp_rel in sorted(files, key=lambda t: (t[1], t[0])):
        if (full, inp_rel) not in seen:
            uniq.append((full, inp_rel))
            seen.add((full, inp_rel))
    return uniq

def make_pak_name(fullpath, root, strip_prefix):
    """Return the pak-internal name for 'fullpath'.
    
    fullpath is relative to 'root', with 'strip_prefix' removed if present."""
    # Compute a pak-internal path relative to root and strip the input dir prefix
    rel = os.path.relpath(fullpath, root).replace(os.sep, '/')
    # strip the input directory prefix
    if strip_prefix:
        if rel.startswith(strip_prefix):
            rel = rel[len(strip_prefix):]
            if rel.startswith('/'):
                rel = rel[1:]
    if rel.startswith('/'):
        rel = rel[1:]
    return rel


def utf8_invalid_positions(b: bytes):
    """Return a list of byte indices where invalid UTF-8 sequences start.

    The function scans the input bytes one byte at a time and attempts to
    validate UTF-8 encoded code points. When it encounters a start byte that
    cannot begin a valid UTF-8 sequence (or the following continuation
    bytes are missing or invalid), it records the index of that start byte.

    The checks follow UTF-8 encoding rules:
    - ASCII bytes (0x00..0x7F) are single-byte code points.
    - 2-byte sequences start with bytes 0xC2..0xDF and must be followed by
      a single continuation byte in range 0x80..0xBF.
      Note: 0xC0 and 0xC1 are disallowed because they would create overlong
      encodings for ASCII.
    - 3-byte sequences start with 0xE0..0xEF and must be followed by two
      continuation bytes. Additional checks prevent overlong encodings and
      UTF-16 surrogate halves:
        * If the first byte is 0xE0, the next byte must be 0xA0..0xBF to avoid
          encoding values that could have been encoded with fewer bytes
          (overlong sequences).
        * If the first byte is 0xED, the next byte must be 0x80..0x9F to avoid
          encoding UTF-16 surrogate range (U+D800..U+DFFF), which is invalid
          in UTF-8.
    - 4-byte sequences start with 0xF0..0xF4 and require three continuation
      bytes. Additional range checks on the second byte prevent overlong
      encodings and values beyond U+10FFFF:
        * If the first byte is 0xF0, the second byte must be 0x90..0xBF.
        * If the first byte is 0xF4, the second byte must be 0x80..0x8F.

    For any start byte that does not match a valid header range or when the
    required continuation bytes are absent or out of range, the index of the
    start byte is appended to the returned list.
    """
    positions = []
    i = 0
    n = len(b)
    while i < n:
        byte = b[i]
        # ASCII: single-byte 0x00..0x7F
        if byte <= 0x7F:
            i += 1
            continue
        # 2-byte sequence header: 0xC2..0xDF (0xC0 and 0xC1 are invalid)
        # Valid encoding form: [0xC2..0xDF] [0x80..0xBF]
        if 0xC2 <= byte <= 0xDF:
            if i + 1 < n and 0x80 <= b[i+1] <= 0xBF:
                i += 2
                continue
            # Missing or invalid continuation byte
            positions.append(i)
            i += 1
            continue
        # 3-byte sequence header: 0xE0..0xEF
        # Valid encoding form: [0xE0..0xEF] [cont1] [cont2]
        if 0xE0 <= byte <= 0xEF:
            if i + 2 < n:
                b1, b2 = b[i+1], b[i+2]
                # If header == 0xE0, cont1 must be >= 0xA0 to avoid overlong
                if byte == 0xE0 and not 0xA0 <= b1 <= 0xBF:
                    positions.append(i)
                    i += 1
                    continue
                # If header == 0xED, cont1 must be <= 0x9F to avoid UTF-16
                # surrogate halves (U+D800..U+DFFF) encoded in UTF-8.
                if byte == 0xED and not 0x80 <= b1 <= 0x9F:
                    positions.append(i)
                    i += 1
                    continue
                # General case: both continuation bytes must be 0x80..0xBF
                if 0x80 <= b1 <= 0xBF and 0x80 <= b2 <= 0xBF:
                    i += 3
                    continue
            # Either not enough bytes remain or continuation bytes invalid
            positions.append(i)
            i += 1
            continue
        # 4-byte sequence header: 0xF0..0xF4
        # Valid encoding form: [0xF0..0xF4] [cont1] [cont2] [cont3]
        if 0xF0 <= byte <= 0xF4:
            if i + 3 < n:
                b1, b2, b3 = b[i+1], b[i+2], b[i+3]
                # If header == 0xF0, cont1 must be >= 0x90 to avoid overlong
                if byte == 0xF0 and not 0x90 <= b1 <= 0xBF:
                    positions.append(i)
                    i += 1
                    continue
                # If header == 0xF4, cont1 must be <= 0x8F to stay <= U+10FFFF
                if byte == 0xF4 and not 0x80 <= b1 <= 0x8F:
                    positions.append(i)
                    i += 1
                    continue
                # All three continuation bytes must be 0x80..0xBF
                if (0x80 <= b1 <= 0xBF and 0x80 <= b2 <= 0xBF and 0x80 <= b3 <= 0xBF):
                    i += 4
                    continue
            # Missing or invalid continuation bytes for 4-byte sequence
            positions.append(i)
            i += 1
            continue
        # Any other leading byte value is not valid UTF-8
        positions.append(i)
        i += 1
    return positions

def create_pak(pak_path, input_paths, root=None, verbose=False):
    """Create a PAK file at 'pak_path' from files under 'input_paths'."""
    # root is always the current working directory
    if root is None:
        root = os.path.abspath('.')
    files = collect_inputs(input_paths, root)

    entries = []
    with open(pak_path, 'wb') as out:
        out.write(b'PACK')
        out.write(struct.pack('<II', 0, 0))

        for full, inp_rel in files:
            with open(full, 'rb') as f:
                data = f.read()
            offset = out.tell()
            out.write(data)
            pak_name = make_pak_name(full, root, strip_prefix=inp_rel)
            if not pak_name:
                print(f"Error: empty pak name for source file: {full}", file=sys.stderr)
                sys.exit(1)
            entries.append((pak_name, offset, len(data)))
            if verbose:
                print(f"Packed: {pak_name}")

        # sort entries by name for deterministic output
        entries.sort(key=lambda e: e[0])

        dir_offset = out.tell()
        for name, offset, size in entries:
            nb = name.encode('ascii')
            if len(nb) > NAME_SIZE:
                print(f"Error: name too long for PAK (max {NAME_SIZE}): {name}", file=sys.stderr)
                sys.exit(1)
            nb_padded = nb + b'\x00' * (NAME_SIZE - len(nb))
            out.write(nb_padded)
            out.write(struct.pack('<II', offset, size))
        dir_length = out.tell() - dir_offset

        out.seek(4)
        out.write(struct.pack('<II', dir_offset, dir_length))


def list_pak(pak_path):
    """Return list of (name, offset, size) entries in the pak."""
    entries = []
    with open(pak_path, 'rb') as fh:
        hdr = fh.read(12)
        if len(hdr) < 12 or hdr[:4] != b'PACK':
            print('Error: not a valid PAK file', file=sys.stderr)
            sys.exit(1)
        dir_offset, dir_len = struct.unpack('<II', hdr[4:12])
        fh.seek(dir_offset)
        end = dir_offset + dir_len
        while fh.tell() < end:
            raw = fh.read(NAME_SIZE)
            # stop at the first NUL byte to avoid embedded NULs in decoded names
            if b'\x00' in raw:
                raw = raw.split(b'\x00', 1)[0]
            off, sz = struct.unpack('<II', fh.read(8))
            # decode using UTF-8 with replacement for display
            name = raw.decode('utf-8', errors='replace')
            # compute invalid UTF-8 byte positions for reporting
            invalid_positions = utf8_invalid_positions(raw)
            entries.append((name, off, sz, invalid_positions))
    return entries


def unpak(pak_path, out_dir, verbose=False, filter_re=None):
    """Unpack the contents of 'pak_path' into 'out_dir'.

    If `filter_re` is provided, only entries whose pak-internal name
    matches the regex will be extracted.
    """
    entries = list_pak(pak_path)
    os.makedirs(out_dir, exist_ok=True)
    with open(pak_path, 'rb') as fh:
        for name, off, sz, invalid_positions in entries:
            if filter_re and not filter_re.search(name):
                continue
            target = os.path.join(out_dir, name)
            target_dir = os.path.dirname(target)
            if target_dir:
                os.makedirs(target_dir, exist_ok=True)
            fh.seek(off)
            data = fh.read(sz)
            with open(target, 'wb') as outf:
                outf.write(data)
            # report per-file decoding/invalid-byte info only when verbose
            if verbose:
                if invalid_positions:
                    print(f"Extracted: {target}"
                           "(invalid UTF-8 at positions: {','.join(map(str, invalid_positions))})")
                else:
                    print(f"Extracted: {target}")


def print_help():
    """Print usage help."""
    print("PAK utility — usage:\n")
    print("Create a pak:\n  python3 pak.py -p PAK INPUT_SUBDIR|FILE|GLOB [INPUT_SUBDIR|...]\n"
        "  example: python3 pak.py -p mypak.pak id1")
    print()
    print("List pak contents:\n  python3 pak.py -l PAK|GLOB [PAK ...]\n"
        "  example: python3 pak.py -l \"*.pak\"\n"
        "  example (with filter): python3 pak.py -l \"*.pak\" -f \"*.bsp\"")
    print()
    print("Unpack pak:\n  python3 pak.py -u PAK|GLOB [PAK ...] OUT_DIR\n"
        "  example: python3 pak.py -u \"*.pak\" other.pak ./outdir\n"
        "  example (use filter before -u to avoid ambiguity): python3 pak.py -f \"*.bsp\" -u \"*.pak\" outdir")
    print()
    print("Verbose flag: -v/--verbose shows invalid-byte positions and per-file messages")
    print("Filter flag: -f/--filter restricts listed/unpacked entries by regex or glob")
    print()
    print("Short flags: -p == --pak, -l == --list, -u == --unpak, -h == --help, -v == --verbose, -f == --filter")


def main():
    """Main entry point for the PAK utility."""
    p = argparse.ArgumentParser(description='PAK utility: create/list/unpack Quake .pak files',
                                add_help=False)
    # custom help flag
    p.add_argument('-help', '-h',
                   action='store_true',
                   dest='helpflag',
                   help='Show this help and exit')
    group = p.add_mutually_exclusive_group(required=False)
    group.add_argument('-p', '--pak',
                       nargs='+',
                       dest='pak',
                       help='Create a pak. Usage: --pak PAK INPUT_SUBDIR [INPUT_SUBDIR ...]')
    group.add_argument('-l', '--list',
                       nargs='+',
                       dest='list',
                       help='List contents: --list PAK [PAK ...]')
    group.add_argument('-u', '--unpak',
                       nargs='+',
                       dest='unpak',
                       help='Unpack contents: --unpak PAK [PAK ...] OUT_DIR')
    p.add_argument('-v', '--verbose',
                   action='store_true',
                   dest='verbose',
                   help='Show extra information (invalid-byte positions, per-file messages)')
    p.add_argument('-f', '--filter',
                   dest='filter',
                   help='Regex or glob to filter listed pak entries (e.g. "\\.bsp$" or "*.bsp")')
    args = p.parse_args()

    if args.helpflag:
        print_help()
        return

    try:
        # Prepare filter regex (supports glob-style patterns too)
        filter_re = None
        if args.filter:
            if any(c in args.filter for c in '*?['):
                filter_re = re.compile(fnmatch.translate(args.filter))
            else:
                filter_re = re.compile(args.filter)

        if args.pak:
            pak = args.pak[0]
            inputs = args.pak[1:]
            if not inputs:
                p.error('When using -p/--pak you must provide an output pak'
                        ' and at least one input subdirectory')
            create_pak(pak, inputs, verbose=args.verbose)
            print(f"Created pak: {os.path.abspath(pak)}")
        elif args.list:
            seen = set()
            for pattern in args.list:
                matches = glob.glob(pattern)
                if not matches:
                    matches = [pattern]
                for pakfile in matches:
                    if pakfile in seen:
                        continue
                    seen.add(pakfile)
                    # Print header when user provided multiple patterns or
                    # the pattern expanded to multiple files (wildcard use).
                    show_header = (len(args.list) > 1 or len(matches) > 1 or
                                   any(c in pattern for c in '*?['))
                    if show_header:
                        print(f"\n> Listing: {pakfile}")
                    entries = list_pak(pakfile)
                    for name, _off, _sz, invalid_positions in entries:
                        if filter_re and not filter_re.search(name):
                            continue
                        if invalid_positions and args.verbose:
                            print(f"{name}  (invalid UTF-8 at positions: "
                                  f"{','.join(map(str, invalid_positions))})")
                        else:
                            print(name)
        elif args.unpak:
            # last argument is the output directory, preceding args are pak patterns
            if len(args.unpak) < 2:
                p.error('When using -u/--unpak you must provide at least one pak and an output directory')
            pak_patterns = args.unpak[:-1]
            outdir = args.unpak[-1]
            seen = set()
            for pattern in pak_patterns:
                matches = glob.glob(pattern)
                if not matches:
                    matches = [pattern]
                for pakfile in matches:
                    if pakfile in seen:
                        continue
                    seen.add(pakfile)
                    # Print which pak is being unpacked when patterns/wildcards used
                    show_header = (len(pak_patterns) > 1 or len(matches) > 1 or
                                   any(c in pattern for c in '*?['))
                    if show_header:
                        print(f"Unpacking: {pakfile} -> {outdir}")
                    unpak(pakfile, outdir, verbose=args.verbose, filter_re=filter_re)
            print(f"Extracted pak to: {os.path.abspath(outdir)}")
        else:
            # no mode provided
            print_help()
    except (OSError, ValueError, struct.error) as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)

if __name__ == '__main__':
    main()
