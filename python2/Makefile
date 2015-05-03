#
#
#
OS=$(shell uname -s)
ifeq ($(OS),Darwin)
	cPYTHON2=/opt/local/bin/python2.7
else
	ifeq ($(OS),Linux)
		cPYTHON2=/usr/bin/python2.7
	else
		cPYTHON2=python
	endif
endif


all: python.ray.png

clean:
	-rm -f *~ make.log
	-rm -f python.ray.png python.ray.pgm ray.pyc

python.ray.pgm: ray.py
	time $(cPYTHON2) ray.py > $@
	openssl md5 $@

################################################################
%.png: %.pgm
	pnmtopng $< > $@
