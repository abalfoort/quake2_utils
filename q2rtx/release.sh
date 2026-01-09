#!/bin/bash

# Edit these
WINDIR='/media/WIN11/Users/arjen/Downloads/q2rtx'
GAMEDIRS='baseq2 rogue xatrix zaero 3zb2 ctf'
SKIPFILES='prefetch toggles clusters'

# Get Q2RTX version
MAJOR=$(grep -Po "Q2RTX_VERSION_MAJOR +\K[0-9]*" src/CMakeLists.txt)
MINOR=$(grep -Po "Q2RTX_VERSION_MINOR +\K[0-9]*" src/CMakeLists.txt)
POINT=$(grep -Po "Q2RTX_VERSION_POINT +\K[0-9]*" src/CMakeLists.txt)

# Create release string
printf -v DATESTR '%(%Y%m%d)T' -1
DEBVERSION=$(grep -oP '^[a-z0-9]+' /etc/debian_version)
DEBRELEASE=Q2RTX_${MAJOR}${MINOR}${POINT}_Deb${DEBVERSION}_${DATESTR}
WINRELEASE=Q2RTX_${MAJOR}${MINOR}${POINT}_Win11_${DATESTR}
MEDIARELEASE=Q2RTX_${MAJOR}${MINOR}${POINT}_Media_${DATESTR}
MEDIAMPSRELEASE=Q2RTX_${MAJOR}${MINOR}${POINT}_Media_MPs_${DATESTR}


if [ ! -d src ]; then
    echo "No src directory found"
    exit 1
fi

if [ ! -d $WINDIR ]; then
    echo "No Windows $WINDIR directory found"
    exit 2
fi

# Init release directory
rm -rf release
for GD in $GAMEDIRS; do
    mkdir -p release/$DEBRELEASE/$GD
    mkdir -p release/$MEDIAMPSRELEASE/$GD
done
mkdir -p release/$MEDIARELEASE
cd release

function copy_file() {
    for F in $1/$2/*.$3; do
        [ ! -e $F ] && continue
        SKIP=false
        FNAME=$(basename $F)
        for S in $SKIPFILES; do
            [[ "$FNAME" == *$S* ]] && SKIP=true; continue
        done
        $SKIP && continue
        cmp -s "$F" "$4/$2/$FNAME"
        [ $? -gt 0 ] || [ ! -e "$Q2DIR/$2/$FNAME" ] && cp -vf $F "$4/$2/"
    done
}

# Debian
for D in $GAMEDIRS; do
    for E in so pkz pak cfg lst txt ico; do

        copy_file ../src $D $E $DEBRELEASE
        copy_file ../q2rtx_media $D $E $MEDIAMPSRELEASE
    done
    cp -rvf ../q2rtx_media/$D/user_guide $MEDIAMPSRELEASE/$D 2>/dev/null
done
mv -vf $MEDIAMPSRELEASE/baseq2 $MEDIARELEASE/
cp -vf ../src/q2rtx $DEBRELEASE/
cp -vf ../src/q2rtxded $DEBRELEASE/
cp -vf ../src/setup/q2rtx.png $DEBRELEASE/
cp -vf ../src/license.txt $DEBRELEASE/
cp -vf ../src/notice.txt $DEBRELEASE/
cp -vf ../src/*.md $DEBRELEASE/
cp -vf ../workingdir/readme_debian.txt $DEBRELEASE/readme

tar -czvf "$DEBRELEASE.tar.gz" "$DEBRELEASE"

# Windows
cp -r $DEBRELEASE $WINRELEASE
for F in $(find $WINRELEASE -type f -name "*.so" -o -name "*.sh"); do rm -vf $F; done
rm -vf $WINRELEASE/q2rtx*
rm -vf $WINRELEASE/readme
for D in $GAMEDIRS; do
    for E in dll; do
        copy_file $WINDIR $D $E $WINRELEASE
    done
done
cp $WINDIR/*.exe $WINRELEASE/
cp -vf ../workingdir/q2rtx.ico $WINRELEASE/
cp -vf ../workingdir/readme_windows.txt $WINRELEASE/readme.txt

zip -r $WINRELEASE.zip $WINRELEASE/*

# Media
zip -r $MEDIARELEASE.zip $MEDIARELEASE/*
zip -r $MEDIAMPSRELEASE.zip $MEDIAMPSRELEASE/*
