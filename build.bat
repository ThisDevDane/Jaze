@echo off
setlocal
set OTM=jaze.otm
set SRC=src/main.odin

if not exist "build" ( mkdir build )

otime.exe -begin %OTM%
echo Compiling with opt=%1...
odin build %SRC% -opt=%1 -collection=mantle=../odin-mantle
set ERR=%ERRORLEVEL%

if %ERR%==0 ( goto :build_success ) else ( goto :build_failed )

:build_success
    mv -f ./src/*.exe ./build 2> nul
    mv -f ./src/*.pdb ./build 2> nul
    echo Build Success
    otime -end %OTM% %ERR%
exit

:build_failed
    echo Build Failed
    otime -end %OTM% %ERR%
exit