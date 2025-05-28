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

vec3 rayOrigin, rayDirection;
// recorded intersection data:
vec3 hitNormal, hitEmission, hitColor;
vec2 hitUV;
float hitObjectID = -INFINITY;
int hitType = -100;


struct Sphere { float radius; vec3 position; vec3 emission; vec3 color; int type; };
struct Ellipsoid { vec3 radii; vec3 position; vec3 emission; vec3 color; int type; };
struct Rectangle { vec3 position; vec3 normal; float radiusU; float radiusV; vec3 emission; vec3 color; int type; };
struct Box { vec3 minCorner; vec3 maxCorner; vec3 emission; vec3 color; int type; };

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



//-------------------------------------------------------------------------------------------------------------------
float SceneIntersect( )
//-------------------------------------------------------------------------------------------------------------------
{
	vec3 n;
	float d;
	float t = INFINITY;
	int isRayExiting = FALSE;
	int objectCount = 0;
	
	hitObjectID = -INFINITY;
	
	
	d = RectangleIntersect( rectangles[0].position, rectangles[0].normal, rectangles[0].radiusU, rectangles[0].radiusV, rayOrigin, rayDirection );
	if (d < t)
	{
		t = d;
		hitNormal = rectangles[0].normal;
		hitEmission = rectangles[0].emission;
		hitColor = rectangles[0].color;
		hitType = rectangles[0].type;
		hitObjectID = float(objectCount);
	}
	objectCount++;

	d = RectangleIntersect( rectangles[1].position, rectangles[1].normal, rectangles[1].radiusU, rectangles[1].radiusV, rayOrigin, rayDirection );
	if (d < t)
	{
		t = d;
		hitNormal = rectangles[1].normal;
		hitEmission = rectangles[1].emission;
		hitColor = rectangles[1].color;
		hitType = rectangles[1].type;
		hitObjectID = float(objectCount);
	}
	objectCount++;

	d = RectangleIntersect( rectangles[2].position, rectangles[2].normal, rectangles[2].radiusU, rectangles[2].radiusV, rayOrigin, rayDirection );
	if (d < t)
	{
		t = d;
		hitNormal = rectangles[2].normal;
		hitEmission = rectangles[2].emission;
		hitColor = rectangles[2].color;
		hitType = rectangles[2].type;
		hitObjectID = float(objectCount);
	}
	objectCount++;
	

	d = BoxIntersect( boxes[0].minCorner, boxes[0].maxCorner, rayOrigin, rayDirection, n, isRayExiting );
	if (d < t)
	{
		t = d;
		hitNormal = n;
		hitEmission = boxes[0].emission;
		hitColor = boxes[0].color;
		hitType = boxes[0].type;
		hitObjectID = float(objectCount);
	}
	objectCount++;

	d = BoxIntersect( boxes[1].minCorner, boxes[1].maxCorner, rayOrigin, rayDirection, n, isRayExiting );
	if (d < t)
	{
		t = d;
		hitNormal = n;
		hitEmission = boxes[1].emission;
		hitColor = boxes[1].color;
		hitType = boxes[1].type;
		hitObjectID = float(objectCount);
	}
	objectCount++;

	d = BoxIntersect( boxes[2].minCorner, boxes[2].maxCorner, rayOrigin, rayDirection, n, isRayExiting );
	if (d < t)
	{
		t = d;
		hitNormal = n;
		hitEmission = boxes[2].emission;
		hitColor = boxes[2].color;
		hitType = boxes[2].type;
		hitObjectID = float(objectCount);
	}
	objectCount++;

	d = BoxIntersect( boxes[3].minCorner, boxes[3].maxCorner, rayOrigin, rayDirection, n, isRayExiting );
	if (d < t)
	{
		t = d;
		hitNormal = n;
		hitEmission = boxes[3].emission;
		hitColor = boxes[3].color;
		hitType = boxes[3].type;
		hitObjectID = float(objectCount);
	}
	objectCount++;

	d = BoxIntersect( boxes[4].minCorner, boxes[4].maxCorner, rayOrigin, rayDirection, n, isRayExiting );
	if (d < t)
	{
		t = d;
		hitNormal = n;
		hitEmission = boxes[4].emission;
		hitColor = boxes[4].color;
		hitType = boxes[4].type;
		hitObjectID = float(objectCount);
	}
	objectCount++;

	d = BoxIntersect( boxes[5].minCorner, boxes[5].maxCorner, rayOrigin, rayDirection, n, isRayExiting );
	if (d < t)
	{
		t = d;
		hitNormal = n;
		hitEmission = boxes[5].emission;
		hitColor = boxes[5].color;
		hitType = boxes[5].type;
		hitObjectID = float(objectCount);
	}
	objectCount++;
	

	d = EllipsoidIntersect( ellipsoids[0].radii, ellipsoids[0].position, rayOrigin, rayDirection );
	if (d < t)
	{
		t = d;
		hitNormal = ((rayOrigin + rayDirection * t) - ellipsoids[0].position) / (ellipsoids[0].radii * ellipsoids[0].radii);
		hitEmission = ellipsoids[0].emission;
		hitColor = ellipsoids[0].color;
		hitType = ellipsoids[0].type;
		hitObjectID = float(objectCount);
	}
	objectCount++;

	d = EllipsoidIntersect( ellipsoids[1].radii, ellipsoids[1].position, rayOrigin, rayDirection );
	if (d < t)
	{
		t = d;
		hitNormal = ((rayOrigin + rayDirection * t) - ellipsoids[1].position) / (ellipsoids[1].radii * ellipsoids[1].radii);
		hitEmission = ellipsoids[1].emission;
		hitColor = ellipsoids[1].color;
		hitType = ellipsoids[1].type;
		hitObjectID = float(objectCount);
	}
	objectCount++;


	d = SphereIntersect( spheres[0].radius, spheres[0].position, rayOrigin, rayDirection );
	if (d < t)
	{
		t = d;
		hitNormal = (rayOrigin + rayDirection * t) - spheres[0].position;
		hitEmission = spheres[0].emission;
		hitColor = spheres[0].color;
		hitType = spheres[0].type;
		hitObjectID = float(objectCount);
	}
	objectCount++;

	d = SphereIntersect( spheres[1].radius, spheres[1].position, rayOrigin, rayDirection );
	if (d < t)
	{
		t = d;
		hitNormal = (rayOrigin + rayDirection * t) - spheres[1].position;
		hitEmission = spheres[1].emission;
		hitColor = spheres[1].color;
		hitType = spheres[1].type;
		hitObjectID = float(objectCount);
	}
	objectCount++;

	d = SphereIntersect( spheres[2].radius, spheres[2].position, rayOrigin, rayDirection );
	if (d < t)
	{
		t = d;
		hitNormal = (rayOrigin + rayDirection * t) - spheres[2].position;
		hitEmission = spheres[2].emission;
		hitColor = spheres[2].color;
		hitType = spheres[2].type;
		hitObjectID = float(objectCount);
	}
	objectCount++;

	d = SphereIntersect( spheres[3].radius, spheres[3].position, rayOrigin, rayDirection );
	if (d < t)
	{
		t = d;
		hitNormal = (rayOrigin + rayDirection * t) - spheres[3].position;
		hitEmission = spheres[3].emission;
		hitColor = spheres[3].color;
		hitType = spheres[3].type;
		hitObjectID = float(objectCount);
	}
	objectCount++;

	d = SphereIntersect( spheres[4].radius, spheres[4].position, rayOrigin, rayDirection );
	if (d < t)
	{
		t = d;
		hitNormal = (rayOrigin + rayDirection * t) - spheres[4].position;
		hitEmission = spheres[4].emission;
		hitColor = spheres[4].color;
		hitType = spheres[4].type;
		hitObjectID = float(objectCount);
	}
	objectCount++;

	d = SphereIntersect( spheres[5].radius, spheres[5].position, rayOrigin, rayDirection );
	if (d < t)
	{
		t = d;
		hitNormal = (rayOrigin + rayDirection * t) - spheres[5].position;
		hitEmission = spheres[5].emission;
		hitColor = spheres[5].color;
		hitType = spheres[5].type;
		hitObjectID = float(objectCount);
	}
	objectCount++;

	d = SphereIntersect( spheres[6].radius, spheres[6].position, rayOrigin, rayDirection );
	if (d < t)
	{
		t = d;
		hitNormal = (rayOrigin + rayDirection * t) - spheres[6].position;
		hitEmission = spheres[6].emission;
		hitColor = spheres[6].color;
		hitType = spheres[6].type;
		hitObjectID = float(objectCount);
	}
	objectCount++;

	d = SphereIntersect( spheres[7].radius, spheres[7].position, rayOrigin, rayDirection );
	if (d < t)
	{
		t = d;
		hitNormal = (rayOrigin + rayDirection * t) - spheres[7].position;
		hitEmission = spheres[7].emission;
		hitColor = spheres[7].color;
		hitType = spheres[7].type;
		hitObjectID = float(objectCount);
	}
	objectCount++;

	d = SphereIntersect( spheres[8].radius, spheres[8].position, rayOrigin, rayDirection );
	if (d < t)
	{
		t = d;
		hitNormal = (rayOrigin + rayDirection * t) - spheres[8].position;
		hitEmission = spheres[8].emission;
		hitColor = spheres[8].color;
		hitType = spheres[8].type;
		hitObjectID = float(objectCount);
	}
	objectCount++;

	d = SphereIntersect( spheres[9].radius, spheres[9].position, rayOrigin, rayDirection );
	if (d < t)
	{
		t = d;
		hitNormal = (rayOrigin + rayDirection * t) - spheres[9].position;
		hitEmission = spheres[9].emission;
		hitColor = spheres[9].color;
		hitType = spheres[9].type;
		hitObjectID = float(objectCount);
	}
	objectCount++;

	d = SphereIntersect( spheres[10].radius, spheres[10].position, rayOrigin, rayDirection );
	if (d < t)
	{
		t = d;
		hitNormal = (rayOrigin + rayDirection * t) - spheres[10].position;
		hitEmission = spheres[10].emission;
		hitColor = spheres[10].color;
		hitType = spheres[10].type;
		hitObjectID = float(objectCount);
	}
	objectCount++;

	d = SphereIntersect( spheres[11].radius, spheres[11].position, rayOrigin, rayDirection );
	if (d < t)
	{
		t = d;
		hitNormal = (rayOrigin + rayDirection * t) - spheres[11].position;
		hitEmission = spheres[11].emission;
		hitColor = spheres[11].color;
		hitType = spheres[11].type;
		hitObjectID = float(objectCount);
	}
	objectCount++;

	
	return t;
	
} // end float SceneIntersect( )


vec3 sampleRectangleLight(vec3 x, vec3 nl, Rectangle light, out float weight)
{
	vec3 U = normalize(cross( abs(light.normal.y) < 0.9 ? vec3(0, 1, 0) : vec3(0, 0, 1), light.normal));
	vec3 V = cross(light.normal, U);
	vec3 randPointOnLight = light.position;
	randPointOnLight += U * light.radiusU * (rng() * 2.0 - 1.0) * 0.9;
	randPointOnLight += V * light.radiusV * (rng() * 2.0 - 1.0) * 0.9;
	
	vec3 dirToLight = randPointOnLight - x;
	float r2 = (light.radiusU * 2.0) * (light.radiusV * 2.0);
	float d2 = dot(dirToLight, dirToLight);
	float cos_a_max = sqrt(1.0 - clamp( r2 / d2, 0.0, 1.0));

	dirToLight = normalize(dirToLight);
	float dotNlRayDir = max(0.0, dot(nl, dirToLight)); 
	weight = 2.0 * (1.0 - cos_a_max) * max(0.0, -dot(dirToLight, light.normal)) * dotNlRayDir;
	weight = clamp(weight, 0.0, 1.0);

	return dirToLight;
}


//----------------------------------------------------------------------------------------------------------------------------------------------------
vec3 CalculateRadiance( out vec3 objectNormal, out vec3 objectColor, out float objectID, out float pixelSharpness )
//----------------------------------------------------------------------------------------------------------------------------------------------------
{
	
	vec3 accumCol = vec3(0);
        vec3 mask = vec3(1);
	vec3 reflectionMask = vec3(1);
	vec3 reflectionRayOrigin = vec3(0);
	vec3 reflectionRayDirection = vec3(0);
	vec3 diffuseBounceMask = vec3(1);
	vec3 diffuseBounceRayOrigin = vec3(0);
	vec3 diffuseBounceRayDirection = vec3(0);
	vec3 skyColor;
	vec3 x, n, nl;
        
	float t;
	float weight;
	float nc, nt, ratioIoR, Re, Tr;
	float thickness = 0.1;
	float previousObjectID;
	float newRandom = rand();

	int reflectionBounces = -1;
	int diffuseBounces = -1;
	int diffuseCount = 0;
	int previousIntersecType = -100;
	hitType = -100;

	int bounceIsSpecular = TRUE;
	int sampleLight = FALSE;
	int willNeedReflectionRay = FALSE;
	int isReflectionTime = FALSE;
	int reflectionNeedsToBeSharp = FALSE;
	int willNeedDiffuseBounceRay = FALSE;
	int isDiffuseBounceTime = FALSE;



	// a higher number of bounces is needed in order to get through the tower of glass spheres
        for (int bounces = 0; bounces < 12; bounces++)
	{
		if (isDiffuseBounceTime == TRUE)
			diffuseBounces++;
		// if (isReflectionTime == TRUE)
		// 	reflectionBounces++;

		previousIntersecType = hitType;
		previousObjectID = hitObjectID;

		t = SceneIntersect();

		
		if (t == INFINITY)
		{		
			skyColor = mix(vec3(0), vec3(0.004, 0.0, 0.04), clamp(exp(rayDirection.y * -15.0), 0.0, 1.0));
			
			// keeps edges of objects against background sky sharp
			if (bounces == 0)
				pixelSharpness = 1.0;

			if (bounceIsSpecular == TRUE || sampleLight == TRUE)
				accumCol += mask * skyColor;
			
			if (willNeedDiffuseBounceRay == TRUE)
			{
				mask = diffuseBounceMask;
				rayOrigin = diffuseBounceRayOrigin;
				rayDirection = diffuseBounceRayDirection;

				willNeedDiffuseBounceRay = FALSE;
				bounceIsSpecular = FALSE;
				sampleLight = FALSE;
				isDiffuseBounceTime = TRUE;
				isReflectionTime = FALSE;
				diffuseCount = 1;
				continue;
			}
			
			if (willNeedReflectionRay == TRUE)
			{
				mask = reflectionMask;
				rayOrigin = reflectionRayOrigin;
				rayDirection = reflectionRayDirection;

				willNeedReflectionRay = FALSE;
				bounceIsSpecular = TRUE;
				sampleLight = FALSE;
				isReflectionTime = TRUE;
				isDiffuseBounceTime = FALSE;
				//diffuseCount = 0; // allows more accurate diffuse objects when seen in glass reflections 
				continue;
			}
			// reached a sky light, so we can exit
                        break;
		}

		// useful data 
		n = normalize(hitNormal);
                nl = dot(n, rayDirection) < 0.0 ? n : -n;
		x = rayOrigin + rayDirection * t;

		if (bounces == 0)
		{
			objectID = hitObjectID;
		}
		if (isReflectionTime == FALSE && diffuseCount == 0 && hitObjectID != previousObjectID)
		{
			objectNormal += n;
			objectColor += hitColor;
		}
		/* if (reflectionNeedsToBeSharp == TRUE && reflectionBounces == 0)
		{
			objectNormal += n;
			objectColor += hitColor;
		} */

		
		if (hitType == LIGHT)
		{	
			if (diffuseCount == 0 && isReflectionTime == FALSE)
				pixelSharpness = 1.0;

			if (isReflectionTime == TRUE && bounceIsSpecular == TRUE)
			{
				objectNormal += nl;
				//objectColor = hitColor;
				objectID += hitObjectID;
			}
			
			if (bounceIsSpecular == TRUE || sampleLight == TRUE)
				accumCol = mask * hitEmission; // looking at light through a reflection
			
			if (willNeedDiffuseBounceRay == TRUE)
			{
				mask = diffuseBounceMask;
				rayOrigin = diffuseBounceRayOrigin;
				rayDirection = diffuseBounceRayDirection;

				willNeedDiffuseBounceRay = FALSE;
				bounceIsSpecular = FALSE;
				sampleLight = FALSE;
				isDiffuseBounceTime = TRUE;
				isReflectionTime = FALSE;
				diffuseCount = 1;
				continue;
			}

			if (willNeedReflectionRay == TRUE)
			{
				mask = reflectionMask;
				rayOrigin = reflectionRayOrigin;
				rayDirection = reflectionRayDirection;

				willNeedReflectionRay = FALSE;
				bounceIsSpecular = TRUE;
				sampleLight = FALSE;
				isReflectionTime = TRUE;
				isDiffuseBounceTime = FALSE;
				//diffuseCount = 0; // allows more accurate diffuse objects when seen in glass reflections
				continue;
			}
			// reached a light, so we can exit
			break;
		}

		// if we get here and sampleLight is still TRUE, shadow ray failed to find the light source 
		// the ray hit an occluding object along its way to the light
		if (sampleLight == TRUE)
		{
			if (willNeedDiffuseBounceRay == TRUE)
			{
				mask = diffuseBounceMask;
				rayOrigin = diffuseBounceRayOrigin;
				rayDirection = diffuseBounceRayDirection;

				willNeedDiffuseBounceRay = FALSE;
				bounceIsSpecular = FALSE;
				sampleLight = FALSE;
				isDiffuseBounceTime = TRUE;
				isReflectionTime = FALSE;
				diffuseCount = 1;
				continue;
			}

			if (willNeedReflectionRay == TRUE)
			{
				mask = reflectionMask;
				rayOrigin = reflectionRayOrigin;
				rayDirection = reflectionRayDirection;

				willNeedReflectionRay = FALSE;
				bounceIsSpecular = TRUE;
				sampleLight = FALSE;
				isReflectionTime = TRUE;
				isDiffuseBounceTime = FALSE;
				//diffuseCount = 0; // allows more accurate diffuse objects when seen in glass reflections
				continue;
			}

			break;
		}
		
		
		    
                if (hitType == DIFF ) // Ideal DIFFUSE reflection
		{
			
			diffuseCount++;

			mask *= hitColor;

			bounceIsSpecular = FALSE;

			rayOrigin = x + nl * uEPS_intersect;

			if (diffuseCount == 1)
			{
				diffuseBounceMask = mask;
				diffuseBounceRayOrigin = rayOrigin;
				diffuseBounceRayDirection = randomCosWeightedDirectionInHemisphere(nl);
				willNeedDiffuseBounceRay = TRUE;
			}
                        
			if (newRandom < 0.3333)
				rayDirection = sampleRectangleLight(x, nl, rectangles[0], weight);
			else if (newRandom < 0.6666)
				rayDirection = sampleRectangleLight(x, nl, rectangles[1], weight);
			else
				rayDirection = sampleRectangleLight(x, nl, rectangles[2], weight);
				
			mask *= weight * N_LIGHTS;
			sampleLight = TRUE;
			continue;
		}
		
		if (hitType == REFR)  // Ideal dielectric REFRACTION
		{
			nc = 1.0; // IOR of Air
			nt = 1.5; // IOR of common Glass
			Re = calcFresnelReflectance(rayDirection, n, nc, nt, ratioIoR);
			Tr = 1.0 - Re;

			if (Re == 1.0)
			{
				rayDirection = reflect(rayDirection, nl);
				rayOrigin = x + nl * uEPS_intersect;
				continue;
			}
			
			if (bounces == 0 && n == nl)
			{
				reflectionMask = mask * Re;
				reflectionRayDirection = reflect(rayDirection, nl); // reflect ray from surface
				reflectionRayOrigin = x + nl * uEPS_intersect;
				willNeedReflectionRay = TRUE;
				//reflectionNeedsToBeSharp = TRUE;
			}

			// transmit ray through surface
			
			// is ray leaving a solid object from the inside? 
			// If so, attenuate ray color with object color by how far ray has travelled through the medium
			if (distance(n, nl) > 0.1)
			{
				mask *= exp(log(hitColor) * thickness * t);
			}
			
			mask *= Tr;
			
			rayDirection = refract(rayDirection, nl, ratioIoR);
			rayOrigin = x - nl * uEPS_intersect;

			// turn on refracting caustics
			if (diffuseBounces == 0 && t < 10.0)
				bounceIsSpecular = TRUE;
			
			continue;
			
		} // end if (hitType == REFR)
		
	} // end for (int bounces = 0; bounces < 12; bounces++)
	
	
	return max(vec3(0), accumCol);
	     
} // end vec3 CalculateRadiance( out vec3 objectNormal, out vec3 objectColor, out float objectID, out float pixelSharpness )


//-----------------------------------------------------------------------
void SetupScene(void)
//-----------------------------------------------------------------------
{
	vec3 z  = vec3(0.0);
	vec3 lightColor = vec3(1.0, 0.8, 0.4);          
	vec3 L1 = lightColor * 20.0;//40.0;
	vec3 L2 = lightColor * 30.0;//60.0;
	vec3 L3 = lightColor * 50.0;//100.0;
	vec3 glassColor = vec3(0.3, 1.0, 0.9);
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

	rectangles[0] = Rectangle( vec3( 10, 200,  50), vec3( 0, -1,  0),  6.0,  6.0, L1, z, LIGHT);// Area Light Rect Overhead 
	rectangles[1] = Rectangle( vec3(200, 110,  70), vec3(-1,  0,  0), 13.0, 13.0, L2, z, LIGHT);// Area Light Rect Right
	rectangles[2] = Rectangle( vec3(-10, 220,-200), vec3( 0, -1,  0), 10.0, 10.0, L3, z, LIGHT);// Area Light Rect Far
}


#include <pathtracing_main>
