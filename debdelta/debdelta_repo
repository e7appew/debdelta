#!/usr/bin/python
"""
debdelta_repo

Copyright (c) 2011 A. Mennucci
License: GNU GPL v2 

"""


#TODO this scheleton does not handle 'security', where some old versions of the packages are in
#  a different DISTTOKEN

import sys , os , tempfile , string ,getopt , tarfile , shutil , time, traceback, stat, pwd, grp

from stat    import ST_SIZE, ST_MTIME, ST_MODE, ST_INO, ST_DEV, S_IMODE, S_IRUSR, S_IWUSR, S_IXUSR 
from os.path import abspath
from copy    import copy
from types import IntType, StringType, FunctionType, TupleType, ListType, DictType, BufferType

from apt import VersionCompare

__help__usage__ = "Usage: debdelta_repo [OPTION]... "
__help__options__={
    "verbose":"-v   --verbose\n       be verbose, print more informations",
    "workspace":"-W WORKSPACE\n      directory were all the work is done",
    "debrepo":"-D DEBREPO\n      directory of the repository of debs",
}
    #-R 
   #--release RELEASE   
      #is the Debian Release file,
#-d   --debug
#      print debugging info (not really useful but for the program author)


__help__ = {
    None : __help__usage__ +"""[COMMAND] [ARGS]..\n
 [command]  may be one of --create --add --sos --deltas \n
Use -h [command] for further help on commands""",
    'create' : __help__usage__ +"""--create [ARGS]\n
Creates the sqlite database SQL DB that is used to store packages' info.""",
    'add' : __help__usage__ +"""--add name version arch filename disttoken
or alternatively
  --add --stdin  
that reads from stdin lines with the above five arguments, tab separated

    it stores in the database the fact that name,version,arch has entered disttoken,
    and the package file is at filename (if nonabsolute, -D is used)""",
    'sos' : __help__usage__ +"""--sos filename
   saves the filename somewhere""",
    'deltas' : __help__usage__ +"""
   create all deltas""",
}


def help(cmd=None):
    if cmd and cmd[:2] == '--': cmd = cmd[2:]
    sys.stderr.write(__help__.get(cmd," UNKNOWN COMMAND ") + "\n")
    if cmd:
        sys.stderr.write("\nOptions:\n  " +string.join( __help__options__.values(),"\n  ")+"\n")



try:
    from pysqlite2 import dbapi2 as dbapi
except ImportError:
    dbapi = None

if dbapi != None:
    # ===== sqlite machinery
    def convert_blob(s):
        return s #this is always a string

    # Register the adapter
    #sqlite.register_adapter(StringType, adapt_blob)

    # Register the converter
    dbapi.register_converter("blob", convert_blob)
    dbapi.register_converter("text", convert_blob)


sql_scheme="""
create table package ( 
id integer unique primary key autoincrement,
name text,
version text,
arch text,
filename text,
ownfile boolean,
ctime integer
) ;
create table dist ( 
id integer unique primary key autoincrement,
disttoken text,
package_id integer,
generated boolean,
ctime integer
) ;
CREATE INDEX IF NOT EXISTS package_name ON package ( name );
CREATE INDEX IF NOT EXISTS package_name_arch ON package ( name,arch );
CREATE INDEX IF NOT EXISTS package_filename ON package ( filename );
CREATE INDEX IF NOT EXISTS dist_package_id ON dist ( package_id );
"""

class theSQLdb:
    dbname=None
    sql_connection=None
    sql_cursor=None

    def __init__(self,dbname):
        assert type(dbname) == StringType
        assert os.path.exists(dbname)
        self.dbname=dbname
        self.sql_connection = dbapi.connect(dbname,
                                            detect_types=dbapi.PARSE_DECLTYPES | dbapi.PARSE_COLNAMES)
        self.sql_cursor = self.sql_connection.cursor()

    def __del__(self):
        self.sql_connection.close()

    def commit(self):
        self.sql_connection.commit()

    def add_one(self,name,version,arch,filename,disttoken,generated=0,ownfile=0,ctime=None):
        if ctime==None: ctime=int(time.time())
        self.sql_cursor.execute('SELECT name,version,arch,id FROM package WHERE filename = ? ',\
                                (filename,))
        tp=self.sql_cursor.fetchone()
        if tp:
            if ( tp[0] != name or tp[1] != version or tp[2] != arch):
                sys.stderr.write('Filename already in package database as: %s\n' % repr(tp))
                return
            tpid=tp[3]
        else:
            self.sql_cursor.execute('INSERT INTO package VALUES (null, ?, ?, ?, ?, ?, ?)',\
                                    (name,version,arch,filename,ownfile,ctime))
            tpid=self.sql_cursor.lastrowid
        z=self.sql_cursor.fetchone()
        if z:
            sys.stderr.write('Warning two entries with same filename?\n')
        self.sql_cursor.execute('SELECT id FROM dist WHERE package_id = ? AND disttoken = ? ', (tpid,disttoken))
        td=self.sql_cursor.fetchone()
        if td:
            sys.stderr.write('Package,version,arch already in dist database for this disttoken\n')
            #FIXME we may have added a package and no dist? 
            return
        self.sql_cursor.execute('INSERT INTO dist VALUES (null, ?, ?, ?, ?)',\
                            (disttoken,tpid,generated,ctime))
    
    def package_versions(self,name,disttoken,arch=None,generated=None):
        "returns a list of id,name,arch,version"
        sql_cursor1 = self.sql_connection.cursor()
        sql_cursor2 = self.sql_connection.cursor()
        if generated==None:
            sql_cursor1.execute('SELECT package_id FROM dist WHERE disttoken = ? ',(disttoken,))
        elif generated:
            sql_cursor1.execute('SELECT package_id FROM dist WHERE disttoken = ? AND generate = 1',(disttoken,))
        else:
            sql_cursor1.execute('SELECT package_id FROM dist WHERE disttoken = ? AND generate = 0',(disttoken,))
        z=[]
        for a in sql_cursor1:
            if arch:
                sql_cursor2.execute('SELECT id,name,arch,version FROM package WHERE id = ? AND arch = ?',\
                                         (a[0],arch))
            else:
                sql_cursor2.execute('SELECT id,name,arch,version FROM package WHERE id = ?',(a[0]))
            a=sql_cursor2.fetchall()
            z=z+a
        return z
        
    def create_deltas(self):
        namearchtokens=[]
        sql_cursor1 = self.sql_connection.cursor()
        sql_cursor2 = self.sql_connection.cursor()
        sql_cursor1.execute('SELECT package_id,disttoken FROM dist WHERE generated = 0 ')
        for n in sql_cursor1:
            #TODO use joins
            sql_cursor2.execute('SELECT name,arch FROM package WHERE id = ? ',(n[0],))
            for z in sql_cursor2:
                a=list(z)+[n[1]] #name,arch,disttoken
                if a not in namearchtokens:
                    namearchtokens.append(a)
        for n in namearchtokens:
            versions=self.package_versions(n[0],n[2],n[1])
            #TODO this is a very good place to delete extra, very old versions
            if len(versions) == 1:
                print 'Only one version for ',n,versions
            else:
                print ' Creating deltas for ',n
                def _cmp_(a,b): 
                    return VersionCompare(a[3],b[3])
                versions.sort(cmp=_cmp_)
                new=versions.pop()
                for a in versions:
                    print '  Create delta from ',a[3],' to ',new[3]
        #TODO mark all above as 'generated=1' when done, if successful


def create(dbname):
    if os.path.exists(dbname):
        sys.stderr.write(sys.argv[0]+': will not overwrite already existing '+dbname+'\n')
        sys.exit(1)
    os.popen("sqlite3 '"+dbname+"'",'w').write(sql_scheme)

def add(dbname, argv, stdin=None):
    H=theSQLdb(dbname)
    if stdin:
        for a in sys.stdin:
            if not a or a[0] == '#' :
                continue
            b=string.split(a,'\t')
            if len(b) == 5:
                H.add_one(*b)
            else: sys.stderr.write('It is not a tab separated list of 5 elements: %s\n'%repr(a))
    else:
        if len(argv) == 5:
            H.add_one(*argv)
        else: sys.stderr.write('It was not given 5 arguments: %s\n'%repr(argv))
    H.commit()

def deltas(dbname):
    H=theSQLdb(dbname)
    H.create_deltas()

def sos(dbname, workspace, argv):
    H=theSQLdb(dbname)
    if len(argv) != 1:
        sys.stderr.write('It was not given 1 arguments: %s\n'%repr(argv))
        sys.exit(1)
    H.sql_cursor.execute('SELECT id,name,version,arch FROM package WHERE filename = ? ',argv)
    a=H.sql_cursor.fetchone()
    if not a:
        sys.stderr.write('Filename not found: %s\n'%repr(argv))
        return
    print 'WILL SAVE',a,'SOMEWHERE INSIDE',workspace,' AND UPDATE SQL ACCORDINGLY'
    #in particular, will mark it as 'owned', so it will be deleted when it will be old

if __name__ == '__main__':
    #argv = debugging_argv or sys.argv
    if len(sys.argv) <= 1:
        help()
        raise SystemExit(0)
    DEBUG = 0
    VERBOSE = 0
    JUSTHELP=False
    WORKSPACE=None
    STDIN=False
    cmd=None
    try: 
        ( opts, argv ) = getopt.getopt(sys.argv[1:], 'hvdW:' ,
                                       ('help','debug','verbose','workspace=','add','stdin','sos','create','deltas') )
    except getopt.GetoptError,a:
        sys.stderr.write(sys.argv[0] +': '+ str(a)+'\n')
        raise SystemExit(2)
    for  o , v  in  opts :
        if o == '-v' or o == '--verbose' :
            VERBOSE += 1
        elif o == '-d' or o == '--debug' : 
            DEBUG += 1
        elif o ==  '--help' or o ==  '-h': 
            JUSTHELP = True
        elif o == '-W' or o == '--workspace':
            WORKSPACE=v
        elif o == '--stdin':
            STDIN=True
        elif o[:2] == '--' and o[2:] in __help__.keys():
            if cmd :
                sys.stderr.write(' option ',o,'is unacceptable after',cmd)
                raise SystemExit(1)
            else:
                cmd=o[2:]
        else:
            sys.stderr.write(' option '+o+'is unknown, try --help')
            raise SystemExit(1)

    if JUSTHELP:
        help(cmd)
        raise SystemExit(0)
    
    if not WORKSPACE:
        sys.stderr.write('Need a workspace. Use -W  . Read --help .\n')
        raise SystemExit(1)
    dbname=os.path.join(WORKSPACE,'theSQLdb')
    if cmd == "create":
        create(dbname)
    elif cmd == 'add':
        add(dbname,argv,STDIN)
    elif cmd == 'sos':
        sos(dbname,WORKSPACE,argv)
    elif cmd == 'deltas':
        deltas(dbname)
    else:
        sys.stderr.write("Sorry this command is yet unimplemented: "+cmd+'\n')
        sys.exit(1)
