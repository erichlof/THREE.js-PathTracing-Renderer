precision highp float;
precision highp int;
precision highp sampler2D;

uniform mat4 uShortBoxInvMatrix;
uniform mat4 uTallBoxInvMatrix;

#include <pathtracing_uniforms_and_defines>

#define N_QUADS 1
#define N_BOXES 4

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


//---------------------------------------------------------------------------------------
float SceneIntersect( )
//---------------------------------------------------------------------------------------
{
	vec3 normal, n;
	vec3 rObjOrigin, rObjDirection;
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

	d = BoxInteriorIntersect( boxes[3].minCorner, boxes[3].maxCorner, rayOrigin, rayDirection, n );
	if (d < t && n != vec3(0,0,-1))
	{
		t = d;
		hitNormal = n;
		hitEmission = boxes[3].emission;
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
	
	// LIGHT-BLOCKER THIN BOX
	d = BoxIntersect( boxes[2].minCorner, boxes[2].maxCorner, rayOrigin, rayDirection, normal, isRayExiting );
	if (d < t)
	{
		t = d;
		hitNormal = normal;
		hitEmission = boxes[2].emission;
		hitColor = boxes[2].color;
		hitType = boxes[2].type;
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



//---------------------------------------------------------------------------------------------------------------------------------------
vec3 CalculateRadiance( out vec3 objectNormal, out vec3 objectColor, out float objectID, out float pixelSharpness )
//---------------------------------------------------------------------------------------------------------------------------------------
{	
	vec3 originalRayOrigin = rayOrigin;
	vec3 originalRayDirection = rayDirection;
	
	vec3 accumCol = vec3(0);
        vec3 mask = vec3(1);
	vec3 n, nl, x;
	vec3 randPointOnLight = vec3( mix(quads[0].v0.x, quads[0].v2.x, rng()),
				      quads[0].v0.y,
				      mix(quads[0].v0.z, quads[0].v2.z, rng()) );
	vec3 lightHitPos = randPointOnLight;
	vec3 lightHitEmission = quads[0].emission;
	vec3 diffuseBounceMask = vec3(1);
	vec3 diffuseBounceRayOrigin = vec3(0);
	vec3 diffuseBounceRayDirection = vec3(0);
        
	float lightHitDistance = INFINITY;
	float t = INFINITY;
	float weight = 0.0;
	
	int diffuseCount = 0;
	int previousIntersecType = -100;

	int bounceIsSpecular = TRUE;
	int sampleLight = FALSE;
	int ableToJoinPaths = FALSE;
	int diffuseFound = FALSE;
	int willNeedDiffuseBounceRay = FALSE;
	int isDiffuseBounceTime = FALSE;

	// first light trace
	rayDirection = quads[0].normal;
	rayOrigin = randPointOnLight + quads[0].normal * uEPS_intersect;
	t = SceneIntersect();

	if (t < INFINITY && hitType == DIFF)
	{
		hitNormal = normalize(hitNormal);
		diffuseFound = TRUE;
		lightHitPos = rayOrigin + rayDirection * t;
		weight = max(0.0, dot(-rayDirection, hitNormal));
		lightHitEmission *= hitColor  * weight;

		// second light trace
		rayDirection = randomCosWeightedDirectionInHemisphere(hitNormal);
		rayOrigin = lightHitPos + hitNormal * uEPS_intersect;
		
		t = SceneIntersect();
		if (t < INFINITY && hitType == DIFF && rand() < 0.5)
		{
			hitNormal = normalize(hitNormal);
			lightHitPos = rayOrigin + rayDirection * t;
			weight = max(0.0, dot(-rayDirection, hitNormal));
			lightHitEmission *= hitColor * weight;

			/* // third light trace
			rayDirection = randomCosWeightedDirectionInHemisphere(hitNormal);
			rayOrigin = lightHitPos + hitNormal * uEPS_intersect;
			t = SceneIntersect();
			if (t < INFINITY && hitType == DIFF && rand() < 0.2)
			{
				hitNormal = normalize(hitNormal);
				lightHitPos = rayOrigin + rayDirection * t;
				weight = max(0.0, dot(-rayDirection, hitNormal));
				lightHitEmission *= hitColor * weight;
			} */
		}

	}

	// this allows the original light to be the lightsource once in a while
	if ( diffuseFound == FALSE || rng() < 0.5 )
	{
		lightHitPos = randPointOnLight;
		lightHitEmission = quads[0].emission;
	}


	// regular path tracing from camera
	rayOrigin = originalRayOrigin;
	rayDirection = originalRayDirection;

	hitObjectID = -INFINITY;

	for (int bounces = 0; bounces < 10; bounces++)
	{

		t = SceneIntersect();
		
		if (t == INFINITY)
		{
			// this makes the object edges sharp against the black background
			if (bounces == 0 || (bounces == 1 && previousIntersecType == SPEC))
				pixelSharpness = 1.0;
			
			if (willNeedDiffuseBounceRay == TRUE)
			{
				mask = diffuseBounceMask;
				rayOrigin = diffuseBounceRayOrigin;
				rayDirection = diffuseBounceRayDirection;

				willNeedDiffuseBounceRay = FALSE;
				bounceIsSpecular = FALSE;
				sampleLight = FALSE;
				isDiffuseBounceTime = TRUE;
				diffuseCount = 1;
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
			objectNormal = n;
			objectColor = hitColor;
			objectID = hitObjectID;
		}
		if (bounces == 1 && previousIntersecType == SPEC)
		{
			objectNormal += n;
		}
		
		
		if (hitType == LIGHT)
		{	
			if (diffuseCount == 0)
				pixelSharpness = 1.0;
			
			if (sampleLight == TRUE)
				accumCol = mask * hitEmission * max(0.0, dot(-rayDirection, nl));

			else
				accumCol = mask * hitEmission;

			if (willNeedDiffuseBounceRay == TRUE)
			{
				mask = diffuseBounceMask;
				rayOrigin = diffuseBounceRayOrigin;
				rayDirection = diffuseBounceRayDirection;

				willNeedDiffuseBounceRay = FALSE;
				bounceIsSpecular = FALSE;
				sampleLight = FALSE;
				isDiffuseBounceTime = TRUE;
				diffuseCount = 1;
				continue;
			}
			// reached a light, so we can exit
			break;
		}


		if (hitType == DIFF && sampleLight == TRUE)
		{
			ableToJoinPaths = abs(lightHitDistance - t) < 0.5 ? TRUE : FALSE;

			if (ableToJoinPaths == TRUE)
			{
				weight = max(0.0, dot(nl, -rayDirection));
				accumCol = mask * lightHitEmission * weight;
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
				diffuseCount = 1;
				continue;
			}
			
			break;
		}

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
				diffuseCount = 1;
				continue;
			}

			break;
		}
			


                if (hitType == DIFF) // Ideal DIFFUSE reflection
		{
			diffuseCount++;

			previousIntersecType = DIFF;

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
			
			rayDirection = normalize(lightHitPos - x);
			weight = max(0.0, dot(nl, rayDirection));
			mask *= weight;
			lightHitDistance = distance(rayOrigin, lightHitPos);
			sampleLight = TRUE;
			continue;
			
		} // end if (hitType == DIFF)
		
		if (hitType == SPEC)  // Ideal SPECULAR reflection
		{
			previousIntersecType = SPEC;

			mask *= hitColor;

			rayDirection = reflect(rayDirection, nl);
			rayOrigin = x + nl * uEPS_intersect;

			//bounceIsSpecular = TRUE; // turn on mirror caustics
			continue;
		}
		
	} // end for (int bounces = 0; bounces < 10; bounces++)
	
	
	return max(vec3(0), accumCol);
	      
}



//-----------------------------------------------------------------------
void SetupScene(void)
//-----------------------------------------------------------------------
{
	vec3 z  = vec3(0);// No color value, Black
	vec3 L1 = vec3(1.0, 0.75, 0.4) * 15.0;// Bright Yellowish light
	
	quads[0] = Quad( vec3( 0.0,-1.0, 0.0), vec3(213.0, 548.0,-332.0), vec3(343.0, 548.0,-332.0), vec3(343.0, 548.0,-227.0), vec3(213.0, 548.0,-227.0), L1, z, LIGHT);// Area Light Rectangle in ceiling
	
	boxes[0] = Box( vec3(-82.0,-170.0, -80.0), vec3(82.0,170.0, 80.0), z, vec3(1), SPEC);// Tall Mirror Box Left
	boxes[1] = Box( vec3(-86.0, -85.0, -80.0), vec3(86.0, 85.0, 80.0), z, vec3(1), DIFF);// Short Diffuse Box Right
	boxes[2] = Box( vec3(183.0, 534.0, -362.0), vec3(373.0, 535.0, -197.0), z, vec3(1), DIFF);// Light Blocker Box
	boxes[3] = Box( vec3(0, 0,-559.2), vec3(549.6, 548.8, 0), z, vec3(1), DIFF);// the Cornell Box interior 
}


#include <pathtracing_main>
