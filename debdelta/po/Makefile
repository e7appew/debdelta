PO_FILES := $(wildcard *.po)
MO_FILES := $(patsubst %.po,%.mo,$(PO_FILES))
LANGS := $(patsubst %.po,%,$(PO_FILES))

all : messages.pot $(MO_FILES)

messages.pot: ../debdelta Makefile
	xgettext -L Python -d debdelta --from-code=UTF-8 -o messages.pot ../debdelta
	for L in $(LANGS) ; do \
		msgmerge --previous -o $$L~new~.po $$L.po messages.pot ; \
		if ! diff -q  $$L~new~.po $$L.po ; then mv $$L~new~.po  $$L.po ; echo Please edit $$L.po ; else rm  $$L~new~.po ; echo No significant changes ; fi ; done

.po.mo :
	msgfmt -c -o ~~$@~~ $< && mv ~~$@~~ $@

.SUFFIXES: .po .mo

#lib/po/messages.pot : Makefile lib/EElection/*py  lib/EElection/plugins/*py lib/EBallotbox/*py
#        xgettext -o lib/po/messages.pot lib/EElection/*py  lib/EElection/plugins/*py lib/EBallotbox/*py
#        cd lib/po && msgmerge -o itnew.po it.po messages.pot
#        @if ! diff -q  lib/po/itnew.po  lib/po/it.po ; then mv  lib/po/itnew.po  lib/po/it.po ; echo Please edit lib/po/it.po ; else rm    lib/po/itnew.po ; echo No changes ; fi 


#lib/locale/it/LC_MESSAGES/e-election.mo : lib/po/it.po
#        msgfmt -o lib/locale/it/LC_MESSAGES/e-election.mo~~ --statistics lib/po/it.po && mv  lib/locale/it/LC_MESSAGES/e-election.mo~~  lib/locale/it/LC_MESSAGES/e-election.mo
