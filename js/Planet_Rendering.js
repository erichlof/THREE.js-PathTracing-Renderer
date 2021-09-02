// scene/demo-specific variables go here
var sceneIsDynamic = true;
var earthRadius = 6360;
var atmosphereRadius = 6420;
var altitude = 2000.0;
var camFlightSpeed = 300;
var sunAngle = 5.1;
var sunDirection = new THREE.Vector3();
var cameraWithinAtmosphere = true;
var UniverseUp_Y_Vec = new THREE.Vector3(0,1,0);
//var UniverseToCam_Z_Vec = new THREE.Vector3(0,0,1);
var centerOfEarthToCameraVec = new THREE.Vector3();
var cameraDistFromCenterOfEarth = 0.0;
var amountToMoveCamera = 0.0;
var canUpdateCameraAtmosphereOrientation = true;
var canUpdateCameraSpaceOrientation = true;
var waterLevel = 0.0;
var cameraUnderWater = false;
var camPosToggle = false;
var timePauseToggle = false;


function toggleCameraPos() {

        camPosToggle = !camPosToggle;
        
        if (camPosToggle) {
                // camera on planet surface
                cameraControlsObject.position.set(-100, 0, earthRadius + 2.0); // in Km
                sunAngle = 0.5;
                canUpdateCameraAtmosphereOrientation = true;
                document.getElementById("cameraPosButton").innerHTML = "Teleport to Space";
        }	
        else {
                // camera in space
                cameraControlsObject.position.set(0, 0, earthRadius + 5000.0); // in Km
                sunAngle = 0.0;
                canUpdateCameraSpaceOrientation = true;
                document.getElementById("cameraPosButton").innerHTML = "Teleport to Surface";
        }

}

function toggleTimePause() {

        timePauseToggle = !timePauseToggle;

        if (timePauseToggle) {
                document.getElementById("timePauseButton").innerHTML = "Resume Time";
        }	
        else {
                document.getElementById("timePauseButton").innerHTML = "Pause Time";
        }

}

// called automatically from within initTHREEjs() function
function initSceneData() {
        
        // scene/demo-specific three.js objects setup goes here

        // pixelRatio is resolution - range: 0.5(half resolution) to 1.0(full resolution)
        pixelRatio = mouseControl ? 0.75 : 0.75; // less demanding on battery-powered mobile devices

        EPS_intersect = mouseControl ? 0.002 : 0.2; // less precision on mobile

        // set camera's field of view
        worldCamera.fov = 60;
        focusDistance = 10.0;

        // position and orient camera
        // camera starts in space
        cameraControlsObject.position.set(0, 0, earthRadius + 5000.0); // in Km
        cameraControlsYawObject.rotation.y = 0.0;
        cameraControlsPitchObject.rotation.x = 0.0;
        
        PerlinNoiseTexture = new THREE.TextureLoader().load( 'textures/perlin256.png' );
        PerlinNoiseTexture.wrapS = THREE.RepeatWrapping;
        PerlinNoiseTexture.wrapT = THREE.RepeatWrapping;
        PerlinNoiseTexture.flipY = false;
        PerlinNoiseTexture.minFilter = THREE.LinearFilter;
        PerlinNoiseTexture.magFilter = THREE.LinearFilter;
        PerlinNoiseTexture.generateMipmaps = false;

} // end function initSceneData()



// called automatically from within initTHREEjs() function
function initPathTracingShaders() {
 
        // scene/demo-specific uniforms go here	
        pathTracingUniforms.t_PerlinNoise = { type: "t", value: PerlinNoiseTexture };
	pathTracingUniforms.uCameraWithinAtmosphere = { type: "b1", value: cameraWithinAtmosphere };
	pathTracingUniforms.uSunAngle = { type: "f", value: 0.0 };
	pathTracingUniforms.uCameraUnderWater = { type: "f", value: 0.0 };
	pathTracingUniforms.uSunDirection = { type: "v3", value: new THREE.Vector3() };
	pathTracingUniforms.uCameraFrameRight = { type: "v3", value: new THREE.Vector3() };
	pathTracingUniforms.uCameraFrameForward = { type: "v3", value: new THREE.Vector3() };
	pathTracingUniforms.uCameraFrameUp = { type: "v3", value: new THREE.Vector3() };
        

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

        fileLoader.load('shaders/Planet_Rendering_Fragment.glsl', function (shaderText) {
                
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
        
        // scene/demo-specific variables

        // reset vectors that may have changed
        cameraControlsObject.updateMatrixWorld(true);
        controls.getDirection(cameraDirectionVector);
        cameraDirectionVector.normalize();

        centerOfEarthToCameraVec.copy(cameraControlsObject.position);
        cameraDistFromCenterOfEarth = centerOfEarthToCameraVec.length();
        centerOfEarthToCameraVec.normalize();

        altitude = Math.max(0.001, cameraDistFromCenterOfEarth - earthRadius);
        camFlightSpeed = Math.max(0.1, altitude * 0.3);
        camFlightSpeed = Math.min(camFlightSpeed, 500.0);

        // camera within atmosphere
        if (cameraDistFromCenterOfEarth < atmosphereRadius)
        {
                cameraWithinAtmosphere = true;
                canUpdateCameraSpaceOrientation = true;
                oldRotationY = cameraControlsYawObject.rotation.y;
                //oldRotationX = cameraControlsPitchObject.rotation.x;

                if (canUpdateCameraAtmosphereOrientation)
                {
                        cameraControlsObject.quaternion.setFromUnitVectors(UniverseUp_Y_Vec, centerOfEarthToCameraVec);
                        cameraControlsObject.updateMatrixWorld(true);
                        
                        cameraControlsObject.up.copy(centerOfEarthToCameraVec);
                        cameraControlsObject.rotateOnWorldAxis(cameraControlsObject.up, cameraControlsObject.rotation.y + oldRotationY);
                        cameraControlsPitchObject.rotation.x = 0;
                        cameraControlsObject.updateMatrixWorld(true);

                        pathTracingUniforms.uCameraFrameRight.value.set(
                                cameraControlsObject.matrixWorld.elements[0],
                                cameraControlsObject.matrixWorld.elements[1],
                                cameraControlsObject.matrixWorld.elements[2] );

                        pathTracingUniforms.uCameraFrameUp.value.set(
                                cameraControlsObject.matrixWorld.elements[4],
                                cameraControlsObject.matrixWorld.elements[5],
                                cameraControlsObject.matrixWorld.elements[6] );

                        pathTracingUniforms.uCameraFrameForward.value.set(
                                cameraControlsObject.matrixWorld.elements[8],
                                cameraControlsObject.matrixWorld.elements[9],
                                cameraControlsObject.matrixWorld.elements[10] );

                }

                canUpdateCameraAtmosphereOrientation = false;
        }
        else { // camera in space
                cameraWithinAtmosphere = false;
                canUpdateCameraAtmosphereOrientation = true;
                oldRotationY = cameraControlsYawObject.rotation.y;

                if (canUpdateCameraSpaceOrientation)
                {
                        //cameraControlsObject.quaternion.setFromUnitVectors(centerOfEarthToCameraVec, UniverseToCam_Z_Vec);
                        cameraControlsObject.rotation.set(0,0,0);
                        cameraControlsObject.up.set(0, 1, 0);
                        cameraControlsObject.updateMatrixWorld(true);
                
                        //cameraControlsObject.rotateOnWorldAxis(cameraControlsObject.up, cameraControlsObject.rotation.y + oldRotationY);
                        cameraControlsPitchObject.rotation.x = 0;
                        cameraControlsObject.updateMatrixWorld(true);

                        pathTracingUniforms.uCameraFrameRight.value.set(1, 0, 0);
                        pathTracingUniforms.uCameraFrameUp.value.set(0, 1, 0);
                        pathTracingUniforms.uCameraFrameForward.value.set(0, -1, 0);
                }
                canUpdateCameraSpaceOrientation = false;
                
        }

        if (cameraDistFromCenterOfEarth < (earthRadius + 0.001))
        {
                amountToMoveCamera = (earthRadius + 0.001) - cameraDistFromCenterOfEarth;
                cameraControlsObject.position.add(centerOfEarthToCameraVec.multiplyScalar(amountToMoveCamera));
        }

        if (altitude < 1.0) // in Km
                cameraUnderWater = 1.0;
        else cameraUnderWater = 0.0;
        
        if (!timePauseToggle)
                sunAngle += (0.05 * frameTime) % TWO_PI; // 0.05
        //sunAngle = 0;
        sunDirection.set(Math.cos(sunAngle), 0, Math.sin(sunAngle));
        sunDirection.normalize();

        pathTracingUniforms.uCameraUnderWater.value = cameraUnderWater;
        pathTracingUniforms.uSunAngle.value = sunAngle;
        pathTracingUniforms.uSunDirection.value.copy(sunDirection);
        pathTracingUniforms.uCameraWithinAtmosphere.value = cameraWithinAtmosphere;
        
        //INFO
                     // 1.0 Km
        if (altitude >= 1.0) { 
                cameraInfoElement.innerHTML = "Altitude: " + altitude.toFixed(1) + " Kilometers | " + (altitude * 0.621371).toFixed(1) + " Miles" +
                " (Water Level = 1 Km)" + "<br>" +
                "FOV: " + worldCamera.fov + " / Aperture: " + apertureSize.toFixed(2) + " / FocusDistance: " + focusDistance + "<br>" +
                "Samples: " + sampleCounter;
        }
        else {
                cameraInfoElement.innerHTML = "Altitude: " + Math.floor(1000 * altitude) + " meters | " + Math.floor(1000 * altitude * 3.28084) + " feet" + "<br>" +
                "FOV: " + worldCamera.fov + " / Aperture: " + apertureSize.toFixed(2) + " / FocusDistance: " + focusDistance + "<br>" +
                "Samples: " + sampleCounter;
        }

} // end function updateUniforms()



init(); // init app and start animating
