# THREE.js-PathTracing-Renderer
Real-time PathTracing with global illumination and progressive rendering, all on top of the Three.js WebGL framework.

<h2>LIVE DEMOS</h2>

* [Geometry Showcase Demo](https://erichlof.github.io/THREE.js-PathTracing-Renderer/Geometry_Showcase.html) demonstrating some primitive shapes for ray tracing.

* [Billiard Table Demo](https://erichlof.github.io/THREE.js-PathTracing-Renderer/Billiard_Table.html) shows support for image textures (i.e. .jpg .png) being loaded and used for materials (the billiard table cloth and two types of wood texture images are demonstrated).

* [Terrain Demo](https://erichlof.github.io/THREE.js-PathTracing-Renderer/Terrain_Rendering.html) combines traditional raytracing with raymarching to render stunning outdoor environments in real time!  Land is procedurally generated, can be altered with simple parameters. Total number of triangles processed for these worlds: 2! (for screen size quad) :-)

* [Planet Demo (W.I.P.)](https://erichlof.github.io/THREE.js-PathTracing-Renderer/Planet_Rendering.html) takes raymarching and raytracing to the extreme and renders an entire Earth-like planet with physically-based atmosphere!  Still a work in progress, the terrain is procedurely generated.  Although the mountains/lakes are too repetitious (W.I.P.), this simulation demonstrates the power of path tracing: you can hover above the planet at high orbit (5000 Km altitude), then drop all the way down and land your camera right on top of a single rock or single lake water wave (1 meter). All planet/atmosphere measurements are to scale.  The level of detail possible with raytracing is extraordinary! (note: demo is for Desktop only - Mobile lacks the precision to explore the terrain correctly)

* [Cornell Box Demo](https://erichlof.github.io/THREE.js-PathTracing-Renderer/CornellBox_DirectLighting.html) which renders the famous Cornell Box, but at ~60 fps!

For comparison, here is a real photograph of the original Cornell Box vs. a rendering with the three.js PathTracer:

![](readme-Images/measured.jpg) ![](readme-Images/CornellBox-Render0.png)

<br>

* [Multi-Method PathTracing Demo](https://erichlof.github.io/THREE.js-PathTracing-Renderer/MultiMethod_PathTracing.html) This is a new real-time path tracing method of my own.  It combines 3 different rendering approaches in the same frame (regular camera-path tracing with direct lighting (as above), light-path tracing to assist the darker areas in shadows (see bi-directional section below), and my own caustics-path tracing algorithm to help mirror/glass caustics converge much faster).  I'm pleased with the results - this is the fastest-converging Cornell Box scene with mirror specular caustics that I've seen anywhere.  And it's all done with Webgl and the browser! (try it on your phone/tablet!)  ;-)

* [Volumetric Rendering Demo](https://erichlof.github.io/THREE.js-PathTracing-Renderer/Volumetric_Rendering.html) renders objects inside a volume of dust/fog/etc..  Notice the cool volumetric caustics from the glass sphere on the left, rendered almost instantly!

* [Ocean and Sky Demo](https://erichlof.github.io/THREE.js-PathTracing-Renderer/Ocean_and_Sky_Rendering.html) which models an enormous calm ocean underneath a realistic physical sky. Now has more photo-realistic procedural clouds!

* [Water Rendering Demo](https://erichlof.github.io/THREE.js-PathTracing-Renderer/Water_Rendering.html) Renders photo-realistic water and simulates waves at 60 FPS. No triangle meshes are needed, as opposed to other traditional engines/renderers. In fact, not a single triangle was harmed during the making of this water volume! It is done through object/ray warping. Total cost: 1 ray-box intersection test!

* [Quadric Geometry Demo](https://erichlof.github.io/THREE.js-PathTracing-Renderer/Quadric_Geometry_Showcase.html) showing different quadric (mathematical) shapes (Warning: this may take 7-10 seconds to load/compile!)

<h3>Constructive Solid Geometry(CSG) Museum Demos</h3>

The following demos showcase different techniques in Constructive Solid Geometry - taking one 3D shape and either adding, removing, or overlapping a second shape. (Warning: these demos may take 10 seconds to load/compile!) <br>
All 4 demos feature a large dark glass sculpture in the center of the room, which shows Ellipsoid vs. Sphere CSG. <br>
Along the back wall, a study in Box vs. Sphere CSG: [CSG_Museum Demo #1](https://erichlof.github.io/THREE.js-PathTracing-Renderer/CSG_Museum_1.html) <br>
Along the right wall, a glass-encased monolith, and a study in Sphere vs. Cylinder CSG: [CSG_Museum Demo #2](https://erichlof.github.io/THREE.js-PathTracing-Renderer/CSG_Museum_2.html) <br>
Along the wall behind the camera, a study in Ellipsoid vs. Sphere CSG: [CSG_Museum Demo #3](https://erichlof.github.io/THREE.js-PathTracing-Renderer/CSG_Museum_3.html) <br>
Along the left wall, a study in Box vs. Cone CSG: [CSG_Museum Demo #4](https://erichlof.github.io/THREE.js-PathTracing-Renderer/CSG_Museum_4.html) <br>

Important note! - There is a hidden Easter Egg in one of the 4 Museum demo rooms.  Happy hunting!

<h3>Materials Demos</h3>

These demos showcase different materials possibilities: <br>
[Materials Demo #1](https://erichlof.github.io/THREE.js-PathTracing-Renderer/Materials_Showcase_1.html) Refractive (glass/water) and Car clearCoat (colored metal with clear coat) materials <br>
[Materials Demo #2](https://erichlof.github.io/THREE.js-PathTracing-Renderer/Materials_Showcase_2.html) Diffuse (matte wall paint/chalk) and Specular (aluminum mirror) materials <br>
[Materials Demo #3](https://erichlof.github.io/THREE.js-PathTracing-Renderer/Materials_Showcase_3.html) ClearCoat (billiard ball, plastic, porcelain) and Translucent (skin/balloons,etc.) materials <br>
[Materials Demo #4](https://erichlof.github.io/THREE.js-PathTracing-Renderer/Materials_Showcase_4.html) Metallic (Gold) and shiny SubSurface scattering (polished Jade/wax candles) materials <br> <br>

* <h4>Classic Scenes</h4>
In 1986 James T. Kajiya published his famous paper The Rendering Equation, in which he presented an elegant unifying integral equation that generalizes a variety of previously known rendering algorithms.  Since the equation is infinitely recursive and hopelessly multidimensional, he suggests using Monte Carlo integration (sampling and averaging) to converge on a solution.  Thus Monte Carlo path tracing was born, which this repo follows fairly closely.  At the end of his paper he included an image that demonstrates global illumination through path tracing:

![](readme-Images/kajiya.jpg)

And here is the same scene from 1986, rendered in real-time at 60 fps: <br>
* [The Rendering Equation Demo](https://erichlof.github.io/THREE.js-PathTracing-Renderer/Classic_Scene_Kajiya_TheRenderingEquation.html) <br>
<br>

* <h4>Bi-Directional Path Tracing</h4> Nearly 20 years ago (Dec 1997), Eric Veach wrote a seminal PhD thesis paper on methods for light transport http://graphics.stanford.edu/papers/veach_thesis/  In Chapter 10, entitled Bi-Directional Path Tracing, Veach outlines a novel way to deal with difficult path tracing scenarios with hidden light sources (i.e. cove lighting, recessed lighting, spotlights, window lighting on a cloudy day, etc.).  Instead of just shooting rays from the camera like we normally do, we also shoot rays from the light sources, and then join the camera paths to the light paths.  Although his full method is difficult to implement on GPUs because of memory storage requirements, I took the basic idea and applied it to real-time path tracing of his classic test scene with hidden light sources.  For reference, here is a rendering made by Veach for his 1997 paper:

![](readme-Images/Veach-BiDirectional.jpg)

And here is the same room rendered in real-time by the three.js path tracer: <br>
* [Bi-Directional PathTracing Demo](https://erichlof.github.io/THREE.js-PathTracing-Renderer/Bi-Directional_PathTracing_ClassicTestScene.html) <br>

The following classic scene rendering comes from later in the same paper by Veach.  This scene is intentionally difficult to converge because there is no direct light, only indirect light hitting the walls and ceiling from a crack in the doorway.  Further complicating things is the fact that caustics must be captured by the glass object on the coffee table, without being able to directly connect with the light source.

![](readme-Images/Veach-DifficultLighting.jpg)

And here is that scene rendered in real-time by the three.js path tracer: Try pressing 'E' and 'R' to open and close the door! <br>
* [Difficult Lighting Classic Test Scene Demo](https://erichlof.github.io/THREE.js-PathTracing-Renderer/Bi-Directional_DifficultLighting_ClassicTestScene.html) <br>

I had the above images only to go on - there are no scene dimensions specifications that I am aware of.  Since I don't have a working BVH acceleration structure just yet, I had to simplify the sculptures on the coffee table from Utah teapots to ellipsoids.  However, I feel that I have captured the essence and purpose of his test scene rooms.  I think Veach would be interested to know that his scenes, which probably took several minutes if not hours to render back in the 1990's, are now rendering real-time near 60 FPS on a web browser! :-D

For more intuition and a direct comparison between regular path tracing and bi-directional path tracing, here is the old Cornell Box scene but this time there is a blocker panel that blocks most of the light source in the ceiling.  The naive approach is just to hope that the camera rays will be lucky enough to find a light source:
* [Naive Approach to Blocked Light Source](https://erichlof.github.io/THREE.js-PathTracing-Renderer/Compare_Uni-Directional.html) As we can painfully see, we will have to wait a long time to get a decent image!
Enter Bi-Directional path tracing to the rescue!:
* [Bi-Directional Approach to Blocked Light Source](https://erichlof.github.io/THREE.js-PathTracing-Renderer/Compare_Bi-Directional_PathTracing.html) Like magic, the difficult scene comes into focus - in real-time! <br> <br> <br>

![](readme-Images/threejsPathTracing.png)


<h2>FEATURES</h2>

* Real-time interactive Path Tracing in your Chrome browser - even on your smartphone! ( What?! )
* First-Person camera navigation through the 3D scene.
* When camera is still, switches to progressive rendering mode and converges on a photo-realistic result!
* The accumulated render image will converge at around 1,000-2,000 samples (lower for simple scenes, higher for complex scenes).
* Direct lighting now makes images render/converge almost instantly!
* Both Uni-Directional (normal) and Bi-Directional path tracing approaches available for different lighting situations.
* Support for: Spheres, Planes, Discs, Quads, Triangles, and quadrics such as Cylinders, Cones, Ellipsoids, Paraboloids, Hyperboloids, Capsules, and Rings/Torii. Parametric/procedural surfaces (i.e. terrain, clouds, waves, etc.) are handled through Raymarching.
* Constructive Solid Geometry(CSG) allows you to combine 2 shapes using operations like addition, subtraction, and overlap.
* Basic support for loading models in .obj format (triangle and quad faces are supported, but no higher-order polys like pentagon, hexagon, etc.)
* Current material options: Metallic (mirrors, gold, etc.), Refractive (glass, water, etc.), Diffuse(matte, chalk, etc), ClearCoat(cars, plastic, billiard balls, etc.), Translucent (skin, leaves, cloth, etc.), Subsurface w/ shiny coat (jelly beans, cherries, teeth, polished Jade, etc.)
* Materials can now use Texture images which can be loaded, applied, and manipulated in the path tracer       
* Diffuse/Matte objects use Monte Carlo integration (a random process, hence the visual noise) to sample the unit-hemisphere oriented around the normal of the ray-object hitpoint and collects any light that is being received.  This is the key-difference between path tracing and simple old-fashioned ray tracing.  This is what produces realistic global illumination effects such as color bleeding/sharing between diffuse objects and refractive caustics from specular/glass/water objects.
* Camera has Depth of Field with real-time adjustable Focal Distance and Aperture Size settings for a still-photography or cinematic look.
* SuperSampling gives beautiful, clean Anti-Aliasing (no jagged edges!)
* Users will be able to use easy, familiar commands from the Three.js library, but under-the-hood the Three.js Renderer will use this path tracing engine to render the final output to the screen.

<h3>Experimental Works in Progress (W.I.P.)</h3>

The following demos show what I have been experimenting with most recently.  They might not work 100% and might have small visual artifacts that I am trying to fix.  I just wanted to share some more possible areas in the world of path tracing! :-) <br>

Rendering spheres, boxes and mathematical shapes is nice, but most modern graphics models are built out of triangles.  The following demo uses an .obj loader to load a model in .obj format (list of triangles) from disk and then places it in a scene to be path traced.  
I successfully added workarounds for the WebGL 1.0 limitation of no dynamic array indexing (such as correctBranch[x] and stackLevel[x] ) where 'x' is a dynamic variable that is necessary for BVH tree traversal through the various levels and branches.  Although it appears to be working under WebGL 1.0 as of now, when a larger model of 900 or more triangles is loaded, it crashes my browser page (loses the WebGL context).  I am still trying to determine the cause - I have a couple of possible suspects to investigate in the near future.  But lower-poly count models render at 60fps, and 30fps on my smartphone! <br>

* [BVH WebGL 1.0 Demo](https://erichlof.github.io/THREE.js-PathTracing-Renderer/BVH_WebGL_1.html)<br>

Some pretty interesting shapes can be obtained by deforming objects and/or warping the ray space (position and direction).  This demo applies a twist warp to the spheres and mirror box and randomizes the object space of the top purple sphere, creating an acceptable representation of a cloud (for free - no extra processing time for volumetrics!) <br>

* [Ray/Object Warping Demo](https://erichlof.github.io/THREE.js-PathTracing-Renderer/Ray_Warping.html)<br>


<h2>Updates</h2>

* June 1st, 2018: New Planet rendering demo!  For the last month I have been working on implementing a planet / atmosphere rendering engine.  First I started with an atmospheric model.  The one described in the wonderful website [ScratchAPixel](https://www.scratchapixel.com/lessons/procedural-generation-virtual-worlds/simulating-sky) was very helpful in getting the project going.  I had to convert his non-realtime C++ code to WebGL and make some necessary changes regarding machine precision.  But once I got it working, it was beautiful to behold!  You can fly like the (now-retired) NASA space shuttle through the atmosphere while the sun is rising/setting and you get the same colors that astronauts would see!  I decided to take this program a step further and let the user be able to land on the planet.  I found out this is much easier said than done.  Getting past the precision issues (5000+ Kilometers to 1 meter), I had to wrestle with my old friends, the quaternions, to get the camera stable and flat relative to the Earth surface whenever you enter the atmosphere from any angle.  This took 2 weeks of trial and error, and only ended up being 4 or 5 lines of code, ha ha.  I also added rotation to the planet system, so as the world rotates, the sun, moon, and stars seem to rotate (like they seem to on Earth) and day/night cycles are produced.  The one big remaining bug is that the terrain is too repetetive.  Right now I just build up a fractal terrain like in the Terrain Demo, all over the surface. In the future I might look into starting with a large continent/ocean shape map, and then building appropriate terrain on top of those larger shapes. Regardless of that TODO, the shear rendering scale possible with ray tracing/marching is awesome.  Try hitting the Pause Time button and flying in low orbit through a sunset! ;-)
* May 4th, 2018: Overhaul of RayMarching techniques used on terrain, water, and clouds. I figured out a good way to get more detailed normals out of the fractal terrain generation algorithm.  Now the rock and snow materials have a more believable texture.  For the water (ocean on the Ocean demo and lakes on the Terrain demo), I employ a technique of my own devising that combines RayMarching and RayTracing on the same material.  For close distance and accurate 3D-form and detail, I use RayMarching.  RayMarching a heightmap gives you a true solid object that you can explore from all angles.  However, when the distance becomes great toward the horizon, it loses its value because the detail cannot be maintained without tanking the framerate.  So at a certain distance I switch to pure RayTracing an infinite plane (usually the ground plane) and where the view ray strikes the plane surface, I use whatever fractal function I had previously used with RayMarching to get the height (let's say a mountain very far away).  Then I use one ray (low cost) to accurately trace a box which I move into position at whatever the height function told me it should be at that exact location of the terrain. This works well when viewed from slightly above looking down at the object in question and at a good distance away.  Unlike RayMarching however, you cannot fly around it, it is a flatter illusion.  But the end result is a seamless transition between the high-detail expensive RayMarching up close and the infinite draw distance of a cheap RayTrace for unprecedented level of detail.  Check out the water in the Ocean demo and try flying up to the stratosphere on the Terrain Demo to see this in action!
* March 6th, 2018: I recently developed a new approach to real-time rendering of scenes containing caustics (bright spots on diffuse surfaces from specular reflections/refractions - i.e. mirrors, metal jewelry, glass objects, swimming pools, etc.).  I nicknamed it 'Multi-Method' path tracing - it uses 3 different methods to render the final image each frame.  It starts out with regular traditional camera-path tracing with Direct Lighting samples. However, not all areas can see the light source for the Direct Light contribution, and they remain in shadow and noisy.  So to assist these darker areas, I employ light-path tracing to get the light out and into these hidden areas of the scene.  Lastly I use a method of my own creation, caustic-path tracing to help along the diffuse areas that are brightened by specular reflections/refractions.  Typically these areas are the slowest to converge in any renderer, even for high-end software like Octane, Cycles, V-Ray, etc.. So to help these areas converge quickly, I store the hit point on a diffuse surface from the 1st loop (the regular camera-path tracing loop).  Then I use that hit point as a caustic ray starting point.  I pick a random point on the object(s) giving caustics, and trace for a bounce depth of 2. If the caustic-finding ray hits the specular surface on the first bounce, it continues with 1 more bounce in hopes of finding the light source.  If it does not find anything bright, no contribution is made to the final pixel color.  If it finds the light source, it brightens the pixel accordingly with diffuse cosine attenuation falloff. The result is caustics that resolve in a matter of seconds rather than minutes! This method is still in the experimentation stage, I have to see if it will work for multiple glass/metal caustic-giving objects in a scene. But the initial results are promising!
* February 21st, 2018: Added support for procedural landscapes through raymarching.  Traditional ray tracing works well for mathematical shapes such as spheres, cones, triangles, etc., but would be too slow or unsolvable for complex shapes such as mountain terrain, clouds, etc.. Therefore Raymarching through heightfields, through distance fields, and through 3d noise is usually employed to deal with these scenarios. Also known as 'sphere' tracing, the basic technique is: instead of firing a thin ray at the scene objects, we shoot out a sphere of conservative size only a little ways out, advancing in calculated steps so we don't miss any important details.  At each raymarch step, the distance is evaluated from the center of the sphere to the object in question.  In the case of terrain in an XZ plane (Y is height), the height of the test sphere location, its Y position, is compared with the height of the terrain, terrain Y, at that same X Z position of the sphere. If you have a texture heightmap for instance, you just use the sphere X and Z to look up the texture coordinates X,Y(sphere Z), read the value at that texture pixel, and make it the terrain Y value at that particular location. If the sphere is 'above' the terrain, keep going, this time moving forward the same distance from the last comparison.  If the sphere is 'beneath' the terrain, stop - you have located the surface. Sorry for the slowness of updates, but I had to wrestle with understanding this technique and making it run at 30 FPS, even on a cell phone.  I must have stopped and restarted the technique from scratch about 5 times and almost abandoned it at one point.  But I'm glad I stuck with it because the Terrain Demo results are beautiful and immersive! 
* November 27th, 2017: I recently added 2 classic scenes demos - a Difficult Lighting scene from Eric Veach's thesis, and The Rendering Equation scene from Kajiya's famous 1986 paper.  These classic scenes are a good fit for the three.js path tracer because they have relatively few objects and simple shapes, which we can render real time without a dedicated geometry acceleration structure (like a BVH, that is still a WIP).  Even though they are simple in their composition, they usually contain a special light transport problem that must be solved quickly and correctly.  With modern GPUs, we can now render in 16 milliseconds what used to take minutes, if not hours, back in the late 80's and early 90's.  I personally had a lot of fun recreating these scenes just from one old image - it gives me a sense of connection with our CG heroes of the past!  :)
* October 3rd, 2017: Major strides have been made in the Bi-Directional path tracing area.  Difficult scenes (due to hidden light sources) which used to take minutes if not hours to come into focus, are now running at 60 FPS and converging under a minute, sometimes within seconds! Check out the new Bi-Directional scene demos above. In Eric Veach's (co-inventor of the Bi-Directional method) original algorithm, he kept a stack of camera path data as well as light path data, then chose different combinations of those 2 paths, depending on the effeciency they had on desired visual effects of the particular scene at hand.  This is not well-suited for GPUs because of the memory stack requirements, so I simplified the full algorithm down to what I'm calling Quasi Bi-Directional path tracing.  Instead of keeping a stack of all the possible paths, I simply join the random camera path to the random light path at the end of the ray tracing loop.  It runs so fast that all the desired effects eventually come into focus, which makes it possible for real-time games in the future where the game character might be in a dimly lit room.  I might put my simplified real-time algorithm to the ultimate test and try to render this scene: https://erichlof.github.io/THREE.js-PathTracing-Renderer/readme-Images/Ref.png Eric Veach had to resort to his novel Metropolis Light Transport (MLT) to deal with this super-difficult lighting situation. Just for fun, I may want to see how my lowly quasi bi-directional method stacks up! ;-) 
* April 21st, 2017: Major rendering engine update across all demos - more FPS and more photo-realism!  Also I have a working BVH builder for triangle models!  Check out the 'BVH debugging' demo above. The BVH data structure has sped up triangle models greatly - I'm getting around 60 fps for low poly models under 1000 triangles! However, rendering them is another story: I've hit a wall with the current WebGL 1.0 shader language (GLSL):  It doesn't allow accessing an array with a variable, like you can easily do in other languages.  For example, vec3 myBoxesData[64];  int x = 13;  float correctNode = myBoxesData[x].  The statement with myBoxesData[x] fails under the current implementation of WebGL 1.0 (It must be a constant like '2' or something).  Hopefully this won't be an issue when Three.js moves over to WebGL 2.0, which does support dynamic indexing of arrays. But in the meantime, I'm trying to figure out a workaround. Also I've been experimenting on the side with rendering fluids like water, oil, milk, etc.  I'll post something as soon as I get it working! :)

<h2>TODO</h2>

* Add support for layered texture materials (diffuse, normal map, specular map, emissive map, etc.)
* Instead of scene description hard-coded in the path tracing shader, let the scene be defined using the Three.js library
* Debug BVH branching - figure out a way around dynamic array index ban in WebGL 1.0, or wait until 2.0 support in three.js
* Dynamic Scene description/BVH updating and streaming into the GPU path tracer via Data Texture. <br>

<h2>ABOUT</h2>

* This began as a port of Kevin Beason's brilliant 'smallPT' ("small PathTracer") over to the Three.js WebGL framework.  http://www.kevinbeason.com/smallpt/  Kevin's original 'smallPT' only supports spheres of various sizes and is meant to render offline, saving the image to a PPM text file (not real-time). I have so far added features such as real-time progressive rendering on any device with a Chrome browser, FirstPerson Camera controls with Depth of Field, more Ray-Primitive object intersection support (such as planes, triangles, and quadrics), and support for more materials like ClearCoat and SubSurface. <br>

This project is in the alpha stage.  More examples, features, and content to come...
