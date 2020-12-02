precision highp float;
precision highp int;
precision highp sampler2D;

uniform mat4 uShortBoxInvMatrix;
uniform mat4 uTallBoxInvMatrix;

#include <pathtracing_uniforms_and_defines>

#define N_QUADS 6
#define N_BOXES 3

struct Ray { vec3 origin; vec3 direction; };
struct Quad { vec3 normal; vec3 v0; vec3 v1; vec3 v2; vec3 v3; vec3 emission; vec3 color; int type; };
struct Box { vec3 minCorner; vec3 maxCorner; vec3 emission; vec3 color; int type; };
struct Intersection { vec3 normal; vec3 emission; vec3 color; int type; };

Quad quads[N_QUADS];
Box boxes[N_BOXES];


#include <pathtracing_random_functions>

#include <pathtracing_quad_intersect>

#include <pathtracing_box_intersect>


//-----------------------------------------------------------------------
float SceneIntersect( Ray r, inout Intersection intersec )
//-----------------------------------------------------------------------
{
	vec3 normal;
        float d;
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
	
	// LIGHT-BLOCKER THIN BOX
	d = BoxIntersect( boxes[2].minCorner, boxes[2].maxCorner, r, normal, isRayExiting );
	if (d < t)
	{
		t = d;
		intersec.normal = normalize(normal);
		intersec.emission = boxes[2].emission;
		intersec.color = boxes[2].color;
		intersec.type = boxes[2].type;
	}
	
	
	// TALL MIRROR BOX
	Ray rObj;
	// transform ray into Tall Box's object space
	rObj.origin = vec3( uTallBoxInvMatrix * vec4(r.origin, 1.0) );
	rObj.direction = vec3( uTallBoxInvMatrix * vec4(r.direction, 0.0) );
	d = BoxIntersect( boxes[0].minCorner, boxes[0].maxCorner, rObj, normal, isRayExiting );
	
	if (d < t)
	{	
		t = d;
		
		// transfom normal back into world space
		normal = normalize(normal);
		intersec.normal = normalize(transpose(mat3(uTallBoxInvMatrix)) * normal);
		intersec.emission = boxes[0].emission;
		intersec.color = boxes[0].color;
		intersec.type = boxes[0].type;
	}
	
	
	// SHORT DIFFUSE WHITE BOX
	// transform ray into Short Box's object space
	rObj.origin = vec3( uShortBoxInvMatrix * vec4(r.origin, 1.0) );
	rObj.direction = vec3( uShortBoxInvMatrix * vec4(r.direction, 0.0) );
	d = BoxIntersect( boxes[1].minCorner, boxes[1].maxCorner, rObj, normal, isRayExiting );
	
	if (d < t)
	{	
		t = d;
		
		// transfom normal back into world space
		normal = normalize(normal);
		intersec.normal = normalize(transpose(mat3(uShortBoxInvMatrix)) * normal);
		intersec.emission = boxes[1].emission;
		intersec.color = boxes[1].color;
		intersec.type = boxes[1].type;
	}
	
	
	return t;
}



//-----------------------------------------------------------------------
vec3 CalculateRadiance(Ray originalRay)
//-----------------------------------------------------------------------
{

	Intersection intersec;
	
	vec3 accumCol = vec3(0);
        vec3 mask = vec3(1);
	vec3 n, nl, x;
	vec3 dirToLight;
	vec3 tdir;
	vec3 randPointOnLight = vec3( mix(quads[5].v0.x, quads[5].v1.x, rand()),
				      quads[5].v0.y,
				      mix(quads[5].v0.z, quads[5].v3.z, rand()) );
	vec3 lightHitPos = randPointOnLight;
	vec3 lightHitEmission = quads[5].emission;
        
	float lightHitDistance = INFINITY;
	float t = INFINITY;
	float t2 = INFINITY;
	float weight = 0.0;
	
	int diffuseCount = 0;

	bool bounceIsSpecular = true;
	bool sampleLight = false;
	bool ableToJoinPaths = false;
	bool diffuseFound = false;

	// first light trace
	Ray r = Ray(randPointOnLight, quads[5].normal);
	r.origin += quads[5].normal * uEPS_intersect;
	t = SceneIntersect(r, intersec);

	if (t < INFINITY && intersec.type == DIFF)
	{
		diffuseFound = true;
		lightHitPos = r.origin + r.direction * t;
		weight = max(0.0, dot(-r.direction, normalize(intersec.normal)));
		lightHitEmission *= intersec.color  * weight;

		// second light trace
		intersec.normal = normalize(intersec.normal);
		r = Ray(lightHitPos, randomCosWeightedDirectionInHemisphere(intersec.normal));
		r.origin += intersec.normal * uEPS_intersect;
		
		t2 = SceneIntersect(r, intersec);
		if (t2 < INFINITY && intersec.type == DIFF && rand() < 0.5)
		{
			lightHitPos = r.origin + r.direction * t2;
			weight = max(0.0, dot(-r.direction, normalize(intersec.normal)));
			lightHitEmission *= intersec.color * weight;
		}
	}

	// this allows the original light to be the lightsource once in a while
	if ( !diffuseFound || rand() < 0.5 )
	{
		lightHitPos = randPointOnLight;
		lightHitEmission = quads[5].emission;
	}


	// regular path tracing from camera
	r = originalRay;

	for (int bounces = 0; bounces < 5; bounces++)
	{

		t = SceneIntersect(r, intersec);
		
		if (t == INFINITY)
			break;
		
		
		if (intersec.type == LIGHT)
		{	
			accumCol = mask * intersec.emission;

			if (sampleLight)
				accumCol = mask * intersec.emission * max(0.0, dot(-r.direction, normalize(intersec.normal)));
			// reached a light, so we can exit
			break;
		}


		if (intersec.type == DIFF && sampleLight)
		{
			ableToJoinPaths = abs(lightHitDistance - t) < 0.5;

			if (ableToJoinPaths)
			{
				weight = max(0.0, dot(normalize(intersec.normal), -r.direction));
				accumCol = mask * lightHitEmission * weight;
			}
			
			break;
		}

		// if we reached this point and sampleLight is still true, then we can 
		//  exit because the light was not found
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

			if (diffuseCount < 3 && rand() < 0.8)
			{	
				// choose random Diffuse sample vector
				r = Ray( x, randomCosWeightedDirectionInHemisphere(nl) );
				r.origin += nl * uEPS_intersect;
				continue;
			}
			
			dirToLight = normalize(lightHitPos - x);
			lightHitDistance = distance(lightHitPos, x);
			weight = max(0.0, dot(nl, dirToLight));
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

			//bounceIsSpecular = true; // turn on mirror caustics
			continue;
		}
		
	} // end for (int bounces = 0; bounces < 5; bounces++)
	
	
	return max(vec3(0), accumCol);
	      
}



//-----------------------------------------------------------------------
void SetupScene(void)
//-----------------------------------------------------------------------
{
	vec3 z  = vec3(0);// No color value, Black
	vec3 L1 = vec3(1.0, 0.75, 0.4) * 30.0;// Bright Yellowish light
	//L1 = vec3(30);
	quads[0] = Quad( vec3( 0.0, 0.0, 1.0), vec3(  0.0,   0.0,-559.2), vec3(549.6,   0.0,-559.2), vec3(549.6, 548.8,-559.2), vec3(  0.0, 548.8,-559.2),  z, vec3(1),  DIFF);// Back Wall
	quads[1] = Quad( vec3( 1.0, 0.0, 0.0), vec3(  0.0,   0.0,   0.0), vec3(  0.0,   0.0,-559.2), vec3(  0.0, 548.8,-559.2), vec3(  0.0, 548.8,   0.0),  z, vec3(0.7, 0.12,0.05), DIFF);// Left Wall Red
	quads[2] = Quad( vec3(-1.0, 0.0, 0.0), vec3(549.6,   0.0,-559.2), vec3(549.6,   0.0,   0.0), vec3(549.6, 548.8,   0.0), vec3(549.6, 548.8,-559.2),  z, vec3(0.2, 0.4, 0.36), DIFF);// Right Wall Green
	quads[3] = Quad( vec3( 0.0,-1.0, 0.0), vec3(  0.0, 548.8,-559.2), vec3(549.6, 548.8,-559.2), vec3(549.6, 548.8,   0.0), vec3(  0.0, 548.8,   0.0),  z, vec3(1),  DIFF);// Ceiling
	quads[4] = Quad( vec3( 0.0, 1.0, 0.0), vec3(  0.0,   0.0,   0.0), vec3(549.6,   0.0,   0.0), vec3(549.6,   0.0,-559.2), vec3(  0.0,   0.0,-559.2),  z, vec3(1),  DIFF);// Floor
	quads[5] = Quad( vec3( 0.0,-1.0, 0.0), vec3(213.0, 548.0,-332.0), vec3(343.0, 548.0,-332.0), vec3(343.0, 548.0,-227.0), vec3(213.0, 548.0,-227.0), L1,       z, LIGHT);// Area Light Rectangle in ceiling
	
	boxes[0] = Box( vec3(-82.0,-170.0, -80.0), vec3(82.0,170.0, 80.0), z, vec3(1), SPEC);// Tall Mirror Box Left
	boxes[1] = Box( vec3(-86.0, -85.0, -80.0), vec3(86.0, 85.0, 80.0), z, vec3(1), DIFF);// Short Diffuse Box Right
	
	boxes[2] = Box( vec3(183.0, 534.0, -362.0), vec3(373.0, 535.0, -197.0), z, vec3(1), DIFF);// Light Blocker Box
	//boxes[2] = Box( vec3(183.0, 500.0, -362.0), vec3(373.0, 530.0, -197.0), z, vec3(1), DIFF);// Light Blocker Box
}


#include <pathtracing_main>
