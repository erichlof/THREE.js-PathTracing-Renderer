precision highp float;
precision highp int;
precision highp sampler2D;

uniform mat4 uShortBoxInvMatrix;
uniform mat3 uShortBoxNormalMatrix;
uniform mat4 uTallBoxInvMatrix;
uniform mat3 uTallBoxNormalMatrix;

#include <pathtracing_uniforms_and_defines>

#define N_QUADS 6
#define N_BOXES 2


//-----------------------------------------------------------------------

struct Ray { vec3 origin; vec3 direction; };
struct Quad { vec3 normal; vec3 v0; vec3 v1; vec3 v2; vec3 v3; vec3 emission; vec3 color; int type; };
struct Box { vec3 minCorner; vec3 maxCorner; vec3 emission; vec3 color; int type; };
struct Intersection { vec3 normal; vec3 emission; vec3 color; int type; };

Quad quads[N_QUADS];
Box boxes[N_BOXES];


#include <pathtracing_random_functions>
		
#include <pathtracing_calc_fresnel_reflectance>

#include <pathtracing_quad_intersect>

#include <pathtracing_box_intersect>

#include <pathtracing_sample_quad_light>


#define STILL_WATER_LEVEL 100.0
#define WATER_WAVE_AMP 20.0
#define WATER_COLOR vec3(0.6, 1.0, 1.0)

float getWaterWaveHeight( vec3 pos )
{
	float waveSpeed = uTime * 6.0;
	
	float sampleAngle1 = mod(pos.x * 0.013  - waveSpeed * 0.7, TWO_PI);
	float sampleAngle2 = mod(pos.z * 0.027  - waveSpeed * 0.4, TWO_PI);
	float sampleAngle3 = mod(pos.x * 0.029  - waveSpeed * 0.5, TWO_PI);
	float sampleAngle4 = mod(pos.z * 0.015  - waveSpeed * 0.6, TWO_PI);
	
	float waveOffset = 0.25 * ( sin(sampleAngle1) + sin(sampleAngle2) + 
				    sin(sampleAngle3) + sin(sampleAngle4) );

	return STILL_WATER_LEVEL + (waveOffset * WATER_WAVE_AMP);
}

//------------------------------------------------------------------------------------------------
float SceneIntersect( Ray r, inout Intersection intersec, bool checkWater )
//------------------------------------------------------------------------------------------------
{
	Ray rObj;
	vec3 hitWorldSpace;
	vec3 normal;

        float d = INFINITY;
	float t = INFINITY;
	float waterWaveDepth;
	
	bool isRayExiting = false;
	
	
	for (int i = 0; i < N_QUADS; i++)
        {
		d = QuadIntersect( quads[i].v0, quads[i].v1, quads[i].v2, quads[i].v3, r, false );
		if (d < t)
		{
			t = d;
			intersec.normal = normalize( quads[i].normal );
			intersec.emission = quads[i].emission;
			intersec.color = quads[i].color;
			intersec.type = quads[i].type;
		}
        }
	
	// TALL MIRROR BOX
	// transform ray into Tall Box's object space
	rObj.origin = vec3( uTallBoxInvMatrix * vec4(r.origin, 1.0) );
	rObj.direction = vec3( uTallBoxInvMatrix * vec4(r.direction, 0.0) );
	d = BoxIntersect( boxes[0].minCorner, boxes[0].maxCorner, rObj, normal, isRayExiting );
	
	if (d < t)
	{	
		t = d;
		// transfom normal back into world space
		normal = normalize(normal);
		intersec.normal = normalize(transpose(mat3(uTallBoxInvMatrix)) * normal);
		intersec.emission = boxes[0].emission;
		intersec.color = boxes[0].color;
		intersec.type = boxes[0].type;
	}
	
	// SHORT DIFFUSE BOX
	// transform ray into Short Box's object space
	rObj.origin = vec3( uShortBoxInvMatrix * vec4(r.origin, 1.0) );
	rObj.direction = vec3( uShortBoxInvMatrix * vec4(r.direction, 0.0) );
	d = BoxIntersect( boxes[1].minCorner, boxes[1].maxCorner, rObj, normal, isRayExiting );
	
	if (d < t)
	{	
		t = d;
		// transfom normal back into world space
		normal = normalize(normal);
		intersec.normal = normalize(transpose(mat3(uShortBoxInvMatrix)) * normal);
		intersec.emission = boxes[1].emission;
		intersec.color = boxes[1].color;
		intersec.type = boxes[1].type;
	}
	
	
	// color surfaces beneath the water
	vec3 underwaterHitPos = r.origin + r.direction * t;
	float testPosWaveHeight = getWaterWaveHeight(underwaterHitPos);
	if (underwaterHitPos.y < testPosWaveHeight)
	{
		intersec.color *= WATER_COLOR;
	}

	if ( !checkWater )
	{
		return t;
	}

	///////////////////////////////////////////////////////////////////////////////////////////////////////
	// WATER VOLUME 
	///////////////////////////////////////////////////////////////////////////////////////////////////////

	vec3 pos = r.origin;
	vec3 dir = r.direction;
	float h = 0.0;
	d = 0.0; // reset d
	
	for(int i = 0; i < 150; i++)
	{
		h = abs(pos.y - getWaterWaveHeight(pos));
		if (d > 10000.0 || h < 1.0) break;
		d += h * 0.5;
		pos += dir * h * 0.5; 
	}
	if (h > WATER_WAVE_AMP) return t;

	if (d < t && pos.z < 0.0 && pos.z > -559.2 && pos.x > 0.0 && pos.x < 549.6) 
	{
		float eps = 1.0;
		t = d;
		hitWorldSpace = pos;
		float dx = getWaterWaveHeight(hitWorldSpace - vec3(eps,0,0)) - getWaterWaveHeight(hitWorldSpace + vec3(eps,0,0));
		float dy = eps * 2.0; // (the water wave height is a function of x and z, not dependent on y)
		float dz = getWaterWaveHeight(hitWorldSpace - vec3(0,0,eps)) - getWaterWaveHeight(hitWorldSpace + vec3(0,0,eps));
		
		intersec.normal = normalize(vec3(dx,dy,dz));
		intersec.emission = vec3(0);
		intersec.color = WATER_COLOR;
		intersec.type = REFR;
	}

	return t;
}


//-----------------------------------------------------------------------
vec3 CalculateRadiance(Ray r)
//-----------------------------------------------------------------------
{
        Intersection intersec;
        Quad light = quads[5];

	vec3 accumCol = vec3(0);
        vec3 mask = vec3(1);
        vec3 n, nl, x;
	vec3 dirToLight;
	vec3 tdir;
	
	float t = INFINITY;
	float nc, nt, ratioIoR, Re, Tr;
	float P, RP, TP;
	float weight;
	float thickness = 0.01; // 0.02

	int diffuseCount = 0;

	bool bounceIsSpecular = true;
	bool sampleLight = false;
	bool checkWater = true;
	bool rayEnteredWater = false;


	for (int bounces = 0; bounces < 5; bounces++)
	{

		t = SceneIntersect(r, intersec, checkWater);
		checkWater = false;

		
		if (t == INFINITY)
			break;
		
		
		if (intersec.type == LIGHT)
		{	
			if (sampleLight || bounceIsSpecular)
				accumCol = mask * intersec.emission;
			// reached a light, so we can exit
			break;
		}
		

		// if we get here and sampleLight is still true, shadow ray failed to find a light source
		if (sampleLight) 	
			break;
		

		// useful data 
		n = normalize(intersec.normal);
                nl = dot(n, r.direction) < 0.0 ? n : normalize(-n);
		x = r.origin + r.direction * t;

		    
                if (intersec.type == DIFF) // Ideal DIFFUSE reflection
		{
			diffuseCount++;

			if (!rayEnteredWater)
				mask *= intersec.color;
			else
			{
				rayEnteredWater = false;
				mask *= exp(log(WATER_COLOR) * thickness * t); 
			}

			bounceIsSpecular = false;

			if (diffuseCount == 1 && rand() < 0.5)
			{
				// choose random Diffuse sample vector
				r = Ray( x, randomCosWeightedDirectionInHemisphere(nl) );
				r.origin += nl * uEPS_intersect;
				continue;
			}
                        
			dirToLight = sampleQuadLight(x, nl, quads[5], dirToLight, weight);
			mask *= weight;

			r = Ray( x, dirToLight );
			r.origin += nl * uEPS_intersect;

			sampleLight = true;
			continue;
                        
		} // end if (intersec.type == DIFF)
		
                if (intersec.type == SPEC)  // Ideal SPECULAR reflection
		{
			if (!rayEnteredWater)
				mask *= intersec.color;
			else
			{
				mask *= exp(log(WATER_COLOR) * thickness * t);
			}

			r = Ray( x, reflect(r.direction, nl) );
			r.origin += nl * uEPS_intersect;

			if (bounces == 0)
				checkWater = true;
			
			continue;
		}

		if (intersec.type == REFR)  // Ideal dielectric REFRACTION
		{
			nc = 1.0; // IOR of Air
			nt = 1.33; // IOR of Water
			Re = calcFresnelReflectance(r.direction, n, nc, nt, ratioIoR);
			Tr = 1.0 - Re;
			P  = 0.25 + (0.5 * Re);
                	RP = Re / P;
                	TP = Tr / (1.0 - P);
			
			if (rand() < P)
			{	
				mask *= RP;

				r = Ray( x, reflect(r.direction, nl) ); // create reflection ray from surface
				r.origin += nl * uEPS_intersect;
				continue;
			}

			// transmit ray through surface	
			rayEnteredWater = true;

			// is ray leaving a solid object from the inside? 
			// If so, attenuate ray color with object color by how far ray has travelled through the medium
			if (distance(n, nl) > 0.1)
			{
				rayEnteredWater = false;
				mask *= exp(log(WATER_COLOR) * thickness * t);
			}

			mask *= TP;
			
			tdir = refract(r.direction, nl, ratioIoR);
			r = Ray(x, tdir);
			r.origin -= nl * uEPS_intersect;

			continue;
			
		} // end if (intersec.type == REFR)
		
	} // end for (int bounces = 0; bounces < 5; bounces++)
	
	
	return max(vec3(0), accumCol); // prevents black spot artifacts appearing in the water 
	     
}


//-----------------------------------------------------------------------
void SetupScene(void)
//-----------------------------------------------------------------------
{
	vec3 z  = vec3(0);// No color value, Black        
	vec3 L1 = vec3(1.0, 0.7, 0.38) * 30.0;// Bright Yellowish light
		    // 0.736507, 0.642866, 0.210431  Original values
	
	quads[0] = Quad( vec3( 0.0, 0.0, 1.0), vec3(  0.0,   0.0,-559.2), vec3(549.6,   0.0,-559.2), vec3(549.6, 548.8,-559.2), vec3(  0.0, 548.8,-559.2),  z, vec3(1),  DIFF);// Back Wall
	quads[1] = Quad( vec3( 1.0, 0.0, 0.0), vec3(  0.0,   0.0,   0.0), vec3(  0.0,   0.0,-559.2), vec3(  0.0, 548.8,-559.2), vec3(  0.0, 548.8,   0.0),  z, vec3(0.7, 0.12,0.05),  DIFF);// Left Wall Red
	quads[2] = Quad( vec3(-1.0, 0.0, 0.0), vec3(549.6,   0.0,-559.2), vec3(549.6,   0.0,   0.0), vec3(549.6, 548.8,   0.0), vec3(549.6, 548.8,-559.2),  z, vec3(0.2, 0.4, 0.36),  DIFF);// Right Wall Green
	quads[3] = Quad( vec3( 0.0,-1.0, 0.0), vec3(  0.0, 548.8,-559.2), vec3(549.6, 548.8,-559.2), vec3(549.6, 548.8,   0.0), vec3(  0.0, 548.8,   0.0),  z, vec3(1),  DIFF);// Ceiling
	quads[4] = Quad( vec3( 0.0, 1.0, 0.0), vec3(  0.0,   0.0,   0.0), vec3(549.6,   0.0,   0.0), vec3(549.6,   0.0,-559.2), vec3(  0.0,   0.0,-559.2),  z, vec3(1),  DIFF);// Floor
	quads[5] = Quad( vec3( 0.0,-1.0, 0.0), vec3(213.0, 548.0,-332.0), vec3(343.0, 548.0,-332.0), vec3(343.0, 548.0,-227.0), vec3(213.0, 548.0,-227.0), L1,       z, LIGHT);// Area Light Rectangle in ceiling
	
	boxes[0]  = Box( vec3(-82.0,-170.0, -80.0), vec3(82.0,170.0, 80.0), z, vec3(1), SPEC);// Tall Mirror Box Left
	boxes[1]  = Box( vec3(-86.0, -85.0, -80.0), vec3(86.0, 85.0, 80.0), z, vec3(1), DIFF);// Short Diffuse Box Right
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
	
    	vec3 camRight   = vec3( uCameraMatrix[0][0],  uCameraMatrix[0][1],  uCameraMatrix[0][2]);
    	vec3 camUp      = vec3( uCameraMatrix[1][0],  uCameraMatrix[1][1],  uCameraMatrix[1][2]);
	vec3 camForward = vec3(-uCameraMatrix[2][0], -uCameraMatrix[2][1], -uCameraMatrix[2][2]);
	
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
	pixelPos += pixelOffset;

	vec3 rayDir = normalize( pixelPos.x * camRight * uULen + pixelPos.y * camUp * uVLen + camForward );
	
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
