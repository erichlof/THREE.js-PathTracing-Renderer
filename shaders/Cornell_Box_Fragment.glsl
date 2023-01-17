precision highp float;
precision highp int;
precision highp sampler2D;

uniform mat4 uShortBoxInvMatrix;
uniform mat4 uTallBoxInvMatrix;

#include <pathtracing_uniforms_and_defines>

#define N_QUADS 1
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

#include <pathtracing_box_interior_intersect>

#include <pathtracing_sample_quad_light>


//---------------------------------------------------------------------------------------
float SceneIntersect( )
//---------------------------------------------------------------------------------------
{
	vec3 rObjOrigin, rObjDirection; 
	vec3 normal, n;
        float d;
	float t = INFINITY;
	int isRayExiting = FALSE;
	int objectCount = 0;
	
	hitObjectID = -INFINITY;
	

	d = QuadIntersect( quads[0].v0, quads[0].v1, quads[0].v2, quads[0].v3, rayOrigin, rayDirection, FALSE );
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
	
	d = BoxInteriorIntersect( boxes[2].minCorner, boxes[2].maxCorner, rayOrigin, rayDirection, n );
	if (d < t && n != vec3(0,0,-1))
	{
		t = d;
		hitNormal = n;
		hitEmission = boxes[2].emission;
		hitColor = vec3(1);
		hitType = DIFF;
	
		if (n == vec3(1,0,0)) // left wall
		{
			hitColor = vec3(0.7, 0.12,0.05);
		}
		else if (n == vec3(-1,0,0)) // right wall
		{
			hitColor = vec3(0.2, 0.4, 0.36);
		}
		
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
		normal = normal;
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
		normal = normal;
		hitNormal = transpose(mat3(uShortBoxInvMatrix)) * normal;
		hitEmission = boxes[1].emission;
		hitColor = boxes[1].color;
		hitType = boxes[1].type;
		hitObjectID = float(objectCount);
	}

	return t;
} // end float SceneIntersect( )


//-----------------------------------------------------------------------------------------------------------------------------
vec3 CalculateRadiance( out vec3 objectNormal, out vec3 objectColor, out float objectID, out float pixelSharpness )
//-----------------------------------------------------------------------------------------------------------------------------
{
        Quad light = quads[0];

	vec3 accumCol = vec3(0);
        vec3 mask = vec3(1);
        vec3 n, nl, x;
	vec3 dirToLight;
        
	float t = INFINITY;
	float weight, p;
	
	int diffuseCount = 0;
	int previousIntersecType = -100;
	hitType = -100;
	
	int bounceIsSpecular = TRUE;
	int sampleLight = FALSE;
	int createCausticRay = FALSE;


	for (int bounces = 0; bounces < 5; bounces++)
	{
		previousIntersecType = hitType;

		t = SceneIntersect();

		if (t == INFINITY)
			break;

		// useful data 
		n = normalize(hitNormal);
                nl = dot(n, rayDirection) < 0.0 ? n : -n;
		x = rayOrigin + rayDirection * t;

		if (bounces == 0)
		{
			objectNormal = nl;
			objectColor = hitColor;
			objectID = hitObjectID;
		}
		if (bounces == 1 && previousIntersecType == SPEC)
		{
			objectNormal = nl;
		}
		
		
		if (hitType == LIGHT)
		{	
			if (diffuseCount == 0)
				pixelSharpness = 1.01;

			if (bounceIsSpecular == TRUE || sampleLight == TRUE || createCausticRay == TRUE)
				accumCol = mask * hitEmission;

			// reached a light source, so we can exit
			break;
		}
		
		// if we get here and sampleLight is still TRUE, shadow ray failed to find the light source 
		// the ray hit an occluding object along its way to the light
		if (sampleLight == TRUE) 
			break;



                if (hitType == DIFF) // Ideal DIFFUSE reflection
                {
			if (createCausticRay == TRUE)
				break;

			if ( diffuseCount == 0 && previousIntersecType == SPEC )	
				objectColor = hitColor;

			diffuseCount++;

			mask *= hitColor;

			// create caustic ray
                        if (diffuseCount == 1 && rand() < 0.25)
                        {
				mask *= 3.0;
				createCausticRay = TRUE;

				vec3 randVec = vec3(rng() * 2.0 - 1.0, rng() * 2.0 - 1.0, rng() * 2.0 - 1.0);
				vec3 offset = vec3(randVec.x * 82.0, randVec.y * 170.0, randVec.z * 80.0);
				vec3 target = vec3(180.0 + offset.x, 170.0 + offset.y, -350.0 + offset.z);
				
				rayDirection = normalize(target - x);
				rayOrigin = x + nl * uEPS_intersect;
				
				weight = max(0.0, dot(nl, rayDirection));
				mask *= weight;

				continue;
			}

			bounceIsSpecular = FALSE;

			if (diffuseCount == 1 && rand() < 0.5)
			{	
				mask *= 2.0;
				// choose random Diffuse sample vector
				rayDirection = randomCosWeightedDirectionInHemisphere(nl);
				rayOrigin = x + nl * uEPS_intersect;
				continue;
			}
			
			dirToLight = sampleQuadLight(x, nl, light, weight);
			mask *= diffuseCount == 1 ? 2.0 : 1.0;
			mask *= weight;

			rayDirection = dirToLight;
			rayOrigin = x + nl * uEPS_intersect;
			sampleLight = TRUE;
			continue;
                        
                } // end if (hitType == DIFF)
		
                if (hitType == SPEC)  // Ideal SPECULAR reflection
		{
			mask *= hitColor;

			rayDirection = reflect(rayDirection, nl);
			rayOrigin = x + nl * uEPS_intersect;

			continue;
		}
		
	} // end for (int bounces = 0; bounces < 5; bounces++)
	
	return max(vec3(0), accumCol);

}  // end vec3 CalculateRadiance( out vec3 objectNormal, out vec3 objectColor, out float objectID, out float pixelSharpness )


//-----------------------------------------------------------------------
void SetupScene(void)
//-----------------------------------------------------------------------
{
	vec3 z  = vec3(0);// No color value, Black        
	vec3 L1 = vec3(1.0, 0.7, 0.38) * 10.0;// Bright Yellowish light
	
	quads[0] = Quad( vec3( 0.0,-1.0, 0.0), vec3(213.0, 548.0,-332.0), vec3(343.0, 548.0,-332.0), vec3(343.0, 548.0,-227.0), vec3(213.0, 548.0,-227.0), L1, z, LIGHT);// Area Light Rectangle in ceiling
	
	boxes[0] = Box( vec3(-82.0,-170.0, -80.0), vec3(82.0,170.0, 80.0), z, vec3(1), SPEC);// Tall Mirror Box Left
	boxes[1] = Box( vec3(-86.0, -85.0, -80.0), vec3(86.0, 85.0, 80.0), z, vec3(1), DIFF);// Short Diffuse Box Right
	boxes[2] = Box( vec3(0, 0,-559.2), vec3(549.6, 548.8, 0), z, vec3(1), DIFF);// the Cornell Box interior 
}


#include <pathtracing_main>
