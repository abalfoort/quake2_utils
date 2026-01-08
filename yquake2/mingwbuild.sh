#!/bin/bash

GDS='yquake2remaster yquake2 xatrix rogue zaero 3zb2 ctf'

rm -rf build.log release_linux release_linux_remaster
mkdir -p release_linux/baseq2/maps release_linux_remaster/baseq2/maps
touch .zshrc

for GD in $GDS; do
    if [ -d $GD ]; then
        cd $GD
        make clean
        make |&  tee -a ../build_win.log
        echo -e "\n========================================================\n" | tee -a ../build_win.log
        
        mkdir -p ../release_windows/docs/$GD
        mkdir -p ../release_windows_remaster/docs/$GD
        if [ "$GD" == 'yquake2' ]; then
            cp -rvf release/* ../release_windows | tee -a ../build_win.log
            cp -vf ../*.pkz ../release_windows/baseq2/ | tee -a ../build_win.log
            cp -vf stuff/yq2.cfg ../release_windows | tee -a ../build_win.log
            cp -rvf stuff/icon ../release_windows/docs/ | tee -a ../build_win.log
            cp -rvf stuff/mapfixes/baseq2 ../release_windows/baseq2/maps | tee -a ../build_win.log
            cp -vf doc/* ../release_windows/docs/$GD | tee -a ../build_win.log
        elif [ "$GD" == 'yquake2remaster' ]; then
            cp -rvf release/* ../release_windows_remaster | tee -a ../build_win.log
            cp -vf ../*.pkz ../release_windows_remaster/baseq2/ | tee -a ../build_win.log
            cp -vf stuff/yq2.cfg ../release_windows_remaster | tee -a ../build_win.log
            cp -rvf stuff/icon ../release_windows_remaster/docs/ | tee -a ../build_win.log
            cp -rvf stuff/mapfixes/baseq2 ../release_windows_remaster/baseq2/maps | tee -a ../build_win.log
            cp -vf doc/* ../release_windows_remaster/docs/$GD | tee -a ../build_win.log
        else
            mkdir -p ../release_windows/$GD | tee -a ../build_win.log
            cp -rvf release/* ../release_windows/$GD | tee -a ../build_win.log
            cp -rvf stuff/mapfixes ../release_windows/$GD/maps 2>/dev/null | tee -a ../build_win.log
        fi
        
        cp -vf LICENSE ../release_windows/docs/$GD/LICENSE.txt 2>/dev/null | tee -a ../build_win.log
        cp -vf CHANGELOG ../release_windows/docs/$GD/CHANGELOG.txt 2>/dev/null | tee -a ../build_win.log
        cp -vf README* ../release_windows/docs/$GD/README.txt 2>/dev/null | tee -a ../build_win.log
        
        cd ..
    fi
done
