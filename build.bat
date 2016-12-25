@echo off
SET MAINFILE=src\jaze.cpp
SET OUTPUT=jaze_win32
SET PDBOUT=jaze_win32
SET LIBRARIES=
SET INCLUDES=..\ht\

SET DEFINES=/DJA_LOGGING

SET DISABLED_WARNINGS=/wd4996

SET DEBUG_DEF=JA_DEBUG
SET RELEASE_DEF=JA_RELEASE

SET LIBS=user32.lib gdi32.lib opengl32.lib

IF NOT EXIST build (
    mkdir build
)
IF NOT EXIST build\debug (
    mkdir build\debug
)
IF NOT EXIST build\release (
    mkdir build\release
)
pushd build

ctime -begin ..\%OUTPUT%.ctm

if "%~1"=="" goto DEBUG_BUILD
if "%~1"=="release" goto RELEASE_BUILD
if "%~1"=="debug" goto DEBUG_BUILD
if "%~1"=="run" goto DEBUG_BUILD

:DEBUG_BUILD

pushd debug

cl ^
	/I ..\..\%INCLUDES% ^
	/Zi ^
	/FC ^
	/W3 ^
	%DISABLED_WARNINGS% ^
	/MP ^
	..\..\%MAINFILE% ^
	%LIBS% ^
	/Fe%OUTPUT% ^
	/Fd%PDBOUT% ^
	/D%DEBUG_DEF% ^
	%DEFINES% ^
	/link ^
	/nologo ^
	/INCREMENTAL:NO

popd

goto END

:RELEASE_BUILD

pushd release

cl ^
	/I ..\..\%INCLUDES% ^
	/W3 ^
	/WX ^
	/MP ^
	/O2 ^
	%DISABLED_WARNINGS% ^
	..\..\%MAINFILE% ^
	%LIBS% ^
	/Fe%OUTPUT% ^
	/Fd%PDBOUT% ^
	/D%RELEASE_DEF% ^
	/D%DEFINES% ^
	/link ^
	/INCREMENTAL:NO ^
	/nologo

del *.obj

popd
	
:END

popd
ctime -end %OUTPUT%.ctm %errorlevel%
echo Build Complete
	