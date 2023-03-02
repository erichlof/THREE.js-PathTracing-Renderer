// scene/demo-specific variables go here
let waterLevel = 0.0;
let cameraUnderWater = false;
let tallBoxGeometry, tallBoxMaterial, tallBoxMesh;
let shortBoxGeometry, shortBoxMaterial, shortBoxMesh;


// called automatically from within initTHREEjs() function (located in InitCommon.js file)
function initSceneData()
{
	demoFragmentShaderFileName = 'Water_Rendering_Fragment.glsl';

	// scene/demo-specific three.js objects setup goes here
	sceneIsDynamic = true;
	
	cameraFlightSpeed = 300;

	// pixelRatio is resolution - range: 0.5(half resolution) to 1.0(full resolution)
	pixelRatio = mouseControl ? 1.0 : 0.8;

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
	worldCamera.fov = 50;
	focusDistance = 500.0;
	apertureChangeSpeed = 200;

	// position and orient camera
	cameraControlsObject.position.set(96, 397, 278);
	cameraControlsYawObject.rotation.y = -0.3;
	// look slightly downward
	cameraControlsPitchObject.rotation.x = -0.45;

	/*
	PerlinNoiseTexture = new THREE.TextureLoader().load( 'textures/perlin256.png' );
	PerlinNoiseTexture.wrapS = THREE.RepeatWrapping;
	PerlinNoiseTexture.wrapT = THREE.RepeatWrapping;
	PerlinNoiseTexture.flipY = false;
	PerlinNoiseTexture.minFilter = THREE.LinearFilter;
	PerlinNoiseTexture.magFilter = THREE.LinearFilter;
	PerlinNoiseTexture.generateMipmaps = false;
	*/

	// scene/demo-specific uniforms go here
	pathTracingUniforms.uShortBoxInvMatrix = { value: new THREE.Matrix4() };
	pathTracingUniforms.uTallBoxInvMatrix = { value: new THREE.Matrix4() };

} // end function initSceneData()



// called automatically from within the animate() function (located in InitCommon.js file)
function updateVariablesAndUniforms()
{

	// scene/demo-specific variables
	if (cameraControlsObject.position.y < 0.0)
		cameraUnderWater = true;
	else cameraUnderWater = false;

	// scene/demo-specific uniforms
	// BOXES
	pathTracingUniforms.uTallBoxInvMatrix.value.copy(tallBoxMesh.matrixWorld).invert();
	pathTracingUniforms.uShortBoxInvMatrix.value.copy(shortBoxMesh.matrixWorld).invert();

	// INFO
	cameraInfoElement.innerHTML = "FOV: " + worldCamera.fov + " / Aperture: " + apertureSize.toFixed(2) + " / FocusDistance: " + focusDistance + "<br>" + "Samples: " + sampleCounter;

} // end function updateUniforms()



init(); // init app and start animating
