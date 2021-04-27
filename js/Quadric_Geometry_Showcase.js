// scene/demo-specific variables go here
var sceneIsDynamic = false;
var camFlightSpeed = 60;
var torusObject;

// called automatically from within initTHREEjs() function
function initSceneData() 
{
        //pixelRatio = 1; // for computers with the latest GPUs!
        
        // scene/demo-specific three.js objects setup goes here
        EPS_intersect = mouseControl ? 0.01 : 1.0; // less precision on mobile

        // Torus Object
        torusObject = new THREE.Object3D();
        pathTracingScene.add(torusObject);
        //torusObject.rotation.set(Math.PI * 0.5, 0, 0);
        torusObject.rotation.set(-0.05, 0, -0.05);
        torusObject.position.set(-60, 6, 50);

        // set camera's field of view
        worldCamera.fov = 60;
        focusDistance = 130.0;

        // position and orient camera
        cameraControlsObject.position.set(0, 20, 120);
        ///cameraControlsYawObject.rotation.y = 0.0;
        // look slightly downward
        ///cameraControlsPitchObject.rotation.x = -0.4;

} // end function initSceneData()



// called automatically from within initTHREEjs() function
function initPathTracingShaders() 
{
 
        // scene/demo-specific uniforms go here
        pathTracingUniforms.uTorusInvMatrix = { type: "m4", value: new THREE.Matrix4() };
        pathTracingUniforms.uColorEdgeSharpeningRate = { type: "f", value: 0.1 };
        pathTracingUniforms.uNormalEdgeSharpeningRate = { type: "f", value: 0.1 };
        pathTracingUniforms.uObjectEdgeSharpeningRate = { type: "f", value: 1.0 };

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

        fileLoader.load('shaders/Quadric_Geometry_Showcase_Fragment.glsl', function (shaderText) 
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
        // TORUS
        torusObject.updateMatrixWorld(true); // 'true' forces immediate matrix update
        pathTracingUniforms.uTorusInvMatrix.value.copy(torusObject.matrixWorld).invert();
        
        // INFO
        cameraInfoElement.innerHTML = "FOV: " + worldCamera.fov + " / Aperture: " + apertureSize.toFixed(2) + " / FocusDistance: " + focusDistance + "<br>" + "Samples: " + sampleCounter;

} // end function updateUniforms()



init(); // init app and start animating
