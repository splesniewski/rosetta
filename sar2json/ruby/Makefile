#
#
#
cJSONBEAUTIFIER=cat
cJSONBEAUTIFIER=python -m json.tool
#

OS=$(shell uname -s)
cRUBY=ruby

ifeq ($(OS),Darwin)
	cRUBY=/opt/local/bin/ruby2.3
endif

FILES=\
	small.test.json full.test.json

all: $(FILES)

clean:
	-rm -f *~
	-rm -f $(FILES)

#................................................................
small.test.json: sar2json.rb
	xzcat  ../_data/0306.sar_n_DEV.small.xz \
	| time $(cRUBY) sar2json.rb \
	| $(cJSONBEAUTIFIER) \
	> $@

full.test.json: sar2json.rb
	xzcat  ../_data/0306.sar_n_DEV.xz \
	| time $(cRUBY) sar2json.rb \
	| $(cJSONBEAUTIFIER) \
	> $@
