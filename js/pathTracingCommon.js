var screenTextureShader = {

        uniforms: THREE.UniformsUtils.merge( [
		
                {
                        tTexture0: { type: "t", value: null }
                }
		
        ] ),

        vertexShader: [
                '#version 300 es',
                
                'precision highp float;',
		'precision highp int;',

		'out vec2 vUv;',

		'void main()',
		'{',
			'vUv = uv;',
			'gl_Position = vec4( position, 1.0 );',
		'}'
		
        ].join( '\n' ),

        fragmentShader: [
                '#version 300 es',
                
                'precision highp float;',
		'precision highp int;',
		'precision highp sampler2D;',

                'uniform sampler2D tTexture0;',
                'in vec2 vUv;',
                'out vec4 out_FragColor;',
		
		'void main()',
		'{',	
			'out_FragColor = texture(tTexture0, vUv);',	
		'}'
		
        ].join( '\n' )

};

var screenOutputShader = {

        uniforms: THREE.UniformsUtils.merge( [
		
                {
                        uOneOverSampleCounter: { type: "f", value: 0.0 },
			tTexture0: { type: "t", value: null }
                }
		
        ] ),

        vertexShader: [
                '#version 300 es',
                
                'precision highp float;',
		'precision highp int;',

		'out vec2 vUv;',

		'void main()',
		'{',
			'vUv = uv;',
			'gl_Position = vec4( position, 1.0 );',
		'}'

        ].join( '\n' ),

        fragmentShader: [
                '#version 300 es',
                
                'precision highp float;',
		'precision highp int;',
		'precision highp sampler2D;',

                'uniform float uOneOverSampleCounter;',
		'uniform sampler2D tTexture0;',
		'in vec2 vUv;',
                'out vec4 out_FragColor;',
		
		'void main()',
		'{',
			'vec4 pixelColor = texture(tTexture0, vUv) * uOneOverSampleCounter;',

			'out_FragColor = sqrt(pixelColor);',	
		'}'
		
        ].join( '\n' )

};


THREE.ShaderChunk[ 'pathtracing_uniforms_and_defines' ] = `

uniform bool uCameraIsMoving;
uniform bool uCameraJustStartedMoving;

uniform float uTime;
uniform float uSampleCounter;
uniform float uFrameCounter;
uniform float uULen;
uniform float uVLen;
uniform float uApertureSize;
uniform float uFocusDistance;

uniform vec2 uResolution;

uniform vec3 uRandomVector;

uniform mat4 uCameraMatrix;

uniform sampler2D tPreviousTexture;

in vec2 vUv;
out vec4 out_FragColor;

#define PI               3.14159265358979323
#define TWO_PI           6.28318530717958648
#define FOUR_PI          12.5663706143591729
#define ONE_OVER_PI      0.31830988618379067
#define ONE_OVER_TWO_PI  0.15915494309
#define ONE_OVER_FOUR_PI 0.07957747154594767
#define PI_OVER_TWO      1.57079632679489662
#define ONE_OVER_THREE   0.33333333333333333
#define E                2.71828182845904524
#define INFINITY         1000000.0

#define POINT_LIGHT -1
#define LIGHT 0
#define DIFF 1
#define REFR 2
#define SPEC 3
#define COAT 4
#define CARCOAT 5
#define TRANSLUCENT 6
#define SPECSUB 7
#define CHECK 8
#define WATER 9
#define WOOD 10
#define SEAFLOOR 11
#define TERRAIN 12
#define CLOTH 13
#define LIGHTWOOD 14
#define DARKWOOD 15
#define PAINTING 16

`;

THREE.ShaderChunk[ 'pathtracing_skymodel_defines' ] = `

#define TURBIDITY 0.3
#define RAYLEIGH_COEFFICIENT 2.0

#define MIE_COEFFICIENT 0.05
#define MIE_DIRECTIONAL_G 0.76

// constants for atmospheric scattering
#define THREE_OVER_SIXTEENPI 0.05968310365946075
#define ONE_OVER_FOURPI 0.07957747154594767

// wavelength of used primaries, according to preetham
#define LAMBDA vec3( 680E-9, 550E-9, 450E-9 )
#define TOTAL_RAYLEIGH vec3( 5.804542996261093E-6, 1.3562911419845635E-5, 3.0265902468824876E-5 )

// mie stuff
// K coefficient for the primaries
#define K vec3(0.686, 0.678, 0.666)
#define MIE_V 4.0
#define MIE_CONST vec3( 1.8399918514433978E14, 2.7798023919660528E14, 4.0790479543861094E14 )

// optical length at zenith for molecules
#define RAYLEIGH_ZENITH_LENGTH 8400.0
#define MIE_ZENITH_LENGTH 1250.0
#define UP_VECTOR vec3(0.0, 1.0, 0.0)

#define SUN_INTENSITY 20.0 //800.0 if Uncharted2ToneMap is used
#define SUN_ANGULAR_DIAMETER_COS 0.99983194915 // 66 arc seconds -> degrees, and the cosine of that
#define CUTOFF_ANGLE 1.66 // original value (PI / 1.9) 

`;


THREE.ShaderChunk[ 'pathtracing_plane_intersect' ] = `

//-----------------------------------------------------------------------
float PlaneIntersect( vec4 pla, Ray r )
//-----------------------------------------------------------------------
{
	vec3 n = normalize(pla.xyz);
	float denom = dot(n, r.direction);

	// uncomment the following if single-sided plane is desired
	//if (denom >= 0.0) return INFINITY;
	
        vec3 pOrO = (pla.w * n) - r.origin; 
        float result = dot(pOrO, n) / denom;
	return (result > 0.0) ? result : INFINITY;
}

`;

THREE.ShaderChunk[ 'pathtracing_disk_intersect' ] = `

//-----------------------------------------------------------------------
float DiskIntersect( float radius, vec3 pos, vec3 normal, Ray r )
//-----------------------------------------------------------------------
{
	vec3 n = normalize(-normal);
	vec3 pOrO = pos - r.origin;
	float denom = dot(n, r.direction);
	// use the following for one-sided disk
	//if (denom <= 0.0) return INFINITY;
	
        float result = dot(pOrO, n) / denom;
	if (result < 0.0) return INFINITY;

        vec3 intersectPos = r.origin + r.direction * result;
	vec3 v = intersectPos - pos;
	float d2 = dot(v,v);
	float radiusSq = radius * radius;
	if (d2 > radiusSq)
		return INFINITY;
		
	return result;
}

`;

THREE.ShaderChunk[ 'pathtracing_rectangle_intersect' ] = `

//------------------------------------------------------------------------------------
float RectangleIntersect( vec3 pos, vec3 normal, float radiusU, float radiusV, Ray r )
//------------------------------------------------------------------------------------
{
	float dt = dot(-normal, r.direction);

	// use the following for one-sided rectangle
	if (dt < 0.0) return INFINITY;

	float t = dot(-normal, pos - r.origin) / dt;
	if (t < 0.0) return INFINITY;
	
	vec3 hit = r.origin + r.direction * t;
	vec3 vi = hit - pos;

	vec3 u = normalize(cross( abs(normal.y) < 0.9 ? vec3(0, 1, 0) : vec3(0, 0, 1), normal));
	vec3 v = cross(normal, u);

	if (abs(dot(u, vi)) > radiusU) return INFINITY;
	if (abs(dot(v, vi)) > radiusV) return INFINITY;
	
	return t;
}

`;

THREE.ShaderChunk[ 'pathtracing_sphere_intersect' ] = `

/*
bool solveQuadratic(float A, float B, float C, out float t0, out float t1)
{
	float discrim = B*B-4.0*A*C;
    	
	if ( discrim < 0.0 )
        	return false;
	
    	float A2 = 2.0 * A;
	float rootDiscrim = sqrt( discrim );
    
	float t_0 = (-B-rootDiscrim)/A2;
	float t_1 = (-B+rootDiscrim)/A2;

	t0 = min( t_0, t_1 );
	t1 = max( t_0, t_1 );
    
	return true;
}
*/

bool solveQuadratic(float A, float B, float C, out float t0, out float t1)
{
	float discrim = B*B-4.0*A*C;
    
	if ( discrim < 0.0 )
        	return false;
    
	float rootDiscrim = sqrt( discrim );

	float Q = (B > 0.0) ? -0.5 * (B + rootDiscrim) : -0.5 * (B - rootDiscrim); 
	float t_0 = Q / A; 
	float t_1 = C / Q;
	
	t0 = min( t_0, t_1 );
	t1 = max( t_0, t_1 );
    
	return true;
}


//-----------------------------------------------------------------------
float SphereIntersect( float rad, vec3 pos, Ray ray )
//-----------------------------------------------------------------------
{
	float t = INFINITY;
	float t0, t1;
	vec3 L = ray.origin - pos;
	float a = dot( ray.direction, ray.direction );
	float b = 2.0 * dot( ray.direction, L );
	float c = dot( L, L ) - (rad * rad);

	if (!solveQuadratic( a, b, c, t0, t1))
		return INFINITY;
	
	if ( t1 > 0.0 )
		t = t1;
		
	if ( t0 > 0.0 )
		t = t0;
	
	return t;
}

`;

THREE.ShaderChunk[ 'pathtracing_ellipsoid_intersect' ] = `

//-----------------------------------------------------------------------
float EllipsoidIntersect( vec3 radii, vec3 pos, Ray r )
//-----------------------------------------------------------------------
{
	float t = INFINITY;
	float t0, t1;
	vec3 oc = r.origin - pos;
	vec3 oc2 = oc*oc;
	vec3 ocrd = oc*r.direction;
	vec3 rd2 = r.direction*r.direction;
	vec3 invRad = 1.0/radii;
	vec3 invRad2 = invRad*invRad;
	
	// quadratic equation coefficients
	float a = dot(rd2, invRad2);
	float b = 2.0*dot(ocrd, invRad2);
	float c = dot(oc2, invRad2) - 1.0;

	if (!solveQuadratic( a, b, c, t0, t1))
		return INFINITY;
	
	if ( t1 > 0.0 )
		t = t1;
		
	if ( t0 > 0.0 )
		t = t0;
	
	return t;
}

`;

THREE.ShaderChunk[ 'pathtracing_opencylinder_intersect' ] = `

//---------------------------------------------------------------------------
float OpenCylinderIntersect( vec3 p0, vec3 p1, float rad, Ray r, out vec3 n )
//---------------------------------------------------------------------------
{
	float r2=rad*rad;
	
	vec3 dp=p1-p0;
	vec3 dpt=dp/dot(dp,dp);
	
	vec3 ao=r.origin-p0;
	vec3 aoxab=cross(ao,dpt);
	vec3 vxab=cross(r.direction,dpt);
	float ab2=dot(dpt,dpt);
	float a=2.0*dot(vxab,vxab);
	float ra=1.0/a;
	float b=2.0*dot(vxab,aoxab);
	float c=dot(aoxab,aoxab)-r2*ab2;
	
	float det=b*b-2.0*a*c;
	
	if(det<0.0)
	return INFINITY;
	
	det=sqrt(det);
	
	float t = INFINITY;
	
	float t0=(-b-det)*ra;
	float t1=(-b+det)*ra;
	
	vec3 ip;
	vec3 lp;
	float ct;
	
	if (t1 > 0.0)
	{
		ip=r.origin+r.direction*t1;
		lp=ip-p0;
		ct=dot(lp,dpt);
		if((ct>0.0)&&(ct<1.0))
		{
			t = t1;
		     	n=(p0+dp*ct)-ip;
		}
		
	}
	
	if (t0 > 0.0)
	{
		ip=r.origin+r.direction*t0;
		lp=ip-p0;
		ct=dot(lp,dpt);
		if((ct>0.0)&&(ct<1.0))
		{
			t = t0;
			n=ip-(p0+dp*ct);
		}
		
	}
	
	return t;
}

`;

THREE.ShaderChunk[ 'pathtracing_cappedcylinder_intersect' ] = `

//-----------------------------------------------------------------------------
float CappedCylinderIntersect( vec3 p0, vec3 p1, float rad, Ray r, out vec3 n )
//-----------------------------------------------------------------------------
{
	float r2=rad*rad;
	
	vec3 dp=p1-p0;
	vec3 dpt=dp/dot(dp,dp);
	
	vec3 ao=r.origin-p0;
	vec3 aoxab=cross(ao,dpt);
	vec3 vxab=cross(r.direction,dpt);
	float ab2=dot(dpt,dpt);
	float a=2.0*dot(vxab,vxab);
	float ra=1.0/a;
	float b=2.0*dot(vxab,aoxab);
	float c=dot(aoxab,aoxab)-r2*ab2;
	
	float det=b*b-2.0*a*c;
	
	if(det<0.0)
		return INFINITY;
	
	det=sqrt(det);
	
	float t0=(-b-det)*ra;
	float t1=(-b+det)*ra;
	
	vec3 ip;
	vec3 lp;
	float ct;
	float result = INFINITY;
	
	// Cylinder caps
	// disk0
	vec3 diskNormal = normalize(dp);
	float denom = dot(diskNormal, r.direction);
	vec3 pOrO = p0 - r.origin;
	float tDisk0 = dot(pOrO, diskNormal) / denom;
	if (tDisk0 > 0.0)
	{
		vec3 intersectPos = r.origin + r.direction * tDisk0;
		vec3 v = intersectPos - p0;
		float d2 = dot(v,v);
		if (d2 <= r2)
		{
			result = tDisk0;
			n = diskNormal;
		}
	}
	
	// disk1
	denom = dot(diskNormal, r.direction);
	pOrO = p1 - r.origin;
	float tDisk1 = dot(pOrO, diskNormal) / denom;
	if (tDisk1 > 0.0)
	{
		vec3 intersectPos = r.origin + r.direction * tDisk1;
		vec3 v = intersectPos - p1;
		float d2 = dot(v,v);
		if (d2 <= r2 && tDisk1 < result)
		{
			result = tDisk1;
			n = diskNormal;
		}
	}
	
	// Cylinder body
	if (t1 > 0.0)
	{
		ip=r.origin+r.direction*t1;
		lp=ip-p0;
		ct=dot(lp,dpt);
		if(ct>0.0 && ct<1.0 && t1<result)
		{
			result = t1;
		     	n=(p0+dp*ct)-ip;
		}
		
	}
	
	if (t0 > 0.0)
	{
		ip=r.origin+r.direction*t0;
		lp=ip-p0;
		ct=dot(lp,dpt);
		if(ct>0.0 && ct<1.0 && t0<result)
		{
			result = t0;
			n=ip-(p0+dp*ct);
		}
		
	}
	
	return result;
}

`;

THREE.ShaderChunk[ 'pathtracing_cone_intersect' ] = `

//----------------------------------------------------------------------------
float ConeIntersect( vec3 p0, float r0, vec3 p1, float r1, Ray r, out vec3 n )
//----------------------------------------------------------------------------   
{
	r0 += 0.1;
	float t = INFINITY;
	vec3 locX;
	vec3 locY;
	vec3 locZ=-(p1-p0)/(1.0 - r1/r0);
	
	Ray ray = r;
	ray.origin-=p0-locZ;
	
	if(abs(locZ.x)<abs(locZ.y))
		locX=vec3(1,0,0);
	else
		locX=vec3(0,1,0);
		
	float len=length(locZ);
	locZ=normalize(locZ)/len;
	locY=normalize(cross(locX,locZ))/r0;
	locX=normalize(cross(locY,locZ))/r0;
	
	mat3 tm;
	tm[0]=locX;
	tm[1]=locY;
	tm[2]=locZ;
	
	ray.direction*=tm;
	ray.origin*=tm;
	
	float dx=ray.direction.x;
	float dy=ray.direction.y;
	float dz=ray.direction.z;
	
	float x0=ray.origin.x;
	float y0=ray.origin.y;
	float z0=ray.origin.z;
	
	float x02=x0*x0;
	float y02=y0*y0;
	float z02=z0*z0;
	
	float dx2=dx*dx;
	float dy2=dy*dy;
	float dz2=dz*dz;
	
	float det=(
		-2.0*x0*dx*z0*dz
		+2.0*x0*dx*y0*dy
		-2.0*z0*dz*y0*dy
		+dz2*x02
		+dz2*y02
		+dx2*z02
		+dy2*z02
		-dy2*x02
		-dx2*y02
        );
	
	if(det<0.0)
		return INFINITY;
		
	float t0=(-x0*dx+z0*dz-y0*dy-sqrt(abs(det)))/(dx2-dz2+dy2);
	float t1=(-x0*dx+z0*dz-y0*dy+sqrt(abs(det)))/(dx2-dz2+dy2);
	vec3 pt0=ray.origin+t0*ray.direction;
	vec3 pt1=ray.origin+t1*ray.direction;
	
        if(t1>0.0 && pt1.z>r1/r0 && pt1.z<1.0)
	{
		t=t1;
		n=pt1;
		n.z=0.0;
		n=normalize(n);
		n.z=-pt1.z/abs(pt1.z);
		n=normalize(n);
		n=tm*-n;
	}
	
	if(t0>0.0 && pt0.z>r1/r0 && pt0.z<1.0)
	{
		t=t0;
		n=pt0;
		n.z=0.0;
		n=normalize(n);
		n.z=-pt0.z/abs(pt0.z);
		n=normalize(n);
		n=tm*n;
	}
	
	return t;	
}

`;


THREE.ShaderChunk[ 'pathtracing_capsule_intersect' ] = `

//-------------------------------------------------------------------------------
float CapsuleIntersect( vec3 p0, float r0, vec3 p1, float r1, Ray r, out vec3 n )
//-------------------------------------------------------------------------------
{
	/*
	// used for ConeIntersect below, if different radius sphere end-caps are desired
	vec3 l  = p1-p0;
	float ld = length(l);
	l=l/ld;
	float d= r0-r1;
	float sa = d/ld;
	float h0 = r0*sa;
	float h1 = r1*sa;
	float cr0 = sqrt(r0*r0-h0*h0);
	float cr1 = sqrt(r1*r1-h1*h1);
	vec3 coneP0=p0+l*h0;
	vec3 coneP1=p1+l*h1;
	*/
	
	float t0=INFINITY;
	    
	float t1;
	vec3 uv1;
	vec3 n1;
	//t1 = ConeIntersect(coneP0,cr0,coneP1,cr1,r,n1);
	t1 = OpenCylinderIntersect(p0,p1,r0,r,n1);
	if(t1<t0)
	{
		t0=t1;
		n=n1;
	}
	t1 = SphereIntersect(r0,p0,r);
	if(t1<t0)
	{
		t0=t1;
		n=(r.origin + r.direction * t1) - p0;
	}
	t1 = SphereIntersect(r1,p1,r);
	if(t1<t0)
	{
		t0=t1;
		n=(r.origin + r.direction * t1) - p1;
	}
	    
	return t0;
}

`;

THREE.ShaderChunk[ 'pathtracing_paraboloid_intersect' ] = `

//------------------------------------------------------------------------------
float ParaboloidIntersect( float rad, float height, vec3 pos, Ray r, out vec3 n )
//------------------------------------------------------------------------------
{
	vec3 rd = r.direction;
	vec3 ro = r.origin - pos;
	float k = height / (rad * rad);
	
	// quadratic equation coefficients
	float a = k * (rd.x * rd.x + rd.z * rd.z);
	float b = k * 2.0 * (rd.x * ro.x + rd.z * ro.z) - rd.y;
	float c = k * (ro.x * ro.x + ro.z * ro.z) - ro.y;

	float t0, t1;
	if (!solveQuadratic( a, b, c, t0, t1))
		return INFINITY;
	
	vec3 ip1, ip2;
	float result = INFINITY;
	
	if (t1 > 0.0)
	{	
		ip2 = ro + rd * t1;
		if (ip2.y < height)
		{
			n = vec3( -2.0 * ip2.x, 2.0 * ip2.y, -2.0 * ip2.z );
			result = t1;
		}		
	}
	
	if (t0 > 0.0)
	{
		ip1 = ro + rd * t0;
		if (ip1.y < height)
		{
			n = vec3( 2.0 * ip1.x, -2.0 * ip1.y, 2.0 * ip1.z );
			result = t0;
		}		
	}
	
	if( t0 > 0.0 && t1 > 0.0)
	{
		float dist1 = distance(ro,ip1);
		float dist2 = distance(ro,ip2);
		
		if (dist2 < dist1 && ip2.y < height)
		{
			n = vec3( -2.0 * ip2.x, 2.0 * ip2.y, -2.0 * ip2.z );
			result = t1;
		}	
		
		if (dist1 < dist2 && ip1.y < height)
		{
			n = vec3( 2.0 * ip1.x, -2.0 * ip1.y, 2.0 * ip1.z );
			result = t0;
		}			
	}
	
	return result;	
}

`;

THREE.ShaderChunk[ 'pathtracing_torus_intersect' ] = `

float map_Torus( in vec3 pos )
{
	return length( vec2(length(pos.xz)-torii[0].radius0,pos.y) )-torii[0].radius1;
}

vec3 calcNormal_Torus( in vec3 pos )
{
	// epsilon = a small number
	vec2 e = vec2(1.0,-1.0)*0.5773*0.0002;

	return normalize( e.xyy*map_Torus( pos + e.xyy ) + 
			  e.yyx*map_Torus( pos + e.yyx ) + 
			  e.yxy*map_Torus( pos + e.yxy ) + 
			  e.xxx*map_Torus( pos + e.xxx ) );
}

/* 
Thanks to koiava for the ray marching strategy! https://www.shadertoy.com/user/koiava 
*/
float TorusIntersect( float rad0, float rad1, Ray r )
{	
	vec3 n;
	float d = CappedCylinderIntersect( vec3(0,rad1,0), vec3(0,-rad1,0), rad0+rad1, r, n );
	if (d == INFINITY)
		return INFINITY;
	
	vec3 pos = r.origin;
	float t = 0.0;
	float torusFar = d + (rad0 * 2.0) + (rad1 * 2.0);
	for (int i = 0; i < 200; i++)
	{
		d = map_Torus(pos);
		if (d < 0.001 || t > torusFar) break;
		pos += r.direction * d;
		t += d;
	}
	
	return (d<0.001) ? t : INFINITY;
}

/*
// borrowed from iq: https://www.shadertoy.com/view/4sBGDy
//-----------------------------------------------------------------------
float TorusIntersect( float rad0, float rad1, vec3 pos, Ray ray )
//-----------------------------------------------------------------------
{
	vec3 rO = ray.origin - pos;
	vec3 rD = ray.direction;
	
	float Ra2 = rad0*rad0;
	float ra2 = rad1*rad1;
	
	float m = dot(rO,rO);
	float n = dot(rO,rD);
		
	float k = (m - ra2 - Ra2) * 0.5;
	float a = n;
	float b = n*n + Ra2*rD.z*rD.z + k;
	float c = k*n + Ra2*rO.z*rD.z;
	float d = k*k + Ra2*rO.z*rO.z - Ra2*ra2;
	
	float a2 = a * a;
	float p = -3.0*a2     + 2.0*b;
	float q =  2.0*a2*a   - 2.0*a*b   + 2.0*c;
	float r = -3.0*a2*a2 + 4.0*a2*b - 8.0*a*c + 4.0*d;
	p *= ONE_OVER_THREE;
	r *= ONE_OVER_THREE;
	float p2 = p * p;
	float Q = p2 + r;
	float R = 3.0*r*p - p2*p - q*q;
	
	float h = R*R - Q*Q*Q;
	float z = 0.0;
	if( h < 0.0 )
	{
		float sQ = sqrt(Q);
		z = 2.0*sQ*cos( acos(R/(sQ*Q)) * ONE_OVER_THREE );
	}
	else
	{
		float sQ = pow( sqrt(h) + abs(R), ONE_OVER_THREE );
		z = sign(R)*abs( sQ + Q/sQ );
	}
	
	z = p - z;
		
	float d1 = z   - 3.0*p;
	float d2 = z*z - 3.0*r;
	if( abs(d1)<0.5 ) // originally < 0.0001, but this was too precise and caused holes when viewed from the side
	{
		if( d2<0.0 ) return INFINITY;
		d2 = sqrt(d2);
	}
	else
	{
		if( d1<0.0 ) return INFINITY;
		d1 = sqrt( d1*0.5 );
		d2 = q/d1;
	}
	
	float result = INFINITY;
	float d1SqMinusZ = d1*d1 - z;
	
	h = d1SqMinusZ - d2;
	if( h>0.0 )
	{
		h = sqrt(h);
		float t1 = d1 - h - a;
		float t2 = d1 + h - a;
		if( t2>0.0 ) result=t2;
		if( t1>0.0 ) result=t1;
	}
	h = d1SqMinusZ + d2;
	if( h>0.0 )
	{
		h = sqrt(h);
		float t1 = -d1 - h - a;
		float t2 = -d1 + h - a;
		if( t2>0.0 ) result=min(result,t2);
		if( t1>0.0 ) result=min(result,t1); 
	}
	return result;
}
*/

`;

THREE.ShaderChunk[ 'pathtracing_quad_intersect' ] = `

//----------------------------------------------------------------------------
float QuadIntersect( vec3 v0, vec3 v1, vec3 v2, vec3 v3, vec3 normal, Ray r )
//----------------------------------------------------------------------------
{
	vec3 u, v, n;    // triangle vectors
	vec3 w0, w, x;   // ray and intersection vectors
	float rt, a, b;  // params to calc ray-plane intersect
	
	// get first triangle edge vectors and plane normal
	v = v2 - v0;
	u = v1 - v0; // switched u and v names to save calculation later below
	//n = cross(v, u); // switched u and v names to save calculation later below
	n = -normal; // can avoid cross product if normal is already known
	    
	w0 = r.origin - v0;
	a = -dot(n,w0);
	b = dot(n, r.direction);
	if (b < 0.0001)   // ray is parallel to quad plane
		return INFINITY;

	// get intersect point of ray with quad plane
	rt = a / b;
	if (rt < 0.0)          // ray goes away from quad
		return INFINITY;   // => no intersect
	    
	x = r.origin + rt * r.direction; // intersect point of ray and plane

	// is x inside first Triangle?
	float uu, uv, vv, wu, wv, D;
	uu = dot(u,u);
	uv = dot(u,v);
	vv = dot(v,v);
	w = x - v0;
	wu = dot(w,u);
	wv = dot(w,v);
	D = 1.0 / (uv * uv - uu * vv);

	// get and test parametric coords
	float s, t;
	s = (uv * wv - vv * wu) * D;
	if (s >= 0.0 && s <= 1.0)
	{
		t = (uv * wu - uu * wv) * D;
		if (t >= 0.0 && (s + t) <= 1.0)
		{
			return rt;
		}
	}
	
	// is x inside second Triangle?
	u = v3 - v0;
	///v = v2 - v0;  //optimization - already calculated above

	uu = dot(u,u);
	uv = dot(u,v);
	///vv = dot(v,v);//optimization - already calculated above
	///w = x - v0;   //optimization - already calculated above
	wu = dot(w,u);
	///wv = dot(w,v);//optimization - already calculated above
	D = 1.0 / (uv * uv - uu * vv);

	// get and test parametric coords
	s = (uv * wv - vv * wu) * D;
	if (s >= 0.0 && s <= 1.0)
	{
		t = (uv * wu - uu * wv) * D;
		if (t >= 0.0 && (s + t) <= 1.0)
		{
			return rt;
		}
	}


	return INFINITY;
}

`;

THREE.ShaderChunk[ 'pathtracing_box_intersect' ] = `

//--------------------------------------------------------------------------
float BoxIntersect( vec3 minCorner, vec3 maxCorner, Ray r, out vec3 normal )
//--------------------------------------------------------------------------
{
	vec3 invDir = 1.0 / r.direction;
	vec3 near = (minCorner - r.origin) * invDir;
	vec3 far  = (maxCorner - r.origin) * invDir;
	
	vec3 tmin = min(near, far);
	vec3 tmax = max(near, far);
	
	float t0 = max( max(tmin.x, tmin.y), tmin.z);
	float t1 = min( min(tmax.x, tmax.y), tmax.z);
	
	if (t0 > t1) return INFINITY;

	float result = INFINITY;
	
	if (t1 > 0.0) // if we are inside the box
	{
		normal = -sign(r.direction) * step(tmax, tmax.yzx) * step(tmax, tmax.zxy);
		result = t1;
	}
	if (t0 > 0.0) // if we are outside the box
	{
		normal = -sign(r.direction) * step(tmin.yzx, tmin) * step(tmin.zxy, tmin);
		result = t0;	
	}
			
	return result;
}

`;

THREE.ShaderChunk[ 'pathtracing_boundingbox_intersect' ] = `

//--------------------------------------------------------------------------------------
float BoundingBoxIntersect( vec3 minCorner, vec3 maxCorner, vec3 rayOrigin, vec3 invDir )
//--------------------------------------------------------------------------------------
{
	vec3 near = (minCorner - rayOrigin) * invDir;
	vec3 far  = (maxCorner - rayOrigin) * invDir;
	
	vec3 tmin = min(near, far);
	vec3 tmax = max(near, far);
	
	float t0 = max( max(tmin.x, tmin.y), tmin.z);
	float t1 = min( min(tmax.x, tmax.y), tmax.z);

	if (t0 > t1) return INFINITY;
	
	float result = INFINITY;
	
	if (t1 > 0.0) result = t1;
	if (t0 > 0.0) result = t0;
	
	return result;
}

`;

THREE.ShaderChunk[ 'pathtracing_triangle_intersect' ] = `

//---------------------------------------------------------
float TriangleIntersect( vec3 v0, vec3 v1, vec3 v2, Ray r )
//---------------------------------------------------------
{
	vec3 edge1 = v1 - v0;
	vec3 edge2 = v2 - v0;
	vec3 pvec = cross(r.direction, edge2);
	float det = 1.0 / dot(edge1, pvec);

	// comment out the following line if double-sided triangles are wanted, or
	// uncomment the following line if back-face culling is desired (single-sided triangles)
	//if (det <= 0.0) return INFINITY;

	vec3 tvec = r.origin - v0;
	float u = dot(tvec, pvec) * det;

	if (u < 0.0 || u > 1.0)
		return INFINITY;

	vec3 qvec = cross(tvec, edge1);
	float v = dot(r.direction, qvec) * det;

	if (v < 0.0 || u + v > 1.0)
		return INFINITY;

	return dot(edge2, qvec) * det;
}

`;

THREE.ShaderChunk[ 'pathtracing_bvhTriangle_intersect' ] = `

//-------------------------------------------------------------------------------------------
float BVH_TriangleIntersect( vec3 v0, vec3 v1, vec3 v2, Ray r, out float u, out float v )
//-------------------------------------------------------------------------------------------
{
	vec3 edge1 = v1 - v0;
	vec3 edge2 = v2 - v0;
	vec3 pvec = cross(r.direction, edge2);
	float det = 1.0 / dot(edge1, pvec);

	// comment out the following line if double-sided triangles are wanted, or
	// uncomment the following line if back-face culling is desired (single-sided triangles)
	//if (det < 0.0) return INFINITY;

	vec3 tvec = r.origin - v0;
	u = dot(tvec, pvec) * det;

	if (u < 0.0 || u > 1.0) return INFINITY;

	vec3 qvec = cross(tvec, edge1);
	v = dot(r.direction, qvec) * det;

	if (v < 0.0 || u + v > 1.0) return INFINITY;

	return dot(edge2, qvec) * det;
}

`;

THREE.ShaderChunk[ 'pathtracing_physical_sky_functions' ] = `

float RayleighPhase(float cosTheta)
{
	return THREE_OVER_SIXTEENPI * (1.0 + (cosTheta * cosTheta));
}

float hgPhase(float cosTheta, float g)
{
        float g2 = g * g;
        float inverse = 1.0 / pow(max(0.0, 1.0 - 2.0 * g * cosTheta + g2), 1.5);
	return ONE_OVER_FOURPI * ((1.0 - g2) * inverse);
}

vec3 totalMie()
{
	float c = (0.2 * TURBIDITY) * 10E-18;
	return 0.434 * c * MIE_CONST;
}

float SunIntensity(float zenithAngleCos)
{
	return SUN_INTENSITY * max( 0.0, 1.0 - exp( -( CUTOFF_ANGLE - acos(zenithAngleCos) ) ) );
}

vec3 Get_Sky_Color(Ray r, vec3 sunDirection)
{
	
    	vec3 viewDir = normalize(r.direction);
	
	/* most of the following code is borrowed from the three.js shader file: SkyShader.js */

    	// Cosine angles
	float cosViewSunAngle = max(0.001, dot(viewDir, sunDirection));
    	float cosSunUpAngle = dot(sunDirection, UP_VECTOR); // allowed to be negative: + is daytime, - is nighttime
    	float cosUpViewAngle = max(0.001, dot(UP_VECTOR, viewDir)); // cannot be 0, used as divisor
	
        // Get sun intensity based on how high in the sky it is
    	float sunE = SunIntensity(cosSunUpAngle);
        
	// extinction (absorbtion + out scattering)
	// rayleigh coefficients
    	vec3 rayleighAtX = TOTAL_RAYLEIGH * RAYLEIGH_COEFFICIENT;
    
	// mie coefficients
	vec3 mieAtX = totalMie() * MIE_COEFFICIENT;  
    
	// optical length
	float zenithAngle = 1.0 / cosUpViewAngle;
    
	float rayleighOpticalLength = RAYLEIGH_ZENITH_LENGTH * zenithAngle;
	float mieOpticalLength = MIE_ZENITH_LENGTH * zenithAngle;

	// combined extinction factor	
	vec3 Fex = exp(-(rayleighAtX * rayleighOpticalLength + mieAtX * mieOpticalLength));

	// in scattering
	vec3 rayleighXtoEye = rayleighAtX * RayleighPhase(cosViewSunAngle);
	vec3 mieXtoEye = mieAtX * hgPhase(cosViewSunAngle, MIE_DIRECTIONAL_G);
     
    	vec3 totalLightAtX = rayleighAtX + mieAtX;
    	vec3 lightFromXtoEye = rayleighXtoEye + mieXtoEye; 
    
    	vec3 somethingElse = sunE * (lightFromXtoEye / totalLightAtX);
    
    	vec3 sky = somethingElse * (1.0 - Fex);
	float oneMinusCosSun = 1.0 - cosSunUpAngle;
    	sky *= mix( vec3(1.0), pow(somethingElse * Fex,vec3(0.5)), 
	    clamp(oneMinusCosSun * oneMinusCosSun * oneMinusCosSun * oneMinusCosSun * oneMinusCosSun, 0.0, 1.0) );

	// composition + solar disc
    	float sundisk = smoothstep(SUN_ANGULAR_DIAMETER_COS - 0.0001, SUN_ANGULAR_DIAMETER_COS, cosViewSunAngle);
	vec3 sun = (sunE * SUN_INTENSITY * Fex) * sundisk;
	
	return sky + sun;
}

`;

THREE.ShaderChunk[ 'pathtracing_random_functions' ] = `

// from iq https://www.shadertoy.com/view/4tXyWN
float rand( inout uvec2 seed )
{
	seed += uvec2(1);

    	uvec2 q = 1103515245U * ( (seed >> 1U) ^ (seed.yx) );
    	uint  n = 1103515245U * ( (q.x) ^ (q.y >> 3U) );
	return float(n) * (1.0 / float(0xffffffffU));
}

vec3 randomSphereDirection( inout uvec2 seed )
{
    	vec2 r = vec2(rand(seed), rand(seed)) * TWO_PI;
	return vec3( sin(r.x) * vec2(sin(r.y), cos(r.y)), cos(r.x) );	
}

vec3 randomDirectionInHemisphere( vec3 nl, inout uvec2 seed )
{
	float up = rand(seed); 
    	float over = sqrt(1.0 - up * up); //uniform distribution
	float around = rand(seed) * TWO_PI;
	vec3 u = normalize( cross( abs(nl.y) < 0.9 ? vec3(0, 1, 0) : vec3(0, 0, 1), nl ) );
	vec3 v = cross(nl, u);
	return normalize(cos(around) * over * u + sin(around) * over * v + up * nl); //uniform distribution
}

vec3 randomCosWeightedDirectionInHemisphere( vec3 nl, inout uvec2 seed )
{
	vec2 uv = vec2(rand(seed), rand(seed));
	float r1 = TWO_PI * uv.x;
	float r2 = uv.y;
	float r2s = sqrt(r2);

	vec3 w = nl;
	vec3 u;
	if (abs(w.x) > 0.1)
		u = cross(vec3( 0.0f, 1.0f, 0.0f ), w);
	else
		u = cross(vec3( 1.0f, 0.0f, 0.0f ), w);

	u = normalize(u);
	vec3 v = cross(w, u);
	return normalize(u*cos(r1)*r2s + v*sin(r1)*r2s + w*sqrt(1.0 - r2));
}

`;

THREE.ShaderChunk[ 'pathtracing_direct_lighting_sphere' ] = `

vec3 calcDirectLightingSphere(vec3 mask, vec3 x, vec3 nl, Sphere light, inout uvec2 seed)
{
	vec3 dirLight = vec3(0.0);
	Intersection shadowIntersec;
	
	// cast shadow ray from intersection point
	vec3 randPointOnLight = light.position + (randomSphereDirection(seed) * light.radius);
	vec3 srDir = normalize(randPointOnLight - x);
		
	Ray shadowRay = Ray(x, srDir);
	shadowRay.origin += nl;
	float st = SceneIntersect(shadowRay, shadowIntersec);
	if ( shadowIntersec.type == light.type )
	{
		float r2 = light.radius * light.radius;
		vec3 d = randPointOnLight - x;
		float d2 = dot(d, d);
		float cos_a_max = sqrt(1.0 - clamp( r2 / d2, 0.0, 1.0));
                float weight = 2.0 * (1.0 - cos_a_max);
                dirLight = mask * light.emission * weight * max(0.0, dot(srDir, nl));
	}
	
	return dirLight;
}

`;

THREE.ShaderChunk[ 'pathtracing_direct_lighting_quad' ] = `

vec3 calcDirectLightingQuad(vec3 mask, vec3 x, vec3 nl, Quad light, inout uvec2 seed)
{
	vec3 dirLight = vec3(0.0);
	Intersection shadowIntersec;
	vec3 randPointOnLight;
	randPointOnLight.x = mix(light.v0.x, light.v1.x, rand(seed));
	randPointOnLight.y = light.v0.y;
	randPointOnLight.z = mix(light.v0.z, light.v3.z, rand(seed));
	vec3 srDir = normalize(randPointOnLight - x);
		
	// cast shadow ray from intersection point	
	Ray shadowRay = Ray(x, srDir);
	shadowRay.origin += nl;
	float st = SceneIntersect(shadowRay, shadowIntersec);
	if ( shadowIntersec.type == LIGHT )
	{
		float r2 = distance(light.v0, light.v1) * distance(light.v0, light.v3);
		vec3 d = randPointOnLight - x;
		float d2 = dot(d, d);
		float weight = -dot(srDir, normalize(shadowIntersec.normal)) * r2 / d2;
		float nlDotSrDir = max(dot(nl, srDir), 0.0);
		dirLight = mask * light.emission * nlDotSrDir * clamp(weight, 0.0, 1.0);
	}

	return dirLight;
}

`;

THREE.ShaderChunk[ 'pathtracing_sample_sphere_light' ] = `

float sampleSphereLight(vec3 x, vec3 nl, out vec3 dirToLight, Sphere light, inout uvec2 seed)
{
	vec3 randPointOnLight = light.position + (randomSphereDirection(seed) * light.radius);
	dirToLight = randPointOnLight - x;
	
	float r2 = light.radius * light.radius;
	float d2 = dot(dirToLight, dirToLight);
	float cos_a_max = sqrt(1.0 - clamp( r2 / d2, 0.0, 1.0));

	dirToLight = normalize(dirToLight);
	float dotNlRayDir = max(0.0, dot(nl, dirToLight));
	
	return 2.0 * (1.0 - cos_a_max) * dotNlRayDir;
}

`;

THREE.ShaderChunk[ 'pathtracing_sample_quad_light' ] = `

float sampleQuadLight(vec3 x, vec3 nl, out vec3 dirToLight, Quad light, inout uvec2 seed)
{
	vec3 randPointOnLight;
	randPointOnLight.x = mix(light.v0.x, light.v1.x, rand(seed));
	randPointOnLight.y = light.v0.y;
	randPointOnLight.z = mix(light.v0.z, light.v3.z, rand(seed));
	dirToLight = randPointOnLight - x;
	float r2 = distance(light.v0, light.v1) * distance(light.v0, light.v3);
	float d2 = dot(dirToLight, dirToLight);
	float cos_a_max = sqrt(1.0 - clamp( r2 / d2, 0.0, 1.0));

	dirToLight = normalize(dirToLight);
	float dotNlRayDir = max(0.0, dot(nl, dirToLight)); 
	return 2.0 * (1.0 - cos_a_max) * max(0.0, -dot(dirToLight, light.normal)) * dotNlRayDir; 
}

`;

THREE.ShaderChunk[ 'pathtracing_calc_fresnel_reflectance' ] = `

float calcFresnelReflectance(vec3 n, vec3 nl, vec3 rayDirection, float nc, float nt, out vec3 tdir)
{
	float nnt = dot(rayDirection, n) <= 0.0 ? (nc / nt) : (nt / nc); // Ray from outside going in?
	tdir = refract(rayDirection, nl, nnt);
		
	// Original Fresnel equations
	float cosThetaInc = dot(nl, rayDirection);
	float cosThetaTra = dot(nl, tdir);
	float coefS = (nc * cosThetaInc - nt * cosThetaTra) / (nc * cosThetaInc + nt * cosThetaTra);
	float coefP = (nc * cosThetaTra - nt * cosThetaInc) / (nc * cosThetaTra + nt * cosThetaInc);

	return ( (coefS * coefS) + (coefP * coefP) ) * 0.5; // Unpolarized
}

`;

THREE.ShaderChunk[ 'pathtracing_main' ] = `

// tentFilter from Peter Shirley's 'Realistic Ray Tracing (2nd Edition)' book, pg. 60		
float tentFilter(float x)
{
	if (x < 0.5) 
		return sqrt(2.0 * x) - 1.0;
	else return 1.0 - sqrt(2.0 - (2.0 * x));
}

// cubicSplineFilter from Peter Shirley's 'Realistic Ray Tracing (2nd Edition)' book, pg. 58
float solve(float r)
{
	float u = r;
	for (int i = 0; i < 5; i++)
	{
		u = (11.0 * r + u * u * (6.0 + u * (8.0 - 9.0 * u))) /
			(4.0 + 12.0 * u * (1.0 + u * (1.0 - u)));
	}
	return u;
}

float cubicFilter(float x)
{
	if (x < 1.0 / 24.0)
		return pow(24.0 * x, 0.25) - 2.0;
	else if (x < 0.5)
		return solve(24.0 * (x - 1.0 / 24.0) / 11.0) - 1.0;
	else if (x < 23.0 / 24.0)
		return 1.0 - solve(24.0 * (23.0 / 24.0 - x) / 11.0);
	else return 2.0 - pow(24.0 * (1.0 - x), 0.25);
}

void main( void )
{
	// not needed, three.js has a built-in uniform named cameraPosition
	//vec3 camPos     = vec3( uCameraMatrix[3][0],  uCameraMatrix[3][1],  uCameraMatrix[3][2]);
	
	vec3 camRight   = vec3( uCameraMatrix[0][0],  uCameraMatrix[0][1],  uCameraMatrix[0][2]);
	vec3 camUp      = vec3( uCameraMatrix[1][0],  uCameraMatrix[1][1],  uCameraMatrix[1][2]);
	vec3 camForward = vec3(-uCameraMatrix[2][0], -uCameraMatrix[2][1], -uCameraMatrix[2][2]);
	
	// seed for rand(seed) function
	uvec2 seed = uvec2(uFrameCounter, uFrameCounter + 1.0) * uvec2(gl_FragCoord);

	vec2 pixelPos = vec2(0);
	vec2 pixelOffset = vec2(0);
	
	float x = rand(seed);
	float y = rand(seed);

	if (!uCameraIsMoving)
	{
		pixelOffset.x = tentFilter(x);
		pixelOffset.y = tentFilter(y);
		//pixelOffset.x = cubicFilter(x);
		//pixelOffset.y = cubicFilter(y);
	}
	
	// pixelOffset ranges from -1.0 to +1.0, so only need to divide by half resolution
	pixelOffset /= (uResolution * 0.5);

	// vUv comes in the range 0.0 to 1.0, so we must map it to the range -1.0 to +1.0
	pixelPos = vUv * 2.0 - 1.0;
	pixelPos += pixelOffset;

	vec3 rayDir = normalize( pixelPos.x * camRight * uULen + pixelPos.y * camUp * uVLen + camForward );
	
	// depth of field
	vec3 focalPoint = uFocusDistance * rayDir;
	float randomAngle = rand(seed) * TWO_PI; // pick random point on aperture
	float randomRadius = rand(seed) * uApertureSize;
	vec3  randomAperturePos = ( cos(randomAngle) * camRight + sin(randomAngle) * camUp ) * randomRadius;
	// point on aperture to focal point
	vec3 finalRayDir = normalize(focalPoint - randomAperturePos);
	
	Ray ray = Ray( cameraPosition + randomAperturePos , finalRayDir );

	SetupScene();
				
	// perform path tracing and get resulting pixel color
	vec3 pixelColor = CalculateRadiance( ray, seed );
	
	vec3 previousColor = texture(tPreviousTexture, vUv).rgb;
	
	if ( uCameraJustStartedMoving )
	{
		previousColor = vec3(0.0); // clear rendering accumulation buffer
	}
	else if ( uCameraIsMoving )
	{
		previousColor *= 0.5; // motion-blur trail amount (old image)
		pixelColor *= 0.5; // brightness of new image (noisy)
	}
		
	out_FragColor = vec4( pixelColor + previousColor, 1.0 );
	
}

`;
