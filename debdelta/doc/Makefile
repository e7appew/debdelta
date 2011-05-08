all: html/index.html debdelta_suite.pdf

html:
	mkdir html

html/index.html: html debdelta_suite.xml
	docbook2html -o html debdelta_suite.xml

debdelta_suite.pdf: debdelta_suite.xml
	docbook2pdf debdelta_suite.xml

