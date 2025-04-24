precision highp float;
precision highp int;
precision highp sampler2D;

#include <pathtracing_uniforms_and_defines>

uniform sampler2D tAlbedoMap;
uniform sampler2D tTriangleTexture;
uniform sampler2D tAABBTexture;

#define INV_TEXTURE_WIDTH 0.000244140625   // (1 / 4096 texture width)
//#define INV_TEXTURE_WIDTH 0.00048828125  // (1 / 2048 texture width)
//#define INV_TEXTURE_WIDTH 0.0009765625   // (1 / 1024 texture width)

#define N_SPHERES 1


//-----------------------------------------------------------------------

vec3 rayOrigin, rayDirection;
// recorded intersection data:
vec3 hitNormal, hitEmission, hitColor;
vec2 hitUV;
float hitObjectID;
int hitType = -100;

struct Sphere { float radius; vec3 position; vec3 emission; vec3 color; int type; };

Sphere spheres[N_SPHERES];


#include <pathtracing_random_functions>

#include <pathtracing_calc_fresnel_reflectance>

#include <pathtracing_sphere_intersect>

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

	//  IMPORTANT NOTE: value below Must be 4096.0 and not 2048.0!

	ivec2 uv0 = ivec2( mod(ix2 + 0.0, 4096.0), (ix2 + 0.0) * INV_TEXTURE_WIDTH ); // data0
	ivec2 uv1 = ivec2( mod(ix2 + 1.0, 4096.0), (ix2 + 1.0) * INV_TEXTURE_WIDTH ); // data1
	
	boxNodeData0 = texelFetch(tAABBTexture, uv0, 0);
	boxNodeData1 = texelFetch(tAABBTexture, uv1, 0);
}


//---------------------------------------------------------------------------------------
float SceneIntersect( )
//---------------------------------------------------------------------------------------
{
	vec4 currentBoxNodeData0, nodeAData0, nodeBData0, tmpNodeData0;
	vec4 currentBoxNodeData1, nodeAData1, nodeBData1, tmpNodeData1;
	
	vec4 vd0, vd1, vd2, vd3, vd4, vd5, vd6, vd7;

	vec3 inverseDir = 1.0 / rayDirection;
	vec3 normal;

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
		

		if (currentBoxNodeData0.x < 0.0) // < 0.0 signifies an inner node
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

		uv0 = ivec2( mod(id + 0.0, 4096.0), (id + 0.0) * INV_TEXTURE_WIDTH );
		uv1 = ivec2( mod(id + 1.0, 4096.0), (id + 1.0) * INV_TEXTURE_WIDTH );
		uv2 = ivec2( mod(id + 2.0, 4096.0), (id + 2.0) * INV_TEXTURE_WIDTH );
		
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
		// IMPORTANT NOTE: value below Must be 4096.0 and not 2048.0!

		uv0 = ivec2( mod(triangleID + 0.0, 4096.0), (triangleID + 0.0) * INV_TEXTURE_WIDTH );
		uv1 = ivec2( mod(triangleID + 1.0, 4096.0), (triangleID + 1.0) * INV_TEXTURE_WIDTH );
		uv2 = ivec2( mod(triangleID + 2.0, 4096.0), (triangleID + 2.0) * INV_TEXTURE_WIDTH );
		uv3 = ivec2( mod(triangleID + 3.0, 4096.0), (triangleID + 3.0) * INV_TEXTURE_WIDTH );
		uv4 = ivec2( mod(triangleID + 4.0, 4096.0), (triangleID + 4.0) * INV_TEXTURE_WIDTH );
		uv5 = ivec2( mod(triangleID + 5.0, 4096.0), (triangleID + 5.0) * INV_TEXTURE_WIDTH );
		uv6 = ivec2( mod(triangleID + 6.0, 4096.0), (triangleID + 6.0) * INV_TEXTURE_WIDTH );
		uv7 = ivec2( mod(triangleID + 7.0, 4096.0), (triangleID + 7.0) * INV_TEXTURE_WIDTH );
		
		vd0 = texelFetch(tTriangleTexture, uv0, 0);
		vd1 = texelFetch(tTriangleTexture, uv1, 0);
		vd2 = texelFetch(tTriangleTexture, uv2, 0);
		vd3 = texelFetch(tTriangleTexture, uv3, 0);
		vd4 = texelFetch(tTriangleTexture, uv4, 0);
		vd5 = texelFetch(tTriangleTexture, uv5, 0);
		vd6 = texelFetch(tTriangleTexture, uv6, 0);
		vd7 = texelFetch(tTriangleTexture, uv7, 0);

		// face normal for flat-shaded polygon look
		//hitNormal = normalize( cross(vec3(vd0.w, vd1.xy) - vec3(vd0.xyz), vec3(vd1.zw, vd2.x) - vec3(vd0.xyz)) );
		
		// interpolated normal using triangle intersection's uv's
		triangleW = 1.0 - triangleU - triangleV;
		hitNormal = (triangleW * vec3(vd2.yzw) + triangleU * vec3(vd3.xyz) + triangleV * vec3(vd3.w, vd4.xy));
		hitEmission = vec3(1, 0, 1); // use this if hitType will be LIGHT
		hitColor = vec3(1);//vd6.yzw;
		hitUV = triangleW * vec2(vd4.zw) + triangleU * vec2(vd5.xy) + triangleV * vec2(vd5.zw);
		//hitType = int(vd6.x);
		//hitAlbedoTextureID = int(vd7.x);
		hitType = CHECK;
		hitObjectID = 1.0;//float(objectCount);
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
		hitObjectID = 0.0;//float(objectCount);
	}
	

	return t;

} // end float SceneIntersect( vec3 rayOrigin, vec3 rayDirection, out float hitObjectID )


//----------------------------------------------------------------------------------------------------------------------------------------------------
vec3 CalculateRadiance( out vec3 objectNormal, out vec3 objectColor, out float objectID, out float pixelSharpness )
//----------------------------------------------------------------------------------------------------------------------------------------------------
{
        vec4 texColor;

	vec3 accumCol = vec3(0.0);
        vec3 mask = vec3(1.0);
	vec3 checkCol0 = vec3(1.0);
	vec3 checkCol1 = vec3(0.5);
	vec3 tdir;
	vec3 x, n, nl;

	vec2 sampleUV;
	
	float t;
	float nc, nt, ratioIoR, Re, Tr;
	float P, RP, TP;
	float weight;
	
	int diffuseCount = 0;

	int bounceIsSpecular = TRUE;
	int sampleLight = FALSE;

	
        for (int bounces = 0; bounces < 2; bounces++)
	{

		t = SceneIntersect();
		
		if (t == INFINITY)
			break;
		
		if (hitType == LIGHT)
		{	
			// this makes the object edges sharp against the background
			if (bounces == 0)
				pixelSharpness = 1.0;

			accumCol = mask * hitEmission;
			// reached a light, so we can exit
			break;
		}

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
		
		    
                if (hitType == DIFF || hitType == CHECK) // Ideal DIFFUSE reflection
                {
			diffuseCount++;

			if ( hitType == CHECK )
			{
				float q = clamp( mod( dot( floor(x.xz * 2.0), vec2(1.0) ), 2.0 ) , 0.0, 1.0 );
				hitColor = checkCol0 * q + checkCol1 * (1.0 - q);	
			}

			if (bounces == 0)
				objectColor = hitColor;
			
			mask *= hitColor;

			bounceIsSpecular = FALSE;

			// choose random Diffuse sample vector
			rayDirection = randomCosWeightedDirectionInHemisphere(nl);
			rayOrigin = x + nl * uEPS_intersect;
			continue;

                } // end if (hitType == DIFF || hitType == CHECK)
		
		
	} // end for (int bounces = 0; bounces < 2; bounces++)
	
	
	return max(vec3(0), accumCol); // prevents black spot artifacts appearing in the water

} // end vec3 CalculateRadiance( vec3 rayOrigin, vec3 rayDirection, out vec3 objectNormal, out vec3 objectColor, out float objectID, out float pixelSharpness )


//-----------------------------------------------------------------------
void SetupScene(void)
//-----------------------------------------------------------------------
{
	vec3 z  = vec3(0);
	vec3 L1 = vec3(0.5, 0.7, 1.0);// Blueish sky light
        float skySphereRadius = 100000.0;
	float groundSphereRadius = 0.0;//4000.0;
	spheres[0] = Sphere( skySphereRadius, vec3(0, 0, 0), L1, z, LIGHT);//large spherical sky light
	//spheres[1] = Sphere( groundSphereRadius, vec3(0, -groundSphereRadius, 0), z, vec3(0.4, 0.4, 0.4), CHECK);//Checkered Floor
}



#include <pathtracing_main>
