precision highp float;
precision highp int;
precision highp sampler2D;

#include <pathtracing_uniforms_and_defines>

#define N_SPHERES 3
#define N_QUADS 6
#define N_BOXES 1


//-----------------------------------------------------------------------

vec3 rayOrigin, rayDirection;
// recorded intersection data:
vec3 hitNormal, hitEmission, hitColor;
vec2 hitUV;
float hitObjectID;
int hitType;


struct Sphere { float radius; vec3 position; vec3 emission; vec3 color; int type; };
struct Quad { vec3 normal; vec3 v0; vec3 v1; vec3 v2; vec3 v3; vec3 emission; vec3 color; int type; };
struct Box { vec3 minCorner; vec3 maxCorner; vec3 emission; vec3 color; int type; };

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


//---------------------------------------------------------------------------------------
float SceneIntersect( )
//---------------------------------------------------------------------------------------
{
	mat4 m;

	vec3 warpedRayOrigin, warpedRayDirection;
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
	int objectCount = 0;
	
	hitObjectID = -INFINITY;
	
	bool isRayExiting = false;
	

	for (int i = 0; i < N_QUADS; i++)
        {
		d = QuadIntersect( quads[i].v0, quads[i].v1, quads[i].v2, quads[i].v3, rayOrigin, rayDirection, false );
		if (d < t)
		{
			t = d;
			hitNormal = normalize(quads[i].normal);
			hitEmission = quads[i].emission;
			hitColor = quads[i].color;
			hitType = quads[i].type;
			hitObjectID = float(objectCount);
		}
		objectCount++;
        }

	
	// Twisted Glass Sphere Left
	d = SphereIntersect( spheres[0].radius, spheres[0].position, rayOrigin, rayDirection );
	intersectionPoint = rayOrigin + rayDirection * d;
	angle = mod(intersectionPoint.y * 0.1, TWO_PI);
	m = makeRotateY(angle);
	o = ( m * vec4(intersectionPoint, 1.0) ).xyz;
	offset = o * 0.1;
	d = SphereIntersect( spheres[0].radius, spheres[0].position + offset, rayOrigin, rayDirection);
	if (d < t)
	{
		t = d;
		intersectionPoint = rayOrigin + rayDirection * t;
		tempNormal = (intersectionPoint - (spheres[0].position + offset));
		hitNormal = normalize(tempNormal);
		hitEmission = spheres[0].emission;
		hitColor = spheres[0].color;
		hitType = spheres[0].type;
		hitObjectID = float(objectCount);
	}
	objectCount++;

	// Twisted Glass Sphere Right
	d = SphereIntersect( spheres[1].radius, spheres[1].position, rayOrigin, rayDirection );
	intersectionPoint = rayOrigin + rayDirection * d;
	angle = mod(intersectionPoint.y * 0.1, TWO_PI);
	m = makeRotateY(angle);
	o = ( m * vec4(intersectionPoint, 1.0) ).xyz;
	offset = o * 0.1;
	d = SphereIntersect( spheres[1].radius, spheres[1].position + offset, rayOrigin, rayDirection);
	if (d < t)
	{
		t = d;
		intersectionPoint = rayOrigin + rayDirection * t;
		tempNormal = (intersectionPoint - (spheres[1].position + offset));
		hitNormal = normalize(tempNormal);
		hitEmission = spheres[1].emission;
		hitColor = spheres[1].color;
		hitType = spheres[1].type;
		hitObjectID = float(objectCount);
	}
	objectCount++;
			
	// Purple Cloud Sphere
	width = 2.0 * rng();
	offset = (spheres[2].radius * 0.5) * (vec3(rng() * 2.0 - 1.0, rng() * 2.0 - 1.0, rng() * 2.0 - 1.0));
	d = SphereIntersect( spheres[2].radius + width, spheres[2].position + offset, rayOrigin, rayDirection);
	if (d < t)
	{
		t = d;
		intersectionPoint = rayOrigin + rayDirection * t;
		tempNormal = (intersectionPoint - (spheres[2].position + offset));
		hitNormal = normalize(tempNormal);
		hitEmission = spheres[2].emission;
		hitColor = spheres[2].color;
		hitType = spheres[2].type;
		hitObjectID = float(objectCount);
	}
	objectCount++;

	// Twisted Tall Mirror Box
	warpedRayOrigin = rayOrigin;
	warpedRayDirection = rayDirection;
	warpedRayOrigin.x -= 200.0;
	warpedRayOrigin.y -= 200.0;
	warpedRayOrigin.z += 400.0;
	
	d = BoxIntersect( boxes[0].minCorner * vec3(1.5, 1.0, 1.5), boxes[0].maxCorner * vec3(1.5, 1.0, 1.5), warpedRayOrigin, warpedRayDirection, n, isRayExiting );
	if (d == INFINITY) return t;
	
	hitPos = warpedRayOrigin + warpedRayDirection * d;
	//float angle = 0.25 * PI;
	angle = mod(hitPos.y * 0.015, TWO_PI);
	m = makeRotateY(angle);
	m = inverse(m);
	warpedRayOrigin = vec3( m * vec4(warpedRayOrigin, 1.0) );
	warpedRayDirection = normalize(vec3( m * vec4(warpedRayDirection, 0.0) ));
	
	d = BoxIntersect( boxes[0].minCorner, boxes[0].maxCorner, warpedRayOrigin, warpedRayDirection, n, isRayExiting );
	if (d < t)
	{
		t = d;
		hitNormal = normalize(n);
		hitNormal = normalize(vec3( transpose(m) * vec4(hitNormal, 0.0) ));
		hitEmission = boxes[0].emission;
		hitColor = boxes[0].color;
		hitType = boxes[0].type;
		hitObjectID = float(objectCount);
	}

	return t;
} // end float SceneIntersect( )


//-----------------------------------------------------------------------------------------------------------------------------
vec3 CalculateRadiance( out vec3 objectNormal, out vec3 objectColor, out float objectID, out float pixelSharpness )
//-----------------------------------------------------------------------------------------------------------------------------
{
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
	int previousIntersecType = -100;
	hitType = -100;

	bool coatTypeIntersected = false;
	bool bounceIsSpecular = true;
	bool sampleLight = false;

	
	for (int bounces = 0; bounces < 5; bounces++)
	{
		previousIntersecType = hitType;

		t = SceneIntersect();
		

		if (t == INFINITY)	
			break;

		// useful data 
		n = normalize(hitNormal);
                nl = dot(n, rayDirection) < 0.0 ? normalize(n) : normalize(-n);
		x = rayOrigin + rayDirection * t;

		if (bounces == 0)
		{
			objectNormal = nl;
			objectColor = hitColor;
			objectID = hitObjectID;
		}
		if (bounces == 1 && previousIntersecType == SPEC)
		{
			objectNormal = nl;
		}
		
		
		if (hitType == LIGHT)
		{	
			if (diffuseCount == 0)
				pixelSharpness = 1.01;

			if (bounceIsSpecular || sampleLight)
				accumCol = mask * hitEmission;
			// reached a light, so we can exit
			break;

		} // end if (hitType == LIGHT)


		// if we get here and sampleLight is still true, shadow ray failed to find a light source
		if (sampleLight)	
			break;
		

		    
                if (hitType == DIFF) // Ideal DIFFUSE reflection
		{
			diffuseCount++;

			mask *= hitColor;

			bounceIsSpecular = false;

			if (diffuseCount == 1 && rand() < 0.5)
			{
				mask *= 2.0;
				// choose random Diffuse sample vector
				rayDirection = randomCosWeightedDirectionInHemisphere(nl);
				rayOrigin = x + nl * uEPS_intersect;
				continue;
			}
                        
			dirToLight = sampleQuadLight(x, nl, quads[5], weight);
			mask *= diffuseCount == 1 ? 2.0 : 1.0;
			mask *= weight;

			rayDirection = dirToLight;
			rayOrigin = x + nl * uEPS_intersect;

			sampleLight = true;
			continue;
                        
		} // end if (hitType == DIFF)
		
		if (hitType == SPEC)  // Ideal SPECULAR reflection
		{
			mask *= hitColor;

			rayDirection = reflect(rayDirection, nl);
			rayOrigin = x + nl * uEPS_intersect;

			continue;
		}
		
		if (hitType == REFR)  // Ideal dielectric REFRACTION
		{
			if (diffuseCount == 0 && !coatTypeIntersected && !uCameraIsMoving )
				pixelSharpness = 1.01;
			else if (diffuseCount > 0)
				pixelSharpness = 0.0;
			else
				pixelSharpness = -1.0;

			nc = 1.0; // IOR of Air
			nt = 1.5; // IOR of common Glass
			Re = calcFresnelReflectance(rayDirection, n, nc, nt, ratioIoR);
			Tr = 1.0 - Re;
			P  = 0.25 + (0.5 * Re);
                	RP = Re / P;
                	TP = Tr / (1.0 - P);
			
			if (rand() < P)
			{
				mask *= RP;
				rayDirection = reflect(rayDirection, nl); // reflect ray from surface
				rayOrigin = x + nl * uEPS_intersect;
				continue;
			}

			// transmit ray through surface
			
			// is ray leaving a solid object from the inside? 
			// If so, attenuate ray color with object color by how far ray has travelled through the medium
			// if (distance(n, nl) > 0.1)
			// {
			// 	thickness = 0.01;
			// 	mask *= exp( log(clamp(hitColor, 0.01, 0.99)) * thickness * t ); 
			// }

			mask *= TP;
			mask *= hitColor;

			tdir = refract(rayDirection, nl, ratioIoR);
			rayDirection = tdir;
			rayOrigin = x - nl * uEPS_intersect;

			if (diffuseCount == 1)
				bounceIsSpecular = true; // turn on refracting caustics

			continue;
			
		} // end if (hitType == REFR)
		
		if (hitType == COAT)  // Diffuse object underneath with ClearCoat on top
		{
			coatTypeIntersected = true;

			nc = 1.0; // IOR of Air
			nt = 1.4; // IOR of Clear Coat
			Re = calcFresnelReflectance(rayDirection, nl, nc, nt, ratioIoR);
			Tr = 1.0 - Re;
			P  = 0.25 + (0.5 * Re);
                	RP = Re / P;
                	TP = Tr / (1.0 - P);

			if (rand() < P)
			{
				if (bounces == 0)
					pixelSharpness = uFrameCounter > 200.0 ? 1.01 : -1.0;
					
				mask *= RP;
				rayDirection = reflect(rayDirection, nl); // reflect ray from surface
				rayOrigin = x + nl * uEPS_intersect;
				continue;
			}

			diffuseCount++;
			mask *= TP;
			mask *= hitColor;

			bounceIsSpecular = false;
			
			if (diffuseCount == 1 && rand() < 0.5)
			{
				mask *= 2.0;
				// choose random Diffuse sample vector
				rayDirection = randomCosWeightedDirectionInHemisphere(nl);
				rayOrigin = x + nl * uEPS_intersect;
				continue;
			}

			dirToLight = sampleQuadLight(x, nl, quads[5], weight);
			mask *= diffuseCount == 1 ? 2.0 : 1.0;
			mask *= weight;
			
			rayDirection = dirToLight;
			rayOrigin = x + nl * uEPS_intersect;

			sampleLight = true;
			continue;
			
		} //end if (hitType == COAT)

		
		
	} // end for (int bounces = 0; bounces < 5; bounces++)
	
	
	return max(vec3(0), accumCol);

} // end vec3 CalculateRadiance( out vec3 objectNormal, out vec3 objectColor, out float objectID, out float pixelSharpness )



//-----------------------------------------------------------------------
void SetupScene(void)
//-----------------------------------------------------------------------
{
	vec3 z  = vec3(0);// No color value, Black        
	vec3 L1 = vec3(1.0, 1.0, 1.0) * 5.0;// Bright light
	
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
