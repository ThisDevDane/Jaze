#!/bin/bash
OTM=jaze.otm
SRC=src/main.odin

build_success(){
	mv -f ./src/*.exe ./build
	echo Build Success
	otime.exe -end $OTM $ERR
}

build_failed(){
	echo Build Failed
	otime.exe -end $OTM $ERR
}

if [ ! -d "build" ]; then
	mkdir build
fi
otime.exe -begin $OTM
echo Compiling with opt=$1...
odin.exe build $SRC -opt=$1 -collection=mantle=../odin-mantle
ERR=$?
if [ $ERR -eq 0 ]; then
	build_success
else
	build_failed
fi