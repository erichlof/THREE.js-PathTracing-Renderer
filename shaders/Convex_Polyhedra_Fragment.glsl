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
vec4 planes[20];

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

	// must first initialize all planes to 0, otherwise garbage values might be loaded and used (especially on mobile)
	planes[0] = planes[1] = planes[2] = planes[3] = planes[4] = 
	planes[5] = planes[6] = planes[7] = planes[8] = planes[9] = 
	planes[10] = planes[11] = planes[12] = planes[13] = planes[14] = 
	planes[15] = planes[16] = planes[17] = planes[18] = planes[19] = vec4(0);
	
	// TETRAHEDRON - 4 faces
	// transform ray into convexPolyhedron's object space
	rObjOrigin = rayOrigin;
	rObjOrigin += vec3(35, 0, 0);
	rObjOrigin = vec3( uConvexPolyhedronInvMatrix * vec4(rObjOrigin, 1.0) );
	rObjDirection = vec3( uConvexPolyhedronInvMatrix * vec4(rayDirection, 0.0) );

	planes[0] = tetrahedron_planes[0];
	planes[1] = tetrahedron_planes[1];
	planes[2] = tetrahedron_planes[2];
	planes[3] = tetrahedron_planes[3];
	
	d = ConvexPolyhedronIntersect( rObjOrigin, rObjDirection, n, 4, planes );
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
	
	planes[0] = rectangularPyramid_planes[0];
	planes[1] = rectangularPyramid_planes[1];
	planes[2] = rectangularPyramid_planes[2];
	planes[3] = rectangularPyramid_planes[3];
	planes[4] = rectangularPyramid_planes[4];

	d = ConvexPolyhedronIntersect( rObjOrigin, rObjDirection, n, 5, planes );
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

	planes[0] = triangularPrism_planes[0];
	planes[1] = triangularPrism_planes[1];
	planes[2] = triangularPrism_planes[2];
	planes[3] = triangularPrism_planes[3];
	planes[4] = triangularPrism_planes[4];
	
	d = ConvexPolyhedronIntersect( rObjOrigin, rObjDirection, n, 5, planes );
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

	planes[0] = cube_planes[0];
	planes[1] = cube_planes[1];
	planes[2] = cube_planes[2];
	planes[3] = cube_planes[3];
	planes[4] = cube_planes[4];
	planes[5] = cube_planes[5];
	
	d = ConvexPolyhedronIntersect( rObjOrigin, rObjDirection, n, 6, planes );
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
	
	planes[0] = frustum_planes[0];
	planes[1] = frustum_planes[1];
	planes[2] = frustum_planes[2];
	planes[3] = frustum_planes[3];
	planes[4] = frustum_planes[4];
	planes[5] = frustum_planes[5];

	d = ConvexPolyhedronIntersect( rObjOrigin, rObjDirection, n, 6, planes );
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
	
	planes[0] = hexahedron_planes[0];
	planes[1] = hexahedron_planes[1];
	planes[2] = hexahedron_planes[2];
	planes[3] = hexahedron_planes[3];
	planes[4] = hexahedron_planes[4];
	planes[5] = hexahedron_planes[5];

	d = ConvexPolyhedronIntersect( rObjOrigin, rObjDirection, n, 6, planes );
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
	
	planes[0] = pentagonalPrism_planes[0];
	planes[1] = pentagonalPrism_planes[1];
	planes[2] = pentagonalPrism_planes[2];
	planes[3] = pentagonalPrism_planes[3];
	planes[4] = pentagonalPrism_planes[4];
	planes[5] = pentagonalPrism_planes[5];
	planes[6] = pentagonalPrism_planes[6];

	d = ConvexPolyhedronIntersect( rObjOrigin, rObjDirection, n, 7, planes );
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

	planes[0] = octahedron_planes[0];
	planes[1] = octahedron_planes[1];
	planes[2] = octahedron_planes[2];
	planes[3] = octahedron_planes[3];
	planes[4] = octahedron_planes[4];
	planes[5] = octahedron_planes[5];
	planes[6] = octahedron_planes[6];
	planes[7] = octahedron_planes[7];
	
	d = ConvexPolyhedronIntersect( rObjOrigin, rObjDirection, n, 8, planes );
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

	planes[0] = hexagonalPrism_planes[0];
	planes[1] = hexagonalPrism_planes[1];
	planes[2] = hexagonalPrism_planes[2];
	planes[3] = hexagonalPrism_planes[3];
	planes[4] = hexagonalPrism_planes[4];
	planes[5] = hexagonalPrism_planes[5];
	planes[6] = hexagonalPrism_planes[6];
	planes[7] = hexagonalPrism_planes[7];
	
	d = ConvexPolyhedronIntersect( rObjOrigin, rObjDirection, n, 8, planes );
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

	planes[0] = dodecahedron_planes[0];
	planes[1] = dodecahedron_planes[1];
	planes[2] = dodecahedron_planes[2];
	planes[3] = dodecahedron_planes[3];
	planes[4] = dodecahedron_planes[4];
	planes[5] = dodecahedron_planes[5];
	planes[6] = dodecahedron_planes[6];
	planes[7] = dodecahedron_planes[7];
	planes[8] = dodecahedron_planes[8];
	planes[9] = dodecahedron_planes[9];
	planes[10] = dodecahedron_planes[10];
	planes[11] = dodecahedron_planes[11];
	
	d = ConvexPolyhedronIntersect( rObjOrigin, rObjDirection, n, 12, planes );
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
	
	planes[0] = icosahedron_planes[0];
	planes[1] = icosahedron_planes[1];
	planes[2] = icosahedron_planes[2];
	planes[3] = icosahedron_planes[3];
	planes[4] = icosahedron_planes[4];
	planes[5] = icosahedron_planes[5];
	planes[6] = icosahedron_planes[6];
	planes[7] = icosahedron_planes[7];
	planes[8] = icosahedron_planes[8];
	planes[9] = icosahedron_planes[9];
	planes[10] = icosahedron_planes[10];
	planes[11] = icosahedron_planes[11];
	planes[12] = icosahedron_planes[12];
	planes[13] = icosahedron_planes[13];
	planes[14] = icosahedron_planes[14];
	planes[15] = icosahedron_planes[15];
	planes[16] = icosahedron_planes[16];
	planes[17] = icosahedron_planes[17];
	planes[18] = icosahedron_planes[18];
	planes[19] = icosahedron_planes[19];

	d = ConvexPolyhedronIntersect( rObjOrigin, rObjDirection, n, 20, planes );
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
	vec3 tdir;
	vec3 x, n, nl;
	vec3 absorptionCoefficient;
	
	float t;
	float nc, nt, ratioIoR, Re, Tr;
	float weight;
	float thickness = 0.08;
	float scatteringDistance;
	float previousRoughness = 0.0;
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
	
	hitRoughness = uRoughness;
	
	for (int bounces = 0; bounces < 10; bounces++)
	{
		if (isReflectionTime == TRUE)
			reflectionBounces++;

		previousIntersecType = hitType;
		previousRoughness = hitRoughness;
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
			//objectID += hitObjectID;
		}
		if (reflectionNeedsToBeSharp == TRUE && reflectionBounces == 0)
		{
			objectNormal += n;
			//objectColor += hitColor;
			objectID += hitObjectID;
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
                        
			rayDirection = sampleQuadLight(x, nl, quads[0], weight);
			mask *= weight;
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
		}
		
		if (hitType == REFR)  // Ideal dielectric REFRACTION
		{
			nc = 1.0; // IOR of Air
			nt = 1.5; // IOR of common Glass
			Re = calcFresnelReflectance(rayDirection, n, nc, nt, ratioIoR);
			Tr = 1.0 - Re;

			if (bounces == 0 && n == nl)
			{
				reflectionMask = mask * Re;
				reflectionRayDirection = reflect(rayDirection, nl); // reflect ray from surface
				reflectionRayDirection = randomDirectionInSpecularLobe(reflectionRayDirection, hitRoughness * 0.7);
				reflectionRayOrigin = x + nl * uEPS_intersect;
				willNeedReflectionRay = TRUE;
			}

			if (Re == 1.0)
			{
				rayDirection = reflect(rayDirection, nl);
				rayOrigin = x + nl * uEPS_intersect;
				continue;
			}

			// transmit ray through surface
			
			// is ray leaving a solid object from the inside? 
			// If so, attenuate ray color with object color by how far ray has travelled through the medium
			if (n != nl)
			{
				mask *= exp( log(clamp(hitColor, 0.01, 0.99)) * thickness * t ); 
			}
			else
				mask *= hitColor;
			
			mask *= Tr;
			
			tdir = refract(rayDirection, nl, ratioIoR);
			rayDirection = randomDirectionInSpecularLobe(tdir, hitRoughness * 0.7);
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
			
			if (bounces == 0 && rand() >= hitRoughness)
			{
				reflectionMask = mask * Re;
				reflectionRayDirection = reflect(rayDirection, nl); // reflect ray from surface
				reflectionRayDirection = randomDirectionInSpecularLobe(reflectionRayDirection, hitRoughness * 0.5);
				reflectionRayOrigin = x + nl * uEPS_intersect;
				willNeedReflectionRay = TRUE;
				if (hitRoughness == 0.0)
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
