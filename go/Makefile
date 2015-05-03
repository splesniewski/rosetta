#
#
#
all: go.ray.png 

clean:
	-rm -f *~ make.log
	-rm -f ray go.ray.png go.ray.pgm

ray: ray.go
	go build ray.go

go.ray.pgm: ray
	time ./ray > $@
	openssl md5 $@

################################################################
%.png: %.pgm
	pnmtopng $< > $@
