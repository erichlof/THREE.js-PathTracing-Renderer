#version 300 es

precision highp float;
precision highp int;
precision highp sampler2D;

uniform sampler2D tTriangleTexture;
uniform sampler2D tAABBTexture;
uniform sampler2D tHDRTexture;
//uniform sampler2D tMarbleTexture;

#include <pathtracing_uniforms_and_defines>

uniform int uMaterialType;
uniform vec3 uMaterialColor;
uniform float uHDRI_Exposure;

//float InvTextureWidth = 0.000244140625; // (1 / 4096 texture width)
//float InvTextureWidth = 0.00048828125;  // (1 / 2048 texture width)
//float InvTextureWidth = 0.0009765625;   // (1 / 1024 texture width)

#define INV_TEXTURE_WIDTH 0.00048828125

#define N_SPHERES 4
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


//----------------------------------------------------------
float SceneIntersect( Ray r, inout Intersection intersec )
//----------------------------------------------------------
{
        BoxNode currentBoxNode, nodeA, nodeB, tnp;
	StackLevelData currentStackData, slDataA, slDataB, tmp;

	// AABB BVH Intersection variables
	vec4 aabbNodeData0, aabbNodeData1, aabbNodeData2;
	vec4 vd0, vd1, vd2, vd3, vd4, vd5, vd6, vd7;
	vec3 aabbMin, aabbMax;
	vec3 inverseDir = 1.0 / r.direction;
        vec3 n;
	ivec2 uv0, uv1, uv2, uv3, uv4, uv5, uv6, uv7;

        float d = INFINITY;
	float t = INFINITY;
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
	
	currentBoxNode = GetBoxNode(0.0);
	currentStackData = StackLevelData(0.0, BoundingBoxIntersect(currentBoxNode.minCorner, currentBoxNode.maxCorner, r.origin, inverseDir));
	stackLevels[0] = currentStackData;

	while (true)
        {
		if (currentStackData.rayT < t)
                {
			
                        if (currentBoxNode.branch_A_Index < 0.0) //  < 0.0 signifies this is a leaf node
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
						stackLevels[int(stackptr++)] = slDataB; // cue larger branch 'b' for future round
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
		intersec.emission = vec3(0);
		intersec.color = uMaterialColor;//vd6.yzw;
		intersec.uv = triangleW * vec2(vd4.zw) + triangleU * vec2(vd5.xy) + triangleV * vec2(vd5.zw); 
		intersec.type = int(uMaterialType);//int(vd6.x);
		intersec.albedoTextureID = -1;//int(vd7.x);
	}

	return t;

} // end float SceneIntersect( Ray r, inout Intersection intersec )



vec3 Get_HDR_Color(Ray r)
{
	vec2 sampleUV;
	sampleUV.x = atan(r.direction.z, r.direction.x) * ONE_OVER_TWO_PI + 0.5;
	sampleUV.y = asin(clamp(r.direction.y, -1.0, 1.0)) * ONE_OVER_PI + 0.5;
	vec4 texData = texture( tHDRTexture, sampleUV );
	texData = RGBEToLinear(texData);
	
	// tone mapping options
        //vec3 texColor = LinearToneMapping(texData.rgb);
        //vec3 texColor = ReinhardToneMapping(texData.rgb);
        vec3 texColor = Uncharted2ToneMapping(texData.rgb);
        //vec3 texColor = OptimizedCineonToneMapping(texData.rgb);
        //vec3 texColor = ACESFilmicToneMapping(texData.rgb);

	return texColor * uHDRI_Exposure;
}


//-----------------------------------------------------------------------
vec3 CalculateRadiance( Ray r, inout uvec2 seed )
//-----------------------------------------------------------------------
{
        Intersection intersec;
	Ray firstRay;

	vec3 accumCol = vec3(0);
        vec3 mask = vec3(1);
	vec3 firstMask = vec3(1);
	vec3 checkCol0 = vec3(1);
	vec3 checkCol1 = vec3(0.5);
        vec3 tdir;

        float nc, nt, Re, Tr;

	bool firstTypeWasREFR = false;
	bool reflectionTime = false;
	
	
	for (int bounces = 0; bounces < 7; bounces++)
	{
		
		float t = SceneIntersect(r, intersec);
		
		
		if (t == INFINITY)
		{	
                        vec3 environmentCol = Get_HDR_Color(r);

			if (firstTypeWasREFR)
			{
				if (!reflectionTime) 
				{
					accumCol = mask * environmentCol;
					
					// start back at the refractive surface, but this time follow reflective branch
					r = firstRay;
					mask = firstMask;
					// set/reset variables
					reflectionTime = true;
					
					// continue with the reflection ray
					continue;
				}
				else 
					accumCol += mask * environmentCol; // add reflective result to the refractive result (if any)
			}
			else 
				accumCol = mask * environmentCol;
			
			// reached the HDRI sky light, so we can exit
			break;
		} // end if (t == INFINITY)
		
		
		// useful data 
		vec3 n = intersec.normal;
                vec3 nl = dot(n,r.direction) <= 0.0 ? normalize(n) : normalize(n * -1.0);
		vec3 x = r.origin + r.direction * t;
		
		    
                if (intersec.type == DIFF || intersec.type == CHECK) // Ideal DIFFUSE reflection
                {
			if( intersec.type == CHECK )
			{
				float q = clamp( mod( dot( floor(x.xz * 0.04), vec2(1.0) ), 2.0 ) , 0.0, 1.0 );
				intersec.color = checkCol0 * q + checkCol1 * (1.0 - q);	
			}
			
			mask *= intersec.color;
                        
			// choose random Diffuse sample vector
			r = Ray( x, randomCosWeightedDirectionInHemisphere(nl, seed) );
			r.origin += nl * uEPS_intersect;
			continue;	
                }
		
                if (intersec.type == SPEC)  // Ideal SPECULAR reflection
                {
			mask *= intersec.color;

			r = Ray( x, reflect(r.direction, nl) );
			r.origin += nl * uEPS_intersect;
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

			if (bounces > 0)
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

			continue;
			
		} // end if (intersec.type == REFR)
		
		if (intersec.type == COAT)  // Diffuse object underneath with ClearCoat on top (like car, or shiny pool ball)
		{
			nc = 1.0; // IOR of Air
			nt = 1.6; // IOR of Clear Coat (a little thicker for this demo)
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

			if (bounces > 0)
			{
				if (rand(seed) < Re)
				{	
					r = Ray( x, reflect(r.direction, nl) );
					r.origin += nl * uEPS_intersect;
					continue;	
				}
			}

			mask *= Tr;
			mask *= intersec.color;
			//accumCol += calcDirectLightingSphere(mask, x, nl, spheres[0], seed);
			r = Ray( x, randomCosWeightedDirectionInHemisphere(nl, seed) );
			r.origin += nl * uEPS_intersect;
			continue;
			
		} //end if (intersec.type == COAT)
		
		
	} // end for (int bounces = 0; bounces < 7; bounces++)
	
	return accumCol;      
} // end vec3 CalculateRadiance( Ray r, inout uvec2 seed )


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