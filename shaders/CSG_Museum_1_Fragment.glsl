#version 300 es

precision highp float;
precision highp int;
precision highp sampler2D;

#include <pathtracing_uniforms_and_defines>

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

#include <pathtracing_quad_intersect>

#include <pathtracing_sphere_intersect>

#include <pathtracing_box_intersect>

#include <pathtracing_sample_quad_light>

//----------------------------------------------------------------------------------------------
float CSG_SphereIntersect( float rad, vec3 pos, Ray r, out vec3 n1, out vec3 n2, out float far )
//----------------------------------------------------------------------------------------------
{
	vec3 op = pos - r.origin;
	float b = dot(op, r.direction);
	float det = b * b - dot(op,op) + rad * rad;
	float result = INFINITY;
	far = INFINITY;
	
	if (det < 0.0)
		return INFINITY;
        
	det = sqrt(det);	
	float t1 = b - det;
	float t2 = b + det;
	
	if( t2 > 0.0 )
	{
		result = t2;
		far = INFINITY;
		n2 = (r.origin + r.direction * result) - pos;   
	}
	
	if( t1 > 0.0 )
	{
		result = t1;
		far = t2;
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
	float result = INFINITY;
	far = INFINITY;
	
	// quadratic equation coefficients
	float a = dot(rd2, invRad2);
	float b = 2.0*dot(ocrd, invRad2);
	float c = dot(oc2, invRad2) - 1.0;
	float det = b*b - 4.0*a*c;
	if (det < 0.0) 
		return INFINITY;
		
	det = sqrt(det);
	float t1 = (-b - det) / (2.0 * a);
	float t2 = (-b + det) / (2.0 * a);
	
	if( t2 > 0.0 )
	{
		result = t2;
		far = INFINITY;
		n2 = ((r.origin + r.direction * result) - pos) * invRad2;
	}
	
	if( t1 > 0.0 )
	{
		result = t1;
		far = t2;
		n1 = ((r.origin + r.direction * result) - pos) * invRad2;
	}
	
	return result;	
}


//------------------------------------------------------------------------------------------------------
float CSG_BoxIntersect( vec3 minCorner, vec3 maxCorner, Ray r, out vec3 n1, out vec3 n2, out float far )
//------------------------------------------------------------------------------------------------------
{
	vec3 invDir = 1.0 / r.direction;
	vec3 tmin = (minCorner - r.origin) * invDir;
	vec3 tmax = (maxCorner - r.origin) * invDir;
	
	vec3 real_min = min(tmin, tmax);
	vec3 real_max = max(tmin, tmax);
	
	float minmax = min( min(real_max.x, real_max.y), real_max.z);
	float maxmin = max( max(real_min.x, real_min.y), real_min.z);
	far = INFINITY;
	float result = INFINITY;
	
	if (minmax < maxmin || minmax < 0.0)
		return INFINITY;
	
	if (minmax > 0.0) // if we are inside the box
	{
		n2 = -sign(r.direction) * step(real_max, real_max.yzx) * step(real_max, real_max.zxy);
		far = INFINITY;
		result = minmax;
	}
	if (maxmin > 0.0) // if we are outside the box
	{
		n1 = -sign(r.direction) * step(real_min.yzx, real_min) * step(real_min.zxy, real_min);
		n2 = -sign(r.direction) * step(real_max, real_max.yzx) * step(real_max, real_max.zxy);
		far = minmax;
		result = maxmin;	
	}
	
	return result;
}

//----------------------------------------------------------------------------------
float CSG_PlaneIntersect( vec4 pla, Ray r, out vec3 n1, out vec3 n2, out float far )
//----------------------------------------------------------------------------------
{
	vec3 n = normalize(pla.xyz);
	float denom = dot(n, r.direction);
	
	// uncomment if single-sided plane is desired
	//if (denom >= 0.0)
	//	return INFINITY;
	
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
	float d = INFINITY;
	float f = INFINITY;
	float A_near, A_far;
	float B_near, B_far;
	float t = INFINITY;
	vec3 n, n2, A_n1, A_n2, B_n1, B_n2;
	
	// first, intersect all regular objects in the scene
	
	for (int i = 0; i < N_QUADS; i++)
        {
		d = QuadIntersect( quads[i].v0, quads[i].v1, quads[i].v2, quads[i].v3, quads[i].normal, r );
		if (d < t)
		{
			t = d;
			intersec.normal = (quads[i].normal);
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
	d = operation_SolidA_Minus_SolidB( A_near, A_far, B_near, B_far, A_n1, A_n2, B_n1, B_n2, n );
	if (d < t)
	{
		t = d;
		intersec.normal = normalize(n);
		intersec.emission = vec3(0);
		intersec.color = vec3(0.0,0.1,0.0);
		intersec.type = REFR;
	}
	
        
	// Blue Glass Sphere-Boxes along back wall
	A_near = CSG_SphereIntersect( 20.0, vec3(-100, 20, -200), r, A_n1, A_n2, A_far);
	B_near = CSG_BoxIntersect( vec3(-115, 6, -215), vec3(-85, 36, -185), r, B_n1, B_n2, B_far );
	d = operation_HollowA_Plus_HollowB( A_near, A_far, B_near, B_far, A_n1, A_n2, B_n1, B_n2, n );
	if (d < t)
	{
		t = d;
		intersec.normal = normalize(n);
		intersec.emission = vec3(0);
		intersec.color = vec3(0.0, 0.4, 1.0);
		intersec.type = REFR;
	}
	
	A_near = CSG_SphereIntersect( 20.0, vec3(0, 20, -200), r, A_n1, A_n2, A_far);
	B_near = CSG_BoxIntersect( vec3(-15, 6, -215), vec3(15, 36, -185), r, B_n1, B_n2, B_far );
	d = operation_HollowA_Minus_SolidB( A_near, A_far, B_near, B_far, A_n1, A_n2, B_n1, B_n2, n );
	if (d < t)
	{
		t = d;
		intersec.normal = normalize(n);
		intersec.emission = vec3(0);
		intersec.color = vec3(0.3, 0.8, 1.0);
		intersec.type = REFR;
	}
	
	A_near = CSG_SphereIntersect( 20.0, vec3(100, 20, -200), r, A_n1, A_n2, A_far);
	B_near = CSG_BoxIntersect( vec3(85, 0, -215), vec3(115, 36, -185), r, B_n1, B_n2, B_far );
	d = operation_HollowA_Overlap_HollowB( A_near, A_far, B_near, B_far, A_n1, A_n2, B_n1, B_n2, n );
	if (d < t)
	{
		t = d;
		intersec.normal = normalize(n);
		intersec.emission = vec3(0);
		intersec.color = vec3(0.1, 0.6, 1.0);
		intersec.type = SPECSUB;
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
	
	return t;
	
} // end float SceneIntersect( Ray r, inout Intersection intersec )


//-----------------------------------------------------------------------
vec3 CalculateRadiance( Ray r, inout uvec2 seed )
//-----------------------------------------------------------------------
{
	Intersection intersec;

	vec3 accumCol = vec3(0.0);
	vec3 mask = vec3(1.0);
	vec3 tdir;
	vec3 randPointOnLight, dirToLight;
        
	float weight;
	float nc, nt, Re;
	float diffuseColorBleeding = 0.2; // range: 0.0 - 0.5, chance of color bleeding between surfaces

	bool bounceIsSpecular = true;
	bool sampleLight = false;

	int diffuseCount = 0;

	Quad lightChoice;
	
	
        for (int bounces = 0; bounces < 4; bounces++)
	{
		
		float t = SceneIntersect(r, intersec);
		
		/*
		//not used in this scene because we are inside a huge room - no rays can escape
		if (t == INFINITY)
		{
                        break;
		}
		*/
		
		// if we reached something bright, don't spawn any more rays
		if (intersec.type == LIGHT)
		{	
			if (bounceIsSpecular || sampleLight)
			{
				accumCol = mask * intersec.emission;
			}
			
			break;
		}
		
		// if we reached this point and sampleLight failed to find a light above, exit early
		if (sampleLight)
		{
			break;
		}
		
		// useful data 
		vec3 n = intersec.normal;
                vec3 nl = dot(n,r.direction) <= 0.0 ? normalize(n) : normalize(n * -1.0);
		vec3 x = r.origin + r.direction * t;
		
		if (rand(seed) < 0.5)
			lightChoice = quads[0];
		else lightChoice = quads[1];
		    
                if (intersec.type == DIFF ) // Ideal DIFFUSE reflection
		{
			diffuseCount++;

			mask *= intersec.color;

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
				r.origin += r.direction;
				
				continue;
                        }
                        else
                        {
				weight = sampleQuadLight(x, nl, dirToLight, lightChoice, seed);
				mask *= clamp(weight, 0.0, 1.0);

                                r = Ray( x, dirToLight );
				r.origin += nl;

				sampleLight = true;
				continue;
                        }
		}
		
		if (intersec.type == SPEC)  // Ideal SPECULAR reflection
		{
			mask *= intersec.color;

			//turns on mirror caustics by possibly forcing bounceIsSpecular to true
			//bounceIsSpecular = (bounces < 2); 

			r = Ray( x, reflect(r.direction, nl) );
			r.origin += r.direction;

			continue;
		}
		
		if (intersec.type == REFR)  // Ideal dielectric REFRACTION
		{
			nc = 1.0; // IOR of Air
			nt = 1.5; // IOR of common Glass
			Re = calcFresnelReflectance(n, nl, r.direction, nc, nt, tdir);
			
			//turns on refractive caustics by possibly forcing bounceIsSpecular to true
			bounceIsSpecular = (bounces < 3); 

			if (rand(seed) < Re) // reflect ray from surface
			{
				r = Ray( x, reflect(r.direction, nl) );
				r.origin += r.direction;
			    	continue;	
			}
			else // transmit ray through surface
			{
				mask *= intersec.color;
				
				r = Ray(x, tdir);
				r.origin += r.direction;
				continue;
			}
			
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
				
				maskFactor = 0.05;
				roughness = 0.05;
				nt = 1.1;
			}
			
			nc = 1.0; // IOR of Air
			
			Re = calcFresnelReflectance(n, nl, r.direction, nc, nt, tdir);
			
			// choose either specular reflection or diffuse
			if ( rand(seed) < Re )
			{	
				mask *= maskFactor;
				vec3 reflectVec = reflect(r.direction, nl);
				vec3 randVec = vec3(rand(seed) * 2.0 - 1.0, rand(seed) * 2.0 - 1.0, rand(seed) * 2.0 - 1.0);
				r = Ray( x, mix( reflectVec, normalize(nl + randVec), roughness) );
				r.origin += r.direction;
				continue;	
			}

			diffuseCount++;

			mask *= intersec.color;
			
			bounceIsSpecular = false;

			if (diffuseCount == 1 && rand(seed) < diffuseColorBleeding)
                        {
                                // choose random Diffuse sample vector
				r = Ray( x, randomCosWeightedDirectionInHemisphere(nl, seed) );
				r.origin += r.direction;
				continue;
                        }
                        else
                        {
				weight = sampleQuadLight(x, nl, dirToLight, lightChoice, seed);
				mask *= clamp(weight, 0.0, 1.0);

                                r = Ray( x, dirToLight );
				r.origin += nl;
				
				sampleLight = true;
				continue;
                        }
			
		} //end if (intersec.type == COAT)

		
		if (intersec.type == SPECSUB)  // Shiny(specular) coating over Sub-Surface Scattering material
		{
			float nc = 1.0; // IOR of Air
			float nt = 1.4; // IOR of Clear Coat
			Re = calcFresnelReflectance(n, nl, r.direction, nc, nt, tdir);
			
			// choose either specular reflection or translucent subsurface scattering/transmission
			if( rand(seed) < Re )
			{
				r = Ray( x, reflect(r.direction, nl) );
				r.origin += r.direction;
				continue;
			}
			
			vec3 absorptionCoefficient = vec3(0.8, 0.4, 0.0);
			float translucentDensity = 0.4;
			float scatteringDistance = -log(rand(seed)) / translucentDensity;
			
			// transmission?
			if (scatteringDistance > t) 
			{
				mask *= exp(-absorptionCoefficient * t);

				r.origin = x;
				r.origin += r.direction * scatteringDistance;

				bounceIsSpecular = true;
				continue;
			}

			diffuseCount++;

			bounceIsSpecular = false;

			// else scattering
			mask *= exp(-absorptionCoefficient * scatteringDistance);
			
			if (diffuseCount == 1 && rand(seed) < diffuseColorBleeding)
                        {
                                // choose random Diffuse sample vector
				r = Ray( x, randomCosWeightedDirectionInHemisphere(nl, seed) );
				r.origin += r.direction * scatteringDistance;
				
				continue;
                        }
                        else
                        {
				weight = sampleQuadLight(x, nl, dirToLight, lightChoice, seed);
				mask *= clamp(weight, 0.0, 1.0);

                                r = Ray( x, dirToLight );
				r.origin += r.direction * scatteringDistance;
				
				sampleLight = true;
				continue;
                        }
			
		} // end if (intersec.type == SPECSUB)
		
		
	} // end for (int bounces = 0; bounces < 4; bounces++)
	
	return accumCol;      
}


//-----------------------------------------------------------------------
void SetupScene(void)
//-----------------------------------------------------------------------
{
	vec3 z  = vec3(0.0);          
	vec3 L1 = vec3(1.0, 1.0, 1.0) * 4.0;// White light
	vec3 L2 = vec3(1.0, 0.8, 0.2);// Yellow light
	vec3 L3 = vec3(0.2, 0.8, 1.0);// Blue light
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