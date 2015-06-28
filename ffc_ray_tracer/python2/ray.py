#!/opt/local/bin/python2.7
import math

INFINITY=1.0e+300
EPSILON=0.00000000000000001
DELTA=math.sqrt(EPSILON)

OVERSAMPLESIZE=4
RESOLUTION=512
LEVEL=6

class Vec:
    def __init__(self, X, Y, Z):
        self.X=X
        self.Y=Y
        self.Z=Z

class Object:
    def __init__(self, TYPE, CENTER, RADIUS, SCENES):
        self.TYPE=TYPE
        self.CENTER=CENTER
        self.RADIUS=RADIUS
        self.SCENES=SCENES

class Hit:
    def __init__(self, l, v):
        self.l=l
        self.v=v

ZEROVEC=Vec(0.0,0.0,0.0)

ST_GROUP=0
ST_SPHERE=1

################################################################
def multiply_vec(r, A):
    return Vec(r*A.X,r*A.Y,r*A.Z)

def vec_add(A, B):
    return Vec((A.X+B.X),(A.Y+B.Y),(A.Z+B.Z))
        
def vec_subtract(A, B):
    return Vec((A.X-B.X),(A.Y-B.Y),(A.Z-B.Z))

def vec_dot(A, B):
    return ((A.X*B.X)+(A.Y*B.Y)+(A.Z*B.Z))

def vec_unitise(R):
    return multiply_vec((1.0 / math.sqrt(vec_dot(R,R))), R)

#................................................................
def ray_sphere(Orig, Dir, Center, Radius):
    V=vec_subtract(Center,Orig)
    B=vec_dot(V,Dir)
    D=((B*B) - vec_dot(V,V) + (Radius * Radius))

    if (D<0.0):
        return INFINITY
    else:
        D2=math.sqrt(D)
	T2=B+D2
        if (T2 < 0.0):
            return INFINITY
        else:
            T1=B-D2
            if (T1 > 0.0):
                return T1
            else:
                return T2

def ofscene(Orig,Dir, LN, Scene):
    if (Scene.TYPE == ST_SPHERE):
	Lp=ray_sphere(Orig, Dir, Scene.CENTER, Scene.RADIUS)
	if (Lp >= LN.l):
	    return LN
	else:
	    return Hit(Lp,
                       vec_unitise(vec_subtract(vec_add(Orig, multiply_vec(Lp, Dir)),Scene.CENTER))
                   )
    elif (Scene.TYPE == ST_GROUP):
	Lp=ray_sphere(Orig, Dir, Scene.CENTER, Scene.RADIUS)
	if (Lp >= LN.l):
	    return LN
	else:
	    qLN=LN
	    for S in Scene.SCENES:
		qLN=ofscene(Orig,Dir, qLN, S)
            return qLN
    else:
        print "BAD"

def intersect(Orig, Dir, Scene):
    return ofscene(Orig, Dir, Hit(INFINITY, ZEROVEC), Scene)

def ray_trace(Light, Orig, Dir, Scene):
    LN=intersect(Orig, Dir, Scene)
    if (LN.l >= INFINITY):
	return 0.0
    else:
	G=0.0-vec_dot(LN.v, Light)
	if (G<=0.0):
	    return 0.0
	else:
	    OrigP=vec_add(Orig, vec_add(multiply_vec(LN.l, Dir),  multiply_vec(DELTA,LN.v)))
	    DirP=vec_subtract(ZEROVEC, Light)
	    LqN=intersect(OrigP, DirP, Scene)
 	    if (LqN.l >= INFINITY):
		return G
	    else:
		return 0.0

def create(Level, R, X, Y, Z):
    Obj=Object(ST_SPHERE, Vec(X,Y,Z), R, [])
    if (Level == 1):
	return Obj
    else:
	Rp = 3.0 * R / math.sqrt(12.0)
        return Object(ST_GROUP,
                      Vec(X,Y,Z),
                      3.0*R,
                      [
                          Obj,
                          create((Level-1), (0.5*R), X-Rp, Y+Rp, Z-Rp),
                          create((Level-1), (0.5*R), X+Rp, Y+Rp, Z-Rp),
                          create((Level-1), (0.5*R), X-Rp, Y+Rp, Z+Rp),
                          create((Level-1), (0.5*R), X+Rp, Y+Rp, Z+Rp)
                      ]
                  )
            
#................................................................
def pixel(Eye, X,Y, Scene):
    rsum=0
    for Dx in range(OVERSAMPLESIZE):
        for Dy in range(OVERSAMPLESIZE):
            rsum=rsum+ray_trace(Eye,
                                Vec(0.0,0.0,-4.0),
                                vec_unitise(Vec(X+(float(Dx)/OVERSAMPLESIZE)-(RESOLUTION/2.0),
                                    RESOLUTION-1-Y+(float(Dy)/OVERSAMPLESIZE)-(RESOLUTION/2.0),
                                    RESOLUTION)),
                                Scene
                            )
    return math.floor(0.5 + (255.0 * ((rsum)/(OVERSAMPLESIZE*OVERSAMPLESIZE))))

################################################################
def tracePGMStdout(Eye, Scene):
    print "P2\n%d %d\n%d" % (RESOLUTION, RESOLUTION, 255) 
    for Y in range(RESOLUTION):
        for X in range(RESOLUTION):
	    print "%s%d" % ((" " if (X>0) else ""), pixel(Eye,X,Y,Scene)),
	print
    return

def tracePGM():
    Level=LEVEL # Number of Spheres
    Eye=vec_unitise(Vec(-3.0,-3.0,2.0) )
    Scene=create(Level, 1.0, 0.0,-1.0,0.0) # Scene tree
    tracePGMStdout(Eye, Scene)
    return
	
#................................................................
def main():
    tracePGM()

if __name__ == '__main__':
    main()
