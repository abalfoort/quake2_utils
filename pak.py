#!/usr/bin/env python3
"""PAK utility: create, list, and unpack Quake .pak files.

Usage examples:
    python3 pak.py -p mypak.pak ./subdir
    python3 pak.py -u mypak.pak ./outdir
    python3 pak.py -l mypak.pak
    python3 pak.py -l mypak.pak -v    # show invalid-byte positions

Behavior:
- Inputs must be subdirectories of the current working directory and are walked recursively.
- The script always uses the current working directory as the root.
- Each input subdirectory prefix is automatically stripped from stored names.
- When creating a pak file, names are ASCII-encoded; names longer than 56 bytes cause an error.
- When listing or unpacking, names are decoded as UTF-8 with replacement for invalid sequences.
- When listing or unpacking, invalid UTF-8 byte positions in names are reported if -v/--verbose is used.

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

NAME_SIZE = 56

def collect_inputs(inputs, root):
    """Return list of (fullpath, input_rel_dir) for all files under each input directory.

    'root' is expected to be the current working directory.
    Each returned tuple includes the absolute file path and the input dir path
    relative to 'root' (used as the strip-prefix).
    """
    files = []
    for inp in inputs:
        # Input is a subdirectory of current dir; interpret relative to root
        full_dir = inp if os.path.isabs(inp) else os.path.join(root, inp)
        if not os.path.exists(full_dir):
            print(f"Error: path not found: {full_dir}", file=sys.stderr)
            sys.exit(1)
        if not os.path.isdir(full_dir):
            print(f"Error: '{inp}' is not a directory; "
                   "inputs must be subdirectories of the current directory", file=sys.stderr)
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

    This performs a byte-level scan of 'b' and identifies the start
    indices of invalid UTF-8 sequences according to UTF-8 encoding rules.
    """
    positions = []
    i = 0
    n = len(b)
    while i < n:
        byte = b[i]
        # 0x00..0x7F: ASCII
        if byte <= 0x7F:
            i += 1
            continue
        # 2-byte sequence (U+0080..U+07FF)
        if 0xC2 <= byte <= 0xDF:
            if i + 1 < n and 0x80 <= b[i+1] <= 0xBF:
                i += 2
                continue
            positions.append(i)
            i += 1
            continue
        # 3-byte sequence
        if 0xE0 <= byte <= 0xEF:
            if i + 2 < n:
                b1, b2 = b[i+1], b[i+2]
                # overlong/UTF-16 surrogate checks
                if byte == 0xE0 and not 0xA0 <= b1 <= 0xBF:
                    positions.append(i)
                    i += 1
                    continue
                if byte == 0xED and not 0x80 <= b1 <= 0x9F:
                    positions.append(i)
                    i += 1
                    continue
                if 0x80 <= b1 <= 0xBF and 0x80 <= b2 <= 0xBF:
                    i += 3
                    continue
            positions.append(i)
            i += 1
            continue
        # 4-byte sequence
        if 0xF0 <= byte <= 0xF4:
            if i + 3 < n:
                b1, b2, b3 = b[i+1], b[i+2], b[i+3]
                if byte == 0xF0 and not 0x90 <= b1 <= 0xBF:
                    positions.append(i)
                    i += 1
                    continue
                if byte == 0xF4 and not 0x80 <= b1 <= 0x8F:
                    positions.append(i)
                    i += 1
                    continue
                if (0x80 <= b1 <= 0xBF and 0x80 <= b2 <= 0xBF and 0x80 <= b3 <= 0xBF):
                    i += 4
                    continue
            positions.append(i)
            i += 1
            continue
        # anything else is invalid
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


def unpak(pak_path, out_dir, verbose=False):
    """Unpack the contents of 'pak_path' into 'out_dir'."""
    entries = list_pak(pak_path)
    os.makedirs(out_dir, exist_ok=True)
    with open(pak_path, 'rb') as fh:
        for name, off, sz, invalid_positions in entries:
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
    print("Create a pak:\n  python3 pak.py -p PAK INPUT_SUBDIR [INPUT_SUBDIR ...]\n"
          "  example: python3 pak.py -p mypak.pak id1")
    print()
    print("List pak contents:\n  python3 pak.py -l PAK\n"
          "  example: python3 pak.py -l mypak.pak")
    print()
    print("Unpack pak:\n  python3 pak.py -u PAK OUT_DIR\n"
          "  example: python3 pak.py -u mypak.pak ./outdir")
    print()
    print("Verbose flag: -v/--verbose shows invalid-byte positions and per-file messages")
    print()
    print("Short flags: -p == --pak, -l == --list, -u == --unpak, -h == --help, -v == --verbose")


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
                       nargs=1,
                       dest='list',
                       help='List contents: --list PAK')
    group.add_argument('-u', '--unpak',
                       nargs=2,
                       dest='unpak',
                       help='Unpack contents: --unpak PAK OUT_DIR')
    p.add_argument('-v', '--verbose',
                   action='store_true',
                   dest='verbose',
                   help='Show extra information (invalid-byte positions, per-file messages)')
    args = p.parse_args()

    if args.helpflag:
        print_help()
        return

    try:
        if args.pak:
            pak = args.pak[0]
            inputs = args.pak[1:]
            if not inputs:
                p.error('When using -p/--pak you must provide an output pak'
                        ' and at least one input subdirectory')
            create_pak(pak, inputs, verbose=args.verbose)
            print(f"Created pak: {os.path.abspath(pak)}")
        elif args.list:
            pak = args.list[0]
            entries = list_pak(pak)
            for name, _off, _sz, invalid_positions in entries:
                if invalid_positions and args.verbose:
                    print(f"{name}  (invalid UTF-8 at positions: "
                          f"{','.join(map(str, invalid_positions))})")
                else:
                    print(name)
        elif args.unpak:
            pak, outdir = args.unpak
            unpak(pak, outdir, verbose=args.verbose)
            print(f"Extracted pak to: {os.path.abspath(outdir)}")
        else:
            # no mode provided
            print_help()
    except (OSError, ValueError, struct.error) as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)

if __name__ == '__main__':
    main()
