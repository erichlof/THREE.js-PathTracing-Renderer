precision highp float;
precision highp int;
precision highp sampler2D;

#include <pathtracing_uniforms_and_defines>

#define N_RECTANGLES 1
#define N_QUADS 1
#define N_BOXES 1
#define N_SPHERES 9

vec3 rayOrigin, rayDirection;
// recorded intersection data:
vec3 hitNormal, hitEmission, hitColor;
vec2 hitUV;
float hitObjectID = -INFINITY;
float hitIoR = 0.0;
int hitType = -100;

struct Rectangle { vec3 position; vec3 normal; float radiusU; float radiusV; vec3 color; float IoR; int type; };
struct Quad { vec3 normal; vec3 v0; vec3 v1; vec3 v2; vec3 v3; vec3 emission; vec3 color; int type; };
struct Box { vec3 minCorner; vec3 maxCorner; vec3 color; float IoR; int type; };
struct Sphere { float radius; vec3 position; vec3 emission; vec3 color; float IoR; int type; };

Rectangle rectangles[N_RECTANGLES];
Quad quads[N_QUADS];
Box boxes[N_BOXES];
Sphere spheres[N_SPHERES];


#include <pathtracing_random_functions>

#include <pathtracing_calc_fresnel_reflectance>

#include <pathtracing_sphere_intersect>

#include <pathtracing_box_intersect>

#include <pathtracing_rectangle_intersect>

#include <pathtracing_quad_intersect>

#include <pathtracing_sample_quad_light>



//---------------------------------------------------------------------------------------
float SceneIntersect( )
//---------------------------------------------------------------------------------------
{
	vec3 n;
	vec3 hitPoint;
	float patternX, patternZ;
	float d;
	float t = INFINITY;
	int objectCount = 0;
	int isRayExiting;
	
	hitObjectID = -INFINITY;

	

	// FLOOR TILE PATTERN (VERY THIN, FLAT BOX)
	d = BoxIntersect( boxes[0].minCorner, boxes[0].maxCorner, rayOrigin, rayDirection, n, isRayExiting );
	hitPoint = rayOrigin + rayDirection * d;
	patternX = abs(cos(hitPoint.x * 0.75));
	patternZ = abs(cos(hitPoint.z * 0.75));
	if (d < t)
	{
		t = d;
		hitNormal = n;
		hitColor = boxes[0].color;
		hitIoR = boxes[0].IoR;
		hitType = boxes[0].type;
		hitObjectID = float(objectCount);
	}
	objectCount++;

	if ((patternX > 0.0 && patternX < 0.05) || (patternZ > 0.0 && patternZ < 0.05))
		t = INFINITY;

	// FLOOR RECTANGLE (UNDERNEATH TILE PATTERN THIN BOX)
	d = RectangleIntersect( rectangles[0].position, rectangles[0].normal, rectangles[0].radiusU, rectangles[0].radiusV, rayOrigin, rayDirection);
	if (d < t)
	{
		t = d;
		hitNormal = rectangles[0].normal;
		hitColor = rectangles[0].color;
		hitIoR = rectangles[0].IoR;
		hitType = rectangles[0].type;
		hitObjectID = float(objectCount);
	}
	objectCount++;

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
	
	d = SphereIntersect( spheres[0].radius, spheres[0].position, rayOrigin, rayDirection );
	if (d < t)
	{
		t = d;
		hitNormal = (rayOrigin + rayDirection * t) - spheres[0].position;
		hitEmission = spheres[0].emission;
		hitColor = spheres[0].color;
		hitIoR = spheres[0].IoR;
		hitType = spheres[0].type;
		hitObjectID = float(objectCount);
	}
	objectCount++;

	d = SphereIntersect( spheres[1].radius, spheres[1].position, rayOrigin, rayDirection );
	if (d < t)
	{
		t = d;
		hitNormal = (rayOrigin + rayDirection * t) - spheres[1].position;
		hitEmission = spheres[1].emission;
		hitColor = spheres[1].color;
		hitIoR = spheres[1].IoR;
		hitType = spheres[1].type;
		hitObjectID = float(objectCount);
	}
	objectCount++;

	d = SphereIntersect( spheres[2].radius, spheres[2].position, rayOrigin, rayDirection );
	if (d < t)
	{
		t = d;
		hitNormal = (rayOrigin + rayDirection * t) - spheres[2].position;
		hitEmission = spheres[2].emission;
		hitColor = spheres[2].color;
		hitIoR = spheres[2].IoR;
		hitType = spheres[2].type;
		hitObjectID = float(objectCount);
	}
	objectCount++;

	d = SphereIntersect( spheres[3].radius, spheres[3].position, rayOrigin, rayDirection );
	if (d < t)
	{
		t = d;
		hitNormal = (rayOrigin + rayDirection * t) - spheres[3].position;
		hitEmission = spheres[3].emission;
		hitColor = spheres[3].color;
		hitIoR = spheres[3].IoR;
		hitType = spheres[3].type;
		hitObjectID = float(objectCount);
	}
	objectCount++;

	d = SphereIntersect( spheres[4].radius, spheres[4].position, rayOrigin, rayDirection );
	if (d < t)
	{
		t = d;
		hitNormal = (rayOrigin + rayDirection * t) - spheres[4].position;
		hitEmission = spheres[4].emission;
		hitColor = spheres[4].color;
		hitIoR = spheres[4].IoR;
		hitType = spheres[4].type;
		hitObjectID = float(objectCount);
	}
	objectCount++;

	d = SphereIntersect( spheres[5].radius, spheres[5].position, rayOrigin, rayDirection );
	if (d < t)
	{
		t = d;
		hitNormal = (rayOrigin + rayDirection * t) - spheres[5].position;
		hitEmission = spheres[5].emission;
		hitColor = spheres[5].color;
		hitIoR = spheres[5].IoR;
		hitType = spheres[5].type;
		hitObjectID = float(objectCount);
	}
	objectCount++;

	d = SphereIntersect( spheres[6].radius, spheres[6].position, rayOrigin, rayDirection );
	if (d < t)
	{
		t = d;
		hitNormal = (rayOrigin + rayDirection * t) - spheres[6].position;
		hitEmission = spheres[6].emission;
		hitColor = spheres[6].color;
		hitIoR = spheres[6].IoR;
		hitType = spheres[6].type;
		hitObjectID = float(objectCount);
	}
	objectCount++;

	d = SphereIntersect( spheres[7].radius, spheres[7].position, rayOrigin, rayDirection );
	if (d < t)
	{
		t = d;
		hitNormal = (rayOrigin + rayDirection * t) - spheres[7].position;
		hitEmission = spheres[7].emission;
		hitColor = spheres[7].color;
		hitIoR = spheres[7].IoR;
		hitType = spheres[7].type;
		hitObjectID = float(objectCount);
	}
	objectCount++;

	d = SphereIntersect( spheres[8].radius, spheres[8].position, rayOrigin, rayDirection );
	if (d < t)
	{
		t = d;
		hitNormal = (rayOrigin + rayDirection * t) - spheres[8].position;
		hitEmission = spheres[8].emission;
		hitColor = spheres[8].color;
		hitIoR = spheres[8].IoR;
		hitType = spheres[8].type;
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
	vec3 reflectionMask = vec3(1);
	vec3 reflectionRayOrigin = vec3(0);
	vec3 reflectionRayDirection = vec3(0);
	vec3 diffuseBounceMask = vec3(1);
	vec3 diffuseBounceRayOrigin = vec3(0);
	vec3 diffuseBounceRayDirection = vec3(0);
	vec3 diffuse2ndBounceMask = vec3(1);
	vec3 diffuse2ndBounceRayOrigin = vec3(0);
	vec3 diffuse2ndBounceRayDirection = vec3(0);
	vec3 x, n, nl;
        
	float t;
	float nc, nt, ratioIoR, Re, Tr;
	float weight;
	float previousObjectID;

	int reflectionBounces = -1;
	int diffuseCount = 0;
	int previousIntersecType = -100;
	hitType = -100;

	int bounceIsSpecular = TRUE;
	int sampleLight = FALSE;
	int willNeedReflectionRay = FALSE;
	int isReflectionTime = FALSE;
	int reflectionNeedsToBeSharp = FALSE;
	int willNeedDiffuseBounceRay = FALSE;
	int willNeed2ndDiffuseBounceRay = FALSE;
	int isDiffuseBounceTime = FALSE;

	
	for (int bounces = 0; bounces < 11; bounces++)
	{
		if (isReflectionTime == TRUE)
			reflectionBounces++;

		previousIntersecType = hitType;
		previousObjectID = hitObjectID;

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
				isReflectionTime = FALSE;
				diffuseCount = 1;
				continue;
			}

			if (willNeed2ndDiffuseBounceRay == TRUE)
			{
				mask = diffuse2ndBounceMask;
				rayOrigin = diffuse2ndBounceRayOrigin;
				rayDirection = diffuse2ndBounceRayDirection;

				willNeed2ndDiffuseBounceRay = FALSE;
				bounceIsSpecular = FALSE;
				sampleLight = FALSE;
				isDiffuseBounceTime = TRUE;
				isReflectionTime = FALSE;
				diffuseCount = 2;
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
			objectID = hitObjectID;
		}
		if (isReflectionTime == FALSE && diffuseCount == 0 && hitObjectID != previousObjectID)
		{
			objectNormal += n;
			objectColor += hitColor;
		}
		if (reflectionNeedsToBeSharp == TRUE && reflectionBounces == 0)
		{
			objectNormal += n;
			//objectColor += hitColor;
		}

		
		
		if (hitType == LIGHT)
		{	
			if (diffuseCount == 0 && isReflectionTime == FALSE)
				pixelSharpness = 1.0;

			if (isReflectionTime == TRUE && bounceIsSpecular == TRUE)
			{
				objectNormal += nl;
				//objectColor = hitColor;
				objectID += hitObjectID;
			}
			
			if (bounceIsSpecular == TRUE || sampleLight == TRUE)
				accumCol += mask * hitEmission;

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

			if (willNeed2ndDiffuseBounceRay == TRUE)
			{
				mask = diffuse2ndBounceMask;
				rayOrigin = diffuse2ndBounceRayOrigin;
				rayDirection = diffuse2ndBounceRayDirection;

				willNeed2ndDiffuseBounceRay = FALSE;
				bounceIsSpecular = FALSE;
				sampleLight = FALSE;
				isDiffuseBounceTime = TRUE;
				isReflectionTime = FALSE;
				diffuseCount = 2;
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
				continue;
			}
			// reached a light, so we can exit
			break;

		} // end if (hitType == LIGHT)


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

			if (willNeed2ndDiffuseBounceRay == TRUE)
			{
				mask = diffuse2ndBounceMask;
				rayOrigin = diffuse2ndBounceRayOrigin;
				rayDirection = diffuse2ndBounceRayDirection;

				willNeed2ndDiffuseBounceRay = FALSE;
				bounceIsSpecular = FALSE;
				sampleLight = FALSE;
				isDiffuseBounceTime = TRUE;
				isReflectionTime = FALSE;
				diffuseCount = 2;
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
				continue;
			}

			break;
		}
		

		
		
		if (hitType == COAT)  // Diffuse object underneath with ClearCoat on top
		{
			nc = 1.0; // IOR of Air
			nt = hitIoR; // IOR of Clear Coat
			Re = calcFresnelReflectance(rayDirection, nl, nc, nt, ratioIoR);
			Tr = 1.0 - Re;
			
			if (bounceIsSpecular == TRUE && isDiffuseBounceTime == FALSE && hitObjectID != previousObjectID)
			{
				reflectionMask = mask * Re;
				reflectionRayDirection = reflect(rayDirection, nl); // reflect ray from surface
				reflectionRayOrigin = x + nl * uEPS_intersect;
				willNeedReflectionRay = TRUE;
				if (bounces == 0)
					reflectionNeedsToBeSharp = TRUE;
			}

			diffuseCount++;

			mask *= Tr;
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
			if (diffuseCount == 2)
			{
				diffuse2ndBounceMask = mask;
				diffuse2ndBounceRayOrigin = rayOrigin;
				diffuse2ndBounceRayDirection = randomCosWeightedDirectionInHemisphere(nl);
				willNeed2ndDiffuseBounceRay = TRUE;
			}
                        
			rayDirection = sampleQuadLight(x, nl, quads[0], weight);
			mask *= weight;
			sampleLight = TRUE;
			continue;
			
		} //end if (hitType == COAT)

		
	} // end for (int bounces = 0; bounces < 11; bounces++)
	
	
	return max(vec3(0), accumCol);

} // end vec3 CalculateRadiance( out vec3 objectNormal, out vec3 objectColor, out float objectID, out float pixelSharpness )



//-----------------------------------------------------------------------
void SetupScene(void)
//-----------------------------------------------------------------------
{
	vec3 z  = vec3(0);// No color value, Black        
	vec3 L1 = vec3(1.0, 1.0, 1.0) * 15.0;// Bright light
	vec3 lightPos = vec3(-36, 50, 4);
	float lightRadius = 12.0;    
	
	spheres[0] = Sphere(4.9, vec3(-11.2, 4.9, 9), z, vec3(0.01, 0.01, 0.8), 2.0, COAT);// Blue Sphere front left
	spheres[1] = Sphere(2.9, vec3(7.3, 2.9, 10),  z, vec3(0.12, 0.01, 0.6), 2.0, COAT);// Purple Sphere front right
	spheres[2] = Sphere(3.3, vec3(16.7, 3.3, 10), z, vec3(0.01, 0.6, 0.01), 2.0, COAT);// Green Sphere front right
	spheres[3] = Sphere(4.1, vec3( 0, 4.1, 0),    z, vec3(0.9,  0.9,  0.9), 2.5, COAT);// White Sphere center
	spheres[4] = Sphere(3.3, vec3(-9.5, 3.3, -5), z, vec3(1.0, 0.01, 0.01), 1.8, COAT);// Red Sphere left
	spheres[5] = Sphere(8.2, vec3( 13, 8.2, -8),  z, vec3(1.0, 0.01, 0.01), 1.8, COAT);// Red Sphere right
	spheres[6] = Sphere(6.3, vec3(-13.5,6.3,-19), z, vec3(0.12, 0.01, 0.6), 2.0, COAT);// Purple Sphere back left
	spheres[7] = Sphere(2.4, vec3(-4.3,2.4,-11.6),z, vec3(0.01, 0.6, 0.01), 2.0, COAT);// Green Sphere back left
	spheres[8] = Sphere(5.0, vec3( 3.2, 5, -26),  z, vec3(0.01, 0.01, 0.8), 2.0, COAT);// Blue Sphere back right
	
	quads[0] = Quad(vec3(0,-1,0), vec3(lightPos + vec3(-lightRadius,0,-lightRadius)), 
				      vec3(lightPos + vec3( lightRadius,0,-lightRadius)), 
				      vec3(lightPos + vec3( lightRadius,0, lightRadius)),
	 			      vec3(lightPos + vec3(-lightRadius,0, lightRadius)), L1, z, LIGHT);// Area Light Rectangle
	boxes[0] = Box(vec3(-150, -0.1, -150), vec3(150, 0.0, 150), vec3(0.09), 1.4, COAT);// Floor tiles-level pattern (thin box)
	rectangles[0] = Rectangle( vec3(0,-0.05,0), vec3(0,1,0), 150.0, 150.0, vec3(0.2), 1.0, COAT);// Ground plane underneath tile pattern thin box
}


#include <pathtracing_main>