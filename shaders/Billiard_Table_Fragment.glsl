precision highp float;
precision highp int;
precision highp sampler2D;

uniform mat4 uShortBoxInvMatrix;
uniform mat3 uShortBoxNormalMatrix;
uniform mat4 uTallBoxInvMatrix;
uniform mat3 uTallBoxNormalMatrix;

#include <pathtracing_uniforms_and_defines>

uniform sampler2D tClothTexture;
uniform sampler2D tDarkWoodTexture;
uniform sampler2D tLightWoodTexture;

#define N_LIGHTS 2.0
#define N_SPHERES 3
#define N_ELLIPSOIDS 2
#define N_QUADS 6
#define N_BOXES 10
#define N_CONES 5

//-----------------------------------------------------------------------

vec3 rayOrigin, rayDirection;
// recorded intersection data:
vec3 hitNormal, hitEmission, hitColor;
vec2 hitUV;
float hitRoughness;
float hitObjectID = -INFINITY;
int hitType = -100;

struct Sphere { float radius; vec3 position; vec3 emission; vec3 color; float roughness; int type; };
struct Ellipsoid { vec3 radii; vec3 position; vec3 emission; vec3 color; float roughness; int type; };
struct Quad { vec3 normal; vec3 v0; vec3 v1; vec3 v2; vec3 v3; vec3 emission; vec3 color; float roughness; int type; };
struct Box { vec3 minCorner; vec3 maxCorner; vec3 emission; vec3 color; float roughness; int type; };
struct Cone { vec3 pos0; float radius0; vec3 pos1; float radius1; vec3 emission; vec3 color; float roughness; int type; };

Sphere spheres[N_SPHERES];
Ellipsoid ellipsoids[N_ELLIPSOIDS];
Quad quads[N_QUADS];
Box boxes[N_BOXES];
Cone cones[N_CONES];

#include <pathtracing_random_functions>

#include <pathtracing_calc_fresnel_reflectance>

#include <pathtracing_sphere_intersect>

#include <pathtracing_ellipsoid_intersect>

#include <pathtracing_quad_intersect>

#include <pathtracing_box_intersect>

#include <pathtracing_cone_intersect>

#include <pathtracing_sample_quad_light>


//---------------------------------------------------------------------------------------
float SceneIntersect( )
//---------------------------------------------------------------------------------------
{
	vec3 n;
	float d;
	float t = INFINITY;
	int isRayExiting = FALSE;
	int objectCount = 0;
	
	hitObjectID = -INFINITY;
	
	/* for (int i = 0; i < N_BOXES; i++)
        {
		d = BoxIntersect( boxes[i].minCorner, boxes[i].maxCorner, rayOrigin, rayDirection, n, isRayExiting );
		if (d < t)
		{
			t = d;
			hitNormal = n;
			hitEmission = boxes[i].emission;
			hitColor = boxes[i].color;
			hitRoughness = boxes[i].roughness;
			hitType = boxes[i].type;
			hitObjectID = float(objectCount);
		}
		objectCount++;
        } */

	// manually unroll the loop above - performs 2x faster on mobile!

	d = BoxIntersect( boxes[0].minCorner, boxes[0].maxCorner, rayOrigin, rayDirection, n, isRayExiting );
	if (d < t)
	{
		t = d;
		hitNormal = n;
		hitEmission = boxes[0].emission;
		hitColor = boxes[0].color;
		hitRoughness = boxes[0].roughness;
		hitType = boxes[0].type;
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
		hitRoughness = boxes[1].roughness;
		hitType = boxes[1].type;
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
		hitRoughness = boxes[2].roughness;
		hitType = boxes[2].type;
		hitObjectID = float(objectCount);
	}
	objectCount++;

	d = BoxIntersect( boxes[3].minCorner, boxes[3].maxCorner, rayOrigin, rayDirection, n, isRayExiting );
	if (d < t)
	{
		t = d;
		hitNormal = n;
		hitEmission = boxes[3].emission;
		hitColor = boxes[3].color;
		hitRoughness = boxes[3].roughness;
		hitType = boxes[3].type;
		hitObjectID = float(objectCount);
	}
	objectCount++;

	d = BoxIntersect( boxes[4].minCorner, boxes[4].maxCorner, rayOrigin, rayDirection, n, isRayExiting );
	if (d < t)
	{
		t = d;
		hitNormal = n;
		hitEmission = boxes[4].emission;
		hitColor = boxes[4].color;
		hitRoughness = boxes[4].roughness;
		hitType = boxes[4].type;
		hitObjectID = float(objectCount);
	}
	objectCount++;

	d = BoxIntersect( boxes[5].minCorner, boxes[5].maxCorner, rayOrigin, rayDirection, n, isRayExiting );
	if (d < t)
	{
		t = d;
		hitNormal = n;
		hitEmission = boxes[5].emission;
		hitColor = boxes[5].color;
		hitRoughness = boxes[5].roughness;
		hitType = boxes[5].type;
		hitObjectID = float(objectCount);
	}
	objectCount++;

	d = BoxIntersect( boxes[6].minCorner, boxes[6].maxCorner, rayOrigin, rayDirection, n, isRayExiting );
	if (d < t)
	{
		t = d;
		hitNormal = n;
		hitEmission = boxes[6].emission;
		hitColor = boxes[6].color;
		hitRoughness = boxes[6].roughness;
		hitType = boxes[6].type;
		hitObjectID = float(objectCount);
	}
	objectCount++;

	d = BoxIntersect( boxes[7].minCorner, boxes[7].maxCorner, rayOrigin, rayDirection, n, isRayExiting );
	if (d < t)
	{
		t = d;
		hitNormal = n;
		hitEmission = boxes[7].emission;
		hitColor = boxes[7].color;
		hitRoughness = boxes[7].roughness;
		hitType = boxes[7].type;
		hitObjectID = float(objectCount);
	}
	objectCount++;

	d = BoxIntersect( boxes[8].minCorner, boxes[8].maxCorner, rayOrigin, rayDirection, n, isRayExiting );
	if (d < t)
	{
		t = d;
		hitNormal = n;
		hitEmission = boxes[8].emission;
		hitColor = boxes[8].color;
		hitRoughness = boxes[8].roughness;
		hitType = boxes[8].type;
		hitObjectID = float(objectCount);
	}
	objectCount++;

	d = BoxIntersect( boxes[9].minCorner, boxes[9].maxCorner, rayOrigin, rayDirection, n, isRayExiting );
	if (d < t)
	{
		t = d;
		hitNormal = n;
		hitEmission = boxes[9].emission;
		hitColor = boxes[9].color;
		hitRoughness = boxes[9].roughness;
		hitType = boxes[9].type;
		hitObjectID = float(objectCount);
	}
	objectCount++;


	d = QuadIntersect( quads[0].v0, quads[0].v1, quads[0].v2, quads[0].v3, rayOrigin, rayDirection, FALSE);
	if (d < t)
	{
		t = d;
		hitNormal = (quads[0].normal);
		hitEmission = quads[0].emission;
		hitColor = quads[0].color;
		hitRoughness = quads[0].roughness;
		hitType = quads[0].type;
		hitObjectID = float(objectCount);
	}
	objectCount++;

	d = QuadIntersect( quads[1].v0, quads[1].v1, quads[1].v2, quads[1].v3, rayOrigin, rayDirection, FALSE);
	if (d < t)
	{
		t = d;
		hitNormal = (quads[1].normal);
		hitEmission = quads[1].emission;
		hitColor = quads[1].color;
		hitRoughness = quads[1].roughness;
		hitType = quads[1].type;
		hitObjectID = float(objectCount);
	}
	objectCount++;

	d = QuadIntersect( quads[2].v0, quads[2].v1, quads[2].v2, quads[2].v3, rayOrigin, rayDirection, FALSE);
	if (d < t)
	{
		t = d;
		hitNormal = (quads[2].normal);
		hitEmission = quads[2].emission;
		hitColor = quads[2].color;
		hitRoughness = quads[2].roughness;
		hitType = quads[2].type;
		hitObjectID = float(objectCount);
	}
	objectCount++;

	d = QuadIntersect( quads[3].v0, quads[3].v1, quads[3].v2, quads[3].v3, rayOrigin, rayDirection, FALSE);
	if (d < t)
	{
		t = d;
		hitNormal = (quads[3].normal);
		hitEmission = quads[3].emission;
		hitColor = quads[3].color;
		hitRoughness = quads[3].roughness;
		hitType = quads[3].type;
		hitObjectID = float(objectCount);
	}
	objectCount++;

	d = QuadIntersect( quads[4].v0, quads[4].v1, quads[4].v2, quads[4].v3, rayOrigin, rayDirection, FALSE);
	if (d < t)
	{
		t = d;
		hitNormal = (quads[4].normal);
		hitEmission = quads[4].emission;
		hitColor = quads[4].color;
		hitRoughness = quads[4].roughness;
		hitType = quads[4].type;
		hitObjectID = float(objectCount);
	}
	objectCount++;

	d = QuadIntersect( quads[5].v0, quads[5].v1, quads[5].v2, quads[5].v3, rayOrigin, rayDirection, FALSE);
	if (d < t)
	{
		t = d;
		hitNormal = (quads[5].normal);
		hitEmission = quads[5].emission;
		hitColor = quads[5].color;
		hitRoughness = quads[5].roughness;
		hitType = quads[5].type;
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

	

	d = EllipsoidIntersect( ellipsoids[0].radii, ellipsoids[0].position, rayOrigin, rayDirection );
	if (d < t)
	{
		t = d;
		hitNormal = ((rayOrigin + rayDirection * t) - ellipsoids[0].position) / (ellipsoids[0].radii * ellipsoids[0].radii);
		hitEmission = ellipsoids[0].emission;
		hitColor = ellipsoids[0].color;
		hitRoughness = ellipsoids[0].roughness;
		hitType = ellipsoids[0].type;
		hitObjectID = float(objectCount);
	}
	objectCount++;

	d = EllipsoidIntersect( ellipsoids[1].radii, ellipsoids[1].position, rayOrigin, rayDirection );
	if (d < t)
	{
		t = d;
		hitNormal = ((rayOrigin + rayDirection * t) - ellipsoids[1].position) / (ellipsoids[1].radii * ellipsoids[1].radii);
		hitEmission = ellipsoids[1].emission;
		hitColor = ellipsoids[1].color;
		hitRoughness = ellipsoids[1].roughness;
		hitType = ellipsoids[1].type;
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
		hitRoughness = cones[0].roughness;
		hitType = cones[0].type;
		hitObjectID = float(objectCount);
	}
	objectCount++;

	d = ConeIntersect( cones[1].pos0, cones[1].radius0, cones[1].pos1, cones[1].radius1, rayOrigin, rayDirection, n );
	if (d < t)
	{
		t = d;
		hitNormal = n;
		hitEmission = cones[1].emission;
		hitColor = cones[1].color;
		hitRoughness = cones[1].roughness;
		hitType = cones[1].type;
		hitObjectID = float(objectCount);
	}
	objectCount++;

	d = ConeIntersect( cones[2].pos0, cones[2].radius0, cones[2].pos1, cones[2].radius1, rayOrigin, rayDirection, n );
	if (d < t)
	{
		t = d;
		hitNormal = n;
		hitEmission = cones[2].emission;
		hitColor = cones[2].color;
		hitRoughness = cones[2].roughness;
		hitType = cones[2].type;
		hitObjectID = float(objectCount);
	}
	objectCount++;

	d = ConeIntersect( cones[3].pos0, cones[3].radius0, cones[3].pos1, cones[3].radius1, rayOrigin, rayDirection, n );
	if (d < t)
	{
		t = d;
		hitNormal = n;
		hitEmission = cones[3].emission;
		hitColor = cones[3].color;
		hitRoughness = cones[3].roughness;
		hitType = cones[3].type;
		hitObjectID = float(objectCount);
	}
	objectCount++;

	d = ConeIntersect( cones[4].pos0, cones[4].radius0, cones[4].pos1, cones[4].radius1, rayOrigin, rayDirection, n );
	if (d < t)
	{
		t = d;
		hitNormal = n;
		hitEmission = cones[4].emission;
		hitColor = cones[4].color;
		hitRoughness = cones[4].roughness;
		hitType = cones[4].type;
		hitObjectID = float(objectCount);
	}
	objectCount++;


	return t;
	
} // end float SceneIntersect( )


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
	vec3 textureColor;
        
	float t;
        float weight;
	float nc, nt, ratioIoR, Re, Tr;
	float spotRadius = 1.5;
	float previousObjectID;
	float newRandom = rand();

	int reflectionBounces = -1;
	int diffuseCount = 0;
	int previousIntersecType;
	hitType = -100;

	int isSpot = FALSE;
	int bounceIsSpecular = TRUE;
	int sampleLight = FALSE;
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
		if (bounces == 0) // no metal mirrors in this scene to handle
		{
			objectNormal = n;
			objectColor = hitColor;
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
				accumCol += mask * hitEmission; // looking at light through a reflection
			
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
		

		
                if (hitType == DIFF || hitType == CLOTH ) // Ideal DIFFUSE reflection
		{
			
			if (hitType == CLOTH)
			{
				textureColor = texture(tClothTexture, (10.0 * x.xz) / 512.0).rgb;
				hitColor *= (textureColor * textureColor);
			}
			if (bounces == 0)
				objectColor = hitColor;
				
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
                        
			if (newRandom < 0.5)
				rayDirection = sampleQuadLight(x, nl, quads[0], weight);
			else
				rayDirection = sampleQuadLight(x, nl, quads[1], weight);

			mask *= weight * N_LIGHTS;
			sampleLight = TRUE;
			continue;

		} // end if (hitType == DIFF)
		
		if (hitType == COAT)  // Diffuse object underneath with ClearCoat on top
		{
			nc = 1.0; // IOR of Air
			nt = 1.5; // IOR of Clear Coat
			Re = calcFresnelReflectance(rayDirection, nl, nc, nt, ratioIoR);
			Tr = 1.0 - Re;

			if (bounces == 0)
			{
				reflectionMask = mask * Re;
				reflectionRayDirection = reflect(rayDirection, nl); // reflect ray from surface
				reflectionRayOrigin = x + nl * uEPS_intersect;
				willNeedReflectionRay = TRUE;
				if (hitColor == spheres[2].color)
					reflectionNeedsToBeSharp = TRUE;
			}

			// handle diffuse surface underneath

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
                        
			if (newRandom < 0.5)
				rayDirection = sampleQuadLight(x, nl, quads[0], weight);
			else
				rayDirection = sampleQuadLight(x, nl, quads[1], weight);
				
			mask *= weight * N_LIGHTS;
			sampleLight = TRUE;
			continue;
                        
		} //end if (hitType == COAT)
		
		if (hitType == LIGHTWOOD || hitType == DARKWOOD)  // Diffuse object underneath with thin ClearCoat on top
		{
			nc = 1.0; // IOR of Air
			nt = 1.2; // IOR of Clear Coat
			Re = calcFresnelReflectance(rayDirection, nl, nc, nt, ratioIoR);
			Tr = 1.0 - Re;

			if (bounces == 0)
			{
				reflectionMask = mask * Re;
				reflectionRayDirection = randomDirectionInSpecularLobe(reflect(rayDirection, nl), hitRoughness);
				reflectionRayOrigin = x + nl * uEPS_intersect;
				willNeedReflectionRay = TRUE;
			}
			
			if ( distance(x, vec3(212, 10, -100)) < spotRadius || distance(x, vec3(212, 10, -200)) < spotRadius ||
			 	distance(x, vec3(212, 10, -300)) < spotRadius || distance(x, vec3(212, 10, -400)) < spotRadius || 
			 	distance(x, vec3(212, 10, 0)) < spotRadius || distance(x, vec3(212, 10, 100)) < spotRadius ||
			  	distance(x, vec3(212, 10, 200)) < spotRadius || distance(x, vec3(212, 10, 300)) < spotRadius ||
			   	distance(x, vec3(212, 10, 400)) < spotRadius ) 
				isSpot = TRUE;
				
			if ( distance(x, vec3(-212, 10, -100)) < spotRadius || distance(x, vec3(-212, 10, -200)) < spotRadius || 
				distance(x, vec3(-212, 10, -300)) < spotRadius || distance(x, vec3(-212, 10, -400)) < spotRadius || 
				distance(x, vec3(-212, 10, 0)) < spotRadius || distance(x, vec3(-212, 10, 100)) < spotRadius || 
				distance(x, vec3(-212, 10, 200)) < spotRadius || distance(x, vec3(-212, 10, 300)) < spotRadius || 
				distance(x, vec3(-212, 10, 400)) < spotRadius ) 
				isSpot = TRUE;
			
			if ( distance(x, vec3(200, 10, -412)) < spotRadius || distance(x, vec3(100, 10, -412)) < spotRadius ||
				distance(x, vec3(0, 10, -412)) < spotRadius || distance(x, vec3(-100, 10, -412)) < spotRadius ||
				distance(x, vec3(-200, 10, -412)) < spotRadius || distance(x, vec3(200, 10,  412)) < spotRadius ||
				distance(x, vec3(100, 10, 412)) < spotRadius || distance(x, vec3(0, 10, 412)) < spotRadius || 
				distance(x, vec3(-100, 10, 412)) < spotRadius || distance(x, vec3(-200, 10, 412)) < spotRadius ) 
				isSpot = TRUE;
			
			if (hitType == DARKWOOD)
			{
				textureColor = texture(tDarkWoodTexture, 3.5 * x.xz / 512.0).rgb;
				hitColor *= (textureColor * textureColor);
			}
				
			if (isSpot == TRUE)
				hitColor = clamp(hitColor + 0.5, 0.0, 1.0);
				
			if (hitType == LIGHTWOOD)
			{
				textureColor = texture(tLightWoodTexture, 6.0 * x.xz / 512.0).rgb;
				hitColor *= (textureColor * textureColor);
			}
				
			if (bounces == 0)
				objectColor = hitColor;

			// handle diffuse surface underneath

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
                        
			if (newRandom < 0.5)
				rayDirection = sampleQuadLight(x, nl, quads[0], weight);
			else
				rayDirection = sampleQuadLight(x, nl, quads[1], weight);
				
			mask *= weight * N_LIGHTS;
			sampleLight = TRUE;
			continue;
                        
		} //end if (hitType == LIGHTWOOD || hitType == DARKWOOD)
		
		
	} // end for (int bounces = 0; bounces < 10; bounces++)
	

	return max(vec3(0), accumCol);

} // end vec3 CalculateRadiance( out vec3 objectNormal, out vec3 objectColor, out float objectID, out float pixelSharpness )


//-----------------------------------------------------------------------
void SetupScene(void)
//-----------------------------------------------------------------------
{
	vec3 z  = vec3(0);          
	vec3 L1 = vec3(1.0, 1.0, 1.0) * 2.0;// Bright White light
	vec3 clothColor = vec3(0.0, 0.2, 1.0) * 0.7;
	vec3 railWoodColor = vec3(0.05,0.0,0.0);
	float ceilingHeight = 300.0;
	
	quads[0] = Quad( vec3(0,-1, 0), vec3(-150, ceilingHeight,-300), vec3(-50, ceilingHeight,-300), vec3(-50, ceilingHeight,300), vec3(-150, ceilingHeight,300), L1, z, 0.0, LIGHT);// rectangular Area Light in ceiling
	quads[1] = Quad( vec3(0,-1, 0), vec3(50, ceilingHeight,-300), vec3(150, ceilingHeight,-300), vec3(150, ceilingHeight,300), vec3(50, ceilingHeight,300), L1, z, 0.0, LIGHT);// rectangular Area Light in ceiling
	quads[2] = Quad( vec3(1,-1, 0), vec3(-200,0,-400), vec3(-190,10,-400), vec3(-190,10,400), vec3(-200,0,400), z, clothColor, 0.0, CLOTH);// Cloth left Rail bottom portion
	quads[3] = Quad( vec3(-1,-1, 0), vec3(190,10,-400), vec3(200,0,-400),  vec3(200,0,400), vec3(190,10,400), z, clothColor, 0.0, CLOTH);// Cloth right Rail bottom portion
	quads[4] = Quad( vec3(0,-1, 1), vec3(-200,0,-400), vec3(200,0,-400), vec3(200,10,-390), vec3(-200,10,-390), z, clothColor, 0.0, CLOTH);// Cloth back Rail bottom portion
	quads[5] = Quad( vec3(0,-1,-1), vec3(200,0,400), vec3(-200,0,400),  vec3(-200,10,390), vec3(200,10,390), z, clothColor, 0.0, CLOTH);// Cloth front Rail bottom portion
	
	spheres[0] = Sphere(9.0, vec3( 25, 9, 25), z, vec3(0.8, 0.7, 0.4), 0.0, COAT);// White Ball
	spheres[1] = Sphere(9.0, vec3(-50, 9, 0),   z, vec3(0.9, 0.4, 0.0), 0.0, COAT);// Yellow Ball
	spheres[2] = Sphere(9.0, vec3( 50, 9, 0), z, vec3(0.25, 0.0, 0.0), 0.0, COAT);// Red Ball
        
	ellipsoids[0] = Ellipsoid(  vec3(1.97,1.97,1), vec3(0,2,79), z, vec3(0,0.3,0.7), 0.0, DIFF);//CueStick blue chalked tip
	ellipsoids[1] = Ellipsoid(  vec3(4.5,4.5,2), vec3(0,4.5,-375), z, vec3(0.01), 0.0, DIFF);//CueStick rubber butt-end cap
	
	cones[0] = Cone( vec3(0,3.5,-160), 3.5, vec3(0,2,72), 2.0, z, vec3(0.99), 0.1, LIGHTWOOD);//Wooden CueStick shaft
	cones[1] = Cone( vec3(0,2,71), 2.0, vec3(0,2,78), 1.97, z, vec3(0.9), 0.0, COAT);//CueStick shaft white plastic collar
	cones[2] = Cone( vec3(0,2,77.5), 1.93, vec3(0,2,79), 1.93, z, vec3(0.02,0.005,0.001), 0.4, COAT);//CueStick dark leather tip
	cones[3] = Cone( vec3(0,4,-270), 4.0, vec3(0,3.5,-160), 3.5, z, vec3(0.4, 0.01, 0.3), 0.0, DARKWOOD);//Wooden CueStick butt
	cones[4] = Cone( vec3(0,4.5,-375), 4.5, vec3(0,4,-270), 4.0, z, vec3(0.1), 0.0, CLOTH);//CueStick handle wrap

	boxes[0] = Box( vec3(-200,-10,-400), vec3(200,0,400), z, clothColor, 0.0, CLOTH);//Blue Cloth Table Bed
	boxes[1] = Box( vec3(-200,9,-400), vec3( 200, 10,-390), z, clothColor, 0.0, CLOTH);//Cloth Rail back
	boxes[2] = Box( vec3(-200,9, 390), vec3( 200, 10, 400), z, clothColor, 0.0, CLOTH);//Cloth Rail front
	boxes[3] = Box( vec3(-200,9,-400), vec3(-190, 10, 400), z, clothColor, 0.0, CLOTH);//Cloth Rail left
	boxes[4] = Box( vec3( 190,9,-400), vec3( 200, 10, 400), z, clothColor, 0.0, CLOTH);//Cloth Rail right
	
	boxes[5] = Box( vec3(-225,-10,-425), vec3( 225, 10,-400), z, railWoodColor, 0.3, DARKWOOD);//Wooden Rail back
	boxes[6] = Box( vec3(-225,-10, 400), vec3( 225, 10, 425), z, railWoodColor, 0.3, DARKWOOD);//Wooden Rail front
	boxes[7] = Box( vec3(-225,-10,-425), vec3(-200, 10, 425), z, railWoodColor, 0.3, DARKWOOD);//Wooden Rail left
	boxes[8] = Box( vec3( 200,-10,-425), vec3( 225, 10, 425), z, railWoodColor, 0.3, DARKWOOD);//Wooden Rail right
	boxes[9] = Box( vec3(-10000,-302,-10000), vec3(10000,-300,10000), z, vec3(0.5), 0.0, DIFF);//Floor
}


#include <pathtracing_main>
