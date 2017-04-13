#!/bin/bash
cl.exe -nologo -O2 -MT -TP -c $1
x=$1
libname=${x%%.*}
lib.exe -nologo $libname.obj -out:$libname.lib
rm *.obj