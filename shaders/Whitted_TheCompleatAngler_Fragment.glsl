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


vec3 perturbNormal(vec3 nl, vec2 normalScale, vec2 uv)
{
	// note: incoming vec3 nl is assumed to be normalized
        vec3 S = normalize( cross( abs(nl.y) < 0.9 ? vec3(0, 1, 0) : vec3(0, 0, 1), nl ) );
        vec3 T = cross(nl, S);
        vec3 N = nl;
	// invert S, T when the UV direction is backwards (from mirrored faces),
	// otherwise it will do the normal mapping backwards.
	vec3 NfromST = cross( S, T );
	if( dot( NfromST, N ) < 0.0 )
	{
		S *= -1.0;
		T *= -1.0;
	}
        mat3 tsn = mat3( S, T, N );

	vec3 mapN = texture(tTileNormalMapTexture, uv).xyz * 2.0 - 1.0;
	//mapN = normalize(mapN);
        mapN.xy *= normalScale;
        
        return normalize( tsn * mapN );
}


//-----------------------------------------------------------------------
float SceneIntersect()
//-----------------------------------------------------------------------
{
	float d;
	float t = INFINITY;
	vec3 n;
	
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
		}
        }
	
	d = RectangleIntersect( rectangles[0].position, rectangles[0].normal, rectangles[0].radiusU, rectangles[0].radiusV, rayOrigin, rayDirection );
	if (d < t)
	{
                t = d;
                hitNormal = rectangles[0].normal;
                hitEmission = rectangles[0].emission;
                hitColor = rectangles[0].color;
                hitType = rectangles[0].type;
	}
        
	return t;
	
} // end float SceneIntersect()



//-----------------------------------------------------------------------
vec3 CalculateRadiance()
//-----------------------------------------------------------------------
{
	vec3 accumCol = vec3(0);
	vec3 mask = vec3(1);
	vec3 checkCol0 = vec3(1,1,0) * 0.6;
        vec3 checkCol1 = vec3(1,0,0) * 0.6;
	vec3 tdir;
	vec3 dirToLight = normalize(vec3(-0.2, 1.0, 0.7));
        vec3 n, nl, x;

        vec2 sphereUV;

	float t;
	float nc, nt, ratioIoR, Re, Tr;
	float P, RP, TP;

        int previousIntersecType = -100;

        bool firstTypeWasREFR = false;
        bool sampleLight = false;
	

        for (int bounces = 0; bounces < 8; bounces++)
	{
		
		float sun = max(0.0, dot(rayDirection, dirToLight));
                vec3 skyColor = vec3(0.0, 0.11, 0.5) + (pow(sun, 50.0) * vec3(5));

		t = SceneIntersect();
		
		if (t == INFINITY)
		{
			if (bounces == 0)
                        {
                                accumCol += mask * skyColor;
                                break;
                        }
			else if (previousIntersecType == REFR)
				accumCol += mask * skyColor * 0.51;
			else if (previousIntersecType == SPEC)
				accumCol += mask * skyColor * 0.2;

                        break;
		}

                
                // if we got here and sampleLight is still true, the shadow rays failed to find a light source or sky,
                // so make shadows on checkerboard or yellow sphere and exit
                if (sampleLight)
                {
			if (previousIntersecType == CHECK)
			{
				if (hitType == REFR) // glass sphere, lighter shadow
                                	accumCol *= 0.8;
				else if (hitType == SPEC) // yellow spec sphere, darker shadow
					accumCol *= 0.5;
			}
                        
                        //accumCol = mask;

                        break;
                }


		// useful data 
		n = normalize(hitNormal);
                nl = dot(n, rayDirection) < 0.0 ? n : -n;
		x = rayOrigin + rayDirection * t;

		    
                if (hitType == CHECK ) // Ideal DIFFUSE reflection
		{
			float q = clamp( mod( dot( floor(x.xz * 0.04), vec2(1.0) ), 2.0 ) , 0.0, 1.0 );
			hitColor = checkCol0 * q + checkCol1 * (1.0 - q);	

			if (previousIntersecType == SPEC)
				accumCol += hitColor * 0.3;
			else if (previousIntersecType == REFR)
				accumCol += hitColor * 0.8;
			else accumCol += hitColor;

                        rayDirection = dirToLight; // shadow ray
			rayOrigin = x + nl * uEPS_intersect;

                        sampleLight = true;
			previousIntersecType = CHECK;
                        continue;
		}

                if (hitType == SPEC)  // special case SPEC/DIFF/COAT material for this classic scene
		{
                        sphereUV.x = atan(nl.z, nl.x) * ONE_OVER_TWO_PI + 0.5;
			sphereUV.y = asin(clamp(nl.y, -1.0, 1.0)) * ONE_OVER_PI + 0.5;
                        sphereUV *= 2.0;

			nl = perturbNormal(nl, vec2(-0.5, 0.5), sphereUV);

                        // temporarily treat as diffuse, apply typical NdotL lighting 
                        accumCol += hitColor * max(0.05, dot(nl, dirToLight));

			
			rayDirection = reflect(rayDirection, nl);
			rayOrigin = x + nl * uEPS_intersect;

			previousIntersecType = SPEC;
                        continue;
		}
		
		if (hitType == REFR)  // Ideal dielectric REFRACTION
		{
			if (previousIntersecType == SPEC)
			{
				accumCol += skyColor * 0.2;
				break;
			}

			previousIntersecType = REFR;

			nc = 1.0; // IOR of Air
			nt = hitColor == vec3(1) ? 1.001 : 1.01; // IOR of this classic demo's Glass
			Re = calcFresnelReflectance(rayDirection, n, nc, nt, ratioIoR);
                        Tr = 1.0 - Re;
			P  = 0.25 + (0.5 * Re);
                	RP = Re / P;
                	TP = Tr / (1.0 - P);

			if (rand() < P && hitColor != vec3(1))
			{
				//mask *= RP;
				mask *= 0.4;
				rayDirection = reflect(rayDirection, nl); // reflect ray from surface
				rayOrigin = x + nl * uEPS_intersect;
				continue;
			}

			// transmit ray through surface
			//mask *= hitColor;
			mask *= TP;
			
			tdir = refract(rayDirection, nl, ratioIoR);
			rayDirection = tdir;
			rayOrigin = x - nl * uEPS_intersect;
			
			continue;
			
		} // end if (hitType == REFR)
		
	} // end for (int bounces = 0; bounces < 8; bounces++)
	
	
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
        spheres[0] = Sphere( 28.0, glassSpherePos, z, vec3(1), REFR);//glass sphere
	spheres[1] = Sphere( 26.5, glassSpherePos, z, vec3(0.95), REFR);//glass sphere
	spheres[2] = Sphere( 27.0, yellowSpherePos + vec3(-cos(mod(uTime * 1.1, TWO_PI)) * orbitRadius, 0, sin(mod(uTime * 1.1, TWO_PI)) * orbitRadius),
                        z, vec3(1.0, 0.85, 0.0), SPEC);//yellow reflective sphere

	//spheres[1] = Sphere( 27.0, yellowSpherePos, z, vec3(1.0, 0.8, 0.0), SPEC);//yellow reflective sphere
	
	rectangles[0] = Rectangle( vec3(100, 0, -100), vec3(0, 1, 0), 200.0, 400.0, z, vec3(1), CHECK);// Checkerboard Ground plane 
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

	// if current raytraced pixel didn't return any color value, just use the previous frame's pixel color
	/* if (pixelColor == vec3(0.0))
	{
		pixelColor = previousColor;
		previousColor *= 0.5;
		pixelColor *= 0.5;
	} */
        
        pc_fragColor = vec4( pixelColor + previousColor, 1.01);		
}
