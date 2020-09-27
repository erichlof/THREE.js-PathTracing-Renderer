precision highp float;
precision highp int;
precision highp sampler2D;

#include <pathtracing_uniforms_and_defines>


uniform sampler2D tTriangleTexture;
uniform sampler2D tAABBTexture;

uniform sampler2D tPaintingTexture;
uniform sampler2D tDarkWoodTexture;
uniform sampler2D tLightWoodTexture;
uniform sampler2D tMarbleTexture;
uniform sampler2D tHammeredMetalNormalMapTexture;

uniform mat4 uDoorObjectInvMatrix;
uniform mat3 uDoorObjectNormalMatrix;

#define INV_TEXTURE_WIDTH 0.00048828125

#define N_SPHERES 2
#define N_OPENCYLINDERS 3
#define N_QUADS 8
#define N_BOXES 10

struct Ray { vec3 origin; vec3 direction; };
struct Sphere { float radius; vec3 position; vec3 emission; vec3 color; float roughness; int type; bool isModel; };
struct OpenCylinder { float radius; vec3 pos1; vec3 pos2; vec3 emission; vec3 color; float roughness; int type; bool isModel; };
struct Quad { vec3 normal; vec3 v0; vec3 v1; vec3 v2; vec3 v3; vec3 emission; vec3 color; float roughness; int type; bool isModel; };
struct Box { vec3 minCorner; vec3 maxCorner; vec3 emission; vec3 color; float roughness; int type; bool isModel; };
struct Intersection { vec3 normal; vec3 emission; vec3 color; float roughness; vec2 uv; int type; bool isModel; };

Sphere spheres[N_SPHERES];
OpenCylinder openCylinders[N_OPENCYLINDERS];
Quad quads[N_QUADS];
Box boxes[N_BOXES];


#include <pathtracing_random_functions>

#include <pathtracing_calc_fresnel_reflectance>

#include <pathtracing_sphere_intersect>

#include <pathtracing_opencylinder_intersect>

#include <pathtracing_quad_intersect>

#include <pathtracing_box_intersect>

#include <pathtracing_boundingbox_intersect>

#include <pathtracing_bvhDoubleSidedTriangle_intersect>



vec3 perturbNormal(vec3 nl, vec2 normalScale, vec2 uv)
{
        vec3 S = normalize( cross( abs(nl.y) < 0.9 ? vec3(0, 1, 0) : vec3(0, 0, 1), nl ) );
        vec3 T = cross(nl, S);
        vec3 N = normalize( nl );
        mat3 tsn = mat3( S, T, N );

        vec3 mapN = texture(tHammeredMetalNormalMapTexture, uv).xyz * 2.0 - 1.0;
        mapN.xy *= normalScale;
        
        return normalize( tsn * mapN );
}


vec2 stackLevels[24];

struct BoxNode
{
	vec4 data0; // corresponds to .x: idTriangle, .y: aabbMin.x, .z: aabbMin.y, .w: aabbMin.z
	vec4 data1; // corresponds to .x: idRightChild .y: aabbMax.x, .z: aabbMax.y, .w: aabbMax.z
};

BoxNode GetBoxNode(const in float i)
{
	// each bounding box's data is encoded in 2 rgba(or xyzw) texture slots 
	float iX2 = (i * 2.0);
	// (iX2 + 0.0) corresponds to .x: idTriangle, .y: aabbMin.x, .z: aabbMin.y, .w: aabbMin.z 
	// (iX2 + 1.0) corresponds to .x: idRightChild .y: aabbMax.x, .z: aabbMax.y, .w: aabbMax.z 

	ivec2 uv0 = ivec2( mod(iX2 + 0.0, 2048.0), (iX2 + 0.0) * INV_TEXTURE_WIDTH ); // data0
	ivec2 uv1 = ivec2( mod(iX2 + 1.0, 2048.0), (iX2 + 1.0) * INV_TEXTURE_WIDTH ); // data1
	
	return BoxNode( texelFetch(tAABBTexture, uv0, 0), texelFetch(tAABBTexture, uv1, 0) );
}


//-----------------------------------------------------------------------
float SceneIntersect( Ray r, inout Intersection intersec, bool checkModels )
//-----------------------------------------------------------------------
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

	int modelID = 0;
	
	bool skip = false;
	bool triangleLookupNeeded = false;
	bool isRayExiting = false;
	
			
	// ROOM
	for (int i = 0; i < N_QUADS; i++)
        {
		d = QuadIntersect( quads[i].v0, quads[i].v1, quads[i].v2, quads[i].v3, r, true );
		if (d < t)
		{
			if (i == 1) // check back wall quad for door portal opening
			{
				vec3 ip = r.origin + r.direction * d;
				if (ip.x > 180.0 && ip.x < 280.0 && ip.y > -100.0 && ip.y < 90.0)
					continue;
			}
			
			t = d;
			intersec.normal = normalize( quads[i].normal );
			intersec.emission = quads[i].emission;
			intersec.color = quads[i].color;
			intersec.type = quads[i].type;
			intersec.isModel = false;
		}
        }
	
	for (int i = 0; i < N_BOXES - 1; i++)
        {
		d = BoxIntersect( boxes[i].minCorner, boxes[i].maxCorner, r, normal, isRayExiting );
		if (d < t)
		{
			t = d;
			intersec.normal = normalize(normal);
			intersec.emission = boxes[i].emission;
			intersec.color = boxes[i].color;
			intersec.type = boxes[i].type;
			intersec.isModel = false;
		}
	}
	
	// DOOR (TALL BOX)
	Ray rObj;
	// transform ray into Tall Box's object space
	rObj.origin = vec3( uDoorObjectInvMatrix * vec4(r.origin, 1.0) );
	rObj.direction = vec3( uDoorObjectInvMatrix * vec4(r.direction, 0.0) );
	d = BoxIntersect( boxes[9].minCorner, boxes[9].maxCorner, rObj, normal, isRayExiting );
	
	if (d < t)
	{	
		t = d;
		
		// transfom normal back into world space
		normal = vec3(uDoorObjectNormalMatrix * normal);
		
		intersec.normal = normalize(normal);
		intersec.emission = boxes[9].emission;
		intersec.color = boxes[9].color;
		intersec.type = boxes[9].type;
		intersec.isModel = false;
	}
	
	for (int i = 0; i < N_OPENCYLINDERS; i++)
        {
		d = OpenCylinderIntersect( openCylinders[i].pos1, openCylinders[i].pos2, openCylinders[i].radius, r, normal );
		if (d < t)
		{
			t = d;
			intersec.normal = normalize(normal);
			intersec.emission = openCylinders[i].emission;
			intersec.color = openCylinders[i].color;
			intersec.type = openCylinders[i].type;
			intersec.isModel = false;
		}
        }
	
	for (int i = 0; i < N_SPHERES; i++)
        {
		d = SphereIntersect( spheres[i].radius, spheres[i].position, rObj );
		if (d < t)
		{
			t = d;

			normal = normalize((rObj.origin + rObj.direction * t) - spheres[i].position);
			normal = vec3(uDoorObjectNormalMatrix * normal);
			intersec.normal = normalize(normal);
			intersec.emission = spheres[i].emission;
			intersec.color = spheres[i].color;
			intersec.type = spheres[i].type;
			intersec.isModel = false;
		}
	}

	if (!checkModels)
		return t;

	// teapot 0
	currentBoxNode = GetBoxNode(stackptr);
	currentStackData = vec2(stackptr, BoundingBoxIntersect(currentBoxNode.data0.yzw, currentBoxNode.data1.yzw, r.origin, inverseDir));
	stackLevels[0] = currentStackData;
	
	while (true)
        {
		if (currentStackData.y < t) 
                {
                        if (currentBoxNode.data0.x >= 0.0) //  >= 0.0 signifies a leaf node
                        {
				// each triangle's data is encoded in 8 rgba(or xyzw) texture slots
				id = 8.0 * currentBoxNode.data0.x;

				uv0 = ivec2( mod(id + 0.0, 2048.0), (id + 0.0) * INV_TEXTURE_WIDTH );
				uv1 = ivec2( mod(id + 1.0, 2048.0), (id + 1.0) * INV_TEXTURE_WIDTH );
				uv2 = ivec2( mod(id + 2.0, 2048.0), (id + 2.0) * INV_TEXTURE_WIDTH );
				
				vd0 = texelFetch(tTriangleTexture, uv0, 0);
				vd1 = texelFetch(tTriangleTexture, uv1, 0);
				vd2 = texelFetch(tTriangleTexture, uv2, 0);

				d = BVH_DoubleSidedTriangleIntersect( vec3(vd0.xyz), vec3(vd0.w, vd1.xy), vec3(vd1.zw, vd2.x), r, tu, tv );

				if (d < t)
				{
					t = d;
					triangleID = id;
					triangleU = tu;
					triangleV = tv;
					triangleLookupNeeded = true;
					modelID = 0;
				}
                        }
                        else // else this is a branch
                        {
                                nodeA = GetBoxNode(currentStackData.x + 1.0);
                                nodeB = GetBoxNode(currentBoxNode.data1.x);
                                stackDataA = vec2(currentStackData.x + 1.0, BoundingBoxIntersect(nodeA.data0.yzw, nodeA.data1.yzw, r.origin, inverseDir));
                                stackDataB = vec2(currentBoxNode.data1.x, BoundingBoxIntersect(nodeB.data0.yzw, nodeB.data1.yzw, r.origin, inverseDir));
				
				//first sort the branch node data so that 'a' is the smallest
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


	stackptr = 0.0;
	r.origin.x -= 70.0;
	// teapot 1
	currentBoxNode = GetBoxNode(stackptr);
	currentStackData = vec2(stackptr, BoundingBoxIntersect(currentBoxNode.data0.yzw, currentBoxNode.data1.yzw, r.origin, inverseDir));
	stackLevels[0] = currentStackData;
	
	while (true)
        {
		if (currentStackData.y < t) 
                {
                        if (currentBoxNode.data0.x >= 0.0) //  >= 0.0 signifies a leaf node
                        {
				// each triangle's data is encoded in 8 rgba(or xyzw) texture slots
				id = 8.0 * currentBoxNode.data0.x;

				uv0 = ivec2( mod(id + 0.0, 2048.0), (id + 0.0) * INV_TEXTURE_WIDTH );
				uv1 = ivec2( mod(id + 1.0, 2048.0), (id + 1.0) * INV_TEXTURE_WIDTH );
				uv2 = ivec2( mod(id + 2.0, 2048.0), (id + 2.0) * INV_TEXTURE_WIDTH );
				
				vd0 = texelFetch(tTriangleTexture, uv0, 0);
				vd1 = texelFetch(tTriangleTexture, uv1, 0);
				vd2 = texelFetch(tTriangleTexture, uv2, 0);

				d = BVH_DoubleSidedTriangleIntersect( vec3(vd0.xyz), vec3(vd0.w, vd1.xy), vec3(vd1.zw, vd2.x), r, tu, tv );

				if (d < t)
				{
					t = d;
					triangleID = id;
					triangleU = tu;
					triangleV = tv;
					triangleLookupNeeded = true;
					modelID = 1;
				}
                        }
                        else // else this is a branch
                        {
                                nodeA = GetBoxNode(currentStackData.x + 1.0);
                                nodeB = GetBoxNode(currentBoxNode.data1.x);
                                stackDataA = vec2(currentStackData.x + 1.0, BoundingBoxIntersect(nodeA.data0.yzw, nodeA.data1.yzw, r.origin, inverseDir));
                                stackDataB = vec2(currentBoxNode.data1.x, BoundingBoxIntersect(nodeB.data0.yzw, nodeB.data1.yzw, r.origin, inverseDir));
				
				//first sort the branch node data so that 'a' is the smallest
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


	stackptr = 0.0;
	r.origin.x -= 70.0;
	// teapot 2
	currentBoxNode = GetBoxNode(stackptr);
	currentStackData = vec2(stackptr, BoundingBoxIntersect(currentBoxNode.data0.yzw, currentBoxNode.data1.yzw, r.origin, inverseDir));
	stackLevels[0] = currentStackData;
	
	while (true)
        {
		if (currentStackData.y < t) 
                {
                        if (currentBoxNode.data0.x >= 0.0) //  >= 0.0 signifies a leaf node
                        {
				// each triangle's data is encoded in 8 rgba(or xyzw) texture slots
				id = 8.0 * currentBoxNode.data0.x;

				uv0 = ivec2( mod(id + 0.0, 2048.0), (id + 0.0) * INV_TEXTURE_WIDTH );
				uv1 = ivec2( mod(id + 1.0, 2048.0), (id + 1.0) * INV_TEXTURE_WIDTH );
				uv2 = ivec2( mod(id + 2.0, 2048.0), (id + 2.0) * INV_TEXTURE_WIDTH );
				
				vd0 = texelFetch(tTriangleTexture, uv0, 0);
				vd1 = texelFetch(tTriangleTexture, uv1, 0);
				vd2 = texelFetch(tTriangleTexture, uv2, 0);

				d = BVH_DoubleSidedTriangleIntersect( vec3(vd0.xyz), vec3(vd0.w, vd1.xy), vec3(vd1.zw, vd2.x), r, tu, tv );

				if (d < t)
				{
					t = d;
					triangleID = id;
					triangleU = tu;
					triangleV = tv;
					triangleLookupNeeded = true;
					modelID = 2;
				}
                        }
                        else // else this is a branch
                        {
                                nodeA = GetBoxNode(currentStackData.x + 1.0);
                                nodeB = GetBoxNode(currentBoxNode.data1.x);
                                stackDataA = vec2(currentStackData.x + 1.0, BoundingBoxIntersect(nodeA.data0.yzw, nodeA.data1.yzw, r.origin, inverseDir));
                                stackDataB = vec2(currentBoxNode.data1.x, BoundingBoxIntersect(nodeB.data0.yzw, nodeB.data1.yzw, r.origin, inverseDir));
				
				//first sort the branch node data so that 'a' is the smallest
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
		//intersec.normal = normalize( cross(vec3(vd0.w, vd1.xy) - vec3(vd0.xyz), vec3(vd1.zw, vd2.x) - vec3(vd0.xyz)) );
		
		// interpolated normal using triangle intersection's uv's
		triangleW = 1.0 - triangleU - triangleV;
		intersec.normal = normalize(triangleW * vec3(vd2.yzw) + triangleU * vec3(vd3.xyz) + triangleV * vec3(vd3.w, vd4.xy));
		intersec.emission = vec3(1, 0, 1); // use this if intersec.type will be LIGHT
		//intersec.color = vd6.yzw;
		intersec.uv = triangleW * vec2(vd4.zw) + triangleU * vec2(vd5.xy) + triangleV * vec2(vd5.zw);
		//intersec.type = int(vd6.x);
		//intersec.albedoTextureID = int(vd7.x);
		intersec.color = vec3(0.7);
		intersec.type = SPEC;
		if (modelID == 1)
		{
			intersec.color = vec3(1);
			intersec.type = COAT;
		}
		
		if (modelID == 2)
		{
			intersec.color = vec3(1);
			intersec.type = REFR;
		}
		
		intersec.isModel = true;
	}
	
	return t;
	
}



//-----------------------------------------------------------------------
vec3 CalculateRadiance(Ray originalRay)
//-----------------------------------------------------------------------
{
	Intersection intersec;
	vec4 texColor;

	//vec3 randVec = vec3(rand() * 2.0 - 1.0, rand() * 2.0 - 1.0, rand() * 2.0 - 1.0);
	vec3 accumCol = vec3(0);
	vec3 mask = vec3(1);
	vec3 checkCol0 = vec3(0.01);
	vec3 checkCol1 = vec3(1.0);
	vec3 nl, n, x;
	vec3 tdir;
	vec3 dirToLight;

	vec2 sampleUV;
	
	float nc, nt, ratioIoR, Re, Tr;
	float P, RP, TP;
	float t = INFINITY;
	float lightHitDistance = INFINITY;
	float weight;

	int diffuseCount = 0;
	int previousIntersecType = -1;

	bool sampleLight = false;
	bool bounceIsSpecular = true;
	bool ableToJoinPaths = false;
	bool checkModels = false;


	// Light path tracing (from Light source) /////////////////////////////////////////////////////////////////////

	vec3 lightHitEmission = quads[0].emission;
	vec3 randPointOnLight;
	randPointOnLight.x = mix(quads[0].v0.x, quads[0].v1.x, rand());
	randPointOnLight.y = mix(quads[0].v0.y, quads[0].v3.y, rand());
	randPointOnLight.z = quads[0].v0.z;
	vec3 lightHitPos = randPointOnLight;
	vec3 lightNormal = normalize(quads[0].normal);
	vec3 randLightDir = randomCosWeightedDirectionInHemisphere(lightNormal);
	
	Ray r = Ray( randPointOnLight, randLightDir );
	r.origin += lightNormal * uEPS_intersect; // move light ray out to prevent self-intersection with light
	
	t = SceneIntersect(r, intersec, checkModels);
		
	if (intersec.type == DIFF)
	{
		lightHitPos = r.origin + r.direction * t;
		weight = max(0.0, dot(-r.direction, normalize(intersec.normal)));
		lightHitEmission *= intersec.color * weight;
	}
	

	// regular path tracing from camera
	r = originalRay;
	//r.direction = normalize(r.direction);
	checkModels = true;

	
	// Eye path tracing (from Camera) ///////////////////////////////////////////////////////////////////////////
	
	for (int bounces = 0; bounces < 5; bounces++)
	{
	
		t = SceneIntersect(r, intersec, checkModels);
		
		if (t == INFINITY)
			break;
		
		
		if (intersec.type == LIGHT)
		{
			if (bounceIsSpecular || sampleLight)
				accumCol = mask * intersec.emission;
			
			break;
		}

		if (intersec.type == DIFF && sampleLight)
		{
			ableToJoinPaths = abs(t - lightHitDistance) < 0.5;
			
			if (ableToJoinPaths)
			{
				weight = max(0.0, dot(normalize(intersec.normal), -r.direction));
				accumCol = mask * lightHitEmission * weight;
			}

			break;
		}

		// if we reached this point and sampleLight is still true, then we can
		// exit because the light was not found
		if (sampleLight)
			break;
		
		// useful data 
		n = normalize(intersec.normal);
		nl = dot(n, r.direction) < 0.0 ? normalize(n) : normalize(-n);
		x = r.origin + r.direction * t;
		
		
		if ( intersec.type == DIFF || intersec.type == LIGHTWOOD ||
		     intersec.type == DARKWOOD || intersec.type == PAINTING ) // Ideal DIFFUSE reflection
		{

			diffuseCount++;
			
			if (intersec.type == LIGHTWOOD)
			{
				if (abs(nl.x) > 0.5) sampleUV = vec2(x.z, x.y);
				else if (abs(nl.y) > 0.5) sampleUV = vec2(x.x, x.z);
				else sampleUV = vec2(x.x, x.y);
				texColor = texture(tLightWoodTexture, sampleUV * 0.01);
				intersec.color *= GammaToLinear(texColor, 2.2).rgb;
			}
			else if (intersec.type == DARKWOOD)
			{
				sampleUV = vec2( uDoorObjectInvMatrix * vec4(x, 1.0) );
				texColor = texture(tDarkWoodTexture, sampleUV * vec2(0.01,0.005));
				intersec.color *= GammaToLinear(texColor, 2.2).rgb;
			}
			else if (intersec.type == PAINTING)
			{
				sampleUV = vec2((55.0 + x.x) / 110.0, (x.y - 20.0) / 44.0);
				texColor = texture(tPaintingTexture, sampleUV);
				intersec.color *= GammaToLinear(texColor, 2.2).rgb;
			}
					
			mask *= intersec.color;

			bounceIsSpecular = false;

			previousIntersecType = DIFF;
			
			
			if (diffuseCount == 1 && rand() < 0.5)
			{
				// choose random Diffuse sample vector
				r = Ray( x, randomCosWeightedDirectionInHemisphere(nl) );
				r.origin += nl * uEPS_intersect;
				continue;
			}

			dirToLight = normalize(lightHitPos - x);
			lightHitDistance = distance(lightHitPos, x);
			weight = max(0.0, dot(nl, dirToLight));
			mask *= weight;
			
			r = Ray( x, dirToLight );
			r.origin += nl * uEPS_intersect;
			sampleLight = true;
			continue;
		}
		
		if (intersec.type == SPEC)  // Ideal SPECULAR reflection
		{
			mask *= intersec.color;
			
			if (intersec.isModel)
				nl = perturbNormal(nl, vec2(-0.2, 0.2), intersec.uv * 2.0);

			r = Ray( x, reflect(r.direction, nl) ); // reflect ray from surface
			r.direction = randomDirectionInSpecularLobe(r.direction, intersec.roughness);
			r.origin += nl * uEPS_intersect;

			previousIntersecType = SPEC;
			continue;
		}
		
		
		if (intersec.type == REFR)  // Ideal dielectric refraction
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
				r.origin += nl * uEPS_intersect;
				
				previousIntersecType = REFR;
				continue;	
			}
			// transmit ray through surface
			
			if (previousIntersecType == DIFF) 
				mask *= 4.0;
		
			previousIntersecType = REFR;
		
			mask *= TP;
			mask *= intersec.color;
			tdir = refract(r.direction, nl, ratioIoR);
			r = Ray(x, tdir);
			r.origin -= nl * uEPS_intersect;

			continue;
				
		} // end if (intersec.type == REFR)
		
		if (intersec.type == COAT || intersec.type == CHECK)  // Diffuse object underneath with ClearCoat on top
		{	
			nc = 1.0; // IOR of Air
			nt = 1.4; // IOR of ClearCoat
			Re = calcFresnelReflectance(r.direction, n, nc, nt, ratioIoR);
			Tr = 1.0 - Re;
			P  = 0.25 + (0.5 * Re);
                	RP = Re / P;
                	TP = Tr / (1.0 - P);

			previousIntersecType = COAT;
			
			// choose either specular reflection or diffuse
			if( rand() < P )
			{	
				mask *= RP;
				r = Ray( x, reflect(r.direction, nl) ); // reflect ray from surface
				r.direction = randomDirectionInSpecularLobe(r.direction, intersec.roughness);
				r.origin += nl * uEPS_intersect;
				continue;	
			}
			
			if (intersec.type == CHECK)
			{
				float q = clamp( mod( dot( floor(x.xz * 0.04), vec2(1.0) ), 2.0 ) , 0.0, 1.0 );
				intersec.color = checkCol0 * q + checkCol1 * (1.0 - q);	
			}
			
			else if (intersec.type == COAT)
			{
				// spherical coordinates
				//sampleUV.x = atan(-nl.z, nl.x) * ONE_OVER_TWO_PI + 0.5;
				//sampleUV.y = asin(clamp(nl.y, -1.0, 1.0)) * ONE_OVER_PI + 0.5;
				texColor = texture(tMarbleTexture, intersec.uv * vec2(-1.0, 1.0));
				//texColor = pow(texColor, vec4(2));
				texColor = clamp(texColor + vec4(0.1), 0.0, 1.0);
				intersec.color = GammaToLinear(texColor, 2.2).rgb;
				
			}
			
			diffuseCount++;

			bounceIsSpecular = false;

			mask *= TP;
			mask *= intersec.color;
			
			if (diffuseCount == 1 && rand() < 0.5)
			{
				// choose random Diffuse sample vector
				r = Ray( x, randomCosWeightedDirectionInHemisphere(nl) );
				r.origin += nl * uEPS_intersect;
				continue;
			}

			dirToLight = normalize(lightHitPos - x);
			lightHitDistance = distance(lightHitPos, x);
			weight = max(0.0, dot(nl, dirToLight));
			mask *= weight;
			
			r = Ray( x, dirToLight );
			r.origin += nl * uEPS_intersect;
			sampleLight = true;
			continue;	
				
		} //end if (intersec.type == COAT)
		
	} // end for (int bounces = 0; bounces < 5; bounces++)
	
	
	return max(vec3(0), accumCol);      
}


//-----------------------------------------------------------------------
void SetupScene(void)
//-----------------------------------------------------------------------
{
	vec3 z  = vec3(0);// No color value, Black
	vec3 L2 = vec3(1.0, 0.9, 0.8) * 15.0;// Bright Yellowish light
	vec3 wallColor = vec3(0.5);
	vec3 tableColor = vec3(1.0, 0.7, 0.4) * 0.6;
	vec3 brassColor = vec3(1.0, 0.7, 0.5) * 0.7;
	
	quads[0] = Quad( vec3(0,0,1), vec3( 180,-100,-298.5), vec3( 280,-100,-298.5), vec3( 280,  90,-298.5), vec3( 180,  90,-298.5), L2, z, 0.0, LIGHT, false);// Area Light Quad in doorway
	
	quads[1] = Quad( vec3(0,0,1), vec3(-350,-100,-300), vec3( 350,-100,-300), vec3( 350, 150,-300), vec3(-350, 150,-300),  z, wallColor, 0.0,   DIFF, false);// Back Wall (in front of camera, visible at startup)
	quads[2] = Quad( vec3(0,0,-1), vec3( 350,-100, 200), vec3(-350,-100, 200), vec3(-350, 150, 200), vec3( 350, 150, 200),  z, wallColor, 0.0,   DIFF, false);// Front Wall (behind camera, not visible at startup)
	quads[3] = Quad( vec3(1,0,0), vec3(-350,-100, 200), vec3(-350,-100,-300), vec3(-350, 150,-300), vec3(-350, 150, 200),  z, wallColor, 0.0,   DIFF, false);// Left Wall
	quads[4] = Quad( vec3(-1,0,0), vec3( 350,-100,-300), vec3( 350,-100, 200), vec3( 350, 150, 200), vec3( 350, 150,-300),  z, wallColor, 0.0,   DIFF, false);// Right Wall
	quads[5] = Quad( vec3(0,-1,0), vec3(-350, 150,-300), vec3( 350, 150,-300), vec3( 350, 150, 200), vec3(-350, 150, 200),  z, vec3(1), 0.0,   DIFF, false);// Ceiling
	quads[6] = Quad( vec3(0,1,0), vec3(-350,-100,-300), vec3(-350,-100, 200), vec3( 350,-100, 200), vec3( 350,-100,-300),  z, vec3(1), 0.0,  CHECK, false);// Floor
	
	quads[7] = Quad( vec3(0,0,1), vec3(-55, 20,-295), vec3( 55, 20,-295), vec3( 55, 65,-295), vec3(-55, 65,-295), z, vec3(1.0), 0.0, PAINTING, false);// Wall Painting
	
	boxes[0] = Box( vec3(-100,-60,-230), vec3(100,-57,-130), z, vec3(1.0), 0.0, LIGHTWOOD, false);// Table Top
	boxes[1] = Box( vec3(-90,-100,-150), vec3(-84,-60,-144), z, vec3(0.8, 0.85, 0.9),  0.1, SPEC, false);// Table leg left front
	boxes[2] = Box( vec3(-90,-100,-220), vec3(-84,-60,-214), z, vec3(0.8, 0.85, 0.9),  0.1, SPEC, false);// Table leg left rear
	boxes[3] = Box( vec3( 84,-100,-150), vec3( 90,-60,-144), z, vec3(0.8, 0.85, 0.9),  0.1, SPEC, false);// Table leg right front
	boxes[4] = Box( vec3( 84,-100,-220), vec3( 90,-60,-214), z, vec3(0.8, 0.85, 0.9),  0.1, SPEC, false);// Table leg right rear
	
	boxes[5] = Box( vec3(-60, 15, -299), vec3( 60, 70, -296), z, vec3(0.01, 0, 0), 0.3, SPEC, false);// Painting Frame
	
	boxes[6] = Box( vec3( 172,-100,-302), vec3( 180,  98,-299), z, vec3(0.001), 0.3, SPEC, false);// Door Frame left
	boxes[7] = Box( vec3( 280,-100,-302), vec3( 288,  98,-299), z, vec3(0.001), 0.3, SPEC, false);// Door Frame right
	boxes[8] = Box( vec3( 172,  90,-302), vec3( 288,  98,-299), z, vec3(0.001), 0.3, SPEC, false);// Door Frame top
	boxes[9] = Box( vec3(   0, -94,  -3), vec3( 101,  95,   3), z, vec3(0.7), 0.0, DARKWOOD, false);// Door
	
	openCylinders[0] = OpenCylinder( 1.5, vec3( 179,  64,-297), vec3( 179,  80,-297), z, brassColor, 0.2, SPEC, false);// Door Hinge upper
	openCylinders[1] = OpenCylinder( 1.5, vec3( 179,  -8,-297), vec3( 179,   8,-297), z, brassColor, 0.2, SPEC, false);// Door Hinge middle
	openCylinders[2] = OpenCylinder( 1.5, vec3( 179, -80,-297), vec3( 179, -64,-297), z, brassColor, 0.2, SPEC, false);// Door Hinge lower
	
	spheres[0] = Sphere( 4.0, vec3( 88, -10,  7.8), z, brassColor, 0.0, SPEC, false);// Door knob front
	spheres[1] = Sphere( 4.0, vec3( 88, -10, -7), z, brassColor, 0.0, SPEC, false);// Door knob back
}



#include <pathtracing_main>
