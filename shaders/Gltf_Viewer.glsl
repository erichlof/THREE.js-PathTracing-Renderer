#version 300 es

precision highp float;
precision highp int;
precision highp sampler2D;

#include <pathtracing_uniforms_and_defines>
#include <pathtracing_skymodel_defines>

uniform vec3 uSunDirection;
uniform sampler2D t_PerlinNoise;
uniform sampler2D tTriangleTexture;
uniform sampler2D tAABBTexture;
uniform sampler2D tAlbedoTextures[8]; // 8 = max number of diffuse albedo textures per model

// (1 / 2048 texture width)
#define INV_TEXTURE_WIDTH 0.00048828125

#define N_PLANES 2


struct Ray { vec3 origin; vec3 direction; };
struct Plane { vec4 pla; vec3 emission; vec3 color; int type; };
struct Intersection { vec3 normal; vec3 emission; vec3 color; vec2 uv; int type; int albedoTextureID; float opacity;};

Plane planes[N_PLANES];

#include <pathtracing_random_functions>
#include <pathtracing_calc_fresnel_reflectance>
#include <pathtracing_sphere_intersect>
#include <pathtracing_plane_intersect>
#include <pathtracing_triangle_intersect>
#include <pathtracing_physical_sky_functions>
#include <pathtracing_boundingbox_intersect>
#include <pathtracing_bvhTriangle_intersect>


// CLOUDS
/* Credit: some of the following cloud code is borrowed from https://www.shadertoy.com/view/XtBXDw posted by user 'valentingalea' */

#define THICKNESS      25.0
#define ABSORPTION     0.333
#define N_MARCH_STEPS  12
#define N_LIGHT_STEPS  3

float noise3D( in vec3 p )
{
	return texture(t_PerlinNoise, p.xz).x;
}

const mat3 m = 1.21 * mat3( 0.00,  0.80,  0.60,
                           -0.80,  0.36, -0.48,
                           -0.60, -0.48,  0.64 );

float fbm( vec3 p )
{
	float t;
	float mult = 2.0;
	t  = 1.0 * noise3D(p);   p = m * p * mult;
	t += 0.5 * noise3D(p);   p = m * p * mult;
	t += 0.25 * noise3D(p);
	
	return t;
}

float cloud_density( vec3 pos, float cov )
{
	float dens = fbm(pos * 0.002);
	dens *= smoothstep(cov, cov + 0.05, dens);

	return clamp(dens, 0.0, 1.0);	
}

float cloud_light( vec3 pos, vec3 dir_step, float cov )
{
	float T = 1.0; // transmitance
    	float dens;
    	float T_i;
	
	for (int i = 0; i < N_LIGHT_STEPS; i++) 
	{
		dens = cloud_density(pos, cov);
		T_i = exp(-ABSORPTION * dens);
		T *= T_i;
		pos += dir_step;
	}

	return T;
}

vec4 render_clouds( Ray eye, vec3 p, vec3 sunDirection )
{
	float march_step = THICKNESS / float(N_MARCH_STEPS);
	vec3 pos = p + vec3(uTime * -3.0, uTime * -0.5, uTime * -2.0);
	vec3 dir_step = eye.direction / clamp(eye.direction.y, 0.3, 1.0) * march_step;
	vec3 light_step = sunDirection * 5.0;
	
	float covAmount = (sin(mod(uTime * 0.1, TWO_PI))) * 0.5 + 0.5;
	float coverage = mix(1.0, 1.5, clamp(covAmount, 0.0, 1.0));
	float T = 1.0; // transmitance
	vec3 C = vec3(0.25); // color
	float alpha = 0.0;
	float dens;
	float T_i;
	float cloudLight;
	
	for (int i = 0; i < N_MARCH_STEPS; i++)
	{
		dens = cloud_density(pos, coverage);

		T_i = exp(-ABSORPTION * dens * march_step);
		T *= T_i;
		cloudLight = cloud_light(pos, light_step, coverage);
		C += T * cloudLight * dens * march_step;
		C = mix(C * 0.95, C, cloudLight);
		alpha += (1.0 - T_i) * (1.0 - alpha);
		pos += dir_step;
	}
	
	return vec4(C, alpha);
}

float checkCloudCover( vec3 sunDirection, vec3 p )
{
	float march_step = THICKNESS / float(N_MARCH_STEPS);
	vec3 pos = p + vec3(uTime * -3.0, uTime * -0.5, uTime * -2.0);
	vec3 dir_step = sunDirection / clamp(sunDirection.y, 0.001, 1.0) * march_step;
	
	float covAmount = (sin(mod(uTime * 0.1, TWO_PI))) * 0.5 + 0.5;
	float coverage = mix(1.0, 1.5, clamp(covAmount, 0.0, 1.0));
	float alpha = 0.0;
	float dens;
	float T_i;
	
	for (int i = 0; i < N_MARCH_STEPS; i++)
	{
		dens = cloud_density(pos, coverage);
		T_i = exp(-ABSORPTION * dens * march_step);
		alpha += (1.0 - T_i) * (1.0 - alpha);
		pos += dir_step;
	}
	
	return clamp(1.0 - alpha, 0.0, 1.0);
}

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
	Ray rObj;
	vec3 hitObjectSpace;
	vec3 hitWorldSpace;
	vec3 normal;
	float dw, dc;
	float d = INFINITY;
	float t = INFINITY;
	float eps = 0.1;
	float waterWaveHeight;

	// AABB BVH Intersection variables
	vec4 aabbNodeData0, aabbNodeData1, aabbNodeData2;
	vec4 vd0, vd1, vd2, vd3, vd4, vd5, vd6, vd7;
	vec3 aabbMin, aabbMax;
	vec3 inverseDir = 1.0 / r.direction;
	vec3 hitPos, toLightBulb;
	ivec2 uv0, uv1, uv2, uv3, uv4, uv5, uv6, uv7;

	float stackptr = 0.0;
	float bc, bd;
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
	
	// GROUND and UNDERGROUND Planes (to block clouds from being rendered underneath ground plane)
	for (int i = 0; i < N_PLANES; i++)
	{
		d = PlaneIntersect( planes[i].pla, r );
		if (d < t)
		{
			t = d;
			intersec.normal = normalize(planes[i].pla.xyz);
			intersec.emission = planes[i].emission;
			intersec.color = planes[i].color;
			intersec.type = planes[i].type;
		}
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



//-----------------------------------------------------------------------
vec3 CalculateRadiance( Ray r, vec3 sunDirection, inout uvec2 seed )
//-----------------------------------------------------------------------
{
	vec3 randVec = vec3(rand(seed) * 2.0 - 1.0, rand(seed) * 2.0 - 1.0, rand(seed) * 2.0 - 1.0);
	Ray cameraRay = r;
	vec3 initialSkyColor = Get_Sky_Color(r, sunDirection);
	
	Ray skyRay = Ray( r.origin * 0.02, normalize(vec3(r.direction.x, abs(r.direction.y), r.direction.z)) );
	float dc = SphereIntersect( 20000.0, vec3(skyRay.origin.x, -19900.0, skyRay.origin.z) + vec3(rand(seed) * 2.0), skyRay );
	vec3 skyPos = skyRay.origin + skyRay.direction * dc;
	vec4 cld = render_clouds(skyRay, skyPos, sunDirection);

	Intersection intersec;
	vec3 accumCol = vec3(0.0);
	vec3 mask = vec3(1.0);
	vec3 n, nl, x;
	vec3 firstX = vec3(0);
	vec3 tdir;

	float hitDistance;
	float nc, nt, Re;
	float weight;
	float t = INFINITY;
	float epsIntersect = 0.01;
	
	int previousIntersecType = -100;
	int diffuseCount = 0;

	bool skyHit = false;
	bool bounceIsSpecular = true;
	bool sampleSun = false;

    	for (int bounces = 0; bounces < 4; bounces++)
	{

		float t = SceneIntersect(r, intersec);

		// ray hits sky first
		if (t == INFINITY && bounces == 0 )
		{
			skyHit = true;
			firstX = skyPos;

			break;	
		}

        	// if ray bounced off of diffuse material and hits sky
		if (t == INFINITY && previousIntersecType == DIFF)
		{	
			weight = 2.0; // normal weight for entire sky, except the small sun angular arc

			          // the dot() check prevents sun 'fireflies' on diffuse surfaces
			if (sampleSun || dot(r.direction, sunDirection) > 0.98) 
				weight = 0.01; // this down-weighting is taking into account the probability that
			// a random ray would exactly hit the sun (small angular arc) instead of the rest of the sky
					
			accumCol = mask * Get_Sky_Color(r, sunDirection) * weight;

			break;
		}

		// reset sampleSun
		sampleSun = false;

        	// if ray bounced off of glass and hits sky
		if (t == INFINITY && previousIntersecType == REFR)
		{
			if (bounceIsSpecular) // prevents sun 'fireflies' on diffuse surfaces
				accumCol = mask * Get_Sky_Color(r, sunDirection) * 0.01; // when using r.direction below, use another magic number at 0.01 here to get the correct brightness
			
			if (diffuseCount == 0) // reflection of sky in glass
			{
				// Setting skyHit to true will fake cloud reflection, as it's actually rendering diffuse surfaces
				// behind the window surface more transparent, resulting in the sky & clouds being rendered 'on top'.
				skyHit = true;
				firstX = skyPos;
			}
			
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
		vec3 n = intersec.normal;
        	vec3 nl = dot(n,r.direction) <= 0.0 ? normalize(n) : normalize(n * -1.0);
		vec3 x = r.origin + r.direction * t;

		if (bounces == 0)
			firstX = x;

		if (intersec.type == SEAFLOOR)
		{
			float undergroundDotSun = max(0.0, dot(vec3(0,1,0), sunDirection));
			accumCol = mask * intersec.color * undergroundDotSun;

            		break;
		}
		
        	if (intersec.type == DIFF) // Ideal DIFFUSE reflection
        	{
			diffuseCount++;
			previousIntersecType = DIFF;

			mask *= intersec.color;
            		bounceIsSpecular = false;

			// Russian Roulette
			float p = max(mask.r, max(mask.g, mask.b));
			if (bounces > 0)
			{
				if (rand(seed) < p)
                    			mask *= 1.0 / p;
                		else
                    			break;
			}

			if (diffuseCount == 1 && rand(seed) < 0.5)
			{
				// this branch gathers color bleeding / caustics from other surfaces hit in the future
				// choose random Diffuse sample vector
				r = Ray( x, randomCosWeightedDirectionInHemisphere(nl, seed) );
				r.origin += r.direction * epsIntersect;

				continue;
			}
			else
			{
				// this branch acts like a traditional shadowRay, checking for direct light from the Sun..
				// if it has a clear path and hits the sun on the next bounce, sunlight is gathered, otherwise returns black (shadow)
				r = Ray( x, normalize(sunDirection + (randVec * 0.01)) );
				r.origin += nl * epsIntersect;
				weight = dot(r.direction, nl);
				if (weight < 0.01)
					break;

				mask *= weight;
				sampleSun = true;
				continue;
			}
		} // end if (intersec.type == DIFF)

        	if (intersec.type == REFR)  // Ideal dielectric REFRACTION
		{
			previousIntersecType = REFR;

			nc = 1.0; // IOR of Air
			nt = 1.5; // IOR of common Glass
			Re = calcFresnelReflectance(n, nl, r.direction, nc, nt, tdir);

			if (rand(seed) < Re) // reflect ray from surface
			{
				r = Ray( x, reflect(r.direction, nl) );
				r.origin += r.direction * epsIntersect;
                		continue;
			}
			else // transmit ray through surface
			{
				mask *= 1.0 - (intersec.color * intersec.opacity);
				r = Ray(x, r.direction); // TODO using r.direction instead of tdir, because going through common Glass makes everything spherical from up close...
				r.origin += r.direction * epsIntersect;
                		if (diffuseCount < 2)
					bounceIsSpecular = true;
				continue;
			}

		} // end if (intersec.type == REFR)

	} // end for (int bounces = 0; bounces < 4; bounces++)


	if ( skyHit ) // sky and clouds
	{
		vec3 cloudColor = cld.rgb / (cld.a + 0.00001);
	   	vec3 sunColor = clamp(Get_Sky_Color( Ray(skyPos, normalize((randVec * 0.03) + sunDirection)), sunDirection ), 0.0, 1.0);
		cloudColor *= mix(sunColor, vec3(1), max(0.0, dot(vec3(0,1,0), sunDirection)) );
        	cloudColor = mix(initialSkyColor, cloudColor, clamp(cld.a, 0.0, 1.0));

		hitDistance = distance(skyRay.origin, skyPos);
        	accumCol = mask * mix( cloudColor, initialSkyColor, clamp( 1.0 - exp2(-hitDistance * 0.003), 0.0, 1.0 ) );
	}	
	else // other objects
	{
	    	// atmospheric haze effect (aerial perspective)
		hitDistance = distance(cameraRay.origin, firstX);
        	accumCol = mix( accumCol, initialSkyColor, clamp( 1.0 - exp2(-log(hitDistance * 0.001)), 0.0, 1.0 ) ); // TODO add logarithmic haze value (0.001) to menu
	}

	return accumCol;
}


//-----------------------------------------------------------------------
void SetupScene(void)
//-----------------------------------------------------------------------
{
	planes[0] = Plane( vec4(0, 1, 0, 0.0), vec3(0), vec3(0.45), DIFF); // Ground
    	planes[1] = Plane( vec4(0, 1, 0, -1000.0), vec3(0), vec3(0.33), SEAFLOOR); // Underground
}

// tentFilter from Peter Shirley's 'Realistic Ray Tracing (2nd Edition)' book, pg. 60
float tentFilter(float x)
{
	if (x < 0.5)
		return sqrt(2.0 * x) - 1.0;

	return 1.0 - sqrt(2.0 - (2.0 * x));
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

	// we must map pixelPos into the range -1.0 to +1.0
	pixelPos = (gl_FragCoord.xy / uResolution) * 2.0 - 1.0;
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

	// perform path tracing and get resulting pixel color
	vec3 pixelColor = CalculateRadiance( ray, uSunDirection, seed );

	vec3 previousColor = texelFetch(tPreviousTexture, ivec2(gl_FragCoord.xy), 0).rgb;
	
	if ( uCameraJustStartedMoving )
	{
		previousColor = vec3(0.0); // clear rendering accumulation buffer
	}
	else if ( uCameraIsMoving )
	{
		previousColor *= 0.5; // motion-blur trail amount (old image)
		pixelColor *= 0.5; // brightness of new image (noisy)
	}
	
	out_FragColor = vec4( pixelColor + previousColor, 1.0 );	
}
