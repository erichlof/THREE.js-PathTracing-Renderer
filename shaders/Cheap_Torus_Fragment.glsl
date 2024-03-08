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
float hitObjectID;
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
	vec3 dirToLight;
	vec3 tdir;
	vec3 x, n, nl;
        
	float t = INFINITY;
	float nc, nt, ratioIoR, Re, Tr;
	float weight;
	float torusEPS = 1.0;

	int diffuseCount = 0;
	int previousIntersecType = -100;
	hitType = -100;

	int coatTypeIntersected = FALSE;
	int bounceIsSpecular = TRUE;
	int sampleLight = FALSE;
	int willNeedReflectionRay = FALSE;
	int hitObjectWasTorus = FALSE;


	for (int bounces = 0; bounces < 6; bounces++)
	{
		previousIntersecType = hitType;

		t = SceneIntersect( hitObjectWasTorus );

		if (t == INFINITY)
		{
			if (willNeedReflectionRay == TRUE)
			{
				mask = reflectionMask;
				rayOrigin = reflectionRayOrigin;
				rayDirection = reflectionRayDirection;

				willNeedReflectionRay = FALSE;
				bounceIsSpecular = TRUE;
				sampleLight = FALSE;
				diffuseCount = 0;
				continue;
			}

			break;
		}

		// useful data 
		n = normalize(hitNormal);
                nl = dot(n, rayDirection) < 0.0 ? n : -n;
		shadingNormal = normalize(shadingNormal);
        	shadingNormal = dot(shadingNormal, rayDirection) < 0.0 ? shadingNormal : -shadingNormal;
		x = rayOrigin + rayDirection * t;

		if (bounces == 0)
		{
			//objectNormal = nl;
			objectNormal = shadingNormal;
			objectColor = hitColor;
			objectID = hitObjectID;
		}
		if (bounces == 1 && diffuseCount == 0 && coatTypeIntersected == FALSE)
		{
			//objectNormal = nl;
			objectNormal = shadingNormal;
		}
		
		
		if (hitType == LIGHT)
		{	
			if (bounces == 0 || (bounces == 1 && previousIntersecType == SPEC))
				pixelSharpness = 1.01;

			if (diffuseCount == 0)
			{
				//objectNormal = nl;
				objectNormal = shadingNormal;
				objectColor = hitColor;
				objectID = hitObjectID;
			}
			
			if (bounceIsSpecular == TRUE || sampleLight == TRUE)
				accumCol += mask * hitEmission;

			if (willNeedReflectionRay == TRUE)
			{
				mask = reflectionMask;
				rayOrigin = reflectionRayOrigin;
				rayDirection = reflectionRayDirection;

				willNeedReflectionRay = FALSE;
				bounceIsSpecular = TRUE;
				sampleLight = FALSE;
				diffuseCount = 0;
				continue;
			}
			// reached a light, so we can exit
			break;

		} // end if (hitType == LIGHT)


		// if we get here and sampleLight is still TRUE, shadow ray failed to find the light source 
		// the ray hit an occluding object along its way to the light
		if (sampleLight == TRUE)
		{
			if (willNeedReflectionRay == TRUE)
			{
				mask = reflectionMask;
				rayOrigin = reflectionRayOrigin;
				rayDirection = reflectionRayDirection;

				willNeedReflectionRay = FALSE;
				bounceIsSpecular = TRUE;
				sampleLight = FALSE;
				diffuseCount = 0;
				continue;
			}

			break;
		}
	
		
		    
                if (hitType == DIFF) // Ideal DIFFUSE reflection
		{	
			diffuseCount++;

			mask *= hitColor;

			bounceIsSpecular = FALSE;

			if (diffuseCount == 1 && rand() < 0.5)
			{
				mask *= 2.0;
				// choose random Diffuse sample vector
				rayDirection = randomCosWeightedDirectionInHemisphere(shadingNormal);
				rayOrigin = x + nl * (hitObjectWasTorus == TRUE ? torusEPS : uEPS_intersect);
				continue;
			}
                        
			dirToLight = sampleQuadLight(x, shadingNormal, quads[0], weight);
			mask *= diffuseCount == 1 ? 2.0 : 1.0;
			mask *= weight;

			rayDirection = dirToLight;
			rayOrigin = x + nl * (hitObjectWasTorus == TRUE ? torusEPS : uEPS_intersect);

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
			pixelSharpness = diffuseCount == 0 ? -1.0 : pixelSharpness;

			nc = 1.0; // IOR of Air
			nt = 1.5; // IOR of common Glass
			Re = calcFresnelReflectance(rayDirection, shadingNormal, nc, nt, ratioIoR);
			Tr = 1.0 - Re;
			
			if (bounces == 0)// || (bounces == 1 && hitObjectID != objectID && bounceIsSpecular == TRUE))
			{
				reflectionMask = mask * Re;
				reflectionRayDirection = reflect(rayDirection, shadingNormal); // reflect ray from surface
				reflectionRayOrigin = x + nl * (hitObjectWasTorus == TRUE ? torusEPS : uEPS_intersect);
				willNeedReflectionRay = TRUE;
			}

			if (Re == 1.0)
			{
				mask = reflectionMask;
				rayOrigin = reflectionRayOrigin;
				rayDirection = reflectionRayDirection;

				willNeedReflectionRay = FALSE;
				bounceIsSpecular = TRUE;
				sampleLight = FALSE;
				continue;
			}

			// transmit ray through surface
			mask *= hitColor;
			mask *= Tr;

			tdir = refract(rayDirection, shadingNormal, ratioIoR);
			rayDirection = uShowTorusAABB ? rayDirection : tdir;
			//rayDirection = tdir;
			rayOrigin = x - nl * (hitObjectWasTorus == TRUE ? torusEPS : uEPS_intersect);

			if (diffuseCount == 1 && coatTypeIntersected == FALSE)
				bounceIsSpecular = TRUE; // turn on refracting caustics

			continue;
			
		} // end if (hitType == REFR)
		
		if (hitType == COAT)  // Diffuse object underneath with ClearCoat on top
		{
			coatTypeIntersected = TRUE;

			nc = 1.0; // IOR of Air
			nt = 1.4; // IOR of Clear Coat
			Re = calcFresnelReflectance(rayDirection, shadingNormal, nc, nt, ratioIoR);
			Tr = 1.0 - Re;

			if (bounces == 0)// || (bounces == 1 && hitObjectID != objectID && bounceIsSpecular == TRUE))
			{
				reflectionMask = mask * Re;
				reflectionRayDirection = reflect(rayDirection, shadingNormal); // reflect ray from surface
				reflectionRayOrigin = x + nl * (hitObjectWasTorus == TRUE ? torusEPS : uEPS_intersect);
				willNeedReflectionRay = TRUE;
			}

			diffuseCount++;

			if (bounces == 0)
				mask *= Tr;
			mask *= hitColor;

			bounceIsSpecular = FALSE;
			
			if (diffuseCount == 1 && rand() < 0.5)
			{
				mask *= 2.0;
				// choose random Diffuse sample vector
				rayDirection = randomCosWeightedDirectionInHemisphere(shadingNormal);
				rayOrigin = x + nl * (hitObjectWasTorus == TRUE ? torusEPS : uEPS_intersect);
				continue;
			}

			dirToLight = sampleQuadLight(x, shadingNormal, quads[0], weight);
			mask *= diffuseCount == 1 ? 2.0 : 1.0;
			mask *= weight;
			
			rayDirection = dirToLight;
			rayOrigin = x + nl * (hitObjectWasTorus == TRUE ? torusEPS : uEPS_intersect);

			sampleLight = TRUE;
			continue;
			
		} //end if (hitType == COAT)
		
	} // end for (int bounces = 0; bounces < 6; bounces++)
	
	
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