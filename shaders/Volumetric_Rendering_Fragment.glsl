precision highp float;
precision highp int;
precision highp sampler2D;

#include <pathtracing_uniforms_and_defines>

#define N_SPHERES 3
#define N_BOXES 1

//-----------------------------------------------------------------------

vec3 rayOrigin, rayDirection;

struct Sphere { float radius; vec3 position; vec3 emission; vec3 color; int type; };
struct Box { vec3 minCorner; vec3 maxCorner; vec3 emission; vec3 color; int type; };

Sphere spheres[N_SPHERES];
Box boxes[N_BOXES];


#include <pathtracing_random_functions>

#include <pathtracing_calc_fresnel_reflectance>

#include <pathtracing_sphere_intersect>

#include <pathtracing_box_interior_intersect>

#include <pathtracing_sample_sphere_light>


//------------------------------------------------------------------------------------------------------------------------------------------------------------
float SceneIntersect( vec3 rOrigin, vec3 rDirection, out vec3 hitNormal, out vec3 hitEmission, out vec3 hitColor, out float hitObjectID, out int hitType )
//------------------------------------------------------------------------------------------------------------------------------------------------------------
{
	vec3 n;
	float d;
	float t = INFINITY;
	int objectCount = 0;
	
	hitObjectID = -INFINITY;


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

	d = SphereIntersect( spheres[2].radius, spheres[2].position, rOrigin, rDirection );
	if (d < t)
	{
		t = d;
		hitNormal = (rOrigin + rDirection * t) - spheres[2].position;
		hitEmission = spheres[2].emission;
		hitColor = spheres[2].color;
		hitType = spheres[2].type;
		hitObjectID = float(objectCount);
	}
	
	d = BoxInteriorIntersect( boxes[0].minCorner, boxes[0].maxCorner, rayOrigin, rayDirection, n );
	if (d < t && n != vec3(0,0,-1) && n != vec3(0,1,0) && n != vec3(0,-1,0))
	{
		t = d;
		hitNormal = n;
		hitEmission = boxes[0].emission;
		hitColor = vec3(1);
		hitType = DIFF;
	
		if (n == vec3(1,0,0)) // left wall
		{
			hitColor = vec3(0.7, 0.05, 0.05);
		}
		else if (n == vec3(-1,0,0)) // right wall
		{
			hitColor = vec3(0.05, 0.05, 0.7);
		}
		
		hitObjectID = float(objectCount);
	}
	
	
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
#define FOG_DENSITY 0.0005 // this is dependent on the particular scene size dimensions
#define LIGHT_COLOR vec3(1.0, 1.0, 1.0) // color of light source
#define LIGHT_POWER 15.0 // brightness of light source


//-----------------------------------------------------------------------------------------------------------------------------
vec3 CalculateRadiance( out vec3 objectNormal, out vec3 objectColor, out float objectID, out float pixelSharpness )
//-----------------------------------------------------------------------------------------------------------------------------
{
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
		
		float u = rng();
		
		t = SceneIntersect(rayOrigin, rayDirection, eHitNormal, eHitEmission, eHitColor, eHitObjectID, eHitType);
		
		// on first loop iteration, save intersection distance along camera ray (t) into camt variable for use below
		if (bounces == 0)
		{
			camt = t;
			//objectNormal = eHitNormal; // handled below
			objectColor = eHitColor;
			objectID = eHitObjectID;
		}
			

		// sample along intial ray from camera into the scene
		sampleEquiAngular(u, camt, cameraRayOrigin, cameraRayDirection, spheres[0].position, xx, pdf);

		// create a particle along cameraRay and cast a shadow ray towards light (similar to Direct Lighting)
		particlePos = cameraRayOrigin + xx * cameraRayDirection;
		lightVec = spheres[0].position - particlePos;
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

		if (diffuseCount == 0)
		{
			objectNormal += n;
			//objectColor = eHitColor; // handled above
			//objectID = eHitObjectID; // handled above
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
		}
		
		
		
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
			
			dirToLight = sampleSphereLight(x, nl, spheres[0], weight);
			mask *= diffuseCount == 1 ? 2.0 : 1.0;
			mask *= weight;

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
                        
			dirToLight = sampleSphereLight(x, nl, spheres[0], weight);
			mask *= diffuseCount == 1 ? 2.0 : 1.0;
			mask *= weight;

			rayDirection = dirToLight;
			rayOrigin = x + nl * uEPS_intersect;
			
			sampleLight = TRUE;
			continue;
			
		} //end if (eHitType == COAT)
		
        } // end for (int bounces = 0; bounces < 4; bounces++)

	
	// Now we go hunting for volumetric caustics! A previously created particle (vray) is chosen
	// as a starting point, the ray origin. Next, Randomize the ray direction based on glass sphere's radius.
	// Then trace towards the light source, eventually rays will refract at just the right angles to find the light!
	rayOrigin = particlePos;
	vec3 lp = spheres[0].position + (randomSphereDirection() * spheres[1].radius * 0.9);
	rayDirection = normalize(lp - rayOrigin);
	mask = vec3(1.0); // reset color mask for this particle
	previousIntersecType = -100;

	// depth of 3 needed to possibly travel into glass sphere, out of it, and then find light = 3 iterations
	for (int bounces = 0; bounces < 3; bounces++)
	{
		
		t = SceneIntersect(rayOrigin, rayDirection, eHitNormal, eHitEmission, eHitColor, eHitObjectID, eHitType);

		// early out test, we are only looking for glass objects and light sources
		if (eHitType != REFR && eHitType != LIGHT)
			break;
		
		// useful data 
		n = normalize(eHitNormal);
                nl = dot(n, rayDirection) < 0.0 ? n : -n;
		x = rayOrigin + rayDirection * t;

		if (eHitType == REFR)  // Ideal dielectric REFRACTION
		{
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
				// the following 'incorrect' assignment turns off noisy caustics that we are not interested in
				previousIntersecType = SPEC; 
			    	continue;	
			}
			// transmit ray through surface
			
			mask *= TP;
			mask *= eHitColor;

			tdir = refract(rayDirection, nl, ratioIoR);
			rayDirection = tdir;
			rayOrigin = x - nl * uEPS_intersect;
			
			previousIntersecType = REFR; // will be used to create volumetric refracted caustics 
			continue;
			
		} // end if (eHitType == REFR)

		if (eHitType == LIGHT)
		{	
			// if we have just traveled through a refractive surface(REFR) like glass, then 
			// allow particle to be lit, producing volumetric caustics
			if (previousIntersecType == REFR && bounces == 2)
			{
				trans = exp( -((d + xx) * FOG_DENSITY) );
				accumCol *= mask * FOG_COLOR * eHitEmission * 50.0 * trans;
			}
			
			break;
		}

        } // end for (int bounces = 0; bounces < 3; bounces++)


	return max(vec3(0), accumCol);

} // end vec3 CalculateRadiance( out vec3 objectNormal, out vec3 objectColor, out float objectID, out float pixelSharpness )

//-----------------------------------------------------------------------
void SetupScene(void)
//-----------------------------------------------------------------------
{
	vec3 z  = vec3(0.0);// No color value, Black        
	vec3 L1 = LIGHT_COLOR * LIGHT_POWER;
		    
	spheres[0] = Sphere( 10.0, vec3(275.0, 430.0, -280.0), L1, z, LIGHT);// Light Sphere
	
	spheres[1] = Sphere(  90.0, vec3(170.0, 201.0, -200.0),  z, vec3(1.0, 1.0, 1.0),  REFR);// Glass Sphere Left
	spheres[2] = Sphere(  90.0, vec3(390.0, 250.0, -250.0),  z, vec3(1.0, 1.0, 1.0),  COAT);// ClearCoat Sphere Right

	boxes[0] = Box( vec3(0, 0,-559.2), vec3(549.6, 548.8, 0), z, vec3(1), DIFF);// the Cornell Box interior 
}


#include <pathtracing_main>
