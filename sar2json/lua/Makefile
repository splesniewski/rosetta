#
#
#
cJSONBEAUTIFIER=cat
cJSONBEAUTIFIER=python -m json.tool
#

OS=$(shell uname -s)
cLUA=lua

ifeq ($(OS),Darwin)
# MACPorts lus5.3 w/lua-luajson
	cLUA=/opt/local/bin/lua
endif

FILES=\
	small.test.json full.test.json

all: $(FILES)

clean:
	-rm -f *~
	-rm -f $(FILES)

#................................................................
small.test.json: sar2json.lua
	xzcat  ../_data/0306.sar_n_DEV.small.xz \
	| time $(cLUA) sar2json.lua \
	| $(cJSONBEAUTIFIER) \
	> $@

full.test.json: sar2json.lua
	xzcat  ../_data/0306.sar_n_DEV.xz \
	| time $(cLUA) sar2json.lua \
	| $(cJSONBEAUTIFIER) \
	> $@
