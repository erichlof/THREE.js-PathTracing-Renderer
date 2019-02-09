// scene/demo-specific variables go here
var tallBoxGeometry, tallBoxMaterial, tallBoxMesh;
var paintingTexture, darkWoodTexture, lightWoodTexture, marbleTexture;
var increaseDoorAngle = false;
var decreaseDoorAngle = false;
var sceneIsDynamic = false;
var camFlightSpeed = 200;

// called automatically from within initTHREEjs() function
function initSceneData() {
        
        // scene/demo-specific three.js objects setup goes here

        // set camera's field of view
        worldCamera.fov = 50;

        // position and orient camera
        cameraControlsObject.position.set(10, -10, 40);
	// look slightly to the right
        cameraControlsYawObject.rotation.y = -0.2;

        // Door (Tall Box mesh)
        tallBoxGeometry = new THREE.BoxGeometry(1,1,1);
        tallBoxMaterial = new THREE.MeshPhysicalMaterial( {
                color: new THREE.Color(0.95, 0.95, 0.95), //RGB, ranging from 0.0 - 1.0
                roughness: 1.0 // ideal Diffuse material	
        } );
        
        tallBoxMesh = new THREE.Object3D();//new THREE.Mesh(tallBoxGeometry, tallBoxMaterial);
        pathTracingScene.add(tallBoxMesh);
        //tallBoxMesh.visible = false; // disable normal Three.js rendering updates of this object: 
        // it is just a data placeholder as well as an Object3D that can be transformed/manipulated by 
        // using familiar Three.js library commands. It is then fed into the GPU path tracing renderer
        // through its 'matrixWorld' matrix. See below:
        tallBoxMesh.rotation.set(0, Math.PI * 2.0 - 0.4, 0);
        tallBoxMesh.position.set(179, -5, -298);
        tallBoxMesh.updateMatrixWorld(true); // 'true' forces immediate matrix update
        
        
        paintingTexture = new THREE.TextureLoader().load( 'textures/painting.jpg' );
        paintingTexture.wrapS = THREE.RepeatWrapping;
        paintingTexture.wrapT = THREE.RepeatWrapping;
        //paintingTexture.flipY = false;
        paintingTexture.minFilter = THREE.LinearFilter; 
        paintingTexture.magFilter = THREE.LinearFilter;
        paintingTexture.generateMipmaps = false;
        
        darkWoodTexture = new THREE.TextureLoader().load( 'textures/darkWood.jpg' );
        darkWoodTexture.wrapS = THREE.RepeatWrapping;
        darkWoodTexture.wrapT = THREE.RepeatWrapping;
        darkWoodTexture.flipY = false;
        darkWoodTexture.minFilter = THREE.LinearFilter; 
        darkWoodTexture.magFilter = THREE.LinearFilter;
        darkWoodTexture.generateMipmaps = false;
        
        lightWoodTexture = new THREE.TextureLoader().load( 'textures/tableWood.jpg' );
        lightWoodTexture.wrapS = THREE.RepeatWrapping;
        lightWoodTexture.wrapT = THREE.RepeatWrapping;
        lightWoodTexture.flipY = false;
        lightWoodTexture.minFilter = THREE.LinearFilter; 
        lightWoodTexture.magFilter = THREE.LinearFilter;
        lightWoodTexture.generateMipmaps = false;
        
        marbleTexture = new THREE.TextureLoader().load( 'textures/whiteMarble.jpg' );
        marbleTexture.wrapS = THREE.RepeatWrapping;
        marbleTexture.wrapT = THREE.RepeatWrapping;
        marbleTexture.flipY = false;
        marbleTexture.minFilter = THREE.LinearFilter; 
        marbleTexture.magFilter = THREE.LinearFilter;
        marbleTexture.generateMipmaps = false;

} // end function initSceneData()



// called automatically from within initTHREEjs() function
function initPathTracingShaders() {
 
        // scene/demo-specific uniforms go here
        pathTracingUniforms = {
					
                tPreviousTexture: { type: "t", value: screenTextureRenderTarget.texture },
                tPaintingTexture: { type: "t", value: paintingTexture },
                tDarkWoodTexture: { type: "t", value: darkWoodTexture },
                tLightWoodTexture: { type: "t", value: lightWoodTexture },
                tMarbleTexture: { type: "t", value: marbleTexture },
                
                uCameraIsMoving: { type: "b1", value: false },
                uCameraJustStartedMoving: { type: "b1", value: false },
                uTime: { type: "f", value: 0.0 },
                uSampleCounter: { type: "f", value: 0.0 },
                uFrameCounter: { type: "f", value: 1.0 },
                uULen: { type: "f", value: 1.0 },
                uVLen: { type: "f", value: 1.0 },
                uApertureSize: { type: "f", value: 0.0 },
                uFocusDistance: { type: "f", value: 230.0 },
                
                uResolution: { type: "v2", value: new THREE.Vector2() },
                
                uRandomVector: { type: "v3", value: new THREE.Vector3() },
        
                uCameraMatrix: { type: "m4", value: new THREE.Matrix4() },
                
                uTallBoxInvMatrix: { type: "m4", value: new THREE.Matrix4() },
                uTallBoxNormalMatrix: { type: "m3", value: new THREE.Matrix3() }

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

        fileLoader.load('shaders/Bi-Directional_Difficult_Lighting_Fragment.glsl', function (shaderText) {
                
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
        
        if ( keyboard.pressed('E') && !keyboard.pressed('R') ) {
					
                decreaseDoorAngle = true;
        }
        if ( keyboard.pressed('R') && !keyboard.pressed('E') ) {
                
                increaseDoorAngle = true;
        }

        if (decreaseDoorAngle) {
                tallBoxMesh.rotation.y -= 0.01;
                if (tallBoxMesh.rotation.y < Math.PI + 0.13)
                        tallBoxMesh.rotation.y = Math.PI + 0.13;

                cameraIsMoving = true;
                decreaseDoorAngle = false;
        }
        
        if (increaseDoorAngle) {
                
                tallBoxMesh.rotation.y += 0.01;
                if (tallBoxMesh.rotation.y > (Math.PI * 2.0))
                        tallBoxMesh.rotation.y = (Math.PI * 2.0);

                cameraIsMoving = true;
                increaseDoorAngle = false;
        }

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
        
        // DOOR
        tallBoxMesh.updateMatrixWorld(true); // 'true' forces immediate matrix update
        pathTracingUniforms.uTallBoxInvMatrix.value.getInverse( tallBoxMesh.matrixWorld );
        pathTracingUniforms.uTallBoxNormalMatrix.value.getNormalMatrix( tallBoxMesh.matrixWorld );
        
        // CAMERA
        cameraControlsObject.updateMatrixWorld(true);			
        pathTracingUniforms.uCameraMatrix.value.copy( worldCamera.matrixWorld );
        screenOutputMaterial.uniforms.uOneOverSampleCounter.value = 1.0 / sampleCounter;
        
        cameraInfoElement.innerHTML = "Press E and R to open and close door: " + "<br>" + "FOV: " + worldCamera.fov + " / Aperture: " + 
                apertureSize.toFixed(2) + " / FocusDistance: " + focusDistance + "<br>" + "Samples: " + sampleCounter;
				
} // end function updateUniforms()



init(); // init app and start animating
