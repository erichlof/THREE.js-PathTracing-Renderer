var screenTextureShader = {

        uniforms: THREE.UniformsUtils.merge( [
		
                {
                        tPathTracedImageTexture: { type: "t", value: null }
                }
		
        ] ),

        vertexShader: [
                '#version 300 es',
                
                'precision highp float;',
		'precision highp int;',

		'void main()',
		'{',
			'gl_Position = vec4( position, 1.0 );',
		'}'
		
        ].join( '\n' ),

        fragmentShader: [
                '#version 300 es',
                
                'precision highp float;',
		'precision highp int;',
		'precision highp sampler2D;',

                'uniform sampler2D tPathTracedImageTexture;',
                'out vec4 out_FragColor;',
		
		'void main()',
		'{',	
			'out_FragColor = texelFetch(tPathTracedImageTexture, ivec2(gl_FragCoord.xy), 0);',	
		'}'
		
        ].join( '\n' )

};

var screenOutputShader = {

        uniforms: THREE.UniformsUtils.merge( [
		
                {
                        uOneOverSampleCounter: { type: "f", value: 0.0 },
			tPathTracedImageTexture: { type: "t", value: null }
                }
		
        ] ),

        vertexShader: [
                '#version 300 es',
                
                'precision highp float;',
		'precision highp int;',

		'void main()',
		'{',
			'gl_Position = vec4( position, 1.0 );',
		'}'

        ].join( '\n' ),

        fragmentShader: [
                '#version 300 es',
                
                'precision highp float;',
		'precision highp int;',
		'precision highp sampler2D;',

                'uniform float uOneOverSampleCounter;',
		'uniform sampler2D tPathTracedImageTexture;',
                'out vec4 out_FragColor;',
		
		'void main()',
		'{',
			'vec3 pixelColor = texelFetch(tPathTracedImageTexture, ivec2(gl_FragCoord.xy), 0).rgb * uOneOverSampleCounter;',
			'pixelColor = ReinhardToneMapping(pixelColor);',
			'//pixelColor = Uncharted2ToneMapping(pixelColor);',
			'//pixelColor = OptimizedCineonToneMapping(pixelColor);',
			'//pixelColor = ACESFilmicToneMapping(pixelColor);',
			'out_FragColor = clamp(vec4( pow(pixelColor, vec3(0.4545)), 1.0 ), 0.0, 1.0);',	
		'}'
		
        ].join( '\n' )

};


THREE.ShaderChunk[ 'pathtracing_uniforms_and_defines' ] = `

uniform bool uCameraIsMoving;
uniform bool uCameraJustStartedMoving;

uniform float uEPS_intersect;
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

#define SPOT_LIGHT -2
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
#define PBR_MATERIAL 10
#define WOOD 11
#define SEAFLOOR 12
#define TERRAIN 13
#define CLOTH 14
#define LIGHTWOOD 15
#define DARKWOOD 16
#define PAINTING 17
#define METALCOAT 18

`;

THREE.ShaderChunk[ 'pathtracing_skymodel_defines' ] = `

#define TURBIDITY 0.2//0.3
#define RAYLEIGH_COEFFICIENT 2.5//2.0

#define MIE_COEFFICIENT 0.05//0.05
#define MIE_DIRECTIONAL_G 0.76//0.76

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

#define SUN_POWER 50.0
#define SUN_ANGULAR_DIAMETER_COS 0.99983194915 // 66 arc seconds -> degrees, and the cosine of that
#define CUTOFF_ANGLE 1.6 

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
	vec3 pOrO = pos - r.origin;
	float denom = dot(-normal, r.direction);
	// use the following for one-sided disk
	//if (denom <= 0.0) return INFINITY;
	
        float result = dot(pOrO, -normal) / denom;
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

	// from "Building an Orthonormal Basis, Revisited" http://jcgt.org/published/0006/01/01/
	float signf = normal.z >= 0.0 ? 1.0 : -1.0;
	float a = -1.0 / (signf + normal.z);
	float b = normal.x * normal.y * a;
	vec3 T = vec3( 1.0 + signf * normal.x * normal.x * a, signf * b, -signf * normal.x );
	vec3 B = vec3( b, signf + normal.y * normal.y * a, -normal.y );

	return (abs(dot(T, vi)) > radiusU || abs(dot(B, vi)) > radiusV) ? INFINITY : t;
}

`;

THREE.ShaderChunk[ 'pathtracing_slab_intersect' ] = `

//--------------------------------------------------------------------------------------
float SlabIntersect( float radius, vec3 normal, Ray r, out vec3 n )
//--------------------------------------------------------------------------------------
{
	n = dot(normal, r.direction) < 0.0 ? normal : -normal;
	float rad = dot(r.origin, n) > radius ? radius : -radius; 
	float denom = dot(n, r.direction);
	vec3 pOrO = (rad * n) - r.origin; 
	float t = dot(pOrO, n) / denom;
	return t > 0.0 ? t : INFINITY;
}

`;

THREE.ShaderChunk[ 'pathtracing_sphere_intersect' ] = `

bool solveQuadratic(float A, float B, float C, out float t0, out float t1)
{
	float discrim = B * B - 4.0 * A * C;
    
	if (discrim < 0.0)
        	return false;
    
	float rootDiscrim = sqrt(discrim);

	float Q = (B > 0.0) ? -0.5 * (B + rootDiscrim) : -0.5 * (B - rootDiscrim); 
	//float t_0 = Q / A; 
	//float t_1 = C / Q;
	//t0 = min( t_0, t_1 );
	//t1 = max( t_0, t_1 );

	t1 = Q / A; 
	t0 = C / Q;
	
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
	
	if ( t0 > 0.0 )
		return t0;

	if ( t1 > 0.0 )
		return t1;
		
	return INFINITY;
}

`;

THREE.ShaderChunk[ 'pathtracing_ellipsoid_param_intersect' ] = `

//------------------------------------------------------------------------------------------------------------
float EllipsoidParamIntersect( float yMinPercent, float yMaxPercent, float phiMaxRadians, vec3 ro, vec3 rd, out vec3 n )
//------------------------------------------------------------------------------------------------------------
{
	vec3 pHit;
	float t = INFINITY;
	float t0, t1, phi;

	// implicit equation of a unit (radius of 1) sphere:
	// x^2 + y^2 + z^2 - 1 = 0
	float a = dot(rd, rd);
	float b = 2.0 * dot(rd, ro);
	float c = dot(ro, ro) - 1.0;

	if (!solveQuadratic( a, b, c, t0, t1))
		return INFINITY;
	
	if ( t0 > 0.0 )
	{
		pHit = ro + rd * t0;
		phi = mod(atan(pHit.z, pHit.x), TWO_PI);
		n = vec3(2.0 * pHit.x, 2.0 * pHit.y, 2.0 * pHit.z);
		// flip normal if it is facing away from us
		n *= sign(-dot(rd, n)) * 2.0 - 1.0; // sign is 0 or 1, map it to -1 and +1
		
		if (pHit.y < yMaxPercent && pHit.y > yMinPercent && phi < phiMaxRadians)
			return t0;
	}

	if ( t1 > 0.0 )
	{
		pHit = ro + rd * t1;
		phi = mod(atan(pHit.z, pHit.x), TWO_PI);
		n = vec3(2.0 * pHit.x, 2.0 * pHit.y, 2.0 * pHit.z);
		// flip normal if it is facing away from us
		n *= sign(-dot(rd, n)) * 2.0 - 1.0; // sign is 0 or 1, map it to -1 and +1
		
		if (pHit.y < yMaxPercent && pHit.y > yMinPercent && phi < phiMaxRadians)
			return t1;
	}

	return INFINITY;
}

`;

THREE.ShaderChunk[ 'pathtracing_cylinder_param_intersect' ] = `

//------------------------------------------------------------------------------------------------------------
float CylinderParamIntersect( float yMinPercent, float yMaxPercent, float phiMaxRadians, vec3 ro, vec3 rd, out vec3 n )
//------------------------------------------------------------------------------------------------------------
{
	vec3 pHit;
	float t = INFINITY;
	float t0, t1, phi;

	// implicit equation of a unit (radius of 1) cylinder, extending infinitely in the +Y and -Y directions:
	// x^2 + z^2 - 1 = 0
	float a = (rd.x * rd.x + rd.z * rd.z);
    	float b = 2.0 * (rd.x * ro.x + rd.z * ro.z);
    	float c = (ro.x * ro.x + ro.z * ro.z) - 1.0;

	if (!solveQuadratic( a, b, c, t0, t1))
		return INFINITY;
		
	if ( t0 > 0.0 )
	{
		pHit = ro + rd * t0;
		phi = mod(atan(pHit.z, pHit.x), TWO_PI);
		n = vec3(2.0 * pHit.x, 0.0, 2.0 * pHit.z);
		// flip normal if it is facing away from us
		n *= sign(-dot(rd, n)) * 2.0 - 1.0; // sign is 0 or 1, map it to -1 and +1
		
		if (pHit.y < yMaxPercent && pHit.y > yMinPercent && phi < phiMaxRadians)
			return t0;
	}

	if ( t1 > 0.0 )
	{
		pHit = ro + rd * t1;
		phi = mod(atan(pHit.z, pHit.x), TWO_PI);
		n = vec3(2.0 * pHit.x, 0.0, 2.0 * pHit.z);
		// flip normal if it is facing away from us
		n *= sign(-dot(rd, n)) * 2.0 - 1.0; // sign is 0 or 1, map it to -1 and +1
		
		if (pHit.y < yMaxPercent && pHit.y > yMinPercent && phi < phiMaxRadians)
			return t1;
	}

	return INFINITY;
}

`;

THREE.ShaderChunk[ 'pathtracing_cone_param_intersect' ] = `

//------------------------------------------------------------------------------------------------------------
float ConeParamIntersect( float yMinPercent, float yMaxPercent, float phiMaxRadians, vec3 ro, vec3 rd, out vec3 n )
//------------------------------------------------------------------------------------------------------------
{
	vec3 pHit;
	float t = INFINITY;
	float t0, t1, phi;

	// implicit equation of a double-cone extending infinitely in +Y and -Y directions
	// x^2 + z^2 - y^2 = 0
	// code below cuts off top cone, leaving bottom cone with apex at the top (+1.0), and circular base (radius of 1) at the bottom (-1.0)
	float k = 0.25;
	float a = rd.x * rd.x + rd.z * rd.z - k * rd.y * rd.y;
    	float b = 2.0 * (rd.x * ro.x + rd.z * ro.z - k * rd.y * (ro.y - 1.0));
    	float c = ro.x * ro.x + ro.z * ro.z - k * (ro.y - 1.0) * (ro.y - 1.0);
	
	if (!solveQuadratic( a, b, c, t0, t1))
		return INFINITY;
		
	if ( t0 > 0.0 )
	{
		pHit = ro + rd * t0;
		phi = mod(atan(pHit.z, pHit.x), TWO_PI);
		n = vec3(2.0 * pHit.x, -2.0 * (pHit.y - 1.0) * k, 2.0 * pHit.z);
		// flip normal if it is facing away from us
		n *= sign(-dot(rd, n)) * 2.0 - 1.0; // sign is 0 or 1, map it to -1 and +1
		
		if (pHit.y < yMaxPercent && pHit.y > yMinPercent && phi < phiMaxRadians)
			return t0;
	}

	if ( t1 > 0.0 )
	{
		pHit = ro + rd * t1;
		phi = mod(atan(pHit.z, pHit.x), TWO_PI);
		n = vec3(2.0 * pHit.x, -2.0 * (pHit.y - 1.0) * k, 2.0 * pHit.z);
		// flip normal if it is facing away from us
		n *= sign(-dot(rd, n)) * 2.0 - 1.0; // sign is 0 or 1, map it to -1 and +1
		
		if (pHit.y < yMaxPercent && pHit.y > yMinPercent && phi < phiMaxRadians)
			return t1;
	}

	return INFINITY;
}

`;

THREE.ShaderChunk[ 'pathtracing_paraboloid_param_intersect' ] = `

//------------------------------------------------------------------------------------------------------------
float ParaboloidParamIntersect( float yMinPercent, float yMaxPercent, float phiMaxRadians, vec3 ro, vec3 rd, out vec3 n )
//------------------------------------------------------------------------------------------------------------
{
	vec3 pHit;
	float t = INFINITY;
	float t0, t1, phi;

	// implicit equation of a paraboloid (bowl or vase-shape extending infinitely in the +Y direction):
	// x^2 + z^2 - y = 0
	ro.y += 1.0; // this essentially centers the paraboloid so that the bottom is at -1.0 and 
		     // the open circular top (radius of 1) is at +1.0

	float k = 0.5;
	float a = (rd.x * rd.x + rd.z * rd.z);
    	float b = 2.0 * (rd.x * ro.x + rd.z * ro.z) - k * rd.y;
    	float c = (ro.x * ro.x + ro.z * ro.z) - k * ro.y;

	if (!solveQuadratic( a, b, c, t0, t1))
		return INFINITY;
	
	// this takes into account that we shifted the ray origin by +1.0
	yMaxPercent += 1.0;
	yMinPercent += 1.0;

	if ( t0 > 0.0 )
	{
		pHit = ro + rd * t0;
		phi = mod(atan(pHit.z, pHit.x), TWO_PI);
		n = vec3(2.0 * pHit.x, -1.0 * k, 2.0 * pHit.z);
		// flip normal if it is facing away from us
		n *= sign(-dot(rd, n)) * 2.0 - 1.0; // sign is 0 or 1, map it to -1 and +1
		
		if (pHit.y < yMaxPercent && pHit.y > yMinPercent && phi < phiMaxRadians)
			return t0;
	}

	if ( t1 > 0.0 )
	{
		pHit = ro + rd * t1;
		phi = mod(atan(pHit.z, pHit.x), TWO_PI);
		n = vec3(2.0 * pHit.x, -1.0 * k, 2.0 * pHit.z);
		// flip normal if it is facing away from us
		n *= sign(-dot(rd, n)) * 2.0 - 1.0; // sign is 0 or 1, map it to -1 and +1
		
		if (pHit.y < yMaxPercent && pHit.y > yMinPercent && phi < phiMaxRadians)
			return t1;
	}

	return INFINITY;
}

`;

THREE.ShaderChunk[ 'pathtracing_hyperboloid_param_intersect' ] = `

//------------------------------------------------------------------------------------------------------------
float HyperboloidParamIntersect( float k, float yMinPercent, float yMaxPercent, float phiMaxRadians, vec3 ro, vec3 rd, out vec3 n )
//------------------------------------------------------------------------------------------------------------
{
	vec3 pHit;
	float t = INFINITY;
	float t0, t1, phi;

	// implicit equation of a hyperboloid of 1 sheet (hourglass shape extending infinitely in the +Y and -Y directions):
	// x^2 + z^2 - y^2 - 1 = 0
	// implicit equation of a hyperboloid of 2 sheets (2 mirrored opposing paraboloids, non-connecting, top extends infinitely in +Y, bottom in -Y):
	// x^2 + z^2 - y^2 + 1 = 0
	
	// if the k argument is negative, a 2-sheet hyperboloid is created
	float j = k - 1.0;
	
	float a = k * rd.x * rd.x + k * rd.z * rd.z - j * rd.y * rd.y;
	float b = 2.0 * (k * rd.x * ro.x + k * rd.z * ro.z - j * rd.y * ro.y);
	float c = (k * ro.x * ro.x + k * ro.z * ro.z - j * ro.y * ro.y) - 1.0;

	if (!solveQuadratic( a, b, c, t0, t1))
		return INFINITY;
	
	if ( t0 > 0.0 )
	{
		pHit = ro + rd * t0;
		phi = mod(atan(pHit.z, pHit.x), TWO_PI);
		n = vec3(2.0 * pHit.x * k, -2.0 * pHit.y * j, 2.0 * pHit.z * k);
		// flip normal if it is facing away from us
		n *= sign(-dot(rd, n)) * 2.0 - 1.0; // sign is 0 or 1, map it to -1 and +1
		
		if (pHit.y < yMaxPercent && pHit.y > yMinPercent && phi < phiMaxRadians)
			return t0;
	}

	if ( t1 > 0.0 )
	{
		pHit = ro + rd * t1;
		phi = mod(atan(pHit.z, pHit.x), TWO_PI);
		n = vec3(2.0 * pHit.x * k, -2.0 * pHit.y * j, 2.0 * pHit.z * k);
		// flip normal if it is facing away from us
		n *= sign(-dot(rd, n)) * 2.0 - 1.0; // sign is 0 or 1, map it to -1 and +1

		if (pHit.y < yMaxPercent && pHit.y > yMinPercent && phi < phiMaxRadians)
			return t1;
	}

	return INFINITY;
}

`;

THREE.ShaderChunk[ 'pathtracing_hyperbolic_paraboloid_param_intersect' ] = `

//------------------------------------------------------------------------------------------------------------
float HyperbolicParaboloidParamIntersect( float yMinPercent, float yMaxPercent, float phiMaxRadians, vec3 ro, vec3 rd, out vec3 n )
//------------------------------------------------------------------------------------------------------------
{
	vec3 pHit;
	float t = INFINITY;
	float t0, t1, phi;

	// implicit equation of an infinite hyperbolic paraboloid (saddle shape):
	// x^2 - z^2 - y = 0
	float a = rd.x * rd.x - rd.z * rd.z;
	float b = 2.0 * (rd.x * ro.x - rd.z * ro.z) - rd.y;
	float c = (ro.x * ro.x - ro.z * ro.z) - ro.y;

	if (!solveQuadratic( a, b, c, t0, t1))
		return INFINITY;

	if ( t0 > 0.0 )
	{
		pHit = ro + rd * t0;
		phi = mod(atan(pHit.z, pHit.x), TWO_PI);
		n = vec3(2.0 * pHit.x, -1.0, -2.0 * pHit.z);
		// flip normal if it is facing away from us
		n *= sign(-dot(rd, n)) * 2.0 - 1.0; // sign is 0 or 1, map it to -1 and +1

		if (abs(pHit.x) < yMaxPercent && abs(pHit.y) < yMaxPercent && abs(pHit.z) < yMaxPercent && phi < phiMaxRadians)
			return t0;
	}

	if ( t1 > 0.0 )
	{
		pHit = ro + rd * t1;
		phi = mod(atan(pHit.z, pHit.x), TWO_PI);
		n = vec3(2.0 * pHit.x, -1.0, -2.0 * pHit.z);
		// flip normal if it is facing away from us
		n *= sign(-dot(rd, n)) * 2.0 - 1.0; // sign is 0 or 1, map it to -1 and +1
		
		if (abs(pHit.x) < yMaxPercent && abs(pHit.y) < yMaxPercent && abs(pHit.z) < yMaxPercent && phi < phiMaxRadians)
			return t1;
	}

	return INFINITY;
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
	
	if ( t0 > 0.0 )
		return t0;

	if ( t1 > 0.0 )
		return t1;
	
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
	
	if (det<0.0) 
		return INFINITY;
	
	det=sqrt(det);
	
	float t0 = (-b-det)*ra;
	float t1 = (-b+det)*ra;
	
	vec3 ip;
	vec3 lp;
	float ct;

	if (t0 > 0.0)
	{
		ip=r.origin+r.direction*t0;
		lp=ip-p0;
		ct=dot(lp,dpt);
		if((ct>0.0)&&(ct<1.0))
		{
			n=ip-(p0+dp*ct);
			return t0;
		}
	}
	
	if (t1 > 0.0)
	{
		ip=r.origin+r.direction*t1;
		lp=ip-p0;
		ct=dot(lp,dpt);
		if((ct>0.0)&&(ct<1.0))
		{
		     	n=(p0+dp*ct)-ip;
			return t1;
		}
	}
	
	return INFINITY;
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
	
	if(t0>0.0 && pt0.z>r1/r0 && pt0.z<1.0)
	{
		n=pt0;
		n.z=0.0;
		n=normalize(n);
		n.z=-pt0.z/abs(pt0.z);
		n=normalize(n);
		n=tm*n;
		return t0;
	}

        if(t1>0.0 && pt1.z>r1/r0 && pt1.z<1.0)
	{
		n=pt1;
		n.z=0.0;
		n=normalize(n);
		n.z=-pt1.z/abs(pt1.z);
		n=normalize(n);
		n=tm*-n;
		return t1;
	}
	
	return INFINITY;	
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
	
	vec3 ip;
	
	if (t0 > 0.0)
	{
		ip = ro + rd * t0;
		n = vec3( 2.0 * ip.x, -1.0 / k, 2.0 * ip.z );
		// flip normal if it is facing away from us
		n *= sign(-dot(rd, n)) * 2.0 - 1.0; // sign is 0 or 1, map it to -1 and +1
		
		if (ip.y < height)
			return t0;
				
	}

	if (t1 > 0.0)
	{	
		ip = ro + rd * t1;
		n = vec3( 2.0 * ip.x, -1.0 / k, 2.0 * ip.z );
		// flip normal if it is facing away from us
		n *= sign(-dot(rd, n)) * 2.0 - 1.0; // sign is 0 or 1, map it to -1 and +1
		
		if (ip.y < height)
			return t1;		
	}
	
	
	return INFINITY;	
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

float TriangleIntersect( vec3 v0, vec3 v1, vec3 v2, Ray r, bool isDoubleSided )
{
	vec3 edge1 = v1 - v0;
	vec3 edge2 = v2 - v0;
	vec3 pvec = cross(r.direction, edge2);
	float det = 1.0 / dot(edge1, pvec);

	if ( !isDoubleSided && det < 0.0 ) 
		return INFINITY;

	vec3 tvec = r.origin - v0;
	float u = dot(tvec, pvec) * det;
	vec3 qvec = cross(tvec, edge1);
	float v = dot(r.direction, qvec) * det;

	float t = dot(edge2, qvec) * det;

	return (u < 0.0 || u > 1.0 || v < 0.0 || u + v > 1.0 || t <= 0.0) ? INFINITY : t;
}

//----------------------------------------------------------------------------------
float QuadIntersect( vec3 v0, vec3 v1, vec3 v2, vec3 v3, Ray r, bool isDoubleSided )
//----------------------------------------------------------------------------------
{
	return min(TriangleIntersect(v0, v1, v2, r, isDoubleSided), TriangleIntersect(v0, v2, v3, r, isDoubleSided));
}

`;

THREE.ShaderChunk[ 'pathtracing_box_intersect' ] = `


//-------------------------------------------------------------------------------------------------------
float BoxIntersect( vec3 minCorner, vec3 maxCorner, inout Ray r, out vec3 normal, out bool isRayExiting )
//-------------------------------------------------------------------------------------------------------
{
	//r.direction = normalize(r.direction);
	vec3 invDir = 1.0 / r.direction;
	vec3 near = (minCorner - r.origin) * invDir;
	vec3 far  = (maxCorner - r.origin) * invDir;
	
	vec3 tmin = min(near, far);
	vec3 tmax = max(near, far);
	
	float t0 = max( max(tmin.x, tmin.y), tmin.z);
	float t1 = min( min(tmax.x, tmax.y), tmax.z);
	
	if (t0 > t1) return INFINITY;

	if (t0 > 0.0) // if we are outside the box
	{
		normal = -sign(r.direction) * step(tmin.yzx, tmin) * step(tmin.zxy, tmin);
		isRayExiting = false;
		return t0;	
	}

	if (t1 > 0.0) // if we are inside the box
	{
		normal = -sign(r.direction) * step(tmax, tmax.yzx) * step(tmax, tmax.zxy);
		isRayExiting = true;
		return t1;
	}

	return INFINITY;
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
	
	return (t0 > t1 || t1 < 0.0) ? INFINITY : t0;
	//return t0 > t1 ? INFINITY : t1 > 0.0 ? t0 : INFINITY;
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
	vec3 tvec = r.origin - v0;
	u = dot(tvec, pvec) * det;
	vec3 qvec = cross(tvec, edge1);
	v = dot(r.direction, qvec) * det;
	float t = dot(edge2, qvec) * det;

	return (det < 0.0 || u < 0.0 || u > 1.0 || v < 0.0 || u + v > 1.0 || t <= 0.0) ? INFINITY : t;
}

`;

THREE.ShaderChunk[ 'pathtracing_bvhDoubleSidedTriangle_intersect' ] = `

//-------------------------------------------------------------------------------------------
float BVH_DoubleSidedTriangleIntersect( vec3 v0, vec3 v1, vec3 v2, Ray r, out float u, out float v )
//-------------------------------------------------------------------------------------------
{
	vec3 edge1 = v1 - v0;
	vec3 edge2 = v2 - v0;
	vec3 pvec = cross(r.direction, edge2);
	float det = 1.0 / dot(edge1, pvec);
	vec3 tvec = r.origin - v0;
	u = dot(tvec, pvec) * det;
	vec3 qvec = cross(tvec, edge1);
	v = dot(r.direction, qvec) * det;
	float t = dot(edge2, qvec) * det;

	return (u < 0.0 || u > 1.0 || v < 0.0 || u + v > 1.0 || t <= 0.0) ? INFINITY : t;
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
	return SUN_POWER * max( 0.0, 1.0 - exp( -( CUTOFF_ANGLE - acos(zenithAngleCos) ) ) );
}

vec3 Get_Sky_Color(Ray r, vec3 sunDirection)
{
	
    	vec3 viewDir = normalize(r.direction);
	
	/* most of the following code is borrowed from the three.js shader file: SkyShader.js */

    	// Cosine angles
	float cosViewSunAngle = dot(viewDir, sunDirection);
    	float cosSunUpAngle = dot(sunDirection, UP_VECTOR); // allowed to be negative: + is daytime, - is nighttime
    	float cosUpViewAngle = max(0.0001, dot(UP_VECTOR, viewDir)); // cannot be 0, used as divisor
	
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

	// composition + solar disk
    	float sundisk = smoothstep(SUN_ANGULAR_DIAMETER_COS - 0.0001, SUN_ANGULAR_DIAMETER_COS, cosViewSunAngle);
	vec3 sun = (sunE * SUN_POWER * Fex) * sundisk;
	
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
    	float up = rand(seed) * 2.0 - 1.0; // range: -1 to +1
	float over = sqrt( max(0.0, 1.0 - up * up) );
	float around = rand(seed) * TWO_PI;
	return normalize(vec3(cos(around) * over, up, sin(around) * over));	
}

vec3 randomDirectionInHemisphere( vec3 nl, inout uvec2 seed )
{
	float up = rand(seed); // uniform distribution in hemisphere
    	float over = sqrt(max(0.0, 1.0 - up * up));
	float around = rand(seed) * TWO_PI;

	// from "Building an Orthonormal Basis, Revisited" http://jcgt.org/published/0006/01/01/
	float signf = nl.z >= 0.0 ? 1.0 : -1.0;
	float a = -1.0 / (signf + nl.z);
	float b = nl.x * nl.y * a;
	vec3 T = vec3( 1.0 + signf * nl.x * nl.x * a, signf * b, -signf * nl.x );
	vec3 B = vec3( b, signf + nl.y * nl.y * a, -nl.y );

	return normalize(cos(around) * over * T + sin(around) * over * B + up * nl);
}

// vec3 randomCosWeightedDirectionInHemisphere( vec3 nl, inout uvec2 seed )
// {
// 	float up = sqrt(rand(seed)); // cos-weighted distribution in hemisphere
// 	float over = sqrt(max(0.0, 1.0 - up * up));
// 	float around = rand(seed) * TWO_PI;
	
// 	vec3 u = normalize( cross( abs(nl.x) > 0.1 ? vec3(0, 1, 0) : vec3(1, 0, 0), nl ) );
// 	vec3 v = cross(nl, u);

// 	return normalize(cos(around) * over * u + sin(around) * over * v + up * nl);
// }

#define N_POINTS 32.0

vec3 randomCosWeightedDirectionInHemisphere( vec3 nl, inout uvec2 seed )
{
	float i = floor(N_POINTS * rand(seed)) + (rand(seed) * 0.5);
			// the Golden angle in radians
	float theta = i * 2.39996322972865332 + mod(uSampleCounter, TWO_PI);
	theta = mod(theta, TWO_PI);
	float r = sqrt(i / N_POINTS); // sqrt pushes points outward to prevent clumping in center of disk
	float x = r * cos(theta);
	float y = r * sin(theta);
	vec3 p = vec3(x, y, sqrt(1.0 - x * x - y * y)); // project XY disk points outward along Z axis

	// from "Building an Orthonormal Basis, Revisited" http://jcgt.org/published/0006/01/01/
	float signf = nl.z >= 0.0 ? 1.0 : -1.0;
	float a = -1.0 / (signf + nl.z);
	float b = nl.x * nl.y * a;
	vec3 T = vec3( 1.0 + signf * nl.x * nl.x * a, signf * b, -signf * nl.x );
	vec3 B = vec3( b, signf + nl.y * nl.y * a, -nl.y );
	
	return (T * p.x + B * p.y + nl * p.z);
}

vec3 randomDirectionInSpecularLobe( vec3 reflectionDir, float roughness, inout uvec2 seed )
{
	roughness = mix( 13.0, 0.0, sqrt(clamp(roughness, 0.0, 1.0)) );
	float cosTheta = pow(rand(seed), 1.0 / (exp(roughness) + 1.0));
	float sinTheta = sqrt(max(0.0, 1.0 - cosTheta * cosTheta));
	float phi = rand(seed) * TWO_PI;

	// from "Building an Orthonormal Basis, Revisited" http://jcgt.org/published/0006/01/01/
	float signf = reflectionDir.z >= 0.0 ? 1.0 : -1.0;
	float a = -1.0 / (signf + reflectionDir.z);
	float b = reflectionDir.x * reflectionDir.y * a;
	vec3 T = vec3( 1.0 + signf * reflectionDir.x * reflectionDir.x * a, signf * b, -signf * reflectionDir.x );
	vec3 B = vec3( b, signf + reflectionDir.y * reflectionDir.y * a, -reflectionDir.y );
	
	return (T * cos(phi) * sinTheta + B * sin(phi) * sinTheta + reflectionDir * cosTheta);
}

// //the following alternative skips the creation of tangent and bi-tangent vectors u and v 
// vec3 randomCosWeightedDirectionInHemisphere( vec3 nl, inout uvec2 seed )
// {
// 	float phi = rand(seed) * TWO_PI;
// 	float theta = 2.0 * rand(seed) - 1.0;
// 	return nl + vec3(sqrt(1.0 - theta * theta) * vec2(cos(phi), sin(phi)), theta);
// }

// vec3 randomDirectionInPhongSpecular( vec3 reflectionDir, float roughness, inout uvec2 seed )
// {
// 	float phi = rand(seed) * TWO_PI;
// 	roughness = clamp(roughness, 0.0, 1.0);
// 	roughness = mix(13.0, 0.0, sqrt(roughness));
// 	float exponent = exp(roughness) + 1.0;
// 	//weight = (exponent + 2.0) / (exponent + 1.0);

// 	float cosTheta = pow(rand(seed), 1.0 / (exponent + 1.0));
// 	float radius = sqrt(max(0.0, 1.0 - cosTheta * cosTheta));

// 	vec3 u = normalize( cross( abs(reflectionDir.x) > 0.1 ? vec3(0, 1, 0) : vec3(1, 0, 0), reflectionDir ) );
// 	vec3 v = cross(reflectionDir, u);

// 	return (u * cos(phi) * radius + v * sin(phi) * radius + reflectionDir * cosTheta);
// }

`;


THREE.ShaderChunk[ 'pathtracing_sample_sphere_light' ] = `

vec3 sampleSphereLight(vec3 x, vec3 nl, Sphere light, vec3 dirToLight, out float weight, inout uvec2 seed)
{
	dirToLight = (light.position - x); // no normalize (for distance calc below)
	float cos_alpha_max = sqrt(1.0 - clamp((light.radius * light.radius) / dot(dirToLight, dirToLight), 0.0, 1.0));
	
	float cos_alpha = mix( cos_alpha_max, 1.0, rand(seed) ); // 1.0 + (rand(seed) * (cos_alpha_max - 1.0));
	// * 0.75 below ensures shadow rays don't miss the light, due to shader float precision
	float sin_alpha = sqrt(max(0.0, 1.0 - cos_alpha * cos_alpha)) * 0.75; 
	float phi = rand(seed) * TWO_PI;

	dirToLight = normalize(dirToLight);
	
	// from "Building an Orthonormal Basis, Revisited" http://jcgt.org/published/0006/01/01/
	float signf = dirToLight.z >= 0.0 ? 1.0 : -1.0;
	float a = -1.0 / (signf + dirToLight.z);
	float b = dirToLight.x * dirToLight.y * a;
	vec3 T = vec3( 1.0 + signf * dirToLight.x * dirToLight.x * a, signf * b, -signf * dirToLight.x );
	vec3 B = vec3( b, signf + dirToLight.y * dirToLight.y * a, -dirToLight.y );
	
	vec3 sampleDir = normalize(T * cos(phi) * sin_alpha + B * sin(phi) * sin_alpha + dirToLight * cos_alpha);
	weight = clamp(2.0 * (1.0 - cos_alpha_max) * max(0.0, dot(nl, sampleDir)), 0.0, 1.0);
	
	return sampleDir;
}

`;

THREE.ShaderChunk[ 'pathtracing_sample_quad_light' ] = `

vec3 sampleQuadLight(vec3 x, vec3 nl, Quad light, vec3 dirToLight, out float weight, inout uvec2 seed)
{
	vec3 randPointOnLight;
	randPointOnLight.x = mix(light.v0.x, light.v1.x, clamp(rand(seed), 0.1, 0.9));
	randPointOnLight.y = light.v0.y;
	randPointOnLight.z = mix(light.v0.z, light.v3.z, clamp(rand(seed), 0.1, 0.9));
	dirToLight = randPointOnLight - x;
	float r2 = distance(light.v0, light.v1) * distance(light.v0, light.v3);
	float d2 = dot(dirToLight, dirToLight);
	float cos_a_max = sqrt(1.0 - clamp( r2 / d2, 0.0, 1.0));

	dirToLight = normalize(dirToLight);
	float dotNlRayDir = max(0.0, dot(nl, dirToLight)); 
	weight =  2.0 * (1.0 - cos_a_max) * max(0.0, -dot(dirToLight, light.normal)) * dotNlRayDir; 
	weight = clamp(weight, 0.0, 1.0);

	return dirToLight;
}

`;

THREE.ShaderChunk[ 'pathtracing_calc_fresnel_reflectance' ] = `

float calcFresnelReflectance(vec3 rayDirection, vec3 n, float etai, float etat, out float ratioIoR)
{
	float temp = etai;
	float cosi = clamp(dot(rayDirection, n), -1.0, 1.0);
	if (cosi > 0.0)
	{
		etai = etat;
		etat = temp;
	}
	
	ratioIoR = etai / etat;
	float sint = ratioIoR * sqrt(1.0 - (cosi * cosi));
	if (sint >= 1.0) 
		return 1.0; // total internal reflection

	float cost = sqrt(1.0 - (sint * sint));
	cosi = abs(cosi);
	float Rs = ((etat * cosi) - (etai * cost)) / ((etat * cosi) + (etai * cost));
	float Rp = ((etai * cosi) - (etat * cost)) / ((etai * cosi) + (etat * cost));

	return clamp( ((Rs * Rs) + (Rp * Rp)) * 0.5, 0.0, 1.0 );
}

`;

THREE.ShaderChunk[ 'pathtracing_main' ] = `

// tentFilter from Peter Shirley's 'Realistic Ray Tracing (2nd Edition)' book, pg. 60		
float tentFilter(float x)
{
	return (x < 0.5) ? sqrt(2.0 * x) - 1.0 : 1.0 - sqrt(2.0 - (2.0 * x));
}

/*
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
*/

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

	// we must map pixelPos into the range -1.0 to +1.0
	pixelPos = (gl_FragCoord.xy / uResolution) * 2.0 - 1.0;
	pixelPos += pixelOffset;

	vec3 rayDir = normalize( pixelPos.x * camRight * uULen + pixelPos.y * camUp * uVLen + camForward );
	
	// depth of field
	vec3 focalPoint = uFocusDistance * rayDir;
	float randomAngle = rand(seed) * TWO_PI; // pick random point on aperture
	float randomRadius = rand(seed) * uApertureSize;
	vec3  randomAperturePos = ( cos(randomAngle) * camRight + sin(randomAngle) * camUp ) * sqrt(randomRadius);
	// point on aperture to focal point
	vec3 finalRayDir = normalize(focalPoint - randomAperturePos);
	
	Ray ray = Ray( cameraPosition + randomAperturePos , finalRayDir );

	SetupScene();
				
	// perform path tracing and get resulting pixel color
	vec3 pixelColor = CalculateRadiance( ray, seed );
	
	vec3 previousColor = texelFetch(tPreviousTexture, ivec2(gl_FragCoord.xy), 0).rgb;

	if (uFrameCounter == 1.0) // camera just moved after being still
	{
		previousColor = vec3(0); // clear rendering accumulation buffer
	}
	else if (uCameraIsMoving) // camera is currently moving
	{
		previousColor *= 0.5; // motion-blur trail amount (old image)
		pixelColor *= 0.5; // brightness of new image (noisy)
	}
		
	out_FragColor = vec4( pixelColor + previousColor, 1.0 );
}

`;
