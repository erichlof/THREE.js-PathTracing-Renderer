precision highp float;
precision highp int;
precision highp sampler2D;

uniform mat4 uGLTF_Model_InvMatrix;
uniform vec3 uGLTF_Model_Position;

#include <pathtracing_uniforms_and_defines>

uniform sampler2D tTriangleTexture;
uniform sampler2D tAABBTexture;

uniform sampler2D tAlbedoMap;
uniform sampler2D tEmissiveMap;
uniform sampler2D tMetallicRoughnessMap;
uniform sampler2D tNormalMap;

//float InvTextureWidth = 0.000244140625; // (1 / 4096 texture width)
//float InvTextureWidth = 0.00048828125;  // (1 / 2048 texture width)
//float InvTextureWidth = 0.0009765625;   // (1 / 1024 texture width)

#define INV_TEXTURE_WIDTH 0.00048828125

#define N_SPHERES 3
#define N_BOXES 2

//-----------------------------------------------------------------------

vec3 rayOrigin, rayDirection;
// recorded intersection data:
vec3 hitNormal, hitEmission, hitColor;
vec2 hitUV;
int hitTextureID;
float hitObjectID;
int hitType = -100;

float diskRadius;
vec3 diskPos, diskNormal, diskEmission, diskColor;
int diskType;

float openCylinderRadius;
vec3 openCylinderPos0, openCylinderPos1, openCylinderEmission, openCylinderColor;
int openCylinderType;

struct Sphere { float radius; vec3 position; vec3 emission; vec3 color; int type; };
struct Box { vec3 minCorner; vec3 maxCorner; vec3 emission; vec3 color; int type; };

Sphere spheres[N_SPHERES];
Box boxes[N_BOXES];


#include <pathtracing_random_functions>

#include <pathtracing_calc_fresnel_reflectance>

#include <pathtracing_disk_intersect>

#include <pathtracing_sphere_intersect>
                                
#include <pathtracing_opencylinder_intersect>

#include <pathtracing_box_intersect>

#include <pathtracing_boundingbox_intersect>

#include <pathtracing_bvhTriangle_intersect>
//#include <pathtracing_bvhDoubleSidedTriangle_intersect>

#include <pathtracing_sample_sphere_light>


vec3 perturbNormal(vec3 nl, vec2 normalScale, vec2 uv)
{
	// note: incoming vec3 nl is assumed to be normalized
        vec3 S = normalize( cross( abs(nl.y) < 0.9 ? vec3(0, 1, 0) : vec3(0, 0, 1), nl ) );
        vec3 T = cross(nl, S);
        vec3 N = nl;
	// invert S, T when the UV direction is backwards (from mirrored faces),
	// otherwise it will do the normal mapping backwards.
	vec3 NfromST = cross( S, T );
	if( dot( NfromST, N ) < 0.0 )
	{
		S *= -1.0;
		T *= -1.0;
	}
        mat3 tsn = mat3( S, T, N );

	vec3 mapN = texture(tNormalMap, uv).xyz * 2.0 - 1.0;
	//mapN = normalize(mapN);
        mapN.xy *= normalScale;
        
        return normalize( tsn * mapN );
}


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


//--------------------------------------------------------------------------------------------------------------
float SceneIntersect( vec3 rayOrigin, vec3 rayDirection, out int isRayExiting )
//--------------------------------------------------------------------------------------------------------------
{
	vec4 currentBoxNodeData0, nodeAData0, nodeBData0, tmpNodeData0;
	vec4 currentBoxNodeData1, nodeAData1, nodeBData1, tmpNodeData1;
	
	vec4 vd0, vd1, vd2, vd3, vd4, vd5, vd6, vd7;

	vec3 inverseDir = 1.0 / rayDirection;
	vec3 normal;
	vec3 hitPos, toLightBulb;

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


	for (int i = 0; i < N_SPHERES; i++)
        {
		d = SphereIntersect( spheres[i].radius, spheres[i].position, rayOrigin, rayDirection );
		if (d < t)
		{
			t = d;
			hitNormal = (rayOrigin + rayDirection * t) - spheres[i].position;
			hitEmission = spheres[i].emission;
			hitColor = spheres[i].color;
			hitType = spheres[i].type;
			hitObjectID = float(objectCount);
		}
		objectCount++;
	}
	
	for (int i = 0; i < N_BOXES; i++)
        {
		d = BoxIntersect( boxes[i].minCorner, boxes[i].maxCorner, rayOrigin, rayDirection, normal, isRayExiting );
		if (d < t)
		{
			t = d;
			hitNormal = normal;
			hitEmission = boxes[i].emission;
			hitColor = boxes[i].color;
			hitType = boxes[i].type;
			hitObjectID = float(objectCount);
		}
		objectCount++;
	}
	
	d = DiskIntersect( diskRadius, diskPos, diskNormal, rayOrigin, rayDirection );
	if (d < t)
	{
		t = d;
		hitNormal = dot(diskNormal, rayDirection) <= 0.0 ? diskNormal : -diskNormal;
		hitEmission = diskEmission;
		hitPos = rayOrigin + rayDirection * t;
		toLightBulb = normalize(spheres[1].position - hitPos);
		
		if (dot(hitNormal, toLightBulb) > 0.0)
		{
			hitColor = diskColor;
			hitType = diskType;
		}
		else
		{
			hitColor = vec3(0);
			hitType = DIFF;
		}
		
		hitObjectID = float(objectCount);
	}

	d = OpenCylinderIntersect( openCylinderPos0, openCylinderPos1, openCylinderRadius, rayOrigin, rayDirection, normal );
	if (d < t)
	{
		t = d;
		hitNormal = normal;
		hitEmission = openCylinderEmission;
		hitPos = rayOrigin + rayDirection * t;
		toLightBulb = normalize(spheres[1].position - hitPos);
		
		if (dot(hitNormal, toLightBulb) > 0.0)
		{
			hitColor = openCylinderColor;
			hitType = openCylinderType;
		}
		else 
		{
			hitColor = vec3(0);
			hitType = DIFF;
		}
		
		hitObjectID = float(objectCount); // same as spotlight disk backing above
	}

	objectCount++;

	// transform ray into GLTF_Model's object space
	rayOrigin = vec3( uGLTF_Model_InvMatrix * vec4(rayOrigin, 1.0) );
	rayDirection = vec3( uGLTF_Model_InvMatrix * vec4(rayDirection, 0.0) );
	inverseDir = 1.0 / rayDirection;
	

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
		uv0 = ivec2( mod(triangleID + 0.0, 2048.0), (triangleID + 0.0) * INV_TEXTURE_WIDTH );
		uv1 = ivec2( mod(triangleID + 1.0, 2048.0), (triangleID + 1.0) * INV_TEXTURE_WIDTH );
		uv2 = ivec2( mod(triangleID + 2.0, 2048.0), (triangleID + 2.0) * INV_TEXTURE_WIDTH );
		uv3 = ivec2( mod(triangleID + 3.0, 2048.0), (triangleID + 3.0) * INV_TEXTURE_WIDTH );
		uv4 = ivec2( mod(triangleID + 4.0, 2048.0), (triangleID + 4.0) * INV_TEXTURE_WIDTH );
		uv5 = ivec2( mod(triangleID + 5.0, 2048.0), (triangleID + 5.0) * INV_TEXTURE_WIDTH );
		uv6 = ivec2( mod(triangleID + 6.0, 2048.0), (triangleID + 6.0) * INV_TEXTURE_WIDTH );
		uv7 = ivec2( mod(triangleID + 7.0, 2048.0), (triangleID + 7.0) * INV_TEXTURE_WIDTH );
		
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
		hitUV = triangleW * vec2(vd4.zw) + triangleU * vec2(vd5.xy) + triangleV * vec2(vd5.zw);
		normal = normalize(triangleW * vec3(vd2.yzw) + triangleU * vec3(vd3.xyz) + triangleV * vec3(vd3.w, vd4.xy));
		
		normal = perturbNormal(normal, vec2(1.0, 1.0), hitUV);

		// transform normal back into world space
		hitNormal = transpose(mat3(uGLTF_Model_InvMatrix)) * normal;
		hitEmission = vec3(1, 0, 1); // use this if intersec.type will be LIGHT
		hitColor = vd6.yzw;
		
		//hitType = int(vd6.x);
		hitType = PBR_MATERIAL;
                hitTextureID = int(vd7.x);
		hitObjectID = float(objectCount);
	}

	return t;

} // end float SceneIntersect( vec3 rayOrigin, vec3 rayDirection, out int isRayExiting )



//----------------------------------------------------------------------------------------------------------------------------------------------------
vec3 CalculateRadiance( out vec3 objectNormal, out vec3 objectColor, out float objectID, out float pixelSharpness )
//----------------------------------------------------------------------------------------------------------------------------------------------------
{
        Sphere light = spheres[1];

	vec3 accumCol = vec3(0);
        vec3 mask = vec3(1);
	vec3 reflectionMask = vec3(1);
	vec3 reflectionRayOrigin = vec3(0);
	vec3 reflectionRayDirection = vec3(0);
	vec3 checkCol0 = vec3(1);
	vec3 checkCol1 = vec3(0.5);
        vec3 dirToLight;
        vec3 tdir;
	vec3 metallicRoughness = vec3(0);
	vec3 x, n, nl;
        
	float t;
        float nc, nt, ratioIoR, Re, Tr;
	//float P, RP, TP;
        float weight;
        float thickness = 0.1;

	int diffuseCount = 0;

	int coatTypeIntersected = FALSE;
	int bounceIsSpecular = TRUE;
	int sampleLight = FALSE;
	int isRayExiting = FALSE;
	int willNeedReflectionRay = FALSE;

	
        for (int bounces = 0; bounces < 6; bounces++)
	{

		t = SceneIntersect(rayOrigin, rayDirection, isRayExiting);
		
		/*
		if (t == INFINITY)
		{
                        break;
		}
		*/
		if (hitType == LIGHT)
		{	
			if (bounces == 0)
				pixelSharpness = 1.01;

			accumCol += mask * hitEmission;

			if (willNeedReflectionRay == TRUE)
			{
				mask = reflectionMask;
				rayOrigin = reflectionRayOrigin;
				rayDirection = reflectionRayDirection;

				willNeedReflectionRay = FALSE;
				bounceIsSpecular = TRUE;
				sampleLight = FALSE;
				diffuseCount = 0;
				continue;
			}
			// reached a light, so we can exit
			break;
		}

		// useful data 
		n = normalize(hitNormal);
                nl = dot(n, rayDirection) < 0.0 ? n : -n;
		x = rayOrigin + rayDirection * t;

		if (bounces == 0)
		{
			objectNormal = nl;
			objectColor = hitColor;
			objectID = hitObjectID;
		}

		
		if (hitType == SPOT_LIGHT)
		{	
			if (diffuseCount == 0)
				pixelSharpness = 1.01;
			
			if (bounceIsSpecular == TRUE)
			{
				if (bounces == 0) // looking directly at light
					accumCol += mask * clamp(hitEmission, 0.0, 10.0);
				else if (bounces == 1) // single bounce reflection or refraction
					accumCol += mask * clamp(hitEmission, 0.0, 20.0);
				else // caustic
					accumCol += mask * clamp(hitEmission, 0.0, 1.0);
			}
				
			if (sampleLight == TRUE)
				accumCol += mask * hitEmission;
			
			if (willNeedReflectionRay == TRUE)
			{
				mask = reflectionMask;
				rayOrigin = reflectionRayOrigin;
				rayDirection = reflectionRayDirection;

				willNeedReflectionRay = FALSE;
				bounceIsSpecular = TRUE;
				sampleLight = FALSE;
				diffuseCount = 0;
				continue;
			}
			// reached a light, so we can exit
			break;
		}

		// if we get here and sampleLight is still true, shadow ray failed to find the light source 
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
				diffuseCount = 0;
				continue;
			}

			break;
		}
		
		

		if (hitType == PBR_MATERIAL)
		{
			hitColor = texture(tAlbedoMap, hitUV).rgb;
			hitColor = pow(hitColor,vec3(2.2));
			
			hitEmission = texture(tEmissiveMap, hitUV).rgb;
			hitEmission = pow(hitEmission,vec3(2.2));
			
			float maxEmission = max(hitEmission.r, max(hitEmission.g, hitEmission.b));
			if (bounceIsSpecular == TRUE && maxEmission > 0.01)
			{
				pixelSharpness = 1.01;
				accumCol = mask * hitEmission;
				break;
			}

			hitType = DIFF;
			
			metallicRoughness = pow(texture(tMetallicRoughnessMap, hitUV).rgb, vec3(2.2));
			
			if (metallicRoughness.g > 0.01) // roughness
			{
				hitType = COAT;
			}
				
			if (metallicRoughness.b > 0.01) // metalness
			{
				hitType = SPEC;
			}
				
		}
		
		    
                if (hitType == DIFF || hitType == CHECK) // Ideal DIFFUSE reflection
                {
			
			if ( hitType == CHECK )
			{
				float q = clamp( mod( dot( floor(x.xz * 0.04), vec2(1.0) ), 2.0 ) , 0.0, 1.0 );
				hitColor = checkCol0 * q + checkCol1 * (1.0 - q);	
			}
			// must update objectColor to checker color pattern
			if (diffuseCount == 0 && coatTypeIntersected == FALSE)	
				objectColor = hitColor;

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
                        
			dirToLight = sampleSphereLight(x, nl, light, weight);
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

			rayDirection = randomDirectionInSpecularLobe(reflect(rayDirection, nl), metallicRoughness.g);
			rayOrigin = x + nl * uEPS_intersect;
			
			if (bounces == 0)
				pixelSharpness = 1.01;
			//bounceIsSpecular = TRUE;
                        continue;
                }

                if (hitType == REFR)  // Ideal dielectric REFRACTION
		{
			pixelSharpness = diffuseCount == 0 ? -1.0 : pixelSharpness;

			nc = 1.0; // IOR of Air
			nt = 1.5; // IOR of common Glass
			Re = calcFresnelReflectance(rayDirection, n, nc, nt, ratioIoR);
			Tr = 1.0 - Re;
			// P  = 0.25 + (0.5 * Re);
                	// RP = Re / P;
                	// TP = Tr / (1.0 - P);
			
			if (bounces == 0 || (bounces == 1 && hitObjectID != objectID && bounceIsSpecular == TRUE))
			{
				reflectionMask = mask * Re;
				reflectionRayDirection = reflect(rayDirection, nl); // reflect ray from surface
				reflectionRayOrigin = x + nl * uEPS_intersect;
				willNeedReflectionRay = TRUE;
			}

			if (Re == 1.0)
			{
				mask = reflectionMask;
				rayOrigin = reflectionRayOrigin;
				rayDirection = reflectionRayDirection;

				willNeedReflectionRay = FALSE;
				bounceIsSpecular = TRUE;
				sampleLight = FALSE;
				continue;
			}

			// transmit ray through surface

			// is ray leaving a solid object from the inside? 
			// If so, attenuate ray color with object color by how far ray has travelled through the medium
			if (isRayExiting == TRUE)
			{
				mask *= exp(log(hitColor) * thickness * t);
			}

			mask *= Tr;
			
			tdir = refract(rayDirection, nl, ratioIoR);
			rayDirection = tdir;
			rayOrigin = x - nl * uEPS_intersect;
			
			// if (bounces == 1)
			// 	bounceIsSpecular = TRUE; // turn on refracting caustics

			continue;
			
		} // end if (hitType == REFR)
		
		if (hitType == COAT)  // Diffuse object underneath with ClearCoat on top
		{	
			coatTypeIntersected = TRUE;

			nc = 1.0; // IOR of Air
			nt = 1.5; // IOR of Clear Coat
			Re = calcFresnelReflectance(rayDirection, nl, nc, nt, ratioIoR);
			Tr = 1.0 - Re;
			// P  = 0.25 + (0.5 * Re);
                	// RP = Re / P;
                	// TP = Tr / (1.0 - P);

			
			if (bounces == 0 || (bounces == 1 && hitObjectID != objectID && bounceIsSpecular == TRUE))
			{
				reflectionMask = mask * Re;
				reflectionRayDirection = reflect(rayDirection, nl); // reflect ray from surface
				reflectionRayOrigin = x + nl * uEPS_intersect;
				willNeedReflectionRay = TRUE;
			}

			diffuseCount++;

			if (bounces == 0)
				mask *= Tr;
			mask *= hitColor;
			
			bounceIsSpecular = FALSE;
			
			/* if (diffuseCount == 1 && rand() < 0.5)
			{
				// choose random Diffuse sample vector
				rayDirection = randomCosWeightedDirectionInHemisphere(nl);
				rayOrigin = x + nl * uEPS_intersect;
				continue;
			} */
                        
			dirToLight = sampleSphereLight(x, nl, light, weight);
			mask *= weight;
			
			rayDirection = dirToLight;
			rayOrigin = x + nl * uEPS_intersect;

			sampleLight = TRUE;
			continue;
                        
		} //end if (hitType == COAT)
		
	} // end for (int bounces = 0; bounces < 4; bounces++)
	

	return max(vec3(0), accumCol);
	    
} // end vec3 CalculateRadiance( vec3 rayOrigin, vec3 rayDirection, out vec3 objectNormal, out vec3 objectColor, out float objectID, out float pixelSharpness )


//-----------------------------------------------------------------------
void SetupScene(void)
//-----------------------------------------------------------------------
{
	vec3 z  = vec3(0);          
	vec3 L1 = vec3(0.5, 0.7, 1.0) * 0.01;// Blueish sky light
	vec3 L2 = vec3(1.0, 1.0, 1.0) * 500.0;// Bright white light bulb
	
	spheres[0] = Sphere( 10000.0,     vec3(0, 0, 0), L1, z, LIGHT);//spherical white Light1
	spheres[1] = Sphere( 3.0, vec3(-10, 100, -50), L2, z, SPOT_LIGHT);//spotlight
	spheres[2] = Sphere( 4000.0, vec3(0, -4000, 0), z, vec3(0.4, 0.4, 0.4), CHECK);//Checkered Floor
        
        vec3 spotLightTarget = uGLTF_Model_Position;
        vec3 spotLightPos = spheres[1].position;
	vec3 spotLightDir = normalize(spotLightTarget - spotLightPos);

	openCylinderPos0 = spotLightPos - (spotLightDir * spheres[1].radius) * 2.0;
	openCylinderPos1 = spotLightPos + (spotLightDir * spheres[1].radius) * 5.0;
	openCylinderRadius = spheres[1].radius * 1.5;
	openCylinderEmission = z;
	openCylinderColor = vec3(1);
	openCylinderType = SPEC;

	diskRadius = spheres[1].radius * 1.5;
	diskPos = spotLightPos - (spotLightDir * spheres[1].radius * 2.0);
	diskNormal = spotLightDir;
	diskEmission = z;
	diskColor = vec3(1);
	diskType = SPEC;

	boxes[0] = Box( vec3(-20.0,11.0,-110.0), vec3(70.0,18.0,-20.0), z, vec3(0.2,0.9,0.7), REFR);//Glass Box
	boxes[1] = Box( vec3(-14.0,13.0,-104.0), vec3(64.0,16.0,-26.0), z, vec3(0),           DIFF);//Inner Box
}


//#include <pathtracing_main>

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
	
	vec2 pixelOffset = vec2( tentFilter(rand()), tentFilter(rand()) ) * 0.5;
	// we must map pixelPos into the range -1.0 to +1.0
	vec2 pixelPos = ((gl_FragCoord.xy + pixelOffset) / uResolution) * 2.0 - 1.0;

        vec3 rayDir = uUseOrthographicCamera ? camForward : 
					       normalize( pixelPos.x * camRight * uULen + pixelPos.y * camUp * uVLen + camForward );

        // depth of field
        vec3 focalPoint = uFocusDistance * rayDir;
        float randomAngle = rng() * TWO_PI; // pick random point on aperture
        float randomRadius = rng() * uApertureSize;
        vec3  randomAperturePos = ( cos(randomAngle) * camRight + sin(randomAngle) * camUp ) * sqrt(randomRadius);
        // point on aperture to focal point
        vec3 finalRayDir = normalize(focalPoint - randomAperturePos);
        
        rayOrigin = uUseOrthographicCamera ? cameraPosition + (camRight * pixelPos.x * uULen * 100.0) + (camUp * pixelPos.y * uVLen * 100.0) + randomAperturePos :
					     cameraPosition + randomAperturePos;
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

	float objectDifference = min(fwidth(objectID), 1.0);

	float colorDifference = (fwidth(objectColor.r) + fwidth(objectColor.g) + fwidth(objectColor.b)) > 0.0 ? 1.0 : 0.0;
	// white-line debug visualization for normal difference
	//currentPixel.rgb += (rng() * 1.5) * vec3(normalDifference);
	// white-line debug visualization for object difference
	//currentPixel.rgb += (rng() * 1.5) * vec3(objectDifference);
	// white-line debug visualization for color difference
	//currentPixel.rgb += (rng() * 1.5) * vec3(colorDifference);
	// white-line debug visualization for all 3 differences
	//currentPixel.rgb += (rng() * 1.5) * vec3( clamp(max(normalDifference, max(objectDifference, colorDifference)), 0.0, 1.0) );
	
	vec4 previousPixel = texelFetch(tPreviousTexture, ivec2(gl_FragCoord.xy), 0);


	if (uCameraIsMoving) // camera is currently moving
	{
		previousPixel.rgb *= 0.5; // motion-blur trail amount (old image)
		currentPixel.rgb *= 0.5; // brightness of new image (noisy)

		previousPixel.a = 0.0;
	}
	else
	{
		previousPixel.rgb *= 0.9; // motion-blur trail amount (old image)
		currentPixel.rgb *= 0.1; // brightness of new image (noisy)
	}

	// if current raytraced pixel didn't return any color value, just use the previous frame's pixel color
	if (currentPixel.rgb == vec3(0.0))
	{
		currentPixel.rgb = previousPixel.rgb;
		previousPixel.rgb *= 0.5;
		currentPixel.rgb *= 0.5;
	}

	if (colorDifference >= 1.0 || normalDifference >= 1.0 || objectDifference >= 1.0)
		pixelSharpness = 1.01;

	currentPixel.a = pixelSharpness;

	// makes sharp edges more stable
	if (previousPixel.a == 1.01)
		currentPixel.a = 1.01;

	// for dynamic scenes (to clear out old, dark, sharp pixel trails left behind from moving objects)
	if (previousPixel.a == 1.01 && rng() < 0.05)
		currentPixel.a = 1.0;

	
	pc_fragColor = vec4(previousPixel.rgb + currentPixel.rgb, currentPixel.a);
}
