precision highp float;
precision highp int;
precision highp sampler2D;

uniform vec3 uSunDirection;
uniform float uWaterLevel;

#include <pathtracing_uniforms_and_defines>

uniform sampler2D t_PerlinNoise;

#include <pathtracing_skymodel_defines>


//-----------------------------------------------------------------------

vec3 rayOrigin, rayDirection;
// recorded intersection data:
vec3 hitNormal, hitEmission, hitColor;
vec2 hitUV;
int hitType = -100;

struct Quad { vec3 v0; vec3 v1; vec3 v2; vec3 v3; vec3 emission; vec3 color; int type; };
struct Box { vec3 minCorner; vec3 maxCorner; vec3 emission; vec3 color; int type; };


#include <pathtracing_random_functions>

#include <pathtracing_calc_fresnel_reflectance>

#include <pathtracing_sphere_intersect>

#include <pathtracing_plane_intersect>

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



// TERRAIN

#define TERRAIN_DETAIL_FAR 50000.0
#define TERRAIN_HEIGHT 2000.0 // terrain amplitude
#define TERRAIN_LIFT  -1900.0 // how much to lift/drop the entire terrain
#define TERRAIN_SAMPLE_SCALE 0.00001

float lookup_Heightmap( in vec3 pos )
{
	vec2 uv = pos.xz;
	uv *= TERRAIN_SAMPLE_SCALE;
	float h = 0.0;
	float mult = 1.0;
	float scaleAccum = mult;

	for (int i = 0; i < 3; i ++)
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
	float scaleAccum = mult;

	for (int i = 0; i < 9; i ++)
	{
		h += mult * texture(t_PerlinNoise, uv + 0.5).x;
		mult *= 0.5;
		uv *= 2.0;
	}
	return h  * TERRAIN_HEIGHT + TERRAIN_LIFT;
}

vec3 terrain_calcNormal( vec3 pos, float t )
{
	vec3 eps = vec3(uEPS_intersect, 0.0, 0.0);
	
	return vec3( lookup_Normal(pos-eps.xyy) - lookup_Normal(pos+eps.xyy),
		     eps.x * 2.0,
		     lookup_Normal(pos-eps.yyx) - lookup_Normal(pos+eps.yyx) ) ;
}

bool isLightSourceVisible( vec3 pos, vec3 n, vec3 dirToLight)
{
	float h = 1.0;
	float t = 0.0;
	float terrainHeight = TERRAIN_HEIGHT * 1.5 + TERRAIN_LIFT;
	
	for (int i = 0; i < 100; i++)
	{
		h = pos.y - lookup_Heightmap(pos);
		if ( pos.y > terrainHeight || h < 0.0) break;
		pos += dirToLight * h;
	}

	return h > 0.0;
}

// WATER
/* Credit: some of the following water code is borrowed from https://www.shadertoy.com/view/Ms2SD1 posted by user 'TDM' */

#define WATER_DETAIL_FAR 1000.0
#define WATER_COLOR vec3(0.96, 1.0, 0.98)
#define WATER_SAMPLE_SCALE 0.009 
#define WATER_WAVE_HEIGHT 20.0 // max height of water waves   
#define WATER_FREQ        0.2 // wave density: lower = spread out, higher = close together
#define WATER_CHOPPY      2.0 // smaller beachfront-type waves, they travel in parallel
#define WATER_SPEED       1.7 // how quickly time passes
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

float ocean_octave( vec2 uv, float choppy )
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
	d =  ocean_octave((uv + sea_time) * freq, choppy);
	d += ocean_octave((uv - sea_time) * freq, choppy);
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
	for (int i = 0; i < 4; i++)
	{        
		d =  ocean_octave((uv + sea_time) * freq, choppy);
		d += ocean_octave((uv - sea_time) * freq, choppy);
		h += d * amp;        
		uv *= OCTAVE_M; freq *= 1.9; amp *= 0.22;
		choppy = mix(choppy, 1.0, 0.2);
	}
	return h * WATER_WAVE_HEIGHT + uWaterLevel;
}

vec3 ocean_calcNormal( vec3 pos, float t )
{
	vec3 eps = vec3(1.0, 0.0, 0.0);
	
	return vec3( getOceanWaterHeight_Detail(pos-eps.xyy) - getOceanWaterHeight_Detail(pos+eps.xyy),
		     eps.x * 2.0,
		     getOceanWaterHeight_Detail(pos-eps.yyx) - getOceanWaterHeight_Detail(pos+eps.yyx) );
}


//-----------------------------------------------------------------------------------------------------------------------------------------------------------------------
float SceneIntersect( int checkWater )
//-----------------------------------------------------------------------------------------------------------------------------------------------------------------------
{
	vec3 normal;
        float d, dp, dw, h, terrainHeight, waterWaveHeight;
	float t = INFINITY;
	vec3 hitPos; 

	// Terrain
	vec3 pos = rayOrigin;
	vec3 dir = rayDirection;
		
	for (int i = 0; i < 200; i++)
	{
		h = pos.y - lookup_Heightmap(pos);
		if (d > TERRAIN_DETAIL_FAR || h < 1.0) break;
		d += h * 0.6;
		pos += dir * h * 0.6; 
	}
	hitPos = pos;
	if (h >= 1.0) d = INFINITY;

	if (d > TERRAIN_DETAIL_FAR)
	{
		dp = PlaneIntersect( vec4(0, 1, 0, uWaterLevel), rayOrigin, rayDirection );
		if (dp < d)
		{
			hitPos = rayOrigin + rayDirection * dp;
			terrainHeight = lookup_Heightmap(hitPos);
			d = DisplacementBoxIntersect( vec3(-INFINITY, -INFINITY, -INFINITY), vec3(INFINITY, terrainHeight, INFINITY), rayOrigin, rayDirection);
		}
		
	}

	if (d < t)
	{
		t = d;
		hitPos = rayOrigin + rayDirection * t;
		hitNormal = terrain_calcNormal(hitPos, t);
		hitEmission = vec3(0);
		hitColor = vec3(0);
		hitType = TERRAIN;
	}
	
	if (checkWater == FALSE)
		return t;
        
        // Water
	pos = rayOrigin; // reset pos
	dir = rayDirection; // reset dir
	h = 0.0; // reset h
	d = 0.0; // reset d

	for (int i = 0; i < 50; i++)
	{
		h = abs(pos.y - getOceanWaterHeight(pos));
		if (d > WATER_DETAIL_FAR || abs(h) < 1.0) break;
		d += h;
		pos += dir * h; 
	}  

	hitPos = pos;
	if (h >= 1.0) d = INFINITY;

	if (d > WATER_DETAIL_FAR)
	{
		dp = PlaneIntersect( vec4(0, 1, 0, uWaterLevel), rayOrigin, rayDirection );
		if ( dp < d )
		{
			hitPos = rayOrigin + rayDirection * dp;
			waterWaveHeight = getOceanWaterHeight_Detail(hitPos);
			d = DisplacementBoxIntersect( vec3(rayOrigin.x - TERRAIN_DETAIL_FAR, -INFINITY, rayOrigin.z - TERRAIN_DETAIL_FAR), 
							vec3(rayOrigin.x + TERRAIN_DETAIL_FAR, waterWaveHeight, rayOrigin.z + TERRAIN_DETAIL_FAR), rayOrigin, rayDirection);
		}	
	}
	
	if (d < t)
	{
                t = d;
                hitPos = rayOrigin + rayDirection * d;
		hitNormal = ocean_calcNormal(hitPos, t);
		hitEmission = vec3(0);
		hitColor = vec3(0.7,0.8,0.9);
		hitType = REFR;
	}
		
	return t;
} // end float SceneIntersect( int checkWater )


//-----------------------------------------------------------------------
vec3 CalculateRadiance()
//-----------------------------------------------------------------------
{
	vec3 firstRayOrigin, firstRayDirection, cameraRayOrigin, cameraRayDirection;

	cameraRayOrigin = rayOrigin;
	cameraRayDirection = rayDirection;

	vec3 randVec = vec3(rng() * 2.0 - 1.0, rng() * 2.0 - 1.0, rng() * 2.0 - 1.0);
	vec3 initialSkyColor = Get_Sky_Color(rayDirection);
	
	vec3 accumCol = vec3(0);
        vec3 mask = vec3(1);
	vec3 reflectionMask = vec3(1);
	vec3 reflectionRayOrigin = vec3(0);
	vec3 reflectionRayDirection = vec3(0);
	vec3 n, nl, x;
	vec3 firstX = cameraRayOrigin;
	vec3 tdir;
	
	float nc, nt, ratioIoR, Re, Tr;
	//float P, RP, TP;
	float t = INFINITY;
	float cameraUnderWaterValue = rayOrigin.y < getOceanWaterHeight(rayOrigin) ? 1.0 : 0.0;
	float thickness = 0.01;

	int previousIntersecType = -100;

	int bounceIsSpecular = TRUE;
	int checkWater = TRUE;
	int skyHit = FALSE;
	int sampleLight = FALSE;
	int willNeedReflectionRay = FALSE;

	
        for (int bounces = 0; bounces < 6; bounces++)
	{

		t = SceneIntersect(checkWater);
		checkWater = FALSE;
		
		if (t == INFINITY)
		{
			if (bounces == 0) // ray hits sky first	
			{
				skyHit = TRUE;
				accumCol += initialSkyColor;
				break; // exit early	
			}

			if (bounceIsSpecular == TRUE)
			{
				accumCol += mask * Get_Sky_Color(rayDirection);
			}

			if (willNeedReflectionRay == TRUE)
			{
				mask = reflectionMask;
				rayOrigin = reflectionRayOrigin;
				rayDirection = reflectionRayDirection;

				willNeedReflectionRay = FALSE;
				bounceIsSpecular = TRUE;
				sampleLight = FALSE;
				continue;
			}
			// reached the sky light, so we can exit
			break;
		} // end if (t == INFINITY)

		
		
		// useful data 
		n = normalize(hitNormal);
                nl = dot(n, rayDirection) < 0.0 ? n : -n;
		x = rayOrigin + rayDirection * t;
		
		if (bounces == 0) 
			firstX = x;

		// ray hits terrain
		if (hitType == TERRAIN)
		{
			if (bounces > 2)
				break;

			previousIntersecType = TERRAIN;

			float rockNoise = texture(t_PerlinNoise, (0.0001 * x.xz) + 0.5).x;
			vec3 rockColor0 = vec3(0.2, 0.2, 0.2) * 0.01 * rockNoise;
			vec3 rockColor1 = vec3(0.2, 0.2, 0.2) * rockNoise;
			vec3 snowColor = vec3(0.9);
			vec3 up = vec3(0, 1, 0);
			vec3 randomSkyVec = randomCosWeightedDirectionInHemisphere(mix(n, up, 0.9));
			vec3 skyColor = Get_Sky_Color(randomSkyVec);
			if (dot(randomSkyVec, uSunDirection) > 0.98) skyColor *= 0.01;
			vec3 sunColor = clamp(Get_Sky_Color(randomDirectionInSpecularLobe(uSunDirection, 0.1)), 0.0, 2.0);
			float terrainLayer = clamp( ((x.y + -TERRAIN_LIFT) + (rockNoise * 1000.0) * n.y) / (TERRAIN_HEIGHT * 1.2), 0.0, 1.0 );
			
			if (x.y > uWaterLevel && terrainLayer > 0.95 && terrainLayer > 0.9 - n.y)
			{
				hitColor = mix(vec3(0.5), snowColor, n.y);
				mask = mix(hitColor * skyColor, hitColor * sunColor, 0.7);// ambient color from sky light
			}	
			else
			{
				hitColor = mix(rockColor0, rockColor1, clamp(terrainLayer * n.y, 0.0, 1.0) );
				mask = hitColor * skyColor;
				if (x.y > uWaterLevel && cameraUnderWaterValue == 0.0 && bounces == 0)
				{
					nc = 1.0; // IOR of air
					nt = 1.33; // IOR of watery rock
					Re = calcFresnelReflectance(rayDirection, n, nc, nt, ratioIoR);
					Tr = 1.0 - Re;
					// P  = 0.25 + (0.5 * Re);
					// RP = Re / P;
					// TP = Tr / (1.0 - P);
					
					if (bounces == 0 || (bounces == 1 && bounceIsSpecular == TRUE))
					{
						previousIntersecType = REFR;
						reflectionMask = mask * Re;
						reflectionRayDirection = reflect(rayDirection, nl); // reflect ray from surface
						reflectionRayOrigin = x + nl * uEPS_intersect;
						willNeedReflectionRay = TRUE;
					}
				}
			}

			bounceIsSpecular = FALSE;
				
			
			vec3 shadowRayDirection = randomDirectionInSpecularLobe(uSunDirection, 0.4);						
			//if ( isLightSourceVisible(x, n, shadowRayDirection) && x.y > uWaterLevel ) // in direct sunlight
			if (bounces < 2 && x.y > uWaterLevel && dot(n, shadowRayDirection) > 0.1 && isLightSourceVisible(x, n, shadowRayDirection) ) // in direct sunlight
			{
				mask = hitColor * mix(skyColor, sunColor, clamp(dot(n,shadowRayDirection),0.0,1.0));	
			}

			accumCol += mask;

			if (willNeedReflectionRay == TRUE)
			{
				mask = reflectionMask;
				rayOrigin = reflectionRayOrigin;
				rayDirection = reflectionRayDirection;

				willNeedReflectionRay = FALSE;
				bounceIsSpecular = TRUE;
				sampleLight = FALSE;
				continue;
			}
				
			break;
		} // end if (hitType == TERRAIN)

		
		if (hitType == REFR)  // Ideal dielectric REFRACTION
		{
			previousIntersecType = REFR;

			nc = 1.0; // IOR of air
			nt = 1.33; // IOR of water
			Re = calcFresnelReflectance(rayDirection, n, nc, nt, ratioIoR);
			Tr = 1.0 - Re;

			if (bounces == 0)
			{
				reflectionMask = mask * Re;
				reflectionRayDirection = reflect(rayDirection, nl); // reflect ray from surface
				reflectionRayOrigin = x + nl * uEPS_intersect;
				willNeedReflectionRay = TRUE;
			}

			if (Re == 1.0)
			{
				mask = reflectionMask;
				rayOrigin = reflectionRayOrigin;
				rayDirection = reflectionRayDirection;

				willNeedReflectionRay = FALSE;
				bounceIsSpecular = TRUE;
				sampleLight = FALSE;
				continue;
			}
			
			// transmit ray through surface
			mask *= hitColor;
			mask *= Tr;
			
			tdir = refract(rayDirection, nl, ratioIoR);
			rayDirection = tdir;
			rayOrigin = x - nl * uEPS_intersect;
			
			continue;
			
		} // end if (hitType == REFR)
		
	} // end for (int bounces = 0; bounces < 3; bounces++)
	
	
	// atmospheric haze effect (aerial perspective)
	float fogStartDistance = TERRAIN_DETAIL_FAR * 0.3;
	float hitDistance = distance(cameraRayOrigin, firstX);
	float fogDistance;

	if (skyHit == TRUE)
	{
		//vec3 cloudColor = cld.rgb / (cld.a + 0.00001);
		//vec3 sunColor = clamp(Get_Sky_Color( normalize((randVec * 0.03) + uSunDirection)), 0.0, 1.0);
		//cloudColor *= mix(sunColor, vec3(1), max(0.0, dot(vec3(0,1,0), uSunDirection)) );
		//cloudColor = mix(initialSkyColor, cloudColor, clamp(cld.a, 0.0, 1.0));
		//accumCol = mask * mix( accumCol, cloudColor, clamp( exp2( -hitDistance * 0.003 ), 0.0, 1.0 ) );
		fogDistance = max(0.0, hitDistance - fogStartDistance);
		accumCol = mix( initialSkyColor, accumCol, clamp( exp(-(fogDistance * 0.00005)), 0.0, 1.0 ) );
	}
	else // terrain and other objects
	{
		fogDistance = max(0.0, hitDistance - fogStartDistance);
		accumCol = mix( initialSkyColor, accumCol, clamp( exp(-(fogDistance * 0.00005)), 0.0, 1.0 ) );
		// underwater fog effect
		hitDistance = distance(cameraRayOrigin, firstX);
		hitDistance *= cameraUnderWaterValue;
		accumCol = mix( vec3(0.0,0.05,0.05), accumCol, clamp( exp2( -hitDistance * 0.001 ), 0.0, 1.0 ) );
	}
	
	
	return max(vec3(0), accumCol); // prevents black spot artifacts appearing in the water 
	     
}

/*
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
	return (x < 0.5) ? sqrt(2.0 * x) - 1.0 : 1.0 - sqrt(2.0 - (2.0 * x));
}

void main( void )
{
	// not needed, three.js has a built-in uniform named cameraPosition
	//vec3 camPos   = vec3( uCameraMatrix[3][0],  uCameraMatrix[3][1],  uCameraMatrix[3][2]);
	
    	vec3 camRight   = vec3( uCameraMatrix[0][0],  uCameraMatrix[0][1],  uCameraMatrix[0][2]);
    	vec3 camUp      = vec3( uCameraMatrix[1][0],  uCameraMatrix[1][1],  uCameraMatrix[1][2]);
	vec3 camForward = vec3(-uCameraMatrix[2][0], -uCameraMatrix[2][1], -uCameraMatrix[2][2]);
	
	// calculate unique seed for rng() function
	seed = uvec2(uFrameCounter, uFrameCounter + 1.0) * uvec2(gl_FragCoord);

	// initialize rand() variables
	counter = -1.0; // will get incremented by 1 on each call to rand()
	channel = 0; // the final selected color channel to use for rand() calc (range: 0 to 3, corresponds to R,G,B, or A)
	randNumber = 0.0; // the final randomly-generated number (range: 0.0 to 1.0)
	randVec4 = vec4(0); // samples and holds the RGBA blueNoise texture value for this pixel
	randVec4 = texelFetch(tBlueNoiseTexture, ivec2(mod(gl_FragCoord.xy + floor(uRandomVec2 * 256.0), 256.0)), 0);
	
	vec2 pixelOffset = vec2( tentFilter(rand()), tentFilter(rand()) ) * 0.5;
	// we must map pixelPos into the range -1.0 to +1.0
	vec2 pixelPos = ((gl_FragCoord.xy + pixelOffset) / uResolution) * 2.0 - 1.0;

	vec3 rayDir = uUseOrthographicCamera ? camForward : 
					       normalize( pixelPos.x * camRight * uULen + pixelPos.y * camUp * uVLen + camForward );

	// depth of field
	vec3 focalPoint = uFocusDistance * rayDir;
	float randomAngle = rng() * TWO_PI; // pick random point on aperture
	float randomRadius = rng() * uApertureSize;
	vec3  randomAperturePos = ( cos(randomAngle) * camRight + sin(randomAngle) * camUp ) * sqrt(randomRadius);
	// point on aperture to focal point
	vec3 finalRayDir = normalize(focalPoint - randomAperturePos);
    
	rayOrigin = uUseOrthographicCamera ? cameraPosition + (camRight * pixelPos.x * uULen * 100.0) + (camUp * pixelPos.y * uVLen * 100.0) + randomAperturePos :
					     cameraPosition + randomAperturePos;
	rayDirection = finalRayDir;


	//SetupScene(); 

	// perform path tracing and get resulting pixel color
	vec3 pixelColor = CalculateRadiance();
	
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
	
	// if current raytraced pixel didn't return any color value, just use the previous frame's pixel color
	if (pixelColor == vec3(0.0))
	{
		pixelColor = previousColor;
		previousColor *= 0.5;
		pixelColor *= 0.5;
	}
	
	pc_fragColor = vec4( pixelColor + previousColor, 1.01 );	
}
