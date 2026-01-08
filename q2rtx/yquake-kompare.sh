#!/bin/bash

GAMEDIRS='rogue xatrix zaero 3zb2 ctf'
[ -n "$1" ] && GAMEDIRS=$1

echo
echo "GAMEDIRS=$GAMEDIRS"
echo
echo "Skip:"
echo "  CMakeLists.txt"
echo "  Flare code"
echo
read -p "Press Enter to start" </dev/tty

QPATH=${PWD%/*}

for D in $GAMEDIRS; do
    kompare ${QPATH}/yquake2/$D/src/ ${QPATH}/q2rtx/src/src/$D/
done
