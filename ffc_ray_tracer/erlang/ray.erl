-module(ray).
-export([start/1,start_process/0,start_single/0,start_plists/0]).

-record(vec, {x,y,z}).

-define(INFINITY, 1.0e+300).
-define(EPSILON, 0.00000000000000001).
-define(DELTA, math:sqrt(?EPSILON)).

-define(ZEROVEC, #vec{x=0.0,y=0.0,z=0.0}).

-define(OVERSAMPLESIZE, 4).
-define(RESOLUTION, 512).
-define(LEVEL, 6).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

multiply_vec(S,R)->#vec{x=S*R#vec.x, y=S*R#vec.y, z=S*R#vec.z}.
vec_add(A,B)->#vec{x=A#vec.x+B#vec.x, y=A#vec.y+B#vec.y, z=A#vec.z+B#vec.z}.
vec_subtract(A,B)->#vec{x=A#vec.x-B#vec.x, y=A#vec.y-B#vec.y, z=A#vec.z-B#vec.z}.
vec_dot(A,B)->A#vec.x*B#vec.x + A#vec.y*B#vec.y + A#vec.z*B#vec.z.
vec_unitise(R)-> multiply_vec((1.0 / math:sqrt(vec_dot(R,R))), R).

ray_sphere(Orig, Dir, Center, Radius)->
    V=vec_subtract(Center,Orig),
    B=vec_dot(V,Dir),
    D= ((B * B) - vec_dot(V,V) + (Radius * Radius)),
    if 
	(D<0.0) -> 
	    ?INFINITY;
	true ->
	    D2=math:sqrt(D),
	    T2=B + D2,
	    if
		(T2 < 0.0) ->
		    ?INFINITY;
		true->
		    T1=B - D2,
		    if 
			(T1 > 0.0) -> T1;
			true -> T2
			end
		end
	end.

ofscene(Orig,Dir, Scene, {L,N}) ->
    case Scene of
	{sphere, Center, Radius} ->
	    Lp=ray_sphere(Orig,Dir, Center,Radius),
	    if 
		(Lp >= L) ->
		    {L,N};
		true ->
		    {Lp, vec_unitise(vec_subtract(vec_add (Orig, multiply_vec(Lp, Dir)),Center))}
	    end;
	{group, Center, Radius, Scenes} ->
	    Lp=ray_sphere(Orig,Dir, Center,Radius),
	    if 
		(Lp >= L) ->
		    {L,N};
		true ->
		    lists:foldl(fun (S, LN) -> ofscene(Orig,Dir, S, LN) end, {L,N}, Scenes)
	    end
    end.

intersect(Orig,Dir,  Scene) ->
    ofscene(Orig,Dir, Scene, {?INFINITY, ?ZEROVEC}).

ray_trace(Light, Orig, Dir, Scene)->
    {L,N}=intersect(Orig, Dir, Scene),
    if 
	(L >= ?INFINITY) -> 0.0;
	true ->
	    G=0.0-vec_dot(N, Light),
	    if
		(G=<0.0)-> 0.0;
		true ->
		    OrigP=vec_add(Orig, vec_add(multiply_vec(L, Dir),  multiply_vec(?DELTA,N))),
		    DirP=vec_subtract(?ZEROVEC, Light),
		    {Lq,_}=intersect(OrigP, DirP, Scene),
		    if 
			(Lq >= ?INFINITY) -> G;
			true -> 0.0
		    end	     
	    end
    end.

create(Level, R, X, Y, Z)->
%    _=io:format("#Level=~w~n",[Level]),
    Obj={sphere, #vec{x=X,y=Y,z=Z}, R},
    if 
	(Level == 1) -> Obj;
	true -> 
	    Rp = 3.0 * R / math:sqrt(12.0),
	    {group, 
	     #vec{x=X,y=Y,z=Z}, 
	     3.0 * R,
	     [
	      Obj,
	      create((Level-1), (0.5*R), X-Rp, Y+Rp, Z-Rp), 
	      create((Level-1), (0.5*R), X+Rp, Y+Rp, Z-Rp), 
	      create((Level-1), (0.5*R), X-Rp, Y+Rp, Z+Rp), 
	      create((Level-1), (0.5*R), X+Rp, Y+Rp, Z+Rp)
	     ]
	    }
    end.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
pixel(Eye, X,Y, Scene)->
    trunc(0.5 + 255.0* (lists:sum([
				   ray_trace(Eye, 
					     #vec{x=0.0,y=0.0,z=-4.0}, 
					     vec_unitise(#vec{x=X+(Dx/float(?OVERSAMPLESIZE))-(float(?RESOLUTION)/2.0),
							      y=?RESOLUTION-1.0-Y+(Dy/float(?OVERSAMPLESIZE))-(float(?RESOLUTION)/2.0),
							      z=float(?RESOLUTION)}), 
					     Scene)
				   ||Dy<-lists:seq(0,?OVERSAMPLESIZE-1,1),
				     Dx<-lists:seq(0,?OVERSAMPLESIZE-1,1)])
			/float(?OVERSAMPLESIZE*?OVERSAMPLESIZE))).
    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
start_single()->
    start(single),
    halt().
start_process()->
    start(process),
    halt().
start_plists()->
    start(plists),
    halt().

start(single)->
    Level=?LEVEL, % Number of Spheres
    Eye=vec_unitise(#vec{x=-3.0,y=-3.0,z=2.0}),
    Scene=create(Level,  1.0,  0.0,-1.0,0.0), % Scene tree
    trace(single,Scene,Eye);
start(process)->
    Level=?LEVEL, % Number of Spheres
    Eye=vec_unitise(#vec{x=-3.0,y=-3.0,z=2.0}),
    Scene=create(Level,  1.0,  0.0,-1.0,0.0), % Scene tree
    trace(process,Scene,Eye);
start(plists)->
    Level=?LEVEL, % Number of Spheres
    Eye=vec_unitise(#vec{x=-3.0,y=-3.0,z=2.0}),
    Scene=create(Level,  1.0,  0.0,-1.0,0.0), % Scene tree
    trace(plists,Scene,Eye).

trace(single, Scene, Eye) ->
    io:format("P2~n~w ~w~n255~n",[?RESOLUTION,?RESOLUTION]),
    Gs=[ pixel(Eye,X,Y,Scene) || 
	   Y<-lists:seq(0,?RESOLUTION-1,1),
	   X<-lists:seq(0,?RESOLUTION-1,1)
	  ],
    _=[ io:format("~w ",[G]) ||G<-Gs];
trace(process, Scene, Eye) ->
    io:format("P2~n~w ~w~n255~n",[?RESOLUTION,?RESOLUTION]),
    lists:foreach(fun(Y)-> spawn_trace_line(Eye,Y,Scene) end, lists:seq(0,?RESOLUTION-1,1)),
    gather_lines(0);
trace(plists, Scene, Eye) ->
    io:format("P2~n~w ~w~n255~n",[?RESOLUTION,?RESOLUTION]),
    Gs=lists:flatten(ec_plists:map(fun(Y)-> trace_line(Eye,Y,Scene) end, lists:seq(0,?RESOLUTION-1,1)),[4, {processes, 3}] ),
    _=[ io:format("~w ",[G]) ||G<-Gs].

%    Gs=plists:map(fun(Y)-> trace_line(Eye,Y,Scene) end, lists:seq(0,?RESOLUTION-1,1)),
%    _=[ [io:format("~w ",[X]) ||X<-G] ||G<-Gs].

gather_lines(R)->
    _=io:format("~n#gathering line ~w~n",[R]),
    receive
	{line, _, Gs} when R==?RESOLUTION-1 ->
	    _=[ io:format("~w ",[G]) ||G<-Gs];
	{line, Y, Gs} when R==Y ->
	    _=[ io:format("~w ",[G]) ||G<-Gs],
	    gather_lines(R+1)
    end.

spawn_trace_line(Eye, Y, Scene)->
    Pid = self(),
    spawn( fun() -> Pid ! {line, Y, trace_line(Eye, Y, Scene)} end).
		   
trace_line(Eye, Y, Scene)->
    [ pixel(Eye,X,Y,Scene) || X<-lists:seq(0,?RESOLUTION-1,1) ].
