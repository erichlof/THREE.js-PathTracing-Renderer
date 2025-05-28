precision highp float;
precision highp int;
precision highp sampler2D;

uniform mat4 uTorus_InvMatrix;
uniform vec3 uBoxMinCorner;
uniform vec3 uBoxMaxCorner;
uniform vec3 uMaterialColor;
uniform float uTorusHoleSize;
uniform int uMaterialType;
uniform bool uShowTorusAABB;

#include <pathtracing_uniforms_and_defines>


#define N_QUADS 1
#define N_BOXES 1

//-----------------------------------------------------------------------

vec3 rayOrigin, rayDirection;
// recorded intersection data:
vec3 hitNormal, hitEmission, hitColor;
vec3 shadingNormal;
vec2 hitUV;
float hitObjectID = -INFINITY;
int hitType = -100;

struct Quad { vec3 normal; vec3 v0; vec3 v1; vec3 v2; vec3 v3; vec3 emission; vec3 color; int type; };
struct Box { vec3 minCorner; vec3 maxCorner; vec3 emission; vec3 color; int type; };

Quad quads[N_QUADS];
Box boxes[N_BOXES];


#include <pathtracing_random_functions>

#include <pathtracing_calc_fresnel_reflectance>

#include <pathtracing_sphere_intersect>

#include <pathtracing_quad_intersect>

#include <pathtracing_box_interior_intersect>

#include <pathtracing_box_intersect>

#include <pathtracing_cheap_torus_intersect>

#include <pathtracing_sample_quad_light>


//---------------------------------------------------------------------------------------
float SceneIntersect( out int hitObjectWasTorus )
//---------------------------------------------------------------------------------------
{
	vec3 rObjOrigin, rObjDirection; 
	vec3 n;
	vec3 hitPos;

	float d = INFINITY;
	float t = INFINITY;
	
	int objectCount = 0;
	int isRayExiting = FALSE;
	
	hitObjectID = -INFINITY;


	d = QuadIntersect( quads[0].v0, quads[0].v1, quads[0].v2, quads[0].v3, rayOrigin, rayDirection, FALSE );
	if (d < t)
	{
		t = d;
		hitNormal = quads[0].normal;
		shadingNormal = hitNormal;
		hitEmission = quads[0].emission;
		hitColor = quads[0].color;
		hitType = quads[0].type;
		hitObjectID = float(objectCount);
		hitObjectWasTorus = FALSE;
	}
	objectCount++;
	
	d = BoxInteriorIntersect( boxes[0].minCorner, boxes[0].maxCorner, rayOrigin, rayDirection, n );
	if (d < t && n != vec3(0,0,-1))
	{
		t = d;
		hitNormal = n;
		shadingNormal = hitNormal;
		hitEmission = boxes[0].emission;
		hitColor = vec3(1);
		hitType = DIFF;
		hitObjectWasTorus = FALSE;

		if (n == vec3(1,0,0)) // left wall
		{
			hitColor = vec3(0.7, 0.05, 0.05);
		}
		else if (n == vec3(-1,0,0)) // right wall
		{
			hitColor = vec3(0.05, 0.05, 0.7);
		}
		
		hitObjectID = float(objectCount);
	}
	objectCount++;



	// transform ray into cheap torus' object space
	rObjOrigin = vec3( uTorus_InvMatrix * vec4(rayOrigin, 1.0) );
	rObjDirection = vec3( uTorus_InvMatrix * vec4(rayDirection, 0.0) );
	// cheap torus (quadratic - surface of 2nd degree)
	d = CheapTorusIntersect( rObjOrigin, rObjDirection, uTorusHoleSize, n );
	if (d < t)
	{
		t = d;
		shadingNormal = normalize(n);
		hitPos = rObjOrigin + (t * rObjDirection);
		
		if (rObjDirection.y < 0.0 && rObjOrigin.y > 0.0 && hitPos.y > 0.0 && n.y > 0.0)
		 	shadingNormal = mix(shadingNormal, vec3(0,1,0), abs(hitPos.y * hitPos.y * hitPos.y));
		if (rObjDirection.y > 0.0 && rObjOrigin.y < 0.0 && hitPos.y < 0.0 && n.y < 0.0)
			shadingNormal = mix(shadingNormal, vec3(0,-1,0), abs(hitPos.y * hitPos.y * hitPos.y));
		
		hitNormal = transpose(mat3(uTorus_InvMatrix)) * n;
		shadingNormal = transpose(mat3(uTorus_InvMatrix)) * shadingNormal;
		hitEmission = vec3(1,0,1);
		hitColor = uShowTorusAABB ? vec3(1,0,1) : uMaterialColor;
		hitType = uShowTorusAABB ? LIGHT : uMaterialType;
		hitObjectID = float(objectCount);
		hitObjectWasTorus = TRUE; // only if cheap torus was hit
	}
	objectCount++;


	if ( !uShowTorusAABB )
		return t;

	
	// yellow glass torus bounding box (AABB)
	d = BoxIntersect( uBoxMinCorner, uBoxMaxCorner, rayOrigin, rayDirection, n, isRayExiting );
	if (d < t)
	{
		t = d;
		hitNormal = n;
		shadingNormal = hitNormal;
		hitEmission = vec3(0);
		hitColor = vec3(1, 1, 0.01);
		hitType = REFR;
		hitObjectID = float(objectCount);
		hitObjectWasTorus = FALSE;
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
	vec3 x, n, nl;
	vec3 tdir;
        
	float t = INFINITY;
	float nc, nt, ratioIoR, Re, Tr;
	float weight;
	float torusEPS = 1.0;
	float previousObjectID;

	int reflectionBounces = -1;
	int diffuseCount = 0;
	int previousIntersecType = -100;
	hitType = -100;

	int bounceIsSpecular = TRUE;
	int sampleLight = FALSE;
	int willNeedReflectionRay = FALSE;
	int hitObjectWasTorus = FALSE;
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

		t = SceneIntersect( hitObjectWasTorus );

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
		shadingNormal = normalize(shadingNormal);
		// the following line is moved further down past the edge detection updates
        	//shadingNormal = dot(shadingNormal, rayDirection) < 0.0 ? shadingNormal : -shadingNormal;
		x = rayOrigin + rayDirection * t;

		if (bounces == 0)
		{
			objectID = hitObjectID;
		}
		if (isReflectionTime == FALSE && diffuseCount == 0 && hitObjectID != previousObjectID)
		{
			objectNormal += shadingNormal;
			objectColor += hitColor;
		}
		// if (reflectionNeedsToBeSharp == TRUE && reflectionBounces == 0)
		// {
		// 	objectNormal += shadingNormal;
		// }
		// next line is moved from above to here so it doesn't interfere with the edge detection updates above
		shadingNormal = dot(shadingNormal, rayDirection) < 0.0 ? shadingNormal : -shadingNormal;
		

		if (hitType == LIGHT)
		{	
			if (diffuseCount == 0 && isReflectionTime == FALSE)
				pixelSharpness = 1.0;

			if (isReflectionTime == TRUE && bounceIsSpecular == TRUE)
			{
				objectNormal += shadingNormal;
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

			rayOrigin = x + nl * (hitObjectWasTorus == TRUE ? torusEPS : uEPS_intersect);

			if (diffuseCount == 1)
			{
				diffuseBounceMask = mask;
				diffuseBounceRayOrigin = rayOrigin;
				diffuseBounceRayDirection = randomCosWeightedDirectionInHemisphere(nl);
				willNeedDiffuseBounceRay = TRUE;
			}
                        
			rayDirection = sampleQuadLight(x, shadingNormal, quads[0], weight);
			mask *= weight;
			sampleLight = TRUE;
			continue;
                        
		} // end if (hitType == DIFF)
		
		if (hitType == SPEC)  // Ideal SPECULAR reflection
		{
			mask *= hitColor;

			rayDirection = reflect(rayDirection, shadingNormal);
			rayOrigin = x + nl * (hitObjectWasTorus == TRUE ? torusEPS : uEPS_intersect);

			continue;
		}
		
		if (hitType == REFR)  // Ideal dielectric REFRACTION
		{
			nc = 1.0; // IOR of Air
			nt = 1.5; // IOR of common Glass
			Re = calcFresnelReflectance(rayDirection, shadingNormal, nc, nt, ratioIoR);
			Tr = 1.0 - Re;

			if (Re == 1.0)
			{
				rayDirection = reflect(rayDirection, shadingNormal);
				rayOrigin = x + nl * uEPS_intersect;
				continue;
			}
			
			if (diffuseCount == 0 && hitObjectID != previousObjectID && n == nl)
			{
				reflectionMask = mask * Re;
				reflectionRayDirection = reflect(rayDirection, shadingNormal); // reflect ray from surface
				reflectionRayOrigin = x + nl * (hitObjectWasTorus == TRUE ? torusEPS : uEPS_intersect);
				willNeedReflectionRay = TRUE;
				// if (bounces == 0)
				// 	reflectionNeedsToBeSharp = TRUE;
			}

			// transmit ray through surface
			mask *= hitColor;
			mask *= Tr;

			tdir = refract(rayDirection, shadingNormal, ratioIoR);
			rayDirection = uShowTorusAABB ? rayDirection : tdir;
			//rayDirection = tdir;
			rayOrigin = x - nl * (hitObjectWasTorus == TRUE ? torusEPS : uEPS_intersect);

			if (diffuseCount == 1 && isDiffuseBounceTime == TRUE)
				bounceIsSpecular = TRUE; // turn on refracting caustics

			continue;
			
		} // end if (hitType == REFR)
		
		if (hitType == COAT)  // Diffuse object underneath with ClearCoat on top
		{
			nc = 1.0; // IOR of Air
			nt = 1.4; // IOR of Clear Coat
			Re = calcFresnelReflectance(rayDirection, shadingNormal, nc, nt, ratioIoR);
			Tr = 1.0 - Re;

			if (diffuseCount == 0 && hitObjectID != previousObjectID)
			{
				reflectionMask = mask * Re;
				reflectionRayDirection = reflect(rayDirection, shadingNormal); // reflect ray from surface
				reflectionRayOrigin = x + nl * (hitObjectWasTorus == TRUE ? torusEPS : uEPS_intersect);
				willNeedReflectionRay = TRUE;
			}

			diffuseCount++;

			mask *= Tr;
			mask *= hitColor;

			bounceIsSpecular = FALSE;

			rayOrigin = x + nl * (hitObjectWasTorus == TRUE ? torusEPS : uEPS_intersect);
			
			if (diffuseCount == 1)
			{
				diffuseBounceMask = mask;
				diffuseBounceRayOrigin = rayOrigin;
				diffuseBounceRayDirection = randomCosWeightedDirectionInHemisphere(nl);
				willNeedDiffuseBounceRay = TRUE;
			}

			rayDirection = sampleQuadLight(x, shadingNormal, quads[0], weight);
			mask *= weight;
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
	vec3 z  = vec3(0);// No color value, Black        
	vec3 L1 = vec3(1.0, 1.0, 1.0) * 4.0;// Bright light
	
	float wallRadius = 50.0;

	quads[0] = Quad( vec3(0,-1,0), vec3(-wallRadius*0.3, wallRadius-1.0,-wallRadius*0.3), vec3(wallRadius*0.3, wallRadius-1.0,-wallRadius*0.3), vec3(wallRadius*0.3, wallRadius-1.0,wallRadius*0.3), vec3(-wallRadius*0.3, wallRadius-1.0,wallRadius*0.3), L1, z, LIGHT);// Area Light Rectangle in ceiling

	boxes[0] = Box( vec3(-wallRadius), vec3(wallRadius), z, vec3(1), DIFF);// the Cornell Box interior
}


#include <pathtracing_main>
