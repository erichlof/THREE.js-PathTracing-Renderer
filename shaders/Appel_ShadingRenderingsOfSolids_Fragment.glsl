precision highp float;
precision highp int;
precision highp sampler2D;

uniform sampler2D tLightTexture;
uniform sampler2D tMedLightTexture;
uniform sampler2D tMediumTexture;
uniform sampler2D tMedDarkTexture;
uniform sampler2D tDarkTexture;
uniform mat4 uCSG_ShapeA_InvMatrix;
uniform mat4 uCSG_ShapeB_InvMatrix;
uniform mat4 uCSG_ShapeC_InvMatrix;
uniform mat4 uCSG_ShapeD_InvMatrix;
uniform mat4 uCSG_ShapeE_InvMatrix;
uniform mat4 uCSG_ShapeF_InvMatrix;
uniform vec3 uSunDirection;
uniform float uA_kParameter;
uniform float uB_kParameter;
uniform float uC_kParameter;
uniform float uD_kParameter;
uniform float uE_kParameter;
uniform float uF_kParameter;
uniform int uCSG_OperationABType;
uniform int uCSG_OperationBCType;
uniform int uCSG_OperationCDType;
uniform int uCSG_OperationDEType;
uniform int uCSG_OperationEFType;
uniform int uShapeAType;
uniform int uShapeBType;
uniform int uShapeCType;
uniform int uShapeDType;
uniform int uShapeEType;
uniform int uShapeFType;


#include <pathtracing_uniforms_and_defines>


//-----------------------------------------------------------------------

vec3 rayOrigin, rayDirection;
// recorded intersection data:
vec3 hitNormal, hitEmission, hitColor;
vec2 hitUV;
float hitObjectID;
int hitType = -100;


#include <pathtracing_random_functions>

#include <pathtracing_sphere_intersect>

#include <pathtracing_box_csg_intersect>

#include <pathtracing_conicalprism_csg_intersect>

#include <pathtracing_csg_operations>


// tentFilter from Peter Shirley's 'Realistic Ray Tracing (2nd Edition)' book, pg. 60
float tentFilter(float x)
{
	return (x < 0.5) ? sqrt(2.0 * x) - 1.0 : 1.0 - sqrt(2.0 - (2.0 * x));
}


//---------------------------------------------------------------------------------------
float SceneIntersect( )
//---------------------------------------------------------------------------------------
{
	vec3 rObjOrigin, rObjDirection;
	vec3 n;
	vec3 A_n0, B_n0, C_n0, D_n0, E_n0, F_n0, n0;
	vec3 A_n1, B_n1, C_n1, D_n1, E_n1, F_n1, n1;
	vec3 w_n0, w_n1;
	vec3 A_color0, B_color0, C_color0, D_color0, E_color0, F_color0, color0;
	vec3 A_color1, B_color1, C_color1, D_color1, E_color1, F_color1, color1;
	vec3 w_color0, w_color1;
	float A_t0 = 0.0;
	float A_t1 = 0.0;
	float B_t0 = 0.0; 
	float B_t1 = 0.0;
	float C_t0 = 0.0; 
	float C_t1 = 0.0;
	float D_t0 = 0.0; 
	float D_t1 = 0.0;
	float E_t0 = 0.0; 
	float E_t1 = 0.0;
	float F_t0 = 0.0; 
	float F_t1 = 0.0;
	float t0 = 0.0;
	float t1 = 0.0;
	float w_t0 = 0.0;
	float w_t1 = 0.0;
	float d = INFINITY;
	float t = INFINITY;
	int A_type0, B_type0, C_type0, D_type0, E_type0, F_type0, type0; 
	int A_type1, B_type1, C_type1, D_type1, E_type1, F_type1, type1;
	int w_type0, w_type1;
	int A_objectID0, B_objectID0, C_objectID0, D_objectID0, E_objectID0, F_objectID0, objectID0; 
	int A_objectID1, B_objectID1, C_objectID1, D_objectID1, E_objectID1, F_objectID1, objectID1;
	int w_objectID0, w_objectID1;
	//int objectCount = 0;
	
	hitObjectID = -INFINITY;


	// SHAPE A
	// transform ray into CSG_ShapeA's object space
	rObjOrigin = vec3( uCSG_ShapeA_InvMatrix * vec4(rayOrigin, 1.0) );
	rObjDirection = vec3( uCSG_ShapeA_InvMatrix * vec4(rayDirection, 0.0) );
	
	if (uShapeAType == 7)
		Box_CSG_Intersect( rObjOrigin, rObjDirection, A_t0, A_t1, A_n0, A_n1 );
	else 
		ConicalPrism_CSG_Intersect( uA_kParameter, rObjOrigin, rObjDirection, A_t0, A_t1, A_n0, A_n1 );
	
	n = (A_n0);
	A_n0 = (transpose(mat3(uCSG_ShapeA_InvMatrix)) * n);
	n = (A_n1);
	A_n1 = (transpose(mat3(uCSG_ShapeA_InvMatrix)) * n);
	

	// SHAPE B
	// transform ray into CSG_ShapeB's object space
	rObjOrigin = vec3( uCSG_ShapeB_InvMatrix * vec4(rayOrigin, 1.0) );
	rObjDirection = vec3( uCSG_ShapeB_InvMatrix * vec4(rayDirection, 0.0) );

	if (uShapeBType == 7)
		Box_CSG_Intersect( rObjOrigin, rObjDirection, B_t0, B_t1, B_n0, B_n1 );
	else 
		ConicalPrism_CSG_Intersect( uB_kParameter, rObjOrigin, rObjDirection, B_t0, B_t1, B_n0, B_n1 );
	
	n = (B_n0);
	B_n0 = (transpose(mat3(uCSG_ShapeB_InvMatrix)) * n);
	n = (B_n1);
	B_n1 = (transpose(mat3(uCSG_ShapeB_InvMatrix)) * n);

	
	A_color0 = A_color1 = vec3(1,0,0);
	A_type0 = A_type1 = DIFF;
	A_objectID0 = A_objectID1 = 0;

	B_color0 = B_color1 = vec3(0,1,0);
	B_type0 = B_type1 = DIFF;
	B_objectID0 = B_objectID1 = 1;

	if (uCSG_OperationABType == 0)
		CSG_Union_Operation( A_t0, A_n0, A_type0, A_color0, A_objectID0, A_t1, A_n1, A_type1, A_color1, A_objectID1, // <-- this line = input 1st surface data
				     B_t0, B_n0, B_type0, B_color0, B_objectID0, B_t1, B_n1, B_type1, B_color1, B_objectID1, // <-- this line = input 2nd surface data
				     t0, n0, type0, color0, objectID0, t1, n1, type1, color1, objectID1 ); // <-- this line = resulting csg operation data output
	else
		CSG_Difference_Operation( A_t0, A_n0, A_type0, A_color0, A_objectID0, A_t1, A_n1, A_type1, A_color1, A_objectID1, // <-- this line = input 1st surface data
				     	  B_t0, B_n0, B_type0, B_color0, B_objectID0, B_t1, B_n1, B_type1, B_color1, B_objectID1, // <-- this line = input 2nd surface data
				          t0, n0, type0, color0, objectID0, t1, n1, type1, color1, objectID1 ); // <-- this line = resulting csg operation data output
	
	// record winning intersection pair
	w_t0 = t0;
	w_n0 = n0;
	w_color0 = color0;
	w_type0 = type0;
	w_objectID0 = objectID0;

	w_t1 = t1;
	w_n1 = n1;
	w_color1 = color1;
	w_type1 = type1;
	w_objectID1 = objectID1;

	// reset
	t0 = t1 = 0.0;


	// SHAPE C
	// transform ray into CSG_ShapeC's object space
	rObjOrigin = vec3( uCSG_ShapeC_InvMatrix * vec4(rayOrigin, 1.0) );
	rObjDirection = vec3( uCSG_ShapeC_InvMatrix * vec4(rayDirection, 0.0) );

	if (uShapeCType == 7)
		Box_CSG_Intersect( rObjOrigin, rObjDirection, C_t0, C_t1, C_n0, C_n1 );
	else 
		ConicalPrism_CSG_Intersect( uC_kParameter, rObjOrigin, rObjDirection, C_t0, C_t1, C_n0, C_n1 );
	
	n = (C_n0);
	C_n0 = (transpose(mat3(uCSG_ShapeC_InvMatrix)) * n);
	n = (C_n1);
	C_n1 = (transpose(mat3(uCSG_ShapeC_InvMatrix)) * n);

	C_color0 = C_color1 = vec3(0,0,1);
	C_type0 = C_type1 = DIFF;
	C_objectID0 = C_objectID1 = 2;

	if (uCSG_OperationBCType == 0)
		CSG_Union_Operation( w_t0, w_n0, w_type0, w_color0, w_objectID0, w_t1, w_n1, w_type1, w_color1, w_objectID1, // <-- this line = input 1st surface data
				     C_t0, C_n0, C_type0, C_color0, C_objectID0, C_t1, C_n1, C_type1, C_color1, C_objectID1, // <-- this line = input 2nd surface data
				     t0, n0, type0, color0, objectID0, t1, n1, type1, color1, objectID1 ); // <-- this line = resulting csg operation data output
	else
		CSG_Difference_Operation( w_t0, w_n0, w_type0, w_color0, w_objectID0, w_t1, w_n1, w_type1, w_color1, w_objectID1, // <-- this line = input 1st surface data
				     	  C_t0, C_n0, C_type0, C_color0, C_objectID0, C_t1, C_n1, C_type1, C_color1, C_objectID1, // <-- this line = input 2nd surface data
				          t0, n0, type0, color0, objectID0, t1, n1, type1, color1, objectID1 ); // <-- this line = resulting csg operation data output
	
	// record winning intersection pair
	w_t0 = t0;
	w_n0 = n0;
	w_color0 = color0;
	w_type0 = type0;
	w_objectID0 = objectID0;

	w_t1 = t1;
	w_n1 = n1;
	w_color1 = color1;
	w_type1 = type1;
	w_objectID1 = objectID1;

	// reset
	t0 = t1 = 0.0;
	

	// SHAPE D
	// transform ray into CSG_ShapeD's object space
	rObjOrigin = vec3( uCSG_ShapeD_InvMatrix * vec4(rayOrigin, 1.0) );
	rObjDirection = vec3( uCSG_ShapeD_InvMatrix * vec4(rayDirection, 0.0) );

	if (uShapeDType == 7)
		Box_CSG_Intersect( rObjOrigin, rObjDirection, D_t0, D_t1, D_n0, D_n1 );
	else 
		ConicalPrism_CSG_Intersect( uD_kParameter, rObjOrigin, rObjDirection, D_t0, D_t1, D_n0, D_n1 );
	
	n = (D_n0);
	D_n0 = (transpose(mat3(uCSG_ShapeD_InvMatrix)) * n);
	n = (D_n1);
	D_n1 = (transpose(mat3(uCSG_ShapeD_InvMatrix)) * n);

	D_color0 = D_color1 = vec3(1,1,0);
	D_type0 = D_type1 = DIFF;
	D_objectID0 = D_objectID1 = 3;

	if (uCSG_OperationCDType == 0)
		CSG_Union_Operation( w_t0, w_n0, w_type0, w_color0, w_objectID0, w_t1, w_n1, w_type1, w_color1, w_objectID1, // <-- this line = input 1st surface data
				     D_t0, D_n0, D_type0, D_color0, D_objectID0, D_t1, D_n1, D_type1, D_color1, D_objectID1, // <-- this line = input 2nd surface data
				     t0, n0, type0, color0, objectID0, t1, n1, type1, color1, objectID1 ); // <-- this line = resulting csg operation data output
	else
		CSG_Difference_Operation( w_t0, w_n0, w_type0, w_color0, w_objectID0, w_t1, w_n1, w_type1, w_color1, w_objectID1, // <-- this line = input 1st surface data
				     	  D_t0, D_n0, D_type0, D_color0, D_objectID0, D_t1, D_n1, D_type1, D_color1, D_objectID1, // <-- this line = input 2nd surface data
				          t0, n0, type0, color0, objectID0, t1, n1, type1, color1, objectID1 ); // <-- this line = resulting csg operation data output
	
	// record winning intersection pair
	w_t0 = t0;
	w_n0 = n0;
	w_color0 = color0;
	w_type0 = type0;
	w_objectID0 = objectID0;

	w_t1 = t1;
	w_n1 = n1;
	w_color1 = color1;
	w_type1 = type1;
	w_objectID1 = objectID1;

	// reset
	t0 = t1 = 0.0;
	

	// SHAPE E
	// transform ray into CSG_ShapeE's object space
	rObjOrigin = vec3( uCSG_ShapeE_InvMatrix * vec4(rayOrigin, 1.0) );
	rObjDirection = vec3( uCSG_ShapeE_InvMatrix * vec4(rayDirection, 0.0) );

	if (uShapeEType == 7)
		Box_CSG_Intersect( rObjOrigin, rObjDirection, E_t0, E_t1, E_n0, E_n1 );
	else 
		ConicalPrism_CSG_Intersect( uE_kParameter, rObjOrigin, rObjDirection, E_t0, E_t1, E_n0, E_n1 );
	
	n = (E_n0);
	E_n0 = (transpose(mat3(uCSG_ShapeE_InvMatrix)) * n);
	n = (E_n1);
	E_n1 = (transpose(mat3(uCSG_ShapeE_InvMatrix)) * n);

	E_color0 = E_color1 = vec3(0,1,1);
	E_type0 = E_type1 = DIFF;
	E_objectID0 = E_objectID1 = 4;

	if (uCSG_OperationDEType == 0)
		CSG_Union_Operation( w_t0, w_n0, w_type0, w_color0, w_objectID0, w_t1, w_n1, w_type1, w_color1, w_objectID1, // <-- this line = input 1st surface data
				     E_t0, E_n0, E_type0, E_color0, E_objectID0, E_t1, E_n1, E_type1, E_color1, E_objectID1, // <-- this line = input 2nd surface data
				     t0, n0, type0, color0, objectID0, t1, n1, type1, color1, objectID1 ); // <-- this line = resulting csg operation data output
	else
		CSG_Difference_Operation( w_t0, w_n0, w_type0, w_color0, w_objectID0, w_t1, w_n1, w_type1, w_color1, w_objectID1, // <-- this line = input 1st surface data
				     	  E_t0, E_n0, E_type0, E_color0, E_objectID0, E_t1, E_n1, E_type1, E_color1, E_objectID1, // <-- this line = input 2nd surface data
				          t0, n0, type0, color0, objectID0, t1, n1, type1, color1, objectID1 ); // <-- this line = resulting csg operation data output
	
	// record winning intersection pair
	w_t0 = t0;
	w_n0 = n0;
	w_color0 = color0;
	w_type0 = type0;
	w_objectID0 = objectID0;

	w_t1 = t1;
	w_n1 = n1;
	w_color1 = color1;
	w_type1 = type1;
	w_objectID1 = objectID1;

	// reset
	t0 = t1 = 0.0;
	

	// SHAPE F
	// transform ray into CSG_ShapeF's object space
	rObjOrigin = vec3( uCSG_ShapeF_InvMatrix * vec4(rayOrigin, 1.0) );
	rObjDirection = vec3( uCSG_ShapeF_InvMatrix * vec4(rayDirection, 0.0) );

	if (uShapeFType == 7)
		Box_CSG_Intersect( rObjOrigin, rObjDirection, F_t0, F_t1, F_n0, F_n1 );
	else 
		ConicalPrism_CSG_Intersect( uF_kParameter, rObjOrigin, rObjDirection, F_t0, F_t1, F_n0, F_n1 );
	
	n = (F_n0);
	F_n0 = (transpose(mat3(uCSG_ShapeF_InvMatrix)) * n);
	n = (F_n1);
	F_n1 = (transpose(mat3(uCSG_ShapeF_InvMatrix)) * n);

	F_color0 = F_color1 = vec3(1,0,1);
	F_type0 = F_type1 = DIFF;
	F_objectID0 = F_objectID1 = 5;

	if (uCSG_OperationEFType == 0)
		CSG_Union_Operation( w_t0, w_n0, w_type0, w_color0, w_objectID0, w_t1, w_n1, w_type1, w_color1, w_objectID1, // <-- this line = input 1st surface data
				     F_t0, F_n0, F_type0, F_color0, F_objectID0, F_t1, F_n1, F_type1, F_color1, F_objectID1, // <-- this line = input 2nd surface data
				     t0, n0, type0, color0, objectID0, t1, n1, type1, color1, objectID1 ); // <-- this line = resulting csg operation data output
	else
		CSG_Difference_Operation( w_t0, w_n0, w_type0, w_color0, w_objectID0, w_t1, w_n1, w_type1, w_color1, w_objectID1, // <-- this line = input 1st surface data
				     	  F_t0, F_n0, F_type0, F_color0, F_objectID0, F_t1, F_n1, F_type1, F_color1, F_objectID1, // <-- this line = input 2nd surface data
				          t0, n0, type0, color0, objectID0, t1, n1, type1, color1, objectID1 ); // <-- this line = resulting csg operation data output
	


	// finally, we can get resulting t values
	if (t0 > 0.0)// && t0 < t)
	{
		t = t0;
		hitNormal = n0;
		hitEmission = vec3(0);
		hitColor = color0;
		hitType = type0;
		hitObjectID = float(objectID0);
	}
	else if (t1 > 0.0)// && t1 < t)
	{
		t = t1;
		hitNormal = n1;
		hitEmission = vec3(0);
		hitColor = color1;
		hitType = type1;
		hitObjectID = float(objectID1);
	}


	return t == 0.0 ? INFINITY : t;
} // end float SceneIntersect( )


vec3 GetBackgroundColor(vec3 rayDirection)
{
	return vec3(1);
}


//-----------------------------------------------------------------------------------------------------------------------------
vec3 CalculateRadiance( out vec3 objectNormal, out vec3 objectColor, out float objectID, out float pixelSharpness )
//-----------------------------------------------------------------------------------------------------------------------------
{
	
	vec3 accumCol = vec3(0);
	vec3 mask = vec3(1);
	vec3 dirToLight;
	vec3 x, n, nl;

	vec2 screenPixelUV, pixelOffset;
	
	float t = INFINITY;
	float weight;

	int sampleLight = FALSE;

	pixelSharpness = 1.0;
	objectID = -INFINITY;


	for (int bounces = 0; bounces < 2; bounces++)
	{

		t = SceneIntersect();

		if (t == INFINITY)
		{
			if (bounces == 0)
				accumCol = GetBackgroundColor(rayDirection);
			
			if (sampleLight == TRUE)
			{

				pixelOffset = vec2( tentFilter(rng()), tentFilter(rng()) );

				screenPixelUV = (gl_FragCoord.xy + pixelOffset) / uResolution;
				screenPixelUV.x *= (uResolution.x / uResolution.y);
				screenPixelUV *= 40.0;

				// select texture based on stepped gradient palette (how light or dark the 'weight' value is)
				// similar to 'toon shading' lookup color palette for different lighting values

				// light
				if (weight > 0.8)
					mask = pow(clamp(texture(tLightTexture, screenPixelUV).rgb + vec3(0), 0.0, 1.0), vec3(2.2));
				// medium light
				else if (weight > 0.6)
					mask = pow(clamp(texture(tMedLightTexture, screenPixelUV).rgb + vec3(0), 0.0, 1.0), vec3(2.2));
				// medium
				else if (weight > 0.4)
					mask = pow(clamp(texture(tMediumTexture, screenPixelUV).rgb + vec3(0), 0.0, 1.0), vec3(2.2));
				// medium dark
				else if (weight > 0.2)
					mask = pow(clamp(texture(tMedDarkTexture, screenPixelUV).rgb + vec3(0), 0.0, 1.0), vec3(2.2));
				// dark
				else
					mask = pow(clamp(texture(tDarkTexture, screenPixelUV).rgb, 0.0, 1.0), vec3(2.2));

				accumCol = mask;
			}

			break;
		}

		// if we get here and sampleLight is still true, shadow ray failed to find the light source 
		// the ray hit an occluding object along its way to the light
		if (sampleLight == TRUE)
		{
			pixelOffset = vec2( tentFilter(rng()), tentFilter(rng()) );

			screenPixelUV = (gl_FragCoord.xy + pixelOffset) / uResolution;
			screenPixelUV.x *= (uResolution.x / uResolution.y);
			screenPixelUV *= 40.0;

			// make this area of the surface a darker shade (in shadow)
			accumCol = pow(clamp(texture(tDarkTexture, screenPixelUV).rgb, 0.0, 1.0), vec3(2.2));
			break;
		}	
				
			

		// useful data 
		n = normalize(hitNormal);
                nl = dot(n, rayDirection) < 0.0 ? n : -n;
		x = rayOrigin + rayDirection * t;

		if (bounces == 0)
		{
			objectNormal = n;
			objectColor = hitColor;
			objectID = hitObjectID;
		}


		    
		if (hitType == DIFF) // Ideal DIFFUSE reflection
		{	
			
			weight = max(0.0, dot(uSunDirection, nl));

			// create Shadow Ray aimed toward the direction of the Sun
			rayDirection = uSunDirection;
			rayOrigin = x + nl * uEPS_intersect;

			sampleLight = TRUE;
			continue;
			
		} // end if (hitType == DIFF)
		
	} // end for (int bounces = 0; bounces < 2; bounces++)
	
	
	return max(vec3(0), accumCol);

} // end vec3 CalculateRadiance( out vec3 objectNormal, out vec3 objectColor, out float objectID, out float pixelSharpness )



//-----------------------------------------------------------------------
void SetupScene(void)
//-----------------------------------------------------------------------
{
	
}


//#include <pathtracing_main>

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

	// rand() produces higher FPS and almost immediate convergence, but may have very slight jagged diagonal edges on higher frequency color patterns, i.e. checkerboards.
	//vec2 pixelOffset = vec2( tentFilter(rand()), tentFilter(rand()) );
	// rng() has a little less FPS on mobile, and a little more noisy initially, but eventually converges on perfect anti-aliased edges - use this if 'beauty-render' is desired.
	vec2 pixelOffset = vec2( tentFilter(rng()), tentFilter(rng()) ) * 2.0;

	// we must map pixelPos into the range -1.0 to +1.0
	vec2 pixelPos = ((gl_FragCoord.xy + vec2(0.5) + pixelOffset) / uResolution) * 2.0 - 1.0;
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
	float objectDifference = min(fwidth(objectID), 1.0);

	float colorDifference = (fwidth(objectColor.r) + fwidth(objectColor.g) + fwidth(objectColor.b)) > 0.0 ? 1.0 : 0.0;
	
	// edge detector black-line debug visualization
	if (objectDifference > 0.0 || colorDifference > 0.0 || normalDifference > 0.0)
		currentPixel.rgb = vec3(0);

	vec4 previousPixel = texelFetch(tPreviousTexture, ivec2(gl_FragCoord.xy), 0);
	

	if (uFrameCounter == 1.0) // camera just moved after being still
	{
		previousPixel.rgb *= (1.0 / (uPreviousSampleCount * 2.0)); // essentially previousPixel *= 0.5, like below
		//previousPixel.a = 0.0;
		currentPixel.rgb *= 0.5;
	}
	else if (uCameraIsMoving) // camera is currently moving
	{
		previousPixel.rgb *= 0.5; // motion-blur trail amount (old image)
		//previousPixel.a = 0.0;
		currentPixel.rgb *= 0.5; // brightness of new image (noisy)
	}


	pc_fragColor = vec4(previousPixel.rgb + currentPixel.rgb, 1.0);
}
