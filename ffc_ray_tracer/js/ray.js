var INFINITY=1.0e+300
var EPSILON=0.00000000000000001
var DELTA=Math.sqrt(EPSILON)

var ZEROVEC={X:0.0,Y:0.0,Z:0.0}

var OVERSAMPLESIZE=4
var RESOLUTION=512
var LEVEL=6

var ST_GROUP=0
var ST_SPHERE=1

// ################################################################
function multiply_vec(r, A) {
    return { X:r*A.X, Y:r*A.Y, Z:r*A.Z }
}

function vec_add(A, B) {
    return { X:(A.X+B.X), Y:(A.Y+B.Y), Z:(A.Z+B.Z) }
}

function vec_subtract(A, B) {
    return { X:(A.X-B.X), Y:(A.Y-B.Y), Z:(A.Z-B.Z) }
}

function vec_dot(A, B) {
    return (A.X*B.X)+(A.Y*B.Y)+(A.Z*B.Z)
}

function vec_unitise(R){
    return multiply_vec((1.0 / Math.sqrt(vec_dot(R,R))), R)
}

function ray_sphere(Orig, Dir, Center, Radius) {
    var V=vec_subtract(Center,Orig)
    var B=vec_dot(V,Dir)
    var D=((B*B) - vec_dot(V,V) + (Radius * Radius))

    if (D<0.0) {
	return INFINITY
    } else {
	var D2=Math.sqrt(D)
	var T2=B+D2

	if (T2 < 0.0) {
	    return INFINITY
	} else {
	    var T1=B-D2
	    if (T1 > 0.0) {
		return T1
	    } else {
		return T2
	    }
	}
    }
}

function ofscene(Orig,Dir,  LN, Scene) {
    if (Scene.TYPE == ST_SPHERE) {
	var Lp=ray_sphere(Orig, Dir, Scene.CENTER, Scene.RADIUS)
	if (Lp >= LN.L){
	    return LN
	} else {
	    return {L:Lp,N:vec_unitise(vec_subtract(vec_add(Orig, multiply_vec(Lp, Dir)),Scene.CENTER))}
	}
    } else if (Scene.TYPE == ST_GROUP) {
	var Lp=ray_sphere(Orig, Dir, Scene.CENTER,  Scene.RADIUS)
	if (Lp>= LN.L) {
	    return LN
	} else {
	    var qLN=LN
	    
	    for (var i in Scene.SCENES) {
		var S=Scene.SCENES[i]
		qLN=ofscene(Orig,Dir, qLN, S)
	    }
	}
	return qLN
    }
}

function intersect(Orig, Dir, Scene) {
    return ofscene(Orig, Dir, {L:INFINITY, N:ZEROVEC}, Scene)
}

function ray_trace(Light, Orig, Dir, Scene) {
    var LN=intersect(Orig, Dir, Scene)

    if (LN.L >= INFINITY) {
	return 0.0
    } else {
	var G=0.0-vec_dot(LN.N, Light)
	if (G<=0.0) {
	    return 0.0
	} else {
	    var OrigP=vec_add(Orig, vec_add(multiply_vec(LN.L, Dir),  multiply_vec(DELTA,LN.N)))
	    var DirP=vec_subtract(ZEROVEC, Light)
	    var LqN=intersect(OrigP, DirP, Scene)
	    if (LqN.L >= INFINITY) {
		return G
	    } else {
		return 0.0
	    }
	}
    }
}

function create(Level, R, X, Y, Z) {
    var Obj={
	TYPE:ST_SPHERE,
	CENTER:{X:X,Y:Y,Z:Z},
	RADIUS:R
    }

    if (Level == 1) {
	return Obj
    } else {
	var Rp = 3.0 * R / Math.sqrt(12.0)
	return { TYPE:ST_GROUP,
		 CENTER:{X:X,Y:Y,Z:Z},
		 RADIUS:3.0*R,
		 SCENES:[
		     Obj,
		     create((Level-1), (0.5*R), X-Rp, Y+Rp, Z-Rp),
		     create((Level-1), (0.5*R), X+Rp, Y+Rp, Z-Rp),
		     create((Level-1), (0.5*R), X-Rp, Y+Rp, Z+Rp),
		     create((Level-1), (0.5*R), X+Rp, Y+Rp, Z+Rp)
		 ]
	       }
    }
}

// ################################################################
function pixel(Eye, X,Y, Scene) {
    var rsum=0
    for (Dx=0; Dx<=(OVERSAMPLESIZE-1); Dx++){
	for (Dy=0; Dy<=(OVERSAMPLESIZE-1); Dy++){
	    rsum=rsum+ray_trace(Eye,
				{X:0.0, Y:0.0, Z:-4.0},
				vec_unitise({ X:X+(Dx/OVERSAMPLESIZE)-(RESOLUTION/2.0),
					      Y:RESOLUTION-1-Y+(Dy/OVERSAMPLESIZE)-(RESOLUTION/2.0),
					      Z:RESOLUTION}),
				Scene)
	}
    }
    return Math.floor(0.5 + 255.0 * (rsum)/(OVERSAMPLESIZE*OVERSAMPLESIZE))
}

// ################################################################
function traceBMPBlob_single(Eye, Scene){
    var pict=new Array();

    for (Y=0; Y<=(RESOLUTION-1); Y++){
	pict[Y] = new Array();
	for (X=0; X<=(RESOLUTION-1); X++){
	    pict[Y][X]=pixel(Eye,X,Y,Scene);
	}
    }

    return array2BMPBlob(RESOLUTION,RESOLUTION, pict);
}

function array2BMPBlob(xsize, ysize, bitmap){
    var bitmapSize=(xsize*4)*ysize
    var fileSize=54+bitmapSize;
    var bmp_ab=new ArrayBuffer(fileSize);
    var bmp_vw = new DataView(bmp_ab);

    // Header
    bmp_vw.setUint16( 0, 0x424D, false);   // Signature ("BM")
    bmp_vw.setUint32( 2, fileSize, true);  // size of the file (bytes)*
    bmp_vw.setUint16( 6, 0, true);         // reserved
    bmp_vw.setUint16( 8, 0, true);         // reserved
    bmp_vw.setUint32(10, 54, true);        // offset of where BMP data lives (54 bytes)

    bmp_vw.setUint32(14, 40, true);        // number of remaining bytes in header from here (40 bytes)
    bmp_vw.setUint32(18, xsize, true);     // the width of the bitmap in pixels*
    bmp_vw.setUint32(22, ysize, true);     // the height of the bitmap in pixels*
    bmp_vw.setUint16(26, 1, true);         // the number of color planes (1)
    bmp_vw.setUint16(28, 32, true);        // 32 bits / pixel
    bmp_vw.setUint32(30, 0, true);         // No compression (0)
    bmp_vw.setUint32(34, bitmapSize, true);// size of the BMP data (bytes)*
    bmp_vw.setUint32(38, 2835, true);      // 2835 pixels/meter - horizontal resolution
    bmp_vw.setUint32(42, 2835, true);      // 2835 pixels/meter - the vertical resolution
    bmp_vw.setUint32(46, 0 , true);        // Number of colors in the palette (keep 0 for 32-bit)
    bmp_vw.setUint32(50, 0 , true);        // 0 important colors (means all colors are important)

    pixels = new Uint8Array(bmp_ab, 54);

    for (Y=0; Y<=(ysize-1); Y++){
	for (X=0; X<=(xsize-1); X++){
	    pos=(((Y*ysize)+X)*4);

	    p=Number(bitmap[ysize-Y-1][X]);    // BMP data is upside down, so render starting at bottom
	    
	    pixels[pos]=p;
	    pixels[pos+1]=p;
	    pixels[pos+2]=p;
	    pixels[pos+3]=0xff;
	}
    }

    return new Blob([bmp_ab], { type: "image/bmp" });
}

// ################################################################
function traceBMPbase64(traceBMPBlobCallback, imageContainer, durationStr){
    var Level=LEVEL // Number of Spheres
    var Eye=vec_unitise({X:-3.0,Y:-3.0,Z:2.0})
    var Scene=create(Level, 1.0, 0.0,-1.0,0.0) // Scene tree

    var startTime=new Date();
    var bmpBlob=traceBMPBlobCallback(Eye, Scene)
    var endTime=new Date();
    var duration=((endTime-startTime)/1000);

    var reader = new window.FileReader();

    reader.onloadend = function() {
        base64data = reader.result;
	document.getElementById(imageContainer).src = base64data;
	document.getElementById(durationStr).innerHTML = duration;
	// console.log("duration="+duration);
    }
    reader.readAsDataURL(bmpBlob);
}

//................................................................
function tracePGMStdout(Eye, Scene){
    var Level=LEVEL // Number of Spheres
    var Eye=vec_unitise({X:-3.0,Y:-3.0,Z:2.0})
    var Scene=create(Level, 1.0, 0.0,-1.0,0.0) // Scene tree

    process.stdout.write("P2\n"+RESOLUTION+" "+RESOLUTION+"\n255\n") 
    for (Y=0; Y<=(RESOLUTION-1); Y++){
	for (X=0; X<=(RESOLUTION-1); X++){
	    process.stdout.write(((X>0)?" ":"")+pixel(Eye,X,Y,Scene));
	}
	process.stdout.write("\n"); 
    }
    return
}
exports.tracePGMStdout=tracePGMStdout
