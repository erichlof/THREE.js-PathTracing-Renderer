#version 300 es

precision highp float;
precision highp int;
precision highp sampler2D;

#include <pathtracing_uniforms_and_defines>

uniform float uLeftSphereMaterialType;
uniform float uRightSphereMaterialType;
uniform vec3 uLeftSphereColor;
uniform vec3 uRightSphereColor;
//uniform vec3 uLeftSphereEmissive;
//uniform vec3 uRightSphereEmissive;

#define N_QUADS 6
#define N_SPHERES 2

struct Ray { vec3 origin; vec3 direction; };
struct Sphere { float radius; vec3 position; vec3 emission; vec3 color; int type; };
struct Quad { vec3 normal; vec3 v0; vec3 v1; vec3 v2; vec3 v3; vec3 emission; vec3 color; int type; };
struct Intersection { vec3 normal; vec3 emission; vec3 color; int type; };

Quad quads[N_QUADS];
Sphere spheres[N_SPHERES];


#include <pathtracing_random_functions>

#include <pathtracing_calc_fresnel_reflectance>

#include <pathtracing_sphere_intersect>

#include <pathtracing_quad_intersect>

#include <pathtracing_sample_quad_light>


//-----------------------------------------------------------------------
float SceneIntersect( Ray r, inout Intersection intersec )
//-----------------------------------------------------------------------
{
	float d;
	float t = INFINITY;
	
        for (int i = 0; i < N_SPHERES; i++)
        {
		d = SphereIntersect( spheres[i].radius, spheres[i].position, r );
		if (d < t)
		{
			t = d;
			intersec.normal = normalize((r.origin + r.direction * t) - spheres[i].position);
			intersec.emission = spheres[i].emission;
			intersec.color = spheres[i].color;
                        intersec.type = spheres[i].type;
		}
        }
	
	for (int i = 0; i < N_QUADS; i++)
        {
		d = QuadIntersect( quads[i].v0, quads[i].v1, quads[i].v2, quads[i].v3, quads[i].normal, r );
		if (d < t)
		{
			t = d;
			intersec.normal = (quads[i].normal);
			intersec.emission = quads[i].emission;
			intersec.color = quads[i].color;
			intersec.type = quads[i].type;
		}
        }
	
	return t;
}


//-----------------------------------------------------------------------
vec3 CalculateRadiance( Ray r, inout uvec2 seed )
//-----------------------------------------------------------------------
{
	Intersection intersec;
	Quad light = quads[5];
	Ray firstRay;

	vec3 accumCol = vec3(0);
        vec3 mask = vec3(1);
	vec3 firstMask = vec3(1);
	vec3 dirToLight;
	vec3 tdir;
	vec3 x, n, nl;
        
	float t;
	float nc, nt, ratioIoR, Re, Tr;
	float weight;
	float diffuseColorBleeding = 0.4; // range: 0.0 - 0.5, amount of color bleeding between surfaces

	int diffuseCount = 0;

	bool bounceIsSpecular = true;
	bool sampleLight = false;
	bool firstTypeWasREFR = false;
	bool reflectionTime = false;
	bool firstTypeWasDIFF = false;
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

                        if (firstTypeWasREFR && !reflectionTime) 
			{
				// start back at the refractive surface, but this time follow reflective branch
				r = firstRay;
				r.direction = normalize(r.direction);
				mask = firstMask;
				// set/reset variables
				diffuseCount = 0;
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
					if (bounceIsSpecular)
						accumCol = mask * intersec.emission;
					if (sampleLight)
						accumCol = mask * intersec.emission * 0.5;
					
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
				
				if (sampleLight)
					accumCol += mask * intersec.emission * 0.5; // add shadow ray result to the colorbleed result (if any)
				break;		
			}

			if (firstTypeWasREFR)
			{
				if (!reflectionTime) 
				{
					if (bounceIsSpecular || sampleLight)
						accumCol = mask * intersec.emission;
					
					// start back at the refractive surface, but this time follow reflective branch
					r = firstRay;
					r.direction = normalize(r.direction);
					mask = firstMask;
					// set/reset variables
					diffuseCount = 0;
					reflectionTime = true;
					bounceIsSpecular = true;
					sampleLight = false;
					// continue with the reflection ray
					continue;
				}

				if (bounceIsSpecular || sampleLight)
					accumCol += mask * intersec.emission; // add reflective result to the refractive result (if any)
				break;	
			}

			 // need this check for translucent materials
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

			if (firstTypeWasREFR && !reflectionTime) 
			{
				// start back at the refractive surface, but this time follow reflective branch
				r = firstRay;
				r.direction = normalize(r.direction);
				mask = firstMask;
				// set/reset variables
				diffuseCount = 0;
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

		    
                if (intersec.type == DIFF) // Ideal DIFFUSE reflection
		{
			diffuseCount++;

			mask *= intersec.color;

			bounceIsSpecular = false;

			if (diffuseCount == 1 && !firstTypeWasDIFF && !firstTypeWasREFR)
			{	
				// save intersection data for future shadowray trace
				firstTypeWasDIFF = true;
				dirToLight = sampleQuadLight(x, nl, quads[5], dirToLight, weight, seed);
				firstMask = mask * weight;
                                firstRay = Ray( x, normalize(dirToLight) ); // create shadow ray pointed towards light
				firstRay.origin += nl * uEPS_intersect;

				// choose random Diffuse sample vector
				r = Ray( x, normalize(randomCosWeightedDirectionInHemisphere(nl, seed)) );
				r.origin += nl * uEPS_intersect;
				continue;
			}
			else if (firstTypeWasREFR && diffuseCount == 1 && rand(seed) < diffuseColorBleeding)
			{
				r = Ray( x, normalize(randomCosWeightedDirectionInHemisphere(nl, seed)) );
				r.origin += nl * uEPS_intersect;
				continue;
			}
                        
			dirToLight = sampleQuadLight(x, nl, quads[5], dirToLight, weight, seed);
			mask *= weight;

			r = Ray( x, normalize(dirToLight) );
			r.origin += nl * uEPS_intersect;

			sampleLight = true;
			continue;
                        
		} // end if (intersec.type == DIFF)
		
		if (intersec.type == SPEC)  // Ideal SPECULAR reflection
		{
			mask *= intersec.color;

			r = Ray( x, reflect(r.direction, nl) );
			r.origin += nl * uEPS_intersect;

			//bounceIsSpecular = true; // turn on mirror caustics
			continue;
		}
		
		if (intersec.type == REFR)  // Ideal dielectric REFRACTION
		{
			nc = 1.0; // IOR of Air
			nt = 1.5; // IOR of common Glass
			Re = calcFresnelReflectance(r.direction, n, nc, nt, ratioIoR);
			Tr = 1.0 - Re;
			
			if (bounces == 0)
			{	
				// save intersection data for future reflection trace
				firstTypeWasREFR = true;
				firstMask = mask * Re;
				firstRay = Ray( x, reflect(r.direction, nl) ); // create reflection ray from surface
				firstRay.origin += nl * uEPS_intersect;
				mask *= Tr;
			}
			else if (diffuseCount == 0 && rand(seed) < Re)
			{
				r = Ray( x, reflect(r.direction, nl) ); // reflect ray from surface
				r.origin += nl * uEPS_intersect;
				continue;
			}

			// transmit ray through surface
			mask *= intersec.color;
			
			tdir = refract(r.direction, nl, ratioIoR);
			r = Ray(x, normalize(tdir));
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

			// clearCoat counts as refractive surface
			if (bounces == 0)
			{	
				// save intersection data for future reflection trace
				firstTypeWasREFR = true;
				firstMask = mask * Re;
				firstRay = Ray( x, reflect(r.direction, nl) ); // create reflection ray from surface
				firstRay.origin += nl * uEPS_intersect;
				mask *= Tr;
			}
			else if (diffuseCount == 0 && rand(seed) < Re)
			{
				r = Ray( x, reflect(r.direction, nl) ); // reflect ray from surface
				r.origin += nl * uEPS_intersect;
				continue;
			}

			diffuseCount++;

			mask *= intersec.color;

			bounceIsSpecular = false;
			
			if (diffuseCount == 1 && rand(seed) < diffuseColorBleeding)
                        {
                                // choose random Diffuse sample vector
				r = Ray( x, normalize(randomCosWeightedDirectionInHemisphere(nl, seed)) );
				r.origin += nl * uEPS_intersect;
				continue;
                        }

			dirToLight = sampleQuadLight(x, nl, quads[5], dirToLight, weight, seed);
			mask *= weight;
			
			r = Ray( x, normalize(dirToLight) );
			r.origin += nl * uEPS_intersect;

			sampleLight = true;
			continue;
			
		} //end if (intersec.type == COAT)

		if (intersec.type == CARCOAT)  // Colored Metal or Fiberglass object underneath with ClearCoat on top
		{
			nc = 1.0; // IOR of Air
			nt = 1.4; // IOR of Clear Coat
			Re = calcFresnelReflectance(r.direction, n, nc, nt, ratioIoR);
			Tr = 1.0 - Re;

			// clearCoat counts as refractive surface
			if (bounces == 0)
			{	
				// save intersection data for future reflection trace
				firstTypeWasREFR = true;
				firstMask = mask * Re;
				firstRay = Ray( x, reflect(r.direction, nl) ); // create reflection ray from surface
				firstRay.origin += nl * uEPS_intersect;
				mask *= Tr;
			}
			// choose either specular reflection, metallic, or diffuse
			else if (diffuseCount == 0 && rand(seed) < Re)
			{
				r = Ray( x, reflect(r.direction, nl) ); // reflect ray from surface
				r.origin += nl * uEPS_intersect;
				continue;
			}

			// metallic component
			mask *= intersec.color;
			
			if (rand(seed) > 0.8)
			{
				r = Ray( x, reflect(r.direction, nl) );
				r.origin += nl * uEPS_intersect;
				continue;
			}

			diffuseCount++;

			bounceIsSpecular = false;

			if (diffuseCount == 1 && rand(seed) < diffuseColorBleeding)
                        {
                                // choose random Diffuse sample vector
				r = Ray( x, normalize(randomCosWeightedDirectionInHemisphere(nl, seed)) );
				r.origin += nl * uEPS_intersect;
				continue;
                        }
                        
			dirToLight = sampleQuadLight(x, nl, quads[5], dirToLight, weight, seed);
			mask *= weight;
			
			r = Ray( x, normalize(dirToLight) );
			r.origin += nl * uEPS_intersect;

			sampleLight = true;
			continue;
			
                } //end if (intersec.type == CARCOAT)


		if (intersec.type == TRANSLUCENT)  // Translucent Sub-Surface Scattering material
		{
			float translucentDensity = 0.25;
			float scatteringDistance = -log(rand(seed)) / translucentDensity;
			vec3 absorptionCoefficient = intersec.color;

			// transmission?
			if (scatteringDistance > t) 
			{
				mask *= exp(-absorptionCoefficient * t);
				
				r = Ray(x, normalize(r.direction));
				r.origin += r.direction * scatteringDistance;

				continue;
			}

			// else scattering
			mask *= exp(-absorptionCoefficient * scatteringDistance);

			diffuseCount++;

			bounceIsSpecular = false;
			
			if (diffuseCount == 1 && rand(seed) < diffuseColorBleeding)
                        {
                                // choose random Diffuse sample vector
				//r = Ray( x, normalize(randomCosWeightedDirectionInHemisphere(nl, seed)) );
				r = Ray( x, normalize(randomSphereDirection(seed)) );
				r.origin += r.direction * scatteringDistance;
				continue;
                        }

			dirToLight = sampleQuadLight(x, nl, quads[5], dirToLight, weight, seed);
			mask *= weight;

			r = Ray( x, normalize(dirToLight) );
			r.origin += r.direction * scatteringDistance;
			
			sampleLight = true;
			continue;
			
		} // end if (intersec.type == TRANSLUCENT)

		
                if (intersec.type == SPECSUB)  // Shiny(specular) coating over Sub-Surface Scattering material
		{
			nc = 1.0; // IOR of Air
			nt = 1.3; // IOR of clear coating (for polished jade)
			Re = calcFresnelReflectance(r.direction, n, nc, nt, ratioIoR);
			Tr = 1.0 - Re;
			
			// specsub clearcoat counts as refractive surface
			if (bounces == 0)
			{	
				// save intersection data for future reflection trace
				firstTypeWasREFR = true;
				firstMask = mask * Re;
				firstRay = Ray( x, reflect(r.direction, nl) ); // create reflection ray from surface
				firstRay.origin += nl * uEPS_intersect;
				mask *= Tr;
			}
			else if (diffuseCount == 0 && rand(seed) < Re)
			{
				r = Ray( x, reflect(r.direction, nl) ); // reflect ray from surface
				r.origin += nl * uEPS_intersect;
				continue;
			}

			vec3 absorptionCoefficient = intersec.color;
			float translucentDensity = 0.1;
			float scatteringDistance = -log(rand(seed)) / translucentDensity;
			
			// transmission?
			if (scatteringDistance > t) 
			{
				mask *= exp(-absorptionCoefficient * t);

				r = Ray(x, normalize(r.direction));
				r.origin += r.direction * scatteringDistance;

				continue;
			}
			
			diffuseCount++;

			// else scattering
			mask *= exp(-absorptionCoefficient * scatteringDistance);

			bounceIsSpecular = false;
			
			if (diffuseCount == 1 && rand(seed) < diffuseColorBleeding)
                        {
                                // choose random scattering direction vector
				r = Ray( x, normalize(randomSphereDirection(seed)) );
				r.origin += r.direction * scatteringDistance;
				continue;
                        }

			dirToLight = sampleQuadLight(x, nl, quads[5], dirToLight, weight, seed);
			mask *= weight;

			r = Ray( x, normalize(dirToLight) );
			r.origin += r.direction * scatteringDistance;
			
			sampleLight = true;
			continue;
			
		} // end if (intersec.type == SPECSUB)
		
	} // end for (int bounces = 0; bounces < 6; bounces++)
	
	
	return max(vec3(0), accumCol);

} // end vec3 CalculateRadiance( Ray r, inout uvec2 seed )



//-----------------------------------------------------------------------
void SetupScene(void)
//-----------------------------------------------------------------------
{
	vec3 z  = vec3(0);// No color value, Black        
	vec3 L1 = vec3(1.0, 1.0, 1.0) * 10.0;// Bright light
		    
	spheres[0] = Sphere(  90.0, vec3(150.0,  91.0, -200.0),  z, uLeftSphereColor, int(uLeftSphereMaterialType));// Sphere Left
	spheres[1] = Sphere(  90.0, vec3(400.0,  91.0, -200.0),  z, uRightSphereColor, int(uRightSphereMaterialType));// Sphere Right
	
	quads[0] = Quad( vec3( 0.0, 0.0, 1.0), vec3(  0.0,   0.0,-559.2), vec3(549.6,   0.0,-559.2), vec3(549.6, 548.8,-559.2), vec3(  0.0, 548.8,-559.2), z, vec3( 1.0,  1.0,  1.0), DIFF);// Back Wall
	quads[1] = Quad( vec3( 1.0, 0.0, 0.0), vec3(  0.0,   0.0,   0.0), vec3(  0.0,   0.0,-559.2), vec3(  0.0, 548.8,-559.2), vec3(  0.0, 548.8,   0.0), z, vec3( 0.7, 0.05, 0.05), DIFF);// Left Wall Red
	quads[2] = Quad( vec3(-1.0, 0.0, 0.0), vec3(549.6,   0.0,-559.2), vec3(549.6,   0.0,   0.0), vec3(549.6, 548.8,   0.0), vec3(549.6, 548.8,-559.2), z, vec3(0.05, 0.05, 0.7 ), DIFF);// Right Wall Blue
	quads[3] = Quad( vec3( 0.0,-1.0, 0.0), vec3(  0.0, 548.8,-559.2), vec3(549.6, 548.8,-559.2), vec3(549.6, 548.8,   0.0), vec3(  0.0, 548.8,   0.0), z, vec3( 1.0,  1.0,  1.0), DIFF);// Ceiling
	quads[4] = Quad( vec3( 0.0, 1.0, 0.0), vec3(  0.0,   0.0,   0.0), vec3(549.6,   0.0,   0.0), vec3(549.6,   0.0,-559.2), vec3(  0.0,   0.0,-559.2), z, vec3( 1.0,  1.0,  1.0), DIFF);// Floor

	quads[5] = Quad( vec3( 0.0,-1.0, 0.0), vec3(213.0, 548.0,-332.0), vec3(343.0, 548.0,-332.0), vec3(343.0, 548.0,-227.0), vec3(213.0, 548.0,-227.0), L1, z, LIGHT);// Area Light Rectangle in ceiling
}


#include <pathtracing_main>
