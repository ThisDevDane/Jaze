#!/bin/bash
ROOTDIR=packages
DIR="package"`date +%d`"-"`date +%m`"-"`date +%Y`"_"`date +%H%M`

if [ ! -d $ROOTDIR ]; then
    mkdir $ROOTDIR
fi
mkdir $ROOTDIR/$DIR

pushd run_tree
for i in $(ls); do
	cp -r $i ../$ROOTDIR/$DIR
done
popd

pushd build
for i in $(ls); do
	cp -r $i ../$ROOTDIR/$DIR
done
popd

7z a ./$ROOTDIR/$DIR.7z ./$ROOTDIR/$DIR/
rm -rf ./$ROOTDIR/$DIR/
rm *.7z
cp ./$ROOTDIR/$DIR.7z .
