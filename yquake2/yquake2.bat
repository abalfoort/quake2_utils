@ECHO off

REM Prepare test directory
rmdir /s /q release_windows_test
mkdir release_windows_test
xcopy release_windows release_windows_test /E /H /C /R /Q /Y

:parse
IF "%~1"=="" GOTO endparse
IF "%~1"=="-h" ECHO -f: Start Quake2 Remaster
IF "%~1"=="-f" xcopy release_windows_remaster release_windows_test /E /H /C /R /Q /Y
SHIFT
GOTO parse
:endparse
dir
cd release_windows_test

REM Copy pak files to test directory
for %%D in (baseq2, xatrix, rogue, zaero, ctf, 3zb2) do (
    copy /Y ..\..\q2rtx\%%D\*.pak %%D\
)

:start
cls
ECHO.
ECHO 1. Quake2
ECHO 2. Quake2 Xatrix
ECHO 3. Quake2 Rogue
ECHO 4. Quake2 Zaero
ECHO 5. Quake2 3zb2 (~, sv spb 4)
ECHO 6. Quake2 CTF
ECHO q. Quit
ECHO.

set choice=
set /p choice=Type number to play: 
if not '%choice%'=='' set choice=%choice:~0,1%
if '%choice%'=='1' goto quake2
if '%choice%'=='2' goto xatrix
if '%choice%'=='3' goto rogue
if '%choice%'=='4' goto zaero
if '%choice%'=='5' goto 3zb2
if '%choice%'=='6' goto ctf
if '%choice%'=='q' goto end
ECHO "%choice%" is not valid, try again
ECHO.
goto start

:quake2
yquake2.exe +set cheats 1
goto start

:xatrix
yquake2.exe +set game xatrix +set cheats 1
goto start

:rogue
yquake2.exe +set game rogue +set cheats 1
goto start

:zaero
yquake2.exe +set game zaero +set cheats 1
goto start

:3zb2
yquake2.exe +set game 3zb2 +map q2dm1 +set deathmatch 1 +set cheats 1
goto start

:ctf
yquake2.exe +set game ctf +map q2ctf1 +set cheats 1
goto start

:end
