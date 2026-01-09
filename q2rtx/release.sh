#!/bin/bash

# Edit these
WINDIR='/media/WIN11/Users/arjen/Downloads/q2rtx'

# Get Q2RTX version
MAJOR=$(grep -Po "Q2RTX_VERSION_MAJOR +\K[0-9]*" src/CMakeLists.txt)
MINOR=$(grep -Po "Q2RTX_VERSION_MINOR +\K[0-9]*" src/CMakeLists.txt)
POINT=$(grep -Po "Q2RTX_VERSION_POINT +\K[0-9]*" src/CMakeLists.txt)

# Create release string
printf -v DATESTR '%(%Y%m%d)T' -1
DEBVERSION=$(grep -oP '^[a-z0-9]+' /etc/debian_version)
DEBRELEASE=Q2RTX_${MAJOR}${MINOR}${POINT}_Deb${DEBVERSION}_${DATESTR}
WINRELEASE=Q2RTX_${MAJOR}${MINOR}${POINT}_Win11_${DATESTR}

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
mkdir -p release/$DEBRELEASE/{3zb2,baseq2,ctf,rogue,xatrix,zaero}
cd release

# Copy files
cp -vf ../src/q2rtx $DEBRELEASE/
cp -vf ../src/q2rtxded $DEBRELEASE/
cp -vf ../src/setup/q2rtx.png $DEBRELEASE/
cp -vf ../src/license.txt $DEBRELEASE/
cp -vf ../src/notice.txt $DEBRELEASE/
cp -vf ../src/*.md $DEBRELEASE/
cp -vf ../workingdir/readme_debian.txt $DEBRELEASE/readme

cp -vf {../src/3zb2/*.pkz,../src/3zb2/*.pak,../src/3zb2/*.so} $DEBRELEASE/3zb2/
cp -vf {../src/baseq2/*.pkz,../src/baseq2/*.pak,../src/baseq2/*.so,../src/baseq2/q2rtx.cfg} $DEBRELEASE/baseq2/
cp -vf {../src/rogue/*.pkz,../src/rogue/*.so} $DEBRELEASE/rogue/
cp -vf {../src/xatrix/*.pkz,../src/xatrix/*.so} $DEBRELEASE/xatrix/
cp -vf {../src/zaero/*.pkz,../src/zaero/*.so} $DEBRELEASE/zaero/
cp -vf ../src/3zb2/*.{cfg,txt,lst} $DEBRELEASE/3zb2/
cp -rvf ../src/3zb2/user_guide $DEBRELEASE/3zb2/
cp -rvf ../src/ctf $DEBRELEASE/

# Create tar
echo -e "\nCreate $DEBRELEASE.tar.gz\n"
tar -czvf "$DEBRELEASE.tar.gz" "$DEBRELEASE"

# Windows
# Copy from debian release
cp -r $DEBRELEASE $WINRELEASE

# Remove linux stuff
for F in $(find $WINRELEASE -type f -name "*.so" -o -name "*.sh"); do rm -vf $F; done
rm -vf $WINRELEASE/q2rtx*
rm -vf $WINRELEASE/readme

# Copy dlls
cp -vf $WINDIR/3zb2/*.dll $WINRELEASE/3zb2/
cp -vf $WINDIR/ctf/*.dll $WINRELEASE/ctf/
cp -vf $WINDIR/baseq2/*.dll $WINRELEASE/baseq2/
cp -vf $WINDIR/rogue/*.dll $WINRELEASE/rogue/
cp -vf $WINDIR/xatrix/*.dll $WINRELEASE/xatrix/
cp -vf $WINDIR/zaero/*.dll $WINRELEASE/zaero/
# Exe and other stuff
cp $WINDIR/*.exe $WINRELEASE/
cp -vf ../workingdir/q2rtx.ico $WINRELEASE/
cp -vf ../workingdir/readme_windows.txt $WINRELEASE/readme.txt

# Create zip
echo -e "\nCreate $WINRELEASE.zip.tar.gz\n"
zip -9 -FSr $WINRELEASE.zip $WINRELEASE/*
