/^OLD/{P=$3 ; OV= $5; };
/^NEW/{P=$3 ; NV= $5; Z=$0};
/delta time.*bsdiff/{  bt= $10 * 1 ; dt = $3 * 1 ;  
 if ( dt > 1  ) { C = C + bt / dt ;  N= N + 1 ; if( bt < 0.4 * dt ) { print 100 * $10 / $3 , P, OV, NV, "'"  $0 "'" } }}
END{print "average", 100*C/N }
