// scene/demo-specific variables go here
let sunAngle = 0;
let sunDirection = new THREE.Vector3();
let waterLevel = 400;
let cameraUnderWater = 0.0;
let PerlinNoiseTexture;

// called automatically from within initTHREEjs() function (located in InitCommon.js file)
function initSceneData()
{
	demoFragmentShaderFileName = 'Terrain_Rendering_Fragment.glsl';

	// scene/demo-specific three.js objects setup goes here
	sceneIsDynamic = true;
	
	cameraFlightSpeed = 300;

	// pixelRatio is resolution - range: 0.5(half resolution) to 1.0(full resolution)
	pixelRatio = mouseControl ? 0.7 : 0.75;

	EPS_intersect = 0.2;

	// set camera's field of view
	worldCamera.fov = 60;
	focusDistance = 3000.0;
	apertureChangeSpeed = 500;

	// position and orient camera
	cameraControlsObject.position.set(-837, 1350, 2156);
	cameraControlsYawObject.rotation.y = 0.0;
	cameraControlsPitchObject.rotation.x = 0.0;

	

	// scene/demo-specific uniforms go here
	pathTracingUniforms.t_PerlinNoise = { value: PerlinNoiseTexture };
	pathTracingUniforms.uCameraUnderWater = { value: 0.0 };
	pathTracingUniforms.uWaterLevel = { value: 0.0 };
	pathTracingUniforms.uSunDirection = { value: new THREE.Vector3() };

} // end function initSceneData()



// called automatically from within the animate() function (located in InitCommon.js file)
function updateVariablesAndUniforms()
{

	// scene/demo-specific variables
	sunAngle = (elapsedTime * 0.035) % (Math.PI + 0.2) - 0.11;
	sunDirection.set(Math.cos(sunAngle), Math.sin(sunAngle), -Math.cos(sunAngle) * 2.0);
	sunDirection.normalize();

	// scene/demo-specific uniforms
	if (cameraControlsObject.position.y < waterLevel)
		cameraUnderWater = 1.0;
	else cameraUnderWater = 0.0;

	pathTracingUniforms.uCameraUnderWater.value = cameraUnderWater;
	pathTracingUniforms.uWaterLevel.value = waterLevel;
	pathTracingUniforms.uSunDirection.value.copy(sunDirection);

	// INFO
	cameraInfoElement.innerHTML = "FOV: " + worldCamera.fov + " / Aperture: " + apertureSize.toFixed(2) + " / FocusDistance: " + focusDistance + "<br>" + "Samples: " + sampleCounter;

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
