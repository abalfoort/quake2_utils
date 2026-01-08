#!/bin/bash

# Bash4: |& = 2>&1

#apt install build-essential libgl1-mesa-dev libsdl2-dev libopenal-dev libcurl4-openssl-dev

while getopts 'fFh' OPT; do
    case $OPT in
        f|F)
            # Force new source
            rm -rf rogue
            rm -rf xatrix
            rm -rf yquake2
            rm -rf yquake2remaster
            rm -rf zaero
            rm -rf ctf
            rm -rf 3zb2
            ;;
        h)
            echo 'Usage: build.sh [options]'
            echo '-f|F: force new download of source and build'
            echo '-h: this help'
            echo
            exit 0
            ;;
    esac
done

GDS='yquake2remaster yquake2 xatrix rogue zaero 3zb2 ctf'

rm -rf build.log release_linux release_linux_remaster
mkdir -p release_linux/baseq2/maps release_linux_remaster/baseq2/maps
touch .zshrc

for GD in $GDS; do
    if [ ! -e $GD ]; then
        git clone https://github.com/abalfoort/$GD.git
    fi
    
    cd $GD
    make clean
    make |& tee -a ../build.log
    echo -e "\n--------------------------------------------------------\n" | tee -a ../build.log
    
    mkdir -p ../release_linux/docs/$GD
    mkdir -p ../release_linux_remaster/docs/$GD
    if [ "$GD" == 'yquake2' ]; then
        cp -rvf release/* ../release_linux | tee -a ../build.log
        cp -vf ../*.pkz ../release_linux/baseq2/ | tee -a ../build.log
        cp -vf stuff/yq2.cfg ../release_linux | tee -a ../build.log
        cp -rvf stuff/icon ../release_linux/docs/ | tee -a ../build.log
        cp -rvf stuff/mapfixes/baseq2 ../release_linux/baseq2/maps | tee -a ../build.log
        cp -vf doc/* ../release_linux/docs/$GD | tee -a ../build.log
    elif [ "$GD" == 'yquake2remaster' ]; then
        cp -rvf release/* ../release_linux_remaster | tee -a ../build.log
        cp -vf ../*.pkz ../release_linux_remaster/baseq2/ | tee -a ../build.log
        cp -vf stuff/yq2.cfg ../release_linux_remaster | tee -a ../build.log
        cp -rvf stuff/icon ../release_linux_remaster/docs/ | tee -a ../build.log
        cp -rvf stuff/mapfixes/baseq2 ../release_linux_remaster/baseq2/maps | tee -a ../build.log
        cp -vf doc/* ../release_linux_remaster/docs/$GD | tee -a ../build.log
    else
        mkdir -p ../release_linux/$GD | tee -a ../build.log
        cp -rvf release/* ../release_linux/$GD | tee -a ../build.log
        cp -rvf stuff/mapfixes ../release_linux/$GD/maps 2>/dev/null | tee -a ../build.log
    fi
    
    cp -vf LICENSE ../release_linux/docs/$GD/LICENSE.txt 2>/dev/null | tee -a ../build.log
    cp -vf CHANGELOG ../release_linux/docs/$GD/CHANGELOG.txt 2>/dev/null | tee -a ../build.log
    cp -vf README* ../release_linux/docs/$GD/README.txt 2>/dev/null | tee -a ../build.log
    
    echo -e "\n========================================================\n" | tee -a ../build.log
    
    cd ..
done
