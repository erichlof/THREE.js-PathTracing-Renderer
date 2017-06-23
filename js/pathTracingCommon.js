var screenTextureShader = {

        uniforms: THREE.UniformsUtils.merge( [
		
                {
                        tTexture0: { type: "t", value: null }
                }
		
        ] ),

        vertexShader: [
		
                'precision highp float;',
		'precision highp int;',

		'varying vec2 vUv;',

		
		'void main()',
		'{',
			'vUv = uv;',
			'gl_Position = vec4( position, 1.0 );',
		'}'
		
        ].join( '\n' ),

        fragmentShader: [
		
                'precision highp float;',
		'precision highp int;',
		'precision highp sampler2D;',

		'varying vec2 vUv;',
		'uniform sampler2D tTexture0;',


		'void main()',
		'{',	
			'gl_FragColor = texture2D(tTexture0, vUv);',	
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
		
                'precision highp float;',
		'precision highp int;',

		'varying vec2 vUv;',

		
		'void main()',
		'{',
			'vUv = uv;',
			'gl_Position = vec4( position, 1.0 );',
		'}'

		
        ].join( '\n' ),

        fragmentShader: [
		
                'precision highp float;',
		'precision highp int;',
		'precision highp sampler2D;',

		'varying vec2 vUv;',
		'uniform float uOneOverSampleCounter;',
		'uniform sampler2D tTexture0;',

		'void main()',
		'{',
			'vec4 pixelColor = texture2D(tTexture0, vUv) * uOneOverSampleCounter;',

			'gl_FragColor = sqrt(pixelColor);',	
		'}'
		
        ].join( '\n' )

};


THREE.ShaderChunk[ 'pathtracing_uniforms_and_defines' ] = `

uniform bool uCameraIsMoving;
uniform bool uCameraJustStartedMoving;

uniform float uTime;
uniform float uSampleCounter;
uniform float uULen;
uniform float uVLen;
uniform float uApertureSize;
uniform float uFocusDistance;

uniform vec2 uResolution;

uniform vec3 uRandomVector;

uniform mat4 uCameraMatrix;

uniform sampler2D tPreviousTexture;

varying vec2 vUv;


#define PI               3.14159265358979323
#define ONE_OVER_PI      0.31830988618379067
#define TWO_PI           6.28318530717958648
#define FOUR_PI          12.5663706143591729
#define ONE_OVER_FOUR_PI 0.07957747154594767
#define PI_OVER_TWO      1.57079632679489662
#define E                2.71828182845904524
#define INFINITY         1000000.0

#define LIGHT 0
#define DIFF 1
#define REFR 2
#define SPEC 3
#define CHECK 4
#define COAT 5
#define VOLUME 6
#define TRANSLUCENT 7
#define SPECSUB 8

`;

THREE.ShaderChunk[ 'pathtracing_sphere_intersect' ] = `

//-----------------------------------------------------------------------
float SphereIntersect( float rad, vec3 pos, Ray r )
//-----------------------------------------------------------------------
{
	vec3 op = pos - r.origin;
	float b = dot(op, r.direction);
	float det = b * b - dot(op,op) + rad * rad;
       	if (det < 0.0)
		return INFINITY;
        
	det = sqrt(det);	
	float t1 = b - det;
	if( t1 > 0.0 )
		return t1;
		
	float t2 = b + det;
	if( t2 > 0.0 )
		return t2;
	return INFINITY;	
}

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
	vec3 tmin = (minCorner - r.origin) * invDir;
	vec3 tmax = (maxCorner - r.origin) * invDir;
	
	vec3 real_min = min(tmin, tmax);
	vec3 real_max = max(tmin, tmax);
	
	float minmax = min( min(real_max.x, real_max.y), real_max.z);
	float maxmin = max( max(real_min.x, real_min.y), real_min.z);
	
	if (minmax > maxmin)
	{
		
		if (maxmin > 0.0) // if we are outside the box
		{
			normal = -sign(r.direction) * step(real_min.yzx, real_min) * step(real_min.zxy, real_min);
			return maxmin;	
		}
		
		else if (minmax > 0.0) // else if we are inside the box
		{
			normal = -sign(r.direction) * step(real_max, real_max.yzx) * step(real_max, real_max.zxy);
			return minmax;
		}
				
	}
	
	return INFINITY;
}

`;


THREE.ShaderChunk[ 'pathtracing_random_functions' ] = `

float rand( inout float seed )
{ 
	seed -= uRandomVector.x * uRandomVector.y;
	return fract( sin( seed ) * 43758.5453123 );
}

vec3 randomSphereDirection( inout float seed )
{
    	vec2 r = vec2(rand(seed), rand(seed)) * TWO_PI;
	return vec3( sin(r.x) * vec2(sin(r.y), cos(r.y)), cos(r.x) );	
}

vec3 randomCosWeightedDirectionInHemisphere( vec3 nl, inout float seed )
{
	float up = sqrt(rand(seed)); // weighted cos(theta)
    	float over = sqrt(1.0 - up * up); // sin(theta)
    	float around = rand(seed) * TWO_PI;
	vec3 u = normalize( cross( abs(nl.x) > 0.1 ? vec3(0, 1, 0) : vec3(1, 0, 0), nl ) );
	vec3 v = normalize( cross(nl, u) );
    	return vec3( cos(around) * over * u ) + ( sin(around) * over * v ) + (up * nl);		
}

`;

THREE.ShaderChunk[ 'pathtracing_direct_lighting_quad' ] = `

vec3 calcDirectLightingQuad(vec3 mask, vec3 x, vec3 nl, Quad light, inout float seed)
{
	vec3 dirLight = vec3(0.0);
	Intersection shadowIntersec;
	vec3 randPointOnLight;
	randPointOnLight.x = mix(light.v0.x, light.v1.x, rand(seed));
	randPointOnLight.y = light.v0.y;
	randPointOnLight.z = mix(light.v0.z, light.v3.z, rand(seed));
	vec3 srDir = normalize(randPointOnLight - x);
	float nlDotSrDir = max(dot(nl, srDir), 0.01);
		
	// cast shadow ray from intersection point	
	Ray shadowRay = Ray(x, srDir);
	shadowRay.origin += nl * 2.0; // larger dimensions of this scene require greater offsets
	float st = SceneIntersect(shadowRay, shadowIntersec);
	if ( shadowIntersec.type == LIGHT )
	{
		float r2 = distance(light.v0, light.v1) * distance(light.v0, light.v3);
		vec3 d = randPointOnLight - shadowRay.origin;
		float d2 = dot(d, d);
		float weight = dot(-srDir, normalize(shadowIntersec.normal)) * r2 / d2;
		dirLight = mask * light.emission * nlDotSrDir * clamp(weight, 0.0, 1.0);
	}

	return dirLight;
}

`;

THREE.ShaderChunk[ 'pathtracing_main' ] = `

void main( void )
{

	vec3 camPos     = vec3( uCameraMatrix[3][0],  uCameraMatrix[3][1],  uCameraMatrix[3][2]);
	
    	vec3 camRight   = vec3( uCameraMatrix[0][0],  uCameraMatrix[0][1],  uCameraMatrix[0][2]);
    	vec3 camUp      = vec3( uCameraMatrix[1][0],  uCameraMatrix[1][1],  uCameraMatrix[1][2]);
	vec3 camForward = vec3(-uCameraMatrix[2][0], -uCameraMatrix[2][1], -uCameraMatrix[2][2]);
	
	// seed for rand(seed) function
	float seed = mod(uSampleCounter,1000.0) * uRandomVector.x - uRandomVector.y + uResolution.y * gl_FragCoord.x / uResolution.x + uResolution.x * gl_FragCoord.y / uResolution.y;
	
	float r1 = 2.0 * rand(seed);
	float r2 = 2.0 * rand(seed);
	
	vec2 d = vec2(1.0);
	if ( !uCameraIsMoving ) 
	{
		d.x = r1 < 1.0 ? sqrt(r1) - 1.0 : 1.0 - sqrt(2.0 - r1);
        	d.y = r2 < 1.0 ? sqrt(r2) - 1.0 : 1.0 - sqrt(2.0 - r2);
	}
	
	d /= (uResolution * 0.5);
	d += (2.0 * vUv - 1.0);
	
	vec3 rayDir = normalize( d.x * camRight * uULen + d.y * camUp * uVLen + camForward );
	
	// depth of field
	vec3 focalPoint = uFocusDistance * rayDir;
	float randomAngle = rand(seed) * TWO_PI; // pick random point on aperture
	float randomRadius = rand(seed) * uApertureSize;
	vec3  randomAperturePos = ( cos(randomAngle) * camRight + sin(randomAngle) * camUp ) * randomRadius;
	// point on aperture to focal point
	vec3 finalRayDir = normalize(focalPoint - randomAperturePos);
	
	Ray ray = Ray( camPos + randomAperturePos , finalRayDir );

	SetupScene();
	     		
	// perform path tracing and get resulting pixel color
	vec3 pixelColor = CalculateRadiance( ray, seed );
	
	vec3 previousColor = texture2D(tPreviousTexture, vUv).rgb;
	
	if ( uCameraJustStartedMoving )
	{
		previousColor = vec3(0.0); // clear rendering accumulation buffer
	}
	else if ( uCameraIsMoving )
	{
		previousColor *= 0.5; // motion-blur trail amount (old image)
		pixelColor *= (uSampleCounter) * 0.5; // brightness of new image (noisy)
	}
		
	gl_FragColor = vec4( pixelColor + previousColor, 1.0 );
	
}

`;