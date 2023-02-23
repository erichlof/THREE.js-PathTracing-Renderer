// scene/demo-specific variables go here
let earthRadius = 6360; // in Km
let atmosphereRadius = 6420; // in Km
let altitude = 2000; // in Km
let sunAngle = 5.1;
let sunDirection = new THREE.Vector3();
let cameraWithinAtmosphere = true;
let UniverseUp_Y_Vec = new THREE.Vector3(0,1,0);
let centerOfEarthToCameraVec = new THREE.Vector3();
let cameraDistFromCenterOfEarth = 0.0;
let amountToMoveCamera = 0.0;
let canUpdateCameraAtmosphereOrientation = true;
let canUpdateCameraSpaceOrientation = true;
let waterLevel = 0.0;
let cameraUnderWater = false;
let camPosToggle = false;
let timePauseToggle = false;

let cameraViewpoint_PositionController, cameraViewpoint_PositionObject;
let needChangeCameraViewpoint = false;
let timePaused_ToggleController, timePaused_ToggleObject;
let needChangeTimePausedToggle = false;
let PerlinNoiseTexture;


// called automatically from within initTHREEjs() function (located in InitCommon.js file)
function initSceneData() 
{
	
	demoFragmentShaderFileName = 'Planet_Rendering_Fragment.glsl';

	// scene/demo-specific three.js objects setup goes here
	sceneIsDynamic = true;
	
	cameraFlightSpeed = 300;

	// pixelRatio is resolution - range: 0.5(half resolution) to 1.0(full resolution)
	pixelRatio = mouseControl ? 0.7 : 0.7; // less demanding on battery-powered mobile devices

	EPS_intersect = 0.002;

	// set camera's field of view
	worldCamera.fov = 60;
	focusDistance = 10.0;
	apertureChangeSpeed = 0.005;

	// position and orient camera
	// camera starts in space
	cameraControlsObject.position.set(0, 0, earthRadius + 5000.0); // in Km
	cameraControlsYawObject.rotation.y = 0.0;
	cameraControlsPitchObject.rotation.x = 0.0;

	// In addition to the default GUI on all demos, add any special GUI elements that this particular demo requires
	
	cameraViewpoint_PositionObject = {
		'Teleport To Surface' : handleCameraViewpointPositionChange
	};

	timePaused_ToggleObject = {
		'Pause Time': handleTimePausedToggleChange
	};
	
	function handleCameraViewpointPositionChange()
	{
		needChangeCameraViewpoint = true;
	}

	function handleTimePausedToggleChange()
	{
		needChangeTimePausedToggle = true;
	}

	cameraViewpoint_PositionController = gui.add(cameraViewpoint_PositionObject, 'Teleport To Surface');
	timePaused_ToggleController = gui.add(timePaused_ToggleObject, 'Pause Time');
	
	

	// scene/demo-specific uniforms go here	
	pathTracingUniforms.t_PerlinNoise = { value: PerlinNoiseTexture };
	pathTracingUniforms.uCameraWithinAtmosphere = { value: cameraWithinAtmosphere };
	pathTracingUniforms.uSunAngle = { value: 0.0 };
	pathTracingUniforms.uCameraUnderWater = { value: 0.0 };
	pathTracingUniforms.uSunDirection = { value: new THREE.Vector3() };
	pathTracingUniforms.uCameraFrameRight = { value: new THREE.Vector3() };
	pathTracingUniforms.uCameraFrameForward = { value: new THREE.Vector3() };
	pathTracingUniforms.uCameraFrameUp = { value: new THREE.Vector3() };

	// debug: start demo on planet surface instead
	//handleCameraViewpointPositionChange();

} // end function initSceneData()




// called automatically from within the animate() function (located in InitCommon.js file)
function updateVariablesAndUniforms() 
{
	
	if (needChangeCameraViewpoint)
	{
		camPosToggle = !camPosToggle;

		if (camPosToggle) 
		{
			// move camera to planet surface
			cameraControlsObject.position.set(-100, 0, earthRadius + 2); // in Km
			sunAngle = 0.5;
			canUpdateCameraAtmosphereOrientation = true;
			cameraViewpoint_PositionController.name('Teleport to Space');
		}
		else 
		{
			// place camera in space
			cameraControlsObject.position.set(0, 0, earthRadius + 5000); // in Km
			sunAngle = 0.0;
			canUpdateCameraSpaceOrientation = true;
			cameraViewpoint_PositionController.name('Teleport to Surface');
		}

		needChangeCameraViewpoint = false;
	}

	if (needChangeTimePausedToggle)
	{
		timePauseToggle = !timePauseToggle;

		if (timePauseToggle)
		{
			timePaused_ToggleController.name('Resume Time');
		}
		else
		{
			timePaused_ToggleController.name('Pause Time');
		}

		needChangeTimePausedToggle = false;
	}


	// reset vectors that may have changed
	cameraControlsObject.updateMatrixWorld(true);
	controls.getDirection(cameraDirectionVector);
	cameraDirectionVector.normalize();

	centerOfEarthToCameraVec.copy(cameraControlsObject.position);
	cameraDistFromCenterOfEarth = centerOfEarthToCameraVec.length();
	centerOfEarthToCameraVec.normalize();

	altitude = Math.max(0.001, cameraDistFromCenterOfEarth - earthRadius);
	cameraFlightSpeed = Math.max(0.1, altitude * 0.3);
	cameraFlightSpeed = Math.min(cameraFlightSpeed, 500.0);

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
	else 
	{ // camera in space
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
	if (altitude >= 1.0) 
	{ 
		cameraInfoElement.innerHTML = "Altitude: " + altitude.toFixed(1) + " Kilometers | " + (altitude * 0.621371).toFixed(1) + " Miles" +
		" (Water Level = 1 Km)" + "<br>" +
		"FOV: " + worldCamera.fov + " / Aperture: " + apertureSize.toFixed(2) + " / FocusDistance: " + focusDistance + "<br>" +
		"Samples: " + sampleCounter;
	}
	else 
	{
		cameraInfoElement.innerHTML = "Altitude: " + Math.floor(1000 * altitude) + " meters | " + Math.floor(1000 * altitude * 3.28084) + " feet" + "<br>" +
		"FOV: " + worldCamera.fov + " / Aperture: " + apertureSize.toFixed(2) + " / FocusDistance: " + focusDistance + "<br>" +
		"Samples: " + sampleCounter;
	}

} // end function updateUniforms()



// load a resource
PerlinNoiseTexture = textureLoader.load(
	// resource URL
	'textures/perlin256.png',

	// onLoad callback
	function (texture)
	{
		texture.wrapS = THREE.RepeatWrapping;
		texture.wrapT = THREE.RepeatWrapping;
		texture.flipY = false;
		texture.minFilter = THREE.LinearFilter;
		texture.magFilter = THREE.LinearFilter;
		texture.generateMipmaps = false;

		// now that the texture has been loaded, we can init 
		init();
	}
);
