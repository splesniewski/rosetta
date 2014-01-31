#!/usr/bin/perl
use strict;
use warnings;

our $VERSION=q(1.0.0);

my $INFINITY=1.0e+300;
my $EPSILON=0.00000000000000001;
my $DELTA=sqrt($EPSILON);

my $ZEROVEC={X=>0.0,Y=>0.0,Z=>0.0};

my $OVERSAMPLESIZE=2;
my $RESOLUTION=256;

my $ST_GROUP=0;
my $ST_SPHERE=1;

################################################################
sub multiply_vec{
    my($s, $r)=@_;
    return ({ X=>$s*$r->{X}, Y=>$s*$r->{Y}, Z=>$s*$r->{Z} });
}

sub vec_add{
    my($A, $B)=@_;
    return ({ X=>($A->{X}+$B->{X}), Y=>($A->{Y}+$B->{Y}), Z=>($A->{Z}+$B->{Z}) });
}

sub vec_subtract{
    my($A, $B)=@_;
    return ({ X=>($A->{X}-$B->{X}), Y=>($A->{Y}-$B->{Y}), Z=>($A->{Z}-$B->{Z}) });
}

sub vec_dot{
    my($A, $B)=@_;
    return ( ($A->{X} * $B->{X}) + ($A->{Y} * $B->{Y}) + ($A->{Z} * $B->{Z}) )
};

sub vec_unitise{
    my ($R)=@_;
    return( multiply_vec((1.0 / sqrt(vec_dot($R,$R))), $R) );
}

sub ray_sphere{
    my ($Orig, $Dir, $Center, $Radius)=@_;
    my $V=vec_subtract($Center,$Orig);
    my $B=vec_dot($V,$Dir);
    my $D= (($B * $B) - vec_dot($V,$V) + ($Radius * $Radius));
    if ($D<0.0) {
	return($INFINITY);
    }else{
	my$D2=sqrt($D);
	my $T2=$B + $D2;
	if ($T2 < 0.0) {
	    return($INFINITY);
	}else{
	    my $T1=$B - $D2;
	    if ($T1 > 0.0){
		return($T1);
	    }else{
		return($T2);
	    }
	}
    }
}

sub ofscene{
    my($Orig,$Dir,  $LN, $Scene)=@_;

    if ($Scene->{TYPE} == $ST_SPHERE){
	my $Lp=ray_sphere($Orig, $Dir, $Scene->{CENTER},  $Scene->{RADIUS});
	if ($Lp >= $LN->{L}){
	    return ($LN);
	}else{
	    return ({L=>$Lp,N=>vec_unitise(vec_subtract(vec_add ($Orig, multiply_vec($Lp, $Dir)),$Scene->{CENTER}))});
	}
    }elsif ($Scene->{TYPE} == $ST_GROUP){
	my $Lp=ray_sphere($Orig, $Dir, $Scene->{CENTER},  $Scene->{RADIUS});
	if ($Lp>= $LN->{L}){
	    return ($LN);
	}else{
	    # lists:foldl(fun (S, LN) -> ofscene(Orig,Dir, S, LN) end, {L,N}, Scenes)

	    my $qLN=$LN;
	    foreach my $S (@{$Scene->{SCENES}}){$qLN=ofscene($Orig,$Dir, $qLN, $S);}
	    return ($qLN);
	}
    }
}

sub intersect{
    my ($Orig,$Dir, $Scene)=@_;
    return(ofscene($Orig,$Dir, {L=>$INFINITY, N=>$ZEROVEC}, $Scene));
}

sub ray_trace{
    my ($Light, $Orig, $Dir, $Scene)=@_;
    my $LN=intersect($Orig, $Dir, $Scene);
    if ($LN->{L} >= $INFINITY){
	return(0.0);
    }else{
	my $G=0.0-vec_dot($LN->{N}, $Light);
	if ($G<=0.0){
	    return(0.0);
	}else{
	    my $OrigP=vec_add($Orig, vec_add(multiply_vec($LN->{L}, $Dir),  multiply_vec($DELTA,$LN->{N})));
	    my $DirP=vec_subtract($ZEROVEC, $Light);
	    my $LqN=intersect($OrigP, $DirP, $Scene);
	    if ($LqN->{L} >= $INFINITY){
		return($G);
	    }else{
		return(0.0);
	    }
	}
    }
}

sub create{
    my ($Level, $R, $X, $Y, $Z)=@_;

    my $Obj={
	TYPE=>$ST_SPHERE,
	CENTER=>{X=>$X,Y=>$Y,Z=>$Z},
	RADIUS=>$R};
    if ($Level == 1){
	return($Obj);
    }else{
	my $Rp = 3.0 * $R / sqrt(12.0);
	return(
	    {TYPE=>$ST_GROUP,
	     CENTER=>{X=>$X,Y=>$Y,Z=>$Z},
	     RADIUS=>3.0 * $R,
	     SCENES=>[
		 $Obj,
		 create(($Level-1), (0.5*$R), $X-$Rp, $Y+$Rp, $Z-$Rp),
		 create(($Level-1), (0.5*$R), $X+$Rp, $Y+$Rp, $Z-$Rp),
		 create(($Level-1), (0.5*$R), $X-$Rp, $Y+$Rp, $Z+$Rp),
		 create(($Level-1), (0.5*$R), $X+$Rp, $Y+$Rp, $Z+$Rp)
		 ] }
	    );
    }
}
################################################################
sub pixel{
    my ($Eye, $X,$Y, $Scene)=@_;
			
    my $rsum=0;
    for my $Dx (0..$OVERSAMPLESIZE-1){
	for my $Dy (0..$OVERSAMPLESIZE-1){
	    $rsum+=ray_trace($Eye,
			     {X=>0.0, Y=>0.0, Z=>-4.0},
			     vec_unitise({ X=>$X+($Dx/$OVERSAMPLESIZE)-($RESOLUTION/2.0),
					   Y=>$RESOLUTION-1.0-$Y+($Dy/$OVERSAMPLESIZE)-($RESOLUTION/2.0),
					   Z=>$RESOLUTION}),
			     $Scene)
	}
    }
    return (int(0.5 + 255.0 * ($rsum)/($OVERSAMPLESIZE*$OVERSAMPLESIZE)));
}

################################################################
sub start{
    my $Level=5; # Number of Spheres
    my$Eye=vec_unitise({X=>-3.0,Y=>-3.0,Z=>2.0});
    my$Scene=create($Level,  1.0,  0.0,-1.0,0.0); # Scene tree
    trace($Eye, $Scene);
    return;
}

sub trace{
    my ($Eye, $Scene)=@_;

    printf(STDOUT "P2\n%s %s\n255\n",$RESOLUTION,$RESOLUTION);
    for my $Y (0..$RESOLUTION-1){
	printf(STDOUT "%s\n", join(q( ),
				   map {pixel($Eye,$_,$Y,$Scene)} 0..$RESOLUTION-1
	       )
	    );
    }
    return;
}

################################################################
start();
