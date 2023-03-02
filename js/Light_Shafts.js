// scene/demo-specific variables go here


// called automatically from within initTHREEjs() function (located in InitCommon.js file)
function initSceneData() 
{
	demoFragmentShaderFileName = 'Light_Shafts_Fragment.glsl';

	// scene/demo-specific three.js objects setup goes here
	sceneIsDynamic = false;

	cameraFlightSpeed = 80;

	// pixelRatio is resolution - range: 0.5(half resolution) to 1.0(full resolution)
	pixelRatio = mouseControl ? 1.0 : 0.75; // less demanding on battery-powered mobile devices

	EPS_intersect = 0.001;

	// set camera's field of view
	worldCamera.fov = 70;
	focusDistance = 100;
	apertureChangeSpeed = 20;

	// position and orient camera
	cameraControlsObject.position.set(0, 0, 51);
	///cameraControlsYawObject.rotation.y = 0.0;
	// look slightly upward
	cameraControlsPitchObject.rotation.x = 0.005;

} // end function initSceneData()



// called automatically from within the animate() function (located in InitCommon.js file)
function updateVariablesAndUniforms() 
{
	// INFO
	cameraInfoElement.innerHTML = "FOV: " + worldCamera.fov + " / Aperture: " + apertureSize.toFixed(2) + " / FocusDistance: " + focusDistance + "<br>" + "Samples: " + sampleCounter;

} // end function updateUniforms()



init(); // init app and start animating
