#
#
#
all: single.ray.png process.ray.png plists.ray.png

clean:
	-rm -f *~ ray.beam scene.ray.term erl_crash.dump
	-rm -f single.ray.png single.ray.pgm single.ray.pgm.log
	-rm -f process.ray.png process.ray.pgm process.ray.pgm.log
	-rm -f plists.ray.png plists.ray.pgm plists.ray.pgm.log

veryclean: clean
	-rm -rf erlware_commons

################################################################
%.png: %.pgm
	pnmtopng $< > $@
	openssl md5 $@

################################################################
erlware_commons/ebin/ec_plists.beam:
	git clone https://github.com/erlware/erlware_commons.git
	cd erlware_commons; make

################################################################
ray.beam: ray.erl
	erlc ray.erl

#----------------
single.ray.pgm: ray.beam Makefile
	(time erl -boot start_clean -noshell -smp disable -s ray start_single >$@) 2>&1 | tee $@.log
	openssl md5 $@

process.ray.pgm: ray.beam Makefile
	(time erl -boot start_clean -noshell -smp enable +S 4 -s ray start_process >$@) 2>&1 | tee $@.log
	openssl md5 $@

plists.ray.pgm: ray.beam erlware_commons/ebin/ec_plists.beam
	(time erl -boot start_clean -noshell -smp enable +S 4 -pa erlware_commons/ebin -s ray start_plists >$@) 2>&1 | tee $@.log
	openssl md5 $@

