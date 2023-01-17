precision highp float;
precision highp int;
precision highp sampler2D;

uniform mat4 uEllipsoidTranslateInvMatrix;
uniform mat4 uEllipsoidRotateInvMatrix;
uniform mat4 uEllipsoidScaleInvMatrix;
uniform mat4 uEllipsoidClipInvMatrix;

uniform mat4 uCylinderTranslateInvMatrix;
uniform mat4 uCylinderRotateInvMatrix;
uniform mat4 uCylinderScaleInvMatrix;
uniform mat4 uCylinderClipInvMatrix;

uniform mat4 uConeTranslateInvMatrix;
uniform mat4 uConeRotateInvMatrix;
uniform mat4 uConeScaleInvMatrix;
uniform mat4 uConeClipInvMatrix;

uniform mat4 uParaboloidTranslateInvMatrix;
uniform mat4 uParaboloidRotateInvMatrix;
uniform mat4 uParaboloidScaleInvMatrix;
uniform mat4 uParaboloidClipInvMatrix;

uniform mat4 uHyperboloidTranslateInvMatrix;
uniform mat4 uHyperboloidRotateInvMatrix;
uniform mat4 uHyperboloidScaleInvMatrix;
uniform mat4 uHyperboloidClipInvMatrix;

uniform mat4 uHyperbolicParaboloidTranslateInvMatrix;
uniform mat4 uHyperbolicParaboloidRotateInvMatrix;
uniform mat4 uHyperbolicParaboloidScaleInvMatrix;
uniform mat4 uHyperbolicParaboloidClipInvMatrix;

#include <pathtracing_uniforms_and_defines>

#define N_LIGHTS 3.0
#define N_SPHERES 4


vec3 rayOrigin, rayDirection;
// recorded intersection data:
vec3 hitNormal, hitEmission, hitColor;
vec2 hitUV;
float hitObjectID;
int hitType = -100;

struct Sphere { float radius; vec3 position; vec3 emission; vec3 color; int type; };

Sphere spheres[N_SPHERES];


#include <pathtracing_random_functions>

#include <pathtracing_calc_fresnel_reflectance>

#include <pathtracing_sphere_intersect>

#include <pathtracing_ellipsoid_param_intersect>

#include <pathtracing_cylinder_param_intersect>

#include <pathtracing_cone_param_intersect>

#include <pathtracing_paraboloid_param_intersect>

#include <pathtracing_hyperboloid_param_intersect>

#include <pathtracing_hyperbolic_paraboloid_param_intersect>

#include <pathtracing_sample_sphere_light>



//---------------------------------------------------------------------------------------
float SceneIntersect()
//---------------------------------------------------------------------------------------
{
	float d;
	float t = INFINITY;
	float angleAmount = (sin(uTime) * 0.5 + 0.5);
	int objectCount = 0;
	vec3 n;
	vec3 rObjOrigin, rObjDirection;
	
        for (int i = 0; i < N_SPHERES; i++)
        {
		d = SphereIntersect( spheres[i].radius, spheres[i].position, rayOrigin, rayDirection );
		if (d < t)
		{
			t = d;
			hitNormal = (rayOrigin + rayDirection * t) - spheres[i].position;
			hitEmission = spheres[i].emission;
			hitColor = spheres[i].color;
			hitType = spheres[i].type;
			hitObjectID = float(objectCount);
		}
		objectCount++;
	}
	
	
	// transform ray into Ellipsoid Param's object space
	rObjOrigin = vec3( uEllipsoidTranslateInvMatrix * vec4(rayOrigin, 1.0) );
	rObjDirection = vec3( uEllipsoidTranslateInvMatrix * vec4(rayDirection, 0.0) );
	d = EllipsoidParamIntersect(-1.0, 1.0, TWO_PI, rObjOrigin, rObjDirection, n);

	if (d < t)
	{
		t = d;
		//vec3 ellipsoidPos = vec3(-uEllipsoidTranslateInvMatrix[3][0], -uEllipsoidTranslateInvMatrix[3][1], -uEllipsoidTranslateInvMatrix[3][2]);
		hitNormal = transpose(mat3(uEllipsoidTranslateInvMatrix)) * n;
		//hitEmission = vec3(0);
		hitColor = vec3(0.0, 0.3, 1.0);
		hitType = SPEC;
		hitObjectID = float(objectCount);
	}
	objectCount++;

	// transform ray into Ellipsoid Param's object space
	rObjOrigin = vec3( uEllipsoidRotateInvMatrix * vec4(rayOrigin, 1.0) );
	rObjDirection = vec3( uEllipsoidRotateInvMatrix * vec4(rayDirection, 0.0) );
	d = EllipsoidParamIntersect(-1.0, 1.0, TWO_PI, rObjOrigin, rObjDirection, n);

	if (d < t)
	{
		t = d;
		hitNormal = transpose(mat3(uEllipsoidRotateInvMatrix)) * n;
		//hitEmission = vec3(0);
		hitColor = vec3(0.0, 0.3, 1.0);
		hitType = REFR;
		hitObjectID = float(objectCount);
	}
	objectCount++;

	// transform ray into Ellipsoid Param's object space
	rObjOrigin = vec3( uEllipsoidScaleInvMatrix * vec4(rayOrigin, 1.0) );
	rObjDirection = vec3( uEllipsoidScaleInvMatrix * vec4(rayDirection, 0.0) );
	d = EllipsoidParamIntersect(-1.0, 1.0, TWO_PI, rObjOrigin, rObjDirection, n);

	if (d < t)
	{
		t = d;
		hitNormal = transpose(mat3(uEllipsoidScaleInvMatrix)) * n;
		//hitEmission = vec3(0);
		hitColor = vec3(0.0, 0.3, 1.0);
		hitType = DIFF;
		hitObjectID = float(objectCount);
	}
	objectCount++;

	// transform ray into Ellipsoid Param's object space
	rObjOrigin = vec3( uEllipsoidClipInvMatrix * vec4(rayOrigin, 1.0) );
	rObjDirection = vec3( uEllipsoidClipInvMatrix * vec4(rayDirection, 0.0) );
	d = EllipsoidParamIntersect(-0.8, angleAmount, TWO_PI, rObjOrigin, rObjDirection, n);

	if (d < t)
	{
		t = d;
		hitNormal = transpose(mat3(uEllipsoidClipInvMatrix)) * n;
		//hitEmission = vec3(0);
		hitColor = vec3(0.0, 0.3, 1.0);
		hitType = COAT;
		hitObjectID = float(objectCount);
	}
	objectCount++;

	// transform ray into Cylinder Param's object space
	rObjOrigin = vec3( uCylinderTranslateInvMatrix * vec4(rayOrigin, 1.0) );
	rObjDirection = vec3( uCylinderTranslateInvMatrix * vec4(rayDirection, 0.0) );
	d = CylinderParamIntersect(-1.0, 1.0, TWO_PI, rObjOrigin, rObjDirection, n);

	if (d < t)
	{
		t = d;
		hitNormal = transpose(mat3(uCylinderTranslateInvMatrix)) * n;
		//hitEmission = vec3(0);
		hitColor = vec3(1.0, 0.0, 0.0);
		hitType = SPEC;
		hitObjectID = float(objectCount);
	}
	objectCount++;

	// transform ray into Cylinder Param's object space
	rObjOrigin = vec3( uCylinderRotateInvMatrix * vec4(rayOrigin, 1.0) );
	rObjDirection = vec3( uCylinderRotateInvMatrix * vec4(rayDirection, 0.0) );
	d = CylinderParamIntersect(-1.0, 1.0, TWO_PI, rObjOrigin, rObjDirection, n);

	if (d < t)
	{
		t = d;
		hitNormal = transpose(mat3(uCylinderRotateInvMatrix)) * n;
		//hitEmission = vec3(0);
		hitColor = vec3(1.0, 0.0, 0.0);
		hitType = REFR;
		hitObjectID = float(objectCount);
	}
	objectCount++;

	// transform ray into Cylinder Param's object space
	rObjOrigin = vec3( uCylinderScaleInvMatrix * vec4(rayOrigin, 1.0) );
	rObjDirection = vec3( uCylinderScaleInvMatrix * vec4(rayDirection, 0.0) );
	d = CylinderParamIntersect(-1.0, 1.0, TWO_PI, rObjOrigin, rObjDirection, n);

	if (d < t)
	{
		t = d;
		hitNormal = transpose(mat3(uCylinderScaleInvMatrix)) * n;
		//hitEmission = vec3(0);
		hitColor = vec3(1.0, 0.0, 0.0);
		hitType = DIFF;
		hitObjectID = float(objectCount);
	}
	objectCount++;

	// transform ray into Cylinder Param's object space
	rObjOrigin = vec3( uCylinderClipInvMatrix * vec4(rayOrigin, 1.0) );
	rObjDirection = vec3( uCylinderClipInvMatrix * vec4(rayDirection, 0.0) );
	d = CylinderParamIntersect(-angleAmount, angleAmount, TWO_PI * 0.6, rObjOrigin, rObjDirection, n);

	if (d < t)
	{
		t = d;
		hitNormal = transpose(mat3(uCylinderClipInvMatrix)) * n;
		//hitEmission = vec3(0);
		hitColor = vec3(1.0, 0.0, 0.0);
		hitType = COAT;
		hitObjectID = float(objectCount);
	}
	objectCount++;

	// transform ray into Cone Param's object space
	rObjOrigin = vec3( uConeTranslateInvMatrix * vec4(rayOrigin, 1.0) );
	rObjDirection = vec3( uConeTranslateInvMatrix * vec4(rayDirection, 0.0) );
	d = ConeParamIntersect(-1.0, 1.0, TWO_PI, rObjOrigin, rObjDirection, n);

	if (d < t)
	{
		t = d;
		hitNormal = transpose(mat3(uConeTranslateInvMatrix)) * n;
		//hitEmission = vec3(0);
		hitColor = vec3(1.0, 0.2, 0.0);
		hitType = SPEC;
		hitObjectID = float(objectCount);
	}
	objectCount++;

	// transform ray into Cone Param's object space
	rObjOrigin = vec3( uConeRotateInvMatrix * vec4(rayOrigin, 1.0) );
	rObjDirection = vec3( uConeRotateInvMatrix * vec4(rayDirection, 0.0) );
	d = ConeParamIntersect(-1.0, 1.0, TWO_PI, rObjOrigin, rObjDirection, n);

	if (d < t)
	{
		t = d;
		hitNormal = transpose(mat3(uConeRotateInvMatrix)) * n;
		//hitEmission = vec3(0);
		hitColor = vec3(1.0, 0.2, 0.0);
		hitType = REFR;
		hitObjectID = float(objectCount);
	}
	objectCount++;

	// transform ray into Cone Param's object space
	rObjOrigin = vec3( uConeScaleInvMatrix * vec4(rayOrigin, 1.0) );
	rObjDirection = vec3( uConeScaleInvMatrix * vec4(rayDirection, 0.0) );
	d = ConeParamIntersect(-1.0, 1.0, TWO_PI, rObjOrigin, rObjDirection, n);

	if (d < t)
	{
		t = d;
		hitNormal = transpose(mat3(uConeScaleInvMatrix)) * n;
		//hitEmission = vec3(0);
		hitColor = vec3(1.0, 0.2, 0.0);
		hitType = DIFF;
		hitObjectID = float(objectCount);
	}
	objectCount++;

	// transform ray into Cone Param's object space
	rObjOrigin = vec3( uConeClipInvMatrix * vec4(rayOrigin, 1.0) );
	rObjDirection = vec3( uConeClipInvMatrix * vec4(rayDirection, 0.0) );
	d = ConeParamIntersect(-1.0, 1.0, TWO_PI * angleAmount, rObjOrigin, rObjDirection, n);

	if (d < t)
	{
		t = d;
		hitNormal = transpose(mat3(uConeClipInvMatrix)) * n;
		//hitEmission = vec3(0);
		hitColor = vec3(1.0, 0.2, 0.0);
		hitType = COAT;
		hitObjectID = float(objectCount);
	}
	objectCount++;

	// transform ray into Paraboloid Param's object space
	rObjOrigin = vec3( uParaboloidTranslateInvMatrix * vec4(rayOrigin, 1.0) );
	rObjDirection = vec3( uParaboloidTranslateInvMatrix * vec4(rayDirection, 0.0) );
	d = ParaboloidParamIntersect(-1.0, 1.0, TWO_PI, rObjOrigin, rObjDirection, n);

	if (d < t)
	{
		t = d;
		hitNormal = transpose(mat3(uParaboloidTranslateInvMatrix)) * n;
		//hitEmission = vec3(0);
		hitColor = vec3(1.0, 0.0, 1.0);
		hitType = SPEC;
		hitObjectID = float(objectCount);
	}
	objectCount++;

	// transform ray into Paraboloid Param's object space
	rObjOrigin = vec3( uParaboloidRotateInvMatrix * vec4(rayOrigin, 1.0) );
	rObjDirection = vec3( uParaboloidRotateInvMatrix * vec4(rayDirection, 0.0) );
	d = ParaboloidParamIntersect(-1.0, 1.0, TWO_PI, rObjOrigin, rObjDirection, n);

	if (d < t)
	{
		t = d;
		hitNormal = transpose(mat3(uParaboloidRotateInvMatrix)) * n;
		//hitEmission = vec3(0);
		hitColor = vec3(1.0, 0.0, 1.0);
		hitType = REFR;
		hitObjectID = float(objectCount);
	}
	objectCount++;

	// transform ray into Paraboloid Param's object space
	rObjOrigin = vec3( uParaboloidScaleInvMatrix * vec4(rayOrigin, 1.0) );
	rObjDirection = vec3( uParaboloidScaleInvMatrix * vec4(rayDirection, 0.0) );
	d = ParaboloidParamIntersect(-1.0, 1.0, TWO_PI, rObjOrigin, rObjDirection, n);

	if (d < t)
	{
		t = d;
		hitNormal = transpose(mat3(uParaboloidScaleInvMatrix)) * n;
		//hitEmission = vec3(0);
		hitColor = vec3(1.0, 0.0, 1.0);
		hitType = DIFF;
		hitObjectID = float(objectCount);
	}
	objectCount++;

	// transform ray into Paraboloid Param's object space
	rObjOrigin = vec3( uParaboloidClipInvMatrix * vec4(rayOrigin, 1.0) );
	rObjDirection = vec3( uParaboloidClipInvMatrix * vec4(rayDirection, 0.0) );
	d = ParaboloidParamIntersect(-angleAmount, 1.0 - angleAmount, TWO_PI, rObjOrigin, rObjDirection, n);

	if (d < t)
	{
		t = d;
		hitNormal = transpose(mat3(uParaboloidClipInvMatrix)) * n;
		//hitEmission = vec3(0);
		hitColor = vec3(1.0, 0.0, 1.0);
		hitType = COAT;
		hitObjectID = float(objectCount);
	}
	objectCount++;

	// transform ray into Hyperboloid Param's object space
	rObjOrigin = vec3( uHyperboloidTranslateInvMatrix * vec4(rayOrigin, 1.0) );
	rObjDirection = vec3( uHyperboloidTranslateInvMatrix * vec4(rayDirection, 0.0) );
	d = HyperboloidParamIntersect(8.0, -1.0, 1.0, TWO_PI, rObjOrigin, rObjDirection, n);

	if (d < t)
	{
		t = d;
		hitNormal = transpose(mat3(uHyperboloidTranslateInvMatrix)) * n;
		//hitEmission = vec3(0);
		hitColor = vec3(1.0, 1.0, 0.0);
		hitType = SPEC;
		hitObjectID = float(objectCount);
	}
	objectCount++;

	// transform ray into Hyperboloid Param's object space
	rObjOrigin = vec3( uHyperboloidRotateInvMatrix * vec4(rayOrigin, 1.0) );
	rObjDirection = vec3( uHyperboloidRotateInvMatrix * vec4(rayDirection, 0.0) );
	d = HyperboloidParamIntersect(8.0, -1.0, 1.0, TWO_PI, rObjOrigin, rObjDirection, n);

	if (d < t)
	{
		t = d;
		hitNormal = transpose(mat3(uHyperboloidRotateInvMatrix)) * n;
		//hitEmission = vec3(0);
		hitColor = vec3(1.0, 1.0, 0.0);
		hitType = REFR;
		hitObjectID = float(objectCount);
	}
	objectCount++;

	// transform ray into Hyperboloid Param's object space
	rObjOrigin = vec3( uHyperboloidScaleInvMatrix * vec4(rayOrigin, 1.0) );
	rObjDirection = vec3( uHyperboloidScaleInvMatrix * vec4(rayDirection, 0.0) );
	d = HyperboloidParamIntersect(8.0, -1.0, 1.0, TWO_PI, rObjOrigin, rObjDirection, n);

	if (d < t)
	{
		t = d;
		hitNormal = transpose(mat3(uHyperboloidScaleInvMatrix)) * n;
		//hitEmission = vec3(0);
		hitColor = vec3(1.0, 1.0, 0.0);
		hitType = DIFF;
		hitObjectID = float(objectCount);
	}
	objectCount++;

	// transform ray into Hyperboloid Param's object space
	rObjOrigin = vec3( uHyperboloidClipInvMatrix * vec4(rayOrigin, 1.0) );
	rObjDirection = vec3( uHyperboloidClipInvMatrix * vec4(rayDirection, 0.0) );
	d = HyperboloidParamIntersect(floor(mix(-40.0, 40.0, angleAmount)) - 0.5, -1.0, 1.0, TWO_PI, rObjOrigin, rObjDirection, n);

	if (d < t)
	{
		t = d;
		hitNormal = transpose(mat3(uHyperboloidClipInvMatrix)) * n;
		//hitEmission = vec3(0);
		hitColor = vec3(1.0, 1.0, 0.0);
		hitType = COAT;
		hitObjectID = float(objectCount);
	}
	objectCount++;

	// transform ray into HyperbolicParaboloid Param's object space
	rObjOrigin = vec3( uHyperbolicParaboloidTranslateInvMatrix * vec4(rayOrigin, 1.0) );
	rObjDirection = vec3( uHyperbolicParaboloidTranslateInvMatrix * vec4(rayDirection, 0.0) );
	d = HyperbolicParaboloidParamIntersect(-1.0, 1.0, TWO_PI, rObjOrigin, rObjDirection, n);

	if (d < t)
	{
		t = d;
		hitNormal = transpose(mat3(uHyperbolicParaboloidTranslateInvMatrix)) * n;
		//hitEmission = vec3(0);
		hitColor = vec3(0.0, 1.0, 0.0);
		hitType = SPEC;
		hitObjectID = float(objectCount);
	}
	objectCount++;

	// transform ray into HyperbolicParaboloid Param's object space
	rObjOrigin = vec3( uHyperbolicParaboloidRotateInvMatrix * vec4(rayOrigin, 1.0) );
	rObjDirection = vec3( uHyperbolicParaboloidRotateInvMatrix * vec4(rayDirection, 0.0) );
	d = HyperbolicParaboloidParamIntersect(-1.0, 1.0, TWO_PI, rObjOrigin, rObjDirection, n);

	if (d < t)
	{
		t = d;
		hitNormal = transpose(mat3(uHyperbolicParaboloidRotateInvMatrix)) * n;
		//hitEmission = vec3(0);
		hitColor = vec3(0.0, 1.0, 0.0);
		hitType = REFR;
		hitObjectID = float(objectCount);
	}
	objectCount++;

	// transform ray into HyperbolicParaboloid Param's object space
	rObjOrigin = vec3( uHyperbolicParaboloidScaleInvMatrix * vec4(rayOrigin, 1.0) );
	rObjDirection = vec3( uHyperbolicParaboloidScaleInvMatrix * vec4(rayDirection, 0.0) );
	d = HyperbolicParaboloidParamIntersect(-1.0, 1.0, TWO_PI, rObjOrigin, rObjDirection, n);

	if (d < t)
	{
		t = d;
		hitNormal = transpose(mat3(uHyperbolicParaboloidScaleInvMatrix)) * n;
		//hitEmission = vec3(0);
		hitColor = vec3(0.0, 1.0, 0.0);
		hitType = DIFF;
		hitObjectID = float(objectCount);
	}
	objectCount++;

	// transform ray into HyperbolicParaboloid Param's object space
	rObjOrigin = vec3( uHyperbolicParaboloidClipInvMatrix * vec4(rayOrigin, 1.0) );
	rObjDirection = vec3( uHyperbolicParaboloidClipInvMatrix * vec4(rayDirection, 0.0) );
	d = HyperbolicParaboloidParamIntersect(-1.0, (1.0 - angleAmount) * 1.9 + 0.1, TWO_PI * (1.0 - angleAmount) + 0.1, rObjOrigin, rObjDirection, n);

	if (d < t)
	{
		t = d;
		hitNormal = transpose(mat3(uHyperbolicParaboloidClipInvMatrix)) * n;
		//hitEmission = vec3(0);
		hitColor = vec3(0.0, 1.0, 0.0);
		hitType = COAT;
		hitObjectID = float(objectCount);
	}
	
        
	return t;
	
} // end float SceneIntersect()


//-----------------------------------------------------------------------------------------------------------------------------
vec3 CalculateRadiance( out vec3 objectNormal, out vec3 objectColor, out float objectID, out float pixelSharpness )
//-----------------------------------------------------------------------------------------------------------------------------
{
	Sphere lightChoice;

	vec3 accumCol = vec3(0);
        vec3 mask = vec3(1);
	vec3 reflectionMask = vec3(1);
	vec3 reflectionRayOrigin = vec3(0);
	vec3 reflectionRayDirection = vec3(0);
	vec3 checkCol0 = vec3(1);
	vec3 checkCol1 = vec3(0.5);
	vec3 dirToLight;
	vec3 tdir;
	vec3 x, n, nl;
        
	float t;
	float nc, nt, ratioIoR, Re, Tr;
	//float P, RP, TP;
	float weight;
	float thickness = 0.1;

	int diffuseCount = 0;
	int previousIntersecType = -100;
	hitType = -100;
	
	int coatTypeIntersected = FALSE;
	int bounceIsSpecular = TRUE;
	int sampleLight = FALSE;
	int isRayExiting;
	int willNeedReflectionRay = FALSE;


	lightChoice = spheres[int(rand() * N_LIGHTS)];

	
	for (int bounces = 0; bounces < 7; bounces++)
	{
		previousIntersecType = hitType;

		t = SceneIntersect();
		
		/*
		//not used in this scene because we are inside a huge sphere - no rays can escape
		if (t == INFINITY)
		{
                        break;
		}
		*/

		// useful data 
		n = normalize(hitNormal);
                nl = dot(n, rayDirection) < 0.0 ? n : -n;
		x = rayOrigin + rayDirection * t;

		if (bounces == 0)
		{
			objectNormal = nl;
			objectColor = hitColor;
			objectID = hitObjectID;
		}
		if (bounces == 1 && diffuseCount == 0 && previousIntersecType == SPEC)
		{
			objectNormal = nl;
		}
		
		
		if (hitType == LIGHT)
		{	
			if (bounces == 0 || (bounces == 1 && previousIntersecType == SPEC))
				pixelSharpness = 1.01;

			if (diffuseCount == 0)
			{
				objectNormal = nl;
				objectColor = hitColor;
				objectID = hitObjectID;
			}
			
			if (bounceIsSpecular == TRUE || sampleLight == TRUE)
				accumCol += mask * hitEmission;

			if (willNeedReflectionRay == TRUE)
			{
				mask = reflectionMask;
				rayOrigin = reflectionRayOrigin;
				rayDirection = reflectionRayDirection;

				willNeedReflectionRay = FALSE;
				bounceIsSpecular = TRUE;
				sampleLight = FALSE;
				diffuseCount = 0;
				continue;
			}
			// reached a light, so we can exit
			break;
		} // end if (hitType == LIGHT)


		// if we get here and sampleLight is still TRUE, shadow ray failed to find the light source 
		// the ray hit an occluding object along its way to the light
		if (sampleLight == TRUE && hitType != REFR) // (&& hitType != REFR) needed here for caustic trick below to work :)
		{
			if (willNeedReflectionRay == TRUE)
			{
				mask = reflectionMask;
				rayOrigin = reflectionRayOrigin;
				rayDirection = reflectionRayDirection;

				willNeedReflectionRay = FALSE;
				bounceIsSpecular = TRUE;
				sampleLight = FALSE;
				diffuseCount = 0;
				continue;
			}

			break;
		}
			


		    
                if (hitType == DIFF || hitType == CHECK) // Ideal DIFFUSE reflection
		{
			if( hitType == CHECK )
			{
				float q = clamp( mod( dot( floor(x.xz * 0.04), vec2(1.0) ), 2.0 ) , 0.0, 1.0 );
				hitColor = checkCol0 * q + checkCol1 * (1.0 - q);	
			}
			// must update objectColor because hitColor may have changed
			if (bounces == 0 || (diffuseCount == 0 && coatTypeIntersected == FALSE && previousIntersecType == SPEC))	
				objectColor = hitColor;

			diffuseCount++;

			mask *= hitColor;

			bounceIsSpecular = FALSE;

			if (diffuseCount == 1 && rand() < 0.4)
			{
				mask /= 0.4;
				// choose random Diffuse sample vector
				rayDirection = randomCosWeightedDirectionInHemisphere(nl);
				rayOrigin = x + nl * uEPS_intersect;
				continue;
			}

			dirToLight = sampleSphereLight(x, nl, lightChoice, weight);
			mask /= diffuseCount == 1 ? 0.6 : 1.0;
			mask *= weight * N_LIGHTS;

			rayDirection = dirToLight;
			rayOrigin = x + nl * uEPS_intersect;

			sampleLight = TRUE;
			continue;
                        
		} // end if (hitType == DIFF)
		
		if (hitType == SPEC)  // Ideal SPECULAR reflection
		{
			mask *= hitColor;

			rayDirection = reflect(rayDirection, nl);
			rayOrigin = x + nl * uEPS_intersect;

			//if (diffuseCount == 1)
			//	bounceIsSpecular = TRUE; // turn on reflective mirror caustics

			continue;
		}
		
		if (hitType == REFR)  // Ideal dielectric REFRACTION
		{
			pixelSharpness = diffuseCount == 0 && coatTypeIntersected == FALSE ? -1.0 : pixelSharpness;

			nc = 1.0; // IOR of Air
			nt = 1.5; // IOR of common Glass
			Re = calcFresnelReflectance(rayDirection, n, nc, nt, ratioIoR);
			Tr = 1.0 - Re;

			if (bounces == 0 || (bounces == 1 && hitObjectID != objectID && bounceIsSpecular == TRUE))
			{
				reflectionMask = mask * Re;
				reflectionRayDirection = reflect(rayDirection, nl); // reflect ray from surface
				reflectionRayOrigin = x + nl * uEPS_intersect;
				willNeedReflectionRay = TRUE;
			}

			if (Re == 1.0)
			{
				mask = reflectionMask;
				rayOrigin = reflectionRayOrigin;
				rayDirection = reflectionRayDirection;

				willNeedReflectionRay = FALSE;
				bounceIsSpecular = TRUE;
				sampleLight = FALSE;
				continue;
			}

			// transmit ray through surface

			// is ray leaving a solid object from the inside? 
			// If so, attenuate ray color with object color by how far ray has travelled through the medium
			if (isRayExiting == TRUE)
			{
				isRayExiting = FALSE;
				mask *= exp(log(hitColor) * thickness * t);
			}
			else 
				mask *= hitColor;

			mask *= Tr;
			
			tdir = refract(rayDirection, nl, ratioIoR);
			rayDirection = tdir;
			rayOrigin = x - nl * uEPS_intersect;

			// if (diffuseCount == 1)
			// 	bounceIsSpecular = TRUE; // turn on refracting caustics
			// trick to make caustics brighter :)
			if (sampleLight == TRUE && bounces == 1)
				mask *= 5.0;

			continue;
			
		} // end if (hitType == REFR)
		
		if (hitType == COAT)  // Diffuse object underneath with ClearCoat on top
		{
			coatTypeIntersected = TRUE;
			
			nc = 1.0; // IOR of Air
			nt = 1.4; // IOR of Clear Coat
			Re = calcFresnelReflectance(rayDirection, nl, nc, nt, ratioIoR);
			Tr = 1.0 - Re;
			
			if (bounces == 0 || (bounces == 1 && hitObjectID != objectID && bounceIsSpecular == TRUE))
			{
				reflectionMask = mask * Re;
				reflectionRayDirection = reflect(rayDirection, nl); // reflect ray from surface
				reflectionRayOrigin = x + nl * uEPS_intersect;
				willNeedReflectionRay = TRUE;
			}

			diffuseCount++;

			if (bounces == 0)
				mask *= Tr;
			mask *= hitColor;

			bounceIsSpecular = FALSE;

			if (diffuseCount == 1 && rand() < 0.4)
			{
				mask /= 0.4;
				// choose random Diffuse sample vector
				rayDirection = randomCosWeightedDirectionInHemisphere(nl);
				rayOrigin = x + nl * uEPS_intersect;
				continue;
			}
			
			if (hitColor.r == 1.0 && rand() < 0.9) // this makes white capsule more 'white'
				dirToLight = sampleSphereLight(x, nl, spheres[0], weight);
			else
				dirToLight = sampleSphereLight(x, nl, lightChoice, weight);
			
			mask /= diffuseCount == 1 ? 0.6 : 1.0;
			mask *= weight * N_LIGHTS;
			
			rayDirection = dirToLight;
			rayOrigin = x + nl * uEPS_intersect;

			sampleLight = TRUE;
			continue;
			
		} //end if (hitType == COAT)

		
	} // end for (int bounces = 0; bounces < 6; bounces++)
	
	
	return max(vec3(0), accumCol);

} // end vec3 CalculateRadiance( out vec3 objectNormal, out vec3 objectColor, out float objectID, out float pixelSharpness )




//-----------------------------------------------------------------------
void SetupScene(void)
//-----------------------------------------------------------------------
{
	vec3 z  = vec3(0);          
	vec3 L1 = vec3(1.0, 1.0, 1.0) * 5.0;// White light
	vec3 L2 = vec3(1.0, 0.8, 0.2) * 4.0;// Yellow light
	vec3 L3 = vec3(0.1, 0.7, 1.0) * 2.0; // Blue light
		
        spheres[0] = Sphere(150.0, vec3(-400, 900, 200), L1, z, LIGHT);//spherical white Light1 
	spheres[1] = Sphere(100.0, vec3( 300, 400,-300), L2, z, LIGHT);//spherical yellow Light2
	spheres[2] = Sphere( 50.0, vec3( 500, 250,-100), L3, z, LIGHT);//spherical blue Light3
	
	spheres[3] = Sphere(1000.0, vec3(  0.0, 1000.0,  0.0), z, vec3(1.0, 1.0, 1.0), CHECK);//Checkered Floor
        
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
	seed = uvec2(uFrameCounter, uFrameCounter + 1.0) * uvec2(gl_FragCoord);

	// initialize rand() variables
	counter = -1.0; // will get incremented by 1 on each call to rand()
	channel = 0; // the final selected color channel to use for rand() calc (range: 0 to 3, corresponds to R,G,B, or A)
	randNumber = 0.0; // the final randomly-generated number (range: 0.0 to 1.0)
	randVec4 = vec4(0); // samples and holds the RGBA blueNoise texture value for this pixel
	randVec4 = texelFetch(tBlueNoiseTexture, ivec2(mod(gl_FragCoord.xy + floor(uRandomVec2 * 256.0), 256.0)), 0);
	
	vec2 pixelOffset = vec2( tentFilter(rand()), tentFilter(rand()) ) * 0.5;
	//vec2 pixelOffset = vec2(0);
	// we must map pixelPos into the range -1.0 to +1.0
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
	vec3 objectNormal, objectColor;
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

	if (uCameraIsMoving) // camera is currently moving
	{
		previousPixel.rgb *= 0.5; // motion-blur trail amount (old image)
		currentPixel.rgb *= 0.5; // brightness of new image (noisy)

		previousPixel.a = 0.0;
	}
	else
	{
		previousPixel.rgb *= 0.9; // motion-blur trail amount (old image)
		currentPixel.rgb *= 0.1; // brightness of new image (noisy)
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

	// makes sharp edges more stable
	if (previousPixel.a == 1.01)
		currentPixel.a = 1.01;

	// for dynamic scenes (to clear out old, dark, sharp pixel trails left behind from moving objects)
	if (previousPixel.a == 1.01 && rng() < 0.05)
		currentPixel.a = 1.0;
	
	
	pc_fragColor = vec4(previousPixel.rgb + currentPixel.rgb, currentPixel.a);
}
