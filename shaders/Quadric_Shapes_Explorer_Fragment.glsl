precision highp float;
precision highp int;
precision highp sampler2D;

#include <pathtracing_uniforms_and_defines>

uniform mat4 uQuadricShapePresetMatrix;
uniform mat4 uQuadricShapeInvMatrix;
uniform vec3 uLeftSphereColor;
uniform vec3 uRightSphereColor;
uniform float uLeftSphereMaterialType;
uniform float uRightSphereMaterialType;

#define N_QUADS 1
#define N_BOXES 1

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

#include <pathtracing_quadric_intersect>

#include <pathtracing_quad_intersect>

#include <pathtracing_box_interior_intersect>

#include <pathtracing_sample_quad_light>


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

	
	d = QuadIntersect( quads[0].v0, quads[0].v1, quads[0].v2, quads[0].v3, rayOrigin, rayDirection, false );
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
	

	// transform ray into Tall Box's object space
	rObjOrigin = vec3( uQuadricShapeInvMatrix * vec4(rayOrigin, 1.0) );
	rObjDirection = vec3( uQuadricShapeInvMatrix * vec4(rayDirection, 0.0) );

	d = QuadricIntersect(uQuadricShapePresetMatrix, vec4(rObjOrigin, 1.0), vec4(rObjDirection, 0.0));
	hitPoint = rObjOrigin + d * rObjDirection;
    
    	//constrain to a box
	if ( d < t)// && all(greaterThanEqual(hitPoint, vec3(-0.5 - QUADRIC_EPSILON))) && all(lessThanEqual(hitPoint, vec3( 0.5 + QUADRIC_EPSILON))) )
	{
		t = d;
		hitNormal = vec3(uQuadricShapePresetMatrix * vec4(hitPoint, 1.0)).xyz;
		hitNormal = transpose(mat3(uQuadricShapeInvMatrix)) * hitNormal;
		hitEmission = vec3(0);
		hitColor = vec3(1,0,1);
		hitType = COAT;
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
	vec3 dirToLight;
	vec3 tdir;
	vec3 x, n, nl;
	vec3 absorptionCoefficient;
	
	float t;
	float nc, nt, ratioIoR, Re, Tr;
	float P, RP, TP;
	float weight;
	float thickness = 0.05;
	float scatteringDistance;

	int diffuseCount = 0;
	int previousIntersecType = -100;
	hitType = -100;

	bool coatTypeIntersected = false;
	bool bounceIsSpecular = true;
	bool sampleLight = false;
	

	
	for (int bounces = 0; bounces < 6; bounces++)
	{
		previousIntersecType = hitType;

		t = SceneIntersect();
		

		if (t == INFINITY)	
			break;

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
			if (diffuseCount == 0)
				pixelSharpness = 1.01;
			
			if (bounceIsSpecular || sampleLight)
				accumCol = mask * hitEmission;
			// reached a light, so we can exit
			break;

		} // end if (hitType == LIGHT)


		// if we get here and sampleLight is still true, shadow ray failed to find a light source
		if (sampleLight)	
			break;
		

		    
		if (hitType == DIFF) // Ideal DIFFUSE reflection
		{
			diffuseCount++;

			mask *= hitColor;

			bounceIsSpecular = false;

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

			sampleLight = true;
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
			pixelSharpness = diffuseCount == 0 ? -1.0 : pixelSharpness;

			nc = 1.0; // IOR of Air
			nt = 1.5; // IOR of common Glass
			Re = calcFresnelReflectance(rayDirection, n, nc, nt, ratioIoR);
			Tr = 1.0 - Re;
			P  = 0.25 + (0.5 * Re);
			RP = Re / P;
			TP = Tr / (1.0 - P);
			
			if (diffuseCount == 0 && rand() < P)
			{
				mask *= RP;
				rayDirection = reflect(rayDirection, nl); // reflect ray from surface
				rayOrigin = x + nl * uEPS_intersect;
				continue;
			}

			// transmit ray through surface
			
			// is ray leaving a solid object from the inside? 
			// If so, attenuate ray color with object color by how far ray has travelled through the medium
			if (distance(n, nl) > 0.1)
			{
				thickness = 0.01;
				mask *= exp( log(clamp(hitColor, 0.01, 0.99)) * thickness * t ); 
			}

			mask *= TP;
			
			tdir = refract(rayDirection, nl, ratioIoR);
			rayDirection = tdir;
			rayOrigin = x - nl * uEPS_intersect;

			if (diffuseCount == 1)
				bounceIsSpecular = true; // turn on refracting caustics
			
			continue;
			
		} // end if (hitType == REFR)
		
		if (hitType == COAT)  // Diffuse object underneath with ClearCoat on top
		{
			coatTypeIntersected = true;

			nc = 1.0; // IOR of Air
			nt = 1.4; // IOR of Clear Coat
			Re = calcFresnelReflectance(rayDirection, nl, nc, nt, ratioIoR);
			Tr = 1.0 - Re;
			P  = 0.25 + (0.5 * Re);
			RP = Re / P;
			TP = Tr / (1.0 - P);

			if (diffuseCount == 0 && rand() < P)
			{
				mask *= RP;
				rayDirection = reflect(rayDirection, nl); // reflect ray from surface
				rayOrigin = x + nl * uEPS_intersect;
				continue;
			}

			diffuseCount++;
			mask *= TP;
			mask *= hitColor;

			bounceIsSpecular = false;
			
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

			sampleLight = true;
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
	
	quads[0] = Quad( vec3(0,-1, 0), vec3(-lightRadius, wallRadius-1.0,-lightRadius), vec3(lightRadius, wallRadius-1.0,-lightRadius), vec3(lightRadius, wallRadius-1.0, lightRadius), vec3(-lightRadius, wallRadius-1.0, lightRadius), L1, z, LIGHT);// Quad Area Light on ceiling

	boxes[0] = Box( vec3(-wallRadius), vec3(wallRadius), z, vec3(1), DIFF);// the Cornell Box interior
}


#include <pathtracing_main>
