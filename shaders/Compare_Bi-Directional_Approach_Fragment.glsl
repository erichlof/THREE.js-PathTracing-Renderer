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
#define N_BOXES 3

struct Ray { vec3 origin; vec3 direction; };
struct Quad { vec3 normal; vec3 v0; vec3 v1; vec3 v2; vec3 v3; vec3 emission; vec3 color; int type; };
struct Box { vec3 minCorner; vec3 maxCorner; vec3 emission; vec3 color; int type; };
struct Intersection { vec3 normal; vec3 emission; vec3 color; int type; };

Quad quads[N_QUADS];
Box boxes[N_BOXES];


#include <pathtracing_random_functions>

#include <pathtracing_quad_intersect>

#include <pathtracing_box_intersect>


//-----------------------------------------------------------------------
float SceneIntersect( Ray r, inout Intersection intersec )
//-----------------------------------------------------------------------
{
	vec3 normal;
        float d;
	float t = INFINITY;
	
	// clear fields out
	intersec.normal = vec3(0);
	intersec.emission = vec3(0);
	intersec.color = vec3(0);
	intersec.type = -1;
	
	
	for (int i = 0; i < N_QUADS; i++)
        {
		d = QuadIntersect( quads[i].v0, quads[i].v1, quads[i].v2, quads[i].v3, quads[i].normal, r );
		if (d < t)
		{
			t = d;
			intersec.normal = quads[i].normal;
			intersec.emission = quads[i].emission;
			intersec.color = quads[i].color;
			intersec.type = quads[i].type;
		}
        }
	
	// LIGHT BLOCKER BOX
	d = BoxIntersect( boxes[2].minCorner, boxes[2].maxCorner, r, normal );
	if (d < t)
	{
		t = d;
		intersec.normal = normalize(normal);
		intersec.emission = boxes[2].emission;
		intersec.color = boxes[2].color;
		intersec.type = boxes[2].type;
	}
	
	
	// TALL MIRROR BOX
	Ray rObj;
	// transform ray into Tall Box's object space
	rObj.origin = vec3( uTallBoxInvMatrix * vec4(r.origin, 1.0) );
	rObj.direction = vec3( uTallBoxInvMatrix * vec4(r.direction, 0.0) );
	d = BoxIntersect( boxes[0].minCorner, boxes[0].maxCorner, rObj, normal );
	
	if (d < t)
	{	
		t = d;
		
		// transfom normal back into world space
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
	d = BoxIntersect( boxes[1].minCorner, boxes[1].maxCorner, rObj, normal );
	
	if (d < t)
	{	
		t = d;
		
		// transfom normal back into world space
		normal = vec3(uShortBoxNormalMatrix * normal);
		
		intersec.normal = normalize(normal);
		intersec.emission = boxes[1].emission;
		intersec.color = boxes[1].color;
		intersec.type = boxes[1].type;
	}
	
	
	return t;
}

#define EYEPATH_LENGTH    4
#define LIGHTPATH_LENGTH  2

//-----------------------------------------------------------------------
vec3 CalculateRadiance( Ray r, inout uvec2 seed )
//-----------------------------------------------------------------------
{
	Intersection intersec;
	vec3 accumCol = vec3(0);
	vec3 maskEyePath = vec3(1);
	vec3 maskLightPath = vec3(1);
	vec3 eyeX = vec3(0);
	vec3 lightX = vec3(0);
	vec3 nl, n, x;
	vec3 nlEyePath = vec3(0);
	vec3 nlLightPath = vec3(0);
	vec3 nlFirst;
	float t = INFINITY;
	bool bounceIsSpecular = true;
	//set following flag to true - we haven't found a diffuse surface yet and can exit early (keeps frame rate high)
	bool skipConnectionLightPath = true;

	
	// Eye path tracing (from Camera) ///////////////////////////////////////////////////////////////////////////
	
	for (int depth = 0; depth < EYEPATH_LENGTH; depth++)
	{
	
		t = SceneIntersect(r, intersec);
		
		if (t == INFINITY)
		{
			break;
		}
		
		if (intersec.type == LIGHT)
		{
			if (depth == 0 || (depth == 2 && nl.y == 1.0))
			{
				if (depth == 2)
					maskEyePath *= max(0.0, dot(nlFirst, quads[5].normal));

				accumCol = maskEyePath * intersec.emission;
				
				skipConnectionLightPath = true;
			}
			
			break;
		}
		
		// useful data 
		n = normalize(intersec.normal);
		nl = dot(n, r.direction) < 0.0 ? normalize(n) : normalize(n * -1.0);
		x = r.origin + r.direction * t;
		
		
		if (intersec.type == DIFF) // Ideal DIFFUSE reflection
		{
			maskEyePath *= intersec.color;
			eyeX = x + nl;
			nlEyePath = nl;
			if (depth == 0)
				nlFirst = nl;
			skipConnectionLightPath = false;

			if (depth > 2 || rand(seed) < 0.5)
			{
				break;
			}
			
			// choose random Diffuse sample vector
			r = Ray( x, randomCosWeightedDirectionInHemisphere(nl, seed) );
			r.origin += r.direction;
			eyeX = r.origin;
			bounceIsSpecular = false;
			continue;
		}
		
		if (intersec.type == SPEC)  // Ideal SPECULAR reflection
		{
			maskEyePath *= intersec.color;
			r = Ray( x, reflect(r.direction, nl) );
			r.origin += r.direction;
			bounceIsSpecular = true;

			continue;
		}
		
	} // end for (int depth = 0; depth < EYEPATH_LENGTH; depth++)
	
	
	if (skipConnectionLightPath)
		return accumCol;
	
	
	// Light path tracing (from Light sources) ////////////////////////////////////////////////////////////////////

	vec3 randPointOnLight;
	randPointOnLight.x = mix(quads[5].v0.x, quads[5].v1.x, rand(seed));
	randPointOnLight.y = quads[5].v0.y;
	randPointOnLight.z = mix(quads[5].v0.z, quads[5].v3.z, rand(seed));
	vec3 randLightDir = randomCosWeightedDirectionInHemisphere(quads[5].normal, seed);
	randLightDir = normalize(randLightDir);
	bool diffuseReached = false;
	r = Ray( randPointOnLight, randLightDir );
	r.origin += r.direction;
	lightX = r.origin;
	nlLightPath = quads[5].normal;
	maskLightPath = quads[5].emission;
	
	for (int depth = 0; depth < LIGHTPATH_LENGTH; depth++)
	{
		
		// This allows the light source to be the only node on the light path, about 50% of the time
		if (rand(seed) < 0.5)
		{
			break;
		}
		
		t = SceneIntersect(r, intersec);
		
		if ( t == INFINITY || intersec.type != DIFF)
		{
			break;
		}
		
		// useful data 
		n = normalize(intersec.normal);
		nl = dot(n, r.direction) < 0.0 ? normalize(n) : normalize(n * -1.0);
		x = r.origin + r.direction * t;
		
		
		//if (intersec.type == DIFF) // Ideal DIFFUSE reflection
		{
			maskLightPath *= intersec.color;
			
			lightX = x + nl;
			nlLightPath = nl;
			diffuseReached = true;

			if (depth > 0)
				break;

			// choose random Diffuse sample vector
			r = Ray( x, randomDirectionInHemisphere(nl, seed) );
			maskLightPath *= max(0.0, dot(r.direction, nl));
			r.origin += r.direction;
			lightX = r.origin;
			continue;
		}
		
		
	} // end for (int depth = 0; depth < LIGHTPATH_LENGTH; depth++)
	
	
	// Connect Camera path and Light path ////////////////////////////////////////////////////////////
	
	Ray connectRay = Ray(eyeX, normalize(lightX - eyeX));
	float connectDist = distance(eyeX, lightX);
	float c = SceneIntersect(connectRay, intersec);
	if (c < connectDist + 2.0)
		return accumCol;
	else
	{
		maskEyePath *= max(0.0, dot(connectRay.direction, nlEyePath));

		//if (diffuseReached)
			maskLightPath *= max(0.0, dot(-connectRay.direction, nlLightPath));

		accumCol = (maskEyePath * maskLightPath);
	}
	
	return accumCol;      
}



//-----------------------------------------------------------------------
void SetupScene(void)
//-----------------------------------------------------------------------
{
	vec3 z  = vec3(0);// No color value, Black
	vec3 L1 = vec3(1.0, 0.75, 0.4) * 40.0;// Bright Yellowish light
	
	quads[0] = Quad( vec3( 0.0, 0.0, 1.0), vec3(  0.0,   0.0,-559.2), vec3(549.6,   0.0,-559.2), vec3(549.6, 548.8,-559.2), vec3(  0.0, 548.8,-559.2),  z, vec3(1),  DIFF);// Back Wall
	quads[1] = Quad( vec3( 1.0, 0.0, 0.0), vec3(  0.0,   0.0,   0.0), vec3(  0.0,   0.0,-559.2), vec3(  0.0, 548.8,-559.2), vec3(  0.0, 548.8,   0.0),  z, vec3(0.7, 0.12,0.05), DIFF);// Left Wall Red
	quads[2] = Quad( vec3(-1.0, 0.0, 0.0), vec3(549.6,   0.0,-559.2), vec3(549.6,   0.0,   0.0), vec3(549.6, 548.8,   0.0), vec3(549.6, 548.8,-559.2),  z, vec3(0.2, 0.4, 0.36), DIFF);// Right Wall Green
	quads[3] = Quad( vec3( 0.0,-1.0, 0.0), vec3(  0.0, 548.8,-559.2), vec3(549.6, 548.8,-559.2), vec3(549.6, 548.8,   0.0), vec3(  0.0, 548.8,   0.0),  z, vec3(1),  DIFF);// Ceiling
	quads[4] = Quad( vec3( 0.0, 1.0, 0.0), vec3(  0.0,   0.0,   0.0), vec3(549.6,   0.0,   0.0), vec3(549.6,   0.0,-559.2), vec3(  0.0,   0.0,-559.2),  z, vec3(1),  DIFF);// Floor
	quads[5] = Quad( vec3( 0.0,-1.0, 0.0), vec3(213.0, 548.0,-332.0), vec3(343.0, 548.0,-332.0), vec3(343.0, 548.0,-227.0), vec3(213.0, 548.0,-227.0), L1,       z, LIGHT);// Area Light Rectangle in ceiling
	
	boxes[0] = Box( vec3(-82.0,-170.0, -80.0), vec3(82.0,170.0, 80.0), z, vec3(1), SPEC);// Tall Mirror Box Left
	boxes[1] = Box( vec3(-86.0, -85.0, -80.0), vec3(86.0, 85.0, 80.0), z, vec3(1), DIFF);// Short Diffuse Box Right
	
	boxes[2] = Box( vec3(183.0, 534.0, -362.0), vec3(373.0, 535.0, -197.0), z, vec3(1), DIFF);// Light Blocker Box
}


#include <pathtracing_main>