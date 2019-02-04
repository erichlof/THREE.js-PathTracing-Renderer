// scene/demo-specific variables go here
var clothTexture, darkWoodTexture, lightWoodTexture;
var increaseDoorAngle = false;
var decreaseDoorAngle = false;
var sceneIsDynamic = false;
var camFlightSpeed = 100;

// called automatically from within initTHREEjs() function
function initSceneData() {
        
        // scene/demo-specific three.js objects setup goes here

        // set camera's field of view
        worldCamera.fov = 60;

        // position and orient camera
        cameraControlsObject.position.set(100,50,140);
        // look left
        cameraControlsYawObject.rotation.y = 0.6;
        // look slightly downward
        cameraControlsPitchObject.rotation.x = -0.2;
        
        
        clothTexture = new THREE.TextureLoader().load( 'textures/cloth.jpg' );
        clothTexture.wrapS = THREE.RepeatWrapping;
        clothTexture.wrapT = THREE.RepeatWrapping;
        clothTexture.flipY = false;
        //clothTexture.minFilter = THREE.LinearMipMapLinearFilter; 
        //clothTexture.magFilter = THREE.LinearFilter;
        //clothTexture.generateMipmaps = false;
        
        darkWoodTexture = new THREE.TextureLoader().load( 'textures/darkWood.jpg' );
        darkWoodTexture.wrapS = THREE.RepeatWrapping;
        darkWoodTexture.wrapT = THREE.RepeatWrapping;
        darkWoodTexture.flipY = false;
        //darkWoodTexture.minFilter = THREE.LinearFilter; 
        //darkWoodTexture.magFilter = THREE.LinearFilter;
        //darkWoodTexture.generateMipmaps = false;
        
        lightWoodTexture = new THREE.TextureLoader().load( 'textures/lightWood.jpg' );
        lightWoodTexture.wrapS = THREE.RepeatWrapping;
        lightWoodTexture.wrapT = THREE.RepeatWrapping;
        lightWoodTexture.flipY = false;
        //lightWoodTexture.minFilter = THREE.LinearFilter; 
        //lightWoodTexture.magFilter = THREE.LinearFilter;
        //lightWoodTexture.generateMipmaps = false;

} // end function initSceneData()



// called automatically from within initTHREEjs() function
function initPathTracingShaders() {
 
        // scene/demo-specific uniforms go here
        pathTracingUniforms = {
					
                tPreviousTexture: { type: "t", value: screenTextureRenderTarget.texture },
                tClothTexture: { type: "t", value: clothTexture },
                tDarkWoodTexture: { type: "t", value: darkWoodTexture },
                tLightWoodTexture: { type: "t", value: lightWoodTexture },
                
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

        fileLoader.load('shaders/Billiard_Table_Fragment.glsl', function (shaderText) {
                
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
        pathTracingUniforms.uRandomVector.value = randomVector.set( Math.random(), Math.random(), Math.random() );
        
        // CAMERA
        cameraControlsObject.updateMatrixWorld(true);			
        pathTracingUniforms.uCameraMatrix.value.copy( worldCamera.matrixWorld );
        screenOutputMaterial.uniforms.uOneOverSampleCounter.value = 1.0 / sampleCounter;
        
        cameraInfoElement.innerHTML = "FOV: " + worldCamera.fov + " / Aperture: " + apertureSize.toFixed(2) + " / FocusDistance: " + focusDistance + "<br>" + "Samples: " + sampleCounter;
				
} // end function updateUniforms()



init(); // init app and start animating
