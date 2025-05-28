precision highp float;
precision highp int;
precision highp sampler2D;

uniform sampler2D tTriangleTexture;
uniform sampler2D tAABBTexture;
uniform sampler2D tHDRTexture;

#include <pathtracing_uniforms_and_defines>

uniform vec3 uMaterialColor;
uniform vec3 uSunDirectionVector;
uniform float uHDRI_Exposure;
uniform float uRoughness;
uniform int uMaterialType;

//float InvTextureWidth = 0.000244140625; // (1 / 4096 texture width)
//float InvTextureWidth = 0.00048828125;  // (1 / 2048 texture width)
//float InvTextureWidth = 0.0009765625;   // (1 / 1024 texture width)

#define INV_TEXTURE_WIDTH 0.00048828125

// the following directions pointing at the sun were found by trial and error: left here just for reference
//#define SUN_DIRECTION normalize(vec3(-0.555, 1.0, 0.205)) // use this vec3 for the symmetrical_garden_2k.hdr environment
//#define SUN_DIRECTION normalize(vec3(0.54, 1.0, -0.595)) // use this vec3 for the kiara_5_noon_2k.hdr environment

#define N_SPHERES 4
#define N_BOXES 2

//-----------------------------------------------------------------------

vec3 rayOrigin, rayDirection;
// recorded intersection data:
vec3 hitNormal, hitEmission, hitColor;
vec2 hitUV;
float hitObjectID = -INFINITY;
int hitType = -100;
int hitIsModel;

struct Sphere { float radius; vec3 position; vec3 emission; vec3 color; int type; };
struct Box { vec3 minCorner; vec3 maxCorner; vec3 emission; vec3 color; int type; };

Sphere spheres[N_SPHERES];
Box boxes[N_BOXES];


#include <pathtracing_random_functions>

#include <pathtracing_calc_fresnel_reflectance>

#include <pathtracing_sphere_intersect>

#include <pathtracing_box_intersect>

#include <pathtracing_boundingbox_intersect>

#include <pathtracing_bvhTriangle_intersect>

//#include <pathtracing_bvhDoubleSidedTriangle_intersect>

	

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


//-----------------------------------------------------------------------------------------------------------------------------------------------
float SceneIntersect( out int finalIsRayExiting )
//-----------------------------------------------------------------------------------------------------------------------------------------------
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
	int isRayExiting = FALSE;
	hitIsModel = FALSE;


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
		//uv0 = ivec2( mod(triangleID + 0.0, 2048.0), (triangleID + 0.0) * INV_TEXTURE_WIDTH );
		//uv1 = ivec2( mod(triangleID + 1.0, 2048.0), (triangleID + 1.0) * INV_TEXTURE_WIDTH );
		uv2 = ivec2( mod(triangleID + 2.0, 2048.0), (triangleID + 2.0) * INV_TEXTURE_WIDTH );
		uv3 = ivec2( mod(triangleID + 3.0, 2048.0), (triangleID + 3.0) * INV_TEXTURE_WIDTH );
		uv4 = ivec2( mod(triangleID + 4.0, 2048.0), (triangleID + 4.0) * INV_TEXTURE_WIDTH );
		uv5 = ivec2( mod(triangleID + 5.0, 2048.0), (triangleID + 5.0) * INV_TEXTURE_WIDTH );
		//uv6 = ivec2( mod(triangleID + 6.0, 2048.0), (triangleID + 6.0) * INV_TEXTURE_WIDTH );
		//uv7 = ivec2( mod(triangleID + 7.0, 2048.0), (triangleID + 7.0) * INV_TEXTURE_WIDTH );
		
		//vd0 = texelFetch(tTriangleTexture, uv0, 0);
		//vd1 = texelFetch(tTriangleTexture, uv1, 0);
		vd2 = texelFetch(tTriangleTexture, uv2, 0);
		vd3 = texelFetch(tTriangleTexture, uv3, 0);
		vd4 = texelFetch(tTriangleTexture, uv4, 0);
		vd5 = texelFetch(tTriangleTexture, uv5, 0);
		//vd6 = texelFetch(tTriangleTexture, uv6, 0);
		//vd7 = texelFetch(tTriangleTexture, uv7, 0);

	
		// face normal for flat-shaded polygon look
		//hitNormal = normalize( cross(vec3(vd0.w, vd1.xy) - vec3(vd0.xyz), vec3(vd1.zw, vd2.x) - vec3(vd0.xyz)) );
		
		// interpolated normal using triangle intersection's uv's
		triangleW = 1.0 - triangleU - triangleV;
		hitNormal = triangleW * vec3(vd2.yzw) + triangleU * vec3(vd3.xyz) + triangleV * vec3(vd3.w, vd4.xy);
		hitEmission = vec3(0);
		hitColor = uMaterialColor;//vd6.yzw;
		hitUV = triangleW * vec2(vd4.zw) + triangleU * vec2(vd5.xy) + triangleV * vec2(vd5.zw); 
		hitType = int(uMaterialType);//int(vd6.x);
		//hitAlbedoTextureID = -1;//int(vd7.x);
		hitIsModel = TRUE;
		hitObjectID = float(objectCount);
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
		hitIsModel = FALSE;
		hitObjectID = float(objectCount);
	}
	objectCount++;

	d = SphereIntersect( spheres[1].radius, spheres[1].position, rayOrigin, rayDirection );
	if (d < t)
	{
		t = d;
		hitNormal = (rayOrigin + rayDirection * t) - spheres[1].position;
		hitEmission = spheres[1].emission;
		hitColor = spheres[1].color;
		hitType = spheres[1].type;
		hitIsModel = FALSE;
		hitObjectID = float(objectCount);
	}
	objectCount++;

	d = SphereIntersect( spheres[2].radius, spheres[2].position, rayOrigin, rayDirection );
	if (d < t)
	{
		t = d;
		hitNormal = (rayOrigin + rayDirection * t) - spheres[2].position;
		hitEmission = spheres[2].emission;
		hitColor = spheres[2].color;
		hitType = spheres[2].type;
		hitIsModel = FALSE;
		hitObjectID = float(objectCount);
	}
	objectCount++;

	d = SphereIntersect( spheres[3].radius, spheres[3].position, rayOrigin, rayDirection );
	if (d < t)
	{
		t = d;
		hitNormal = (rayOrigin + rayDirection * t) - spheres[3].position;
		hitEmission = spheres[3].emission;
		hitColor = spheres[3].color;
		hitType = spheres[3].type;
		hitIsModel = FALSE;
		hitObjectID = float(objectCount);
	}
	objectCount++;


	d = BoxIntersect( boxes[0].minCorner, boxes[0].maxCorner, rayOrigin, rayDirection, normal, isRayExiting );
	if (d < t)
	{
		t = d;
		hitNormal = normal;
		hitEmission = boxes[0].emission;
		hitColor = boxes[0].color;
		hitType = boxes[0].type;
		hitIsModel = FALSE;
		finalIsRayExiting = isRayExiting;
		hitObjectID = float(objectCount);
	}
	objectCount++;

	d = BoxIntersect( boxes[1].minCorner, boxes[1].maxCorner, rayOrigin, rayDirection, normal, isRayExiting );
	if (d < t)
	{
		t = d;
		hitNormal = normal;
		hitEmission = boxes[1].emission;
		hitColor = boxes[1].color;
		hitType = boxes[1].type;
		hitIsModel = FALSE;
		finalIsRayExiting = isRayExiting;
		hitObjectID = float(objectCount);
	}
	


	return t;

} // end float SceneIntersect( out int finalIsRayExiting )



vec3 Get_HDR_Color(vec3 rDirection)
{
	vec2 sampleUV;
	//sampleUV.y = asin(clamp(rDirection.y, -1.0, 1.0)) * ONE_OVER_PI + 0.5;
	///sampleUV.x = (1.0 + atan(rDirection.x, -rDirection.z) * ONE_OVER_PI) * 0.5;
	sampleUV.x = atan(rDirection.x, -rDirection.z) * ONE_OVER_TWO_PI + 0.5;
  	sampleUV.y = acos(rDirection.y) * ONE_OVER_PI;
	vec3 texColor = texture(tHDRTexture, sampleUV).rgb;

	// texColor = texData.a > 0.57 ? vec3(100) : vec3(0);
	// return texColor;
	return texColor * uHDRI_Exposure;
}


//----------------------------------------------------------------------------------------------------------------------------------------------------
vec3 CalculateRadiance( out vec3 objectNormal, out vec3 objectColor, out float objectID, out float pixelSharpness )
//----------------------------------------------------------------------------------------------------------------------------------------------------
{
	vec3 accumCol = vec3(0);
        vec3 mask = vec3(1);
	vec3 reflectionMask = vec3(1);
	vec3 reflectionRayOrigin = vec3(0);
	vec3 reflectionRayDirection = vec3(0);
	vec3 diffuseBounceMask = vec3(1);
	vec3 diffuseBounceRayOrigin = vec3(0);
	vec3 diffuseBounceRayDirection = vec3(0);
	vec3 checkCol0 = vec3(1);
	vec3 checkCol1 = vec3(0.5);
        vec3 tdir;
	vec3 x, n, nl;
        
	float t;
        float nc, nt, ratioIoR, Re, Tr;
	float weight;
	float thickness = 0.1;
	float roughness = 0.0;
	float previousObjectID;

	int reflectionBounces = -1;
	int diffuseCount = 0;
	int previousIntersecType = -100;
	hitType = -100;

	int coatTypeIntersected = FALSE;
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
		roughness = hitIsModel == TRUE ? uRoughness : roughness;
		
		
		if (t == INFINITY)
		{	
                        vec3 environmentCol = Get_HDR_Color(rayDirection);

			// looking directly at sky
			if (bounces == 0)
			{
				pixelSharpness = 1.0;

				accumCol += environmentCol;
				break;
			}

			// sun light source location in HDRI image is sampled by a diffuse surface
			// mask has already been down-weighted in this case
			if (sampleLight == TRUE)
			{
				accumCol += mask * environmentCol;
				//break;
			}

			// random diffuse bounce hits sky
			else if (bounceIsSpecular == FALSE)
			{
				weight = dot(rayDirection, uSunDirectionVector) < 0.98 ? 1.0 : 0.0;
				accumCol += mask * environmentCol * weight;

				if (bounces == 3)
					accumCol += mask * environmentCol * weight * 2.0; // ground beneath glass table

				//break;
			}
			
			if (bounceIsSpecular == TRUE)
			{
				if (coatTypeIntersected == TRUE)
				{
					if (dot(rayDirection, uSunDirectionVector) > 0.998)
						pixelSharpness = 1.0;
				}
				else
					pixelSharpness = 1.0;

				
				if (dot(rayDirection, uSunDirectionVector) > 0.8)
				{
					environmentCol = mix(vec3(1), environmentCol, clamp(pow(1.0-roughness, 20.0), 0.0, 1.0));
				}
					
				accumCol += mask * environmentCol;
				//break;
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
					
			// reached the HDRI sky light, so we can exit
			break;

		} // end if (t == INFINITY)


		// useful data 
		n = normalize(hitNormal);
                nl = dot(n, rayDirection) < 0.0 ? n : -n;
		x = rayOrigin + rayDirection * t;

		if (bounces == 0)
		{
			objectID = hitObjectID;
		}
		if (isReflectionTime == FALSE && diffuseCount == 0 && hitObjectID != previousObjectID && coatTypeIntersected == FALSE)
		{
			objectNormal += n;
			objectColor += hitColor;
		}
		/* if (reflectionNeedsToBeSharp == TRUE && reflectionBounces == 0)
		{
			objectNormal += n;
			objectColor += hitColor;
		} */


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
		
		
		    
                if (hitType == DIFF || hitType == CHECK) // Ideal DIFFUSE reflection
                {
			if( hitType == CHECK )
			{
				float q = clamp( mod( dot( floor(x.xz * 0.04), vec2(1.0) ), 2.0 ) , 0.0, 1.0 );
				hitColor = checkCol0 * q + checkCol1 * (1.0 - q);	
			}
			if (diffuseCount == 0 && coatTypeIntersected == FALSE)	
				objectColor = hitColor;

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

			rayDirection = randomDirectionInSpecularLobe(uSunDirectionVector, 0.07);
			weight = max(0.0, dot(rayDirection, nl)) * 0.000015; // down-weight directSunLight contribution
			mask *= weight;
			sampleLight = TRUE;
			continue;
                }
		
                if (hitType == SPEC)  // Ideal SPECULAR reflection
                {
			mask *= hitColor;

			rayDirection = randomDirectionInSpecularLobe(reflect(rayDirection, nl), roughness);
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
			
			//if (bounces == 0 || (bounces == 1 && hitObjectID != objectID && bounceIsSpecular == TRUE))
			if (diffuseCount == 0 && hitObjectID != previousObjectID && n == nl)
			{
				reflectionMask = mask * Re;
				reflectionRayDirection = reflect(rayDirection, nl); // reflect ray from surface
				reflectionRayDirection = randomDirectionInSpecularLobe(reflectionRayDirection, roughness);
				reflectionRayOrigin = x + nl * uEPS_intersect;
				willNeedReflectionRay = TRUE;
				if (bounces == 0 && hitColor == vec3(0.2,0.9,0.7) && isRayExiting == FALSE)
					reflectionNeedsToBeSharp = TRUE;
			}

			// transmit ray through surface
			
			// is ray leaving a solid object from the inside? 
			// If so, attenuate ray color with object color by how far ray has travelled through the medium
			if (isRayExiting == TRUE || (distance(n, nl) > 0.1))
			{
				isRayExiting = FALSE;
				mask *= exp(log(hitColor) * thickness * t);
			}
			else 
				mask *= hitColor;

			mask *= Tr;
			
			tdir = refract(rayDirection, nl, ratioIoR);
			rayDirection = randomDirectionInSpecularLobe(tdir, roughness * roughness);
			rayOrigin = x - nl * uEPS_intersect;

			continue;
			
		} // end if (hitType == REFR)
		
		if (hitType == COAT)  // Diffuse object underneath with ClearCoat on top (like car, or shiny pool ball)
		{
			coatTypeIntersected = TRUE;

			nc = 1.0; // IOR of Air
			nt = 1.5; // IOR of Clear Coat
			Re = calcFresnelReflectance(rayDirection, nl, nc, nt, ratioIoR);
			Tr = 1.0 - Re;
			
			//if (bounces == 0 || (bounces == 1 && hitObjectID != objectID && bounceIsSpecular == TRUE))
			if (diffuseCount == 0 && hitObjectID != previousObjectID)
			{
				reflectionMask = mask * Re;
				reflectionRayDirection = reflect(rayDirection, nl); // reflect ray from surface
				reflectionRayDirection = randomDirectionInSpecularLobe(reflectionRayDirection, roughness);
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

			rayDirection = randomDirectionInSpecularLobe(uSunDirectionVector, 0.07);
			weight = max(0.0, dot(rayDirection, nl)) * 0.000015; // down-weight directSunLight contribution
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
	vec3 z  = vec3(0);          
	
	spheres[0] = Sphere(  4000.0, vec3(0, -4000, 0),  z, vec3(0.4,0.4,0.4), CHECK);//Checkered Floor
	spheres[1] = Sphere(     6.0, vec3(55, 36, -45),  z,         vec3(0.9),  SPEC);//small mirror ball
	spheres[2] = Sphere(     6.0, vec3(55, 24, -45),  z, vec3(0.5,1.0,1.0),  REFR);//small glass ball
	spheres[3] = Sphere(     6.0, vec3(60, 24, -30),  z,         vec3(1.0),  COAT);//small plastic ball

	boxes[0] = Box( vec3(-20.0,11.0,-110.0), vec3(70.0,18.0,-20.0), z, vec3(0.2,0.9,0.7), REFR);//Glass Box
	boxes[1] = Box( vec3(-14.0,13.0,-104.0), vec3(64.0,16.0,-26.0), z, vec3(0),           DIFF);//Inner Box
}


#include <pathtracing_main>
