#!/opt/local/bin/lua

INFINITY=1.0e+300
EPSILON=0.00000000000000001
DELTA=math.sqrt(EPSILON)

ZEROVEC={X=0.0,Y=0.0,Z=0.0}

OVERSAMPLESIZE=4
RESOLUTION=512
LEVEL=6

ST_GROUP=0
ST_SPHERE=1

-- ################################################################
function multiply_vec(r, A)
   return { X=r*A.X, Y=r*A.Y, Z=r*A.Z }
end

function vec_add(A, B)
   return { X=(A.X+B.X), Y=(A.Y+B.Y), Z=(A.Z+B.Z) }
end

function vec_subtract(A, B)
   return { X=(A.X-B.X), Y=(A.Y-B.Y), Z=(A.Z-B.Z) }
end

function vec_dot(A, B)
   return (A.X*B.X)+(A.Y*B.Y)+(A.Z*B.Z)
end

function vec_unitise(R)
   return multiply_vec((1.0 / math.sqrt(vec_dot(R,R))), R)
end

function ray_sphere(Orig, Dir, Center, Radius)
   local V=vec_subtract(Center,Orig)
   local B=vec_dot(V,Dir)
   local D=((B*B) - vec_dot(V,V) + (Radius * Radius))

   if (D<0.0) then
      return INFINITY
   else
      local D2=math.sqrt(D)
      local T2=B+D2

      if (T2 < 0.0) then
	 return INFINITY
      else
	 local T1=B-D2
	 if (T1 > 0.0) then
	    return T1
	 else
	    return T2
	 end
      end
   end
end

function ofscene(Orig,Dir,  LN, Scene)
   if (Scene.TYPE == ST_SPHERE) then
      local Lp=ray_sphere(Orig, Dir, Scene.CENTER, Scene.RADIUS)
      if (Lp >= LN.L)then
	 return LN
      else
	 return {L=Lp,N=vec_unitise(vec_subtract(vec_add(Orig, multiply_vec(Lp, Dir)),Scene.CENTER))}
      end
   elseif (Scene.TYPE == ST_GROUP) then
      local Lp=ray_sphere(Orig, Dir, Scene.CENTER,  Scene.RADIUS)
      if (Lp>= LN.L) then
	 return LN
      else
	 local qLN=LN
	 for i,S in ipairs(Scene.SCENES) do
	    qLN=ofscene(Orig,Dir, qLN, S)
	 end
	 return qLN
      end
   end
end

function intersect(Orig, Dir, Scene)
   return ofscene(Orig, Dir, {L=INFINITY, N=ZEROVEC}, Scene)
end

function ray_trace(Light, Orig, Dir, Scene)
    local LN=intersect(Orig, Dir, Scene)

    if (LN.L >= INFINITY) then
       return 0.0
    else
       local G=0.0-vec_dot(LN.N, Light)
       if (G<=0.0) then
	  return 0.0
       else
	  local OrigP=vec_add(Orig, vec_add(multiply_vec(LN.L, Dir),  multiply_vec(DELTA,LN.N)))
	  local DirP=vec_subtract(ZEROVEC, Light)
	  local LqN=intersect(OrigP, DirP, Scene)
	  if (LqN.L >= INFINITY) then
	     return G
	  else
	     return 0.0
	  end
       end
    end
end

function create(Level, R, X, Y, Z)
   local Obj={
      TYPE=ST_SPHERE,
      CENTER={X=X,Y=Y,Z=Z},
      RADIUS=R
   }

   if (Level == 1) then
	return Obj
   else
      local Rp = 3.0 * R / math.sqrt(12.0)
      return { TYPE=ST_GROUP,
	       CENTER={X=X,Y=Y,Z=Z},
	       RADIUS=3.0*R,
	       SCENES={
		  Obj,
		  create((Level-1), (0.5*R), X-Rp, Y+Rp, Z-Rp),
		  create((Level-1), (0.5*R), X+Rp, Y+Rp, Z-Rp),
		  create((Level-1), (0.5*R), X-Rp, Y+Rp, Z+Rp),
		  create((Level-1), (0.5*R), X+Rp, Y+Rp, Z+Rp)
	       }
      }
   end
end

-- ################################################################
function pixel(Eye, X,Y, Scene)
   local rsum=0
   for Dx=0,(OVERSAMPLESIZE-1) do
      for Dy=0,(OVERSAMPLESIZE-1) do
	 rsum=rsum+ray_trace(Eye,
			     {X=0.0, Y=0.0, Z=-4.0},
			     vec_unitise({ X=X+(Dx/OVERSAMPLESIZE)-(RESOLUTION/2.0),
					   Y=RESOLUTION-1.0-Y+(Dy/OVERSAMPLESIZE)-(RESOLUTION/2.0),
					   Z=RESOLUTION}),
			     Scene)
	 end
    end
   return math.floor(0.5 + 255.0 * (rsum)/(OVERSAMPLESIZE*OVERSAMPLESIZE))
end

-- ################################################################
function start()
   local Level=LEVEL -- Number of Spheres
   local Eye=vec_unitise({X=-3.0,Y=-3.0,Z=2.0})
   local Scene=create(Level, 1.0, 0.0,-1.0,0.0) -- Scene tree
   trace(Eye, Scene)
   return
end

function trace(Eye, Scene)
   io.write(string.format("P2\n%d %d\n255\n", RESOLUTION, RESOLUTION))
   for Y=0,(RESOLUTION-1) do
      for X=0,(RESOLUTION-1) do
      	 if (X>0) then io.write(" ") end
      	 io.write(string.format("%d",pixel(Eye,X,Y,Scene)))
      end
      io.write("\n")
   end
   return
end

-- ################################################################
start()
	
