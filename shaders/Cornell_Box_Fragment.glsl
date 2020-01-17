#version 300 es

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


struct Ray { vec3 origin; vec3 direction; };
struct Quad { vec3 normal; vec3 v0; vec3 v1; vec3 v2; vec3 v3; vec3 emission; vec3 color; int type; };
struct Box { vec3 minCorner; vec3 maxCorner; vec3 emission; vec3 color; int type; };
struct Intersection { vec3 normal; vec3 emission; vec3 color; int type; };

Quad quads[N_QUADS];
Box boxes[N_BOXES];

#include <pathtracing_random_functions>

#include <pathtracing_quad_intersect>

#include <pathtracing_box_intersect>

#include <pathtracing_sample_quad_light>


//-----------------------------------------------------------------------
float SceneIntersect( Ray r, inout Intersection intersec )
//-----------------------------------------------------------------------
{
	vec3 normal;
        float d;
	float t = INFINITY;
	bool isRayExiting = false;
		
	for (int i = 0; i < N_QUADS; i++)
        {
		d = QuadIntersect( quads[i].v0, quads[i].v1, quads[i].v2, quads[i].v3, r, false );
		if (d < t)
		{
			t = d;
			intersec.normal = normalize(quads[i].normal);
			intersec.emission = quads[i].emission;
			intersec.color = quads[i].color;
			intersec.type = quads[i].type;
		}
        }
	
	
	// TALL MIRROR BOX
	Ray rObj;
	// transform ray into Tall Box's object space
	rObj.origin = vec3( uTallBoxInvMatrix * vec4(r.origin, 1.0) );
	rObj.direction = vec3( uTallBoxInvMatrix * vec4(r.direction, 0.0) );
	d = BoxIntersect( boxes[0].minCorner, boxes[0].maxCorner, rObj, normal, isRayExiting );
	
	if (d < t)
	{	
		t = d;
		
		// transfom normal back into world space
		normal = normalize(normal);
		normal = vec3(uTallBoxNormalMatrix * normal);
		intersec.normal = normalize(normal);
		intersec.emission = boxes[0].emission;
		intersec.color = boxes[0].color;
		intersec.type = boxes[0].type;
	}
	
	
	// SHORT DIFFUSE WHITE BOX
	// transform ray into Short Box's object space
	rObj.origin = vec3( uShortBoxInvMatrix * vec4(r.origin, 1.0) );
	rObj.direction = vec3( uShortBoxInvMatrix * vec4(r.direction, 0.0) );
	d = BoxIntersect( boxes[1].minCorner, boxes[1].maxCorner, rObj, normal, isRayExiting );
	
	if (d < t)
	{	
		t = d;
		
		// transfom normal back into world space
		normal = normalize(normal);
		normal = vec3(uShortBoxNormalMatrix * normal);
		intersec.normal = normalize(normal);
		intersec.emission = boxes[1].emission;
		intersec.color = boxes[1].color;
		intersec.type = boxes[1].type;
	}
	
	
	return t;
}


//-----------------------------------------------------------------------
vec3 CalculateRadiance( Ray r, inout uvec2 seed )
//-----------------------------------------------------------------------
{
        Intersection intersec;
        Quad light = quads[5];
	Ray firstRay;

	vec3 accumCol = vec3(0);
        vec3 mask = vec3(1);
	vec3 firstMask = vec3(1);
        vec3 n, nl, x;
	vec3 dirToLight;
        
	float t;
	float weight, p;
	//float diffuseColorBleeding = 0.5; // range: 0.0 - 0.5, amount of color bleeding between surfaces

	int diffuseCount = 0;

	bool bounceIsSpecular = true;
	bool sampleLight = false;
	bool firstTypeWasDIFF = false;
	bool shadowTime = false;
	bool createCausticRay = false;


	for (int bounces = 0; bounces < 5; bounces++)
	{

		t = SceneIntersect(r, intersec);
		
		if (t == INFINITY)
		{
			if (bounces == 0 || createCausticRay) 
				break;

			if (firstTypeWasDIFF && !shadowTime) 
			{
				// start back at the diffuse surface, but this time follow shadow ray branch
				r = firstRay;
				r.direction = normalize(r.direction);
				mask = firstMask;
				// set/reset variables
				shadowTime = true;
				bounceIsSpecular = false;
				sampleLight = true;
				// continue with the shadow ray
				continue;
			}
			// nothing left to calculate, so exit	
			break;
		}
		
		if (intersec.type == LIGHT)
		{	
			if (createCausticRay)
			{
				accumCol = mask * intersec.emission;
				break;
			}

			if (bounces == 0)
			{
				accumCol = intersec.emission;
				break;
			}

			if (firstTypeWasDIFF && !createCausticRay)
			{
				if (!shadowTime) 
				{
					if (sampleLight)
						accumCol = mask * intersec.emission * 0.5;
					
					// start back at the diffuse surface, but this time follow shadow ray branch
					r = firstRay;
					r.direction = normalize(r.direction);
					mask = firstMask;
					// set/reset variables
					shadowTime = true;
					bounceIsSpecular = false;
					sampleLight = true;
					// continue with the shadow ray
					continue;
				}
				
				if (sampleLight)
					accumCol += mask * intersec.emission * 0.5; // add shadow ray result to the colorbleed result (if any)
				
				break;		
			}
			
			if (bounceIsSpecular)
				accumCol = mask * intersec.emission; // looking at light through a reflection
			// reached a light, so we can exit
			break;
		} // end if (intersec.type == LIGHT)
		
		// if we get here and sampleLight is still true, shadow ray failed to find a light source
		if (sampleLight) 
		{
			if (firstTypeWasDIFF && !shadowTime) 
			{
				// start back at the diffuse surface, but this time follow shadow ray branch
				r = firstRay;
				r.direction = normalize(r.direction);
				mask = firstMask;
				// set/reset variables
				shadowTime = true;
				bounceIsSpecular = false;
				sampleLight = true;
				// continue with the shadow ray
				continue;
			}
			// nothing left to calculate, so exit	
			break;
		}
		
		// useful data 
		n = normalize(intersec.normal);
                nl = dot(n, r.direction) < 0.0 ? normalize(n) : normalize(-n);
		x = r.origin + r.direction * t;
		
		
                if (intersec.type == DIFF) // Ideal DIFFUSE reflection
                {
			diffuseCount++;

			mask *= intersec.color;

			if (createCausticRay)
				break;

			// create caustic ray
                        if (diffuseCount == 1 && rand(seed) < 0.2) // 0.2
                        {
				createCausticRay = true;

				vec3 randVec = vec3(rand(seed) * 2.0 - 1.0, rand(seed) * 2.0 - 1.0, rand(seed) * 2.0 - 1.0);
				vec3 offset = vec3(randVec.x * 82.0, randVec.y * 170.0, randVec.z * 80.0);
				vec3 target = vec3(180.0 + offset.x, 170.0 + offset.y, -350.0 + offset.z);
				r = Ray( x, normalize(target - x) );
				r.origin += nl * uEPS_intersect;
				
				weight = max(0.0, dot(nl, r.direction));
				mask *= weight;

				continue;
			}

			bounceIsSpecular = false;

			if (diffuseCount == 1)
			{	
				// save intersection data for future shadowray trace
				firstTypeWasDIFF = true;
				dirToLight = sampleQuadLight(x, nl, light, dirToLight, weight, seed);
				firstMask = mask * weight;
                                firstRay = Ray( x, normalize(dirToLight) ); // create shadow ray pointed towards light
				firstRay.origin += nl * uEPS_intersect;

				// choose random Diffuse sample vector
				r = Ray( x, normalize(randomCosWeightedDirectionInHemisphere(nl, seed)) );
				r.origin += nl * uEPS_intersect;
				continue;
			}
			
			dirToLight = sampleQuadLight(x, nl, light, dirToLight, weight, seed);
			mask *= weight;

			r = Ray( x, normalize(dirToLight) );
			r.origin += nl * uEPS_intersect;
			sampleLight = true;
			continue;
                        
                } // end if (intersec.type == DIFF)
		
                if (intersec.type == SPEC)  // Ideal SPECULAR reflection
		{
			mask *= intersec.color;

			r = Ray( x, reflect(r.direction, nl) );
			r.origin += nl * uEPS_intersect;

			continue;
		}
		
	} // end for (int bounces = 0; bounces < 5; bounces++)
	

	return max(vec3(0), accumCol);

}


//-----------------------------------------------------------------------
void SetupScene(void)
//-----------------------------------------------------------------------
{
	vec3 z  = vec3(0);// No color value, Black        
	vec3 L1 = vec3(1.0, 0.7, 0.38) * 30.0;// Bright Yellowish light
	
	quads[0] = Quad( vec3( 0.0, 0.0, 1.0), vec3(  0.0,   0.0,-559.2), vec3(549.6,   0.0,-559.2), vec3(549.6, 548.8,-559.2), vec3(  0.0, 548.8,-559.2),  z, vec3(1),  DIFF);// Back Wall
	quads[1] = Quad( vec3( 1.0, 0.0, 0.0), vec3(  0.0,   0.0,   0.0), vec3(  0.0,   0.0,-559.2), vec3(  0.0, 548.8,-559.2), vec3(  0.0, 548.8,   0.0),  z, vec3(0.7, 0.12,0.05),  DIFF);// Left Wall Red
	quads[2] = Quad( vec3(-1.0, 0.0, 0.0), vec3(549.6,   0.0,-559.2), vec3(549.6,   0.0,   0.0), vec3(549.6, 548.8,   0.0), vec3(549.6, 548.8,-559.2),  z, vec3(0.2, 0.4, 0.36),  DIFF);// Right Wall Green
	quads[3] = Quad( vec3( 0.0,-1.0, 0.0), vec3(  0.0, 548.8,-559.2), vec3(549.6, 548.8,-559.2), vec3(549.6, 548.8,   0.0), vec3(  0.0, 548.8,   0.0),  z, vec3(1),  DIFF);// Ceiling
	quads[4] = Quad( vec3( 0.0, 1.0, 0.0), vec3(  0.0,   0.0,   0.0), vec3(549.6,   0.0,   0.0), vec3(549.6,   0.0,-559.2), vec3(  0.0,   0.0,-559.2),  z, vec3(1),  DIFF);// Floor
	quads[5] = Quad( vec3( 0.0,-1.0, 0.0), vec3(213.0, 548.0,-332.0), vec3(343.0, 548.0,-332.0), vec3(343.0, 548.0,-227.0), vec3(213.0, 548.0,-227.0), L1,       z, LIGHT);// Area Light Rectangle in ceiling
	
	boxes[0]  = Box( vec3(-82.0,-170.0, -80.0), vec3(82.0,170.0, 80.0), z, vec3(1), SPEC);// Tall Mirror Box Left
	boxes[1]  = Box( vec3(-86.0, -85.0, -80.0), vec3(86.0, 85.0, 80.0), z, vec3(1), DIFF);// Short Diffuse Box Right
}


//#include <pathtracing_main>
// tentFilter from Peter Shirley's 'Realistic Ray Tracing (2nd Edition)' book, pg. 60		
float tentFilter(float x)
{
	return (x < 0.5) ? sqrt(2.0 * x) - 1.0 : 1.0 - sqrt(2.0 - (2.0 * x));
}


/* // cubicSplineFilter from Peter Shirley's 'Realistic Ray Tracing (2nd Edition)' book, pg. 58
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
} */


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
		pixelOffset = vec2(tentFilter(x), tentFilter(y));
		//pixelOffset = vec2(cubicFilter(x), cubicFilter(y));
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

	
	if (uFrameCounter == 1.0)
	{
		previousColor = vec3(0);
	}
	else if (uCameraIsMoving)
	{
		// vec3 interpColorX = vec3(0);
		// vec3 interpColorY = vec3(0);
		// vec3 dFdxColor = dFdx(pixelColor);
		// interpColorX.r = pixelColor.r + dFdxColor.r;
		// interpColorX.g = pixelColor.g + dFdxColor.g;
		// interpColorX.b = pixelColor.b + dFdxColor.b;
		
		// vec3 dFdyColor = dFdy(pixelColor);
		// interpColorY.r = pixelColor.r + dFdyColor.r;
		// interpColorY.g = pixelColor.g + dFdyColor.g;
		// interpColorY.b = pixelColor.b + dFdyColor.b;
		// pixelColor = max(vec3(0), (pixelColor + interpColorX + pixelColor + interpColorY) * 0.25);

		pixelColor += fwidth(pixelColor) * 0.25;
		pixelColor += fwidth(previousColor) * 0.25;
		

		pixelColor *= 0.5;
		previousColor *= 0.5;
	}
	
	

	out_FragColor = vec4( previousColor + pixelColor, 1.0 );
}
