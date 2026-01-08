@echo off
REM https://deponie.yamagi.org/quake2/windows/buildenv/
REM Extract buildenv next to the yquake2 directory
REM Edit etc\nsswitch.conf > db_home: /c/Users/%U/Downloads/yquake2 cygwin desc
REM Add before "export path" in etc\profile: PKG_CONFIG_PATH="$PKG_CONFIG_PATH:/opt/SDL3/${MINGW_CHOST}/lib/pkgconfig"

SET CURDIR=%~dp0
SET NSSWITCH=%CURDIR%..\buildenv\etc\nsswitch.conf
SET NSSWITCH_SEARCH=db_home
SET NSSWITCH_REPLACE=db_home: /c/Users/%U/Downloads/yquake2 cygwin desc
SET PROFILE=%CURDIR%..\buildenv\etc\profile

>nul find "/yquake2" %NSSWITCH% && (
  echo %NSSWITCH% check: OK.
) || (
    echo %NSSWITCH% check: fix %NSSWITCH_SEARCH%.
  powershell -Command "(Get-Content -Path "^""%NSSWITCH%^"" -Raw) -creplace "^""%NSSWITCH_SEARCH%:*^"", "^""%NSSWITCH_REPLACE%^"" | Set-Content -Path "^""%NSSWITCH%.out^"" -Encoding UTF8"
)

>nul find "/opt/SDL3" %PROFILE% && (
    echo %PROFILE% check: OK.
) || (
    echo %PROFILE% check: add PKG_CONFIG_PATH="$PKG_CONFIG_PATH:/opt/SDL3/${MINGW_CHOST}/lib/pkgconfig"
    for /f "usebackq delims="  %%a in ("%PROFILE%") do (
        if "%%~a"=="export PATH" >>"%PROFILE%" echo(PKG_CONFIG_PATH="$PKG_CONFIG_PATH:/opt/SDL3/${MINGW_CHOST}/lib/pkgconfig"
        >>"%PROFILE%.out" echo(%%a
    )
)

REM if not exist .zshrc copy NUL .zshrc
start %CURDIR%..\buildenv\mingw64 ./mingwbuild.sh
copy /Y %CURDIR%..\buildenv\opt\SDL3\x86_64-w64-mingw32\bin\SDL3.dll %CURDIR%\release_windows\
