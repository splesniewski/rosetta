#
#
#
OS=$(shell uname -s)
cPYTHON2=python
cJYTHON2=jython
cPYPY=pypy

ifeq ($(OS),Darwin)
	cPYTHON2=/opt/local/bin/python2.7
	cJYTHON2=/opt/local/bin/jython
	cPYPY=/opt/local/bin/pypy
endif


all: python.ray.png jython.ray.png pypy.ray.png

clean:
	-rm -f *~ make.log
	-rm -f ray.pyc python.ray.png python.ray.pgm python.ray.pgm.log
	-rm -f jython.ray.png jython.ray.pgm jython.ray.pgm.log
	-rm -f pypy.ray.png pypy.ray.pgm pypy.ray.pgm.log

python.ray.pgm: ray.py
	(time $(cPYTHON2) ray.py > $@) 2>&1 | tee $@.log
	openssl md5 $@

jython.ray.pgm: ray.py
	(time $(cJYTHON2) ray.py > $@) 2>&1 | tee $@.log
	openssl md5 $@

pypy.ray.pgm: ray.py
	(time $(cPYPY) ray.py > $@) 2>&1 | tee $@.log
	openssl md5 $@

################################################################
%.png: %.pgm
	pnmtopng $< > $@
