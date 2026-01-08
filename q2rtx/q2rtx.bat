@ECHO off

:start
cls
ECHO.
ECHO Cheat codes:
ECHO god
ECHO give all
ECHO noclip
ECHO notarget
ECHO.
ECHO 1. Q2RTX
ECHO 2. Q2RTX Xatrix
ECHO 3. Q2RTX Rogue
ECHO 4. Q2RTX Zaero
ECHO 5. Q2RTX 3ZB2 (~, sv spb 4)
ECHO 6. Q2RTX CTF
ECHO q. Quit
ECHO.

set choice=
set /p choice=Type number to play: 
if not '%choice%'=='' set choice=%choice:~0,1%
if '%choice%'=='1' goto q2rtx
if '%choice%'=='2' goto xatrix
if '%choice%'=='3' goto rogue
if '%choice%'=='4' goto zaero
if '%choice%'=='5' goto 3zb2
if '%choice%'=='6' goto ctf
if '%choice%'=='q' goto end
ECHO "%choice%" is not valid, try again
ECHO.
goto start

:q2rtx
q2rtx\q2rtx.exe +set cheats 1
goto start

:xatrix
q2rtx\q2rtx.exe +set game xatrix +set cheats 1
goto start

:rogue
q2rtx\q2rtx.exe +set game rogue +set cheats 1
goto start

:zaero
q2rtx\q2rtx.exe +set game zaero +set cheats 1
goto start

:3zb2
q2rtx\q2rtx.exe +set game 3zb2 +gamemap q2dm5 +set cheats 1
goto start

:ctf
q2rtx\q2rtx.exe +set game ctf +map q2ctf1 +set cheats 1
goto start

:end
