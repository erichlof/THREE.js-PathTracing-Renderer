// scene/demo-specific variables go here
let sunAngle = 0;
let sunDirection = new THREE.Vector3();
let waterLevel = 0.0;
let cameraUnderWater = false;

// called automatically from within initTHREEjs() function (located in InitCommon.js file)
function initSceneData()
{
	demoFragmentShaderFileName = 'Arctic_Circle_Fragment.glsl';

	// scene/demo-specific three.js objects setup goes here
	sceneIsDynamic = true;
	
	cameraFlightSpeed = 1000;

	// pixelRatio is resolution - range: 0.5(half resolution) to 1.0(full resolution)
	pixelRatio = mouseControl ? 0.7 : 0.75;

	EPS_intersect = 1.0;

	// set camera's field of view
	worldCamera.fov = 60;
	focusDistance = 2000.0;
	apertureChangeSpeed = 100;

	// position and orient camera
	cameraControlsObject.position.set(-7134, 1979, -4422);
	cameraControlsYawObject.rotation.y = 3.0;
	cameraControlsPitchObject.rotation.x = 0.0;

	PerlinNoiseTexture = new THREE.TextureLoader().load('textures/perlin256.png');
	PerlinNoiseTexture.wrapS = THREE.RepeatWrapping;
	PerlinNoiseTexture.wrapT = THREE.RepeatWrapping;
	PerlinNoiseTexture.flipY = false;
	PerlinNoiseTexture.minFilter = THREE.LinearFilter;
	PerlinNoiseTexture.magFilter = THREE.LinearFilter;
	PerlinNoiseTexture.generateMipmaps = false;

	// scene/demo-specific uniforms go here
	pathTracingUniforms.t_PerlinNoise = { value: PerlinNoiseTexture };
	pathTracingUniforms.uWaterLevel = { value: 0.0 };
	pathTracingUniforms.uSunDirection = { value: new THREE.Vector3() };

} // end function initSceneData()



// called automatically from within the animate() function (located in InitCommon.js file)
function updateVariablesAndUniforms()
{

	// scene/demo-specific variables
	if (cameraControlsObject.position.y < 0.0)
		cameraUnderWater = true;
	else cameraUnderWater = false;

	sunAngle = ((elapsedTime * 0.04) + 0.5) % TWO_PI;
	sunDirection.set(Math.cos(sunAngle), Math.cos(sunAngle) * 0.2 + 0.2, Math.sin(sunAngle));
	sunDirection.normalize();

	// scene/demo-specific uniforms
	pathTracingUniforms.uWaterLevel.value = waterLevel;
	pathTracingUniforms.uSunDirection.value.copy(sunDirection);

	// INFO
	cameraInfoElement.innerHTML = "FOV: " + worldCamera.fov + " / Aperture: " + apertureSize.toFixed(2) + " / FocusDistance: " + focusDistance + "<br>" + "Samples: " + sampleCounter;

} // end function updateUniforms()



init(); // init app and start animating
