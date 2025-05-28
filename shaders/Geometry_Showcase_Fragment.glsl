precision highp float;
precision highp int;
precision highp sampler2D;

#include <pathtracing_uniforms_and_defines>

uniform mat4 uTorusInvMatrix;

#define N_LIGHTS 3.0
#define N_SPHERES 6
#define N_PLANES 1
#define N_DISKS 1
#define N_TRIANGLES 1
#define N_QUADS 1
#define N_BOXES 2
#define N_ELLIPSOIDS 1
#define N_PARABOLOIDS 1
#define N_OPENCYLINDERS 1
#define N_CAPPEDCYLINDERS 1
#define N_CONES 1
#define N_CAPSULES 1
#define N_TORII 1


//-----------------------------------------------------------------------

vec3 rayOrigin, rayDirection;
// recorded intersection data:
vec3 hitNormal, hitEmission, hitColor;
vec2 hitUV;
float hitObjectID = -INFINITY;
int hitType = -100;

struct Sphere { float radius; vec3 position; vec3 emission; vec3 color; int type; };
struct Ellipsoid { vec3 radii; vec3 position; vec3 emission; vec3 color; int type; };
struct Paraboloid { float rad; float height; vec3 pos; vec3 emission; vec3 color; int type; };
struct OpenCylinder { float radius; float height; vec3 position; vec3 emission; vec3 color; int type; };
struct CappedCylinder { float radius; vec3 cap1pos; vec3 cap2pos; vec3 emission; vec3 color; int type; };
struct Cone { vec3 pos0; float radius0; vec3 pos1; float radius1; vec3 emission; vec3 color; int type; };
struct Capsule { vec3 pos0; float radius0; vec3 pos1; float radius1; vec3 emission; vec3 color; int type; };
struct UnitTorus { float parameterK; vec3 emission; vec3 color; int type; };
struct Box { vec3 minCorner; vec3 maxCorner; vec3 emission; vec3 color; int type; };

Sphere spheres[N_SPHERES];
Ellipsoid ellipsoids[N_ELLIPSOIDS];
Paraboloid paraboloids[N_PARABOLOIDS];
OpenCylinder openCylinders[N_OPENCYLINDERS];
CappedCylinder cappedCylinders[N_CAPPEDCYLINDERS];
Cone cones[N_CONES];
Capsule capsules[N_CAPSULES];
UnitTorus torii[N_TORII];
Box boxes[N_BOXES];


#include <pathtracing_random_functions>

#include <pathtracing_calc_fresnel_reflectance>

#include <pathtracing_sphere_intersect>

#include <pathtracing_unit_bounding_sphere_intersect>

#include <pathtracing_ellipsoid_intersect>

#include <pathtracing_opencylinder_intersect>

#include <pathtracing_cappedcylinder_intersect>

#include <pathtracing_cone_intersect>

#include <pathtracing_capsule_intersect>

#include <pathtracing_paraboloid_intersect>

#include <pathtracing_unit_torus_intersect>

#include <pathtracing_box_intersect>

#include <pathtracing_sample_sphere_light>

//-------------------------------------------------------------------------------------------------------------------
float SceneIntersect( out int finalIsRayExiting )
//-------------------------------------------------------------------------------------------------------------------
{
	vec3 rObjOrigin, rObjDirection;
	vec3 hitPos;
	vec3 n;
	float d, dt;
	float t = INFINITY;
	float q;
	int isRayExiting = FALSE;
	int insideSphere = FALSE;
	int objectCount = 0;
	
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

	d = SphereIntersect( spheres[3].radius, spheres[3].position, rayOrigin, rayDirection );
	if (d < t)
	{
		t = d;
		hitPos = rayOrigin + (rayDirection * t);
		hitNormal = hitPos - spheres[3].position;
		hitEmission = spheres[3].emission;
		q = clamp( mod( dot( floor(hitPos.xz * 0.04), vec2(1.0) ), 2.0 ) , 0.0, 1.0 );
		hitColor = mix(vec3(0.5), spheres[3].color, q);
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
		hitType = spheres[5].type;
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
		finalIsRayExiting = isRayExiting;
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
		finalIsRayExiting = isRayExiting;
		hitObjectID = float(objectCount);
	}
	objectCount++;

	
	d = EllipsoidIntersect( ellipsoids[0].radii, ellipsoids[0].position, rayOrigin, rayDirection );
	if (d < t)
	{
		t = d;
		hitNormal = ((rayOrigin + rayDirection * t) - 
			ellipsoids[0].position) / (ellipsoids[0].radii * ellipsoids[0].radii);
		hitEmission = ellipsoids[0].emission;
		hitColor = ellipsoids[0].color;
		hitType = ellipsoids[0].type;
		hitObjectID = float(objectCount);
	}
	objectCount++;
	
	d = ParaboloidIntersect( paraboloids[0].rad, paraboloids[0].height, paraboloids[0].pos, rayOrigin, rayDirection, n );
	if (d < t)
	{
		t = d;
		hitNormal = n;
		hitEmission = paraboloids[0].emission;
		hitColor = paraboloids[0].color;
		hitType = paraboloids[0].type;
		hitObjectID = float(objectCount);
	}
	objectCount++;
	
	d = OpenCylinderIntersect( openCylinders[0].position, openCylinders[0].position + vec3(0,30,30), openCylinders[0].radius, rayOrigin, rayDirection, n );
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
        
	d = CappedCylinderIntersect( cappedCylinders[0].cap1pos, cappedCylinders[0].cap2pos, cappedCylinders[0].radius, rayOrigin, rayDirection, n);
	if (d < t)
	{
		t = d;
		hitNormal = n;
		hitEmission = cappedCylinders[0].emission;
		hitColor = cappedCylinders[0].color;
		hitType = cappedCylinders[0].type;
		hitObjectID = float(objectCount);
	}
	objectCount++;
        
	d = ConeIntersect( cones[0].pos0, cones[0].radius0, cones[0].pos1, cones[0].radius1, rayOrigin, rayDirection, n );
	if (d < t)
	{
		t = d;
		hitNormal = n;
		hitEmission = cones[0].emission;
		hitColor = cones[0].color;
		hitType = cones[0].type;
		hitObjectID = float(objectCount);
	}
	objectCount++;
        
	d = CapsuleIntersect( capsules[0].pos0, capsules[0].radius0, capsules[0].pos1, capsules[0].radius1, rayOrigin, rayDirection, n );
	if (d < t)
	{
		t = d;
		hitNormal = n;
		hitEmission = capsules[0].emission;
		hitColor = capsules[0].color;
		hitType = capsules[0].type;
		hitObjectID = float(objectCount);
	}
	objectCount++;
        
	// transform ray into Torus's object space
	rObjOrigin = vec3( uTorusInvMatrix * vec4(rayOrigin, 1.0) );
	rObjDirection = vec3( uTorusInvMatrix * vec4(rayDirection, 0.0) );
	// first check that the ray hits the bounding sphere around the torus
	d = UnitBoundingSphereIntersect( rObjOrigin, rObjDirection, insideSphere );
	if (d < INFINITY)
	{	// if outside the sphere, move the ray up close to the Torus, for numerical stability
		d = insideSphere == TRUE ? 0.0 : d;
		rObjOrigin += rObjDirection * d;

		dt = d + UnitTorusIntersect( rObjOrigin, rObjDirection, torii[0].parameterK, n );
		if (dt < t)
		{
			t = dt;
			hitNormal = transpose(mat3(uTorusInvMatrix)) * n;
			hitEmission = torii[0].emission;
			hitColor = torii[0].color;
			hitType = torii[0].type;
			hitObjectID = float(objectCount);
		}
	}
        
	
	return t;
	
} // end float SceneIntersect( out int finalIsRayExiting )


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
	vec3 x, n, nl;
        
	float t;
	float nc, nt, ratioIoR, Re, Tr;
	float weight;
	float thickness = 0.1;
	float previousObjectID;
	float newRandom = rand();

	int reflectionBounces = -1;
	int diffuseCount = 0;
	int previousIntersecType = -100;
	hitType = -100;
	
	int bounceIsSpecular = TRUE;
	int sampleLight = FALSE;
	int isRayExiting;
	int willNeedReflectionRay = FALSE;
	int isReflectionTime = FALSE;
	int reflectionNeedsToBeSharp = FALSE;
	int willNeedDiffuseBounceRay = FALSE;
	int isDiffuseBounceTime = FALSE;


	
	for (int bounces = 0; bounces < 10; bounces++)
	{
		if (isReflectionTime == TRUE)
			reflectionBounces++;

		previousIntersecType = hitType;
		previousObjectID = hitObjectID;

		t = SceneIntersect(isRayExiting);
		
		// shouldn't happen because we are inside a huge checkered sphere, but just in case
		if (t == INFINITY)
		{
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
			objectColor += hitColor;
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
 
			if (newRandom < 0.3333)
				rayDirection = sampleSphereLight(x, nl, spheres[0], weight);
			else if (newRandom < 0.6666)
				rayDirection = sampleSphereLight(x, nl, spheres[1], weight);
			else
				rayDirection = sampleSphereLight(x, nl, spheres[2], weight);
			
			mask *= weight * N_LIGHTS;
			sampleLight = TRUE;
			continue;
                        
		} // end if (hitType == DIFF)
		
		if (hitType == SPEC)  // Ideal SPECULAR reflection
		{
			mask *= hitColor;

			rayDirection = reflect(rayDirection, nl);
			rayOrigin = x + nl * uEPS_intersect;

			// if (diffuseCount == 1)
			// 	bounceIsSpecular = TRUE; // turn on reflective mirror caustics

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

			if (diffuseCount == 0 && hitObjectID != previousObjectID && n == nl)
			{
				reflectionMask = mask * Re;
				reflectionRayDirection = reflect(rayDirection, nl); // reflect ray from surface
				reflectionRayOrigin = x + nl * uEPS_intersect;
				willNeedReflectionRay = TRUE;
				if (bounces == 0 && hitColor == vec3(0.2,0.9,0.7) && isRayExiting == FALSE)
					reflectionNeedsToBeSharp = TRUE;
			}

			// transmit ray through surface

			// is ray leaving a solid object from the inside? 
			// If so, attenuate ray color with object color by how far ray has travelled through the medium
			if (isRayExiting == TRUE)
			{
				isRayExiting = FALSE;
				mask *= exp(log(hitColor) * thickness * t);
			}
			else 
				mask *= hitColor;

			mask *= Tr;
			
			rayDirection = refract(rayDirection, nl, ratioIoR);
			rayOrigin = x - nl * uEPS_intersect;

			if (diffuseCount == 1 && isDiffuseBounceTime == TRUE)
				bounceIsSpecular = TRUE; // turn on refracting caustics

			continue;
			
		} // end if (hitType == REFR)
		
		if (hitType == COAT)  // Diffuse object underneath with ClearCoat on top
		{
			nc = 1.0; // IOR of Air
			nt = 1.4; // IOR of Clear Coat
			Re = calcFresnelReflectance(rayDirection, nl, nc, nt, ratioIoR);
			Tr = 1.0 - Re;
			
			if (diffuseCount == 0 && hitObjectID != previousObjectID)
			{
				reflectionMask = mask * Re;
				reflectionRayDirection = reflect(rayDirection, nl); // reflect ray from surface
				reflectionRayOrigin = x + nl * uEPS_intersect;
				willNeedReflectionRay = TRUE;
				if (bounces == 0 && hitColor == vec3(0.04,0.04,0.04))
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
			
			if (hitColor.r == 1.01 && rand() < 0.9) // this makes white capsule more 'white'
			 	rayDirection = sampleSphereLight(x, nl, spheres[0], weight);
			else if (newRandom < 0.3333)
				rayDirection = sampleSphereLight(x, nl, spheres[0], weight);
			else if (newRandom < 0.6666)
				rayDirection = sampleSphereLight(x, nl, spheres[1], weight);
			else
				rayDirection = sampleSphereLight(x, nl, spheres[2], weight);
			
			mask *= weight * N_LIGHTS;
			sampleLight = TRUE;
			continue;
			
		} //end if (hitType == COAT)

		
	} // end for (int bounces = 0; bounces < 10; bounces++)
	
	
	return max(vec3(0), accumCol);

} // end vec3 CalculateRadiance( out vec3 objectNormal, out vec3 objectColor, out float objectID, out float pixelSharpness )


//-----------------------------------------------------------------------
void SetupScene(void)
//-----------------------------------------------------------------------
{
	vec3 z  = vec3(0);          
	vec3 L1 = vec3(1.0, 1.0, 1.0) * 5.0;// White light
	vec3 L2 = vec3(1.0, 0.8, 0.2) * 4.0;// Yellow light
	vec3 L3 = vec3(0.1, 0.7, 1.0) * 2.0;// Blue light
		
        spheres[0] = Sphere(150.0, vec3(-400, 900, 200), L1, z, LIGHT);//spherical white Light1 
	spheres[1] = Sphere(100.0, vec3( 300, 400,-300), L2, z, LIGHT);//spherical yellow Light2
	spheres[2] = Sphere( 50.0, vec3( 500, 250,-100), L3, z, LIGHT);//spherical blue Light3
	
	spheres[3] = Sphere(1000.0, vec3(  0.0, 1000.0,  0.0), z, vec3(1.0, 1.0, 1.0), DIFF);//Checkered Floor
        spheres[4] = Sphere(  16.5, vec3(-26.0,   17.2,  5.0), z, vec3(0.95, 0.95, 0.95), SPEC);//Mirror sphere
        spheres[5] = Sphere(  15.0, vec3( 32.0,   16.1, 30.0), z, vec3(1.0, 1.0, 1.0), REFR);//Glass sphere
        
	ellipsoids[0] = Ellipsoid(  vec3(30,40,16), vec3(90,5,-30), z, vec3(1.0, 0.765557, 0.336057), SPEC);//metallic gold ellipsoid
	
	paraboloids[0] = Paraboloid(  16.5, 50.0, vec3(20,1.5,-50), z, vec3(1.0, 0.2, 0.7), REFR);//paraboloid
	
	openCylinders[0] = OpenCylinder( 15.0, 30.0, vec3(-70,7,-80), z, vec3(0.9,0.01,0.01), REFR);//red glass open Cylinder

	cappedCylinders[0] = CappedCylinder( 14.0, vec3(-60,0,20), vec3(-60,14,20), z, vec3(0.04,0.04,0.04), COAT);//dark gray capped Cylinder
	
	cones[0] = Cone( vec3(1,20,-12), 15.0, vec3(1,0,-12), 0.0, z, vec3(0.01,0.1,0.5), REFR);//blue Cone
	
	capsules[0] = Capsule( vec3(80,13,15), 10.0, vec3(110,15.8,15), 10.0, z, vec3(1.01,1.0,1.0), COAT);//white Capsule
	
	torii[0] = UnitTorus( 0.75, z, vec3(0.955008, 0.637427, 0.538163), SPEC);//copper Torus
	
	boxes[0] = Box( vec3(50.0,21.0,-60.0), vec3(100.0,28.0,-130.0), z, vec3(0.2,0.9,0.7), REFR);//Glass Box
	boxes[1] = Box( vec3(56.0,23.0,-66.0), vec3(94.0,26.0,-124.0), z, vec3(0.0,0.0,0.0), DIFF);//Diffuse Box
}


#include <pathtracing_main>
