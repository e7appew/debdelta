#!/bin/sh -e

# this script creates

# Copyright (C) 2006-07 Andrea Mennucci.
# License: GNU General Public License, version 2 or later

#who I am
b=`basename $0`

TMPDIR=/data6/tmp
export TMPDIR

DEBUG=''
VERBOSE=''
[ "$1" = '-v'  ] && { VERBOSE='-v' ; shift ; }
[ "$1" = '-d'  ] && { DEBUG='--debug' ; }

#where to download the full mirror of debian stable security
secdebmir=/data6/mirror/debian-security
#the lock used by debmirror
secdebmirlock=$secdebmir/Archive-Update-in-Progress-`hostname  -f`

#where is the full mirror of debian stable
fulldebmir=/data/mirror/debian
#the name by which "stable" is known in that mirror
stable="etch"

#where to create the repository of deltas
deltamir=/data6/mirror/debian-security-deltas

#where is the debdeltas program
debdeltas=/home/debdev/bin/debdeltas
#options to your taste
debdelta_opt=" -n 3 --delta-algo xdelta "

#do mirror security
trap "rm  $VERBOSE -f $secdebmirlock" 0
~/bin/debmirror.mine $DEBUG $VERBOSE $secdebmir --trash $deltamir/old_debs  \
 --nosource -h security.debian.org \
 -r debian-security -d stable/updates  --arch=i386,amd64

#do create deltas
lockfile -r 1  /tmp/$b.lock || exit 1
trap "rm  $VERBOSE -f /tmp/$b.lock" 0
cd $secdebmir
for p in `find dists -name Packages` ; do
 q=`echo $p | sed "s:/stable/updates/:/$stable/:"`
 $debdeltas $VERBOSE -vd $debdelta_opt  \
  --alt $fulldebmir/$q   --alt $deltamir/old_debs  \
  --dir $deltamir//   $p
done
