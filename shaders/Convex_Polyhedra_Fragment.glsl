precision highp float;
precision highp int;
precision highp sampler2D;

#include <pathtracing_uniforms_and_defines>

uniform mat4 uConvexPolyhedronInvMatrix;
uniform int uMaterialType;
uniform vec3 uMaterialColor;
uniform float uRoughness;

#define N_QUADS 1
#define N_BOXES 1

vec3 rayOrigin, rayDirection;
// recorded intersection data:
vec3 hitNormal, hitEmission, hitColor;
vec2 hitUV;
float hitRoughness;
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

#include <pathtracing_sample_quad_light>

#include <pathtracing_convexpolyhedron_intersect>


vec4 tetrahedron_planes[4];
vec4 rectangularPyramid_planes[5];
vec4 triangularPrism_planes[5];
vec4 cube_planes[6];
vec4 frustum_planes[6];
vec4 hexahedron_planes[6];
vec4 pentagonalPrism_planes[7];
vec4 octahedron_planes[8];
vec4 hexagonalPrism_planes[8];
vec4 dodecahedron_planes[12];
vec4 icosahedron_planes[20];

//---------------------------------------------------------------------------------------
float SceneIntersect( )
//---------------------------------------------------------------------------------------
{
	vec3 rObjOrigin, rObjDirection;
	vec3 n, hitPoint;
	float d;
	float t = INFINITY;
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
			//hitColor = vec3(0.7, 0.05, 0.05);
			hitColor = vec3(1.0, 1.0, 0.05);
		}
		else if (n == vec3(-1,0,0)) // right wall
		{
			//hitColor = vec3(0.05, 0.05, 0.7);
			hitColor = vec3(0.05, 0.05, 0.9);
		}
		
		hitObjectID = float(objectCount);
	}
	objectCount++;


	// TETRAHEDRON - 4 faces
	// transform ray into convexPolyhedron's object space
	rObjOrigin = rayOrigin;
	rObjOrigin += vec3(35, 0, 0);
	rObjOrigin = vec3( uConvexPolyhedronInvMatrix * vec4(rObjOrigin, 1.0) );
	rObjDirection = vec3( uConvexPolyhedronInvMatrix * vec4(rayDirection, 0.0) );
	
	d = ConvexPolyhedron_4faces_Intersect( rObjOrigin, rObjDirection, n, tetrahedron_planes );
	if (d < t)
	{
		t = d;
		hitNormal = transpose(mat3(uConvexPolyhedronInvMatrix)) * n;
		hitEmission = vec3(0);
		hitColor = uMaterialColor;
		hitType = uMaterialType;
		hitObjectID = float(objectCount);
	}
	objectCount++;

	// RECTANGULAR PYRAMID - 5 faces
	// transform ray into convexPolyhedron's object space
	rObjOrigin = rayOrigin;
	rObjOrigin += vec3(0, 0, -37);
	rObjOrigin = vec3( uConvexPolyhedronInvMatrix * vec4(rObjOrigin, 1.0) );
	rObjDirection = vec3( uConvexPolyhedronInvMatrix * vec4(rayDirection, 0.0) );
	
	d = ConvexPolyhedron_5faces_Intersect( rObjOrigin, rObjDirection, n, rectangularPyramid_planes );
	if (d < t)
	{
		t = d;
		hitNormal = transpose(mat3(uConvexPolyhedronInvMatrix)) * n;
		hitEmission = vec3(0);
		hitColor = uMaterialColor;
		hitType = uMaterialType;
		hitObjectID = float(objectCount);
	}
	objectCount++;

	// TRIANGULAR PRISM - 5 faces
	// transform ray into convexPolyhedron's object space
	rObjOrigin = rayOrigin;
	rObjOrigin += vec3(0, 0, 0);
	rObjOrigin = vec3( uConvexPolyhedronInvMatrix * vec4(rObjOrigin, 1.0) );
	rObjDirection = vec3( uConvexPolyhedronInvMatrix * vec4(rayDirection, 0.0) );
	
	d = ConvexPolyhedron_5faces_Intersect( rObjOrigin, rObjDirection, n, triangularPrism_planes );
	if (d < t)
	{
		t = d;
		hitNormal = transpose(mat3(uConvexPolyhedronInvMatrix)) * n;
		hitEmission = vec3(0);
		hitColor = uMaterialColor;
		hitType = uMaterialType;
		hitObjectID = float(objectCount);
	}
	objectCount++;

	// CUBE - 6 faces
	// transform ray into convexPolyhedron's object space
	rObjOrigin = rayOrigin;
	rObjOrigin += vec3(0, 0, 35);
	rObjOrigin = vec3( uConvexPolyhedronInvMatrix * vec4(rObjOrigin, 1.0) );
	rObjDirection = vec3( uConvexPolyhedronInvMatrix * vec4(rayDirection, 0.0) );
	
	d = ConvexPolyhedron_6faces_Intersect( rObjOrigin, rObjDirection, n, cube_planes );
	if (d < t)
	{
		t = d;
		hitNormal = transpose(mat3(uConvexPolyhedronInvMatrix)) * n;
		hitEmission = vec3(0);
		hitColor = uMaterialColor;
		hitType = uMaterialType;
		hitObjectID = float(objectCount);
	}
	objectCount++;

	// FRUSTUM - 6 faces
	// transform ray into convexPolyhedron's object space
	rObjOrigin = rayOrigin;
	rObjOrigin += vec3(-35, 0, 0);
	rObjOrigin = vec3( uConvexPolyhedronInvMatrix * vec4(rObjOrigin, 1.0) );
	rObjDirection = vec3( uConvexPolyhedronInvMatrix * vec4(rayDirection, 0.0) );
	
	d = ConvexPolyhedron_6faces_Intersect( rObjOrigin, rObjDirection, n, frustum_planes );
	if (d < t)
	{
		t = d;
		hitNormal = transpose(mat3(uConvexPolyhedronInvMatrix)) * n;
		hitEmission = vec3(0);
		hitColor = uMaterialColor;
		hitType = uMaterialType;
		hitObjectID = float(objectCount);
	}
	objectCount++;

	// HEXAHEDRON - 6 faces
	// transform ray into convexPolyhedron's object space
	rObjOrigin = rayOrigin;
	rObjOrigin += vec3(-35, 0, -35);
	rObjOrigin = vec3( uConvexPolyhedronInvMatrix * vec4(rObjOrigin, 1.0) );
	rObjDirection = vec3( uConvexPolyhedronInvMatrix * vec4(rayDirection, 0.0) );
	
	d = ConvexPolyhedron_6faces_Intersect( rObjOrigin, rObjDirection, n, hexahedron_planes );
	if (d < t)
	{
		t = d;
		hitNormal = transpose(mat3(uConvexPolyhedronInvMatrix)) * n;
		hitEmission = vec3(0);
		hitColor = uMaterialColor;
		hitType = uMaterialType;
		hitObjectID = float(objectCount);
	}
	objectCount++;

	// PENTAGONAL PRISM - 7 faces
	// transform ray into convexPolyhedron's object space
	rObjOrigin = rayOrigin;
	rObjOrigin += vec3(35, 0, 35);
	rObjOrigin = vec3( uConvexPolyhedronInvMatrix * vec4(rObjOrigin, 1.0) );
	rObjDirection = vec3( uConvexPolyhedronInvMatrix * vec4(rayDirection, 0.0) );
	
	d = ConvexPolyhedron_7faces_Intersect( rObjOrigin, rObjDirection, n, pentagonalPrism_planes );
	if (d < t)
	{
		t = d;
		hitNormal = transpose(mat3(uConvexPolyhedronInvMatrix)) * n;
		hitEmission = vec3(0);
		hitColor = uMaterialColor;
		hitType = uMaterialType;
		hitObjectID = float(objectCount);
	}
	objectCount++;

	// OCTAHEDRON - 8 faces
	// transform ray into convexPolyhedron's object space
	rObjOrigin = rayOrigin;
	rObjOrigin += vec3(35, 0, -35);
	rObjOrigin = vec3( uConvexPolyhedronInvMatrix * vec4(rObjOrigin, 1.0) );
	rObjDirection = vec3( uConvexPolyhedronInvMatrix * vec4(rayDirection, 0.0) );
	
	d = ConvexPolyhedron_8faces_Intersect( rObjOrigin, rObjDirection, n, octahedron_planes );
	if (d < t)
	{
		t = d;
		hitNormal = transpose(mat3(uConvexPolyhedronInvMatrix)) * n;
		hitEmission = vec3(0);
		hitColor = uMaterialColor;
		hitType = uMaterialType;
		hitObjectID = float(objectCount);
	}
	objectCount++;

	// HEXAGONAL PRISM - 8 faces
	// transform ray into convexPolyhedron's object space
	rObjOrigin = rayOrigin;
	rObjOrigin += vec3(-35, 0, 35);
	rObjOrigin = vec3( uConvexPolyhedronInvMatrix * vec4(rObjOrigin, 1.0) );
	rObjDirection = vec3( uConvexPolyhedronInvMatrix * vec4(rayDirection, 0.0) );
	
	d = ConvexPolyhedron_8faces_Intersect( rObjOrigin, rObjDirection, n, hexagonalPrism_planes );
	if (d < t)
	{
		t = d;
		hitNormal = transpose(mat3(uConvexPolyhedronInvMatrix)) * n;
		hitEmission = vec3(0);
		hitColor = uMaterialColor;
		hitType = uMaterialType;
		hitObjectID = float(objectCount);
	}
	objectCount++;

	// DODECAHEDRON - 12 faces
	// transform ray into convexPolyhedron's object space
	rObjOrigin = rayOrigin;
	rObjOrigin += vec3(19, 0, -18);
	rObjOrigin = vec3( uConvexPolyhedronInvMatrix * vec4(rObjOrigin, 1.0) );
	rObjDirection = vec3( uConvexPolyhedronInvMatrix * vec4(rayDirection, 0.0) );
	
	d = ConvexPolyhedron_12faces_Intersect( rObjOrigin, rObjDirection, n, dodecahedron_planes );
	if (d < t)
	{
		t = d;
		hitNormal = transpose(mat3(uConvexPolyhedronInvMatrix)) * n;
		hitEmission = vec3(0);
		hitColor = uMaterialColor;
		hitType = uMaterialType;
		hitObjectID = float(objectCount);
	}
	objectCount++;

	// ICOSAHEDRON - 20 faces
	// transform ray into convexPolyhedron's object space
	rObjOrigin = rayOrigin;
	rObjOrigin += vec3(-18, 0, -18);
	rObjOrigin = vec3( uConvexPolyhedronInvMatrix * vec4(rObjOrigin, 1.0) );
	rObjDirection = vec3( uConvexPolyhedronInvMatrix * vec4(rayDirection, 0.0) );
	
	d = ConvexPolyhedron_20faces_Intersect( rObjOrigin, rObjDirection, n, icosahedron_planes );
	if (d < t)
	{
		t = d;
		hitNormal = transpose(mat3(uConvexPolyhedronInvMatrix)) * n;
		hitEmission = vec3(0);
		hitColor = uMaterialColor;
		hitType = uMaterialType;
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
	vec3 dirToLight;
	vec3 tdir;
	vec3 x, n, nl;
	vec3 absorptionCoefficient;
	
	float t;
	float nc, nt, ratioIoR, Re, Tr;
	//float P, RP, TP;
	float weight;
	float thickness = 0.08;
	float scatteringDistance;
	float previousRoughness = 0.0;

	int diffuseCount = 0;
	int previousIntersecType = -100;
	hitType = -100;

	int coatTypeIntersected = FALSE;
	int bounceIsSpecular = TRUE;
	int sampleLight = FALSE;
	int willNeedReflectionRay = FALSE;
	
	hitRoughness = uRoughness;
	
	for (int bounces = 0; bounces < 6; bounces++)
	{
		previousIntersecType = hitType;
		previousRoughness = hitRoughness;

		t = SceneIntersect();
		

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
		x = rayOrigin + rayDirection * t;

		if (bounces == 0)
		{
			objectNormal = nl;
			objectColor = hitColor;
			objectID = hitObjectID;
		}
		if (bounces == 1 && previousIntersecType == SPEC)
		{
			objectNormal = nl;
		}

		
		
		if (hitType == LIGHT)
		{	
			if (bounces == 0 || (bounces == 1 && previousIntersecType == SPEC && previousRoughness < 0.1))
				pixelSharpness = 1.01;

			if (diffuseCount == 0)
			{
				objectNormal = nl;
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
				rayDirection = randomCosWeightedDirectionInHemisphere(nl);
				rayOrigin = x + nl * uEPS_intersect;
				continue;
			}
			
			dirToLight = sampleQuadLight(x, nl, quads[0], weight);
			mask *= diffuseCount == 1 ? 2.0 : 1.0;
			mask *= weight;

			rayDirection = dirToLight;
			rayOrigin = x + nl * uEPS_intersect;

			sampleLight = TRUE;
			continue;
			
		} // end if (hitType == DIFF)
		
		if (hitType == SPEC)  // Ideal SPECULAR reflection
		{
			mask *= hitColor;

			if (bounces == 0 && rand() >= hitRoughness)
			{
				rayDirection = reflect(rayDirection, nl); // reflect ray from metal surface
				rayDirection = randomDirectionInSpecularLobe(rayDirection, hitRoughness * 0.5);
				rayOrigin = x + nl * uEPS_intersect;
				continue;
			}

			diffuseCount++;
			
			bounceIsSpecular = FALSE;

			if (diffuseCount == 1 && rand() < 0.5)
			{
				mask *= 2.0;
				// choose random Diffuse sample vector
				rayDirection = randomCosWeightedDirectionInHemisphere(nl);
				rayOrigin = x + nl * uEPS_intersect;
				continue;
			}
			
			dirToLight = sampleQuadLight(x, nl, quads[0], weight);
			mask *= diffuseCount == 1 ? 2.0 : 1.0;
			mask *= weight;
			
			rayDirection = dirToLight;
			rayOrigin = x + nl * uEPS_intersect;

			sampleLight = TRUE;
			continue;
		}
		
		if (hitType == REFR)  // Ideal dielectric REFRACTION
		{
			pixelSharpness = diffuseCount == 0 && coatTypeIntersected == FALSE ? -1.0 : pixelSharpness;

			nc = 1.0; // IOR of Air
			nt = 1.5; // IOR of common Glass
			Re = calcFresnelReflectance(rayDirection, n, nc, nt, ratioIoR);
			Tr = 1.0 - Re;

			if (bounces == 0)
			{
				reflectionMask = mask * Re;
				reflectionRayDirection = reflect(rayDirection, nl); // reflect ray from surface
				reflectionRayDirection = randomDirectionInSpecularLobe(reflectionRayDirection, hitRoughness * 0.7);
				reflectionRayOrigin = x + nl * uEPS_intersect;
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
			
			// is ray leaving a solid object from the inside? 
			// If so, attenuate ray color with object color by how far ray has travelled through the medium
			if (distance(n, nl) > 0.1)
			{
				mask *= exp( log(clamp(hitColor, 0.01, 0.99)) * thickness * t ); 
			}

			if (bounces == 0)
				mask *= Tr;
			
			tdir = refract(rayDirection, nl, ratioIoR);
			//rayDirection = tdir;
			rayDirection = randomDirectionInSpecularLobe(tdir, hitRoughness * 0.7);
			rayOrigin = x - nl * uEPS_intersect;

			if (diffuseCount == 1)
				bounceIsSpecular = TRUE; // turn on refracting caustics
			
			continue;
			
		} // end if (hitType == REFR)
		
		if (hitType == COAT)  // Diffuse object underneath with ClearCoat on top
		{
			coatTypeIntersected = TRUE;

			nc = 1.0; // IOR of Air
			nt = 1.4; // IOR of Clear Coat
			Re = calcFresnelReflectance(rayDirection, nl, nc, nt, ratioIoR);
			Tr = 1.0 - Re;
			
			if (bounces == 0 && rand() >= hitRoughness)
			{
				reflectionMask = mask * Re;
				reflectionRayDirection = reflect(rayDirection, nl); // reflect ray from surface
				reflectionRayDirection = randomDirectionInSpecularLobe(reflectionRayDirection, hitRoughness * 0.5);
				reflectionRayOrigin = x + nl * uEPS_intersect;
				willNeedReflectionRay = TRUE;
			}
			else 
				Tr = 1.0;

			diffuseCount++;

			if (bounces == 0)
				mask *= Tr;
			mask *= hitColor;

			bounceIsSpecular = FALSE;
			
			if (diffuseCount == 1 && rand() < 0.5)
			{
				mask *= 2.0;
				// choose random Diffuse sample vector
				rayDirection = randomCosWeightedDirectionInHemisphere(nl);
				rayOrigin = x + nl * uEPS_intersect;
				continue;
			}

			dirToLight = sampleQuadLight(x, nl, quads[0], weight);
			mask *= diffuseCount == 1 ? 2.0 : 1.0;
			mask *= weight;
			
			rayDirection = dirToLight;
			rayOrigin = x + nl * uEPS_intersect;

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
	vec3 L1 = vec3(1.0, 1.0, 1.0) * 5.0;// Bright light
	float wallRadius = 50.0;
	float lightRadius = 10.0;

	// tetrahedron (triangular pyramid)
	tetrahedron_planes[0] = vec4(vec3(-0.5773502588272095, 0.5773502588272095, 0.5773502588272095), 0.5);
	tetrahedron_planes[1] = vec4(vec3( 0.5773502588272095, 0.5773502588272095,-0.5773502588272095), 0.5);
	tetrahedron_planes[2] = vec4(vec3( 0.5773502588272095,-0.5773502588272095, 0.5773502588272095), 0.5);
	tetrahedron_planes[3] = vec4(vec3(-0.5773502588272095,-0.5773502588272095,-0.5773502588272095), 0.5);

	// rectangular pyramid
	rectangularPyramid_planes[0] = vec4(normalize(vec3( 1, 0.5, 0)), 0.4);
	rectangularPyramid_planes[1] = vec4(normalize(vec3(-1, 0.5, 0)), 0.4);
	rectangularPyramid_planes[2] = vec4(normalize(vec3( 0, 0.5, 1)), 0.4);
	rectangularPyramid_planes[3] = vec4(normalize(vec3( 0, 0.5,-1)), 0.4);
	rectangularPyramid_planes[4] = vec4((vec3( 0,-1, 0)), 1.0);

	// triangular prism
	triangularPrism_planes[0] = vec4((vec3( 0, -1, 0)), 0.5);
	triangularPrism_planes[1] = vec4(normalize(vec3( 1, 0.577, 0)), 0.5);
	triangularPrism_planes[2] = vec4(normalize(vec3(-1, 0.577, 0)), 0.5);
	triangularPrism_planes[3] = vec4((vec3( 0, 0, 1)), 1.0);
	triangularPrism_planes[4] = vec4((vec3( 0, 0,-1)), 1.0);

	// cube
	cube_planes[0] = vec4((vec3( 1, 0, 0)), 1.0);
	cube_planes[1] = vec4((vec3(-1, 0, 0)), 1.0);
	cube_planes[2] = vec4((vec3( 0, 1, 0)), 1.0);
	cube_planes[3] = vec4((vec3( 0,-1, 0)), 1.0);
	cube_planes[4] = vec4((vec3( 0, 0, 1)), 1.0);
	cube_planes[5] = vec4((vec3( 0, 0,-1)), 1.0);

	// frustum (rectangular pyramid with apex cut off)
	frustum_planes[0] = vec4(normalize(vec3( 1, 0.35, 0)), 0.6);
	frustum_planes[1] = vec4(normalize(vec3(-1, 0.35, 0)), 0.6);
	frustum_planes[2] = vec4(normalize(vec3( 0, 0.35, 1)), 0.6);
	frustum_planes[3] = vec4(normalize(vec3( 0, 0.35,-1)), 0.6);
	frustum_planes[4] = vec4((vec3( 0, 1, 0)), 1.0);
	frustum_planes[5] = vec4((vec3( 0,-1, 0)), 1.0);

	// hexahedron (triangular bipyramid)
	hexahedron_planes[0] = vec4(normalize(vec3( 1, 0.7, 0.6)), 0.55);
	hexahedron_planes[1] = vec4(normalize(vec3(-1, 0.7, 0.6)), 0.55);
	hexahedron_planes[2] = vec4(normalize(vec3( 0, 0.6,  -1)), 0.55);
	hexahedron_planes[3] = vec4(normalize(vec3( 1,-0.7, 0.6)), 0.55);
	hexahedron_planes[4] = vec4(normalize(vec3(-1,-0.7, 0.6)), 0.55);
	hexahedron_planes[5] = vec4(normalize(vec3( 0,-0.6,  -1)), 0.55);

	// pentagonal prism
	pentagonalPrism_planes[0] = vec4(normalize(vec3(cos(TWO_PI * 0.15), sin(TWO_PI * 0.15), 0)), 0.8);
	pentagonalPrism_planes[1] = vec4(normalize(vec3(cos(TWO_PI * 0.35), sin(TWO_PI * 0.35), 0)), 0.8);
	pentagonalPrism_planes[2] = vec4(normalize(vec3(cos(TWO_PI * 0.55), sin(TWO_PI * 0.55), 0)), 0.8);
	pentagonalPrism_planes[3] = vec4(normalize(vec3(cos(TWO_PI * 0.75), sin(TWO_PI * 0.75), 0)), 0.8);
	pentagonalPrism_planes[4] = vec4(normalize(vec3(cos(TWO_PI * 0.95), sin(TWO_PI * 0.95), 0)), 0.8);
	pentagonalPrism_planes[5] = vec4((vec3(0, 0, 1)), 1.0);
	pentagonalPrism_planes[6] = vec4((vec3(0, 0,-1)), 1.0);

	// octahedron (rectangular bipyramid) 
	octahedron_planes[0] = vec4(vec3( 0.5773502588272095, 0.5773502588272095, 0.5773502588272095), 0.6);
	octahedron_planes[1] = vec4(vec3( 0.5773502588272095,-0.5773502588272095, 0.5773502588272095), 0.6);
	octahedron_planes[2] = vec4(vec3( 0.5773502588272095,-0.5773502588272095,-0.5773502588272095), 0.6);
	octahedron_planes[3] = vec4(vec3( 0.5773502588272095, 0.5773502588272095,-0.5773502588272095), 0.6);
	octahedron_planes[4] = vec4(vec3(-0.5773502588272095, 0.5773502588272095,-0.5773502588272095), 0.6);
	octahedron_planes[5] = vec4(vec3(-0.5773502588272095,-0.5773502588272095,-0.5773502588272095), 0.6);
	octahedron_planes[6] = vec4(vec3(-0.5773502588272095,-0.5773502588272095, 0.5773502588272095), 0.6);
	octahedron_planes[7] = vec4(vec3(-0.5773502588272095, 0.5773502588272095, 0.5773502588272095), 0.6);

	// hexagonal prism
	hexagonalPrism_planes[0] = vec4((vec3( 0, 1, 0)), 0.9);
	hexagonalPrism_planes[1] = vec4((vec3( 0,-1, 0)), 0.9);
	hexagonalPrism_planes[2] = vec4(normalize(vec3( 1, 0.57735, 0)), 0.9);
	hexagonalPrism_planes[3] = vec4(normalize(vec3( 1,-0.57735, 0)), 0.9);
	hexagonalPrism_planes[4] = vec4(normalize(vec3(-1, 0.57735, 0)), 0.9);
	hexagonalPrism_planes[5] = vec4(normalize(vec3(-1,-0.57735, 0)), 0.9);
	hexagonalPrism_planes[6] = vec4((vec3(0, 0, 1)), 1.0);
	hexagonalPrism_planes[7] = vec4((vec3(0, 0,-1)), 1.0);

	// dodecahedron
	dodecahedron_planes[ 0] = vec4(vec3(0, 0.8506507873535156, 0.525731086730957), 0.9);
	dodecahedron_planes[ 1] = vec4(vec3(0.8506507873535156, 0.525731086730957, 0), 0.9);
	dodecahedron_planes[ 2] = vec4(vec3(0.525731086730957, 0, -0.8506508469581604), 0.9);
	dodecahedron_planes[ 3] = vec4(vec3(-0.525731086730957, 0, -0.8506508469581604), 0.9);
	dodecahedron_planes[ 4] = vec4(vec3(-0.8506507873535156, -0.525731086730957, 0), 0.9);
	dodecahedron_planes[ 5] = vec4(vec3(0, 0.8506507873535156, -0.525731086730957), 0.9);
	dodecahedron_planes[ 6] = vec4(vec3(-0.8506508469581604, 0.525731086730957, 0), 0.9);
	dodecahedron_planes[ 7] = vec4(vec3(-0.525731086730957, 0, 0.8506508469581604), 0.9);
	dodecahedron_planes[ 8] = vec4(vec3(0, -0.8506508469581604, -0.525731086730957), 0.9);
	dodecahedron_planes[ 9] = vec4(vec3(0.525731086730957, 0, 0.8506508469581604), 0.9);
	dodecahedron_planes[10] = vec4(vec3(0.8506508469581604, -0.525731086730957, 0), 0.9);
	dodecahedron_planes[11] = vec4(vec3(0, -0.8506508469581604, 0.525731086730957), 0.9);

	// icosahedron
	icosahedron_planes[ 0] = vec4(vec3(-0.5773502588272095, 0.5773502588272095, 0.5773502588272095), 0.9);
	icosahedron_planes[ 1] = vec4(vec3(0, 0.9341723322868347, 0.35682210326194763), 0.9);
	icosahedron_planes[ 2] = vec4(vec3(0, 0.9341723322868347, -0.35682210326194763), 0.9);
	icosahedron_planes[ 3] = vec4(vec3(-0.5773502588272095, 0.5773502588272095, -0.5773502588272095), 0.9);
	icosahedron_planes[ 4] = vec4(vec3(-0.9341723322868347, 0.35682210326194763, 0), 0.9);
	icosahedron_planes[ 5] = vec4(vec3(0.5773502588272095, 0.5773502588272095, 0.5773502588272095), 0.9);
	icosahedron_planes[ 6] = vec4(vec3(-0.35682210326194763, 0, 0.9341723322868347), 0.9);
	icosahedron_planes[ 7] = vec4(vec3(-0.9341723322868347, -0.35682210326194763, 0), 0.9);
	icosahedron_planes[ 8] = vec4(vec3(-0.35682210326194763, 0, -0.9341723322868347), 0.9);
	icosahedron_planes[ 9] = vec4(vec3(0.5773502588272095, 0.5773502588272095, -0.5773502588272095), 0.9);
	icosahedron_planes[10] = vec4(vec3(0.5773502588272095, -0.5773502588272095, 0.5773502588272095), 0.9);
	icosahedron_planes[11] = vec4(vec3(0, -0.9341723322868347, 0.35682210326194763), 0.9);
	icosahedron_planes[12] = vec4(vec3(0, -0.9341723322868347, -0.35682210326194763), 0.9);
	icosahedron_planes[13] = vec4(vec3(0.5773502588272095, -0.5773502588272095, -0.5773502588272095), 0.9);
	icosahedron_planes[14] = vec4(vec3(0.9341723322868347, -0.35682210326194763, 0), 0.9);
	icosahedron_planes[15] = vec4(vec3(0.35682210326194763, 0, 0.9341723322868347), 0.9);
	icosahedron_planes[16] = vec4(vec3(-0.5773502588272095, -0.5773502588272095, 0.5773502588272095), 0.9);
	icosahedron_planes[17] = vec4(vec3(-0.5773502588272095, -0.5773502588272095, -0.5773502588272095), 0.9);
	icosahedron_planes[18] = vec4(vec3(0.35682210326194763, 0, -0.9341723322868347), 0.9);
	icosahedron_planes[19] = vec4(vec3(0.9341723322868347, 0.35682210326194763, 0), 0.9);
	

	
	quads[0] = Quad( vec3(0,-1, 0), vec3(-lightRadius, wallRadius-1.0,-lightRadius), vec3(lightRadius, wallRadius-1.0,-lightRadius), vec3(lightRadius, wallRadius-1.0, lightRadius), vec3(-lightRadius, wallRadius-1.0, lightRadius), L1, z, LIGHT);// Quad Area Light on ceiling

	boxes[0] = Box( vec3(-wallRadius), vec3(wallRadius), z, vec3(1), DIFF);// the Cornell Box interior
}


#include <pathtracing_main>
