precision highp float;
precision highp int;
precision highp sampler2D;

uniform sampler2D tTriangleTexture;
uniform sampler2D tAABBTexture;
uniform sampler2D tMarbleTexture;

#include <pathtracing_uniforms_and_defines>

uniform float uBVH_NodeLevel;

//float InvTextureWidth = 0.000244140625; // (1 / 4096 texture width)
//float InvTextureWidth = 0.00048828125;  // (1 / 2048 texture width)
//float InvTextureWidth = 0.0009765625;   // (1 / 1024 texture width)

#define INV_TEXTURE_WIDTH 0.00048828125

#define N_SPHERES 5
#define N_BOXES 2

vec3 rayOrigin, rayDirection;
// recorded intersection data:
vec3 hitNormal, hitEmission, hitColor;
vec2 hitUV;
float hitObjectID;
int hitType;

//-----------------------------------------------------------------------


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


//-------------------------------------------------------------------------------------------------------------------
float SceneIntersect( out bool finalIsRayExiting )
//-------------------------------------------------------------------------------------------------------------------
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
	float levelCounter = 0.0;
	float id = 0.0;
	float tu, tv;
	float triangleID = 0.0;
	float triangleU = 0.0;
	float triangleV = 0.0;
	float triangleW = 0.0;

	int objectCount = 0;
	
	hitObjectID = -INFINITY;
	
	bool skip = false;
	bool triangleLookupNeeded = false;
	bool isRayExiting = false;

	
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
			hitNormal = normalize(normal);
			hitEmission = boxes[i].emission;
			hitColor = boxes[i].color;
			hitType = boxes[i].type;
			finalIsRayExiting = isRayExiting;
			hitObjectID = float(objectCount);
		}
		objectCount++;
	}

	
	GetBoxNodeData(stackptr, currentBoxNodeData0, currentBoxNodeData1);
	currentStackData = vec2(stackptr, BoundingBoxIntersect(currentBoxNodeData0.yzw, currentBoxNodeData1.yzw, rayOrigin, inverseDir));
	stackLevels[0] = currentStackData;
	skip = (currentStackData.y < t);

	while (true)
        {
		if (!skip) 
                {
                        // decrease pointer by 1 (0.0 is root level, 27.0 is maximum depth)
                        if (--stackptr < 0.0) // went past the root level, terminate loop
                                break;

                        currentStackData = stackLevels[int(stackptr)];

			levelCounter = stackptr;
			
			if (currentStackData.y >= t)
				continue;
			
			GetBoxNodeData(currentStackData.x, currentBoxNodeData0, currentBoxNodeData1);
                }
		skip = false; // reset skip

		
		// render selected nodes
		if (levelCounter == uBVH_NodeLevel)
		{
			d = BoxIntersect(currentBoxNodeData0.yzw, currentBoxNodeData1.yzw, rayOrigin, rayDirection, normal, isRayExiting);
			if (d < t)
			{
				t = d;
				hitNormal = normal;
				hitEmission = vec3(0);
				hitColor = vec3(1, 1, 0);
				hitType = REFR;
				finalIsRayExiting = isRayExiting;
				hitObjectID = 2.0;
				break;
			}
		}

		if (currentBoxNodeData0.x < 0.0) //  < 0.0 signifies an inner node
		{
			levelCounter++;

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
				skip = true; // this will prevent the stackptr from decreasing by 1
			}
			if (stackDataA.y < t) // see if branch 'a' (the smaller rayT) needs to be processed 
			{
				if (skip) // if larger branch 'b' needed to be processed also,
					stackLevels[int(stackptr++)] = stackDataB; // cue larger branch 'b' for future round
							// also, increase pointer by 1
				
				currentStackData = stackDataA;
				currentBoxNodeData0 = nodeAData0; 
				currentBoxNodeData1 = nodeAData1;
				skip = true; // this will prevent the stackptr from decreasing by 1
			}

			continue;
		} // end if (currentBoxNode.data0.x < 0.0)  // inner node
    
		// else this is a leaf node

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
			hitEmission = vec3(1, 0, 1);
			hitColor = vec3(0);
			hitType = LIGHT;
			hitObjectID = float(objectCount);
		}
                        
        } // end while (true)


	return t;

} // end float SceneIntersect( out bool finalIsRayExiting )


//----------------------------------------------------------------------------------------------------------------------------------------------------
vec3 CalculateRadiance( out vec3 objectNormal, out vec3 objectColor, out float objectID, out float pixelSharpness )
//----------------------------------------------------------------------------------------------------------------------------------------------------
{
	vec3 accumCol = vec3(0);
        vec3 mask = vec3(1);
	vec3 checkCol0 = vec3(1);
	vec3 checkCol1 = vec3(0.5);
        vec3 tdir;
	vec3 x, n, nl;
        
	float t;
        float nc, nt, ratioIoR, Re, Tr;
	float P, RP, TP;
	float thickness = 0.1;

	int diffuseCount = 0;

	bool coatTypeIntersected = false;
	bool bounceIsSpecular = true;
	bool isRayExiting = false;

	
	// need more bounces than usual, because there could be lots of yellow glass boxes in a row
	for (int bounces = 0; bounces < 10; bounces++)
	{
		
		t = SceneIntersect(isRayExiting);
		
		/*
		if (t == INFINITY)
		{
                        break;
		}
		*/
		if (hitType == LIGHT)
		{	
			if (diffuseCount == 0 && hitEmission == vec3(1, 0, 1))
				pixelSharpness = 1.01;
			
			if (bounces == 0)
				objectID = hitObjectID;
			
			accumCol = mask * hitEmission;
			break;
		}
		
		
		// useful data 
		n = normalize(hitNormal);
                nl = dot(n, rayDirection) < 0.0 ? normalize(n) : normalize(-n);
		x = rayOrigin + rayDirection * t;

		if (bounces == 0)
		{
			objectNormal = nl;
			objectColor = hitColor;
			objectID = hitObjectID;
		}

		
		    
                if (hitType == DIFF || hitType == CHECK) // Ideal DIFFUSE reflection
                {
			
			if( hitType == CHECK )
			{
				float q = clamp( mod( dot( floor(x.xz * 0.04), vec2(1.0) ), 2.0 ) , 0.0, 1.0 );
				hitColor = checkCol0 * q + checkCol1 * (1.0 - q);	
			}

			if (diffuseCount == 0 && !coatTypeIntersected)	
				objectColor = hitColor;

			
			mask *= hitColor;

			diffuseCount++;

			bounceIsSpecular = false;
                        
			// choose random Diffuse sample vector
			rayDirection = randomCosWeightedDirectionInHemisphere(nl);
			rayOrigin = x + nl * uEPS_intersect;
			continue;	
                }
		
                if (hitType == SPEC)  // Ideal SPECULAR reflection
		{
			mask *= hitColor;

			rayDirection = reflect(rayDirection, nl);
			rayOrigin = x + nl * uEPS_intersect;

			continue;
		}

                if (hitType == REFR)  // Ideal dielectric REFRACTION
		{
			if (diffuseCount == 0 && !coatTypeIntersected && !uCameraIsMoving )
				pixelSharpness = 1.01;
			else if (diffuseCount > 0)
				pixelSharpness = 0.0;
			else
				pixelSharpness = -1.0;

			nc = 1.0; // IOR of Air
			nt = 1.5; // IOR of common Glass
			Re = calcFresnelReflectance(rayDirection, n, nc, nt, ratioIoR);
			Tr = 1.0 - Re;
			P  = 0.25 + (0.5 * Re);
                	RP = Re / P;
                	TP = Tr / (1.0 - P);
			
			if (rand() < P)
			{
				mask *= RP;
				rayDirection = reflect(rayDirection, nl); // reflect ray from surface
				rayOrigin = x + nl * uEPS_intersect;
				continue;
			}

			// transmit ray through surface

			// is ray leaving a solid object from the inside? 
			// If so, attenuate ray color with object color by how far ray has travelled through the medium
			if (isRayExiting || (distance(n, nl) > 0.1))
			{
				isRayExiting = false;
				mask *= exp(log(hitColor) * thickness * t);
			}

			mask *= TP;
			
			tdir = refract(rayDirection, nl, ratioIoR);
			rayDirection = tdir;
			rayOrigin = x - nl * uEPS_intersect;

			continue;
			
		} // end if (hitType == REFR)
		
		if (hitType == COAT)  // Diffuse object underneath with ClearCoat on top (like car, or shiny pool ball)
		{
			coatTypeIntersected = true;

			pixelSharpness = 0.0;
			
			nc = 1.0; // IOR of Air
			nt = 1.6; // IOR of Clear Coat (a little thicker for this demo)
			Re = calcFresnelReflectance(rayDirection, nl, nc, nt, ratioIoR);
			Tr = 1.0 - Re;
			P  = 0.25 + (0.5 * Re);
                	RP = Re / P;
                	TP = Tr / (1.0 - P);

			if (rand() < P)
			{
				if (diffuseCount == 0)
					pixelSharpness = uFrameCounter > 200.0 ? 1.01 : -1.0;
					
				mask *= RP;
				rayDirection = reflect(rayDirection, nl); // reflect ray from surface
				rayOrigin = x + nl * uEPS_intersect;
				continue;
			}

			diffuseCount++;

			bounceIsSpecular = false;
			
			mask *= hitColor;
			mask *= TP;
			
			// choose random Diffuse sample vector
			rayDirection = randomCosWeightedDirectionInHemisphere(nl);
			rayOrigin = x + nl * uEPS_intersect;
			continue;
			
		} //end if (hitType == COAT)
		
		
	} // end for (int bounces = 0; bounces < 10; bounces++)
	
	
	return max(vec3(0), accumCol);
	      
} // end vec3 CalculateRadiance(out vec3 objectNormal, out vec3 objectColor, out float objectID, out float pixelSharpness)


//-----------------------------------------------------------------------
void SetupScene(void)
//-----------------------------------------------------------------------
{
	vec3 z  = vec3(0);          
	vec3 L3 = vec3(0.5, 0.7, 1.0) * 0.9;// Blueish light
	
	spheres[0] = Sphere( 10000.0,     vec3(0, 0, 0), L3,                 z, LIGHT);//spherical white Light1
	spheres[1] = Sphere(  4000.0, vec3(0, -4000, 0),  z, vec3(0.4,0.4,0.4), CHECK);//Checkered Floor
	spheres[2] = Sphere(     6.0, vec3(55, 36, -45),  z,         vec3(0.9),  SPEC);//small mirror ball
	spheres[3] = Sphere(     6.0, vec3(55, 24, -45),  z, vec3(0.5,1.0,1.0),  REFR);//small glass ball
	spheres[4] = Sphere(     6.0, vec3(60, 24, -30),  z,         vec3(1.0),  COAT);//small plastic ball
		
	boxes[0] = Box( vec3(-20.0,11.0,-110.0), vec3(70.0,18.0,-20.0), z, vec3(0.2,0.9,0.7), REFR);//Glass Box
	boxes[1] = Box( vec3(-14.0,13.0,-104.0), vec3(64.0,16.0,-26.0), z, vec3(0),           DIFF);//Inner Box
}


#include <pathtracing_main>
