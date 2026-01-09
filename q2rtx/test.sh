#!/bin/bash

GAMEDIRS='baseq2 rogue xatrix zaero 3zb2 ctf'
PAKDIR='workingdir/_pak'

# Copy needed files for testing
rm -rf test; mkdir -p test/{3zb2,baseq2,ctf,rogue,xatrix,zaero}
cp -vf src/q2rtx test/
cp -vf src/q2rtxded test/
cp -vf {src/3zb2/*.pkz,src/3zb2/*.pak,src/3zb2/*.so} test/3zb2/
cp -vf {src/baseq2/*.pkz,src/baseq2/*.pak,src/baseq2/*.so} test/baseq2/
cp -vf {src/rogue/*.pkz,src/rogue/*.so} test/rogue/
cp -vf {src/xatrix/*.pkz,src/xatrix/*.so} test/xatrix/
cp -vf {src/zaero/*.pkz,src/zaero/*.so} test/zaero/
cp -rvf src/ctf/* test/ctf/

# Copy pak files
for D in $GAMEDIRS; do
    cp -vf $PAKDIR/$D/*.pak test/$D/
done

cd test

echo
echo "Cheat codes:"
echo "god"
echo "give all"
echo "noclip"
echo "notarget"
echo
PS3="Type number to play (7 to quit): "
options=("Q2RTX" "Xatrix" "Rogue" "Zaero" "3ZB2 (~, sv spb 4)" "CTF" "Quit")
select opt in "${options[@]}"
do
    case $opt in
        "Q2RTX")
            ./q2rtx +set cheats 1
            echo
            ;;
        "Xatrix")
            ./q2rtx +set game xatrix +set cheats 1
            echo
            ;;
        "Rogue")
            ./q2rtx +set game rogue +set cheats 1
            echo
            ;;
        "Zaero")
            ./q2rtx +set game zaero +set cheats 1
            echo
            ;;
        "3ZB2 (~, sv spb 4)")
            # Use q2dm5 for testing
            ./q2rtx +set game 3zb2 +gamemap q2dm5 +set cheats 1
            echo
            ;;
        "CTF")
            ./q2rtx +set game ctf +map q2ctf1 +set cheats 1
            echo
            ;;
        "Quit")
            break
            ;;
        *) echo "invalid option $REPLY";;
    esac
done
