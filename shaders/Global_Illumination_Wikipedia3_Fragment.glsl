precision highp float;
precision highp int;
precision highp sampler2D;

#include <pathtracing_uniforms_and_defines>

#define N_RECTANGLES 1
#define N_SPHERES 8
#define DIRECTION_TO_SUN normalize(vec3(-1, 1, 0.1))

vec3 rayOrigin, rayDirection;
// recorded intersection data:
vec3 hitNormal, hitEmission, hitColor;
vec2 hitUV;
float hitObjectID = -INFINITY;
float hitIoR = 0.0;
int hitType = -100;

struct Rectangle { vec3 position; vec3 normal; float radiusU; float radiusV; vec3 color; float IoR; int type; };
struct Sphere { float radius; vec3 position; vec3 emission; vec3 color; float IoR; int type; };

Rectangle rectangles[N_RECTANGLES];
Sphere spheres[N_SPHERES];


#include <pathtracing_random_functions>

#include <pathtracing_calc_fresnel_reflectance>

#include <pathtracing_sphere_intersect>

#include <pathtracing_rectangle_intersect>



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


	// GROUND RECTANGLE
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


	return t;
} // end float SceneIntersect( )


vec3 getSkyColor(vec3 rayDir)
{
	vec3 skyColor = mix(vec3(0.6, 0.7, 1.0) * 2.0, vec3(1.0) * 5.0, clamp(exp(rayDir.y * -8.0), 0.0, 1.0));
	vec3 sunColor = vec3(1.0, 1.0, 0.9) * 1500.0;

	return mix( skyColor, sunColor, pow(max(0.0, dot(rayDir, DIRECTION_TO_SUN)), 500.0) );
}


//-----------------------------------------------------------------------------------------------------------------------------
vec3 CalculateRadiance( out vec3 objectNormal, out vec3 objectColor, out float objectID, out float pixelSharpness )
//-----------------------------------------------------------------------------------------------------------------------------
{
	
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
	vec3 directionToSun = normalize(vec3(-1,1,0));
        
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
			if (diffuseCount == 0 && isReflectionTime == FALSE)
				pixelSharpness = 1.0;

			if (bounceIsSpecular == TRUE || sampleLight == TRUE)
				accumCol += mask * getSkyColor(rayDirection);
				
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


		// if we get here and sampleLight is still TRUE, shadow ray failed to find the light source 
		// the ray hit an occluding object along its way to the light
		if (sampleLight == TRUE)
		{
			objectID += hitObjectID; // produces sharper shadow boundary edges

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
		

		    
                if (hitType == DIFF) // Ideal DIFFUSE reflection
		{	
			diffuseCount++;

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
                        
			rayDirection = randomDirectionInSpecularLobe(nl, DIRECTION_TO_SUN, 0.2);
			weight = max(0.0, dot(nl, rayDirection)) * 0.01;
			mask *= weight;
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
                        
			rayDirection = randomDirectionInSpecularLobe(nl, DIRECTION_TO_SUN, 0.2);
			weight = max(0.0, dot(nl, rayDirection)) * 0.01;
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
	float ior = 1.4;

	spheres[0] = Sphere(3.7, vec3(-11, 3.7, 21), z, vec3(0.5, 0.09, 0.2), ior, COAT);// Pink Sphere front left
	spheres[1] = Sphere(1.8, vec3(-4, 1.8, 22), z, vec3(0.9, 0.6, 0.1), ior, COAT);// Yellow Sphere front left
	spheres[2] = Sphere(4.0, vec3(9.4, 4, 21), z, vec3(0.5, 0.1, 0.08), ior, COAT);// Orange Sphere front right
	spheres[3] = Sphere(10.0, vec3( 0, 10, -2), z, vec3(0.5, 0.1, 0.08), ior, COAT);// Orange Sphere center
	spheres[4] = Sphere(12.0, vec3(-29.5, 12, 4), z, vec3(0.5, 0.09, 0.2), ior, COAT);// Pink Sphere left
	spheres[5] = Sphere(16.0, vec3(28.5, 16, -5), z, vec3(0.5, 0.09, 0.2) * 0.7, ior, COAT);// Pink Sphere right
	spheres[6] = Sphere(6.0, vec3(-30, 6, -24), z, vec3(0.7, 0.4, 0.05), ior, COAT);// Yellow Sphere back left
	spheres[7] = Sphere(10.0, vec3( 26, 10, -35), z, vec3(0.7, 0.7, 0.7), 1.0, SPEC);// Mirror Sphere back right
	
	rectangles[0] = Rectangle( vec3(0,0,0), vec3(0,1,0), 150.0, 150.0, vec3(0.8), 1.0, DIFF);// Ground rectangle
}


#include <pathtracing_main>
