#!/bin/bash

Q2DIR='/home/shared/Games/q2rtx'
GAMEDIRS='baseq2 rogue xatrix zaero 3zb2 ctf'
SKIPFILES='prefetch toggles clusters'

function copy_file() {
    for F in $1/$2/*.$3; do
        [ ! -e $F ] && continue
        SKIP=false
        FNAME=$(basename $F)
        for S in $SKIPFILES; do
            [[ "$FNAME" == *$S* ]] && SKIP=true; continue
        done
        $SKIP && continue
        cmp -s "$F" "$Q2DIR/$2/$FNAME"
        [ $? -eq 1 ] || [ ! -e "$Q2DIR/$2/$FNAME" ] && cp -vf $F "$Q2DIR/$2/"
    done
}

cmp -s src/q2rtx "$Q2DIR/q2rtx"
[ $? -eq 1 ] && cp -vf src/q2rtx $Q2DIR
cmp -s src/q2rtxded "$Q2DIR/q2rtxded"
[ $? -eq 1 ] && cp -vf src/q2rtxded $Q2DIR

for D in $GAMEDIRS; do
    for E in so pkz pak cfg lst txt ico; do
        copy_file src $D $E
        if [ "$D" == "baseq2" ] && [ "$E" == pak ]; then continue; fi
        copy_file q2rtx_media $D $E
    done
done

cd $Q2DIR

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
 
