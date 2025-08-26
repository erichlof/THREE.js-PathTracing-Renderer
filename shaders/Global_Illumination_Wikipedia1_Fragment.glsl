precision highp float;
precision highp int;
precision highp sampler2D;

//uniform int uSceneSelection;

#include <pathtracing_uniforms_and_defines>

#define N_SPHERES 3
#define N_OPENCYLINDERS 1
#define N_QUADS 1
#define N_BOXES 4

//-----------------------------------------------------------------------

vec3 rayOrigin, rayDirection;
// recorded intersection data:
vec3 hitNormal, hitEmission, hitColor;
vec2 hitUV;
float hitObjectID;
int hitType = -100;

struct Sphere { float radius; vec3 position; vec3 emission; vec3 color; int type; };
struct OpenCylinder { float radius; float height; vec3 position; vec3 emission; vec3 color; int type; };
struct Quad { vec3 normal; vec3 v0; vec3 v1; vec3 v2; vec3 v3; vec3 emission; vec3 color; int type; };
struct Box { vec3 minCorner; vec3 maxCorner; vec3 emission; vec3 color; int type; };

Sphere spheres[N_SPHERES];
OpenCylinder openCylinders[N_OPENCYLINDERS];
Quad quads[N_QUADS];
Box boxes[N_BOXES];


#include <pathtracing_random_functions>

#include <pathtracing_calc_fresnel_reflectance>

#include <pathtracing_sphere_intersect>

#include <pathtracing_opencylinder_intersect>

#include <pathtracing_quad_intersect>

#include <pathtracing_box_intersect>

#include <pathtracing_box_interior_intersect>

#include <pathtracing_sample_quad_light>



//---------------------------------------------------------------------------------------
float SceneIntersect( )
//---------------------------------------------------------------------------------------
{
	vec3 n, hitPos;
	float d = INFINITY;
	float t = INFINITY;
	float q;
	int objectCount = 0;
	int isRayExiting = FALSE;
	
	hitObjectID = -INFINITY;

	d = SphereIntersect( spheres[0].radius, spheres[0].position, rayOrigin, rayDirection );
	if (d < t)
	{
		t = d;
		hitNormal = (rayOrigin + rayDirection * t) - spheres[0].position;
		hitEmission = spheres[0].emission;
		hitColor = spheres[0].color;
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
		hitType = spheres[2].type;
		hitObjectID = float(objectCount);
	}
	objectCount++;

	d = OpenCylinderIntersect( openCylinders[0].position, openCylinders[0].position + vec3(0,25,0), openCylinders[0].radius, rayOrigin, rayDirection, n );
	if (d < t)
	{
		t = d;
		hitNormal = n;
		hitEmission = openCylinders[0].emission;
		hitColor = openCylinders[0].color;
		hitType = openCylinders[0].type;
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

	d = BoxIntersect( boxes[0].minCorner, boxes[0].maxCorner, rayOrigin, rayDirection, n, isRayExiting );
	if (d < t)
	{
		t = d;
		hitNormal = n;
		hitEmission = boxes[0].emission;
		hitColor = boxes[0].color;
		hitType = boxes[0].type;
		//finalIsRayExiting = isRayExiting;
		hitObjectID = float(objectCount);
	}
	objectCount++;

	d = BoxIntersect( boxes[1].minCorner, boxes[1].maxCorner, rayOrigin, rayDirection, n, isRayExiting );
	if (d < t)
	{
		t = d;
		hitNormal = n;
		hitEmission = boxes[1].emission;
		hitColor = boxes[1].color;
		hitType = boxes[1].type;
		//finalIsRayExiting = isRayExiting;
		hitObjectID = float(objectCount);
	}
	objectCount++;

	d = BoxIntersect( boxes[2].minCorner, boxes[2].maxCorner, rayOrigin, rayDirection, n, isRayExiting );
	if (d < t)
	{
		t = d;
		hitNormal = n;
		hitEmission = boxes[2].emission;
		hitColor = boxes[2].color;
		hitType = boxes[2].type;
		//finalIsRayExiting = isRayExiting;
		hitObjectID = float(objectCount);
	}
	objectCount++;
	
	d = BoxInteriorIntersect( boxes[3].minCorner, boxes[3].maxCorner, rayOrigin, rayDirection, n );
	if (d < t)
	{
		t = d;
		hitNormal = n;
		hitEmission = boxes[3].emission;
		hitColor = vec3(1);
		hitType = DIFF;

		if (n == vec3(1,0,0)) // left wall
		{
			hitColor = vec3(0.8, 0.02, 0.01);
		}
		else if (n == vec3(-1,0,0)) // right wall
		{
			hitColor = vec3(0.01, 0.8, 0.05);
		}
		else if (n == vec3(0,1,0)) // right wall
		{
			hitPos = rayOrigin + rayDirection * t;
			q = clamp( mod( dot( floor(hitPos.xz * 0.1), vec2(1.0) ), 2.0 ) , 0.0, 1.0 );
			hitColor = mix(vec3(1), vec3(0.01,0.0,0.18), q);
			hitType = COAT;
		}
		
		hitObjectID = float(objectCount);
	}
	objectCount++;



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
        
	float t = INFINITY;
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
			//objectID += hitObjectID;
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
			{
				if (isDiffuseBounceTime == TRUE && previousIntersecType == REFR)
					accumCol += mask * hitEmission * 3.0;
				else
					accumCol += mask * hitEmission;
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
                        
			rayDirection = sampleQuadLight(x, nl, quads[0], weight);
			mask *= weight;
			sampleLight = TRUE;
			continue;
                        
		} // end if (hitType == DIFF)
		
		if (hitType == SPEC)  // Ideal SPECULAR reflection
		{
			mask *= hitColor;

			rayDirection = reflect(rayDirection, nl);
			rayOrigin = x + nl * uEPS_intersect;

			// if (diffuseCount == 1 && isDiffuseBounceTime == TRUE)// && previousIntersecType != COAT)
			// 	bounceIsSpecular = TRUE; // turn on reflective caustics

			continue;
		}
		
		if (hitType == REFR)  // Ideal dielectric REFRACTION
		{
			nc = 1.0; // IOR of Air
			nt = 1.5; // IOR of common Glass
			Re = calcFresnelReflectance(rayDirection, n, nc, nt, ratioIoR);
			Tr = 1.0 - Re;
			
			if (Re == 1.0)
			{
				rayDirection = reflect(rayDirection, nl);
				rayOrigin = x + nl * uEPS_intersect;
				continue;
			}
			
			if (bounceIsSpecular == TRUE && isDiffuseBounceTime == FALSE && hitObjectID != previousObjectID && n == nl)
			{
				reflectionMask = mask * Re;
				reflectionRayDirection = reflect(rayDirection, nl); // reflect ray from surface
				reflectionRayOrigin = x + nl * uEPS_intersect;
				willNeedReflectionRay = TRUE;
				if (bounces == 0)
					reflectionNeedsToBeSharp = TRUE;
			}

			// transmit ray through surface
			mask *= Tr;
			mask *= hitColor;
			
			rayDirection = refract(rayDirection, nl, ratioIoR);
			rayOrigin = x - nl * uEPS_intersect;

			if (diffuseCount == 1 && isDiffuseBounceTime == TRUE)// && previousIntersecType != COAT)
				bounceIsSpecular = TRUE; // turn on refracting caustics

			continue;
			
		} // end if (hitType == REFR)
		
		if (hitType == COAT)  // Diffuse object underneath with ClearCoat on top
		{
			nc = 1.0; // IOR of Air
			nt = 1.5; // IOR of thick Clear Coat
			Re = calcFresnelReflectance(rayDirection, nl, nc, nt, ratioIoR);
			Tr = 1.0 - Re;
			
			if (bounceIsSpecular == TRUE && isDiffuseBounceTime == FALSE && hitObjectID != previousObjectID)
			{
				reflectionMask = mask * Re;
				reflectionRayDirection = reflect(rayDirection, nl); // reflect ray from surface
				reflectionRayOrigin = x + nl * uEPS_intersect;
				willNeedReflectionRay = TRUE;
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
	vec3 L1 = vec3(1.0, 1.0, 1.0) * 8.0;// Bright light

	spheres[0] = Sphere(6.0, vec3(73,-44,30), z, vec3(1.0, 1.0, 1.0), DIFF);//White Diffuse sphere
        spheres[1] = Sphere(16.0, vec3(30,-34,-12), z, vec3(0.4, 0.4, 0.4), SPEC);//Mirror sphere
        spheres[2] = Sphere(17.0, vec3(-20,-8,7), z, vec3(1.0, 1.0, 1.0), REFR);//Glass sphere

	openCylinders[0] = OpenCylinder( 1.8, 0.0, vec3(-20,-50,7), z, vec3(1.0, 0.765557, 0.336057), SPEC);//metallic gold thin Cylinder under glass sphere

	quads[0] = Quad( vec3(0,-1,0), vec3(-12,47,-12), vec3(12,47,-12), vec3(12,47,12), vec3(-12,47,12), L1, z, LIGHT);// Area Light Rectangle under the ceiling

	boxes[0] = Box( vec3(-50,-50,-120), vec3(24,50,-50), z, vec3(1), DIFF);// large box in back left (room walls)
	boxes[1] = Box( vec3(0,8,-120), vec3(90,23,-115), z, vec3(1), DIFF);// short, wide box in back right (on rear room wall)
	boxes[2] = Box( vec3(-12,47.1,-12), vec3(12,50,12), z, vec3(1), DIFF);// small box on ceiling (above quad light)
	boxes[3] = Box( vec3(-50,-50,-120), vec3(90,50,50), z, vec3(1), DIFF);// the Cornell Box interior
}


#include <pathtracing_main>
