#version 300 es

precision highp float;
precision highp int;
precision highp sampler2D;

#include <pathtracing_uniforms_and_defines>

uniform mat4 uTallBoxInvMatrix;
uniform mat3 uTallBoxNormalMatrix;

uniform sampler2D tPaintingTexture;
uniform sampler2D tDarkWoodTexture;
uniform sampler2D tLightWoodTexture;
uniform sampler2D tMarbleTexture;

#define N_SPHERES 2
#define N_ELLIPSOIDS 3
#define N_OPENCYLINDERS 4
#define N_QUADS 8
#define N_BOXES 10

struct Ray { vec3 origin; vec3 direction; };
struct Sphere { float radius; vec3 position; vec3 emission; vec3 color; float roughness; int type; };
struct Ellipsoid { vec3 radii; vec3 position; vec3 emission; vec3 color; float roughness; int type; };
struct OpenCylinder { float radius; vec3 pos1; vec3 pos2; vec3 emission; vec3 color; float roughness; int type; };
struct Quad { vec3 v0; vec3 v1; vec3 v2; vec3 v3; vec3 emission; vec3 color; float roughness; int type; };
struct Box { vec3 minCorner; vec3 maxCorner; vec3 emission; vec3 color; float roughness; int type; };
struct Intersection { vec3 normal; vec3 emission; vec3 color; float roughness; int type; };

Sphere spheres[N_SPHERES];
Ellipsoid ellipsoids[N_ELLIPSOIDS];
OpenCylinder openCylinders[N_OPENCYLINDERS];
Quad quads[N_QUADS];
Box boxes[N_BOXES];


#include <pathtracing_random_functions>

#include <pathtracing_calc_fresnel_reflectance>

#include <pathtracing_sphere_intersect>

#include <pathtracing_ellipsoid_intersect>

#include <pathtracing_opencylinder_intersect>

#include <pathtracing_triangle_intersect>

#include <pathtracing_box_intersect>


//----------------------------------------------------------------------------
float QuadIntersect( vec3 v0, vec3 v1, vec3 v2, vec3 v3, Ray r )
//----------------------------------------------------------------------------
{
	float tTri1 = TriangleIntersect( v0, v1, v2, r );
	float tTri2 = TriangleIntersect( v0, v2, v3, r );
	return min(tTri1, tTri2);
}

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
		d = QuadIntersect( quads[i].v0, quads[i].v1, quads[i].v2, quads[i].v3, r );
		if (d < t && d > 0.0)
		{
			if (i == 1) // check back wall quad for door portal opening
			{
				vec3 ip = r.origin + r.direction * d;
				if (ip.x > 180.0 && ip.x < 280.0 && ip.y > -100.0 && ip.y < 90.0)
					continue;
			}
			
			
			t = d;
			intersec.normal = normalize( cross(quads[i].v1 - quads[i].v0, quads[i].v2 - quads[i].v0) );
			intersec.emission = quads[i].emission;
			intersec.color = quads[i].color;
			intersec.roughness = quads[i].roughness;
			intersec.type = quads[i].type;
		}
        }
	
	for (int i = 0; i < N_BOXES - 1; i++)
        {
		d = BoxIntersect( boxes[i].minCorner, boxes[i].maxCorner, r, normal );
		if (d < t)
		{
			t = d;
			intersec.normal = normalize(normal);
			intersec.emission = boxes[i].emission;
			intersec.color = boxes[i].color;
			intersec.roughness = boxes[i].roughness;
			intersec.type = boxes[i].type;
		}
	}
	
	// DOOR (TALL BOX)
	Ray rObj;
	// transform ray into Tall Box's object space
	rObj.origin = vec3( uTallBoxInvMatrix * vec4(r.origin, 1.0) );
	rObj.direction = vec3( uTallBoxInvMatrix * vec4(r.direction, 0.0) );
	d = BoxIntersect( boxes[9].minCorner, boxes[9].maxCorner, rObj, normal );
	
	if (d < t)
	{	
		t = d;
		
		// transfom normal back into world space
		normal = vec3(uTallBoxNormalMatrix * normal);
		
		intersec.normal = normalize(normal);
		intersec.emission = boxes[9].emission;
		intersec.color = boxes[9].color;
		intersec.roughness = boxes[9].roughness;
		intersec.type = boxes[9].type;
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
	
	for (int i = 0; i < N_SPHERES; i++)
        {
		d = SphereIntersect( spheres[i].radius, spheres[i].position, rObj );
		if (d < t)
		{
			t = d;

			normal = normalize((rObj.origin + rObj.direction * t) - spheres[i].position);
			normal = vec3(uTallBoxNormalMatrix * normal);
			intersec.normal = normalize(normal);
			intersec.emission = spheres[i].emission;
			intersec.color = spheres[i].color;
			intersec.type = spheres[i].type;
		}
	}
	
	return t;
}


#define EYE_PATH_LENGTH    4
#define LIGHT_PATH_LENGTH  1  // Only 1 ray cast from light source is necessary because the light just needs to find its way through
				// the crack in the doorway and land on a wall, where it can be connected with the eye path later

//-----------------------------------------------------------------------
vec3 CalculateRadiance( Ray r, inout uvec2 seed )
//-----------------------------------------------------------------------
{
	vec3 randVec = vec3(rand(seed) * 2.0 - 1.0, rand(seed) * 2.0 - 1.0, rand(seed) * 2.0 - 1.0);
	Intersection intersec;
	vec3 accumCol = vec3(0);
	vec3 maskEyePath = vec3(1);
	vec3 maskLightPath = vec3(1);
	vec3 eyeX = vec3(0);
	vec3 lightX = vec3(0);
	vec3 checkCol0 = vec3(0.01);
	vec3 checkCol1 = vec3(1.0);
	vec3 nl, n, x;
	vec3 nlEyePath = vec3(0);
	vec3 tdir;
	
	float nc, nt, Re;
	float t = INFINITY;
	int diffuseCount = 0;
	int previousIntersecType = -1;
	bool bounceIsSpecular = true;
	
	//set following flag to true - we haven't found a diffuse surface yet and can exit early (keeps frame rate high)
	bool skipConnectionEyePath = true;

	
	// Eye path tracing (from Camera) ///////////////////////////////////////////////////////////////////////////
	
	for (int bounces = 0; bounces < EYE_PATH_LENGTH; bounces++)
	{
	
		t = SceneIntersect(r, intersec);
		
		// not needed, light can't escape from the small room in this scene
		/*
		if (t == INFINITY)
		{
			break;
		}
		*/
		
		if (intersec.type == LIGHT)
		{
			if (bounceIsSpecular)
			{
				accumCol = maskEyePath * intersec.emission;
			
				skipConnectionEyePath = true;
			}
			
			break;
		}
		
		// useful data 
		n = normalize(intersec.normal);
		nl = dot(n, r.direction) < 0.0 ? normalize(n) : normalize(n * -1.0);
		x = r.origin + r.direction * t;
		
		
		if ( intersec.type == DIFF || intersec.type == LIGHTWOOD ||
		     intersec.type == DARKWOOD || intersec.type == PAINTING ) // Ideal DIFFUSE reflection
		{
			
			if (intersec.type == LIGHTWOOD)
			{
				vec2 uv;
				if (abs(nl.x) > 0.5) uv = vec2(x.z, x.y);
				else if (abs(nl.y) > 0.5) uv = vec2(x.x, x.z);
				else uv = vec2(x.x, x.y);
				intersec.color *= texture(tLightWoodTexture, uv * 0.01).rgb;
			}
			else if (intersec.type == DARKWOOD)
			{
				vec2 uv = vec2( uTallBoxInvMatrix * vec4(x, 1.0) );
				intersec.color *= texture(tDarkWoodTexture, uv * vec2(0.01,0.005)).rgb;
			}
			else if (intersec.type == PAINTING)
			{
				vec2 uv = vec2((55.0 + x.x) / 110.0, (x.y - 20.0) / 44.0);
				intersec.color *= texture(tPaintingTexture, uv).rgb;
			}
					
			maskEyePath *= intersec.color;
			eyeX = x + nl;
			nlEyePath = nl;
			skipConnectionEyePath = false;
			bounceIsSpecular = false;
			previousIntersecType = DIFF;
			
			diffuseCount++;
			if (diffuseCount > 1 || rand(seed) < 0.5)
			{
				break;
			}
				
			// choose random Diffuse sample vector
			r = Ray( x, randomCosWeightedDirectionInHemisphere(nl, seed) );
			r.origin += r.direction;
			eyeX = r.origin;
			continue;
		}
		
		if (intersec.type == SPEC)  // Ideal SPECULAR reflection
		{
			maskEyePath *= intersec.color;
			
			vec3 reflectVec = reflect(r.direction, nl);
			vec3 glossyVec = randomDirectionInHemisphere(nl, seed);
			r = Ray( x, mix(reflectVec, glossyVec, intersec.roughness) );
			r.origin += r.direction;

			previousIntersecType = SPEC;
			continue;
		}
		
		
		if (intersec.type == REFR)  // Ideal dielectric refraction
		{	
			nc = 1.0; // IOR of Air
			nt = 1.5; // IOR of common Glass
			Re = calcFresnelReflectance(n, nl, r.direction, nc, nt, tdir);

			if (rand(seed) < Re) // reflect ray from surface
			{
				r = Ray( x, reflect(r.direction, nl) );
				r.origin += r.direction;
				
				previousIntersecType = REFR;
				continue;	
			}
			else // transmit ray through surface
			{
				if (previousIntersecType == DIFF) 
					maskEyePath *= 4.0;
			
				previousIntersecType = REFR;
			
				maskEyePath *= intersec.color;
				r = Ray(x, tdir);
				r.origin += r.direction;

				continue;
			}	
		} // end if (intersec.type == REFR)
		
		if (intersec.type == COAT || intersec.type == CHECK)  // Diffuse object underneath with ClearCoat on top
		{	
			nc = 1.0; // IOR of Air
			nt = 1.4; // IOR of ClearCoat
			Re = calcFresnelReflectance(n, nl, r.direction, nc, nt, tdir);
			
			previousIntersecType = COAT;
			
			// choose either specular reflection or diffuse
			if( rand(seed) < Re )
			{	
				vec3 reflectVec = reflect(r.direction, nl);
				vec3 glossyVec = randomDirectionInHemisphere(nl, seed);
				r = Ray( x, mix(reflectVec, glossyVec, intersec.roughness) );
				r.origin += r.direction;
				
				continue;	
			}
			else
			{
				if (intersec.type == CHECK)
				{
					float q = clamp( mod( dot( floor(x.xz * 0.04), vec2(1.0) ), 2.0 ) , 0.0, 1.0 );
					intersec.color = checkCol0 * q + checkCol1 * (1.0 - q);	
				}
				
				if (intersec.color.r == 0.99) // tag for marble ellipsoid
				{
					vec2 uv;
					// spherical coordinates
					uv.x = (1.0 + atan(nl.z, nl.x) / PI) * 0.5;
					uv.y = acos(nl.y) / PI;
					intersec.color = texture(tMarbleTexture, uv).rgb;
				}
				
				diffuseCount++;

				skipConnectionEyePath = false;
				bounceIsSpecular = false;
				maskEyePath *= intersec.color;
				
				eyeX = x + nl;
				nlEyePath = nl;
				
				// choose random sample vector for diffuse material underneath ClearCoat
				r = Ray( x, randomCosWeightedDirectionInHemisphere(nl, seed) );
				r.origin += r.direction;
				continue;	
			}	
		} //end if (intersec.type == COAT)
		
	} // end for (int bounces = 0; bounces < EYE_PATH_LENGTH; bounces++)
	
	
	if (skipConnectionEyePath)
		return accumCol;
	
	
	// Light path tracing (from Light source) /////////////////////////////////////////////////////////////////////

	vec3 randPointOnLight;
	randPointOnLight.x = mix(quads[0].v0.x, quads[0].v1.x, rand(seed));
	randPointOnLight.y = mix(quads[0].v0.y, quads[0].v3.y, rand(seed));
	randPointOnLight.z = quads[0].v0.z;
	vec3 randLightDir = randomCosWeightedDirectionInHemisphere(vec3(0,0,1), seed);
	vec3 nlLightPath = vec3(0,0,1);
	bool diffuseReached = false;
	randLightDir = normalize(randLightDir);
	r = Ray( randPointOnLight, randLightDir );
	r.origin += r.direction; // move light ray out to prevent self-intersection with light
	lightX = r.origin;
	maskLightPath = quads[0].emission;
	
	
	for (int bounces = 0; bounces < LIGHT_PATH_LENGTH; bounces++)
	{
		// this lets the original light be the only node on the light path, about 50% of the time
		if (rand(seed) < 0.5)
		{
			break;
		}
				
		t = SceneIntersect(r, intersec);

		if ( intersec.type != DIFF )
		{
			break;
		}
		
		// useful data 
		n = normalize(intersec.normal);
		nl = dot(n, r.direction) < 0.0 ? normalize(n) : normalize(n * -1.0);
		x = r.origin + r.direction * t;
		
		
		//if (intersec.type == DIFF)
		{
			maskLightPath *= intersec.color;
			lightX = x + nl;
			nlLightPath = nl;
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
	vec3 z  = vec3(0.0);// No color value, Black        
	//vec3 L1 = vec3(1.0) * 6.0;// Bright White light
	vec3 L2 = vec3(1.0, 0.9, 0.8) * 3.0;// Bright Yellowish light
	vec3 tableColor = vec3(1.0, 0.7, 0.4) * 0.6;
	vec3 brassColor = vec3(1.0, 0.7, 0.5) * 0.7;
	
	quads[0] = Quad( vec3( 180,-100,-299), vec3( 280,-100,-299), vec3( 280,  90,-299), vec3( 180,  90,-299), L2, z, 0.0, LIGHT);// Area Light Quad in doorway
	
	quads[1] = Quad( vec3(-350,-100,-300), vec3( 350,-100,-300), vec3( 350, 150,-300), vec3(-350, 150,-300),  z, vec3(1.0), 0.0,   DIFF);// Back Wall (in front of camera, visible at startup)
	quads[2] = Quad( vec3( 350,-100, 200), vec3(-350,-100, 200), vec3(-350, 150, 200), vec3( 350, 150, 200),  z, vec3(1.0), 0.0,   DIFF);// Front Wall (behind camera, not visible at startup)
	quads[3] = Quad( vec3(-350,-100, 200), vec3(-350,-100,-300), vec3(-350, 150,-300), vec3(-350, 150, 200),  z, vec3(1.0), 0.0,   DIFF);// Left Wall
	quads[4] = Quad( vec3( 350,-100,-300), vec3( 350,-100, 200), vec3( 350, 150, 200), vec3( 350, 150,-300),  z, vec3(1.0), 0.0,   DIFF);// Right Wall
	quads[5] = Quad( vec3(-350, 150,-300), vec3( 350, 150,-300), vec3( 350, 150, 200), vec3(-350, 150, 200),  z, vec3(1.0), 0.0,   DIFF);// Ceiling
	quads[6] = Quad( vec3(-350,-100,-300), vec3(-350,-100, 200), vec3( 350,-100, 200), vec3( 350,-100,-300),  z, vec3(1.0), 0.0,  CHECK);// Floor
	
	quads[7] = Quad( vec3(-55, 20,-295), vec3( 55, 20,-295), vec3( 55, 65,-295), vec3(-55, 65,-295), z, vec3(0.9), 0.0, PAINTING);// Wall Painting
	
	boxes[0] = Box( vec3(-100,-60,-230), vec3(100,-57,-130), z, vec3(1.0), 0.0, LIGHTWOOD);// Table Top
	boxes[1] = Box( vec3(-90,-100,-150), vec3(-84,-60,-144), z, vec3(0.8, 0.85, 0.9),  0.1, SPEC);// Table leg left front
	boxes[2] = Box( vec3(-90,-100,-220), vec3(-84,-60,-214), z, vec3(0.8, 0.85, 0.9),  0.1, SPEC);// Table leg left rear
	boxes[3] = Box( vec3( 84,-100,-150), vec3( 90,-60,-144), z, vec3(0.8, 0.85, 0.9),  0.1, SPEC);// Table leg right front
	boxes[4] = Box( vec3( 84,-100,-220), vec3( 90,-60,-214), z, vec3(0.8, 0.85, 0.9),  0.1, SPEC);// Table leg right rear
	
	boxes[5] = Box( vec3(-60, 15, -299), vec3( 60, 70, -296), z, vec3(0.01, 0, 0), 0.3, SPEC);// Painting Frame
	
	boxes[6] = Box( vec3( 172,-100,-302), vec3( 180,  98,-299), z, vec3(0.001), 0.3, SPEC);// Door Frame left
	boxes[7] = Box( vec3( 280,-100,-302), vec3( 288,  98,-299), z, vec3(0.001), 0.3, SPEC);// Door Frame right
	boxes[8] = Box( vec3( 172,  90,-302), vec3( 288,  98,-299), z, vec3(0.001), 0.3, SPEC);// Door Frame top
	boxes[9] = Box( vec3(   0, -94,  -3), vec3( 101,  95,   3), z, vec3(1.0), 0.0, DARKWOOD);// Door
	
	openCylinders[0] = OpenCylinder( 1.5, vec3( 179,  64,-297), vec3( 179,  80,-297), z, brassColor, 0.2, SPEC);// Door Hinge upper
	openCylinders[1] = OpenCylinder( 1.5, vec3( 179,  -8,-297), vec3( 179,   8,-297), z, brassColor, 0.2, SPEC);// Door Hinge middle
	openCylinders[2] = OpenCylinder( 1.5, vec3( 179, -80,-297), vec3( 179, -64,-297), z, brassColor, 0.2, SPEC);// Door Hinge lower
	
	spheres[0] = Sphere( 4.0, vec3( 88, -10,  7.8), z, brassColor, 0.0, SPEC);// Door knob front
	spheres[1] = Sphere( 4.0, vec3( 88, -10, -7), z, brassColor, 0.0, SPEC);// Door knob back
	
	ellipsoids[0] = Ellipsoid( vec3(22, 18, 22), vec3( -60, -43,-180), z, vec3(0.9 ), 0.3, SPEC);// Metallic Ellipsoid
	ellipsoids[1] = Ellipsoid( vec3(22, 18, 22), vec3(   0, -43,-180), z, vec3(0.99), 0.0, COAT);// Marble Ellipsoid
	ellipsoids[2] = Ellipsoid( vec3(22, 18, 22), vec3(  60, -43,-180), z, vec3(1.0 ), 0.0, REFR);// Glass Ellipsoid
}


#include <pathtracing_main>
