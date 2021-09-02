// scene/demo-specific variables go here
var sceneIsDynamic = false;
var camFlightSpeed = 70;

// called automatically from within initTHREEjs() function
function initSceneData() 
{
        // scene/demo-specific three.js objects setup goes here

        // pixelRatio is resolution - range: 0.5(half resolution) to 1.0(full resolution)
        pixelRatio = mouseControl ? 0.75 : 0.75; // less demanding on battery-powered mobile devices

        EPS_intersect = mouseControl ? 0.1 : 1.0; // less precision on mobile

        // set camera's field of view
        worldCamera.fov = 60;
        focusDistance = 153.0;

        // position and orient camera
        cameraControlsObject.position.set(0, 20, 150);
        ///cameraControlsYawObject.rotation.y = 0.0;
        // look slightly downward
        ///cameraControlsPitchObject.rotation.x = -0.4;

} // end function initSceneData()



// called automatically from within initTHREEjs() function
function initPathTracingShaders() 
{
        // scene/demo-specific uniforms go here
        

        pathTracingDefines = {
                //NUMBER_OF_TRIANGLES: total_number_of_triangles
        };

        // load vertex and fragment shader files that are used in the pathTracing material, mesh and scene
        fileLoader.load('shaders/common_PathTracing_Vertex.glsl', function (shaderText) 
        {
                pathTracingVertexShader = shaderText;

                createPathTracingMaterial();
        });

} // end function initPathTracingShaders()


// called automatically from within initPathTracingShaders() function above
function createPathTracingMaterial() 
{

        fileLoader.load('shaders/CSG_Museum_4_Fragment.glsl', function (shaderText) 
        {

                pathTracingFragmentShader = shaderText;

                pathTracingMaterial = new THREE.ShaderMaterial({
                        uniforms: pathTracingUniforms,
                        defines: pathTracingDefines,
                        vertexShader: pathTracingVertexShader,
                        fragmentShader: pathTracingFragmentShader,
                        depthTest: false,
                        depthWrite: false
                });

                pathTracingMesh = new THREE.Mesh(pathTracingGeometry, pathTracingMaterial);
                pathTracingScene.add(pathTracingMesh);

                // the following keeps the large scene ShaderMaterial quad right in front 
                //   of the camera at all times. This is necessary because without it, the scene 
                //   quad will fall out of view and get clipped when the camera rotates past 180 degrees.
                worldCamera.add(pathTracingMesh);

        });

} // end function createPathTracingMaterial()



// called automatically from within the animate() function
function updateVariablesAndUniforms() 
{
        // clamp camera height for walking on Museum floor
        cameraControlsObject.position.y = 20;

        // INFO
        cameraInfoElement.innerHTML = "FOV: " + worldCamera.fov + " / Aperture: " + apertureSize.toFixed(2) + " / FocusDistance: " + focusDistance + "<br>" + "Samples: " + sampleCounter;

} // end function updateUniforms()



init(); // init app and start animating
