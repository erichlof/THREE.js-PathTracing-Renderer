// scene/demo-specific variables go here
var EPS_intersect;
var sceneIsDynamic = true;
var camFlightSpeed = 60;
var tileNormalMapTexture;

// called automatically from within initTHREEjs() function
function initSceneData() {
        
        // scene/demo-specific three.js objects setup goes here
        
        // desktop needs 0.1 precision instead of 0.01 to avoid artifacts on yellow sphere
        EPS_intersect = mouseControl ? 0.1 : 1.0; // less precision on mobile

        // set camera's field of view
        worldCamera.fov = 56;
        focusDistance = 119.0;
        
        // position and orient camera
        cameraControlsObject.position.set(-10, 88, 195);
        // look slightly downward
        cameraControlsPitchObject.rotation.x = -0.05;

        tileNormalMapTexture = new THREE.TextureLoader().load( 'textures/tileNormalMap.png' );
        tileNormalMapTexture.wrapS = THREE.RepeatWrapping;
        tileNormalMapTexture.wrapT = THREE.RepeatWrapping;
        tileNormalMapTexture.flipY = true;
        tileNormalMapTexture.minFilter = THREE.LinearFilter; 
        tileNormalMapTexture.magFilter = THREE.LinearFilter;
        tileNormalMapTexture.generateMipmaps = false;

} // end function initSceneData()



// called automatically from within initTHREEjs() function
function initPathTracingShaders() {
 
        // scene/demo-specific uniforms go here
        pathTracingUniforms = {

                tPreviousTexture: { type: "t", value: screenCopyRenderTarget.texture },
                tTileNormalMapTexture: { type: "t", value: tileNormalMapTexture },

                uCameraIsMoving: { type: "b1", value: false },
        
                uEPS_intersect: { type: "f", value: EPS_intersect },
                uTime: { type: "f", value: 0.0 },
                uSampleCounter: { type: "f", value: 0.0 },
                uFrameCounter: { type: "f", value: 1.0 },
                uULen: { type: "f", value: 1.0 },
                uVLen: { type: "f", value: 1.0 },
                uApertureSize: { type: "f", value: 0.0 },
                uFocusDistance: { type: "f", value: focusDistance },
        
                uResolution: { type: "v2", value: new THREE.Vector2() },
        
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

        fileLoader.load('shaders/Whitted_TheCompleatAngler_Fragment.glsl', function (shaderText) {
                
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
        
        // INFO
        cameraInfoElement.innerHTML = "FOV: " + worldCamera.fov + " / Aperture: " + apertureSize.toFixed(2) + " / FocusDistance: " + focusDistance + "<br>" + "Samples: " + sampleCounter;

} // end function updateUniforms()



init(); // init app and start animating
