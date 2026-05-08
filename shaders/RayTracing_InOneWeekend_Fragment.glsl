precision highp float;
precision highp int;
precision highp sampler2D;

#include <pathtracing_uniforms_and_defines>

uniform sampler2D tShape_DataTexture;
uniform sampler2D tAABB_DataTexture;
uniform float uAnimationType;
uniform bool uShowBVH_Leaves;

//float InvTextureWidth = 0.000244140625; // (1 / 4096 texture width)
//float InvTextureWidth = 0.00048828125;  // (1 / 2048 texture width)
//float InvTextureWidth = 0.0009765625;   // (1 / 1024 texture width)

#define INV_TEXTURE_WIDTH 0.00048828125

#define N_SPHERES 4

vec3 rayOrigin, rayDirection;
// recorded intersection data:
vec3 hitNormal, hitEmission, hitColor;
vec2 hitUV;
float hitObjectID;
float hitRoughness;
int hitType = -100;

struct Sphere { float radius; vec3 position; vec3 emission; vec3 color; int type; };

Sphere spheres[N_SPHERES];


#include <pathtracing_random_functions>

#include <pathtracing_calc_fresnel_reflectance>

#include <pathtracing_sphere_intersect>

#include <pathtracing_unit_sphere_intersect>

#include <pathtracing_unit_cylinder_intersect>

#include <pathtracing_unit_cone_intersect>

#include <pathtracing_unit_paraboloid_intersect>

#include <pathtracing_unit_box_intersect>

#include <pathtracing_box_intersect>

#include <pathtracing_boundingbox_intersect>



float stackNodeIDs[32];

//vec4 boxNodeData0 corresponds to: .x = aabbMin.x, .y = aabbMin.y, .z =      aabbMin.z, .w = aabbMax.x,
//vec4 boxNodeData1 corresponds to: .x = aabbMax.y, .y = aabbMax.z, .z = primitiveCount, .w = leafOrChild_ID

void GetBoxNodeData(const in float i, inout vec4 boxNodeData0, inout vec4 boxNodeData1)
{
	// each bounding box's data is encoded in 2 rgba(or xyzw) texture slots 
	float ix2 = i * 2.0;
	// (ix2 + 0.0) corresponds to: .x = aabbMin.x, .y = aabbMin.y, .z =      aabbMin.z, .w = aabbMax.x,
	// (ix2 + 1.0) corresponds to: .x = aabbMax.y, .y = aabbMax.z, .z = primitiveCount, .w = leafOrChild_ID 

	ivec2 uv0 = ivec2( mod(ix2 + 0.0, 2048.0), (ix2 + 0.0) * INV_TEXTURE_WIDTH ); // data0
	ivec2 uv1 = ivec2( mod(ix2 + 1.0, 2048.0), (ix2 + 1.0) * INV_TEXTURE_WIDTH ); // data1
	
	boxNodeData0 = texelFetch(tAABB_DataTexture, uv0, 0);
	boxNodeData1 = texelFetch(tAABB_DataTexture, uv1, 0);
}


mat4 makeScaleX(float s)
{
	return mat4(
	 	s, 0, 0, 0,
	 	0, 1, 0, 0,
	        0, 0, 1, 0,
	 	0, 0, 0, 1 
	);
}
mat4 makeScaleY(float s)
{
	return mat4(
	 	1, 0, 0, 0,
	 	0, s, 0, 0,
	        0, 0, 1, 0,
	 	0, 0, 0, 1 
	);
}
mat4 makeScaleZ(float s)
{
	return mat4(
	 	1, 0, 0, 0,
	 	0, 1, 0, 0,
	        0, 0, s, 0,
	 	0, 0, 0, 1 
	);
}


//---------------------------------------------------------------------------------------
float SceneIntersect( )
//---------------------------------------------------------------------------------------
{
	mat4 invTransformMatrix, hitMatrix;
	vec4 currentBoxNodeData0, nodeAData0, nodeBData0, tmpNodeData0;
	vec4 currentBoxNodeData1, nodeAData1, nodeBData1, tmpNodeData1;
	vec4 sd0, sd1, sd2, sd3, sd4, sd5, sd6, sd7;

	vec3 inverseDir = 1.0 / rayDirection;
	vec3 normal;
	vec3 rObjOrigin, rObjDirection;
	vec3 n, hitPoint;

	ivec2 uv0, uv1, uv2, uv3, uv4, uv5, uv6, uv7;

	float stackNodeID_A, stackNodeID_B, tmpNodeID;
	float stackNodeA_t, stackNodeB_t, tmpNode_t;
	float d;
	float t = INFINITY;
	float stackptr = 0.0;
	float id = 0.0;
	float shapeID = 0.0;

	int objectCount = 0;
	
	hitObjectID = -INFINITY;

	int isRayExiting = FALSE;
	int popNextNodeOffStack = TRUE;
	int shapeLookupNeeded = FALSE;



	GetBoxNodeData(stackptr, currentBoxNodeData0, currentBoxNodeData1);
	d = BoundingBoxIntersect(currentBoxNodeData0.xyz, vec3(currentBoxNodeData0.w, currentBoxNodeData1.xy), rayOrigin, inverseDir);
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
			stackNodeA_t = BoundingBoxIntersect(nodeAData0.xyz, vec3(nodeAData0.w, nodeAData1.xy), rayOrigin, inverseDir);
			stackNodeB_t = BoundingBoxIntersect(nodeBData0.xyz, vec3(nodeBData0.w, nodeBData1.xy), rayOrigin, inverseDir);
			
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
		
		if (uShowBVH_Leaves)
		{
			// debug leaf AABB visualization
			d = BoxIntersect(currentBoxNodeData0.xyz, vec3(currentBoxNodeData0.w, currentBoxNodeData1.xy), rayOrigin, rayDirection, n, isRayExiting);
			if (d > 0.0 && d < t)
			{
				t = d;
				hitNormal = n;
				hitColor = vec3(1,1,0);
				hitType = REFR;
				hitObjectID = float(objectCount);
			}
		}
		// else this is a leaf

		// each shape's data is encoded in 8 rgba(or xyzw) texture slots
		id = 8.0 * currentBoxNodeData1.w;

		uv0 = ivec2( mod(id + 0.0, 2048.0), (id + 0.0) * INV_TEXTURE_WIDTH );
		uv1 = ivec2( mod(id + 1.0, 2048.0), (id + 1.0) * INV_TEXTURE_WIDTH );
		uv2 = ivec2( mod(id + 2.0, 2048.0), (id + 2.0) * INV_TEXTURE_WIDTH );
		uv3 = ivec2( mod(id + 3.0, 2048.0), (id + 3.0) * INV_TEXTURE_WIDTH );
		uv4 = ivec2( mod(id + 4.0, 2048.0), (id + 4.0) * INV_TEXTURE_WIDTH );
		uv7 = ivec2( mod(id + 7.0, 2048.0), (id + 7.0) * INV_TEXTURE_WIDTH );
		invTransformMatrix = mat4( texelFetch(tShape_DataTexture, uv0, 0),
		 			   texelFetch(tShape_DataTexture, uv1, 0), 
		 			   texelFetch(tShape_DataTexture, uv2, 0), 
		 			   texelFetch(tShape_DataTexture, uv3, 0) );

		sd4 = texelFetch(tShape_DataTexture, uv4, 0); // contains shape type and some material info
		sd7 = texelFetch(tShape_DataTexture, uv7, 0); // contains rotation Axis/Angle info
		
		if (uAnimationType == 1.0)
		{
			// animate Translation
			invTransformMatrix[3][1] = -1.0 + (sin(uTime + currentBoxNodeData1.w) * 1.5);
		}
		if (uAnimationType == 2.0)
		{
			// animate Rotation

			// first, create ortho basis vectors
			vec3 xAxis = vec3(1,0,0);
			vec3 yAxis = vec3(0,1,0);
			vec3 zAxis = vec3(0,0,1);
			// each object has a unique axis of rotation, which was stored on the tShape_DataTexture
			vec3 rotAxis = vec3(sd7.x, sd7.y, sd7.z);
			// rotation angle increases with time. Offset the phase with a stored offset angle from the tShape_DataTexture
			float cosAngle = cos(uTime + sd7.w);
			float sinAngle = sin(uTime + sd7.w);
			// perform axis-angle rotation on each axis of the original ortho basis (GLSL algo by Fabrice Neyret on ShaderToy)
			xAxis = mix(dot(xAxis, rotAxis) * rotAxis, xAxis, cosAngle) + sinAngle * cross(xAxis, rotAxis);
			yAxis = mix(dot(yAxis, rotAxis) * rotAxis, yAxis, cosAngle) + sinAngle * cross(yAxis, rotAxis);
			zAxis = mix(dot(zAxis, rotAxis) * rotAxis, zAxis, cosAngle) + sinAngle * cross(zAxis, rotAxis);
			// place the rotated basis vectors into the columns of a new 4x4 matrix - in this case, we have created a Rotation matrix
			mat4 R = mat4(
				xAxis.x, yAxis.x, zAxis.x, 0,
				xAxis.y, yAxis.y, zAxis.y, 0,
				xAxis.z, yAxis.z, zAxis.z, 0,
				0,       0,       0,       1 
			);
			// apply this Rotation matrix 'R' to this object's original inverse transform matrix (stored on the tShape_DataTexture)
			invTransformMatrix = R * invTransformMatrix;

			if (sd4.x == 1.0)
			{
				mat4 m;
				float mod3 = floor(mod(currentBoxNodeData1.w, 3.0));
				if (mod3 == 0.0)
				{
					m = makeScaleX(2.0);
				}
				else if (mod3 == 1.0)
				{
					m = makeScaleY(2.0);
				}
				else //mod3 == 2.0
				{
					m = makeScaleZ(2.0);
				}
				invTransformMatrix = m * invTransformMatrix;
			}
		}
		if (uAnimationType == 3.0)
		{
			// animate Scaling
			mat4 m;
			float mod3 = floor(mod(currentBoxNodeData1.w, 3.0));
			if (mod3 == 0.0)
			{
				m = makeScaleX(10.0 - abs(sin(uTime + currentBoxNodeData1.w) * 9.5));
			}
			else if (mod3 == 1.0)
			{
				m = makeScaleY(10.0 - abs(sin(uTime + currentBoxNodeData1.w) * 9.5));
			}
			else //mod3 == 2.0
			{
				m = makeScaleZ(10.0 - abs(sin(uTime + currentBoxNodeData1.w) * 9.5));
			}
			invTransformMatrix = m * invTransformMatrix;
		}
			

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
		
		if (d > 0.0 && d < t)
		{
			t = d;
			hitNormal = n;
			hitMatrix = invTransformMatrix; // save winning matrix for hitNormal code below
			shapeID = id;
			shapeLookupNeeded = TRUE;
			objectCount++;
		}
	      
        } // end while (TRUE)


	if (shapeLookupNeeded == TRUE)
	{
		//uv0 = ivec2( mod(shapeID + 0.0, 2048.0), (shapeID + 0.0) * INV_TEXTURE_WIDTH );
		//uv1 = ivec2( mod(shapeID + 1.0, 2048.0), (shapeID + 1.0) * INV_TEXTURE_WIDTH );
		//uv2 = ivec2( mod(shapeID + 2.0, 2048.0), (shapeID + 2.0) * INV_TEXTURE_WIDTH );
		//uv3 = ivec2( mod(shapeID + 3.0, 2048.0), (shapeID + 3.0) * INV_TEXTURE_WIDTH );
		uv4 = ivec2( mod(shapeID + 4.0, 2048.0), (shapeID + 4.0) * INV_TEXTURE_WIDTH );
		uv5 = ivec2( mod(shapeID + 5.0, 2048.0), (shapeID + 5.0) * INV_TEXTURE_WIDTH );
		//uv6 = ivec2( mod(shapeID + 6.0, 2048.0), (shapeID + 6.0) * INV_TEXTURE_WIDTH );
		//uv7 = ivec2( mod(shapeID + 7.0, 2048.0), (shapeID + 7.0) * INV_TEXTURE_WIDTH );
		
		//sd0 = texelFetch(tShape_DataTexture, uv0, 0);
		//sd1 = texelFetch(tShape_DataTexture, uv1, 0);
		//sd2 = texelFetch(tShape_DataTexture, uv2, 0);
		//sd3 = texelFetch(tShape_DataTexture, uv3, 0);
		sd4 = texelFetch(tShape_DataTexture, uv4, 0);
		sd5 = texelFetch(tShape_DataTexture, uv5, 0);
		//sd6 = texelFetch(tShape_DataTexture, uv6, 0);
		//sd7 = texelFetch(tShape_DataTexture, uv7, 0);

		hitNormal = transpose(mat3(hitMatrix)) * hitNormal;
		hitColor = sd5.rgb;
		//hitUV =
		hitType = int(sd4.y);
		hitRoughness = sd4.w;
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
		hitRoughness = 0.0;
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
		hitRoughness = 0.0;
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
		hitRoughness = 0.0;
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
		hitRoughness = 0.0;
		hitObjectID = float(objectCount);
	}
	

	return t;

} // end float SceneIntersect( )


//-----------------------------------------------------------------------------------------------------------------------------
vec3 CalculateRadiance( out vec3 objectNormal, out vec3 objectColor, out float objectID, out float pixelSharpness )
//-----------------------------------------------------------------------------------------------------------------------------
{

	vec3 accumCol = vec3(0);
	vec3 mask = vec3(1);
	vec3 reflectionMask = vec3(1);
	vec3 reflectionRayOrigin = vec3(0);
	vec3 reflectionRayDirection = vec3(0);
	vec3 x, n, nl;
	vec3 skyColor = vec3(0.5, 0.7, 1.0);
	vec3 skyGradient = vec3(0);
	
	float t;
	float nc, nt, ratioIoR, Re, Tr;
	
	float previousObjectID;

	int diffuseCount = 0;
	int previousIntersecType = -100;
	hitType = -100;

	int bounceIsSpecular = TRUE;
	int willNeedReflectionRay = FALSE;
	int isReflectionTime = FALSE;

	
	for (int bounces = 0; bounces < 8; bounces++)
	{
		previousIntersecType = hitType;
		previousObjectID = hitObjectID;

		t = SceneIntersect();
		

		if (t == INFINITY)
		{	
			// this makes the object edges sharp against the background
			if (bounceIsSpecular == TRUE)
				pixelSharpness = 1.0;

			skyGradient = mix(vec3(1.5), skyColor * 1.5, 0.5 * (rayDirection.y + 1.0));
			accumCol += mask * skyGradient;

			if (willNeedReflectionRay == TRUE)
			{
				mask = reflectionMask;
				rayOrigin = reflectionRayOrigin;
				rayDirection = reflectionRayDirection;

				willNeedReflectionRay = FALSE;
				bounceIsSpecular = TRUE;
				isReflectionTime = TRUE;
				continue;
			}

			// reached the background sky, so we can exit
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
		
		    
                if (hitType == DIFF) // Ideal DIFFUSE reflection
                {
			diffuseCount++;
			
			mask *= hitColor;

			bounceIsSpecular = FALSE;

			// choose random Diffuse sample vector
			rayDirection = randomCosWeightedDirectionInHemisphere(nl);
			rayOrigin = x + nl * uEPS_intersect;
			continue;

                }

		if (hitType == SPEC)  // Ideal SPECULAR reflection
		{
			mask *= hitColor;

			rayDirection = reflect(rayDirection, nl);
			rayDirection = randomDirectionInSpecularLobe(nl, rayDirection, hitRoughness);
			rayOrigin = x + nl * uEPS_intersect;

			continue;
		}
		
		if (hitType == REFR)  // Ideal dielectric REFRACTION
		{
			nc = 1.0; // IOR of Air
			nt = hitColor == vec3(1,1,0) ? 1.1 : 1.5; // IOR of common Glass
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
			mask *= Tr;
			mask *= hitColor;

			rayDirection = refract(rayDirection, nl, ratioIoR);
			rayOrigin = x - nl * uEPS_intersect;

			if (diffuseCount == 1)
				bounceIsSpecular = TRUE; // turn on refracting caustics

			continue;
			
		} // end if (hitType == REFR)
		
		
	} // end for (int bounces = 0; bounces < 8; bounces++)
	
	
	return max(vec3(0), accumCol); // prevents black spot artifacts appearing in the water


} // end vec3 CalculateRadiance( out vec3 objectNormal, out vec3 objectColor, out float objectID, out float pixelSharpness )



//-----------------------------------------------------------------------
void SetupScene(void)
//-----------------------------------------------------------------------
{
	vec3 z  = vec3(0);// No color value, Black
	spheres[0] = Sphere( 1000.0, vec3(0, -1000, 0), z, vec3(0.5), DIFF);
	spheres[1] = Sphere( 1.0, vec3(0, 1, 0), z, vec3(1.0, 1.0, 1.0), REFR);
	spheres[2] = Sphere( 1.0, vec3(-4, 1, 0), z, vec3(0.4, 0.2, 0.1), DIFF);
	spheres[3] = Sphere( 1.0, vec3(4, 1, 0), z, vec3(0.7, 0.6, 0.5), SPEC);
}


//#include <pathtracing_main>

// tentFilter from Peter Shirley's 'Realistic Ray Tracing (2nd Edition)' book, pg. 60
float tentFilter(float x) // input: x: a random float(0.0 to 1.0), output: a filtered float (-1.0 to +1.0)
{
	return (x < 0.5) ? sqrt(2.0 * x) - 1.0 : 1.0 - sqrt(2.0 - (2.0 * x));
}

void main( void )
{
	vec3 camRight   = vec3( uCameraMatrix[0][0],  uCameraMatrix[0][1],  uCameraMatrix[0][2]);
	vec3 camUp      = vec3( uCameraMatrix[1][0],  uCameraMatrix[1][1],  uCameraMatrix[1][2]);
	vec3 camForward = vec3(-uCameraMatrix[2][0], -uCameraMatrix[2][1], -uCameraMatrix[2][2]);
	// the following is not needed - three.js has a built-in uniform named cameraPosition
	//vec3 camPos   = vec3( uCameraMatrix[3][0],  uCameraMatrix[3][1],  uCameraMatrix[3][2]);

	// calculate unique seed for rng() function
	seed = uvec2(uFrameCounter, uFrameCounter + 1.0) * uvec2(gl_FragCoord);
	// initialize rand() variables
	randNumber = 0.0; // the final randomly-generated number (range: 0.0 to 1.0)
	blueNoise = texelFetch(tBlueNoiseTexture, ivec2(mod(floor(gl_FragCoord.xy), 128.0)), 0).r;

	vec2 pixelOffset;
	
	if (uSampleCounter < 50.0)
	{
		pixelOffset = vec2( tentFilter(rand()), tentFilter(rand()) );
		pixelOffset *= uCameraIsMoving ? 0.5 : 1.0;
	}	
	else pixelOffset = vec2( tentFilter(uRandomVec2.x), tentFilter(uRandomVec2.y) );
	
	// we must map pixelPos into the range -1.0 to +1.0: (-1.0,-1.0) is bottom-left screen corner, (1.0,1.0) is top-right
	vec2 pixelPos = ((gl_FragCoord.xy + vec2(0.5) + pixelOffset) / uResolution) * 2.0 - 1.0;

	vec3 rayDir = uUseOrthographicCamera ? camForward :
		      normalize( (camRight * pixelPos.x * uULen) + (camUp * pixelPos.y * uVLen) + camForward );
					       
	// depth of field
	vec3 focalPoint = uFocusDistance * rayDir;
	float randomAngle = rng() * TWO_PI; // pick random point on aperture
	float randomRadius = rng() * uApertureSize;
	vec3  randomAperturePos = ((camRight * cos(randomAngle)) + (camUp * sin(randomAngle))) * sqrt(randomRadius);
	// point on aperture to focal point
	vec3 finalRayDir = normalize(focalPoint - randomAperturePos);

	rayOrigin = cameraPosition + randomAperturePos;
	rayOrigin += !uUseOrthographicCamera ? vec3(0) : 
		     (camRight * pixelPos.x * uULen * 100.0) + (camUp * pixelPos.y * uVLen * 100.0);
					     
	rayDirection = finalRayDir;
	

	SetupScene();

	// Edge Detection - don't want to blur edges where either surface normals change abruptly (i.e. room wall corners), objects overlap each other (i.e. edge of a foreground sphere in front of another sphere right behind it),
	// or an abrupt color variation on the same smooth surface, even if it has similar surface normals (i.e. checkerboard pattern). Want to keep all of these cases as sharp as possible - no blur filter will be applied.
	vec3 objectNormal = vec3(0);
	vec3 objectColor = vec3(0);
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

	
	if (uFrameCounter == 1.0) // camera just moved after being still
	{
		previousPixel.rgb *= (1.0 / uPreviousSampleCount) * 0.5; // essentially previousPixel *= 0.5, like below
		previousPixel.a = 0.0;
		currentPixel.rgb *= 0.5;
	}
	else if (uCameraIsMoving) // camera is currently moving
	{
		previousPixel.rgb *= 0.5; // motion-blur trail amount (old image)
		previousPixel.a = 0.0;
		currentPixel.rgb *= 0.5; // brightness of new image (noisy)
	}
	else if (uSceneIsDynamic)
	{
		previousPixel.rgb *= 0.9; // motion-blur trail amount (old image)
		currentPixel.rgb *= 0.1; // brightness of new image (noisy)
	}

	if (colorDifference > 0.0 || normalDifference >= 0.9 || objectDifference >= 1.0)
		pixelSharpness = 1.0; // 1.0 means an edge pixel

	currentPixel.a = pixelSharpness;

	// Eventually, all edge-containing pixels' .a (alpha channel) values will converge to 1.0, 
	//   which keeps them from getting blurred by the box-blur filter, thus retaining sharpness over time.
	if (previousPixel.a == 1.0) // an edge or a light source
		currentPixel.a = 1.0;

	if (uSceneIsDynamic)
	{ // for dynamic scenes (to clear out old, dark, sharp pixel trails left behind from moving objects)	
		if (previousPixel.a == 1.0 && rng() < 0.05)
			currentPixel.a = 0.0;
	}
	

	pc_fragColor = vec4(previousPixel.rgb + currentPixel.rgb, currentPixel.a);
}
