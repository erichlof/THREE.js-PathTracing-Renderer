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
float hitObjectID;
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
	
	for (int i = 0; i < N_BOXES; i++)
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
        }

	for (int i = 0; i < N_QUADS; i++)
        {
		d = QuadIntersect( quads[i].v0, quads[i].v1, quads[i].v2, quads[i].v3, rayOrigin, rayDirection, FALSE);
		if (d < t)
		{
			t = d;
			hitNormal = (quads[i].normal);
			hitEmission = quads[i].emission;
			hitColor = quads[i].color;
			hitRoughness = quads[i].roughness;
			hitType = quads[i].type;
			hitObjectID = float(objectCount);
		}
		objectCount++;
	}
	
	for (int i = 0; i < N_SPHERES; i++)
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
        }
	
	for (int i = 0; i < N_ELLIPSOIDS; i++)
        {
		d = EllipsoidIntersect( ellipsoids[i].radii, ellipsoids[i].position, rayOrigin, rayDirection );
		if (d < t)
		{
			t = d;
			hitNormal = ((rayOrigin + rayDirection * t) - ellipsoids[i].position) / (ellipsoids[i].radii * ellipsoids[i].radii);
			hitEmission = ellipsoids[i].emission;
			hitColor = ellipsoids[i].color;
			hitRoughness = ellipsoids[i].roughness;
			hitType = ellipsoids[i].type;
			hitObjectID = float(objectCount);
		}
		objectCount++;
	}
	
	for (int i = 0; i < N_CONES; i++)
        {
		d = ConeIntersect( cones[i].pos0, cones[i].radius0, cones[i].pos1, cones[i].radius1, rayOrigin, rayDirection, n );
		if (d < t)
		{
			t = d;
			hitNormal = n;
			hitEmission = cones[i].emission;
			hitColor = cones[i].color;
			hitRoughness = cones[i].roughness;
			hitType = cones[i].type;
			hitObjectID = float(objectCount);
		}
		objectCount++;
        }


	return t;
	
} // end float SceneIntersect( )


//-----------------------------------------------------------------------------------------------------------------------------
vec3 CalculateRadiance( out vec3 objectNormal, out vec3 objectColor, out float objectID, out float pixelSharpness )
//-----------------------------------------------------------------------------------------------------------------------------
{
	Quad lightChoice;

	vec3 accumCol = vec3(0);
	vec3 mask = vec3(1);
	vec3 reflectionMask = vec3(1);
	vec3 reflectionRayOrigin = vec3(0);
	vec3 reflectionRayDirection = vec3(0);
	vec3 tdir;
	vec3 dirToLight;
	vec3 x, n, nl;
        
	float t;
        float weight;
	float nc, nt, ratioIoR, Re, Tr;
	//float P, RP, TP;
	float hitObjectID;
	float spotRadius = 1.5;

	int diffuseCount = 0;

	//int coatTypeIntersected = FALSE;
	int isSpot = FALSE;
	int bounceIsSpecular = TRUE;
	int sampleLight = FALSE;
	int willNeedReflectionRay = FALSE;


	lightChoice = quads[int(rand() * N_LIGHTS)];

	
        for (int bounces = 0; bounces < 4; bounces++)
	{
		
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


		if (hitType == LIGHT)
		{	
			if (bounces == 0)
				pixelSharpness = 1.01;

			if (diffuseCount == 0)
			{
				objectNormal = nl;
				objectColor = hitColor;
				objectID = hitObjectID;
			}
			
			if (bounceIsSpecular == TRUE || sampleLight == TRUE)
				accumCol += mask * hitEmission; // looking at light through a reflection
			
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
		}

		// if we get here and sampleLight is still true, shadow ray failed to find the light source 
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
		

		
                if (hitType == DIFF || hitType == CLOTH ) // Ideal DIFFUSE reflection
		{
			
			if (hitType == CLOTH)
				hitColor *= pow(clamp(texture(tClothTexture, (10.0 * x.xz) / 512.0).rgb, 0.0, 1.0), vec3(2.2));

			if (bounces == 0)
				objectColor = hitColor;
				
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
                        
			dirToLight = sampleQuadLight(x, nl, lightChoice, weight);
			mask *= diffuseCount == 1 ? 2.0 : 1.0;
			mask *= weight * N_LIGHTS;

			rayDirection = dirToLight;
			rayOrigin = x + nl * uEPS_intersect;
			
			sampleLight = TRUE;
			continue;

		} // end if (hitType == DIFF)
		
		if (hitType == COAT)  // Diffuse object underneath with ClearCoat on top
		{
			//coatTypeIntersected = TRUE;

			nc = 1.0; // IOR of Air
			nt = 1.5; // IOR of Clear Coat
			Re = calcFresnelReflectance(rayDirection, nl, nc, nt, ratioIoR);
			Tr = 1.0 - Re;
			// P  = 0.25 + (0.5 * Re);
                	// RP = Re / P;
                	// TP = Tr / (1.0 - P);

			if (bounces == 0 || (bounces == 1 && hitObjectID != objectID && bounceIsSpecular == TRUE))
			{
				reflectionMask = mask * Re;
				reflectionRayDirection = reflect(rayDirection, nl); // reflect ray from surface
				reflectionRayOrigin = x + nl * uEPS_intersect;
				willNeedReflectionRay = TRUE;
			}

			// handle diffuse surface underneath

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
                        
			dirToLight = sampleQuadLight(x, nl, lightChoice, weight);
			mask *= diffuseCount == 1 ? 2.0 : 1.0;
			mask *= weight * N_LIGHTS;
			
			rayDirection = dirToLight;
			rayOrigin = x + nl * uEPS_intersect;

			sampleLight = TRUE;
			continue;
                        
		} //end if (hitType == COAT)
		
		if (hitType == LIGHTWOOD || hitType == DARKWOOD)  // Diffuse object underneath with thin ClearCoat on top
		{
			nc = 1.0; // IOR of Air
			nt = 1.1; // IOR of Clear Coat
			Re = calcFresnelReflectance(rayDirection, nl, nc, nt, ratioIoR);
			Tr = 1.0 - Re;
			// P  = 0.25 + (0.5 * Re);
                	// RP = Re / P;
                	// TP = Tr / (1.0 - P);

			if (bounces == 0 || (bounces == 1 && hitObjectID != objectID && bounceIsSpecular == TRUE))
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
				hitColor *= pow(clamp(texture(tDarkWoodTexture, 3.5 * x.xz / 512.0).rgb, 0.0, 1.0), vec3(2.2));
			if (isSpot == TRUE)
				hitColor = clamp(hitColor + 0.5, 0.0, 1.0);
				
			if (hitType == LIGHTWOOD)	
				hitColor *= pow(clamp(texture(tLightWoodTexture, 6.0 * x.xz / 512.0).rgb, 0.0, 1.0), vec3(2.2));
		
			
			if (bounces == 0)
				objectColor = hitColor;

			// handle diffuse surface underneath

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

			dirToLight = sampleQuadLight(x, nl, lightChoice, weight);
			mask *= diffuseCount == 1 ? 2.0 : 1.0;
			mask *= weight * N_LIGHTS;
			
			rayDirection = dirToLight;
			rayOrigin = x + nl * uEPS_intersect;

			sampleLight = TRUE;
			continue;
                        
		} //end if (hitType == LIGHTWOOD || hitType == DARKWOOD)
		
		
	} // end for (int bounces = 0; bounces < 4; bounces++)
	

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
