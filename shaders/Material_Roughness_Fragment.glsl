precision highp float;
precision highp int;
precision highp sampler2D;

#include <pathtracing_uniforms_and_defines>
uniform int uMaterialType;
uniform vec3 uMaterialColor;

#define N_LIGHTS 3.0
#define N_SPHERES 15

//-----------------------------------------------------------------------

vec3 rayOrigin, rayDirection;
// recorded intersection data:
vec3 hitNormal, hitEmission, hitColor;
vec2 hitUV;
float hitRoughness;
float hitObjectID = -INFINITY;
int hitType = -100;


struct Sphere { float radius; vec3 position; vec3 emission; vec3 color; float roughness; int type; };

Sphere spheres[N_SPHERES];


#include <pathtracing_random_functions>

#include <pathtracing_calc_fresnel_reflectance>

#include <pathtracing_sphere_intersect>

#include <pathtracing_sample_sphere_light>


//---------------------------------------------------------------------------------------
float SceneIntersect( )
//---------------------------------------------------------------------------------------
{
	vec3 n;
	vec3 hitPos;
	float d;
	float t = INFINITY;
	float q;
	
	int objectCount = 0;
	
	hitObjectID = -INFINITY;
	
        /* for (int i = 0; i < N_SPHERES; i++)
        {
		d = SphereIntersect( spheres[i].radius, spheres[i].position, rayOrigin, rayDirection );
		if (d < t)
		{
			t = d;
			hitNormal = (rayOrigin + rayDirection * t) - spheres[i].position;
			hitEmission = spheres[i].emission;
			hitColor = spheres[i].color;
                        hitRoughness = spheres[i].roughness;
			hitType = spheres[i].type;
			hitObjectID = float(objectCount);
		}
		objectCount++;
	} */

	// manually unroll the loop above - performs 2x faster on mobile!

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
		hitRoughness = spheres[4].roughness;
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
		hitRoughness = spheres[5].roughness;
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
		hitRoughness = spheres[6].roughness;
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
		hitRoughness = spheres[7].roughness;
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
		hitRoughness = spheres[8].roughness;
		hitType = spheres[8].type;
		hitObjectID = float(objectCount);
	}
	objectCount++;

	d = SphereIntersect( spheres[9].radius, spheres[9].position, rayOrigin, rayDirection );
	if (d < t)
	{
		t = d;
		hitNormal = (rayOrigin + rayDirection * t) - spheres[9].position;
		hitEmission = spheres[9].emission;
		hitColor = spheres[9].color;
		hitRoughness = spheres[9].roughness;
		hitType = spheres[9].type;
		hitObjectID = float(objectCount);
	}
	objectCount++;

	d = SphereIntersect( spheres[10].radius, spheres[10].position, rayOrigin, rayDirection );
	if (d < t)
	{
		t = d;
		hitNormal = (rayOrigin + rayDirection * t) - spheres[10].position;
		hitEmission = spheres[10].emission;
		hitColor = spheres[10].color;
		hitRoughness = spheres[10].roughness;
		hitType = spheres[10].type;
		hitObjectID = float(objectCount);
	}
	objectCount++;

	d = SphereIntersect( spheres[11].radius, spheres[11].position, rayOrigin, rayDirection );
	if (d < t)
	{
		t = d;
		hitNormal = (rayOrigin + rayDirection * t) - spheres[11].position;
		hitEmission = spheres[11].emission;
		hitColor = spheres[11].color;
		hitRoughness = spheres[11].roughness;
		hitType = spheres[11].type;
		hitObjectID = float(objectCount);
	}
	objectCount++;

	d = SphereIntersect( spheres[12].radius, spheres[12].position, rayOrigin, rayDirection );
	if (d < t)
	{
		t = d;
		hitNormal = (rayOrigin + rayDirection * t) - spheres[12].position;
		hitEmission = spheres[12].emission;
		hitColor = spheres[12].color;
		hitRoughness = spheres[12].roughness;
		hitType = spheres[12].type;
		hitObjectID = float(objectCount);
	}
	objectCount++;

	d = SphereIntersect( spheres[13].radius, spheres[13].position, rayOrigin, rayDirection );
	if (d < t)
	{
		t = d;
		hitNormal = (rayOrigin + rayDirection * t) - spheres[13].position;
		hitEmission = spheres[13].emission;
		hitColor = spheres[13].color;
		hitRoughness = spheres[13].roughness;
		hitType = spheres[13].type;
		hitObjectID = float(objectCount);
	}
	objectCount++;

	d = SphereIntersect( spheres[14].radius, spheres[14].position, rayOrigin, rayDirection );
	if (d < t)
	{
		t = d;
		hitNormal = (rayOrigin + rayDirection * t) - spheres[14].position;
		hitEmission = spheres[14].emission;
		hitColor = spheres[14].color;
		hitRoughness = spheres[14].roughness;
		hitType = spheres[14].type;
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
	vec3 checkCol0 = vec3(1);
	vec3 checkCol1 = vec3(0.5);
	vec3 x, n, nl, normal;
        
	float t;
	float nc, nt, ratioIoR, Re, Tr;
	float weight;
	float thickness = 0.05;
	float firstIntersectionRoughness = 0.0;
	float previousObjectID;
	float newRandom = rand();

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
	int isDiffuseBounceTime = FALSE;


	
	for (int bounces = 0; bounces < 10; bounces++)
	{
		//if (isReflectionTime == TRUE)
		//	reflectionBounces++;

		previousIntersecType = hitType;
		previousObjectID = hitObjectID;

		t = SceneIntersect();
		
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
			firstIntersectionRoughness = hitRoughness;
		}
		if (isReflectionTime == FALSE && diffuseCount == 0 && hitObjectID != previousObjectID && firstIntersectionRoughness < 0.2)
		{
			objectNormal += n;
			objectColor += hitColor;
		}
		/* if (reflectionNeedsToBeSharp == TRUE && reflectionBounces == 0)
		{
			objectNormal += n;
			objectColor += hitColor;
		} */

		
		if (hitType == LIGHT)
		{	
			
			if (diffuseCount == 0 && firstIntersectionRoughness < 0.1 && isReflectionTime == FALSE)
				pixelSharpness = 1.0;

			if (isReflectionTime == TRUE && bounceIsSpecular == TRUE && firstIntersectionRoughness < 0.1)
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

			if (diffuseCount == 0 && rand() > (hitRoughness * hitRoughness))
			{
				mask *= 1.1;
				rayDirection = reflect(rayDirection, nl); // reflect ray from metal surface
				rayDirection = randomDirectionInSpecularLobe(rayDirection, hitRoughness == 0.1 ? 0.25 : hitRoughness * 0.8);
				rayOrigin = x + nl * uEPS_intersect;
				continue;
			}

			if (diffuseCount == 0)
				mask /= max(0.7, 1.0 - (hitRoughness * hitRoughness));

			diffuseCount++;
			
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

			if (bounces == 0)// || (bounces == 1 && hitObjectID != objectID && bounceIsSpecular == TRUE))
			{
				reflectionMask = mask * Re;
				reflectionRayDirection = reflect(rayDirection, nl); // reflect ray from surface
				reflectionRayDirection = randomDirectionInSpecularLobe(reflectionRayDirection, hitRoughness * 0.8);
				reflectionRayOrigin = x + nl * uEPS_intersect;
				willNeedReflectionRay = TRUE;
			}

			// transmit ray through surface
			// is ray leaving a solid object from the inside? 
			// If so, attenuate ray color with object color by how far ray has travelled through the medium
			if (distance(n, nl) > 0.1)
			{
				mask *= exp(log(hitColor) * thickness * t);
			}

			mask *= Tr;
			
			rayDirection = refract(rayDirection, nl, ratioIoR);
			rayDirection = randomDirectionInSpecularLobe(rayDirection, hitRoughness * 0.4);
			rayOrigin = x - nl * uEPS_intersect;

			if (diffuseCount == 1 && isDiffuseBounceTime == TRUE)
				bounceIsSpecular = TRUE; // turn on refracting caustics

			continue;
			
		} // end if (hitType == REFR)
		
		if (hitType == COAT)  // Diffuse object underneath with ClearCoat on top
		{
			nc = 1.0; // IOR of Air
			nt = 1.5; // IOR of Clear Coat
			Re = calcFresnelReflectance(rayDirection, nl, nc, nt, ratioIoR);
			Tr = 1.0 - Re;

			if (bounces == 0)// || (bounces == 1 && hitObjectID != objectID && bounceIsSpecular == TRUE))
			{
				reflectionMask = mask * Re;
				reflectionRayDirection = reflect(rayDirection, nl); // reflect ray from surface
				reflectionRayDirection = randomDirectionInSpecularLobe(reflectionRayDirection, hitRoughness * 0.8);
				reflectionRayOrigin = x + nl * uEPS_intersect;
				willNeedReflectionRay = TRUE;
			}

			diffuseCount++;

			mask *= 1.5;
			//if (bounces == 0)
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
 
			if (newRandom < 0.3333)
				rayDirection = sampleSphereLight(x, nl, spheres[0], weight);
			else if (newRandom < 0.6666)
				rayDirection = sampleSphereLight(x, nl, spheres[1], weight);
			else
				rayDirection = sampleSphereLight(x, nl, spheres[2], weight);
			
			mask *= weight * N_LIGHTS;
			sampleLight = TRUE;
			continue;
                        
		} //end if (hitType == COAT)

		if (hitType == METALCOAT)  // Metal object underneath with ClearCoat on top
		{
			nc = 1.0; // IOR of Air
			nt = 1.5; // IOR of Clear Coat
			Re = calcFresnelReflectance(rayDirection, nl, nc, nt, ratioIoR);
			Tr = 1.0 - Re;

			if (bounces == 0)// || (bounces == 1 && hitObjectID != objectID && bounceIsSpecular == TRUE))
			{
				reflectionMask = mask * Re;
				reflectionRayDirection = reflect(rayDirection, nl); // reflect ray from surface
				reflectionRayOrigin = x + nl * uEPS_intersect;
				willNeedReflectionRay = TRUE;
			}

			mask *= 1.25;
			//if (bounces == 0)
				mask *= Tr;
			mask *= hitColor;
			
			rayDirection = reflect(rayDirection, nl); // reflect ray from metal surface
			rayDirection = randomDirectionInSpecularLobe(rayDirection, hitRoughness == 0.1 ? 0.25 : hitRoughness * 0.8);
			rayOrigin = x + nl * uEPS_intersect;
			continue;

		} //end if (hitType == METALCOAT)

		
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
	vec3 L3 = vec3(0.1, 0.7, 1.0) * 2.0; // Blue light
	
	vec3 color = uMaterialColor;
	int typeID = uMaterialType;
	
        spheres[0]  = Sphere(150.0, vec3(-400, 900, 200), L1, z, 0.0, LIGHT);//spherical white Light1 
	spheres[1]  = Sphere(100.0, vec3( 300, 400,-300), L2, z, 0.0, LIGHT);//spherical yellow Light2
	spheres[2]  = Sphere( 50.0, vec3( 500, 250,-100), L3, z, 0.0, LIGHT);//spherical blue Light3
	
	spheres[3]  = Sphere(1000.0, vec3(  0.0, 1000.0,  0.0), z, vec3(1.0, 1.0, 1.0), 0.0, DIFF);//Checkered Floor

        spheres[4]  = Sphere(  14.0, vec3(-150, 30, 0), z, color, 0.0, typeID);
        spheres[5]  = Sphere(  14.0, vec3(-120, 30, 0), z, color, 0.1, typeID);
        spheres[6]  = Sphere(  14.0, vec3( -90, 30, 0), z, color, 0.2, typeID);
        spheres[7]  = Sphere(  14.0, vec3( -60, 30, 0), z, color, 0.3, typeID);
        spheres[8]  = Sphere(  14.0, vec3( -30, 30, 0), z, color, 0.4, typeID);
        spheres[9]  = Sphere(  14.0, vec3(   0, 30, 0), z, color, 0.5, typeID);
        spheres[10] = Sphere(  14.0, vec3(  30, 30, 0), z, color, 0.6, typeID);
        spheres[11] = Sphere(  14.0, vec3(  60, 30, 0), z, color, 0.7, typeID);
        spheres[12] = Sphere(  14.0, vec3(  90, 30, 0), z, color, 0.8, typeID);
        spheres[13] = Sphere(  14.0, vec3( 120, 30, 0), z, color, 0.9, typeID);
        spheres[14] = Sphere(  14.0, vec3( 150, 30, 0), z, color, 1.0, typeID);
}


#include <pathtracing_main>
