// scene/demo-specific variables go here


// called automatically from within initTHREEjs() function (located in InitCommon.js file)
function initSceneData()
{
	demoFragmentShaderFileName = 'Bi-Directional_PathTracing_Fragment.glsl';

	// scene/demo-specific three.js objects setup goes here
	sceneIsDynamic = false;
	
	edgeSharpenSpeed = 0.001;//0.0002;

	cameraFlightSpeed = 300;

	// pixelRatio is resolution - range: 0.5(half resolution) to 1.0(full resolution)
	pixelRatio = mouseControl ? 1.0 : 0.75;

	EPS_intersect = 0.01;

	// set camera's field of view
	worldCamera.fov = 55;
	focusDistance = 622.0;
	apertureChangeSpeed = 100;

	// position and orient camera
	cameraControlsObject.position.set(380, 350, 180);
	// look slightly to the left
	cameraControlsYawObject.rotation.y = 0.2;
	// look slightly upward
	cameraControlsPitchObject.rotation.x = -0.25;

} // end function initSceneData()



// called automatically from within the animate() function (located in InitCommon.js file)
function updateVariablesAndUniforms()
{
	
	// INFO
	cameraInfoElement.innerHTML = "FOV: " + worldCamera.fov + " / Aperture: " + apertureSize.toFixed(2) + " / FocusDistance: " + focusDistance + "<br>" + "Samples: " + sampleCounter;

} // end function updateUniforms()



init(); // init app and start animating
