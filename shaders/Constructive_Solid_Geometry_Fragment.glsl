precision highp float;
precision highp int;
precision highp sampler2D;


uniform int uCSG_OperationType;
uniform int uShapeAType;
uniform int uMaterialAType;
uniform int uShapeBType;
uniform int uMaterialBType;
uniform float uA_kParameter;
uniform float uB_kParameter;
uniform vec3 uMaterialAColor;
uniform vec3 uMaterialBColor;
uniform mat4 uCSG_ShapeA_InvMatrix;
uniform mat4 uCSG_ShapeB_InvMatrix;

#include <pathtracing_uniforms_and_defines>


#define N_QUADS 1
#define N_BOXES 1

//-----------------------------------------------------------------------

vec3 rayOrigin, rayDirection;
// recorded intersection data:
vec3 hitNormal, hitEmission, hitColor;
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

#include <pathtracing_sphere_csg_intersect>

#include <pathtracing_cylinder_csg_intersect>

#include <pathtracing_cone_csg_intersect>

#include <pathtracing_conicalprism_csg_intersect>

#include <pathtracing_paraboloid_csg_intersect>

#include <pathtracing_parabolicprism_csg_intersect>

#include <pathtracing_hyperboloid1sheet_csg_intersect>

#include <pathtracing_hyperbolicprism1sheet_csg_intersect>

#include <pathtracing_hyperboloid2sheets_csg_intersect>

#include <pathtracing_hyperbolicprism2sheets_csg_intersect>

#include <pathtracing_capsule_csg_intersect>

#include <pathtracing_box_csg_intersect>

#include <pathtracing_pyramidfrustum_csg_intersect>

#include <pathtracing_csg_operations>

#include <pathtracing_quad_intersect>

#include <pathtracing_box_interior_intersect>

#include <pathtracing_sample_quad_light>



//---------------------------------------------------------------------------------------
float SceneIntersect( )
//---------------------------------------------------------------------------------------
{
	vec3 rObjOrigin, rObjDirection; 
	vec3 n, A_n0, A_n1, B_n0, B_n1, n0, n1;
	vec3 A_color0, A_color1, B_color0, B_color1, color0, color1;
	vec3 hit;
	float A_t0 = 0.0;
	float A_t1 = 0.0;
	float B_t0 = 0.0; 
	float B_t1 = 0.0;
	float t0 = 0.0;
	float t1 = 0.0;
	float d = INFINITY;
	float t = INFINITY;
	int A_type0, A_type1, B_type0, B_type1, type0, type1;
	int A_objectID0, A_objectID1, B_objectID0, B_objectID1, objectID0, objectID1;
	int objectCount = 0;
	
	hitObjectID = -INFINITY;


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


	// SHAPE A
	// transform ray into CSG_Shape1's object space
	rObjOrigin = vec3( uCSG_ShapeA_InvMatrix * vec4(rayOrigin, 1.0) );
	rObjDirection = vec3( uCSG_ShapeA_InvMatrix * vec4(rayDirection, 0.0) );
	if (uShapeAType == 0)
		Sphere_CSG_Intersect( rObjOrigin, rObjDirection, A_t0, A_t1, A_n0, A_n1 );
	else if (uShapeAType == 1)
		Cylinder_CSG_Intersect( rObjOrigin, rObjDirection, A_t0, A_t1, A_n0, A_n1 );
	else if (uShapeAType == 2)
		Cone_CSG_Intersect( uA_kParameter, rObjOrigin, rObjDirection, A_t0, A_t1, A_n0, A_n1 );
	else if (uShapeAType == 3)
		Paraboloid_CSG_Intersect( rObjOrigin, rObjDirection, A_t0, A_t1, A_n0, A_n1 );
	else if (uShapeAType == 4)
		Hyperboloid1Sheet_CSG_Intersect( uA_kParameter, rObjOrigin, rObjDirection, A_t0, A_t1, A_n0, A_n1 );
	else if (uShapeAType == 5)
		Hyperboloid2Sheets_CSG_Intersect( uA_kParameter, rObjOrigin, rObjDirection, A_t0, A_t1, A_n0, A_n1 );
	else if (uShapeAType == 6) 
		Capsule_CSG_Intersect( uA_kParameter, rObjOrigin, rObjDirection, A_t0, A_t1, A_n0, A_n1 );
	else if (uShapeAType == 7)
		Box_CSG_Intersect( rObjOrigin, rObjDirection, A_t0, A_t1, A_n0, A_n1 );
	else if (uShapeAType == 8)
		PyramidFrustum_CSG_Intersect( uA_kParameter, rObjOrigin, rObjDirection, A_t0, A_t1, A_n0, A_n1 );
	else if (uShapeAType == 9)
		ConicalPrism_CSG_Intersect( uA_kParameter, rObjOrigin, rObjDirection, A_t0, A_t1, A_n0, A_n1 );
	else if (uShapeAType == 10)
		ParabolicPrism_CSG_Intersect( rObjOrigin, rObjDirection, A_t0, A_t1, A_n0, A_n1 );
	else if (uShapeAType == 11)
		HyperbolicPrism1Sheet_CSG_Intersect( uA_kParameter, rObjOrigin, rObjDirection, A_t0, A_t1, A_n0, A_n1 );
	else //if (uShapeAType == 12)
		HyperbolicPrism2Sheets_CSG_Intersect( uA_kParameter, rObjOrigin, rObjDirection, A_t0, A_t1, A_n0, A_n1 );

	n = (A_n0);
	A_n0 = (transpose(mat3(uCSG_ShapeA_InvMatrix)) * n);
	n = (A_n1);
	A_n1 = (transpose(mat3(uCSG_ShapeA_InvMatrix)) * n);
	

	// SHAPE B
	// transform ray into CSG_ShapeB's object space
	rObjOrigin = vec3( uCSG_ShapeB_InvMatrix * vec4(rayOrigin, 1.0) );
	rObjDirection = vec3( uCSG_ShapeB_InvMatrix * vec4(rayDirection, 0.0) );
	if (uShapeBType == 0)
		Sphere_CSG_Intersect( rObjOrigin, rObjDirection, B_t0, B_t1, B_n0, B_n1 );
	else if (uShapeBType == 1)
		Cylinder_CSG_Intersect( rObjOrigin, rObjDirection, B_t0, B_t1, B_n0, B_n1 );
	else if (uShapeBType == 2)
		Cone_CSG_Intersect( uB_kParameter, rObjOrigin, rObjDirection, B_t0, B_t1, B_n0, B_n1 );
	else if (uShapeBType == 3)
		Paraboloid_CSG_Intersect( rObjOrigin, rObjDirection, B_t0, B_t1, B_n0, B_n1 );
	else if (uShapeBType == 4)
		Hyperboloid1Sheet_CSG_Intersect( uB_kParameter, rObjOrigin, rObjDirection, B_t0, B_t1, B_n0, B_n1 );
	else if (uShapeBType == 5)
		Hyperboloid2Sheets_CSG_Intersect( uB_kParameter, rObjOrigin, rObjDirection, B_t0, B_t1, B_n0, B_n1 );
	else if (uShapeBType == 6)
		Capsule_CSG_Intersect( uB_kParameter, rObjOrigin, rObjDirection, B_t0, B_t1, B_n0, B_n1 );
	else if (uShapeBType == 7)
		Box_CSG_Intersect( rObjOrigin, rObjDirection, B_t0, B_t1, B_n0, B_n1 );
	else if (uShapeBType == 8)
		PyramidFrustum_CSG_Intersect( uB_kParameter, rObjOrigin, rObjDirection, B_t0, B_t1, B_n0, B_n1 );
	else if (uShapeBType == 9)
		ConicalPrism_CSG_Intersect( uB_kParameter, rObjOrigin, rObjDirection, B_t0, B_t1, B_n0, B_n1 );
	else if (uShapeBType == 10)
		ParabolicPrism_CSG_Intersect( rObjOrigin, rObjDirection, B_t0, B_t1, B_n0, B_n1 );
	else if (uShapeBType == 11)
		HyperbolicPrism1Sheet_CSG_Intersect( uB_kParameter, rObjOrigin, rObjDirection, B_t0, B_t1, B_n0, B_n1 );
	else //if (uShapeBType == 12)
		HyperbolicPrism2Sheets_CSG_Intersect( uB_kParameter, rObjOrigin, rObjDirection, B_t0, B_t1, B_n0, B_n1 );

	n = (B_n0);
	B_n0 = (transpose(mat3(uCSG_ShapeB_InvMatrix)) * n);
	n = (B_n1);
	B_n1 = (transpose(mat3(uCSG_ShapeB_InvMatrix)) * n);

	
	A_color0 = A_color1 = uMaterialAColor;
	A_type0 = A_type1 = uMaterialAType;
	B_color0 = B_color1 = uMaterialBColor;
	B_type0 = B_type1 = uMaterialBType;

	// reset t0 and t1
	t0 = t1 = 0.0;

	if (uCSG_OperationType == 0)
		CSG_Union_Operation( A_t0, A_n0, A_type0, A_color0, A_objectID0, A_t1, A_n1, A_type1, A_color1, A_objectID1, // <-- this line = input 1st surface data
				     B_t0, B_n0, B_type0, B_color0, B_objectID0, B_t1, B_n1, B_type1, B_color1, B_objectID1, // <-- this line = input 2nd surface data
				     t0, n0, type0, color0, objectID0, t1, n1, type1, color1, objectID1 ); // <-- this line = resulting csg operation data output
	else if (uCSG_OperationType == 1)
		CSG_Difference_Operation( A_t0, A_n0, A_type0, A_color0, A_objectID0, A_t1, A_n1, A_type1, A_color1, A_objectID1, // <-- this line = input 1st surface data
				     	  B_t0, B_n0, B_type0, B_color0, B_objectID0, B_t1, B_n1, B_type1, B_color1, B_objectID1, // <-- this line = input 2nd surface data
				          t0, n0, type0, color0, objectID0, t1, n1, type1, color1, objectID1 ); // <-- this line = resulting csg operation data output
	else
		CSG_Intersection_Operation( A_t0, A_n0, A_type0, A_color0, A_objectID0, A_t1, A_n1, A_type1, A_color1, A_objectID1, // <-- this line = input 1st surface data
				     	    B_t0, B_n0, B_type0, B_color0, B_objectID0, B_t1, B_n1, B_type1, B_color1, B_objectID1, // <-- this line = input 2nd surface data
				            t0, n0, type0, color0, objectID0, t1, n1, type1, color1, objectID1 ); // <-- this line = resulting csg operation data output
	
	// compare the resulting intersection pair (t0/t1) with the rest of the scene and update data if we get a closer t value
	
	if (t0 > 0.0 && t0 < t)
	{
		t = t0;
		hitNormal = n0;
		hitEmission = vec3(0);
		hitColor = color0;
		hitType = type0;
		hitObjectID = float(objectCount);
	}
	else if (t1 > 0.0 && t1 < t)
	{
		t = t1;
		hitNormal = n1;
		hitEmission = vec3(0);
		hitColor = color1;
		hitType = type1;
		hitObjectID = float(objectCount + 1);
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
			objectNormal += n;
			objectColor += hitColor;
		}
		/* if (reflectionNeedsToBeSharp == TRUE && reflectionBounces == 0)
		{
			objectNormal += n;
			objectColor += hitColor;
			objectID += hitObjectID;
		} */
		
		
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
			// the following check wouldn't work because coat/glass objects could be intersecting, 
			//   causing the 1st outer reflection (bounces == 0) to not show up
			///if (diffuseCount == 0 && hitObjectID != previousObjectID && n == nl)
			// therefore we have to use simple check if (bounces == 0).  If mirrors are needed, additional checks for
			//   (bounces == 1) && (previousIntersecType == SPEC) would allow correct reflections 'inside' the mirror image
			
			if (Re == 1.0)
			{
				rayDirection = reflect(rayDirection, nl);
				rayOrigin = x + nl * uEPS_intersect;
				continue;
			}
			
			if (bounces == 0 && n == nl)
			{
				reflectionMask = mask * Re;
				reflectionRayDirection = reflect(rayDirection, nl); // reflect ray from surface
				reflectionRayOrigin = x + nl * uEPS_intersect;
				willNeedReflectionRay = TRUE;
				//if (bounces == 0)
					//reflectionNeedsToBeSharp = TRUE;
			}

			// transmit ray through surface
			mask *= hitColor;
			mask *= Tr;

			rayDirection = refract(rayDirection, nl, ratioIoR);
			rayOrigin = x - nl * uEPS_intersect;

			if (diffuseCount == 1 && isDiffuseBounceTime == TRUE)// && previousIntersecType != COAT)
				bounceIsSpecular = TRUE; // turn on refracting caustics

			continue;
			
		} // end if (hitType == REFR)
		
		if (hitType == COAT)  // Diffuse object underneath with ClearCoat on top
		{
			nc = 1.0; // IOR of Air
			nt = 1.4; // IOR of Clear Coat
			Re = calcFresnelReflectance(rayDirection, nl, nc, nt, ratioIoR);
			Tr = 1.0 - Re;
			
			if (bounces == 0) //(diffuseCount == 0 && hitObjectID != previousObjectID)
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
