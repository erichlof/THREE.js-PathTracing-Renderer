#version 300 es

precision highp float;
precision highp int;
precision highp sampler2D;

#include <pathtracing_uniforms_and_defines>

uniform sampler2D tTileNormalMapTexture;

#define N_SPHERES 2
#define N_RECTANGLES 1


//-----------------------------------------------------------------------

struct Ray { vec3 origin; vec3 direction; };
struct Sphere { float radius; vec3 position; vec3 emission; vec3 color; float IoR; int type; };
struct Rectangle { vec3 position; vec3 normal; float radiusU; float radiusV; vec3 emission; vec3 color; float IoR; int type; };
struct Intersection { vec3 normal; vec3 emission; vec3 color; float IoR; int type; };

Sphere spheres[N_SPHERES];
Rectangle rectangles[N_RECTANGLES];


#include <pathtracing_random_functions>

#include <pathtracing_calc_fresnel_reflectance>

#include <pathtracing_rectangle_intersect>

#include <pathtracing_sphere_intersect>


vec3 perturbNormal(vec3 nl, vec2 normalScale, vec2 uv)
{
        vec3 S = normalize( cross( abs(nl.y) < 0.9 ? vec3(0, 1, 0) : vec3(0, 0, 1), nl ) );
        vec3 T = cross(nl, S);
        vec3 N = normalize( nl );
        mat3 tsn = mat3( S, T, N );

        vec3 mapN = texture(tTileNormalMapTexture, uv).xyz * 2.0 - 1.0;
        mapN.xy *= normalScale;
        
        return normalize( tsn * mapN );
}


//-----------------------------------------------------------------------
float SceneIntersect( Ray r, inout Intersection intersec )
//-----------------------------------------------------------------------
{
	float d;
	float t = INFINITY;
	vec3 n;
	
        for (int i = 0; i < N_SPHERES; i++)
        {
		d = SphereIntersect( spheres[i].radius, spheres[i].position, r );
		if (d < t)
		{
			t = d;
			intersec.normal = normalize((r.origin + r.direction * t) - spheres[i].position);
			intersec.emission = spheres[i].emission;
			intersec.color = spheres[i].color;
                        intersec.IoR = spheres[i].IoR;
			intersec.type = spheres[i].type;
		}
        }
	
	d = RectangleIntersect( rectangles[0].position, rectangles[0].normal, rectangles[0].radiusU, rectangles[0].radiusV, r );
	if (d < t)
	{
                t = d;
                intersec.normal = normalize(rectangles[0].normal);
                intersec.emission = rectangles[0].emission;
                intersec.color = rectangles[0].color;
                intersec.IoR = rectangles[0].IoR;
                intersec.type = rectangles[0].type;
	}
        
	return t;
	
} // end float SceneIntersect( Ray r, inout Intersection intersec )



//-----------------------------------------------------------------------
vec3 CalculateRadiance( Ray r, inout uvec2 seed, out bool rayHitIsDynamic )
//-----------------------------------------------------------------------
{
	Intersection intersec;

	vec3 accumCol = vec3(0.0);
	vec3 mask = vec3(1.0);
	vec3 checkCol0 = vec3(1,1,0) * 0.6;
        vec3 checkCol1 = vec3(1,0,0) * 0.6;
	vec3 tdir;
	vec3 dirToLight = normalize(vec3(-0.2, 1.0, 0.7));
        vec3 n, nl, x;
        vec2 sphereUV;

	float nc, nt, Re;
        float epsIntersect = 1.0;//0.01;

        int previousIntersecType = -100;
        rayHitIsDynamic = false;
	
        for (int bounces = 0; bounces < 5; bounces++)
	{
		
		float t = SceneIntersect(r, intersec);
		
		if (t == INFINITY)
		{
                        float sun = max(0.0, dot(r.direction, dirToLight));
                        vec3 skyColor = vec3(0.0, 0.15, 0.5) + (pow(sun, 79.0) * vec3(3));
                        
			if (bounces == 0)
                                accumCol = skyColor;
                        else if (previousIntersecType == CHECK)
                                accumCol = mask;    
                        else if (previousIntersecType == REFR)
                                accumCol = mask * skyColor;
                        else if (previousIntersecType == SPEC)
                                accumCol = mask * skyColor;
                                
                        break;
		}

                // if we got here and previousIntersecType == CHECK, the shadow rays hit a sphere,
                // so make shadows on checkerboard and exit
                if (previousIntersecType == CHECK)
                {
                        if (intersec.type == REFR) // glass sphere
                                accumCol = mask * 0.7;
                        else // yellow spec sphere
                                accumCol = mask * 0.3;

                        break;
                }
                
		
		// useful data 
		n = intersec.normal;
                nl = dot(n,r.direction) <= 0.0 ? normalize(n) : normalize(n * -1.0);
		x = r.origin + r.direction * t;

		    
                if (intersec.type == CHECK ) // Ideal DIFFUSE reflection
		{
                        previousIntersecType = CHECK;

			float q = clamp( mod( dot( floor(x.xz * 0.04), vec2(1.0) ), 2.0 ) , 0.0, 1.0 );
			intersec.color = checkCol0 * q + checkCol1 * (1.0 - q);	
			
                        if (bounces == 4)
                        {
                                accumCol = intersec.color;
                                break;
                        }
                                
			mask = intersec.color;// * max(0., dot(nl, dirToLight));

                        r = Ray( x, dirToLight ); // shadow ray
			r.origin += nl * epsIntersect;

                        continue;
		}

                if (intersec.type == SPEC)  // special case SPEC/DIFF/COAT material for this classic scene
		{
                        previousIntersecType = SPEC;
                        rayHitIsDynamic = true;

                        sphereUV.x = atan(nl.z, nl.x) * ONE_OVER_TWO_PI + 0.5;
			sphereUV.y = asin(clamp(nl.y, -1.0, 1.0)) * ONE_OVER_PI + 0.5;
                        sphereUV *= 2.0;

			nl = perturbNormal(nl, vec2(-0.4, 0.4), sphereUV);

                        nc = 1.0; // IOR of Air
			nt = intersec.IoR; // IOR of 'metallic' ClearCoat
			Re = calcFresnelReflectance(n, nl, r.direction, nc, nt, tdir);
                        Re += 0.1; // add more reflectivity for this classic yellow-metal type material

			if (rand(seed) < Re) // reflect ray from surface
			{ 
                                mask = vec3(1); // this behaves like a reflective ClearCoat

				r = Ray( x, reflect(r.direction, nl) );
				r.origin += nl * epsIntersect;

			    	continue;	
			}
                        else
                        {
                                // treat as diffuse, apply typical NdotL lighting, and exit 
                                accumCol = intersec.color * max(0.2, dot(nl, dirToLight));

                                break;
                        }
			
		}
		
		if (intersec.type == REFR)  // Ideal dielectric REFRACTION
		{
                        previousIntersecType = REFR;

			nc = 1.0; // IOR of Air
			nt = intersec.IoR; // IOR of this classic demo's Glass
			Re = calcFresnelReflectance(n, nl, r.direction, nc, nt, tdir);
                        
                        if (bounces == 0)
                        {
                                Re *= 500.0;
                                Re += 0.1;
                        }
                        else
                        {
                                Re *= 2000.0;
                                Re += 0.01;
                        }
                        

                        if (rand(seed) < Re) // reflect ray from surface
			{
                                mask = vec3(1);
				r = Ray( x, reflect(r.direction, nl) );
				r.origin += nl * epsIntersect;

			    	continue;	
			}
			else // transmit ray through surface
			{
                                mask = intersec.color;
				r = Ray(x, tdir);
                                r.origin -= nl * epsIntersect;

				continue;
			}
			
		} // end if (intersec.type == REFR)
		
	} // end for (int bounces = 0; bounces < 5; bounces++)
	
	
	return accumCol;      
}


//-----------------------------------------------------------------------
void SetupScene(void)
//-----------------------------------------------------------------------
{
	vec3 z  = vec3(0.0);
	vec3 glassSpherePos = vec3(-10, 78, 70);
        vec3 yellowSpherePos = glassSpherePos + vec3(0,-25, 7);
        float orbitRadius = 70.0;
        spheres[0] = Sphere( 27.0, glassSpherePos, z, vec3(0.95), 1.005, REFR);//glass outer sphere
	spheres[1] = Sphere( 27.0, yellowSpherePos + vec3(-cos(mod(uTime, TWO_PI)) * orbitRadius, 0, sin(mod(uTime, TWO_PI)) * orbitRadius),
                        z, vec3(0.8, 0.7, 0.0), 1.001, SPEC);//yellow reflective sphere
	
	
	rectangles[0] = Rectangle( vec3(100, 0, -100), vec3(0, 1, 0), 200.0, 400.0, z, vec3(1), 1.0, CHECK);// Checkerboard Ground plane 
	
}

//#include <pathtracing_main>

// tentFilter from Peter Shirley's 'Realistic Ray Tracing (2nd Edition)' book, pg. 60		
float tentFilter(float x)
{
        if (x < 0.5) 
                return sqrt(2.0 * x) - 1.0;
        else return 1.0 - sqrt(2.0 - (2.0 * x));
}

void main( void )
{
        // not needed, three.js has a built-in uniform named cameraPosition
        //vec3 camPos   = vec3( uCameraMatrix[3][0],  uCameraMatrix[3][1],  uCameraMatrix[3][2]);
        
        vec3 camRight   = vec3( uCameraMatrix[0][0],  uCameraMatrix[0][1],  uCameraMatrix[0][2]);
        vec3 camUp      = vec3( uCameraMatrix[1][0],  uCameraMatrix[1][1],  uCameraMatrix[1][2]);
        vec3 camForward = vec3(-uCameraMatrix[2][0], -uCameraMatrix[2][1], -uCameraMatrix[2][2]);
        
        // seed for rand(seed) function
        uvec2 seed = uvec2(uFrameCounter, uFrameCounter + 1.0) * uvec2(gl_FragCoord);

        vec2 pixelPos = vec2(0);
        vec2 pixelOffset = vec2(0);

        float x = rand(seed);
        float y = rand(seed);

        if (!uCameraIsMoving)
        {
                pixelOffset.x = tentFilter(x);
                pixelOffset.y = tentFilter(y);
        }
        
        
        // pixelOffset ranges from -1.0 to +1.0, so only need to divide by half resolution
        pixelOffset /= (uResolution * 0.5);

        // we must map pixelPos into the range -1.0 to +1.0
	pixelPos = (gl_FragCoord.xy / uResolution) * 2.0 - 1.0;
        pixelPos += pixelOffset;

        vec3 rayDir = normalize( pixelPos.x * camRight * uULen + pixelPos.y * camUp * uVLen + camForward );
        
        // depth of field
        vec3 focalPoint = uFocusDistance * rayDir;
        float randomAngle = rand(seed) * TWO_PI; // pick random point on aperture
        float randomRadius = rand(seed) * uApertureSize;
        vec3  randomAperturePos = ( cos(randomAngle) * camRight + sin(randomAngle) * camUp ) * randomRadius;
        // point on aperture to focal point
        vec3 finalRayDir = normalize(focalPoint - randomAperturePos);
        
        Ray ray = Ray( cameraPosition + randomAperturePos, finalRayDir );

        SetupScene(); 

        bool rayHitIsDynamic;
        // perform path tracing and get resulting pixel color
        vec3 pixelColor = CalculateRadiance( ray, seed, rayHitIsDynamic );
        
	vec4 previousImage = texelFetch(tPreviousTexture, ivec2(gl_FragCoord.xy), 0);
	vec3 previousColor = previousImage.rgb;

        
	if (uCameraIsMoving || previousImage.a > 0.0)
	{
                previousColor *= 0.5; // motion-blur trail amount (old image)
                pixelColor *= 0.5; // brightness of new image (noisy)
        }
	else
	{
                previousColor *= 0.92; // motion-blur trail amount (old image)
                pixelColor *= 0.08; // brightness of new image (noisy)
        }
        
        out_FragColor = vec4( pixelColor + previousColor, rayHitIsDynamic? 1.0 : 0.0 );		
}