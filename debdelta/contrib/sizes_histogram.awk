# this awk program scans the output of 'debdeltas -v' and prints statistics
/ deb delta is.*/{p = $4 * 1 ; s = $9 * 1 ;
bucket = int(p / 5) ; count++;
if (p <= 80 ) { cou ++; hist[ bucket ] ++ ;  cumul += p ; savin += s };};
END{if(cou>0){ print "# ",int(cou * 100 /count) ,"% of deltas are <=80% of original;"
print "# of those, the average percent is ",int(cumul / cou), "%"
print "# of those, the average saving  is ",int(savin / cou), "kB"
print "# and the histogram is"
val=0
while(val<=16) {
 #if (hist[val] > 0 )
 {
  l=int(100*hist[val]/cou) 
  printf("%2d %2d %s\n", val*5, l,substr("-------------------------------------------------------...",1,l) )
 } 
val++
}}
#for (val in  hist) print val*5,int(100*hist[val]/cou) 
};
