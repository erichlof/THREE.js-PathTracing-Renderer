precision highp float;
precision highp int;
precision highp sampler2D;

#include <pathtracing_uniforms_and_defines>
uniform int uMaterialType;
uniform sampler2D tShape_DataTexture;
uniform sampler2D tAABB_DataTexture;

//float InvTextureWidth = 0.000244140625; // (1 / 4096 texture width)
//float InvTextureWidth = 0.00048828125;  // (1 / 2048 texture width)
//float InvTextureWidth = 0.0009765625;   // (1 / 1024 texture width)

#define INV_TEXTURE_WIDTH 0.00048828125

#define N_QUADS 1
#define N_BOXES 1

vec3 rayOrigin, rayDirection;
// recorded intersection data:
vec3 hitNormal, hitColor;
vec2 hitUV;
float hitObjectID = -INFINITY;
int hitType = -100;


struct Quad { vec3 normal; vec3 v0; vec3 v1; vec3 v2; vec3 v3; vec3 color; int type; };
struct Box { vec3 minCorner; vec3 maxCorner; vec3 color; int type; };

Quad quads[N_QUADS];
Box boxes[N_BOXES];


#include <pathtracing_random_functions>

#include <pathtracing_calc_fresnel_reflectance>

#include <pathtracing_sphere_intersect>

#include <pathtracing_unit_sphere_intersect>

#include <pathtracing_box_intersect>

#include <pathtracing_boundingbox_intersect>

#include <pathtracing_quad_intersect>

#include <pathtracing_sample_quad_light>


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

	// start with root node (bounding box around the entire model)
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
		d = BoxIntersect(currentBoxNodeData0.xyz, vec3(currentBoxNodeData0.w, currentBoxNodeData1.xy), rayOrigin, rayDirection, n, isRayExiting);
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
		d = UnitSphereIntersect(rObjOrigin, rObjDirection, n);
		
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
		hitType = (uMaterialType == 1000) ? int(sd4.y) : uMaterialType;
		hitObjectID = float(objectCount);
	}
	objectCount++;



	d = QuadIntersect( quads[0].v0, quads[0].v1, quads[0].v2, quads[0].v3, rayOrigin, rayDirection, FALSE );
	if (d < t)
	{
		t = d;
		hitNormal = quads[0].normal;
		hitColor = quads[0].color;
		hitType = quads[0].type;
		hitObjectID = float(objectCount);
	}
	objectCount++;
	
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
	Quad light = quads[0];

	vec3 accumCol = vec3(0);
	vec3 mask = vec3(1);
	vec3 reflectionMask = vec3(1);
	vec3 reflectionRayOrigin = vec3(0);
	vec3 reflectionRayDirection = vec3(0);
	vec3 diffuseBounceMask = vec3(1);
	vec3 diffuseBounceRayOrigin = vec3(0);
	vec3 diffuseBounceRayDirection = vec3(0);
	vec3 x, n, nl;
	vec3 absorptionCoefficient;
	
	float t;
	float nc, nt, ratioIoR, Re, Tr;
	float weight;
	float thickness = 0.1;
	float scatteringDistance;
	float previousObjectID;

	int reflectionBounces = -1;
	int diffuseCount = 0;
	int previousIntersecType = -100;
	hitType = -100;

	int bounceIsSpecular = TRUE;
	int sampleLight = FALSE;
	int isRayExiting = FALSE;
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

		t = SceneIntersect(isRayExiting);
		

		if (t == INFINITY)
		{
			// this makes the object edges sharp against the background
			if (bounces == 0)
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
				pixelSharpness = 1.0;

			if (isReflectionTime == TRUE && bounceIsSpecular == TRUE)
			{
				objectNormal += nl;
				//objectColor = hitColor;
				objectID += hitObjectID;
			}
			
			if (bounceIsSpecular == TRUE || sampleLight == TRUE)
				accumCol += mask * hitColor;

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
				continue;
			}
			// reached a light, so we can exit
			break;

		} // end if (hitType == LIGHT)


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
                        
			rayDirection = sampleQuadLight(x, nl, quads[0], weight);
			mask *= weight;
			sampleLight = TRUE;
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
			nc = 1.0; // IOR of Air
			nt = 1.5; // IOR of common Glass
			Re = calcFresnelReflectance(rayDirection, n, nc, nt, ratioIoR);
			Tr = 1.0 - Re;

			if (Re == 1.0)
			{
				rayDirection = reflect(rayDirection, nl);
				rayOrigin = x + nl * uEPS_intersect;
				continue;
			}

			//if (diffuseCount == 0 && hitObjectID != previousObjectID && n == nl)
			if (bounces == 0 && n == nl)
			{
				reflectionMask = mask * Re;
				reflectionRayDirection = reflect(rayDirection, nl); // reflect ray from surface
				reflectionRayOrigin = x + nl * uEPS_intersect;
				willNeedReflectionRay = TRUE;
			}

			// transmit ray through surface
			
			//is ray leaving a solid object from the inside? 
			//If so, attenuate ray color with object color by how far ray has travelled through the medium
			
			// if (distance(n, nl) > 0.1)
			// {
			// 	mask *= exp( log(clamp(hitColor, 0.01, 0.99)) * thickness * t ); 
			// }

			mask *= hitColor;
			mask *= Tr;
			
			rayDirection = refract(rayDirection, nl, ratioIoR);
			rayOrigin = x - nl * uEPS_intersect;

			if (diffuseCount == 1 && isDiffuseBounceTime == TRUE)
				bounceIsSpecular = TRUE; // turn on refracting caustics
			
			continue;
			
		} // end if (hitType == REFR)
		
		if (hitType == COAT)  // Diffuse object underneath with ClearCoat on top
		{
			nc = 1.0; // IOR of Air
			nt = 1.4; // IOR of Clear Coat
			Re = calcFresnelReflectance(rayDirection, nl, nc, nt, ratioIoR);
			Tr = 1.0 - Re;
			
			if (diffuseCount == 0 && hitObjectID != previousObjectID)
			{
				reflectionMask = mask * Re;
				reflectionRayDirection = reflect(rayDirection, nl); // reflect ray from surface
				reflectionRayOrigin = x + nl * uEPS_intersect;
				willNeedReflectionRay = TRUE;
			}

			diffuseCount++;

			mask *= Tr;
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
                        
			rayDirection = sampleQuadLight(x, nl, quads[0], weight);
			mask *= weight;
			sampleLight = TRUE;
			continue;
			
		} //end if (hitType == COAT)
		
	} // end for (int bounces = 0; bounces < 10; bounces++)
	
	
	return max(vec3(0), accumCol);

} // end vec3 CalculateRadiance( out vec3 objectNormal, out vec3 objectColor, out float objectID, out float pixelSharpness )



//-----------------------------------------------------------------------
void SetupScene(void)
//-----------------------------------------------------------------------
{
	vec3 z  = vec3(0);// No color value, Black        
	vec3 L1 = vec3(1.0, 1.0, 1.0) * 4.0;// Bright light
	float lightRadius = 100.0;
	
	quads[0] = Quad(vec3(0,-1, 0), vec3(-lightRadius, 500,-lightRadius), vec3(lightRadius, 500,-lightRadius), vec3(lightRadius, 500, lightRadius), vec3(-lightRadius, 500, lightRadius), L1, LIGHT);// Quad Area Light on ceiling

	boxes[0] = Box(vec3(-10000, -1, -10000), vec3(10000, 0, 10000), vec3(1), DIFF);// the Cornell Box interior
}


#include <pathtracing_main>
