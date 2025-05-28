precision highp float;
precision highp int;
precision highp sampler2D;

#include <pathtracing_uniforms_and_defines>

uniform vec3 uSunDirection;
uniform sampler2D tTriangleTexture;
uniform sampler2D tAABBTexture;
uniform sampler2D tAlbedoTextures[8]; // 8 = max number of diffuse albedo textures per model
uniform sampler2D tHDRTexture;
uniform float uSkyLightIntensity;
uniform float uSunLightIntensity;
uniform vec3 uSunColor;

// (1 / 2048 texture width)
#define INV_TEXTURE_WIDTH 0.00048828125

vec3 rayOrigin, rayDirection;
// recorded intersection data:
vec3 hitNormal, hitEmission, hitColor;
vec2 hitUV;
float hitObjectID = -INFINITY;
float hitOpacity;
int hitType = -100; 
int hitAlbedoTextureID;

struct Box { vec3 minCorner; vec3 maxCorner; vec3 emission; vec3 color; int type; };
Box box;

#include <pathtracing_random_functions>

#include <pathtracing_calc_fresnel_reflectance>

#include <pathtracing_sphere_intersect>

#include <pathtracing_box_intersect>

#include <pathtracing_boundingbox_intersect>

#include <pathtracing_bvhTriangle_intersect>


vec2 stackLevels[28];

//vec4 boxNodeData0 corresponds to .x = idTriangle,  .y = aabbMin.x, .z = aabbMin.y, .w = aabbMin.z
//vec4 boxNodeData1 corresponds to .x = idRightChild .y = aabbMax.x, .z = aabbMax.y, .w = aabbMax.z

void GetBoxNodeData(const in float i, inout vec4 boxNodeData0, inout vec4 boxNodeData1)
{
	// each bounding box's data is encoded in 2 rgba(or xyzw) texture slots 
	float ix2 = i * 2.0;
	// (ix2 + 0.0) corresponds to .x = idTriangle,  .y = aabbMin.x, .z = aabbMin.y, .w = aabbMin.z 
	// (ix2 + 1.0) corresponds to .x = idRightChild .y = aabbMax.x, .z = aabbMax.y, .w = aabbMax.z 

	ivec2 uv0 = ivec2( mod(ix2 + 0.0, 2048.0), (ix2 + 0.0) * INV_TEXTURE_WIDTH ); // data0
	ivec2 uv1 = ivec2( mod(ix2 + 1.0, 2048.0), (ix2 + 1.0) * INV_TEXTURE_WIDTH ); // data1
	
	boxNodeData0 = texelFetch(tAABBTexture, uv0, 0);
	boxNodeData1 = texelFetch(tAABBTexture, uv1, 0);
}


//-----------------------------------------------------------------------------------------------------------------------------------------------------------------------
float SceneIntersect( )
//-----------------------------------------------------------------------------------------------------------------------------------------------------------------------
{
	vec4 currentBoxNodeData0, nodeAData0, nodeBData0, tmpNodeData0;
	vec4 currentBoxNodeData1, nodeAData1, nodeBData1, tmpNodeData1;
	
	vec4 vd0, vd1, vd2, vd3, vd4, vd5, vd6, vd7;

	vec3 inverseDir = 1.0 / rayDirection;
	vec3 normal, n;

	vec2 currentStackData, stackDataA, stackDataB, tmpStackData;
	ivec2 uv0, uv1, uv2, uv3, uv4, uv5, uv6, uv7;

	float d;
	float t = INFINITY;
        float stackptr = 0.0;
	float id = 0.0;
	float tu, tv;
	float triangleID = 0.0;
	float triangleU = 0.0;
	float triangleV = 0.0;
	float triangleW = 0.0;

	int objectCount = 0;
	
	hitObjectID = -INFINITY;

	int skip = FALSE;
	int triangleLookupNeeded = FALSE;
	int isRayExiting = FALSE;


	///////////////////////////////////////////////////////////////////////////////////////////////////////
	// glTF
	///////////////////////////////////////////////////////////////////////////////////////////////////////

	GetBoxNodeData(stackptr, currentBoxNodeData0, currentBoxNodeData1);
	currentStackData = vec2(stackptr, BoundingBoxIntersect(currentBoxNodeData0.yzw, currentBoxNodeData1.yzw, rayOrigin, inverseDir));
	stackLevels[0] = currentStackData;
	skip = (currentStackData.y < t) ? TRUE : FALSE;

	while (true)
        {
		if (skip == FALSE) 
                {
                        // decrease pointer by 1 (0.0 is root level, 27.0 is maximum depth)
                        if (--stackptr < 0.0) // went past the root level, terminate loop
                                break;

                        currentStackData = stackLevels[int(stackptr)];
			
			if (currentStackData.y >= t)
				continue;
			
			GetBoxNodeData(currentStackData.x, currentBoxNodeData0, currentBoxNodeData1);
                }
		skip = FALSE; // reset skip
		
		if (currentBoxNodeData0.x < 0.0) // // < 0.0 signifies an inner node 
		{
			GetBoxNodeData(currentStackData.x + 1.0, nodeAData0, nodeAData1);
			GetBoxNodeData(currentBoxNodeData1.x, nodeBData0, nodeBData1);
			stackDataA = vec2(currentStackData.x + 1.0, BoundingBoxIntersect(nodeAData0.yzw, nodeAData1.yzw, rayOrigin, inverseDir));
			stackDataB = vec2(currentBoxNodeData1.x, BoundingBoxIntersect(nodeBData0.yzw, nodeBData1.yzw, rayOrigin, inverseDir));
			
			// first sort the branch node data so that 'a' is the smallest
			if (stackDataB.y < stackDataA.y)
			{
				tmpStackData = stackDataB;
				stackDataB = stackDataA;
				stackDataA = tmpStackData;

				tmpNodeData0 = nodeBData0;   tmpNodeData1 = nodeBData1;
				nodeBData0   = nodeAData0;   nodeBData1   = nodeAData1;
				nodeAData0   = tmpNodeData0; nodeAData1   = tmpNodeData1;
			} // branch 'b' now has the larger rayT value of 'a' and 'b'

			if (stackDataB.y < t) // see if branch 'b' (the larger rayT) needs to be processed
			{
				currentStackData = stackDataB;
				currentBoxNodeData0 = nodeBData0;
				currentBoxNodeData1 = nodeBData1;
				skip = TRUE; // this will prevent the stackptr from decreasing by 1
			}
			if (stackDataA.y < t) // see if branch 'a' (the smaller rayT) needs to be processed 
			{
				if (skip == TRUE) // if larger branch 'b' needed to be processed also,
					stackLevels[int(stackptr++)] = stackDataB; // cue larger branch 'b' for future round
							// also, increase pointer by 1
				
				currentStackData = stackDataA;
				currentBoxNodeData0 = nodeAData0; 
				currentBoxNodeData1 = nodeAData1;
				skip = TRUE; // this will prevent the stackptr from decreasing by 1
			}

			continue;
		} // end if (currentBoxNodeData0.x < 0.0) // inner node


		// else this is a leaf

		// each triangle's data is encoded in 8 rgba(or xyzw) texture slots
		
		id = 8.0 * currentBoxNodeData0.x;

		uv0 = ivec2( mod(id + 0.0, 2048.0), (id + 0.0) * INV_TEXTURE_WIDTH );
		uv1 = ivec2( mod(id + 1.0, 2048.0), (id + 1.0) * INV_TEXTURE_WIDTH );
		uv2 = ivec2( mod(id + 2.0, 2048.0), (id + 2.0) * INV_TEXTURE_WIDTH );
		
		vd0 = texelFetch(tTriangleTexture, uv0, 0);
		vd1 = texelFetch(tTriangleTexture, uv1, 0);
		vd2 = texelFetch(tTriangleTexture, uv2, 0);

		d = BVH_TriangleIntersect( vec3(vd0.xyz), vec3(vd0.w, vd1.xy), vec3(vd1.zw, vd2.x), rayOrigin, rayDirection, tu, tv );

		if (d < t)
		{
			t = d;
			triangleID = id;
			triangleU = tu;
			triangleV = tv;
			triangleLookupNeeded = TRUE;
		}
	      
        } // end while (TRUE)


	if (triangleLookupNeeded == TRUE)
	{
		uv0 = ivec2( mod(triangleID + 0.0, 2048.0), floor((triangleID + 0.0) * INV_TEXTURE_WIDTH) );
		uv1 = ivec2( mod(triangleID + 1.0, 2048.0), floor((triangleID + 1.0) * INV_TEXTURE_WIDTH) );
		uv2 = ivec2( mod(triangleID + 2.0, 2048.0), floor((triangleID + 2.0) * INV_TEXTURE_WIDTH) );
		uv3 = ivec2( mod(triangleID + 3.0, 2048.0), floor((triangleID + 3.0) * INV_TEXTURE_WIDTH) );
		uv4 = ivec2( mod(triangleID + 4.0, 2048.0), floor((triangleID + 4.0) * INV_TEXTURE_WIDTH) );
		uv5 = ivec2( mod(triangleID + 5.0, 2048.0), floor((triangleID + 5.0) * INV_TEXTURE_WIDTH) );
		uv6 = ivec2( mod(triangleID + 6.0, 2048.0), floor((triangleID + 6.0) * INV_TEXTURE_WIDTH) );
		uv7 = ivec2( mod(triangleID + 7.0, 2048.0), floor((triangleID + 7.0) * INV_TEXTURE_WIDTH) );
		
		vd0 = texelFetch(tTriangleTexture, uv0, 0);
		vd1 = texelFetch(tTriangleTexture, uv1, 0);
		vd2 = texelFetch(tTriangleTexture, uv2, 0);
		vd3 = texelFetch(tTriangleTexture, uv3, 0);
		vd4 = texelFetch(tTriangleTexture, uv4, 0);
		vd5 = texelFetch(tTriangleTexture, uv5, 0);
		vd6 = texelFetch(tTriangleTexture, uv6, 0);
		vd7 = texelFetch(tTriangleTexture, uv7, 0);

		// face normal for flat-shaded polygon look
		//hitNormal = ( cross(vec3(vd0.w, vd1.xy) - vec3(vd0.xyz), vec3(vd1.zw, vd2.x) - vec3(vd0.xyz)) );

		// interpolated normal using triangle intersection's uv's
		triangleW = 1.0 - triangleU - triangleV;
		hitNormal = (triangleW * vec3(vd2.yzw) + triangleU * vec3(vd3.xyz) + triangleV * vec3(vd3.w, vd4.xy));
		hitEmission = vec3(1, 0, 1); // use this if hitType will be LIGHT
		hitColor = vd6.yzw;
		hitOpacity = vd7.y;
		hitUV = triangleW * vec2(vd4.zw) + triangleU * vec2(vd5.xy) + triangleV * vec2(vd5.zw);
		hitType = int(vd6.x);
		hitAlbedoTextureID = int(vd7.x);
		hitObjectID = float(objectCount);
	}
	objectCount++;


	// GROUND Plane (thin, wide box that acts like ground plane)
	d = BoxIntersect( box.minCorner, box.maxCorner, rayOrigin, rayDirection, n, isRayExiting );
	if (d < t)
	{
		t = d;
		hitNormal = n;
		hitEmission = box.emission;
		hitColor = box.color;
		hitType = box.type;
		hitObjectID = float(objectCount);
	}
	
	

	return t;

} // end float SceneIntersect( )


vec3 Get_HDR_Color(vec3 rayDirection)
{
	vec2 sampleUV;
	sampleUV.x = atan(rayDirection.z, rayDirection.x) * ONE_OVER_TWO_PI + 0.5;
	sampleUV.y = asin(clamp(rayDirection.y, -1.0, 1.0)) * ONE_OVER_PI + 0.5;
	
	return texture( tHDRTexture, sampleUV ).rgb;
}

//-----------------------------------------------------------------------------------------------------------------------------
vec3 CalculateRadiance( out vec3 objectNormal, out vec3 objectColor, out float objectID, out float pixelSharpness )
//-----------------------------------------------------------------------------------------------------------------------------
{
	vec3 randVec = vec3(rand() * 2.0 - 1.0, rand() * 2.0 - 1.0, rand() * 2.0 - 1.0);

	vec3 accumCol = vec3(0.0);
	vec3 mask = vec3(1.0);
	vec3 reflectionMask = vec3(1);
	vec3 reflectionRayOrigin = vec3(0);
	vec3 reflectionRayDirection = vec3(0);
	vec3 n, nl, x;
	vec3 firstX = vec3(0);

	float hitDistance;
	float nc, nt, ratioIoR, Re, Tr;
	float weight;
	float t = INFINITY;
	float epsIntersect = 0.01;
	float previousObjectID;
	
	int reflectionBounces = -1;
	int diffuseCount = 0;
	int previousIntersecType = -100;
	hitType = -100;
	
	int bounceIsSpecular = TRUE;
	int sampleLight = FALSE;
	int willNeedReflectionRay = FALSE;
	int isReflectionTime = FALSE;
	int reflectionNeedsToBeSharp = FALSE;


    	for (int bounces = 0; bounces < 5; bounces++)
	{
		if (isReflectionTime == TRUE)
			reflectionBounces++;

		previousIntersecType = hitType;
		previousObjectID = hitObjectID;

		t = SceneIntersect();

		
		if (t == INFINITY)
		{
			// ray hits sky first
			if (bounces == 0)
			{
				pixelSharpness = 1.0;

				accumCol += Get_HDR_Color(rayDirection);
				break;
			}

			// if ray bounced off of diffuse material and hits sky
			if (previousIntersecType == DIFF)
			{
				if (sampleLight == TRUE)
					accumCol += mask * uSunColor * uSunLightIntensity * 0.5;
				else
					accumCol += mask * Get_HDR_Color(rayDirection) * uSkyLightIntensity * 0.5;
			}

			// if ray bounced off of glass and hits sky
			if (previousIntersecType == REFR)
			{
				if (diffuseCount == 0) // camera looking through glass, hitting the sky
				{
					pixelSharpness = 1.0;
					mask *= Get_HDR_Color(rayDirection);
				}	
				else if (sampleLight == TRUE) // sun rays going through glass, hitting another surface
					mask *= uSunColor * uSunLightIntensity;
				else  // sky rays going through glass, hitting another surface
					mask *= Get_HDR_Color(rayDirection) * uSkyLightIntensity;

				if (bounceIsSpecular == TRUE) // prevents sun 'fireflies' on diffuse surfaces
					accumCol += mask;
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
				continue;
			}
			// reached a light, so we can exit
			break;

		} // end if (t == INFINITY)


		/* // other lights, like houselights, could be added to the scene
		// if we reached light material, don't spawn any more rays
		if (hitType == LIGHT)
		{
	    		accumCol = mask * hitEmission * 0.5;
			break;
		} */

		/* // Since we want fast direct sunlight caustics through windows, we don't use the following early out
		if (sampleLight == TRUE)
			break; */

		// useful data
		n = normalize(hitNormal);
		nl = dot(n, rayDirection) < 0.0 ? n : -n;
		x = rayOrigin + rayDirection * t;

		if (isReflectionTime == FALSE && diffuseCount == 0)// && hitObjectID != previousObjectID)
		{
			objectNormal += n;
			objectColor += hitColor;
			objectID += hitObjectID;
		}
		if (reflectionNeedsToBeSharp == TRUE && reflectionBounces == 0)
		{
			objectNormal += n;
			//objectColor += hitColor;
			//objectID += hitObjectID;
		}



		if (hitType == DIFF) // Ideal DIFFUSE reflection
		{
			// if (diffuseCount == 0)
			// 	objectColor = hitColor;

			diffuseCount++;

			mask *= hitColor;
	    		bounceIsSpecular = FALSE;

			if (diffuseCount == 1 && rand() < 0.5)
			{
				mask *= 2.0;
				// this branch gathers color bleeding / caustics from other surfaces hit in the future
				// choose random Diffuse sample vector
				rayDirection = randomCosWeightedDirectionInHemisphere(nl);
				rayOrigin = x + nl * epsIntersect;

				continue;
			}
			
			// this branch acts like a traditional shadowRay, checking for direct light from the Sun..
			// if it has a clear path and hits the Sun on the next bounce, sunlight is gathered, otherwise returns black (shadow)
			rayDirection = normalize(uSunDirection + (randVec * 0.01));
			rayOrigin = x + nl * epsIntersect;

			weight = max(0.0, dot(rayDirection, nl));
			mask *= diffuseCount == 1 ? 2.0 : 1.0;
			mask *= weight;
			
			sampleLight = TRUE;
			continue;
			
		} // end if (hitType == DIFF)

		if (hitType == SPEC)  // Ideal SPECULAR reflection
		{
			mask *= hitColor;

			rayDirection = reflect(rayDirection, nl);
			rayOrigin = x + rayDirection * epsIntersect;

			//bounceIsSpecular = TRUE; // turn on mirror caustics
			continue;
		}

		if (hitType == REFR)  // Ideal dielectric REFRACTION
		{
			nc = 1.0; // IOR of Air
			nt = 1.5; // IOR of common Glass
			Re = calcFresnelReflectance(rayDirection, n, nc, nt, ratioIoR);
			Tr = 1.0 - Re;

			if (bounces == 0)// || (bounces == 1 && hitObjectID != objectID && bounceIsSpecular == TRUE))
			{
				reflectionMask = mask * Re;
				reflectionRayDirection = reflect(rayDirection, nl); // reflect ray from surface
				reflectionRayOrigin = x + nl * epsIntersect;
				willNeedReflectionRay = TRUE;
				//reflectionNeedsToBeSharp = TRUE;
			}

			if (Re == 1.0)
			{
				rayDirection = reflect(rayDirection, nl);
				rayOrigin = x + nl * uEPS_intersect;
				continue;
			}
			
			// transmit ray through surface
			
			mask *= Tr;
			mask *= hitColor;
			
			rayDirection = rayDirection; // TODO using rayDirection instead of refracted direction, 
			// because going through common Glass makes everything spherical from up close...
			rayOrigin = x + rayDirection * epsIntersect;

			if (diffuseCount < 2)
				bounceIsSpecular = TRUE;

			continue;
			
		} // end if (hitType == REFR)

	} // end for (int bounces = 0; bounces < 5; bounces++)

	return max(vec3(0), accumCol);

} // end vec3 CalculateRadiance()


//-----------------------------------------------------------------------
void SetupScene(void)
//-----------------------------------------------------------------------
{
	// Add thin box for the ground (acts like ground plane)
	box = Box( vec3(-100000, -1, -100000), vec3(100000, 0, 100000), vec3(0), vec3(0.45), DIFF);
}


#include <pathtracing_main>