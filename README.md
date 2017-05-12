# THREE.js-PathTracing-Renderer
Real-time PathTracing with global illumination and progressive rendering, all on top of the Three.js WebGL framework.

<h2>LIVE DEMOS</h2>

* [Geometry Showcase Demo](https://erichlof.github.io/THREE.js-PathTracing-Renderer/ThreeJS_PathTracing_Renderer_GeometryShowcase.html) demonstrating some primitive shapes for ray tracing.

* [Cornell Box Demo](https://erichlof.github.io/THREE.js-PathTracing-Renderer/ThreeJS_PathTracing_Renderer_CornellBox_DirectLighting.html) which renders the famous Cornell Box, but at ~60 fps!

For comparison, here is a real photograph of the original Cornell Box vs. a rendering with the three.js PathTracer:

![](readme-Images/measured.jpg) ![](readme-Images/CornellBox-Render0.png)

* [Water Rendering Demo](https://erichlof.github.io/THREE.js-PathTracing-Renderer/ThreeJS_PathTracing_Renderer_Water_Rendering.html) Renders photo-realistic water and simulates waves at 60 FPS. No triangle meshes are needed, as opposed to other traditional engines/renderers. In fact, not a single triangle was harmed during the making of this water volume! It is done through object/ray warping. Total cost: 1 ray-box intersection test!  

* [Ocean and Sky Demo](https://erichlof.github.io/THREE.js-PathTracing-Renderer/ThreeJS_PathTracing_Renderer_Ocean_Rendering.html) which models an enormous calm ocean underneath a realistic physical sky and time of day.

* [Quadric Geometry Demo](https://erichlof.github.io/THREE.js-PathTracing-Renderer/ThreeJS_PathTracing_Renderer_QuadricGeometryShowcase.html) showing different quadric (mathematical) shapes (Warning: this may take 7-10 seconds to load/compile!)

<h3>Constructive Solid Geometry(CSG) Museum Demos</h3>

The following demos showcase different techniques in Constructive Solid Geometry - taking one 3D shape and either adding, removing, or overlapping a second shape. (Warning: these demos may take 10 seconds to load/compile!) <br>
All 4 demos feature a large dark glass sculpture in the center of the room, which shows Ellipsoid vs. Sphere CSG. <br>
Along the back wall, a study in Box vs. Sphere CSG: [CSG_Museum Demo #1](https://erichlof.github.io/THREE.js-PathTracing-Renderer/ThreeJS_PathTracing_Renderer_CSG_Museum_1.html) <br>
Along the right wall, a glass-encased monolith, and a study in Sphere vs. Cylinder CSG: [CSG_Museum Demo #2](https://erichlof.github.io/THREE.js-PathTracing-Renderer/ThreeJS_PathTracing_Renderer_CSG_Museum_2.html) <br>
Along the wall behind the camera, a study in Ellipsoid vs. Sphere CSG: [CSG_Museum Demo #3](https://erichlof.github.io/THREE.js-PathTracing-Renderer/ThreeJS_PathTracing_Renderer_CSG_Museum_3.html) <br>
Along the left wall, a study in Box vs. Cone CSG: [CSG_Museum Demo #4](https://erichlof.github.io/THREE.js-PathTracing-Renderer/ThreeJS_PathTracing_Renderer_CSG_Museum_4.html) <br>

Important note! - There is a hidden Easter Egg in one of the 4 Museum demo rooms.  Happy hunting!

<h3>Materials Demos</h3>

These demos showcase different materials possibilities: <br>
[Materials Demo #1](https://erichlof.github.io/THREE.js-PathTracing-Renderer/ThreeJS_PathTracing_Renderer_MaterialsShowcase_1.html) Refractive (glass/water) and ClearCoat (billiard ball/car paint) materials <br>
[Materials Demo #2](https://erichlof.github.io/THREE.js-PathTracing-Renderer/ThreeJS_PathTracing_Renderer_MaterialsShowcase_2.html) Cheap Volumetric (smoke/fog/gas) and Specular (aluminum mirror) materials <br>
[Materials Demo #3](https://erichlof.github.io/THREE.js-PathTracing-Renderer/ThreeJS_PathTracing_Renderer_MaterialsShowcase_3.html) Diffuse (matte wall paint/chalk) and Translucent (skin/balloons,etc.) materials <br>
[Materials Demo #4](https://erichlof.github.io/THREE.js-PathTracing-Renderer/ThreeJS_PathTracing_Renderer_MaterialsShowcase_4.html) Metallic (Gold) and shiny SubSurface scattering (polished Jade/wax candles) materials <br>

![](readme-Images/threejsPathTracing.png)

<br>
<h2>FEATURES</h2>

* Real-time interactive Path Tracing in your Chrome browser - even on your smartphone! ( What?! )
* First-Person camera navigation through the 3D scene.
* When camera is still, switches to progressive rendering mode and converges on a photo-realistic result!
* The accumulated render image will converge at around 1,000-2,000 samples (lower for simple scenes, higher for complex scenes).
* Direct lighting now makes images render/converge almost instantly!
* Support for: Spheres, Planes, Discs, Quads, Triangles, and quadrics such as Cylinders, Cones, Ellipsoids, Paraboloids, Hyperboloids, Capsules, and Rings/Torii.
* Constructive Solid Geometry(CSG) allows you to combine 2 shapes using operations like addition, subtraction, and overlap.
* Basic support for loading models in .obj format (triangle and quad faces are supported, but no higher-order polys like pentagon, hexagon, etc.)
* Current material options: Metallic (mirrors, gold, etc.), Refractive (glass, water, etc.), Diffuse(matte, chalk, etc), ClearCoat(cars, plastic, billiard balls, etc.), Translucent (skin, leaves, cloth, etc.), Subsurface w/ shiny coat (jelly beans, cherries, teeth, polished Jade, etc.), Volumetric (smoke, dust, fog, etc.)
* Diffuse/Matte objects use Monte Carlo integration (a random process, hence the visual noise) to sample the unit-hemisphere oriented around the normal of the ray-object hitpoint and collects any light that is being received.  This is the key-difference between path tracing and simple old-fashioned ray tracing.  This is what produces realistic global illumination effects such as color bleeding/sharing between diffuse objects and refractive caustics from specular/glass/water objects.
* Camera has Depth of Field with real-time adjustable Focal Distance and Aperture Size settings for a still-photography or cinematic look.
* SuperSampling gives beautiful, clean Anti-Aliasing (no jagged edges!)
* Users will be able to use easy, familiar commands from the Three.js library, but under-the-hood the Three.js Renderer will use this path tracing engine to render the final output to the screen.

<h3>Experimental Works in Progress (W.I.P.)</h3>

The following demos show what I have been experimenting with most recently.  They might not work 100% and might have small visual artifacts that I am trying to fix.  I just wanted to share some more possible areas in the world of path tracing! :-) <br>

Rendering spheres, boxes and mathematical shapes is nice, but most modern graphics models are built out of triangles.  The following demo uses an .obj loader to load a model in .obj format (list of triangles) from disk and then places it in a scene to be path traced.  As of now, it runs too slow for my taste.  It still needs a BVH acceleration structure to speed things up greatly (I am currently investigating different approaches on the GPU). I am showing this because I wanted to demonstrate the ability of the three.js PathTracing renderer to load and render a model in one of the most popular model formats ever: <br>

* [.OBJ Model Loading Demo](https://erichlof.github.io/THREE.js-PathTracing-Renderer/ThreeJS_PathTracing_Renderer_OBJModel_Loader.html)<br>

I now have a working BVH (Bounding Volume Hierarchy) builder.  It builds a nested set of bounding boxes to avoid having to test every single triangle in the scene. Scenes which used to render at 10 FPS are now rendering at 50-60 FPS! For BVH test purposes, I randomize the branch that the ray takes when it is traversing the array of Bounding Boxes.  Hence the following demo, which renders the triangle model (a vintage desktop DOS PC - ha ha) as more of a 'point cloud' than a solid object. This is because the rays are taking random branches since in WebGL 1.0, I can't keep a stack with dynamic indexing like Boxes[x].data where x is the correct branch. But at least the model is loading and rendering very quickly. I just have to figure out how to access the arrays of boxes somehow so that the ray always takes the correct branch, and backs up and takes the other fork if it fails.  In the meantime, enjoy this 'artistic' rendering, where it seems to ask, "What is real? Does the computer create the scene, or does the ray-tracing scene create the computer?"  I know, I know - programmer art! :D <br>

* [BVH Debugging Demo](https://erichlof.github.io/THREE.js-PathTracing-Renderer/ThreeJS_PathTracing_Renderer_BVH_Debugging.html)<br>

This Demo renders objects inside a volume of gas/dust/fog/clouds(etc.).  Notice the cool volumetric caustics from the glass sphere on the left!: <br>

* [Volumetric Rendering Demo](https://erichlof.github.io/THREE.js-PathTracing-Renderer/ThreeJS_PathTracing_Renderer_VolumetricRendering.html) <br>

This Demo deliberately creates a very hard scene to render because the light source is almost 100% blocked.  Normal naive path tracing will be very dark and noisy because the rays from the camera can't find the light source unless they are very lucky: <br>

* [Naive Path Tracing Hidden-Light comparison Demo](https://erichlof.github.io/THREE.js-PathTracing-Renderer/ThreeJS_PathTracing_Renderer_CompareUni-Directional.html) <br>

Enter Bi-Directional Path Tracing to the rescue!  Not only do we trace rays from the camera, we trace rays from the light source as well, and then at the last moment, connect them.  The result is still a little noisy, but much better (we can actually see something!)<br>

* [Bi-Directional Path Tracing Hidden-Light comparison Demo](https://erichlof.github.io/THREE.js-PathTracing-Renderer/ThreeJS_PathTracing_Renderer_Bi-Directional_PathTracer.html) <br>

Some pretty interesting shapes can be obtained by deforming objects and/or warping the ray space (position and direction).  This demo applies a twist warp to the spheres and mirror box and randomizes the object space of the top purple sphere, creating an acceptable representation of a cloud (for free - no extra processing time for volumetrics!)
* [Ray/Object Warping Demo](https://erichlof.github.io/THREE.js-PathTracing-Renderer/ThreeJS_PathTracing_Renderer_RayWarping.html)<br>

Taking this object warping idea further, I have been experimenting with rendering deformable surfaces such as liquids. Each ray (1 of millions) gets its own personalized map of where the deformable surface is located in 3D space, depending on where the ray hits the original non-deformed bounding box / bounding shape.  I am quite pleased with the initial results - pixel-accurate smooth surfaces, no cracks, seams or facets as you sometimes get with traditional triangulated patches/meshes.  And best of all, the total computation cost is 1 initial bounding shape and 1 deformed/displaced shape of the same type!  This can be executed on GPU in parallel, achieving real time realistic looking water movement at 60 FPS on desktop and 30 FPS on a smartphone!  Later I will experiment with rendering terrain such as hills and mountains, maybe borrowing some popular fractal fBm noise functions on sites like glslSandbox and ShaderToy.
* [Liquid Simulation Demo](https://erichlof.github.io/THREE.js-PathTracing-Renderer/ThreeJS_PathTracing_Renderer_Liquid_Simulation.html)<br>

<h2>Updates</h2>

* May 4th, 2017: I had a breakthrough with liquid/fluid rendering and simulation. Check out the new Water Rendering Demo!  These breakthroughs don't happen very often, especially for a hobbyist like me, but I was overjoyed at the realism and rendering speed of the new water simulation demo.  I first started out trying the more traditional bump-map/water-plane approach, but the illusion only works if you are at a good viewing angle - it quickly breaks down when you try to 'swim' in the liquid. I then started thinking 'outside the waterBox'(ha), and instead, I move the entire water box up and down for each ray, depending on where the ray strikes it. Each one of millions of rays gets its own personalized map of where the box is, depending on where the ray initially strikes the un-transformed box. The result is smooth, pixel-accurate, wavy water, with no facets or edges. Also you can swim underneath the surface, look upwards, and watch the above dry world bobble around with physically accurate refraction - give it a try! The wave motions are just simple sine wave functions that spit out Y values (wave-height) based on the X and Z coordinates as inputs.  If you wanted, you could easily use a displacement, bump, or noise texture to 'look up' the Y wave-height value depending on the X and Z coordinate of the ray-box intersection.  Next, I will explore rendering hills and mountains with the same technique, maybe with some fbm functions. I'll post something if it pans out!
* April 21st, 2017: Major rendering engine update across all demos - more FPS and more photo-realism!  Also I have a working BVH builder for triangle models!  Check out the 'BVH debugging' demo above. The BVH data structure has sped up triangle models greatly - I'm getting around 60 fps for low poly models under 1000 triangles! However, rendering them is another story: I've hit a wall with the current WebGL 1.0 shader language (GLSL):  It doesn't allow accessing an array with a variable, like you can easily do in other languages.  For example, vec3 myBoxesData[64];  int x = 13;  float correctNode = myBoxesData[x].  The statement with myBoxesData[x] fails under the current implementation of WebGL 1.0 (It must be a constant like '2' or something).  Hopefully this won't be an issue when Three.js moves over to WebGL 2.0, which does support dynamic indexing of arrays. But in the meantime, I'm trying to figure out a workaround. Also I've been experimenting on the side with rendering fluids like water, oil, milk, etc.  I'll post something as soon as I get it working! :)
* April 11th, 2017: 4 new CSG_Museum demos!  Constructive Solid Geometry(CSG) allows the creation of interesting, complex shapes by combining 2 basic 3D shapes (like Box and Sphere).  Operations include Plus (fuse the 2 shapes together into 1 shape), Minus (remove a negative chunk out of the first shape with the second shape), and Overlap (only render the volume where the two shapes overlap or intersect).  I'm pretty happy with how these operations turned out, although I'm reaching the compilation limit on my humble laptop integrated graphics card.  This is why the demos are split into 4 different showcases.  Trying to stuff ALL the artwork into one room was crashing my browser at shader-compilation time.  Interestingly enough, my Samsung S7 has no problem and achieves 30-60 fps.  Ray/Path tracers eat math shapes (Spheres, boxes, etc.) for breakfast which is why I went down this CSG path temporarily.  I'm still actively working on the BVH so we can start having regular triangular models at 30-60 fps. It's the most complicated piece thus far.  Soon! 
* March 3rd, 2017: Complete overhaul of mobile joystick controls.  Now the controls on Cell Phones and Tablets have a smooth, fluid response.  Also I changed the look of the buttons to directional, which makes more sense in this fly-cam setting.  However, I left the vintage joystick arcade-style circular buttons code intact, but commented out, so if you want a character jump-action button, etc., you can just mix and match the button shapes to your liking! :-) <br>

<h2>TODO</h2>

* Instead of scene description hard-coded in the path tracing shader, let the scene be defined using the Three.js library
* Debug BVH triangle rendering - figure out a way around dynamic array index ban in WebGL 1.0, or wait until 2.0
* Dynamic Scene description/BVH updating and streaming into the GPU path tracer via Data Texture. <br>

<h2>ABOUT</h2>

* This began as a port of Kevin Beason's brilliant 'smallPT' ("small PathTracer") over to the Three.js WebGL framework.  http://www.kevinbeason.com/smallpt/  Kevin's original 'smallPT' only supports spheres of various sizes and is meant to render offline, saving the image to a PPM text file (not real-time). I have so far added features such as real-time progressive rendering on any device with a Chrome browser, FirstPerson Camera controls with Depth of Field, more Ray-Primitive object intersection support (such as planes, triangles, and quadrics), and support for more materials like ClearCoat and SubSurface. <br>

This project is in the alpha stage.  More examples, features, and content to come...
