@echo off
REM https://cmake.org/download/
REM https://vulkan.lunarg.com/sdk/home#windows
REM https://sourceforge.net/projects/gnuwin32/

git config --global --add safe.directory C:/Users/arjen/Downloads/q2rtx

del /F /Q build.log
rmdir /S /Q q2rtx\build
mkdir q2rtx\build
cd q2rtx\build
cmake -S .. -B . | "C:\Program Files (x86)\GnuWin32\bin\tee.exe" ..\..\build.log
cmake --build . | "C:\Program Files (x86)\GnuWin32\bin\tee.exe" -a ..\..\build.log
cd ..\..
build.log
