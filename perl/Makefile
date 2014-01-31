#
#
#
all: perl.ray.png

clean:
	-rm -f *~ tmon.out make.log
	-rm -f perl.ray.png perl.ray.pgm 

perl.ray.pgm: ray.pl Makefile
	time perl ray.pl > $@
	openssl md5 $@

################################################################
%.png: %.pgm
	pnmtopng $< > $@

################################################################
cPERLCRITIC=\
	/opt/local/bin/perlcritic-5.12 \
	-brutal \
	-exclude CodeLayout::ProhibitParensWithBuiltins \
	-exclude CodeLayout::ProhibitHardTabs \
	-exclude InputOutput::ProhibitBacktickOperators \
	-exclude NamingConventions::ProhibitMixedCaseVars \
	-exclude NamingConventions::ProhibitMixedCaseSubs

.PHONY: critic
critic:
	$(cPERLCRITIC) ray.pl
