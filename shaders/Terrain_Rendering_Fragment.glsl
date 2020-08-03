precision highp float;
precision highp int;
precision highp sampler2D;

#include <pathtracing_uniforms_and_defines>
#include <pathtracing_skymodel_defines>

uniform float uCameraUnderWater;
uniform float uWaterLevel;
uniform vec3 uSunDirection;
uniform sampler2D t_PerlinNoise;

struct Ray { vec3 origin; vec3 direction; };
struct Quad { vec3 v0; vec3 v1; vec3 v2; vec3 v3; vec3 emission; vec3 color; int type; };
struct Box { vec3 minCorner; vec3 maxCorner; vec3 emission; vec3 color; int type; };
struct Intersection { vec3 normal; vec3 emission; vec3 color; vec2 uv; int type; };

#include <pathtracing_random_functions>

#include <pathtracing_calc_fresnel_reflectance>

#include <pathtracing_sphere_intersect>

#include <pathtracing_plane_intersect>

#include <pathtracing_box_intersect>

#include <pathtracing_physical_sky_functions>
	

//---------------------------------------------------------------------------------------------------------
float DisplacementBoxIntersect( vec3 minCorner, vec3 maxCorner, Ray r )
//---------------------------------------------------------------------------------------------------------
{
	vec3 invDir = 1.0 / r.direction;
	vec3 tmin = (minCorner - r.origin) * invDir;
	vec3 tmax = (maxCorner - r.origin) * invDir;
	
	vec3 real_min = min(tmin, tmax);
	vec3 real_max = max(tmin, tmax);
	
	float minmax = min( min(real_max.x, real_max.y), real_max.z);
	float maxmin = max( max(real_min.x, real_min.y), real_min.z);
	
	// early out
	if (minmax < maxmin) return INFINITY;
	
	if (maxmin > 0.0) // if we are outside the box
	{
		return maxmin;	
	}
		
	if (minmax > 0.0) // else if we are inside the box
	{
		return minmax;
	}
				
	return INFINITY;
}

// WATER
/* Credit: some of the following water code is borrowed from https://www.shadertoy.com/view/Ms2SD1 posted by user 'TDM' */

#define WATER_COLOR vec3(0.96, 1.0, 0.98)
#define WATER_SAMPLE_SCALE 0.05 
#define WATER_WAVE_HEIGHT 2.0 // max height of water waves   
#define WATER_FREQ        1.0 // wave density: lower = spread out, higher = close together
#define WATER_CHOPPY      1.0 // smaller beachfront-type waves, they travel in parallel
#define WATER_SPEED       0.5 // how quickly time passes
#define OCTAVE_M  mat2(1.6, 1.2, -1.2, 1.6);

float hash( vec2 p )
{
	float h = dot(p,vec2(127.1,311.7));	
    	return fract(sin(h)*43758.5453123);
}

float noise( in vec2 p )
{
	vec2 i = floor( p );
	vec2 f = fract( p );	
	vec2 u = f*f*(3.0-2.0*f);
	return -1.0+2.0*mix( mix( hash( i + vec2(0.0,0.0) ), 
		     hash( i + vec2(1.0,0.0) ), u.x),
		mix( hash( i + vec2(0.0,1.0) ), 
		     hash( i + vec2(1.0,1.0) ), u.x), u.y);
}

float sea_octave( vec2 uv, float choppy )
{
	uv += noise(uv);        
	vec2 wv = 1.0 - abs(sin(uv));
	vec2 swv = abs(cos(uv));    
	wv = mix(wv, swv, wv);
	return pow(1.0 - pow(wv.x * wv.y, 0.65), choppy);
}

float getOceanWaterHeight( vec3 p )
{
	float freq = WATER_FREQ;
	float amp = 1.0;
	float choppy = WATER_CHOPPY;
	float sea_time = uTime * WATER_SPEED;
	
	vec2 uv = p.xz * WATER_SAMPLE_SCALE; 
	uv.x *= 0.75;
	float d, h = 0.0;
	d =  sea_octave((uv + sea_time) * freq, choppy);
	d += sea_octave((uv - sea_time) * freq, choppy);
	h += d * amp;        
	
	return h * WATER_WAVE_HEIGHT + uWaterLevel;
}

float getOceanWaterHeight_Detail( vec3 p )
{
	float freq = WATER_FREQ;
	float amp = 1.0;
	float choppy = WATER_CHOPPY;
	float sea_time = uTime * WATER_SPEED;
	
	vec2 uv = p.xz * WATER_SAMPLE_SCALE; 
	uv.x *= 0.75;
	float d, h = 0.0;    
	for(int i = 0; i < 4; i++)
	{        
		d =  sea_octave((uv + sea_time) * freq, choppy);
		d += sea_octave((uv - sea_time) * freq, choppy);
		h += d * amp;        
		uv *= OCTAVE_M; freq *= 1.9; amp *= 0.22;
		choppy = mix(choppy, 1.0, 0.2);
	}
	return h * WATER_WAVE_HEIGHT + uWaterLevel;
}

// CLOUDS
/* Credit: some of the following cloud code is borrowed from https://www.shadertoy.com/view/XtBXDw posted by user 'valentingalea' */
#define THICKNESS      25.0
#define ABSORPTION     0.45
#define N_MARCH_STEPS  12
#define N_LIGHT_STEPS  3

float noise3D( in vec3 p )
{
	return texture(t_PerlinNoise, p.xz).x;
}

const mat3 m = 1.21 * mat3( 0.00,  0.80,  0.60,
                    -0.80,  0.36, -0.48,
		    -0.60, -0.48,  0.64 );

float fbm( vec3 p )
{
	float t;
	float mult = 2.0;
	t  = 1.0 * noise3D(p);   p = m * p * mult;
	t += 0.5 * noise3D(p);   p = m * p * mult;
	t += 0.25 * noise3D(p);
	
	return t;
}

float cloud_density( vec3 pos, float cov )
{
	float dens = fbm(pos * 0.002);
	dens *= smoothstep(cov, cov + 0.05, dens);
	return clamp(dens, 0.0, 1.0);	
}

float cloud_light( vec3 pos, vec3 dir_step, float cov )
{
	float T = 1.0; // transmitance
    	float dens;
    	float T_i;
	
	for (int i = 0; i < N_LIGHT_STEPS; i++) 
	{
		dens = cloud_density(pos, cov);
		T_i = exp(-ABSORPTION * dens);
		T *= T_i;
		pos += dir_step;
	}
	return T;
}

vec4 render_clouds( Ray eye, vec3 p, vec3 sunDirection )
{
	float march_step = THICKNESS / float(N_MARCH_STEPS);
	vec3 pos = p + vec3(uTime * -3.0, uTime * -0.5, uTime * -2.0);
	vec3 dir_step = eye.direction / clamp(eye.direction.y, 0.3, 1.0) * march_step;
	vec3 light_step = normalize(sunDirection) * 5.0;
	
	float covAmount = (sin(mod(uTime * 0.1 + 3.5, TWO_PI))) * 0.5 + 0.5;
	float coverage = mix(1.1, 1.5, clamp(covAmount, 0.0, 1.0));
	float T = 1.0; // transmitance
	vec3 C = vec3(0); // color
	float alpha = 0.0;
	float dens;
	float T_i;
	float cloudLight;
	
	for (int i = 0; i < N_MARCH_STEPS; i++)
	{
		dens = cloud_density(pos, coverage);
		T_i = exp(-ABSORPTION * dens * march_step);
		T *= T_i;
		cloudLight = cloud_light(pos, light_step, coverage);
		C += T * cloudLight * dens * march_step;
		C = mix(C * 0.95, C, cloudLight);
		alpha += (1.0 - T_i) * (1.0 - alpha);
		pos += dir_step;
	}
	
	return vec4(C, alpha);
}

// TERRAIN
#define TERRAIN_HEIGHT 2000.0
#define TERRAIN_SAMPLE_SCALE 0.00004 
#define TERRAIN_LIFT -1300.0 // how much to lift or drop the entire terrain
#define TERRAIN_FAR 100000.0

float lookup_Heightmap( in vec3 pos )
{
	vec2 uv = pos.xz;
	uv *= TERRAIN_SAMPLE_SCALE;
	float h = 0.0;
	float mult = 1.0;
	for (int i = 0; i < 4; i ++)
	{
		h += mult * texture(t_PerlinNoise, uv + 0.5).x;
		mult *= 0.5;
		uv *= 2.0;
	}
	return h * TERRAIN_HEIGHT + TERRAIN_LIFT;	
}

float lookup_Normal( in vec3 pos )
{
	vec2 uv = pos.xz;
	uv *= TERRAIN_SAMPLE_SCALE;
	float h = 0.0;
	float mult = 1.0;
	for (int i = 0; i < 9; i ++)
	{
		h += mult * texture(t_PerlinNoise, uv + 0.5).x;
		mult *= 0.5;
		uv *= 2.0;
	}
	return h * TERRAIN_HEIGHT + TERRAIN_LIFT; 
}

vec3 terrain_calcNormal( vec3 pos, float t )
{
	vec3 eps = vec3(uEPS_intersect, 0.0, 0.0);
	
	return normalize( vec3( lookup_Normal(pos-eps.xyy) - lookup_Normal(pos+eps.xyy),
			  	eps.x * 2.0,
			  	lookup_Normal(pos-eps.yyx) - lookup_Normal(pos+eps.yyx) ) );
}

bool isLightSourceVisible( vec3 pos, vec3 n, vec3 dirToLight)
{
	dirToLight = normalize(dirToLight);
	float h = 1.0;
	float t = 0.0;
	float terrainHeight = TERRAIN_HEIGHT * 2.0 + TERRAIN_LIFT;

	for(int i = 0; i < 300; i++)
	{
		h = pos.y - lookup_Heightmap(pos);
		if ( pos.y > terrainHeight || h < 0.0) break;
		pos += dirToLight * h;
	}
	return h >= 0.0;
}


//-----------------------------------------------------------------------------------------------------------------------------------------------------------------------
float SceneIntersect( Ray r, inout Intersection intersec, bool checkWater )
//-----------------------------------------------------------------------------------------------------------------------------------------------------------------------
{
	vec3 normal;
	float d = 0.0;
	float dp = 0.0;
	float t = INFINITY;
	vec3 hitPos;
	float terrainHeight;
	float waterWaveHeight;
	// Terrain
	vec3 pos = r.origin;
	vec3 dir = normalize(r.direction);
	float h = 0.0;
	
	for (int i = 0; i < 300; i++)
	{
		h = pos.y - lookup_Heightmap(pos);
		if (d > TERRAIN_FAR || h < 1.0) break;
		d += h * 0.45;
		pos += dir * h * 0.45; 
	}
	hitPos = pos;
	if (h >= 1.0) d = INFINITY;
	if (d > TERRAIN_FAR)
	{
		dp = PlaneIntersect( vec4(0, 1, 0, uWaterLevel), r );
		if (dp < d)
		{
			hitPos = r.origin + r.direction * dp;
			terrainHeight = lookup_Heightmap(hitPos);
			d = DisplacementBoxIntersect( vec3(-INFINITY, -INFINITY, -INFINITY), vec3(INFINITY, terrainHeight, INFINITY), r);
		}
		
	}
	if (d < t)
	{
		t = d;
		intersec.normal = terrain_calcNormal(hitPos, t);
		intersec.emission = vec3(0);
		intersec.color = vec3(0);
		intersec.type = TERRAIN;
	}
	
	if ( !checkWater )
		return t;
	
	pos = r.origin; // reset pos
	dir = r.direction; // reset dir
	h = 0.0; // reset h
	d = 0.0; // reset d
	for(int i = 0; i < 50; i++)
	{
		h = abs(pos.y - getOceanWaterHeight(pos));
		if (d > 1000.0 || h < 1.0) break;
		d += h;
		pos += dir * h; 
	}
	hitPos = pos;
	if (h >= 1.0) d = INFINITY;
	
	if (d > 1000.0)
	{
		dp = PlaneIntersect( vec4(0, 1, 0, uWaterLevel), r );
		if ( dp < d )
		{
			hitPos = r.origin + r.direction * dp;
			waterWaveHeight = getOceanWaterHeight_Detail(hitPos);
			d = DisplacementBoxIntersect( vec3(-INFINITY, -INFINITY, -INFINITY), vec3(INFINITY, waterWaveHeight, INFINITY), r);
		}
		
	}
	
	if (d < t) 
	{
		float eps = 1.0;
		t = d;
		float dx = getOceanWaterHeight_Detail(hitPos - vec3(eps,0,0)) - getOceanWaterHeight_Detail(hitPos + vec3(eps,0,0));
		float dy = eps * 2.0; // (the water wave height is a function of x and z, not dependent on y)
		float dz = getOceanWaterHeight_Detail(hitPos - vec3(0,0,eps)) - getOceanWaterHeight_Detail(hitPos + vec3(0,0,eps));
		
		intersec.normal = normalize(vec3(dx,dy,dz));
		intersec.emission = vec3(0);
		intersec.color = vec3(0.6, 1.0, 1.0);
		intersec.type = REFR;
	}
		
	return t;
}


//-----------------------------------------------------------------------
vec3 CalculateRadiance( Ray r, vec3 sunDirection, inout uvec2 seed )
//-----------------------------------------------------------------------
{
	Intersection intersec;
	Ray firstRay;
	Ray cameraRay = r;

	vec3 randVec = vec3(rand(seed) * 2.0 - 1.0, rand(seed) * 2.0 - 1.0, rand(seed) * 2.0 - 1.0);
	vec3 initialSkyColor = Get_Sky_Color(r, normalize(sunDirection));
	
	Ray skyRay = Ray( r.origin * vec3(0.02), normalize(vec3(r.direction.x, abs(r.direction.y), r.direction.z)) );
	float dc = SphereIntersect( 20000.0, vec3(skyRay.origin.x, -19900.0, skyRay.origin.z) + vec3(rand(seed) * 2.0), skyRay );
	vec3 skyPos = skyRay.origin + skyRay.direction * dc;
	vec4 cld = render_clouds(skyRay, skyPos, normalize(sunDirection));
	
	
	vec3 accumCol = vec3(0);
	vec3 terrainCol = vec3(0);
        vec3 mask = vec3(1);
	vec3 firstMask = vec3(1);
	vec3 n, nl, x;
	vec3 firstX = vec3(0);
	vec3 tdir;
	
	float nc, nt, ratioIoR, Re, Tr;
	float t = INFINITY;
	float thickness = 0.01;

	bool checkWater = true;
	bool skyHit = false;
	bool firstTypeWasREFR = false;
	bool reflectionTime = false;
	bool rayEnteredWater = false;
	
	
        for (int bounces = 0; bounces < 3; bounces++)
	{
		
		t = SceneIntersect(r, intersec, checkWater);
		checkWater = false;

		if (t == INFINITY)
		{
			if (bounces == 0) // ray hits sky first	
			{
				skyHit = true;
				firstX = skyPos;
				accumCol = initialSkyColor;
				break; // exit early	
			}

			if (firstTypeWasREFR)
			{
				if (!reflectionTime) 
				{
					accumCol = mask * Get_Sky_Color(r, normalize(sunDirection));
					
					// start back at the refractive surface, but this time follow reflective branch
					r = firstRay;
					mask = firstMask;
					// set/reset variables
					reflectionTime = true;
					// continue with the reflection ray
					continue;
				}

				accumCol += mask * Get_Sky_Color(r, normalize(sunDirection)); // add reflective result to the refractive result (if any)
			}
			else 
				accumCol = mask * Get_Sky_Color(r, normalize(sunDirection));
			/*
			else if (dot(r.direction, sunDirection) < 0.98)
				accumCol = mask * 2.0 * Get_Sky_Color(r, sunDirection);
			else 
				accumCol = mask * 0.03 * Get_Sky_Color(r, sunDirection);
			*/

			// reached the sky light, so we can exit
			break;
		} // end if (t == INFINITY)
		
		
		// useful data 
		n = normalize(intersec.normal);
                nl = dot(n, r.direction) < 0.0 ? normalize(n) : normalize(-n);
		x = r.origin + r.direction * t;
		
		if (bounces == 0) 
			firstX = x;
		
		// ray hits terrain
		if (intersec.type == TERRAIN)
		{
			float rockNoise = texture(t_PerlinNoise, (0.0003 * x.xz)).x;
			vec3 rockColor0 = max(vec3(0.01), vec3(0.04, 0.01, 0.01) * rockNoise);
			vec3 rockColor1 = max(vec3(0.01), vec3(0.08, 0.07, 0.07) * rockNoise);
			vec3 snowColor = vec3(0.9);
			vec3 up = normalize(vec3(0, 1, 0));
			vec3 randomSkyVec = normalize(vec3(randVec.x, abs(randVec.y), randVec.z));
			vec3 skyColor = clamp(Get_Sky_Color( Ray(x, normalize(up + (n * 0.1))), normalize(sunDirection) ), 0.0, 1.0);
			vec3 sunColor = clamp(Get_Sky_Color( Ray(x, normalize(normalize(vec3(sunDirection.x, sunDirection.y + 0.05, sunDirection.z)) + (randomSkyVec * 0.1))), normalize(sunDirection) ), 0.0, 1.0);
			float terrainLayer = clamp( (x.y + (rockNoise * 500.0) * n.y) / (TERRAIN_HEIGHT * 1.5 + TERRAIN_LIFT), 0.0, 1.0 );
			
			if (terrainLayer > 0.8 && terrainLayer > 1.0 - n.y)
			{
				intersec.color = mix(vec3(0.7), snowColor, terrainLayer * n.y);
				mask = mix(intersec.color * skyColor, intersec.color * sunColor, dot(normalize(sunDirection), up));// ambient color from sky light
			}	
			else
			{
				intersec.color = mix(rockColor0, rockColor1, clamp(n.y, 0.0, 1.0) );
				mask = intersec.color * skyColor; // ambient color from sky light
			}		
			
			vec3 shadowRayDirection = normalize(normalize(sunDirection) + (randomSkyVec * 0.05));						
			if (bounces == 0 && isLightSourceVisible(x, n, shadowRayDirection) ) // in direct sunlight
			{
				mask = intersec.color * sunColor;	
			}

			if (rayEnteredWater)
			{
				rayEnteredWater = false;
				mask *= exp(log(WATER_COLOR) * thickness * t); 
			}

			if (firstTypeWasREFR)
			{
				if (!reflectionTime) 
				{	
					accumCol = mask;
					// start back at the refractive surface, but this time follow reflective branch
					r = firstRay;
					r.direction = normalize(r.direction);
					mask = firstMask;
					// set/reset variables
					reflectionTime = true;
					// continue with the reflection ray
					continue;
				}

				accumCol += mask;
				break;
			}

			accumCol = mask;	
			break;
		}
		
		if (intersec.type == REFR)  // Ideal dielectric REFRACTION
		{
			nc = 1.0; // IOR of air
			nt = 1.33; // IOR of water
			Re = calcFresnelReflectance(r.direction, n, nc, nt, ratioIoR);
			Tr = 1.0 - Re;
			
			if (bounces == 0)
			{	
				// save intersection data for future reflection trace
				firstTypeWasREFR = true;
				firstMask = mask * Re;
				firstRay = Ray( x, reflect(r.direction, nl) ); // create reflection ray from surface
				firstRay.origin += nl * uEPS_intersect;
				mask *= Tr;
				rayEnteredWater = true;
			}
			
			// is ray leaving a solid object from the inside? 
			// If so, attenuate ray color with object color by how far ray has travelled through the medium
			if (distance(n, nl) > 0.1)
			{
				rayEnteredWater = false;
				mask *= exp(log(WATER_COLOR) * thickness * t);
			}
			
			tdir = refract(r.direction, nl, ratioIoR);
			r = Ray(x, normalize(tdir));
			r.origin -= nl * uEPS_intersect;
			
			continue;
			
		} // end if (intersec.type == REFR)
		
	} // end for (int bounces = 0; bounces < 3; bounces++)
	
	
	// atmospheric haze effect (aerial perspective)
	float hitDistance;
	
	if ( skyHit ) // sky and clouds
	{
		vec3 cloudColor = cld.rgb / (cld.a + 0.00001);
		vec3 sunColor = clamp(Get_Sky_Color( Ray(skyPos, normalize((randVec * 0.03) + sunDirection)), sunDirection ), 0.0, 1.0);
		
		cloudColor *= mix(sunColor, vec3(1), max(0.0, dot(vec3(0,1,0), sunDirection)) );
		cloudColor = mix(initialSkyColor, cloudColor, clamp(cld.a, 0.0, 1.0));
		
		hitDistance = distance(skyRay.origin, skyPos);
		accumCol = mask * mix( accumCol, cloudColor, clamp( exp2( -hitDistance * 0.004 ), 0.0, 1.0 ) );
	}	
	else // terrain and other objects
	{
		hitDistance = distance(cameraRay.origin, firstX);
		accumCol = mix( initialSkyColor, accumCol, clamp( exp2( -log(hitDistance * 0.00008) ), 0.0, 1.0 ) );
		// underwater fog effect
		hitDistance = distance(cameraRay.origin, firstX);
		hitDistance *= uCameraUnderWater;
		accumCol = mix( vec3(0.0,0.05,0.05), accumCol, clamp( exp2( -hitDistance * 0.001 ), 0.0, 1.0 ) );
	}
	
	
	return max(vec3(0), accumCol); // prevents black spot artifacts appearing in the water 
	      
}

/*
// not needed in this demo, all objects are procedurally generated
//-----------------------------------------------------------------------
void SetupScene(void)
//-----------------------------------------------------------------------
{
	vec3 z  = vec3(0);// No color value, Black        
	
}
*/


// tentFilter from Peter Shirley's 'Realistic Ray Tracing (2nd Edition)' book, pg. 60		
float tentFilter(float x)
{
	if (x < 0.5) 
		return sqrt(2.0 * x) - 1.0;
	else return 1.0 - sqrt(2.0 - (2.0 * x));
}

void main( void )
{
	// not needed, three.js has a built-in uniform named cameraPosition
	//vec3 camPos   = vec3( uCameraMatrix[3][0],  uCameraMatrix[3][1],  uCameraMatrix[3][2]);
	
    	vec3 camRight   = vec3( uCameraMatrix[0][0],  uCameraMatrix[0][1],  uCameraMatrix[0][2]);
    	vec3 camUp      = vec3( uCameraMatrix[1][0],  uCameraMatrix[1][1],  uCameraMatrix[1][2]);
	vec3 camForward = vec3(-uCameraMatrix[2][0], -uCameraMatrix[2][1], -uCameraMatrix[2][2]);
	
	// seed for rand(seed) function
	uvec2 seed = uvec2(uFrameCounter, uFrameCounter + 1.0) * uvec2(gl_FragCoord);

	vec2 pixelPos = vec2(0);
	vec2 pixelOffset = vec2(0);
	
	float x = rand(seed);
	float y = rand(seed);

	//if (!uCameraIsMoving)
	{
		pixelOffset.x = tentFilter(x);
		pixelOffset.y = tentFilter(y);
	}
	
	// pixelOffset ranges from -1.0 to +1.0, so only need to divide by half resolution
	pixelOffset /= (uResolution * 1.0); // normally this is * 0.5, but for dynamic scenes, * 1.0 looks sharper

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
    
	Ray ray = Ray( cameraPosition + randomAperturePos, finalRayDir );

	//SetupScene(); 

	// perform path tracing and get resulting pixel color
	vec3 pixelColor = CalculateRadiance( ray, uSunDirection, seed );
	
	vec3 previousColor = texelFetch(tPreviousTexture, ivec2(gl_FragCoord.xy), 0).rgb;
	
	if ( uCameraIsMoving )
	{
		previousColor *= 0.8; // motion-blur trail amount (old image)
		pixelColor *= 0.2; // brightness of new image (noisy)
	}
	else
	{
		previousColor *= 0.9; // motion-blur trail amount (old image)
		pixelColor *= 0.1; // brightness of new image (noisy)
	}
	
	
	pc_fragColor = vec4( pixelColor + previousColor, 1.0 );	
}
