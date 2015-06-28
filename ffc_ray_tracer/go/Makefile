#
#
#
all: go.ray.png 

clean:
	-rm -f *~ make.log
	-rm -f ray go.ray.png go.ray.pgm go.ray.pgm.log

ray: ray.go
	go build ray.go

go.ray.pgm: ray
	(time ./ray > $@) 2>&1 | tee $@.log
	openssl md5 $@

################################################################
%.png: %.pgm
	pnmtopng $< > $@
