#!/bin/sh -e

# Copyright (C) 2008 Andrea Mennucci.
# License: GNU Library General Public License, version 2 or later

# this small script is capable of applying a deb delta,
# it basically summarizes what "debpatch" does


if test "$3" = "" ; then
 echo Provide 3 arguments:  patchin  fromfile  tofile
 exit
fi

if test "$2" = / ; then
 echo Sorry, for this simple script you really need the old deb 
 exit 1
fi

case "$1" in 
    /*) delta="$1" ;;
    *) delta=`pwd`/"$1" ;;
esac
olddeb="$2"
newdeb="$3"

TD=${TMPDIR:-/tmp}/debpatch$$
mkdir $TD $TD/OLD $TD/OLD/CONTROL $TD/OLD/DATA $TD/NEW $TD/NEW/CONTROL $TD/NEW/DATA $TD/PATCH

ln -s '/usr/lib/debdelta/minigzip' '/usr/lib/debdelta/minibzip2' $TD/

ar p $olddeb control.tar.gz  | tar -x -z -p -f - -C $TD/OLD/CONTROL

if ar t $olddeb | grep -q data.tar.lzma ; then
 ar p $olddeb data.tar.lzma  | unlzma -c | tar -x -p -f - -C $TD/OLD/DATA
elif ar t $olddeb | grep -q data.tar.bz2 ; then
 ar p $olddeb data.tar.bz2  | tar -x --bzip2 -p -f - -C $TD/OLD/DATA
else
 ar p $olddeb data.tar.gz  | tar -x -z -p -f - -C $TD/OLD/DATA
fi

pushd $TD > /dev/null

cd PATCH
ar x "$delta"
cd $TD

if test -r  PATCH/patch.sh.lzma  ; then
 unlzma PATCH/patch.sh.lzma
elif test -r  PATCH/patch.sh.gz  ; then
 gunzip PATCH/patch.sh.gz
elif test -r  PATCH/patch.sh.bz2  ; then
 bunzip2 PATCH/patch.sh.bz2
fi

#dash will not work, see bug 379227
bash -e PATCH/patch.sh

#note that we do not check MD5 in this simple script..

popd > /dev/null

mv -vb $TD/NEW.file "$newdeb"

#eventually,
#rm -r "$TD"
