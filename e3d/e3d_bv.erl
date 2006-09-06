%%
%%  e3d_bv.erl --
%%
%%     Bounding volume operations.
%%        Currently only quickhull, and eigen-vecs calculation implemented
%%  Copyright (c) 2001-2005 Dan Gudmundsson
%%
%%  See the file "license.terms" for information on usage and redistribution
%%  of this file, and for a DISCLAIMER OF ALL WARRANTIES.
%%
%%     $Id: e3d_bv.erl,v 1.1 2005/05/03 16:23:08 dgud Exp $
%%

-module(e3d_bv).
-export([eigen_vecs/1,quickhull/1,covariance_matrix/1]).

-import(e3d_vec, [dot/2,add/2,sub/2,average/1,norm/1,normal/1]).
-import(lists, [foldl/3]).

-compile(inline).

eigen_vecs(Vs) ->
    Fs = quickhull(Vs),
    SymMat = covariance_matrix(Fs),
    {Vals,{X1,Y1,Z1,X2,Y2,Z2,X3,Y3,Z3}} = e3d_mat:eigenv3(SymMat),
    {Vals,{{X1,Y1,Z1},
	   {X2,Y2,Z2},
	   {X3,Y3,Z3}}}.

%%%%%%%%%%%%%%%%%%%%%%%%%%% QHULL %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
-record(hull, {f,p,os}).
%% Splits a point soup in a convex-triangle-hull.
quickhull([V1,V2|Vs0]) when list(Vs0) -> 
    %% Init find an initial triangle..
    [M1,M2] = if V1 < V2 -> [V1,V2]; true -> [V2,V1] end,
    {T1,T2,[T30|Vs1]} = minmax_x(Vs0,M1,M2,[]),
    Cen = average([T1,T2]),
    Vec = e3d_vec:norm_sub(T2,Cen),
    Max = fun(V) ->
		  {VVec,Vd} = vec_dist(V,Cen),
		  A = (1-abs(dot(VVec,Vec))),
		  Vd*A
	  end,
    {T3,Vs2} = max_zy(Vs1,Max,Max(T30),T30,[]),
    %% Create the initial hull of two faces
    F1 = #hull{p=Plane} = hull([T1,T2,T3]),
    F2 = hull([T1,T3,T2]),
    %% Split vertices on each plane
    {F1L,F2L} = initial_split(Vs2,Plane,0.0,[],0.0,[]),
    %% Expand hull
    quickhull2([F1#hull{os=F1L},F2#hull{os=F2L}],[]).

quickhull2([This=#hull{os=[]}|Rest], Completed) ->
    quickhull2(Rest,[This|Completed]);
quickhull2([#hull{f=Face,os=[New|Os0]}|Rest], Completed) ->
    Eds0 = mk_eds(Face,gb_sets:empty()),
    {Eds,Os,Unchanged} = 
	remove_seen_hull(Completed++Rest,Eds0,New,Os0,[]),
    NewHulls = create_new_hulls(Eds,Os,New,[]),
    quickhull2(NewHulls++Unchanged, []);
quickhull2([],Completed) ->    
    [Vs|| #hull{f=Vs} <- Completed].

remove_seen_hull([This=#hull{p=Plane,f=F,os=Os}|R],
		 Eds0,Point,Os0,Ignore) ->
    case check_plane(Point,Plane) of
	{true,_} ->
	    remove_seen_hull(R,mk_eds(F,Eds0),Point,Os++Os0,Ignore);
	{false,_} ->
	    remove_seen_hull(R,Eds0,Point,Os0,[This|Ignore])
    end;
remove_seen_hull([],Eds,_,Os,Ignored) ->
    {gb_sets:to_list(Eds),Os,Ignored}.

create_new_hulls([{V1,V2}|R],Os0,Point,Acc) ->
    Hull = #hull{p=Plane} = hull([V1,V2,Point]),
    {Os,Inside} = split_outside(Os0,Plane,0.0,[],[]),
    create_new_hulls(R,Inside,Point,[Hull#hull{os=Os}|Acc]);
create_new_hulls([],_Inside,_,Acc) ->
    Acc.

split_outside([V|R],Plane,Worst,InFront0,Behind) ->
    case check_plane(V,Plane) of
	{true,D} ->
	    {WP,InFront} = worst(V,D,Worst,InFront0),
	    split_outside(R,Plane,WP,InFront,Behind);
	{false,_} ->
	    split_outside(R,Plane,Worst,InFront0,[V|Behind])
    end;
split_outside([],_,_,InFront,Behind) ->
    {InFront,Behind}.

mk_eds([V1,V2,V3],T0) ->
    T1 = add_edge(V1,V2,T0),
    T2 = add_edge(V2,V3,T1),
    add_edge(V3,V1,T2).

add_edge(V1,V2,T) ->
    %% Add only border edges
    case gb_sets:is_member({V2,V1}, T) of
	true -> gb_sets:delete({V2,V1},T);
	false -> gb_sets:add_element({V1,V2},T)
    end.

check_plane(V,{PC,PN}) ->
    {Vec,D} = vec_dist(V,PC),
    A = dot(Vec,PN),
    if A > 0 -> % 1.0e-6 ->
	    {true, D*A};
       true ->%%A < 1.0e-6 ->
	    {false,-D*A}
    end.

minmax_x([This|R],Old,Max,Acc) when This < Old ->
    minmax_x(R,This,Max,[Old|Acc]);
minmax_x([This|R],Min,Old,Acc) when This > Old ->
    minmax_x(R,Min,This,[Old|Acc]);
minmax_x([This|R],Min,Max,Acc) ->
    minmax_x(R,Min,Max,[This|Acc]);
minmax_x([],Min,Max,Acc) -> 
    {Min,Max,Acc}.

max_zy([This|R],Test,Val,BestSoFar,Acc) ->
    case Test(This) of
	Better when Better > Val ->
	    max_zy(R,Test,Better,This,[BestSoFar|Acc]);
	_Worse ->
	    max_zy(R,Test,Val,BestSoFar,[This|Acc])
    end;
max_zy([],_,_,Best,Acc) -> {Best,Acc}.

initial_split([V|Vs],Plane,WP0,Pos0,WN0,Neg0) ->
    case check_plane(V,Plane) of	
	{true,D} -> 
	    {WP,Pos} = worst(V,D,WP0,Pos0),
	    initial_split(Vs,Plane,WP,Pos,WN0,Neg0);
	{false,D} -> 
	    {WN,Neg} =worst(V,D,WN0,Neg0),
	    initial_split(Vs,Plane,WP0,Pos0,WN,Neg)
    end;
initial_split([],_,_,Pos,_,Neg) -> 
    {Pos,Neg}.

worst(V,This,D,[W|List]) when This < D -> 
    {D,[W,V|List]};
worst(V,D,_Worst,List) ->
    {D,[V|List]}.

hull(Vs) ->
    #hull{f=Vs,p={average(Vs),normal(Vs)}}.

vec_dist({V10,V11,V12}, {V20,V21,V22})
  when is_float(V10), is_float(V11), is_float(V12), 
       is_float(V20), is_float(V21), is_float(V22)->
    X = V10-V20,
    Y = V11-V21,
    Z = V12-V22,
    try 
	D = math:sqrt(X*X+Y*Y+Z*Z),
	{{X/D,Y/D,Z/D},D}
    catch error:badarith ->
	    {{0.0,0.0,0.0},0.0}
    end.

%%%%%%%%%%%%%%%%%%%%% QHULL %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Creates a Symmetric covariance matrix from a list of triangles.
covariance_matrix(Faces) ->
    N = length(Faces),
    C0 = foldl(fun(Vs,Acc) -> add(average(Vs),Acc) end, 
	       {0.0,0.0,0.0}, Faces),
    {Cx,Cy,Cz} = e3d_vec:mul(C0,1/N),
    M0 = foldl(fun([{X00,Y00,Z00},{X10,Y10,Z10},{X20,Y20,Z20}],
		   {M11,M12,M13,M22,M23,M33}) ->
		       X0=X00-Cx,X1=X10-Cx,X2=X20-Cx,
		       Y0=Y00-Cy,Y1=Y10-Cy,Y2=Y20-Cy,
		       Z0=Z00-Cz,Z1=Z10-Cz,Z2=Z20-Cz,
		       {X0*X0+X1*X1+X2*X2+M11,
			X0*Y0+X1*Y1+X2*Y2+M12,
			X0*Z0+X1*Z1+X2*Z2+M13,
			Y0*Y0+Y1*Y1+Y2*Y2+M22,
			Y0*Z0+Y1*Z1+Y2*Z2+M23,
			Z0*Z0+Z1*Z1+Z2*Z2+M33}
	       end,{0.0,0.0,0.0,0.0,0.0,0.0},Faces),
    {M11,M21=M12,M31=M13,M22,M32=M23,M33} = M0,
    D = 3*N,
    {M11/D, M12/D, M13/D,
     M21/D, M22/D, M23/D,
     M31/D, M32/D, M33/D}.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%