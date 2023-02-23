// scene/demo-specific variables go here
let tileNormalMapTexture;


// called automatically from within initTHREEjs() function (located in InitCommon.js file)
function initSceneData()
{
	demoFragmentShaderFileName = 'Whitted_TheCompleatAngler_Fragment.glsl';

	// scene/demo-specific three.js objects setup goes here
	sceneIsDynamic = true;

	cameraFlightSpeed = 60;

	// pixelRatio is resolution - range: 0.5(half resolution) to 1.0(full resolution)
	pixelRatio = mouseControl ? 1.0 : 1.0; // mobile devices can also handle full resolution for this raytracing (not full pathtracing) demo 

	// needs 0.1 precision instead of 0.01 to avoid artifacts on yellow sphere
	EPS_intersect = 0.1;

	// set camera's field of view
	worldCamera.fov = 55;
	focusDistance = 119.0;
	apertureChangeSpeed = 5;

	// position and orient camera
	cameraControlsObject.position.set(-10, 79, 195);
	// look slightly downward
	cameraControlsPitchObject.rotation.x = -0.05;

	
	// scene/demo-specific uniforms go here
	pathTracingUniforms.tTileNormalMapTexture = { value: tileNormalMapTexture };

} // end function initSceneData()



// called automatically from within the animate() function (located in InitCommon.js file)
function updateVariablesAndUniforms()
{

	// INFO
	cameraInfoElement.innerHTML = "FOV: " + worldCamera.fov + " / Aperture: " + apertureSize.toFixed(2) + " / FocusDistance: " + focusDistance + "<br>" + "Samples: " + sampleCounter;

} // end function updateUniforms()



// load a resource
tileNormalMapTexture = textureLoader.load(
	// resource URL
	'textures/tileNormalMap.png',

	// onLoad callback
	function (texture)
	{
		texture.wrapS = THREE.RepeatWrapping;
		texture.wrapT = THREE.RepeatWrapping;
		texture.flipY = true;
		texture.minFilter = THREE.NearestFilter;
		texture.magFilter = THREE.NearestFilter;
		texture.generateMipmaps = false;

		// now that the texture has been loaded, we can init 
		init();
	}
);
