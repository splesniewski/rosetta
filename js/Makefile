#
#
#
SHELL=bash
OS=$(shell uname -s)
ifeq ($(OS),Darwin)
        cNODEJS=/opt/local/bin/node
else
        ifeq ($(OS),Linux)
                cNODEJS=nodejs
        else
                cNODEJS=nodejs
        endif
endif

all: nodejs.ray.png

clean:
	-rm -f *~ make.log
	-rm -f nodejs.ray.png nodejs.ray.pgm

nodejs.ray.pgm: ray.js nodejs.ray.js
	time $(cNODEJS) nodejs.ray.js > $@
	openssl md5 $@

################################################################
%.png: %.pgm
	pnmtopng $< > $@
