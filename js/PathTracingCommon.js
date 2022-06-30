THREE.ShaderChunk[ 'pathtracing_uniforms_and_defines' ] = `
uniform sampler2D tPreviousTexture;
uniform sampler2D tBlueNoiseTexture;
uniform mat4 uCameraMatrix;
uniform vec2 uResolution;
uniform vec2 uRandomVec2;
uniform float uEPS_intersect;
uniform float uTime;
uniform float uSampleCounter;
uniform float uFrameCounter;
uniform float uULen;
uniform float uVLen;
uniform float uApertureSize;
uniform float uFocusDistance;
uniform float uPreviousSampleCount;
uniform bool uCameraIsMoving;
uniform bool uUseOrthographicCamera;

in vec2 vUv;

#define PI               3.14159265358979323
#define TWO_PI           6.28318530717958648
#define FOUR_PI          12.5663706143591729
#define ONE_OVER_PI      0.31830988618379067
#define ONE_OVER_TWO_PI  0.15915494309
#define ONE_OVER_FOUR_PI 0.07957747154594767
#define PI_OVER_TWO      1.57079632679489662
#define ONE_OVER_THREE   0.33333333333333333
#define E                2.71828182845904524
#define INFINITY         1000000.0
#define QUADRIC_EPSILON  0.00001
#define SPOT_LIGHT -2
#define POINT_LIGHT -1
#define LIGHT 0
#define DIFF 1
#define REFR 2
#define SPEC 3
#define COAT 4
#define CARCOAT 5
#define TRANSLUCENT 6
#define SPECSUB 7
#define CHECK 8
#define WATER 9
#define PBR_MATERIAL 10
#define WOOD 11
#define SEAFLOOR 12
#define TERRAIN 13
#define CLOTH 14
#define LIGHTWOOD 15
#define DARKWOOD 16
#define PAINTING 17
#define METALCOAT 18
`;

THREE.ShaderChunk[ 'pathtracing_skymodel_defines' ] = `
#define TURBIDITY 1.0
#define RAYLEIGH_COEFFICIENT 3.0
#define MIE_COEFFICIENT 0.03
#define MIE_DIRECTIONAL_G 0.76
// constants for atmospheric scattering
#define THREE_OVER_SIXTEENPI 0.05968310365946075
#define ONE_OVER_FOURPI 0.07957747154594767
// wavelength of used primaries, according to preetham
#define LAMBDA vec3( 680E-9, 550E-9, 450E-9 )
#define TOTAL_RAYLEIGH vec3( 5.804542996261093E-6, 1.3562911419845635E-5, 3.0265902468824876E-5 )
// mie stuff
// K coefficient for the primaries
#define K vec3(0.686, 0.678, 0.666)
#define MIE_V 4.0
#define MIE_CONST vec3( 1.8399918514433978E14, 2.7798023919660528E14, 4.0790479543861094E14 )
// optical length at zenith for molecules
#define RAYLEIGH_ZENITH_LENGTH 8400.0
#define MIE_ZENITH_LENGTH 1250.0
#define UP_VECTOR vec3(0.0, 1.0, 0.0)
#define SUN_POWER 1000.0
// 66 arc seconds -> degrees, and the cosine of that
#define SUN_ANGULAR_DIAMETER_COS 0.9998 //0.9999566769
#define CUTOFF_ANGLE 1.6110731556870734
#define STEEPNESS 1.5
`;


THREE.ShaderChunk[ 'pathtracing_plane_intersect' ] = `
//-----------------------------------------------------------------------
float PlaneIntersect( vec4 pla, vec3 rayOrigin, vec3 rayDirection )
//-----------------------------------------------------------------------
{
	vec3 n = pla.xyz;
	float denom = dot(n, rayDirection);
	
        vec3 pOrO = (pla.w * n) - rayOrigin; 
        float result = dot(pOrO, n) / denom;
	return (result > 0.0) ? result : INFINITY;
}
`;

THREE.ShaderChunk[ 'pathtracing_single_sided_plane_intersect' ] = `
//----------------------------------------------------------------------------
float SingleSidedPlaneIntersect( vec4 pla, vec3 rayOrigin, vec3 rayDirection )
//----------------------------------------------------------------------------
{
	vec3 n = pla.xyz;
	float denom = dot(n, rayDirection);
	if (denom > 0.0) return INFINITY;
	
        vec3 pOrO = (pla.w * n) - rayOrigin; 
        float result = dot(pOrO, n) / denom;
	return (result > 0.0) ? result : INFINITY;
}
`;

THREE.ShaderChunk[ 'pathtracing_disk_intersect' ] = `
//-------------------------------------------------------------------------------------------
float DiskIntersect( float radius, vec3 pos, vec3 normal, vec3 rayOrigin, vec3 rayDirection )
//-------------------------------------------------------------------------------------------
{
	vec3 pOrO = pos - rayOrigin;
	float denom = dot(-normal, rayDirection);
	// use the following for one-sided disk
	//if (denom <= 0.0) return INFINITY;
	
        float result = dot(pOrO, -normal) / denom;
	if (result < 0.0) return INFINITY;
        vec3 intersectPos = rayOrigin + rayDirection * result;
	vec3 v = intersectPos - pos;
	float d2 = dot(v,v);
	float radiusSq = radius * radius;
	if (d2 > radiusSq)
		return INFINITY;
		
	return result;
}
`;

THREE.ShaderChunk[ 'pathtracing_rectangle_intersect' ] = `
//----------------------------------------------------------------------------------------------------------------
float RectangleIntersect( vec3 pos, vec3 normal, float radiusU, float radiusV, vec3 rayOrigin, vec3 rayDirection )
//----------------------------------------------------------------------------------------------------------------
{
	float dt = dot(-normal, rayDirection);
	// use the following for one-sided rectangle
	if (dt < 0.0) return INFINITY;

	float t = dot(-normal, pos - rayOrigin) / dt;
	if (t < 0.0) return INFINITY;
	
	vec3 hit = rayOrigin + rayDirection * t;
	vec3 vi = hit - pos;
	vec3 U = normalize( cross( abs(normal.y) < 0.9 ? vec3(0, 1, 0) : vec3(0, 0, 1), normal ) );
	vec3 V = cross(normal, U);
	return (abs(dot(U, vi)) > radiusU || abs(dot(V, vi)) > radiusV) ? INFINITY : t;
}
`;

THREE.ShaderChunk[ 'pathtracing_slab_intersect' ] = `
//---------------------------------------------------------------------------------------------
float SlabIntersect( float radius, vec3 normal, vec3 rayOrigin, vec3 rayDirection, out vec3 n )
//---------------------------------------------------------------------------------------------
{
	n = dot(normal, rayDirection) < 0.0 ? normal : -normal;
	float rad = dot(rayOrigin, n) > radius ? radius : -radius; 
	float denom = dot(n, rayDirection);
	vec3 pOrO = (rad * n) - rayOrigin; 
	float t = dot(pOrO, n) / denom;
	return t > 0.0 ? t : INFINITY;
}
`;

THREE.ShaderChunk[ 'pathtracing_sphere_intersect' ] = `
/* bool solveQuadratic(float A, float B, float C, out float t0, out float t1)
{
	float discrim = B * B - 4.0 * A * C;
    
	if (discrim < 0.0)
        	return false;
    
	float rootDiscrim = sqrt(discrim);
	float Q = (B > 0.0) ? -0.5 * (B + rootDiscrim) : -0.5 * (B - rootDiscrim); 
	// float t_0 = Q / A; 
	// float t_1 = C / Q;
	// t0 = min( t_0, t_1 );
	// t1 = max( t_0, t_1 );
	t1 = Q / A; 
	t0 = C / Q;
	
	return true;
} */
// optimized algorithm for solving quadratic equations developed by Dr. Po-Shen Loh -> https://youtu.be/XKBX0r3J-9Y
// Adapted to root finding (ray t0/t1) for all quadric shapes (sphere, ellipsoid, cylinder, cone, etc.) by Erich Loftis
void solveQuadratic(float A, float B, float C, out float t0, out float t1)
{
	float invA = 1.0 / A;
	B *= invA;
	C *= invA;
	float neg_halfB = -B * 0.5;
	float u2 = neg_halfB * neg_halfB - C;
	float u = u2 < 0.0 ? neg_halfB = 0.0 : sqrt(u2);
	t0 = neg_halfB - u;
	t1 = neg_halfB + u;
}

//-----------------------------------------------------------------------------
float SphereIntersect( float rad, vec3 pos, vec3 rayOrigin, vec3 rayDirection )
//-----------------------------------------------------------------------------
{
	float t0, t1;
	vec3 L = rayOrigin - pos;
	float a = dot( rayDirection, rayDirection );
	float b = 2.0 * dot( rayDirection, L );
	float c = dot( L, L ) - (rad * rad);
	solveQuadratic(a, b, c, t0, t1);
	return t0 > 0.0 ? t0 : t1 > 0.0 ? t1 : INFINITY;
}
`;

THREE.ShaderChunk[ 'pathtracing_unit_bounding_sphere_intersect' ] = `

float UnitBoundingSphereIntersect( vec3 ro, vec3 rd, out bool insideSphere )
{
	float t0, t1;
	float a = dot(rd, rd);
	float b = 2.0 * dot(rd, ro);
	float c = dot(ro, ro) - (1.01 * 1.01); // - (rad * rad) = - (1.0 * 1.0) = - 1.0 
	solveQuadratic(a, b, c, t0, t1);
	if (t0 > 0.0)
	{
		insideSphere = false;
		return t0;
	}
	if (t1 > 0.0)
	{
		insideSphere = true;
		return t1;
	}

	return INFINITY;
}
`;

THREE.ShaderChunk[ 'pathtracing_quadric_intersect' ] = `

/*
The Quadric shape Parameters (A-J) are stored in a 4x4 matrix (a 'mat4' in GLSL).
Following the technique found in the 2004 paper, "Ray Tracing Arbitrary Objects on the GPU" by Wood, et al.,
the parameter layout is:
mat4 shape = mat4(A, B, C, D,
		  B, E, F, G,
		  C, F, H, I,
		  D, G, I, J);
*/

float QuadricIntersect(mat4 shape, vec4 ro, vec4 rd) 
{
	vec4 rda = shape * rd;
    	vec4 roa = shape * ro;
	vec3 hitPoint;
    
    	// quadratic coefficients
    	float a = dot(rd, rda);
    	float b = dot(ro, rda) + dot(rd, roa);
    	float c = dot(ro, roa);
	
	float t0, t1;
	solveQuadratic(a, b, c, t0, t1);

	// restrict valid intersections to be inside unit bounding box vec3(-1,-1,-1) to vec3(+1,+1,+1)
	hitPoint = ro.xyz + rd.xyz * t0;
	if ( t0 > 0.0 && all(greaterThanEqual(hitPoint, vec3(-1.0 - QUADRIC_EPSILON))) && all(lessThanEqual(hitPoint, vec3(1.0 + QUADRIC_EPSILON))) )
		return t0;
		
	hitPoint = ro.xyz + rd.xyz * t1;
	if ( t1 > 0.0 && all(greaterThanEqual(hitPoint, vec3(-1.0 - QUADRIC_EPSILON))) && all(lessThanEqual(hitPoint, vec3(1.0 + QUADRIC_EPSILON))) )
		return t1;
	
	return INFINITY;
}

`;

THREE.ShaderChunk[ 'pathtracing_sphere_csg_intersect' ] = `
//------------------------------------------------------------------------------------------------------------
void Sphere_CSG_Intersect( vec3 ro, vec3 rd, out float t0, out float t1, out vec3 n0, out vec3 n1 )
//------------------------------------------------------------------------------------------------------------
{
	vec3 hit;
	// implicit equation of a unit (radius of 1) sphere:
	// x^2 + y^2 + z^2 - 1 = 0
	float a = dot(rd, rd);
	float b = 2.0 * dot(rd, ro);
	float c = dot(ro, ro) - 1.0;
	solveQuadratic(a, b, c, t0, t1);
	hit = ro + rd * t0;
	n0 = vec3(2.0 * hit.x, 2.0 * hit.y, 2.0 * hit.z);
	hit = ro + rd * t1;
	n1 = vec3(2.0 * hit.x, 2.0 * hit.y, 2.0 * hit.z);
}
`;

THREE.ShaderChunk[ 'pathtracing_cylinder_csg_intersect' ] = `
//------------------------------------------------------------------------------------------------------------
void Cylinder_CSG_Intersect( vec3 ro, vec3 rd, out float t0, out float t1, out vec3 n0, out vec3 n1 )
//------------------------------------------------------------------------------------------------------------
{
	vec3 hit;
	float d0, d1;
	d0 = d1 = 0.0;
	vec3 dn0, dn1;
	// implicit equation of a unit (radius of 1) cylinder, extending infinitely in the +Y and -Y directions:
	// x^2 + z^2 - 1 = 0
	float a = (rd.x * rd.x + rd.z * rd.z);
    	float b = 2.0 * (rd.x * ro.x + rd.z * ro.z);
    	float c = (ro.x * ro.x + ro.z * ro.z) - 1.0;
	solveQuadratic(a, b, c, t0, t1);
	hit = ro + rd * t0;
	t0 = (abs(hit.y) > 1.0) ? 0.0 : t0;
	n0 = vec3(2.0 * hit.x, 0.0, 2.0 * hit.z);
	hit = ro + rd * t1;
	t1 = (abs(hit.y) > 1.0) ? 0.0 : t1;
	n1 = vec3(2.0 * hit.x, 0.0, 2.0 * hit.z);
	// intersect top and bottom unit-radius disk caps
	if (rd.y < 0.0)
	{
		d0 = (ro.y - 1.0) / -rd.y;
		dn0 = vec3(0,1,0);
		d1 = (ro.y + 1.0) / -rd.y;
		dn1 = vec3(0,-1,0);
	}
	else
	{
		d1 = (ro.y - 1.0) / -rd.y;
		dn1 = vec3(0,1,0);
		d0 = (ro.y + 1.0) / -rd.y;
		dn0 = vec3(0,-1,0);
	}
	
	hit = ro + rd * d0;
	if (hit.x * hit.x + hit.z * hit.z <= 1.0) // unit radius disk
	{
		t0 = d0;
		n0 = dn0;
	}
	hit = ro + rd * d1;
	if (hit.x * hit.x + hit.z * hit.z <= 1.0) // unit radius disk
	{
		t1 = d1;
		n1 = dn1;
	}
}
`;

THREE.ShaderChunk[ 'pathtracing_cone_csg_intersect' ] = `
//------------------------------------------------------------------------------------------------------------
void Cone_CSG_Intersect( float k, vec3 ro, vec3 rd, out float t0, out float t1, out vec3 n0, out vec3 n1 )
//------------------------------------------------------------------------------------------------------------
{
	vec3 hit;
	float d0, d1, dr0, dr1;
	d0 = d1 = dr0 = dr1 = 0.0;
	vec3 dn0, dn1;
	// implicit equation of a double-cone extending infinitely in +Y and -Y directions
	// x^2 + z^2 - y^2 = 0
	// code below cuts off top cone, leaving bottom cone with apex at the top (+1.0), and circular base (radius of 1) at the bottom (-1.0)
	
	// valid range for k: 0.01 to 1.0 (1.0 being the default for cone with a sharp, pointed apex)
	k = clamp(k, 0.01, 1.0);
	
	float j = 1.0 / k;
	float h = j * 2.0 - 1.0;		   // (k * 0.25) makes the normal cone's bottom circular base have a unit radius of 1.0
	float a = j * rd.x * rd.x + j * rd.z * rd.z - (k * 0.25) * rd.y * rd.y;
    	float b = 2.0 * (j * rd.x * ro.x + j * rd.z * ro.z - (k * 0.25) * rd.y * (ro.y - h));
    	float c = j * ro.x * ro.x + j * ro.z * ro.z - (k * 0.25) * (ro.y - h) * (ro.y - h);
	solveQuadratic(a, b, c, t0, t1);
	
	hit = ro + rd * t0;
	t0 = (abs(hit.y) > 1.0) ? 0.0 : t0; // invalidate t0 if it's outside truncated cone's height bounds
	n0 = vec3(2.0 * hit.x * j, 2.0 * (h - hit.y) * (k * 0.25), 2.0 * hit.z * j);
	
	hit = ro + rd * t1;
	t1 = (abs(hit.y) > 1.0) ? 0.0 : t1; // invalidate t1 if it's outside truncated cone's height bounds
	n1 = vec3(2.0 * hit.x * j, 2.0 * (h - hit.y) * (k * 0.25), 2.0 * hit.z * j);
	// since the infinite double-cone is artificially cut off, if t0 intersection was invalidated, try t1
	if (t0 == 0.0)
	{
		t0 = t1;
		n0 = n1;
	}
	// intersect top and bottom disk caps
	if (rd.y < 0.0)
	{
		d0 = (ro.y - 1.0) / -rd.y;
		dn0 = vec3(0,1,0);
		d1 = (ro.y + 1.0) / -rd.y;
		dn1 = vec3(0,-1,0);
		dr0 = (1.0 - k) * (1.0 - k); // top cap's size is relative to k
		dr1 = 1.0; // bottom cap is unit radius
	}
	else
	{
		d1 = (ro.y - 1.0) / -rd.y;
		dn1 = vec3(0,1,0);
		d0 = (ro.y + 1.0) / -rd.y;
		dn0 = vec3(0,-1,0);
		dr0 = 1.0; // bottom cap is unit radius
		dr1 = (1.0 - k) * (1.0 - k);// top cap's size is relative to k
	}
	hit = ro + rd * d0;
	if (hit.x * hit.x + hit.z * hit.z <= dr0)
	{
		t1 = t0;
		n1 = n0;
		t0 = d0;
		n0 = dn0;
	}
	hit = ro + rd * d1;
	if (hit.x * hit.x + hit.z * hit.z <= dr1)
	{
		t1 = d1;
		n1 = dn1;
	}
}
`;

THREE.ShaderChunk[ 'pathtracing_conicalprism_csg_intersect' ] = `
//------------------------------------------------------------------------------------------------------------
void ConicalPrism_CSG_Intersect( float k, vec3 ro, vec3 rd, out float t0, out float t1, out vec3 n0, out vec3 n1 )
//------------------------------------------------------------------------------------------------------------
{
	vec3 hit;
	float d0, d1, dr0, dr1;
	d0 = d1 = dr0 = dr1 = 0.0;
	vec3 dn0, dn1;
	// start with implicit equation of a double-cone extending infinitely in +Y and -Y directions
	// x^2 + z^2 - y^2 = 0
	// To obtain a conical prism along the Z axis, the Z component is simply removed, leaving:
	// x^2 - y^2 = 0
	// code below cuts off top cone of the double-cone, leaving bottom cone with apex at the top (+1.0), and base (radius of 1) at the bottom (-1.0)
	
	// valid range for k: 0.01 to 1.0 (1.0 being the default for cone with a sharp, pointed apex)
	k = clamp(k, 0.01, 1.0);
	
	float j = 1.0 / k;
	float h = j * 2.0 - 1.0;		   // (k * 0.25) makes the normal cone's bottom circular base have a unit radius of 1.0
	float a = j * rd.x * rd.x - (k * 0.25) * rd.y * rd.y;
    	float b = 2.0 * (j * rd.x * ro.x - (k * 0.25) * rd.y * (ro.y - h));
    	float c = j * ro.x * ro.x - (k * 0.25) * (ro.y - h) * (ro.y - h);
	solveQuadratic(a, b, c, t0, t1);
	hit = ro + rd * t0;
	t0 = (abs(hit.y) > 1.0 || abs(hit.z) > 1.0) ? 0.0 : t0; // invalidate t0 if it's outside unit radius bounds
	n0 = vec3(2.0 * hit.x * j, 2.0 * (hit.y - h) * -(k * 0.25), 0.0);
	
	hit = ro + rd * t1;
	t1 = (abs(hit.y) > 1.0 || abs(hit.z) > 1.0) ? 0.0 : t1; // invalidate t1 if it's outside unit radius bounds
	n1 = vec3(2.0 * hit.x * j, 2.0 * (hit.y - h) * -(k * 0.25), 0.0);
	
	// since the infinite double-cone shape is artificially cut off at the top and bottom,
	// if t0 intersection was invalidated above, try t1
	if (t0 == 0.0)
	{
		t0 = t1;
		n0 = n1;
	}
	// intersect top and bottom base rectangles
	if (rd.y < 0.0)
	{
		d0 = (ro.y - 1.0) / -rd.y;
		dn0 = vec3(0,1,0);
		d1 = (ro.y + 1.0) / -rd.y;
		dn1 = vec3(0,-1,0);
		dr0 = 1.0 - (k); // top cap's size is relative to k
		dr1 = 1.0; // bottom cap is unit radius
	}
	else
	{
		d1 = (ro.y - 1.0) / -rd.y;
		dn1 = vec3(0,1,0);
		d0 = (ro.y + 1.0) / -rd.y;
		dn0 = vec3(0,-1,0);
		dr0 = 1.0; // bottom cap is unit radius
		dr1 = 1.0 - (k);// top cap's size is relative to k
	}
	hit = ro + rd * d0;
	if (abs(hit.x) <= dr0 && abs(hit.z) <= 1.0)
	{
		t1 = t0;
		n1 = n0;
		t0 = d0;
		n0 = dn0;
	}
	hit = ro + rd * d1;
	if (abs(hit.x) <= dr1 && abs(hit.z) <= 1.0)
	{
		t1 = d1;
		n1 = dn1;
	}
	// intersect conical-shaped front and back wall pieces
	if (rd.z < 0.0)
	{
		d0 = (ro.z - 1.0) / -rd.z;
		dn0 = vec3(0,0,1);
		d1 = (ro.z + 1.0) / -rd.z;
		dn1 = vec3(0,0,-1);
	}
	else
	{
		d1 = (ro.z - 1.0) / -rd.z;
		dn1 = vec3(0,0,1);
		d0 = (ro.z + 1.0) / -rd.z;
		dn0 = vec3(0,0,-1);
	}
	
	hit = ro + rd * d0;
	if (abs(hit.x) <= 1.0 && abs(hit.y) <= 1.0 && (j * hit.x * hit.x - k * 0.25 * (hit.y - h) * (hit.y - h)) <= 0.0) // y is a quadratic (conical) function of x
	{
		if (t0 != 0.0)
		{
			t1 = t0;
			n1 = n0;
		}
		
		t0 = d0;
		n0 = dn0;
	}
	hit = ro + rd * d1;
	if (abs(hit.x) <= 1.0 && abs(hit.y) <= 1.0 && (j * hit.x * hit.x - k * 0.25 * (hit.y - h) * (hit.y - h)) <= 0.0) // y is a quadratic (conical) function of x
	{
		t1 = d1;
		n1 = dn1;
	}
	
}
`;

THREE.ShaderChunk[ 'pathtracing_paraboloid_csg_intersect' ] = `
//------------------------------------------------------------------------------------------------------------
void Paraboloid_CSG_Intersect( vec3 ro, vec3 rd, out float t0, out float t1, out vec3 n0, out vec3 n1 )
//------------------------------------------------------------------------------------------------------------
{
	vec3 hit;
	float d = 0.0;
	vec3 dn;
	// implicit equation of a paraboloid (upside down rounded-v shape extending infinitely downward in the -Y direction):
	// x^2 + z^2 + y = 0
	// code below centers the paraboloid so that its rounded apex is at the top (+1.0) and 
	//   its circular base is of unit radius (1) and is located at the bottom (-1.0) where the shape is truncated 
	
	float k = 0.5;
	float a = rd.x * rd.x + rd.z * rd.z;
    	float b = 2.0 * (rd.x * ro.x + rd.z * ro.z) + k * rd.y;
    	float c = ro.x * ro.x + ro.z * ro.z + k * (ro.y - 1.0);
	solveQuadratic(a, b, c, t0, t1);
	hit = ro + rd * t0;
	t0 = (abs(hit.y) > 1.0) ? 0.0 : t0; // invalidate t0 if it's outside unit radius bounds
	n0 = vec3(2.0 * hit.x, 1.0 * k, 2.0 * hit.z);
	hit = ro + rd * t1;
	t1 = (abs(hit.y) > 1.0) ? 0.0 : t1; // invalidate t1 if it's outside unit radius bounds
	n1 = vec3(2.0 * hit.x, 1.0 * k, 2.0 * hit.z);
	// since the infinite paraboloid is artificially cut off at the bottom,
	// if t0 intersection was invalidated, try t1
	if (t0 == 0.0)
	{
		t0 = t1;
		n0 = n1;
	}
	
	// now intersect unit-radius disk located at bottom base opening of unit paraboloid shape
	d = (ro.y + 1.0) / -rd.y;
	hit = ro + rd * d;
	if (hit.x * hit.x + hit.z * hit.z <= 1.0) // disk with unit radius
	{
		if (rd.y < 0.0)
		{
			t1 = d;
			n1 = vec3(0,-1,0);
		}
		else
		{
			t1 = t0;
			n1 = n0;
			t0 = d;
			n0 = vec3(0,-1,0);
		}
	}
}
`;

THREE.ShaderChunk[ 'pathtracing_parabolicprism_csg_intersect' ] = `
//------------------------------------------------------------------------------------------------------------
void ParabolicPrism_CSG_Intersect( vec3 ro, vec3 rd, out float t0, out float t1, out vec3 n0, out vec3 n1 )
//------------------------------------------------------------------------------------------------------------
{
	vec3 hit;
	float d, d0, d1;
	d = d0 = d1 = 0.0;
	vec3 dn, dn0, dn1;
	// start with implicit equation of a paraboloid (upside down rounded-v shape extending infinitely downward in the -Y direction):
	// x^2 + z^2 + y = 0
	// To obtain a parabolic prism along the Z axis, the Z component is simply removed, leaving:
	// x^2 + y = 0
	// code below centers the parabolic prism so that its rounded apex is at the top (+1.0) and 
	//   its square base is of unit radius (1) and is located at the bottom (-1.0) where the infinite parabola shape is truncated also
	
	float k = 0.5; // k:0.5 narrows the parabola to ensure that when the lower portion of the parabola reaches the cut-off at the base, it is 1 unit wide
	float a = rd.x * rd.x;
    	float b = 2.0 * (rd.x * ro.x) + k * rd.y;
    	float c = ro.x * ro.x + k * (ro.y - 1.0);
	solveQuadratic(a, b, c, t0, t1);
	hit = ro + rd * t0;
	t0 = (hit.y < -1.0 || abs(hit.z) > 1.0) ? 0.0 : t0; // invalidate t0 if it's outside unit radius bounds
	n0 = vec3(2.0 * hit.x, 1.0 * k, 0.0);
	
	hit = ro + rd * t1;
	t1 = (hit.y < -1.0 || abs(hit.z) > 1.0) ? 0.0 : t1; // invalidate t1 if it's outside unit radius bounds
	n1 = vec3(2.0 * hit.x, 1.0 * k, 0.0);
	
	// since the infinite parabolic shape is artificially cut off at the bottom,
	// if t0 intersection was invalidated above, try t1
	if (t0 == 0.0)
	{
		t0 = t1;
		n0 = n1;
	}
	
	// intersect unit-radius square located at bottom opening of unit paraboloid shape
	d = (ro.y + 1.0) / -rd.y;
	hit = ro + rd * d;
	if (abs(hit.x) <= 1.0 && abs(hit.z) <= 1.0) // square with unit radius
	{
		if (rd.y < 0.0)
		{
			t1 = d;
			n1 = vec3(0,-1,0);
		}
		else
		{
			t1 = t0;
			n1 = n0;
			t0 = d;
			n0 = vec3(0,-1,0);
		}
	}
	// intersect parabola-shaped front and back wall pieces
	if (rd.z < 0.0)
	{
		d0 = (ro.z - 1.0) / -rd.z;
		dn0 = vec3(0,0,1);
		d1 = (ro.z + 1.0) / -rd.z;
		dn1 = vec3(0,0,-1);
	}
	else
	{
		d1 = (ro.z - 1.0) / -rd.z;
		dn1 = vec3(0,0,1);
		d0 = (ro.z + 1.0) / -rd.z;
		dn0 = vec3(0,0,-1);
	}
	
	hit = ro + rd * d0;
	if (hit.y >= -1.0 && (hit.x * hit.x + k * (hit.y - 1.0)) <= 0.0) // y is a parabolic function of x
	{
		t0 = d0;
		n0 = dn0;
	}
	hit = ro + rd * d1;
	if (hit.y >= -1.0 && (hit.x * hit.x + k * (hit.y - 1.0)) <= 0.0) // y is a parabolic function of x
	{
		t1 = d1;
		n1 = dn1;
	}
}
`;

THREE.ShaderChunk[ 'pathtracing_hyperboloid1sheet_csg_intersect' ] = `
//------------------------------------------------------------------------------------------------------------
void Hyperboloid1Sheet_CSG_Intersect( float k, vec3 ro, vec3 rd, out float t0, out float t1, out vec3 n0, out vec3 n1 )
//------------------------------------------------------------------------------------------------------------
{
	vec3 hit;
	float d0, d1, dr0, dr1;
	d0 = d1 = dr0 = dr1 = 0.0;
	vec3 dn0, dn1;
	// implicit equation of a hyperboloid of 1 sheet (hourglass shape extending infinitely in the +Y and -Y directions):
	// x^2 + z^2 - y^2 - 1 = 0
	// for CSG purposes, we artificially truncate the hyperboloid at the middle, so that only the top half of the hourglass remains with added top/bottom caps...
	// This way, the total number of possible intersections will be 2 max (t0/t1), rather than possibly 4 (if we left it as a full hourglass with added top/bottom caps)
	
	ro.y += 0.5; // this places the top-to-middle portion of the shape closer to its own origin, so that it rotates smoothly around its own middle. 
	
	// conservative range of k: 1 to 100
	float j = k - 1.0;
	float a = k * rd.x * rd.x + k * rd.z * rd.z - j * rd.y * rd.y;
	float b = 2.0 * (k * rd.x * ro.x + k * rd.z * ro.z - j * rd.y * ro.y);
	float c = (k * ro.x * ro.x + k * ro.z * ro.z - j * ro.y * ro.y) - 1.0;
	solveQuadratic(a, b, c, t0, t1);
	hit = ro + rd * t0;
	t0 = (hit.y > 1.0 || hit.y < 0.0) ? 0.0 : t0; // invalidate t0 if it's outside unit radius bounds of top half
	n0 = vec3(2.0 * hit.x * k, 2.0 * -hit.y * j, 2.0 * hit.z * k);
	hit = ro + rd * t1;
	t1 = (hit.y > 1.0 || hit.y < 0.0) ? 0.0 : t1; // invalidate t1 if it's outside unit radius bounds of top half
	n1 = vec3(2.0 * hit.x * k, 2.0 * -hit.y * j, 2.0 * hit.z * k);
	// since the infinite hyperboloid is artificially cut off at the top and bottom so that it has a unit radius top cap,
	// if t0 intersection was invalidated, try t1
	if (t0 == 0.0)
	{
		t0 = t1;
		n0 = n1;
	}
	if (rd.y < 0.0)
	{
		d0 = (ro.y - 1.0) / -rd.y;
		dn0 = vec3(0,1,0);
		d1 = (ro.y + 0.0) / -rd.y;
		dn1 = vec3(0,-1,0);
		dr0 = 1.0; // top cap is unit radius
		dr1 = 1.0 / k; // bottom cap is inverse size of k (smaller than 1)
	}
	else
	{
		d1 = (ro.y - 1.0) / -rd.y;
		dn1 = vec3(0,1,0);
		d0 = (ro.y + 0.0) / -rd.y;
		dn0 = vec3(0,-1,0);
		dr0 = 1.0 / k; // bottom cap is inverse size of k (smaller than 1)
		dr1 = 1.0; // top cap is unit radius
	}
	
	hit = ro + rd * d0;
	if (hit.x * hit.x + hit.z * hit.z <= dr0)
	{
		t1 = t0;
		n1 = n0;
		t0 = d0;
		n0 = dn0;
	}
	hit = ro + rd * d1;
	if (hit.x * hit.x + hit.z * hit.z <= dr1)
	{
		t1 = d1;
		n1 = dn1;
	}
}
`;

THREE.ShaderChunk[ 'pathtracing_hyperboloid2sheets_csg_intersect' ] = `
//------------------------------------------------------------------------------------------------------------
void Hyperboloid2Sheets_CSG_Intersect( float k, vec3 ro, vec3 rd, out float t0, out float t1, out vec3 n0, out vec3 n1 )
//------------------------------------------------------------------------------------------------------------
{
	vec3 hit;
	float d = 0.0;
	vec3 dn;
	// implicit equation of a hyperboloid of 2 sheets (2 rounded v shapes that are mirrored and pointing at each other)
	// -x^2 - z^2 + y^2 - 1 = 0
	// for CSG purposes, we artificially truncate the hyperboloid at the middle, so that only 1 sheet (the top sheet) of the 2 mirrored sheets remains...
	// This way, the total number of possible intersections will be 2 max (t0/t1), rather than possibly 4 (if we left it as 2 full sheets with added top/bottom caps)
	
	ro.y += 0.5; // this places the top-to-middle portion of the shape closer to its own origin, so that it rotates smoothly around its own middle. 
	
	// conservative range of k: 1 to 100
	float j = k + 1.0;
	float a = -k * rd.x * rd.x - k * rd.z * rd.z + j * rd.y * rd.y;
	float b = 2.0 * (-k * rd.x * ro.x - k * rd.z * ro.z + j * rd.y * ro.y);
	float c = (-k * ro.x * ro.x - k * ro.z * ro.z + j * ro.y * ro.y) - 1.0;
	solveQuadratic(a, b, c, t0, t1);
	hit = ro + rd * t0;
	t0 = (hit.y > 1.0 || hit.y < 0.0) ? 0.0 : t0; // invalidate t0 if it's outside unit radius bounds of top half
	n0 = vec3(2.0 * -hit.x * k, 2.0 * hit.y * j, 2.0 * -hit.z * k);
	hit = ro + rd * t1;
	t1 = (hit.y > 1.0 || hit.y < 0.0) ? 0.0 : t1; // invalidate t1 if it's outside unit radius bounds of top half
	n1 = vec3(2.0 * -hit.x * k, 2.0 * hit.y * j, 2.0 * -hit.z * k);
	// since the infinite hyperboloid is artificially cut off at the top and bottom so that it has a unit radius top cap,
	// if t0 intersection was invalidated, try t1
	if (t0 == 0.0)
	{
		t0 = t1;
		n0 = n1;
	}
	// intersect unit-radius disk located at top opening of unit hyperboloid shape
	d = (ro.y - 1.0) / -rd.y;
	hit = ro + rd * d;
	if (hit.x * hit.x + hit.z * hit.z <= 1.0) // disk with unit radius
	{
		if (rd.y > 0.0)
		{
			t1 = d;
			n1 = vec3(0,1,0);
		}
		else
		{
			t1 = t0;
			n1 = n0;
			t0 = d;
			n0 = vec3(0,1,0);
		}
	}
	
}
`;

THREE.ShaderChunk[ 'pathtracing_hyperbolicprism1sheet_csg_intersect' ] = `
//------------------------------------------------------------------------------------------------------------
void HyperbolicPrism1Sheet_CSG_Intersect( float k, vec3 ro, vec3 rd, out float t0, out float t1, out vec3 n0, out vec3 n1 )
//------------------------------------------------------------------------------------------------------------
{
	vec3 hit;
	float d0, d1, dr0, dr1;
	d0 = d1 = dr0 = dr1 = 0.0;
	vec3 dn0, dn1;
	// start with the implicit equation of a hyperboloid of 1 sheet (hourglass shape extending infinitely in the +Y and -Y directions):
	// x^2 + z^2 - y^2 - 1 = 0
	// To obtain a hyperbolic prism along the Z axis, the Z component is simply removed, leaving:
	// x^2 - y^2 - 1 = 0
	// for CSG purposes, we artificially truncate the hyperbolic prism at the middle, so that only the top half of the hourglass remains with added top/bottom caps...
	// This way, the total number of possible intersections will be 2 max (t0/t1), rather than possibly 4 (if we left it as a full hourglass with added top/bottom caps)
	
	ro.y += 0.5; // this places the top-to-middle portion of the shape closer to its own origin, so that it rotates smoothly around its own middle. 
	
	// conservative range of k: 1 to 100
	float j = k - 1.0;
	float a = k * rd.x * rd.x - j * rd.y * rd.y;
	float b = 2.0 * (k * rd.x * ro.x - j * rd.y * ro.y);
	float c = (k * ro.x * ro.x - j * ro.y * ro.y) - 1.0;
	solveQuadratic(a, b, c, t0, t1);
	hit = ro + rd * t0;
	t0 = (hit.y > 1.0 || hit.y < 0.0 || abs(hit.z) > 1.0) ? 0.0 : t0; // invalidate t0 if it's outside unit radius bounds of top half
	n0 = vec3(2.0 * hit.x * k, 2.0 * -hit.y * j, 0.0);
	hit = ro + rd * t1;
	t1 = (hit.y > 1.0 || hit.y < 0.0 || abs(hit.z) > 1.0) ? 0.0 : t1; // invalidate t1 if it's outside unit radius bounds of top half
	n1 = vec3(2.0 * hit.x * k, 2.0 * -hit.y * j, 0.0);
	// since the infinite hyperbolic shape is artificially cut off at the top and bottom so that it has a unit radius top cap,
	// if t0 intersection was invalidated, try t1
	if (t0 == 0.0)
	{
		t0 = t1;
		n0 = n1;
	}
	// intersect top and bottom base rectangles
	if (rd.y < 0.0)
	{
		d0 = (ro.y - 1.0) / -rd.y;
		dn0 = vec3(0,1,0);
		d1 = (ro.y + 0.0) / -rd.y;
		dn1 = vec3(0,-1,0);
		dr0 = 1.0; // top cap is unit radius
		dr1 = 1.0 / sqrt(abs(k)); // bottom cap is related to k (smaller than 1)
	}
	else
	{
		d1 = (ro.y - 1.0) / -rd.y;
		dn1 = vec3(0,1,0);
		d0 = (ro.y + 0.0) / -rd.y;
		dn0 = vec3(0,-1,0);
		dr0 = 1.0 / sqrt(abs(k)); // bottom cap is related to k (smaller than 1)
		dr1 = 1.0; // top cap is unit radius
	}
	
	hit = ro + rd * d0;
	if (abs(hit.x) <= dr0 && abs(hit.z) <= 1.0)
	{
		if (t0 != 0.0)
		{
			t1 = t0;
			n1 = n0;
		}
		t0 = d0;
		n0 = dn0;
	}
	hit = ro + rd * d1;
	if (abs(hit.x) <= dr1 && abs(hit.z) <= 1.0)
	{
		t1 = d1;
		n1 = dn1;
	}
	// intersect hyperbolic-shaped front and back wall pieces
	if (rd.z < 0.0)
	{
		d0 = (ro.z - 1.0) / -rd.z;
		dn0 = vec3(0,0,1);
		d1 = (ro.z + 1.0) / -rd.z;
		dn1 = vec3(0,0,-1);
	}
	else
	{
		d1 = (ro.z - 1.0) / -rd.z;
		dn1 = vec3(0,0,1);
		d0 = (ro.z + 1.0) / -rd.z;
		dn0 = vec3(0,0,-1);
	}
	
	hit = ro + rd * d0;
	if (abs(hit.x) <= 1.0 && hit.y >= 0.0 && hit.y <= 1.0 && (k * hit.x * hit.x - j * hit.y * hit.y - 1.0) <= 0.0) // y is a quadratic (hyperbolic) function of x
	{
		if (t0 != 0.0)
		{
			t1 = t0;
			n1 = n0;
		}
		
		t0 = d0;
		n0 = dn0;
	}
	hit = ro + rd * d1;
	if (abs(hit.x) <= 1.0 && hit.y >= 0.0 && hit.y <= 1.0 && (k * hit.x * hit.x - j * hit.y * hit.y - 1.0) <= 0.0) // y is a quadratic (hyperbolic) function of x
	{
		t1 = d1;
		n1 = dn1;
	}
}
`;


THREE.ShaderChunk[ 'pathtracing_hyperbolicprism2sheets_csg_intersect' ] = `
//------------------------------------------------------------------------------------------------------------
void HyperbolicPrism2Sheets_CSG_Intersect( float k, vec3 ro, vec3 rd, out float t0, out float t1, out vec3 n0, out vec3 n1 )
//------------------------------------------------------------------------------------------------------------
{
	vec3 hit;
	float d, d0, d1, dr0, dr1;
	d = d0 = d1 = dr0 = dr1 = 0.0;
	vec3 dn0, dn1;
	// start with the implicit equation of a hyperboloid of 2 sheets (2 rounded v shapes that are mirrored and pointing at each other)
	// -x^2 - z^2 + y^2 - 1 = 0
	// To obtain a hyperbolic prism along the Z axis, the Z component is simply removed, leaving:
	// -x^2 + y^2 - 1 = 0
	// for CSG purposes, we artificially truncate the hyperbolic prism at the middle, so that only 1 sheet (the top sheet) of the 2 mirrored sheets remains...
	// This way, the total number of possible intersections will be 2 max (t0/t1), rather than possibly 4 (if we left it as 2 full sheets with added top/bottom caps)
	
	ro.y += 0.5; // this places the top-to-middle portion of the shape closer to its own origin, so that it rotates smoothly around its own middle. 
	
	// conservative range of k: 1 to 100
	float j = k + 1.0;
	float a = -k * rd.x * rd.x + j * rd.y * rd.y;
	float b = 2.0 * (-k * rd.x * ro.x + j * rd.y * ro.y);
	float c = (-k * ro.x * ro.x + j * ro.y * ro.y) - 1.0;
	solveQuadratic(a, b, c, t0, t1);
	hit = ro + rd * t0;
	t0 = (hit.y > 1.0 || hit.y < 0.0 || abs(hit.z) > 1.0) ? 0.0 : t0; // invalidate t0 if it's outside unit radius bounds of top half
	n0 = vec3(2.0 * -hit.x * k, 2.0 * hit.y * j, 0.0);
	hit = ro + rd * t1;
	t1 = (hit.y > 1.0 || hit.y < 0.0 || abs(hit.z) > 1.0) ? 0.0 : t1; // invalidate t1 if it's outside unit radius bounds of top half
	n1 = vec3(2.0 * -hit.x * k, 2.0 * hit.y * j, 0.0);
	// since the infinite hyperbolic shape is artificially cut off at the top and bottom so that it has a unit radius top cap,
	// if t0 intersection was invalidated, try t1
	if (t0 == 0.0)
	{
		t0 = t1;
		n0 = n1;
	}
	// intersect unit-radius square located at top opening of hyperbolic prism shape
	d = (ro.y - 1.0) / -rd.y;
	hit = ro + rd * d;
	if (abs(hit.x) <= 1.0 && abs(hit.z) <= 1.0) // square with unit radius
	{
		if (rd.y > 0.0)
		{
			t1 = d;
			n1 = vec3(0,1,0);
		}
		else
		{
			t1 = t0;
			n1 = n0;
			t0 = d;
			n0 = vec3(0,1,0);
		}
	}
	// intersect hyperbolic v-shaped front and back wall pieces
	if (rd.z < 0.0)
	{
		d0 = (ro.z - 1.0) / -rd.z;
		dn0 = vec3(0,0,1);
		d1 = (ro.z + 1.0) / -rd.z;
		dn1 = vec3(0,0,-1);
	}
	else
	{
		d1 = (ro.z - 1.0) / -rd.z;
		dn1 = vec3(0,0,1);
		d0 = (ro.z + 1.0) / -rd.z;
		dn0 = vec3(0,0,-1);
	}
	
	hit = ro + rd * d0;
	if (abs(hit.x) <= 1.0 && hit.y >= 0.0 && hit.y <= 1.0 && (-k * hit.x * hit.x + j * hit.y * hit.y - 1.0) >= 0.0) // y is a quadratic (hyperbolic) function of x
	{
		if (t0 != 0.0)
		{
			t1 = t0;
			n1 = n0;
		}
		
		t0 = d0;
		n0 = dn0;
	}
	hit = ro + rd * d1;
	if (abs(hit.x) <= 1.0 && hit.y >= 0.0 && hit.y <= 1.0 && (-k * hit.x * hit.x + j * hit.y * hit.y - 1.0) >= 0.0) // y is a quadratic (hyperbolic) function of x
	{
		t1 = d1;
		n1 = dn1;
	}
}
`;

THREE.ShaderChunk[ 'pathtracing_capsule_csg_intersect' ] = `
//------------------------------------------------------------------------------------------------------------
void Capsule_CSG_Intersect( float k, vec3 ro, vec3 rd, out float t0, out float t1, out vec3 n0, out vec3 n1 )
//------------------------------------------------------------------------------------------------------------
{
	vec3 hit, s0n0, s0n1, s1n0, s1n1;
	float s0t0, s0t1, s1t0, s1t1;
	s0t0 = s0t1 = s1t0 = s1t1 = 0.0;
	// implicit equation of a unit (radius of 1) cylinder, extending infinitely in the +Y and -Y directions:
	// x^2 + z^2 - 1 = 0
	float a = (rd.x * rd.x + rd.z * rd.z);
    	float b = 2.0 * (rd.x * ro.x + rd.z * ro.z);
    	float c = (ro.x * ro.x + ro.z * ro.z) - 1.0;
	solveQuadratic(a, b, c, t0, t1);
	hit = ro + rd * t0;
	t0 = (abs(hit.y) > k) ? 0.0 : t0;
	n0 = vec3(2.0 * hit.x, 0.0, 2.0 * hit.z);
	hit = ro + rd * t1;
	t1 = (abs(hit.y) > k) ? 0.0 : t1;
	n1 = vec3(2.0 * hit.x, 0.0, 2.0 * hit.z);
	// intersect unit-radius sphere located at top opening of cylinder
	vec3 s0pos = vec3(0, k, 0);
	vec3 L = ro - s0pos;
	a = dot(rd, rd);
	b = 2.0 * dot(rd, L);
	c = dot(L, L) - 1.0;
	solveQuadratic(a, b, c, s0t0, s0t1);
	hit = ro + rd * s0t0;
	s0n0 = vec3(2.0 * hit.x, 2.0 * (hit.y - s0pos.y), 2.0 * hit.z);
	s0t0 = (hit.y < k) ? 0.0 : s0t0;
	hit = ro + rd * s0t1;
	s0n1 = vec3(2.0 * hit.x, 2.0 * (hit.y - s0pos.y), 2.0 * hit.z);
	s0t1 = (hit.y < k) ? 0.0 : s0t1;
	// now intersect unit-radius sphere located at bottom opening of cylinder
	vec3 s1pos = vec3(0, -k, 0);
	L = ro - s1pos;
	a = dot(rd, rd);
	b = 2.0 * dot(rd, L);
	c = dot(L, L) - 1.0;
	solveQuadratic(a, b, c, s1t0, s1t1);
	hit = ro + rd * s1t0;
	s1n0 = vec3(2.0 * hit.x, 2.0 * (hit.y - s1pos.y), 2.0 * hit.z);
	s1t0 = (hit.y > -k) ? 0.0 : s1t0;
	hit = ro + rd * s1t1;
	s1n1 = vec3(2.0 * hit.x, 2.0 * (hit.y - s1pos.y), 2.0 * hit.z);
	s1t1 = (hit.y > -k) ? 0.0 : s1t1;
	if (s0t0 != 0.0)
	{
		t0 = s0t0;
		n0 = s0n0;
	}
	else if (s1t0 != 0.0)
	{
		t0 = s1t0;
		n0 = s1n0;
	}
	
	if (s0t1 != 0.0)
	{
		t1 = s0t1;
		n1 = s0n1;
	}
	else if (s1t1 != 0.0)
	{
		t1 = s1t1;
		n1 = s1n1;
	}
}
`;

THREE.ShaderChunk[ 'pathtracing_box_csg_intersect' ] = `
//------------------------------------------------------------------------------------------------------------
void Box_CSG_Intersect( vec3 ro, vec3 rd, out float t0, out float t1, out vec3 n0, out vec3 n1 )
//------------------------------------------------------------------------------------------------------------
{
	vec3 invDir = 1.0 / rd;
	vec3 near = (vec3(-1) - ro) * invDir; // unit radius box: vec3(-1,-1,-1) min corner
	vec3 far  = (vec3(1) - ro) * invDir;  // unit radius box: vec3(+1,+1,+1) max corner
	
	vec3 tmin = min(near, far);
	vec3 tmax = max(near, far);
	t0 = max( max(tmin.x, tmin.y), tmin.z);
	t1 = min( min(tmax.x, tmax.y), tmax.z);
	n0 = -sign(rd) * step(tmin.yzx, tmin) * step(tmin.zxy, tmin);
	n1 = -sign(rd) * step(tmax, tmax.yzx) * step(tmax, tmax.zxy);
	if (t0 > t1) // invalid intersection
		t0 = t1 = 0.0;
}
`;

/* THREE.ShaderChunk[ 'pathtracing_convexpolyhedron_csg_intersect' ] = `
// This convexPolyhedron routine works with any number of user-defined cutting planes (a plane is defined by its unit normal (vec3) and an offset distance (float) from the shape's origin along this normal)
// Examples of shapes that can be made from a list of pure convex cutting planes: cube, frustum, triangular pyramid (tetrahedron), rectangular pyramid, triangular bipyramid (hexahedron), rectangular bipyramid (octahedron), other Platonic/Archimedean solids, etc.)
// Although I am proud of coming up with this ray casting / ray intersection algo for arbitrary mathematical convex polyhedra, and it does indeed give pixel-perfect sharp cut convex polygon faces (tris, quads, pentagons, hexagons, etc), 
// I'm not currently using it because it runs too slowly on mobile, probably due to the nested for loops that have to compare each plane against all of its neighbor planes: big O(N-squared) - ouch! Hopefully I can optimize someday!
// -Erich  erichlof on GitHub

const int numPlanes = 8;
vec4 convex_planes[numPlanes];
//------------------------------------------------------------------------------------------------------------
float ConvexPolyhedron_Intersect( vec3 ro, vec3 rd, out vec3 n )
//------------------------------------------------------------------------------------------------------------
{
	vec3 hit;
	float t;
	float smallestT = INFINITY;

	// to get triangular bipyramid (hexahedron), set numPlanes = 6 above
	//convex_planes[0] = vec4(normalize(vec3(1, 1, -1)), 0.5);
	//convex_planes[1] = vec4(normalize(vec3(-1, 1, -1)), 0.5);
	//convex_planes[2] = vec4(normalize(vec3(0, 1, 1)), 0.5);
	//convex_planes[3] = vec4(normalize(vec3(0, -1, 1)), 0.5);
	//convex_planes[4] = vec4(normalize(vec3(1, -1, -1)), 0.5);
	//convex_planes[5] = vec4(normalize(vec3(-1, -1, -1)), 0.5);

	// to get rectangular bipyramid (octahedron), set numPlanes = 8 above
	convex_planes[0] = vec4(normalize(vec3(1, 1, 0)), 0.5);
	convex_planes[1] = vec4(normalize(vec3(-1, 1, 0)), 0.5);
	convex_planes[2] = vec4(normalize(vec3(0, 1, 1)), 0.5);
	convex_planes[3] = vec4(normalize(vec3(0, 1, -1)), 0.5);
	convex_planes[4] = vec4(normalize(vec3(1, -1, 0)), 0.5);
	convex_planes[5] = vec4(normalize(vec3(-1, -1, 0)), 0.5);
	convex_planes[6] = vec4(normalize(vec3(0, -1, 1)), 0.5);
	convex_planes[7] = vec4(normalize(vec3(0, -1, -1)), 0.5);
	
	for (int i = 0; i < numPlanes; i++)
	{
		t = (-dot(convex_planes[i].xyz, ro) + convex_planes[i].w) / dot(convex_planes[i].xyz, rd);
		if (t <= 0.0)
			continue;
		hit = ro + rd * t;

		for (int j = 0; j < numPlanes; j++)
		{
			if (i != j)
				t = dot(convex_planes[j].xyz, (hit - (convex_planes[j].xyz * convex_planes[j].w))) > 0.0 ? INFINITY : t;
		}
		
		if (t < smallestT)
		{
			smallestT = t;
			n = convex_planes[i].xyz;
		}
	}

	return smallestT;
}

//const int numPlanes = 8;
//vec4 convex_planes[numPlanes];
//------------------------------------------------------------------------------------------------------------
void ConvexPolyhedron_CSG_Intersect( vec3 ro, vec3 rd, out float t0, out float t1, out vec3 n0, out vec3 n1 )
//------------------------------------------------------------------------------------------------------------
{
	vec3 hit;
	float smallestT = INFINITY;
	float largestT = -INFINITY;
	float t = 0.0;
	
	// to get triangular bipyramid (hexahedron), set numPlanes = 6 above
	//convex_planes[0] = vec4(normalize(vec3(1, 1, -1)), 0.5);
	//convex_planes[1] = vec4(normalize(vec3(-1, 1, -1)), 0.5);
	//convex_planes[2] = vec4(normalize(vec3(0, 1, 1)), 0.5);
	//convex_planes[3] = vec4(normalize(vec3(0, -1, 1)), 0.5);
	//convex_planes[4] = vec4(normalize(vec3(1, -1, -1)), 0.5);
	//convex_planes[5] = vec4(normalize(vec3(-1, -1, -1)), 0.5);

	// to get rectangular bipyramid (octahedron), set numPlanes = 8 above
	convex_planes[0] = vec4(normalize(vec3(1, 1, 0)), 0.5);
	convex_planes[1] = vec4(normalize(vec3(-1, 1, 0)), 0.5);
	convex_planes[2] = vec4(normalize(vec3(0, 1, 1)), 0.5);
	convex_planes[3] = vec4(normalize(vec3(0, 1, -1)), 0.5);
	convex_planes[4] = vec4(normalize(vec3(1, -1, 0)), 0.5);
	convex_planes[5] = vec4(normalize(vec3(-1, -1, 0)), 0.5);
	convex_planes[6] = vec4(normalize(vec3(0, -1, 1)), 0.5);
	convex_planes[7] = vec4(normalize(vec3(0, -1, -1)), 0.5);

	for (int i = 0; i < numPlanes; i++)
	{
		t = (-dot(convex_planes[i].xyz, ro) + convex_planes[i].w) / dot(convex_planes[i].xyz, rd);
		hit = ro + rd * t;
		for (int j = 0; j < numPlanes; j++)
		{
			if (i != j)
				t = dot(convex_planes[j].xyz, (hit - (convex_planes[j].xyz * convex_planes[j].w))) > 0.0 ? 0.0 : t;
		}
		if (t == 0.0) 
			continue;
		
		if (t < smallestT)
		{
			smallestT = t;
			t0 = t;
			n0 = convex_planes[i].xyz;
		}
		if (t > largestT)
		{
			largestT = t;
			t1 = t;
			n1 = convex_planes[i].xyz;
		}
		
	} // end for (int i = 0; i < numPlanes; i++)
}
`; */

THREE.ShaderChunk[ 'pathtracing_pyramidfrustum_csg_intersect' ] = `
//------------------------------------------------------------------------------------------------------------
void PyramidFrustum_CSG_Intersect( float k, vec3 ro, vec3 rd, out float t0, out float t1, out vec3 n0, out vec3 n1 )
//------------------------------------------------------------------------------------------------------------
{
	vec3 hit, dn0, dn1, xn0, xn1, zn0, zn1;
	float d0, d1, dr0, dr1;
	float xt0, xt1, zt0, zt1;
	d0 = d1 = dr0 = dr1 = xt0 = xt1 = zt0 = zt1 = 0.0;
	// first, intersect left and right sides of pyramid/frustum
	// start with implicit equation of a double-cone extending infinitely in +Y and -Y directions
	// x^2 + z^2 - y^2 = 0
	// To obtain a conical prism along the Z axis, the Z component is simply removed, leaving:
	// x^2 - y^2 = 0
	// code below cuts off top cone of the double-cone, leaving bottom cone with apex at the top (+1.0), and base (radius of 1) at the bottom (-1.0)
	
	// valid range for k: 0.01 to 1.0 (1.0 being the default for cone with a sharp, pointed apex)
	k = clamp(k, 0.01, 1.0);
	
	float j = 1.0 / k;
	float h = j * 2.0 - 1.0; // (k * 0.25) makes the normal cone's bottom circular base have a unit radius of 1.0
	float a = j * rd.x * rd.x - (k * 0.25) * rd.y * rd.y;
    	float b = 2.0 * (j * rd.x * ro.x - (k * 0.25) * rd.y * (ro.y - h));
    	float c = j * ro.x * ro.x - (k * 0.25) * (ro.y - h) * (ro.y - h);
	solveQuadratic(a, b, c, xt0, xt1);
	hit = ro + rd * xt0;
	xt0 = (abs(hit.x) > 1.0 || abs(hit.z) > 1.0 || hit.y > 1.0 || (j * hit.z * hit.z - k * 0.25 * (hit.y - h) * (hit.y - h)) > 0.0) ? 0.0 : xt0;
	xn0 = vec3(2.0 * hit.x * j, 2.0 * (hit.y - h) * -(k * 0.25), 0.0);
	
	hit = ro + rd * xt1;
	xt1 = (abs(hit.x) > 1.0 || abs(hit.z) > 1.0 || hit.y > 1.0 || (j * hit.z * hit.z - k * 0.25 * (hit.y - h) * (hit.y - h)) > 0.0) ? 0.0 : xt1;
	xn1 = vec3(2.0 * hit.x * j, 2.0 * (hit.y - h) * -(k * 0.25), 0.0);
	
	// since the infinite double-cone shape is artificially cut off at the top and bottom,
	// if xt0 intersection was invalidated above, try xt1
	if (xt0 == 0.0)
	{
		xt0 = xt1;
		xn0 = xn1;
		xt1 = 0.0; // invalidate xt1 (see sorting algo below)
	}
	// now intersect front and back sides of pyramid/frustum
	// start with implicit equation of a double-cone extending infinitely in +Y and -Y directions
	// x^2 + z^2 - y^2 = 0
	// To obtain a conical prism along the X axis, the X component is simply removed, leaving:
	// z^2 - y^2 = 0
	a = j * rd.z * rd.z - (k * 0.25) * rd.y * rd.y;
    	b = 2.0 * (j * rd.z * ro.z - (k * 0.25) * rd.y * (ro.y - h));
    	c = j * ro.z * ro.z - (k * 0.25) * (ro.y - h) * (ro.y - h);
	solveQuadratic(a, b, c, zt0, zt1);
	hit = ro + rd * zt0;
	zt0 = (abs(hit.x) > 1.0 || abs(hit.z) > 1.0 || hit.y > 1.0 || (j * hit.x * hit.x - k * 0.25 * (hit.y - h) * (hit.y - h)) > 0.0) ? 0.0 : zt0;
	zn0 = vec3(0.0, 2.0 * (hit.y - h) * -(k * 0.25), 2.0 * hit.z * j);
	
	hit = ro + rd * zt1;
	zt1 = (abs(hit.x) > 1.0 || abs(hit.z) > 1.0 || hit.y > 1.0 || (j * hit.x * hit.x - k * 0.25 * (hit.y - h) * (hit.y - h)) > 0.0) ? 0.0 : zt1;
	zn1 = vec3(0.0, 2.0 * (hit.y - h) * -(k * 0.25), 2.0 * hit.z * j);
	// since the infinite double-cone shape is artificially cut off at the top and bottom,
	// if zt0 intersection was invalidated above, try zt1
	if (zt0 == 0.0)
	{
		zt0 = zt1;
		zn0 = zn1;
		zt1 = 0.0; // invalidate zt1 (see sorting algo below)
	}
	// sort valid intersections of 4 sides of pyramid/frustum thus far
	if (xt1 != 0.0) // the only way xt1 can be valid (not 0), is if xt0 was also valid (not 0) (see above)
	{
		t0 = xt0;
		n0 = xn0;
		t1 = xt1;
		n1 = xn1;
	}
	else if (zt1 != 0.0) // the only way zt1 can be valid (not 0), is if zt0 was also valid (not 0) (see above)
	{
		t0 = zt0;
		n0 = zn0;
		t1 = zt1;
		n1 = zn1;
	}
	else if (xt0 != 0.0)
	{
		if (zt0 == 0.0)
		{
			t0 = xt0;
			n0 = xn0;	
		}
		else if (zt0 < xt0)
		{
			t0 = zt0;
			n0 = zn0;
			t1 = xt0;
			n1 = xn0;
		}
		else
		{
			t0 = xt0;
			n0 = xn0;
			t1 = zt0;
			n1 = zn0;
		}
	}
	else if (xt0 == 0.0)
	{
		t0 = zt0;
		n0 = zn0;
	}
	
	// lastly, intersect top and bottom base squares (both are perfect squares)
	if (rd.y < 0.0)
	{
		d0 = (ro.y - 1.0) / -rd.y;
		dn0 = vec3(0,1,0);
		d1 = (ro.y + 1.0) / -rd.y;
		dn1 = vec3(0,-1,0);
		dr0 = 1.0 - k; // top square's size is relative to k
		dr1 = 1.0; // bottom square is unit radius
	}
	else
	{
		d1 = (ro.y - 1.0) / -rd.y;
		dn1 = vec3(0,1,0);
		d0 = (ro.y + 1.0) / -rd.y;
		dn0 = vec3(0,-1,0);
		dr0 = 1.0; // bottom square is unit radius
		dr1 = 1.0 - k;// top square's size is relative to k
	}
	hit = ro + rd * d0;
	if (abs(hit.x) <= dr0 && abs(hit.z) <= dr0)
	{
		t1 = t0;
		n1 = n0;
		t0 = d0;
		n0 = dn0;
	}
	hit = ro + rd * d1;
	if (abs(hit.x) <= dr1 && abs(hit.z) <= dr1)
	{
		t1 = d1;
		n1 = dn1;
	}
}
`;

THREE.ShaderChunk[ 'pathtracing_csg_operations' ] = `
//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
void CSG_Union_Operation( float A_t0, vec3 A_n0, int A_type0, vec3 A_color0, int A_objectID0, float A_t1, vec3 A_n1, int A_type1, vec3 A_color1, int A_objectID1, 
			  float B_t0, vec3 B_n0, int B_type0, vec3 B_color0, int B_objectID0, float B_t1, vec3 B_n1, int B_type1, vec3 B_color1, int B_objectID1, 
			  out float t0, out vec3 n0, out int type0, out vec3 color0, out int objectID0, out float t1, out vec3 n1, out int type1, out vec3 color1, out int objectID1 )
//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
{
	// CSG UNION OPERATION [A + B] (outside of shape A and outside of shape B are fused together into a single, new shape)
	// (hypothetically, the interior volume of the newly created union could be completely filled with water in one pass)
	
	vec3 temp_n0, temp_n1, temp_col0, temp_col1;
	float temp_t0, temp_t1;
	int temp_type0, temp_type1, temp_objectID0, temp_objectID1;
	// if shape B is closer than A, swap shapes
	if (B_t0 < A_t0)
	{
		temp_t0 = A_t0;
		temp_n0 = A_n0;
		temp_col0 = A_color0;
		temp_type0 = A_type0;
		temp_objectID0 = A_objectID0;
		
		temp_t1 = A_t1;
		temp_n1 = A_n1;
		temp_col1 = A_color1;
		temp_type1 = A_type1;
		temp_objectID1 = A_objectID1;


		A_t0 = B_t0;
		A_n0 = B_n0;
		A_color0 = B_color0;
		A_type0 = B_type0;
		A_objectID0 = B_objectID0;

		A_t1 = B_t1;
		A_n1 = B_n1;
		A_color1 = B_color1;
		A_type1 = B_type1;
		A_objectID1 = B_objectID1;


		B_t0 = temp_t0;
		B_n0 = temp_n0;
		B_color0 = temp_col0;
		B_type0 = temp_type0;
		B_objectID0 = temp_objectID0;

		B_t1 = temp_t1;
		B_n1 = temp_n1;
		B_color1 = temp_col1;
		B_type1 = temp_type1;
		B_objectID1 = temp_objectID1;
	}
	// shape A is always considered to be first
	t0 = A_t0;
	n0 = A_n0;
	type0 = A_type0;
	color0 = A_color0;
	objectID0 = A_objectID0;

	t1 = A_t1;
	n1 = A_n1;
	type1 = A_type1;
	color1 = A_color1;
	objectID1 = A_objectID1;
	
	// except for when the outside of shape B matches the outside of shape A
	if (B_t0 == A_t0)
	{
		t0 = B_t0;
		n0 = B_n0;
		type0 = B_type0;
		color0 = B_color0;
		objectID0 = B_objectID0;
	}
	// A is behind us and completely in front of B
	if (A_t1 <= 0.0 && A_t1 < B_t0)
	{
		t0 = B_t0;
		n0 = B_n0;
		type0 = B_type0;
		color0 = B_color0;
		objectID0 = B_objectID0;

		t1 = B_t1;
		n1 = B_n1;
		type1 = B_type1;
		color1 = B_color1;
		objectID1 = B_objectID1;
	}
	else if (B_t0 <= A_t1 && B_t1 > A_t1)
	{
		t1 = B_t1;
		n1 = B_n1;
		type1 = B_type1;
		color1 = B_color1;
		objectID1 = B_objectID1;
	}
	else if (B_t0 <= A_t1 && B_t1 <= A_t1)
	{
		t1 = A_t1;
		n1 = A_n1;
		type1 = A_type1;
		color1 = A_color1;
		objectID1 = A_objectID1;
	}
}
//-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
void CSG_Difference_Operation( float A_t0, vec3 A_n0, int A_type0, vec3 A_color0, int A_objectID0, float A_t1, vec3 A_n1, int A_type1, vec3 A_color1, int A_objectID1, 
			       float B_t0, vec3 B_n0, int B_type0, vec3 B_color0, int B_objectID0, float B_t1, vec3 B_n1, int B_type1, vec3 B_color1, int B_objectID1, 
			       out float t0, out vec3 n0, out int type0, out vec3 color0, out int objectID0, out float t1, out vec3 n1, out int type1, out vec3 color1, out int objectID1 )
//-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
{
	// CSG DIFFERENCE OPERATION [A - B] (shape A is carved out with shape B where the two shapes overlap)
	
	if ((B_t0 < A_t0 && B_t1 < A_t0) || (B_t0 > A_t1 && B_t1 > A_t1))
	{
		t0 = A_t0;
		n0 = A_n0;
		type0 = A_type0;
		color0 = A_color0;
		objectID0 = A_objectID0;

		t1 = A_t1;
		n1 = A_n1;
		type1 = A_type1;
		color1 = A_color1;
		objectID1 = A_objectID1;
	}
	else if (B_t0 > 0.0 && B_t0 < A_t1 && B_t0 > A_t0)
	{
		t0 = A_t0;
		n0 = A_n0;
		type0 = A_type0;
		color0 = A_color0;
		objectID0 = A_objectID0;

		t1 = B_t0;
		n1 = B_n0;
		type1 = B_type0;
		color1 = B_color0;
		objectID1 = B_objectID0;
	}
	else if (B_t1 > A_t0 && B_t1 < A_t1)
	{
		t0 = B_t1;
		n0 = B_n1;
		type0 = B_type1;
		color0 = B_color1;
		objectID0 = B_objectID1;

		t1 = A_t1;
		n1 = A_n1;
		type1 = A_type1;
		color1 = A_color1;
		objectID1 = A_objectID1;
	}
}
//-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
void CSG_Intersection_Operation( float A_t0, vec3 A_n0, int A_type0, vec3 A_color0, int A_objectID0, float A_t1, vec3 A_n1, int A_type1, vec3 A_color1, int A_objectID1, 
			  	 float B_t0, vec3 B_n0, int B_type0, vec3 B_color0, int B_objectID0, float B_t1, vec3 B_n1, int B_type1, vec3 B_color1, int B_objectID1, 
			  	 out float t0, out vec3 n0, out int type0, out vec3 color0, out int objectID0, out float t1, out vec3 n1, out int type1, out vec3 color1, out int objectID1 )
//-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
{
	// CSG INTERSECTION OPERATION [A ^ B] (Only valid where shape A overlaps shape B)
	// (ray must intersect both shape A and shape B)
	vec3 temp_n0, temp_n1, temp_col0, temp_col1;
	float temp_t0, temp_t1;
	int temp_type0, temp_type1, temp_objectID0, temp_objectID1;
	// if shape B is closer than A, swap shapes
	if (B_t0 < A_t0)
	{
		temp_t0 = A_t0;
		temp_n0 = A_n0;
		temp_col0 = A_color0;
		temp_type0 = A_type0;
		temp_objectID0 = A_objectID0;
		
		temp_t1 = A_t1;
		temp_n1 = A_n1;
		temp_col1 = A_color1;
		temp_type1 = A_type1;
		temp_objectID1 = A_objectID1;


		A_t0 = B_t0;
		A_n0 = B_n0;
		A_color0 = B_color0;
		A_type0 = B_type0;
		A_objectID0 = B_objectID0;

		A_t1 = B_t1;
		A_n1 = B_n1;
		A_color1 = B_color1;
		A_type1 = B_type1;
		A_objectID1 = B_objectID1;


		B_t0 = temp_t0;
		B_n0 = temp_n0;
		B_color0 = temp_col0;
		B_type0 = temp_type0;
		B_objectID0 = temp_objectID0;

		B_t1 = temp_t1;
		B_n1 = temp_n1;
		B_color1 = temp_col1;
		B_type1 = temp_type1;
		B_objectID1 = temp_objectID1;
	}
	if (B_t0 < A_t1)
	{
		t0 = B_t0;
		n0 = B_n0;
		// in surfaceA's space, so must use surfaceA's material
		type0 = A_type0; 
		color0 = A_color0;
		objectID0 = A_objectID0;
	}
	if (A_t1 > B_t0 && A_t1 < B_t1)
	{
		t1 = A_t1;
		n1 = A_n1;
		// in surfaceB's space, so must use surfaceB's material
		type1 = B_type0;
		color1 = B_color0;
		objectID1 = B_objectID0;
	}
	else if (B_t1 > A_t0 && B_t1 <= A_t1)
	{
		t1 = B_t1;
		n1 = B_n1;
		// in surfaceA's space, so must use surfaceA's material
		type1 = A_type0;
		color1 = A_color0;
		objectID1 = A_objectID0;
	}
}
`;

THREE.ShaderChunk[ 'pathtracing_ellipsoid_param_intersect' ] = `
//------------------------------------------------------------------------------------------------------------
float EllipsoidParamIntersect( float yMinPercent, float yMaxPercent, float phiMaxRadians, vec3 ro, vec3 rd, out vec3 n )
//------------------------------------------------------------------------------------------------------------
{
	vec3 pHit;
	float t, t0, t1, phi;
	// implicit equation of a unit (radius of 1) sphere:
	// x^2 + y^2 + z^2 - 1 = 0
	float a = dot(rd, rd);
	float b = 2.0 * dot(rd, ro);
	float c = dot(ro, ro) - 1.0;
	solveQuadratic(a, b, c, t0, t1);
	if (t1 <= 0.0) return INFINITY;
	t = t0 > 0.0 ? t0 : INFINITY;
	pHit = ro + rd * t;
	phi = mod(atan(pHit.z, pHit.x), TWO_PI);
	if (pHit.y > yMaxPercent || pHit.y < yMinPercent || phi > phiMaxRadians)
	{
		t = t1;
		pHit = ro + rd * t;
		phi = mod(atan(pHit.z, pHit.x), TWO_PI);
		if (pHit.y > yMaxPercent || pHit.y < yMinPercent || phi > phiMaxRadians)
			t = INFINITY;
	}
	
	n = vec3(2.0 * pHit.x, 2.0 * pHit.y, 2.0 * pHit.z);
	n = dot(rd, n) < 0.0 ? n : -n; // flip normal if it is facing away from us
	return t;
}
`;

THREE.ShaderChunk[ 'pathtracing_cylinder_param_intersect' ] = `
//------------------------------------------------------------------------------------------------------------
float CylinderParamIntersect( float yMinPercent, float yMaxPercent, float phiMaxRadians, vec3 ro, vec3 rd, out vec3 n )
//------------------------------------------------------------------------------------------------------------
{
	vec3 pHit;
	float t, t0, t1, phi;
	// implicit equation of a unit (radius of 1) cylinder, extending infinitely in the +Y and -Y directions:
	// x^2 + z^2 - 1 = 0
	float a = (rd.x * rd.x + rd.z * rd.z);
    	float b = 2.0 * (rd.x * ro.x + rd.z * ro.z);
    	float c = (ro.x * ro.x + ro.z * ro.z) - 1.0;
	solveQuadratic(a, b, c, t0, t1);
	if (t1 <= 0.0) return INFINITY;
		
	t = t0 > 0.0 ? t0 : INFINITY;
	pHit = ro + rd * t;
	phi = mod(atan(pHit.z, pHit.x), TWO_PI);
	if (pHit.y > yMaxPercent || pHit.y < yMinPercent || phi > phiMaxRadians)
	{
		t = t1;
		pHit = ro + rd * t;
		phi = mod(atan(pHit.z, pHit.x), TWO_PI);
		if (pHit.y > yMaxPercent || pHit.y < yMinPercent || phi > phiMaxRadians)
			t = INFINITY;
	}
	
	n = vec3(2.0 * pHit.x, 0.0, 2.0 * pHit.z);
	n = dot(rd, n) < 0.0 ? n : -n; // flip normal if it is facing away from us
		
	return t;
}
`;

THREE.ShaderChunk[ 'pathtracing_cone_param_intersect' ] = `
//------------------------------------------------------------------------------------------------------------
float ConeParamIntersect( float yMinPercent, float yMaxPercent, float phiMaxRadians, vec3 ro, vec3 rd, out vec3 n )
//------------------------------------------------------------------------------------------------------------
{
	vec3 pHit;
	float t, t0, t1, phi;
	// implicit equation of a double-cone extending infinitely in +Y and -Y directions
	// x^2 + z^2 - y^2 = 0
	// code below cuts off top cone, leaving bottom cone with apex at the top (+1.0), and circular base (radius of 1) at the bottom (-1.0)
	float k = 0.25;
	float a = rd.x * rd.x + rd.z * rd.z - k * rd.y * rd.y;
    	float b = 2.0 * (rd.x * ro.x + rd.z * ro.z - k * rd.y * (ro.y - 1.0));
    	float c = ro.x * ro.x + ro.z * ro.z - k * (ro.y - 1.0) * (ro.y - 1.0);
	
	solveQuadratic(a, b, c, t0, t1);
	if (t1 <= 0.0) return INFINITY;
		
	t = t0 > 0.0 ? t0 : INFINITY;
	pHit = ro + rd * t;
	phi = mod(atan(pHit.z, pHit.x), TWO_PI);
	if (pHit.y > yMaxPercent || pHit.y < yMinPercent || phi > phiMaxRadians)
	{
		t = t1;
		pHit = ro + rd * t;
		phi = mod(atan(pHit.z, pHit.x), TWO_PI);
		if (pHit.y > yMaxPercent || pHit.y < yMinPercent || phi > phiMaxRadians)
			t = INFINITY;
	}
	n = vec3(2.0 * pHit.x, 2.0 * (1.0 - pHit.y) * k, 2.0 * pHit.z);
	n = dot(rd, n) < 0.0 ? n : -n; // flip normal if it is facing away from us
	return t;
}
`;

THREE.ShaderChunk[ 'pathtracing_paraboloid_param_intersect' ] = `
//------------------------------------------------------------------------------------------------------------
float ParaboloidParamIntersect( float yMinPercent, float yMaxPercent, float phiMaxRadians, vec3 ro, vec3 rd, out vec3 n )
//------------------------------------------------------------------------------------------------------------
{
	vec3 pHit;
	float t, t0, t1, phi;
	// implicit equation of a paraboloid (bowl or vase-shape extending infinitely in the +Y direction):
	// x^2 + z^2 - y = 0
	ro.y += 1.0; // this essentially centers the paraboloid so that the bottom is at -1.0 and 
		     // the open circular top (radius of 1) is at +1.0
	float k = 0.5;
	float a = (rd.x * rd.x + rd.z * rd.z);
    	float b = 2.0 * (rd.x * ro.x + rd.z * ro.z) - k * rd.y;
    	float c = (ro.x * ro.x + ro.z * ro.z) - k * ro.y;
	solveQuadratic(a, b, c, t0, t1);
	if (t1 <= 0.0) return INFINITY;
	
	// this takes into account that we shifted the ray origin by +1.0
	yMaxPercent += 1.0;
	yMinPercent += 1.0;
	t = t0 > 0.0 ? t0 : INFINITY;
	pHit = ro + rd * t;
	phi = mod(atan(pHit.z, pHit.x), TWO_PI);
	if (pHit.y > yMaxPercent || pHit.y < yMinPercent || phi > phiMaxRadians)
	{
		t = t1;
		pHit = ro + rd * t;
		phi = mod(atan(pHit.z, pHit.x), TWO_PI);
		if (pHit.y > yMaxPercent || pHit.y < yMinPercent || phi > phiMaxRadians)
			t = INFINITY;
	}
	
	n = vec3(2.0 * pHit.x, -1.0 * k, 2.0 * pHit.z);
	n = dot(rd, n) < 0.0 ? n : -n; // flip normal if it is facing away from us
			
	return t;
}
`;

THREE.ShaderChunk[ 'pathtracing_hyperboloid_param_intersect' ] = `
//------------------------------------------------------------------------------------------------------------
float HyperboloidParamIntersect( float k, float yMinPercent, float yMaxPercent, float phiMaxRadians, vec3 ro, vec3 rd, out vec3 n )
//------------------------------------------------------------------------------------------------------------
{
	vec3 pHit;
	float t, t0, t1, phi;
	// implicit equation of a hyperboloid of 1 sheet (hourglass shape extending infinitely in the +Y and -Y directions):
	// x^2 + z^2 - y^2 - 1 = 0
	// implicit equation of a hyperboloid of 2 sheets (2 mirrored opposing paraboloids, non-connecting, top extends infinitely in +Y, bottom in -Y):
	// x^2 + z^2 - y^2 + 1 = 0
	
	// if the k argument is negative, a 2-sheet hyperboloid is created
	float j = k - 1.0;
	
	float a = k * rd.x * rd.x + k * rd.z * rd.z - j * rd.y * rd.y;
	float b = 2.0 * (k * rd.x * ro.x + k * rd.z * ro.z - j * rd.y * ro.y);
	float c = (k * ro.x * ro.x + k * ro.z * ro.z - j * ro.y * ro.y) - 1.0;
	solveQuadratic(a, b, c, t0, t1);
	if (t1 <= 0.0) return INFINITY;
	
	t = t0 > 0.0 ? t0 : INFINITY;
	pHit = ro + rd * t;
	phi = mod(atan(pHit.z, pHit.x), TWO_PI);
	if (pHit.y > yMaxPercent || pHit.y < yMinPercent || phi > phiMaxRadians)
	{
		t = t1;
		pHit = ro + rd * t;
		phi = mod(atan(pHit.z, pHit.x), TWO_PI);
		if (pHit.y > yMaxPercent || pHit.y < yMinPercent || phi > phiMaxRadians)
			t = INFINITY;
	}
	
	n = vec3(2.0 * pHit.x * k, 2.0 * -pHit.y * j, 2.0 * pHit.z * k);
	n = dot(rd, n) < 0.0 ? n : -n; // flip normal if it is facing away from us
		
	return t;
}
`;

THREE.ShaderChunk[ 'pathtracing_hyperbolic_paraboloid_param_intersect' ] = `
//------------------------------------------------------------------------------------------------------------
float HyperbolicParaboloidParamIntersect( float yMinPercent, float yMaxPercent, float phiMaxRadians, vec3 ro, vec3 rd, out vec3 n )
//------------------------------------------------------------------------------------------------------------
{
	vec3 pHit;
	float t, t0, t1, phi;
	// implicit equation of an infinite hyperbolic paraboloid (saddle shape):
	// x^2 - z^2 - y = 0
	float a = rd.x * rd.x - rd.z * rd.z;
	float b = 2.0 * (rd.x * ro.x - rd.z * ro.z) - rd.y;
	float c = (ro.x * ro.x - ro.z * ro.z) - ro.y;
	solveQuadratic(a, b, c, t0, t1);
	if (t1 <= 0.0) return INFINITY;
	t = t0 > 0.0 ? t0 : INFINITY;
	pHit = ro + rd * t;
	phi = mod(atan(pHit.z, pHit.x), TWO_PI);
	if (abs(pHit.x) > yMaxPercent || abs(pHit.y) > yMaxPercent || abs(pHit.z) > yMaxPercent || phi > phiMaxRadians)
	{
		t = t1;
		pHit = ro + rd * t;
		phi = mod(atan(pHit.z, pHit.x), TWO_PI);
		if (abs(pHit.x) > yMaxPercent || abs(pHit.y) > yMaxPercent || abs(pHit.z) > yMaxPercent || phi > phiMaxRadians)
			t = INFINITY;
	}
	
	n = vec3(2.0 * pHit.x, -1.0, -2.0 * pHit.z);
	n = dot(rd, n) < 0.0 ? n : -n; // flip normal if it is facing away from us
		
	return t;
}
`;

THREE.ShaderChunk[ 'pathtracing_ellipsoid_intersect' ] = `
//---------------------------------------------------------------------------------
float EllipsoidIntersect( vec3 radii, vec3 pos, vec3 rayOrigin, vec3 rayDirection )
//---------------------------------------------------------------------------------
{
	float t0, t1;
	vec3 oc = rayOrigin - pos;
	vec3 oc2 = oc*oc;
	vec3 ocrd = oc*rayDirection;
	vec3 rd2 = rayDirection*rayDirection;
	vec3 invRad = 1.0/radii;
	vec3 invRad2 = invRad*invRad;

	// quadratic equation coefficients
	float a = dot(rd2, invRad2);
	float b = 2.0*dot(ocrd, invRad2);
	float c = dot(oc2, invRad2) - 1.0;
	solveQuadratic(a, b, c, t0, t1);

	return t0 > 0.0 ? t0 : t1 > 0.0 ? t1 : INFINITY;
}
`;

THREE.ShaderChunk[ 'pathtracing_opencylinder_intersect' ] = `
//-------------------------------------------------------------------------------------------------------
float OpenCylinderIntersect( vec3 p0, vec3 p1, float rad, vec3 rayOrigin, vec3 rayDirection, out vec3 n )
//-------------------------------------------------------------------------------------------------------
{
	float r2=rad*rad;
	
	vec3 dp=p1-p0;
	vec3 dpt=dp/dot(dp,dp);
	
	vec3 ao=rayOrigin-p0;
	vec3 aoxab=cross(ao,dpt);
	vec3 vxab=cross(rayDirection,dpt);
	float ab2=dot(dpt,dpt);
	float a=2.0*dot(vxab,vxab);
	float ra=1.0/a;
	float b=2.0*dot(vxab,aoxab);
	float c=dot(aoxab,aoxab)-r2*ab2;
	
	float det=b*b-2.0*a*c;
	
	if (det<0.0) 
		return INFINITY;
	
	det=sqrt(det);
	
	float t0 = (-b-det)*ra;
	float t1 = (-b+det)*ra;
	
	vec3 ip;
	vec3 lp;
	float ct;
	if (t0 > 0.0)
	{
		ip=rayOrigin+rayDirection*t0;
		lp=ip-p0;
		ct=dot(lp,dpt);
		if((ct>0.0)&&(ct<1.0))
		{
			n=ip-(p0+dp*ct);
			return t0;
		}
	}
	
	if (t1 > 0.0)
	{
		ip=rayOrigin+rayDirection*t1;
		lp=ip-p0;
		ct=dot(lp,dpt);
		if((ct>0.0)&&(ct<1.0))
		{
		     	n=(p0+dp*ct)-ip;
			return t1;
		}
	}
	
	return INFINITY;
}
`;

THREE.ShaderChunk[ 'pathtracing_cappedcylinder_intersect' ] = `
//---------------------------------------------------------------------------------------------------------
float CappedCylinderIntersect( vec3 p0, vec3 p1, float rad, vec3 rayOrigin, vec3 rayDirection, out vec3 n )
//---------------------------------------------------------------------------------------------------------
{
	float r2=rad*rad;
	
	vec3 dp=p1-p0;
	vec3 dpt=dp/dot(dp,dp);
	
	vec3 ao=rayOrigin-p0;
	vec3 aoxab=cross(ao,dpt);
	vec3 vxab=cross(rayDirection,dpt);
	float ab2=dot(dpt,dpt);
	float a=2.0*dot(vxab,vxab);
	float ra=1.0/a;
	float b=2.0*dot(vxab,aoxab);
	float c=dot(aoxab,aoxab)-r2*ab2;
	
	float det=b*b-2.0*a*c;
	
	if(det<0.0)
		return INFINITY;
	
	det=sqrt(det);
	
	float t0=(-b-det)*ra;
	float t1=(-b+det)*ra;
	
	vec3 ip;
	vec3 lp;
	float ct;
	float result = INFINITY;
	
	// Cylinder caps
	// disk0
	vec3 diskNormal = normalize(dp);
	float denom = dot(diskNormal, rayDirection);
	vec3 pOrO = p0 - rayOrigin;
	float tDisk0 = dot(pOrO, diskNormal) / denom;
	if (tDisk0 > 0.0)
	{
		vec3 intersectPos = rayOrigin + rayDirection * tDisk0;
		vec3 v = intersectPos - p0;
		float d2 = dot(v,v);
		if (d2 <= r2)
		{
			result = tDisk0;
			n = diskNormal;
		}
	}
	
	// disk1
	denom = dot(diskNormal, rayDirection);
	pOrO = p1 - rayOrigin;
	float tDisk1 = dot(pOrO, diskNormal) / denom;
	if (tDisk1 > 0.0)
	{
		vec3 intersectPos = rayOrigin + rayDirection * tDisk1;
		vec3 v = intersectPos - p1;
		float d2 = dot(v,v);
		if (d2 <= r2 && tDisk1 < result)
		{
			result = tDisk1;
			n = diskNormal;
		}
	}
	
	// Cylinder body
	if (t1 > 0.0)
	{
		ip=rayOrigin+rayDirection*t1;
		lp=ip-p0;
		ct=dot(lp,dpt);
		if(ct>0.0 && ct<1.0 && t1<result)
		{
			result = t1;
		     	n=(p0+dp*ct)-ip;
		}
	}
	
	if (t0 > 0.0)
	{
		ip=rayOrigin+rayDirection*t0;
		lp=ip-p0;
		ct=dot(lp,dpt);
		if(ct>0.0 && ct<1.0 && t0<result)
		{
			result = t0;
			n=ip-(p0+dp*ct);
		}
	}
	
	return result;
}
`;

THREE.ShaderChunk[ 'pathtracing_cone_intersect' ] = `
//--------------------------------------------------------------------------------------------------------
float ConeIntersect( vec3 p0, float r0, vec3 p1, float r1, vec3 rayOrigin, vec3 rayDirection, out vec3 n )
//-------------------------------------------------------------------------------------------------------- 
{
	r0 += 0.1;
	vec3 locX;
	vec3 locY;
	vec3 locZ=-(p1-p0)/(1.0 - r1/r0);
	
	rayOrigin-=p0-locZ;
	
	if(abs(locZ.x)<abs(locZ.y))
		locX=vec3(1,0,0);
	else
		locX=vec3(0,1,0);
		
	float len=length(locZ);
	locZ=normalize(locZ)/len;
	locY=normalize(cross(locX,locZ))/r0;
	locX=normalize(cross(locY,locZ))/r0;
	
	mat3 tm;
	tm[0]=locX;
	tm[1]=locY;
	tm[2]=locZ;
	
	rayDirection*=tm;
	rayOrigin*=tm;
	
	float dx=rayDirection.x;
	float dy=rayDirection.y;
	float dz=rayDirection.z;
	
	float x0=rayOrigin.x;
	float y0=rayOrigin.y;
	float z0=rayOrigin.z;
	
	float x02=x0*x0;
	float y02=y0*y0;
	float z02=z0*z0;
	
	float dx2=dx*dx;
	float dy2=dy*dy;
	float dz2=dz*dz;
	
	float det=(
		-2.0*x0*dx*z0*dz
		+2.0*x0*dx*y0*dy
		-2.0*z0*dz*y0*dy
		+dz2*x02
		+dz2*y02
		+dx2*z02
		+dy2*z02
		-dy2*x02
		-dx2*y02
        );
	
	if(det<0.0)
		return INFINITY;
		
	float t0=(-x0*dx+z0*dz-y0*dy-sqrt(abs(det)))/(dx2-dz2+dy2);
	float t1=(-x0*dx+z0*dz-y0*dy+sqrt(abs(det)))/(dx2-dz2+dy2);
	vec3 pt0=rayOrigin+t0*rayDirection;
	vec3 pt1=rayOrigin+t1*rayDirection;
	
	if(t0>0.0 && pt0.z>r1/r0 && pt0.z<1.0)
	{
		n=pt0;
		n.z=0.0;
		n=normalize(n);
		n.z=-pt0.z/abs(pt0.z);
		n=normalize(n);
		n=tm*n;
		return t0;
	}
        if(t1>0.0 && pt1.z>r1/r0 && pt1.z<1.0)
	{
		n=pt1;
		n.z=0.0;
		n=normalize(n);
		n.z=-pt1.z/abs(pt1.z);
		n=normalize(n);
		n=tm*-n;
		return t1;
	}
	
	return INFINITY;	
}
`;


THREE.ShaderChunk[ 'pathtracing_capsule_intersect' ] = `
//-----------------------------------------------------------------------------------------------------------
float CapsuleIntersect( vec3 p0, float r0, vec3 p1, float r1, vec3 rayOrigin, vec3 rayDirection, out vec3 n )
//-----------------------------------------------------------------------------------------------------------
{
	/*
	// used for ConeIntersect below, if different radius sphere end-caps are desired
	vec3 l  = p1-p0;
	float ld = length(l);
	l=l/ld;
	float d= r0-r1;
	float sa = d/ld;
	float h0 = r0*sa;
	float h1 = r1*sa;
	float cr0 = sqrt(r0*r0-h0*h0);
	float cr1 = sqrt(r1*r1-h1*h1);
	vec3 coneP0=p0+l*h0;
	vec3 coneP1=p1+l*h1;
	*/
	
	float t0=INFINITY;
	    
	float t1;
	vec3 uv1;
	vec3 n1;
	//t1 = ConeIntersect(coneP0,cr0,coneP1,cr1,rayOrigin, rayDirection,n1);
	t1 = OpenCylinderIntersect(p0,p1,r0,rayOrigin, rayDirection,n1);
	if(t1<t0)
	{
		t0=t1;
		n=n1;
	}
	t1 = SphereIntersect(r0,p0,rayOrigin, rayDirection);
	if(t1<t0)
	{
		t0=t1;
		n=(rayOrigin + rayDirection * t1) - p0;
	}
	t1 = SphereIntersect(r1,p1,rayOrigin, rayDirection);
	if(t1<t0)
	{
		t0=t1;
		n=(rayOrigin + rayDirection * t1) - p1;
	}
	    
	return t0;
}
`;

THREE.ShaderChunk[ 'pathtracing_paraboloid_intersect' ] = `
//-----------------------------------------------------------------------------------------------------------
float ParaboloidIntersect( float rad, float height, vec3 pos, vec3 rayOrigin, vec3 rayDirection, out vec3 n )
//-----------------------------------------------------------------------------------------------------------
{
	vec3 rd = rayDirection;
	vec3 ro = rayOrigin - pos;
	float k = height / (rad * rad);
	
	// quadratic equation coefficients
	float a = k * (rd.x * rd.x + rd.z * rd.z);
	float b = k * 2.0 * (rd.x * ro.x + rd.z * ro.z) - rd.y;
	float c = k * (ro.x * ro.x + ro.z * ro.z) - ro.y;
	float t0, t1;
	solveQuadratic(a, b, c, t0, t1);
	
	vec3 ip;
	
	if (t0 > 0.0)
	{
		ip = ro + rd * t0;
		n = vec3( 2.0 * ip.x, -1.0 / k, 2.0 * ip.z );
		// flip normal if it is facing away from us
		n *= sign(-dot(rd, n)) * 2.0 - 1.0; // sign is 0 or 1, map it to -1 and +1
		
		if (ip.y < height)
			return t0;
				
	}
	if (t1 > 0.0)
	{	
		ip = ro + rd * t1;
		n = vec3( 2.0 * ip.x, -1.0 / k, 2.0 * ip.z );
		// flip normal if it is facing away from us
		n *= sign(-dot(rd, n)) * 2.0 - 1.0; // sign is 0 or 1, map it to -1 and +1
		
		if (ip.y < height)
			return t1;		
	}
	
	return INFINITY;	
}
`;

THREE.ShaderChunk[ 'pathtracing_hyperboloid_intersect' ] = `
//------------------------------------------------------------------------------------------------------------
float HyperboloidIntersect( float rad, float height, vec3 pos, vec3 rayOrigin, vec3 rayDirection, out vec3 n )
//------------------------------------------------------------------------------------------------------------
{
	vec3 rd = rayDirection;
	vec3 ro = rayOrigin - pos;
	float k = height / (rad * rad);
	
	// quadratic equation coefficients
	float a = k * ((rd.x * rd.x) - (rd.y * rd.y) + (rd.z * rd.z));
	float b = k * 2.0 * ( (rd.x * ro.x) - (rd.y * ro.y) + (rd.z * ro.z) );
	float c = k * ((ro.x * ro.x) - (ro.y * ro.y) + (ro.z * ro.z)) - (rad * rad);
	
	float t0, t1;
	solveQuadratic(a, b, c, t0, t1);
	
	vec3 ip;
	
	if (t0 > 0.0)
	{
		ip = ro + rd * t0;
		n = vec3( 2.0 * ip.x, -2.0 * ip.y, 2.0 * ip.z );
		// flip normal if it is facing away from us
		n *= sign(-dot(rd, n)) * 2.0 - 1.0; // sign is 0 or 1, map it to -1 and +1
		
		if (abs(ip.y) < height)
			return t0;		
	}
	if (t1 > 0.0)
	{	
		ip = ro + rd * t1;
		n = vec3( 2.0 * ip.x, -2.0 * ip.y, 2.0 * ip.z );
		// flip normal if it is facing away from us
		n *= sign(-dot(rd, n)) * 2.0 - 1.0; // sign is 0 or 1, map it to -1 and +1
		
		if (abs(ip.y) < height)
			return t1;	
	}
	
	return INFINITY;	
}
`;

THREE.ShaderChunk[ 'pathtracing_hyperbolic_paraboloid_intersect' ] = `
//---------------------------------------------------------------------------------------------------------------------
float HyperbolicParaboloidIntersect( float rad, float height, vec3 pos, vec3 rayOrigin, vec3 rayDirection, out vec3 n )
//---------------------------------------------------------------------------------------------------------------------
{
	vec3 rd = rayDirection;
	vec3 ro = rayOrigin - pos;
	float k = height / (rad * rad);
	
	// quadratic equation coefficients
	float a = k * (rd.x * rd.x - rd.z * rd.z);
	float b = k * 2.0 * (rd.x * ro.x - rd.z * ro.z) - rd.y;
	float c = k * (ro.x * ro.x - ro.z * ro.z) - ro.y;
	
	float t0, t1;
	solveQuadratic(a, b, c, t0, t1);
	
	vec3 ip;
	if (t0 > 0.0)
	{
		ip = ro + rd * t0;
		n = vec3( 2.0 * ip.x, -1.0 / k, -2.0 * ip.z );
		// flip normal if it is facing away from us
		n *= sign(-dot(rd, n)) * 2.0 - 1.0; // sign is 0 or 1, map it to -1 and +1
		
		if (abs(ip.x) < height && abs(ip.y) < height && abs(ip.z) < height)
			return t0;		
	}
	if (t1 > 0.0)
	{	
		ip = ro + rd * t1;
		n = vec3( 2.0 * ip.x, -1.0 / k, -2.0 * ip.z );
		// flip normal if it is facing away from us
		n *= sign(-dot(rd, n)) * 2.0 - 1.0; // sign is 0 or 1, map it to -1 and +1
		
		if (abs(ip.x) < height && abs(ip.y) < height && abs(ip.z) < height)
			return t1;		
	}
		
	return INFINITY;	
}
`;


THREE.ShaderChunk[ 'pathtracing_unit_torus_intersect' ] = `

// The following Torus quartic solver algo/code is from https://www.shadertoy.com/view/ssc3Dn by Shadertoy user 'mla'

float sgn(float x) 
{
	return x < 0.0 ? -1.0 : 1.0; // Return 1.0 for x == 0.0
}

float evalquadratic(float x, float A, float B, float C) 
{
  	return (A * x + B) * x + C;
}

float evalcubic(float x, float A, float B, float C, float D) 
{
  	return ((A * x + B) * x + C) * x + D;
}

// Quadratic solver from Kahan
int quadratic(float A, float B, float C, out vec2 res) 
{
  	float b = -0.5 * B, b2 = b * b;
  	float q = b2 - A * C;
  	if (q < 0.0) return 0;
  	float r = b + sgn(b) * sqrt(q);
  	if (r == 0.0) 
	{
  		res[0] = C / A;
    		res[1] = -res[0];
  	} 
	else 
	{
    		res[0] = C / r;
    		res[1] = r / A;
  	}

  	return 2;
}

// Numerical Recipes algorithm for solving cubic equation
int cubic(float a, float b, float c, float d, out vec3 res) 
{
  	if (a == 0.0) 
  	{
    		return quadratic(b, c, d, res.xy);
  	}
  	if (d == 0.0) 
  	{
    		res.x = 0.0;
    		return 1 + quadratic(a, b, c, res.yz);
  	}
  	float tmp = a; a = b / tmp; b = c / tmp; c = d / tmp;
  	// solve x^3 + ax^2 + bx + c = 0
  	float Q = (a * a - 3.0 * b) / 9.0;
  	float R = (2.0 * a * a * a - 9.0 * a * b + 27.0 * c) / 54.0;
  	float R2 = R * R, Q3 = Q * Q * Q;
  	if (R2 < Q3) 
  	{
    		float X = clamp(R / sqrt(Q3), -1.0, 1.0);
    		float theta = acos(X);
    		float S = sqrt(Q); // Q must be positive since 0 <= R2 < Q3
    		res[0] = -2.0 *S *cos(theta / 3.0) - a / 3.0;
    		res[1] = -2.0 *S *cos((theta + 2.0 * PI) / 3.0) - a / 3.0;
    		res[2] = -2.0 *S *cos((theta + 4.0 * PI) / 3.0) - a / 3.0;
    		return 3;
  	} 
  	else 
  	{
    		float alpha = -sgn(R) * pow(abs(R) + sqrt(R2 - Q3), 0.3333);
    		float beta = alpha == 0.0 ? 0.0 : Q / alpha;
    		res[0] = alpha + beta - a / 3.0;
    		return 1;
  	}
}

/* float qcubic(float B, float C, float D) {
  vec3 roots;
  int nroots = cubic(1.0,B,C,D,roots);
  // Sort into descending order
  if (nroots > 1 && roots.x < roots.y) roots.xy = roots.yx;
  if (nroots > 2) {
    if (roots.y < roots.z) roots.yz = roots.zy;
    if (roots.x < roots.y) roots.xy = roots.yx;
  }
  // And select the largest
  float psi = roots[0];
  psi = max(1e-6,psi);
  // and give a quick polish with Newton-Raphson
  for (int i = 0; i < 3; i++) {
    float delta = evalcubic(psi,1.0,B,C,D)/evalquadratic(psi,3.0,2.0*B,C);
    psi -= delta;
  }
  return psi;
} */

float qcubic(float B, float C, float D) 
{
  	vec3 roots;
  	int nroots = cubic(1.0, B, C, D, roots);
  	// Select the largest
  	float psi = roots[0];
  	if (nroots > 1) psi = max(psi, roots[1]);
  	if (nroots > 2) psi = max(psi, roots[2]);
  
  	// Give a quick polish with Newton-Raphson
  	float delta;
	delta = evalcubic(psi, 1.0, B, C, D) / evalquadratic(psi, 3.0, 2.0 * B, C);
	psi -= delta;
	delta = evalcubic(psi, 1.0, B, C, D) / evalquadratic(psi, 3.0, 2.0 * B, C);
    	psi -= delta;
  
  	return psi;
}

// The Lanczos quartic method
int lquartic(float c1, float c2, float c3, float c4, out vec4 res) 
{
  	float alpha = 0.5 * c1;
  	float A = c2 - alpha * alpha;
  	float B = c3 - alpha * A;
  	float a, b, beta, psi;
  	psi = qcubic(2.0 * A - alpha * alpha, A * A + 2.0 * B * alpha - 4.0 * c4, -B * B);
  	// There _should_ be a root >= 0, but sometimes the cubic
  	// solver misses it (probably a double root around zero).
  	psi = max(0.0, psi);
  	a = sqrt(psi);
  	beta = 0.5 * (A + psi);
  	if (psi <= 0.0) 
  	{
    		b = sqrt(max(beta * beta - c4, 0.0));
  	} 
  	else 
  	{
    		b = 0.5 * a * (alpha - B / psi);
  	}

  	int resn = quadratic(1.0, alpha + a, beta + b, res.xy);
  	vec2 tmp;
  	if (quadratic(1.0, alpha - a, beta - b, tmp) != 0) 
  	{ 
    		res.zw = res.xy;
    		res.xy = tmp;
    		resn += 2;
  	}

  	return resn;
}

// Note: the parameter below is renamed '_E', because Euler's number 'E' is already defined in 'pathtracing_defines_and_uniforms'
int quartic(float A, float B, float C, float D, float _E, out vec4 roots) 
{
	int nroots;
  	// Sometimes it's advantageous to solve for the reciprocal (if there are very large solutions)
  	if (abs(B / A) < abs(D /_E)) 
	{
    		nroots = lquartic(B / A, C / A, D / A,_E / A, roots);
  	} 
	else 
	{
    		nroots = lquartic(D /_E, C /_E, B /_E, A /_E, roots);
    		for (int i = 0; i < nroots; i++) 
		{
      			roots[i] = 1.0 / roots[i];
    		}
  	}
  
  	return nroots;
}


float UnitTorusIntersect(vec3 ro, vec3 rd, float k, out vec3 n) 
{
	// Note: the vec3 'rd' might not be normalized to unit length of 1, 
	//  in order to allow for inverse transform of intersecting rays into Torus' object space
	k = mix(0.5, 1.0, k);
	float torus_R = max(0.0, k); // outer extent of the entire torus/ring
	float torus_r = max(0.01, 1.0 - k); // thickness of circular 'tubing' part of torus/ring
	float torusR2 = torus_R * torus_R;
	float torusr2 = torus_r * torus_r;
	
	float U = dot(rd, rd);
	float V = 2.0 * dot(ro, rd);
	float W = dot(ro, ro) - (torusR2 + torusr2);
	// A*t^4 + B*t^3 + C*t^2 + D*t + _E = 0
	float A = U * U;
	float B = 2.0 * U * V;
	float C = V * V + 2.0 * U * W + 4.0 * torusR2 * rd.z * rd.z;
	float D = 2.0 * V * W + 8.0 * torusR2 * ro.z * rd.z;
// Note: the float below is renamed '_E', because Euler's number 'E' is already defined in 'pathtracing_defines_and_uniforms'
	float _E = W * W + 4.0 * torusR2 * (ro.z * ro.z - torusr2);

	vec4 res = vec4(0);
	int nr = quartic(A, B, C, D, _E, res);
	if (nr == 0) return INFINITY;
  	// Sort the roots.
  	if (res.x > res.y) res.xy = res.yx; 
  	if (nr > 2) 
	{
    		if (res.y > res.z) res.yz = res.zy; 
    		if (res.x > res.y) res.xy = res.yx;
  	}
	if (nr > 3) 
	{
		if (res.z > res.w) res.zw = res.wz; 
		if (res.y > res.z) res.yz = res.zy; 
		if (res.x > res.y) res.xy = res.yx; 
	}
  
	float t = INFINITY;
	
	t = (res.w > 0.0) ? res.w : t;	
	t = (res.z > 0.0) ? res.z : t;
	t = (res.y > 0.0) ? res.y : t;	
	t = (res.x > 0.0) ? res.x : t;
		
	vec3 pos = ro + t * rd;
	//n = pos * (dot(pos, pos) - torusr2 - torusR2 * vec3(1, 1,-1));

	float kn = sqrt(torusR2 / dot(pos.xy, pos.xy));
	pos.xy -= kn * pos.xy;
	n = pos;
	
  	return t;
}

`;


THREE.ShaderChunk[ 'pathtracing_quad_intersect' ] = `
float TriangleIntersect( vec3 v0, vec3 v1, vec3 v2, vec3 rayOrigin, vec3 rayDirection, bool isDoubleSided )
{
	vec3 edge1 = v1 - v0;
	vec3 edge2 = v2 - v0;
	vec3 pvec = cross(rayDirection, edge2);
	float det = 1.0 / dot(edge1, pvec);
	if ( !isDoubleSided && det < 0.0 ) 
		return INFINITY;
	vec3 tvec = rayOrigin - v0;
	float u = dot(tvec, pvec) * det;
	vec3 qvec = cross(tvec, edge1);
	float v = dot(rayDirection, qvec) * det;
	float t = dot(edge2, qvec) * det;
	return (u < 0.0 || u > 1.0 || v < 0.0 || u + v > 1.0 || t <= 0.0) ? INFINITY : t;
}
//--------------------------------------------------------------------------------------------------------------
float QuadIntersect( vec3 v0, vec3 v1, vec3 v2, vec3 v3, vec3 rayOrigin, vec3 rayDirection, bool isDoubleSided )
//--------------------------------------------------------------------------------------------------------------
{
	return min(TriangleIntersect(v0, v1, v2, rayOrigin, rayDirection, isDoubleSided), 
		   TriangleIntersect(v0, v2, v3, rayOrigin, rayDirection, isDoubleSided));
}
`;

THREE.ShaderChunk[ 'pathtracing_box_intersect' ] = `
//-----------------------------------------------------------------------------------------------------------------------------
float BoxIntersect( vec3 minCorner, vec3 maxCorner, vec3 rayOrigin, vec3 rayDirection, out vec3 normal, out bool isRayExiting )
//-----------------------------------------------------------------------------------------------------------------------------
{
	vec3 invDir = 1.0 / rayDirection;
	vec3 near = (minCorner - rayOrigin) * invDir;
	vec3 far  = (maxCorner - rayOrigin) * invDir;

	vec3 tmin = min(near, far);
	vec3 tmax = max(near, far);

	float t0 = max( max(tmin.x, tmin.y), tmin.z);
	float t1 = min( min(tmax.x, tmax.y), tmax.z);

	if (t0 > t1) return INFINITY;
	if (t0 > 0.0) // if we are outside the box
	{
		normal = -sign(rayDirection) * step(tmin.yzx, tmin) * step(tmin.zxy, tmin);
		isRayExiting = false;
		return t0;
	}
	if (t1 > 0.0) // if we are inside the box
	{
		normal = -sign(rayDirection) * step(tmax, tmax.yzx) * step(tmax, tmax.zxy);
		isRayExiting = true;
		return t1;
	}
	return INFINITY;
}
`;

THREE.ShaderChunk[ 'pathtracing_boundingbox_intersect' ] = `
//--------------------------------------------------------------------------------------
float BoundingBoxIntersect( vec3 minCorner, vec3 maxCorner, vec3 rayOrigin, vec3 invDir )
//--------------------------------------------------------------------------------------
{
	vec3 near = (minCorner - rayOrigin) * invDir;
	vec3 far  = (maxCorner - rayOrigin) * invDir;
	
	vec3 tmin = min(near, far);
	vec3 tmax = max(near, far);
	
	float t0 = max( max(tmin.x, tmin.y), tmin.z);
	float t1 = min( min(tmax.x, tmax.y), tmax.z);
	
	//return t1 >= max(t0, 0.0) ? t0 : INFINITY;
	return max(t0, 0.0) > t1 ? INFINITY : t0;
}
`;



THREE.ShaderChunk[ 'pathtracing_bvhTriangle_intersect' ] = `
//-------------------------------------------------------------------------------------------------------------------
float BVH_TriangleIntersect( vec3 v0, vec3 v1, vec3 v2, vec3 rayOrigin, vec3 rayDirection, out float u, out float v )
//-------------------------------------------------------------------------------------------------------------------
{
	vec3 edge1 = v1 - v0;
	vec3 edge2 = v2 - v0;
	vec3 pvec = cross(rayDirection, edge2);
	float det = 1.0 / dot(edge1, pvec);
	vec3 tvec = rayOrigin - v0;
	u = dot(tvec, pvec) * det;
	vec3 qvec = cross(tvec, edge1);
	v = dot(rayDirection, qvec) * det;
	float t = dot(edge2, qvec) * det;
	return (det < 0.0 || u < 0.0 || u > 1.0 || v < 0.0 || u + v > 1.0 || t <= 0.0) ? INFINITY : t;
}
`;

THREE.ShaderChunk[ 'pathtracing_bvhDoubleSidedTriangle_intersect' ] = `
//------------------------------------------------------------------------------------------------------------------------------
float BVH_DoubleSidedTriangleIntersect( vec3 v0, vec3 v1, vec3 v2, vec3 rayOrigin, vec3 rayDirection, out float u, out float v )
//------------------------------------------------------------------------------------------------------------------------------
{
	vec3 edge1 = v1 - v0;
	vec3 edge2 = v2 - v0;
	vec3 pvec = cross(rayDirection, edge2);
	float det = 1.0 / dot(edge1, pvec);
	vec3 tvec = rayOrigin - v0;
	u = dot(tvec, pvec) * det;
	vec3 qvec = cross(tvec, edge1);
	v = dot(rayDirection, qvec) * det; 
	float t = dot(edge2, qvec) * det;
	return (u < 0.0 || u > 1.0 || v < 0.0 || u + v > 1.0 || t <= 0.0) ? INFINITY : t;
}
`;

THREE.ShaderChunk[ 'pathtracing_physical_sky_functions' ] = `
float RayleighPhase(float cosTheta)
{
	return THREE_OVER_SIXTEENPI * (1.0 + (cosTheta * cosTheta));
}

float hgPhase(float cosTheta, float g)
{
        float g2 = g * g;
        float inverse = 1.0 / pow(max(0.0, 1.0 - 2.0 * g * cosTheta + g2), 1.5);
	return ONE_OVER_FOURPI * ((1.0 - g2) * inverse);
}

vec3 totalMie()
{
	float c = (0.2 * TURBIDITY) * 10E-18;
	return 0.434 * c * MIE_CONST;
}

float SunIntensity(float zenithAngleCos)
{
	zenithAngleCos = clamp( zenithAngleCos, -1.0, 1.0 );
	return SUN_POWER * max( 0.0, 1.0 - pow( E, -( ( CUTOFF_ANGLE - acos( zenithAngleCos ) ) / STEEPNESS ) ) );
}

vec3 Get_Sky_Color(vec3 rayDir)
{
	vec3 viewDirection = normalize(rayDir);
	
	/* most of the following code is borrowed from the three.js shader file: SkyShader.js */
    	// Cosine angles
	float cosViewSunAngle = dot(viewDirection, uSunDirection);
    	float cosSunUpAngle = dot(UP_VECTOR, uSunDirection); // allowed to be negative: + is daytime, - is nighttime
    	float cosUpViewAngle = dot(UP_VECTOR, viewDirection);
	
        // Get sun intensity based on how high in the sky it is
    	float sunE = SunIntensity(cosSunUpAngle);
        
	// extinction (absorbtion + out scattering)
	// rayleigh coefficients
    	vec3 rayleighAtX = TOTAL_RAYLEIGH * RAYLEIGH_COEFFICIENT;
    
	// mie coefficients
	vec3 mieAtX = totalMie() * MIE_COEFFICIENT;  
    
	// optical length
	float zenithAngle = acos( max( 0.0, dot( UP_VECTOR, viewDirection ) ) );
	float inverse = 1.0 / ( cos( zenithAngle ) + 0.15 * pow( 93.885 - ( ( zenithAngle * 180.0 ) / PI ), -1.253 ) );
	float rayleighOpticalLength = RAYLEIGH_ZENITH_LENGTH * inverse;
	float mieOpticalLength = MIE_ZENITH_LENGTH * inverse;
	// combined extinction factor	
	vec3 Fex = exp(-(rayleighAtX * rayleighOpticalLength + mieAtX * mieOpticalLength));
	// in scattering
	vec3 betaRTheta = rayleighAtX * RayleighPhase(cosViewSunAngle * 0.5 + 0.5);
	vec3 betaMTheta = mieAtX * hgPhase(cosViewSunAngle, MIE_DIRECTIONAL_G);
	
	vec3 Lin = pow( sunE * ( ( betaRTheta + betaMTheta ) / ( rayleighAtX + mieAtX ) ) * ( 1.0 - Fex ), vec3( 1.5 ) );
	Lin *= mix( vec3( 1.0 ), pow( sunE * ( ( betaRTheta + betaMTheta ) / ( rayleighAtX + mieAtX ) ) * Fex, vec3( 1.0 / 2.0 ) ), clamp( pow( 1.0 - cosSunUpAngle, 5.0 ), 0.0, 1.0 ) );
	// nightsky
	float theta = acos( viewDirection.y ); // elevation --> y-axis, [-pi/2, pi/2]
	float phi = atan( viewDirection.z, viewDirection.x ); // azimuth --> x-axis [-pi/2, pi/2]
	vec2 uv = vec2( phi, theta ) / vec2( 2.0 * PI, PI ) + vec2( 0.5, 0.0 );
	vec3 L0 = vec3( 0.1 ) * Fex;
	// composition + solar disc
	float sundisk = smoothstep( SUN_ANGULAR_DIAMETER_COS, SUN_ANGULAR_DIAMETER_COS + 0.00002, cosViewSunAngle );
	L0 += ( sunE * 19000.0 * Fex ) * sundisk;
	vec3 texColor = ( Lin + L0 ) * 0.04 + vec3( 0.0, 0.0003, 0.00075 );
	float sunfade = 1.0 - clamp( 1.0 - exp( ( uSunDirection.y / 450000.0 ) ), 0.0, 1.0 );
	vec3 retColor = pow( texColor, vec3( 1.0 / ( 1.2 + ( 1.2 * sunfade ) ) ) );
	return retColor;
}
`;

THREE.ShaderChunk[ 'pathtracing_pbr_material_functions' ] = `

/*  All of the following GGX functions come from this great tutorial/resource:
	http://cwyman.org/code/dxrTutors/tutors/Tutor14/tutorial14.md.html */


// The NDF for GGX, see Eqn 19 from 
//    http://blog.selfshadow.com/publications/s2012-shading-course/hoffman/s2012_pbs_physics_math_notes.pdf
//
// This function can be used for "D" in the Cook-Torrance model:  D*G*F / (4*NdotL*NdotV)
float ggxNormalDistribution(float NdotH, float roughness)
{
	float a2 = roughness * roughness;
	float d = ((NdotH * a2 - NdotH) * NdotH + 1.0);
	return a2 / max(0.001, (d * d * PI));
}

// This from Schlick 1994, modified as per Karas in SIGGRAPH 2013 "Physically Based Shading" course
//
// This function can be used for "G" in the Cook-Torrance model:  D*G*F / (4*NdotL*NdotV)
float ggxSchlickMaskingTerm(float NdotL, float NdotV, float roughness)
{
	// Karis notes they use alpha / 2 (or roughness^2 / 2)
	float k = (roughness * roughness) * 0.5;

	// Karis also notes they can use the following equation, but only for analytical lights
	//float k = (roughness + 1.0) * (roughness + 1.0) / 8.0; 

	// Compute G(v) and G(l).  These equations directly from Schlick 1994
	float g_v = NdotV / (NdotV * (1.0 - k) + k);
	float g_l = NdotL / (NdotL * (1.0 - k) + k);

	// Return G(v) * G(l)
	return g_v * g_l;
}

// Traditional Schlick approximation to the Fresnel term (also from Schlick 1994)
//
// This function can be used for "F" in the Cook-Torrance model:  D*G*F / (4*NdotL*NdotV)
vec3 schlickFresnel(vec3 f0, float u)
{
	float U = 1.0 - u;
	return f0 + (vec3(1) - f0) * (U * U * U * U * U); // same as  * pow(1.0 - u, 5.0);
}

// Get a GGX half vector / microfacet normal, sampled according to the distribution computed by
//     the function ggxNormalDistribution() above.  
//
// When using this function to sample, the probability density is pdf = D * NdotH / (4 * HdotV)
vec3 getGGXMicrofacet(float roughness, vec3 nl)
{
	float r0 = rng();
	// GGX NDF sampling
	float a2 = roughness * roughness;
	float cosThetaH = sqrt(max(0.0, (1.0 - r0) / ((a2 - 1.0) * r0 + 1.0)));
	float sinThetaH = sqrt(max(0.0, 1.0 - cosThetaH * cosThetaH));
	float phiH = rng() * TWO_PI;

	// Get an orthonormal basis from the normal
	vec3 T = normalize(cross(nl.yzx, nl));
	vec3 B = cross(nl, T);

	// Get our GGX NDF sample (i.e., the half vector)
	return normalize(T * sinThetaH * cos(phiH) + B * sinThetaH * sin(phiH) + nl * cosThetaH);
}

float luminance(vec3 color)
{ 
	//return dot(color, vec3(0.299, 0.587, 0.114));
	return dot(color, vec3(0.2126, 0.7152, 0.0722));
}
// Our material has both a diffuse and a specular lobe.  
//     With what probability should we sample the diffuse one?
float probabilityToSampleDiffuse(vec3 difColor, vec3 specColor)
{
	float lumDiffuse = max(0.001, luminance(difColor));
	float lumSpecular = max(0.001, luminance(specColor));
	return lumDiffuse / (lumDiffuse + lumSpecular);
}

vec3 ggxDirect(Sphere light, vec3 hitPoint, vec3 N, vec3 difColor, vec3 specColor, float roughness, out vec3 L)
{
	vec3 V = -rayDirection;
	float weight;
	L = sampleSphereLight(hitPoint, N, light, weight);
	// Compute our lambertian term (N dot L)
	float NdotL = clamp(dot(N, L), 0.001, 1.0);

	// Compute half vectors and additional dot products for GGX
	vec3 H = normalize(V + L);
	float NdotH = clamp(dot(N, H), 0.001, 1.0);
	float LdotH = clamp(dot(L, H), 0.001, 1.0);
	float NdotV = clamp(dot(N, V), 0.001, 1.0);

	// Evaluate terms for our GGX BRDF model
	float D = ggxNormalDistribution(NdotH, roughness);
	float G = ggxSchlickMaskingTerm(NdotL, NdotV, roughness);
	vec3  F = schlickFresnel(specColor, LdotH);

	// Evaluate the Cook-Torrance Microfacet BRDF model
	//     Cancel out NdotL here & the next eq. to avoid catastrophic numerical precision issues.
	vec3 ggxTerm = D * G * F / (4.0 * NdotV /* * NdotL */);

	// Compute our final color (combining diffuse lobe plus specular GGX lobe)
	return (/* NdotL * */ ggxTerm + weight * difColor / PI);
}

vec3 ggxIndirect(vec3 hitPoint, vec3 N, vec3 difColor, vec3 specColor, float roughness, out vec3 L, inout int diffuseCount)
{
	// We have to decide whether we sample our diffuse or specular/ggx lobe.
	float probDiffuse = probabilityToSampleDiffuse(difColor, specColor);
	bool chooseDiffuse = rng() < probDiffuse;

	vec3 V = -rayDirection;
	// We'll need NdotV for both diffuse and specular...
	float NdotV = clamp(dot(N, V), 0.001, 1.0);

	// If we randomly selected to sample our diffuse lobe...
	if (chooseDiffuse)
	{
		diffuseCount++;
		// Choose a randomly selected cosine-sampled diffuse ray.
		L = randomCosWeightedDirectionInHemisphere(N);

		// Check to make sure our randomly selected, normal mapped diffuse ray didn't go below the surface.
		//if (dot(noNormalN, L) <= 0.0) return vec3(0, 0, 0);

		// Accumulate the color: (NdotL * incomingLight * dif / pi) 
		// Probability of sampling:  (NdotL / pi) * probDiffuse
		return difColor / probDiffuse;
	}
	// Otherwise we randomly selected to sample our GGX lobe
	else
	{
		// Randomly sample the NDF to get a microfacet in our BRDF to reflect off of
		vec3 H = getGGXMicrofacet(roughness, N);

		// Compute the outgoing direction based on this (perfectly reflective) microfacet
		L = reflect(rayDirection, H);

		// Check to make sure our randomly selected, normal mapped diffuse ray didn't go below the surface.
		//if (dot(noNormalN, L) <= 0.0) return vec3(0, 0, 0);

		// Compute some dot products needed for shading
		float NdotL = clamp(dot(N, L), 0.001, 1.0);
		float NdotH = clamp(dot(N, H), 0.001, 1.0);
		float LdotH = clamp(dot(L, H), 0.001, 1.0);

		// Evaluate our BRDF using a microfacet BRDF model
		float D = ggxNormalDistribution(NdotH, roughness);        // The GGX normal distribution
		float G = ggxSchlickMaskingTerm(NdotL, NdotV, roughness); // Use Schlick's masking term approx
		vec3  F = schlickFresnel(specColor, LdotH);               // Use Schlick's approx to Fresnel
		vec3  ggxTerm = D * G * F / (4.0 * NdotL * NdotV);        // The Cook-Torrance microfacet BRDF

		// What's the probability of sampling vector H from getGGXMicrofacet()?
		float  ggxProb = D * NdotH / (4.0 * LdotH);

		// Accumulate the color:  ggx-BRDF * incomingLight * NdotL / probability-of-sampling
		//    -> Should really simplify the math above.
		return NdotL * ggxTerm / (ggxProb * (1.0 - probDiffuse));
	}
}

`;

THREE.ShaderChunk[ 'pathtracing_random_functions' ] = `
// globals used in rand() function
vec4 randVec4; // samples and holds the RGBA blueNoise texture value for this pixel
float randNumber; // the final randomly generated number (range: 0.0 to 1.0)
float counter; // will get incremented by 1 on each call to rand()
int channel; // the final selected color channel to use for rand() calc (range: 0 to 3, corresponds to R,G,B, or A)
float rand()
{
	counter++; // increment counter by 1 on every call to rand()
	// cycles through channels, if modulus is 1.0, channel will always be 0 (the R color channel)
	channel = int(mod(counter, 2.0)); 
	// but if modulus was 4.0, channel will cycle through all available channels: 0,1,2,3,0,1,2,3, and so on...
	randNumber = randVec4[channel]; // get value stored in channel 0:R, 1:G, 2:B, or 3:A
	return fract(randNumber); // we're only interested in randNumber's fractional value between 0.0 (inclusive) and 1.0 (non-inclusive)
	//return clamp(randNumber,0.0,0.999999999); // we're only interested in randNumber's fractional value between 0.0 (inclusive) and 1.0 (non-inclusive)
}
// from iq https://www.shadertoy.com/view/4tXyWN
// global seed used in rng() function
uvec2 seed;
float rng()
{
	seed += uvec2(1);
    	uvec2 q = 1103515245U * ( (seed >> 1U) ^ (seed.yx) );
    	uint  n = 1103515245U * ( (q.x) ^ (q.y >> 3U) );
	return float(n) * (1.0 / float(0xffffffffU));
}

vec3 randomSphereDirection()
{
    	float up = rng() * 2.0 - 1.0; // range: -1 to +1
	float over = sqrt( max(0.0, 1.0 - up * up) );
	float around = rng() * TWO_PI;
	return normalize(vec3(cos(around) * over, up, sin(around) * over));	
}

/* vec3 randomCosWeightedDirectionInHemisphere(vec3 nl)
{
	float r0 = sqrt(rng());
	float phi = rng() * TWO_PI;
	float x = r0 * cos(phi);
	float y = r0 * sin(phi);
	float z = sqrt(1.0 - r0 * r0);
	vec3 T = normalize(cross(nl.yzx, nl));
	vec3 B = cross(nl, T);
	return normalize(T * x + B * y + nl * z);
} */

//the following alternative skips the creation of tangent and bi-tangent vectors T and B
vec3 randomCosWeightedDirectionInHemisphere(vec3 nl)
{
	float z = rng() * 2.0 - 1.0;
	float phi = rng() * TWO_PI;
	float r = sqrt(1.0 - z * z);
    	return normalize(nl + vec3(r * cos(phi), r * sin(phi), z));
}

vec3 randomDirectionInSpecularLobe(vec3 reflectionDir, float roughness)
{
	float z = rng() * 2.0 - 1.0;
	float phi = rng() * TWO_PI;
	float r = sqrt(1.0 - z * z);
    	vec3 cosDiffuseDir = normalize(reflectionDir + vec3(r * cos(phi), r * sin(phi), z));
	return normalize( mix(reflectionDir, cosDiffuseDir, roughness * roughness) );
}

/* vec3 randomDirectionInPhongSpecular(vec3 reflectionDir, float shininess)
{
	float cosTheta = pow(rng(), 1.0 / (2.0 + shininess));
	float sinTheta = sqrt(1.0 - cosTheta * cosTheta);
	float phi = rng() * TWO_PI;
	float x = sinTheta * cos(phi);
	float y = sinTheta * sin(phi);
	vec3 T = normalize(cross(reflectionDir.yzx, reflectionDir));
	vec3 B = cross(reflectionDir, T);
	return normalize(T * x + B * y + reflectionDir * cosTheta);
} */

/* 
// this is my crude attempt at a Fibonacci-spiral sample point pattern on a hemisphere above a diffuse surface
#define N_POINTS 64.0 //64.0
vec3 randomCosWeightedDirectionInHemisphere(vec3 nl)
{
	float i = N_POINTS * rng();
			// the Golden angle in radians
	float phi = mod(i * 2.39996322972865332, TWO_PI);
	float r = sqrt(i / N_POINTS); // sqrt pushes points outward to prevent clumping in center of disk
	float x = r * cos(phi);
	float y = r * sin(phi);
	float z = sqrt(1.0 - r * r);
	
	vec3 U = normalize( cross( abs(nl.y) < 0.9 ? vec3(0, 1, 0) : vec3(0, 0, 1), nl ) );
	vec3 V = cross(nl, U);
	return normalize(x * U + y * V + z * nl);
} */

/* 
// like the function several functions above, 
// the following alternative skips the creation of tangent and bi-tangent vectors T and B 
vec3 randomCosWeightedDirectionInHemisphere(vec3 nl)
{
	float phi = rng() * TWO_PI;
	float theta = rng() * 2.0 - 1.0;
	return normalize(nl + vec3(sqrt(1.0 - theta * theta) * vec2(cos(phi), sin(phi)), theta));
} */

`;


THREE.ShaderChunk[ 'pathtracing_sample_sphere_light' ] = `
vec3 sampleSphereLight(vec3 x, vec3 nl, Sphere light, out float weight)
{
	vec3 dirToLight = (light.position - x); // no normalize (for distance calc below)
	float cos_alpha_max = sqrt(1.0 - clamp((light.radius * light.radius) / dot(dirToLight, dirToLight), 0.0, 1.0));
	float r0 = rng();
	float cos_alpha = 1.0 - r0 + r0 * cos_alpha_max;//mix( cos_alpha_max, 1.0, rng() );
	// * 0.75 below ensures shadow rays don't miss smaller sphere lights, due to shader float precision
	float sin_alpha = sqrt(max(0.0, 1.0 - cos_alpha * cos_alpha)) * 0.75; 
	float phi = rng() * TWO_PI;
	dirToLight = normalize(dirToLight);
	
	vec3 U = normalize( cross( abs(dirToLight.y) < 0.9 ? vec3(0, 1, 0) : vec3(0, 0, 1), dirToLight ) );
	vec3 V = cross(dirToLight, U);
	
	vec3 sampleDir = normalize(U * cos(phi) * sin_alpha + V * sin(phi) * sin_alpha + dirToLight * cos_alpha);
	weight = clamp(2.0 * (1.0 - cos_alpha_max) * max(0.0, dot(nl, sampleDir)), 0.0, 1.0);
	
	return sampleDir;
}
`;

THREE.ShaderChunk[ 'pathtracing_sample_quad_light' ] = `
vec3 sampleQuadLight(vec3 x, vec3 nl, Quad light, out float weight)
{
	vec3 randPointOnLight;
	randPointOnLight.x = mix(light.v0.x, light.v2.x, clamp(rng(), 0.1, 0.9));
	randPointOnLight.y = light.v0.y;
	randPointOnLight.z = mix(light.v0.z, light.v2.z, clamp(rng(), 0.1, 0.9));
	vec3 dirToLight = randPointOnLight - x;
	float r2 = distance(light.v0, light.v1) * distance(light.v0, light.v3);
	float d2 = dot(dirToLight, dirToLight);
	float cos_a_max = sqrt(1.0 - clamp( r2 / d2, 0.0, 1.0));
	dirToLight = normalize(dirToLight);
	float dotNlRayDir = max(0.0, dot(nl, dirToLight)); 
	weight =  2.0 * (1.0 - cos_a_max) * max(0.0, -dot(dirToLight, light.normal)) * dotNlRayDir; 
	weight = clamp(weight, 0.0, 1.0);
	return dirToLight;
}
`;

THREE.ShaderChunk[ 'pathtracing_calc_fresnel_reflectance' ] = `
float calcFresnelReflectance(vec3 rayDirection, vec3 n, float etai, float etat, out float ratioIoR)
{
	float temp = etai;
	float cosi = clamp(dot(rayDirection, n), -1.0, 1.0);
	if (cosi > 0.0)
	{
		etai = etat;
		etat = temp;
	}
	
	ratioIoR = etai / etat;
	float sint = ratioIoR * sqrt(1.0 - (cosi * cosi));
	if (sint >= 1.0) 
		return 1.0; // total internal reflection
	float cost = sqrt(1.0 - (sint * sint));
	cosi = abs(cosi);
	float Rs = ((etat * cosi) - (etai * cost)) / ((etat * cosi) + (etai * cost));
	float Rp = ((etai * cosi) - (etat * cost)) / ((etai * cosi) + (etat * cost));
	return clamp( ((Rs * Rs) + (Rp * Rp)) * 0.5, 0.0, 1.0 );
}
`;

THREE.ShaderChunk[ 'pathtracing_main' ] = `
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
	counter = -1.0; // will get incremented by 1 on each call to rand()
	channel = 0; // the final selected color channel to use for rand() calc (range: 0 to 3, corresponds to R,G,B, or A)
	randNumber = 0.0; // the final randomly-generated number (range: 0.0 to 1.0)
	randVec4 = vec4(0); // samples and holds the RGBA blueNoise texture value for this pixel
	randVec4 = texelFetch(tBlueNoiseTexture, ivec2(mod(gl_FragCoord.xy + floor(uRandomVec2 * 256.0), 256.0)), 0);
	
	// rand() produces higher FPS and almost immediate convergence, but may have very slight jagged diagonal edges on higher frequency color patterns, i.e. checkerboards.
	// rng() has a little less FPS on mobile, and a little more noisy initially, but eventually converges on perfect anti-aliased edges - use this if 'beauty-render' is desired.
	vec2 pixelOffset = uFrameCounter < 150.0 ? vec2( tentFilter(rand()), tentFilter(rand()) ) :
					      	   vec2( tentFilter(rng()), tentFilter(rng()) );
	
	// we must map pixelPos into the range -1.0 to +1.0: (-1.0,-1.0) is bottom-left screen corner, (1.0,1.0) is top-right
	vec2 pixelPos = ((gl_FragCoord.xy + pixelOffset) / uResolution) * 2.0 - 1.0;

	vec3 rayDir = uUseOrthographicCamera ? camForward : 
					       normalize( pixelPos.x * camRight * uULen + pixelPos.y * camUp * uVLen + camForward );

	// depth of field
	vec3 focalPoint = uFocusDistance * rayDir;
	float randomAngle = rng() * TWO_PI; // pick random point on aperture
	float randomRadius = rng() * uApertureSize;
	vec3  randomAperturePos = ( cos(randomAngle) * camRight + sin(randomAngle) * camUp ) * sqrt(randomRadius);
	// point on aperture to focal point
	vec3 finalRayDir = normalize(focalPoint - randomAperturePos);

	rayOrigin = uUseOrthographicCamera ? cameraPosition + (camRight * pixelPos.x * uULen * 100.0) + (camUp * pixelPos.y * uVLen * 100.0) + randomAperturePos :
					     cameraPosition + randomAperturePos;
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
	edge0 = 0.0;
	edge1 = 0.5;
	float difference_obj = abs(dFdx(objectID)) > 0.0 ? 1.0 : 0.0;
	difference_obj += abs(dFdy(objectID)) > 0.0 ? 1.0 : 0.0;
	float objectDifference = smoothstep(edge0, edge1, difference_obj);
	float difference_col = length(dFdx(objectColor)) > 0.0 ? 1.0 : 0.0;
	difference_col += length(dFdy(objectColor)) > 0.0 ? 1.0 : 0.0;
	float colorDifference = smoothstep(edge0, edge1, difference_col);
	// edge detector (normal and object differences) white-line debug visualization
	//currentPixel.rgb += 1.0 * vec3(max(normalDifference, objectDifference));
	// edge detector (color difference) white-line debug visualization
	//currentPixel.rgb += 1.0 * vec3(colorDifference);

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

	// if current raytraced pixel didn't return any color value, just use the previous frame's pixel color
	if (currentPixel.rgb == vec3(0.0))
	{
		currentPixel.rgb = previousPixel.rgb;
		previousPixel.rgb *= 0.5;
		currentPixel.rgb *= 0.5;
	}


	if (colorDifference >= 1.0 || normalDifference >= 1.0 || objectDifference >= 1.0)
		pixelSharpness = 1.01;


	currentPixel.a = pixelSharpness;

	// Eventually, all edge-containing pixels' .a (alpha channel) values will converge to 1.01, which keeps them from getting blurred by the box-blur filter, thus retaining sharpness.
	if (previousPixel.a == 1.01)
		currentPixel.a = 1.01;

	pc_fragColor = vec4(previousPixel.rgb + currentPixel.rgb, currentPixel.a);
}
`;
