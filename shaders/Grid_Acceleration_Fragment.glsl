precision highp float;
precision highp int;
precision highp sampler2D;

#include <pathtracing_uniforms_and_defines>
#include <pathtracing_random_functions>

// the following grid acc. structure code is partially copied from/inspired by Shadertoy user koiava https://www.shadertoy.com/view/MtBSzd#
// thank you mr. Koiava for the inspiration and for sharing your code on Shadertoy!

#define MAX_DISPLACEMENT 100.0 // how high can the vertices rise out of the ground plane

#define DISP_MAP_SEGMENTS 1024.0 // each segment quad is made of 2 triangles, so the acc. structure multiplies this number by 2!
// now we have Width(#segments) * Height(#segments) * 2(triangles per quad) to get the total triangles...
// so in this case 1024.0 x 1024.0 x 2 = 2,097,152 raytraced triangles with shadows in realtime!

uniform sampler2D t_Heightmap;
float displacementMultiplier;

vec3 rayOrigin, rayDirection;
// recorded intersection data:
vec3 hitNormal, hitEmission, hitColor;
vec2 hitUV;
float hitObjectID;
int hitType = -100;


vec3 displacementVolumeMin = vec3(-DISP_MAP_SEGMENTS * 0.5, 0.0, -DISP_MAP_SEGMENTS * 0.5);
vec3 displacementVolumeMax = vec3( DISP_MAP_SEGMENTS * 0.5, MAX_DISPLACEMENT, DISP_MAP_SEGMENTS * 0.5);


bool rayAABBIntersection( vec3 rayOrigin, vec3 rayDirection, vec3 aabbMin, vec3 aabbMax, out float t_enter, out float t_exit) 
{
	vec3 OMIN = (aabbMin - rayOrigin) / rayDirection;
	vec3 OMAX = (aabbMax - rayOrigin) / rayDirection;
	vec3 MAX = max(OMAX, OMIN);
	vec3 MIN = min(OMAX, OMIN);
	t_exit = min(MAX.x, min(MAX.y, MAX.z));
	t_enter = max(MIN.x, max(MIN.y, MIN.z));

	t_enter = (t_enter < 0.0) ? 0.0 : t_enter;

	return (t_exit > t_enter && t_exit > 0.0);
}


vec3 getTriangleNormal(vec3 v0, vec3 v1, vec3 v2) 
{
	return cross(v1 - v0, v2 - v0);
}


bool rayIntersectsTriangle(vec3 p, vec3 d, vec3 v0, vec3 v1, vec3 v2, out float t) 
{
	vec3 e1, e2, h, s, q;
	float a, f, u, v;
	e1 = v1 - v0;
	e2 = v2 - v0;

	h = cross(d, e2);
	a = dot(e1, h);

	f = 1.0 / a;
	s = p - v0;
	u = f * dot(s, h);

	if (u < 0.0 || u > 1.0)
		return false;

	q = cross(s, e1);
	v = f * dot(d, q);

	if (v < 0.0 || u + v > 1.0)
		return false;

	t = f * dot(e2, q);

	//uv = vec2(u, v);

	return (t > 0.0);
}


bool rayQuadIntersect( vec3 rayOrigin, vec3 rayDirection, vec3 v0, vec3 v1, vec3 v2, vec3 v3, out float t, out vec3 n) 
{
	float tcurrent;
	t = 10e+10;

	//first triangle
	if (rayIntersectsTriangle(rayOrigin, rayDirection, v0, v1, v2, tcurrent)) 
	{
		t = tcurrent;
		n = getTriangleNormal(v0, v1, v2);
	}

	//second triangle
	if (rayIntersectsTriangle(rayOrigin, rayDirection, v0, v2, v3, tcurrent)) 
	{
		if (tcurrent < t) 
		{
			t = tcurrent;
			n = getTriangleNormal(v0, v2, v3);
		}
	}

	return (t < 10e+10);
}


float getDisplacement(vec2 uv) 
{
	// procedural 3D graph pattern
	//return 0.9 * sin(uTime - length(vec2(0.5) - uv) * 20.0) * 0.5 + 0.5;

	// landscape with animated lowering and raising
	return (sin(uTime * 0.4) * 0.5 + 0.5) * texture(t_Heightmap, uv).x;

	// stationary landscape
	//return texture(t_Heightmap, uv).x;
}


void getPixelDisplacements(vec2 uv, out float d1, out float d2, out float d3, out float d4) 
{
	float inverseSegments = 1.0 / DISP_MAP_SEGMENTS;

	d1 = getDisplacement(vec2(uv.x,                   uv.y));
	d2 = getDisplacement(vec2(uv.x + inverseSegments, uv.y));
	d3 = getDisplacement(vec2(uv.x + inverseSegments, uv.y + inverseSegments));
	d4 = getDisplacement(vec2(uv.x,                   uv.y + inverseSegments));
}


#define UVH2POS(aabbMin, aabbMax, uvd, pos) {vec3 aabbDim = aabbMax - aabbMin; pos = aabbMin + uvd * aabbDim;}
#define POS2UVH(aabbMin, aabbMax, pos, uvd) {vec3 aabbDim = aabbMax - aabbMin; uvd = (pos - aabbMin) / aabbDim;}

bool processVoxel(vec3 rayOrigin, vec3 rayDirection, vec3 p, out float t, out vec3 normal) 
{
	//Lookup displacement values
	vec2 uv = floor(p.xz) / vec2(DISP_MAP_SEGMENTS, DISP_MAP_SEGMENTS);
	uv = clamp(uv, 0.0, 1.0);
	
	float disp[4];
	getPixelDisplacements(uv, disp[0], disp[1], disp[2], disp[3]);
	vec3 corner_uv[4];
	//calculate displaced vertices
	float inverseSegments = 1.0 / DISP_MAP_SEGMENTS;

	corner_uv[0] = vec3(uv.x,                   disp[0],                   uv.y);
	corner_uv[1] = vec3(uv.x + inverseSegments, disp[1],                   uv.y);
	corner_uv[2] = vec3(uv.x + inverseSegments, disp[2], uv.y + inverseSegments);
	corner_uv[3] = vec3(uv.x,                   disp[3], uv.y + inverseSegments);

	vec3 vertices[4];
	UVH2POS(displacementVolumeMin, displacementVolumeMax, corner_uv[0], vertices[0]);
	UVH2POS(displacementVolumeMin, displacementVolumeMax, corner_uv[1], vertices[1]);
	UVH2POS(displacementVolumeMin, displacementVolumeMax, corner_uv[2], vertices[2]);
	UVH2POS(displacementVolumeMin, displacementVolumeMax, corner_uv[3], vertices[3]);

	float hitDist;
	vec3 hitN;
	if (rayQuadIntersect(rayOrigin, rayDirection, vertices[0], vertices[1], vertices[2], vertices[3], hitDist, hitN)) 
	{
		t = hitDist;
		normal = hitN;
		return true;
	}

	return false;
}


#define FRAC0(x) (x - floor(x))
#define FRAC1(x) (1.0 - x + floor(x))

bool processVoxelsOnLine(vec3 rayOrigin, vec3 rayDirection, vec3 p0, vec3 p1, out float t, out vec3 normal) 
{
	float tMaxX, tMaxY, tMaxZ, tDeltaX, tDeltaY, tDeltaZ;
	ivec3 voxel;  

	ivec3 s = ivec3(sign(p1 - p0));
	vec3 d = p1 - p0;
	if (s.x != 0) tDeltaX = min(float(s.x) / d.x, INFINITY); 
		else tDeltaX = INFINITY;
	if (s.x > 0) tMaxX = tDeltaX * FRAC1(p0.x);
		else tMaxX = tDeltaX * FRAC0(p0.x);

	if (s.y != 0) tDeltaY = min(float(s.y) / d.y, INFINITY); 
		else tDeltaY = INFINITY;
	if (s.y > 0) tMaxY = tDeltaY * FRAC1(p0.y); 
		else tMaxY = tDeltaY * FRAC0(p0.y);

	if (s.z != 0) tDeltaZ = min(float(s.z) / d.z, INFINITY); 
		else tDeltaZ = INFINITY;
	if (s.z > 0) tMaxZ = tDeltaZ * FRAC1(p0.z); 
		else tMaxZ = tDeltaZ * FRAC0(p0.z);

	voxel = ivec3(p0);

	for (int i = 0; i < int(DISP_MAP_SEGMENTS + (DISP_MAP_SEGMENTS * 0.5)); i++)
	//while (true)
	{
		if (tMaxX < tMaxY) 
		{
			if (tMaxX < tMaxZ) 
			{
				voxel.x += s.x;
				tMaxX += tDeltaX;
			} 
			else 
			{
				voxel.z += s.z;
				tMaxZ += tDeltaZ;
			}
		} 
		else 
		{
			if (tMaxY < tMaxZ) 
			{
				voxel.y += s.y;
				tMaxY += tDeltaY;
			} 
			else 
			{
				voxel.z += s.z;
				tMaxZ += tDeltaZ;
			}
		}
		if (tMaxX > 1.0 && tMaxY > 1.0 && tMaxZ > 1.0) 
			return false;
		// process voxel here
		if (processVoxel(rayOrigin, rayDirection, vec3(voxel), t, normal))
			return true;
	}
}


bool rayIntersectsDisplacement( vec3 rayOrigin, vec3 rayDirection, out float t, out vec3 normal) 
{
	float t1, t2;
	
	if (!rayAABBIntersection(rayOrigin, rayDirection, displacementVolumeMin, displacementVolumeMax, t1, t2))
		return false;
	//{
		vec3 hitpos1 = rayOrigin + rayDirection * (t1 + 2.0); //volume entry point
		vec3 hitpos2 = rayOrigin + rayDirection * (t2 + 2.0); //volume exit point

		//Convert position to parametric coordinates
		vec3 uvd1, uvd2;
		POS2UVH(displacementVolumeMin, displacementVolumeMax, hitpos1, uvd1);
		POS2UVH(displacementVolumeMin, displacementVolumeMax, hitpos2, uvd2);

		//pixel coordinates of projected entry and exit point
		vec3 p0 = uvd1 * vec3(DISP_MAP_SEGMENTS, 1.0, DISP_MAP_SEGMENTS);
		vec3 p1 = uvd2 * vec3(DISP_MAP_SEGMENTS, 1.0, DISP_MAP_SEGMENTS);

		if (processVoxelsOnLine(rayOrigin, rayDirection, p0, p1, t, normal)) 
			return true;	
	//}

	return false;
}


vec3 getColor() 
{
	float t;
	vec3 n;
	
	if (!rayIntersectsDisplacement(rayOrigin, rayDirection, t, n)) 
		return vec3(0); 
	
	n = normalize(n);
	vec3 p = rayOrigin + rayDirection * t;
	vec3 normal = dot(rayDirection, n) < 0.0 ? n : -n;

	vec3 lc = normalize(vec3(1.0, 1.0, 1.0));

	float dotNL = dot(normal, lc);
	if (dotNL < 0.0) 
		return vec3(0.01); //fake indirect
	vec3 shadowRayDirection = lc;
	vec3 shadowRayOrigin = p + normal * 0.01;

	if (!rayIntersectsDisplacement(shadowRayOrigin, shadowRayDirection, t, n)) 
		return max(0.0, dotNL) * vec3(1);
	
	return vec3(0.01); //fake indirect
}


// tentFilter from Peter Shirley's 'Realistic Ray Tracing (2nd Edition)' book, pg. 60		
float tentFilter(float x) 
{
	return (x < 0.5) ? sqrt(2.0 * x) - 1.0 : 1.0 - sqrt(2.0 - (2.0 * x));
}

void main(void) 
{
	// not needed, three.js has a built-in uniform named cameraPosition
	//vec3 camPos     = vec3( uCameraMatrix[3][0],  uCameraMatrix[3][1],  uCameraMatrix[3][2]);

	vec3 camRight = vec3(uCameraMatrix[0][0], uCameraMatrix[0][1], uCameraMatrix[0][2]);
	vec3 camUp = vec3(uCameraMatrix[1][0], uCameraMatrix[1][1], uCameraMatrix[1][2]);
	vec3 camForward = vec3(-uCameraMatrix[2][0], -uCameraMatrix[2][1], -uCameraMatrix[2][2]);

	// calculate unique seed for rng() function
	seed = uvec2(uFrameCounter, uFrameCounter + 1.0) * uvec2(gl_FragCoord);

	// initialize rand() variables
	counter = -1.0; // will get incremented by 1 on each call to rand()
	channel = 0; // the final selected color channel to use for rand() calc (range: 0 to 3, corresponds to R,G,B, or A)
	randNumber = 0.0; // the final randomly-generated number (range: 0.0 to 1.0)
	randVec4 = vec4(0); // samples and holds the RGBA blueNoise texture value for this pixel
	randVec4 = texelFetch(tBlueNoiseTexture, ivec2(mod(gl_FragCoord.xy + floor(uRandomVec2 * 256.0), 256.0)), 0);
	
	vec2 pixelOffset = vec2( tentFilter(rand()), tentFilter(rand()) ) * 0.5;
	// we must map pixelPos into the range -1.0 to +1.0
	vec2 pixelPos = ((gl_FragCoord.xy + pixelOffset) / uResolution) * 2.0 - 1.0;

	vec3 rayDir = uUseOrthographicCamera ? camForward : 
					       normalize( pixelPos.x * camRight * uULen + pixelPos.y * camUp * uVLen + camForward );

	// depth of field
	vec3 focalPoint = uFocusDistance * rayDir;
	float randomAngle = rng() * TWO_PI; // pick random point on aperture
	float randomRadius = rng() * uApertureSize;
	vec3 randomAperturePos = (cos(randomAngle) * camRight + sin(randomAngle) * camUp) * sqrt(randomRadius);
	// point on aperture to focal point
	vec3 finalRayDir = normalize(focalPoint - randomAperturePos);

	rayOrigin = uUseOrthographicCamera ? cameraPosition + (camRight * pixelPos.x * uULen * 100.0) + (camUp * pixelPos.y * uVLen * 100.0) + randomAperturePos :
					     cameraPosition + randomAperturePos; 
	rayDirection = finalRayDir;


	// perform path tracing and get resulting pixel color
	vec3 pixelColor = getColor();

	vec3 previousColor = texelFetch(tPreviousTexture, ivec2(gl_FragCoord.xy), 0).rgb;

	if (uCameraIsMoving)
	{
                previousColor *= 0.5; // motion-blur trail amount (old image)
                pixelColor *= 0.5; // brightness of new image (noisy)
        }
	else
	{
                previousColor *= 0.9; // motion-blur trail amount (old image)
                pixelColor *= 0.1; // brightness of new image (noisy)
        }

	// if current raytraced pixel didn't return any color value, just use the previous frame's pixel color
	if (pixelColor == vec3(0.0))
	{
		pixelColor = previousColor;
		previousColor *= 0.5;
		pixelColor *= 0.5;
	}

	pc_fragColor = vec4(pixelColor + previousColor, 1.01);
}
