precision highp float;
precision highp int;
precision highp sampler2D;

uniform mat4 uGLTF_Model_InvMatrix;
uniform mat3 uGLTF_Model_NormalMatrix;
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

#define N_DISKS 1
#define N_SPHERES 3
#define N_BOXES 2
#define N_OPENCYLINDERS 1

//-----------------------------------------------------------------------

struct Ray { vec3 origin; vec3 direction; };
struct Disk { float radius; vec3 pos; vec3 normal; vec3 emission; vec3 color; int type; bool isDynamic; };
struct Sphere { float radius; vec3 position; vec3 emission; vec3 color; int type; bool isDynamic; };
struct OpenCylinder { vec3 pos0; vec3 pos1; float radius; vec3 emission; vec3 color; int type; bool isDynamic; };
struct Box { vec3 minCorner; vec3 maxCorner; vec3 emission; vec3 color; int type; bool isDynamic; };
struct Intersection { vec3 normal; vec3 emission; vec3 color; vec2 uv; int type; int textureID; bool isDynamic; };

Disk disks[N_DISKS];
Sphere spheres[N_SPHERES];
OpenCylinder openCylinders[N_OPENCYLINDERS];
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
	
        vec3 S = normalize( cross( abs(nl.y) < 0.9 ? vec3(0, 1, 0) : vec3(0, 0, 1), nl ) );
        vec3 T = cross(nl, S);
        vec3 N = normalize( nl );
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
	mapN = normalize(mapN);
        mapN.xy *= normalScale;
        
        return normalize( tsn * mapN );
}


vec2 stackLevels[28];

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


//-------------------------------------------------------------------------------
float SceneIntersect( Ray r, inout Intersection intersec, out bool isRayExiting )
//-------------------------------------------------------------------------------
{
	BoxNode currentBoxNode, nodeA, nodeB, tmpNode;
	
	vec4 aabbNodeData;
	vec4 vd0, vd1, vd2, vd3, vd4, vd5, vd6, vd7;

	vec3 aabbMin, aabbMax;
	vec3 inverseDir = 1.0 / r.direction;
	vec3 normal;
	vec3 hitPos, toLightBulb;

	vec2 currentStackData, stackDataA, stackDataB, tmpStackData;
	ivec2 uv0, uv1, uv2, uv3, uv4, uv5, uv6, uv7;

	float d;
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
			intersec.textureID = -1;
			intersec.isDynamic = false;
		}
	}

        for (int i = 0; i < N_BOXES; i++)
        {
		d = BoxIntersect( boxes[i].minCorner, boxes[i].maxCorner, r, normal, isRayExiting );
		if (d < t)
		{
			t = d;
			intersec.normal = normalize(normal);
			intersec.emission = boxes[i].emission;
			intersec.color = boxes[i].color;
			intersec.type = boxes[i].type;
			intersec.textureID = -1;
			intersec.isDynamic = false;
		}
        }

        d = DiskIntersect( disks[0].radius, disks[0].pos, disks[0].normal, r );
	if (d < t)
	{
		t = d;
		intersec.normal = dot(disks[0].normal,r.direction) <= 0.0 ? normalize(disks[0].normal) : normalize(disks[0].normal * -1.0);
		intersec.emission = disks[0].emission;
		hitPos = r.origin + r.direction * t;
		toLightBulb = normalize(spheres[1].position - hitPos);
		
		if (dot(intersec.normal, toLightBulb) > 0.0)
		{
			intersec.color = disks[0].color;
			intersec.type = disks[0].type;
		}
		else
		{
			intersec.color = vec3(0);
			intersec.type = DIFF;
		}
		intersec.textureID = -1;
		intersec.isDynamic = false;
	}

	d = OpenCylinderIntersect( openCylinders[0].pos0, openCylinders[0].pos1, openCylinders[0].radius, r, normal );
	if (d < t)
	{
		t = d;
		intersec.normal = normalize(normal);
		intersec.emission = openCylinders[0].emission;
		hitPos = r.origin + r.direction * t;
		toLightBulb = normalize(spheres[1].position - hitPos);
		
		if (dot(intersec.normal, toLightBulb) > 0.0)
		{
			intersec.color = openCylinders[0].color;
			intersec.type = openCylinders[0].type;
		}
		else 
		{
			intersec.color = vec3(0);
			intersec.type = DIFF;
		}
		intersec.textureID = -1;
		intersec.isDynamic = false;
        }
        

	// transform ray into GLTF_Model's object space
	r.origin = vec3( uGLTF_Model_InvMatrix * vec4(r.origin, 1.0) );
	r.direction = vec3( uGLTF_Model_InvMatrix * vec4(r.direction, 0.0) );
	inverseDir = 1.0 / r.direction;


	currentBoxNode = GetBoxNode(stackptr);
	currentStackData = vec2(stackptr, BoundingBoxIntersect(currentBoxNode.data0.yzw, currentBoxNode.data1.yzw, r.origin, inverseDir));
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
			
			if (currentStackData.y >= t)
				continue;
			
			currentBoxNode = GetBoxNode(currentStackData.x);
                }
		skip = false; // reset skip
		

		if (currentBoxNode.data0.x < 0.0) // < 0.0 signifies an inner node
		{
			nodeA = GetBoxNode(currentStackData.x + 1.0);
			nodeB = GetBoxNode(currentBoxNode.data1.x);
			stackDataA = vec2(currentStackData.x + 1.0, BoundingBoxIntersect(nodeA.data0.yzw, nodeA.data1.yzw, r.origin, inverseDir));
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

			continue;
		} // end if (currentBoxNode.data0.x < 0.0) // inner node


		// else this is a leaf

		// each triangle's data is encoded in 8 rgba(or xyzw) texture slots
		id = 8.0 * currentBoxNode.data0.x;

		uv0 = ivec2( mod(id + 0.0, 2048.0), (id + 0.0) * INV_TEXTURE_WIDTH );
		uv1 = ivec2( mod(id + 1.0, 2048.0), (id + 1.0) * INV_TEXTURE_WIDTH );
		uv2 = ivec2( mod(id + 2.0, 2048.0), (id + 2.0) * INV_TEXTURE_WIDTH );
		
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
	      
        } // end while (true)


	if (triangleLookupNeeded)
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
		//intersec.normal = normalize( cross(vec3(vd0.w, vd1.xy) - vec3(vd0.xyz), vec3(vd1.zw, vd2.x) - vec3(vd0.xyz)) );
		
		// interpolated normal using triangle intersection's uv's
		triangleW = 1.0 - triangleU - triangleV;
		intersec.uv = triangleW * vec2(vd4.zw) + triangleU * vec2(vd5.xy) + triangleV * vec2(vd5.zw);
		intersec.normal = normalize(triangleW * vec3(vd2.yzw) + triangleU * vec3(vd3.xyz) + triangleV * vec3(vd3.w, vd4.xy));
		
		intersec.normal = perturbNormal(intersec.normal, vec2(1.0, 1.0), intersec.uv);

		// transform normal back into world space
		intersec.normal = normalize((uGLTF_Model_NormalMatrix * intersec.normal));
		intersec.emission = vec3(1, 0, 1); // use this if intersec.type will be LIGHT
		intersec.color = vd6.yzw;
		
		//intersec.type = int(vd6.x);
		intersec.type = PBR_MATERIAL;
                intersec.textureID = int(vd7.x);
                intersec.isDynamic = true;
	}

	return t;

} // end float SceneIntersect( Ray r, inout Intersection intersec )



//--------------------------------------------------------------------------------------------------------
vec3 CalculateRadiance(Ray r)
//--------------------------------------------------------------------------------------------------------
{
        Intersection intersec;
        Sphere light = spheres[1];

	vec3 accumCol = vec3(0);
        vec3 mask = vec3(1);
	vec3 checkCol0 = vec3(1);
	vec3 checkCol1 = vec3(0.5);
        vec3 dirToLight;
        vec3 tdir;
	vec3 metallicRoughness = vec3(0);
	vec3 x, n, nl;
        
	float t;
        float nc, nt, ratioIoR, Re, Tr;
	float P, RP, TP;
        float weight;
        float thickness = 0.1;

	int diffuseCount = 0;

	bool bounceIsSpecular = true;
	bool sampleLight = false;
	bool isRayExiting = false;

	
        for (int bounces = 0; bounces < 4; bounces++)
	{

		t = SceneIntersect(r, intersec, isRayExiting);
		
		/*
		if (t == INFINITY)
		{
                        break;
		}
		*/
		

		if (intersec.type == LIGHT)
		{	
			accumCol = mask * intersec.emission;
			// reached a light, so we can exit
			break;
		}


		if (intersec.type == SPOT_LIGHT)
		{	
			if (bounceIsSpecular)
			{
				if (bounces == 0) // looking directly at light
					accumCol = mask * clamp(intersec.emission, 0.0, 10.0);
				else if (bounces == 1) // single bounce reflection or refraction
					accumCol = mask * clamp(intersec.emission, 0.0, 10.0);
				else // caustic
					accumCol = mask * clamp(intersec.emission, 0.0, 1.0);
			}
				
			if (sampleLight)
				accumCol = mask * intersec.emission;
			
			// reached a light, so we can exit
			break;
		}

		
		// if we get here and sampleLight is still true, shadow ray failed to find a light source
		if (sampleLight) 
			break;
		
		
		// useful data 
		n = normalize(intersec.normal);
                nl = dot(n, r.direction) < 0.0 ? normalize(n) : normalize(-n);
		x = r.origin + r.direction * t;

		if (intersec.type == PBR_MATERIAL)
		{
			intersec.color = texture(tAlbedoMap, intersec.uv).rgb;
			intersec.color = pow(intersec.color,vec3(2.2));
			
			intersec.emission = texture(tEmissiveMap, intersec.uv).rgb;
			intersec.emission = pow(intersec.emission,vec3(2.2));
			
			float maxEmission = max(intersec.emission.r, max(intersec.emission.g, intersec.emission.b));
			if (bounceIsSpecular && maxEmission > 0.01) //if (rand() < maxEmission)
			{
				accumCol = mask * intersec.emission;
				break;
			}

			intersec.type = DIFF;

			metallicRoughness = pow(texture(tMetallicRoughnessMap, intersec.uv).rgb, vec3(2.2));
			
			if (metallicRoughness.g > 0.01) // roughness
				intersec.type = COAT;
			if (metallicRoughness.b > 0.01) // metalness
				intersec.type = SPEC;
			
		}
		
		    
                if (intersec.type == DIFF || intersec.type == CHECK) // Ideal DIFFUSE reflection
                {
			diffuseCount++;

			if ( intersec.type == CHECK )
			{
				float q = clamp( mod( dot( floor(x.xz * 0.04), vec2(1.0) ), 2.0 ) , 0.0, 1.0 );
				intersec.color = checkCol0 * q + checkCol1 * (1.0 - q);	
			}
			
			mask *= intersec.color;

                        bounceIsSpecular = false;

			if (diffuseCount == 1 && rand() < 0.5)
			{
				// choose random Diffuse sample vector
				r = Ray( x, randomCosWeightedDirectionInHemisphere(nl) );
				r.origin += nl * uEPS_intersect;
				continue;
			}
                        
			dirToLight = sampleSphereLight(x, nl, light, dirToLight, weight);
			mask *= weight;

			r = Ray( x, dirToLight );
			r.origin += nl * uEPS_intersect;
			sampleLight = true;
			continue;
                        
		} // end if (intersec.type == DIFF)
		
                if (intersec.type == SPEC)  // Ideal SPECULAR reflection
                {
			mask *= intersec.color;
			r = Ray( x, randomDirectionInSpecularLobe(reflect(r.direction, nl), metallicRoughness.g) );
			r.origin += nl * uEPS_intersect;
			
			//bounceIsSpecular = true;
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
			
			
			if (rand() < P)
			{
				mask *= RP;
				r = Ray( x, reflect(r.direction, nl) ); // reflect ray from surface
				r.origin += nl * uEPS_intersect;
				continue;
			}

			// transmit ray through surface

			// is ray leaving a solid object from the inside? 
			// If so, attenuate ray color with object color by how far ray has travelled through the medium
			if (isRayExiting)
			{
				mask *= exp(log(intersec.color) * thickness * t);
			}

			mask *= TP;
			
			tdir = refract(r.direction, nl, ratioIoR);
			r = Ray(x, tdir);
			r.origin -= nl * uEPS_intersect;
			
			if (bounces == 1)
				bounceIsSpecular = true; // turn on refracting caustics

			continue;
			
		} // end if (intersec.type == REFR)
		
		if (intersec.type == COAT)  // Diffuse object underneath with ClearCoat on top
		{
			nc = 1.0; // IOR of Air
			nt = 1.5; // IOR of Clear Coat
			Re = calcFresnelReflectance(r.direction, n, nc, nt, ratioIoR);
			Tr = 1.0 - Re;
			P  = 0.25 + (0.5 * Re);
                	RP = Re / P;
                	TP = Tr / (1.0 - P);

			
			if (bounceIsSpecular && rand() < P)
			{
				mask *= RP;
				r = Ray( x, reflect(r.direction, nl) ); // reflect ray from surface
				r.origin += nl * uEPS_intersect;
				continue;
			}

			diffuseCount++;

			mask *= TP;
			mask *= intersec.color;
			
			bounceIsSpecular = false;
			
			if (diffuseCount == 1 && rand() < 0.5)
			{
				// choose random Diffuse sample vector
				r = Ray( x, randomCosWeightedDirectionInHemisphere(nl) );
				r.origin += nl * uEPS_intersect;
				continue;
			}
                        
			dirToLight = sampleSphereLight(x, nl, light, dirToLight, weight);
			mask *= weight;
			
			r = Ray( x, dirToLight );
			r.origin += nl * uEPS_intersect;

			sampleLight = true;
			continue;
                        
		} //end if (intersec.type == COAT)
		
	} // end for (int bounces = 0; bounces < 4; bounces++)
	

	return max(vec3(0), accumCol);
	    
} // end vec3 CalculateRadiance(Ray r)


//-----------------------------------------------------------------------
void SetupScene(void)
//-----------------------------------------------------------------------
{
	vec3 z  = vec3(0);          
	vec3 L1 = vec3(0.5, 0.7, 1.0) * 0.01;// Blueish sky light
	vec3 L2 = vec3(1.0, 1.0, 1.0) * 300.0;// Bright white light bulb
	
	spheres[0] = Sphere( 10000.0,     vec3(0, 0, 0), L1, z, LIGHT, false);//spherical white Light1
	spheres[1] = Sphere( 3.0, vec3(-10, 100, -50), L2, z, SPOT_LIGHT, false);//spotlight
	spheres[2] = Sphere( 4000.0, vec3(0, -4000, 0), z, vec3(0.4, 0.4, 0.4), CHECK, false);//Checkered Floor
        
        vec3 spotLightTarget = uGLTF_Model_Position;
        vec3 spotLightPos = spheres[1].position;
	vec3 spotLightDir = normalize(spotLightTarget - spotLightPos);
	openCylinders[0] = OpenCylinder( spotLightPos - (spotLightDir * spheres[1].radius) * 2.0, spotLightPos + (spotLightDir * spheres[1].radius) * 5.0, 
					   spheres[1].radius * 1.5, z, vec3(1), SPEC, true);//metal open Cylinder
        disks[0] = Disk( spheres[1].radius * 1.5, spotLightPos - (spotLightDir * spheres[1].radius * 2.0), spotLightDir, z, vec3(0.9, 0.9, 0.9), SPEC, true);//metal disk
        	
	boxes[0] = Box( vec3(-20.0,11.0,-110.0), vec3(70.0,18.0,-20.0), z, vec3(0.2,0.9,0.7), REFR, false);//Glass Box
	boxes[1] = Box( vec3(-14.0,13.0,-104.0), vec3(64.0,16.0,-26.0), z, vec3(0),           DIFF, false);//Inner Box
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
	//seed = uvec2(uFrameCounter, uFrameCounter + 1.0) * uvec2(gl_FragCoord); // old way of generating random numbers

	randVec4 = texture(tBlueNoiseTexture, (gl_FragCoord.xy + (uRandomVec2 * 256.0)) / 256.0 ); // new way of rand()

	vec2 pixelPos = vec2(0);
	vec2 pixelOffset = vec2(0);
	
	float x = rand();
	float y = rand();

	pixelOffset = vec2(tentFilter(x), tentFilter(y)) * 0.5;

	// we must map pixelPos into the range -1.0 to +1.0
	pixelPos = ((gl_FragCoord.xy + pixelOffset) / uResolution) * 2.0 - 1.0;

        vec3 rayDir = normalize( pixelPos.x * camRight * uULen + pixelPos.y * camUp * uVLen + camForward );
        
        // depth of field
        vec3 focalPoint = uFocusDistance * rayDir;
        float randomAngle = rand() * TWO_PI; // pick random point on aperture
        float randomRadius = rand() * uApertureSize;
        vec3  randomAperturePos = ( cos(randomAngle) * camRight + sin(randomAngle) * camUp ) * sqrt(randomRadius);
        // point on aperture to focal point
        vec3 finalRayDir = normalize(focalPoint - randomAperturePos);
        
        Ray ray = Ray( cameraPosition + randomAperturePos, finalRayDir );

        SetupScene(); 

        // perform path tracing and get resulting pixel color
        vec3 pixelColor = CalculateRadiance(ray);
        
	vec4 previousImage = texelFetch(tPreviousTexture, ivec2(gl_FragCoord.xy), 0);
	vec3 previousColor = previousImage.rgb;

	if (uCameraIsMoving)
	{
                previousColor *= 0.5; // motion-blur trail amount (old image)
                pixelColor *= 0.5; // brightness of new image (noisy)
        }
	else
	{
                previousColor *= 0.9; // motion-blur trail amount (old image)
                pixelColor *= 0.1; // brightness of new image (noisy)
        }
	
        pc_fragColor = vec4( pixelColor + previousColor, 1.0 );	
}
