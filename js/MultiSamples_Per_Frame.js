// scene/demo-specific variables go here
let torusObject;

let samplesPerFrame_AmountController, samplesPerFrame_AmountObject;
let needChangeSamplesPerFrameAmount = false;
let cameraFlight_SpeedController, cameraFlight_SpeedObject;
let needChangeCameraFlightSpeed = false;
let cameraRotation_SpeedController, cameraRotation_SpeedObject;
let needChangeCameraRotationSpeed = false;


// called automatically from within initTHREEjs() function (located in InitCommon.js file)
function initSceneData()
{

	demoFragmentShaderFileName = 'MultiSamples_Per_Frame_Fragment.glsl';

	// scene/demo-specific settings and three.js objects setup goes here
	sceneIsDynamic = false;
	
	cameraFlightSpeed = 60;

	// pixelRatio is resolution - range: 0.5(half resolution) to 1.0(full resolution)
	pixelRatio = mouseControl ? 0.5 : 0.5;

	EPS_intersect = 0.01;

	// Torus Object
	torusObject = new THREE.Object3D();
	pathTracingScene.add(torusObject);

	torusObject.rotation.set((Math.PI * 0.5) - 0.05, -0.05, 0);
	torusObject.position.set(-60, 6, 50);
	torusObject.scale.set(11.5, 11.5, 11.5);

	// set camera's field of view
	worldCamera.fov = 60;
	focusDistance = 130.0;

	// position and orient camera
	cameraControlsObject.position.set(0, 20, 120);
	///cameraControlsYawObject.rotation.y = 0.0;
	// look slightly downward
	///cameraControlsPitchObject.rotation.x = -0.4;


	// In addition to the default GUI on all demos, add any special GUI elements that this particular demo requires
	samplesPerFrame_AmountObject = {
		samplesPerFrame: 4
	};

	cameraFlight_SpeedObject = {
		cameraFlightSpeed: 60
	};

	cameraRotation_SpeedObject = {
		cameraRotationSpeed: 1
	};

	function handleSamplesPerFrameAmountChange()
	{
		needChangeSamplesPerFrameAmount = true;
	}

	function handleCameraFlightSpeedChange()
	{
		needChangeCameraFlightSpeed = true;
	}

	function handleCameraRotationSpeedChange()
	{
		needChangeCameraRotationSpeed = true;
	}

	samplesPerFrame_AmountController = gui.add(samplesPerFrame_AmountObject, 'samplesPerFrame', 1, 100, 1).onChange(handleSamplesPerFrameAmountChange);
	cameraFlight_SpeedController = gui.add(cameraFlight_SpeedObject, 'cameraFlightSpeed', 1, 1000, 1).onChange(handleCameraFlightSpeedChange);
	cameraRotation_SpeedController = gui.add(cameraRotation_SpeedObject, 'cameraRotationSpeed', 0.0001, 2.0, 0.0001).onChange(handleCameraRotationSpeedChange);


	// scene/demo-specific uniforms go here
	pathTracingUniforms.uTorusInvMatrix = { value: new THREE.Matrix4() };
	pathTracingUniforms.uSamplesPerFrame = { value: 4 };

} // end function initSceneData()



// called automatically from within the animate() function (located in InitCommon.js file)
function updateVariablesAndUniforms()
{
	// if GUI has been used, update

	if (needChangeSamplesPerFrameAmount)
	{
		pathTracingUniforms.uSamplesPerFrame.value = samplesPerFrame_AmountController.getValue();
		cameraIsMoving = true;
		needChangeSamplesPerFrameAmount = false;
	}

	if (needChangeCameraFlightSpeed)
	{
		cameraFlightSpeed = cameraFlight_SpeedController.getValue();
		needChangeCameraFlightSpeed = false;
	}

	if (needChangeCameraRotationSpeed)
	{
		cameraRotationSpeed = cameraRotation_SpeedController.getValue();
		needChangeCameraRotationSpeed = false;
	}


	// TORUS
	torusObject.updateMatrixWorld(true); // 'true' forces immediate matrix update
	pathTracingUniforms.uTorusInvMatrix.value.copy(torusObject.matrixWorld).invert();

	// INFO
	cameraInfoElement.innerHTML = "FOV: " + worldCamera.fov + " / Aperture: " + apertureSize.toFixed(2) + " / FocusDistance: " + focusDistance + "<br>" + "Samples: " + sampleCounter;

} // end function updateVariablesAndUniforms()



init(); // init app and start animating
