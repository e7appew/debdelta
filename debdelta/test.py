
import os,sys, select, fcntl



class DebDeltaError:
  def __init__(self,s):
    self.__str = s
  def __str__(self):
    return self.__str
def die(s=None):
  if s : sys.stderr.write(s+'\n')
  raise DebDeltaError,s

try:
    die('ciao')
except  DebDeltaError,s:
    print type(s)
    print ' Creation of delta failed, reason:',str(s)
sys.exit(2)


def g(t):
    a=t
    while 1:
        a+=t
        yield a
        print b

gen=g(1)

print gen.next()
print gen.next()
print gen.next()
print gen.next()

sys.exit(2)

import os,sys, select, fcntl

( hi, ho , he) = os.popen3( 'date ; /usr/games/rot13','b',24)

print ' pipe ',repr(( hi, ho , he))

#for f in (sys.stdin,sys.stdout,sys.stderr):
#    flags = fcntl.fcntl (ho.fileno(), fcntl.F_GETFL, 0)
#    flags = flags | os.O_NONBLOCK
#    fcntl.fcntl (ho.fileno(), fcntl.F_SETFL, flags)
   
import thread

def copyin():
    while 1:
        #print ' o'
        s=os.read(ho.fileno(),1)
        #s=ho.readline()
        if s == '':
            thread.interrupt_main(   )
        os.write(1,s)
        #sys.stdout.write(s)
        #sys.stdout.flush()
        
        
def copyerr():
    while 1:
        #print ' e '
        #s=he.readline()
        s=os.read(he.fileno(),1)
        if s == '':
            thread.interrupt_main(   )
        os.write(2,s)
        #sys.stderr.write(s)        
        #sys.stderr.flush()
        
def copyout():
    while 1:
        s=os.read(0,20)
        #sys.stdin.readline()
        if s == '':
            thread.interrupt_main()
        os.write(hi.fileno(),(s))
        #hi.flush()


tin=thread.start_new_thread(copyin,())
tout=thread.start_new_thread(copyout,())
#terr=thread.start_new_thread(
copyerr()

sys.exit(0)

lenin=0
lenout=0

buf=''
while 1:
    if buf:
        o=[hi]
    else:
        o=[]
    print ' selecting ',repr(o),repr(buf)
    ( i, o , e) = select.select( [sys.stdin,ho,he],o,[], 1.0)
    print ' selecta! ',repr(( i, o , e))
    for f in i:      
        s=f.read(20)
        if f == ho:
            print 'o ',lenin,lenout,repr(s)
        elif f == sys.stdin :
            print 'stdin '+repr(s)
            buf+=s
            lenin+=len(s)
        elif f == he :
            print 'e '+repr(s)
        else:
            print 'i! ',repr(f)
    for f in o:
        if f == hi:
            hi.write(buf)
            lenout+=len(buf)
            buf=''
        else:
            print 'o! ',repr(f)
    if e:
        print 'e! ',repr(e)

sys.exit(0)
      
print 'I',ho.read()


j=100000

l=open('/tmp/log','a')


    #'/usr/lib/apt/methods/'('/bin/sed','-n','l')
while 1:
    ( i, o , e) = select.select( [ho,he], [hi], [], 2.0)
    #print ' selecta! ',repr(( i, o , e))
    for f in i:
       s=f.read(20)
       if f == ho:
           print 'o '+str(j)+repr(s)
       elif f == he :
           print 'e '+repr(s)
       else:
           print 'I ',repr(f)
    for f in o:
        if j>0:
            f.write('c\n')
            j-=1



    
if 0:
  import thread
  ( hi, ho , he) = os.popen3( ('/usr/lib/apt/methods/http.distrib',))

  for f in (ho,hi,he,sys.stdin,sys.stdout,sys.stderr):
    flags = fcntl.fcntl (ho.fileno(), fcntl.F_GETFL, 0)
    flags = flags | os.O_NONBLOCK
    fcntl.fcntl (ho.fileno(), fcntl.F_SETFL, flags)

  def copyin():
    c
  
  

if 0:

  ret=os.system('/usr/lib/apt/methods/http.distrib')

  #ret=os.system('script -a -c /usr/lib/apt/methods/http.distrib /tmp/log2 ')
  sys.exit(ret)
  
  log=open('/tmp/log','a')
  log.write('  --- here we go\n')
  import select, fcntl
  ( hi, ho , he) = os.popen3( ('/usr/lib/apt/methods/http.distrib',))

  for f in (ho,hi,he,sys.stdin,sys.stdout,sys.stderr):
    flags = fcntl.fcntl (ho.fileno(), fcntl.F_GETFL, 0)
    flags = flags | os.O_NONBLOCK
    fcntl.fcntl (ho.fileno(), fcntl.F_SETFL, flags)

  



if 0:
  bufin=''
  bufout=''
  buferr=''
  lenin=0
  lenout=0
  while 1:
    o=[ ]
    if bufout:
      o.append(sys.stdout)
    if buferr:
      o.append(sys.stderr)
    if bufin:
      o.append(hi)
    #print ' selecting ',repr(o),repr(buf)
    ( i, o , e) = select.select( [sys.stdin,ho,he],o,[], 1.0)
    log.write(' selecta! %s\n' % repr(( i, o , e)))
    for f in i:
      try:
        s=f.read()
      except KeyboardInterrupt:
        s=-1
      if s != -1:
        if f == ho:
          log.write( 'o %d %s\n' % (lenout,repr(s)))
          bufout+=s
          lenout+=len(s)
        elif f == sys.stdin :
          log.write( 'i %d %s\n' % (lenin,repr(s)))
          bufin+=s
          lenin+=len(s)
        elif f == he :
          log.write( 'e %s\n'+repr(s))
          buferr += s
        else: raise
    for f in o:
        if f == hi:
          l=hi.write(bufin)
          lenout-=len(bufin)
          bufin=''
          hi.flush()
        elif f == sys.stdout:
          l=sys.stdout.write(bufout[0])
          lenout-=1
          bufout=bufout[1:]
          sys.stdout.flush()
        elif f == sys.stderr:          
          l=sys.stderr.write(buferr)
          buferr=''
          sys.stderr.flush()
        else: raise
    log.flush()
    

