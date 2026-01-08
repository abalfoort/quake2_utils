#!/bin/bash

GAMEDIRS='rogue xatrix zaero 3zb2 ctf'

echo
echo "Ctrl-PgDwn = next file"
echo
echo "Skip:"
echo "  CMakeLists.txt"
echo "  Flare code"
echo
read -p "Press Enter to start" </dev/tty

QPATH=${PWD%/*}

for D in $GAMEDIRS; do
    kompare ${QPATH}/q2rtx/src/src/$D/ ${QPATH}/yquake2/$D/src/
done
