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

delta=`realpath $1`
olddeb=`realpath $2`
newdeb="$3"



TD=${TMPDIR:-/tmp}/debpatch$$
mkdir $TD

pushd $TD > /dev/null

ln -s '/usr/lib/debdelta/minigzip' '/usr/lib/debdelta/minibzip2' .

mkdir OLD OLD/CONTROL OLD/DATA NEW NEW/CONTROL NEW/DATA PATCH

ar p $olddeb control.tar.gz  | tar -x -z -p -f - -C OLD/CONTROL

if ar t $olddeb | grep -q data.tar.bz2 ; then
 ar p $olddeb data.tar.bz2  | tar -x --bzip2 -p -f - -C OLD/DATA
else
 ar p $olddeb data.tar.gz  | tar -x -z -p -f - -C OLD/DATA
fi


cd PATCH
ar x "$delta"
cd $TD

if test -r  PATCH/patch.sh.gz  ; then
 gunzip PATCH/patch.sh.gz
elif test -r  PATCH/patch.sh.bz2  ; then
 bunzip2 PATCH/patch.sh.bz2
fi

sh -e PATCH/patch.sh

#note that we do not check MD5 in this simple script..

popd > /dev/null

mv -vb $TD/NEW.file "$newdeb"

#eventually,
#rm -r "$TD"
