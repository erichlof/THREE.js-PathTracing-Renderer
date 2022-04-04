precision highp float;
precision highp int;
precision highp sampler2D;

uniform mat4 uShortBoxInvMatrix;
uniform mat4 uTallBoxInvMatrix;

#include <pathtracing_uniforms_and_defines>

#define N_QUADS 6
#define N_BOXES 3

vec3 rayOrigin, rayDirection;
// recorded intersection data:
vec3 hitNormal, hitEmission, hitColor;
vec2 hitUV;
float hitObjectID;
int hitType = -100;

struct Quad { vec3 normal; vec3 v0; vec3 v1; vec3 v2; vec3 v3; vec3 emission; vec3 color; int type; };
struct Box { vec3 minCorner; vec3 maxCorner; vec3 emission; vec3 color; int type; };

Quad quads[N_QUADS];
Box boxes[N_BOXES];


#include <pathtracing_random_functions>

#include <pathtracing_quad_intersect>

#include <pathtracing_box_intersect>


//---------------------------------------------------------------------------------------
float SceneIntersect( )
//---------------------------------------------------------------------------------------
{
	vec3 normal;
	vec3 rObjOrigin, rObjDirection;
        float d;
	float t = INFINITY;
	bool isRayExiting = false;
	
	for (int i = 0; i < N_QUADS; i++)
        {
		d = QuadIntersect( quads[i].v0, quads[i].v1, quads[i].v2, quads[i].v3, rayOrigin, rayDirection, false );
		if (d < t)
		{
			t = d;
			hitNormal = quads[i].normal;
			hitEmission = quads[i].emission;
			hitColor = quads[i].color;
			hitType = quads[i].type;
			hitObjectID = 0.0;
		}
        }
	
	// LIGHT BLOCKER BOX
	d = BoxIntersect( boxes[2].minCorner, boxes[2].maxCorner, rayOrigin, rayDirection, normal, isRayExiting );
	if (d < t)
	{
		t = d;
		hitNormal = normal;
		hitEmission = boxes[2].emission;
		hitColor = boxes[2].color;
		hitType = boxes[2].type;
		hitObjectID = 1.0;
	}
	
	
	// TALL MIRROR BOX
	// transform ray into Tall Box's object space
	rObjOrigin = vec3( uTallBoxInvMatrix * vec4(rayOrigin, 1.0) );
	rObjDirection = vec3( uTallBoxInvMatrix * vec4(rayDirection, 0.0) );
	d = BoxIntersect( boxes[0].minCorner, boxes[0].maxCorner, rObjOrigin, rObjDirection, normal, isRayExiting );
	
	if (d < t)
	{	
		t = d;
		
		// transfom normal back into world space
		normal = normal;
		hitNormal = transpose(mat3(uTallBoxInvMatrix)) * normal;
		hitEmission = boxes[0].emission;
		hitColor = boxes[0].color;
		hitType = boxes[0].type;
		hitObjectID = 2.0;
	}
	
	
	// SHORT DIFFUSE WHITE BOX
	// transform ray into Short Box's object space
	rObjOrigin = vec3( uShortBoxInvMatrix * vec4(rayOrigin, 1.0) );
	rObjDirection = vec3( uShortBoxInvMatrix * vec4(rayDirection, 0.0) );
	d = BoxIntersect( boxes[1].minCorner, boxes[1].maxCorner, rObjOrigin, rObjDirection, normal, isRayExiting );
	
	if (d < t)
	{	
		t = d;
		
		// transfom normal back into world space
		normal = normal;
		hitNormal = transpose(mat3(uShortBoxInvMatrix)) * normal;
		hitEmission = boxes[1].emission;
		hitColor = boxes[1].color;
		hitType = boxes[1].type;
		hitObjectID = 3.0;
	}
	
	
	return t;
} // end float SceneIntersect( )


//-----------------------------------------------------------------------------------------------------------------------------
vec3 CalculateRadiance( out vec3 objectNormal, out vec3 objectColor, out float objectID, out float pixelSharpness )
//-----------------------------------------------------------------------------------------------------------------------------
{
	vec3 accumCol = vec3(0);
        vec3 mask = vec3(1);
	vec3 x, n, nl;

	float t;

	int diffuseCount = 0;
	int previousIntersecType = -100;

	bool bounceIsSpecular = true;

	pixelSharpness = 1.01; // can't really use de-noiser on this demo

	// hope that we get lucky enough to find the blocked light source
	for (int bounces = 0; bounces < 5; bounces++)
	{
                
		t = SceneIntersect();
		
		if (t == INFINITY)
                        break;
		
		// useful data 
		n = normalize(hitNormal);
                nl = dot(n, rayDirection) < 0.0 ? n : -n;
		x = rayOrigin + rayDirection * t;

		// if (diffuseCount == 0)
		// {
		// 	objectNormal = nl;
		// 	objectColor = hitColor;
		// 	objectID = hitObjectID;
		// }
		

		// if we reached something bright, don't spawn any more rays
		if (hitType == LIGHT )
		{
			accumCol = mask * hitEmission;
			break;
		}
		
		    
                if (hitType == DIFF) // Ideal DIFFUSE reflection
                {
			diffuseCount++;

			previousIntersecType = DIFF;
			
			mask *= hitColor;

			bounceIsSpecular = false;

			// Russian Roulette
			float p = max(mask.r, max(mask.g, mask.b));
			if (rng() > p) 
				break;
			mask /= p;
			
			/* // Russian Roulette (from pbrt book)
			float q = max(mask.r, max(mask.g, mask.b));
			q = max(0.05, 1.0 - q);
			if (rng() < q) break;
			mask /= (1.0 - q); */
			
			// choose random Diffuse sample vector
			rayDirection = randomCosWeightedDirectionInHemisphere(nl);
			rayOrigin = x + nl * uEPS_intersect;

			mask *= max(0.0, dot(nl, rayDirection));
                	continue;
                }
		
                if (hitType == SPEC)  // Ideal SPECULAR reflection
                {
			previousIntersecType = SPEC;

			mask *= hitColor;

			rayDirection = reflect(rayDirection, nl);
			rayOrigin = x + nl * uEPS_intersect;
                        continue;
                }
		
	} // for (int bounces = 0; bounces < 10; bounces++)
	
	return max(vec3(0), accumCol);      
}


//-----------------------------------------------------------------------
void SetupScene(void)
//-----------------------------------------------------------------------
{
	vec3 z  = vec3(0);// No color value, Black
	vec3 L1 = vec3(1.0, 0.75, 0.4) * 30.0;// Bright Yellowish light
	
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
