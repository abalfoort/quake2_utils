#!/bin/bash

# Bash4: |& = 2>&1
# Pass branch to build specific branch.
# Default build: current branch

cd src
[ -n "$1" ] && git switch $1
echo
echo "Build branch: $(git rev-parse --abbrev-ref HEAD)" | tee ../build.log
echo
sleep 5

mkdir -p build
cd build
rm -r *
cmake .. |& tee -a ../../build.log
cmake --build . |& tee -a ../../build.log

echo
echo -e "\nCreate shaders.pkz file\n" | tee -a ../../build.log
cd ../baseq2
zip -9 -FSr "shaders.pkz" shader_vkpt |& tee -a ../../build.log

cd ../../q2rtx_media
./media.sh

echo
echo -e "\nList .so files (check date and time)\n" | tee -a ../build.log
find ../src -name "*.so" -exec ls -al {} \; |& tee -a ../build.log

xdg-open ../build.log
