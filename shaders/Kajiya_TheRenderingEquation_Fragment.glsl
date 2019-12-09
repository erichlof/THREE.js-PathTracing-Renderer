#version 300 es

precision highp float;
precision highp int;
precision highp sampler2D;

#include <pathtracing_uniforms_and_defines>

#define N_LIGHTS 3.0
#define N_SPHERES 12
#define N_ELLIPSOIDS 2
#define N_BOXES 6
#define N_RECTANGLES 3

//-----------------------------------------------------------------------

struct Ray { vec3 origin; vec3 direction; };
struct Sphere { float radius; vec3 position; vec3 emission; vec3 color; int type; };
struct Ellipsoid { vec3 radii; vec3 position; vec3 emission; vec3 color; int type; };
struct Rectangle { vec3 position; vec3 normal; float radiusU; float radiusV; vec3 emission; vec3 color; int type; };
struct Box { vec3 minCorner; vec3 maxCorner; vec3 emission; vec3 color; int type; };
struct Intersection { vec3 normal; vec3 emission; vec3 color; int type; };

Sphere spheres[N_SPHERES];
Ellipsoid ellipsoids[N_ELLIPSOIDS];
Rectangle rectangles[N_RECTANGLES];
Box boxes[N_BOXES];


#include <pathtracing_random_functions>

#include <pathtracing_calc_fresnel_reflectance>

#include <pathtracing_rectangle_intersect>

#include <pathtracing_sphere_intersect>

#include <pathtracing_ellipsoid_intersect>

#include <pathtracing_box_intersect>


//-----------------------------------------------------------------------
float SceneIntersect( Ray r, inout Intersection intersec )
//-----------------------------------------------------------------------
{
	float d;
	float t = INFINITY;
	vec3 n;
	
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
	
	for (int i = 0; i < N_ELLIPSOIDS; i++)
        {
		d = EllipsoidIntersect( ellipsoids[i].radii, ellipsoids[i].position, r );
		if (d < t)
		{
			t = d;
			intersec.normal = normalize( ((r.origin + r.direction * t) - ellipsoids[i].position) / (ellipsoids[i].radii * ellipsoids[i].radii) );
			intersec.emission = ellipsoids[i].emission;
			intersec.color = ellipsoids[i].color;
			intersec.type = ellipsoids[i].type;
		}
	}
	
        
	for (int i = 0; i < N_BOXES; i++)
        {
		d = BoxIntersect( boxes[i].minCorner, boxes[i].maxCorner, r, n );
		if (d < t)
		{
			t = d;
			intersec.normal = normalize(n);
			intersec.emission = boxes[i].emission;
			intersec.color = boxes[i].color;
			intersec.type = boxes[i].type;
		}
	}
	
	for (int i = 0; i < N_RECTANGLES; i++)
        {
		d = RectangleIntersect( rectangles[i].position, rectangles[i].normal, rectangles[i].radiusU, rectangles[i].radiusV, r );
		if (d < t)
		{
			t = d;
			intersec.normal = normalize(rectangles[i].normal);
			intersec.emission = rectangles[i].emission;
			intersec.color = rectangles[i].color;
			intersec.type = rectangles[i].type;
		}
        }
	
	return t;
	
} // end float SceneIntersect( Ray r, inout Intersection intersec )


vec3 sampleRectangleLight(vec3 x, vec3 nl, Rectangle light, vec3 dirToLight, out float weight, inout uvec2 seed)
{
	vec3 u = normalize(cross( abs(light.normal.y) < 0.9 ? vec3(0, 1, 0) : vec3(0, 0, 1), light.normal));
	vec3 v = cross(light.normal, u);
	vec3 randPointOnLight = light.position;

	randPointOnLight += mix(u * -light.radiusU * 0.9, u * light.radiusU * 0.9, rand(seed));
	randPointOnLight += mix(v * -light.radiusV * 0.9, v * light.radiusV * 0.9, rand(seed));
	
	dirToLight = randPointOnLight - x;
	float r2 = (light.radiusU * 2.0) * (light.radiusV * 2.0);
	float d2 = dot(dirToLight, dirToLight);
	float cos_a_max = sqrt(1.0 - clamp( r2 / d2, 0.0, 1.0));

	dirToLight = normalize(dirToLight);
	float dotNlRayDir = max(0.0, dot(nl, dirToLight)); 
	weight = 2.0 * (1.0 - cos_a_max) * max(0.0, -dot(dirToLight, light.normal)) * dotNlRayDir;
	weight = clamp(weight, 0.0, 1.0);

	return dirToLight;
}


//-----------------------------------------------------------------------
vec3 CalculateRadiance( Ray r, inout uvec2 seed )
//-----------------------------------------------------------------------
{
	Intersection intersec;
	Rectangle lightChoice;
	Ray firstRay;

	vec3 accumCol = vec3(0);
        vec3 mask = vec3(1);
	vec3 firstMask = vec3(1);
	vec3 tdir;
	vec3 randPointOnLight, dirToLight;
	vec3 skyColor;
	vec3 x, n, nl;
        
	float diffuseColorBleeding = 0.4; // range: 0.0 - 0.5, amount of color bleeding between surfaces
	float t;
	float weight;
	float nc, nt, ratioIoR, Re, Tr;
	float randChoose;

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

			skyColor = mix(vec3(0), vec3(0.004, 0.0, 0.04), clamp(exp(r.direction.y * -15.0), 0.0, 1.0));
			
			if (bounces == 0)
			{
				accumCol = mask * skyColor;
				break;
			}

			if (firstTypeWasDIFF) 
			{
				// sky light is mostly black, so it does not contribute to diffuse surfaces

				if (!shadowTime)
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

				break;
			}
				
			if (firstTypeWasREFR)
			{
				if (!reflectionTime) 
				{
					accumCol = mask * skyColor;
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
				
				// add reflective result to the refractive result (if any)
				accumCol += mask * skyColor;
				break;
			}
			
			// reached a sky light, so we can exit
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
		
		randChoose = rand(seed) * 3.0; // 3 lights to choose from
		lightChoice = rectangles[int(randChoose)];

		    
                if (intersec.type == DIFF ) // Ideal DIFFUSE reflection
		{
			diffuseCount++;

			mask *= intersec.color;

			bounceIsSpecular = false;

			if (diffuseCount == 1 && !firstTypeWasDIFF && !firstTypeWasREFR)
			{	
				// save intersection data for future shadowray trace
				firstTypeWasDIFF = true;
				dirToLight = sampleRectangleLight(x, nl, lightChoice, dirToLight, weight, seed);
				firstMask = mask * weight *  N_LIGHTS;
                                firstRay = Ray( x, normalize(dirToLight) ); // create shadow ray pointed towards light
				firstRay.origin += nl * uEPS_intersect;

				// choose random Diffuse sample vector
				r = Ray( x, normalize(randomCosWeightedDirectionInHemisphere(nl, seed)) );
				r.origin += nl * uEPS_intersect;
				continue;
			}
			else if (firstTypeWasREFR && diffuseCount == 1 && rand(seed) < diffuseColorBleeding)
			{
				// choose random Diffuse sample vector
				r = Ray( x, normalize(randomCosWeightedDirectionInHemisphere(nl, seed)) );
				r.origin += nl * uEPS_intersect;
				continue;
			}
                        
			dirToLight = sampleRectangleLight(x, nl, lightChoice, dirToLight, weight, seed);
			mask *= weight * N_LIGHTS;

			r = Ray( x, normalize(dirToLight) );
			r.origin += nl * uEPS_intersect;

			sampleLight = true;
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

			// turn on refracting caustics
			if (diffuseCount == 1 && bounces < 3)
			{
				if (t < 10.0)
					bounceIsSpecular = true;
			}

			continue;
			
		} // end if (intersec.type == REFR)
		
	} // end for (int bounces = 0; bounces < 6; bounces++)
	
	
	return max(vec3(0), accumCol);
	     
}


//-----------------------------------------------------------------------
void SetupScene(void)
//-----------------------------------------------------------------------
{
	vec3 z  = vec3(0.0);
	vec3 lightColor = vec3(1.0, 0.8, 0.4);          
	vec3 L1 = lightColor * 40.0;
	vec3 L2 = lightColor * 60.0;
	vec3 L3 = lightColor * 100.0;
	vec3 glassColor = vec3(0.5, 1.0, 0.9);
	vec3 diffuseColor = vec3(1);
	
        spheres[0] = Sphere( 10.0, vec3(   0,   10,    0), z, glassColor, REFR);//Glass sphere
	spheres[1] = Sphere( 10.0, vec3(  10,   10,-17.5), z, glassColor, REFR);//Glass sphere
	spheres[2] = Sphere( 10.0, vec3(  20,   10,  -35), z, glassColor, REFR);//Glass sphere
	spheres[3] = Sphere( 10.0, vec3( -10,   10,-17.5), z, glassColor, REFR);//Glass sphere
	spheres[4] = Sphere( 10.0, vec3( -20,   10,  -35), z, glassColor, REFR);//Glass sphere
	spheres[5] = Sphere( 10.0, vec3(   0,   10,  -35), z, glassColor, REFR);//Glass sphere
	spheres[6] = Sphere( 10.0, vec3(   0,   26,  -12), z, glassColor, REFR);//Glass sphere
	spheres[7] = Sphere( 10.0, vec3(  10,   26,-29.5), z, glassColor, REFR);//Glass sphere
	spheres[8] = Sphere( 10.0, vec3( -10,   26,-29.5), z, glassColor, REFR);//Glass sphere
	spheres[9] = Sphere( 10.0, vec3(   0, 41.5,  -24), z, glassColor, REFR);//Glass sphere
	
	spheres[10] = Sphere( 10.0, vec3( -40,  80,  -80), z, glassColor, REFR);//Glass sphere on top of Far Tall Column Box
	spheres[11] = Sphere( 10.0, vec3( -60,  80,   10), z, glassColor, REFR);//Glass sphere on top of Near Tall Column Box
        
	ellipsoids[0] = Ellipsoid( vec3(  12, 80,  12), vec3(  27, -20,  40), z, diffuseColor, DIFF);//vertical ellipsoid
	ellipsoids[1] = Ellipsoid( vec3(  25,  3,  25), vec3(  27,  48,  40), z, diffuseColor, DIFF);//horizontal ellipsoid
	boxes[0] = Box( vec3(9, 0, 22), vec3(45, 10, 58), z, diffuseColor, DIFF);//Short Box Platform on Right, underneath ellipsoids
	
	boxes[1] = Box( vec3( -50,  10, -90), vec3( -30, 70, -70), z, diffuseColor, DIFF);//Tall Box Column Left Far
	boxes[2] = Box( vec3( -60,   0,-100), vec3( -20, 10, -60), z, diffuseColor, DIFF);//Short Box Platform Left Far
	boxes[3] = Box( vec3( -70,  10,   0), vec3( -50, 70,  20), z, diffuseColor, DIFF);//Tall Box Left Column Near
	boxes[4] = Box( vec3( -80,   0, -10), vec3( -40, 10,  30), z, diffuseColor, DIFF);//Short Box Platform Left Near
	boxes[5] = Box( vec3(-500, -10,-500), vec3( 500,  0, 500), z, vec3(1.0, 0.55, 0.07), DIFF);//Yellowish Large Floor Box

	rectangles[0] = Rectangle( vec3( 10, 200,  50), normalize(vec3( 0, -1,  0)),  6.0,  6.0, L1, z, LIGHT);// Area Light Rect Overhead 
	rectangles[1] = Rectangle( vec3(200, 110,  70), normalize(vec3(-1,  0,  0)), 13.0, 13.0, L2, z, LIGHT);// Area Light Rect Right
	rectangles[2] = Rectangle( vec3(-10, 220,-200), normalize(vec3( 0, -1,  0)), 10.0, 10.0, L3, z, LIGHT);// Area Light Rect Far
}


#include <pathtracing_main>
