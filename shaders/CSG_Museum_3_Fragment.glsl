#version 300 es

precision highp float;
precision highp int;
precision highp sampler2D;

#include <pathtracing_uniforms_and_defines>

#define N_LIGHTS 2.0
#define N_SPHERES 2
#define N_PLANES 4
#define N_QUADS 2
#define N_BOXES 2


//-----------------------------------------------------------------------

struct Ray { vec3 origin; vec3 direction; };
struct Sphere { float radius; vec3 position; vec3 emission; vec3 color; int type; };
struct Plane { vec4 pla; vec3 emission; vec3 color; int type; };
struct Quad { vec3 normal; vec3 v0; vec3 v1; vec3 v2; vec3 v3; vec3 emission; vec3 color; int type; };
struct Box { vec3 minCorner; vec3 maxCorner; vec3 emission; vec3 color; int type; };
struct Intersection { vec3 normal; vec3 emission; vec3 color; int type; };

Sphere spheres[N_SPHERES];
Plane planes[N_PLANES];
Quad quads[N_QUADS];
Box boxes[N_BOXES];

#include <pathtracing_random_functions>

#include <pathtracing_calc_fresnel_reflectance>

#include <pathtracing_plane_intersect>

#include <pathtracing_sphere_intersect>

#include <pathtracing_box_intersect>

#include <pathtracing_quad_intersect>

#include <pathtracing_sample_quad_light>

//----------------------------------------------------------------------------------------------
float CSG_SphereIntersect( float rad, vec3 pos, Ray r, out vec3 n1, out vec3 n2, out float far )
//----------------------------------------------------------------------------------------------
{
	vec3 L = r.origin - pos;
	float t0, t1; 
	float result = INFINITY;
	far = INFINITY;
	// quadratic equation coefficients
	float a = dot( r.direction, r.direction );
	float b = 2.0 * dot( r.direction, L );
	float c = dot( L, L ) - (rad * rad);

	solveQuadratic(a, b, c, t0, t1);
	
	if( t1 > 0.0 )
	{
		result = t1;
		far = INFINITY;
		n2 = (r.origin + r.direction * result) - pos;   
	}
	
	if( t0 > 0.0 )
	{
		result = t0;
		far = t1;
		n1 = (r.origin + r.direction * result) - pos;
	}
		
	return result;	
}

//--------------------------------------------------------------------------------------------------
float CSG_EllipsoidIntersect( vec3 radii, vec3 pos, Ray r, out vec3 n1, out vec3 n2, out float far )
//--------------------------------------------------------------------------------------------------
{
	vec3 oc = r.origin - pos;
	vec3 oc2 = oc*oc;
	vec3 ocrd = oc*r.direction;
	vec3 rd2 = r.direction*r.direction;
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
		n2 = ((r.origin + r.direction * result) - pos) * invRad2;
	}
	
	if( t0 > 0.0 )
	{
		result = t0;
		far = t1;
		n1 = ((r.origin + r.direction * result) - pos) * invRad2;
	}
	
	return result;	
}


//------------------------------------------------------------------------------------------------------
float CSG_BoxIntersect( vec3 minCorner, vec3 maxCorner, Ray r, out vec3 n1, out vec3 n2, out float far )
//------------------------------------------------------------------------------------------------------
{
	vec3 invDir = 1.0 / r.direction;
	vec3 near = (minCorner - r.origin) * invDir;
	vec3 further = (maxCorner - r.origin) * invDir;
	
	vec3 tmin = min(near, further);
	vec3 tmax = max(near, further);
	
	float t0 = max( max(tmin.x, tmin.y), tmin.z);
	float t1 = min( min(tmax.x, tmax.y), tmax.z);
	float result = INFINITY;
	far = INFINITY;
	
	if (t0 > t1) return INFINITY;
	
	if (t1 > 0.0) // if we are inside the box
	{
		n2 = -sign(r.direction) * step(tmax, tmax.yzx) * step(tmax, tmax.zxy);
		far = INFINITY;
		result = t1;
	}

	if (t0 > 0.0) // if we are outside the box
	{
		n1 = -sign(r.direction) * step(tmin.yzx, tmin) * step(tmin.zxy, tmin);
		n2 = -sign(r.direction) * step(tmax, tmax.yzx) * step(tmax, tmax.zxy);
		far = t1;
		result = t0;	
	}
	
	return result;
}

//----------------------------------------------------------------------------------
float CSG_PlaneIntersect( vec4 pla, Ray r, out vec3 n1, out vec3 n2, out float far )
//----------------------------------------------------------------------------------
{
	vec3 n = normalize(pla.xyz);
	float denom = dot(n, r.direction);
	far = INFINITY;
	// uncomment if single-sided plane is desired
	if (denom >= 0.0)
		return INFINITY;
	
        vec3 pOrO = (pla.w * n) - r.origin; 
        float result = dot(pOrO, n) / denom;
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


//-----------------------------------------------------------------------
float SceneIntersect( Ray r, inout Intersection intersec )
//-----------------------------------------------------------------------
{
	vec3 n, n2, A_n1, A_n2, B_n1, B_n2;
	float d = INFINITY;
	float f = INFINITY;
	float A_near, A_far;
	float B_near, B_far;
	float t = INFINITY;
	
	// first, intersect all regular objects in the scene
	
	for (int i = 0; i < N_QUADS; i++)
        {
		d = QuadIntersect( quads[i].v0, quads[i].v1, quads[i].v2, quads[i].v3, r, true );
		if (d < t)
		{
			t = d;
			intersec.normal = normalize(quads[i].normal);
			intersec.emission = quads[i].emission;
			intersec.color = quads[i].color;
			intersec.type = quads[i].type;
		}
	}
	
	d = SphereIntersect( spheres[0].radius, spheres[0].position, r );	
	if (d < t)
	{
		t = d;
		//n = (r.origin + r.direction * d) - spheres[0].position;
		n = vec3(0,1,0);
		intersec.normal = normalize(n);
		intersec.emission = spheres[0].emission;
		intersec.color = spheres[0].color;
		intersec.type = spheres[0].type;
	}
        
	for (int i = 0; i < N_PLANES; i++)
        {
		d = PlaneIntersect( planes[i].pla, r );
		if (d < t)
		{
			t = d;
			intersec.normal = normalize(planes[i].pla.xyz);
			intersec.emission = planes[i].emission;
			intersec.color = planes[i].color;
			intersec.type = planes[i].type;
		}
        }
	
	// now intersect all CSG objects
	// dark glass sculpture in center of room
	A_near = CSG_EllipsoidIntersect( vec3(40, 30, 15), vec3(0, 30, 0), r, A_n1, A_n2, A_far);
	B_near = CSG_SphereIntersect( 25.0, vec3(18, 20, 0), r, B_n1, B_n2, B_far);
	d = operation_HollowA_Minus_SolidB( A_near, A_far, B_near, B_far, A_n1, A_n2, B_n1, B_n2, n );
	if (d < t)
	{
		t = d;
		intersec.normal = normalize(n);
		intersec.emission = vec3(0);
		intersec.color = vec3(0.0,0.01,0.0);
		intersec.type = REFR;
	}
	
	
	// mirror ellipsoid-spheres along wall behind camera
	A_near = CSG_EllipsoidIntersect( vec3(40, 10, 15), vec3(150, 10, 240), r, A_n1, A_n2, A_far);
	B_near = CSG_SphereIntersect( 18.0, vec3(150, 21, 240), r, B_n1, B_n2, B_far);
	d = operation_SolidA_Plus_SolidB( A_near, A_far, B_near, B_far, A_n1, A_n2, B_n1, B_n2, n );
	if (d < t)
	{
		t = d;
		intersec.normal = normalize(n);
		intersec.emission = vec3(0);
		intersec.color = vec3(0.971519, 0.959915, 0.915324) * 0.8; // silver
		intersec.type = SPEC;
	}
	
	A_near = CSG_EllipsoidIntersect( vec3(40, 10, 15), vec3(0, 10, 240), r, A_n1, A_n2, A_far);
	B_near = CSG_SphereIntersect( 18.0, vec3(0, 21, 240), r, B_n1, B_n2, B_far);
	d = operation_SolidA_Minus_SolidB( A_near, A_far, B_near, B_far, A_n1, A_n2, B_n1, B_n2, n );
	if (d < t)
	{
		t = d;
		intersec.normal = normalize(n);
		intersec.emission = vec3(0);
		intersec.color = vec3(0.955008, 0.637427, 0.538163); // copper
		intersec.type = SPEC;
	}
	
	A_near = CSG_EllipsoidIntersect( vec3(40, 10, 15), vec3(-130, 10, 240), r, A_n1, A_n2, A_far);
	B_near = CSG_SphereIntersect( 20.0, vec3(-130, 20, 240), r, B_n1, B_n2, B_far);
	d = operation_SolidA_Overlap_SolidB( A_near, A_far, B_near, B_far, A_n1, A_n2, B_n1, B_n2, n );
	if (d < t)
	{
		t = d;
		intersec.normal = normalize(n);
		intersec.emission = vec3(0);
		intersec.color = vec3(1.000000, 0.765557, 0.336057); // gold
		intersec.type = SPEC;
	}
	
	
	// doorframe
	A_near = CSG_BoxIntersect( vec3(-304, -4, -132), vec3(-298, 82, -68), r, A_n1, A_n2, A_far );
	B_near = CSG_BoxIntersect( vec3(-310, -2, -128), vec3(-296, 78, -72), r, B_n1, B_n2, B_far );
	d = operation_SolidA_Minus_SolidB( A_near, A_far, B_near, B_far, A_n1, A_n2, B_n1, B_n2, n );
	if (d < t)
	{
		t = d;
		intersec.normal = normalize(n);
		intersec.emission = vec3(0);
		intersec.color = vec3(0.9);
		intersec.type = COAT;
	}
	// left wall and hallway
	Plane leftWallPlane = Plane( vec4( 1,0,0, -300.0), vec3(0), vec3(0.05,0.15,0.15), DIFF);
	A_near = CSG_PlaneIntersect( leftWallPlane.pla, r, A_n1, A_n2, A_far );
	B_near = CSG_BoxIntersect( vec3(-350, 0, -128), vec3(-290, 78, -72), r, B_n1, B_n2, B_far );
	d = operation_SolidA_Minus_SolidB( A_near, A_far, B_near, B_far, A_n1, A_n2, B_n1, B_n2, n );
	if (d < t)
	{
		t = d;
		intersec.normal = normalize(n);
		intersec.emission = leftWallPlane.emission;
		intersec.color = leftWallPlane.color;
		intersec.type = leftWallPlane.type;
	}
	
	// hidden Easter Egg, literally!
	A_near = CSG_SphereIntersect( 8.0, vec3(-330, 20, 40), r, A_n1, A_n2, A_far);
	B_near = CSG_SphereIntersect( 10000.0, vec3(9670, 0, 0), r, B_n1, B_n2, B_far);
	d = operation_HollowA_Minus_SolidB( A_near, A_far, B_near, B_far, A_n1, A_n2, B_n1, B_n2, n );
	if (d < t)
	{
		t = d;
		intersec.normal = normalize(n);
		intersec.emission = vec3(0);
		intersec.color = vec3(1.0,0.5,0.8);
		intersec.type = COAT;
	}
	A_near = CSG_EllipsoidIntersect( vec3(13, 8, 8), vec3(-324, 20, 40), r, A_n1, A_n2, A_far);
	B_near = CSG_SphereIntersect( 10000.0, vec3(-10324, 0, 0), r, B_n1, B_n2, B_far);
	d = operation_HollowA_Minus_SolidB( A_near, A_far, B_near, B_far, A_n1, A_n2, B_n1, B_n2, n );
	if (d < t)
	{
		t = d;
		intersec.normal = normalize(n);
		intersec.emission = vec3(0);
		intersec.color = vec3(1.0,0.5,0.8);
		intersec.type = COAT;
	}
	
	return t;
	
} // end float SceneIntersect( Ray r, inout Intersection intersec )


//-----------------------------------------------------------------------
vec3 CalculateRadiance( Ray r, inout uvec2 seed )
//-----------------------------------------------------------------------
{
	Intersection intersec;
	Quad lightChoice;
	Ray firstRay;
	Ray secondaryRay;

	vec3 accumCol = vec3(0);
	vec3 mask = vec3(1);
	vec3 firstMask = vec3(1);
	vec3 secondaryMask = vec3(1);
	vec3 tdir;
	vec3 randPointOnLight, dirToLight;
	vec3 x, n, nl;
        
	float t;
	float weight;
	float nc, nt, ratioIoR, Re, Tr;
	float randChoose;

	int diffuseCount = 0;

	bool bounceIsSpecular = true;
	bool sampleLight = false;
	bool firstTypeWasREFR = false;
	bool reflectionTime = false;
	bool firstTypeWasDIFF = false;
	bool shadowTime = false;
	bool firstTypeWasCOAT = false;


        for (int bounces = 0; bounces < 7; bounces++)
	{
		
		t = SceneIntersect(r, intersec);
		
		/*
		//not used in this scene because we are inside a huge room - no rays can escape
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

			if (firstTypeWasDIFF)
			{
				if (!shadowTime) 
				{
					if (sampleLight)
						accumCol = mask * intersec.emission * 0.5;
					else if (bounceIsSpecular)
						accumCol = mask * intersec.emission;
					
					// start back at the diffuse surface, but this time follow shadow ray branch
					r = firstRay;
					r.direction = normalize(r.direction);
					mask = firstMask;
					// set/reset variables
					shadowTime = true;
					bounceIsSpecular = false;
					sampleLight = true;
					// continue with the shadow ray
					continue;
				}
				
				accumCol += mask * intersec.emission * 0.5; // add shadow ray result to the colorbleed result (if any)
				
				break;		
			}

			if (firstTypeWasREFR)
			{
				if (!reflectionTime) 
				{
					if (bounceIsSpecular || sampleLight)
						accumCol = mask * intersec.emission;
					
					// start back at the refractive surface, but this time follow reflective branch
					r = firstRay;
					r.direction = normalize(r.direction);
					mask = firstMask;
					// set/reset variables
					reflectionTime = true;
					bounceIsSpecular = true;
					sampleLight = false;
					// continue with the reflection ray
					continue;
				}

				if (bounceIsSpecular || sampleLight)
					accumCol += mask * intersec.emission; // add reflective result to the refractive result (if any)
				
				break;	
			}

			if (firstTypeWasCOAT)
			{
				if (!shadowTime) 
				{
					if (sampleLight)
						accumCol = mask * intersec.emission * 0.5;

					// start back at the diffuse surface, but this time follow shadow ray branch
					r = secondaryRay;
					r.direction = normalize(r.direction);
					mask = secondaryMask;
					// set/reset variables
					shadowTime = true;
					bounceIsSpecular = false;
					sampleLight = true;
					// continue with the shadow ray
					continue;
				}

				if (!reflectionTime)
				{
					// add initial shadow ray result to secondary shadow ray result (if any) 
					accumCol += mask * intersec.emission * 0.5;

					// start back at the coat surface, but this time follow reflective branch
					r = firstRay;
					r.direction = normalize(r.direction);
					mask = firstMask;
					// set/reset variables
					reflectionTime = true;
					bounceIsSpecular = true;
					sampleLight = false;
					// continue with the reflection ray
					continue;
				}

				// add reflective result to the diffuse result
				if (sampleLight || bounceIsSpecular)
					accumCol += mask * intersec.emission;
				
				break;	
			}

			if (sampleLight || bounceIsSpecular)
				accumCol = mask * intersec.emission; // looking at light through a reflection
			// reached a light, so we can exit
			break;

		} // end if (intersec.type == LIGHT)


		// if we get here and sampleLight is still true, shadow ray failed to find a light source
		if (sampleLight) 
		{

			if (firstTypeWasDIFF && !shadowTime) 
			{
				// start back at the diffuse surface, but this time follow shadow ray branch
				r = firstRay;
				r.direction = normalize(r.direction);
				mask = firstMask;
				// set/reset variables
				shadowTime = true;
				bounceIsSpecular = false;
				sampleLight = true;
				// continue with the shadow ray
				continue;
			}

			if (firstTypeWasREFR && !reflectionTime) 
			{
				// start back at the refractive surface, but this time follow reflective branch
				r = firstRay;
				r.direction = normalize(r.direction);
				mask = firstMask;
				// set/reset variables
				reflectionTime = true;
				bounceIsSpecular = true;
				sampleLight = false;
				// continue with the reflection ray
				continue;
			}

			if (firstTypeWasCOAT && !shadowTime) 
			{
				// start back at the diffuse surface, but this time follow shadow ray branch
				r = secondaryRay;
				r.direction = normalize(r.direction);
				mask = secondaryMask;
				// set/reset variables
				shadowTime = true;
				bounceIsSpecular = false;
				sampleLight = true;
				// continue with the shadow ray
				continue;
			}

			if (firstTypeWasCOAT && !reflectionTime) 
			{
				// start back at the refractive surface, but this time follow reflective branch
				r = firstRay;
				r.direction = normalize(r.direction);
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
		n = normalize(intersec.normal);
                nl = dot(n, r.direction) < 0.0 ? normalize(n) : normalize(-n);
		x = r.origin + r.direction * t;
		
		randChoose = rand(seed) * 2.0; // 2 lights to choose from
		lightChoice = quads[int(randChoose)];

		    
                if (intersec.type == DIFF ) // Ideal DIFFUSE reflection
		{
			diffuseCount++;

			mask *= intersec.color;

			bounceIsSpecular = false;

			if (diffuseCount == 1 && !firstTypeWasDIFF && !firstTypeWasREFR)
			{	
				// save intersection data for future shadowray trace
				firstTypeWasDIFF = true;
				dirToLight = sampleQuadLight(x, nl, lightChoice, dirToLight, weight, seed);
				firstMask = mask * weight * N_LIGHTS;
                                firstRay = Ray( x, normalize(dirToLight) ); // create shadow ray pointed towards light
				firstRay.origin += nl * uEPS_intersect;

				// choose random Diffuse sample vector
				r = Ray( x, normalize(randomCosWeightedDirectionInHemisphere(nl, seed)) );
				r.origin += nl * uEPS_intersect;
				continue;
			}
			else if ((firstTypeWasREFR || reflectionTime) && rand(seed) < 0.5)
			{
				r = Ray( x, normalize(randomCosWeightedDirectionInHemisphere(nl, seed)) );
				r.origin += nl * uEPS_intersect;
				continue;
			}
                        
			dirToLight = sampleQuadLight(x, nl, lightChoice, dirToLight, weight, seed);
			mask *= weight * N_LIGHTS;

			r = Ray( x, normalize(dirToLight) );
			r.origin += nl * uEPS_intersect;

			r.direction = normalize(r.direction);
			sampleLight = true;
			continue;
		}
		
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
			Re = calcFresnelReflectance(r.direction, n, nc, nt, ratioIoR);
			Tr = 1.0 - Re;
			
			if (!firstTypeWasREFR && diffuseCount == 0)
			{	
				// save intersection data for future reflection trace
				firstTypeWasREFR = true;
				firstMask = mask * Re;
				firstRay = Ray( x, reflect(r.direction, nl) ); // create reflection ray from surface
				firstRay.origin += nl * uEPS_intersect;
				mask *= Tr;
			}
			else if (bounceIsSpecular && n == nl && rand(seed) < Re)
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

			if (bounces == 1)
				bounceIsSpecular = true; // turn on refracting caustics

			continue;
			
		} // end if (intersec.type == REFR)
		
		if (intersec.type == COAT || intersec.type == CHECK)  // Diffuse object underneath with ClearCoat on top
		{	
			float roughness = 0.0;
			float maskFactor = 1.0;
			nt = 1.4; // IOR of Clear Coat

			if( intersec.type == CHECK )
			{
				vec3 checkCol0 = vec3(0.3, 0.1, 0.0);
				vec3 checkCol1 = checkCol0 * 0.5;
				vec3 firstColor = ( (mod(x.x, 20.0) > 10.0) == (mod(x.z, 20.0) > 10.0) )? checkCol0 : checkCol1;
				vec3 secondColor = ( (mod(x.x, 10.0) > 5.0) == (mod(x.z, 10.0) > 5.0) )? checkCol1 : checkCol0;
				vec3 thirdColor = ( (mod(x.x, 5.0) > 2.5) == (mod(x.z, 5.0) > 2.5) )? checkCol0 : checkCol1;
				intersec.color = firstColor * secondColor * thirdColor;
				
				maskFactor = 0.1;
				roughness = 0.05;
				nt = 1.1;
			}
			
			nc = 1.0; // IOR of Air
			
			Re = calcFresnelReflectance(r.direction, n, nc, nt, ratioIoR);
			Tr = 1.0 - Re;

			vec3 reflectVec = reflect(r.direction, nl);
			vec3 glossyVec = normalize(randomCosWeightedDirectionInHemisphere(nl, seed));
			
			if (!firstTypeWasREFR && !firstTypeWasCOAT && diffuseCount == 0)
			{	
				// save intersection data for future reflection trace
				firstTypeWasCOAT = true;
				firstMask = mask * Re * maskFactor;
				firstRay = Ray( x, mix(reflectVec, glossyVec, roughness)); // create reflection ray from surface
				firstRay.direction = normalize(firstRay.direction);
				firstRay.origin += nl * uEPS_intersect;
				mask *= Tr;
			}
			else if (bounceIsSpecular && rand(seed) < Re)
			{
				mask *= maskFactor;
				r = Ray( x, mix(reflectVec, glossyVec, roughness));
				r.direction = normalize(r.direction);
				r.origin += nl * uEPS_intersect;
				continue;
			}

			diffuseCount++;

			mask *= intersec.color;
			
			bounceIsSpecular = false;

			if (firstTypeWasCOAT && diffuseCount == 1)
                        {
                                // save intersection data for future shadowray trace
				dirToLight = sampleQuadLight(x, nl, lightChoice, dirToLight, weight, seed);
				secondaryMask = mask * weight * N_LIGHTS;
                                secondaryRay = Ray( x, normalize(dirToLight) ); // create shadow ray pointed towards light
				secondaryRay.origin += nl * uEPS_intersect;

				// choose random Diffuse sample vector
				r = Ray( x, normalize(randomCosWeightedDirectionInHemisphere(nl, seed)) );
				r.origin += nl * uEPS_intersect;
				continue;
                        }
			else if ((firstTypeWasREFR || reflectionTime) && rand(seed) < 0.5)
			{
				// choose random Diffuse sample vector
				r = Ray( x, normalize(randomCosWeightedDirectionInHemisphere(nl, seed)) );
				r.origin += nl * uEPS_intersect;
				continue;
			}

			dirToLight = sampleQuadLight(x, nl, lightChoice, dirToLight, weight, seed);
			mask *= weight * N_LIGHTS;
			
			r = Ray( x, normalize(dirToLight) );
			r.origin += nl * uEPS_intersect;

			sampleLight = true;
			continue;
                        
			
		} // end if (intersec.type == COAT || intersec.type == CHECK)
		
		
	} // end for (int bounces = 0; bounces < 7; bounces++)
	

	return max(vec3(0), accumCol);

} // end vec3 CalculateRadiance( Ray r, inout uvec2 seed )



//-----------------------------------------------------------------------
void SetupScene(void)
//-----------------------------------------------------------------------
{
	vec3 z  = vec3(0);          
	vec3 L1 = vec3(1.0, 1.0, 1.0) * 2.0;// White light
	float ceilingHeight = 300.0;
	
	quads[0] = Quad( vec3( 0.0,-1.0, 0.0), vec3(-150.0, ceilingHeight,-200.0), vec3(150.0, ceilingHeight,-200.0), vec3(150.0, ceilingHeight,-25.0), vec3(-150.0, ceilingHeight,-25.0), L1, z, LIGHT);// rectangular Area Light in ceiling
	quads[1] = Quad( vec3( 0.0,-1.0, 0.0), vec3(-150.0, ceilingHeight,25.0), vec3(150.0, ceilingHeight,25.0), vec3(150.0, ceilingHeight,200.0), vec3(-150.0, ceilingHeight,200.0), L1, z, LIGHT);// rectangular Area Light in ceiling
	
	spheres[0] = Sphere(100000.0, vec3(  0.0, 100000.0, 0.0), z, vec3(1.0), CHECK);//Checkered Floor
        
	planes[0] = Plane( vec4( 0,0,1,  -300.0), z, vec3(0.7), DIFF);//Gray Wall in front of camera
	planes[1] = Plane( vec4( 0,0,-1, -300.0), z, vec3(0.7), DIFF);//Gray Wall behind camera
	planes[2] = Plane( vec4(-1,0,0,  -300.0), z, vec3(0.15,0.05,0.15), DIFF);//Purple Wall on the right
	planes[3] = Plane( vec4( 0,-1,0, -301.0), z, vec3(0.7), DIFF);//Ceiling	
}


#include <pathtracing_main>
