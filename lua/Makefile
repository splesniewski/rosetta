#
#
#
all: lua.ray.png luajit.ray.png

clean:
	-rm -f *~ make.log
	-rm -f lua.ray.png lua.ray.pgm luajit.ray.png luajit.ray.pgm

lua.ray.pgm: ray.lua
	time lua ray.lua > $@
	openssl md5 $@

# OSX.10/MacPorts: needed 'port -s -v install luajit' to prevent precompiled binary install (avoid "Segmentation fault: 11" issue")
luajit.ray.pgm: ray.lua
	time luajit ray.lua > $@
	openssl md5 $@

################################################################
%.png: %.pgm
	pnmtopng $< > $@
