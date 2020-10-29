// scene/demo-specific variables go here
var EPS_intersect;
var sceneIsDynamic = false;
var camFlightSpeed = 300;
var gui;
var ableToEngagePointerLock = true;
var material_TypeObject, material_ColorObject;
var material_LTypeController, material_LColorController;
var material_RTypeController, material_RColorController;
var matType = 0;
var changeLeftSphereMaterialType = false;
var changeRightSphereMaterialType = false;
var changeLeftSphereMaterialColor = false;
var changeRightSphereMaterialColor = false;


function init_GUI() {

        material_TypeObject = {
                LSphereMaterial: 4,
                RSphereMaterial: 2
        };
        material_ColorObject = {
                LSphereColor: [255, 255, 255],
                RSphereColor: [255, 255, 255]
        };

        function leftMatTypeChanger() {
                changeLeftSphereMaterialType = true;
        }
        function rightMatTypeChanger() {
                changeRightSphereMaterialType = true;
        }
        function leftMatColorChanger() {
		changeLeftSphereMaterialColor = true;
        }
        function rightMatColorChanger() {
                changeRightSphereMaterialColor = true;
        }

        gui = new dat.GUI();
        
        material_LTypeController = gui.add( material_TypeObject, 'LSphereMaterial', 1, 7, 1 ).onChange( leftMatTypeChanger );
        material_RTypeController = gui.add( material_TypeObject, 'RSphereMaterial', 1, 7, 1 ).onChange( rightMatTypeChanger );
        material_LColorController = gui.addColor( material_ColorObject, 'LSphereColor' ).onChange( leftMatColorChanger );
        material_RColorController = gui.addColor( material_ColorObject, 'RSphereColor' ).onChange( rightMatColorChanger );

        leftMatTypeChanger();
        rightMatTypeChanger();
        leftMatColorChanger();
        rightMatColorChanger();

        gui.domElement.style.webkitUserSelect = "none";
        gui.domElement.style.MozUserSelect = "none";
        
        window.addEventListener('resize', onWindowResize, false);

        if ( 'ontouchstart' in window ) {
                mouseControl = false;
                // if on mobile device, unpause the app because there is no ESC key and no mouse capture to do
                isPaused = false;
		
                ableToEngagePointerLock = true;

                mobileJoystickControls = new MobileJoystickControls ({
                        //showJoystick: true
                });	
        }

        if (mouseControl) {

                window.addEventListener( 'wheel', onMouseWheel, false );

                window.addEventListener("click", function(event) {
                        event.preventDefault();	
                }, false);
                window.addEventListener("dblclick", function(event) {
                        event.preventDefault();	
                }, false);
                
                document.body.addEventListener("click", function(event) {
                        if (!ableToEngagePointerLock)
                                return;
                        this.requestPointerLock = this.requestPointerLock || this.mozRequestPointerLock;
                        this.requestPointerLock();
                }, false);


                var pointerlockChange = function ( event ) {
                        if ( document.pointerLockElement === document.body || 
                            document.mozPointerLockElement === document.body || document.webkitPointerLockElement === document.body ) {

                                isPaused = false;
                        } else {
                                isPaused = true;
                        }
                };

                // Hook pointer lock state change events
                document.addEventListener( 'pointerlockchange', pointerlockChange, false );
                document.addEventListener( 'mozpointerlockchange', pointerlockChange, false );
                document.addEventListener( 'webkitpointerlockchange', pointerlockChange, false );

        }

        if (mouseControl) {
                gui.domElement.addEventListener("mouseenter", function(event) {
                                ableToEngagePointerLock = false;	
                }, false);
                gui.domElement.addEventListener("mouseleave", function(event) {
                                ableToEngagePointerLock = true;
                }, false);
        }

        /*
        // Fullscreen API
        document.addEventListener("click", function() {
        	
        	if ( !document.fullscreenElement && !document.mozFullScreenElement && !document.webkitFullscreenElement ) {

        		if (document.documentElement.requestFullscreen) {
        			document.documentElement.requestFullscreen();
        			
        		} else if (document.documentElement.mozRequestFullScreen) {
        			document.documentElement.mozRequestFullScreen();
        		
        		} else if (document.documentElement.webkitRequestFullscreen) {
        			document.documentElement.webkitRequestFullscreen();
        		
        		}

        	}
        });
        */

        initTHREEjs(); // boilerplate: init necessary three.js items and scene/demo-specific objects

} // end function init_GUI()



// called automatically from within initTHREEjs() function
function initSceneData() {
        
        // scene/demo-specific three.js objects setup goes here
        EPS_intersect = mouseControl ? 0.01 : 1.0; // less precision on mobile

        // set camera's field of view
        worldCamera.fov = 50;
        focusDistance = 530.0;

        // position and orient camera
        cameraControlsObject.position.set(278, 170, 320);
        ///cameraControlsYawObject.rotation.y = 0.0;
        // look slightly upward
        cameraControlsPitchObject.rotation.x = 0.005;

} // end function initSceneData()



// called automatically from within initTHREEjs() function
function initPathTracingShaders() {
 
        // scene/demo-specific uniforms go here
        pathTracingUniforms = {

                tPreviousTexture: { type: "t", value: screenCopyRenderTarget.texture },
					
                uCameraIsMoving: { type: "b1", value: false },

                uEPS_intersect: { type: "f", value: EPS_intersect },
                uTime: { type: "f", value: 0.0 },
                uSampleCounter: { type: "f", value: 0.0 },
                uFrameCounter: { type: "f", value: 1.0 },
                uULen: { type: "f", value: 1.0 },
                uVLen: { type: "f", value: 1.0 },
                uApertureSize: { type: "f", value: 0.0 },
                uFocusDistance: { type: "f", value: focusDistance },
                uLeftSphereMaterialType: { type: "f", value: 0.0 },
                uRightSphereMaterialType: { type: "f", value: 0.0 },

                uLeftSphereColor: { type: "v3", value: new THREE.Color() },
                uRightSphereColor: { type: "v3", value: new THREE.Color() },
                
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

        fileLoader.load('shaders/Switching_Materials_Fragment.glsl', function (shaderText) {
                
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
        
        if (changeLeftSphereMaterialType) {
                                        
                matType = Math.floor(material_LTypeController.getValue());
                pathTracingUniforms.uLeftSphereMaterialType.value = matType;

                //if (matType == 0) { // LIGHT
                //        pathTracingUniforms.uLeftSphereColor.value.setRGB(0.0, 0.0, 0.0);
                //        pathTracingUniforms.uLeftSphereEmissive.value.setRGB(1.0, 0.0, 1.0);
                //}
                if (matType == 1) { // DIFF
                        pathTracingUniforms.uLeftSphereColor.value.setRGB(1.0, 1.0, 1.0);   
                }
                else if (matType == 2) { // REFR
                        pathTracingUniforms.uLeftSphereColor.value.setRGB(0.6, 1.0, 0.9); 
                }
                else if (matType == 3) { // SPEC
                        pathTracingUniforms.uLeftSphereColor.value.setRGB(1.000000, 0.765557, 0.336057); // Gold
                        // other metals
                        // Aluminum: (0.913183, 0.921494, 0.924524) / Copper: (0.955008, 0.637427, 0.538163) / Silver: (0.971519, 0.959915, 0.915324)   
                }
                else if (matType == 4) { // COAT
                        pathTracingUniforms.uLeftSphereColor.value.setRGB(1.0, 1.0, 1.0);   
                }
                else if (matType == 5) { // CARCOAT
                        pathTracingUniforms.uLeftSphereColor.value.setRGB(1.0, 0.001, 0.001);   
                }
                else if (matType == 6) { // TRANSLUCENT
                        pathTracingUniforms.uLeftSphereColor.value.setRGB(0.5, 0.9, 1.0);
                }
                else if (matType == 7) { // SPECSUB
                        pathTracingUniforms.uLeftSphereColor.value.setRGB(0.99, 0.99, 0.96);  
                }

		
		material_LColorController.setValue([ pathTracingUniforms.uLeftSphereColor.value.r * 255,
						     pathTracingUniforms.uLeftSphereColor.value.g * 255,
						     pathTracingUniforms.uLeftSphereColor.value.b * 255 ]);
		
                cameraIsMoving = true;
                changeLeftSphereMaterialType = false;
        }

        if (changeRightSphereMaterialType) {

                matType = Math.floor(material_RTypeController.getValue());
                pathTracingUniforms.uRightSphereMaterialType.value = matType;

                //if (matType == 0) { // LIGHT
                //        pathTracingUniforms.uRightSphereColor.value.setRGB(0.0, 0.0, 0.0);
                //        pathTracingUniforms.uRightSphereEmissive.value.setRGB(1.0, 0.0, 1.0);    
                //}
                if (matType == 1) { // DIFF
                        pathTracingUniforms.uRightSphereColor.value.setRGB(1.0, 1.0, 1.0);   
                }
                else if (matType == 2) { // REFR
                        pathTracingUniforms.uRightSphereColor.value.setRGB(1.0, 1.0, 1.0);
                }
                else if (matType == 3) { // SPEC
                        pathTracingUniforms.uRightSphereColor.value.setRGB(0.913183, 0.921494, 0.924524); // Aluminum
                        // other metals
                        // Gold: (1.000000, 0.765557, 0.336057) / Copper: (0.955008, 0.637427, 0.538163) / Silver: (0.971519, 0.959915, 0.915324)   
                }
                else if (matType == 4) { // COAT
                        pathTracingUniforms.uRightSphereColor.value.setRGB(1.0, 1.0, 0.0);   
                }
                else if (matType == 5) { // CARCOAT
                        pathTracingUniforms.uRightSphereColor.value.setRGB(0.2, 0.3, 0.6);
                }
                else if (matType == 6) { // TRANSLUCENT
                        pathTracingUniforms.uRightSphereColor.value.setRGB(1.0, 0.82, 0.8);
                }
                else if (matType == 7) { // SPECSUB
                        pathTracingUniforms.uRightSphereColor.value.setRGB(0.0, 0.99, 0.8); 
                }

		
                material_RColorController.setValue([ pathTracingUniforms.uRightSphereColor.value.r * 255,
                                                     pathTracingUniforms.uRightSphereColor.value.g * 255,
                                                     pathTracingUniforms.uRightSphereColor.value.b * 255 ]);
		
                cameraIsMoving = true;
                changeRightSphereMaterialType = false;
        }

        if (changeLeftSphereMaterialColor) {
		matType = Math.floor(material_LTypeController.getValue());

		
                pathTracingUniforms.uLeftSphereColor.value.setRGB( material_LColorController.getValue()[0] / 255, 
                                                                   material_LColorController.getValue()[1] / 255, 
                                                                   material_LColorController.getValue()[2] / 255 );
		
                cameraIsMoving = true;
                changeLeftSphereMaterialColor = false;
	}
	
	if (changeRightSphereMaterialColor) {
		matType = Math.floor(material_RTypeController.getValue());

                
                pathTracingUniforms.uRightSphereColor.value.setRGB( material_RColorController.getValue()[0] / 255, 
                                                                    material_RColorController.getValue()[1] / 255, 
                                                                    material_RColorController.getValue()[2] / 255 );
		

                cameraIsMoving = true;
                changeRightSphereMaterialColor = false;
        }

        // INFO
        cameraInfoElement.innerHTML = "FOV: " + worldCamera.fov + " / Aperture: " + apertureSize.toFixed(2) + " / FocusDistance: " + focusDistance + "<br>" + "Samples: " + sampleCounter;
				
} // end function updateVariablesAndUniforms()



init_GUI(); // init app and start animating
