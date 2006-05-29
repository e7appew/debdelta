/ deb delta is.*/{p = $4 * 1 ; s = $10 * 1 ;
bucket = int(p / 5) ; count++;
if (p <= 50 ) { cou ++; hist[ bucket ] ++ ;  cumul += p ; savin += s };};
END{ print "# ",int(cou * 100 /count) ,"% of deltas are <=50% of original;"
print "# of those, the average percent is ",int(cumul / cou), "%"
print "# of those, the average saving  is ",int(savin / cou), "kB"
print "# and the histogram is"
for (val in  hist) print val*5,int(100*hist[val]/cou) };
