precision highp float;
precision highp int;
precision highp sampler2D;

uniform mat4 uShortBoxInvMatrix;
uniform mat4 uTallBoxInvMatrix;

#include <pathtracing_uniforms_and_defines>

#define N_QUADS 6
#define N_BOXES 2

//-----------------------------------------------------------------------

vec3 rayOrigin, rayDirection;
// recorded intersection data:
vec3 hitNormal, hitEmission, hitColor;
vec2 hitUV;
float hitObjectID;
int hitType;

struct Quad { vec3 normal; vec3 v0; vec3 v1; vec3 v2; vec3 v3; vec3 emission; vec3 color; int type; };
struct Box { vec3 minCorner; vec3 maxCorner; vec3 emission; vec3 color; int type; };

Quad quads[N_QUADS];
Box boxes[N_BOXES];


#include <pathtracing_random_functions>
		
#include <pathtracing_calc_fresnel_reflectance>

#include <pathtracing_quad_intersect>

#include <pathtracing_box_intersect>

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
float SceneIntersect( bool checkWater )
//--------------------------------------------------------------------------------------------------------
{
	vec3 rObjOrigin, rObjDirection;
	vec3 hitWorldSpace;
	vec3 normal;

        float d = INFINITY;
	float t = INFINITY;
	float waterWaveDepth;

	int objectCount = 0;
	
	bool isRayExiting = false;
	
	
	for (int i = 0; i < N_QUADS; i++)
        {
		d = QuadIntersect( quads[i].v0, quads[i].v1, quads[i].v2, quads[i].v3, rayOrigin, rayDirection, false );
		if (d < t)
		{
			t = d;
			hitNormal = normalize( quads[i].normal );
			hitEmission = quads[i].emission;
			hitColor = quads[i].color;
			hitType = quads[i].type;
			hitObjectID = float(objectCount);
		}
		objectCount++;
        }
	
	// TALL MIRROR BOX
	// transform ray into Tall Box's object space
	rObjOrigin = vec3( uTallBoxInvMatrix * vec4(rayOrigin, 1.0) );
	rObjDirection = vec3( uTallBoxInvMatrix * vec4(rayDirection, 0.0) );
	d = BoxIntersect( boxes[0].minCorner, boxes[0].maxCorner, rObjOrigin, rObjDirection, normal, isRayExiting );
	
	if (d < t)
	{	
		t = d;
		// transfom normal back into world space
		normal = normalize(normal);
		hitNormal = normalize(transpose(mat3(uTallBoxInvMatrix)) * normal);
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
		normal = normalize(normal);
		hitNormal = normalize(transpose(mat3(uShortBoxInvMatrix)) * normal);
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

	if ( !checkWater )
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
		
		hitNormal = normalize(vec3(dx,dy,dz));
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
        Quad light = quads[5];

	vec3 accumCol = vec3(0);
        vec3 mask = vec3(1);
        vec3 n, nl, x;
	vec3 dirToLight;
	vec3 tdir;
	
	float t = INFINITY;
	float nc, nt, ratioIoR, Re, Tr;
	float P, RP, TP;
	float weight;
	float thickness = 0.01; // 0.02
	float hitObjectID;

	int diffuseCount = 0;
	int previousIntersecType = -100;
	hitType = -100;

	bool bounceIsSpecular = true;
	bool sampleLight = false;
	bool checkWater = true;
	bool rayEnteredWater = false;


	for (int bounces = 0; bounces < 5; bounces++)
	{
		previousIntersecType = hitType;

		t = SceneIntersect(checkWater);
		checkWater = false;

		
		if (t == INFINITY)
			break;

		// useful data 
		n = normalize(hitNormal);
                nl = dot(n, rayDirection) < 0.0 ? n : normalize(-n);
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
			else pixelSharpness = 0.0;

			if (sampleLight || bounceIsSpecular)
				accumCol = mask * hitEmission;
			// reached a light, so we can exit
			break;
		}
		

		// if we get here and sampleLight is still true, shadow ray failed to find a light source
		if (sampleLight) 	
			break;
		

		
                if (hitType == DIFF) // Ideal DIFFUSE reflection
		{

			if (!rayEnteredWater)
				mask *= hitColor;
			else
			{
				rayEnteredWater = false;
				mask *= exp(log(WATER_COLOR) * thickness * t); 
			}

			diffuseCount++;

			bounceIsSpecular = false;

			if (diffuseCount == 1 && rand() < 0.4)
			{
				mask /= 0.4;
				// choose random Diffuse sample vector
				rayDirection = randomCosWeightedDirectionInHemisphere(nl);
				rayOrigin = x + nl * uEPS_intersect;
				continue;
			}
                        
			dirToLight = sampleQuadLight(x, nl, quads[5], weight);
			mask /= diffuseCount == 1 ? 0.6 : 1.0;
			mask *= weight;

			rayDirection = dirToLight;
			rayOrigin = x + nl * uEPS_intersect;

			sampleLight = true;
			continue;
                        
		} // end if (hitType == DIFF)
		
                if (hitType == SPEC)  // Ideal SPECULAR reflection
		{
			if (!rayEnteredWater)
				mask *= hitColor;
			else
			{
				mask *= exp(log(WATER_COLOR) * thickness * t);
			}

			rayDirection = reflect(rayDirection, nl);
			rayOrigin = x + nl * uEPS_intersect;

			if (bounces == 0)
				checkWater = true;
			
			continue;
		}

		if (hitType == REFR)  // Ideal dielectric REFRACTION
		{
			if (diffuseCount == 0)
				pixelSharpness = -1.0;

			nc = 1.0; // IOR of Air
			nt = 1.33; // IOR of Water
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
			rayEnteredWater = true;

			// is ray leaving a solid object from the inside? 
			// If so, attenuate ray color with object color by how far ray has travelled through the medium
			if (distance(n, nl) > 0.1)
			{
				rayEnteredWater = false;
				mask *= exp(log(WATER_COLOR) * thickness * t);
			}

			mask *= TP;
			
			tdir = refract(rayDirection, nl, ratioIoR);
			rayDirection = tdir;
			rayOrigin = x - nl * uEPS_intersect;

			continue;
			
		} // end if (hitType == REFR)
		
	} // end for (int bounces = 0; bounces < 5; bounces++)
	
	
	return max(vec3(0), accumCol); // prevents black spot artifacts appearing in the water 
	     
}


//-----------------------------------------------------------------------
void SetupScene(void)
//-----------------------------------------------------------------------
{
	vec3 z  = vec3(0);// No color value, Black        
	vec3 L1 = vec3(1.0, 0.7, 0.38) * 15.0;// Bright Yellowish light
		    // 0.736507, 0.642866, 0.210431  Original values
	
	quads[0] = Quad( vec3( 0.0, 0.0, 1.0), vec3(  0.0,   0.0,-559.2), vec3(549.6,   0.0,-559.2), vec3(549.6, 548.8,-559.2), vec3(  0.0, 548.8,-559.2),  z, vec3(1),  DIFF);// Back Wall
	quads[1] = Quad( vec3( 1.0, 0.0, 0.0), vec3(  0.0,   0.0,   0.0), vec3(  0.0,   0.0,-559.2), vec3(  0.0, 548.8,-559.2), vec3(  0.0, 548.8,   0.0),  z, vec3(0.7, 0.12,0.05),  DIFF);// Left Wall Red
	quads[2] = Quad( vec3(-1.0, 0.0, 0.0), vec3(549.6,   0.0,-559.2), vec3(549.6,   0.0,   0.0), vec3(549.6, 548.8,   0.0), vec3(549.6, 548.8,-559.2),  z, vec3(0.2, 0.4, 0.36),  DIFF);// Right Wall Green
	quads[3] = Quad( vec3( 0.0,-1.0, 0.0), vec3(  0.0, 548.8,-559.2), vec3(549.6, 548.8,-559.2), vec3(549.6, 548.8,   0.0), vec3(  0.0, 548.8,   0.0),  z, vec3(1),  DIFF);// Ceiling
	quads[4] = Quad( vec3( 0.0, 1.0, 0.0), vec3(  0.0,   0.0,   0.0), vec3(549.6,   0.0,   0.0), vec3(549.6,   0.0,-559.2), vec3(  0.0,   0.0,-559.2),  z, vec3(1),  DIFF);// Floor
	quads[5] = Quad( vec3( 0.0,-1.0, 0.0), vec3(213.0, 548.0,-332.0), vec3(343.0, 548.0,-332.0), vec3(343.0, 548.0,-227.0), vec3(213.0, 548.0,-227.0), L1,       z, LIGHT);// Area Light Rectangle in ceiling
	
	boxes[0]  = Box( vec3(-82.0,-170.0, -80.0), vec3(82.0,170.0, 80.0), z, vec3(1), SPEC);// Tall Mirror Box Left
	boxes[1]  = Box( vec3(-86.0, -85.0, -80.0), vec3(86.0, 85.0, 80.0), z, vec3(1), DIFF);// Short Diffuse Box Right
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
	counter = -1.0; // will get incremented by 1 on each call to rand()
	channel = 0; // the final selected color channel to use for rand() calc (range: 0 to 3, corresponds to R,G,B, or A)
	randNumber = 0.0; // the final randomly-generated number (range: 0.0 to 1.0)
	randVec4 = vec4(0); // samples and holds the RGBA blueNoise texture value for this pixel
	randVec4 = texelFetch(tBlueNoiseTexture, ivec2(mod(gl_FragCoord.xy + floor(uRandomVec2 * 256.0), 256.0)), 0);
	
	vec2 pixelOffset = vec2( tentFilter(rng()), tentFilter(rng()) ) * 0.5;

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

	edge0 = 0.0;
	edge1 = 0.5;
	float difference_obj = abs(dFdx(objectID)) > 0.0 ? 1.0 : 0.0;
	difference_obj += abs(dFdy(objectID)) > 0.0 ? 1.0 : 0.0;
	float objectDifference = smoothstep(edge0, edge1, difference_obj);

	float difference_col = length(dFdx(objectColor)) > 0.0 ? 1.0 : 0.0;
	difference_col += length(dFdy(objectColor)) > 0.0 ? 1.0 : 0.0;
	float colorDifference = smoothstep(edge0, edge1, difference_col);
	// edge detector (normal and object differences) white-line debug visualization
	//currentPixel.rgb += 1.0 * vec3(max(normalDifference, objectDifference));
	
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

	currentPixel.a = 0.0;
	if (colorDifference >= 1.0 || normalDifference >= 1.0 || objectDifference >= 1.0)
		pixelSharpness = 1.01;
	

	// Eventually, all edge-containing pixels' .a (alpha channel) values will converge to 1.01, which keeps them from getting blurred by the box-blur filter, thus retaining sharpness.
	if (previousPixel.a == 1.01)
		currentPixel.a = 1.01;
	// for dynamic scenes
	if (previousPixel.a == 1.01 && rng() < 0.01)
		currentPixel.a = 1.0;
	if (previousPixel.a == -1.0)
		currentPixel.a = 0.0;

	if (pixelSharpness == 1.01)
		currentPixel.a = 1.01;
	if (pixelSharpness == -1.0)
		currentPixel.a = -1.0;

	
	pc_fragColor = vec4(previousPixel.rgb + currentPixel.rgb, currentPixel.a);
}
