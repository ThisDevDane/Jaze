@echo off
call "C:\Program Files (x86)\Microsoft Visual Studio\2017\Community\VC\Auxiliary\Build\vcvars64.bat" >nul
IF NOT EXIST build (
    mkdir build
)

otime -begin jaze.otm
odin build src\main.odin
set ERRORLEV=%errorlevel%
IF %ERRORLEVEL% EQU 0  (
    move /Y src\*.exe .\build >nul
    echo Build Success
	del src\*.ll >nul
	del src\*.bc >nul
	del src\*.obj >nul
    goto END
)

echo Build Failed

:END
otime -end jaze.otm %ERRORLEV%