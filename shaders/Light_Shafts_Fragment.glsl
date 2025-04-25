precision highp float;
precision highp int;
precision highp sampler2D;

#include <pathtracing_uniforms_and_defines>

#define N_SPHERES 2
#define N_QUADS 2
#define N_BOXES 1


//-----------------------------------------------------------------------

vec3 rayOrigin, rayDirection;

struct Sphere { float radius; vec3 position; vec3 emission; vec3 color; int type; };
struct Quad { vec3 normal; vec3 v0; vec3 v1; vec3 v2; vec3 v3; vec3 emission; vec3 color; int type; };
struct Box { vec3 minCorner; vec3 maxCorner; vec3 emission; vec3 color; int type; };

Sphere spheres[N_SPHERES];
Quad quads[N_QUADS];
Box boxes[N_BOXES];


#include <pathtracing_random_functions>

#include <pathtracing_calc_fresnel_reflectance>

#include <pathtracing_sphere_intersect>

#include <pathtracing_box_intersect>

#include <pathtracing_quad_intersect>


vec3 randPointOnLight; // global variable that can be used across multiple functions

vec3 sampleQuadLight(vec3 x, vec3 nl, Quad light, out float weight)
{
	// vec3 randPointOnLight is already chosen on each bounces loop iteration below in the CalculateRadiance() function 
	
	vec3 dirToLight = randPointOnLight - x;
	float r2 = distance(light.v0, light.v1) * distance(light.v0, light.v3);
	float d2 = dot(dirToLight, dirToLight);
	float cos_a_max = sqrt(1.0 - clamp( r2 / d2, 0.0, 1.0));
	dirToLight = normalize(dirToLight);
	float dotNlRayDir = max(0.0, dot(nl, dirToLight)); 
	weight =  2.0 * (1.0 - cos_a_max) * max(0.0, -dot(dirToLight, light.normal)) * dotNlRayDir; 
	weight = clamp(weight, 0.0, 1.0);
	return dirToLight;
}


//----------------------------------------------------------------------------------------------------------------------------------------
float BoxMissingSidesIntersect( vec3 minCorner, vec3 maxCorner, vec3 rayOrigin, vec3 rayDirection, out vec3 normal, out int isRayExiting )
//----------------------------------------------------------------------------------------------------------------------------------------
{
	vec3 invDir = 1.0 / rayDirection;
	vec3 near = (minCorner - rayOrigin) * invDir;
	vec3 far  = (maxCorner - rayOrigin) * invDir;

	vec3 tmin = min(near, far);
	vec3 tmax = max(near, far);

	float t0 = max( max(tmin.x, tmin.y), tmin.z);
	float t1 = min( min(tmax.x, tmax.y), tmax.z);

	if (t0 > t1) return INFINITY;

	vec3 ip;
	float result = INFINITY;
	if (t0 > 0.0) // if we are outside the box
	{
		normal = -sign(rayDirection) * step(tmin.yzx, tmin) * step(tmin.zxy, tmin);
		isRayExiting = FALSE;
		ip = rayOrigin + rayDirection * t0;
		if (normal == vec3(1,0,0) && abs(ip.y) < 2.0 && abs(ip.z) < 2.0)
			t0 = INFINITY;
		if (normal == vec3(0,1,0) || normal == vec3(0,0,1))
			t0 = INFINITY;
		result = t0;
	}
	if ((t0 < 0.0 || t0 == INFINITY) && t1 > 0.0) // if we are inside the box
	{
		normal = -sign(rayDirection) * step(tmax, tmax.yzx) * step(tmax, tmax.zxy);
		isRayExiting = TRUE;
		ip = rayOrigin + rayDirection * t1;
		if (normal == vec3(-1,0,0) && abs(ip.y) < 2.0 && abs(ip.z) < 2.0)
			t1 = INFINITY;
		if (normal == vec3(0,-1,0) || normal == vec3(0,0,-1))
			t1 = INFINITY;
		result = t1;
	}
	return result;
}



//------------------------------------------------------------------------------------------------------------------------------------------------------------
float SceneIntersect( vec3 rOrigin, vec3 rDirection, out vec3 hitNormal, out vec3 hitEmission, out vec3 hitColor, out float hitObjectID, out int hitType )
//------------------------------------------------------------------------------------------------------------------------------------------------------------
{
	vec3 n;
	float d;
	float t = INFINITY;
	int objectCount = 0;
	int isRayExiting = FALSE;
	
	hitObjectID = -INFINITY;

// NOTE: all intersect functions must use rOrigin/rDirection as parameters instead of the usual 
//   global rayOrigin/rayDirection!  This is because rOrigin/rDirection might represent a particle shadow ray

	d = BoxMissingSidesIntersect( boxes[0].minCorner, boxes[0].maxCorner, rOrigin, rDirection, n, isRayExiting );
	if (d < t)
	{
		t = d;
		hitNormal = n;
		hitEmission = boxes[0].emission;
		hitColor = vec3(1);
		hitType = DIFF;

		if (isRayExiting == TRUE && n == vec3(1,0,0)) // left wall
		{
			hitColor = vec3(0.7, 0.05, 0.05);
		}
		else if (isRayExiting == TRUE && n == vec3(-1,0,0)) // right wall
		{
			hitColor = vec3(0.05, 0.05, 0.7);
		}
		else if (isRayExiting == FALSE && n == vec3(-1,0,0)) // left wall
		{
			hitColor = vec3(0.7, 0.05, 0.05);
		}
		else if (isRayExiting == FALSE && n == vec3(1,0,0)) // right wall
		{
			hitColor = vec3(0.05, 0.05, 0.7);
		}
		
		hitObjectID = float(objectCount);
	}
	objectCount++;


	d = SphereIntersect( spheres[0].radius, spheres[0].position, rOrigin, rDirection );
	if (d < t)
	{
		t = d;
		hitNormal = (rOrigin + rDirection * t) - spheres[0].position;
		hitEmission = spheres[0].emission;
		hitColor = spheres[0].color;
		hitType = spheres[0].type;
		hitObjectID = float(objectCount);
	}
	objectCount++;

	d = SphereIntersect( spheres[1].radius, spheres[1].position, rOrigin, rDirection );
	if (d < t)
	{
		t = d;
		hitNormal = (rOrigin + rDirection * t) - spheres[1].position;
		hitEmission = spheres[1].emission;
		hitColor = spheres[1].color;
		hitType = spheres[1].type;
		hitObjectID = float(objectCount);
	}
	objectCount++;


	d = QuadIntersect( quads[0].v0, quads[0].v1, quads[0].v2, quads[0].v3, rOrigin, rDirection, TRUE );
	if (d < t)
	{
		t = d;
		hitNormal = quads[0].normal;
		hitEmission = quads[0].emission;
		hitColor = quads[0].color;
		hitType = quads[0].type;
		hitObjectID = float(objectCount);
	}
	objectCount++;

	d = QuadIntersect( quads[1].v0, quads[1].v1, quads[1].v2, quads[1].v3, rOrigin, rDirection, TRUE );
	if (d < t)
	{
		t = d;
		hitNormal = quads[1].normal;
		hitEmission = quads[1].emission;
		hitColor = quads[1].color;
		hitType = quads[1].type;
		hitObjectID = float(objectCount);
	}
	objectCount++;
	
	
	return t;
} // end float SceneIntersect( vec3 rOrigin, vec3 rDirection, out vec3 hitNormal, out vec3 hitEmission, out vec3 hitColor, out float hitObjectID, out int hitType )


/* Credit: Some of the equi-angular sampling code is borrowed from https://www.shadertoy.com/view/Xdf3zB posted by user 'sjb' ,
// who in turn got it from the paper 'Importance Sampling Techniques for Path Tracing in Participating Media' ,
which can be viewed at: https://docs.google.com/viewer?url=https%3A%2F%2Fwww.solidangle.com%2Fresearch%2Fegsr2012_volume.pdf */
void sampleEquiAngular( float u, float maxDistance, vec3 rOrigin, vec3 rDirection, vec3 lightPos, out float dist, out float pdf )
{
	// get coord of closest point to light along (infinite) ray
	float delta = dot(lightPos - rOrigin, rDirection);
	
	// get distance this point is from light
	float D = distance(rOrigin + delta * rDirection, lightPos);

	// get angle of endpoints
	float thetaA = atan(0.0 - delta, D);
	float thetaB = atan(maxDistance - delta, D);

	// take sample
	float t = D * tan( mix(thetaA, thetaB, u) );
	dist = delta + t;
	pdf = D / ( (thetaB - thetaA) * (D * D + t * t) );
}


#define FOG_COLOR vec3(0.05, 0.05, 0.4) // color of the fog / participating medium
#define FOG_DENSITY 0.005 // this is dependent on the particular scene size dimensions


//-----------------------------------------------------------------------------------------------------------------------------
vec3 CalculateRadiance( out vec3 objectNormal, out vec3 objectColor, out float objectID, out float pixelSharpness )
//-----------------------------------------------------------------------------------------------------------------------------
{
	Quad chosenLight;

	vec3 cameraRayOrigin = rayOrigin;
	vec3 cameraRayDirection = rayDirection;
	vec3 vRayOrigin, vRayDirection;

	// recorded intersection data (from eye):
	vec3 eHitNormal, eHitEmission, eHitColor;
	float eHitObjectID;
	int eHitType = -100; // note: make sure to initialize this to a nonsense type id number!
	// recorded intersection data (from volumetric particle):
	vec3 vHitNormal, vHitEmission, vHitColor;
	float vHitObjectID;
	int vHitType = -100; // note: make sure to initialize this to a nonsense type id number!

	vec3 accumCol = vec3(0.0);
	vec3 mask = vec3(1.0);
	vec3 dirToLight;
	vec3 lightVec;
	vec3 particlePos;
	vec3 tdir;
	vec3 x, n, nl;
	
	float nc, nt, ratioIoR, Re, Tr;
	float P, RP, TP;
	float weight;
	float t, vt, camt;
	float xx;
	float pdf;
	float d;
	float geomTerm;
	float trans;

	int diffuseCount = 0;
	int previousIntersecType = -100;
	
	int bounceIsSpecular = TRUE;
	int sampleLight = FALSE;

	
	// depth of 4 is required for higher quality glass refraction
	for (int bounces = 0; bounces < 4; bounces++)
	{
		chosenLight = quads[0];
		randPointOnLight.x = chosenLight.v0.x;
		randPointOnLight.y = mix(chosenLight.v0.y, chosenLight.v2.y, clamp(rng(), 0.1, 0.9));
		randPointOnLight.z = mix(chosenLight.v0.z, chosenLight.v2.z, clamp(rng(), 0.1, 0.9));

		float u = rng();
		
		t = SceneIntersect(rayOrigin, rayDirection, eHitNormal, eHitEmission, eHitColor, eHitObjectID, eHitType);
		
		// on first loop iteration, save intersection distance along camera ray (t) into camt variable for use below
		if (bounces == 0)
		{
			camt = t;
		}
			
		// sample along intial ray from camera into the scene
		sampleEquiAngular(u, camt, cameraRayOrigin, cameraRayDirection, randPointOnLight, xx, pdf);

		// create a particle along cameraRay and cast a shadow ray towards light (similar to Direct Lighting)
		particlePos = cameraRayOrigin + xx * cameraRayDirection;
		lightVec = randPointOnLight - particlePos;
		d = length(lightVec);

		vRayOrigin = particlePos;
		vRayDirection = normalize(lightVec);

		vt = SceneIntersect(vRayOrigin, vRayDirection, vHitNormal, vHitEmission, vHitColor, vHitObjectID, vHitType);
		
		// if the particle can see the light source, apply volumetric lighting calculation
		if (vHitType == LIGHT)
		{	
			trans = exp( -((d + xx) * FOG_DENSITY) );
			geomTerm = 1.0 / (d * d);
			
			accumCol += FOG_COLOR * vHitEmission * geomTerm * trans / pdf;
		}
		// otherwise the particle will remain in shadow - this is what produces the shafts of light vs. the volume shadows


		// useful data 
		n = normalize(eHitNormal);
		nl = dot(n, rayDirection) < 0.0 ? n : -n;
		x = rayOrigin + rayDirection * t;

		if (bounces == 0)
		{
			//objectNormal = n;
			objectColor = eHitColor;
			objectID = eHitObjectID;
		}
		if (diffuseCount == 0) // handles reflections of light sources
		{
			objectNormal += n; 
		}

		// now do the normal path tracing routine with the camera ray
		if (eHitType == LIGHT)
		{
			if (bounceIsSpecular == TRUE || sampleLight == TRUE)
			{
				trans = exp( -((d + camt) * FOG_DENSITY) );
				accumCol += mask * eHitEmission * trans;	
			}

			// normally we would 'break' here, but 'continue' allows more particles to be lit
			continue;
			//break;
		}
		
		if (sampleLight == TRUE)
			break;
		
		
		if (eHitType == DIFF) // Ideal DIFFUSE reflection
		{
			diffuseCount++;

			mask *= eHitColor;

			bounceIsSpecular = FALSE;

			if (diffuseCount == 1 && rand() < 0.5)
			{
				mask *= 2.0;
				// choose random Diffuse sample vector
				rayDirection = randomCosWeightedDirectionInHemisphere(nl);
				rayOrigin = x + nl * uEPS_intersect;
				continue;
			}
			
			if (rng() < 0.5)
			{
				chosenLight = quads[1];
				randPointOnLight.x = mix(chosenLight.v0.x, chosenLight.v2.x, clamp(rng(), 0.1, 0.9));
				randPointOnLight.y = chosenLight.v0.y;
				randPointOnLight.z = mix(chosenLight.v0.z, chosenLight.v2.z, clamp(rng(), 0.1, 0.9));
			}
			dirToLight = sampleQuadLight(x, nl, chosenLight, weight);
			mask *= diffuseCount == 1 ? 2.0 : 1.0;
			mask *= weight;
			mask *= 2.0;

			rayDirection = dirToLight;
			rayOrigin = x + nl * uEPS_intersect;
			
			sampleLight = TRUE;
			continue;	
		}
		
		if (eHitType == SPEC)  // Ideal SPECULAR reflection
		{
			mask *= eHitColor;

			rayDirection = reflect(rayDirection, nl);
			rayOrigin = x + nl * uEPS_intersect;
			
			//bounceIsSpecular = TRUE; // turn on mirror caustics
			
			continue;
		}

		if (eHitType == REFR)  // Ideal dielectric REFRACTION
		{
			previousIntersecType = REFR;

			nc = 1.0; // IOR of Air
			nt = 1.5; // IOR of common Glass
			Re = calcFresnelReflectance(rayDirection, n, nc, nt, ratioIoR);
			Tr = 1.0 - Re;
			P  = 0.25 + (0.5 * Re);
			RP = Re / P;
			TP = Tr / (1.0 - P);

			if (bounces == 0 && rand() < P)
			{
				mask *= RP;
				rayDirection = reflect(rayDirection, nl); // reflect ray from surface
				rayOrigin = x + nl * uEPS_intersect;
				    
				//bounceIsSpecular = TRUE; // turn on reflecting caustics
			    	continue;	
			}
			// transmit ray through surface
			
			mask *= TP;
			mask *= eHitColor;

			tdir = refract(rayDirection, nl, ratioIoR);
			rayDirection = tdir;
			rayOrigin = x - nl * uEPS_intersect;

			//bounceIsSpecular = TRUE; // turn on refracting caustics
			continue;
			
		} // end if (eHitType == REFR)
		
		if (eHitType == COAT)  // Diffuse object underneath with ClearCoat on top
		{
			nc = 1.0; // IOR of air
			nt = 1.4; // IOR of ClearCoat 
			Re = calcFresnelReflectance(rayDirection, nl, nc, nt, ratioIoR);
			Tr = 1.0 - Re;
			P  = 0.25 + (0.5 * Re);
			RP = Re / P;
			TP = Tr / (1.0 - P);
			
			// choose either specular reflection or diffuse
			if (diffuseCount == 0 && rand() < P)
			{	
				mask *= RP;
				rayDirection = reflect(rayDirection, nl); // reflect ray from surface
				rayOrigin = x + nl * uEPS_intersect;
				continue;	
			}

			diffuseCount++;

			bounceIsSpecular = FALSE;

			mask *= TP;
			mask *= eHitColor;

			if (diffuseCount == 1 && rand() < 0.5)
			{
				mask *= 2.0;
				// choose random Diffuse sample vector
				rayDirection = randomCosWeightedDirectionInHemisphere(nl);
				rayOrigin = x + nl * uEPS_intersect;
				continue;
			}
			
			if (rng() < 0.5)
			{
				chosenLight = quads[1];
				randPointOnLight.x = mix(chosenLight.v0.x, chosenLight.v2.x, clamp(rng(), 0.1, 0.9));
				randPointOnLight.y = chosenLight.v0.y;
				randPointOnLight.z = mix(chosenLight.v0.z, chosenLight.v2.z, clamp(rng(), 0.1, 0.9));
			}
			dirToLight = sampleQuadLight(x, nl, chosenLight, weight);
			mask *= diffuseCount == 1 ? 2.0 : 1.0;
			mask *= weight;
			mask *= 2.0;

			rayDirection = dirToLight;
			rayOrigin = x + nl * uEPS_intersect;
			
			sampleLight = TRUE;
			continue;
			
		} //end if (eHitType == COAT)
		
	} // end for (int bounces = 0; bounces < 4; bounces++)


	return max(vec3(0), accumCol);

} // end vec3 CalculateRadiance( out vec3 objectNormal, out vec3 objectColor, out float objectID, out float pixelSharpness )

//-----------------------------------------------------------------------
void SetupScene(void)
//-----------------------------------------------------------------------
{
	vec3 z  = vec3(0);// No color value, Black        
	vec3 L1 = vec3(1.0, 1.0, 1.0) * 40.0;
	
	spheres[0] = Sphere( 10.0, vec3( 0,-40,-40), z, vec3(1.0, 1.0, 1.0), DIFF);// Diffuse Sphere Left
	spheres[1] = Sphere( 10.0, vec3(30,-40,-40), z, vec3(1.0, 1.0, 0.0), COAT);// ClearCoat Sphere Right
	
	quads[0] = Quad( vec3(-1, 0, 0), vec3(80,-2,-2), vec3(80,-2, 2), vec3(80, 2, 2), vec3(80, 2,-2), L1, z, LIGHT);// Rectangular Area Light
	quads[1] = Quad( vec3( 0,-1, 0), vec3(-5, 20,-40), vec3(5, 20,-40), vec3(5, 20,-35), vec3(-5, 20,-35), vec3(0.5), z, LIGHT);// Ceiling Rectangular Area Light

	boxes[0] = Box( vec3(-50), vec3(50), z, vec3(1.0, 1.0, 1.0), DIFF);// the Cornell Box interior
}


#include <pathtracing_main>
