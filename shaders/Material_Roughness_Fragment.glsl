precision highp float;
precision highp int;
precision highp sampler2D;

#include <pathtracing_uniforms_and_defines>
uniform int uMaterialType;
uniform vec3 uMaterialColor;

#define N_LIGHTS 3.0
#define N_SPHERES 15


//-----------------------------------------------------------------------

struct Ray { vec3 origin; vec3 direction; };
struct Sphere { float radius; vec3 position; vec3 emission; vec3 color; float roughness; int type; };
struct Intersection { vec3 normal; vec3 emission; vec3 color; float roughness; int type; };

Sphere spheres[N_SPHERES];


#include <pathtracing_random_functions>

#include <pathtracing_calc_fresnel_reflectance>

#include <pathtracing_sphere_intersect>

#include <pathtracing_sample_sphere_light>


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
                        intersec.roughness = spheres[i].roughness;
			intersec.type = spheres[i].type;
		}
	}
        
	return t;
	
} // end float SceneIntersect( Ray r, inout Intersection intersec )


//-----------------------------------------------------------------------
vec3 CalculateRadiance(Ray r)
//-----------------------------------------------------------------------
{
	Intersection intersec;
	Sphere lightChoice;

	vec3 accumCol = vec3(0);
        vec3 mask = vec3(1);
	vec3 checkCol0 = vec3(1);
	vec3 checkCol1 = vec3(0.5);
	vec3 dirToLight;
	vec3 tdir;
	vec3 x, n, nl, normal;
        
	float t;
	float nc, nt, ratioIoR, Re, Tr;
	float P, RP, TP;
	float randChoose;
	float weight;
	float thickness = 0.05;

	int diffuseCount = 0;

	bool bounceIsSpecular = true;
	bool sampleLight = false;

	randChoose = rand() * N_LIGHTS; // 3 lights to choose from
	lightChoice = spheres[int(randChoose)];

	
	for (int bounces = 0; bounces < 7; bounces++)
	{

		t = SceneIntersect(r, intersec);
		
		/*
		//not used in this scene because we are inside a huge sphere - no rays can escape
		if (t == INFINITY)
		{
                        break;
		}
		*/
		
		
		if (intersec.type == LIGHT)
		{	
			if (bounceIsSpecular || sampleLight)
				accumCol = mask * intersec.emission;
			// reached a light, so we can exit
			break;

		} // end if (intersec.type == LIGHT)


		if (sampleLight)// && intersec.type != REFR)
			break;


		// useful data 
		n = normalize(intersec.normal);
                nl = dot(n, r.direction) < 0.0 ? normalize(n) : normalize(-n);
		x = r.origin + r.direction * t;

		    
                if (intersec.type == DIFF || intersec.type == CHECK) // Ideal DIFFUSE reflection
		{
			diffuseCount++;

			if( intersec.type == CHECK )
			{
				float q = clamp( mod( dot( floor(x.xz * 0.04), vec2(1.0) ), 2.0 ) , 0.0, 1.0 );
				intersec.color = checkCol0 * q + checkCol1 * (1.0 - q);	
			}

			mask *= intersec.color;
			bounceIsSpecular = false;

			if (diffuseCount == 1 && rand() < 0.5)
			{
				r = Ray( x, randomCosWeightedDirectionInHemisphere(nl) );
				r.origin += nl * uEPS_intersect;
				continue;
			}

			dirToLight = sampleSphereLight(x, nl, lightChoice, dirToLight, weight);
			mask *= weight * N_LIGHTS;

			r = Ray( x, dirToLight );
			r.origin += nl * uEPS_intersect;

			sampleLight = true;
			continue;
                        
		} // end if (intersec.type == DIFF)
		
		if (intersec.type == SPEC)  // Ideal SPECULAR reflection
		{
			mask *= intersec.color;
			r = Ray( x, reflect(r.direction, nl) );
			r.direction = randomDirectionInSpecularLobe(r.direction, intersec.roughness);
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
			P  = 0.25 + (0.5 * Re);
                	RP = Re / P;
                	TP = Tr / (1.0 - P);
			
			if (rand() < P)
			{
				mask *= RP;
				r = Ray( x, reflect(r.direction, nl) ); // reflect ray from surface
				r.direction = randomDirectionInSpecularLobe(r.direction, intersec.roughness);
				r.origin += nl * uEPS_intersect;
				continue;
			}

			// transmit ray through surface
			// is ray leaving a solid object from the inside? 
			// If so, attenuate ray color with object color by how far ray has travelled through the medium
			if (distance(n, nl) > 0.1)
			{
				mask *= exp(log(intersec.color) * thickness * t);
			}

			mask *= TP;
			
			tdir = refract(r.direction, nl, ratioIoR);
			r = Ray(x, tdir);
			r.direction = randomDirectionInSpecularLobe(r.direction, intersec.roughness * intersec.roughness);
			r.origin -= nl * uEPS_intersect;

			if (diffuseCount == 1)
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
			
			if (rand() < P)
			{
				mask *= RP;
				r = Ray( x, reflect(r.direction, nl) ); // reflect ray from surface
				r.direction = randomDirectionInSpecularLobe(r.direction, intersec.roughness);
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
			
			dirToLight = sampleSphereLight(x, nl, lightChoice, dirToLight, weight);
			mask *= weight * N_LIGHTS;
			
			r = Ray( x, dirToLight );
			r.origin += nl * uEPS_intersect;

			sampleLight = true;
			continue;
                        
		} //end if (intersec.type == COAT)

		if (intersec.type == METALCOAT)  // Metal object underneath with ClearCoat on top
		{
			nc = 1.0; // IOR of Air
			nt = 1.5; // IOR of Clear Coat
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

			mask *= TP;
			mask *= intersec.color;
                        
			r = Ray( x, reflect(r.direction, nl) );
			r.direction = randomDirectionInSpecularLobe(r.direction, intersec.roughness);
			r.origin += nl * uEPS_intersect;

			continue;
                        
		} //end if (intersec.type == METALCOAT)

		
	} // end for (int bounces = 0; bounces < 7; bounces++)
	
	
	return max(vec3(0), accumCol);

} // end vec3 CalculateRadiance(Ray r)


//-----------------------------------------------------------------------
void SetupScene(void)
//-----------------------------------------------------------------------
{
	vec3 z  = vec3(0);          
	vec3 L1 = vec3(1.0, 1.0, 1.0) * 13.0;// White light
	vec3 L2 = vec3(1.0, 0.8, 0.2) * 10.0;// Yellow light
	vec3 L3 = vec3(0.1, 0.7, 1.0) * 5.0; // Blue light
	
	vec3 color = uMaterialColor;
	int typeID = uMaterialType;
	
        spheres[0]  = Sphere(150.0, vec3(-400, 900, 200), L1, z, 0.0, LIGHT);//spherical white Light1 
	spheres[1]  = Sphere(100.0, vec3( 300, 400,-300), L2, z, 0.0, LIGHT);//spherical yellow Light2
	spheres[2]  = Sphere( 50.0, vec3( 500, 250,-100), L3, z, 0.0, LIGHT);//spherical blue Light3
	
	spheres[3]  = Sphere(1000.0, vec3(  0.0, 1000.0,  0.0), z, vec3(1.0, 1.0, 1.0), 0.0, CHECK);//Checkered Floor

        spheres[4]  = Sphere(  14.0, vec3(-150, 30, 0), z, color, 0.0, typeID);
        spheres[5]  = Sphere(  14.0, vec3(-120, 30, 0), z, color, 0.1, typeID);
        spheres[6]  = Sphere(  14.0, vec3( -90, 30, 0), z, color, 0.2, typeID);
        spheres[7]  = Sphere(  14.0, vec3( -60, 30, 0), z, color, 0.3, typeID);
        spheres[8]  = Sphere(  14.0, vec3( -30, 30, 0), z, color, 0.4, typeID);
        spheres[9]  = Sphere(  14.0, vec3(   0, 30, 0), z, color, 0.5, typeID);
        spheres[10] = Sphere(  14.0, vec3(  30, 30, 0), z, color, 0.6, typeID);
        spheres[11] = Sphere(  14.0, vec3(  60, 30, 0), z, color, 0.7, typeID);
        spheres[12] = Sphere(  14.0, vec3(  90, 30, 0), z, color, 0.8, typeID);
        spheres[13] = Sphere(  14.0, vec3( 120, 30, 0), z, color, 0.9, typeID);
        spheres[14] = Sphere(  14.0, vec3( 150, 30, 0), z, color, 1.0, typeID);
}


#include <pathtracing_main>
