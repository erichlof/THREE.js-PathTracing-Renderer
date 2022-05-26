// scene/demo-specific variables go here
let torusObject;
let torusRotationAngle = 0;

// called automatically from within initTHREEjs() function (located in InitCommon.js file)
function initSceneData()
{
	demoFragmentShaderFileName = 'GameEngine_PathTracer_Fragment.glsl';

	// scene/demo-specific three.js objects setup goes here
	sceneIsDynamic = true;

	pixelEdgeSharpness = 0.75;
	
	cameraFlightSpeed = 60;

	// pixelRatio is resolution - range: 0.5(half resolution) to 1.0(full resolution)
	pixelRatio = mouseControl ? 0.75 : 0.75;

	EPS_intersect = 0.01;

	// Torus Object
	torusObject = new THREE.Object3D();
	pathTracingScene.add(torusObject);
	
	torusObject.position.set(-60, 18, 50);
	torusObject.scale.set(11.5, 11.5, 11.5);

	// set camera's field of view
	worldCamera.fov = 60;
	focusDistance = 130.0;

	// position and orient camera
	cameraControlsObject.position.set(0, 20, 120);
	///cameraControlsYawObject.rotation.y = 0.0;
	// look slightly downward
	///cameraControlsPitchObject.rotation.x = -0.4;



	// scene/demo-specific uniforms go here
	pathTracingUniforms.uTorusInvMatrix = { value: new THREE.Matrix4() };

} // end function initSceneData()



// called automatically from within the animate() function (located in InitCommon.js file)
function updateVariablesAndUniforms()
{

	// TORUS
	torusRotationAngle += (1.5 * frameTime);
	torusRotationAngle %= TWO_PI;
	torusObject.rotation.set(0, torusRotationAngle, 0);
	torusObject.updateMatrixWorld(true); // 'true' forces immediate matrix update
	pathTracingUniforms.uTorusInvMatrix.value.copy(torusObject.matrixWorld).invert();


	// INFO
	cameraInfoElement.innerHTML = "FOV: " + worldCamera.fov + " / Aperture: " + apertureSize.toFixed(2) + " / FocusDistance: " + focusDistance + "<br>" + "Samples: " + sampleCounter;

} // end function updateUniforms()



init(); // init app and start animating
