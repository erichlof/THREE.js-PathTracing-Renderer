// scene/demo-specific variables go here
let sunAngle = 0;
let sunDirection = new THREE.Vector3();
let tallBoxGeometry, tallBoxMaterial, tallBoxMesh;
let shortBoxGeometry, shortBoxMaterial, shortBoxMesh;
let PerlinNoiseTexture;

// called automatically from within initTHREEjs() function (located in InitCommon.js file)
function initSceneData()
{
	demoFragmentShaderFileName = 'Ocean_And_Sky_Rendering_Fragment.glsl';

	// scene/demo-specific three.js objects setup goes here
	sceneIsDynamic = true;

	pixelEdgeSharpness = 0.5;
	
	cameraFlightSpeed = 300;

	// pixelRatio is resolution - range: 0.5(half resolution) to 1.0(full resolution)
	pixelRatio = mouseControl ? 0.75 : 0.8;

	EPS_intersect = 0.01;

	// Boxes
	tallBoxGeometry = new THREE.BoxGeometry(1, 1, 1);
	tallBoxMaterial = new THREE.MeshPhysicalMaterial({
		color: new THREE.Color(0.95, 0.95, 0.95), //RGB, ranging from 0.0 - 1.0
		roughness: 1.0 // ideal Diffuse material	
	});

	tallBoxMesh = new THREE.Mesh(tallBoxGeometry, tallBoxMaterial);
	pathTracingScene.add(tallBoxMesh);
	tallBoxMesh.visible = false; // disable normal Three.js rendering updates of this object: 
	// it is just a data placeholder as well as an Object3D that can be transformed/manipulated by 
	// using familiar Three.js library commands. It is then fed into the GPU path tracing renderer
	// through its 'matrixWorld' matrix. See below:
	tallBoxMesh.rotation.set(0, Math.PI * 0.1, 0);
	tallBoxMesh.position.set(180, 170, -350);
	tallBoxMesh.updateMatrixWorld(true); // 'true' forces immediate matrix update


	shortBoxGeometry = new THREE.BoxGeometry(1, 1, 1);
	shortBoxMaterial = new THREE.MeshPhysicalMaterial({
		color: new THREE.Color(0.95, 0.95, 0.95), //RGB, ranging from 0.0 - 1.0
		roughness: 1.0 // ideal Diffuse material	
	});

	shortBoxMesh = new THREE.Mesh(shortBoxGeometry, shortBoxMaterial);
	pathTracingScene.add(shortBoxMesh);
	shortBoxMesh.visible = false;
	shortBoxMesh.rotation.set(0, -Math.PI * 0.09, 0);
	shortBoxMesh.position.set(370, 85, -170);
	shortBoxMesh.updateMatrixWorld(true); // 'true' forces immediate matrix update


	// set camera's field of view
	worldCamera.fov = 60;
	focusDistance = 1180.0;
	apertureChangeSpeed = 100;

	// position and orient camera
	cameraControlsObject.position.set(278, 270, 1050);
	///cameraControlsYawObject.rotation.y = 0.0;
	// look slightly upward
	cameraControlsPitchObject.rotation.x = 0.005;

	

	// scene/demo-specific uniforms go here
	pathTracingUniforms.t_PerlinNoise = { value: PerlinNoiseTexture };
	pathTracingUniforms.uCameraUnderWater = { value: 0.0 };
	pathTracingUniforms.uSunDirection = { value: new THREE.Vector3() };
	pathTracingUniforms.uTallBoxInvMatrix = { value: new THREE.Matrix4() };
	pathTracingUniforms.uShortBoxInvMatrix = { value: new THREE.Matrix4() };

} // end function initSceneData()



// called automatically from within the animate() function (located in InitCommon.js file)
function updateVariablesAndUniforms()
{

	// scene/demo-specific variables
	sunAngle = (elapsedTime * 0.035) % (Math.PI + 0.2) - 0.11;
	sunDirection.set(Math.cos(sunAngle), Math.sin(sunAngle), -Math.cos(sunAngle) * 2.0);
	sunDirection.normalize();

	// scene/demo-specific uniforms
	pathTracingUniforms.uSunDirection.value.copy(sunDirection);

	// BOXES
	pathTracingUniforms.uTallBoxInvMatrix.value.copy(tallBoxMesh.matrixWorld).invert();
	pathTracingUniforms.uShortBoxInvMatrix.value.copy(shortBoxMesh.matrixWorld).invert();

	// CAMERA
	if (cameraControlsObject.position.y < 2.0)
		pathTracingUniforms.uCameraUnderWater.value = 1.0;
	else
		pathTracingUniforms.uCameraUnderWater.value = 0.0;

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
