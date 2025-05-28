precision highp float;
precision highp int;
precision highp sampler2D;

uniform mat4 uShortBoxInvMatrix;
uniform mat4 uTallBoxInvMatrix;

#include <pathtracing_uniforms_and_defines>

#define N_QUADS 1
#define N_BOXES 3

//-----------------------------------------------------------------------

vec3 rayOrigin, rayDirection;
// recorded intersection data:
vec3 hitNormal, hitEmission, hitColor;
vec2 hitUV;
float hitObjectID = -INFINITY;
int hitType = -100;

struct Quad { vec3 normal; vec3 v0; vec3 v1; vec3 v2; vec3 v3; vec3 emission; vec3 color; int type; };
struct Box { vec3 minCorner; vec3 maxCorner; vec3 emission; vec3 color; int type; };

Quad quads[N_QUADS];
Box boxes[N_BOXES];


#include <pathtracing_random_functions>
		
#include <pathtracing_calc_fresnel_reflectance>

#include <pathtracing_quad_intersect>

#include <pathtracing_box_intersect>

#include <pathtracing_box_interior_intersect>

#include <pathtracing_sample_quad_light>


#define STILL_WATER_LEVEL 100.0
#define WATER_WAVE_AMP 20.0
#define WATER_COLOR vec3(0.6, 1.0, 1.0)

float getWaterWaveHeight( vec3 pos )
{
	float waveSpeed = uTime * 6.0;
	
	float sampleAngle1 = mod(pos.x * 0.013  - waveSpeed * 0.7, TWO_PI);
	float sampleAngle2 = mod(pos.z * 0.027  - waveSpeed * 0.4, TWO_PI);
	float sampleAngle3 = mod(pos.x * 0.029  - waveSpeed * 0.5, TWO_PI);
	float sampleAngle4 = mod(pos.z * 0.015  - waveSpeed * 0.6, TWO_PI);
	
	float waveOffset = 0.25 * ( sin(sampleAngle1) + sin(sampleAngle2) + 
				    sin(sampleAngle3) + sin(sampleAngle4) );

	return STILL_WATER_LEVEL + (waveOffset * WATER_WAVE_AMP);
}

//--------------------------------------------------------------------------------------------------------
float SceneIntersect( int checkWater )
//--------------------------------------------------------------------------------------------------------
{
	vec3 rObjOrigin, rObjDirection;
	vec3 hitWorldSpace;
	vec3 normal, n;

        float d = INFINITY;
	float t = INFINITY;
	float waterWaveDepth;

	int objectCount = 0;
	
	int isRayExiting = FALSE;
	
	
	d = QuadIntersect( quads[0].v0, quads[0].v1, quads[0].v2, quads[0].v3, rayOrigin, rayDirection, FALSE );
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

	d = BoxInteriorIntersect( boxes[2].minCorner, boxes[2].maxCorner, rayOrigin, rayDirection, n );
	if (d < t && n != vec3(0,0,-1))
	{
		t = d;
		hitNormal = n;
		hitEmission = boxes[2].emission;
		hitColor = vec3(1);
		hitType = DIFF;
	
		if (n == vec3(1,0,0)) // left wall
		{
			hitColor = vec3(0.7, 0.12,0.05);
		}
		else if (n == vec3(-1,0,0)) // right wall
		{
			hitColor = vec3(0.2, 0.4, 0.36);
		}
		
		hitObjectID = float(objectCount);
	}
	objectCount++;

	
	// TALL MIRROR BOX
	// transform ray into Tall Box's object space
	rObjOrigin = vec3( uTallBoxInvMatrix * vec4(rayOrigin, 1.0) );
	rObjDirection = vec3( uTallBoxInvMatrix * vec4(rayDirection, 0.0) );
	d = BoxIntersect( boxes[0].minCorner, boxes[0].maxCorner, rObjOrigin, rObjDirection, normal, isRayExiting );
	
	if (d < t)
	{	
		t = d;
		// transfom normal back into world space
		hitNormal = transpose(mat3(uTallBoxInvMatrix)) * normal;
		hitEmission = boxes[0].emission;
		hitColor = boxes[0].color;
		hitType = boxes[0].type;
		hitObjectID = float(objectCount);
	}
	objectCount++;
	
	// SHORT DIFFUSE BOX
	// transform ray into Short Box's object space
	rObjOrigin = vec3( uShortBoxInvMatrix * vec4(rayOrigin, 1.0) );
	rObjDirection = vec3( uShortBoxInvMatrix * vec4(rayDirection, 0.0) );
	d = BoxIntersect( boxes[1].minCorner, boxes[1].maxCorner, rObjOrigin, rObjDirection, normal, isRayExiting );
	
	if (d < t)
	{	
		t = d;
		// transfom normal back into world space
		hitNormal = transpose(mat3(uShortBoxInvMatrix)) * normal;
		hitEmission = boxes[1].emission;
		hitColor = boxes[1].color;
		hitType = boxes[1].type;
		hitObjectID = float(objectCount);
	}
	objectCount++;
	
	
	// color surfaces beneath the water
	vec3 underwaterHitPos = rayOrigin + rayDirection * t;
	float testPosWaveHeight = getWaterWaveHeight(underwaterHitPos);
	if (underwaterHitPos.y < testPosWaveHeight)
	{
		hitColor *= WATER_COLOR;
	}

	if (checkWater == FALSE)
	{
		return t;
	}

	///////////////////////////////////////////////////////////////////////////////////////////////////////
	// WATER VOLUME 
	///////////////////////////////////////////////////////////////////////////////////////////////////////

	vec3 pos = rayOrigin;
	vec3 dir = rayDirection;
	float h = 0.0;
	d = 0.0; // reset d
	
	for(int i = 0; i < 150; i++)
	{
		h = abs(pos.y - getWaterWaveHeight(pos));
		if (d > 10000.0 || h < 1.0) break;
		d += h * 0.5;
		pos += dir * h * 0.5; 
	}
	if (h > WATER_WAVE_AMP) return t;

	if (d < t && pos.z < 0.0 && pos.z > -559.2 && pos.x > 0.0 && pos.x < 549.6) 
	{
		float eps = 1.0;
		t = d;
		hitWorldSpace = pos;
		float dx = getWaterWaveHeight(hitWorldSpace - vec3(eps,0,0)) - getWaterWaveHeight(hitWorldSpace + vec3(eps,0,0));
		float dy = eps * 2.0; // (the water wave height is a function of x and z, not dependent on y)
		float dz = getWaterWaveHeight(hitWorldSpace - vec3(0,0,eps)) - getWaterWaveHeight(hitWorldSpace + vec3(0,0,eps));
		
		hitNormal = vec3(dx,dy,dz);
		hitEmission = vec3(0);
		hitColor = WATER_COLOR;
		hitType = REFR;
	}

	return t;
}


//-----------------------------------------------------------------------------------------------------------------------------
vec3 CalculateRadiance( out vec3 objectNormal, out vec3 objectColor, out float objectID, out float pixelSharpness )
//-----------------------------------------------------------------------------------------------------------------------------
{
        Quad light = quads[0];

	vec3 accumCol = vec3(0);
        vec3 mask = vec3(1);
	vec3 reflectionMask = vec3(1);
	vec3 reflectionRayOrigin = vec3(0);
	vec3 reflectionRayDirection = vec3(0);
	vec3 diffuseBounceMask = vec3(1);
	vec3 diffuseBounceRayOrigin = vec3(0);
	vec3 diffuseBounceRayDirection = vec3(0);
        vec3 n, nl, x;
	
	float t = INFINITY;
	float nc, nt, ratioIoR, Re, Tr;
	float weight;
	float thickness = 0.01; // 0.02
	float previousObjectID;

	int reflectionBounces = -1;
	int diffuseCount = 0;
	int previousIntersecType = -100;
	hitType = -100;

	int bounceIsSpecular = TRUE;
	int sampleLight = FALSE;
	int checkWater = TRUE;
	int rayEnteredWater = FALSE;
	int willNeedReflectionRay = FALSE;
	int isReflectionTime = FALSE;
	int reflectionNeedsToBeSharp = FALSE;
	int willNeedDiffuseBounceRay = FALSE;
	int isDiffuseBounceTime = FALSE;


	for (int bounces = 0; bounces < 10; bounces++)
	{
		if (isReflectionTime == TRUE)
			reflectionBounces++;

		previousIntersecType = hitType;
		previousObjectID = hitObjectID;

		t = SceneIntersect(checkWater);
		checkWater = FALSE;

		
		if (t == INFINITY)
		{
			// this makes the mirror box edges sharp and Cornell box edges sharp against the black background
			if (bounceIsSpecular == TRUE && isReflectionTime == FALSE)
				pixelSharpness = 1.0;

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
				diffuseCount = 0;
				continue;
			}
			
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
			{
				pixelSharpness = 1.0;
			}

			if (isReflectionTime == TRUE && bounceIsSpecular == TRUE)
			{
				objectNormal += nl;
				//objectColor = hitColor;
				objectID += hitObjectID;
			}

			if (bounceIsSpecular == TRUE || sampleLight == TRUE)
				accumCol += mask * hitEmission;

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
				diffuseCount = 0;
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
				diffuseCount = 0;
				continue;
			}

			break;
		}
		

		
                if (hitType == DIFF) // Ideal DIFFUSE reflection
		{

			if (rayEnteredWater == FALSE)
				mask *= hitColor;
			else
			{
				rayEnteredWater = FALSE;
				mask *= exp(log(WATER_COLOR) * thickness * t); 
			}

			diffuseCount++;

			bounceIsSpecular = FALSE;

			rayOrigin = x + nl * uEPS_intersect;
                        
			if (diffuseCount == 1)
			{
				diffuseBounceMask = mask;
				diffuseBounceRayOrigin = rayOrigin;
				diffuseBounceRayDirection = randomCosWeightedDirectionInHemisphere(nl);
				willNeedDiffuseBounceRay = TRUE;
			}
                        
			rayDirection = sampleQuadLight(x, nl, quads[0], weight);
			mask *= weight;
			sampleLight = TRUE;
			continue;
                        
		} // end if (hitType == DIFF)
		
                if (hitType == SPEC)  // Ideal SPECULAR reflection
		{
			if (rayEnteredWater == FALSE)
				mask *= hitColor;
			else
			{
				mask *= exp(log(WATER_COLOR) * thickness * t);
			}

			rayDirection = reflect(rayDirection, nl);
			rayOrigin = x + nl * uEPS_intersect;

			if (bounces == 0)
				checkWater = TRUE;
			
			continue;
		}

		if (hitType == REFR)  // Ideal dielectric REFRACTION
		{
			nc = 1.0; // IOR of Air
			nt = 1.33; // IOR of Water
			Re = calcFresnelReflectance(rayDirection, n, nc, nt, ratioIoR);
			Tr = 1.0 - Re;

			if (Re == 1.0)
			{
				rayDirection = reflect(rayDirection, nl);
				rayOrigin = x + nl * uEPS_intersect;
				continue;
			}

			if (bounces == 0 || (bounces == 1 && hitObjectID != objectID && bounceIsSpecular == TRUE))
			{
				reflectionMask = mask * Re;
				reflectionRayDirection = reflect(rayDirection, nl); // reflect ray from surface
				reflectionRayOrigin = x + nl * uEPS_intersect;
				willNeedReflectionRay = TRUE;
			}

			// transmit ray through surface	
			rayEnteredWater = TRUE;

			// is ray leaving a solid object from the inside? 
			// If so, attenuate ray color with object color by how far ray has travelled through the medium
			if (distance(n, nl) > 0.1)
			{
				rayEnteredWater = FALSE;
				mask *= exp(log(WATER_COLOR) * thickness * t);
			}

			mask *= Tr;
			
			rayDirection = refract(rayDirection, nl, ratioIoR);
			rayOrigin = x - nl * uEPS_intersect;

			continue;
			
		} // end if (hitType == REFR)
		
	} // end for (int bounces = 0; bounces < 10; bounces++)
	
	
	return max(vec3(0), accumCol); // prevents black spot artifacts appearing in the water 
	     
}


//-----------------------------------------------------------------------
void SetupScene(void)
//-----------------------------------------------------------------------
{
	vec3 z  = vec3(0);// No color value, Black        
	vec3 L1 = vec3(1.0, 0.7, 0.38) * 15.0;// Bright Yellowish light
		    // 0.736507, 0.642866, 0.210431  Original values
	
	quads[0] = Quad( vec3( 0.0,-1.0, 0.0), vec3(213.0, 548.0,-332.0), vec3(343.0, 548.0,-332.0), vec3(343.0, 548.0,-227.0), vec3(213.0, 548.0,-227.0), L1, z, LIGHT);// Area Light Rectangle in ceiling
	
	boxes[0] = Box( vec3(-82.0,-170.0, -80.0), vec3(82.0,170.0, 80.0), z, vec3(1), SPEC);// Tall Mirror Box Left
	boxes[1] = Box( vec3(-86.0, -85.0, -80.0), vec3(86.0, 85.0, 80.0), z, vec3(1), DIFF);// Short Diffuse Box Right
	boxes[2] = Box( vec3(0, 0,-559.2), vec3(549.6, 548.8, 0), z, vec3(1), DIFF);// the Cornell Box interior 
}	



// tentFilter from Peter Shirley's 'Realistic Ray Tracing (2nd Edition)' book, pg. 60		
float tentFilter(float x)
{
	return (x < 0.5) ? sqrt(2.0 * x) - 1.0 : 1.0 - sqrt(2.0 - (2.0 * x));
}


void main( void )
{
        // not needed, three.js has a built-in uniform named cameraPosition
        //vec3 camPos   = vec3( uCameraMatrix[3][0],  uCameraMatrix[3][1],  uCameraMatrix[3][2]);
        
        vec3 camRight   = vec3( uCameraMatrix[0][0],  uCameraMatrix[0][1],  uCameraMatrix[0][2]);
        vec3 camUp      = vec3( uCameraMatrix[1][0],  uCameraMatrix[1][1],  uCameraMatrix[1][2]);
        vec3 camForward = vec3(-uCameraMatrix[2][0], -uCameraMatrix[2][1], -uCameraMatrix[2][2]);
        
        // calculate unique seed for rng() function
	seed = uvec2(uFrameCounter, uFrameCounter + 1.0) * uvec2(gl_FragCoord);
	// initialize rand() variables
	randNumber = 0.0; // the final randomly-generated number (range: 0.0 to 1.0)
	blueNoise = texelFetch(tBlueNoiseTexture, ivec2(mod(floor(gl_FragCoord.xy), 128.0)), 0).r;

	vec2 pixelOffset = vec2( tentFilter(rand()), tentFilter(rand()) );
	//pixelOffset *= 0.5;//uCameraIsMoving ? 0.5 : 1.0;

	// we must map pixelPos into the range -1.0 to +1.0
	vec2 pixelPos = ((gl_FragCoord.xy + vec2(0.5) + pixelOffset) / uResolution) * 2.0 - 1.0;

        vec3 rayDir = uUseOrthographicCamera ? camForward : 
					       normalize( pixelPos.x * camRight * uULen + pixelPos.y * camUp * uVLen + camForward );

        // depth of field
        vec3 focalPoint = uFocusDistance * rayDir;
        float randomAngle = rng() * TWO_PI; // pick random point on aperture
        float randomRadius = rng() * uApertureSize;
        vec3  randomAperturePos = ( cos(randomAngle) * camRight + sin(randomAngle) * camUp ) * sqrt(randomRadius);
        // point on aperture to focal point
        vec3 finalRayDir = normalize(focalPoint - randomAperturePos);
        
        rayOrigin = uUseOrthographicCamera ? cameraPosition + (camRight * pixelPos.x * uULen * 100.0) + (camUp * pixelPos.y * uVLen * 100.0) + randomAperturePos :
					     cameraPosition + randomAperturePos; 
	rayDirection = finalRayDir;
	

        SetupScene(); 

        // Edge Detection - don't want to blur edges where either surface normals change abruptly (i.e. room wall corners), objects overlap each other (i.e. edge of a foreground sphere in front of another sphere right behind it),
	// or an abrupt color variation on the same smooth surface, even if it has similar surface normals (i.e. checkerboard pattern). Want to keep all of these cases as sharp as possible - no blur filter will be applied.
	vec3 objectNormal, objectColor;
	float objectID = -INFINITY;
	float pixelSharpness = 0.0;
	
	// perform path tracing and get resulting pixel color
	vec4 currentPixel = vec4( vec3(CalculateRadiance(objectNormal, objectColor, objectID, pixelSharpness)), 0.0 );

	// if difference between normals of neighboring pixels is less than the first edge0 threshold, the white edge line effect is considered off (0.0)
	float edge0 = 0.2; // edge0 is the minimum difference required between normals of neighboring pixels to start becoming a white edge line
	// any difference between normals of neighboring pixels that is between edge0 and edge1 smoothly ramps up the white edge line brightness (smoothstep 0.0-1.0)
	float edge1 = 0.6; // once the difference between normals of neighboring pixels is >= this edge1 threshold, the white edge line is considered fully bright (1.0)
	float difference_Nx = fwidth(objectNormal.x);
	float difference_Ny = fwidth(objectNormal.y);
	float difference_Nz = fwidth(objectNormal.z);
	float normalDifference = smoothstep(edge0, edge1, difference_Nx) + smoothstep(edge0, edge1, difference_Ny) + smoothstep(edge0, edge1, difference_Nz);

	float objectDifference = min(fwidth(objectID), 1.0);

	float colorDifference = (fwidth(objectColor.r) + fwidth(objectColor.g) + fwidth(objectColor.b)) > 0.0 ? 1.0 : 0.0;
	// white-line debug visualization for normal difference
	//currentPixel.rgb += (rng() * 1.5) * vec3(normalDifference);
	// white-line debug visualization for object difference
	//currentPixel.rgb += (rng() * 1.5) * vec3(objectDifference);
	// white-line debug visualization for color difference
	//currentPixel.rgb += (rng() * 1.5) * vec3(colorDifference);
	// white-line debug visualization for all 3 differences
	//currentPixel.rgb += (rng() * 1.5) * vec3( clamp(max(normalDifference, max(objectDifference, colorDifference)), 0.0, 1.0) );
	
	vec4 previousPixel = texelFetch(tPreviousTexture, ivec2(gl_FragCoord.xy), 0);


	if (uCameraIsMoving) // camera is currently moving
	{
		previousPixel.rgb *= 0.6; // motion-blur trail amount (old image)
		currentPixel.rgb *= 0.4; // brightness of new image (noisy)

		previousPixel.a = 0.0;
	}
	else
	{
		previousPixel.rgb *= 0.9; // motion-blur trail amount (old image)
		currentPixel.rgb *= 0.1; // brightness of new image (noisy)
	}

	currentPixel.a = pixelSharpness;

	// check for all edges that are not light sources
	if (pixelSharpness < 1.01 && (colorDifference >= 1.0 || normalDifference >= 0.9 || objectDifference >= 1.0)) // all other edges
		currentPixel.a = pixelSharpness = 1.0;

	/* // makes light source edges (shape boundaries) more stable
	if (previousPixel.a == 1.01)
	{
		if (pixelSharpness > 0.0)
			currentPixel.a = 1.01;
		else currentPixel.a = 1.0;
	} */

	// makes sharp edges more stable
	if (previousPixel.a == 1.0)
		currentPixel.a = 1.0;
		
	// for dynamic scenes (to clear out old, dark, sharp pixel trails left behind from moving objects)
	if (previousPixel.a == 1.0 && rng() < 0.1)
		currentPixel.a = 0.0;
	
	pc_fragColor = vec4(previousPixel.rgb + currentPixel.rgb, currentPixel.a);
}
