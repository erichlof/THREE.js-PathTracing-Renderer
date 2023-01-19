// scene/demo-specific variables go here
let tallBoxGeometry, tallBoxMaterial, tallBoxMesh;
let shortBoxGeometry, shortBoxMaterial, shortBoxMesh;

// called automatically from within initTHREEjs() function (located in InitCommon.js file)
function initSceneData() 
{
	demoFragmentShaderFileName = 'Cornell_Box_Fragment.glsl';

	// scene/demo-specific three.js objects setup goes here
	sceneIsDynamic = false;
	
	cameraFlightSpeed = 300;

	// pixelRatio is resolution - range: 0.5(half resolution) to 1.0(full resolution)
	pixelRatio = mouseControl ? 1.0 : 0.75;

	EPS_intersect = 0.01;

	// Boxes
	tallBoxGeometry = new THREE.BoxGeometry(1,1,1);
	tallBoxMaterial = new THREE.MeshPhysicalMaterial( {
		color: new THREE.Color(0.95, 0.95, 0.95), //RGB, ranging from 0.0 - 1.0
		roughness: 1.0 // ideal Diffuse material	
	} );
	
	tallBoxMesh = new THREE.Mesh(tallBoxGeometry, tallBoxMaterial);
	pathTracingScene.add(tallBoxMesh);
	tallBoxMesh.visible = false; // disable normal Three.js rendering updates of this object: 
	// it is just a data placeholder as well as an Object3D that can be transformed/manipulated by 
	// using familiar Three.js library commands. It is then fed into the GPU path tracing renderer
	// through its 'matrixWorld' matrix. See below:
	tallBoxMesh.rotation.set(0, Math.PI * 0.1, 0);
	tallBoxMesh.position.set(180, 170, -350);
	tallBoxMesh.updateMatrixWorld(true); // 'true' forces immediate matrix update
	
	
	shortBoxGeometry = new THREE.BoxGeometry(1,1,1);
	shortBoxMaterial = new THREE.MeshPhysicalMaterial( {
		color: new THREE.Color(0.95, 0.95, 0.95), //RGB, ranging from 0.0 - 1.0
		roughness: 1.0 // ideal Diffuse material	
	} );
	
	shortBoxMesh = new THREE.Mesh(shortBoxGeometry, shortBoxMaterial);
	pathTracingScene.add(shortBoxMesh);
	shortBoxMesh.visible = false;
	shortBoxMesh.rotation.set(0, -Math.PI * 0.09, 0);
	shortBoxMesh.position.set(370, 85, -170);
	shortBoxMesh.updateMatrixWorld(true); // 'true' forces immediate matrix update
	

	// set camera's field of view
	worldCamera.fov = 31;
	focusDistance = 1180.0;
	apertureChangeSpeed = 200;

	// position and orient camera
	cameraControlsObject.position.set(278, 270, 1050);
	///cameraControlsYawObject.rotation.y = 0.0;
	// look slightly upward
	cameraControlsPitchObject.rotation.x = 0.005;


	// scene/demo-specific uniforms go here     
	pathTracingUniforms.uTallBoxInvMatrix = { value: new THREE.Matrix4() };
	pathTracingUniforms.uShortBoxInvMatrix = { value: new THREE.Matrix4() };

} // end function initSceneData()



// called automatically from within the animate() function (located in InitCommon.js file)
function updateVariablesAndUniforms() 
{   
	// BOXES
	pathTracingUniforms.uTallBoxInvMatrix.value.copy(tallBoxMesh.matrixWorld).invert();
	pathTracingUniforms.uShortBoxInvMatrix.value.copy(shortBoxMesh.matrixWorld).invert();
	
	// INFO
	cameraInfoElement.innerHTML = "FOV: " + worldCamera.fov + " / Aperture: " + apertureSize.toFixed(2) + " / FocusDistance: " + focusDistance + "<br>" + "Samples: " + sampleCounter;

} // end function updateVariablesAndUniforms()



init(); // init app and start animating
