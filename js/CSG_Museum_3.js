// scene/demo-specific variables go here
var EPS_intersect;
var sceneIsDynamic = false;
var camFlightSpeed = 70;

// called automatically from within initTHREEjs() function
function initSceneData() {
        
        // scene/demo-specific three.js objects setup goes here
        EPS_intersect = mouseControl ? 0.1 : 1.0; // less precision on mobile

        // set camera's field of view
        worldCamera.fov = 60;

        // position and orient camera
        cameraControlsObject.position.set(0,20,150);
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
        
                uEPS_intersect: { type: "f", value: EPS_intersect },
                uTime: { type: "f", value: 0.0 },
                uSampleCounter: { type: "f", value: 0.0 },
                uFrameCounter: { type: "f", value: 1.0 },
                uULen: { type: "f", value: 1.0 },
                uVLen: { type: "f", value: 1.0 },
                uApertureSize: { type: "f", value: 0.0 },
                uFocusDistance: { type: "f", value: 132.0 },
        
                uResolution: { type: "v2", value: new THREE.Vector2() },
        
                uRandomVector: { type: "v3", value: new THREE.Vector3() },
        
                uCameraMatrix: { type: "m4", value: new THREE.Matrix4() }
        
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

        fileLoader.load('shaders/CSG_Museum_3_Fragment.glsl', function (shaderText) {
                
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
function updateVariablesAndUniforms() {

        // clamp camera height for walking on Museum floor
	cameraControlsObject.position.y = 20;
        
        if (cameraIsMoving) {
                sampleCounter = 1.0;
                frameCounter += 1.0;

                if (!cameraRecentlyMoving) {
                        cameraJustStartedMoving = true;
                        cameraRecentlyMoving = true;
                }
        }

        if ( !cameraIsMoving ) {
                sampleCounter += 1.0; // for progressive refinement of image
                if (sceneIsDynamic)
                        sampleCounter = 1.0; // reset for continuous updating of image
                
                frameCounter  += 1.0;
                if (cameraRecentlyMoving)
                        frameCounter = 1.0;

                cameraRecentlyMoving = false;  
        }

        
        pathTracingUniforms.uCameraIsMoving.value = cameraIsMoving;
        pathTracingUniforms.uCameraJustStartedMoving.value = cameraJustStartedMoving;
        pathTracingUniforms.uSampleCounter.value = sampleCounter;
        pathTracingUniforms.uFrameCounter.value = frameCounter;
        pathTracingUniforms.uRandomVector.value = randomVector.set(Math.random(), Math.random(), Math.random());
        
        // CAMERA
        cameraControlsObject.updateMatrixWorld(true);
        pathTracingUniforms.uCameraMatrix.value.copy(worldCamera.matrixWorld);
        screenOutputMaterial.uniforms.uOneOverSampleCounter.value = 1.0 / sampleCounter;

        cameraInfoElement.innerHTML = "FOV: " + worldCamera.fov + " / Aperture: " + apertureSize.toFixed(2) + " / FocusDistance: " + focusDistance + "<br>" + "Samples: " + sampleCounter;

} // end function updateUniforms()



init(); // init app and start animating
