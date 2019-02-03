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

#define N_QUADS 5
#define N_SPHERES 3

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

#include <pathtracing_sample_sphere_light>


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
	Sphere light = spheres[0];

	vec3 accumCol = vec3(0.0);
	vec3 mask = vec3(1.0);
	vec3 n, nl, x;
	vec3 dirToLight;
	vec3 tdir;
	
	float nc, nt, Re;
	float weight;
	float diffuseColorBleeding = 0.4; // range: 0.0 - 0.5, amount of color bleeding between surfaces

	int diffuseCount = 0;

	bool bounceIsSpecular = true;
	bool sampleLight = false;
	
	
        for (int bounces = 0; bounces < 5; bounces++)
	{
		
		float t = SceneIntersect(r, intersec);
		
		if (t == INFINITY)
		{
                        break;
		}
		
		// if we reached something bright, don't spawn any more rays
		if (intersec.type == LIGHT)
		{	
			if (bounceIsSpecular || sampleLight)
			{
				accumCol = mask * intersec.emission;
			}
			
			break;
		}

		// if we reached this point and sampleLight failed to find a light above, exit early
		if (sampleLight)
		{
			break;
		}
		
		// useful data 
		n = normalize(intersec.normal);
                nl = dot(n, r.direction) <= 0.0 ? normalize(n) : normalize(n * -1.0);
		x = r.origin + r.direction * t;
		
		    
                if (intersec.type == DIFF) // Ideal DIFFUSE reflection
                {

			diffuseCount++;

			mask *= intersec.color;

			/*
			// Russian Roulette - if needed, this speeds up the framerate, at the cost of some dark noise
			float p = max(mask.r, max(mask.g, mask.b));
			if (diffuseCount > 1)
			{
				if (rand(seed) < p)
                                	mask *= 1.0 / p;
                        	else
                                	break;
			}
			*/

			bounceIsSpecular = false;

                        if (diffuseCount == 1 && rand(seed) < diffuseColorBleeding)
                        {
                                // choose random Diffuse sample vector
				r = Ray( x, randomCosWeightedDirectionInHemisphere(nl, seed) );
				r.origin += r.direction;
				continue;
                        }
                        else
                        {
				weight = sampleSphereLight(x, nl, dirToLight, light, seed);
				mask *= clamp(weight, 0.0, 1.0);

                                r = Ray( x, dirToLight );
				r.origin += nl;

				sampleLight = true;
				continue;
                        }
				
                } // end if (intersec.type == DIFF)
		

                if (intersec.type == SPEC)  // Ideal SPECULAR reflection
		{
			mask *= intersec.color;

			r = Ray( x, reflect(r.direction, nl) );
			r.origin += r.direction;

			//bounceIsSpecular = true; // turn on mirror caustics
			continue;
		}
		

		if (intersec.type == REFR)  // Ideal dielectric REFRACTION
		{
			nc = 1.0; // IOR of Air
			nt = 1.5; // IOR of common Glass
			Re = calcFresnelReflectance(n, nl, r.direction, nc, nt, tdir);

			if (rand(seed) < Re) // reflect ray from surface
			{
				r = Ray( x, reflect(r.direction, nl) );
				r.origin += r.direction;

				//bounceIsSpecular = true; // turn on reflecting caustics, useful for water
			    	continue;	
			}
			else // transmit ray through surface
			{
				mask *= intersec.color;
				
				r = Ray(x, tdir);
				r.origin += r.direction;

				bounceIsSpecular = true; // turn on refracting caustics
				continue;
			}
			
		} // end if (intersec.type == REFR)
		
		
                if (intersec.type == COAT)  // Diffuse object underneath with ClearCoat on top
		{
			nc = 1.0; // IOR of Air
			nt = 1.4; // IOR of Clear Coat
			Re = calcFresnelReflectance(n, nl, r.direction, nc, nt, tdir);
			
			// choose either specular reflection or diffuse
			if( rand(seed) < Re )
			{	
				r = Ray( x, reflect(r.direction, nl) );
				r.origin += r.direction;
				continue;	
			}

			diffuseCount++;

			mask *= intersec.color;
			
			bounceIsSpecular = false;

			if (diffuseCount == 1 && rand(seed) < diffuseColorBleeding)
                        {
                                // choose random Diffuse sample vector
				r = Ray( x, randomCosWeightedDirectionInHemisphere(nl, seed) );
				r.origin += r.direction;
				continue;
                        }
                        else
                        {
				weight = sampleSphereLight(x, nl, dirToLight, light, seed);
				mask *= clamp(weight, 0.0, 1.0);
				
                                r = Ray( x, dirToLight );
				r.origin += nl;

				sampleLight = true;
				continue;
                        }
			
		} //end if (intersec.type == COAT)
		
		
		if (intersec.type == CARCOAT)  // Colored Metal or Fiberglass object underneath with ClearCoat on top
		{
			nc = 1.0; // IOR of Air
			nt = 1.4; // IOR of Clear Coat
			Re = calcFresnelReflectance(n, nl, r.direction, nc, nt, tdir);
			
			// choose either specular reflection, metallic, or diffuse
			if( rand(seed) < Re )
			{	
				r = Ray( x, reflect(r.direction, nl) );
				r.origin += r.direction;
				continue;	
			}

			mask *= intersec.color;
			
			if (rand(seed) > 0.8)
			{
				r = Ray( x, reflect(r.direction, nl) );
				r.origin += r.direction;
				continue;
			}

			diffuseCount++;

			bounceIsSpecular = false;

			if (diffuseCount == 1 && rand(seed) < diffuseColorBleeding)
                        {
                                // choose random Diffuse sample vector
				r = Ray( x, randomCosWeightedDirectionInHemisphere(nl, seed) );
				r.origin += r.direction;
				continue;
                        }
                        else
                        {
				weight = sampleSphereLight(x, nl, dirToLight, light, seed);
				mask *= clamp(weight, 0.0, 1.0);
				
                                r = Ray( x, dirToLight );
				r.origin += nl;

				sampleLight = true;
				continue;
                        }
			
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
				
				r.origin = x;
				r.origin += r.direction * scatteringDistance;

				bounceIsSpecular = true;
				continue;
			}

			// else scattering
			mask *= exp(-absorptionCoefficient * scatteringDistance);

			diffuseCount++;

			bounceIsSpecular = false;
			
			if (diffuseCount == 1 && rand(seed) < diffuseColorBleeding)
                        {
                                // choose random Diffuse sample vector
				r = Ray( x, randomCosWeightedDirectionInHemisphere(nl, seed) );
				r.origin += r.direction * scatteringDistance;
				continue;
                        }
                        else
                        {
				weight = sampleSphereLight(x, nl, dirToLight, light, seed);
				mask *= clamp(weight, 0.0, 1.0);

                                r = Ray( x, dirToLight );
				r.origin += r.direction * scatteringDistance;
				
				sampleLight = true;
				continue;
                        }
			
		} // end if (intersec.type == TRANSLUCENT)

		
                if (intersec.type == SPECSUB)  // Shiny(specular) coating over Sub-Surface Scattering material
		{
			nc = 1.0; // IOR of Air
			nt = 1.3; // IOR of clear coating (for polished jade)
			Re = calcFresnelReflectance(n, nl, r.direction, nc, nt, tdir);
			
			// choose either specular reflection or translucent subsurface scattering/transmission
			if( rand(seed) < Re )
			{
				r = Ray( x, reflect(r.direction, nl) );
				r.origin += r.direction;
				continue;
			}

			vec3 absorptionCoefficient = intersec.color;
			float translucentDensity = 0.1;
			float scatteringDistance = -log(rand(seed)) / translucentDensity;
			
			// transmission?
			if (scatteringDistance > t) 
			{
				mask *= exp(-absorptionCoefficient * t);

				r.origin = x;
				r.origin += r.direction * scatteringDistance;

				bounceIsSpecular = true;
				continue;
			}

			diffuseCount++;

			bounceIsSpecular = false;

			// else scattering
			mask *= exp(-absorptionCoefficient * scatteringDistance);
			
			if (diffuseCount == 1 && rand(seed) < diffuseColorBleeding)
                        {
                                // choose random Diffuse sample vector
				r = Ray( x, randomCosWeightedDirectionInHemisphere(nl, seed) );
				r.origin += r.direction * scatteringDistance;
				
				continue;
                        }
                        else
                        {
				weight = sampleSphereLight(x, nl, dirToLight, light, seed);
				mask *= clamp(weight, 0.0, 1.0);

                                r = Ray( x, dirToLight );
				r.origin += r.direction * scatteringDistance;
				
				sampleLight = true;
				continue;
                        }
			
		} // end if (intersec.type == SPECSUB)
		
                
	} // end for (int bounces = 0; bounces < 5; bounces++)
	
	
	return accumCol;      
}

//-----------------------------------------------------------------------
void SetupScene(void)
//-----------------------------------------------------------------------
{
	vec3 z  = vec3(0);// No color value, Black        
	vec3 L1 = vec3(1.0, 1.0, 1.0) * 4.0;// Bright light
		    
	spheres[0] = Sphere( 200.0, vec3(275.0, 620.0, -280.0), L1, z, LIGHT);// Light Sphere
	spheres[1] = Sphere(  90.0, vec3(150.0,  91.0, -200.0),  z, uLeftSphereColor, int(uLeftSphereMaterialType));// Sphere Left
	spheres[2] = Sphere(  90.0, vec3(400.0,  91.0, -200.0),  z, uRightSphereColor, int(uRightSphereMaterialType));// Sphere Right
	
	quads[0] = Quad( vec3( 0.0, 0.0, 1.0), vec3(  0.0,   0.0,-559.2), vec3(549.6,   0.0,-559.2), vec3(549.6, 548.8,-559.2), vec3(  0.0, 548.8,-559.2), z, vec3( 1.0,  1.0,  1.0), DIFF);// Back Wall
	quads[1] = Quad( vec3( 1.0, 0.0, 0.0), vec3(  0.0,   0.0,   0.0), vec3(  0.0,   0.0,-559.2), vec3(  0.0, 548.8,-559.2), vec3(  0.0, 548.8,   0.0), z, vec3( 0.7, 0.05, 0.05), DIFF);// Left Wall Red
	quads[2] = Quad( vec3(-1.0, 0.0, 0.0), vec3(549.6,   0.0,-559.2), vec3(549.6,   0.0,   0.0), vec3(549.6, 548.8,   0.0), vec3(549.6, 548.8,-559.2), z, vec3(0.05, 0.05, 0.7 ), DIFF);// Right Wall Blue
	quads[3] = Quad( vec3( 0.0,-1.0, 0.0), vec3(  0.0, 548.8,-559.2), vec3(549.6, 548.8,-559.2), vec3(549.6, 548.8,   0.0), vec3(  0.0, 548.8,   0.0), z, vec3( 1.0,  1.0,  1.0), DIFF);// Ceiling
	quads[4] = Quad( vec3( 0.0, 1.0, 0.0), vec3(  0.0,   0.0,   0.0), vec3(549.6,   0.0,   0.0), vec3(549.6,   0.0,-559.2), vec3(  0.0,   0.0,-559.2), z, vec3( 1.0,  1.0,  1.0), DIFF);// Floor
}

#include <pathtracing_main>