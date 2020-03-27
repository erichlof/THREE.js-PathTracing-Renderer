#version 300 es

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
#define N_PLANES 1
#define N_QUADS 6
#define N_BOXES 9
#define N_CONES 5

//-----------------------------------------------------------------------
struct Ray { vec3 origin; vec3 direction; };
struct Sphere { float radius; vec3 position; vec3 emission; vec3 color; float roughness; int type; };
struct Ellipsoid { vec3 radii; vec3 position; vec3 emission; vec3 color; float roughness; int type; };
struct Plane { vec4 pla; vec3 emission; vec3 color; float roughness; int type; };
struct Quad { vec3 normal; vec3 v0; vec3 v1; vec3 v2; vec3 v3; vec3 emission; vec3 color; float roughness; int type; };
struct Box { vec3 minCorner; vec3 maxCorner; vec3 emission; vec3 color; float roughness; int type; };
struct Cone { vec3 pos0; float radius0; vec3 pos1; float radius1; vec3 emission; vec3 color; float roughness; int type; };
struct Intersection { vec3 normal; vec3 emission; vec3 color; float roughness; int type; };

Sphere spheres[N_SPHERES];
Ellipsoid ellipsoids[N_ELLIPSOIDS];
Plane planes[N_PLANES];
Quad quads[N_QUADS];
Box boxes[N_BOXES];
Cone cones[N_CONES];

#include <pathtracing_random_functions>
#include <pathtracing_calc_fresnel_reflectance>
#include <pathtracing_plane_intersect>
#include <pathtracing_sphere_intersect>
#include <pathtracing_ellipsoid_intersect>
#include <pathtracing_quad_intersect>
#include <pathtracing_box_intersect>
#include <pathtracing_cone_intersect>
#include <pathtracing_sample_quad_light>


//-----------------------------------------------------------------------
float SceneIntersect( Ray r, inout Intersection intersec )
//-----------------------------------------------------------------------
{
	vec3 n;
	float d;
	float t = INFINITY;
	bool isRayExiting = false;
	
	
	for (int i = 0; i < N_QUADS; i++)
        {
		d = QuadIntersect( quads[i].v0, quads[i].v1, quads[i].v2, quads[i].v3, r, false);
		if (d < t)
		{
			t = d;
			intersec.normal = normalize(quads[i].normal);
			intersec.emission = quads[i].emission;
			intersec.color = quads[i].color;
			intersec.roughness = quads[i].roughness;
			intersec.type = quads[i].type;
		}
	}
	
	for (int i = 0; i < N_SPHERES; i++)
        {
		d = SphereIntersect( spheres[i].radius, spheres[i].position, r );
		if (d < t)
		{
			t = d;
			intersec.normal = normalize((r.origin + r.direction * t) - spheres[i].position);
			intersec.emission = spheres[i].emission;
			intersec.color = spheres[i].color;
			intersec.roughness = spheres[i].roughness;
			intersec.type = spheres[i].type;
		}
        }
	
	for (int i = 0; i < N_ELLIPSOIDS; i++)
        {
		d = EllipsoidIntersect( ellipsoids[i].radii, ellipsoids[i].position, r );
		if (d < t)
		{
			t = d;
			intersec.normal = normalize( ((r.origin + r.direction * t) - ellipsoids[i].position) / (ellipsoids[i].radii * ellipsoids[i].radii) );
			intersec.emission = ellipsoids[i].emission;
			intersec.color = ellipsoids[i].color;
			intersec.roughness = ellipsoids[i].roughness;
			intersec.type = ellipsoids[i].type;
		}
	}
	
	for (int i = 0; i < N_BOXES; i++)
        {
	
		d = BoxIntersect( boxes[i].minCorner, boxes[i].maxCorner, r, n, isRayExiting );
		if (d < t)
		{
			t = d;
			intersec.normal = normalize(n);
			intersec.emission = boxes[i].emission;
			intersec.color = boxes[i].color;
			intersec.roughness = boxes[i].roughness;
			intersec.type = boxes[i].type;
		}
        }
	
	for (int i = 0; i < N_PLANES; i++)
        {
		d = PlaneIntersect( planes[i].pla, r );
		if (d < t)
		{
			t = d;
			intersec.normal = normalize(planes[i].pla.xyz);
			intersec.emission = planes[i].emission;
			intersec.color = planes[i].color;
			intersec.roughness = planes[i].roughness;
			intersec.type = planes[i].type;
		}
        }
	
	for (int i = 0; i < N_CONES; i++)
        {
		d = ConeIntersect( cones[i].pos0, cones[i].radius0, cones[i].pos1, cones[i].radius1, r, n );
		if (d < t)
		{
			t = d;
			intersec.normal = normalize(n);
			intersec.emission = cones[i].emission;
			intersec.color = cones[i].color;
			intersec.roughness = cones[i].roughness;
			intersec.type = cones[i].type;
		}
        }
	
	return t;
	
} // end float SceneIntersect( Ray r, inout Intersection intersec )


//-----------------------------------------------------------------------
vec3 CalculateRadiance( Ray r, inout uvec2 seed )
//-----------------------------------------------------------------------
{
	Intersection intersec;
	Quad lightChoice;
	Ray firstRay;
	Ray secondaryRay;

	vec3 randVec = vec3(rand(seed) * 2.0 - 1.0, rand(seed) * 2.0 - 1.0, rand(seed) * 2.0 - 1.0);
	vec3 accumCol = vec3(0);
	vec3 mask = vec3(1);
	vec3 firstMask = vec3(1);
	vec3 secondaryMask = vec3(1);
	vec3 tdir;
	vec3 dirToLight;
	vec3 x, n, nl;
	vec3 clothTextureColor, darkWoodTextureColor, lightWoodTextureColor;
        
	float t;
        float weight;
	float nc, nt, ratioIoR, Re, Tr;
	float randChoose;

	int diffuseCount = 0;

	bool bounceIsSpecular = true;
	bool sampleLight = false;
	bool reflectionTime = false;
	bool firstTypeWasDIFF = false;
	bool firstTypeWasCOAT = false;
	bool shadowTime = false;

	
        for (int bounces = 0; bounces < 6; bounces++)
	{
		
		t = SceneIntersect(r, intersec);
		
		if (t == INFINITY)
		{
			if (firstTypeWasDIFF && !shadowTime) 
			{
				// start back at the diffuse surface, but this time follow shadow ray branch
				r = firstRay;
				r.direction = normalize(r.direction);
				mask = firstMask;
				// set/reset variables
				shadowTime = true;
				bounceIsSpecular = false;
				sampleLight = true;
				// continue with the shadow ray
				continue;
			}

			if (firstTypeWasCOAT && !shadowTime) 
			{
				// start back at the diffuse surface, but this time follow shadow ray branch
				r = secondaryRay;
				r.direction = normalize(r.direction);
				mask = secondaryMask;
				// set/reset variables
				shadowTime = true;
				bounceIsSpecular = false;
				sampleLight = true;
				// continue with the shadow ray
				continue;
			}

			if (firstTypeWasCOAT && !reflectionTime) 
			{
				// start back at the refractive surface, but this time follow reflective branch
				r = firstRay;
				r.direction = normalize(r.direction);
				mask = firstMask;
				// set/reset variables
				//diffuseCount = 0;
				reflectionTime = true;
				bounceIsSpecular = true;
				sampleLight = false;
				// continue with the reflection ray
				continue;
			}

			// nothing left to calculate, so exit	
			break;
		}
		
		if (intersec.type == LIGHT)
		{	
			if (bounces == 0)
			{
				accumCol = mask * intersec.emission;
				break;
			}

			if (firstTypeWasDIFF)
			{
				if (!shadowTime) 
				{
					if (sampleLight)
						accumCol = mask * intersec.emission * 0.5;
					else if (bounceIsSpecular)
						accumCol = mask * intersec.emission;
					
					// start back at the diffuse surface, but this time follow shadow ray branch
					r = firstRay;
					r.direction = normalize(r.direction);
					mask = firstMask;
					// set/reset variables
					shadowTime = true;
					bounceIsSpecular = false;
					sampleLight = true;
					// continue with the shadow ray
					continue;
				}
				
				accumCol += mask * intersec.emission * 0.5; // add shadow ray result to the colorbleed result (if any)
				
				break;		
			}

			if (firstTypeWasCOAT)
			{
				if (!shadowTime) 
				{
					if (sampleLight)
						accumCol = mask * intersec.emission * 0.5;

					// start back at the diffuse surface, but this time follow shadow ray branch
					r = secondaryRay;
					r.direction = normalize(r.direction);
					mask = secondaryMask;
					// set/reset variables
					shadowTime = true;
					bounceIsSpecular = false;
					sampleLight = true;
					// continue with the shadow ray
					continue;
				}

				if (!reflectionTime)
				{
					// add initial shadow ray result to secondary shadow ray result (if any) 
					accumCol += mask * intersec.emission * 0.5;

					// start back at the coat surface, but this time follow reflective branch
					r = firstRay;
					r.direction = normalize(r.direction);
					mask = firstMask;
					// set/reset variables
					reflectionTime = true;
					bounceIsSpecular = true;
					sampleLight = false;
					// continue with the reflection ray
					continue;
				}

				// add reflective result to the diffuse result
				if (sampleLight || bounceIsSpecular)
					accumCol += mask * intersec.emission;

				break;	
			}

			if (sampleLight || bounceIsSpecular)
				accumCol = mask * intersec.emission; // looking at light through a reflection
			
			// reached a light, so we can exit
			break;

		} // end if (intersec.type == LIGHT)


		// if we get here and sampleLight is still true, shadow ray failed to find a light source
		if (sampleLight) 
		{

			if (firstTypeWasDIFF && !shadowTime) 
			{
				// start back at the diffuse surface, but this time follow shadow ray branch
				r = firstRay;
				r.direction = normalize(r.direction);
				mask = firstMask;
				// set/reset variables
				shadowTime = true;
				bounceIsSpecular = false;
				sampleLight = true;
				// continue with the shadow ray
				continue;
			}

			if (firstTypeWasCOAT && !shadowTime) 
			{
				// start back at the diffuse surface, but this time follow shadow ray branch
				r = secondaryRay;
				r.direction = normalize(r.direction);
				mask = secondaryMask;
				// set/reset variables
				shadowTime = true;
				bounceIsSpecular = false;
				sampleLight = true;
				// continue with the shadow ray
				continue;
			}

			if (firstTypeWasCOAT && !reflectionTime) 
			{
				// start back at the refractive surface, but this time follow reflective branch
				r = firstRay;
				r.direction = normalize(r.direction);
				mask = firstMask;
				// set/reset variables
				//diffuseCount = 0;
				reflectionTime = true;
				bounceIsSpecular = true;
				sampleLight = false;
				// continue with the reflection ray
				continue;
			}

			// nothing left to calculate, so exit	
			break;
		}

		// useful data 
		n = normalize(intersec.normal);
                nl = dot(n, r.direction) < 0.0 ? normalize(n) : normalize(-n);
		x = r.origin + r.direction * t;

		clothTextureColor = pow(clamp(texture(tClothTexture, (10.0 * x.xz) / 512.0).rgb, 0.0, 1.0), vec3(2.2));
		darkWoodTextureColor = pow(clamp(texture(tDarkWoodTexture, 3.5 * x.xz / 512.0).rgb, 0.0, 1.0), vec3(2.2));
		lightWoodTextureColor = pow(clamp(texture(tLightWoodTexture, 6.0 * x.xz / 512.0).rgb, 0.0, 1.0), vec3(2.2));

		
		randChoose = rand(seed) * 2.0; // 2 lights to choose from
		lightChoice = quads[int(randChoose)];

		
                if (intersec.type == DIFF || intersec.type == CLOTH ) // Ideal DIFFUSE reflection
		{
			diffuseCount++;

			if (intersec.type == CLOTH)
				intersec.color *= clothTextureColor;

			mask *= intersec.color;

			bounceIsSpecular = false;

			if (diffuseCount == 1 && !firstTypeWasDIFF)
			{	
				// save intersection data for future shadowray trace
				firstTypeWasDIFF = true;
				dirToLight = sampleQuadLight(x, nl, lightChoice, dirToLight, weight, seed);
				firstMask = mask * weight * N_LIGHTS;
                                firstRay = Ray( x, normalize(dirToLight) ); // create shadow ray pointed towards light
				firstRay.origin += nl * uEPS_intersect;

				// choose random Diffuse sample vector
				r = Ray( x, normalize(randomCosWeightedDirectionInHemisphere(nl, seed)) );
				r.origin += nl * uEPS_intersect;
				continue;
			}
                        
			dirToLight = sampleQuadLight(x, nl, lightChoice, dirToLight, weight, seed);
			mask *= weight * N_LIGHTS;

			r = Ray( x, normalize(dirToLight) );
			r.origin += nl * uEPS_intersect;
			
			sampleLight = true;
			continue;

		} // end if (intersec.type == DIFF)
		
		if (intersec.type == COAT)  // Diffuse object underneath with ClearCoat on top
		{
			nc = 1.0; // IOR of Air
			nt = 1.3; // IOR of Clear Coat
			Re = calcFresnelReflectance(r.direction, n, nc, nt, ratioIoR);
			Tr = 1.0 - Re;

			if (!firstTypeWasCOAT && diffuseCount == 0)
			{	
				// save intersection data for future reflection trace
				firstTypeWasCOAT = true;
				firstMask = mask * Re;
				firstRay = Ray( x, reflect(r.direction, nl) ); // create reflection ray from surface
				firstRay.origin += nl * uEPS_intersect;
				mask *= Tr;
			}

			diffuseCount++;

			mask *= intersec.color;
			
			bounceIsSpecular = false;

			if (firstTypeWasCOAT && diffuseCount == 1)
                        {
                                // save intersection data for future shadowray trace
				dirToLight = sampleQuadLight(x, nl, lightChoice, dirToLight, weight, seed);
				secondaryMask = mask * weight * N_LIGHTS;
                                secondaryRay = Ray( x, normalize(dirToLight) ); // create shadow ray pointed towards light
				secondaryRay.origin += nl * uEPS_intersect;

				// choose random Diffuse sample vector
				r = Ray( x, normalize(randomCosWeightedDirectionInHemisphere(nl, seed)) );
				r.origin += nl * uEPS_intersect;
				continue;
                        }
                        
			dirToLight = sampleQuadLight(x, nl, lightChoice, dirToLight, weight, seed);
			mask *= weight * N_LIGHTS;
			
			r = Ray( x, normalize(dirToLight) );
			r.origin += nl * uEPS_intersect;

			sampleLight = true;
			continue;
                        
		} //end if (intersec.type == COAT)
		
		if (intersec.type == LIGHTWOOD || intersec.type == DARKWOOD)  // Diffuse object underneath with thin ClearCoat on top
		{
			nc = 1.0; // IOR of Air
			nt = 1.1; // IOR of Clear Coat
			Re = calcFresnelReflectance(r.direction, n, nc, nt, ratioIoR);
			Tr = 1.0 - Re;
			
			float spotRadius = 1.5;
			bool isSpot = false;
			
			bool spotn1 = distance(x, vec3(212, 10, -100)) < spotRadius;
			bool spotn2 = distance(x, vec3(212, 10, -200)) < spotRadius;
			bool spotn3 = distance(x, vec3(212, 10, -300)) < spotRadius;
			bool spotn4 = distance(x, vec3(212, 10, -400)) < spotRadius;
			bool spotp0 = distance(x, vec3(212, 10, 0)) < spotRadius;
			bool spotp1 = distance(x, vec3(212, 10, 100)) < spotRadius;
			bool spotp2 = distance(x, vec3(212, 10, 200)) < spotRadius;
			bool spotp3 = distance(x, vec3(212, 10, 300)) < spotRadius;
			bool spotp4 = distance(x, vec3(212, 10, 400)) < spotRadius;
			if (spotn1 || spotn2 || spotn3 || spotn4 || spotp0 || 
				spotp1 || spotp2 || spotp3 || spotp4 ) 
				isSpot = true;
				
			spotn1 = distance(x, vec3(-212, 10, -100)) < spotRadius;
			spotn2 = distance(x, vec3(-212, 10, -200)) < spotRadius;
			spotn3 = distance(x, vec3(-212, 10, -300)) < spotRadius;
			spotn4 = distance(x, vec3(-212, 10, -400)) < spotRadius;
			bool spotn0 = distance(x, vec3(-212, 10, 0)) < spotRadius;
			spotp1 = distance(x, vec3(-212, 10, 100)) < spotRadius;
			spotp2 = distance(x, vec3(-212, 10, 200)) < spotRadius;
			spotp3 = distance(x, vec3(-212, 10, 300)) < spotRadius;
			spotp4 = distance(x, vec3(-212, 10, 400)) < spotRadius;
			if (spotn1 || spotn2 || spotn3 || spotn4 || spotn0 || 
				spotp1 || spotp2 || spotp3 || spotp4 ) 
				isSpot = true;
			
			spotn1 = distance(x, vec3(200, 10, -412)) < spotRadius;
			spotn2 = distance(x, vec3(100, 10, -412)) < spotRadius;
			spotn0 = distance(x, vec3(0, 10, -412)) < spotRadius;
			spotn3 = distance(x, vec3(-100, 10, -412)) < spotRadius;
			spotn4 = distance(x, vec3(-200, 10, -412)) < spotRadius;
			spotp1 = distance(x, vec3(200, 10,  412)) < spotRadius;
			spotp2 = distance(x, vec3(100, 10, 412)) < spotRadius;
			spotp0 = distance(x, vec3(0, 10, 412)) < spotRadius;
			spotp3 = distance(x, vec3(-100, 10, 412)) < spotRadius;
			spotp4 = distance(x, vec3(-200, 10, 412)) < spotRadius;
			if (spotn1 || spotn2 || spotn0 || spotn3 || spotn4 || 
				spotp1 || spotp2 || spotp0 || spotp3 || spotp4 ) 
				isSpot = true;
			
			if (intersec.type == DARKWOOD)
				intersec.color *= darkWoodTextureColor;
			if (isSpot)
				intersec.color = clamp(intersec.color + 0.5, 0.0, 1.0);
				
			if (intersec.type == LIGHTWOOD)	
				intersec.color *= lightWoodTextureColor;
		
			vec3 reflectVec = reflect(r.direction, nl);
			vec3 glossyVec = randomCosWeightedDirectionInHemisphere(nl, seed);

			if (!firstTypeWasCOAT && diffuseCount == 0)
			{	
				// save intersection data for future reflection trace
				firstTypeWasCOAT = true;
				firstMask = mask * Re;
				firstRay = Ray( x, mix(reflectVec, glossyVec, intersec.roughness)); // create reflection ray from surface
				firstRay.direction = normalize(firstRay.direction);
				firstRay.origin += nl * uEPS_intersect;
				mask *= Tr;
			}

			diffuseCount++;

			mask *= intersec.color;
			
			bounceIsSpecular = false;

			if (firstTypeWasCOAT && diffuseCount == 1)
                        {
                                // save intersection data for future shadowray trace
				dirToLight = sampleQuadLight(x, nl, lightChoice, dirToLight, weight, seed);
				secondaryMask = mask * weight * N_LIGHTS;
                                secondaryRay = Ray( x, normalize(dirToLight) ); // create shadow ray pointed towards light
				secondaryRay.origin += nl * uEPS_intersect;

				// choose random Diffuse sample vector
				r = Ray( x, normalize(randomCosWeightedDirectionInHemisphere(nl, seed)) );
				r.origin += nl * uEPS_intersect;
				continue;
                        }

			dirToLight = sampleQuadLight(x, nl, lightChoice, dirToLight, weight, seed);
			mask *= weight * N_LIGHTS;
			
			r = Ray( x, normalize(dirToLight) );
			r.origin += nl * uEPS_intersect;

			sampleLight = true;
			continue;
                        
		} //end if (intersec.type == LIGHTWOOD || intersec.type == DARKWOOD)
		
		
	} // end for (int bounces = 0; bounces < 6; bounces++)
	

	return max(vec3(0), accumCol);

}


//-----------------------------------------------------------------------
void SetupScene(void)
//-----------------------------------------------------------------------
{
	vec3 z  = vec3(0);          
	vec3 L1 = vec3(1.0, 1.0, 1.0) * 4.0;// Bright White light
	vec3 clothColor = vec3(0.0, 0.2, 1.0) * 0.7;
	vec3 railWoodColor = vec3(0.05,0.0,0.0);
	float ceilingHeight = 300.0;
	
	quads[0] = Quad( normalize(vec3(0,-1, 0)), vec3(-150, ceilingHeight,-300), vec3(-50, ceilingHeight,-300), vec3(-50, ceilingHeight,300), vec3(-150, ceilingHeight,300), L1, z, 0.0, LIGHT);// rectangular Area Light in ceiling
	quads[1] = Quad( normalize(vec3(0,-1, 0)), vec3(50, ceilingHeight,-300), vec3(150, ceilingHeight,-300), vec3(150, ceilingHeight,300), vec3(50, ceilingHeight,300), L1, z, 0.0, LIGHT);// rectangular Area Light in ceiling
	quads[2] = Quad( normalize(vec3(1,-1, 0)), vec3(-200,0,-400), vec3(-190,10,-400), vec3(-190,10,400), vec3(-200,0,400), z, clothColor, 0.0, CLOTH);// Cloth left Rail bottom portion
	quads[3] = Quad( normalize(vec3(-1,-1, 0)), vec3(190,10,-400), vec3(200,0,-400),  vec3(200,0,400), vec3(190,10,400), z, clothColor, 0.0, CLOTH);// Cloth right Rail bottom portion
	quads[4] = Quad( normalize(vec3(0,-1, 1)), vec3(-200,0,-400), vec3(200,0,-400), vec3(200,10,-390), vec3(-200,10,-390), z, clothColor, 0.0, CLOTH);// Cloth back Rail bottom portion
	quads[5] = Quad( normalize(vec3(0,-1, -1)), vec3(200,0,400), vec3(-200,0,400),  vec3(-200,10,390), vec3(200,10,390), z, clothColor, 0.0, CLOTH);// Cloth front Rail bottom portion
	
	spheres[0] = Sphere(9.0, vec3( 25, 9, 25), z, vec3(0.8, 0.7, 0.4), 0.0, COAT);// White Ball
	spheres[1] = Sphere(9.0, vec3(-50, 9, 0),   z, vec3(0.9, 0.4, 0.0), 0.0, COAT);// Yellow Ball
	spheres[2] = Sphere(9.0, vec3( 50, 9, 0), z, vec3(0.25, 0.0, 0.0), 0.0, COAT);// Red Ball
        
	ellipsoids[0] = Ellipsoid(  vec3(1.97,1.97,1), vec3(0,2,79), z, vec3(0,0.3,0.7), 0.0, DIFF);//CueStick blue chalked tip
	ellipsoids[1] = Ellipsoid(  vec3(4.5,4.5,2), vec3(0,4.5,-375), z, vec3(0.01), 0.0, DIFF);//CueStick rubber butt-end cap
	
	boxes[0] = Box( vec3(-200,-10,-400), vec3(200,0,400), z, clothColor, 0.0, CLOTH);//Blue Cloth Table Bed
	boxes[1] = Box( vec3(-200,9,-400), vec3( 200, 10,-390), z, clothColor, 0.0, CLOTH);//Cloth Rail back
	boxes[2] = Box( vec3(-200,9, 390), vec3( 200, 10, 400), z, clothColor, 0.0, CLOTH);//Cloth Rail front
	boxes[3] = Box( vec3(-200,9,-400), vec3(-190, 10, 400), z, clothColor, 0.0, CLOTH);//Cloth Rail left
	boxes[4] = Box( vec3( 190,9,-400), vec3( 200, 10, 400), z, clothColor, 0.0, CLOTH);//Cloth Rail right
	
	boxes[5] = Box( vec3(-225,-10,-425), vec3( 225, 10,-400), z, railWoodColor, 0.3, DARKWOOD);//Wooden Rail back
	boxes[6] = Box( vec3(-225,-10, 400), vec3( 225, 10, 425), z, railWoodColor, 0.3, DARKWOOD);//Wooden Rail front
	boxes[7] = Box( vec3(-225,-10,-425), vec3(-200, 10, 425), z, railWoodColor, 0.3, DARKWOOD);//Wooden Rail left
	boxes[8] = Box( vec3( 200,-10,-425), vec3( 225, 10, 425), z, railWoodColor, 0.3, DARKWOOD);//Wooden Rail right
	
	planes[0] = Plane( vec4( 0,1,0, -300.0), z, vec3(0.5), 0.0, DIFF);//Floor
	
	cones[0] = Cone( vec3(0,3.5,-160), 3.5, vec3(0,2,72), 2.0, z, vec3(0.99), 0.1, LIGHTWOOD);//Wooden CueStick shaft
	cones[1] = Cone( vec3(0,2,71), 2.0, vec3(0,2,78), 1.97, z, vec3(0.9), 0.0, COAT);//CueStick shaft white plastic collar
	cones[2] = Cone( vec3(0,2,77.5), 1.93, vec3(0,2,79), 1.93, z, vec3(0.02,0.005,0.001), 0.4, COAT);//CueStick dark leather tip
	cones[3] = Cone( vec3(0,4,-270), 4.0, vec3(0,3.5,-160), 3.5, z, vec3(0.4, 0.01, 0.3), 0.0, DARKWOOD);//Wooden CueStick butt
	cones[4] = Cone( vec3(0,4.5,-375), 4.5, vec3(0,4,-270), 4.0, z, vec3(0.1), 0.0, CLOTH);//CueStick handle wrap
}


#include <pathtracing_main>
