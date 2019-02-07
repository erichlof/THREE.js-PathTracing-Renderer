#version 300 es

precision highp float;
precision highp int;
precision highp sampler2D;

#include <pathtracing_uniforms_and_defines>

uniform mat4 uTorusInvMatrix;
uniform mat3 uTorusNormalMatrix;

#define N_SPHERES 6
#define N_PLANES 1
#define N_DISKS 1
#define N_TRIANGLES 1
#define N_QUADS 1
#define N_BOXES 2
#define N_ELLIPSOIDS 1
#define N_PARABOLOIDS 1
#define N_OPENCYLINDERS 1
#define N_CAPPEDCYLINDERS 1
#define N_CONES 1
#define N_CAPSULES 1
#define N_TORII 1


//-----------------------------------------------------------------------

struct Ray { vec3 origin; vec3 direction; };
struct Sphere { float radius; vec3 position; vec3 emission; vec3 color; int type; bool isDynamic; };
struct Ellipsoid { vec3 radii; vec3 position; vec3 emission; vec3 color; int type; bool isDynamic; };
struct Paraboloid { float rad; float height; vec3 pos; vec3 emission; vec3 color; int type; bool isDynamic; };
struct OpenCylinder { float radius; float height; vec3 position; vec3 emission; vec3 color; int type; bool isDynamic; };
struct CappedCylinder { float radius; vec3 cap1pos; vec3 cap2pos; vec3 emission; vec3 color; int type; bool isDynamic; };
struct Cone { vec3 pos0; float radius0; vec3 pos1; float radius1; vec3 emission; vec3 color; int type; bool isDynamic; };
struct Capsule { vec3 pos0; float radius0; vec3 pos1; float radius1; vec3 emission; vec3 color; int type; bool isDynamic; };
struct Torus { float radius0; float radius1; vec3 emission; vec3 color; int type; bool isDynamic; };
struct Box { vec3 minCorner; vec3 maxCorner; vec3 emission; vec3 color; int type; bool isDynamic; };
struct Intersection { vec3 normal; vec3 emission; vec3 color; int type; bool isDynamic; };

Sphere spheres[N_SPHERES];
Ellipsoid ellipsoids[N_ELLIPSOIDS];
Paraboloid paraboloids[N_PARABOLOIDS];
OpenCylinder openCylinders[N_OPENCYLINDERS];
CappedCylinder cappedCylinders[N_CAPPEDCYLINDERS];
Cone cones[N_CONES];
Capsule capsules[N_CAPSULES];
Torus torii[N_TORII];
Box boxes[N_BOXES];


#include <pathtracing_random_functions>

#include <pathtracing_calc_fresnel_reflectance>

#include <pathtracing_sphere_intersect>

#include <pathtracing_ellipsoid_intersect>

#include <pathtracing_opencylinder_intersect>

#include <pathtracing_cappedcylinder_intersect>

#include <pathtracing_cone_intersect>

#include <pathtracing_capsule_intersect>

#include <pathtracing_paraboloid_intersect>

#include <pathtracing_torus_intersect>

#include <pathtracing_box_intersect>

#include <pathtracing_sample_sphere_light>



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
			intersec.isDynamic = spheres[i].isDynamic;
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
			intersec.isDynamic = boxes[i].isDynamic;
		}
        }
	
	d = EllipsoidIntersect( ellipsoids[0].radii, ellipsoids[0].position, r );
	if (d < t)
	{
		t = d;
		intersec.normal = normalize( ((r.origin + r.direction * t) - 
			ellipsoids[0].position) / (ellipsoids[0].radii * ellipsoids[0].radii) );
		intersec.emission = ellipsoids[0].emission;
		intersec.color = ellipsoids[0].color;
		intersec.type = ellipsoids[0].type;
		intersec.isDynamic = ellipsoids[0].isDynamic;
	}
	
	d = ParaboloidIntersect( paraboloids[0].rad, paraboloids[0].height, paraboloids[0].pos, r, n );
	if (d < t)
	{
		t = d;
		intersec.normal = normalize(n);
		intersec.emission = paraboloids[0].emission;
		intersec.color = paraboloids[0].color;
		intersec.type = paraboloids[0].type;
		intersec.isDynamic = paraboloids[0].isDynamic;
	}
	
	d = OpenCylinderIntersect( openCylinders[0].position, openCylinders[0].position + vec3(0,30,30), openCylinders[0].radius, r, n );
	if (d < t)
	{
		t = d;
		intersec.normal = normalize(n);
		intersec.emission = openCylinders[0].emission;
		intersec.color = openCylinders[0].color;
		intersec.type = openCylinders[0].type;
		intersec.isDynamic = openCylinders[0].isDynamic;
	}
        
	d = CappedCylinderIntersect( cappedCylinders[0].cap1pos, cappedCylinders[0].cap2pos, cappedCylinders[0].radius, r, n);
	if (d < t)
	{
		t = d;
		intersec.normal = normalize(n);
		intersec.emission = cappedCylinders[0].emission;
		intersec.color = cappedCylinders[0].color;
		intersec.type = cappedCylinders[0].type;
		intersec.isDynamic = cappedCylinders[0].isDynamic;
	}
        
	d = ConeIntersect( cones[0].pos0, cones[0].radius0, cones[0].pos1, cones[0].radius1, r, n );
	if (d < t)
	{
		t = d;
		intersec.normal = normalize(n);
		intersec.emission = cones[0].emission;
		intersec.color = cones[0].color;
		intersec.type = cones[0].type;
		intersec.isDynamic = cones[0].isDynamic;
	}
        
	d = CapsuleIntersect( capsules[0].pos0, capsules[0].radius0, capsules[0].pos1, capsules[0].radius1, r, n );
	if (d < t)
	{
		t = d;
		intersec.normal = normalize(n);
		intersec.emission = capsules[0].emission;
		intersec.color = capsules[0].color;
		intersec.type = capsules[0].type;
		intersec.isDynamic = capsules[0].isDynamic;
	}
        
	Ray rObj;
	// transform ray into Torus's object space
	rObj.origin = vec3( uTorusInvMatrix * vec4(r.origin, 1.0) );
	rObj.direction = vec3( uTorusInvMatrix * vec4(r.direction, 0.0) );
	
	d = TorusIntersect( torii[0].radius0, torii[0].radius1, rObj );
	if (d < t)
	{
		t = d;
		vec3 hit = rObj.origin + rObj.direction * t;
		intersec.normal = calcNormal_Torus(hit);
		// transfom normal back into world space
		intersec.normal = vec3(uTorusNormalMatrix * intersec.normal);
		intersec.emission = torii[0].emission;
		intersec.color = torii[0].color;
		intersec.type = torii[0].type;
		intersec.isDynamic = torii[0].isDynamic;
	}
        
	return t;
	
} // end float SceneIntersect( Ray r, inout Intersection intersec )


//--------------------------------------------------------------------------------------------------------
vec3 CalculateRadiance( Ray r, inout uvec2 seed, inout bool rayHitIsDynamic )
//--------------------------------------------------------------------------------------------------------
{
	Intersection intersec;

	vec3 accumCol = vec3(0.0);
        vec3 mask = vec3(1.0);
	vec3 checkCol0 = vec3(1);
	vec3 checkCol1 = vec3(0.5);
	vec3 dirToLight;
	vec3 tdir;
        
	float nc, nt, Re;
	float weight;
	float randChoose;
	float diffuseColorBleeding = 0.1; // range: 0.0 - 0.5, amount of color bleeding between surfaces
	
	int diffuseCount = 0;
	int previousIntersecType = -100;

	bool bounceIsSpecular = true;
	bool sampleLight = false;

	Sphere lightChoice;
	
	rayHitIsDynamic = false;
	

	for (int bounces = 0; bounces < 6; bounces++)
	{
		
		float t = SceneIntersect(r, intersec);
		
		if (bounces == 0 && intersec.isDynamic)
			rayHitIsDynamic = true;

		/*
		//not used in this scene because we are inside a huge sphere - no rays can escape
		if (t == INFINITY)
		{
                        break;
		}
		*/
		
		// if we reached something bright, don't spawn any more rays
		if (intersec.type == LIGHT)
		{	
			if (sampleLight)// || bounceIsSpecular)
			{
				accumCol = mask * intersec.emission;
			}
			else if (bounceIsSpecular)
			{
				accumCol = mask * clamp(intersec.emission, 0.0, 2.0);
			}
			
			break;
		}

		// comment out the following if refractive caustics are still desired

		// if we reached this point and sampleLight failed to find a light above, exit early
		//if (sampleLight)
		//{
		//	break;
		//}
		
		// useful data 
		vec3 n = intersec.normal;
                vec3 nl = dot(n,r.direction) <= 0.0 ? normalize(n) : normalize(n * -1.0);
		vec3 x = r.origin + r.direction * t;

		randChoose = rand(seed);
		if (randChoose < 0.33)
			lightChoice = spheres[0];
		else if (randChoose < 0.66)
			lightChoice = spheres[1];
		else lightChoice = spheres[2];
		
		    
                if (intersec.type == DIFF || intersec.type == CHECK) // Ideal DIFFUSE reflection
		{
			previousIntersecType = DIFF;
			diffuseCount++;

			if (diffuseCount > 2)
				break;

			if( intersec.type == CHECK )
			{
				float q = clamp( mod( dot( floor(x.xz * 0.04), vec2(1.0) ), 2.0 ) , 0.0, 1.0 );
				intersec.color = checkCol0 * q + checkCol1 * (1.0 - q);	
			}

			mask *= intersec.color;

			/*
			// Russian Roulette - if needed, this speeds up the framerate, at the cost of some dark noise
			float p = max(mask.r, max(mask.g, mask.b));
			if (bounces > 0)
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
				weight = sampleSphereLight(x, nl, dirToLight, lightChoice, seed);
				mask *= clamp(weight, 0.0, 1.0);

                                r = Ray( x, dirToLight );
				r.origin += nl;

				sampleLight = true;
				continue;
			}
			
		}
		
		if (intersec.type == SPEC)  // Ideal SPECULAR reflection
		{
			mask *= intersec.color;

			r = Ray( x, reflect(r.direction, nl) );
			r.origin += r.direction;

			previousIntersecType = SPEC;
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

				previousIntersecType = REFR;
				//bounceIsSpecular = true; // turn on reflecting caustics, useful for water
			    	continue;	
			}
			else // transmit ray through surface
			{
				mask *= intersec.color;

				if (previousIntersecType == DIFF)
					mask *= TWO_PI;
				
				r = Ray(x, tdir);
				r.origin += r.direction;

				previousIntersecType = REFR;
				//bounceIsSpecular = true; // turn on refracting caustics
				continue;
			}
			
		} // end if (intersec.type == REFR)
		
		if (intersec.type == COAT)  // Diffuse object underneath with ClearCoat on top
		{
			previousIntersecType = COAT;

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

			if (diffuseCount > 2)
				break;

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
				if (rand(seed) < 0.9)
					lightChoice = spheres[0]; // this makes capsule more white
				weight = sampleSphereLight(x, nl, dirToLight, lightChoice, seed);
				mask *= clamp(weight, 0.0, 1.0);
				
                                r = Ray( x, dirToLight );
				r.origin += nl;

				sampleLight = true;
				continue;
                        }
			
		} //end if (intersec.type == COAT)
		
	} // end for (int bounces = 0; bounces < 6; bounces++)
	
	return accumCol;      
}


//-----------------------------------------------------------------------
void SetupScene(void)
//-----------------------------------------------------------------------
{
	vec3 z  = vec3(0.0);          
	vec3 L1 = vec3(1.0, 1.0, 1.0) * 18.0;// White light
	vec3 L2 = vec3(1.0, 0.8, 0.2) * 15.0;// Yellow light
	vec3 L3 = vec3(0.1, 0.7, 1.0) * 10.0;// Blue light
		
        spheres[0] = Sphere(150.0, vec3(-400, 900, 200), L1, z, LIGHT, false);//spherical white Light1 
	spheres[1] = Sphere(100.0, vec3( 300, 400,-300), L2, z, LIGHT, false);//spherical yellow Light2
	spheres[2] = Sphere( 50.0, vec3( 500, 250,-100), L3, z, LIGHT, false);//spherical blue Light3
	
	spheres[3] = Sphere(1000.0, vec3(  0.0, 1000.0,  0.0), z, vec3(1.0, 1.0, 1.0), CHECK, false);//Checkered Floor
        spheres[4] = Sphere(  16.5, vec3(-26.0,   17.2,  5.0), z, vec3(0.95, 0.95, 0.95), SPEC, false);//Mirror sphere
        spheres[5] = Sphere(  15.0, vec3( sin(mod(uTime * 0.3, TWO_PI)) * 80.0, 25, cos(mod(uTime * 0.1, TWO_PI)) * 80.0 ), z, vec3(1.0, 1.0, 1.0), REFR, true);//Glass sphere
        
	ellipsoids[0] = Ellipsoid(  vec3(30,40,16), vec3(cos(mod(uTime * 0.5, TWO_PI)) * 80.0,5,-30), z, vec3(1.0, 0.765557, 0.336057), SPEC, true);//metallic gold ellipsoid
	
	paraboloids[0] = Paraboloid(  16.5, 50.0, vec3(20,1,-50), z, vec3(1.0, 0.2, 0.7), REFR, false);//paraboloid
	
	openCylinders[0] = OpenCylinder( 15.0, 30.0, vec3( cos(mod(uTime * 0.1, TWO_PI)) * 100.0, 10, sin(mod(uTime * 0.4, TWO_PI)) * 100.0 ), z, vec3(0.7,0.01,0.01), REFR, true);//red glass open Cylinder

	cappedCylinders[0] = CappedCylinder( 14.0, vec3(-60,0,20), vec3(-60,14,20), z, vec3(0.05,0.05,0.05), COAT, false);//dark gray capped Cylinder
	
	cones[0] = Cone( vec3(1,20,-12), 15.0, vec3(1,0,-12), 0.0, z, vec3(0.01,0.1,0.5), REFR, false);//blue Cone
	
	capsules[0] = Capsule( vec3(80,13,15), 10.0, vec3(110,15.8,15), 10.0, z, vec3(1.0,1.0,1.0), COAT, false);//white Capsule
	
	torii[0] = Torus( 10.0, 1.5, z, vec3(0.955008, 0.637427, 0.538163), SPEC, false);//copper Torus
	
	boxes[0] = Box( vec3(50.0,21.0,-60.0), vec3(100.0,28.0,-130.0), z, vec3(0.2,0.9,0.7), REFR, false);//Glass Box
	boxes[1] = Box( vec3(56.0,23.0,-66.0), vec3(94.0,26.0,-124.0), z, vec3(0.0,0.0,0.0), DIFF, false);//Diffuse Box
}


//#include <pathtracing_main>

// tentFilter from Peter Shirley's 'Realistic Ray Tracing (2nd Edition)' book, pg. 60		
float tentFilter(float x)
{
	if (x < 0.5) 
		return sqrt(2.0 * x) - 1.0;
	else return 1.0 - sqrt(2.0 - (2.0 * x));
}

void main( void )
{
	// not needed, three.js has a built-in uniform named cameraPosition
	//vec3 camPos   = vec3( uCameraMatrix[3][0],  uCameraMatrix[3][1],  uCameraMatrix[3][2]);
	
	vec3 camRight   = vec3( uCameraMatrix[0][0],  uCameraMatrix[0][1],  uCameraMatrix[0][2]);
	vec3 camUp      = vec3( uCameraMatrix[1][0],  uCameraMatrix[1][1],  uCameraMatrix[1][2]);
	vec3 camForward = vec3(-uCameraMatrix[2][0], -uCameraMatrix[2][1], -uCameraMatrix[2][2]);
	
	// seed for rand(seed) function
	uvec2 seed = uvec2(uFrameCounter, uFrameCounter + 1.0) * uvec2(gl_FragCoord);

	vec2 pixelPos = vec2(0);
	vec2 pixelOffset = vec2(0);
	
	float x = rand(seed);
	float y = rand(seed);

	if (!uCameraIsMoving)
	{
		pixelOffset.x = tentFilter(x);
		pixelOffset.y = tentFilter(y);
	}
	
	
	// pixelOffset ranges from -1.0 to +1.0, so only need to divide by half resolution
	pixelOffset /= (uResolution * 0.5);

	// vUv comes in the range 0.0 to 1.0, so we must map it to the range -1.0 to +1.0
	pixelPos = vUv * 2.0 - 1.0;
	pixelPos += pixelOffset;

	vec3 rayDir = normalize( pixelPos.x * camRight * uULen + pixelPos.y * camUp * uVLen + camForward );
	
	// depth of field
	vec3 focalPoint = uFocusDistance * rayDir;
	float randomAngle = rand(seed) * TWO_PI; // pick random point on aperture
	float randomRadius = rand(seed) * uApertureSize;
	vec3  randomAperturePos = ( cos(randomAngle) * camRight + sin(randomAngle) * camUp ) * randomRadius;
	// point on aperture to focal point
	vec3 finalRayDir = normalize(focalPoint - randomAperturePos);
	
	Ray ray = Ray( cameraPosition + randomAperturePos, finalRayDir );

	SetupScene(); 

	bool rayHitIsDynamic = false;
	
	// perform path tracing and get resulting pixel color
	vec3 pixelColor = CalculateRadiance( ray, seed, rayHitIsDynamic );
	
	vec4 previousImage = texture2D(tPreviousTexture, vUv);
	vec3 previousColor = previousImage.rgb;

	
	if (uCameraIsMoving || previousImage.a > 0.0)
	{
                previousColor *= 0.55; // motion-blur trail amount (old image)
                pixelColor *= 0.45; // brightness of new image (noisy)
        }
	else
	{
                previousColor *= 0.93; // motion-blur trail amount (old image)
                pixelColor *= 0.07; // brightness of new image (noisy)
        }
	
        out_FragColor = vec4( pixelColor + previousColor, rayHitIsDynamic? 1.0 : 0.0 );	
}
