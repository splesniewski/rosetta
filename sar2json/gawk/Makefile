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
small.test.json: sar2json.gawk
	xzcat  ../_data/0306.sar_n_DEV.small.xz \
	| time gawk -f sar2json.gawk \
	| $(cJSONBEAUTIFIER) \
	> $@

full.test.json: sar2json.gawk
	xzcat  ../_data/0306.sar_n_DEV.xz \
	| time gawk -f sar2json.gawk \
	| $(cJSONBEAUTIFIER) \
	> $@
