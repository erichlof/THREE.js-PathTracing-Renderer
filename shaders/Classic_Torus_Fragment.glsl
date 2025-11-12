precision highp float;
precision highp int;
precision highp sampler2D;

uniform sampler2D uUVGridTexture;
uniform mat4 uTorus_InvMatrix;
uniform vec3 uTorusPosition;
uniform vec3 uMaterialColor;
uniform vec3 uTorusMinXYZ;
uniform vec3 uTorusMaxXYZ;
uniform vec2 uTorusUV;
uniform float uTorusLargestScale;
uniform float uTorusTubeRadius;
uniform float uTorusMinAnglePercent;
uniform float uTorusMaxAnglePercent;
uniform float uTorusMinRadius;
uniform float uTorusMaxRadius;
uniform int uMaterialType;
uniform bool uShowTorusAABB;
uniform bool uTorusIsCheckered;
uniform bool uShowTorusUVs;

#include <pathtracing_uniforms_and_defines>


#define N_QUADS 1
#define N_BOXES 1

//-----------------------------------------------------------------------

vec3 rayOrigin, rayDirection;
// recorded intersection data:
vec3 hitNormal, hitEmission, hitColor;
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

#include <pathtracing_boundingbox_intersect>

#include <pathtracing_unit_torus_intersect>

#include <pathtracing_cheap_torus_intersect>

#include <pathtracing_sample_quad_light>


//---------------------------------------------------------------------------------------
float SceneIntersect( out int torusWasHit )
//---------------------------------------------------------------------------------------
{
	vec3 rObjOrigin, rObjDirection; 
	vec3 n;
	vec3 hitPos;
	vec3 torusAABBmin = vec3(-1);
	vec3 torusAABBmax = vec3(1);
	vec2 uv;
	float d = INFINITY;
	float t = INFINITY;
	int objectCount = 0;
	int isRayExiting = FALSE;
	
	hitObjectID = -INFINITY;
	torusWasHit = FALSE;

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
	
	d = BoxInteriorIntersect( boxes[0].minCorner, boxes[0].maxCorner, rayOrigin, rayDirection, n );
	if (d < t && n != vec3(0,0,-1))
	{
		t = d;
		hitNormal = n;
		hitEmission = boxes[0].emission;
		hitColor = vec3(1);
		hitType = DIFF;

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



	// UNIT TORUS

	torusAABBmin *= (uTorusLargestScale * (1.0 + uTorusTubeRadius));
	torusAABBmax *= (uTorusLargestScale * (1.0 + uTorusTubeRadius));
	//vec3 torusPos = vec3( inverse(uTorus_InvMatrix) * vec4(vec3(0), 1) );
	torusAABBmin += uTorusPosition;
	torusAABBmax += uTorusPosition;

	if ( uShowTorusAABB )
	{
		// yellow glass torus bounding box (AABB)
		d = BoxIntersect( torusAABBmin, torusAABBmax, rayOrigin, rayDirection, n, isRayExiting );
		if (d < t)
		{
			t = d;
			hitNormal = n;
			hitEmission = vec3(0);
			hitColor = vec3(1, 1, 0.01);
			hitType = REFR;
			hitObjectID = float(objectCount);
		}
		objectCount++;
	}
	
	d = BoundingBoxIntersect( torusAABBmin, torusAABBmax, rayOrigin, 1.0/rayDirection );
	if (d == INFINITY)
		return t;

	float distToTorusAABB = 0.0;
	// in the torus' case, its AABB is always a perfect cube (to allow for arbitrary rotations and scaling), so we can just pick one extent
	float BoxMinBoxMax_ext = (torusAABBmax.x - torusAABBmin.x) * 1.5; // pick 'x' extent as representative of all AABB extents, since it's always a cube

	// first check if rayOrigin is outside the torus' bounding box volume
	if (any(lessThan(rayOrigin, torusAABBmin)) || any(greaterThan(rayOrigin, torusAABBmax)))
	{
		// move rayOrigin up to the outside of torus' bounding box
		// when starting the ray closer to the torus, intersection calculations will remain precise, even if camera is very far away 
		vec3 torusRayOrigin = rayOrigin + (d * rayDirection);
		distToTorusAABB = d; // record the distance that we had to move the rayOrigin to be closer to the torus
		// transform ray into unit torus' object space, using a rayOrigin that is moved up closer to torus 
		rObjOrigin = vec3( uTorus_InvMatrix * vec4(torusRayOrigin, 1.0) ); // modified rayOrigin
		rObjDirection = vec3( uTorus_InvMatrix * vec4(rayDirection, 0.0) );
	}
	else// the rayOrigin is already close to the torus (within its bounding box volume), so continue normally
	{
		// transform ray into unit torus' object space, using the normal unmodified rayOrigin
		rObjOrigin = vec3( uTorus_InvMatrix * vec4(rayOrigin, 1.0) ); // unmodified rayOrigin
		rObjDirection = vec3( uTorus_InvMatrix * vec4(rayDirection, 0.0) );
	}

	d = UnitTorusParamIntersect( rObjOrigin, rObjDirection, uTorusTubeRadius, BoxMinBoxMax_ext, uTorusMinAnglePercent, uTorusMaxAnglePercent, 
					uTorusMinRadius, uTorusMaxRadius, uTorusMinXYZ, uTorusMaxXYZ, n, uv );
	d += distToTorusAABB; // if the rayOrigin was moved up closer to torus, now it will be added back into the total distance to intersection
	if (d < t)
	{
		t = d;
		hitNormal = transpose(mat3(uTorus_InvMatrix)) * n;
		hitEmission = vec3(1,0,1);
		hitColor = uMaterialColor;
		hitUV = uv;
		hitType = uShowTorusAABB ? LIGHT : uMaterialType;
		hitObjectID = float(objectCount);
		torusWasHit = TRUE;
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
	vec3 textureColor;
        
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
	int isDiffuseBounceTime = FALSE;
	int torusWasHit = FALSE;


	for (int bounces = 0; bounces < 10; bounces++)
	{
		if (isReflectionTime == TRUE)
			reflectionBounces++;

		previousIntersecType = hitType;
		previousObjectID = hitObjectID;

		t = SceneIntersect( torusWasHit );

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
		if (isReflectionTime == FALSE && diffuseCount == 0)
		{
			objectNormal += n; // change nl to n in order to keep edge detection accurate on same object
			objectColor += hitColor;
		}
		// if (reflectionNeedsToBeSharp == TRUE && reflectionBounces == 0)
		// {
		// 	objectNormal += nl;
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

	
		if (torusWasHit == TRUE && !uShowTorusAABB)
		{
			if (uTorusIsCheckered)
			{
				hitUV *= uTorusUV;
				hitColor = mod(floor(hitUV.x) + floor(hitUV.y), 2.0) == 0.0 ? vec3(1,1,1) : hitColor;
			}
			else if (uShowTorusUVs)
			{
				hitUV *= uTorusUV;
				textureColor = texture(uUVGridTexture, hitUV).rgb;
				textureColor *= textureColor; // remove gamma from texture image
				hitColor = textureColor;
			}
			
			if (diffuseCount == 0 && isReflectionTime == FALSE)
				objectColor += hitColor; // lets edge detector do its work
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
				// if (bounces == 0)
				// 	reflectionNeedsToBeSharp = TRUE;
			}

			// transmit ray through surface
			mask *= hitColor;
			mask *= Tr;

			tdir = refract(rayDirection, nl, ratioIoR);
			rayDirection = uShowTorusAABB ? rayDirection : tdir;
			//rayDirection = tdir;
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

			rayDirection = sampleQuadLight(x, nl, quads[0], weight);
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
