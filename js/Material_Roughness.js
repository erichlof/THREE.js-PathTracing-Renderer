// scene/demo-specific variables go here
var EPS_intersect;
var sceneIsDynamic = false;
var camFlightSpeed = 60;

var gui;
var ableToEngagePointerLock = true;
var material_TypeObject, material_ColorObject;
var material_TypeController, material_ColorController;
var changeMaterialType = false;
var changeMaterialColor = false;
var matType = 0;


function init_GUI() {

	material_TypeObject = {
                Material_Preset: 'ClearCoat Diffuse'
        };
        material_ColorObject = {
                Material_Color: [0, 255, 255]
        };
        
	function materialTypeChanger() {
                changeMaterialType = true;
        }
        function materialColorChanger() {
                changeMaterialColor = true;
        }
        gui = new dat.GUI();
        
        material_TypeController = gui.add( material_TypeObject, 'Material_Preset', [ 'ClearCoat Diffuse', 'Transparent Refractive', 
                'Copper Metal', 'Aluminum Metal', 'Gold Metal', 'Silver Metal', 'ClearCoat Metal(Brass)' ] ).onChange( materialTypeChanger );
        
        material_ColorController = gui.addColor( material_ColorObject, 'Material_Color' ).onChange( materialColorChanger );
        
	materialTypeChanger();
        materialColorChanger();

        gui.domElement.style.webkitUserSelect = "none";
        gui.domElement.style.MozUserSelect = "none";
        
        window.addEventListener('resize', onWindowResize, false);

        if ( 'ontouchstart' in window ) {
                mouseControl = false;
                // if on mobile device, unpause the app because there is no ESC key and no mouse capture to do
                isPaused = false;
                pixelRatio = 0.5;
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

        initTHREEjs(); // boilerplate: init necessary three.js items and scene/demo-specific objects

} // end function init_GUI()



// called automatically from within initTHREEjs() function
function initSceneData() {
        
        // scene/demo-specific three.js objects setup goes here
        EPS_intersect = mouseControl ? 0.01 : 1.0; // less precision on mobile

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
function initPathTracingShaders() {
 
        // scene/demo-specific uniforms go here
        pathTracingUniforms = {

                tPreviousTexture: { type: "t", value: screenCopyRenderTarget.texture },

                uCameraIsMoving: { type: "b1", value: false },
        
                uMaterialType: { type: "i", value: 4 },

                uEPS_intersect: { type: "f", value: EPS_intersect },
                uTime: { type: "f", value: 0.0 },
                uSampleCounter: { type: "f", value: 0.0 },
                uFrameCounter: { type: "f", value: 1.0 },
                uULen: { type: "f", value: 1.0 },
                uVLen: { type: "f", value: 1.0 },
                uApertureSize: { type: "f", value: 0.0 },
                uFocusDistance: { type: "f", value: focusDistance },

                uResolution: { type: "v2", value: new THREE.Vector2() },
        
                uMaterialColor: { type: "v3", value: new THREE.Color(0.0, 1.0, 1.0) },
        
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

        fileLoader.load('shaders/Material_Roughness_Fragment.glsl', function (shaderText) {
                
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

        if (changeMaterialType) {

                if (material_TypeController.getValue() == 'ClearCoat Diffuse') {
                        pathTracingUniforms.uMaterialType.value = 4;
                        pathTracingUniforms.uMaterialColor.value.setRGB(0.0, 1.0, 1.0);
                }
                else if (material_TypeController.getValue() == 'Transparent Refractive') {
                        pathTracingUniforms.uMaterialType.value = 2;
                        pathTracingUniforms.uMaterialColor.value.setRGB(0.1, 1.0, 0.6);
                }
                else if (material_TypeController.getValue() == 'Copper Metal') {
                        pathTracingUniforms.uMaterialType.value = 3;
                        pathTracingUniforms.uMaterialColor.value.setRGB(0.955008, 0.637427, 0.538163);
                }
                else if (material_TypeController.getValue() == 'Aluminum Metal') {
                        pathTracingUniforms.uMaterialType.value = 3;
                        pathTracingUniforms.uMaterialColor.value.setRGB(0.913183, 0.921494, 0.924524);
                }
                else if (material_TypeController.getValue() == 'Gold Metal') {
                        pathTracingUniforms.uMaterialType.value = 3;
                        pathTracingUniforms.uMaterialColor.value.setRGB(1.000000, 0.765557, 0.336057);
                }
                else if (material_TypeController.getValue() == 'Silver Metal') {
                        pathTracingUniforms.uMaterialType.value = 3;
                        pathTracingUniforms.uMaterialColor.value.setRGB(0.971519, 0.959915, 0.915324);
                }
                else if (material_TypeController.getValue() == 'ClearCoat Metal(Brass)') {
                        pathTracingUniforms.uMaterialType.value = 18;
                        pathTracingUniforms.uMaterialColor.value.setRGB(0.956863, 0.894118, 0.678431);
                }
                        
                
                material_ColorController.setValue([ pathTracingUniforms.uMaterialColor.value.r * 255,
                                                    pathTracingUniforms.uMaterialColor.value.g * 255,
                                                    pathTracingUniforms.uMaterialColor.value.b * 255 ]);
                
                cameraIsMoving = true;
                changeMaterialType = false;
        }

        if (changeMaterialColor) {
                pathTracingUniforms.uMaterialColor.value.setRGB( material_ColorController.getValue()[0] / 255, 
                                                                 material_ColorController.getValue()[1] / 255, 
                                                                 material_ColorController.getValue()[2] / 255 );
                
                cameraIsMoving = true;
                changeMaterialColor = false;
        }

        // INFO
        cameraInfoElement.innerHTML = "FOV: " + worldCamera.fov + " / Aperture: " + apertureSize.toFixed(2) + " / FocusDistance: " + focusDistance + "<br>" + "Samples: " + sampleCounter;

} // end function updateUniforms()



init_GUI(); // init app and start animating
