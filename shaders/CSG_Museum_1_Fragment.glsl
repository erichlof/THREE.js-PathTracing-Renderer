precision highp float;
precision highp int;
precision highp sampler2D;

#include <pathtracing_uniforms_and_defines>

#define N_LIGHTS 2.0
#define N_QUADS 2
#define N_BOXES 1


//-----------------------------------------------------------------------

vec3 rayOrigin, rayDirection;
// recorded intersection data:
vec3 hitNormal, hitEmission, hitColor;
vec2 hitUV;
float hitObjectID = -INFINITY;
int hitType = -100;


struct Plane { vec4 pla; vec3 emission; vec3 color; int type; };
struct Quad { vec3 normal; vec3 v0; vec3 v1; vec3 v2; vec3 v3; vec3 emission; vec3 color; int type; };
struct Box { vec3 minCorner; vec3 maxCorner; vec3 emission; vec3 color; int type; };

Quad quads[N_QUADS];
Box boxes[N_BOXES];

#include <pathtracing_random_functions>

#include <pathtracing_calc_fresnel_reflectance>

#include <pathtracing_sphere_intersect>

#include <pathtracing_box_intersect>

#include <pathtracing_box_interior_intersect>

#include <pathtracing_quad_intersect>

#include <pathtracing_sample_quad_light>


//--------------------------------------------------------------------------------------------------------------------------
float CSG_SphereIntersect( float rad, vec3 pos, vec3 rayOrigin, vec3 rayDirection, out vec3 n1, out vec3 n2, out float far )
//--------------------------------------------------------------------------------------------------------------------------
{
	vec3 L = rayOrigin - pos;
	float t0, t1; 
	float result = INFINITY;
	far = INFINITY;
	// quadratic equation coefficients
	float a = dot( rayDirection, rayDirection );
	float b = 2.0 * dot( rayDirection, L );
	float c = dot( L, L ) - (rad * rad);

	solveQuadratic(a, b, c, t0, t1);
	
	if( t1 > 0.0 )
	{
		result = t1;
		far = INFINITY;
		n2 = (rayOrigin + rayDirection * result) - pos;   
	}
	
	if( t0 > 0.0 )
	{
		result = t0;
		far = t1;
		n1 = (rayOrigin + rayDirection * result) - pos;
	}
		
	return result;	
}

//------------------------------------------------------------------------------------------------------------------------------
float CSG_EllipsoidIntersect( vec3 radii, vec3 pos, vec3 rayOrigin, vec3 rayDirection, out vec3 n1, out vec3 n2, out float far )
//------------------------------------------------------------------------------------------------------------------------------
{
	vec3 oc = rayOrigin - pos;
	vec3 oc2 = oc*oc;
	vec3 ocrd = oc*rayDirection;
	vec3 rd2 = rayDirection*rayDirection;
	vec3 invRad = 1.0/radii;
	vec3 invRad2 = invRad*invRad;
	float t0, t1;
	float result = INFINITY;
	far = INFINITY;
	// quadratic equation coefficients
	float a = dot(rd2, invRad2);
	float b = 2.0*dot(ocrd, invRad2);
	float c = dot(oc2, invRad2) - 1.0;

	solveQuadratic(a, b, c, t0, t1);
	
	if( t1 > 0.0 )
	{
		result = t1;
		far = INFINITY;
		n2 = ((rayOrigin + rayDirection * result) - pos) * invRad2;
	}
	
	if( t0 > 0.0 )
	{
		result = t0;
		far = t1;
		n1 = ((rayOrigin + rayDirection * result) - pos) * invRad2;
	}
	
	return result;	
}


//----------------------------------------------------------------------------------------------------------------------------------
float CSG_BoxIntersect( vec3 minCorner, vec3 maxCorner, vec3 rayOrigin, vec3 rayDirection, out vec3 n1, out vec3 n2, out float far )
//----------------------------------------------------------------------------------------------------------------------------------
{
	vec3 invDir = 1.0 / rayDirection;
	vec3 near = (minCorner - rayOrigin) * invDir;
	vec3 further = (maxCorner - rayOrigin) * invDir;
	
	vec3 tmin = min(near, further);
	vec3 tmax = max(near, further);
	
	float t0 = max( max(tmin.x, tmin.y), tmin.z);
	float t1 = min( min(tmax.x, tmax.y), tmax.z);
	float result = INFINITY;
	far = INFINITY;
	
	if (t0 > t1) return INFINITY;
	
	if (t1 > 0.0) // if we are inside the box
	{
		n2 = -sign(rayDirection) * step(tmax, tmax.yzx) * step(tmax, tmax.zxy);
		far = INFINITY;
		result = t1;
	}

	if (t0 > 0.0) // if we are outside the box
	{
		n1 = -sign(rayDirection) * step(tmin.yzx, tmin) * step(tmin.zxy, tmin);
		n2 = -sign(rayDirection) * step(tmax, tmax.yzx) * step(tmax, tmax.zxy);
		far = t1;
		result = t0;	
	}
	
	return result;
}

//--------------------------------------------------------------------------------------------------------------
float CSG_PlaneIntersect( vec4 pla, vec3 rayOrigin, vec3 rayDirection, out vec3 n1, out vec3 n2, out float far )
//--------------------------------------------------------------------------------------------------------------
{
	vec3 n = pla.xyz;
	float denom = dot(n, rayDirection);
	
	// uncomment if single-sided plane is desired
	//if (denom >= 0.0)
	//	return INFINITY;
	
        vec3 pOrO = (pla.w * n) - rayOrigin; 
        float result = dot(pOrO, n) / denom;
	far = INFINITY;
	if (result < 0.0) return INFINITY;
	n1 = n2 = pla.xyz;
	far = result;
	return result;
}




// CSG (Constructive Solid Geometry) functions ////////////////////////////////////////////////////////////////////////////////////////////////////

// solid object A and solid object B are fused together (A + B)
float operation_SolidA_Plus_SolidB( float A_near, float A_far, float B_near, float B_far, vec3 A_n1, vec3 A_n2, vec3 B_n1, vec3 B_n2, out vec3 n )
{
	float result = INFINITY;
	
	// Missed object A
	if (A_near == INFINITY)
	{
		// Missed object B also, early out
		if (B_near == INFINITY) 
			return INFINITY;
		// Outside object B
		if (B_far < INFINITY)
		{
			n = B_n1;
			result = B_near;
		}
		// Inside object B
		if (B_far == INFINITY)
		{
			n = B_n2;
			result = 0.1;
		}	
	}
	
	// Outside object A
	if (A_near < INFINITY && A_far < INFINITY)
	{
		// Missed object B
		if (B_near == INFINITY) 
		{
			n = A_n1;
			result = A_near;
		}
		// Outside object B
		if (B_far < INFINITY)
		{
			if (A_near < B_near)
			{
				n = A_n1;
				result = A_near;
			}
			else
			{
				n = B_n1;
				result = B_near;
			}
		}
		// Inside object B
		if (B_near < INFINITY && B_far == INFINITY)
		{
			n = B_n2;
			result = 0.1;
		}
		
	}
	
	// Inside object A
	if (A_near < INFINITY && A_far == INFINITY)
	{
		// inside solid is black
		n = A_n2;
		result = 0.1;
	}
	
	return result;
}


// hollow object A and hollow object B are fused together (A + B)
float operation_HollowA_Plus_HollowB( float A_near, float A_far, float B_near, float B_far, vec3 A_n1, vec3 A_n2, vec3 B_n1, vec3 B_n2, out vec3 n )
{
	float result = INFINITY;
	
	// Missed object A
	if (A_near == INFINITY)
	{
		// Missed object B also, early out
		if (B_near == INFINITY) 
			return INFINITY;
		// Outside object B
		if (B_far < INFINITY)
		{
			n = B_n1;
			result = B_near;
		}
		// Inside object B
		if (B_far == INFINITY)
		{
			n = B_n2;
			result = B_near;
		}	
	}
	
	// Outside object A
	if (A_near < INFINITY && A_far < INFINITY)
	{
		// Missed object B
		if (B_near == INFINITY) 
		{
			n = A_n1;
			result = A_near;
		}
		// Outside object B
		if (B_far < INFINITY)
		{
			if (A_near < B_near)
			{
				n = A_n1;
				result = A_near;
			}
			else
			{
				n = B_n1;
				result = B_near;
			}
		}
		// Inside object B
		if (B_near < INFINITY && B_far == INFINITY)
		{
			if (A_far > B_near)
			{
				n = A_n2;
				result = A_far;
			}
			else
			{
				n = B_n2;
				result = B_near;
			}
		}
		
	}
	
	// Inside object A
	if (A_near < INFINITY && A_far == INFINITY)
	{
		// Missed object B
		if (B_near == INFINITY) 
		{
			n = A_n2;
			result = A_near;
		}
		// Outside solid object B
		if (B_far < INFINITY)
		{
			if (B_far > A_near)
			{
				n = B_n2;
				result = B_far;
			}
			else
			{
				n = A_n2;
				result = A_near;
			}
		}
		// Inside solid object B
		if (B_near < INFINITY && B_far == INFINITY)
		{
			if (B_near > A_near)
			{
				n = B_n2;
				result = B_near;
			}
			else
			{
				n = A_n2;
				result = A_near;
			}
		}
	}
	
	return result;
}

// solid object A has solid shape B subtracted from it (A - B)
float operation_SolidA_Minus_SolidB( float A_near, float A_far, float B_near, float B_far, vec3 A_n1, vec3 A_n2, vec3 B_n1, vec3 B_n2, out vec3 n )
{
	float result = INFINITY;
	
	// Missed solid object A
	if (A_near == INFINITY)
	{
		// early out
		return INFINITY;
	}
	
	// Outside solid object A
	if (A_near < INFINITY && A_far < INFINITY)
	{
		// Missed sub-space object B
		if (B_near == INFINITY) 
		{
			n = A_n1;
			result = A_near;
		}
		// Outside sub-space object B
		if (B_far < INFINITY)
		{
			if (B_far > A_near && B_far < A_far)
			{
				n = B_n2;
				result = B_far;
			}
			if (B_near < A_near && B_far > A_far)
			{
				result = INFINITY;
			}
			if (B_near > A_near || B_far < A_near)
			{
				n = A_n1;
				result = A_near;
			}
		}
		// Inside sub-space object B
		if (B_near < INFINITY && B_far == INFINITY)
		{
			if (B_near < A_far && B_near > A_near)
			{
				n = B_n2;
				result = B_near;
			}
			
			if (B_near > A_far)
			{
				result = INFINITY;
			}
			
			if (B_near < A_near)
			{
				n = A_n1;
				result = A_near;
			}
		}	
	}
	
	// Inside solid object A
	if (A_near < INFINITY && A_far == INFINITY)
	{
		// Missed sub-space object B
		if (B_near == INFINITY) 
		{
			n = A_n2;
			result = 0.1;
		}
		// Outside sub-space object B
		if (B_far < INFINITY)
		{
			n = A_n2;
			result = 0.1;
		}
		// Inside sub-space object B
		if (B_near < INFINITY && B_far == INFINITY)
		{
			if (B_near < A_near)
			{
				n = B_n2;
				result = B_near;
			}
			if (B_near > A_near)
			{
				result = INFINITY;
			}
			
		}
	}
	
	return result;
}

// hollow object A has solid shape B subtracted from it (A - B)
float operation_HollowA_Minus_SolidB( float A_near, float A_far, float B_near, float B_far, vec3 A_n1, vec3 A_n2, vec3 B_n1, vec3 B_n2, out vec3 n )
{
	float result = INFINITY;
	
	// Missed solid object A
	if (A_near == INFINITY)
	{
		// early out
		return INFINITY;
	}
	
	// Outside hollow object A
	if (A_near < INFINITY && A_far < INFINITY)
	{
		// Missed sub-space object B
		if (B_near == INFINITY) 
		{
			n = A_n1;
			result = A_near;
		}
		// Outside sub-space object B
		if (B_far < INFINITY)
		{
			if (B_far > A_near && B_far < A_far)
			{
				n = A_n2;
				result = A_far;
			}
			if (B_near < A_near && B_far > A_far)
			{
				result = INFINITY;
			}
			if (B_near > A_near || B_far < A_near)
			{
				n = A_n1;
				result = A_near;
			}
		}
		// Inside sub-space object B
		if (B_near < INFINITY && B_far == INFINITY)
		{
			if (B_near < A_far && B_near > A_near)
			{
				n = A_n2;
				result = A_far;
			}
			
			if (B_near > A_far)
			{
				result = INFINITY;
			}
			
			if (B_near < A_near)
			{
				n = A_n1;
				result = A_near;
			}
		}	
	}
	
	// Inside hollow object A
	if (A_near < INFINITY && A_far == INFINITY)
	{
		// Missed sub-space object B
		if (B_near == INFINITY) 
		{
			n = A_n2;
			result = A_near;
		}
		// Outside sub-space object B
		if (B_far < INFINITY)
		{
			if (B_far < A_near)
			{
				n = B_n2;
				result = B_far;
			}
			if (B_near < A_near)
			{
				result = INFINITY;
			}	
			if (A_near < B_near)
			{
				n = A_n2;
				result = A_near;
			}
		}
		// Inside sub-space object B
		if (B_near < INFINITY && B_far == INFINITY)
		{
			if (B_near < A_near)
			{
				n = A_n2;
				result = A_near;
			}
			if (B_near > A_near)
			{
				result = INFINITY;
			}	
		}
	}
	
	return result;
}

// render only the area where solid object A overlaps solid object B (A ^ B)
float operation_SolidA_Overlap_SolidB( float A_near, float A_far, float B_near, float B_far, vec3 A_n1, vec3 A_n2, vec3 B_n1, vec3 B_n2, out vec3 n )
{
	float result = INFINITY;
	
	// Missed object A or B
	if (A_near == INFINITY || B_near == INFINITY)
	{
		// early out
		return INFINITY;
	}
	
	// Outside object A
	if (A_near < INFINITY && A_far < INFINITY)
	{
		// Outside object B
		if (B_far < INFINITY)
		{
			if (A_near < B_far && A_near > B_near)
			{
				n = A_n1;
				result = A_near;
			}
			if (B_near < A_far && B_near > A_near)
			{
				n = B_n1;
				result = B_near;
			}
		}
		// Inside object B
		if (B_near < INFINITY && B_far == INFINITY)
		{
			if (A_near < B_near)
			{
				n = A_n1;
				result = A_near;
			}
			else
			{
				result = INFINITY;
			}
		}
	}
	
	// Inside object A
	if (A_near < INFINITY && A_far == INFINITY)
	{
		// Outside object B
		if (B_far < INFINITY)
		{
			if (B_near < A_near)
			{
				n = B_n1;
				result = B_near;
			}
			else
			{
				result = INFINITY;
			}
		}
		// Inside object B
		if (B_near < INFINITY && B_far == INFINITY)
		{
			if (A_near < B_near)
			{
				n = A_n2;
				result = 0.1;
			}
			else
			{
				n = B_n2;
				result = 0.1;
			}
		}
	}
	
	return result;
}

// render only the area where hollow object A overlaps hollow object B (A ^ B)
float operation_HollowA_Overlap_HollowB( float A_near, float A_far, float B_near, float B_far, vec3 A_n1, vec3 A_n2, vec3 B_n1, vec3 B_n2, out vec3 n )
{
	float result = INFINITY;
	
	// Missed object A or B
	if (A_near == INFINITY || B_near == INFINITY)
	{
		// early out
		return INFINITY;
	}
	
	// Outside hollow object A
	if (A_near < INFINITY && A_far < INFINITY)
	{
		// Outside hollow object B
		if (B_far < INFINITY)
		{
			if (A_near < B_far && A_near > B_near)
			{
				n = A_n1;
				result = A_near;
			}
			if (B_near < A_far && B_near > A_near)
			{
				n = B_n1;
				result = B_near;
			}
		}
		// Inside hollow object B
		if (B_near < INFINITY && B_far == INFINITY)
		{
			if (A_near < B_near)
			{
				n = A_n1;
				result = A_near;
			}
			else
			{
				result = INFINITY;
			}
		}
	}
	
	// Inside hollow object A
	if (A_near < INFINITY && A_far == INFINITY)
	{
		// Outside hollow object B
		if (B_far < INFINITY)
		{
			if (B_near < A_near)
			{
				n = B_n1;
				result = B_near;
			}
			else
			{
				result = INFINITY;
			}
		}
		// Inside hollow object B
		if (B_near < INFINITY && B_far == INFINITY)
		{
			if (A_near < B_near)
			{
				n = A_n2;
				result = A_near;
			}
			else
			{
				n = B_n2;
				result = B_near;
			}
		}
	}
	
	return result;
}


//---------------------------------------------------------------------------------------
float SceneIntersect( )
//---------------------------------------------------------------------------------------
{
	vec3 n, n2, A_n1, A_n2, B_n1, B_n2;
	float d = INFINITY;
	float f = INFINITY;
	float A_near, A_far;
	float B_near, B_far;
	float t = INFINITY;
	int objectCount = 0;
	
	hitObjectID = -INFINITY;
	
	// first, intersect all regular objects in the scene

	d = BoxInteriorIntersect(boxes[0].minCorner, boxes[0].maxCorner, rayOrigin, rayDirection, n);
	if (d < t)
	{
		t = d;
		hitNormal = n;
		hitEmission = boxes[0].emission;
		hitColor = boxes[0].color;
		hitType = boxes[0].type;
		hitObjectID = float(objectCount);

		if (n == vec3(-1,0,0))
		{
			hitColor = vec3(0.15,0.05,0.15);
		}
		if (n == vec3(0,1,0))
		{
			hitColor = vec3(1);
			hitType = CHECK;
		}
	}
	objectCount++;
	

	d = QuadIntersect( quads[0].v0, quads[0].v1, quads[0].v2, quads[0].v3, rayOrigin, rayDirection, TRUE );
	if (d < t)
	{
		t = d;
		hitNormal = (quads[0].normal);
		hitEmission = quads[0].emission;
		hitColor = quads[0].color;
		hitType = quads[0].type;
		hitObjectID = float(objectCount);
	}
	objectCount++;

	d = QuadIntersect( quads[1].v0, quads[1].v1, quads[1].v2, quads[1].v3, rayOrigin, rayDirection, TRUE );
	if (d < t)
	{
		t = d;
		hitNormal = (quads[1].normal);
		hitEmission = quads[1].emission;
		hitColor = quads[1].color;
		hitType = quads[1].type;
		hitObjectID = float(objectCount);
	}
	objectCount++;
	
	
	// now intersect all CSG objects
	// dark glass sculpture in center of room
	A_near = CSG_EllipsoidIntersect( vec3(40, 30, 15), vec3(0, 30, 0), rayOrigin, rayDirection, A_n1, A_n2, A_far);
	B_near = CSG_SphereIntersect( 25.0, vec3(18, 20, 0), rayOrigin, rayDirection, B_n1, B_n2, B_far);
	d = operation_HollowA_Minus_SolidB( A_near, A_far, B_near, B_far, A_n1, A_n2, B_n1, B_n2, n );
	if (d < t)
	{
		t = d;
		hitNormal = n;
		hitEmission = vec3(0);
		hitColor = vec3(0.0,0.01,0.0);
		hitType = REFR;
		hitObjectID = float(objectCount);
	}
	objectCount++;
	
        
	// Blue Glass Sphere-Boxes along back wall
	A_near = CSG_SphereIntersect( 20.0, vec3(-100, 20, -200), rayOrigin, rayDirection, A_n1, A_n2, A_far);
	B_near = CSG_BoxIntersect( vec3(-115, 6, -215), vec3(-85, 36, -185), rayOrigin, rayDirection, B_n1, B_n2, B_far );
	d = operation_HollowA_Plus_HollowB( A_near, A_far, B_near, B_far, A_n1, A_n2, B_n1, B_n2, n );
	if (d < t)
	{
		t = d;
		hitNormal = n;
		hitEmission = vec3(0);
		hitColor = vec3(0.0, 0.4, 1.0);
		hitType = REFR;
		hitObjectID = float(objectCount);
	}
	objectCount++;
	
	A_near = CSG_SphereIntersect( 20.0, vec3(0, 20, -200), rayOrigin, rayDirection, A_n1, A_n2, A_far);
	B_near = CSG_BoxIntersect( vec3(-15, 6, -215), vec3(15, 36, -185), rayOrigin, rayDirection, B_n1, B_n2, B_far );
	d = operation_HollowA_Minus_SolidB( A_near, A_far, B_near, B_far, A_n1, A_n2, B_n1, B_n2, n );
	if (d < t)
	{
		t = d;
		hitNormal = n;
		hitEmission = vec3(0);
		hitColor = vec3(0.3, 0.8, 1.0);
		hitType = REFR;
		hitObjectID = float(objectCount);
	}
	objectCount++;
	
	A_near = CSG_SphereIntersect( 20.0, vec3(100, 20, -200), rayOrigin, rayDirection, A_n1, A_n2, A_far);
	B_near = CSG_BoxIntersect( vec3(85, 0, -215), vec3(115, 36, -185), rayOrigin, rayDirection, B_n1, B_n2, B_far );
	d = operation_HollowA_Overlap_HollowB( A_near, A_far, B_near, B_far, A_n1, A_n2, B_n1, B_n2, n );
	if (d < t)
	{
		t = d;
		hitNormal = n;
		hitEmission = vec3(0);
		hitColor = vec3(0.1, 0.6, 1.0);
		hitType = SPECSUB;
		hitObjectID = float(objectCount);
	}
	objectCount++;
	
	// doorframe
	A_near = CSG_BoxIntersect( vec3(-304, -4, -132), vec3(-298, 82, -68), rayOrigin, rayDirection, A_n1, A_n2, A_far );
	B_near = CSG_BoxIntersect( vec3(-310, -2, -128), vec3(-296, 78, -72), rayOrigin, rayDirection, B_n1, B_n2, B_far );
	d = operation_SolidA_Minus_SolidB( A_near, A_far, B_near, B_far, A_n1, A_n2, B_n1, B_n2, n );
	if (d < t)
	{
		t = d;
		hitNormal = n;
		hitEmission = vec3(0);
		hitColor = vec3(0.9);
		hitType = COAT;
		hitObjectID = float(objectCount);
	}
	objectCount++;

	// left wall and hallway
	Plane leftWallPlane = Plane( vec4( 1,0,0, -300.0), vec3(0), vec3(0.05,0.15,0.15), DIFF);
	A_near = CSG_PlaneIntersect( leftWallPlane.pla, rayOrigin, rayDirection, A_n1, A_n2, A_far );
	B_near = CSG_BoxIntersect( vec3(-350, 0, -128), vec3(-290, 78, -72), rayOrigin, rayDirection, B_n1, B_n2, B_far );
	d = operation_SolidA_Minus_SolidB( A_near, A_far, B_near, B_far, A_n1, A_n2, B_n1, B_n2, n );
	if (d < t)
	{
		t = d;
		hitNormal = n;
		hitEmission = leftWallPlane.emission;
		hitColor = leftWallPlane.color;
		hitType = leftWallPlane.type;
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
	vec3 diffuseBounceMask = vec3(1);
	vec3 diffuseBounceRayOrigin = vec3(0);
	vec3 diffuseBounceRayDirection = vec3(0);
	vec3 x, n, nl;
        
	float t;
	float weight;
	float nc, nt, ratioIoR, Re, Tr;
	float previousObjectID;
	float newRandom = rand();

	int reflectionBounces = -1;
	int diffuseCount = 0;
	int previousIntersecType;

	int bounceIsSpecular = TRUE;
	int sampleLight = FALSE;
	int willNeedReflectionRay = FALSE;
	int isReflectionTime = FALSE;
	int reflectionNeedsToBeSharp = FALSE;
	int willNeedDiffuseBounceRay = FALSE;
	int isDiffuseBounceTime = FALSE;



        for (int bounces = 0; bounces < 10; bounces++)
	{
		if (isReflectionTime == TRUE)
			reflectionBounces++;

		previousIntersecType = hitType;
		previousObjectID = hitObjectID;


		t = SceneIntersect();
		
		// shouldn't happen because we are inside a large room, but just in case
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
			objectNormal += n;
			objectColor += hitColor;
		}


		
		if (hitType == LIGHT)
		{	
			if (diffuseCount == 0 && isReflectionTime == FALSE)
				pixelSharpness = 1.0;

			if (isReflectionTime == TRUE && reflectionBounces == 0)
			{
				objectNormal += nl;
				//objectColor = hitColor;
				objectID += hitObjectID;
			}

			if (bounceIsSpecular == TRUE || sampleLight == TRUE)
				accumCol += mask * hitEmission; // looking at light through a reflection
			
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
		}

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
		

		    
                if (hitType == DIFF) // Ideal DIFFUSE reflection
		{
			diffuseCount++;

			mask *= hitColor;

			bounceIsSpecular = FALSE;

			rayOrigin = x + nl * uEPS_intersect;

			if (diffuseCount == 1)
			{
				diffuseBounceMask = mask;
				diffuseBounceRayOrigin = rayOrigin;
				diffuseBounceRayDirection = randomCosWeightedDirectionInHemisphere(nl);
				willNeedDiffuseBounceRay = TRUE;
			}
                        
			if (newRandom < 0.5)
				rayDirection = sampleQuadLight(x, nl, quads[0], weight);
			else
				rayDirection = sampleQuadLight(x, nl, quads[1], weight);
				
			mask *= weight * N_LIGHTS;
			sampleLight = TRUE;
			continue;
		}
		
		if (hitType == SPEC)  // Ideal SPECULAR reflection
		{
			mask *= hitColor;

			rayDirection = reflect(rayDirection, nl);
			rayOrigin = x + nl * uEPS_intersect;

			//bounceIsSpecular = TRUE; // turn on mirror caustics
			continue;
		}
		
		if (hitType == REFR)  // Ideal dielectric REFRACTION
		{
			nc = 1.0; // IOR of Air
			nt = 1.5; // IOR of common Glass
			Re = calcFresnelReflectance(rayDirection, n, nc, nt, ratioIoR);
			Tr = 1.0 - Re;
			
			if (Re == 1.0)
			{
				rayDirection = reflect(rayDirection, nl);
				rayOrigin = x + nl * uEPS_intersect;
				continue;
			}

			if (bounces == 0 || (bounces == 1 && bounceIsSpecular == TRUE && hitObjectID != previousObjectID && n == nl))
			{
				reflectionMask = mask * Re;
				reflectionRayDirection = reflect(rayDirection, nl); // reflect ray from surface
				reflectionRayOrigin = x + nl * uEPS_intersect;
				willNeedReflectionRay = TRUE;
				
				reflectionNeedsToBeSharp = TRUE;
			}

			// transmit ray through surface
			mask *= Tr;
			mask *= hitColor;
			
			rayDirection = refract(rayDirection, nl, ratioIoR);
			rayOrigin = x - nl * uEPS_intersect;

			if (diffuseCount == 1 && isDiffuseBounceTime == TRUE)
				bounceIsSpecular = TRUE; // turn on refracting caustics

			continue;
			
		} // end if (hitType == REFR)
		
		if (hitType == COAT || hitType == CHECK)  // Diffuse object underneath with ClearCoat on top
		{
			float roughness = 0.0;
			
			nt = 1.4; // IOR of Clear Coat

			if (hitType == CHECK)
			{
				vec3 checkCol0 = vec3(0.3, 0.1, 0.0);
				vec3 checkCol1 = checkCol0 * 0.5;
				vec3 firstColor = ( (mod(x.x, 20.0) > 10.0) == (mod(x.z, 20.0) > 10.0) )? checkCol0 : checkCol1;
				vec3 secondColor = ( (mod(x.x, 10.0) > 5.0) == (mod(x.z, 10.0) > 5.0) )? checkCol1 : checkCol0;
				vec3 thirdColor = ( (mod(x.x, 5.0) > 2.5) == (mod(x.z, 5.0) > 2.5) )? checkCol0 : checkCol1;
				hitColor = firstColor * secondColor * thirdColor;
				if (bounces == 0)
					objectColor = hitColor;
				
				roughness = 0.1;
				nt = 1.03;
			}
			
			nc = 1.0; // IOR of Air
			
			Re = calcFresnelReflectance(rayDirection, nl, nc, nt, ratioIoR);
			Tr = 1.0 - Re;
			
			if (bounces == 0 || (bounces == 1 && diffuseCount == 0 && hitObjectID != previousObjectID))
			{
				reflectionMask = mask * Re;
				reflectionRayDirection = reflect(rayDirection, nl); // reflect ray from surface
				reflectionRayDirection = randomDirectionInSpecularLobe(reflectionRayDirection, roughness);
				reflectionRayOrigin = x + nl * uEPS_intersect;
				willNeedReflectionRay = TRUE;
				// if (bounces == 0 && hitType != CHECK)
				// 	reflectionNeedsToBeSharp = TRUE;
			}

			diffuseCount++;

			mask *= Tr;
			mask *= hitColor;
			
			bounceIsSpecular = FALSE;

			rayOrigin = x + nl * uEPS_intersect;

			if (diffuseCount == 1)
			{
				diffuseBounceMask = mask;
				diffuseBounceRayOrigin = rayOrigin;
				diffuseBounceRayDirection = randomCosWeightedDirectionInHemisphere(nl);
				willNeedDiffuseBounceRay = TRUE;
			}
                        
			if (newRandom < 0.5)
				rayDirection = sampleQuadLight(x, nl, quads[0], weight);
			else
				rayDirection = sampleQuadLight(x, nl, quads[1], weight);
				
			mask *= weight * N_LIGHTS;
			sampleLight = TRUE;
			continue;
                        
		} // end if (hitType == COAT || hitType == CHECK)

		
		if (hitType == SPECSUB)  // Shiny(specular) coating over Sub-Surface Scattering material
		{
			float nc = 1.0; // IOR of Air
			float nt = 1.4; // IOR of Clear Coat
			Re = calcFresnelReflectance(rayDirection, nl, nc, nt, ratioIoR);
			Tr = 1.0 - Re;
			
			if (bounces == 0)
			{
				reflectionMask = mask * Re;
				reflectionRayDirection = reflect(rayDirection, nl); // reflect ray from surface
				reflectionRayOrigin = x + nl * uEPS_intersect;
				willNeedReflectionRay = TRUE;
				//reflectionNeedsToBeSharp = TRUE;
			}

			mask *= Tr;
			
			vec3 absorptionCoefficient = vec3(0.8, 0.4, 0.0);
			float translucentDensity = 0.4;
			float scatteringDistance = -log(rand()) / translucentDensity;
			
			// transmission?
			if (scatteringDistance > t) 
			{
				mask *= exp(-absorptionCoefficient * t);

				rayDirection = rayDirection;
				rayOrigin = x + rayDirection * scatteringDistance;

				continue;
			}

			diffuseCount++;

			bounceIsSpecular = FALSE;

			// else scattering
			mask *= exp(-absorptionCoefficient * scatteringDistance);

			rayOrigin = x + nl * uEPS_intersect;

			if (diffuseCount == 1)
			{
				diffuseBounceMask = mask;
				diffuseBounceRayOrigin = rayOrigin;
				diffuseBounceRayDirection = randomSphereDirection();
				willNeedDiffuseBounceRay = TRUE;
			}
                        
			if (newRandom < 0.5)
				rayDirection = sampleQuadLight(x, nl, quads[0], weight);
			else
				rayDirection = sampleQuadLight(x, nl, quads[1], weight);
				
			mask *= weight * N_LIGHTS;
			sampleLight = TRUE;
			continue;
			
		} // end if (hitType == SPECSUB)
		
		
	} // end for (int bounces = 0; bounces < 10; bounces++)
	

	return max(vec3(0), accumCol);

} // end vec3 CalculateRadiance( out vec3 objectNormal, out vec3 objectColor, out float objectID, out float pixelSharpness )


//-----------------------------------------------------------------------
void SetupScene(void)
//-----------------------------------------------------------------------
{
	vec3 z  = vec3(0);          
	vec3 L1 = vec3(1.0, 1.0, 1.0) * 2.0;// White light
	float ceilingHeight = 300.0;
	
	quads[0] = Quad( vec3(0,-1,0), vec3(-150, ceilingHeight,-200), vec3(150, ceilingHeight,-200), vec3(150, ceilingHeight,-25), vec3(-150, ceilingHeight,-25), L1, z, LIGHT);// rectangular Area Light in ceiling
	quads[1] = Quad( vec3(0,-1,0), vec3(-150, ceilingHeight, 25), vec3(150, ceilingHeight, 25), vec3(150, ceilingHeight, 200), vec3(-150, ceilingHeight, 200), L1, z, LIGHT);// rectangular Area Light in ceiling
	
	boxes[0] = Box( vec3(-100000,0,-300), vec3(300,301,300), z, vec3(0.7), DIFF); // museum room interior
}


#include <pathtracing_main>
