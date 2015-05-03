package main

import (
	"fmt"
	"math"
	"os"
	"runtime"
)

const (
	OVERSAMPLESIZE = 4
	RESOLUTION     = 512
	LEVEL          = 6
)

type Vector struct {
	x float64
	y float64
	z float64
}

type Hit struct {
	l float64
	v Vector
}

type Object struct {
	kind   int
	center Vector
	radius float64
	objs   []Object
}

const (
	INFINITY = 1.0e+300
	EPSILON  = 0.00000000000000001

	ST_GROUP  = 0
	ST_SPHERE = 1
)

var ZEROVEC Vector = Vector{x: 0.0, y: 0.0, z: 0.0}
var DELTA float64 = math.Sqrt(EPSILON)

//----------------------------------------------------------------
func multiply_vec(s Vector, r float64) Vector {
	return Vector{x: r * s.x, y: r * s.y, z: r * s.z}
}

func vec_add(a Vector, b Vector) Vector       {
	return Vector{x: (a.x + b.x), y: (a.y + b.y), z: (a.z + b.z)}
}

func vec_subtract(a Vector, b Vector) Vector {
	return Vector{x: (a.x - b.x), y: (a.y - b.y), z: (a.z - b.z)}
}

func vec_dot(a Vector, b Vector) float64 {
	return (a.x * b.x) + (a.y * b.y) + (a.z * b.z)
}

func vec_unitise(a Vector) Vector {
	return multiply_vec(a, (float64(1.0) / math.Sqrt(vec_dot(a, a))))
}

//----------------------------------------------------------------
func ray_sphere(orig Vector, dir Vector, center Vector, radius float64) float64 {
	v := vec_subtract(center, orig)
	b := vec_dot(v, dir)
	d := ((b * b) - vec_dot(v, v) + (radius * radius))

	if d < 0.0 {
		return INFINITY
	} else {
		d2 := math.Sqrt(d)
		t2 := b + d2

		if t2 < 0.0 {
			return INFINITY
		} else {
			t1 := b - d2
			if t1 > 0.0 {
				return t1
			} else {
				return t2
			}
		}
	}
}

func ofscene(orig Vector, dir Vector, ln Hit, scene Object) Hit {
	if scene.kind == ST_SPHERE {
		lp := ray_sphere(orig, dir, scene.center, scene.radius)

		if lp >= ln.l {
			return ln
		}
		return Hit{l: lp, v: vec_unitise(vec_subtract(vec_add(orig, multiply_vec(dir, lp)), scene.center))}

	} else if scene.kind == ST_GROUP {
		lp := ray_sphere(orig, dir, scene.center, scene.radius)
		qln := ln

		if lp >= ln.l {
			return ln
		} else {
			for _, s := range scene.objs {
				qln = ofscene(orig, dir, qln, s)
			}
		}
		return qln
	}
	return ln // should never reach this
}

func intersect(orig Vector, dir Vector, scene Object) Hit {
	return ofscene(orig, dir, Hit{l: INFINITY, v: ZEROVEC}, scene)
}

func ray_trace(light Vector, orig Vector, dir Vector, scene Object) float64 {
	ln := intersect(orig, dir, scene)

	if ln.l >= INFINITY {
		return 0.0
	} else {
		g := 0.0 - vec_dot(ln.v, light)
		if g <= 0.0 {
			return 0.0
		} else {
			origp := vec_add(orig, vec_add(multiply_vec(dir, ln.l), multiply_vec(ln.v, DELTA)))
			dirp := vec_subtract(ZEROVEC, light)
			lqn := intersect(origp, dirp, scene)

			if lqn.l >= INFINITY {
				return g
			}

			return 0.0
		}
	}
}

func create(level int, r float64, x float64, y float64, z float64) Object {
	obj := Object{
		kind:   ST_SPHERE,
		center: Vector{x: x, y: y, z: z},
		radius: r,
		objs:   nil,
	}

	if level == 1 {
		return obj
	} else {
		rp := 3.0 * r / math.Sqrt(12.0)
		return Object{
			kind:   ST_GROUP,
			center: Vector{x: x, y: y, z: z},
			radius: 3.0 * r,
			objs: []Object{
				obj,
				create((level - 1), (0.5 * r), x-rp, y+rp, z-rp),
				create((level - 1), (0.5 * r), x+rp, y+rp, z-rp),
				create((level - 1), (0.5 * r), x-rp, y+rp, z+rp),
				create((level - 1), (0.5 * r), x+rp, y+rp, z+rp),
			},
		}
	}
}

//----------------------------------------------------------------
func pixel(eye Vector, x int, y int, scene Object) int {

	var rsum float64 = float64(0.0)

	for dx := 0; dx <= (OVERSAMPLESIZE - 1); dx++ {
		for dy := 0; dy <= (OVERSAMPLESIZE - 1); dy++ {
			rsum = rsum + ray_trace(
				eye,
				Vector{x: 0.0, y: 0.0, z: -4.0},
				vec_unitise(
					Vector{
						x: float64(x) + (float64(dx) / float64(OVERSAMPLESIZE)) - (float64(RESOLUTION) / 2.0),
						y: float64(RESOLUTION) - 1.0 - float64(y) + (float64(dy) / float64(OVERSAMPLESIZE)) - (float64(RESOLUTION) / 2.0),
						z: float64(RESOLUTION),
					}),
				scene)
		}
	}
	return int(math.Floor(float64(0.5) + (float64(255.0) * ((rsum) / float64(OVERSAMPLESIZE*OVERSAMPLESIZE)))))
}

//----------------------------------------------------------------
func trace_single(eye Vector, scene Object) {
	fmt.Printf("P2\n%d %d\n255\n", RESOLUTION, RESOLUTION)
	for y := 0; y <= (RESOLUTION - 1); y++ {
		for x := 0; x <= (RESOLUTION - 1); x++ {
			if x > 0 {
				fmt.Printf(" ")
			}
			fmt.Printf("%d", pixel(eye, x, y, scene))
		}
		fmt.Printf("\n")
	}
}

//................................................................
func trace_goroutine (eye Vector, scene Object) {

	type workerdata struct {
		y int
		d [RESOLUTION]int
	}

	var numWorkers int = runtime.NumCPU() * 2
	runtime.GOMAXPROCS(numWorkers)

	image:= make([][RESOLUTION]int,RESOLUTION)

	done := make(chan struct{}, RESOLUTION)
	work := make(chan int, RESOLUTION)
	result := make(chan workerdata, RESOLUTION)

	// setup workers
	for i := 0; i < numWorkers; i++ {
		go func(workerid int, d chan struct{}, w chan int, r chan workerdata) {
			fmt.Fprintf(os.Stderr, "%02d: started\n", workerid)

			var workresult workerdata;
			for y := range w {
//				fmt.Fprintf(os.Stderr, "%02d: working y=%d\n", workerid, y)
				workresult.y=y;
				for x := 0; x <= (RESOLUTION - 1); x++ {
					workresult.d[x]=pixel(eye, x, y, scene)
				}
				select {
				case r <- workresult:
//					fmt.Fprintf(os.Stderr, "%02d: sent y=%d\n", workerid, y)
				case <-d:
					return
				}
			}
		}(i, done,work,result)
	}

	// fill up work queue
	for y := 0; y <= (RESOLUTION - 1); y++ { work <- y }

	// reap results
	for y := 0; y <= (RESOLUTION - 1); y++ {
		r := <- result
//		fmt.Fprintf(os.Stderr, "XX: result y=%d\n", r.y)
		image[r.y] = r.d
	}
	
	// display results
	fmt.Printf("P2\n%d %d\n255\n", RESOLUTION, RESOLUTION)
	for y := 0; y <= (RESOLUTION - 1); y++ {
		for x := 0; x <= (RESOLUTION - 1); x++ {
			if x > 0 {
				fmt.Printf(" ")
			}
			fmt.Printf("%d", image[y][x])
		}
		fmt.Printf("\n")
	}
}

//----------------------------------------------------------------
func main() {
	level := LEVEL // Number of Spheres
	eye := vec_unitise(Vector{x: -3.0, y: -3.0, z: 2.0})
	scene := create(level, 1.0, 0.0, -1.0, 0.0) // Scene tree

//	trace_single(eye, scene)
	trace_goroutine(eye, scene)
}
