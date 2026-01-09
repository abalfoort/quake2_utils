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

cd ../3zb2
echo -e "\nCreate 3zb2/q2rtx_media.pkz file\n" | tee -a ../../build.log
zip -9 -FSr "q2rtx_media.pkz" * -x *.{pkz,pak,so} -x "user_guide/*" |& tee -a ../../build.log

cd ../baseq2
echo -e "\nCreate baseq2/shaders.pkz file\n" | tee -a ../../build.log
zip -9 -FSr "shaders.pkz" shader_vkpt |& tee -a ../../build.log
echo -e "\nCreate baseq2/q2rtx_media.pkz file\n" | tee -a ../../build.log
zip -9 -FSr "q2rtx_media.pkz" * -x *.{pkz,pak,so} -x "shader_vkpt/*" |& tee -a ../../build.log

cd ../rogue
echo -e "\nCreate rogue/q2rtx_media.pkz file\n" | tee -a ../../build.log
zip -9 -FSr "q2rtx_media.pkz" * -x *.{pkz,pak,so} |& tee -a ../../build.log

cd ../xatrix
echo -e "\nCreate xatrix/q2rtx_media.pkz file\n" | tee -a ../../build.log
zip -9 -FSr "q2rtx_media.pkz" * -x *.{pkz,pak,so} |& tee -a ../../build.log

cd ../zaero
echo -e "\nCreate zaero/q2rtx_media.pkz file\n" | tee -a ../../build.log
zip -9 -FSr "q2rtx_media.pkz" * -x *.{pkz,pak,so} |& tee -a ../../build.log
echo

cd ..
echo -e "\nList .so files (check date and time)\n" | tee -a ../build.log
find . -name "*.so" -exec ls -al {} \; |& tee -a ../build.log

xdg-open ../build.log
