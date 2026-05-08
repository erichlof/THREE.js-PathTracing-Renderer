precision highp float;
precision highp int;
precision highp sampler2D;

#include <pathtracing_uniforms_and_defines>

uniform sampler2D tQuadTexture;
uniform sampler2D tAABBTexture;
uniform sampler2D tAlbedoTexture;
uniform mat4 uQuadModel_InvMatrix;
uniform float uFrontLeftVertexHeight;
uniform float uFrontMiddleVertexHeight;
uniform float uFrontRightVertexHeight;
uniform float uRearLeftVertexHeight;
uniform float uRearMiddleVertexHeight;
uniform float uRearRightVertexHeight;
uniform bool uModelUsesVertexNormals;

//float InvTextureWidth = 0.00048828125;  // (1 / 2048 texture width)
//float InvTextureWidth = 0.000244140625; // (1 / 4096 texture width)
#define INV_TEXTURE_WIDTH 0.000244140625

#define N_QUADS 1
#define N_BOXES 1
#define N_BILINEAR_PATCHES 2

vec3 rayOrigin, rayDirection;
// recorded intersection data:
vec3 hitNormal, hitEmission, hitColor;
vec2 hitUV;
float hitObjectID = -INFINITY;
int hitType = -100;
int modelWasIntersected = FALSE;

struct Quad { vec3 normal; vec3 v0; vec3 v1; vec3 v2; vec3 v3; vec3 emission; vec3 color; int type; };
struct Box { vec3 minCorner; vec3 maxCorner; vec3 emission; vec3 color; int type; };
struct BiLinearPatch { vec3 p0; vec3 p1; vec3 p2; vec3 p3; vec3 emission; vec3 color; int type; };

Quad quads[N_QUADS];
Box boxes[N_BOXES];
BiLinearPatch bilinearPatches[N_BILINEAR_PATCHES];


#include <pathtracing_random_functions>

#include <pathtracing_calc_fresnel_reflectance>

#include <pathtracing_sphere_intersect>

#include <pathtracing_bilinear_patch_intersect>

#include <pathtracing_quad_intersect>

#include <pathtracing_box_interior_intersect>

#include <pathtracing_boundingbox_intersect>

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
	vec4 vd0, vd1, vd2, vd3, vd4, vd5, vd6, vd7, vd8;

	vec3 inverseDir = 1.0 / rayDirection;
	vec3 rObjOrigin, rObjDirection;
	vec3 normal, hitPoint;
	
	ivec2 uv0, uv1, uv2, uv3, uv4, uv5, uv6, uv7, uv8;

	float stackNodeID_A, stackNodeID_B, tmpNodeID;
	float stackNodeA_t, stackNodeB_t, tmpNode_t;
	float stackptr = 0.0;
	float id = 0.0;
	float d;
	float quadID = 0.0;
	float quadU, quadV;
	float t = INFINITY;
	float u, v;

	int objectCount = 0;
	int popNextNodeOffStack = TRUE;
	int quadLookupNeeded = FALSE;

	hitObjectID = -INFINITY;
	modelWasIntersected = FALSE;

	// transform ray into GLTF_Model's object space
	rObjOrigin = vec3( uQuadModel_InvMatrix * vec4(rayOrigin, 1.0) );
	rObjDirection = vec3( uQuadModel_InvMatrix * vec4(rayDirection, 0.0) );
	inverseDir = 1.0 / rObjDirection;

	GetBoxNodeData(stackptr, currentBoxNodeData0, currentBoxNodeData1);
	d = BoundingBoxIntersect(currentBoxNodeData0.xyz, vec3(currentBoxNodeData0.w, currentBoxNodeData1.xy), rObjOrigin, inverseDir);
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
			stackNodeA_t = BoundingBoxIntersect(nodeAData0.xyz, vec3(nodeAData0.w, nodeAData1.xy), rObjOrigin, inverseDir);
			stackNodeB_t = BoundingBoxIntersect(nodeBData0.xyz, vec3(nodeBData0.w, nodeBData1.xy), rObjOrigin, inverseDir);
			
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


		// else this is a leaf

		// each quad's data is encoded in 16 rgba(or xyzw) texels
		id = 16.0 * currentBoxNodeData1.w;

		uv0 = ivec2( mod(id + 0.0, 4096.0), (id + 0.0) * INV_TEXTURE_WIDTH );
		uv1 = ivec2( mod(id + 1.0, 4096.0), (id + 1.0) * INV_TEXTURE_WIDTH );
		uv2 = ivec2( mod(id + 2.0, 4096.0), (id + 2.0) * INV_TEXTURE_WIDTH );
		
		vd0 = texelFetch(tQuadTexture, uv0, 0);
		vd1 = texelFetch(tQuadTexture, uv1, 0);
		vd2 = texelFetch(tQuadTexture, uv2, 0);

		d = BilinearPatchIntersect( vec3(vd0.xyz), vec3(vd0.w,vd1.xy), vec3(vd1.zw,vd2.x), vec3(vd2.yzw), rObjOrigin, rObjDirection, FALSE, normal, u, v );
		if (d < t)
		{
			t = d;
			hitNormal = normal;
			//hitNormal = transpose(mat3(uQuadModel_InvMatrix)) * hitNormal; // transform normal back into world space
			quadID = id;
			quadU = u;
			quadV = v;
			quadLookupNeeded = TRUE;
			modelWasIntersected = TRUE;
		}
	      
        } // end while (TRUE)



	if (quadLookupNeeded == TRUE)
	{
		//uv0 = ivec2( mod(quadID + 0.0, 4096.0), (quadID + 0.0) * INV_TEXTURE_WIDTH ); // quad vertex positions data
		//uv1 = ivec2( mod(quadID + 1.0, 4096.0), (quadID + 1.0) * INV_TEXTURE_WIDTH ); // quad vertex positions data
		//uv2 = ivec2( mod(quadID + 2.0, 4096.0), (quadID + 2.0) * INV_TEXTURE_WIDTH ); // quad vertex positions data
		uv3 = ivec2( mod(quadID + 3.0, 4096.0), (quadID + 3.0) * INV_TEXTURE_WIDTH ); // quad vertex normals data
		uv4 = ivec2( mod(quadID + 4.0, 4096.0), (quadID + 4.0) * INV_TEXTURE_WIDTH ); // quad vertex normals data
		uv5 = ivec2( mod(quadID + 5.0, 4096.0), (quadID + 5.0) * INV_TEXTURE_WIDTH ); // quad vertex normals data
		uv6 = ivec2( mod(quadID + 6.0, 4096.0), (quadID + 6.0) * INV_TEXTURE_WIDTH ); // quad vertex uv texture coords data
		uv7 = ivec2( mod(quadID + 7.0, 4096.0), (quadID + 7.0) * INV_TEXTURE_WIDTH ); // quad vertex uv texture coords data
		uv8 = ivec2( mod(quadID + 8.0, 4096.0), (quadID + 8.0) * INV_TEXTURE_WIDTH ); // quad face color rgba data
		//vd0 = texelFetch(tQuadTexture, uv0, 0); // quad vertex positions data
		//vd1 = texelFetch(tQuadTexture, uv1, 0); // quad vertex positions data
		//vd2 = texelFetch(tQuadTexture, uv2, 0); // quad vertex positions data
		vd3 = texelFetch(tQuadTexture, uv3, 0); // quad vertex normals data
		vd4 = texelFetch(tQuadTexture, uv4, 0); // quad vertex normals data
		vd5 = texelFetch(tQuadTexture, uv5, 0); // quad vertex normals data
		vd6 = texelFetch(tQuadTexture, uv6, 0); // quad vertex uv texture coords data
		vd7 = texelFetch(tQuadTexture, uv7, 0); // quad vertex uv texture coords data
		vd8 = texelFetch(tQuadTexture, uv8, 0); // quad face color rgba data

		if (uModelUsesVertexNormals)
		{
			//vn0 = vec3(vd3.xyz); vn1 = vec3(vd3.w, vd4.xy); vn2 = vec3(vd4.zw, vd5.x); vn3 = vec3(vd5.yzw);
			//hitNormal = mix(mix(vn0, vn1, quadU), mix(vn3, vn2, quadU), quadV); // shading normal
			hitNormal = mix(mix(vec3(vd3.xyz), vec3(vd3.w, vd4.xy), quadU), mix(vec3(vd5.yzw), vec3(vd4.zw, vd5.x), quadU), quadV); // shading normal
			hitColor = vec3(1, 1, 1); // model's albedo color texture map will be applied later
		}
		else
		{
			hitColor = vd8.rgb; // use the random color for this quad face that was assigned at startup
		}

		hitNormal = transpose(mat3(uQuadModel_InvMatrix)) * hitNormal; // transform normal back into world space
		
		//vtc0 = vec2(vd6.xy); vtc1 = vec2(vd6.zw); vtc2 = vec2(vd7.xy); vtc3 = vec2(vd7.zw);
		//hitUV = mix(mix(vtc0, vtc1, quadU), mix(vtc3, vtc2, quadU), quadV);
		hitUV = mix(mix(vec2(vd6.xy), vec2(vd6.zw), quadU), mix(vec2(vd7.zw), vec2(vd7.xy), quadU), quadV);   
		
		hitEmission = vec3(0, 0, 0); // use this if hitType will be LIGHT
		
		
		hitType = COAT;
		//hitAlbedoTextureID = int(vd7.x);
		hitObjectID = float(objectCount);
	}
	objectCount++;


	
	d = QuadIntersect( quads[0].v0, quads[0].v1, quads[0].v2, quads[0].v3, rayOrigin, rayDirection, FALSE );
	if (d < t)
	{
		t = d;
		hitNormal = quads[0].normal;
		hitEmission = quads[0].emission;
		hitColor = quads[0].color;
		hitType = quads[0].type;
		hitObjectID = float(objectCount);
		modelWasIntersected = FALSE;
	}
	objectCount++;
	
	d = BoxInteriorIntersect( boxes[0].minCorner, boxes[0].maxCorner, rayOrigin, rayDirection, normal );
	if (d < t && normal != vec3(0,0,-1))
	{
		t = d;
		hitNormal = normal;
		hitEmission = boxes[0].emission;
		hitColor = vec3(1);
		hitType = DIFF;

		if (normal == vec3(1,0,0)) // left wall
		{
			hitColor = vec3(0.7, 0.05, 0.05);
		}
		else if (normal == vec3(-1,0,0)) // right wall
		{
			hitColor = vec3(0.05, 0.05, 0.7);
		}
		
		hitObjectID = float(objectCount);
		modelWasIntersected = FALSE;
	}
	objectCount++;
	

	d = BilinearPatchIntersect( bilinearPatches[0].p0, bilinearPatches[0].p1, bilinearPatches[0].p2, bilinearPatches[0].p3, rayOrigin, rayDirection, TRUE, normal, u, v );
	if (d < t)
	{
		t = d;
		hitNormal = normal;
		hitEmission = bilinearPatches[0].emission;
		hitColor = bilinearPatches[0].color;
		hitType = bilinearPatches[0].type;
		hitObjectID = float(objectCount);
		modelWasIntersected = FALSE;
	}
	objectCount++;

	d = BilinearPatchIntersect( bilinearPatches[1].p0, bilinearPatches[1].p1, bilinearPatches[1].p2, bilinearPatches[1].p3, rayOrigin, rayDirection, TRUE, normal, u, v );
	if (d < t)
	{
		t = d;
		hitNormal = normal;
		hitEmission = bilinearPatches[1].emission;
		hitColor = bilinearPatches[1].color;
		hitType = bilinearPatches[1].type;
		hitObjectID = float(objectCount);
		modelWasIntersected = FALSE;
	}
	objectCount++;

	
	return t;

} // end float SceneIntersect( )


//-----------------------------------------------------------------------------------------------------------------------------
vec3 CalculateRadiance( out vec3 objectNormal, out vec3 objectColor, out float objectID, out float pixelSharpness )
//-----------------------------------------------------------------------------------------------------------------------------
{
	Quad light = quads[0];

	vec4 textureColor;

	vec3 accumCol = vec3(0);
	vec3 mask = vec3(1);
	vec3 reflectionMask = vec3(1);
	vec3 reflectionRayOrigin = vec3(0);
	vec3 reflectionRayDirection = vec3(0);
	vec3 dirToLight;
	vec3 x, n, nl;
	vec3 absorptionCoefficient;
	
	float t;
	float nc, nt, ratioIoR, Re, Tr;
	float weight;
	float thickness = 0.05;
	float scatteringDistance;
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
	

	for (int bounces = 0; bounces < 6; bounces++)
	{
		if (isReflectionTime == TRUE)
			reflectionBounces++;

		previousIntersecType = hitType;
		previousObjectID = hitObjectID;

		t = SceneIntersect();
		

		if (t == INFINITY)
		{
			// this makes the object edges sharp against the black background
			if (bounces == 0 || (bounces == 1 && previousIntersecType == SPEC))
				pixelSharpness = 1.01;

			if (willNeedReflectionRay == TRUE)
			{
				mask = reflectionMask;
				rayOrigin = reflectionRayOrigin;
				rayDirection = reflectionRayDirection;

				willNeedReflectionRay = FALSE;
				bounceIsSpecular = TRUE;
				sampleLight = FALSE;
				//diffuseCount = 0;
				isReflectionTime = TRUE;
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
		if (reflectionNeedsToBeSharp == TRUE && reflectionBounces == 0)
		{
			objectNormal += n;
			objectColor += hitColor;
		}
		
		
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
				accumCol += mask * hitEmission;

			if (willNeedReflectionRay == TRUE)
			{
				mask = reflectionMask;
				rayOrigin = reflectionRayOrigin;
				rayDirection = reflectionRayDirection;

				willNeedReflectionRay = FALSE;
				bounceIsSpecular = TRUE;
				sampleLight = FALSE;
				//diffuseCount = 0;
				isReflectionTime = TRUE;
				continue;
			}
			// reached a light, so we can exit
			break;

		} // end if (hitType == LIGHT)


		// if we get here and sampleLight is still TRUE, shadow ray failed to find the light source 
		// the ray hit an occluding object along its way to the light
		if (sampleLight == TRUE)
		{
			if (willNeedReflectionRay == TRUE)
			{
				mask = reflectionMask;
				rayOrigin = reflectionRayOrigin;
				rayDirection = reflectionRayDirection;

				willNeedReflectionRay = FALSE;
				bounceIsSpecular = TRUE;
				sampleLight = FALSE;
				//diffuseCount = 0;
				isReflectionTime = TRUE;
				continue;
			}

			break;
		}
		

		    
		if (hitType == DIFF) // Ideal DIFFUSE reflection
		{
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
			
			dirToLight = sampleQuadLight(x, nl, quads[0], weight);
			mask *= diffuseCount == 1 ? 2.0 : 1.0;
			mask *= weight;

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
			continue;

		} // end if (hitType == SPEC)

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

			if (diffuseCount == 0 && hitObjectID != previousObjectID && n == nl)
			{
				reflectionMask = mask * Re;
				reflectionRayDirection = reflect(rayDirection, nl); // reflect ray from surface
				reflectionRayOrigin = x + nl * uEPS_intersect;
				willNeedReflectionRay = TRUE;
			}

			// transmit ray through surface
			
			// is ray leaving a solid object from the inside? 
			// If so, attenuate ray color with object color by how far ray has travelled through the medium
			// if (distance(n, nl) > 0.1)
			// {
			// 	thickness = 0.01;
			// 	mask *= exp( log(clamp(hitColor, 0.01, 0.99)) * thickness * t ); 
			// }

			mask *= Tr;
			mask *= hitColor;

			rayDirection = refract(rayDirection, nl, ratioIoR);
			rayOrigin = x - nl * uEPS_intersect;

			if (diffuseCount == 1 && isReflectionTime == FALSE)
				bounceIsSpecular = TRUE; // turn on refracting caustics

			continue;
			
		} // end if (hitType == REFR)
		
		if (hitType == COAT)  // Diffuse object underneath with ClearCoat on top
		{
			nc = 1.0; // IOR of Air
			nt = 1.4; // IOR of Clear Coat
			Re = calcFresnelReflectance(rayDirection, nl, nc, nt, ratioIoR);
			Tr = 1.0 - Re;
			
			if (bounces == 0)
			{
				reflectionMask = mask * Re;
				reflectionRayDirection = reflect(rayDirection, nl); // reflect ray from surface
				reflectionRayOrigin = x + nl * uEPS_intersect;
				willNeedReflectionRay = TRUE;
				//reflectionNeedsToBeSharp = TRUE;
			}

			diffuseCount++;

			if (uModelUsesVertexNormals && modelWasIntersected == TRUE)
			{
				textureColor = texture(tAlbedoTexture, hitUV);
				hitColor *= (textureColor.rgb * textureColor.rgb);
			}
			
			mask *= Tr;
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

			dirToLight = sampleQuadLight(x, nl, quads[0], weight);
			mask *= diffuseCount == 1 ? 2.0 : 1.0;
			mask *= weight;
			
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
	vec3 z  = vec3(0);// No color value, Black        
	vec3 L1 = vec3(1.0, 1.0, 1.0) * 5.0;// Bright light
	float wallRadius = 50.0;
	float lightRadius = 10.0;
	
	quads[0] = Quad( vec3(0,-1, 0), vec3(-lightRadius, wallRadius-1.0,-lightRadius), vec3(lightRadius, wallRadius-1.0,-lightRadius), vec3(lightRadius, wallRadius-1.0, lightRadius), vec3(-lightRadius, wallRadius-1.0, lightRadius), L1, z, LIGHT);// Quad Area Light on ceiling

	boxes[0] = Box( vec3(-wallRadius), vec3(wallRadius), z, vec3(1), DIFF);// the Cornell Box interior

	bilinearPatches[0] = BiLinearPatch(vec3(-40,uFrontLeftVertexHeight,10), vec3(-20,uFrontMiddleVertexHeight,10), vec3(-20,uRearMiddleVertexHeight,-10), vec3(-40,uRearLeftVertexHeight,-10), z, vec3(0,1,1), COAT);// cyan BiLinear Patch
	bilinearPatches[1] = BiLinearPatch(vec3(-20,uFrontMiddleVertexHeight,10), vec3(0,uFrontRightVertexHeight,10), vec3(0,uRearRightVertexHeight,-10), vec3(-20,uRearMiddleVertexHeight,-10), z, vec3(1,1,0), COAT);// yellow BiLinear Patch
}


#include <pathtracing_main>
