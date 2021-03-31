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


#define N_QUADS 6


//-----------------------------------------------------------------------

struct Ray { vec3 origin; vec3 direction; };
struct Quad { vec3 normal; vec3 v0; vec3 v1; vec3 v2; vec3 v3; vec3 emission; vec3 color; int type; };
struct Intersection { vec3 normal; vec3 emission; vec3 color; int type; };


Quad quads[N_QUADS];

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

#include <pathtracing_sample_quad_light>



//--------------------------------------------------------------------------
float SceneIntersect(Ray r, inout Intersection intersec)
//--------------------------------------------------------------------------
{
	Ray rObj; 
	vec3 n, A_n0, A_n1, B_n0, B_n1, n0, n1;
	vec3 A_color, B_color, color0, color1;
	vec3 hit;
	float A_t0 = 0.0;
	float A_t1 = 0.0;
	float B_t0 = 0.0; 
	float B_t1 = 0.0;
	float t0 = 0.0;
	float t1 = 0.0;
	float d = INFINITY;
	float t = INFINITY;
	int A_type, B_type, type0, type1;


	for (int i = 0; i < N_QUADS; i++)
        {
		d = QuadIntersect( quads[i].v0, quads[i].v1, quads[i].v2, quads[i].v3, r, false );
		if (d < t)
		{
			t = d;
			intersec.normal = normalize(quads[i].normal);
			intersec.emission = quads[i].emission;
			intersec.color = quads[i].color;
			intersec.type = quads[i].type;
		}
        }


	// SHAPE A
	// transform ray into CSG_Shape1's object space
	rObj.origin = vec3( uCSG_ShapeA_InvMatrix * vec4(r.origin, 1.0) );
	rObj.direction = vec3( uCSG_ShapeA_InvMatrix * vec4(r.direction, 0.0) );
	if (uShapeAType == 0)
		Sphere_CSG_Intersect( rObj.origin, rObj.direction, A_t0, A_t1, A_n0, A_n1 );
	else if (uShapeAType == 1)
		Cylinder_CSG_Intersect( rObj.origin, rObj.direction, A_t0, A_t1, A_n0, A_n1 );
	else if (uShapeAType == 2)
		Cone_CSG_Intersect( uA_kParameter, rObj.origin, rObj.direction, A_t0, A_t1, A_n0, A_n1 );
	else if (uShapeAType == 3)
		Paraboloid_CSG_Intersect( rObj.origin, rObj.direction, A_t0, A_t1, A_n0, A_n1 );
	else if (uShapeAType == 4)
		Hyperboloid1Sheet_CSG_Intersect( uA_kParameter, rObj.origin, rObj.direction, A_t0, A_t1, A_n0, A_n1 );
	else if (uShapeAType == 5)
		Hyperboloid2Sheets_CSG_Intersect( uA_kParameter, rObj.origin, rObj.direction, A_t0, A_t1, A_n0, A_n1 );
	else if (uShapeAType == 6) 
		Capsule_CSG_Intersect( uA_kParameter, rObj.origin, rObj.direction, A_t0, A_t1, A_n0, A_n1 );
	else if (uShapeAType == 7)
		Box_CSG_Intersect( rObj.origin, rObj.direction, A_t0, A_t1, A_n0, A_n1 );
	else if (uShapeAType == 8)
		PyramidFrustum_CSG_Intersect( uA_kParameter, rObj.origin, rObj.direction, A_t0, A_t1, A_n0, A_n1 );
	else if (uShapeAType == 9)
		ConicalPrism_CSG_Intersect( uA_kParameter, rObj.origin, rObj.direction, A_t0, A_t1, A_n0, A_n1 );
	else if (uShapeAType == 10)
		ParabolicPrism_CSG_Intersect( rObj.origin, rObj.direction, A_t0, A_t1, A_n0, A_n1 );
	else if (uShapeAType == 11)
		HyperbolicPrism1Sheet_CSG_Intersect( uA_kParameter, rObj.origin, rObj.direction, A_t0, A_t1, A_n0, A_n1 );
	else //if (uShapeAType == 12)
		HyperbolicPrism2Sheets_CSG_Intersect( uA_kParameter, rObj.origin, rObj.direction, A_t0, A_t1, A_n0, A_n1 );

	n = normalize(A_n0);
	A_n0 = normalize(transpose(mat3(uCSG_ShapeA_InvMatrix)) * n);
	n = normalize(A_n1);
	A_n1 = normalize(transpose(mat3(uCSG_ShapeA_InvMatrix)) * n);
	

	// SHAPE B
	// transform ray into CSG_ShapeB's object space
	rObj.origin = vec3( uCSG_ShapeB_InvMatrix * vec4(r.origin, 1.0) );
	rObj.direction = vec3( uCSG_ShapeB_InvMatrix * vec4(r.direction, 0.0) );
	if (uShapeBType == 0)
		Sphere_CSG_Intersect( rObj.origin, rObj.direction, B_t0, B_t1, B_n0, B_n1 );
	else if (uShapeBType == 1)
		Cylinder_CSG_Intersect( rObj.origin, rObj.direction, B_t0, B_t1, B_n0, B_n1 );
	else if (uShapeBType == 2)
		Cone_CSG_Intersect( uB_kParameter, rObj.origin, rObj.direction, B_t0, B_t1, B_n0, B_n1 );
	else if (uShapeBType == 3)
		Paraboloid_CSG_Intersect( rObj.origin, rObj.direction, B_t0, B_t1, B_n0, B_n1 );
	else if (uShapeBType == 4)
		Hyperboloid1Sheet_CSG_Intersect( uB_kParameter, rObj.origin, rObj.direction, B_t0, B_t1, B_n0, B_n1 );
	else if (uShapeBType == 5)
		Hyperboloid2Sheets_CSG_Intersect( uB_kParameter, rObj.origin, rObj.direction, B_t0, B_t1, B_n0, B_n1 );
	else if (uShapeBType == 6)
		Capsule_CSG_Intersect( uB_kParameter, rObj.origin, rObj.direction, B_t0, B_t1, B_n0, B_n1 );
	else if (uShapeBType == 7)
		Box_CSG_Intersect( rObj.origin, rObj.direction, B_t0, B_t1, B_n0, B_n1 );
	else if (uShapeBType == 8)
		PyramidFrustum_CSG_Intersect( uB_kParameter, rObj.origin, rObj.direction, B_t0, B_t1, B_n0, B_n1 );
	else if (uShapeBType == 9)
		ConicalPrism_CSG_Intersect( uB_kParameter, rObj.origin, rObj.direction, B_t0, B_t1, B_n0, B_n1 );
	else if (uShapeBType == 10)
		ParabolicPrism_CSG_Intersect( rObj.origin, rObj.direction, B_t0, B_t1, B_n0, B_n1 );
	else if (uShapeBType == 11)
		HyperbolicPrism1Sheet_CSG_Intersect( uB_kParameter, rObj.origin, rObj.direction, B_t0, B_t1, B_n0, B_n1 );
	else //if (uShapeBType == 12)
		HyperbolicPrism2Sheets_CSG_Intersect( uB_kParameter, rObj.origin, rObj.direction, B_t0, B_t1, B_n0, B_n1 );

	n = normalize(B_n0);
	B_n0 = normalize(transpose(mat3(uCSG_ShapeB_InvMatrix)) * n);
	n = normalize(B_n1);
	B_n1 = normalize(transpose(mat3(uCSG_ShapeB_InvMatrix)) * n);

	
	A_color = uMaterialAColor;
	A_type = uMaterialAType;
	B_color = uMaterialBColor;
	B_type = uMaterialBType;

	// reset t0 and t1
	t0 = t1 = 0.0;
	if (uCSG_OperationType == 0)
	CSG_Union_Operation( A_t0, A_n0, A_t1, A_n1, B_t0, B_n0, B_t1, B_n1, A_type, A_color, B_type, B_color,// <-- this line = input surfaces data
				t0, n0, t1, n1, type0, color0, type1, color1 ); // <-- this line = resulting csg operation data output
	else if (uCSG_OperationType == 1)
	CSG_Difference_Operation( A_t0, A_n0, A_t1, A_n1, B_t0, B_n0, B_t1, B_n1, A_type, A_color, B_type, B_color,// <-- this line = input surfaces data
				t0, n0, t1, n1, type0, color0, type1, color1 ); // <-- this line = resulting csg operation data output
	else
	CSG_Intersection_Operation( A_t0, A_n0, A_t1, A_n1, B_t0, B_n0, B_t1, B_n1, A_type, A_color, B_type, B_color,// <-- this line = input surfaces data
				t0, n0, t1, n1, type0, color0, type1, color1 ); // <-- this line = resulting csg operation data output
	
	// compare the resulting intersection pair (t0/t1) with the rest of the scene and update data if we get a closer t value
	
	if (t0 > 0.0 && t0 < t)
	{
		t = t0;
		intersec.normal = normalize(n0);
		intersec.emission = vec3(0);
		intersec.color = color0;
		intersec.type = type0;
	}
	else if (t1 > 0.0 && t1 < t)
	{
		t = t1;
		intersec.normal = normalize(n1);
		intersec.emission = vec3(0);
		intersec.color = color1;
		intersec.type = type1;
	}


	return t;
}


//-----------------------------------------------------------------------
vec3 CalculateRadiance(Ray r)
//-----------------------------------------------------------------------
{
	Intersection intersec;
	Quad light = quads[5];

	vec3 accumCol = vec3(0);
        vec3 mask = vec3(1);
	vec3 dirToLight;
	vec3 tdir;
	vec3 x, n, nl;
        
	float t = INFINITY;
	float nc, nt, ratioIoR, Re, Tr;
	float P, RP, TP;
	float weight;

	int diffuseCount = 0;

	bool bounceIsSpecular = true;
	bool sampleLight = false;

	
	for (int bounces = 0; bounces < 6; bounces++)
	{

		t = SceneIntersect(r, intersec);
		

		if (t == INFINITY)	
			break;
		
		
		if (intersec.type == LIGHT)
		{	
			if (bounceIsSpecular || sampleLight)
				accumCol = mask * intersec.emission;
			// reached a light, so we can exit
			break;

		} // end if (intersec.type == LIGHT)


		// if we get here and sampleLight is still true, shadow ray failed to find a light source
		if (sampleLight)	
			break;
		

		// useful data 
		n = normalize(intersec.normal);
                nl = dot(n, r.direction) < 0.0 ? normalize(n) : normalize(-n);
		x = r.origin + r.direction * t;

		    
                if (intersec.type == DIFF) // Ideal DIFFUSE reflection
		{
			diffuseCount++;

			mask *= intersec.color;

			bounceIsSpecular = false;

			if (diffuseCount == 1 && rand() < 0.5)
			{
				r = Ray( x, randomCosWeightedDirectionInHemisphere(nl) );
				r.origin += nl * uEPS_intersect;
				continue;
			}
                        
			dirToLight = sampleQuadLight(x, nl, quads[5], weight);
			mask *= weight;

			r = Ray( x, dirToLight );
			r.origin += nl * uEPS_intersect;

			sampleLight = true;
			continue;
                        
		} // end if (intersec.type == DIFF)
		
		if (intersec.type == SPEC)  // Ideal SPECULAR reflection
		{
			mask *= intersec.color;

			r = Ray( x, reflect(r.direction, nl) );
			r.origin += nl * uEPS_intersect;

			continue;
		}
		
		if (intersec.type == REFR)  // Ideal dielectric REFRACTION
		{
			nc = 1.0; // IOR of Air
			nt = 1.5; // IOR of common Glass
			Re = calcFresnelReflectance(r.direction, n, nc, nt, ratioIoR);
			Tr = 1.0 - Re;
			P  = 0.25 + (0.5 * Re);
                	RP = Re / P;
                	TP = Tr / (1.0 - P);
			
			if (rand() < P)
			{
				mask *= RP;
				r = Ray( x, reflect(r.direction, nl) ); // reflect ray from surface
				r.origin += nl * uEPS_intersect;
				continue;
			}

			// transmit ray through surface
			mask *= intersec.color;
			mask *= TP;

			tdir = refract(r.direction, nl, ratioIoR);
			r = Ray(x, tdir);
			r.origin -= nl * uEPS_intersect;

			if (diffuseCount == 1)
				bounceIsSpecular = true; // turn on refracting caustics

			continue;
			
		} // end if (intersec.type == REFR)
		
		if (intersec.type == COAT)  // Diffuse object underneath with ClearCoat on top
		{
			nc = 1.0; // IOR of Air
			nt = 1.4; // IOR of Clear Coat
			Re = calcFresnelReflectance(r.direction, n, nc, nt, ratioIoR);
			Tr = 1.0 - Re;
			P  = 0.25 + (0.5 * Re);
                	RP = Re / P;
                	TP = Tr / (1.0 - P);

			if (rand() < P)
			{
				mask *= RP;
				r = Ray( x, reflect(r.direction, nl) ); // reflect ray from surface
				r.origin += nl * uEPS_intersect;
				continue;
			}

			diffuseCount++;
			mask *= TP;
			mask *= intersec.color;

			bounceIsSpecular = false;
			
			if (diffuseCount == 1 && rand() < 0.5)
			{
				// choose random Diffuse sample vector
				r = Ray( x, randomCosWeightedDirectionInHemisphere(nl) );
				r.origin += nl * uEPS_intersect;
				continue;
			}

			dirToLight = sampleQuadLight(x, nl, quads[5], weight);
			mask *= weight;
			
			r = Ray( x, dirToLight );
			r.origin += nl * uEPS_intersect;

			sampleLight = true;
			continue;
			
		} //end if (intersec.type == COAT)
		
	} // end for (int bounces = 0; bounces < 6; bounces++)
	
	
	return max(vec3(0), accumCol);

} // end vec3 CalculateRadiance(Ray r)



//-----------------------------------------------------------------------
void SetupScene(void)
//-----------------------------------------------------------------------
{
	vec3 z  = vec3(0);// No color value, Black        
	vec3 L1 = vec3(1.0, 1.0, 1.0) * 8.0;// Bright light
	
	float wallRadius = 50.0;
	quads[0] = Quad( vec3(0,0,1), vec3(-wallRadius,-wallRadius,-wallRadius), vec3(wallRadius,-wallRadius,-wallRadius), vec3(wallRadius, wallRadius,-wallRadius), vec3(-wallRadius, wallRadius,-wallRadius), z, vec3(1), DIFF);// Back Wall
	quads[1] = Quad( vec3(1,0,0), vec3(-wallRadius,-wallRadius,wallRadius), vec3(-wallRadius,-wallRadius,-wallRadius), vec3(-wallRadius, wallRadius,-wallRadius), vec3(-wallRadius, wallRadius,wallRadius), z, vec3(0.7, 0.05, 0.05), DIFF);// Left Wall Red
	quads[2] = Quad( vec3(-1,0,0), vec3(wallRadius,-wallRadius,-wallRadius), vec3(wallRadius,-wallRadius,wallRadius), vec3(wallRadius, wallRadius,wallRadius), vec3(wallRadius, wallRadius,-wallRadius), z, vec3(0.05, 0.05, 0.7), DIFF);// Right Wall Blue
	quads[3] = Quad( vec3(0,-1,0), vec3(-wallRadius, wallRadius,-wallRadius), vec3(wallRadius, wallRadius,-wallRadius), vec3(wallRadius, wallRadius,wallRadius), vec3(-wallRadius, wallRadius,wallRadius), z, vec3(1), DIFF);// Ceiling
	quads[4] = Quad( vec3(0,1,0), vec3(-wallRadius,-wallRadius,wallRadius), vec3(wallRadius,-wallRadius,wallRadius), vec3(wallRadius,-wallRadius,-wallRadius), vec3(-wallRadius,-wallRadius,-wallRadius), z, vec3(1), DIFF);// Floor

	quads[5] = Quad( vec3(0,-1,0), vec3(-wallRadius*0.3, wallRadius-1.0,-wallRadius*0.3), vec3(wallRadius*0.3, wallRadius-1.0,-wallRadius*0.3), vec3(wallRadius*0.3, wallRadius-1.0,wallRadius*0.3), vec3(-wallRadius*0.3, wallRadius-1.0,wallRadius*0.3), L1, z, LIGHT);// Area Light Rectangle in ceiling	
}


#include <pathtracing_main>
