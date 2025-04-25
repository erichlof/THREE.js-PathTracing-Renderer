precision highp float;
precision highp int;
precision highp sampler2D;

#include <pathtracing_uniforms_and_defines>

uniform mat4 uTorusInvMatrix;
uniform float uSamplesPerFrame;

#define N_LIGHTS 3.0
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

vec3 rayOrigin, rayDirection;
// recorded intersection data:
vec3 hitNormal, hitEmission, hitColor;
vec2 hitUV;
float hitObjectID;
int hitType = -100;

struct Sphere { float radius; vec3 position; vec3 emission; vec3 color; int type; };
struct Ellipsoid { vec3 radii; vec3 position; vec3 emission; vec3 color; int type; };
struct Paraboloid { float rad; float height; vec3 pos; vec3 emission; vec3 color; int type; };
struct OpenCylinder { float radius; float height; vec3 position; vec3 emission; vec3 color; int type; };
struct CappedCylinder { float radius; vec3 cap1pos; vec3 cap2pos; vec3 emission; vec3 color; int type; };
struct Cone { vec3 pos0; float radius0; vec3 pos1; float radius1; vec3 emission; vec3 color; int type; };
struct Capsule { vec3 pos0; float radius0; vec3 pos1; float radius1; vec3 emission; vec3 color; int type; };
struct UnitTorus { float parameterK; vec3 emission; vec3 color; int type; };
struct Box { vec3 minCorner; vec3 maxCorner; vec3 emission; vec3 color; int type; };

Sphere spheres[N_SPHERES];
Ellipsoid ellipsoids[N_ELLIPSOIDS];
Paraboloid paraboloids[N_PARABOLOIDS];
OpenCylinder openCylinders[N_OPENCYLINDERS];
CappedCylinder cappedCylinders[N_CAPPEDCYLINDERS];
Cone cones[N_CONES];
Capsule capsules[N_CAPSULES];
UnitTorus torii[N_TORII];
Box boxes[N_BOXES];


#include <pathtracing_random_functions>

#include <pathtracing_calc_fresnel_reflectance>

#include <pathtracing_sphere_intersect>

#include <pathtracing_unit_bounding_sphere_intersect>

#include <pathtracing_ellipsoid_intersect>

#include <pathtracing_opencylinder_intersect>

#include <pathtracing_cappedcylinder_intersect>

#include <pathtracing_cone_intersect>

#include <pathtracing_capsule_intersect>

#include <pathtracing_paraboloid_intersect>

#include <pathtracing_unit_torus_intersect>

#include <pathtracing_box_intersect>

#include <pathtracing_sample_sphere_light>

//-------------------------------------------------------------------------------------------------------------------
float SceneIntersect( out int finalIsRayExiting )
//-------------------------------------------------------------------------------------------------------------------
{
	vec3 rObjOrigin, rObjDirection;
	vec3 n;
	float d, dt;
	float t = INFINITY;
	int isRayExiting = FALSE;
	int insideSphere = FALSE;
	int objectCount = 0;
	
	hitObjectID = -INFINITY;
	
	
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
	

	d = BoxIntersect( boxes[0].minCorner, boxes[0].maxCorner, rayOrigin, rayDirection, n, isRayExiting );
	if (d < t)
	{
		t = d;
		hitNormal = n;
		hitEmission = boxes[0].emission;
		hitColor = boxes[0].color;
		hitType = boxes[0].type;
		finalIsRayExiting = isRayExiting;
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
		finalIsRayExiting = isRayExiting;
		hitObjectID = float(objectCount);
	}
	objectCount++;
	
	
	d = EllipsoidIntersect( ellipsoids[0].radii, ellipsoids[0].position, rayOrigin, rayDirection );
	if (d < t)
	{
		t = d;
		hitNormal = ((rayOrigin + rayDirection * t) - 
			ellipsoids[0].position) / (ellipsoids[0].radii * ellipsoids[0].radii);
		hitEmission = ellipsoids[0].emission;
		hitColor = ellipsoids[0].color;
		hitType = ellipsoids[0].type;
		hitObjectID = float(objectCount);
	}
	objectCount++;
	
	d = ParaboloidIntersect( paraboloids[0].rad, paraboloids[0].height, paraboloids[0].pos, rayOrigin, rayDirection, n );
	if (d < t)
	{
		t = d;
		hitNormal = n;
		hitEmission = paraboloids[0].emission;
		hitColor = paraboloids[0].color;
		hitType = paraboloids[0].type;
		hitObjectID = float(objectCount);
	}
	objectCount++;
	
	d = OpenCylinderIntersect( openCylinders[0].position, openCylinders[0].position + vec3(0,30,30), openCylinders[0].radius, rayOrigin, rayDirection, n );
	if (d < t)
	{
		t = d;
		hitNormal = n;
		hitEmission = openCylinders[0].emission;
		hitColor = openCylinders[0].color;
		hitType = openCylinders[0].type;
		hitObjectID = float(objectCount);
	}
	objectCount++;
        
	d = CappedCylinderIntersect( cappedCylinders[0].cap1pos, cappedCylinders[0].cap2pos, cappedCylinders[0].radius, rayOrigin, rayDirection, n);
	if (d < t)
	{
		t = d;
		hitNormal = n;
		hitEmission = cappedCylinders[0].emission;
		hitColor = cappedCylinders[0].color;
		hitType = cappedCylinders[0].type;
		hitObjectID = float(objectCount);
	}
	objectCount++;
        
	d = ConeIntersect( cones[0].pos0, cones[0].radius0, cones[0].pos1, cones[0].radius1, rayOrigin, rayDirection, n );
	if (d < t)
	{
		t = d;
		hitNormal = n;
		hitEmission = cones[0].emission;
		hitColor = cones[0].color;
		hitType = cones[0].type;
		hitObjectID = float(objectCount);
	}
	objectCount++;
        
	d = CapsuleIntersect( capsules[0].pos0, capsules[0].radius0, capsules[0].pos1, capsules[0].radius1, rayOrigin, rayDirection, n );
	if (d < t)
	{
		t = d;
		hitNormal = n;
		hitEmission = capsules[0].emission;
		hitColor = capsules[0].color;
		hitType = capsules[0].type;
		hitObjectID = float(objectCount);
	}
	objectCount++;
        
	// transform ray into Torus's object space
	rObjOrigin = vec3( uTorusInvMatrix * vec4(rayOrigin, 1.0) );
	rObjDirection = vec3( uTorusInvMatrix * vec4(rayDirection, 0.0) );
	// first check that the ray hits the bounding sphere around the torus
	d = UnitBoundingSphereIntersect( rObjOrigin, rObjDirection, insideSphere );
	if (d < INFINITY)
	{	// if outside the sphere, move the ray up close to the Torus, for numerical stability
		d = insideSphere == TRUE ? 0.0 : d;
		rObjOrigin += rObjDirection * d;

		dt = d + UnitTorusIntersect( rObjOrigin, rObjDirection, torii[0].parameterK, n );
		if (dt < t)
		{
			t = dt;
			hitNormal = transpose(mat3(uTorusInvMatrix)) * n;
			hitEmission = torii[0].emission;
			hitColor = torii[0].color;
			hitType = torii[0].type;
			hitObjectID = float(objectCount);
		}
	}
        
	
	return t;
	
} // end float SceneIntersect( out int finalIsRayExiting )


//-----------------------------------------------------------------------------------------------------------------------------
vec3 CalculateRadiance( out vec3 objectNormal, out vec3 objectColor, out float objectID, out float pixelSharpness )
//-----------------------------------------------------------------------------------------------------------------------------
{
	Sphere lightChoice;

	vec3 accumCol = vec3(0);
        vec3 mask = vec3(1);
	vec3 checkCol0 = vec3(1);
	vec3 checkCol1 = vec3(0.5);
	vec3 dirToLight;
	vec3 tdir;
	vec3 x, n, nl;
        
	float t;
	float nc, nt, ratioIoR, Re, Tr;
	float P, RP, TP;
	float weight;
	float thickness = 0.1;

	int diffuseCount = 0;
	int previousIntersecType = -100;
	hitType = -100;
	
	int coatTypeIntersected = FALSE;
	int bounceIsSpecular = TRUE;
	int sampleLight = FALSE;
	int isRayExiting;

	lightChoice = spheres[int(rng() * N_LIGHTS)];

	
	for (int bounces = 0; bounces < 6; bounces++)
	{
		previousIntersecType = hitType;

		t = SceneIntersect(isRayExiting);
		
		/*
		//not used in this scene because we are inside a huge sphere - no rays can escape
		if (t == INFINITY)
		{
                        break;
		}
		*/

		// useful data 
		n = normalize(hitNormal);
                nl = dot(n, rayDirection) < 0.0 ? n : -n;
		x = rayOrigin + rayDirection * t;

		if (bounces == 0)
		{
			objectNormal = n;
			objectColor = hitColor;
			objectID = hitObjectID;
		}
		
		
		if (hitType == LIGHT)
		{	
			if (bounceIsSpecular == TRUE || sampleLight == TRUE)
				accumCol = mask * hitEmission;
			// reached a light, so we can exit
			break;
		} // end if (hitType == LIGHT)


		if (sampleLight == TRUE)
			break;


		    
                if (hitType == DIFF || hitType == CHECK) // Ideal DIFFUSE reflection
		{
			if( hitType == CHECK )
			{
				float q = clamp( mod( dot( floor(x.xz * 0.04), vec2(1.0) ), 2.0 ) , 0.0, 1.0 );
				hitColor = checkCol0 * q + checkCol1 * (1.0 - q);	
			}
				
			if (bounces == 0 || (diffuseCount == 0 && coatTypeIntersected == FALSE && previousIntersecType == SPEC))	
				objectColor = hitColor;

			diffuseCount++;

			mask *= hitColor;

			bounceIsSpecular = FALSE;

			if (diffuseCount == 1 && rand() < 0.5)
			{
				mask *= 2.0;
				// choose random Diffuse sample vector
				rayDirection = randomCosWeightedDirectionInHemisphere(nl);
				rayOrigin = x + nl * uEPS_intersect;
				continue;
			}

			dirToLight = sampleSphereLight(x, nl, lightChoice, weight);
			mask *= diffuseCount == 1 ? 2.0 : 1.0;
			mask *= weight * N_LIGHTS;

			rayDirection = dirToLight;
			rayOrigin = x + nl * uEPS_intersect;

			sampleLight = TRUE;
			continue;
                        
		} // end if (hitType == DIFF)
		
		if (hitType == SPEC)  // Ideal SPECULAR reflection
		{
			mask *= hitColor;

			rayDirection = reflect(rayDirection, nl);
			rayOrigin = x + nl * uEPS_intersect;

			//if (diffuseCount == 1)
			//	bounceIsSpecular = TRUE; // turn on reflective mirror caustics

			continue;
		}
		
		if (hitType == REFR)  // Ideal dielectric REFRACTION
		{

			nc = 1.0; // IOR of Air
			nt = 1.5; // IOR of common Glass
			Re = calcFresnelReflectance(rayDirection, n, nc, nt, ratioIoR);
			Tr = 1.0 - Re;
			P  = 0.25 + (0.5 * Re);
                	RP = Re / P;
                	TP = Tr / (1.0 - P);

			if (diffuseCount == 0 && rng() < P)
			{
				mask *= RP;
				rayDirection = reflect(rayDirection, nl); // reflect ray from surface
				rayOrigin = x + nl * uEPS_intersect;
				continue;
			}

			// transmit ray through surface

			// is ray leaving a solid object from the inside? 
			// If so, attenuate ray color with object color by how far ray has travelled through the medium
			if (isRayExiting == TRUE)
			{
				isRayExiting = FALSE;
				mask *= exp(log(hitColor) * thickness * t);
			}
			else 
				mask *= hitColor;

			mask *= TP;
			
			tdir = refract(rayDirection, nl, ratioIoR);
			rayDirection = tdir;
			rayOrigin = x - nl * uEPS_intersect;

			if (diffuseCount == 1)
				bounceIsSpecular = TRUE; // turn on refracting caustics

			continue;
			
		} // end if (hitType == REFR)
		
		if (hitType == COAT)  // Diffuse object underneath with ClearCoat on top
		{
			coatTypeIntersected = TRUE;
			
			nc = 1.0; // IOR of Air
			nt = 1.4; // IOR of Clear Coat
			Re = calcFresnelReflectance(rayDirection, nl, nc, nt, ratioIoR);
			Tr = 1.0 - Re;
			P  = 0.25 + (0.5 * Re);
                	RP = Re / P;
                	TP = Tr / (1.0 - P);
			
			if (diffuseCount == 0 && rng() < P)
			{
				mask *= RP;
				rayDirection = reflect(rayDirection, nl); // reflect ray from surface
				rayOrigin = x + nl * uEPS_intersect;
				continue;
			}

			diffuseCount++;

			mask *= TP;
			mask *= hitColor;

			bounceIsSpecular = FALSE;

			if (diffuseCount == 1 && rand() < 0.5)
			{
				mask *= 2.0;
				// choose random Diffuse sample vector
				rayDirection = randomCosWeightedDirectionInHemisphere(nl);
				rayOrigin = x + nl * uEPS_intersect;
				continue;
			}
			
			if (hitColor.r == 1.0 && rng() < 0.9) // this makes white capsule more 'white'
				dirToLight = sampleSphereLight(x, nl, spheres[0], weight);
			else
				dirToLight = sampleSphereLight(x, nl, lightChoice, weight);
			
			mask *= diffuseCount == 1 ? 2.0 : 1.0;
			mask *= weight * N_LIGHTS;
			
			rayDirection = dirToLight;
			rayOrigin = x + nl * uEPS_intersect;

			sampleLight = TRUE;
			continue;
			
		} //end if (hitType == COAT)

		
	} // end for (int bounces = 0; bounces < 6; bounces++)
	
	
	return max(vec3(0), accumCol);

} // end vec3 CalculateRadiance( out vec3 objectNormal, out vec3 objectColor, out float objectID, out float pixelSharpness )


//-----------------------------------------------------------------------
void SetupScene(void)
//-----------------------------------------------------------------------
{
	vec3 z  = vec3(0);          
	vec3 L1 = vec3(1.0, 1.0, 1.0) * 5.0;// White light
	vec3 L2 = vec3(1.0, 0.8, 0.2) * 4.0;// Yellow light
	vec3 L3 = vec3(0.1, 0.7, 1.0) * 2.0;// Blue light
		
        spheres[0] = Sphere(150.0, vec3(-400, 900, 200), L1, z, LIGHT);//spherical white Light1 
	spheres[1] = Sphere(100.0, vec3( 300, 400,-300), L2, z, LIGHT);//spherical yellow Light2
	spheres[2] = Sphere( 50.0, vec3( 500, 250,-100), L3, z, LIGHT);//spherical blue Light3
	
	spheres[3] = Sphere(1000.0, vec3(  0.0, 1000.0,  0.0), z, vec3(1.0, 1.0, 1.0), CHECK);//Checkered Floor
        spheres[4] = Sphere(  16.5, vec3(-26.0,   17.2,  5.0), z, vec3(0.95, 0.95, 0.95), SPEC);//Mirror sphere
        spheres[5] = Sphere(  15.0, vec3( 32.0,   16.1, 30.0), z, vec3(1.0, 1.0, 1.0), REFR);//Glass sphere
        
	ellipsoids[0] = Ellipsoid(  vec3(30,40,16), vec3(90,5,-30), z, vec3(1.0, 0.765557, 0.336057), SPEC);//metallic gold ellipsoid
	
	paraboloids[0] = Paraboloid(  16.5, 50.0, vec3(20,1.5,-50), z, vec3(1.0, 0.2, 0.7), REFR);//paraboloid
	
	openCylinders[0] = OpenCylinder( 15.0, 30.0, vec3(-70,7,-80), z, vec3(0.9,0.01,0.01), REFR);//red glass open Cylinder

	cappedCylinders[0] = CappedCylinder( 14.0, vec3(-60,0,20), vec3(-60,14,20), z, vec3(0.04,0.04,0.04), COAT);//dark gray capped Cylinder
	
	cones[0] = Cone( vec3(1,20,-12), 15.0, vec3(1,0,-12), 0.0, z, vec3(0.01,0.1,0.5), REFR);//blue Cone
	
	capsules[0] = Capsule( vec3(80,13,15), 10.0, vec3(110,15.8,15), 10.0, z, vec3(1.0, 1.0, 1.0), COAT);//white Capsule
	
	torii[0] = UnitTorus( 0.75, z, vec3(0.955008, 0.637427, 0.538163), SPEC);//copper Torus
	
	boxes[0] = Box( vec3(50.0,21.0,-60.0), vec3(100.0,28.0,-130.0), z, vec3(0.2,0.9,0.7), REFR);//Glass Box
	boxes[1] = Box( vec3(56.0,23.0,-66.0), vec3(94.0,26.0,-124.0), z, vec3(0.0,0.0,0.0), DIFF);//Diffuse Box
}

// normally we would use the default <pathtracing_main> function in PathTracingCommon.js,
// but since we want multi-sampling ability, the main function is instead redefined below
//#include <pathtracing_main>

// tentFilter from Peter Shirley's 'Realistic Ray Tracing (2nd Edition)' book, pg. 60
float tentFilter(float x)
{
	return (x < 0.5) ? sqrt(2.0 * x) - 1.0 : 1.0 - sqrt(2.0 - (2.0 * x));
}

void main( void )
{
	vec3 camRight   = vec3( uCameraMatrix[0][0],  uCameraMatrix[0][1],  uCameraMatrix[0][2]);
	vec3 camUp      = vec3( uCameraMatrix[1][0],  uCameraMatrix[1][1],  uCameraMatrix[1][2]);
	vec3 camForward = vec3(-uCameraMatrix[2][0], -uCameraMatrix[2][1], -uCameraMatrix[2][2]);
	// the following is not needed - three.js has a built-in uniform named cameraPosition
	//vec3 camPos   = vec3( uCameraMatrix[3][0],  uCameraMatrix[3][1],  uCameraMatrix[3][2]);

	// calculate unique seed for rng() function
	seed = uvec2(uFrameCounter, uFrameCounter + 1.0) * uvec2(gl_FragCoord);
	// initialize rand() variables
	randNumber = 0.0; // the final randomly-generated number (range: 0.0 to 1.0)
	blueNoise = texelFetch(tBlueNoiseTexture, ivec2(mod(floor(gl_FragCoord.xy), 128.0)), 0).r;
	
	SetupScene();

	// NOTE: for this 'MultiSamples Per Frame' test demo, the edge detection and denoiser are temporarily disabled.
	// the following 4 variables are just acting as place holders that are passed in as arguments to the CalculateRadiance() function.
	// Any denoising/smoothness that you see is a direct result of the number of multi-samples layered on top of each other per frame, in Monte Carlo fashion.
	
	// Edge Detection - don't want to blur edges where either surface normals change abruptly (i.e. room wall corners), objects overlap each other (i.e. edge of a foreground sphere in front of another sphere right behind it),
	// or an abrupt color variation on the same smooth surface, even if it has similar surface normals (i.e. checkerboard pattern). Want to keep all of these cases as sharp as possible - no blur filter will be applied.
	vec3 objectNormal = vec3(0);
	vec3 objectColor = vec3(0);
	float objectID = -INFINITY;
	float pixelSharpness = 0.0;

	

	// multi-samples per frame
	vec4 currentPixel = vec4(0);
	// perform path tracing and get resulting pixel color
	for (int i = 0; i < int(uSamplesPerFrame); i++)
	{
		vec2 pixelOffset = vec2( tentFilter(rng()), tentFilter(rng()) );

		// we must map pixelPos into the range -1.0 to +1.0
		vec2 pixelPos = ((gl_FragCoord.xy + pixelOffset) / uResolution) * 2.0 - 1.0;
		vec3 rayDir = normalize( pixelPos.x * camRight * uULen + pixelPos.y * camUp * uVLen + camForward );

		// depth of field
		vec3 focalPoint = uFocusDistance * rayDir;
		float randomAngle = rng() * TWO_PI; // pick random point on aperture
		float randomRadius = rng() * uApertureSize;
		vec3  randomAperturePos = ( cos(randomAngle) * camRight + sin(randomAngle) * camUp ) * sqrt(randomRadius);
		// point on aperture to focal point
		vec3 finalRayDir = normalize(focalPoint - randomAperturePos);

		rayOrigin = cameraPosition + randomAperturePos;
		rayDirection = finalRayDir;
		currentPixel += vec4( vec3(CalculateRadiance(objectNormal, objectColor, objectID, pixelSharpness)), 0.0 );
		seed *= uvec2(3);
	}
	currentPixel /= uSamplesPerFrame; // average by number of samples

	
	vec4 previousPixel = texelFetch(tPreviousTexture, ivec2(gl_FragCoord.xy), 0);
	if (uFrameCounter == 1.0) // camera just moved after being still
	{
		previousPixel.rgb *= (1.0 / uPreviousSampleCount) * 0.5; // essentially previousPixel *= 0.5, like below
		currentPixel.rgb *= 0.5;
	}
	else if (uCameraIsMoving) // camera is currently moving
	{
		previousPixel.rgb *= 0.5; // motion-blur trail amount (old image)
		currentPixel.rgb *= 0.5; // brightness of new image (noisy)
	}

	// if current raytraced pixel didn't return any color value, just use the previous frame's pixel color
	if (currentPixel.rgb == vec3(0.0))
	{
		currentPixel.rgb = previousPixel.rgb;
		previousPixel.rgb *= 0.5;
		currentPixel.rgb *= 0.5;
	}

	pc_fragColor = vec4(previousPixel.rgb + currentPixel.rgb, 1.01); // 1.01 is a signal to screenOutputShader to skip noise blur-filtering
}
