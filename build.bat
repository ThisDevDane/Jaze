@echo off
call "C:\Program Files (x86)\Microsoft Visual Studio 14.0\VC\vcvarsall.bat" x64
IF NOT EXIST build (
    mkdir build
)

otime -begin jaze.otm
odin build src\main.odin
set ERRORLEV=%errorlevel%
IF %ERRORLEVEL% EQU 0  (
    move /Y src\*.exe .\build >nul
    echo Build Success
    goto END
)

echo Build Failed

:END
del src\*.ll >nul
del src\*.bc >nul
del src\*.obj >nul
otime -end jaze.otm %ERRORLEV%