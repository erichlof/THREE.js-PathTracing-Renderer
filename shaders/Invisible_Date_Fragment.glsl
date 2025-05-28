precision highp float;
precision highp int;
precision highp sampler2D;

#include <pathtracing_uniforms_and_defines>

uniform sampler2D tTriangleTexture;
uniform sampler2D tAABBTexture;
uniform sampler2D tShapes_DataTexture;
uniform sampler2D tShapes_AABB_DataTexture;
uniform sampler2D tPaintingTexture;

uniform mat4 uModelObject3DInvMatrix;
uniform mat4 uDoorObject3DInvMatrix;

//float InvTextureWidth = 0.000244140625; // (1 / 4096 texture width)
//float InvTextureWidth = 0.00048828125;  // (1 / 2048 texture width)
//float InvTextureWidth = 0.0009765625;   // (1 / 1024 texture width)

#define INV_TEXTURE_WIDTH 0.00048828125

#define N_RECTANGLES 1
#define N_BOXES 7

vec3 rayOrigin, rayDirection;
// recorded intersection data:
vec3 hitNormal, hitColor;
vec2 hitUV;
float hitObjectID = -INFINITY;
float hitOpacity, hitIoR, hitClearCoat, hitMetalness, hitRoughness;
int hitType = -100;

struct Rectangle { vec3 position; vec3 normal; float radiusU; float radiusV; vec3 color; float roughness; int type; };
struct Box { vec3 minCorner; vec3 maxCorner; vec3 color; float roughness; int type; };

Rectangle rectangles[N_RECTANGLES];
Box boxes[N_BOXES];


#include <pathtracing_random_functions>

#include <pathtracing_calc_fresnel_reflectance>

#include <pathtracing_rectangle_intersect>

#include <pathtracing_sphere_intersect>

#include <pathtracing_unit_sphere_intersect>

#include <pathtracing_unit_cylinder_intersect>

#include <pathtracing_unit_cone_intersect>

#include <pathtracing_unit_paraboloid_intersect>

#include <pathtracing_unit_box_intersect>

#include <pathtracing_box_intersect>

#include <pathtracing_boundingbox_intersect>

#include <pathtracing_box_interior_intersect>

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

//vec4 boxNodeData0 corresponds to: .x = idShape,      .y = aabbMin.x, .z = aabbMin.y, .w = aabbMin.z
//vec4 boxNodeData1 corresponds to: .x = idRightChild, .y = aabbMax.x, .z = aabbMax.y, .w = aabbMax.z

void GetShapesBoxNodeData(const in float i, inout vec4 boxNodeData0, inout vec4 boxNodeData1)
{
	// each bounding box's data is encoded in 2 rgba(or xyzw) texture slots 
	float ix2 = i * 2.0;
	// (ix2 + 0.0) corresponds to: .x = idShape,      .y = aabbMin.x, .z = aabbMin.y, .w = aabbMin.z 
	// (ix2 + 1.0) corresponds to: .x = idRightChild, .y = aabbMax.x, .z = aabbMax.y, .w = aabbMax.z 

	ivec2 uv0 = ivec2( mod(ix2 + 0.0, 2048.0), (ix2 + 0.0) * INV_TEXTURE_WIDTH ); // data0
	ivec2 uv1 = ivec2( mod(ix2 + 1.0, 2048.0), (ix2 + 1.0) * INV_TEXTURE_WIDTH ); // data1
	
	boxNodeData0 = texelFetch(tShapes_AABB_DataTexture, uv0, 0);
	boxNodeData1 = texelFetch(tShapes_AABB_DataTexture, uv1, 0);
}


//---------------------------------------------------------------------------------------
float SceneIntersect( out int isRayExiting )
//---------------------------------------------------------------------------------------
{
	mat4 invTransformMatrix, hitMatrix;
	vec4 currentBoxNodeData0, nodeAData0, nodeBData0, tmpNodeData0;
	vec4 currentBoxNodeData1, nodeAData1, nodeBData1, tmpNodeData1;
	vec4 vd0, vd1, vd2, vd3, vd4, vd5, vd6, vd7;
	vec4 sd0, sd1, sd2, sd3, sd4, sd5, sd6, sd7;

	vec3 inverseDir = 1.0 / rayDirection;
	vec3 normal;
	vec3 rObjOrigin, rObjDirection;
	vec3 n, hitPoint;

	vec2 currentStackData, stackDataA, stackDataB, tmpStackData;
	ivec2 uv0, uv1, uv2, uv3, uv4, uv5, uv6, uv7;

	float d;
	float t = INFINITY;
	float stackptr = 0.0;
	float id = 0.0;
	float shapeID = 0.0;
	float patternX = 0.0;
	float patternZ = 0.0;
	float tu, tv;
	float triangleID = 0.0;
	float triangleU = 0.0;
	float triangleV = 0.0;
	float triangleW = 0.0;

	int objectCount = 0;
	
	hitObjectID = -INFINITY;

	int skip = FALSE;
	int triangleLookupNeeded = FALSE;
	int shapeLookupNeeded = FALSE;



	// UTAH TEAPOT

	// transform ray into GLTF_Model's object space
	rObjOrigin = vec3( uModelObject3DInvMatrix * vec4(rayOrigin, 1.0) );
	rObjDirection = vec3( uModelObject3DInvMatrix * vec4(rayDirection, 0.0) );
	inverseDir = 1.0 / rObjDirection;

	GetBoxNodeData(stackptr, currentBoxNodeData0, currentBoxNodeData1);
	currentStackData = vec2(stackptr, BoundingBoxIntersect(currentBoxNodeData0.yzw, currentBoxNodeData1.yzw, rObjOrigin, inverseDir));
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
			stackDataA = vec2(currentStackData.x + 1.0, BoundingBoxIntersect(nodeAData0.yzw, nodeAData1.yzw, rObjOrigin, inverseDir));
			stackDataB = vec2(currentBoxNodeData1.x, BoundingBoxIntersect(nodeBData0.yzw, nodeBData1.yzw, rObjOrigin, inverseDir));
			
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

		d = BVH_TriangleIntersect( vec3(vd0.xyz), vec3(vd0.w, vd1.xy), vec3(vd1.zw, vd2.x), rObjOrigin, rObjDirection, tu, tv );

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

		
		// interpolated normal using triangle intersection's uv's
		triangleW = 1.0 - triangleU - triangleV;
		normal = (triangleW * vec3(vd2.yzw) + triangleU * vec3(vd3.xyz) + triangleV * vec3(vd3.w, vd4.xy));
		// or, triangle face normal for flat-shaded, low-poly look
		//normal = ( cross(vec3(vd0.w, vd1.xy) - vec3(vd0.xyz), vec3(vd1.zw, vd2.x) - vec3(vd0.xyz)) );
		
		hitNormal = transpose(mat3(uModelObject3DInvMatrix)) * normal;
		hitUV = triangleW * vec2(vd4.zw) + triangleU * vec2(vd5.xy) + triangleV * vec2(vd5.zw);
		//hitType = int(vd6.x);
		//hitAlbedoTextureID = int(vd7.x);
		hitColor = vec3(1);
		hitRoughness = 0.0;
		hitType = COAT;
		hitObjectID = float(objectCount);
		//hitIsModel = TRUE;

	} // end if (triangleLookupNeeded == TRUE)

	objectCount++;


	// reset variables
	inverseDir = 1.0 / rayDirection;
	stackptr = 0.0;
	GetShapesBoxNodeData(stackptr, currentBoxNodeData0, currentBoxNodeData1);
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
			
			GetShapesBoxNodeData(currentStackData.x, currentBoxNodeData0, currentBoxNodeData1);
                }
		skip = FALSE; // reset skip
		

		if (currentBoxNodeData0.x < 0.0) // < 0.0 signifies an inner node
		{
			GetShapesBoxNodeData(currentStackData.x + 1.0, nodeAData0, nodeAData1);
			GetShapesBoxNodeData(currentBoxNodeData1.x, nodeBData0, nodeBData1);
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
		
		// //debug leaf AABB visualization
		// d = BoxIntersect(currentBoxNodeData0.yzw, currentBoxNodeData1.yzw, rayOrigin, rayDirection, n, isRayExiting);
		// if (d > 0.0 && d < t)
		// {
		// 	t = d;
		// 	hitNormal = n;
		// 	hitColor = vec3(1,1,0);
		// 	hitType = REFR;
		// 	hitObjectID = float(objectCount);
		// }

		// else this is a leaf

		// each shape's data is encoded in 8 rgba(or xyzw) texture slots
		id = 8.0 * currentBoxNodeData0.x;

		uv0 = ivec2( mod(id + 0.0, 2048.0), (id + 0.0) * INV_TEXTURE_WIDTH );
		uv1 = ivec2( mod(id + 1.0, 2048.0), (id + 1.0) * INV_TEXTURE_WIDTH );
		uv2 = ivec2( mod(id + 2.0, 2048.0), (id + 2.0) * INV_TEXTURE_WIDTH );
		uv3 = ivec2( mod(id + 3.0, 2048.0), (id + 3.0) * INV_TEXTURE_WIDTH );
		uv4 = ivec2( mod(id + 4.0, 2048.0), (id + 4.0) * INV_TEXTURE_WIDTH );
		
		invTransformMatrix = mat4( texelFetch(tShapes_DataTexture, uv0, 0),
		 			   texelFetch(tShapes_DataTexture, uv1, 0), 
		 			   texelFetch(tShapes_DataTexture, uv2, 0), 
		 			   texelFetch(tShapes_DataTexture, uv3, 0) );

		sd4 = texelFetch(tShapes_DataTexture, uv4, 0);

		// transform ray into shape's object space
		rObjOrigin = vec3( invTransformMatrix * vec4(rayOrigin, 1.0) );
		rObjDirection = vec3( invTransformMatrix * vec4(rayDirection, 0.0) );

		if (sd4.x == 0.0)
			d = UnitBoxIntersect(rObjOrigin, rObjDirection, n);
		else if (sd4.x == 1.0)
			d = UnitSphereIntersect(rObjOrigin, rObjDirection, n);
		else if (sd4.x == 2.0)
			d = UnitCylinderIntersect(rObjOrigin, rObjDirection, n);
		else if (sd4.x == 3.0)
			d = UnitConeIntersect(rObjOrigin, rObjDirection, n);
		else if (sd4.x == 4.0)
			d = UnitParaboloidIntersect(rObjOrigin, rObjDirection, n);
		
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
		
		sd0 = texelFetch(tShapes_DataTexture, uv0, 0);
		sd1 = texelFetch(tShapes_DataTexture, uv1, 0);
		sd2 = texelFetch(tShapes_DataTexture, uv2, 0);
		sd3 = texelFetch(tShapes_DataTexture, uv3, 0);
		sd4 = texelFetch(tShapes_DataTexture, uv4, 0);
		sd5 = texelFetch(tShapes_DataTexture, uv5, 0);
		sd6 = texelFetch(tShapes_DataTexture, uv6, 0);
		sd7 = texelFetch(tShapes_DataTexture, uv7, 0);

		hitNormal = transpose(mat3(hitMatrix)) * hitNormal;
		hitType = int(sd4.y);
		hitRoughness = sd4.w;
		hitColor = sd5.rgb;
		hitIoR = sd6.x;

		hitObjectID = float(objectCount);
	}

	objectCount++;


	// LIGHT IN DOORWAY
	d = RectangleIntersect( rectangles[0].position, rectangles[0].normal, rectangles[0].radiusU, rectangles[0].radiusV, rayOrigin, rayDirection);
	if (d < t)
	{
		t = d;
		hitNormal = rectangles[0].normal;
		hitColor = rectangles[0].color;
		hitRoughness = rectangles[0].roughness;
		hitType = rectangles[0].type;
		hitObjectID = float(objectCount);
	}
	objectCount++;
	
	// ROOM
	d = BoxInteriorIntersect( boxes[0].minCorner, boxes[0].maxCorner, rayOrigin, rayDirection, n );
	hitPoint = rayOrigin + rayDirection * d;
	if (n == vec3(1,0,0))
	{
		if (hitPoint.y < 80.0 && hitPoint.z < 60.0 && hitPoint.z > 20.0)
			d = INFINITY;
	}
		
	if (d < t)// && n != vec3(0,0,-1))
	{
		t = d;
		hitNormal = n;
		hitColor = boxes[0].color;
		hitRoughness = boxes[0].roughness;
		hitType = boxes[0].type;
		hitObjectID = float(objectCount);
	}
	objectCount++;

	// FLOOR TILES-LEVEL PATTERN (VERY THIN, FLAT BOX)
	d = BoxIntersect( boxes[1].minCorner, boxes[1].maxCorner, rayOrigin, rayDirection, n, isRayExiting );
	hitPoint = rayOrigin + rayDirection * d;
	patternX = cos(hitPoint.x * 0.2);
	patternZ = cos(hitPoint.z * 0.2);
	if ((patternX > 0.0 && patternX < 0.2) || (patternZ > 0.0 && patternZ < 0.2))
		d = INFINITY;

	if (d < t)
	{
		t = d;
		hitNormal = n;
		hitColor = boxes[1].color;
		hitRoughness = boxes[1].roughness;
		hitType = boxes[1].type;
		hitObjectID = float(objectCount);
	}
	objectCount++;

	// MONDRIAN PAINTING
	d = BoxIntersect( boxes[2].minCorner, boxes[2].maxCorner, rayOrigin, rayDirection, n, isRayExiting );
	if (d < t)
	{	
		t = d;
		hitNormal = n;
		hitColor = boxes[2].color;
		hitRoughness = boxes[2].roughness;
		hitType = boxes[2].type;
		hitObjectID = float(objectCount);
	}
	objectCount++;


	// DOOR (TALL BOX)
	// transform ray into Tall Box's object space
	rObjOrigin = vec3( uDoorObject3DInvMatrix * vec4(rayOrigin, 1.0) );
	rObjDirection = vec3( uDoorObject3DInvMatrix * vec4(rayDirection, 0.0) );
	d = BoxIntersect( boxes[3].minCorner, boxes[3].maxCorner, rObjOrigin, rObjDirection, n, isRayExiting );
	if (d < t)
	{	
		t = d;
		// transfom normal back into world space
		hitNormal = transpose(mat3(uDoorObject3DInvMatrix)) * n;
		hitColor = boxes[3].color;
		hitRoughness = boxes[3].roughness;
		hitType = boxes[3].type;
		hitObjectID = float(objectCount);
	}
	objectCount++;

	// DOOR HANDLE PLATE ATTACHMENT (THIN, FLAT BOX)
	d = BoxIntersect( boxes[4].minCorner, boxes[4].maxCorner, rObjOrigin, rObjDirection, n, isRayExiting );
	if (d < t)
	{	
		t = d;
		// transfom normal back into world space
		hitNormal = transpose(mat3(uDoorObject3DInvMatrix)) * n;
		hitColor = boxes[4].color;
		hitRoughness = boxes[4].roughness;
		hitType = boxes[4].type;
		hitObjectID = float(objectCount);
	}
	objectCount++;

	// DOOR HANDLE BARREL (SMALL BOX)
	d = BoxIntersect( boxes[5].minCorner, boxes[5].maxCorner, rObjOrigin, rObjDirection, n, isRayExiting );
	if (d < t)
	{	
		t = d;
		// transfom normal back into world space
		hitNormal = transpose(mat3(uDoorObject3DInvMatrix)) * n;
		hitColor = boxes[5].color;
		hitRoughness = boxes[5].roughness;
		hitType = boxes[5].type;
		hitObjectID = float(objectCount);
	}
	objectCount++;

	// DOOR HANDLE/LEVER ITSELF (SMALL BOX)
	d = BoxIntersect( boxes[6].minCorner, boxes[6].maxCorner, rObjOrigin, rObjDirection, n, isRayExiting );
	if (d < t)
	{	
		t = d;
		// transfom normal back into world space
		hitNormal = transpose(mat3(uDoorObject3DInvMatrix)) * n;
		hitColor = boxes[6].color;
		hitRoughness = boxes[6].roughness;
		hitType = boxes[6].type;
		hitObjectID = float(objectCount);
	}
	objectCount++;

	

	
	
	
	return t;

} // end float SceneIntersect( out int isRayExiting )



vec3 sampleRectangleLight(vec3 x, vec3 nl, Rectangle light, out float weight)
{
	vec3 U = normalize(cross( abs(light.normal.y) < 0.9 ? vec3(0, 1, 0) : vec3(0, 0, 1), light.normal));
	vec3 V = cross(light.normal, U);
	vec3 randPointOnLight = light.position;
	randPointOnLight += U * light.radiusU * (rng() * 2.0 - 1.0) * 0.9;
	randPointOnLight += V * light.radiusV * (rng() * 2.0 - 1.0) * 0.9;
	
	vec3 dirToLight = randPointOnLight - x;
	float r2 = light.radiusU * light.radiusV;
	float d2 = dot(dirToLight, dirToLight);
	float cos_a_max = sqrt(1.0 - clamp( r2 / d2, 0.0, 1.0));

	dirToLight = normalize(dirToLight);
	float dotNlRayDir = max(0.0, dot(nl, dirToLight)); 
	weight = 2.0 * (1.0 - cos_a_max) * max(0.0, -dot(dirToLight, light.normal)) * dotNlRayDir;
	weight = clamp(weight, 0.0, 1.0);

	return dirToLight;
}


//-----------------------------------------------------------------------------------------------------------------------------
vec3 CalculateRadiance( out vec3 objectNormal, out vec3 objectColor, out float objectID, out float pixelSharpness )
//-----------------------------------------------------------------------------------------------------------------------------
{
	vec4 texColor;

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

	vec2 sampleUV;
	
	float t;
	float nc, nt, ratioIoR, Re, Tr;
	float weight;
	float thickness = 0.1;
	float scatteringDistance;
	float previousObjectID;
	float reflectionRoughness = 0.0;
	float previousHitRoughness = 0.0;
	hitRoughness = 0.0;

	int reflectionBounces = -1;
	int diffuseBounces = -1;
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
		if (isDiffuseBounceTime == TRUE)
			diffuseBounces++;

		previousIntersecType = hitType;
		previousObjectID = hitObjectID;
		previousHitRoughness = hitRoughness;

		t = SceneIntersect(isRayExiting);
		

		if (t == INFINITY)
		{
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
			//objectID = hitObjectID;
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
		

		    
		if (hitType == DIFF || hitType == PAINTING) // Ideal DIFFUSE reflection
		{
			if (hitType == PAINTING && bounceIsSpecular == TRUE)
			{ 	// the * 0.0217391304 below is the same as dividing by 46, which is the width and height of painting box geometry.
				// Moving the hitpoint (x) up to where the painting box geometry starts (x + 60.0, y - 40.0), and dividing 
				// by the containing box dimensions, puts the sampleUV coordinates into the desired 0.0-1.0 range
				sampleUV = vec2((x.x + 58.0) * 0.0217391304, (x.y - 46.0) * 0.0217391304);
				texColor = texture(tPaintingTexture, sampleUV);
				hitColor *= (texColor.rgb * texColor.rgb);// pow(texColor.rgb, vec3(2.2));
			}

			if (bounces == 0 || (diffuseCount == 0 && coatTypeIntersected == FALSE && previousIntersecType == SPEC))	
				objectColor = hitColor;

			diffuseCount++;

			mask *= hitColor;

			bounceIsSpecular = FALSE;

			hitRoughness = 1.0;

			rayOrigin = x + nl * uEPS_intersect;
                        
			if (diffuseCount == 1)
			{
				diffuseBounceMask = mask;
				diffuseBounceRayOrigin = rayOrigin;
				diffuseBounceRayDirection = randomCosWeightedDirectionInHemisphere(nl);
				willNeedDiffuseBounceRay = TRUE;
			}
			
			rayDirection = sampleRectangleLight(x, nl, rectangles[0], weight);
			mask *= weight;
			sampleLight = TRUE;
			continue;
			
		} // end if (hitType == DIFF)
		
		if (hitType == SPEC)  // Ideal SPECULAR reflection
		{
			mask *= hitColor;

			rayDirection = reflect(rayDirection, nl); // reflect ray from surface
			rayDirection = randomDirectionInSpecularLobe(rayDirection, hitRoughness);
			rayOrigin = x + nl * uEPS_intersect;
			continue;
		}
		
		if (hitType == REFR)  // Ideal dielectric REFRACTION
		{
			nc = 1.0; // IOR of Air
			nt = hitIoR; // IOR of intersected material
			Re = calcFresnelReflectance(rayDirection, n, nc, nt, ratioIoR);
			Tr = 1.0 - Re;

			if (Re == 1.0)
			{
				rayDirection = reflect(rayDirection, nl);
				rayOrigin = x + nl * uEPS_intersect;
				continue;
			}

			//if (diffuseCount == 0 && hitObjectID != previousObjectID && n == nl)
			if (bounces == 0)
			{
				reflectionMask = mask * Re;
				reflectionRoughness = hitRoughness;
				reflectionRayDirection = reflect(rayDirection, nl); // reflect ray from surface
				reflectionRayOrigin = x + nl * uEPS_intersect;
				willNeedReflectionRay = TRUE;
				if (bounces == 0 && hitColor == vec3(0.1, 0.8, 1.0) && isRayExiting == FALSE)
					reflectionNeedsToBeSharp = TRUE;
			}

			// transmit ray through surface
			
			// is ray leaving a solid object from the inside? 
			// If so, attenuate ray color with object color by how far ray has travelled through the medium
			// if (distance(n, nl) > 0.1)
			// {
			// 	mask *= exp( log(clamp(hitColor, 0.01, 0.99)) * thickness * t ); 
			// }

			mask *= hitColor;
			mask *= Tr;
			
			rayDirection = refract(rayDirection, nl, ratioIoR);
			rayOrigin = x - nl * uEPS_intersect;

			// turn on refracting caustics
			if ((diffuseBounces == 0 || diffuseBounces == 1) && hitColor == vec3(0,1,1) && t < 20.0)
				bounceIsSpecular = TRUE;
			
			continue;
			
		} // end if (hitType == REFR)
		
		if (hitType == COAT)  // Diffuse object underneath with ClearCoat on top
		{
			
			nc = 1.0; // IOR of Air
			nt = 1.4; // IOR of Clear Coat
			Re = calcFresnelReflectance(rayDirection, nl, nc, nt, ratioIoR);
			Tr = 1.0 - Re;
			
			if (bounces == 0)// || (bounces == 1 && hitObjectID != objectID && bounceIsSpecular == TRUE))
			{
				reflectionMask = mask * Re;
				reflectionRoughness = hitRoughness;
				reflectionRayDirection = reflect(rayDirection, nl); // reflect ray from surface
				reflectionRayDirection = randomDirectionInSpecularLobe(reflectionRayDirection, hitRoughness);
				reflectionRayOrigin = x + nl * uEPS_intersect;
				willNeedReflectionRay = TRUE;
			}

			diffuseCount++;

			mask *= Tr;
			mask *= hitColor;

			bounceIsSpecular = FALSE;

			hitRoughness = 1.0;
			
			rayOrigin = x + nl * uEPS_intersect;
                        
			if (diffuseCount == 1)
			{
				diffuseBounceMask = mask;
				diffuseBounceRayOrigin = rayOrigin;
				diffuseBounceRayDirection = randomCosWeightedDirectionInHemisphere(nl);
				willNeedDiffuseBounceRay = TRUE;
			}

			rayDirection = sampleRectangleLight(x, nl, rectangles[0], weight);
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
	vec3 L1 = vec3(1.0, 1.0, 1.0) * 30.0;// Bright light
	
	rectangles[0] = Rectangle( vec3(-101, 40, 40), vec3(1,0,0), 20.0, 40.0, L1, 0.0, LIGHT);// Rectangle Area Light on left

	boxes[0] = Box(vec3(-101, 0, -100), vec3(101, 100, 100), vec3(0.5), 0.0, DIFF);// the Room interior
	boxes[1] = Box(vec3(-101, 0, -100), vec3(101, 0.2, 100), vec3(0.5), 0.2, COAT);// Floor tiles-level pattern
	boxes[2] = Box(vec3(-58, 46, -100), vec3(-12, 92, -98), vec3(1), 0.0, PAINTING); // Mondrian Painting
	boxes[3] = Box(vec3(-1, -39, -40), vec3(1, 40, 0), vec3(1), 0.0, DIFF); // Door
	boxes[4] = Box(vec3(1, -6, -37.5), vec3(1.2, 4, -34.5), vec3(1), 0.1, SPEC); // Metal rectangular Plate attachment that holds handle to the door
	boxes[5] = Box(vec3(1.2, -1, -36.5), vec3(2.5, 0, -35.5), vec3(1), 0.1, SPEC); // Metal barrel connecting metal plate and door handle
	boxes[6] = Box(vec3(2.5, -1, -37), vec3(3, 0, -30), vec3(1), 0.1, SPEC); // Metal door Handle/Lever itself
	
}


#include <pathtracing_main>
