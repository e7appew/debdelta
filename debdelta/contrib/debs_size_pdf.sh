#compute distribution (=integral) of probability of packages sizes in an archive
find pool -type f -name '*deb' | \
 xargs ls -l |\
 awk '{p=$5 * 1; bucket = int(p/1024) ; count++; hist[ bucket ] ++; }\
END{ for (val in  hist) print val,hist[val] }'|\
sort  -n |\
 awk '{b+=$2; print $1, b}'
