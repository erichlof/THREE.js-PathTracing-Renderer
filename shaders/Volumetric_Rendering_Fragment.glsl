#version 300 es

precision highp float;
precision highp int;
precision highp sampler2D;

#include <pathtracing_uniforms_and_defines>

#define N_SPHERES 3
#define N_QUADS 3


//-----------------------------------------------------------------------

struct Ray { vec3 origin; vec3 direction; };
struct Sphere { float radius; vec3 position; vec3 emission; vec3 color; int type; };
struct Quad { vec3 normal; vec3 v0; vec3 v1; vec3 v2; vec3 v3; vec3 emission; vec3 color; int type; };
struct Intersection { vec3 normal; vec3 emission; vec3 color; int type; };

Sphere spheres[N_SPHERES];
Quad quads[N_QUADS];


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
		if (d < t && d > 0.0)
		{
			t = d;
			intersec.normal = normalize( quads[i].normal );
			intersec.emission = quads[i].emission;
			intersec.color = quads[i].color;
			intersec.type = quads[i].type;
		}
        }
	
	return t;
}

/* Credit: Some of the equi-angular sampling code is borrowed from https://www.shadertoy.com/view/Xdf3zB posted by user 'sjb' ,
// who in turn got it from the paper 'Importance Sampling Techniques for Path Tracing in Participating Media' ,
which can be viewed at: https://docs.google.com/viewer?url=https%3A%2F%2Fwww.solidangle.com%2Fresearch%2Fegsr2012_volume.pdf */
void sampleEquiAngular( float u, float maxDistance, Ray r, vec3 lightPos, out float dist, out float pdf )
{
	// get coord of closest point to light along (infinite) ray
	float delta = dot(lightPos - r.origin, r.direction);
	
	// get distance this point is from light
	float D = distance(r.origin + delta*r.direction, lightPos);

	// get angle of endpoints
	float thetaA = atan(0.0 - delta, D);
	float thetaB = atan(maxDistance - delta, D);

	// take sample
	float t = D*tan(mix(thetaA, thetaB, u));
	dist = delta + t;
	pdf = D/((thetaB - thetaA)*(D*D + t*t));
}


#define FOG_COLOR vec3(0.05, 0.05, 0.4) // color of the fog / participating medium
#define FOG_DENSITY 0.0005 // this is dependent on the particular scene size dimensions
#define LIGHT_COLOR vec3(1.0, 1.0, 1.0) // color of light source
#define LIGHT_POWER 30.0 // brightness of light source

//-----------------------------------------------------------------------
vec3 CalculateRadiance( Ray r, inout uvec2 seed )
//-----------------------------------------------------------------------
{
	Intersection intersec;
	Intersection vintersec;
	Ray cameraRay = r;
	Ray vray;

	vec3 accumCol = vec3(0.0);
        vec3 mask = vec3(1.0);
	vec3 dirToLight;
	vec3 lightVec;
	vec3 particlePos;
	vec3 tdir;
	
	float nc, nt, ratioIoR, Re, Tr;
        float weight;
	float t, vt, camt;
	float xx;
	float pdf;
	float d;
	float geomTerm;
	float trans;

	int diffuseCount = 0;
	int prevIntersecType = -1;
	
	bool bounceIsSpecular = true;
	
	// depth of 4 is required for higher quality glass refraction
        for (int bounces = 0; bounces < 4; bounces++)
	{
		
		float u = rand(seed);
		
		t = SceneIntersect(r, intersec);
		
		// on first loop iteration, save intersection distance along camera ray (t) into camt variable for use below
		if (bounces == 0) 
			camt = t;

		// sample along intial ray from camera into the scene
		sampleEquiAngular(u, camt, cameraRay, spheres[0].position, xx, pdf);

		// create a particle along cameraRay and cast a shadow ray towards light (similar to Direct Lighting)
		particlePos = cameraRay.origin + xx * cameraRay.direction;
		lightVec = spheres[0].position - particlePos;
		d = length(lightVec);
		vray = Ray(particlePos, normalize(lightVec));

		vt = SceneIntersect(vray, vintersec);
		
		// if the particle can see the light source, apply volumetric lighting calculation
		if (vintersec.type == LIGHT)
		{	
			trans = exp( -((d + xx) * FOG_DENSITY) );
			geomTerm = 1.0 / (d * d);
			
			accumCol += FOG_COLOR * vintersec.emission * geomTerm * trans / pdf;
		}
		// otherwise the particle will remain in shadow - this is what produces the shafts of light vs. the volume shadows

		
		// now do the normal path tracing routine with the camera ray
		if (intersec.type == LIGHT)
		{	
			if (bounceIsSpecular)
			{
				trans = exp( -((d + camt) * FOG_DENSITY) );
				accumCol += mask * intersec.emission * trans;	
			}
			bounceIsSpecular = false;

			// normally we would 'break' here, but 'continue' allows more particles to be lit
			continue; 
		}
		
		// useful data 
		vec3 n = intersec.normal;
                vec3 nl = dot(n,r.direction) <= 0.0 ? normalize(n) : normalize(n * -1.0);
		vec3 x = r.origin + r.direction * t;
		
		    
                if (intersec.type == DIFF) // Ideal DIFFUSE reflection
                {
			diffuseCount++;

			mask *= intersec.color;

			/*
			// Russian Roulette
			float p = max(mask.r, max(mask.g, mask.b));
			if (bounces > 0)
			{
				if (rand(seed) < p)
					mask *= 1.0 / p;
				else
					break;
			}
			*/

			if (diffuseCount == 1 && rand(seed) < 0.5)
			{
				// choose random Diffuse sample vector
				dirToLight = normalize(spheres[0].position - x);
				r = Ray( x, normalize(randomCosWeightedDirectionInHemisphere(dirToLight, seed)) );
				r.origin += nl;
				
				bounceIsSpecular = false;
				continue;
			}
			else
			{
				dirToLight = sampleSphereLight(x, nl, spheres[0], dirToLight, weight, seed);
				mask *= weight;

				r = Ray( x, normalize(dirToLight) );
				r.origin += nl;
				
				bounceIsSpecular = true;
				continue;
			}	
                }
		
                if (intersec.type == SPEC)  // Ideal SPECULAR reflection
                {
			mask *= intersec.color;

			r = Ray( x, reflect(r.direction, nl) );

                        r.origin += nl;
                        
                        //bounceIsSpecular = true; // turn on mirror caustics
			
                        continue;
                }

                if (intersec.type == REFR)  // Ideal dielectric REFRACTION
		{
			nc = 1.0; // IOR of Air
			nt = 1.5; // IOR of common Glass
			Re = calcFresnelReflectance(r.direction, n, nc, nt, ratioIoR);
			Tr = 1.0 - Re;

			if (rand(seed) < Re) // reflect ray from surface
			{
				r = Ray( x, reflect(r.direction, nl) );
				r.origin += nl;
				    
				//bounceIsSpecular = true; // turn on reflecting caustics, useful for water
			    	continue;	
			}
			else // transmit ray through surface
			{
				mask *= intersec.color;

				tdir = refract(r.direction, nl, ratioIoR);
				r = Ray(x, tdir);
				r.origin -= nl;

				//bounceIsSpecular = true; // turn on refracting caustics
				continue;
			}
		} // end if (intersec.type == REFR)
		
		if (intersec.type == COAT)  // Diffuse object underneath with ClearCoat on top
		{
			nc = 1.0; // IOR of air
			nt = 1.4; // IOR of ClearCoat 
			Re = calcFresnelReflectance(r.direction, n, nc, nt, ratioIoR);
			Tr = 1.0 - Re;
			
			// choose either specular reflection or diffuse
			if( rand(seed) < Re )
			{	
				r = Ray( x, reflect(r.direction, nl) );
				r.origin += nl;
				continue;	
			}

			diffuseCount++;

			bounceIsSpecular = false;

			mask *= intersec.color;

			if (diffuseCount == 1 && rand(seed) < 0.5)
                        {
                                // choose random Diffuse sample vector
				dirToLight = normalize(spheres[0].position - x);
				r = Ray( x, normalize(randomCosWeightedDirectionInHemisphere(dirToLight, seed)) );
				r.origin += nl;
				continue;
				
				bounceIsSpecular = false;
				continue;
                        }
                        else
                        {
				dirToLight = sampleSphereLight(x, nl, spheres[0], dirToLight, weight, seed);
				mask *= weight;

				r = Ray( x, normalize(dirToLight) );
				r.origin += nl;
				
				bounceIsSpecular = true;
				continue;
                        }
			
		} //end if (intersec.type == COAT)
		
        } // end for (int bounces = 0; bounces < 4; bounces++)
	
	// Now we go hunting for volumetric caustics! A previously created particle (vray) is chosen
	// as a starting point, the ray origin. Next, Randomize the ray direction based on glass sphere's radius.
	// Then trace towards the light source, eventually rays will refract at just the right angles to find the light!
	r.origin = vray.origin;
	vec3 lp = spheres[0].position + (normalize(randomSphereDirection(seed)) * spheres[1].radius * 0.9);
	r.direction = normalize(lp - r.origin);
	mask = vec3(1.0); // reset color mask for this particle

	// depth of 3 needed to possibly travel into glass sphere, out of it, and then find light = 3 iterations
	for (int bounces = 0; bounces < 3; bounces++)
	{
		
		t = SceneIntersect(r, intersec);

		// early out test, we are only looking for glass objects and light sources
		if (intersec.type != REFR && intersec.type != LIGHT)
			break;
		
		// useful data 
		vec3 n = intersec.normal;
		vec3 nl = dot(n,r.direction) <= 0.0 ? normalize(n) : normalize(n * -1.0);
		vec3 x = r.origin + r.direction * t;

		if (intersec.type == REFR)  // Ideal dielectric REFRACTION
		{
			nc = 1.0; // IOR of Air
			nt = 1.5; // IOR of common Glass
			Re = calcFresnelReflectance(r.direction, n, nc, nt, ratioIoR);
			Tr = 1.0 - Re;

			if (Re > 0.99)
			{
				r = Ray( x, reflect(r.direction, nl) ); // reflect ray from surface
				r.origin += nl;
				continue;
			}
			
			if (rand(seed) < Re) // reflect ray from surface
			{
				r = Ray( x, reflect(r.direction, nl) );
			    	r.origin += nl;
				
				prevIntersecType = SPEC;
			    	continue;	
			}
			else // transmit ray through surface
			{
				mask *= intersec.color;
				tdir = refract(r.direction, nl, ratioIoR);
				r = Ray(x, tdir);
				r.origin -= nl;
				
				prevIntersecType = REFR;
				continue;
			}
		} // end if (intersec.type == REFR)

		if (intersec.type == LIGHT)
		{	
			// if we have just traveled through a refractive surface(REFR) like glass, then 
			// allow particle to be lit, producing volumetric caustics
			if (prevIntersecType == REFR && bounces == 2)
			{
				trans = exp( -((d + xx) * FOG_DENSITY) );
				accumCol += FOG_COLOR * mask * intersec.emission * trans;
			}
			
			break;
		}

        } // end for (int bounces = 0; bounces < 3; bounces++)


	return max(vec3(0), accumCol);

}

//-----------------------------------------------------------------------
void SetupScene(void)
//-----------------------------------------------------------------------
{
	vec3 z  = vec3(0.0);// No color value, Black        
	vec3 L1 = LIGHT_COLOR * LIGHT_POWER;
		    
	spheres[0] = Sphere( 10.0, vec3(275.0, 430.0, -280.0), L1, z, LIGHT);// Light Sphere
	
	spheres[1] = Sphere(  90.0, vec3(170.0, 201.0, -200.0),  z, vec3(1.0, 1.0, 1.0),  REFR);// Glass Sphere Left
	spheres[2] = Sphere(  90.0, vec3(390.0, 250.0, -250.0),  z, vec3(1.0, 1.0, 1.0),  COAT);// ClearCoat Sphere Right
	
	quads[0] = Quad( vec3( 0.0, 0.0, 1.0), vec3(  0.0,   0.0,-559.2), vec3(549.6,   0.0,-559.2), vec3(549.6, 548.8,-559.2), vec3(  0.0, 548.8,-559.2), z, vec3( 1.0,  1.0,  1.0), DIFF);// Back Wall
	quads[1] = Quad( vec3( 1.0, 0.0, 0.0), vec3(  0.0,   0.0,   0.0), vec3(  0.0,   0.0,-559.2), vec3(  0.0, 548.8,-559.2), vec3(  0.0, 548.8,   0.0), z, vec3( 0.7, 0.05, 0.05), DIFF);// Left Wall Red
	quads[2] = Quad( vec3(-1.0, 0.0, 0.0), vec3(549.6,   0.0,-559.2), vec3(549.6,   0.0,   0.0), vec3(549.6, 548.8,   0.0), vec3(549.6, 548.8,-559.2), z, vec3(0.05, 0.05, 0.7 ), DIFF);// Right Wall Blue
	//quads[3] = Quad( vec3( 0.0,-1.0, 0.0), vec3(  0.0, 548.8,-559.2), vec3(549.6, 548.8,-559.2), vec3(549.6, 548.8,   0.0), vec3(  0.0, 548.8,   0.0), z, vec3( 1.0,  1.0,  1.0), DIFF);// Ceiling
	//quads[4] = Quad( vec3( 0.0, 1.0, 0.0), vec3(  0.0,   0.0,   0.0), vec3(549.6,   0.0,   0.0), vec3(549.6,   0.0,-559.2), vec3(  0.0,   0.0,-559.2), z, vec3( 1.0,  1.0,  1.0), DIFF);// Floor
	
}


#include <pathtracing_main>
