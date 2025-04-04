// scene/demo-specific variables go here
let frontLeft_VertexMoveController, frontLeft_VertexMoveObject;
let frontMiddle_VertexMoveController, frontMiddle_VertexMoveObject;
let frontRight_VertexMoveController, frontRight_VertexMoveObject;
let rearLeft_VertexMoveController, rearLeft_VertexMoveObject;
let rearMiddle_VertexMoveController, rearMiddle_VertexMoveObject;
let rearRight_VertexMoveController, rearRight_VertexMoveObject;
let needChangePatchVertex = false;


// called automatically from within initTHREEjs() function (located in InitCommon.js file)
function initSceneData() 
{
	demoFragmentShaderFileName = 'Quads_Only_Modeling_Fragment.glsl';

	// scene/demo-specific three.js objects setup goes here
	sceneIsDynamic = false;

	cameraFlightSpeed = 100;

	// pixelRatio is resolution - range: 0.5(half resolution) to 1.0(full resolution)
	pixelRatio = mouseControl ? 1.0 : 1.0; // mobile devices can also handle full resolution for this demo 

	EPS_intersect = 0.01;

	// set camera's field of view
	worldCamera.fov = 50;
	focusDistance = 120.0;
	apertureChangeSpeed = 5;

	// position and orient camera
	cameraControlsObject.position.set(0, -2, 140);
	///cameraControlsYawObject.rotation.y = 0.0;
	// look slightly upward
	//cameraControlsPitchObject.rotation.x = 0.005;


	// In addition to the default GUI on all demos, add any special GUI elements that this particular demo requires
	frontLeft_VertexMoveObject = { FrontLeftVertexHeight : -5 };
	frontMiddle_VertexMoveObject = { FrontMiddleVertexHeight : -10 };
	frontRight_VertexMoveObject = { FrontRightVertexHeight : 0 };

	rearLeft_VertexMoveObject = { RearLeftVertexHeight : -13 };
	rearMiddle_VertexMoveObject = { RearMiddleVertexHeight : 10 };
	rearRight_VertexMoveObject = { RearRightVertexHeight : -8 };

	function handlePatchVertexChange() 
	{
		needChangePatchVertex = true;
	}

	frontLeft_VertexMoveController = gui.add(frontLeft_VertexMoveObject, 'FrontLeftVertexHeight', -25, 25, 0.01).onChange(handlePatchVertexChange);
	frontMiddle_VertexMoveController = gui.add(frontMiddle_VertexMoveObject, 'FrontMiddleVertexHeight', -25, 25, 0.01).onChange(handlePatchVertexChange);
	frontRight_VertexMoveController = gui.add(frontRight_VertexMoveObject, 'FrontRightVertexHeight', -25, 25, 0.01).onChange(handlePatchVertexChange);

	rearLeft_VertexMoveController = gui.add(rearLeft_VertexMoveObject, 'RearLeftVertexHeight', -25, 25, 0.01).onChange(handlePatchVertexChange);
	rearMiddle_VertexMoveController = gui.add(rearMiddle_VertexMoveObject, 'RearMiddleVertexHeight', -25, 25, 0.01).onChange(handlePatchVertexChange);
	rearRight_VertexMoveController = gui.add(rearRight_VertexMoveObject, 'RearRightVertexHeight', -25, 25, 0.01).onChange(handlePatchVertexChange);

	// jumpstart all the gui change controller handlers so that the pathtracing fragment shader uniforms are correct and up-to-date
	handlePatchVertexChange();

	// scene/demo-specific uniforms go here
	pathTracingUniforms.uFrontLeftVertexHeight = { value: 0.0 };
	pathTracingUniforms.uFrontMiddleVertexHeight = { value: 0.0 };
	pathTracingUniforms.uFrontRightVertexHeight = { value: 0.0 };
	pathTracingUniforms.uRearLeftVertexHeight = { value: 0.0 };
	pathTracingUniforms.uRearMiddleVertexHeight = { value: 0.0 };
	pathTracingUniforms.uRearRightVertexHeight = { value: 0.0 };

} // end function initSceneData()



// called automatically from within the animate() function (located in InitCommon.js file)
function updateVariablesAndUniforms() 
{

	if (needChangePatchVertex)
	{
		pathTracingUniforms.uFrontLeftVertexHeight.value = frontLeft_VertexMoveController.getValue();
		pathTracingUniforms.uFrontMiddleVertexHeight.value = frontMiddle_VertexMoveController.getValue();
		pathTracingUniforms.uFrontRightVertexHeight.value = frontRight_VertexMoveController.getValue();

		pathTracingUniforms.uRearLeftVertexHeight.value = rearLeft_VertexMoveController.getValue();
		pathTracingUniforms.uRearMiddleVertexHeight.value = rearMiddle_VertexMoveController.getValue();
		pathTracingUniforms.uRearRightVertexHeight.value = rearRight_VertexMoveController.getValue();

		cameraIsMoving = true;
		needChangePatchVertex = false;
	}

	// INFO
	cameraInfoElement.innerHTML = "FOV: " + worldCamera.fov + " / Aperture: " + apertureSize.toFixed(2) + " / FocusDistance: " + focusDistance + "<br>" + "Samples: " + sampleCounter;

} // end function updateVariablesAndUniforms()



init(); // init app and start animating