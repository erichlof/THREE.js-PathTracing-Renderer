# THREE.js-PathTracing-Renderer
Real-time PathTracing with global illumination and progressive rendering, all on top of the Three.js WebGL framework. <br>
Click for demo -> https://erichlof.github.io/THREE.js-PathTracing-Renderer/ThreeJS_PathTracing_Renderer.html
<h2>TODO</h2>
* I am in the process of porting Kevin Beason's smallPT ("small PathTracer") raytracing/pathtracing engine over to the Three.js WebGL framework. Users will be able to use easy, familiar commands from the Three.js library, but under-the-hood the Three.js Renderer will use the smallPT path tracing engine to render the final output to the screen.
* At first, only Sphere geometry will be supported, along with Sphere CSG (constructive solid geometry) techniques and non-uniform scaling of Spheres (if oblong spherical-shapes are desired for instance).
* Then I will implement ray-triangle and ray-box intersections so that other shapes like planes, cubes, pyramids, etc. will be supported.  And hopefully down-the-line, entire triangular models/meshes will be supported - for instance, loading a model in .obj format.

This experiment is in the early pre-alpha stage.  More examples, features, and content to come...
