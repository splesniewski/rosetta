#
#
#
cJSONBEAUTIFIER=cat
cJSONBEAUTIFIER=python -m json.tool
#

OS=$(shell uname -s)
cPYTHON2=python
cPYPY=pypy

ifeq ($(OS),Darwin)
	cPYTHON2=/opt/local/bin/python2.7
	cPYPY=/opt/local/bin/pypy
endif

FILES=\
	small.test.json full.test.json \
	pypy.small.test.json pypy.full.test.json

all: $(FILES)

clean:
	-rm -f *~
	-rm -f $(FILES)

#................................................................
small.test.json: sar2json.py
	xzcat  ../_data/0306.sar_n_DEV.small.xz \
	| time $(cPYTHON2) sar2json.py \
	| $(cJSONBEAUTIFIER) \
	> $@

full.test.json: sar2json.py
	xzcat  ../_data/0306.sar_n_DEV.xz \
	| time $(cPYTHON2) sar2json.py \
	| $(cJSONBEAUTIFIER) \
	> $@

#................................................................
pypy.small.test.json: sar2json.py
	xzcat  ../_data/0306.sar_n_DEV.small.xz \
	| time $(cPYPY) sar2json.py \
	| $(cJSONBEAUTIFIER) \
	> $@

pypy.full.test.json: sar2json.py
	xzcat  ../_data/0306.sar_n_DEV.xz \
	| time $(cPYPY) sar2json.py \
	| $(cJSONBEAUTIFIER) \
	> $@
