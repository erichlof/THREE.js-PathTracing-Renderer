#version 300 es

precision highp float;
precision highp int;
precision highp sampler2D;

#include <pathtracing_uniforms_and_defines>

#define N_SPHERES 3
#define N_ELLIPSOIDS 1
#define N_OPENCYLINDERS 6
#define N_CONES 1
#define N_DISKS 2
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



//-----------------------------------------------------------------------
float SceneIntersect( Ray r, inout Intersection intersec )
//-----------------------------------------------------------------------
{
	vec3 normal;
        float d;
	float t = INFINITY;
	// clear fields out
	intersec.normal = vec3(0);
	intersec.emission = vec3(0);
	intersec.color = vec3(0);
	intersec.roughness = 0.0;
	intersec.type = -1;
			
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
	
	d = SphereIntersect( spheres[2].radius, spheres[2].position, r );
	hitPos = r.origin + r.direction * d;
	if (hitPos.y >= spheres[2].position.y) 
		d = INFINITY;
	
	if (d < t)
	{
		t = d;
		intersec.normal = normalize((r.origin + r.direction * t) - spheres[2].position);
		intersec.emission = spheres[2].emission;
		intersec.color = spheres[2].color;
		intersec.roughness = spheres[2].roughness;
		intersec.type = spheres[2].type;
	}
	
	
	return t;
}

#define EYE_PATH_LENGTH    5
#define LIGHT_PATH_LENGTH  1

//-----------------------------------------------------------------------
vec3 CalculateRadiance( Ray r, inout uvec2 seed )
//-----------------------------------------------------------------------
{
	Intersection intersec;
	vec3 accumCol = vec3(0);
	vec3 maskEyePath = vec3(1);
	vec3 maskLightPath = vec3(1);
	vec3 eyeX = vec3(0);
	vec3 lightX = vec3(0);
	vec3 nl, n, x;
	vec3 nlEyePath = vec3(0);
	vec3 tdir;
	
	float nc, nt, Re;
	float t = INFINITY;
	int diffuseCount = 0;
	int previousIntersecType = -1;
	bool bounceIsSpecular = true;
	//set following flag to true - we haven't found a diffuse surface yet and can exit early (keeps frame rate high)
	bool skipConnectionLightPath = true;
	
	
	// Eye path tracing (from Camera) ///////////////////////////////////////////////////////////////////////////
	
	for (int bounces = 0; bounces < EYE_PATH_LENGTH; bounces++)
	{
	
		t = SceneIntersect(r, intersec);
		
		if (t == INFINITY)
		{
			break;
		}
		
		if (intersec.type == LIGHT)
		{
			if (bounceIsSpecular)
			{
				accumCol = maskEyePath * intersec.emission;
			
				skipConnectionLightPath = true;
			}
			
			break;
		}
		
		// useful data 
		n = normalize(intersec.normal);
		nl = dot(n, r.direction) < 0.0 ? normalize(n) : normalize(n * -1.0);
		x = r.origin + r.direction * t;
		
		
		if (intersec.type == DIFF) // Ideal DIFFUSE reflection
		{
			maskEyePath *= intersec.color;
			eyeX = x + nl;
			nlEyePath = nl;
			skipConnectionLightPath = false;
			
			diffuseCount++;
			if (diffuseCount > 1 || rand(seed) < 0.5)
			{
				break;
			}
			
			// choose random Diffuse sample vector
			r = Ray( x, randomCosWeightedDirectionInHemisphere(nl, seed) );
			r.origin += nl;
			eyeX = r.origin;
			bounceIsSpecular = false;
			previousIntersecType = DIFF;
			continue;
		}
		
		if (intersec.type == SPEC)  // Ideal SPECULAR reflection
		{
			maskEyePath *= intersec.color;
			vec3 reflectVec = reflect(r.direction, nl);
			vec3 randVec = randomDirectionInHemisphere(nl, seed);
			r = Ray( x, mix(reflectVec, randVec, intersec.roughness) );
			r.origin += nl;
			bounceIsSpecular = true;
			previousIntersecType = SPEC;
			continue;
		}
		
		
		if (intersec.type == REFR)  // Ideal dielectric refraction
		{	
			nc = 1.0; // IOR of Air
			nt = 1.6; // IOR of Heavy Glass
			Re = calcFresnelReflectance(n, nl, r.direction, nc, nt, tdir);
			
			bounceIsSpecular = true;
				
			if (rand(seed) < Re) // reflect ray from surface
			{
				previousIntersecType = REFR;
				r = Ray( x, reflect(r.direction, nl) );
				r.origin += nl;
				continue;	
			}
			else // transmit ray through surface
			{
				if (previousIntersecType == DIFF) 
					maskEyePath *= TWO_PI;
					
				previousIntersecType = REFR;
				maskEyePath *= intersec.color;
				r = Ray(x, tdir);
				r.origin -= nl;
				continue;
			}	
		} // end if (intersec.type == REFR)
		
	} // end for (int bounces = 0; bounces < EYE_PATH_LENGTH; bounces++)
	
	
	if (skipConnectionLightPath)
		return accumCol;
	
	
	// Light path tracing (from Light sources) ////////////////////////////////////////////////////////////////////
	vec3 randLightPos;
	vec3 randLightDir;
	vec3 randPointOnLight;
	vec3 nlLightPath;
	// Choose a random light source for this loop
	if (rand(seed) < 0.85)
	{
		// Floor Lamp
		vec3 floorLampDir = vec3(0,1,0);
		nlLightPath = floorLampDir;
		//randLightDir = randomDirectionInHemisphere(nlLightPath, seed);
		randLightDir = randomCosWeightedDirectionInHemisphere(nlLightPath, seed);
		randLightPos = vec3(80.0, 372.0, -430.0);
		randPointOnLight = randLightPos + randLightDir * 6.0; // multiplied by light bulb radius
		maskLightPath = spheres[1].emission;// * max(0.0, dot(nlLightPath, randLightDir));
	}
	else
	{
		// Spot Light
		vec3 spotlightPos1 = vec3(380.0, 290.0, -470.0);
		vec3 spotlightPos2 = vec3(430.0, 315.0, -485.0);
		vec3 spotlightDir = normalize(spotlightPos1 - spotlightPos2);
		nlLightPath = spotlightDir;
		randLightPos = spotlightPos2 + spotlightDir;
		randLightDir = randomCosWeightedDirectionInHemisphere(spotlightDir, seed);
		randPointOnLight = randLightPos + randLightDir;
		maskLightPath = disks[1].emission;
	}
	
	r = Ray( randPointOnLight, randLightDir );
	r.origin += r.direction * 3.0; // move light ray out to prevent self-intersection with light
	vec3 originalLightPos = r.origin;
	lightX = originalLightPos;
	vec3 originalLightMask = maskLightPath;
	bool diffuseReached = false;
	
	// the following loop only performs 1 iteration because of the relative ease of this particular scene for
	// the light sources to escape their blockers and find a diffuse surface (like a nearby wall) to illuminate.
	// For more hidden lights however, 2 bounces might be needed to get the light out and into the scene.
	
	for (int bounces = 0; bounces < LIGHT_PATH_LENGTH; bounces++)
	{
	
		t = SceneIntersect(r, intersec);
		
		if ( t == INFINITY || intersec.type != DIFF)
		{
			break;
		}
		
		// useful data 
		n = normalize(intersec.normal);
		nl = dot(n, r.direction) < 0.0 ? normalize(n) : normalize(n * -1.0);
		x = r.origin + r.direction * t;
		
		//if (intersec.type == DIFF) // Ideal DIFFUSE reflection
		{
			maskLightPath *= intersec.color;
			nlLightPath = nl;
			lightX = x + nl;
			diffuseReached = true;
			break;
		}
		
	} // end for (int bounces = 0; bounces < LIGHT_PATH_LENGTH; bounces++)
	
	
	// Connect Camera path and Light path ////////////////////////////////////////////////////////////
	
	Ray connectRay = Ray(eyeX, normalize(lightX - eyeX));
	float connectDist = distance(eyeX, lightX);
	float c = SceneIntersect(connectRay, intersec);
	if (c < connectDist)
		return accumCol;
	else
	{
		maskEyePath *= max(0.0, dot(connectRay.direction, nlEyePath));
		
		if (diffuseReached)
			maskLightPath *= max(0.0, dot(-connectRay.direction, nlLightPath));
		accumCol = (maskEyePath * maskLightPath);
	}
	
	return accumCol;
}


//-----------------------------------------------------------------------
void SetupScene(void)
//-----------------------------------------------------------------------
{
	vec3 z  = vec3(0);// No color value, Black        
	vec3 L1 = vec3(1.0, 1.0, 1.0) * 12.0;// Bright White light
	vec3 L2 = vec3(0.936507, 0.642866, 0.310431) * 25.0;// Bright Yellowish light
	vec3 wallColor = vec3(1.0, 0.98, 1.0) * 0.5;
	vec3 tableColor = vec3(1.0, 0.7, 0.4) * 0.6;
	vec3 lampColor = vec3(1.0, 1.0, 0.8) * 0.7;
	vec3 spotlightPos1 = vec3(380.0, 290.0, -470.0);
	vec3 spotlightPos2 = vec3(430.0, 315.0, -485.0);
	vec3 spotlightDir = normalize(spotlightPos1 - spotlightPos2);
	
	quads[0] = Quad( vec3( 0.0, 0.0, 1.0), vec3(  0.0,   0.0,-559.2), vec3(549.6,   0.0,-559.2), vec3(549.6, 548.8,-559.2), vec3(  0.0, 548.8,-559.2),  z, wallColor, 0.0, DIFF);// Back Wall
	quads[1] = Quad( vec3( 1.0, 0.0, 0.0), vec3(  0.0,   0.0,   0.0), vec3(  0.0,   0.0,-559.2), vec3(  0.0, 548.8,-559.2), vec3(  0.0, 548.8,   0.0),  z, wallColor, 0.0, DIFF);// Left Wall Red
	quads[2] = Quad( vec3(-1.0, 0.0, 0.0), vec3(549.6,   0.0,-559.2), vec3(549.6,   0.0,   0.0), vec3(549.6, 548.8,   0.0), vec3(549.6, 548.8,-559.2),  z, wallColor, 0.0, DIFF);// Right Wall Green
	quads[3] = Quad( vec3( 0.0,-1.0, 0.0), vec3(  0.0, 548.8,-559.2), vec3(549.6, 548.8,-559.2), vec3(549.6, 548.8,   0.0), vec3(  0.0, 548.8,   0.0),  z, wallColor, 0.0, DIFF);// Ceiling
	quads[4] = Quad( vec3( 0.0, 1.0, 0.0), vec3(  0.0,   0.0,   0.0), vec3(549.6,   0.0,   0.0), vec3(549.6,   0.0,-559.2), vec3(  0.0,   0.0,-559.2),  z, wallColor, 0.0, DIFF);// Floor
	
	boxes[0] = Box( vec3(180.0, 145.0, -540.0), vec3(510.0, 155.0, -310.0), z, tableColor, 0.0, DIFF);// Table Top
	
	openCylinders[0] = OpenCylinder( 8.5, vec3(205.0, 0.0, -515.0), vec3(205.0, 145.0, -515.0), z, tableColor, 0.0, DIFF);// Table Leg
	openCylinders[1] = OpenCylinder( 8.5, vec3(485.0, 0.0, -515.0), vec3(485.0, 145.0, -515.0), z, tableColor, 0.0, DIFF);// Table Leg
	openCylinders[2] = OpenCylinder( 8.5, vec3(205.0, 0.0, -335.0), vec3(205.0, 145.0, -335.0), z, tableColor, 0.0, DIFF);// Table Leg
	openCylinders[3] = OpenCylinder( 8.5, vec3(485.0, 0.0, -335.0), vec3(485.0, 145.0, -335.0), z, tableColor, 0.0, DIFF);// Table Leg
	
	openCylinders[4] = OpenCylinder( 6.0, vec3(80.0, 0.0, -430.0), vec3(80.0, 366.0, -430.0), z, lampColor, 0.0, SPEC);// Floor Lamp Post
	openCylinders[5] = OpenCylinder( 22.0, spotlightPos1, spotlightPos2, z, vec3(1.0,0.9,0.9), 0.6, SPEC);// Spotlight Casing
	
	disks[0] = Disk( 22.0, spotlightPos2, spotlightDir, z, vec3(0.4), 1.0, SPEC);// disk backing of spotlight
	disks[1] = Disk( 21.0, spotlightPos2 + spotlightDir, spotlightDir, L2, z, 0.0, LIGHT);// Light disk of spotlight
	
	cones[0] = Cone( vec3(80.0, 405.0, -430.0), 70.0, vec3(80.0, 365.0, -430.0), 6.0, z, lampColor, 0.2, SPEC);// Floor Lamp Shade
	
	spheres[0] = Sphere( 80.0, vec3(80.0, -60.0, -430.0), z, lampColor, 0.4, SPEC);// Floor Lamp Base
	spheres[1] = Sphere( 6.0, vec3(80.0, 378.0, -430.0), L1, z, 0.0, LIGHT);// Floor Lamp Bulb
	
	spheres[2] = Sphere( 33.0, vec3(290.0, 189.0, -435.0), z, vec3(1), 0.0, REFR);// Glass Egg Bottom
	ellipsoids[0] = Ellipsoid( vec3(33, 62, 33), vec3(290.0, 189.0, -435.0), z, vec3(1), 0.0, REFR);// Glass Egg Top
}


#include <pathtracing_main>
