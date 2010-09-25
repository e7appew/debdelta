#!/bin/sh

unset LANG
unset LC_ALL
unset LC_NUMERIC

if test "$2" = "" -o ! -r "$2"  ; then
 echo Usage  $0  ' dir_or_prefix logs [ logs ] '
 exit 
fi

PREFIX="$1"

shift

t=`tempfile`

#echo ===== working towards $PREFIX

dir=`dirname $0`

zcat "$@" | awk -f $dir/sizes_histogram.awk  > ${PREFIX}sizes.txt

if test -s ${PREFIX}sizes.txt ; then
cat > $t <<EOF
set term png
set out "${PREFIX}sizes.png"
set xlabel "% of patchsize / new deb size"
set ylabel "% of deltas"
plot "${PREFIX}sizes.txt" w steps
EOF
gnuplot < $t
fi


sizes_by_instsize=`tempfile`

zcat "$@" | awk '/^ NEW/{P=$3 ; SI=$9 * 1 ; SZ = $16 * 1 ; N = N + 1 ; };
/^ deb delta is/{if (SI > 1 ) { SZ = $16 * 1; TOTDEBSZ = TOTDEBSZ + SZ ; PC = $4 * 1 ;
  TOTDELTASZ = TOTDELTASZ + ( SZ * PC   ) ;   print SI, " ",  PC,SZ }};
/^ delta is/{if (SI > 1 ) { SZ = $15 * 1; TOTDEBSZ = TOTDEBSZ + SZ ; PC = $3 * 1 ;
  TOTDELTASZ = TOTDELTASZ + ( SZ * PC   ) ;   print SI, " ",  PC,SZ }};
END{printf("# total %d new debs processed, %d KB installed size\n",N,TOTDEBSZ);
if(TOTDEBSZ>0){printf("#size average=%d\n", TOTDELTASZ / TOTDEBSZ );};}'  >  $sizes_by_instsize

sizes_by_instsize_avg=`tail -1 $sizes_by_instsize | cut -d= -f2 `


if grep -q average  $sizes_by_instsize ; then
cat > $t <<EOF
set term png
set out "${PREFIX}sizes_by_size.png"
set ylabel "% of patch size / new deb size"
set xlabel "installed size of new deb (in kB)"
set logscale x 2
set arrow from 1600,${sizes_by_instsize_avg} to 3200,${sizes_by_instsize_avg} nohead  front
set label "avg ${sizes_by_instsize_avg}" at  3200,${sizes_by_instsize_avg} front
set title " (% of patch size / new deb size) by new.deb.size ; average=${sizes_by_instsize_avg}"
plot "$sizes_by_instsize" w points
EOF
gnuplot < $t
fi
###

delta_speeds_by_instsize=`tempfile`

zcat "$@" | awk '/NEW/{P=$3 ; SI=$9 * 1};
/^ deb delta is/{SZ = $16 * 1 ; }
/^ delta is/{SZ = $15 * 1 ; }
/^ delta time/{ if( SI > 1) { N = N+1 ;  TOTSZ = TOTSZ + SZ ; TOTTIM = TOTTIM + $3 ; SP= $6 * 1 ; TSP=TSP+SP ;  print SI, " ", SP }};
#/^Total running time:/{TOTTIM = $4 * 1 }
END{if(TOTTIM>0){printf("#create average=%d\n", TOTSZ / TOTTIM )};}'    >  $delta_speeds_by_instsize 

delta_speeds_by_instsize_avg=`tail -1 $delta_speeds_by_instsize | cut -d= -f2`

patch_speeds_by_instsize=`tempfile`

zcat "$@" | awk '/NEW/{P=$3 ; SI=$9 * 1};
/^ deb delta is/{SZ = $16 * 1 ;}
/^ delta is/{SZ = $15 * 1 ;}
/ Patching done/{ if( SI > 1) {N = N+1 ; TOTSZ = TOTSZ + SZ ;  TOTTIM = TOTTIM + ($4 * 1 ); SP= $6 * 1 ; TSP=TSP+SP ; print SI, " ", SP }};
END{if(TOTTIM>0){printf("#patch average=%d\n", TOTSZ / TOTTIM )} ; }'    >  $patch_speeds_by_instsize

patch_speeds_by_instsize_avg=`tail -1 $patch_speeds_by_instsize | cut -d= -f2`

if grep -q average  $delta_speeds_by_instsize && grep -q average  $patch_speeds_by_instsize ; then
cat > $t <<EOF
set term png
set out "${PREFIX}speeds_by_size.png"
unset arrow
unset label
set ylabel "speed of creating/applying delta \n w.r.t. size of new .deb  (in kB / sec)"
set xlabel "installed size of new deb (in kB)"
set logscale x 2
set yrange [4:16384]
set logscale y 2
set arrow from 1600,${delta_speeds_by_instsize_avg} to 3200,${delta_speeds_by_instsize_avg} nohead front
set label "create avg ${delta_speeds_by_instsize_avg}" at  5000,${delta_speeds_by_instsize_avg} front
set arrow from 1600,${patch_speeds_by_instsize_avg} to 3200,${patch_speeds_by_instsize_avg} nohead  front
set label "patch avg ${patch_speeds_by_instsize_avg}" at 3200,${patch_speeds_by_instsize_avg} front
set title "speed by new.deb.size ; average when patching =${patch_speeds_by_instsize_avg} creating=${delta_speeds_by_instsize_avg}"
plot "$delta_speeds_by_instsize" w points title "create" , "$patch_speeds_by_instsize" w points title "patch" 
quit
EOF

gnuplot < $t
fi

grep -h '#'  $sizes_by_instsize $delta_speeds_by_instsize $patch_speeds_by_instsize >  "${PREFIX}.txt"

rm $t $sizes_by_instsize $delta_speeds_by_instsize $patch_speeds_by_instsize
