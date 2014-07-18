#!/usr/bin/python

" debdeltas  publisher "

import os, sys, subprocess, ConfigParser, copy


# -a is -rlptgoD  (no -H,-A,-X)
rsync_base=['rsync', '-ax', '--no-motd', '--timeout=600',  '--contimeout=600']


def publish(rsync_args, basedir, rsync_destination, files=[]):
    """ rsync basedir to a remote destination 
       rsync_args is the list of args 
       files is the list of files , if relative paths, relative to basedir;
         but if no file is given , then publish all, and add --delete to arguments"""
    
    # rsync gives a special meaning to paths ending in '/'
    if basedir[-1] != '/':
        basedir+='/'
    if rsync_destination[-1] != '/':
        rsync_destination+='/'
    
    assert os.path.isdir(basedir) and os.path.isabs(basedir)
    
    if len(files)<1:
        r=subprocess.call(rsync_args + ['--delete', basedir, rsync_destination ], cwd=basedir)
    else:
        args=[]
        l=len(basedir)
        for f in files:
            if os.path.isabs(f):
                assert os.path.isfile(f)
                if f[:l] == basedir:
                    args.append(f[l:])
                else:
                    raise Exception(' cannot publish this file ' +repr(f))
            else:
                assert os.path.isfile(os.path.join(basedir,f))
                args.append(f)
        r=subprocess.call(rsync_args +  ['-R' ] + args + [ rsync_destination ], cwd=basedir)
    return r


if __name__ == '__main__':
    config=ConfigParser.SafeConfigParser()
    assert os.path.isfile(sys.argv[1])
    config.read(sys.argv[1])
    assert config.has_section("'server'")
    assert config.has_section("'publisher'")
    
    home=''
    if config.has_option("'server'",'home'):
        home=eval(config.get("'server'",'home'))
    
    def gets(s):
        return eval(config.get("'server'", s), {'home':home})
    def getp(s):
        return eval(config.get("'publisher'", s), {'home':home})
    
    basedir=gets('deltas_www_dir')
    
    rsync_args=copy.copy(rsync_base)
    
    if  config.has_option("'publisher'", "rsync_password_file"):
        rsync_password_file = getp("rsync_password_file")
        rsync_args += ['--password-file', rsync_password_file]
    
    rsync_destination = getp( "rsync_destination")
    
    args=sys.argv[2:]
    #TODO parse command arguments such as --delete
    
    publish(rsync_args, basedir, rsync_destination, args)
