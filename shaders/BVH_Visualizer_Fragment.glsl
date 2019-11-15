#version 300 es

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
	vec3 n;
	float d = INFINITY;
	float t = INFINITY;
		
	// AABB BVH Intersection variables
	vec4 aabbNodeData0, aabbNodeData1, aabbNodeData2;
	vec4 vd0, vd1, vd2, vd3, vd4, vd5, vd6, vd7;
	vec3 aabbMin, aabbMax;
	vec3 inverseDir = 1.0 / r.direction;
	ivec2 uv0, uv1, uv2, uv3, uv4, uv5, uv6, uv7;

	float stackptr = 0.0;
	float levelCounter = 0.0;
	float savedLevel = INFINITY;
	float bc, bd;
	float id = 0.0;
	float tu, tv;
	float triangleID = 0.0;
	float triangleU = 0.0;
	float triangleV = 0.0;
	float triangleW = 0.0;
	bool skip = false;
	bool triangleLookupNeeded = false;

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
			triangleLookupNeeded = false;
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
			triangleLookupNeeded = false;
		}
	}
	
	currentBoxNode = GetBoxNode(0.0);
	currentStackData = StackLevelData(0.0, BoundingBoxIntersect(currentBoxNode.minCorner, currentBoxNode.maxCorner, r.origin, inverseDir));
	stackLevels[0] = currentStackData;

	while (true)
        {
		if (currentStackData.rayT < t)
                {
			// render selected nodes
			if (levelCounter == uBVH_NodeLevel)
			{
				d = BoxIntersect(currentBoxNode.minCorner, currentBoxNode.maxCorner, r, n);
				if (d < t)
				{
					t = d;
					intersec.normal = n;
					intersec.emission = vec3(0);
					intersec.color = vec3(1, 1, 0);
					intersec.type = REFR;
					break;
				}
			}

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
					intersec.emission = vec3(1, 0, 1);
					intersec.color = vec3(0);
					intersec.type = LIGHT;
				}
                        }
                        else // else this is a branch
                        {
				levelCounter++;

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
			levelCounter = stackptr;
                }
		skip = false; // reset skip
		
        } // end while (true)


	return t;

} // end float SceneIntersect( Ray r, inout Intersection intersec )


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
	vec3 x, n, nl;
        
	float t;
        float nc, nt, ratioIoR, Re, Tr;

	bool bounceIsSpecular = true;
	bool firstTypeWasREFR = false;
	bool reflectionTime = false;
	bool firstTypeWasCOAT = false;
	bool specularTime = false;
	
	// need more bounces than usual, because there could be lots of yellow glass boxes in a row
	for (int bounces = 0; bounces < 10; bounces++)
	{
		
		t = SceneIntersect(r, intersec);
		
		/*
		if (t == INFINITY)
		{
                        break;
		}
		*/
		
		if (intersec.type == LIGHT)
		{	

			if (bounces == 0)
			{
				accumCol = mask * intersec.emission;
				break;
			}

			if (firstTypeWasREFR)
			{
				if (!reflectionTime) 
				{
					accumCol = mask * intersec.emission;
					
					// start back at the refractive surface, but this time follow reflective branch
					r = firstRay;
					r.direction = normalize(r.direction);
					mask = firstMask;
					// set/reset variables
					reflectionTime = true;
					
					// continue with the reflection ray
					continue;
				}

				accumCol += mask * intersec.emission; // add reflective result to the refractive result (if any)
				break;
			}

			if (firstTypeWasCOAT)
			{
				if (!specularTime) 
				{
					accumCol = mask * intersec.emission;
					
					// start back at the refractive surface, but this time follow reflective branch
					r = firstRay;
					r.direction = normalize(r.direction);
					mask = firstMask;
					// set/reset variables
					specularTime = true;
					
					// continue with the reflection ray
					continue;
				}

				accumCol += mask * intersec.emission; // add reflective result to the refractive result (if any)
				break;
			}

			accumCol = mask * intersec.emission; // looking at light through a reflection
			// reached a light, so we can exit
			break;
		} // end if (intersec.type == LIGHT)
		
		
		// useful data 
		n = normalize(intersec.normal);
                nl = dot(n, r.direction) < 0.0 ? normalize(n) : normalize(-n);
		x = r.origin + r.direction * t;
		
		    
                if (intersec.type == DIFF || intersec.type == CHECK) // Ideal DIFFUSE reflection
                {
			if( intersec.type == CHECK )
			{
				float q = clamp( mod( dot( floor(x.xz * 0.04), vec2(1.0) ), 2.0 ) , 0.0, 1.0 );
				intersec.color = checkCol0 * q + checkCol1 * (1.0 - q);	
			}
			
			mask *= intersec.color;

			/* // Russian Roulette
			float p = max(mask.r, max(mask.g, mask.b));
			if (bounces > 0)
			{
				if (rand(seed) < p)
                                	mask *= 1.0 / p;
                        	else
                                	break;
			} */
                        
			// choose random Diffuse sample vector
			r = Ray( x, normalize(randomCosWeightedDirectionInHemisphere(nl, seed)) );
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
			Re = calcFresnelReflectance(r.direction, n, nc, nt, ratioIoR);
			Tr = 1.0 - Re;

			if (Re > 0.99)
			{
				r = Ray( x, reflect(r.direction, nl) ); // reflect ray from surface
				r.origin += nl * uEPS_intersect;
				continue;
			}
			
			if (bounces < 2 && !firstTypeWasREFR && !firstTypeWasCOAT)
			{	
				// save intersection data for future reflection trace
				firstTypeWasREFR = true;
				firstMask = mask * Re;
				firstRay = Ray( x, reflect(r.direction, nl) ); // create reflection ray from surface
				firstRay.origin += nl * uEPS_intersect;
				mask *= Tr;
			}
			else if (rand(seed) < Re)
			{
				r = Ray( x, reflect(r.direction, nl) ); // reflect ray from surface
				r.origin += nl * uEPS_intersect;
				continue;
			}

			// transmit ray through surface
			mask *= intersec.color;
			
			tdir = refract(r.direction, nl, ratioIoR);
			r = Ray(x, normalize(tdir));
			r.origin -= nl * uEPS_intersect;

			continue;
			
		} // end if (intersec.type == REFR)
		
		if (intersec.type == COAT)  // Diffuse object underneath with ClearCoat on top (like car, or shiny pool ball)
		{
			nc = 1.0; // IOR of Air
			nt = 1.6; // IOR of Clear Coat (a little thicker for this demo)
			Re = calcFresnelReflectance(r.direction, n, nc, nt, ratioIoR);
			Tr = 1.0 - Re;

			if (Re > 0.99)
			{
				r = Ray( x, reflect(r.direction, nl) ); // reflect ray from surface
				r.origin += nl * uEPS_intersect;
				continue;
			}
			
			if (bounces < 2 && !firstTypeWasCOAT && !firstTypeWasREFR)
			{	
				// save intersection data for future reflection trace
				firstTypeWasCOAT = true;
				firstMask = mask * Re;
				firstRay = Ray( x, reflect(r.direction, nl) ); // create reflection ray from surface
				firstRay.origin += nl * uEPS_intersect;
				mask *= Tr;
			}
			else if (rand(seed) < Re)
			{
				r = Ray( x, reflect(r.direction, nl) ); // reflect ray from surface
				r.origin += nl * uEPS_intersect;
				continue;
			}
			
			mask *= intersec.color;

			r = Ray( x, normalize(randomCosWeightedDirectionInHemisphere(nl, seed)) );
			r.origin += nl * uEPS_intersect;
			continue;
			
		} //end if (intersec.type == COAT)
		
		
	} // end for (int bounces = 0; bounces < 10; bounces++)
	
	
	return max(vec3(0), accumCol);
	      
} // end vec3 CalculateRadiance( Ray r, inout uvec2 seed )


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
