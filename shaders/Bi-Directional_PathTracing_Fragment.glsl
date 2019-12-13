#version 300 es

precision highp float;
precision highp int;
precision highp sampler2D;

#include <pathtracing_uniforms_and_defines>

#define N_SPHERES 4
#define N_ELLIPSOIDS 1
#define N_OPENCYLINDERS 6
#define N_CONES 1
#define N_DISKS 1
#define N_QUADS 5
#define N_BOXES 1

struct Ray { vec3 origin; vec3 direction; };
struct Sphere { float radius; vec3 position; vec3 emission; vec3 color; float roughness; int type; };
struct Ellipsoid { vec3 radii; vec3 position; vec3 emission; vec3 color; float roughness; int type; };
struct OpenCylinder { float radius; vec3 pos1; vec3 pos2; vec3 emission; vec3 color; float roughness; int type; };
struct Cone { vec3 pos0; float radius0; vec3 pos1; float radius1; vec3 emission; vec3 color; float roughness; int type; };
struct Disk { float radius; vec3 pos; vec3 normal; vec3 emission; vec3 color; float roughness; int type; };
struct Quad { vec3 normal; vec3 v0; vec3 v1; vec3 v2; vec3 v3; vec3 emission; vec3 color; float roughness; int type; };
struct Box { vec3 minCorner; vec3 maxCorner; vec3 emission; vec3 color; float roughness; int type; };
struct Intersection { vec3 normal; vec3 emission; vec3 color; float roughness; int type; };

Sphere spheres[N_SPHERES];
Ellipsoid ellipsoids[N_ELLIPSOIDS];
OpenCylinder openCylinders[N_OPENCYLINDERS];
Cone cones[N_CONES];
Disk disks[N_DISKS];
Quad quads[N_QUADS];
Box boxes[N_BOXES];

#include <pathtracing_random_functions>

#include <pathtracing_calc_fresnel_reflectance>

#include <pathtracing_sphere_intersect>

#include <pathtracing_ellipsoid_intersect>

#include <pathtracing_opencylinder_intersect>

#include <pathtracing_cone_intersect>

#include <pathtracing_disk_intersect>

#include <pathtracing_quad_intersect>

#include <pathtracing_box_intersect>

#include <pathtracing_sample_sphere_light>



//-----------------------------------------------------------------------
float SceneIntersect( Ray r, inout Intersection intersec )
//-----------------------------------------------------------------------
{
	vec3 normal;
        float d;
	float t = INFINITY;
			
	// ROOM
	for (int i = 0; i < N_QUADS; i++)
        {
		d = QuadIntersect( quads[i].v0, quads[i].v1, quads[i].v2, quads[i].v3, quads[i].normal, r );
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
	
	// TABLETOP
	d = BoxIntersect( boxes[0].minCorner, boxes[0].maxCorner, r, normal );
	if (d < t)
	{
		t = d;
		intersec.normal = normalize(normal);
		intersec.emission = boxes[0].emission;
		intersec.color = boxes[0].color;
		intersec.roughness = boxes[0].roughness;
		intersec.type = boxes[0].type;
	}
	
	// TABLE LEGS, LAMP POST, and SPOTLIGHT CASING
	for (int i = 0; i < N_OPENCYLINDERS; i++)
        {
		d = OpenCylinderIntersect( openCylinders[i].pos1, openCylinders[i].pos2, openCylinders[i].radius, r, normal );
		if (d < t)
		{
			t = d;
			intersec.normal = normalize(normal);
			intersec.emission = openCylinders[i].emission;
			intersec.color = openCylinders[i].color;
			intersec.roughness = openCylinders[i].roughness;
			intersec.type = openCylinders[i].type;
		}
        }
	
	// LAMP BASE AND FLOOR LAMP BULB
	for (int i = 0; i < N_SPHERES - 1; i++)
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
	
	// LIGHT DISK OF SPOTLIGHT AND SPOTLIGHT CASE DISK BACKING
	for (int i = 0; i < N_DISKS; i++)
        {
		d = DiskIntersect( disks[i].radius, disks[i].pos, disks[i].normal, r );
		if (d < t)
		{
			t = d;
			intersec.normal = normalize(disks[i].normal);
			intersec.emission = disks[i].emission;
			intersec.color = disks[i].color;
			intersec.roughness = disks[i].roughness;
			intersec.type = disks[i].type;
		}
	}
	
	// LAMP SHADE
	d = ConeIntersect( cones[0].pos0, cones[0].radius0, cones[0].pos1, cones[0].radius1, r, normal );
	if (d < t)
	{
		t = d;
		intersec.normal = normalize(normal);
		intersec.emission = cones[0].emission;
		intersec.color = cones[0].color;
		intersec.roughness = cones[0].roughness;
		intersec.type = cones[0].type;
	}
	
	
	// GLASS EGG
	vec3 hitPos;
	
	d = EllipsoidIntersect( ellipsoids[0].radii, ellipsoids[0].position, r );
	hitPos = r.origin + r.direction * d;
	if (hitPos.y < ellipsoids[0].position.y) 
		d = INFINITY;
	
	if (d < t)
	{
		t = d;
		intersec.normal = normalize( ((r.origin + r.direction * t) - ellipsoids[0].position) / (ellipsoids[0].radii * ellipsoids[0].radii) );
		intersec.emission = ellipsoids[0].emission;
		intersec.color = ellipsoids[0].color;
		intersec.roughness = ellipsoids[0].roughness;
		intersec.type = ellipsoids[0].type;
	}
	
	d = SphereIntersect( spheres[3].radius, spheres[3].position, r );
	hitPos = r.origin + r.direction * d;
	if (hitPos.y >= spheres[3].position.y) 
		d = INFINITY;
	
	if (d < t)
	{
		t = d;
		intersec.normal = normalize((r.origin + r.direction * t) - spheres[3].position);
		intersec.emission = spheres[3].emission;
		intersec.color = spheres[3].color;
		intersec.roughness = spheres[3].roughness;
		intersec.type = spheres[3].type;
	}
	
	
	return t;
}



//-----------------------------------------------------------------------
vec3 CalculateRadiance( Ray originalRay, inout uvec2 seed )
//-----------------------------------------------------------------------
{
	Intersection intersec;
	int randChoose = int(rand(seed) * 2.0); // 2 lights to choose from
	Sphere lightChoice = spheres[randChoose]; 
	//lightChoice = spheres[1]; // override lightChoice
	Ray firstRay;
	
	vec3 accumCol = vec3(0);
        vec3 mask = vec3(1);
	vec3 firstMask = vec3(1);
	vec3 dirToLight;
	vec3 tdir;
	vec3 spotlightPos1 = vec3(380.0, 290.0, -470.0);
	vec3 spotlightPos2 = vec3(430.0, 315.0, -485.0);
	vec3 spotlightDir = normalize(spotlightPos1 - spotlightPos2);
	//vec3 lightHitPos = lightChoice.position + normalize(randomSphereDirection(seed)) * (lightChoice.radius * 0.5);
	
	vec3 lightNormal = vec3(0,1,0);
	if (randChoose > 0)
		lightNormal = spotlightDir;
	lightNormal = normalize(lightNormal);
	vec3 lightDir = normalize(randomCosWeightedDirectionInHemisphere(lightNormal, seed));
	vec3 lightHitPos = lightChoice.position + lightDir;
	vec3 lightHitEmission = lightChoice.emission;
	vec3 x, n, nl;
        
	float lightHitDistance = INFINITY;
	float firstLightHitDistance = INFINITY;
	float t = INFINITY;
	float nc, nt, ratioIoR, Re, Tr;
	float weight;
	float distanceEPS = uEPS_intersect * 10.0;
	
	int diffuseCount = 0;

	bool bounceIsSpecular = true;
	bool sampleLight = false;
	bool firstTypeWasREFR = false;
	bool reflectionTime = false;
	bool firstTypeWasDIFF = false;
	bool shadowTime = false;
	bool ableToJoinPaths = false;

	// light trace
	
	Ray r = Ray(lightChoice.position, lightDir);
	r.direction = normalize(r.direction);
	r.origin += r.direction * (lightChoice.radius * 1.1);
	t = SceneIntersect(r, intersec);
	if (intersec.type == DIFF)
	{
		lightHitPos = r.origin + r.direction * t;
		weight = max(0.0, dot(-r.direction, intersec.normal));
		lightHitEmission *= intersec.color * weight;
	}

	
	// regular path tracing from camera
	r = originalRay;
	r.direction = normalize(r.direction);

	for (int bounces = 0; bounces < 6; bounces++)
	{

		t = SceneIntersect(r, intersec);
		
		if (t == INFINITY)
		{
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

			if (firstTypeWasDIFF && !shadowTime) 
			{
				// start back at the diffuse surface, but this time follow shadow ray branch
				r = firstRay;
				r.direction = normalize(r.direction);
				mask = firstMask;
				lightHitDistance = firstLightHitDistance;
				// set/reset variables
				shadowTime = true;
				bounceIsSpecular = false;
				sampleLight = true;
				// continue with the shadow ray
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

			if (firstTypeWasREFR)
			{
				if (!reflectionTime) 
				{
					if (bounceIsSpecular || sampleLight)
						accumCol += mask * intersec.emission;
					
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
				if (bounceIsSpecular || sampleLight)
					accumCol += mask * intersec.emission;

				break;	
			}

			if (firstTypeWasDIFF)
			{
				if (!shadowTime) 
				{
					if (bounceIsSpecular)
						accumCol += mask * intersec.emission * 20.0;
					else if (sampleLight)
						accumCol += mask * intersec.emission * 0.5;
					
					// start back at the diffuse surface, but this time follow shadow ray branch
					r = firstRay;
					r.direction = normalize(r.direction);
					mask = firstMask;
					lightHitDistance = firstLightHitDistance;
					// set/reset variables
					shadowTime = true;
					sampleLight = true;
					bounceIsSpecular = false;
					// continue with the shadow ray
					continue;
				}
				
				// add shadow ray result to the colorbleed result (if any)
				accumCol += mask * intersec.emission * 0.5;

				break;
						
			}

			if (bounceIsSpecular)
				accumCol = mask * intersec.emission; // looking at light through a reflection
			// reached a light, so we can exit
			break;
		} // end if (intersec.type == LIGHT)


		if (intersec.type == DIFF && sampleLight)
		{
			ableToJoinPaths = abs(lightHitDistance - t) < distanceEPS;
			
			if (firstTypeWasDIFF)
			{
				if (!shadowTime) 
				{	
					if (ableToJoinPaths)
					{
						weight = max(0.0, dot(intersec.normal, -r.direction));
						accumCol += mask * lightHitEmission * weight * 0.5;
					}
					// start back at the diffuse surface, but this time follow shadow ray branch
					r = firstRay;
					r.direction = normalize(r.direction);
					mask = firstMask;
					lightHitDistance = firstLightHitDistance;
					// set/reset variables
					shadowTime = true;
					sampleLight = true;
					bounceIsSpecular = false;
					// continue with the shadow ray
					continue;
				}
				
				// add shadow ray result to the colorbleed result (if any)
				if (ableToJoinPaths)
				{
					weight = max(0.0, dot(intersec.normal, -r.direction));
					accumCol += mask * lightHitEmission * weight * 0.5;
				}

				break;
			}

			if (firstTypeWasREFR)
			{
				if (!reflectionTime) 
				{
					if (ableToJoinPaths)
					{
						weight = max(0.0, dot(intersec.normal, -r.direction));
						accumCol += mask * lightHitEmission * weight * 0.5;
					}
					
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
				if (ableToJoinPaths)
				{
					weight = max(0.0, dot(intersec.normal, -r.direction));
					accumCol += mask * lightHitEmission * weight * 0.5;
				}

				break;	
			}

			//break;
		}

		// if we reached this point and sampleLight is still true, then we can either
		//  continue with the reflection/shadow ray or exit because the light was not found
		if (sampleLight)
		{
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

			if (firstTypeWasDIFF && !shadowTime) 
			{
				// start back at the diffuse surface, but this time follow shadow ray branch
				r = firstRay;
				r.direction = normalize(r.direction);
				mask = firstMask;
				lightHitDistance = firstLightHitDistance;
				// set/reset variables
				shadowTime = true;
				bounceIsSpecular = false;
				sampleLight = true;
				// continue with the shadow ray
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

			if (diffuseCount > 2)
				break;

			mask *= intersec.color;

			bounceIsSpecular = false;

			if (diffuseCount == 1 && !firstTypeWasREFR)
			{	
				// save intersection data for future shadow ray trace
				firstTypeWasDIFF = true;
				
				dirToLight = normalize(lightHitPos - x);
				firstLightHitDistance = distance(lightHitPos, x);
				lightHitDistance = firstLightHitDistance;
				weight = max(0.0, dot(nl, dirToLight));
				firstMask = mask * weight;

				firstRay = Ray( x, normalize(dirToLight) ); // create shadow ray pointed towards light
				firstRay.origin += nl * uEPS_intersect;

				// choose random Diffuse sample vector
				r = Ray( x, normalize(randomCosWeightedDirectionInHemisphere(nl, seed)) );
				//r = Ray(x, nl); // interesting effect for tracing heightfields/holographic projections?
				r.origin += nl * uEPS_intersect;
				sampleLight = false;
				continue;
			}
			if (diffuseCount == 1 && firstTypeWasREFR)
			{
				// choose random Diffuse sample vector
				r = Ray( x, normalize(randomCosWeightedDirectionInHemisphere(nl, seed)) );
				r.origin += nl * uEPS_intersect;
				sampleLight = false;
				continue;
			}
			
			dirToLight = normalize(lightHitPos - x);
			lightHitDistance = distance(lightHitPos, x);
			weight = max(0.0, dot(nl, dirToLight));
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
			nt = 1.5; // IOR of heavy Glass
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

			// transmit ray through surface
			mask *= intersec.color;
			
			tdir = refract(r.direction, nl, ratioIoR);
			r = Ray(x, normalize(tdir));
			r.origin -= nl * uEPS_intersect;

			bounceIsSpecular = true; // turn on refracting caustics

			continue;
			
		} // end if (intersec.type == REFR)
		
		
	} // end for (int bounces = 0; bounces < 6; bounces++)
	

	return max(vec3(0), accumCol);

} // end vec3 CalculateRadiance( Ray r, inout uvec2 seed )



//-----------------------------------------------------------------------
void SetupScene(void)
//-----------------------------------------------------------------------
{
	vec3 z  = vec3(0);// No color value, Black        
	vec3 L1 = vec3(1.0) * 20.0;// Bright White light
	vec3 L2 = vec3(0.936507, 0.642866, 0.310431) * 15.0;// Bright Yellowish light
	vec3 wallColor = vec3(1.0, 0.98, 1.0) * 0.5;
	vec3 tableColor = vec3(1.0, 0.55, 0.2) * 0.6;
	vec3 lampColor = vec3(1.0, 1.0, 0.8) * 0.7;
	vec3 spotlightPos1 = vec3(380.0, 290.0, -470.0);
	vec3 spotlightPos2 = vec3(430.0, 315.0, -485.0);
	vec3 spotlightDir = normalize(spotlightPos1 - spotlightPos2);
	float spotlightRadius = 14.0; // 12.0
	
	quads[0] = Quad( vec3( 0.0, 0.0, 1.0), vec3(  0.0,   0.0,-559.2), vec3(549.6,   0.0,-559.2), vec3(549.6, 548.8,-559.2), vec3(  0.0, 548.8,-559.2),  z, wallColor, 0.0, DIFF);// Back Wall
	quads[1] = Quad( vec3( 1.0, 0.0, 0.0), vec3(  0.0,   0.0,   0.0), vec3(  0.0,   0.0,-559.2), vec3(  0.0, 548.8,-559.2), vec3(  0.0, 548.8,   0.0),  z, wallColor, 0.0, DIFF);// Left Wall
	quads[2] = Quad( vec3(-1.0, 0.0, 0.0), vec3(549.6,   0.0,-559.2), vec3(549.6,   0.0,   0.0), vec3(549.6, 548.8,   0.0), vec3(549.6, 548.8,-559.2),  z, wallColor, 0.0, DIFF);// Right Wall
	quads[3] = Quad( vec3( 0.0,-1.0, 0.0), vec3(  0.0, 548.8,-559.2), vec3(549.6, 548.8,-559.2), vec3(549.6, 548.8,   0.0), vec3(  0.0, 548.8,   0.0),  z, vec3(1.0), 0.0, DIFF);// Ceiling
	quads[4] = Quad( vec3( 0.0, 1.0, 0.0), vec3(  0.0,   0.0,   0.0), vec3(549.6,   0.0,   0.0), vec3(549.6,   0.0,-559.2), vec3(  0.0,   0.0,-559.2),  z, wallColor, 0.0, DIFF);// Floor
	
	boxes[0] = Box( vec3(180.0, 145.0, -540.0), vec3(510.0, 155.0, -310.0), z, tableColor, 0.0, DIFF);// Table Top
	
	openCylinders[0] = OpenCylinder( 8.5, vec3(205.0, 0.0, -515.0), vec3(205.0, 145.0, -515.0), z, tableColor, 0.0, DIFF);// Table Leg
	openCylinders[1] = OpenCylinder( 8.5, vec3(485.0, 0.0, -515.0), vec3(485.0, 145.0, -515.0), z, tableColor, 0.0, DIFF);// Table Leg
	openCylinders[2] = OpenCylinder( 8.5, vec3(205.0, 0.0, -335.0), vec3(205.0, 145.0, -335.0), z, tableColor, 0.0, DIFF);// Table Leg
	openCylinders[3] = OpenCylinder( 8.5, vec3(485.0, 0.0, -335.0), vec3(485.0, 145.0, -335.0), z, tableColor, 0.0, DIFF);// Table Leg
	
	openCylinders[4] = OpenCylinder( 6.0, vec3(80.0, 0.0, -430.0), vec3(80.0, 366.0, -430.0), z, lampColor, 0.0, SPEC);// Floor Lamp Post
	openCylinders[5] = OpenCylinder( spotlightRadius, spotlightPos1, spotlightPos2, z, vec3(1.0,1.0,1.0), 0.0, SPEC);// Spotlight Casing
	
	disks[0] = Disk( spotlightRadius, spotlightPos2, spotlightDir, z, vec3(1), 0.0, SPEC);// disk backing of spotlight
	
	cones[0] = Cone( vec3(80.0, 405.0, -430.0), 70.0, vec3(80.0, 365.0, -430.0), 6.0, z, lampColor, 0.2, SPEC);// Floor Lamp Shade
	
	spheres[0] = Sphere( spotlightRadius * 0.5, spotlightPos2 + spotlightDir * 20.0, L2, z, 0.0, LIGHT);// Spot Light Bulb
	spheres[1] = Sphere( 6.0, vec3(80.0, 378.0, -430.0), L1, z, 0.0, LIGHT);// Floor Lamp Bulb
	spheres[2] = Sphere( 80.0, vec3(80.0, -60.0, -430.0), z, lampColor, 0.4, SPEC);// Floor Lamp Base
	spheres[3] = Sphere( 33.0, vec3(290.0, 189.0, -435.0), z, vec3(1), 0.0, REFR);// Glass Egg Bottom
	ellipsoids[0] = Ellipsoid( vec3(33, 62, 33), vec3(290.0, 189.0, -435.0), z, vec3(1), 0.0, REFR);// Glass Egg Top
}


#include <pathtracing_main>
