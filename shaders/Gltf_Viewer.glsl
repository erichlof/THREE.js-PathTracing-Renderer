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

struct Ray { vec3 origin; vec3 direction; };
struct Plane { vec4 pla; vec3 emission; vec3 color; int type; };
struct Intersection { vec3 normal; vec3 emission; vec3 color; vec2 uv; int type; int albedoTextureID; float opacity;};

Plane plane;

#include <pathtracing_random_functions>
#include <pathtracing_calc_fresnel_reflectance>
#include <pathtracing_sphere_intersect>
#include <pathtracing_plane_intersect>
#include <pathtracing_boundingbox_intersect>
#include <pathtracing_bvhTriangle_intersect>

struct StackLevelData
{
	float id;
	float rayT;
} stackLevels[24];

struct BoxNode
{
	float branch_A_Index;
	vec3 minCorner;
	float branch_B_Index;
	vec3 maxCorner;
};

BoxNode GetBoxNode(const in float i)
{
	// each bounding box's data is encoded in 2 rgba(or xyzw) texture slots 
	float iX2 = (i * 2.0);
	// (iX2 + 0.0) corresponds to .x: idLeftChild, .y: aabbMin.x, .z: aabbMin.y, .w: aabbMin.z 
	// (iX2 + 1.0) corresponds to .x: idRightChild .y: aabbMax.x, .z: aabbMax.y, .w: aabbMax.z 

	ivec2 uv0 = ivec2( mod(iX2 + 0.0, 2048.0), floor((iX2 + 0.0) * INV_TEXTURE_WIDTH) );
	ivec2 uv1 = ivec2( mod(iX2 + 1.0, 2048.0), floor((iX2 + 1.0) * INV_TEXTURE_WIDTH) );
	
	vec4 aabbNodeData0 = texelFetch(tAABBTexture, uv0, 0);
	vec4 aabbNodeData1 = texelFetch(tAABBTexture, uv1, 0);
	
	BoxNode BN = BoxNode( aabbNodeData0.x,
			      aabbNodeData0.yzw,
			      aabbNodeData1.x,
			      aabbNodeData1.yzw );

	return BN;
}

//-----------------------------------------------------------------------------------------------------------------------------------------------------------------------
float SceneIntersect( Ray r, inout Intersection intersec )
//-----------------------------------------------------------------------------------------------------------------------------------------------------------------------
{
	float d = INFINITY;
	float t = INFINITY;

	// AABB BVH Intersection variables
	vec4 aabbNodeData0, aabbNodeData1, aabbNodeData2;
	vec4 vd0, vd1, vd2, vd3, vd4, vd5, vd6, vd7;
	vec3 inverseDir = 1.0 / r.direction;
	vec3 n = vec3(0);
	ivec2 uv0, uv1, uv2, uv3, uv4, uv5, uv6, uv7;

	float stackptr = 0.0;
	float id = 0.0;
	float tu, tv;
	float triangleID = 0.0;
	float triangleU = 0.0;
	float triangleV = 0.0;
	float triangleW = 0.0;

	bool skip = false;
	bool triangleLookupNeeded = false;

	BoxNode currentBoxNode, nodeA, nodeB, tnp;
	StackLevelData currentStackData, slDataA, slDataB, tmp;
	
	// GROUND Plane
    d = PlaneIntersect( plane.pla, r );
    if (d < t)
    {
        t = d;
        intersec.normal = normalize(plane.pla.xyz);
        intersec.emission = plane.emission;
        intersec.color = plane.color;
        intersec.type = plane.type;
    }

	///////////////////////////////////////////////////////////////////////////////////////////////////////
	// glTF
	///////////////////////////////////////////////////////////////////////////////////////////////////////

	currentBoxNode = GetBoxNode(stackptr);
	currentStackData = StackLevelData(stackptr, BoundingBoxIntersect(currentBoxNode.minCorner, currentBoxNode.maxCorner, r.origin, inverseDir));
	stackLevels[0] = currentStackData;

	while(true)
	{
		if (currentStackData.rayT < t)
        	{
			if (currentBoxNode.branch_A_Index >= 0.0) // signifies this is a branch
			{
				nodeA = GetBoxNode(currentBoxNode.branch_A_Index);
				nodeB = GetBoxNode(currentBoxNode.branch_B_Index);
				slDataA = StackLevelData(currentBoxNode.branch_A_Index, BoundingBoxIntersect(nodeA.minCorner, nodeA.maxCorner, r.origin, inverseDir));
				slDataB = StackLevelData(currentBoxNode.branch_B_Index, BoundingBoxIntersect(nodeB.minCorner, nodeB.maxCorner, r.origin, inverseDir));

				// first sort the branch node data so that 'a' is the smallest
				if (slDataB.rayT < slDataA.rayT)
				{
					tmp = slDataB;
					slDataB = slDataA;
					slDataA = tmp;

					tnp = nodeB;
					nodeB = nodeA;
					nodeA = tnp;
				} // branch 'b' now has the larger rayT value of 'a' and 'b'

				if (slDataB.rayT < t) // see if branch 'b' (the larger rayT) needs to be processed
				{
					currentStackData = slDataB;
					currentBoxNode = nodeB;
					skip = true; // this will prevent the stackptr from decreasing by 1
				}

				if (slDataA.rayT < t) // see if branch 'a' (the smaller rayT) needs to be processed
				{
					if (skip == true) // if larger branch 'b' needed to be processed also,
						stackLevels[int(stackptr++)] = slDataB; // cue larger branch 'b' for future round
												// also, increase pointer by 1

					currentStackData = slDataA;
					currentBoxNode = nodeA;
					skip = true; // this will prevent the stackptr from decreasing by 1
				}
			}
			else //if (currentBoxNode.branch_A_Index < 0.0) //  < 0.0 signifies a leaf node
			{
				// each triangle's data is encoded in 8 rgba(or xyzw) texture slots
				id = 8.0 * (-currentBoxNode.branch_A_Index - 1.0);

				uv0 = ivec2( mod(id + 0.0, 2048.0), floor((id + 0.0) * INV_TEXTURE_WIDTH) );
				uv1 = ivec2( mod(id + 1.0, 2048.0), floor((id + 1.0) * INV_TEXTURE_WIDTH) );
				uv2 = ivec2( mod(id + 2.0, 2048.0), floor((id + 2.0) * INV_TEXTURE_WIDTH) );
				
				vd0 = texelFetch(tTriangleTexture, uv0, 0);
				vd1 = texelFetch(tTriangleTexture, uv1, 0);
				vd2 = texelFetch(tTriangleTexture, uv2, 0);

				d = BVH_TriangleIntersect( vec3(vd0.xyz), vec3(vd0.w, vd1.xy), vec3(vd1.zw, vd2.x), r, tu, tv );

				if (d < t && d > 0.0)
				{
					t = d;
					triangleID = id;
					triangleU = tu;
					triangleV = tv;
					triangleLookupNeeded = true;
				}
			}
		} // end if (currentStackData.rayT < t)

		if (skip == false)
		{
			// decrease pointer by 1 (0.0 is root level, 24.0 is maximum depth)
			if (--stackptr < 0.0) // went past the root level, terminate loop
				break;
			currentStackData = stackLevels[int(stackptr)];
			currentBoxNode = GetBoxNode(currentStackData.id);
		}
		skip = false; // reset skip

	} // end while (true)


	if (triangleLookupNeeded)
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
		//intersec.normal = normalize( cross(vec3(vd0.w, vd1.xy) - vec3(vd0.xyz), vec3(vd1.zw, vd2.x) - vec3(vd0.xyz)) );

		// interpolated normal using triangle intersection's uv's
		triangleW = 1.0 - triangleU - triangleV;
		intersec.normal = normalize(triangleW * vec3(vd2.yzw) + triangleU * vec3(vd3.xyz) + triangleV * vec3(vd3.w, vd4.xy));
		intersec.emission = vec3(1, 0, 1); // use this if intersec.type will be LIGHT
		intersec.color = vd6.yzw;
		intersec.opacity = vd7.y;
		intersec.uv = triangleW * vec2(vd4.zw) + triangleU * vec2(vd5.xy) + triangleV * vec2(vd5.zw);
		intersec.type = int(vd6.x);
		intersec.albedoTextureID = int(vd7.x);
	}

	return t;

} // end float SceneIntersect( Ray r, inout Intersection intersec )


vec3 Get_HDR_Color(Ray r)
{
	vec2 sampleUV;
	sampleUV.x = atan(r.direction.z, r.direction.x) * ONE_OVER_TWO_PI + 0.5;
	sampleUV.y = asin(clamp(r.direction.y, -1.0, 1.0)) * ONE_OVER_PI + 0.5;
	vec4 texData = texture( tHDRTexture, sampleUV );
	texData = RGBEToLinear(texData);
	
	// tone mapping
	vec3 texColor = ACESFilmicToneMapping(texData.rgb);

	return texColor;
}

//-----------------------------------------------------------------------
vec3 CalculateRadiance(Ray r, vec3 sunDirection)
//-----------------------------------------------------------------------
{
	vec3 randVec = vec3(rand() * 2.0 - 1.0, rand() * 2.0 - 1.0, rand() * 2.0 - 1.0);

	Intersection intersec;
	vec3 accumCol = vec3(0.0);
	vec3 mask = vec3(1.0);
	vec3 n, nl, x;
	vec3 firstX = vec3(0);
	vec3 tdir;

	float hitDistance;
	float nc, nt, ratioIoR, Re, Tr;
	float weight;
	float t = INFINITY;
	float epsIntersect = 0.01;
	
	int previousIntersecType = -100;
	int diffuseCount = 0;

	bool skyHit = false;
	bool bounceIsSpecular = true;
	bool sampleSunLight = false;

    	for (int bounces = 0; bounces < 4; bounces++)
	{

		float t = SceneIntersect(r, intersec);

		// ray hits sky first
		if (t == INFINITY && bounces == 0 )
		{
			accumCol = Get_HDR_Color(r);

			break;	
		}

        	// if ray bounced off of diffuse material and hits sky
		if (t == INFINITY && previousIntersecType == DIFF)
		{
			if (sampleSunLight)
				accumCol = mask * uSunColor * uSunLightIntensity;
			else
				accumCol = mask * Get_HDR_Color(r) * uSkyLightIntensity;

			break;
		}

        	// if ray bounced off of glass and hits sky
		if (t == INFINITY && previousIntersecType == REFR)
		{
            		if (diffuseCount == 0) // camera looking through glass, hitting the sky
			    	mask *= Get_HDR_Color(r);
			else if (sampleSunLight) // sun rays going through glass, hitting another surface
				mask *= uSunColor * uSunLightIntensity;
			else  // sky rays going through glass, hitting another surface
                		mask *= Get_HDR_Color(r) * uSkyLightIntensity;

			if (bounceIsSpecular) // prevents sun 'fireflies' on diffuse surfaces
                		accumCol = mask;

			break;
		}

        	// other lights, like houselights, could be added to the scene
		// if we reached light material, don't spawn any more rays
		if (intersec.type == LIGHT)
		{
            		accumCol = mask * intersec.emission;

			break;
		}

		// useful data
		vec3 n = normalize(intersec.normal);
        	vec3 nl = dot(n,r.direction) <= 0.0 ? normalize(n) : normalize(-n);
		vec3 x = r.origin + r.direction * t;

        	if (intersec.type == DIFF) // Ideal DIFFUSE reflection
        	{
			diffuseCount++;
			previousIntersecType = DIFF;

			mask *= intersec.color;
            		bounceIsSpecular = false;

			/*
			// Russian Roulette
			float p = max(mask.r, max(mask.g, mask.b));
			if (bounces > 0)
			{
				if (rand() < p)
                    			mask *= 1.0 / p;
                		else
                    			break;
			}
			*/

			if (diffuseCount == 1 && rand() < 0.5)
			{
				// this branch gathers color bleeding / caustics from other surfaces hit in the future
				// choose random Diffuse sample vector
				r = Ray( x, randomCosWeightedDirectionInHemisphere(nl) );
				r.origin += r.direction * epsIntersect;

				continue;
			}
			else
			{
				// this branch acts like a traditional shadowRay, checking for direct light from the Sun..
				// if it has a clear path and hits the Sun on the next bounce, sunlight is gathered, otherwise returns black (shadow)
				r = Ray( x, normalize(sunDirection + (randVec * 0.01)) );
				r.origin += nl * epsIntersect;
				weight = dot(r.direction, nl);
				if (weight < 0.01)
					break;

				mask *= weight;
				sampleSunLight = true;
				continue;
			}
		} // end if (intersec.type == DIFF)

		if (intersec.type == SPEC)  // Ideal SPECULAR reflection
		{
			previousIntersecType = SPEC;
			mask *= intersec.color;

			r = Ray( x, reflect(r.direction, nl) );
			r.origin += r.direction * epsIntersect;

			//bounceIsSpecular = true; // turn on mirror caustics
			continue;
		}

        	if (intersec.type == REFR)  // Ideal dielectric REFRACTION
		{
			previousIntersecType = REFR;

			nc = 1.0; // IOR of Air
			nt = 1.5; // IOR of common Glass
			Re = calcFresnelReflectance(r.direction, n, nc, nt, ratioIoR);
			Tr = 1.0 - Re;

			if (rand() < Re) // reflect ray from surface
			{
				r = Ray( x, reflect(r.direction, nl) );
				r.origin += r.direction * epsIntersect;
                		continue;
			}
			else // transmit ray through surface
			{
				mask *= 1.0 - (intersec.color * intersec.opacity);
				tdir = refract(r.direction, nl, ratioIoR);
				r = Ray(x, r.direction); // TODO using r.direction instead of tdir, because going through common Glass makes everything spherical from up close...
				r.origin += r.direction * epsIntersect;
				
                		if (diffuseCount < 2)
					bounceIsSpecular = true;
				continue;
			}

		} // end if (intersec.type == REFR)

	} // end for (int bounces = 0; bounces < 4; bounces++)

	return accumCol;
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
	//seed = uvec2(uFrameCounter, uFrameCounter + 1.0) * uvec2(gl_FragCoord); // old way of generating random numbers

	randVec4 = texture(tBlueNoiseTexture, (gl_FragCoord.xy + (uRandomVec2 * 256.0)) / 256.0 ); // new way of rand()

	vec2 pixelPos = vec2(0);
	vec2 pixelOffset = vec2(0);
	
	float x = rand();
	float y = rand();

	pixelOffset = vec2(tentFilter(x), tentFilter(y));

	// we must map pixelPos into the range -1.0 to +1.0
	pixelPos = ((gl_FragCoord.xy + pixelOffset) / uResolution) * 2.0 - 1.0;

	vec3 rayDir = normalize( pixelPos.x * camRight * uULen + pixelPos.y * camUp * uVLen + camForward );
	
	// depth of field
	vec3 focalPoint = uFocusDistance * rayDir;
	float randomAngle = rand() * TWO_PI; // pick random point on aperture
	float randomRadius = rand() * uApertureSize;
	vec3  randomAperturePos = ( cos(randomAngle) * camRight + sin(randomAngle) * camUp ) * randomRadius;
	// point on aperture to focal point
	vec3 finalRayDir = normalize(focalPoint - randomAperturePos);
    
	Ray ray = Ray( cameraPosition + randomAperturePos, finalRayDir );

	// Add ground plane
	plane = Plane( vec4(0, 1, 0, 0.0), vec3(0), vec3(0.45), DIFF);

	// perform path tracing and get resulting pixel color
	vec3 pixelColor = CalculateRadiance(ray, uSunDirection);

	vec3 previousColor = texelFetch(tPreviousTexture, ivec2(gl_FragCoord.xy), 0).rgb;
	
	if ( uFrameCounter == 1.0 )
	{
		previousColor = vec3(0.0); // clear rendering accumulation buffer
	}
	else if ( uCameraIsMoving )
	{
		previousColor *= 0.5; // motion-blur trail amount (old image)
		pixelColor *= 0.5; // brightness of new image (noisy)
	}
	
	pc_fragColor = vec4( pixelColor + previousColor, 1.0 );	
}
