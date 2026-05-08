precision highp float;
precision highp int;
precision highp sampler2D;

#include <pathtracing_uniforms_and_defines>

uniform sampler2D tShape_DataTexture;
uniform sampler2D tAABB_DataTexture;
uniform vec3 uSunDirection;

//#include <pathtracing_skymodel_defines>
#define TURBIDITY 1.0
#define RAYLEIGH_COEFFICIENT 2.0
#define MIE_COEFFICIENT 0.005
#define MIE_DIRECTIONAL_G 0.76
// constants for atmospheric scattering
#define THREE_OVER_SIXTEENPI 0.05968310365946075
#define ONE_OVER_FOURPI 0.07957747154594767
// wavelength of used primaries, according to preetham
#define LAMBDA vec3( 680E-9, 550E-9, 450E-9 )

// original Rayleigh colors, from Preetham's sky model paper
//#define TOTAL_RAYLEIGH vec3( 5.804542996261093E-6, 1.3562911419845635E-5, 3.0265902468824876E-5 )
// I lowered the red portion of this Rayleigh color, in order to make the sky a brighter blue
#define TOTAL_RAYLEIGH vec3( 2.804542996261093E-6, 1.3562911419845635E-5, 3.0265902468824876E-5 )

// mie stuff
#define UP_VECTOR vec3(0,1,0)
// K coefficient for the primaries
#define K vec3(0.686, 0.678, 0.666)
#define MIE_V 4.0
#define MIE_CONST vec3( 1.8399918514433978E14, 2.7798023919660528E14, 4.0790479543861094E14 )
// optical length at zenith for molecules
#define RAYLEIGH_ZENITH_LENGTH 8400.0//8400.0
#define MIE_ZENITH_LENGTH 1250.0//1250.0
#define SUN_POWER 1000.0//1000.0
// 66 arc seconds -> degrees, and the cosine of that
#define SUN_ANGULAR_DIAMETER_COS 0.9998 //0.9999566769
#define CUTOFF_ANGLE 1.6110731556870734
#define STEEPNESS 1.5//1.5

#include <pathtracing_physical_sky_functions>

//float InvTextureWidth = 0.000244140625; // (1 / 4096 texture width)
//float InvTextureWidth = 0.00048828125;  // (1 / 2048 texture width)
//float InvTextureWidth = 0.0009765625;   // (1 / 1024 texture width)

#define INV_TEXTURE_WIDTH 0.00048828125

#define N_BOXES 1

vec3 rayOrigin, rayDirection;
// recorded intersection data:
vec3 hitNormal, hitColor;
vec2 hitUV;
float hitObjectID;
int hitType = -100;


struct Box { vec3 minCorner; vec3 maxCorner; vec3 color; int type; };

Box boxes[N_BOXES];


#include <pathtracing_random_functions>

#include <pathtracing_calc_fresnel_reflectance>

#include <pathtracing_sphere_intersect>

#include <pathtracing_unit_box_intersect>

#include <pathtracing_box_intersect>

#include <pathtracing_boundingbox_intersect>




float stackNodeIDs[32];

//vec4 boxNodeData0 corresponds to: .x = aabbMin.x, .y = aabbMin.y, .z =      aabbMin.z, .w = aabbMax.x,
//vec4 boxNodeData1 corresponds to: .x = aabbMax.y, .y = aabbMax.z, .z = primitiveCount, .w = leafOrChild_ID

void GetBoxNodeData(const in float i, inout vec4 boxNodeData0, inout vec4 boxNodeData1)
{
	// each bounding box's data is encoded in 2 rgba(or xyzw) texture slots 
	float ix2 = i * 2.0;
	// (ix2 + 0.0) corresponds to: .x = aabbMin.x, .y = aabbMin.y, .z =      aabbMin.z, .w = aabbMax.x,
	// (ix2 + 1.0) corresponds to: .x = aabbMax.y, .y = aabbMax.z, .z = primitiveCount, .w = leafOrChild_ID 

	ivec2 uv0 = ivec2( mod(ix2 + 0.0, 2048.0), (ix2 + 0.0) * INV_TEXTURE_WIDTH ); // data0
	ivec2 uv1 = ivec2( mod(ix2 + 1.0, 2048.0), (ix2 + 1.0) * INV_TEXTURE_WIDTH ); // data1
	
	boxNodeData0 = texelFetch(tAABB_DataTexture, uv0, 0);
	boxNodeData1 = texelFetch(tAABB_DataTexture, uv1, 0);
}


//---------------------------------------------------------------------------------------
float SceneIntersect( out int isRayExiting )
//---------------------------------------------------------------------------------------
{
	mat4 invTransformMatrix, hitMatrix;
	vec4 currentBoxNodeData0, nodeAData0, nodeBData0, tmpNodeData0;
	vec4 currentBoxNodeData1, nodeAData1, nodeBData1, tmpNodeData1;
	vec4 sd0, sd1, sd2, sd3, sd4, sd5, sd6, sd7;

	vec3 inverseDir = 1.0 / rayDirection;
	vec3 normal;
	vec3 rObjOrigin, rObjDirection;
	vec3 n, hitPoint;

	ivec2 uv0, uv1, uv2, uv3, uv4, uv5, uv6, uv7;

	float stackNodeID_A, stackNodeID_B, tmpNodeID;
	float stackNodeA_t, stackNodeB_t, tmpNode_t;
	float d;
	float t = INFINITY;
	float stackptr = 0.0;
	float id = 0.0;
	float shapeID = 0.0;

	int objectCount = 0;
	
	hitObjectID = -INFINITY;

	int popNextNodeOffStack = TRUE;
	int shapeLookupNeeded = FALSE;


	GetBoxNodeData(stackptr, currentBoxNodeData0, currentBoxNodeData1);
	d = BoundingBoxIntersect(currentBoxNodeData0.xyz, vec3(currentBoxNodeData0.w, currentBoxNodeData1.xy), rayOrigin, inverseDir);
	popNextNodeOffStack = (d < t) ? FALSE : TRUE;

	while (true)
        {
		if (popNextNodeOffStack == TRUE) 
                {
                        // decrease pointer by 1.0 (0.0 is root level, 31.0 is maximum depth)
                        if (--stackptr < 0.0) // went past the root level, terminate loop
                                break;
			// pop the next node off the stack
			GetBoxNodeData(stackNodeIDs[int(stackptr)], currentBoxNodeData0, currentBoxNodeData1);
                }
		popNextNodeOffStack = TRUE; // reset popNextNodeOffStack
		

		if (currentBoxNodeData1.z == 0.0) // == 0.0 signifies an inner node
		{
			GetBoxNodeData(currentBoxNodeData1.w, nodeAData0, nodeAData1); // leftChild
			GetBoxNodeData(currentBoxNodeData1.w + 1.0, nodeBData0, nodeBData1); // rightChild
			stackNodeID_A = currentBoxNodeData1.w;
			stackNodeID_B = currentBoxNodeData1.w + 1.0;
			stackNodeA_t = BoundingBoxIntersect(nodeAData0.xyz, vec3(nodeAData0.w, nodeAData1.xy), rayOrigin, inverseDir);
			stackNodeB_t = BoundingBoxIntersect(nodeBData0.xyz, vec3(nodeBData0.w, nodeBData1.xy), rayOrigin, inverseDir);
			
			// first, sort the children nodes data so that nodeA is the closer node
			if (stackNodeB_t < stackNodeA_t)
			{
				tmpNodeID = stackNodeID_A;
				stackNodeID_A = stackNodeID_B;
				stackNodeID_B = tmpNodeID;

				tmpNode_t = stackNodeA_t;
				stackNodeA_t = stackNodeB_t;
				stackNodeB_t = tmpNode_t;

				tmpNodeData0 = nodeAData0;   tmpNodeData1 = nodeAData1;
				nodeAData0   = nodeBData0;   nodeAData1   = nodeBData1;
				nodeBData0   = tmpNodeData0; nodeBData1   = tmpNodeData1;
			} // now it's guaranteed that nodeA is the closer node and nodeB is the farther node

			if (stackNodeB_t < t) // see if the farther nodeB (the larger ray t) needs to be processed
			{
				currentBoxNodeData0 = nodeBData0;
				currentBoxNodeData1 = nodeBData1;
				popNextNodeOffStack = FALSE; // this will prevent the stackptr from decreasing by 1
			}
			
			if (stackNodeA_t < t) // see if the closer nodeA (the smaller ray t) needs to be processed 
			{
				if (popNextNodeOffStack == FALSE) // if further nodeB needed to be visited also,
					stackNodeIDs[int(stackptr++)] = stackNodeID_B; // push nodeB on stack for future round
							// also, increase stackptr by 1
				// since nodeA is always the closest node, set nodeA as the current node to be processed
				currentBoxNodeData0 = nodeAData0;
				currentBoxNodeData1 = nodeAData1;
				popNextNodeOffStack = FALSE; // this will prevent the stackptr from decreasing by 1
			}

			continue;
		} // end if (currentBoxNodeData1.z == 0.0) // inner node
		/* 
		// debug leaf AABB visualization
		d = BoxIntersect(currentBoxNodeData0.yzw, currentBoxNodeData1.yzw, rayOrigin, rayDirection, n, isRayExiting);
		if (d > 0.0 && d < t)
		{
			t = d;
			hitNormal = n;
			hitColor = vec3(1,1,0);
			hitType = REFR;
			hitObjectID = float(objectCount);
		} */

		// else this is a leaf

		// each shape's data is encoded in 8 rgba(or xyzw) texture slots
		id = 8.0 * currentBoxNodeData1.w;

		uv0 = ivec2( mod(id + 0.0, 2048.0), (id + 0.0) * INV_TEXTURE_WIDTH );
		uv1 = ivec2( mod(id + 1.0, 2048.0), (id + 1.0) * INV_TEXTURE_WIDTH );
		uv2 = ivec2( mod(id + 2.0, 2048.0), (id + 2.0) * INV_TEXTURE_WIDTH );
		uv3 = ivec2( mod(id + 3.0, 2048.0), (id + 3.0) * INV_TEXTURE_WIDTH );
		uv4 = ivec2( mod(id + 4.0, 2048.0), (id + 4.0) * INV_TEXTURE_WIDTH );
		
		invTransformMatrix = mat4( texelFetch(tShape_DataTexture, uv0, 0),
		 			   texelFetch(tShape_DataTexture, uv1, 0), 
		 			   texelFetch(tShape_DataTexture, uv2, 0), 
		 			   texelFetch(tShape_DataTexture, uv3, 0) );

		//sd4 = texelFetch(tShape_DataTexture, uv4, 0);

		// transform ray into shape's object space
		rObjOrigin = vec3( invTransformMatrix * vec4(rayOrigin, 1.0) );
		rObjDirection = vec3( invTransformMatrix * vec4(rayDirection, 0.0) );
		d = UnitBoxIntersect(rObjOrigin, rObjDirection, n);
		
		if (d < t)
		{
			t = d;
			hitNormal = n;
			hitMatrix = invTransformMatrix; // save winning matrix for hitNormal code below
			shapeID = id;
			shapeLookupNeeded = TRUE;
		}
	      
        } // end while (TRUE)



	if (shapeLookupNeeded == TRUE)
	{
		uv0 = ivec2( mod(shapeID + 0.0, 2048.0), (shapeID + 0.0) * INV_TEXTURE_WIDTH );
		uv1 = ivec2( mod(shapeID + 1.0, 2048.0), (shapeID + 1.0) * INV_TEXTURE_WIDTH );
		uv2 = ivec2( mod(shapeID + 2.0, 2048.0), (shapeID + 2.0) * INV_TEXTURE_WIDTH );
		uv3 = ivec2( mod(shapeID + 3.0, 2048.0), (shapeID + 3.0) * INV_TEXTURE_WIDTH );
		uv4 = ivec2( mod(shapeID + 4.0, 2048.0), (shapeID + 4.0) * INV_TEXTURE_WIDTH );
		uv5 = ivec2( mod(shapeID + 5.0, 2048.0), (shapeID + 5.0) * INV_TEXTURE_WIDTH );
		uv6 = ivec2( mod(shapeID + 6.0, 2048.0), (shapeID + 6.0) * INV_TEXTURE_WIDTH );
		uv7 = ivec2( mod(shapeID + 7.0, 2048.0), (shapeID + 7.0) * INV_TEXTURE_WIDTH );
		
		sd0 = texelFetch(tShape_DataTexture, uv0, 0);
		sd1 = texelFetch(tShape_DataTexture, uv1, 0);
		sd2 = texelFetch(tShape_DataTexture, uv2, 0);
		sd3 = texelFetch(tShape_DataTexture, uv3, 0);
		sd4 = texelFetch(tShape_DataTexture, uv4, 0);
		sd5 = texelFetch(tShape_DataTexture, uv5, 0);
		sd6 = texelFetch(tShape_DataTexture, uv6, 0);
		sd7 = texelFetch(tShape_DataTexture, uv7, 0);

		hitNormal = transpose(mat3(hitMatrix)) * hitNormal;
		hitColor = sd5.rgb;
		//hitUV =
		hitType = int(sd4.y);
		hitObjectID = float(objectCount);
	}
	objectCount++;


	// ground plane (large, thin flat box)
	d = BoxIntersect(boxes[0].minCorner, boxes[0].maxCorner, rayOrigin, rayDirection, n, isRayExiting);
	if (d < t)
	{
		t = d;
		hitNormal = n;
		hitColor = vec3(1);
		hitType = DIFF;
		hitObjectID = float(objectCount);
	}
	
	
	return t;

} // end float SceneIntersect( out int isRayExiting )


//-----------------------------------------------------------------------------------------------------------------------------
vec3 CalculateRadiance( out vec3 objectNormal, out vec3 objectColor, out float objectID, out float pixelSharpness )
//-----------------------------------------------------------------------------------------------------------------------------
{
	vec3 accumCol = vec3(0);
	vec3 mask = vec3(1);
	vec3 diffuseBounceMask = vec3(1);
	vec3 diffuseBounceRayOrigin = vec3(0);
	vec3 diffuseBounceRayDirection = vec3(0);
	vec3 x, n, nl;
	vec3 absorptionCoefficient;
	vec3 skyColor;
	
	float t;
	float nc, nt, ratioIoR, Re, Tr;
	float weight;
	float thickness = 0.1;
	float scatteringDistance;

	int diffuseCount = 0;
	int previousIntersecType = -100;
	hitType = -100;

	int bounceIsSpecular = TRUE;
	int sampleLight = FALSE;
	int isRayExiting = FALSE;
	int willNeedDiffuseBounceRay = FALSE;
	int isDiffuseBounceTime = FALSE;
	

	
	for (int bounces = 0; bounces < 10; bounces++)
	{
		previousIntersecType = hitType;

		t = SceneIntersect(isRayExiting);
		

		if (t == INFINITY)
		{
			skyColor = Get_Sky_Color(rayDirection);

			if (bounces == 0) // ray hits sky first
			{
				pixelSharpness = 1.0;
				
				accumCol += skyColor;
				break; // exit early	
			}
			else if (sampleLight == TRUE)
			{
				accumCol += mask * skyColor;
			}
			else if (diffuseCount > 0)
			{
				weight = dot(rayDirection, uSunDirection) < 0.99 ? 2.0 : 0.0;
				accumCol += mask * skyColor * weight;
			}

			if (willNeedDiffuseBounceRay == TRUE)
			{
				mask = diffuseBounceMask;
				rayOrigin = diffuseBounceRayOrigin;
				rayDirection = diffuseBounceRayDirection;

				willNeedDiffuseBounceRay = FALSE;
				bounceIsSpecular = FALSE;
				sampleLight = FALSE;
				isDiffuseBounceTime = TRUE;
				diffuseCount = 1;
				continue;
			}
	
			// reached the sky light, so we can exit
			break;
		} // end if (t == INFINITY)
			

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
				diffuseCount = 1;
				continue;
			}

			break;
		}
		

		    
		if (hitType == DIFF) // Ideal DIFFUSE reflection
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
			
			rayDirection = randomDirectionInSpecularLobe(nl, uSunDirection, 0.15); // create shadow ray pointed towards light
			weight = max(0.0, dot(rayDirection, nl)) * 0.03; // down-weight directSunLight contribution
			mask *= weight;
			sampleLight = TRUE;
			continue;
			
		} // end if (hitType == DIFF)
		
		
		
	} // end for (int bounces = 0; bounces < 10; bounces++)
	
	
	return max(vec3(0), accumCol);

} // end vec3 CalculateRadiance( out vec3 objectNormal, out vec3 objectColor, out float objectID, out float pixelSharpness )



//-----------------------------------------------------------------------
void SetupScene(void)
//-----------------------------------------------------------------------
{
	vec3 z  = vec3(0);// No color value, Black        
	
	boxes[0] = Box(vec3(-5000, -1, -5000), vec3(5000, 0, 5000), vec3(1), DIFF);// the Cornell Box interior
}


#include <pathtracing_main>
