#version 300 es

precision highp float;
precision highp int;
precision highp sampler2D;

#include <pathtracing_uniforms_and_defines>

#define N_SPHERES 3
#define N_QUADS 6
#define N_BOXES 1


//-----------------------------------------------------------------------

struct Ray { vec3 origin; vec3 direction; };
struct Sphere { float radius; vec3 position; vec3 emission; vec3 color; int type; };
struct Quad { vec3 normal; vec3 v0; vec3 v1; vec3 v2; vec3 v3; vec3 emission; vec3 color; int type; };
struct Box { vec3 minCorner; vec3 maxCorner; vec3 emission; vec3 color; int type; };
struct Intersection { vec3 normal; vec3 emission; vec3 color; int type; };

Sphere spheres[N_SPHERES];
Quad quads[N_QUADS];
Box boxes[N_BOXES];

#include <pathtracing_random_functions>

#include <pathtracing_calc_fresnel_reflectance>

#include <pathtracing_sphere_intersect>

#include <pathtracing_cappedcylinder_intersect>

#include <pathtracing_quad_intersect>

#include <pathtracing_box_intersect>

#include <pathtracing_sample_quad_light>
// vec3 sampleQuadLight(vec3 x, vec3 nl, Quad light, vec3 dirToLight, out float weight, inout uvec2 seed)
// {
// 	float steps = 20.0;
// 	vec3 randPointOnLight;
// 	randPointOnLight.x = mix(light.v0.x, light.v1.x, clamp(floor((1.0 + steps) * rand(seed)) / steps, 0.1, 0.9));
// 	randPointOnLight.y = light.v0.y;
// 	randPointOnLight.z = mix(light.v0.z, light.v3.z, clamp(floor((1.0 + steps) * rand(seed)) / steps, 0.1, 0.9));
// 	dirToLight = randPointOnLight - x;
// 	float r2 = distance(light.v0, light.v1) * distance(light.v0, light.v3);
// 	float d2 = dot(dirToLight, dirToLight);
// 	float cos_a_max = sqrt(1.0 - clamp( r2 / d2, 0.0, 1.0));

// 	dirToLight = normalize(dirToLight);
// 	float dotNlRayDir = max(0.0, dot(nl, dirToLight)); 
// 	weight =  2.0 * (1.0 - cos_a_max) * max(0.0, -dot(dirToLight, light.normal)) * dotNlRayDir; 
// 	weight = clamp(weight, 0.0, 1.0);

// 	return dirToLight;
// }


mat4 makeRotateY(float rot)
{
	float s = sin(rot);
	float c = cos(rot);
	
	return mat4(
	 	c, 0, s, 0,
	 	0, 1, 0, 0,
	       -s, 0, c, 0,
	 	0, 0, 0, 1 
	);
}

mat4 makeRotateX(float rot)
{
	float s = sin(rot);
	float c = cos(rot);
	
	return mat4(
		1, 0,  0, 0,
		0, c, -s, 0,
		0, s,  c, 0,
		0, 0,  0, 1
	);
}

mat4 makeRotateZ(float rot)
{
	float s = sin(rot);
	float c = cos(rot);
	
	return mat4(
		c, -s, 0, 0,
		s,  c, 0, 0,
		0,  0, 1, 0,
		0,  0, 0, 1
	);
}


//--------------------------------------------------------------------------
float SceneIntersect( Ray r, inout Intersection intersec, inout uvec2 seed )
//--------------------------------------------------------------------------
{
	Ray warpedRay;
	vec3 n, n1, n2;
	vec3 intersectionPoint;
	vec3 offset;

	float d;
	float t = INFINITY;
	
	bool isRayExiting = false;
	

	/*
        for (int i = 0; i < N_SPHERES; i++)
        {
		if (i == 0) // Sphere Light
		{
			d = SphereIntersect( spheres[i].radius, spheres[i].position, r );
			offset = vec3(0);
		}
		else if (i == 1 || i == 2) // Twisted Spheres
		{
			warpedRay = r;

			float torusThickness = 10.0;
			d = CappedCylinderIntersect( spheres[i].position - vec3(0, 0, torusThickness), spheres[i].position + vec3(0, 0, torusThickness), spheres[i].radius, warpedRay, n);
			if (d == INFINITY) continue;

			vec3 hitPos = warpedRay.origin + warpedRay.direction * d;
			vec3 hitVec = (hitPos - spheres[i].position);
			hitVec.z = 0.0;
			hitVec = normalize(hitVec);
			
			vec3 spherePos = spheres[i].position + (hitVec * (90.0 - torusThickness));

			d = SphereIntersect( torusThickness, spherePos, warpedRay );
			if (d < t)
			{
				t = d;
				intersectionPoint = warpedRay.origin + warpedRay.direction * d;
				intersec.normal = normalize(intersectionPoint - spherePos);
				intersec.emission = spheres[i].emission;
				intersec.color = spheres[i].color;
				intersec.type = spheres[i].type;
			}
		}
		else if (i == 3) // Cloudy Sphere
		{
			float dense = 1.0 + rand(seed);
			offset = (spheres[i].radius*0.5) * (vec3(rand(seed) * 2.0 - 1.0, rand(seed) * 2.0 - 1.0, rand(seed) * 2.0 - 1.0));
			d = SphereIntersect( spheres[i].radius * dense, spheres[i].position + offset, r);
		}
		
		if (d < t)
		{
			t = d;
			intersectionPoint = r.origin + r.direction * d;
			vec3 tempNormal = (intersectionPoint - (spheres[i].position + offset));
			intersec.normal = normalize(tempNormal);
			intersec.emission = spheres[i].emission;
			intersec.color = spheres[i].color;
			intersec.type = spheres[i].type;
		}
        }
	*/

	for (int i = 0; i < N_SPHERES; i++)
        {
		
		if (i < 2) // Twisted Spheres
		{
			d = SphereIntersect( spheres[i].radius, spheres[i].position, r );
			if (d == INFINITY) continue;
			intersectionPoint = r.origin + r.direction * d;
			float angle = mod(intersectionPoint.y * 0.1, TWO_PI);
			mat4 m = makeRotateY(angle);
			vec3 o = ( m * vec4(intersectionPoint, 1.0) ).xyz;
			offset = o * 0.1;
			d = SphereIntersect( spheres[i].radius, spheres[i].position + offset, r);
		}
		else // Cloudy Sphere
		{
			float width = 2.0 * rand(seed);
			offset = (spheres[i].radius * 0.5) * (vec3(rand(seed) * 2.0 - 1.0, rand(seed) * 2.0 - 1.0, rand(seed) * 2.0 - 1.0));
			d = SphereIntersect( spheres[i].radius + width, spheres[i].position + offset, r);
		}
		
		if (d < t)
		{
			t = d;
			intersectionPoint = r.origin + r.direction * d;
			vec3 tempNormal = (intersectionPoint - (spheres[i].position + offset));
			intersec.normal = normalize(tempNormal);
			intersec.emission = spheres[i].emission;
			intersec.color = spheres[i].color;
			intersec.type = spheres[i].type;
		}
	}
	
	for (int i = 0; i < N_BOXES; i++)
        {
		warpedRay = r;
                warpedRay.origin.x -= 200.0;
                warpedRay.origin.y -= 200.0;
                warpedRay.origin.z += 400.0;
                
                d = BoxIntersect( boxes[i].minCorner * vec3(1.5, 1.0, 1.5), boxes[i].maxCorner * vec3(1.5, 1.0, 1.5), warpedRay, n, isRayExiting );
                if (d == INFINITY) continue;
            	
                vec3 hitPos = warpedRay.origin + warpedRay.direction * d;
                //float angle = 0.25 * PI;
		float angle = mod(hitPos.y * 0.015, TWO_PI);
		mat4 m = makeRotateY(angle);
                m = inverse(m);
                warpedRay.origin = vec3( m * vec4(warpedRay.origin, 1.0) );
		warpedRay.direction = normalize(vec3( m * vec4(warpedRay.direction, 0.0) ));
                
		d = BoxIntersect( boxes[i].minCorner, boxes[i].maxCorner, warpedRay, n, isRayExiting );
		if (d < t)
		{
			t = d;
			intersec.normal = normalize(n);
                        intersec.normal = normalize(vec3( transpose(m) * vec4(intersec.normal, 0.0) ));
			intersec.emission = boxes[i].emission;
			intersec.color = boxes[i].color;
			intersec.type = boxes[i].type;
		}
        }
	
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
	float thickness = 0.04;

	int diffuseCount = 0;

	bool bounceIsSpecular = true;
	bool sampleLight = false;
	bool firstTypeWasREFR = false;
	bool reflectionTime = false;
	bool firstTypeWasDIFF = false;
	bool shadowTime = false;

	
	for (int bounces = 0; bounces < 6; bounces++)
	{

		t = SceneIntersect(r, intersec, seed);
		
		
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
			
			// is ray leaving a solid object from the inside? 
			// If so, attenuate ray color with object color by how far ray has travelled through the medium
			if (n != nl)
			{
				mask *= exp(log(intersec.color) * thickness * t);
			}
			
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
		
	} // end for (int bounces = 0; bounces < 6; bounces++)
	
	
	return max(vec3(0), accumCol);

} // end vec3 CalculateRadiance( Ray r, inout uvec2 seed )



//-----------------------------------------------------------------------
void SetupScene(void)
//-----------------------------------------------------------------------
{
	vec3 z  = vec3(0);// No color value, Black        
	vec3 L1 = vec3(1.0, 1.0, 1.0) * 6.0;// Bright light
	
	spheres[0] = Sphere( 90.0, vec3(150.0,  91.0, -200.0),  z, vec3(0.4, 1.0, 1.0),  REFR);// Sphere Left
	spheres[1] = Sphere( 90.0, vec3(400.0,  91.0, -200.0),  z, vec3(1.0, 1.0, 1.0),  COAT);// Sphere Right
	spheres[2] = Sphere( 60.0, vec3(450.0, 380.0, -300.0),  z, vec3(1.0, 0.0, 1.0),  DIFF);// Cloud Sphere Top Right
	
	boxes[0]  = Box( vec3(-82, -170, -80), vec3(82, 170, 80), z, vec3(1.0, 1.0, 1.0), SPEC);// Tall Mirror Box Left
	
	quads[0] = Quad( vec3( 0.0, 0.0, 1.0), vec3(  0.0,   0.0,-559.2), vec3(549.6,   0.0,-559.2), vec3(549.6, 548.8,-559.2), vec3(  0.0, 548.8,-559.2), z, vec3( 1.0,  1.0,  1.0), DIFF);// Back Wall
	quads[1] = Quad( vec3( 1.0, 0.0, 0.0), vec3(  0.0,   0.0,   0.0), vec3(  0.0,   0.0,-559.2), vec3(  0.0, 548.8,-559.2), vec3(  0.0, 548.8,   0.0), z, vec3( 0.7, 0.05, 0.05), DIFF);// Left Wall Red
	quads[2] = Quad( vec3(-1.0, 0.0, 0.0), vec3(549.6,   0.0,-559.2), vec3(549.6,   0.0,   0.0), vec3(549.6, 548.8,   0.0), vec3(549.6, 548.8,-559.2), z, vec3(0.05, 0.05, 0.7 ), DIFF);// Right Wall Blue
	quads[3] = Quad( vec3( 0.0,-1.0, 0.0), vec3(  0.0, 548.8,-559.2), vec3(549.6, 548.8,-559.2), vec3(549.6, 548.8,   0.0), vec3(  0.0, 548.8,   0.0), z, vec3( 1.0,  1.0,  1.0), DIFF);// Ceiling
	quads[4] = Quad( vec3( 0.0, 1.0, 0.0), vec3(  0.0,   0.0,   0.0), vec3(549.6,   0.0,   0.0), vec3(549.6,   0.0,-559.2), vec3(  0.0,   0.0,-559.2), z, vec3( 1.0,  1.0,  1.0), DIFF);// Floor

	quads[5] = Quad( vec3( 0.0,-1.0, 0.0), vec3(213.0, 548.0,-332.0), vec3(343.0, 548.0,-332.0), vec3(343.0, 548.0,-227.0), vec3(213.0, 548.0,-227.0), L1, z, LIGHT);// Area Light Rectangle in ceiling	
}


#include <pathtracing_main>
