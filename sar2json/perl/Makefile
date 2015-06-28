#
#
#
cJSONBEAUTIFIER=cat
cJSONBEAUTIFIER=python -m json.tool
#
FILES=small.test.json full.test.json
all: $(FILES)

clean:
	-rm -f *~
	-rm -f $(FILES)

#................................................................
# OSX/MACPorts: p5-json
# UBUNTU: libjson-perl
#................................................................
small.test.json: sar2json.pl
	xzcat  ../_data/0306.sar_n_DEV.small.xz \
	| time perl sar2json.pl \
	| $(cJSONBEAUTIFIER) \
	> $@

full.test.json: sar2json.pl
	xzcat  ../_data/0306.sar_n_DEV.xz \
	| time perl sar2json.pl \
	| $(cJSONBEAUTIFIER) \
	> $@
