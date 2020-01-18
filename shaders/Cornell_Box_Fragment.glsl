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


#include <pathtracing_main>
