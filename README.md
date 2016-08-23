# THREE.js-PathTracing-Renderer
Real-time PathTracing with global illumination and progressive rendering, all on top of the Three.js WebGL framework. <br>

Click for demo -> https://erichlof.github.io/THREE.js-PathTracing-Renderer/ThreeJS_PathTracing_Renderer.html

<h2>FEATURES</h2>
* Real-time realistic Path tracing in your browser - even on your smartphone!
* First-Person camera navigation through the 3D scene
* When camera is still, switches to HQ progressive rendering mode
* If your device (most desktops / laptops) supports FLOAT texture buffers, the render accumulation will converge at around 15,000 samples.  If your device does not support FLOAT textures (most 2016 smartphones / tablets unfortunately still), it will default to a U-Byte texture and will still produce a nice image, but won't be as physically accurate as the HQ desktop/laptop rendering.
* Supports most primitives: Spheres, Planes, Discs, Quads, and Triangles (Other quadrics such as Cylinder, Cone, Ellipse, possibly even surfaces and NURBS, coming soon)
* Any supported shape can be an Area Light!
* Both Reflections (mirror) and Refractions (glass, water) are supported.
* Diffuse/Matte objects use Monte Carlo integration (a random process, hence the visual noise) to sample the unit-hemisphere oriented around the normal of the ray-object hitpoint and collects any light that is being received.  This is the key-difference between path tracing and simple old-fashioned ray tracing.  This is what produces realistic global illumination effects such as color bleeding/sharing between diffuse objects.
* Camera has Depth of Field with real-time adjustable Focal Distance and Aperture Size settings for a still-photography or cinematic look.
* SuperSampling gives beautiful, clean Anti-Aliasing (no jagged edges!)
* Users will be able to use easy, familiar commands from the Three.js library, but under-the-hood the Three.js Renderer will use the path tracing engine to render the final output to the screen.


<h2>TODO</h2>
* Instead of scene description in the path tracing shader code, let the scene be defined using the Three.js library
* Add more primitives support: Ray-Box, Ray-Cylinder, Ray-Cone, Ray-Ellipse, (Ray-3DBezierSurface?)
* Implement ray-BoundingBox intersections for object culling.
* hopefully, entire triangular models/meshes will soon be supported - for instance, loading and rendering a model in .obj format.
* Scene description/BVH streaming into the GPU path tracer via Data Texture?


<h2>ABOUT</h2>
* This is a port of Kevin Beason's smallPT ("small PathTracer") raytracing/pathtracing engine over to the Three.js WebGL framework.  I have added features such as real-time progressive rendering, camera Depth of Field, and more Ray-Primitive object support. Kevin's original smallPT only supports spheres of various sizes and is meant to render offline (not real-time).

This experiment is in the early pre-alpha stage.  More examples, features, and content to come...
