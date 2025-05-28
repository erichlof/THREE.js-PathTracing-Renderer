precision highp float;
precision highp int;
precision highp sampler2D;

uniform sampler2D t_PerlinNoise;
uniform float uCameraUnderWater;
uniform vec3 uSunDirection;

uniform mat4 uShortBoxInvMatrix;
uniform mat4 uTallBoxInvMatrix;

#include <pathtracing_uniforms_and_defines>

#include <pathtracing_calc_fresnel_reflectance>

#include <pathtracing_skymodel_defines>

#define N_QUADS 4
#define N_BOXES 2
#define N_OPENCYLINDERS 4


//-----------------------------------------------------------------------

vec3 rayOrigin, rayDirection;
// recorded intersection data:
vec3 hitNormal, hitEmission, hitColor;
vec2 hitUV;
float hitObjectID = -INFINITY;
int hitType = -100;

struct OpenCylinder { float radius; vec3 pos1; vec3 pos2; vec3 emission; vec3 color; int type; };
struct Quad { vec3 normal; vec3 v0; vec3 v1; vec3 v2; vec3 v3; vec3 emission; vec3 color; int type; };
struct Box { vec3 minCorner; vec3 maxCorner; vec3 emission; vec3 color; int type; };


OpenCylinder openCylinders[N_OPENCYLINDERS];
Quad quads[N_QUADS];
Box boxes[N_BOXES];


#include <pathtracing_random_functions>

#include <pathtracing_sphere_intersect>

#include <pathtracing_opencylinder_intersect>

#include <pathtracing_plane_intersect>

#include <pathtracing_quad_intersect>

#include <pathtracing_box_intersect>

#include <pathtracing_physical_sky_functions>


//---------------------------------------------------------------------------------------------------------
float DisplacementBoxIntersect( vec3 minCorner, vec3 maxCorner, vec3 rayOrigin, vec3 rayDirection )
//---------------------------------------------------------------------------------------------------------
{
	vec3 invDir = 1.0 / rayDirection;
	vec3 tmin = (minCorner - rayOrigin) * invDir;
	vec3 tmax = (maxCorner - rayOrigin) * invDir;
	
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


// SEA
/* Credit: some of the following ocean code is borrowed from https://www.shadertoy.com/view/Ms2SD1 posted by user 'TDM' */

#define SEA_HEIGHT     1.0 // this is how many units from the top of the ocean bounding box
#define SEA_FREQ       1.5 // wave density: lower = spread out, higher = close together
#define SEA_CHOPPY     2.0 // smaller beachfront-type waves, they travel in parallel
#define SEA_SPEED      0.15 // how quickly time passes
#define OCTAVE_M   mat2(1.6, 1.2, -1.2, 1.6);

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
	wv = mix(wv, swv, clamp(wv, 0.0, 1.0));
	return pow(1.0 - pow(wv.x * wv.y, 0.65), choppy);
}

float getOceanWaterHeight( vec3 p )
{
	p.x *= 0.001;
	p.z *= 0.001;
	float freq = SEA_FREQ;
	float amp = SEA_HEIGHT;
	float choppy = SEA_CHOPPY;
	float sea_time = uTime * SEA_SPEED;
	
	vec2 uv = p.xz; uv.x *= 0.75;
	float d, h = 0.0;

	d =  sea_octave((uv + sea_time) * freq, choppy);
	d += sea_octave((uv - sea_time) * freq, choppy);
	h += d * amp;        
	
	return 50.0 * h - 10.0;
}

float getOceanWaterHeight_Detail( vec3 p )
{
	p.x *= 0.001;
	p.z *= 0.001;
	float freq = SEA_FREQ;
	float amp = SEA_HEIGHT;
	float choppy = SEA_CHOPPY;
	float sea_time = uTime * SEA_SPEED;
	
	vec2 uv = p.xz; uv.x *= 0.75;
	float d, h = 0.0;    
	for(int i = 0; i < 4; i++)
	{        
		d =  sea_octave((uv + sea_time) * freq, choppy);
		d += sea_octave((uv - sea_time) * freq, choppy);
		h += d * amp;        
		uv *= OCTAVE_M; freq *= 1.9; amp *= 0.22;
		choppy = mix(choppy, 1.0, 0.2);
	}
	return 50.0 * h - 10.0;
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

vec4 render_clouds(vec3 rayOrigin, vec3 rayDirection)
{
	float march_step = THICKNESS / float(N_MARCH_STEPS);
	vec3 pos = rayOrigin + vec3(uTime * -3.0, uTime * -0.5, uTime * -2.0);
	vec3 dir_step = rayDirection / clamp(rayDirection.y, 0.3, 1.0) * march_step;
	vec3 light_step = uSunDirection * 5.0;
	
	float covAmount = (sin(mod(uTime * 0.1, TWO_PI))) * 0.5 + 0.5;
	float coverage = mix(1.0, 1.5, clamp(covAmount, 0.0, 1.0));
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
		C = mix(C * 0.95, C, clamp(cloudLight, 0.0, 1.0));
		alpha += (1.0 - T_i) * (1.0 - alpha);
		pos += dir_step;
	}
	
	return vec4(C, alpha);
}

float checkCloudCover(vec3 rayOrigin, vec3 rayDirection)
{
	float march_step = THICKNESS / float(N_MARCH_STEPS);
	vec3 pos = rayOrigin + vec3(uTime * -3.0, uTime * -0.5, uTime * -2.0);
	vec3 dir_step = rayDirection / clamp(rayDirection.y, 0.001, 1.0) * march_step;
	
	float covAmount = (sin(mod(uTime * 0.1, TWO_PI))) * 0.5 + 0.5;
	float coverage = mix(1.0, 1.5, clamp(covAmount, 0.0, 1.0));
	float alpha = 0.0;
	float dens;
	float T_i;
	
	for (int i = 0; i < N_MARCH_STEPS; i++)
	{
		dens = cloud_density(pos, coverage);
		T_i = exp(-ABSORPTION * dens * march_step);
		alpha += (1.0 - T_i) * (1.0 - alpha);
		pos += dir_step;
	}
	
	return clamp(1.0 - alpha, 0.0, 1.0);
}


//-----------------------------------------------------------------------------------------------------------------------------------------------------------------------
float SceneIntersect( int checkOcean )
//-----------------------------------------------------------------------------------------------------------------------------------------------------------------------
{
	vec3 rObjOrigin, rObjDirection;

	vec3 hitObjectSpace;
	vec3 hitWorldSpace;
	vec3 normal;
	vec3 pos;
	vec3 dir;

	float h;
        float d, dw, dc;
	float dx, dy, dz;
	float t = INFINITY;
        float eps = 0.1;
	float waterWaveHeight;

	int objectCount = 0;

	int isRayExiting = FALSE;
	
	
	
	// SEA FLOOR
	d = PlaneIntersect(vec4(0, 1, 0, -1000.0), rayOrigin, rayDirection);
	if (d < t)
	{
		t = d;
		hitNormal = vec3(0,1,0);
		hitEmission = vec3(0);
		hitColor = vec3(0.0, 0.07, 0.07);
		hitType = SEAFLOOR;
		hitObjectID = -1.0;
	}
	
	d = OpenCylinderIntersect( openCylinders[0].pos1, openCylinders[0].pos2, openCylinders[0].radius, rayOrigin, rayDirection, normal );
	if (d < t)
	{
		t = d;
		hitNormal = normal;
		hitEmission = vec3(0);
		hitColor = openCylinders[0].color;
		hitType = WOOD;
		hitObjectID = float(objectCount);
	}
	objectCount++;

	d = OpenCylinderIntersect( openCylinders[1].pos1, openCylinders[1].pos2, openCylinders[1].radius, rayOrigin, rayDirection, normal );
	if (d < t)
	{
		t = d;
		hitNormal = normal;
		hitEmission = vec3(0);
		hitColor = openCylinders[0].color;
		hitType = WOOD;
		hitObjectID = float(objectCount);
	}
	objectCount++;

	d = OpenCylinderIntersect( openCylinders[2].pos1, openCylinders[2].pos2, openCylinders[2].radius, rayOrigin, rayDirection, normal );
	if (d < t)
	{
		t = d;
		hitNormal = normal;
		hitEmission = vec3(0);
		hitColor = openCylinders[0].color;
		hitType = WOOD;
		hitObjectID = float(objectCount);
	}
	objectCount++;

	d = OpenCylinderIntersect( openCylinders[3].pos1, openCylinders[3].pos2, openCylinders[3].radius, rayOrigin, rayDirection, normal );
	if (d < t)
	{
		t = d;
		hitNormal = normal;
		hitEmission = vec3(0);
		hitColor = openCylinders[0].color;
		hitType = WOOD;
		hitObjectID = float(objectCount);
	}
	objectCount++;
	

	d = QuadIntersect( quads[0].v0, quads[0].v1, quads[0].v2, quads[0].v3, rayOrigin, rayDirection, TRUE );
	if (d < t)
	{
		t = d;
		hitNormal = quads[0].normal;
		hitEmission = quads[0].emission;
		hitColor = quads[0].color;
		hitType = quads[0].type;
		hitObjectID = float(objectCount);
	}
	objectCount++;

	d = QuadIntersect( quads[1].v0, quads[1].v1, quads[1].v2, quads[1].v3, rayOrigin, rayDirection, TRUE );
	if (d < t)
	{
		t = d;
		hitNormal = quads[1].normal;
		hitEmission = quads[1].emission;
		hitColor = quads[1].color;
		hitType = quads[1].type;
		hitObjectID = float(objectCount);
	}
	objectCount++;

	d = QuadIntersect( quads[2].v0, quads[2].v1, quads[2].v2, quads[2].v3, rayOrigin, rayDirection, TRUE );
	if (d < t)
	{
		t = d;
		hitNormal = quads[2].normal;
		hitEmission = quads[2].emission;
		hitColor = quads[2].color;
		hitType = quads[2].type;
		hitObjectID = float(objectCount);
	}
	objectCount++;

	d = QuadIntersect( quads[3].v0, quads[3].v1, quads[3].v2, quads[3].v3, rayOrigin, rayDirection, TRUE );
	if (d < t)
	{
		t = d;
		hitNormal = quads[3].normal;
		hitEmission = quads[3].emission;
		hitColor = quads[3].color;
		hitType = quads[3].type;
		hitObjectID = float(objectCount);
	}
	objectCount++;

	
	// TALL MIRROR BOX
	// transform ray into Tall Box's object space
	rObjOrigin = vec3( uTallBoxInvMatrix * vec4(rayOrigin, 1.0) );
	rObjDirection = vec3( uTallBoxInvMatrix * vec4(rayDirection, 0.0) );
	d = BoxIntersect( boxes[0].minCorner, boxes[0].maxCorner, rObjOrigin, rObjDirection, normal, isRayExiting );
	
	if (d < t)
	{	
		t = d;
		
		// transfom normal back into world space
		hitNormal = transpose(mat3(uTallBoxInvMatrix)) * normal;
		hitEmission = boxes[0].emission;
		hitColor = boxes[0].color;
		hitType = boxes[0].type;
		hitObjectID = float(objectCount);
	}
	objectCount++;
	
	
	// SHORT DIFFUSE WHITE BOX
	// transform ray into Short Box's object space
	rObjOrigin = vec3( uShortBoxInvMatrix * vec4(rayOrigin, 1.0) );
	rObjDirection = vec3( uShortBoxInvMatrix * vec4(rayDirection, 0.0) );
	d = BoxIntersect( boxes[1].minCorner, boxes[1].maxCorner, rObjOrigin, rObjDirection, normal, isRayExiting );
	
	if (d < t)
	{	
		t = d;
		
		// transfom normal back into world space
		hitNormal = transpose(mat3(uShortBoxInvMatrix)) * normal;
		hitEmission = boxes[1].emission;
		hitColor = boxes[1].color;
		hitType = boxes[1].type;
		hitObjectID = float(objectCount);
	}
	objectCount++;
	
	
	///////////////////////////////////////////////////////////////////////////////////////////////////////
	// OCEAN 
	///////////////////////////////////////////////////////////////////////////////////////////////////////
	
	if ( checkOcean == FALSE )
	{
		return t;
	}

	pos = rayOrigin;
	dir = rayDirection;
	h = 0.0;
	d = 0.0; // reset d

	for(int i = 0; i < 100; i++)
	{
		h = abs(pos.y - getOceanWaterHeight(pos));
		if (d > 4000.0 || h < 1.0) break;
		d += h;
		pos += dir * h; 
	}
	hitWorldSpace = pos;
	
	if (d > 4000.0)
	{
		d = PlaneIntersect( vec4(0, 1, 0, 0.0), rayOrigin, rayDirection );
		if ( d >= INFINITY ) return t;
		hitWorldSpace = rayOrigin + rayDirection * d;
		
		waterWaveHeight = getOceanWaterHeight_Detail(hitWorldSpace);
		d = DisplacementBoxIntersect( vec3(-INFINITY, -INFINITY, -INFINITY), vec3(INFINITY, waterWaveHeight, INFINITY), rayOrigin, rayDirection);
		hitWorldSpace = rayOrigin + rayDirection * d;
	}
	
	if (d < t) 
	{
		eps = 1.0;
		t = d;
		dx = getOceanWaterHeight_Detail(hitWorldSpace - vec3(eps,0,0)) - getOceanWaterHeight_Detail(hitWorldSpace + vec3(eps,0,0));
		dy = eps * 2.0; // (the water wave height is a function of x and z, not dependent on y)
		dz = getOceanWaterHeight_Detail(hitWorldSpace - vec3(0,0,eps)) - getOceanWaterHeight_Detail(hitWorldSpace + vec3(0,0,eps));
		
		hitNormal = vec3(dx,dy,dz);
		hitEmission = vec3(0);
		hitColor = vec3(0.6, 1.0, 1.0);
		hitType = REFR;
		hitObjectID = -1.0; // same as sea floor above
	}
	
	
	return t;
}


//-----------------------------------------------------------------------------------------------------------------------------------------
vec3 CalculateRadiance(out vec3 objectNormal, out vec3 objectColor, out float objectID, out float pixelSharpness)
//-----------------------------------------------------------------------------------------------------------------------------------------
{
	vec3 skyRayOrigin, skyRayDirection;
	vec3 cameraRayOrigin, cameraRayDirection;
	vec3 cloudShadowRayOrigin, cloudShadowRayDirection;
	cameraRayOrigin = rayOrigin;
	cameraRayDirection = rayDirection;

	vec3 randVec = vec3(rng() * 2.0 - 1.0, rng() * 2.0 - 1.0, rng() * 2.0 - 1.0);
	randVec = normalize(randVec);

	vec3 initialSkyColor = Get_Sky_Color(rayDirection);
	
	skyRayOrigin = rayOrigin * vec3(0.02);
	skyRayDirection = normalize(vec3(rayDirection.x, abs(rayDirection.y), rayDirection.z));
	float dc = SphereIntersect( 20000.0, vec3(skyRayOrigin.x, -19900.0, skyRayOrigin.z) + vec3(rng() * 2.0), skyRayOrigin, skyRayDirection );
	vec3 skyPos = skyRayOrigin + skyRayDirection * dc;
	vec4 cld = render_clouds(skyPos, skyRayDirection);
	
	cloudShadowRayOrigin = rayOrigin * vec3(0.02);
	cloudShadowRayDirection = normalize(uSunDirection + (randVec * 0.05));
	float dcs = SphereIntersect( 20000.0, vec3(skyRayOrigin.x, -19900.0, skyRayOrigin.z) + vec3(rng() * 2.0), cloudShadowRayOrigin, cloudShadowRayDirection );
	vec3 cloudShadowPos = cloudShadowRayOrigin + cloudShadowRayDirection * dcs;
	float cloudShadowFactor = checkCloudCover(cloudShadowPos, cloudShadowRayDirection);
	
	vec3 accumCol = vec3(0);
        vec3 mask = vec3(1);
	vec3 reflectionMask = vec3(1);
	vec3 reflectionRayOrigin = vec3(0);
	vec3 reflectionRayDirection = vec3(0);
	vec3 diffuseBounceMask = vec3(1);
	vec3 diffuseBounceRayOrigin = vec3(0);
	vec3 diffuseBounceRayDirection = vec3(0);
	vec3 n, nl, x;
	vec3 firstX = vec3(0);
	
	float nc, nt, ratioIoR, Re, Tr;
	float weight;
	float t = INFINITY;
	float previousObjectID;
	
	int reflectionBounces = -1;
	int diffuseCount = 0;
	int previousIntersecType = -100;
	hitType = -100;

	int checkOcean = TRUE;
	int skyHit = FALSE;
	int sampleLight = FALSE;
	int bounceIsSpecular = TRUE;
	int willNeedReflectionRay = FALSE;
	int isReflectionTime = FALSE;
	int reflectionNeedsToBeSharp = FALSE;
	int willNeedDiffuseBounceRay = FALSE;
	int isDiffuseBounceTime = FALSE;
	
	
        for (int bounces = 0; bounces < 10; bounces++)
	{
		if (isReflectionTime == TRUE)
			reflectionBounces++;

		previousIntersecType = hitType;
		previousObjectID = hitObjectID;

		t = SceneIntersect(checkOcean);
		checkOcean = FALSE;

		if (t == INFINITY)
		{
			// keeps edges of objects against background sky sharp
			if (bounceIsSpecular == TRUE && isReflectionTime == FALSE)
				pixelSharpness = 1.0;

			vec3 skyColor = Get_Sky_Color(rayDirection);

			if (bounces == 0) // ray hits sky first
			{
				skyHit = TRUE;
				firstX = skyPos;
				initialSkyColor = skyColor;
				accumCol += skyColor;
				break; // exit early	
			}
			else if (bounces == 1 && previousIntersecType == SPEC) // ray reflects off of mirror box first, then hits sky
			{
				skyHit = TRUE;
				firstX = skyPos;
				initialSkyColor = mask * skyColor;
				accumCol += initialSkyColor;
				//break; // exit early	
			}
			else if (diffuseCount == 0 && bounceIsSpecular == TRUE) // ray reflects off of the ocean
			{
				pixelSharpness = 1.0;
				//skyHit = TRUE;
				firstX = skyPos;
				initialSkyColor = mask * skyColor;
				accumCol += initialSkyColor;
				//break; // exit early	
			}	
			else if (sampleLight == TRUE) // diffuse direct sun light sampling (Cornell Box) 
			{
				accumCol += mask * skyColor;
				//break;
			}
			else if (diffuseCount > 0) // random diffuse ray hit sky (don't count Sun hits, otherwise will make fireflies)
			{
				weight = dot(rayDirection, uSunDirection) < 0.99 ? 1.0 : 0.0;
				accumCol += mask * skyColor * weight;
				//break;
			}

			if (willNeedDiffuseBounceRay == TRUE)
			{
				mask = diffuseBounceMask;
				rayOrigin = diffuseBounceRayOrigin;
				rayDirection = diffuseBounceRayDirection;

				willNeedDiffuseBounceRay = FALSE;
				bounceIsSpecular = FALSE;
				sampleLight = FALSE;
				isDiffuseBounceTime = TRUE;
				isReflectionTime = FALSE;
				diffuseCount = 1;
				continue;
			}

			if (willNeedReflectionRay == TRUE)
			{
				mask = reflectionMask;
				rayOrigin = reflectionRayOrigin;
				rayDirection = reflectionRayDirection;

				willNeedReflectionRay = FALSE;
				bounceIsSpecular = TRUE;
				sampleLight = FALSE;
				isReflectionTime = TRUE;
				isDiffuseBounceTime = FALSE;
				diffuseCount = 0;
				continue;
			}
			// reached the sky light, so we can exit
			break;
		} // end if (t == INFINITY)

		
		if (hitType == SEAFLOOR)
		{

			float waterDotSun = max(0.0, dot(vec3(0,1,0), uSunDirection));
			float waterDotCamera = max(0.4, dot(vec3(0,1,0), -cameraRayDirection));

			accumCol += mask * hitColor * waterDotSun * waterDotCamera;

			if (willNeedDiffuseBounceRay == TRUE)
			{
				mask = diffuseBounceMask;
				rayOrigin = diffuseBounceRayOrigin;
				rayDirection = diffuseBounceRayDirection;

				willNeedDiffuseBounceRay = FALSE;
				bounceIsSpecular = FALSE;
				sampleLight = FALSE;
				isDiffuseBounceTime = TRUE;
				isReflectionTime = FALSE;
				diffuseCount = 1;
				continue;
			}

			if (willNeedReflectionRay == TRUE)
			{
				mask = reflectionMask;
				rayOrigin = reflectionRayOrigin;
				rayDirection = reflectionRayDirection;

				willNeedReflectionRay = FALSE;
				bounceIsSpecular = TRUE;
				sampleLight = FALSE;
				isReflectionTime = TRUE;
				isDiffuseBounceTime = FALSE;
				diffuseCount = 0;
				continue;
			}

			break;
		} // end if (hitType == SEAFLOOR)


		// if we get here and sampleLight is still TRUE, shadow ray failed to find the light source 
		// the ray hit an occluding object along its way to the light
		if (sampleLight == TRUE)
		{
			if (willNeedDiffuseBounceRay == TRUE)
			{
				mask = diffuseBounceMask;
				rayOrigin = diffuseBounceRayOrigin;
				rayDirection = diffuseBounceRayDirection;

				willNeedDiffuseBounceRay = FALSE;
				bounceIsSpecular = FALSE;
				sampleLight = FALSE;
				isDiffuseBounceTime = TRUE;
				isReflectionTime = FALSE;
				diffuseCount = 1;
				continue;
			}

			if (willNeedReflectionRay == TRUE)
			{
				mask = reflectionMask;
				rayOrigin = reflectionRayOrigin;
				rayDirection = reflectionRayDirection;

				willNeedReflectionRay = FALSE;
				bounceIsSpecular = TRUE;
				sampleLight = FALSE;
				isReflectionTime = TRUE;
				isDiffuseBounceTime = FALSE;
				diffuseCount = 0;
				continue;
			}

			break;
		}
		
		
		
		// useful data 
		n = normalize(hitNormal);
                nl = dot(n, rayDirection) < 0.0 ? n : -n;
		x = rayOrigin + rayDirection * t;
			
		if (bounces == 0)
		{
			firstX = x;

			objectNormal = n;
			objectColor = hitColor;
			objectID = hitObjectID;
		}
		if (bounces == 1 && previousIntersecType == SPEC)
		{
			objectNormal += n;
		}

		
                if (hitType == DIFF) // Ideal DIFFUSE reflection
                {	
			diffuseCount++;

			mask *= hitColor;

			bounceIsSpecular = FALSE;

			rayOrigin = x + nl * uEPS_intersect;
                        
			if (diffuseCount == 1)
			{
				diffuseBounceMask = mask;
				diffuseBounceRayOrigin = rayOrigin;
				diffuseBounceRayDirection = randomCosWeightedDirectionInHemisphere(nl);
				willNeedDiffuseBounceRay = TRUE;
			}
                        
			rayDirection = randomDirectionInSpecularLobe(uSunDirection, 0.1); // create shadow ray pointed towards light
			weight = max(0.0, dot(rayDirection, nl)) * 0.05; // down-weight directSunLight contribution
			mask *= weight * cloudShadowFactor;
			
			sampleLight = TRUE;
			continue;
                        
                } // end if (hitType == DIFF)
		
                if (hitType == SPEC)  // Ideal SPECULAR reflection
                {
			mask *= hitColor;

			rayDirection = reflect(rayDirection, nl);
			rayOrigin = x + nl * uEPS_intersect;

			if (bounces == 0)
				checkOcean = TRUE;

			//bounceIsSpecular = TRUE; // turn on mirror caustics
			continue;
                }
		
		if (hitType == REFR)  // Ideal dielectric REFRACTION
		{
			nc = 1.0; // IOR of Air
			nt = 1.33; // IOR of Water
			Re = calcFresnelReflectance(rayDirection, n, nc, nt, ratioIoR);
			Tr = 1.0 - Re;

			if (Re == 1.0)
			{
				rayDirection = reflect(rayDirection, nl);
				rayOrigin = x + nl * uEPS_intersect;
				continue;
			}
			
			if ( (bounces == 0 || (bounces == 1 && previousIntersecType == SPEC)) )
			{
				reflectionMask = mask * Re;
				reflectionRayDirection = reflect(rayDirection, nl); // reflect ray from surface
				reflectionRayOrigin = x + nl * uEPS_intersect;
				willNeedReflectionRay = TRUE;
			}

			mask *= Tr;
			mask *= hitColor;

			// transmit ray through surface
			rayDirection = refract(rayDirection, nl, ratioIoR);
			rayOrigin = x - nl * uEPS_intersect;	

			continue;
			
		} // end if (hitType == REFR)
		
		if (hitType == WOOD)  // Diffuse object underneath with thin layer of Water on top
		{
			nc = 1.0; // IOR of air
			nt = 1.1; // IOR of ClearCoat 
			Re = calcFresnelReflectance(rayDirection, n, nc, nt, ratioIoR);
			Tr = 1.0 - Re;
			
			if (bounces == 0)// || (bounces == 1 && hitObjectID != objectID && bounceIsSpecular == TRUE))
			{
				reflectionMask = mask * Re;
				reflectionRayDirection = reflect(rayDirection, nl); // reflect ray from surface
				reflectionRayOrigin = x + nl * uEPS_intersect;
				willNeedReflectionRay = TRUE;
			}

			diffuseCount++;

			mask *= Tr;
			
			float pattern = noise( vec2( x.x * 0.5 * x.z * 0.5 + sin(x.y*0.005) ) );
			float woodPattern = 1.0 / max(1.0, pattern * 100.0);
			hitColor *= woodPattern;

			if (bounces == 0)
				objectColor = hitColor;
			
			mask *= hitColor;

			bounceIsSpecular = FALSE;

			rayOrigin = x + nl * uEPS_intersect;

			if (diffuseCount == 1)
			{
				diffuseBounceMask = mask;
				diffuseBounceRayOrigin = rayOrigin;
				diffuseBounceRayDirection = randomCosWeightedDirectionInHemisphere(nl);
				willNeedDiffuseBounceRay = TRUE;
			}
			
			rayDirection = randomDirectionInSpecularLobe(uSunDirection, 0.1); // create shadow ray pointed towards light
			weight = max(0.0, dot(rayDirection, nl)) * 0.05; // down-weight directSunLight contribution
			mask *= weight;
			
			sampleLight = TRUE;
			continue;
			
		} //end if (hitType == WOOD)
		
	} // end for (int bounces = 0; bounces < 10; bounces++)
	

	// atmospheric haze effect (aerial perspective)
	float hitDistance;
	
	if ( skyHit == TRUE ) // sky and clouds
	{
		vec3 cloudColor = cld.rgb / (cld.a + 0.00001);
		vec3 sunColor = clamp( Get_Sky_Color(randomDirectionInSpecularLobe(uSunDirection, 0.1)), 0.0, 5.0 );
		
		cloudColor *= sunColor;
		cloudColor = mix(initialSkyColor, cloudColor, clamp(cld.a, 0.0, 1.0));
		
		hitDistance = distance(skyRayOrigin, skyPos);
		accumCol = mask * mix( accumCol, cloudColor, clamp( exp2( -hitDistance * 0.004 ), 0.0, 1.0 ) );
	}
	else // terrain and other objects
	{
		hitDistance = distance(cameraRayOrigin, firstX);
		accumCol = mix( initialSkyColor, accumCol, clamp( exp2( -log(hitDistance * 0.00003) ), 0.0, 1.0 ) );

		// underwater fog effect
		hitDistance = distance(cameraRayOrigin, firstX);
		hitDistance *= uCameraUnderWater;
		accumCol = mix( vec3(0.0,0.05,0.05), accumCol, clamp( exp2( -hitDistance * 0.001 ), 0.0, 1.0 ) );
	}


	return max(vec3(0), accumCol); // prevents black spot artifacts appearing in the water

}


//-----------------------------------------------------------------------
void SetupScene( void )
//-----------------------------------------------------------------------
{
	vec3 z  = vec3(0);// No color value, Black
	
	quads[0] = Quad( vec3(0,0,1), vec3(  0.0, 0.0,-559.2), vec3(549.6, 0.0,-559.2), vec3(549.6, 548.8,-559.2), vec3(  0.0, 548.8,-559.2),    z, vec3(0.9),  DIFF);// Back Wall
	quads[1] = Quad( vec3(1,0,0),vec3(  0.0, 0.0,   0.0), vec3(  0.0, 0.0,-559.2), vec3(  0.0, 548.8,-559.2), vec3(  0.0, 548.8,   0.0),    z, vec3(0.7, 0.12,0.05),  DIFF);// Left Wall Red
	quads[2] = Quad( vec3(-1,0,0),vec3(549.6, 0.0,-559.2), vec3(549.6, 0.0,   0.0), vec3(549.6, 548.8,   0.0), vec3(549.6, 548.8,-559.2),    z, vec3(0.2, 0.4, 0.36),  DIFF);// Right Wall Green
	//quads[3] = Quad( vec3(0,-1,0), vec3(  0.0, 548.8,-559.2), vec3(549.6, 548.8,-559.2), vec3(549.6, 548.8,   0.0), vec3(0.0, 548.8, 0.0),  z, vec3(0.9),  DIFF);// Ceiling
	quads[3] = Quad( vec3(0,1,0),vec3(  0.0, 0.0,   0.0), vec3(549.6, 0.0,   0.0), vec3(549.6, 0.0,-559.2), vec3(  0.0, 0.0,-559.2),    z, vec3(0.9), DIFF);// Floor
	
	openCylinders[0] = OpenCylinder( 50.0, vec3(50 , 0, -50), vec3(50 ,-1000, -50), z, vec3(0.05, 0.0, 0.0), WOOD);// wooden support OpenCylinder
	openCylinders[1] = OpenCylinder( 50.0, vec3(500, 0, -50), vec3(500,-1000, -50), z, vec3(0.05, 0.0, 0.0), WOOD);// wooden support OpenCylinder
	openCylinders[2] = OpenCylinder( 50.0, vec3(50 , 0,-510), vec3(50 ,-1000,-510), z, vec3(0.05, 0.0, 0.0), WOOD);// wooden support OpenCylinder
	openCylinders[3] = OpenCylinder( 50.0, vec3(500, 0,-510), vec3(500,-1000,-510), z, vec3(0.05, 0.0, 0.0), WOOD);// wooden support OpenCylinder
	
	boxes[0] = Box( vec3( -82.0,-170.0, -80.0), vec3(  82.0, 170.0,   80.0), z, vec3(1.0), SPEC);// Tall Mirror Box Left
	boxes[1] = Box( vec3( -86.0, -85.0, -80.0), vec3(  86.0,  85.0,   80.0), z, vec3(0.9), DIFF);// Short Diffuse Box Right
}


// tentFilter from Peter Shirley's 'Realistic Ray Tracing (2nd Edition)' book, pg. 60		
float tentFilter(float x)
{
	return (x < 0.5) ? sqrt(2.0 * x) - 1.0 : 1.0 - sqrt(2.0 - (2.0 * x));
}


void main( void )
{
        vec3 camRight   = vec3( uCameraMatrix[0][0],  uCameraMatrix[0][1],  uCameraMatrix[0][2]);
        vec3 camUp      = vec3( uCameraMatrix[1][0],  uCameraMatrix[1][1],  uCameraMatrix[1][2]);
        vec3 camForward = vec3(-uCameraMatrix[2][0], -uCameraMatrix[2][1], -uCameraMatrix[2][2]);
	// the following is not needed - three.js has a built-in uniform named cameraPosition
	//vec3 camPos   = vec3( uCameraMatrix[3][0],  uCameraMatrix[3][1],  uCameraMatrix[3][2]);
        
        // calculate unique seed for rng() function
	seed = uvec2(uFrameCounter, uFrameCounter + 1.0) * uvec2(gl_FragCoord);
	// initialize rand() variables
	randNumber = 0.0; // the final randomly-generated number (range: 0.0 to 1.0)
	blueNoise = texelFetch(tBlueNoiseTexture, ivec2(mod(floor(gl_FragCoord.xy), 128.0)), 0).r;

	vec2 pixelOffset = vec2( tentFilter(rand()), tentFilter(rand()) );
	pixelOffset *= 0.5;//uCameraIsMoving ? 0.5 : 1.0;

	// we must map pixelPos into the range -1.0 to +1.0
	vec2 pixelPos = ((gl_FragCoord.xy + vec2(0.5) + pixelOffset) / uResolution) * 2.0 - 1.0;

	vec3 rayDir = uUseOrthographicCamera ? camForward : 
					       normalize( pixelPos.x * camRight * uULen + pixelPos.y * camUp * uVLen + camForward );

	// depth of field
	vec3 focalPoint = uFocusDistance * rayDir;
	float randomAngle = rand() * TWO_PI; // pick random point on aperture
	float randomRadius = rand() * uApertureSize;
	vec3  randomAperturePos = ( cos(randomAngle) * camRight + sin(randomAngle) * camUp ) * sqrt(randomRadius);
	// point on aperture to focal point
	vec3 finalRayDir = normalize(focalPoint - randomAperturePos);
	
	rayOrigin = uUseOrthographicCamera ? cameraPosition + (camRight * pixelPos.x * uULen * 100.0) + (camUp * pixelPos.y * uVLen * 100.0) + randomAperturePos :
					     cameraPosition + randomAperturePos;
	rayDirection = finalRayDir;


        SetupScene(); 

        // Edge Detection - don't want to blur edges where either surface normals change abruptly (i.e. room wall corners), objects overlap each other (i.e. edge of a foreground sphere in front of another sphere right behind it),
	// or an abrupt color variation on the same smooth surface, even if it has similar surface normals (i.e. checkerboard pattern). Want to keep all of these cases as sharp as possible - no blur filter will be applied.
	vec3 objectNormal, objectColor;
	float objectID = -INFINITY;
	float pixelSharpness = 0.0;
	
	// perform path tracing and get resulting pixel color
	vec4 currentPixel = vec4( vec3(CalculateRadiance(objectNormal, objectColor, objectID, pixelSharpness)), 0.0 );

	// if difference between normals of neighboring pixels is less than the first edge0 threshold, the white edge line effect is considered off (0.0)
	float edge0 = 0.2; // edge0 is the minimum difference required between normals of neighboring pixels to start becoming a white edge line
	// any difference between normals of neighboring pixels that is between edge0 and edge1 smoothly ramps up the white edge line brightness (smoothstep 0.0-1.0)
	float edge1 = 0.6; // once the difference between normals of neighboring pixels is >= this edge1 threshold, the white edge line is considered fully bright (1.0)
	float difference_Nx = fwidth(objectNormal.x);
	float difference_Ny = fwidth(objectNormal.y);
	float difference_Nz = fwidth(objectNormal.z);
	float normalDifference = smoothstep(edge0, edge1, difference_Nx) + smoothstep(edge0, edge1, difference_Ny) + smoothstep(edge0, edge1, difference_Nz);

	float objectDifference = min(fwidth(objectID), 1.0);

	float colorDifference = (fwidth(objectColor.r) + fwidth(objectColor.g) + fwidth(objectColor.b)) > 0.0 ? 1.0 : 0.0;
	// white-line debug visualization for normal difference
	//currentPixel.rgb += (rng() * 1.5) * vec3(normalDifference);
	// white-line debug visualization for object difference
	//currentPixel.rgb += (rng() * 1.5) * vec3(objectDifference);
	// white-line debug visualization for color difference
	//currentPixel.rgb += (rng() * 1.5) * vec3(colorDifference);
	// white-line debug visualization for all 3 differences
	//currentPixel.rgb += (rng() * 1.5) * vec3( clamp(max(normalDifference, max(objectDifference, colorDifference)), 0.0, 1.0) );
	
	vec4 previousPixel = texelFetch(tPreviousTexture, ivec2(gl_FragCoord.xy), 0);

	
	if (uCameraIsMoving) // camera is currently moving
	{
		previousPixel.rgb *= 0.7; // motion-blur trail amount (old image)
		currentPixel.rgb *= 0.3; // brightness of new image (noisy)

		previousPixel.a = 0.0;
	}
	else
	{
		previousPixel.rgb *= 0.9; // motion-blur trail amount (old image)
		currentPixel.rgb *= 0.1; // brightness of new image (noisy)
	}

	currentPixel.a = pixelSharpness;

	// check for all edges that are not light sources
	if (pixelSharpness < 1.01 && (colorDifference >= 1.0 || normalDifference >= 0.9 || objectDifference >= 1.0)) // all other edges
		currentPixel.a = pixelSharpness = 1.0;

	// makes light source edges (shape boundaries) more stable
	// if (previousPixel.a == 1.01)
	// 	currentPixel.a = 1.01;

	// makes sharp edges more stable
	if (previousPixel.a == 1.0)
		currentPixel.a = 1.0;
		
	// for dynamic scenes (to clear out old, dark, sharp pixel trails left behind from moving objects)
	if (previousPixel.a == 1.0 && rng() < 0.05)
		currentPixel.a = 0.0;

	
	pc_fragColor = vec4(previousPixel.rgb + currentPixel.rgb, currentPixel.a);
}
