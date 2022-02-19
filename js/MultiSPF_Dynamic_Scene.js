// scene/demo-specific variables go here
let torusObject;
let torusRotationAngle = 0;

let gui;
let ableToEngagePointerLock = true;
let pixel_ResolutionController, pixel_ResolutionObject;
let needChangePixelResolution = false;
let samplesPerFrame_AmountController, samplesPerFrame_AmountObject;
let needChangeSamplesPerFrameAmount = false;
let previousFrameBlend_WeightController, previousFrameBlend_WeightObject;
let needChangePreviousFrameBlendWeight = false;
let cameraFlight_SpeedController, cameraFlight_SpeedObject;
let needChangeCameraFlightSpeed = false;
let cameraRotation_SpeedController, cameraRotation_SpeedObject;
let needChangeCameraRotationSpeed = false;


function init_GUI() 
{
	pixel_ResolutionObject = {
		pixel_Resolution: 0.5
	}

	samplesPerFrame_AmountObject = {
		samplesPerFrame: 4
	};

	previousFrameBlend_WeightObject = {
		previousFrameBlendWeight: 0.5
	};

	cameraFlight_SpeedObject = {
		cameraFlightSpeed: 60
	};

	cameraRotation_SpeedObject = {
		cameraRotationSpeed: 1
	};


	function handlePixelResolutionChange()
	{
		needChangePixelResolution = true;
	}

	function handleSamplesPerFrameAmountChange()
	{
		needChangeSamplesPerFrameAmount = true;
	}

	function handlePreviousFrameBlendWeightChange()
	{
		needChangePreviousFrameBlendWeight = true;
	}

	function handleCameraFlightSpeedChange()
	{
		needChangeCameraFlightSpeed = true;
	}

	function handleCameraRotationSpeedChange()
	{
		needChangeCameraRotationSpeed = true;
	}


	// since I use the lil-gui.min.js minified version of lil-gui without modern exports, 
	//'g()' is 'GUI()' ('g' is the shortened version of 'GUI' inside the lil-gui.min.js file)
	gui = new g(); // same as gui = new GUI();

	pixel_ResolutionController = gui.add(pixel_ResolutionObject, 'pixel_Resolution', 0.3, 1.0, 0.01).onChange(handlePixelResolutionChange);
	samplesPerFrame_AmountController = gui.add(samplesPerFrame_AmountObject, 'samplesPerFrame', 1, 20, 1).onChange(handleSamplesPerFrameAmountChange);
	previousFrameBlend_WeightController = gui.add(previousFrameBlend_WeightObject, 'previousFrameBlendWeight', 0.0, 1.0, 0.01).onChange(handlePreviousFrameBlendWeightChange);
	cameraFlight_SpeedController = gui.add(cameraFlight_SpeedObject, 'cameraFlightSpeed', 1, 1000, 1).onChange(handleCameraFlightSpeedChange);
	cameraRotation_SpeedController = gui.add(cameraRotation_SpeedObject, 'cameraRotationSpeed', 0.0001, 2.0, 0.0001).onChange(handleCameraRotationSpeedChange);


	gui.domElement.style.userSelect = "none";
	gui.domElement.style.MozUserSelect = "none";

	window.addEventListener('resize', onWindowResize, false);

	if ('ontouchstart' in window) 
	{
		mouseControl = false;
		// if on mobile device, unpause the app because there is no ESC key and no mouse capture to do
		isPaused = false;

		ableToEngagePointerLock = true;

		mobileJoystickControls = new MobileJoystickControls({
			//showJoystick: true
		});
	}

	if (mouseControl) 
	{

		window.addEventListener('wheel', onMouseWheel, false);

		// window.addEventListener("click", function(event) 
		// {
		// 	event.preventDefault();	
		// }, false);
		window.addEventListener("dblclick", function (event) 
		{
			event.preventDefault();
		}, false);

		document.body.addEventListener("click", function (event) 
		{
			if (!ableToEngagePointerLock)
				return;
			this.requestPointerLock = this.requestPointerLock || this.mozRequestPointerLock;
			this.requestPointerLock();
		}, false);


		pointerlockChange = function (event)
		{
			if (document.pointerLockElement === document.body ||
				document.mozPointerLockElement === document.body || document.webkitPointerLockElement === document.body)
			{
				document.addEventListener('keydown', onKeyDown, false);
				document.addEventListener('keyup', onKeyUp, false);
				isPaused = false;
			}
			else
			{
				document.removeEventListener('keydown', onKeyDown, false);
				document.removeEventListener('keyup', onKeyUp, false);
				isPaused = true;
			}
		};

		// Hook pointer lock state change events
		document.addEventListener('pointerlockchange', pointerlockChange, false);
		document.addEventListener('mozpointerlockchange', pointerlockChange, false);
		document.addEventListener('webkitpointerlockchange', pointerlockChange, false);

	}

	if (mouseControl) 
	{
		gui.domElement.addEventListener("mouseenter", function (event) 
		{
			ableToEngagePointerLock = false;
		}, false);
		gui.domElement.addEventListener("mouseleave", function (event) 
		{
			ableToEngagePointerLock = true;
		}, false);
	}


} // end function init_GUI()

init_GUI();


// called automatically from within initTHREEjs() function
function initSceneData()
{
	// scene/demo-specific three.js objects setup goes here
	sceneIsDynamic = true;
	cameraFlightSpeed = 60;

	// pixelRatio is resolution - range: 0.5(half resolution) to 1.0(full resolution)
	//pixelRatio = mouseControl ? 0.75 : 0.75; // less demanding on battery-powered mobile devices
	pixelRatio = 0.5;

	EPS_intersect = 0.01;

	// Torus Object
	torusObject = new THREE.Object3D();
	pathTracingScene.add(torusObject);
	//torusObject.rotation.set(Math.PI * 0.5, 0, 0);
	torusObject.position.set(-60, 18, 50);

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
function initPathTracingShaders()
{
	// scene/demo-specific uniforms go here
	pathTracingUniforms.uTorusInvMatrix = { type: "m4", value: new THREE.Matrix4() };
	pathTracingUniforms.uSamplesPerFrame = { type: "f", value: 4 };
	pathTracingUniforms.uPreviousFrameBlendWeight = { type: "f", value: 0.5 };

	pathTracingDefines = {
		//NUMBER_OF_TRIANGLES: total_number_of_triangles
	};

	// load vertex and fragment shader files that are used in the pathTracing material, mesh and scene
	fileLoader.load('shaders/common_PathTracing_Vertex.glsl', function (shaderText)
	{
		pathTracingVertexShader = shaderText;

		createPathTracingMaterial();
	});

} // end function initPathTracingShaders()


// called automatically from within initPathTracingShaders() function above
function createPathTracingMaterial()
{

	fileLoader.load('shaders/MultiSPF_Dynamic_Scene_Fragment.glsl', function (shaderText)
	{

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
function updateVariablesAndUniforms()
{
	// if GUI has been used, update

	if (needChangePixelResolution)
	{
		pixelRatio = pixel_ResolutionController.getValue();
		onWindowResize();
		needChangePixelResolution = false;
	}

	if (needChangeSamplesPerFrameAmount)
	{
		pathTracingUniforms.uSamplesPerFrame.value = samplesPerFrame_AmountController.getValue();
		cameraIsMoving = true;
		needChangeSamplesPerFrameAmount = false;
	}

	if (needChangePreviousFrameBlendWeight)
	{
		pathTracingUniforms.uPreviousFrameBlendWeight.value = previousFrameBlend_WeightController.getValue();
		cameraIsMoving = true;
		needChangePreviousFrameBlendWeight = false;
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
	torusRotationAngle += (1.5 * frameTime);
	torusRotationAngle %= TWO_PI;
	torusObject.rotation.set(0, torusRotationAngle, Math.PI * 0.5);
	torusObject.updateMatrixWorld(true); // 'true' forces immediate matrix update
	pathTracingUniforms.uTorusInvMatrix.value.copy(torusObject.matrixWorld).invert();

	// INFO
	cameraInfoElement.innerHTML = "FOV: " + worldCamera.fov + " / Aperture: " + apertureSize.toFixed(2) + " / FocusDistance: " + focusDistance + "<br>" + "Samples: " + sampleCounter;

} // end function updateUniforms()



init(); // init app and start animating
