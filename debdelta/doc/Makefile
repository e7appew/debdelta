# Use last changelog date as our PDF document creation and modification date.
DOC_DATE := D:$(subst :,',$(shell date -d "$(shell dpkg-parsechangelog -l ../debian/changelog -S Date)" +%Y%m%d%H%M%S%:z))'

all: html/index.html debdelta_suite.pdf

html:
	mkdir html

html/index.html: html debdelta_suite.xml
	rm -f html/*.html
	docbook2html -o html debdelta_suite.xml

debdelta_suite.pdf: debdelta_suite.xml
	docbook2pdf debdelta_suite.xml
	# Since dh_strip_nondeterminism doesn't handle PDF files, we need to
	# use some hacks, so that we can perform reproducible builds. We can't
	# have different PDF IDs, each time the document is generated, so we
	# force the use of PDF IDs from a template file instead.
	pdftk A=template.pdf B=$@ cat B output $@.~ keep_first_id
	# We also need to fudge the creation and modification dates for reproducibility.
	pdftk $@ dump_data | sed -e "/^InfoKey:.*Date$$/,+1s/^\(InfoValue:\).*$$/\1 $(DOC_DATE)/" | pdftk $@.~ update_info - output $@.~~
	mv -f $@.~~ $@
	rm -f $@.~

