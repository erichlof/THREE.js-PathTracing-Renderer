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

#include <pathtracing_quad_intersect>

#include <pathtracing_box_intersect>

#include <pathtracing_sample_quad_light>

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
	mat4 m;

	vec3 o;
	vec3 offset;
	vec3 n, n1, n2;
	vec3 intersectionPoint;
	vec3 tempNormal;
	vec3 hitPos;

	float angle = 0.0;
	float width = 0.0;
	float d = INFINITY;
	float t = INFINITY;
	
	bool isRayExiting = false;
	

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

	
	// Twisted Glass Sphere Left
	d = SphereIntersect( spheres[0].radius, spheres[0].position, r );
	intersectionPoint = r.origin + r.direction * d;
	angle = mod(intersectionPoint.y * 0.1, TWO_PI);
	m = makeRotateY(angle);
	o = ( m * vec4(intersectionPoint, 1.0) ).xyz;
	offset = o * 0.1;
	d = SphereIntersect( spheres[0].radius, spheres[0].position + offset, r);
	if (d < t)
	{
		t = d;
		intersectionPoint = r.origin + r.direction * t;
		tempNormal = (intersectionPoint - (spheres[0].position + offset));
		intersec.normal = normalize(tempNormal);
		intersec.emission = spheres[0].emission;
		intersec.color = spheres[0].color;
		intersec.type = spheres[0].type;
	}

	// Twisted Glass Sphere Right
	d = SphereIntersect( spheres[1].radius, spheres[1].position, r );
	intersectionPoint = r.origin + r.direction * d;
	angle = mod(intersectionPoint.y * 0.1, TWO_PI);
	m = makeRotateY(angle);
	o = ( m * vec4(intersectionPoint, 1.0) ).xyz;
	offset = o * 0.1;
	d = SphereIntersect( spheres[1].radius, spheres[1].position + offset, r);
	if (d < t)
	{
		t = d;
		intersectionPoint = r.origin + r.direction * t;
		tempNormal = (intersectionPoint - (spheres[1].position + offset));
		intersec.normal = normalize(tempNormal);
		intersec.emission = spheres[1].emission;
		intersec.color = spheres[1].color;
		intersec.type = spheres[1].type;
	}	
			
	// Purple Cloud Sphere
	width = 2.0 * rand(seed);
	offset = (spheres[2].radius * 0.5) * (vec3(rand(seed) * 2.0 - 1.0, rand(seed) * 2.0 - 1.0, rand(seed) * 2.0 - 1.0));
	d = SphereIntersect( spheres[2].radius + width, spheres[2].position + offset, r);
	if (d < t)
	{
		t = d;
		intersectionPoint = r.origin + r.direction * t;
		tempNormal = (intersectionPoint - (spheres[2].position + offset));
		intersec.normal = normalize(tempNormal);
		intersec.emission = spheres[2].emission;
		intersec.color = spheres[2].color;
		intersec.type = spheres[2].type;
	}
	

	// Twisted Tall Mirror Box
	warpedRay = r;
	warpedRay.origin.x -= 200.0;
	warpedRay.origin.y -= 200.0;
	warpedRay.origin.z += 400.0;
	
	d = BoxIntersect( boxes[0].minCorner * vec3(1.5, 1.0, 1.5), boxes[0].maxCorner * vec3(1.5, 1.0, 1.5), warpedRay, n, isRayExiting );
	if (d == INFINITY) return t;
	
	hitPos = warpedRay.origin + warpedRay.direction * d;
	//float angle = 0.25 * PI;
	angle = mod(hitPos.y * 0.015, TWO_PI);
	m = makeRotateY(angle);
	m = inverse(m);
	warpedRay.origin = vec3( m * vec4(warpedRay.origin, 1.0) );
	warpedRay.direction = normalize(vec3( m * vec4(warpedRay.direction, 0.0) ));
	
	d = BoxIntersect( boxes[0].minCorner, boxes[0].maxCorner, warpedRay, n, isRayExiting );
	if (d < t)
	{
		t = d;
		intersec.normal = normalize(n);
		intersec.normal = normalize(vec3( transpose(m) * vec4(intersec.normal, 0.0) ));
		intersec.emission = boxes[0].emission;
		intersec.color = boxes[0].color;
		intersec.type = boxes[0].type;
	}

	return t;
}


//-----------------------------------------------------------------------
vec3 CalculateRadiance( Ray r, inout uvec2 seed )
//-----------------------------------------------------------------------
{
	Intersection intersec;
	Quad light = quads[5];

	vec3 accumCol = vec3(0);
        vec3 mask = vec3(1);
	vec3 dirToLight;
	vec3 tdir;
	vec3 x, n, nl;
        
	float t;
	float nc, nt, ratioIoR, Re, Tr;
	float P, RP, TP;
	float weight;

	int diffuseCount = 0;

	bool bounceIsSpecular = true;
	bool sampleLight = false;

	
	for (int bounces = 0; bounces < 5; bounces++)
	{

		t = SceneIntersect(r, intersec, seed);
		

		if (t == INFINITY)	
			break;
		
		
		if (intersec.type == LIGHT)
		{	
			if (bounceIsSpecular || sampleLight)
				accumCol = mask * intersec.emission;
			// reached a light, so we can exit
			break;

		} // end if (intersec.type == LIGHT)


		// if we get here and sampleLight is still true, shadow ray failed to find a light source
		if (sampleLight)	
			break;
		

		// useful data 
		n = normalize(intersec.normal);
                nl = dot(n, r.direction) < 0.0 ? normalize(n) : normalize(-n);
		x = r.origin + r.direction * t;

		    
                if (intersec.type == DIFF) // Ideal DIFFUSE reflection
		{
			diffuseCount++;

			mask *= intersec.color;

			bounceIsSpecular = false;

			if (diffuseCount == 1 && rand(seed) < 0.5)
			{
				r = Ray( x, randomCosWeightedDirectionInHemisphere(nl, seed) );
				r.origin += nl * uEPS_intersect;
				continue;
			}
                        
			dirToLight = sampleQuadLight(x, nl, quads[5], dirToLight, weight, seed);
			mask *= weight;

			r = Ray( x, dirToLight );
			r.origin += nl * uEPS_intersect;

			sampleLight = true;
			continue;
                        
		} // end if (intersec.type == DIFF)
		
		if (intersec.type == SPEC)  // Ideal SPECULAR reflection
		{
			mask *= intersec.color;

			r = Ray( x, reflect(r.direction, nl) );
			r.origin += nl * uEPS_intersect;

			continue;
		}
		
		if (intersec.type == REFR)  // Ideal dielectric REFRACTION
		{
			nc = 1.0; // IOR of Air
			nt = 1.5; // IOR of common Glass
			Re = calcFresnelReflectance(r.direction, n, nc, nt, ratioIoR);
			Tr = 1.0 - Re;
			P  = 0.25 + (0.5 * Re);
                	RP = Re / P;
                	TP = Tr / (1.0 - P);
			
			if (rand(seed) < P)
			{
				mask *= RP;
				r = Ray( x, reflect(r.direction, nl) ); // reflect ray from surface
				r.origin += nl * uEPS_intersect;
				continue;
			}

			// transmit ray through surface
			
			// is ray leaving a solid object from the inside? 
			// If so, attenuate ray color with object color by how far ray has travelled through the medium
			// if (distance(n, nl) > 0.1)
			// {
			// 	thickness = 0.01;
			// 	mask *= exp( log(clamp(intersec.color, 0.01, 0.99)) * thickness * t ); 
			// }

			mask *= TP;
			mask *= intersec.color;

			tdir = refract(r.direction, nl, ratioIoR);
			r = Ray(x, tdir);
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
			P  = 0.25 + (0.5 * Re);
                	RP = Re / P;
                	TP = Tr / (1.0 - P);

			if (rand(seed) < P)
			{
				mask *= RP;
				r = Ray( x, reflect(r.direction, nl) ); // reflect ray from surface
				r.origin += nl * uEPS_intersect;
				continue;
			}

			diffuseCount++;
			mask *= TP;
			mask *= intersec.color;

			bounceIsSpecular = false;
			
			if (diffuseCount == 1 && rand(seed) < 0.5)
			{
				// choose random Diffuse sample vector
				r = Ray( x, randomCosWeightedDirectionInHemisphere(nl, seed) );
				r.origin += nl * uEPS_intersect;
				continue;
			}

			dirToLight = sampleQuadLight(x, nl, quads[5], dirToLight, weight, seed);
			mask *= weight;
			
			r = Ray( x, dirToLight );
			r.origin += nl * uEPS_intersect;

			sampleLight = true;
			continue;
			
		} //end if (intersec.type == COAT)

		
		
	} // end for (int bounces = 0; bounces < 5; bounces++)
	
	
	return max(vec3(0), accumCol);

} // end vec3 CalculateRadiance( Ray r, inout uvec2 seed )



//-----------------------------------------------------------------------
void SetupScene(void)
//-----------------------------------------------------------------------
{
	vec3 z  = vec3(0);// No color value, Black        
	vec3 L1 = vec3(1.0, 1.0, 1.0) * 10.0;// Bright light
	
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
