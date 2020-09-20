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

#define N_SPHERES 2


//-----------------------------------------------------------------------

struct Ray { vec3 origin; vec3 direction; };
struct Sphere { float radius; vec3 position; vec3 emission; vec3 color; int type; };
struct Intersection { vec3 normal; vec3 emission; vec3 color; vec2 uv; int type; int albedoTextureID; };

Sphere spheres[N_SPHERES];


#include <pathtracing_random_functions>

#include <pathtracing_calc_fresnel_reflectance>

#include <pathtracing_sphere_intersect>

#include <pathtracing_boundingbox_intersect>

#include <pathtracing_bvhTriangle_intersect>

#include <pathtracing_bvhDoubleSidedTriangle_intersect>


vec2 stackLevels[24];

struct BoxNode
{
	vec4 data0; // corresponds to .x: idLeftChild, .y: aabbMin.x, .z: aabbMin.y, .w: aabbMin.z
	vec4 data1; // corresponds to .x: idRightChild .y: aabbMax.x, .z: aabbMax.y, .w: aabbMax.z
};

BoxNode GetBoxNode(const in float i)
{
	// each bounding box's data is encoded in 2 rgba(or xyzw) texture slots 
	float iX2 = (i * 2.0);
	// (iX2 + 0.0) corresponds to .x: idLeftChild, .y: aabbMin.x, .z: aabbMin.y, .w: aabbMin.z 
	// (iX2 + 1.0) corresponds to .x: idRightChild .y: aabbMax.x, .z: aabbMax.y, .w: aabbMax.z 

	ivec2 uv0 = ivec2( mod(iX2 + 0.0, 4096.0), (iX2 + 0.0) * INV_TEXTURE_WIDTH ); // data0
	ivec2 uv1 = ivec2( mod(iX2 + 1.0, 4096.0), (iX2 + 1.0) * INV_TEXTURE_WIDTH ); // data1
	
	BoxNode BN = BoxNode( texelFetch(tAABBTexture, uv0, 0), texelFetch(tAABBTexture, uv1, 0) );

        return BN;
}


//----------------------------------------------------------
float SceneIntersect( Ray r, inout Intersection intersec )
//----------------------------------------------------------
{
	BoxNode currentBoxNode, nodeA, nodeB, tmpNode;
	
	vec4 vd0, vd1, vd2, vd3, vd4, vd5, vd6, vd7;

	vec3 inverseDir = 1.0 / r.direction;
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
	
	
	currentBoxNode = GetBoxNode(stackptr);
	currentStackData = vec2(stackptr, BoundingBoxIntersect(currentBoxNode.data0.yzw, currentBoxNode.data1.yzw, r.origin, inverseDir));
	stackLevels[0] = currentStackData;
	
	while (true)
        {
		if (currentStackData.y < t) 
                {
                        if (currentBoxNode.data0.x < 0.0) //  < 0.0 signifies a leaf node
                        {
				// each triangle's data is encoded in 8 rgba(or xyzw) texture slots
				id = 8.0 * (-currentBoxNode.data0.x - 1.0);

				uv0 = ivec2( mod(id + 0.0, 4096.0), (id + 0.0) * INV_TEXTURE_WIDTH );
				uv1 = ivec2( mod(id + 1.0, 4096.0), (id + 1.0) * INV_TEXTURE_WIDTH );
				uv2 = ivec2( mod(id + 2.0, 4096.0), (id + 2.0) * INV_TEXTURE_WIDTH );
				
				vd0 = texelFetch(tTriangleTexture, uv0, 0);
				vd1 = texelFetch(tTriangleTexture, uv1, 0);
				vd2 = texelFetch(tTriangleTexture, uv2, 0);

				d = BVH_TriangleIntersect( vec3(vd0.xyz), vec3(vd0.w, vd1.xy), vec3(vd1.zw, vd2.x), r, tu, tv );

				if (d < t)
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
                                nodeA = GetBoxNode(currentBoxNode.data0.x);
                                nodeB = GetBoxNode(currentBoxNode.data1.x);
                                stackDataA = vec2(currentBoxNode.data0.x, BoundingBoxIntersect(nodeA.data0.yzw, nodeA.data1.yzw, r.origin, inverseDir));
                                stackDataB = vec2(currentBoxNode.data1.x, BoundingBoxIntersect(nodeB.data0.yzw, nodeB.data1.yzw, r.origin, inverseDir));
				
				// first sort the branch node data so that 'a' is the smallest
				if (stackDataB.y < stackDataA.y)
				{
					tmpStackData = stackDataB;
					stackDataB = stackDataA;
					stackDataA = tmpStackData;

					tmpNode = nodeB;
					nodeB = nodeA;
					nodeA = tmpNode;
				} // branch 'b' now has the larger rayT value of 'a' and 'b'

				if (stackDataB.y < t) // see if branch 'b' (the larger rayT) needs to be processed
				{
					currentStackData = stackDataB;
					currentBoxNode = nodeB;
					skip = true; // this will prevent the stackptr from decreasing by 1
				}
				if (stackDataA.y < t) // see if branch 'a' (the smaller rayT) needs to be processed 
				{
					if (skip) // if larger branch 'b' needed to be processed also,
						stackLevels[int(stackptr++)] = stackDataB; // cue larger branch 'b' for future round
								// also, increase pointer by 1
					
					currentStackData = stackDataA;
					currentBoxNode = nodeA;
					skip = true; // this will prevent the stackptr from decreasing by 1
				}
                        }
		} // end if (currentStackData.y < t)

		if (!skip) 
                {
                        // decrease pointer by 1 (0.0 is root level, 24.0 is maximum depth)
                        if (--stackptr < 0.0) // went past the root level, terminate loop
                                break;
                        currentStackData = stackLevels[int(stackptr)];
                        currentBoxNode = GetBoxNode(currentStackData.x);
                }
		skip = false; // reset skip

        } // end while (true)



	if (triangleLookupNeeded)
	{
		//uv0 = ivec2( mod(triangleID + 0.0, 4096.0), (triangleID + 0.0) * INV_TEXTURE_WIDTH );
		//uv1 = ivec2( mod(triangleID + 1.0, 4096.0), (triangleID + 1.0) * INV_TEXTURE_WIDTH );
		uv2 = ivec2( mod(triangleID + 2.0, 4096.0), (triangleID + 2.0) * INV_TEXTURE_WIDTH );
		uv3 = ivec2( mod(triangleID + 3.0, 4096.0), (triangleID + 3.0) * INV_TEXTURE_WIDTH );
		uv4 = ivec2( mod(triangleID + 4.0, 4096.0), (triangleID + 4.0) * INV_TEXTURE_WIDTH );
		uv5 = ivec2( mod(triangleID + 5.0, 4096.0), (triangleID + 5.0) * INV_TEXTURE_WIDTH );
		//uv6 = ivec2( mod(triangleID + 6.0, 4096.0), (triangleID + 6.0) * INV_TEXTURE_WIDTH );
		//uv7 = ivec2( mod(triangleID + 7.0, 4096.0), (triangleID + 7.0) * INV_TEXTURE_WIDTH );
		
		//vd0 = texelFetch(tTriangleTexture, uv0, 0);
		//vd1 = texelFetch(tTriangleTexture, uv1, 0);
		vd2 = texelFetch(tTriangleTexture, uv2, 0);
		vd3 = texelFetch(tTriangleTexture, uv3, 0);
		vd4 = texelFetch(tTriangleTexture, uv4, 0);
		vd5 = texelFetch(tTriangleTexture, uv5, 0);
		//vd6 = texelFetch(tTriangleTexture, uv6, 0);
		//vd7 = texelFetch(tTriangleTexture, uv7, 0);

	
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
		intersec.type = CHECK;//DIFF;
	}

	return t;

} // end float SceneIntersect( Ray r, inout Intersection intersec )


//-----------------------------------------------------------------------
vec3 CalculateRadiance(Ray r)
//-----------------------------------------------------------------------
{
	Intersection intersec;
        vec4 texColor;

	vec3 accumCol = vec3(0.0);
        vec3 mask = vec3(1.0);
	vec3 checkCol0 = vec3(1.0);
	vec3 checkCol1 = vec3(0.5);
	vec3 tdir;
	vec3 x, n, nl;

	vec2 sampleUV;
	
	float t;
	float epsIntersect = 0.01;
	float nc, nt, ratioIoR, Re, Tr;
	float P, RP, TP;
	float weight;
	
	int diffuseCount = 0;

	bool bounceIsSpecular = true;
	bool sampleLight = false;

	
        for (int bounces = 0; bounces < 2; bounces++)
	{

		t = SceneIntersect(r, intersec);
		
		if (t == INFINITY)
			break;
		
		// if we reached something bright, don't spawn any more rays
		if (intersec.type == LIGHT)
		{	
			//if (bounceIsSpecular)
				accumCol = mask * intersec.emission;
			
			break;
		}
		
		// useful data 
		n = normalize(intersec.normal);
                nl = dot(n, r.direction) < 0.0 ? normalize(n) : normalize(-n);
		x = r.origin + r.direction * t;
		
		    
                if (intersec.type == DIFF || intersec.type == CHECK) // Ideal DIFFUSE reflection
                {
			diffuseCount++;

			if ( intersec.type == CHECK )
			{
				float q = clamp( mod( dot( floor(x.xz * 2.0), vec2(1.0) ), 2.0 ) , 0.0, 1.0 );
				intersec.color = checkCol0 * q + checkCol1 * (1.0 - q);	
			}
			
			mask *= intersec.color;

			bounceIsSpecular = false;
			
			// int id = intersec.albedoTextureID;
			// if (id > -1)
			// {
			// 	texColor = texture(tAlbedoMap, intersec.uv);
			// 	intersec.color = GammaToLinear(texColor, 2.2).rgb;
			// }

			r = Ray( x, randomCosWeightedDirectionInHemisphere(nl) );
			r.origin += nl * epsIntersect;
			continue;
	
                }
		

		if (intersec.type == REFR)  // Ideal dielectric REFRACTION
		{
			nc = 1.0; // IOR of Air
			nt = 1.5; // IOR of common Glass
			Re = calcFresnelReflectance(r.direction, n, nc, nt, ratioIoR);
			Tr = 1.0 - Re;
			P  = 0.25 + (0.5 * Re);
                	RP = Re / P;
                	TP = Tr / (1.0 - P);
			

			if (rand() < P) // reflect ray from surface
			{
				mask *= RP;
				r = Ray( x, reflect(r.direction, nl) );
				r.origin += nl * epsIntersect;
			    	continue;	
			}
			// transmit ray through surface
			
			mask *= intersec.color;
			mask *= TP;

			tdir = refract(r.direction, nl, ratioIoR);
			r = Ray(x, tdir);
			r.origin -= nl * epsIntersect;

			bounceIsSpecular = true; // turn on refracting caustics
			
			continue;

		} // end if (intersec.type == REFR)
		
		
	} // end for (int bounces = 0; bounces < 2; bounces++)
	
	
	return max(vec3(0), accumCol); // prevents black spot artifacts appearing in the water   
}


//-----------------------------------------------------------------------
void SetupScene(void)
//-----------------------------------------------------------------------
{
	vec3 z  = vec3(0);
	vec3 L1 = vec3(0.5, 0.7, 1.0);// Blueish sky light
        float skySphereRadius = 100000.0;
	float groundSphereRadius = 0.0;//4000.0;
	spheres[0] = Sphere( skySphereRadius, vec3(0, 0, 0), L1, z, LIGHT);//large spherical sky light
	spheres[1] = Sphere( groundSphereRadius, vec3(0, -groundSphereRadius, 0), z, vec3(0.4, 0.4, 0.4), CHECK);//Checkered Floor
}



#include <pathtracing_main>
