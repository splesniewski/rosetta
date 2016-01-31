#
#
#
cJSONBEAUTIFIER=cat
cJSONBEAUTIFIER=python -m json.tool
#

OS=$(shell uname -s)
cNODEJS=node

ifeq ($(OS),Darwin)
	cNODEJS=/opt/local/bin/node
endif

FILES=\
	small.test.json full.test.json

all: $(FILES)

clean:
	-rm -f *~
	-rm -f $(FILES)

#................................................................
small.test.json: sar2json.js
	xzcat  ../_data/0306.sar_n_DEV.small.xz \
	| time $(cNODEJS) sar2json.js \
	| $(cJSONBEAUTIFIER) \
	> $@

full.test.json: sar2json.js
	xzcat  ../_data/0306.sar_n_DEV.xz \
	| time $(cNODEJS) sar2json.js \
	| $(cJSONBEAUTIFIER) \
	> $@
