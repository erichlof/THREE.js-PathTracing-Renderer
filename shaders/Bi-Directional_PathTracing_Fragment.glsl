precision highp float;
precision highp int;
precision highp sampler2D;

#include <pathtracing_uniforms_and_defines>

#define N_SPHERES 4
#define N_ELLIPSOIDS 1
#define N_OPENCYLINDERS 6
#define N_CONES 1
#define N_DISKS 1
#define N_BOXES 2


vec3 rayOrigin, rayDirection;
// recorded intersection data:
vec3 hitNormal, hitEmission, hitColor;
vec2 hitUV;
float hitRoughness;
float hitObjectID = -INFINITY;
int hitType = -100;

struct Sphere { float radius; vec3 position; vec3 emission; vec3 color; float roughness; int type; };
struct Ellipsoid { vec3 radii; vec3 position; vec3 emission; vec3 color; float roughness; int type; };
struct OpenCylinder { float radius; vec3 pos1; vec3 pos2; vec3 emission; vec3 color; float roughness; int type; };
struct Cone { vec3 pos0; float radius0; vec3 pos1; float radius1; vec3 emission; vec3 color; float roughness; int type; };
struct Disk { float radius; vec3 pos; vec3 normal; vec3 emission; vec3 color; float roughness; int type; };
struct Box { vec3 minCorner; vec3 maxCorner; vec3 emission; vec3 color; float roughness; int type; };

Sphere spheres[N_SPHERES];
Ellipsoid ellipsoids[N_ELLIPSOIDS];
OpenCylinder openCylinders[N_OPENCYLINDERS];
Cone cones[N_CONES];
Disk disks[N_DISKS];
Box boxes[N_BOXES];

#include <pathtracing_random_functions>

#include <pathtracing_calc_fresnel_reflectance>

#include <pathtracing_sphere_intersect>

#include <pathtracing_ellipsoid_intersect>

#include <pathtracing_opencylinder_intersect>

#include <pathtracing_cone_intersect>

#include <pathtracing_disk_intersect>

#include <pathtracing_box_intersect>

#include <pathtracing_box_interior_intersect>

//#include <pathtracing_sample_sphere_light>



//--------------------------------------------------------------------------------------
float SceneIntersect()
//--------------------------------------------------------------------------------------
{
	vec3 normal, n;
        float d;
	float t = INFINITY;
	int isRayExiting = FALSE;
	int objectCount = 0;
	
	hitObjectID = -INFINITY;

			
	// ROOM	
	d = BoxInteriorIntersect( boxes[1].minCorner, boxes[1].maxCorner, rayOrigin, rayDirection, n );
	if (d < t && n != vec3(0,0,-1))
	{
		t = d;
		hitNormal = n;
		hitEmission = boxes[1].emission;
		hitColor = boxes[1].color;
		hitRoughness = boxes[1].roughness;
		hitType = boxes[1].type;
	
		if (n == vec3(0,-1,0)) // ceiling
		{
			hitColor = vec3(1);
		}
		
		hitObjectID = float(objectCount);
	}
	objectCount++;

	// TABLETOP
	d = BoxIntersect( boxes[0].minCorner, boxes[0].maxCorner, rayOrigin, rayDirection, normal, isRayExiting );
	if (d < t)
	{
		t = d;
		hitNormal = normal;
		hitEmission = boxes[0].emission;
		hitColor = boxes[0].color;
		hitRoughness = boxes[0].roughness;
		hitType = boxes[0].type;
		hitObjectID = float(objectCount);
	}
	objectCount++;
	
	// LAMP BASE AND FLOOR LAMP BULB
	d = SphereIntersect( spheres[0].radius, spheres[0].position, rayOrigin, rayDirection );
	if (d < t)
	{
		t = d;
		hitNormal = (rayOrigin + rayDirection * t) - spheres[0].position;
		hitEmission = spheres[0].emission;
		hitColor = spheres[0].color;
		hitRoughness = spheres[0].roughness;
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
		hitRoughness = spheres[1].roughness;
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
		hitRoughness = spheres[2].roughness;
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
		hitRoughness = spheres[3].roughness;
		hitType = spheres[3].type;
		hitObjectID = float(objectCount);
	}
	objectCount++;
	
	// LIGHT DISK OF SPOTLIGHT AND SPOTLIGHT CASE DISK BACKING
	
	d = DiskIntersect( disks[0].radius, disks[0].pos, disks[0].normal, rayOrigin, rayDirection );
	if (d < t)
	{
		t = d;
		hitNormal = disks[0].normal;
		hitEmission = disks[0].emission;
		hitColor = disks[0].color;
		hitRoughness = disks[0].roughness;
		hitType = disks[0].type;
		hitObjectID = float(objectCount);
	}
	objectCount++;
	
	
	// LAMP SHADE
	d = ConeIntersect( cones[0].pos0, cones[0].radius0, cones[0].pos1, cones[0].radius1, rayOrigin, rayDirection, normal );
	if (d < t)
	{
		t = d;
		hitNormal = normal;
		hitEmission = cones[0].emission;
		hitColor = cones[0].color;
		hitRoughness = cones[0].roughness;
		hitType = cones[0].type;
		hitObjectID = float(objectCount);
	}
	objectCount++;
	
	
	// GLASS EGG
	vec3 hitPos;
	
	d = SphereIntersect( spheres[3].radius, spheres[3].position, rayOrigin, rayDirection );
	hitPos = rayOrigin + rayDirection * d;
	if (hitPos.y >= spheres[3].position.y) 
		d = INFINITY;
	if (d < t)
	{
		t = d;
		hitNormal = (rayOrigin + rayDirection * t) - spheres[3].position;
		hitEmission = spheres[3].emission;
		hitColor = spheres[3].color;
		hitRoughness = spheres[3].roughness;
		hitType = spheres[3].type;
		hitObjectID = float(objectCount); // same as ellipsoid - sphere and ellipsoid make up 1 object
	}

	d = EllipsoidIntersect( ellipsoids[0].radii, ellipsoids[0].position, rayOrigin, rayDirection );
	hitPos = rayOrigin + rayDirection * d;
	if (hitPos.y < ellipsoids[0].position.y) 
		d = INFINITY;
	
	if (d < t)
	{
		t = d;
		hitNormal = ((rayOrigin + rayDirection * t) - ellipsoids[0].position) / (ellipsoids[0].radii * ellipsoids[0].radii);
		hitEmission = ellipsoids[0].emission;
		hitColor = ellipsoids[0].color;
		hitRoughness = ellipsoids[0].roughness;
		hitType = ellipsoids[0].type;
		hitObjectID = float(objectCount);  // same as sphere - sphere and ellipsoid make up 1 object
	}
	objectCount++;

	// TABLE LEGS, LAMP POST, and SPOTLIGHT CASING
	d = OpenCylinderIntersect( openCylinders[0].pos1, openCylinders[0].pos2, openCylinders[0].radius, rayOrigin, rayDirection, normal );
	if (d < t)
	{
		t = d;
		hitNormal = normal;
		hitEmission = openCylinders[0].emission;
		hitColor = openCylinders[0].color;
		hitRoughness = openCylinders[0].roughness;
		hitType = openCylinders[0].type;
		hitObjectID = float(objectCount);
	}
	objectCount++;

	d = OpenCylinderIntersect( openCylinders[1].pos1, openCylinders[1].pos2, openCylinders[1].radius, rayOrigin, rayDirection, normal );
	if (d < t)
	{
		t = d;
		hitNormal = normal;
		hitEmission = openCylinders[1].emission;
		hitColor = openCylinders[1].color;
		hitRoughness = openCylinders[1].roughness;
		hitType = openCylinders[1].type;
		hitObjectID = float(objectCount);
	}
	objectCount++;

	d = OpenCylinderIntersect( openCylinders[2].pos1, openCylinders[2].pos2, openCylinders[2].radius, rayOrigin, rayDirection, normal );
	if (d < t)
	{
		t = d;
		hitNormal = normal;
		hitEmission = openCylinders[2].emission;
		hitColor = openCylinders[2].color;
		hitRoughness = openCylinders[2].roughness;
		hitType = openCylinders[2].type;
		hitObjectID = float(objectCount);
	}
	objectCount++;

	d = OpenCylinderIntersect( openCylinders[3].pos1, openCylinders[3].pos2, openCylinders[3].radius, rayOrigin, rayDirection, normal );
	if (d < t)
	{
		t = d;
		hitNormal = normal;
		hitEmission = openCylinders[3].emission;
		hitColor = openCylinders[3].color;
		hitRoughness = openCylinders[3].roughness;
		hitType = openCylinders[3].type;
		hitObjectID = float(objectCount);
	}
	objectCount++;

	d = OpenCylinderIntersect( openCylinders[4].pos1, openCylinders[4].pos2, openCylinders[4].radius, rayOrigin, rayDirection, normal );
	if (d < t)
	{
		t = d;
		hitNormal = normal;
		hitEmission = openCylinders[4].emission;
		hitColor = openCylinders[4].color;
		hitRoughness = openCylinders[4].roughness;
		hitType = openCylinders[4].type;
		hitObjectID = float(objectCount);
	}
	objectCount++;

	d = OpenCylinderIntersect( openCylinders[5].pos1, openCylinders[5].pos2, openCylinders[5].radius, rayOrigin, rayDirection, normal );
	if (d < t)
	{
		t = d;
		hitNormal = normal;
		hitEmission = openCylinders[5].emission;
		hitColor = openCylinders[5].color;
		hitRoughness = openCylinders[5].roughness;
		hitType = openCylinders[5].type;
		hitObjectID = float(objectCount);
	}
	
	
	
	return t;
} // end float SceneIntersect()



//--------------------------------------------------------------------------------------------------------------------------------------------------------------------
vec3 CalculateRadiance( out vec3 objectNormal, out vec3 objectColor, out float objectID, out float pixelSharpness )
//--------------------------------------------------------------------------------------------------------------------------------------------------------------------
{
	float randChoose = rand();

	Sphere lightChoice;
	if (randChoose < 0.5) lightChoice = spheres[0]; 
	else lightChoice = spheres[1];
	
	vec3 originalRayOrigin = rayOrigin;
	vec3 originalRayDirection = rayDirection;
	vec3 accumCol = vec3(0);
        vec3 mask = vec3(1);
	vec3 reflectionMask = vec3(1);
	vec3 reflectionRayOrigin = vec3(0);
	vec3 reflectionRayDirection = vec3(0);
	vec3 diffuseBounceMask = vec3(1);
	vec3 diffuseBounceRayOrigin = vec3(0);
	vec3 diffuseBounceRayDirection = vec3(0);
	vec3 spotlightPos1 = vec3(380.0, 290.0, -470.0);
	vec3 spotlightPos2 = vec3(430.0, 315.0, -485.0);
	vec3 spotlightDir = normalize(spotlightPos1 - spotlightPos2);
	
	vec3 lightNormal = vec3(0,1,0);
	if (randChoose >= 0.5)
		lightNormal = spotlightDir;
	
	vec3 lightDir = randomCosWeightedDirectionInHemisphere(lightNormal);
	vec3 lightHitPos = lightChoice.position + lightDir;
	vec3 lightHitEmission = lightChoice.emission;
	vec3 x, n, nl;
        
	float lightHitDistance = INFINITY;
	float firstLightHitDistance = INFINITY;
	float t = INFINITY;
	float nc, nt, ratioIoR, Re, Tr;
	float weight;
	float previousObjectID;
	
	int reflectionBounces = -1;
	int diffuseCount = 0;
	int previousIntersecType;
	hitType = -100;

	int bounceIsSpecular = TRUE;
	int sampleLight = FALSE;
	int firstTypeWasDIFF = FALSE;
	int ableToJoinPaths = FALSE;
	int willNeedReflectionRay = FALSE;
	int isReflectionTime = FALSE;
	int reflectionNeedsToBeSharp = FALSE;
	int willNeedDiffuseBounceRay = FALSE;
	int isDiffuseBounceTime = FALSE;


	// light trace
	rayOrigin = lightChoice.position;
	rayDirection = lightDir;
	rayOrigin += rayDirection * lightChoice.radius;
	t = SceneIntersect();
	if (hitType == DIFF)
	{
		lightHitPos = rayOrigin + rayDirection * t;
		lightHitEmission *= hitColor;
	}

	
	// regular path tracing from camera
	rayOrigin = originalRayOrigin;
	rayDirection = originalRayDirection;

	hitType = -100;
	hitObjectID = -100.0;


	for (int bounces = 0; bounces < 10; bounces++)
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
			objectNormal += nl; // this is not changed from 'nl' to 'n' because of seams in the glass egg on wood table
			objectColor += hitColor;
		}
		// if (reflectionNeedsToBeSharp == TRUE && reflectionBounces == 0)
		// {
		// 	objectNormal += nl;
		// 	objectColor += hitColor;
		// 	objectID += hitObjectID;
		// }
		

		
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

			if (firstTypeWasDIFF == TRUE && bounceIsSpecular == TRUE) // caustics from glass egg
				accumCol += mask * hitEmission * 100.0;	 
			else if (bounceIsSpecular == TRUE || sampleLight == TRUE)
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


		if (hitType == DIFF && sampleLight == TRUE)
		{
			ableToJoinPaths = abs(lightHitDistance - t) < 0.5 ? TRUE : FALSE;
			
			if (ableToJoinPaths == TRUE)
			{
				weight = max(0.0, dot(n, -rayDirection));
				accumCol += mask * lightHitEmission * weight;
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
		}

		// if we get here and sampleLight is still true, shadow ray failed to find the light source 
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

			if (bounces == 0 || (bounces == 1 && previousIntersecType == SPEC))
			{
				firstTypeWasDIFF = TRUE;	
			}
				
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
			mask *= hitColor;

			rayDirection = reflect(rayDirection, nl);
			rayOrigin = x + nl * uEPS_intersect;

			//bounceIsSpecular = TRUE; // turn on mirror caustics
			continue;
		}
		
		if (hitType == REFR)  // Ideal dielectric REFRACTION
		{	
			nc = 1.0; // IOR of Air
			nt = 1.5; // IOR of Glass
			Re = calcFresnelReflectance(rayDirection, n, nc, nt, ratioIoR);
			Tr = 1.0 - Re;
			
			if (diffuseCount == 0 && hitObjectID != previousObjectID && n == nl)
			{
				reflectionMask = mask * Re;
				reflectionRayDirection = reflect(rayDirection, nl); // reflect ray from surface
				reflectionRayOrigin = x + nl * uEPS_intersect;
				willNeedReflectionRay = TRUE;
				if (bounces == 0)
					reflectionNeedsToBeSharp = TRUE;
			}

			if (Re == 1.0)
			{
				rayDirection = reflect(rayDirection, nl);
				rayOrigin = x + nl * uEPS_intersect;
				continue;
			}

			// transmit ray through surface

			mask *= Tr;
			mask *= hitColor;
			
			rayDirection = refract(rayDirection, nl, ratioIoR);
			rayOrigin = x - nl * uEPS_intersect;

			if (isDiffuseBounceTime == TRUE && diffuseCount == 1 && t < 50.0)
				bounceIsSpecular = TRUE; // turn on refracting caustics

			continue;
			
		} // end if (hitType == REFR)
		
		
	} // end for (int bounces = 0; bounces < 10; bounces++)
	

	return max(vec3(0), accumCol);

} // end vec3 CalculateRadiance( vec3 originalRayOrigin, vec3 originalRayDirection, out vec3 objectNormal, out vec3 objectColor, out float objectID, out float pixelSharpness )



//-----------------------------------------------------------------------
void SetupScene(void)
//-----------------------------------------------------------------------
{
	vec3 z  = vec3(0);// No color value, Black        
	vec3 L1 = vec3(1.0) * 15.0;//30.0;// Bright White light
	vec3 L2 = vec3(0.936507, 0.642866, 0.310431) * 10.0;//20.0;// Bright Yellowish light
	vec3 wallColor = vec3(1.0, 0.98, 1.0) * 0.5;
	vec3 tableColor = vec3(1.0, 0.55, 0.2) * 0.6;
	vec3 lampColor = vec3(1.0, 1.0, 0.8) * 0.7;
	vec3 spotlightPos1 = vec3(380.0, 290.0, -470.0);
	vec3 spotlightPos2 = vec3(430.0, 315.0, -485.0);
	vec3 spotlightDir = normalize(spotlightPos1 - spotlightPos2);
	float spotlightRadius = 14.0; // 12.0
	
	boxes[0] = Box( vec3(180.0, 145.0, -540.0), vec3(510.0, 155.0, -310.0), z, tableColor, 0.0, DIFF);// Table Top
	boxes[1] = Box( vec3(0, 0,-559.2), vec3(549.6, 548.8, 0), z, wallColor, 0.0, DIFF);// the Cornell Box interior 

	openCylinders[0] = OpenCylinder( 8.5, vec3(205.0, 0.0, -515.0), vec3(205.0, 145.0, -515.0), z, tableColor, 0.0, DIFF);// Table Leg
	openCylinders[1] = OpenCylinder( 8.5, vec3(485.0, 0.0, -515.0), vec3(485.0, 145.0, -515.0), z, tableColor, 0.0, DIFF);// Table Leg
	openCylinders[2] = OpenCylinder( 8.5, vec3(205.0, 0.0, -335.0), vec3(205.0, 145.0, -335.0), z, tableColor, 0.0, DIFF);// Table Leg
	openCylinders[3] = OpenCylinder( 8.5, vec3(485.0, 0.0, -335.0), vec3(485.0, 145.0, -335.0), z, tableColor, 0.0, DIFF);// Table Leg
	
	openCylinders[4] = OpenCylinder( 6.0, vec3(80.0, 0.0, -430.0), vec3(80.0, 366.0, -430.0), z, lampColor, 0.0, SPEC);// Floor Lamp Post
	openCylinders[5] = OpenCylinder( spotlightRadius, spotlightPos1, spotlightPos2, z, vec3(1.0,1.0,1.0), 0.0, SPEC);// Spotlight Casing
	
	disks[0] = Disk( spotlightRadius, spotlightPos2, spotlightDir, z, vec3(1), 0.0, SPEC);// disk backing of spotlight
	
	cones[0] = Cone( vec3(80.0, 405.0, -430.0), 70.0, vec3(80.0, 365.0, -430.0), 6.0, z, lampColor, 0.2, SPEC);// Floor Lamp Shade
	
	spheres[0] = Sphere( spotlightRadius * 0.5, spotlightPos2 + spotlightDir * 20.0, L2, z, 0.0, LIGHT);// Spot Light Bulb
	spheres[1] = Sphere( 6.0, vec3(80.0, 378.0, -430.0), L1, z, 0.0, LIGHT);// Floor Lamp Bulb
	spheres[2] = Sphere( 80.0, vec3(80.0, -60.0, -430.0), z, lampColor, 0.4, SPEC);// Floor Lamp Base
	spheres[3] = Sphere( 33.0, vec3(290.0, 188.0, -435.0), z, vec3(1), 0.0, REFR);// Glass Egg Bottom
	ellipsoids[0] = Ellipsoid( vec3(33, 62, 33), vec3(290.0, 188.0, -435.0), z, vec3(1), 0.0, REFR);// Glass Egg Top
}


#include <pathtracing_main>
