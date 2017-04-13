#!/bin/bash
ROOTDIR=packages
DIR="package"`date +%d%m%Y%H%M%S`
echo $DIR
mkdir $ROOTDIR
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

7z a $DIR.7z ./$ROOTDIR/$DIR/
