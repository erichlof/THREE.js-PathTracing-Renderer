precision highp float;
precision highp int;
precision highp sampler2D;

uniform sampler2D t_PerlinNoise;
uniform vec3 uSunDirection;
uniform vec3 uCameraFrameForward;
uniform vec3 uCameraFrameRight;
uniform vec3 uCameraFrameUp;
uniform float uCameraUnderWater;
uniform float uSunAngle;
uniform bool uCameraWithinAtmosphere;

#include <pathtracing_uniforms_and_defines>

#define N_SPHERES 2

//-----------------------------------------------------------------------

struct Ray { vec3 origin; vec3 direction; };
struct Sphere { float radius; vec3 position; vec3 emission; vec3 color; int type; };
struct Intersection { vec3 normal; vec3 emission; vec3 color; vec2 uv; int type; };

Sphere spheres[N_SPHERES];

#include <pathtracing_random_functions>

#include <pathtracing_calc_fresnel_reflectance>

#include <pathtracing_sphere_intersect>

#include <pathtracing_plane_intersect>

#define EARTH_RADIUS      6360.0 // in Km
#define ATMOSPHERE_RADIUS 6420.0 // in Km
#define SUN_POWER 30.0

vec3 hash33(vec3 p)
{
	p = fract(p * vec3(443.8975,397.2973, 491.1871));
    	p += dot(p.zxy, p.yxz+19.27);
    	return fract(vec3(p.x * p.y, p.z*p.x, p.y*p.z));
}

vec3 stars(in vec3 p)
{
	vec3 c = vec3(0);
	float res = uResolution.x;
	
	for (float i = 0.0; i < 4.0; i++)
	{
		vec3 q = fract(p*(.15*res))-0.5;
		vec3 id = floor(p*(.15*res));
		vec2 rn = hash33(id).xy;
		float c2 = 1.-smoothstep(0.,.6,length(q));
		c2 *= step(rn.x,.0005+i*i*0.001);
		c += c2*(mix(vec3(1.0,0.49,0.1),vec3(0.75,0.9,1.),clamp(rn.y,0.0,1.0))*0.1+0.9);
		p *= 1.3;
	}
	return vec3(pow(max(0.0,c.r), 5.0), pow(max(0.0,c.g), 7.0), pow(max(0.0,c.b), 6.5));
}

/*
float starRand(vec3 v)
{
	return fract(sin(dot(v ,vec3(12.9898,78.233,.0235))) * 43758.5453);
}
*/

//----------------------------------------------------------------------------------------
bool PlanetSphereIntersect( Ray ray, float rad, vec3 pos, inout float t0, inout float t1 )
//----------------------------------------------------------------------------------------
{
	vec3 L = ray.origin - pos;
	float a = dot( ray.direction, ray.direction );
	float b = 2.0 * dot( ray.direction, L );
	float c = dot( L, L ) - (rad * rad);

	solveQuadratic(a, b, c, t0, t1);
	
	float temp;
	if (t0 > t1)
	{
		temp = t0;
		t0 = t1;
		t1 = temp;
	}
	return true;
}

vec3 computeIncidentLight(Ray r, float tmin, float tmax)
{ 
	vec3 betaR = vec3(3.8e-3, 13.5e-3, 33.1e-3); 
	vec3 betaM = vec3(21e-3);  
	float Hr = 7.994;
	float Hm = 1.200;
	float t0, t1; 
	if (!PlanetSphereIntersect(r, ATMOSPHERE_RADIUS, vec3(0), t0, t1) || t1 < 0.0) return vec3(0); 
	if (t0 > tmin && t0 > 0.0) tmin = t0; 
	if (t1 < tmax) tmax = t1; 
	int numSamples = 16; 
	int numSamplesLight = 8; 
	float segmentLength = (tmax - tmin) / float(numSamples); 
	float tCurrent = tmin; 
	vec3 sumR = vec3(0); // rayleigh contribution
	vec3 sumM = vec3(0); // mie contribution 
	float opticalDepthR = 0.0;
	float opticalDepthM = 0.0; 
	float mu = dot(r.direction, uSunDirection); // mu in the paper which is the cosine of the angle between the sun direction and the ray direction 
	float phaseR = 3.0 / (16.0 * PI) * (1.0 + mu * mu); 
	float g = 0.76; 
	float phaseM = 3.0 / (8.0 * PI) * ((1.0 - g * g) * (1.0 + mu * mu)) / ((2.0 + g * g) * pow(max(0.0, 1.0 + g * g - 2.0 * g * mu), 1.5)); 
    	for (int i = 0; i < 16; ++i)
	{ 
		vec3 samplePosition = r.origin + (tCurrent + segmentLength * 0.5) * r.direction; 
		float height = length(samplePosition) - EARTH_RADIUS; 
		// compute optical depth for light
		float hr = exp(-height / Hr) * segmentLength; 
		float hm = exp(-height / Hm) * segmentLength; 
		opticalDepthR += hr; 
		opticalDepthM += hm; 
		// light optical depth
		float t0Light, t1Light; 
		PlanetSphereIntersect(Ray(samplePosition, uSunDirection), ATMOSPHERE_RADIUS, vec3(0), t0Light, t1Light); 
		float segmentLengthLight = t1Light / float(numSamplesLight);
		float tCurrentLight = 0.0; 
		float opticalDepthLightR = 0.0;
		float opticalDepthLightM = 0.0; 
		int jCounter = 0; 
		for (int j = 0; j < 8; ++j)
		{ 
			vec3 samplePositionLight = samplePosition + (tCurrentLight + segmentLengthLight * 0.5) * uSunDirection; 
			float heightLight = length(samplePositionLight) - EARTH_RADIUS; 
			if (heightLight < 0.0) break;
			jCounter += 1;
			opticalDepthLightR += exp(-heightLight / Hr) * segmentLengthLight; 
			opticalDepthLightM += exp(-heightLight / Hm) * segmentLengthLight; 
			tCurrentLight += segmentLengthLight; 
		} 
		if (jCounter == numSamplesLight)
		{ 
			vec3 tau = betaR * (opticalDepthR + opticalDepthLightR) + betaM * 1.1 * (opticalDepthM + opticalDepthLightM); 
			vec3 attenuation = vec3(exp(-tau.x), exp(-tau.y), exp(-tau.z)); 
			sumR += attenuation * hr; 
			sumM += attenuation * hm; 
		} 
		tCurrent += segmentLength; 
    	} 
    return (sumR * betaR * phaseR + sumM * betaM * phaseM) * SUN_POWER;
} 


// TERRAIN

#define TERRAIN_HEIGHT 4.0 // max height in Km
#define TERRAIN_SAMPLE_SCALE 0.02 
#define TERRAIN_LIFT -2.0 // (Km) how much to lift or drop the entire terrain
#define TERRAIN_FAR 100.0

float getTerrainHeight( in vec3 pos )
{
	vec2 uv;
	pos *= TERRAIN_SAMPLE_SCALE;
	uv.x = dot(pos, uCameraFrameRight);
	uv.y = dot(pos, uCameraFrameForward);
	float h = 0.0;
	float amp = TERRAIN_HEIGHT;

	for (int i = 0; i < 4; i ++)
	{
		h += amp * texture(t_PerlinNoise, uv + 0.5).x;
		amp *= 0.5;
		uv *= 2.0;
	}
	return h + TERRAIN_LIFT + EARTH_RADIUS;	
}

float getTerrainHeight_Detail( in vec3 pos )
{
	vec2 uv;
	pos *= TERRAIN_SAMPLE_SCALE;
	uv.x = dot(pos, uCameraFrameRight);
	uv.y = dot(pos, uCameraFrameForward);
	float h = 0.0;
	float amp = TERRAIN_HEIGHT;

	for (int i = 0; i < 9; i ++)
	{
		h += amp * texture(t_PerlinNoise, uv + 0.5).x;
		amp *= 0.5;
		uv *= 2.0;
	}
	return h; 
}

vec3 terrain_calcNormal( vec3 pos, float t )
{
	float e = uEPS_intersect;

	pos += uCameraFrameUp * getTerrainHeight_Detail(pos);

	vec3 xPos = pos + (uCameraFrameRight*e);
	vec3 xNeg = pos - (uCameraFrameRight*e);
	vec3 zPos = pos + (uCameraFrameForward*e);
	vec3 zNeg = pos - (uCameraFrameForward*e);

	xPos += (uCameraFrameUp * getTerrainHeight_Detail(xPos));
	xNeg += (uCameraFrameUp * getTerrainHeight_Detail(xNeg));
	zPos += (uCameraFrameUp * getTerrainHeight_Detail(zPos));
	zNeg += (uCameraFrameUp * getTerrainHeight_Detail(zNeg));

	vec3 xVec = normalize(xPos - xNeg);
	vec3 zVec = normalize(zPos - zNeg); 
	return normalize(cross(zVec, xVec));
}

bool terrain_isSunVisible( vec3 pos, vec3 n, vec3 dirToLight)
{
	dirToLight = normalize(dirToLight);
	float h = 1.0;
	float a = 0.0;
	float t = 0.0;
	float terrainHeight = TERRAIN_HEIGHT * 2.0 + TERRAIN_LIFT + EARTH_RADIUS;
	pos += n * 0.01;

	if (dot(n, dirToLight) < 0.0)
		return false;

	for(int i = 0; i < 300; i++)
	{
		a = length(pos);
		h = a - getTerrainHeight(pos);
		pos += dirToLight * h;
		if (a > terrainHeight || h < 0.01) break;
	}

	return h >= 0.01;
}

float TerrainIntersect( Ray r )
{
	vec3 pos = r.origin;
	vec3 dir = r.direction;
	float h = 0.0;
	float t = 0.0;
	float precisionFactor = 0.4;
	
	for (int i = 0; i < 300; i++)
	{
		h = length(pos) - getTerrainHeight(pos);
		if (t > TERRAIN_FAR || h < 0.01) break;
		t += h * precisionFactor;
		pos += dir * h * precisionFactor; 
	}
	return (h <= 0.01) ? t : INFINITY;
}

// WATER
/* Credit: some of the following water code is borrowed from https://www.shadertoy.com/view/Ms2SD1 posted by user 'TDM' */

#define WATER_SAMPLE_SCALE 50.0  // higher equals more repitition
#define MAX_WAVE_HEIGHT    0.001 // (in Km) Max water wave amplitude
#define WATER_FREQ         1.0   // wave density: lower = spread out, higher = close together
#define WATER_CHOPPY       2.0   // smaller beachfront-type waves, they travel in parallel
#define WATER_SPEED        0.5   // how quickly time passes
#define WATER_FAR 	   1.0	 // (in Km) how far to draw wave details
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

float water_octave( vec2 uv, float choppy )
{
	uv += noise(uv);        
	vec2 wv = 1.0 - abs(sin(uv));
	vec2 swv = abs(cos(uv));    
	wv = mix(wv, swv, clamp(wv, 0.0, 1.0));
	return pow(max(0.0, 1.0 - pow(max(0.0, wv.x * wv.y), 0.65)), choppy);
}

float getWaterHeight( vec3 pos )
{
	float freq = WATER_FREQ;
	float amp = MAX_WAVE_HEIGHT;
	float choppy = WATER_CHOPPY;
	float water_time = uTime * WATER_SPEED;
	pos *= WATER_SAMPLE_SCALE;
	vec2 uv;
	uv.x = dot(pos, uCameraFrameRight);
	uv.y = dot(pos, uCameraFrameForward);
	float d, h = 0.0;

	for(int i = 0; i < 2; i++)
	{        
		d =  water_octave((uv + water_time) * freq, choppy);
		d += water_octave((uv - water_time) * freq, choppy);
		h += d * amp;        
		uv *= OCTAVE_M; freq *= 1.9; amp *= 0.22;
		choppy = mix(choppy, 1.0, 0.2);
	}        
	
	return h + EARTH_RADIUS + 1.0; // 1.0 Km above Earth surface
}

float getWaterHeight_Detail( vec3 pos )
{
	float freq = WATER_FREQ;
	float amp = MAX_WAVE_HEIGHT;
	float choppy = WATER_CHOPPY;
	float water_time = uTime * WATER_SPEED;
	pos *= WATER_SAMPLE_SCALE;
	vec2 uv;
	uv.x = dot(pos, uCameraFrameRight);
	uv.y = dot(pos, uCameraFrameForward);
	float d, h = 0.0;

	for(int i = 0; i < 5; i++)
	{        
		d =  water_octave((uv + water_time) * freq, choppy);
		d += water_octave((uv - water_time) * freq, choppy);
		h += d * amp;        
		uv *= OCTAVE_M; freq *= 1.9; amp *= 0.22;
		choppy = mix(choppy, 1.0, 0.2);
	}

	return h;
}

vec3 water_calcNormal( vec3 pos, float t )
{
	float e = 0.01;

	pos += uCameraFrameUp * getWaterHeight_Detail(pos);

	vec3 xPos = pos + (uCameraFrameRight*e);
	vec3 xNeg = pos - (uCameraFrameRight*e);
	vec3 zPos = pos + (uCameraFrameForward*e);
	vec3 zNeg = pos - (uCameraFrameForward*e);

	xPos += (uCameraFrameUp * getWaterHeight_Detail(xPos));
	xNeg += (uCameraFrameUp * getWaterHeight_Detail(xNeg));
	zPos += (uCameraFrameUp * getWaterHeight_Detail(zPos));
	zNeg += (uCameraFrameUp * getWaterHeight_Detail(zNeg));
	
	vec3 xVec = normalize(xPos - xNeg);
	vec3 zVec = normalize(zPos - zNeg); 
	return normalize(cross(zVec, xVec));
}

float WaterIntersect( Ray r )
{
	vec3 pos = r.origin;
	vec3 dir = r.direction;
	float h = 0.0;
	float t = 0.0;
	float precisionFactor = 1.0;
	
	for (int i = 0; i < 300; i++)
	{
		h = abs(length(pos) - getWaterHeight(pos));
		if (t > WATER_FAR || h < 0.01) break;
		t += h * precisionFactor;
		pos += dir * h * precisionFactor; 
	}
	return (h <=0.01) ? t : INFINITY;
}


//-----------------------------------------------------------------------------------------------------------------------------------------------------------------------
float SceneIntersect( Ray r, inout Intersection intersec, bool checkWater )
//-----------------------------------------------------------------------------------------------------------------------------------------------------------------------
{
        float d = INFINITY;
	float t = INFINITY;
	float terrainHeight, waterHeight;
	vec3 hitPos;
	vec3 normal;

	

	d = TerrainIntersect( r );

	if (d > TERRAIN_FAR)
	{
		d = SphereIntersect(EARTH_RADIUS, vec3(0), r);
		if (d < INFINITY)
		{
			hitPos = r.origin + r.direction * d;
			terrainHeight = getTerrainHeight(hitPos);
			//d = PlaneIntersect(vec4(uCameraFrameUp, terrainHeight), r);
			d = SphereIntersect(terrainHeight, vec3(0), r);
		}
	}
	if (d < t)
	{	
		t = d;
		hitPos = r.origin + r.direction * t;
		intersec.normal = terrain_calcNormal(hitPos, t);
		intersec.emission = vec3(1,0,1);
		intersec.color = vec3(0);
		intersec.type = TERRAIN;
	}

	
	if (!checkWater)
		return t;

	d = INFINITY; // reset d

	d = WaterIntersect( r );
	
	if (d > WATER_FAR)
	{
		d = SphereIntersect(EARTH_RADIUS, vec3(0), r);
		if (d < INFINITY)
		{
			hitPos = r.origin + r.direction * d;
			waterHeight = getWaterHeight(hitPos);
			//d = PlaneIntersect(vec4(uCameraFrameUp, waterHeight), r);
			d = SphereIntersect(waterHeight, vec3(0), r);
		}
	}
	if (d < t)
	{	
		t = d;
		hitPos = r.origin + r.direction * t;
		intersec.normal = water_calcNormal(hitPos, t);
		//if ( !uCameraWithinAtmosphere )
		//	intersec.normal = normalize(hitPos);
		intersec.emission = vec3(0);
		intersec.color = vec3(0.7,0.8,0.9);
		intersec.type = REFR;
	}

	return t;
}


//-----------------------------------------------------------------------
vec3 CalculateRadiance(Ray r)
//-----------------------------------------------------------------------
{
	Intersection intersec;
	Ray firstRay;
	Ray cameraRay = r;

	vec3 randVec = vec3(rand() * 2.0 - 1.0, rand() * 2.0 - 1.0, rand() * 2.0 - 1.0);
	

	vec3 accumCol = vec3(0);
        vec3 mask = vec3(1);
	vec3 firstMask = vec3(1);
	vec3 n, nl, x;
	vec3 initialSkyColor = vec3(0);
	vec3 firstX = vec3(0);
	vec3 tdir;
	
	float nc, nt, ratioIoR, Re, Tr;
	float t0, t1, tMax = INFINITY;
	float t = INFINITY;
	
	bool waterHit = false;
	bool terrainHit = false;
	bool bounceIsSpecular = true;
	bool firstTypeWasREFR = false;
	bool reflectionTime = false;
	bool checkWater = true;
	bool isDayTime = true;
	
	
	if (dot(normalize(uSunDirection), normalize(uCameraFrameUp)) <= 0.0)
	{
		isDayTime = false;
	}

	if (PlanetSphereIntersect(r, EARTH_RADIUS, vec3(0), t0, t1) && t1 > 0.0)
	{
		tMax = max(0.0, t0);
	}
			

	initialSkyColor = computeIncidentLight(r, 0.0, tMax);

        for (int bounces = 0; bounces < 3; bounces++)
	{
		
		t = SceneIntersect(r, intersec, checkWater);
		checkWater = false; // no need to check water a second time
		
		tMax = INFINITY; //reset tMax

		if (PlanetSphereIntersect(r, EARTH_RADIUS, vec3(0), t0, t1) && t1 > 0.0)
		{
			tMax = max(0.0, t0);
		}
			

		if (t == INFINITY)
		{
			if (bounces == 0) // ray hits sky first	
			{
				accumCol = initialSkyColor;
				break; // exit early	
			}

			if (firstTypeWasREFR)
			{
				if (!reflectionTime) 
				{
					accumCol = mask * initialSkyColor;// computeIncidentLight(r, 0.0, tMax);
					
					// start back at the refractive surface, but this time follow reflective branch
					r = firstRay;
					r.direction = normalize(r.direction);
					mask = firstMask;
					// set/reset variables
					reflectionTime = true;
					
					// continue with the reflection ray
					continue;
				}

				accumCol += mask * computeIncidentLight(r, 0.0, tMax); // add reflective result to the refractive result (if any)
				break;
			}

			// reached the sky light, so we can exit
			break;
		} // end if (t == INFINITY)
		
		
		// useful data 
		n = intersec.normal;
                nl = dot(n,r.direction) <= 0.0 ? normalize(n) : normalize(n * -1.0);
		x = r.origin + r.direction * t;

		if (bounces == 0) 
			firstX = x;
		
		
		// ray hits terrain
		if (intersec.type == TERRAIN)
		{
			terrainHit = true;

			float altitude = length(x) - EARTH_RADIUS;
			vec2 uv;
			uv.x = dot(x, uCameraFrameRight);
			uv.y = dot(x, uCameraFrameForward);
			float rockNoise = texture(t_PerlinNoise, (0.05 * uv)).x;
			vec3 rockColor0 = vec3(0.04, 0.01, 0.01) * clamp(rockNoise + 0.1, 0.1, 1.0);
			vec3 rockColor1 = vec3(0.08, 0.07, 0.07) * clamp(rockNoise + 0.1, 0.1, 1.0);
			vec3 snowColor = vec3(1);
			vec3 up = normalize(x);
			float nY = max(0.0, dot(n, up));
			vec3 sunDirection = normalize(uSunDirection);
			vec3 randomSkyVec = normalize(n + (randVec * 0.2));
			vec3 skyColor = computeIncidentLight(Ray(x, normalize(up)), 0.0, tMax);
			vec3 sunColor = computeIncidentLight(Ray(x, normalize(normalize(sunDirection) + (randomSkyVec * 0.02))), 0.0, tMax);
			float terrainLayer = clamp( (altitude + (rockNoise * 1.0) * nY) / (TERRAIN_HEIGHT * 1.5 + TERRAIN_LIFT), 0.0, 1.0 );

			if (!isDayTime)
				sunDirection = normalize(-sunDirection);
			else
				sunColor = sunColor + 0.3;
			
				

			if (terrainLayer > 0.8 && terrainLayer > 1.0 - nY)
			{
				intersec.color = mix(vec3(0.7), snowColor, terrainLayer * nY);
				mask = mix(intersec.color * skyColor, intersec.color * sunColor, dot(normalize(sunDirection), up));// ambient color from sky light
			}	
			else
			{
				intersec.color = mix(rockColor0, rockColor1, clamp(nY, 0.0, 1.0) );
				//skyColor = (uCameraWithinAtmosphere && isDayTime) ? (skyColor + 0.5) : skyColor;
				mask = intersec.color * skyColor; // ambient color from sky light
			}		
				
			vec3 shadowRayDirection = normalize(normalize(sunDirection) + (randomSkyVec * 0.05));
									
			if ( bounces == 0 && terrain_isSunVisible(x, n, shadowRayDirection) ) // in direct sunlight
			{
				if (isDayTime)
					mask = intersec.color * sunColor;
				else 	
					mask = intersec.color * 0.002;
			}
			
			if (isDayTime && altitude < 1.0) // terrain is under water
			{
				mask = mix(rockColor0, mask, clamp(0.1*altitude, 0.0, 1.0)) * 0.1;
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
			waterHit = true;

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
			}
			
			// transmit ray through surface
			mask *= intersec.color;
			
			tdir = refract(r.direction, nl, ratioIoR);
			r = Ray(x, tdir);
			r.origin -= nl * uEPS_intersect;

			continue;
			
		} // end if (intersec.type == REFR)
			
	} // end for (int bounces = 0; bounces < 3; bounces++)
	
	// atmospheric haze effect (aerial perspective)
	float hitDistance;

	if (terrainHit)
	{
		hitDistance = distance(cameraRay.origin, firstX);
		accumCol = mix( initialSkyColor, accumCol, clamp( exp2( -log(hitDistance * 0.02) ), 0.0, 1.0 ) );
		// underwater fog effect
		hitDistance *= uCameraUnderWater;
		accumCol = mix( vec3(0.0,0.05,0.05), accumCol, clamp( exp2( -hitDistance * 1.0 ), 0.0, 1.0 ) );
	}
	
	// sun and moon
	for (int i = 0; i < N_SPHERES; i++)
        {
		// Sun and Moon Spheres
		float d = SphereIntersect( spheres[i].radius, spheres[i].position, r );
		if (d < t)
		{
			t = d;
			intersec.normal = normalize((r.origin + r.direction * t) - spheres[i].position);
			intersec.emission = spheres[i].emission;
			intersec.color = spheres[i].color;
			intersec.type = spheres[i].type;
		}
	}

	// SUN
	if ((uCameraUnderWater > 0.0 || uCameraWithinAtmosphere || !terrainHit) && intersec.type == LIGHT)
	{	
		vec3 sampleSkyCol = computeIncidentLight(r, 0.0, tMax);
		mask = mix(sampleSkyCol, intersec.emission, 0.5);
		accumCol = mask;
	}
	
	// MOON
	if ((uCameraUnderWater > 0.0 || uCameraWithinAtmosphere || !terrainHit) && intersec.type == DIFF)
	{
		vec2 uv;
		vec3 mn = intersec.normal;
		uv.x = (1.0 + atan(mn.z, mn.x) / PI) * 0.5;
		uv.y = acos(mn.y) / PI;
		uv.x *= 1.3;
		float rockNoise = clamp(texture(t_PerlinNoise, uv).x, 0.0, 1.0);
		intersec.color = clamp(intersec.color * rockNoise, 0.0, 1.0);
		vec3 sampleSkyCol = computeIncidentLight(r, 0.0, tMax);
		mask = mix(intersec.color, sampleSkyCol, clamp(0.7 * (sampleSkyCol.r + sampleSkyCol.b), 0.0, 1.0));
				// * max(0.0, dot(nl, uSunDirection)); // for moon phases

		accumCol = mask;
	}
	
	// stars
	if (t == INFINITY && !waterHit)
	{
		vec3 rotatedStarDir = r.direction;
		rotatedStarDir.x = r.direction.x * cos(uSunAngle) + r.direction.z * sin(uSunAngle);
		rotatedStarDir.z = r.direction.x * -sin(uSunAngle) + r.direction.z * cos(uSunAngle);
		vec3 starVal = stars(normalize(rotatedStarDir));
		float altitude = length(cameraRay.origin); 
		if (altitude < ATMOSPHERE_RADIUS && isDayTime)
		{
			float starAlt = EARTH_RADIUS + 15.0; // in Km
			if (altitude > starAlt)
				starVal = mix(vec3(0), starVal, clamp(exp(-(ATMOSPHERE_RADIUS - altitude) * 0.07), 0.0, 1.0));
			else
				starVal = mix(vec3(0), starVal, clamp(dot(uCameraFrameUp, -uSunDirection), 0.0, 1.0));
		
		}
			
		accumCol += starVal;
	}


        return max(vec3(0), accumCol); // prevents black spot artifacts appearing in the water

}


//-----------------------------------------------------------------------
void SetupScene(void)
//-----------------------------------------------------------------------
{
	vec3 z  = vec3(0); // no color value, black        
        vec3 L1 = vec3(1.0, 0.9, 0.8) * SUN_POWER;// Sun Light
	spheres[0] = Sphere( 100.0, cameraPosition + (normalize( uSunDirection) * 5000.0), L1, z, LIGHT);//Sun
	spheres[1] = Sphere( 150.0, cameraPosition + (normalize(-uSunDirection) * 5000.0), z, vec3(1), DIFF);//Moon	
}

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

    	vec3 camRight   = normalize( vec3( uCameraMatrix[0][0],  uCameraMatrix[0][1],  uCameraMatrix[0][2]) );
	vec3 camUp      = normalize( vec3( uCameraMatrix[1][0],  uCameraMatrix[1][1],  uCameraMatrix[1][2]) );    
	vec3 camForward = normalize( vec3(-uCameraMatrix[2][0], -uCameraMatrix[2][1], -uCameraMatrix[2][2]) );

	// calculate unique seed for rand() function
	seed = uvec2(uFrameCounter, uFrameCounter + 1.0) * uvec2(gl_FragCoord);

	vec2 pixelPos = vec2(0);
	vec2 pixelOffset = vec2(0);
	
	float x = rand();
	float y = rand();

	//if (!uCameraIsMoving)
	{
		pixelOffset.x = tentFilter(x);
		pixelOffset.y = tentFilter(y);
	}
	
	// pixelOffset ranges from -1.0 to +1.0, so only need to divide by half resolution
	pixelOffset /= (uResolution * 1.0); // normally this is * 0.5, but for dynamic scenes, * 1.0 looks sharper

	// we must map pixelPos into the range -1.0 to +1.0
	pixelPos = (gl_FragCoord.xy / uResolution) * 2.0 - 1.0;
	vec2 starPixelPos = pixelPos;
	pixelPos += pixelOffset;

	vec3 rayDir = normalize( pixelPos.x * camRight * uULen + pixelPos.y * camUp * uVLen + camForward );
	//vec3 starRayDir = normalize( starPixelPos.x * camRight * uULen + starPixelPos.y * camUp * uVLen + camForward );

	// depth of field
	vec3 focalPoint = uFocusDistance * rayDir;
	float randomAngle = rand() * TWO_PI; // pick random point on aperture
	float randomRadius = rand() * uApertureSize;
	vec3  randomAperturePos = ( cos(randomAngle) * camRight + sin(randomAngle) * camUp ) * sqrt(randomRadius);
	// point on aperture to focal point
	vec3 finalRayDir = normalize(focalPoint - randomAperturePos);
    
	Ray ray = Ray( cameraPosition + randomAperturePos, finalRayDir );
	
	SetupScene(); 

	// perform path tracing and get resulting pixel color
	vec3 pixelColor = CalculateRadiance(ray);
	
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
