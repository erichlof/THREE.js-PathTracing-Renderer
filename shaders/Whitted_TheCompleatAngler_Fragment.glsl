precision highp float;
precision highp int;
precision highp sampler2D;

#include <pathtracing_uniforms_and_defines>

uniform sampler2D tTileNormalMapTexture;

#define N_SPHERES 3
#define N_RECTANGLES 1


//-----------------------------------------------------------------------

vec3 rayOrigin, rayDirection;
// recorded intersection data:
vec3 hitNormal, hitEmission, hitColor;
vec2 hitUV;
float hitObjectID;
int hitType = -100;

struct Sphere { float radius; vec3 position; vec3 emission; vec3 color; int type; };
struct Rectangle { vec3 position; vec3 normal; float radiusU; float radiusV; vec3 emission; vec3 color; int type; };

Sphere spheres[N_SPHERES];
Rectangle rectangles[N_RECTANGLES];


#include <pathtracing_random_functions>

#include <pathtracing_calc_fresnel_reflectance>

#include <pathtracing_rectangle_intersect>

#include <pathtracing_sphere_intersect>


vec3 perturbNormal(vec3 normal, vec2 bumpScale, vec2 uv)
{
	// note: incoming vec3 normal is assumed to be normalized
        vec3 S = normalize(cross(vec3(0, 0.9938837346736189, 0.11043152607484655), normal));
        vec3 T = cross(normal, S);
        vec3 N = normal;
	// invert S, T when the UV direction is backwards (from mirrored faces),
	// otherwise it will do the normal mapping backwards.
	// vec3 NfromST = cross( S, T );
	// if( dot( NfromST, N ) < 0.0 )
	// {
	// 	S *= -1.0;
	// 	T *= -1.0;
	// }
        mat3 tsn = mat3( S, T, N );

	vec3 mapN = texture(tTileNormalMapTexture, uv).xyz * 2.0 - 1.0;
	//mapN = normalize(mapN);
        mapN.xy *= bumpScale;
        
        return normalize( tsn * mapN );
}

// the following 3 functions combine to implement Blinn-Phong Lighting
vec3 doAmbientLighting(vec3 rayColorMask, vec3 materialColor, float ambientIntensity)
{
	vec3 ambientColor = rayColorMask * materialColor;
	return ambientColor * ambientIntensity;
}

vec3 doDiffuseDirectLighting(vec3 rayColorMask, vec3 materialColor, vec3 lightColor, float diffuseIntensity)
{
	vec3 diffuseColor = rayColorMask * materialColor * lightColor;
	return diffuseColor * diffuseIntensity;
}

vec3 doBlinnPhongSpecularLighting(vec3 rayColorMask, vec3 surfaceNormal, vec3 halfwayVector, vec3 lightColor, float materialRoughness, float diffuseIntensity)
{
	// for dielectric materials (non-conductors), specular color is unaffected by surface color
	// for metal materials (conductors) however, specular color gets tinted by the metal surface color
	// therefore, in the metal case, 'rayColorMask' will get pre-tinted before it is passed into this function
	vec3 specularColor = rayColorMask; // will either be white for dielectrics (usually vec3(1,1,1)), or tinted by metal color for metallics
	specularColor *= clamp(lightColor, 0.0, 4.0);
	float shininess = 1.0 - materialRoughness;
	float shininessExponent = max(2000.0 * shininess * shininess * shininess, 5.0);
	float specularIntensity = pow(max(0.0, dot(surfaceNormal, halfwayVector)), shininessExponent); // this is a powered cosine with shininess as the exponent
	// makes specular highlights fade away as surface shininess and diffuseIntensity decrease
	return specularColor * (specularIntensity * shininess * diffuseIntensity);
}


//-----------------------------------------------------------------------
float SceneIntersect()
//-----------------------------------------------------------------------
{
	float d;
	float t = INFINITY;
	vec3 n;

	d = RectangleIntersect( rectangles[0].position, rectangles[0].normal, rectangles[0].radiusU, rectangles[0].radiusV, rayOrigin, rayDirection );
	if (d < t)
	{
                t = d;
                hitNormal = rectangles[0].normal;
                hitEmission = rectangles[0].emission;
                hitColor = rectangles[0].color;
                hitType = rectangles[0].type;
	}

	d = SphereIntersect( spheres[0].radius, spheres[0].position, rayOrigin, rayDirection );
	if (d < t)
	{
		t = d;
		hitNormal = (rayOrigin + rayDirection * t) - spheres[0].position;
		hitEmission = spheres[0].emission;
		hitColor = spheres[0].color;
		hitType = spheres[0].type;
	}

	d = SphereIntersect( spheres[1].radius, spheres[1].position, rayOrigin, rayDirection );
	if (d < t)
	{
		t = d;
		hitNormal = (rayOrigin + rayDirection * t) - spheres[1].position;
		hitEmission = spheres[1].emission;
		hitColor = spheres[1].color;
		hitType = spheres[1].type;
	}

	d = SphereIntersect( spheres[2].radius, spheres[2].position, rayOrigin, rayDirection );
	if (d < t)
	{
		t = d;
		hitNormal = (rayOrigin + rayDirection * t) - spheres[2].position;
		hitEmission = spheres[2].emission;
		hitColor = spheres[2].color;
		hitType = spheres[2].type;
	}

        
	return t;
	
} // end float SceneIntersect()



//-----------------------------------------------------------------------
vec3 CalculateRadiance()
//-----------------------------------------------------------------------
{
	vec3 accumCol = vec3(0);
	vec3 mask = vec3(1);
	vec3 reflectionMask = vec3(1);
	vec3 reflectionRayOrigin = vec3(0);
	vec3 reflectionRayDirection = vec3(0);
	vec3 reflectionMask2 = vec3(1);
	vec3 reflectionRayOrigin2 = vec3(0);
	vec3 reflectionRayDirection2 = vec3(0);
	vec3 reflectionMask3 = vec3(1);
	vec3 reflectionRayOrigin3 = vec3(0);
	vec3 reflectionRayDirection3 = vec3(0);
	vec3 checkCol0 = vec3(1,1,0) * 0.8;
        vec3 checkCol1 = vec3(1,0,0) * 0.8;
	vec3 skyColor = vec3(0.01, 0.15, 0.7);
	vec3 sunlightColor = vec3(1);
	vec3 ambientColor = vec3(0);
	vec3 diffuseColor = vec3(0);
	vec3 specularColor = vec3(0);
	vec3 tdir;
	vec3 directionToLight = normalize(vec3(-0.2, 1.0, 0.7));
        vec3 n, nl, x;
	vec3 halfwayVector;

        vec2 sphereUV;

	float t;
	float ni, nt, ratioIoR, Re, Tr;
	float ambientIntensity = 0.2;
	float diffuseIntensity;
	float specularIntensity;

        int previousIntersecType;
	int bounceIsSpecular = FALSE;
        int sampleLight = FALSE;
	int willNeedReflectionRay = FALSE;
	int willNeedReflectionRay2 = FALSE;
	int willNeedReflectionRay3 = FALSE;
	int reflectionIsFromMetal = FALSE;

	hitType = -100;
	

        for (int bounces = 0; bounces < 12; bounces++)
	{
		previousIntersecType = hitType;

		t = SceneIntersect();
		
		if (t == INFINITY)
		{
			if (bounces == 0)
                        {
                                accumCol += mask * skyColor;
                                break;
                        }
			else if (sampleLight == TRUE)
			{
				accumCol += diffuseColor + specularColor;
			}
			else if (bounceIsSpecular == TRUE && reflectionIsFromMetal == FALSE)
			{
				accumCol += mask * skyColor;
			}
			

			if (willNeedReflectionRay == TRUE)
			{
				mask = reflectionMask;
				rayOrigin = reflectionRayOrigin;
				rayDirection = reflectionRayDirection;
				hitType = -100;
				willNeedReflectionRay = FALSE;
				sampleLight = FALSE;
				bounceIsSpecular = TRUE;
				continue;
			}

			if (willNeedReflectionRay2 == TRUE)
			{
				mask = reflectionMask2;
				rayOrigin = reflectionRayOrigin2;
				rayDirection = reflectionRayDirection2;
				hitType = -100;
				willNeedReflectionRay2 = FALSE;
				sampleLight = FALSE;
				bounceIsSpecular = TRUE;
				continue;
			}

			if (willNeedReflectionRay3 == TRUE)
			{
				mask = reflectionMask3;
				rayOrigin = reflectionRayOrigin3;
				rayDirection = reflectionRayDirection3;
				hitType = -100;
				willNeedReflectionRay3 = FALSE;
				sampleLight = FALSE;
				bounceIsSpecular = TRUE;
				continue;
			}

                        break;
		}

                
                // if we get here and sampleLight is still TRUE, shadow ray failed to find the light source 
		// the ray hit an occluding object along its way to the light
                if (sampleLight == TRUE)
                {
			if (bounces == 1 && hitType == REFR && previousIntersecType == CHECK)
			{
				accumCol *= 3.5; // make shadow underneath glass sphere a little lighter
				break;
			}

                        if (willNeedReflectionRay == TRUE)
			{
				mask = reflectionMask;
				rayOrigin = reflectionRayOrigin;
				rayDirection = reflectionRayDirection;
				hitType = -100;
				willNeedReflectionRay = FALSE;
				sampleLight = FALSE;
				bounceIsSpecular = TRUE;
				continue;
			}

			if (willNeedReflectionRay2 == TRUE)
			{
				mask = reflectionMask2;
				rayOrigin = reflectionRayOrigin2;
				rayDirection = reflectionRayDirection2;
				hitType = -100;
				willNeedReflectionRay2 = FALSE;
				sampleLight = FALSE;
				bounceIsSpecular = TRUE;
				continue;
			}

			if (willNeedReflectionRay3 == TRUE)
			{
				mask = reflectionMask3;
				rayOrigin = reflectionRayOrigin3;
				rayDirection = reflectionRayDirection3;
				hitType = -100;
				willNeedReflectionRay3 = FALSE;
				sampleLight = FALSE;
				bounceIsSpecular = TRUE;
				continue;
			}

                        break;
                }


		// useful data 
		n = normalize(hitNormal);
                nl = dot(n, rayDirection) < 0.0 ? n : -n;
		x = rayOrigin + rayDirection * t;
		halfwayVector = normalize(-rayDirection + directionToLight); // this is Blinn's modification to Phong's model
		

		    
                if (hitType == CHECK ) // Ideal DIFFUSE reflection
		{
			bounceIsSpecular = FALSE;

			float q = clamp( mod( dot( floor(x.xz * 0.04), vec2(1.0) ), 2.0 ) , 0.0, 1.0 );
			hitColor = checkCol0 * q + checkCol1 * (1.0 - q);	

			ambientColor = doAmbientLighting(mask, hitColor, ambientIntensity);
			accumCol += ambientColor;

			diffuseIntensity = max(0.0, dot(nl, directionToLight));
			diffuseColor = doDiffuseDirectLighting(mask, hitColor, sunlightColor, diffuseIntensity);

			specularColor = vec3(0);

                        rayDirection = directionToLight; // shadow ray
			rayOrigin = x + nl * uEPS_intersect;
                        sampleLight = TRUE;
                        continue;
		}

                if (hitType == SPEC)  // special case SPEC/DIFF/COAT material for this classic scene
		{
			bounceIsSpecular = FALSE;

                        sphereUV.x = atan(-nl.z, nl.x) * ONE_OVER_PI;
			sphereUV.y = acos(-nl.y) * ONE_OVER_PI;
			sphereUV.y *= 2.0;

			nl = perturbNormal(nl, vec2(0.5, 0.5), sphereUV);

                        ambientColor = doAmbientLighting(mask, hitColor, ambientIntensity);
			accumCol += ambientColor * 0.6;

			diffuseIntensity = max(0.0, dot(nl, directionToLight));
			diffuseColor = doDiffuseDirectLighting(mask, hitColor, sunlightColor, diffuseIntensity);

			specularColor = doBlinnPhongSpecularLighting(mask, nl, halfwayVector, sunlightColor * 2.0, 0.6, diffuseIntensity);

			if (bounces == 0)
			{
				reflectionMask = mask * 0.15;
				reflectionRayDirection = reflect(rayDirection, nl); // reflect ray from surface
				reflectionRayOrigin = x + nl * uEPS_intersect;
				willNeedReflectionRay = TRUE;
				reflectionIsFromMetal = TRUE;
			}

			rayDirection = directionToLight; // shadow ray
			rayOrigin = x + nl * uEPS_intersect;
			sampleLight = TRUE;
                        continue;
		}
		
		if (hitType == REFR)  // Ideal dielectric REFRACTION
		{
			ni = 1.0; // IOR of Air
			nt = hitColor == vec3(1) ? 1.01 : 1.04; // IOR of this classic demo's Glass

			//Re = calcFresnelReflectance(rayDirection, n, ni, nt, ratioIoR);
			ratioIoR = ni / nt;

			if (bounces == 0)
			{
				reflectionMask = mask * 0.05;// * Re;
				reflectionRayDirection = reflect(rayDirection, nl); // reflect ray from surface
				reflectionRayOrigin = x + nl * uEPS_intersect;
				willNeedReflectionRay = TRUE;
			}

			if (bounces == 1 && previousIntersecType == REFR)
			{
				reflectionMask2 = mask * 0.05;// * Re;
				reflectionRayDirection2 = reflect(rayDirection, nl); // reflect ray from surface
				reflectionRayOrigin2 = x + nl * uEPS_intersect;
				willNeedReflectionRay2 = TRUE;
			}

			if (bounces == 2 && previousIntersecType == REFR)
			{
				reflectionMask3 = mask * 0.05;// * Re;
				reflectionRayDirection3 = reflect(rayDirection, nl); // reflect ray from surface
				reflectionRayOrigin3 = x + nl * uEPS_intersect;
				willNeedReflectionRay3 = TRUE;
			}

			ambientColor = vec3(0);
			diffuseColor = vec3(0);

			diffuseIntensity = max(0.0, dot(nl, directionToLight));
			specularColor = doBlinnPhongSpecularLighting(mask, nl, halfwayVector, sunlightColor * 1.5, 0.5, diffuseIntensity);
			if (bounces == 0)
				accumCol += specularColor;
			else accumCol += specularColor * 0.2;
			specularColor = vec3(0);

			// transmit ray through surface
			//mask *= hitColor;
			//mask *= Tr;
			mask *= 0.95;
			
			tdir = refract(rayDirection, nl, ratioIoR);
			rayDirection = tdir;
			rayOrigin = x - nl * uEPS_intersect;
			bounceIsSpecular = TRUE;
			
			continue;
			
		} // end if (hitType == REFR)
		
	} // end for (int bounces = 0; bounces < 12; bounces++)
	
	
	return max(vec3(0), accumCol);

} // end vec3 CalculateRadiance()


//-----------------------------------------------------------------------
void SetupScene(void)
//-----------------------------------------------------------------------
{
	vec3 z  = vec3(0.0);
	vec3 glassSpherePos = vec3(-10, 78, 70);
        vec3 yellowSpherePos = glassSpherePos + vec3(0,-19, 5);
	//vec3 yellowSpherePos = glassSpherePos + vec3(50,-25, 70);
        float orbitRadius = 70.0;
        spheres[0] = Sphere( 28.0, glassSpherePos, z, vec3(1), REFR);//glass sphere 28.0
	spheres[1] = Sphere( 26.5, glassSpherePos, z, vec3(0.99), REFR);//glass sphere 26.5
	spheres[2] = Sphere( 27.0, yellowSpherePos + vec3(-cos(mod(uTime * 1.1, TWO_PI)) * orbitRadius, 0, sin(mod(uTime * 1.1, TWO_PI)) * orbitRadius),
                         z, vec3(1.0, 0.85, 0.0), SPEC);//yellow reflective sphere
	
	rectangles[0] = Rectangle( vec3(100, 0, -100), vec3(0,1,0), 200.0, 400.0, z, vec3(1), CHECK);// Checkerboard Ground plane 
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
	randNumber = 0.0; // the final randomly-generated number (range: 0.0 to 1.0)
	blueNoise = texelFetch(tBlueNoiseTexture, ivec2(mod(floor(gl_FragCoord.xy), 128.0)), 0).r;

	vec2 pixelOffset = vec2( tentFilter(rand()), tentFilter(rand()) ) * 0.75;
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
        
        rayOrigin = cameraPosition + randomAperturePos;
	rayOrigin += !uUseOrthographicCamera ? vec3(0) : 
		     (camRight * pixelPos.x * uULen * 100.0) + (camUp * pixelPos.y * uVLen * 100.0);
					     
	rayDirection = finalRayDir;


        SetupScene(); 

        // perform path tracing and get resulting pixel color
        vec3 pixelColor = CalculateRadiance();
        
	vec3 previousColor = texelFetch(tPreviousTexture, ivec2(gl_FragCoord.xy), 0).rgb;

        
	if (uCameraIsMoving)
	{
                previousColor *= 0.5; // motion-blur trail amount (old image)
                pixelColor *= 0.5; // brightness of new image (noisy)
        }
	else
	{
                previousColor *= 0.6; // motion-blur trail amount (old image)
                pixelColor *= 0.4; // brightness of new image (noisy)
        }
	
        
        pc_fragColor = vec4( pixelColor + previousColor, 1.01);		
}
