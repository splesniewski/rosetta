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
	-rm -f sar2json core
	-rm -rf sar2json.dSYM sar2json.d 

#................................................................
# UBUNTU: gnustep-core-devel clang
CC=clang
CFLAGS=-Wall -g -v $$(gnustep-config --objc-flags)
LDFLAGS=$$(gnustep-config --objc-libs) -lgnustep-base 

ifeq ($(OS),Darwin)
	CC=clang

	FRAMEWORKS:= -framework Foundation
	LIBRARIES:= -lobjc

	CFLAGS=-Wall -Werror -g -v
	LDFLAGS=$(LIBRARIES) $(FRAMEWORKS)
endif
#................................................................
sar2json: sar2json.m
	$(CC) $(CFLAGS) $(LDFLAGS) -o $@ $<
#	gcc -o $@ -Wall -std=c99 $< -framework Foundation -lobjc

small.test.json: sar2json
	xzcat  ../_data/0306.sar_n_DEV.small.xz \
	| time ./sar2json \
	| $(cJSONBEAUTIFIER) \
	> $@

full.test.json: sar2json
	xzcat  ../_data/0306.sar_n_DEV.xz \
	| time ./sar2json \
	| $(cJSONBEAUTIFIER) \
	> $@
