// scene/demo-specific three.js objects/variables setup goes here
var torusObject;
function initSceneData() {
        
        // Torus Object
        torusObject = new THREE.Object3D();
        pathTracingScene.add(torusObject);
        //torusObject.rotation.set(Math.PI * 0.5, 0, 0);
        torusObject.rotation.set(-0.05, 0, -0.05);
        torusObject.position.set(-60, 6, 50);

        // set camera's field of view
        worldCamera.fov = 60;

        // position and orient camera
        cameraControlsObject.position.set(0, 20, 120);
        ///cameraControlsYawObject.rotation.y = 0.0;
        // look slightly downward
        ///cameraControlsPitchObject.rotation.x = -0.4;

} // end function initSceneData()



// called automatically from within initTHREEjs() function
function initPathTracingShaders() {
 
        // scene/demo-specific uniforms go here
        pathTracingUniforms = {

                tPreviousTexture: { type: "t", value: screenTextureRenderTarget.texture },
                
                uCameraIsMoving: { type: "b1", value: false },
                uCameraJustStartedMoving: { type: "b1", value: false },
        
                uTime: { type: "f", value: 0.0 },
                uSampleCounter: { type: "f", value: 0.0 },
                uFrameCounter: { type: "f", value: 1.0 },
                uULen: { type: "f", value: 1.0 },
                uVLen: { type: "f", value: 1.0 },
                uApertureSize: { type: "f", value: 0.0 },
                uFocusDistance: { type: "f", value: 132.0 },
        
                uResolution: { type: "v2", value: new THREE.Vector2() },
        
                uRandomVector: { type: "v3", value: new THREE.Vector3() },
        
                uCameraMatrix: { type: "m4", value: new THREE.Matrix4() },
        
                uTorusInvMatrix: { type: "m4", value: new THREE.Matrix4() },
                uTorusNormalMatrix: { type: "m3", value: new THREE.Matrix3() }
        
        };

        pathTracingDefines = {
        	//NUMBER_OF_TRIANGLES: total_number_of_triangles
        };

        // load vertex and fragment shader files that are used in the pathTracing material, mesh and scene
        fileLoader.load('shaders/common_PathTracing_Vertex.glsl', function (shaderText) {
                pathTracingVertexShader = shaderText;

                createPathTracingMaterial();
        });

} // end function initPathTracingShaders()


// called automatically from within initPathTracingShaders() function above
function createPathTracingMaterial() {

        fileLoader.load('shaders/Geometry_Showcase_Fragment.glsl', function (shaderText) {
                
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
function updateUniforms() {
        
        pathTracingUniforms.uCameraIsMoving.value = cameraIsMoving;
        pathTracingUniforms.uCameraJustStartedMoving.value = cameraJustStartedMoving;
        pathTracingUniforms.uSampleCounter.value = sampleCounter;
        pathTracingUniforms.uFrameCounter.value = frameCounter;
        pathTracingUniforms.uRandomVector.value = randomVector.set(Math.random(), Math.random(), Math.random());
        // TORUS
        torusObject.updateMatrixWorld(true); // 'true' forces immediate matrix update
        pathTracingUniforms.uTorusInvMatrix.value.getInverse(torusObject.matrixWorld);
        pathTracingUniforms.uTorusNormalMatrix.value.getNormalMatrix(torusObject.matrixWorld);
        // CAMERA
        cameraControlsObject.updateMatrixWorld(true);
        pathTracingUniforms.uCameraMatrix.value.copy(worldCamera.matrixWorld);
        screenOutputMaterial.uniforms.uOneOverSampleCounter.value = 1.0 / sampleCounter;

} // end function updateUniforms()



initWindowAndControls(); // boilerplate: init handlers for window, mouse / mobile controls

initTHREEjs(); // boilerplate: init necessary three.js items

initSceneData(); // scene/demo-specific setup happens here

onWindowResize(); // this 'jumpstarts' the initial dimensions and parameters for the window and renderer

// everything is set up, now we can start animating
animate();