#version 300 es

precision highp float;
precision highp int;
precision highp sampler2D;

#include <pathtracing_uniforms_and_defines>

uniform sampler2D tTriangleTexture;
uniform sampler2D tAABBTexture;
uniform sampler2D tAlbedoTextures[8]; // 8 = max number of diffuse albedo textures per model

//float InvTextureWidth = 0.000244140625; // (1 / 4096 texture width)
//float InvTextureWidth = 0.00048828125;  // (1 / 2048 texture width)
//float InvTextureWidth = 0.0009765625;   // (1 / 1024 texture width)

#define INV_TEXTURE_WIDTH 0.00048828125

#define N_SPHERES 3
#define N_BOXES 2

//-----------------------------------------------------------------------

struct Ray { vec3 origin; vec3 direction; };
struct Sphere { float radius; vec3 position; vec3 emission; vec3 color; int type; };
struct Box { vec3 minCorner; vec3 maxCorner; vec3 emission; vec3 color; int type; };
struct Intersection { vec3 normal; vec3 emission; vec3 color; vec2 uv; int type; int albedoTextureID; };

Sphere spheres[N_SPHERES];
Box boxes[N_BOXES];


#include <pathtracing_random_functions>

#include <pathtracing_calc_fresnel_reflectance>

#include <pathtracing_sphere_intersect>

#include <pathtracing_box_intersect>

#include <pathtracing_boundingbox_intersect>

#include <pathtracing_bvhTriangle_intersect>

#include <pathtracing_sample_sphere_light>


struct StackLevelData
{
        int id;
        float rayT;
} stackLevels[24];

struct BoxNode
{
	int branch_A_Index;
	vec3 minCorner;
	int branch_B_Index;
	vec3 maxCorner;  
};

int modulus(in int a, in int b)
{
	return a - (a / b) * b;
}

BoxNode GetBoxNode(const in int i)
{
	// each bounding box's data is encoded in 2 rgba(or xyzw) texture slots 
	int iX2 = i * 2;
	// (iX2 + 0.0) corresponds to .x: idLeftChild, .y: aabbMin.x, .z: aabbMin.y, .w: aabbMin.z 
	// (iX2 + 1.0) corresponds to .x: idRightChild .y: aabbMax.x, .z: aabbMax.y, .w: aabbMax.z 

	ivec2 uv0 = ivec2( modulus(iX2 + 0, 2048), (iX2 + 0) / 2048 );
	ivec2 uv1 = ivec2( modulus(iX2 + 1, 2048), (iX2 + 1) / 2048 );
	
	vec4 aabbNodeData0 = texelFetch(tAABBTexture, uv0, 0);
	vec4 aabbNodeData1 = texelFetch(tAABBTexture, uv1, 0);
	

	BoxNode BN = BoxNode( int(aabbNodeData0.x),
			      aabbNodeData0.yzw,
			      int(aabbNodeData1.x),
			      aabbNodeData1.yzw );

        return BN;
}

//----------------------------------------------------------
float SceneIntersect( Ray r, inout Intersection intersec )
//----------------------------------------------------------
{
	vec3 n;
	float d = INFINITY;
	float t = INFINITY;
	
	// AABB BVH Intersection variables
	vec4 aabbNodeData0, aabbNodeData1, aabbNodeData2;
	vec4 vd0, vd1, vd2, vd3, vd4, vd5, vd6, vd7;
	vec3 aabbMin, aabbMax;
	vec3 inverseDir = 1.0 / r.direction;
	vec3 hitPos, toLightBulb;
	ivec2 uv0, uv1, uv2, uv3, uv4, uv5, uv6, uv7;
	
	float bc, bd;
	float tu, tv;
	float triangleU = 0.0;
	float triangleV = 0.0;
	float triangleW = 0.0;

	int stackptr = 0;
	int id = 0;
	int triangleID = 0;
	
	bool skip = false;
	bool triangleHit = false;

	BoxNode currentBoxNode, nodeA, nodeB, tnp;
	StackLevelData currentStackData, slDataA, slDataB, tmp;

	for (int i = 0; i < N_SPHERES; i++)
        {
		d = SphereIntersect( spheres[i].radius, spheres[i].position, r );
		if (d < t)
		{
			t = d;
			intersec.normal = (r.origin + r.direction * t) - spheres[i].position;
			intersec.emission = spheres[i].emission;
			intersec.color = spheres[i].color;
			intersec.type = spheres[i].type;
			intersec.albedoTextureID = -1;
		}
	}
	
	for (int i = 0; i < N_BOXES; i++)
        {
		d = BoxIntersect( boxes[i].minCorner, boxes[i].maxCorner, r, n );
		if (d < t)
		{
			t = d;
			intersec.normal = normalize(n);
			intersec.emission = boxes[i].emission;
			intersec.color = boxes[i].color;
			intersec.type = boxes[i].type;
			intersec.albedoTextureID = -1;
		}
	}
	

	currentBoxNode = GetBoxNode(stackptr);
	currentStackData = StackLevelData(stackptr, BoundingBoxIntersect(currentBoxNode.minCorner, currentBoxNode.maxCorner, r.origin, inverseDir));
	stackLevels[0] = currentStackData;
	
	while (true)
        {

		if (currentStackData.rayT < t) 
                {
                        if (currentBoxNode.branch_A_Index < 0) //  < 0.0 signifies a leaf node
                        {
				// each triangle's data is encoded in 8 rgba(or xyzw) texture slots
				id = 8 * (-currentBoxNode.branch_A_Index - 1);

				uv0 = ivec2( modulus(id + 0, 2048), (id + 0) / 2048 );
				uv1 = ivec2( modulus(id + 1, 2048), (id + 1) / 2048 );
				uv2 = ivec2( modulus(id + 2, 2048), (id + 2) / 2048 );
				
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
					triangleHit = true;
				}
                        }
                        else // else this is a branch
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
						stackLevels[stackptr++] = slDataB; // cue larger branch 'b' for future round
								// also, increase pointer by 1
					
					currentStackData = slDataA;
					currentBoxNode = nodeA;
					skip = true; // this will prevent the stackptr from decreasing by 1
				}
                        }
		} // end if (currentStackData.rayT < t)

		if (skip == false) 
                {
                        // decrease pointer by 1 (0.0 is root level, 24.0 is maximum depth)
                        if (--stackptr < 0) // went past the root level, terminate loop
                                break;
                        currentStackData = stackLevels[stackptr];
                        currentBoxNode = GetBoxNode(currentStackData.id);
                }
		skip = false; // reset skip

        } // end while (true)



	// take texture lookups out of if statement branch, just read them always

	//uv0 = ivec2( modulus(triangleID + 0, 2048), (triangleID + 0) / 2048 );
	//uv1 = ivec2( modulus(triangleID + 1, 2048), (triangleID + 1) / 2048 );
	uv2 = ivec2( modulus(triangleID + 2, 2048), (triangleID + 2) / 2048 );
	uv3 = ivec2( modulus(triangleID + 3, 2048), (triangleID + 3) / 2048 );
	uv4 = ivec2( modulus(triangleID + 4, 2048), (triangleID + 4) / 2048 );
	uv5 = ivec2( modulus(triangleID + 5, 2048), (triangleID + 5) / 2048 );
	uv6 = ivec2( modulus(triangleID + 6, 2048), (triangleID + 6) / 2048 );
	//uv7 = ivec2( modulus(triangleID + 7, 2048), (triangleID + 7) / 2048 );
	
	//vd0 = texelFetch(tTriangleTexture, uv0, 0);
	//vd1 = texelFetch(tTriangleTexture, uv1, 0);
	vd2 = texelFetch(tTriangleTexture, uv2, 0);
	vd3 = texelFetch(tTriangleTexture, uv3, 0);
	vd4 = texelFetch(tTriangleTexture, uv4, 0);
	vd5 = texelFetch(tTriangleTexture, uv5, 0);
	vd6 = texelFetch(tTriangleTexture, uv6, 0);
	//vd7 = texelFetch(tTriangleTexture, uv7, 0);

		
	if (triangleHit) // if statement branch: only do this if triangle hit was closest
	{	
		// face normal for flat-shaded polygon look
		//intersec.normal = normalize( cross(vec3(vd0.w, vd1.xy) - vec3(vd0.xyz), vec3(vd1.zw, vd2.x) - vec3(vd0.xyz)) );
		
		// interpolated normal using triangle intersection's uv's
		triangleW = 1.0 - triangleU - triangleV;
		intersec.normal = normalize(triangleW * vec3(vd2.yzw) + triangleU * vec3(vd3.xyz) + triangleV * vec3(vd3.w, vd4.xy));
		intersec.emission = vec3(1, 0, 1); // use this if intersec.type will be LIGHT
		intersec.color = vd6.yzw;
		intersec.uv = triangleW * vec2(vd4.zw) + triangleU * vec2(vd5.xy) + triangleV * vec2(vd5.zw);
		//intersec.type = int(vd6.x);
		//intersec.albedoTextureID = int(vd7.x);
		intersec.type = COAT;
		intersec.albedoTextureID = -1;
	}

	return t;

} // end float SceneIntersect( Ray r, inout Intersection intersec )


//-----------------------------------------------------------------------
vec3 CalculateRadiance( Ray r, inout uvec2 seed )
//-----------------------------------------------------------------------
{
	Intersection intersec;
	Sphere light = spheres[1];
	Ray firstRay;

	vec3 accumCol = vec3(0);
        vec3 mask = vec3(1);
	vec3 firstMask = vec3(1);
	vec3 checkCol0 = vec3(1);
	vec3 checkCol1 = vec3(0.5);

	vec3 dirToLight;
	vec3 tdir;
	
	float nc, nt, Re, Tr;
	float weight;
	float diffuseColorBleeding = 0.3; // range: 0.0 - 0.5, amount of color bleeding between surfaces

	int diffuseCount = 0;

	bool bounceIsSpecular = true;
	bool sampleLight = false;
	bool firstTypeWasREFR = false;
	bool reflectionTime = false;

	
        for (int bounces = 0; bounces < 6; bounces++)
	{

		float t = SceneIntersect(r, intersec);
		
		/*
		if (t == INFINITY)
		{
                        break;
		}
		*/
		/*
		if (intersec.type == POINT_LIGHT)
		{	
			
			if (sampleLight)
			{
				accumCol = mask * intersec.emission;
			}
			else if (bounceIsSpecular && bounces < 2)
			{
				accumCol = mask * clamp(intersec.emission, 0.0, 5.0);
			}

			break;
		}
		*/
		if (intersec.type == LIGHT || intersec.type == POINT_LIGHT)
		{	
			if (firstTypeWasREFR)
			{
				if (!reflectionTime) 
				{
					if (sampleLight || bounceIsSpecular)
						accumCol = mask * intersec.emission;
					
					// start back at the refractive surface, but this time follow reflective branch
					r = firstRay;
					mask = firstMask;
					// set/reset variables
					reflectionTime = true;
					bounceIsSpecular = true;
					sampleLight = false;
					// continue with the reflection ray
					continue;
				}
				else if (sampleLight)
					accumCol += mask * intersec.emission; // add reflective result to the refractive result (if any)
				else if (bounceIsSpecular)
					accumCol += mask * clamp(intersec.emission, 0.0, 100.0);	
				
			}
			else if (sampleLight)
					accumCol = mask * intersec.emission;
			else if (bounceIsSpecular)
					accumCol = mask * clamp(intersec.emission, 0.0, 50.0);	
			
			// reached a light, so we can exit
			break;
		} // end if (intersec.type == LIGHT)


		// if we get here and sampleLight is still true, shadow ray failed to find a light source
		if (sampleLight) 
		{
			if (firstTypeWasREFR && !reflectionTime) 
			{
				// start back at the refractive surface, but this time follow reflective branch
				r = firstRay;
				mask = firstMask;
				// set/reset variables
				reflectionTime = true;
				bounceIsSpecular = true;
				sampleLight = false;
				// continue with the reflection ray
				continue;
			}
			// nothing left to calculate, so exit	
			break;
		}
		
		
		// useful data 
		vec3 n = intersec.normal;
                vec3 nl = dot(n,r.direction) <= 0.0 ? normalize(n) : normalize(n * -1.0);
		vec3 x = r.origin + r.direction * t;
		
		    
                if (intersec.type == DIFF || intersec.type == CHECK) // Ideal DIFFUSE reflection
                {
			diffuseCount++;

			if ( intersec.type == CHECK )
			{
				float q = clamp( mod( dot( floor(x.xz * 0.04), vec2(1.0) ), 2.0 ) , 0.0, 1.0 );
				intersec.color = checkCol0 * q + checkCol1 * (1.0 - q);	
			}
			
			mask *= intersec.color;
			
			int id = intersec.albedoTextureID;
			if (id > -1)
			{
				vec3 albedoSample;
				     if (id == 0) albedoSample = texture(tAlbedoTextures[0], intersec.uv).rgb;
				else if (id == 1) albedoSample = texture(tAlbedoTextures[1], intersec.uv).rgb;
				else if (id == 2) albedoSample = texture(tAlbedoTextures[2], intersec.uv).rgb;
				else if (id == 3) albedoSample = texture(tAlbedoTextures[3], intersec.uv).rgb;
				else if (id == 4) albedoSample = texture(tAlbedoTextures[4], intersec.uv).rgb;
				else if (id == 5) albedoSample = texture(tAlbedoTextures[5], intersec.uv).rgb;
				else if (id == 6) albedoSample = texture(tAlbedoTextures[6], intersec.uv).rgb;
				else if (id == 7) albedoSample = texture(tAlbedoTextures[7], intersec.uv).rgb;

				mask *= albedoSample;
			}
			
			/*
			// Russian Roulette - if needed, this speeds up the framerate, at the cost of some dark noise
			float p = max(mask.r, max(mask.g, mask.b));
			if (bounces > 0)
			{
				if (rand(seed) < p)
                                	mask *= 1.0 / p;
                        	else
                                	break;
			}
			*/

                        bounceIsSpecular = false;

                        if (diffuseCount == 1 && rand(seed) < diffuseColorBleeding)
                        {
                                // choose random Diffuse sample vector
				r = Ray( x, randomCosWeightedDirectionInHemisphere(nl, seed) );
				r.origin += nl * uEPS_intersect;
				
				continue;
                        }
                        else
                        {
				weight = sampleSphereLight(x, nl, dirToLight, light, seed);
				mask *= clamp(weight, 0.0, 1.0);

                                r = Ray( x, dirToLight );
				r.origin += nl * uEPS_intersect;

				sampleLight = true;
				continue;
                        }
		} // end if (intersec.type == DIFF)
		
		if (intersec.type == SPEC)  // Ideal SPECULAR reflection
		{
			mask *= intersec.color;

			r = Ray( x, reflect(r.direction, nl) );
			r.origin += nl * uEPS_intersect;

			//bounceIsSpecular = true; // turn on mirror caustics
			continue;
		}
		
		if (intersec.type == REFR)  // Ideal dielectric REFRACTION
		{
			nc = 1.0; // IOR of Air
			nt = 1.5; // IOR of common Glass
			Re = calcFresnelReflectance(n, nl, r.direction, nc, nt, tdir);
			Tr = 1.0 - Re;

			if (bounces == 0)
			{	
				// save intersection data for future reflection trace
				firstTypeWasREFR = true;
				firstMask = mask * Re;
				firstRay = Ray( x, reflect(r.direction, nl) ); // create reflection ray from surface
				firstRay.origin += nl * uEPS_intersect;
			}

			if (bounces > 0 && bounceIsSpecular)
			{
				if (rand(seed) < Re)
				{
					r = Ray( x, reflect(r.direction, nl) ); // reflect ray from surface
					r.origin += nl * uEPS_intersect;
					continue;
				}
			}

			// transmit ray through surface
			mask *= Tr;
			mask *= intersec.color;
			
			r = Ray(x, tdir);
			r.origin -= nl * uEPS_intersect;

			bounceIsSpecular = true; // turn on refracting caustics
			continue;
			
		} // end if (intersec.type == REFR)
		
		if (intersec.type == COAT)  // Diffuse object underneath with ClearCoat on top
		{
			nc = 1.0; // IOR of Air
			nt = 1.4; // IOR of Clear Coat
			Re = calcFresnelReflectance(n, nl, r.direction, nc, nt, tdir);
			Tr = 1.0 - Re;

			// clearCoat counts as refractive surface
			if (bounces == 0)
			{	
				// save intersection data for future reflection trace
				firstTypeWasREFR = true;
				firstMask = mask * Re;
				firstRay = Ray( x, reflect(r.direction, nl) ); // create reflection ray from surface
				firstRay.origin += nl * uEPS_intersect;
			}
			
			if (bounces > 0 && bounceIsSpecular)
			{
				
				if (rand(seed) < Re)
				{	
					r = Ray( x, reflect(r.direction, nl) );
					r.origin += nl * uEPS_intersect;
					continue;	
				}
			}
			
			diffuseCount++;

			mask *= Tr;
			mask *= intersec.color;
			
			bounceIsSpecular = false;

			if (diffuseCount == 1 && rand(seed) < diffuseColorBleeding)
                        {
                                // choose random Diffuse sample vector
				r = Ray( x, randomCosWeightedDirectionInHemisphere(nl, seed) );
				r.origin += nl * uEPS_intersect;
				continue;
                        }
                        else
                        {
				weight = sampleSphereLight(x, nl, dirToLight, light, seed);
				mask *= clamp(weight, 0.0, 1.0);
				
                                r = Ray( x, dirToLight );
				r.origin += nl * uEPS_intersect;

				sampleLight = true;
				continue;
                        }
			
		} //end if (intersec.type == COAT)
		
		
	} // end for (int bounces = 0; bounces < 6; bounces++)
	
	return accumCol;      
} // end vec3 CalculateRadiance( Ray r, inout uvec2 seed )


//-----------------------------------------------------------------------
void SetupScene(void)
//-----------------------------------------------------------------------
{
	vec3 z  = vec3(0);
	vec3 L1 = vec3(0.5, 0.7, 1.0) * 0.01;// Blueish sky light
	vec3 L2 = vec3(1.0, 0.9, 0.8) * 500.0;// Bright white light bulb
	
	spheres[0] = Sphere( 10000.0, vec3(0, 0, 0), L1, z, LIGHT);//large spherical sky light
	spheres[1] = Sphere( 0.5, vec3(-10, 35, -10), L2, z, POINT_LIGHT);//small spherical point light
	spheres[2] = Sphere( 4000.0, vec3(0, -4000, 0), z, vec3(0.4, 0.4, 0.4), CHECK);//Checkered Floor
		
	boxes[0] = Box( vec3(-20.0, 11.0, -110.0), vec3(70.0, 18.0, -20.0), z, vec3(0.2, 0.9, 0.7), REFR);//Glass Box
	boxes[1] = Box( vec3(-14.0, 13.0, -104.0), vec3(64.0, 16.0, -26.0), z, vec3(0, 0, 0), DIFF);//Inner Box
}


#include <pathtracing_main>
