// scene/demo-specific variables go here


// called automatically from within initTHREEjs() function (located in InitCommon.js file)
function initSceneData() 
{
	demoFragmentShaderFileName = 'Kajiya_TheRenderingEquation_Fragment.glsl';

	// scene/demo-specific three.js objects setup goes here
	sceneIsDynamic = false;
	
	cameraFlightSpeed = 60;

	// pixelRatio is resolution - range: 0.5(half resolution) to 1.0(full resolution)
	pixelRatio = mouseControl ? 0.75 : 0.7; // less demanding on battery-powered mobile devices

	EPS_intersect = 0.01;

	// set camera's field of view
	worldCamera.fov = 60;
	focusDistance = 140.0;
	apertureChangeSpeed = 5;

	// position and orient camera
	cameraControlsObject.position.set(20,30,130);
	cameraControlsYawObject.rotation.y = 0.2;
	// look slightly downward
	///cameraControlsPitchObject.rotation.x = -0.4;

} // end function initSceneData()



// called automatically from within the animate() function (located in InitCommon.js file)
function updateVariablesAndUniforms() 
{
	
	// INFO
	cameraInfoElement.innerHTML = "FOV: " + worldCamera.fov + " / Aperture: " + apertureSize.toFixed(2) + " / FocusDistance: " + focusDistance + "<br>" + "Samples: " + sampleCounter;

} // end function updateUniforms()



init(); // init app and start animating
