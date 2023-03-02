// scene/demo-specific variables go here
let HeightmapTexture;

// called automatically from within initTHREEjs() function (located in InitCommon.js file)
function initSceneData()
{
	demoFragmentShaderFileName = 'Grid_Acceleration_Fragment.glsl';

	// scene/demo-specific three.js objects setup goes here
	sceneIsDynamic = true;
	
	cameraFlightSpeed = 60;

	// pixelRatio is resolution - range: 0.5(half resolution) to 1.0(full resolution)
	pixelRatio = mouseControl ? 0.5 : 0.5;

	EPS_intersect = 0.01;

	// set camera's field of view
	worldCamera.fov = 60;
	focusDistance = 140.0;

	// position and orient camera
	//cameraControlsObject.position.set(0, 200, 400); // for 512.0 segments
	cameraControlsObject.position.set(0, 300, 750); // for 1024.0 segments

	// look left or right
	//cameraControlsYawObject.rotation.y = 0.2;

	// look slightly downward
	cameraControlsPitchObject.rotation.x = -0.5;

	

	// scene/demo-specific uniforms go here
	pathTracingUniforms.t_Heightmap = { value: HeightmapTexture };

} // end function initSceneData()



// called automatically from within the animate() function (located in InitCommon.js file)
function updateVariablesAndUniforms()
{

	// INFO
	cameraInfoElement.innerHTML = "FOV: " + worldCamera.fov + " / Aperture: " + apertureSize.toFixed(2) + " / FocusDistance: " + focusDistance + "<br>" + "Samples: " + sampleCounter;

} // end function updateUniforms()



// load a resource
HeightmapTexture = textureLoader.load(
	// resource URL
	'textures/DinoIsland1024.png',

	// onLoad callback
	function (texture)
	{
		//texture.wrapS = THREE.RepeatWrapping;
		//texture.wrapT = THREE.RepeatWrapping;
		texture.flipY = false;
		texture.minFilter = THREE.LinearFilter;
		texture.magFilter = THREE.LinearFilter;
		texture.generateMipmaps = false;

		// now that the texture has been loaded, we can init 
		init();
	}
);
