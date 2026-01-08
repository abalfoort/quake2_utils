#!/bin/bash

REMASTER=false
while getopts 'rh' OPT; do
  case $OPT in
    h)
        printf "Options:
-h:    This help
-r:    Play Quake2 Remastered
"
        exit
        ;;
    r)
        # Test Quake2 Remaster
        REMASTER=true
        ;;
  esac
done

# Install SDL3
if [ -z "$(dpkg-query -l libsdl3-0 2>/dev/null | grep ^i)" ]; then sudo apt install libsdl3-0; fi

# Prepare test directory
rm -rf release_linux_test
cp -rf release_linux release_linux_test
$REMASTER && cp -rvf release_linux_remaster/* release_linux_test/
cd release_linux_test

# Copy pak files to test directory
for D in baseq2 xatrix rogue zaero ctf 3zb2; do
    cp -rf ../../q2rtx/workingdir/_pak/$D/*.pak ./$D/
done

cp -rf ../3zb2/misc/* ./3zb2/

echo
echo "Cheat codes:"
echo "god"
echo "give all"
echo "noclip"
echo "notarget"
echo
PS3="Type number to play (7 to quit): "
options=("Quake2" "Xatrix" "Rogue" "Zaero" "3ZB2 (~, sv spb 4)" "CTF" "Quit")
select opt in "${options[@]}"
do
    case $opt in
        "Quake2")
            ./quake2 +set cheats 1
            echo
            ;;
        "Xatrix")
            ./quake2 +set game xatrix +set cheats 1
            echo
            ;;
        "Rogue")
            ./quake2 +set game rogue +set cheats 1
            echo
            ;;
        "Zaero")
            ./quake2 +set game zaero +set cheats 1
            echo
            ;;
        "3ZB2 (~, sv spb 4)")
            ./quake2 +set game 3zb2 +map q2dm1 +set cheats 1
            echo
            ;;
        "CTF")
            ./quake2 +set game ctf +map q2ctf1 +set cheats 1
            echo
            ;;
        "Quit")
            break
            ;;
        *) echo "invalid option $REPLY";;
    esac
done
 
