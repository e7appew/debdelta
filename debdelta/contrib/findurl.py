#!/usr/bin/python

# Copyright (C) 2009 Andrea Mennucci.
# License: GNU Library General Public License, version 2 or later

import os, sys, string, ConfigParser

from string import join

def version_mangle(v):
  if  ':' in v :
    return join(v.split(':'),'%3a')
  else:
    return v

def delta_uri_from_config(config, **dictio):
  secs=config.sections()
  for s in secs:
    opt=config.options(s)
    if 'delta_uri' not in opt:
      print 'Error!! sources.conf section ',s,'does not contain delta_uri'
      raise SystemExit(1)
    match=True
    for a in dictio:
      #damn it, ConfigParser changes everything to lowercase !
      if ( a.lower() in opt ) and ( dictio[a] != config.get( s, a) ) :
        #print '!!',a, repr(dictio[a]) , ' != ',repr(config.get( s, a))
        match=False
        break
    if match:
      return  config.get( s, 'delta_uri' )

############main code
if len( sys.argv) <=1 :
  print "Usage: findurl.py [packages]"
else:
  config=ConfigParser.SafeConfigParser()
  config.read(['/etc/debdelta/sources.conf', os.path.expanduser('~/.debdelta/sources.conf')  ])

  try:
    import  apt_pkg
  except ImportError:
    print 'ERROR!!! python module "apt_pkg" is missing. Please install python-apt'
    raise SystemExit
  
  try:
    import  apt
  except ImportError:
    print 'ERROR!!! python module "apt" is missing. Please install a newer version of python-apt (newer than 0.6.12)'
    raise SystemExit
  
  apt_pkg.init()
  
  cache=apt.Cache()
  #cache.upgrade(True)

  for a in sys.argv[1:]:
    p = cache[a]
    installed_version=p.installed.version
    candidate = p.candidate
    candidate_version=p.candidate.version
    print 'Looking up ',a, ' version ',candidate_version
    for origin in p.candidate.origins:
      arch=candidate.architecture
      if not candidate.uris :
        print 'Sorry, cannot find an URI to download the debian package of ',a
        continue
      deb_uri = candidate.uri
      deb_path=string.split(deb_uri,'/')
      deb_path=string.join(deb_path[(deb_path.index('pool')):],'/')

      print " One of the archives for this package has this info "
      print "  Origin  ",origin.origin
      print "  Archive ",origin.archive
      print "  Label   ",origin.label
      print "  Site    ",origin.site
      #print " Component ",origin.component  is not used below
      #print " Code Name ", is not available in Python APT interface AFAICS

      delta_uri_base=delta_uri_from_config(config,
                                           Origin=origin.origin,
                                             Label=origin.label,
                                             Site=origin.site,
                                             Archive=origin.archive,
                                             PackageName=p.name)

      if delta_uri_base == None:
        print '  Sorry, sources.conf does not provide a server for this archive'
        continue

      if installed_version == candidate_version:
        print '  Sorry, this package is already at its newest version for this archive'
        continue

      #delta name
      delta_name=p.name+'_'+version_mangle(installed_version)+\
                  '_'+ version_mangle(candidate_version)+'_'+\
                  arch+'.debdelta'

      uri=delta_uri_base+'/'+os.path.dirname(deb_path)+'/'+delta_name

      print '  The package ',a,' may be upgraded by using: ', uri
