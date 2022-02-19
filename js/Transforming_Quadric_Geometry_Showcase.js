// scene/demo-specific variables go here

var ellipsoidTranslate, cylinderTranslate, coneTranslate, paraboloidTranslate, hyperboloidTranslate, hyperbolicParaboloidTranslate;
var ellipsoidRotate, cylinderRotate, coneRotate, paraboloidRotate, hyperboloidRotate, hyperbolicParaboloidRotate;
var ellipsoidScale, cylinderScale, coneScale, paraboloidScale, hyperboloidScale, hyperbolicParaboloidScale;
var ellipsoidClip, cylinderClip, coneClip, paraboloidClip, hyperboloidClip, hyperbolicParaboloidClip;

var ellipsoidTranslateAngle, cylinderTranslateAngle, coneTranslateAngle, paraboloidTranslateAngle, hyperboloidTranslateAngle, hyperbolicParaboloidTranslateAngle;
var ellipsoidRotateAngle, cylinderRotateAngle, coneRotateAngle, paraboloidRotateAngle, hyperboloidRotateAngle, hyperbolicParaboloidRotateAngle;
var ellipsoidScaleAngle, cylinderScaleAngle, coneScaleAngle, paraboloidScaleAngle, hyperboloidScaleAngle, hyperbolicParaboloidScaleAngle;

var spacing = 50;
var baseXPos = 200;
var baseYPos = 50;
var baseZPos = -200;
var posXOffset = 25;


// called automatically from within initTHREEjs() function
function initSceneData()
{
	// scene/demo-specific three.js objects setup goes here
	sceneIsDynamic = true;
	cameraFlightSpeed = 60;

	// pixelRatio is resolution - range: 0.5(half resolution) to 1.0(full resolution)
	pixelRatio = mouseControl ? 0.75 : 0.75; // less demanding on battery-powered mobile devices

	EPS_intersect = 0.01;

	// set camera's field of view
	worldCamera.fov = 60;
	focusDistance = 325.0;

	// position and orient camera
	cameraControlsObject.position.set(0, 20, 120);
	///cameraControlsYawObject.rotation.y = 0.0;
	// look slightly downward
	///cameraControlsPitchObject.rotation.x = -0.4;

	// translation models
	ellipsoidTranslate = new THREE.Object3D();
	pathTracingScene.add(ellipsoidTranslate);
	ellipsoidTranslate.position.set(spacing * -3 + posXOffset, baseYPos + 3, baseZPos);
	ellipsoidTranslate.scale.set(20, 20, 20);

	cylinderTranslate = new THREE.Object3D();
	pathTracingScene.add(cylinderTranslate);
	cylinderTranslate.position.set(spacing * -2 + posXOffset, baseYPos, baseZPos);
	cylinderTranslate.scale.set(20, 20, 20);

	coneTranslate = new THREE.Object3D();
	pathTracingScene.add(coneTranslate);
	coneTranslate.position.set(spacing * -1 + posXOffset, baseYPos, baseZPos);
	coneTranslate.scale.set(20, 20, 20);

	paraboloidTranslate = new THREE.Object3D();
	pathTracingScene.add(paraboloidTranslate);
	paraboloidTranslate.position.set(spacing * 0 + posXOffset, baseYPos - 3, baseZPos);
	paraboloidTranslate.scale.set(20, 20, 20);

	hyperboloidTranslate = new THREE.Object3D();
	pathTracingScene.add(hyperboloidTranslate);
	hyperboloidTranslate.position.set(spacing * 1 + posXOffset, baseYPos, baseZPos);
	hyperboloidTranslate.scale.set(20, 20, 20);

	hyperbolicParaboloidTranslate = new THREE.Object3D();
	pathTracingScene.add(hyperbolicParaboloidTranslate);
	hyperbolicParaboloidTranslate.position.set(spacing * 2 + posXOffset, baseYPos + 5, baseZPos);
	hyperbolicParaboloidTranslate.scale.set(20, 20, 20);


	// rotation models
	ellipsoidRotate = new THREE.Object3D();
	pathTracingScene.add(ellipsoidRotate);
	ellipsoidRotate.position.set(baseXPos, baseYPos + 5, spacing * -3);
	ellipsoidRotate.scale.set(20, 20, 10);

	cylinderRotate = new THREE.Object3D();
	pathTracingScene.add(cylinderRotate);
	cylinderRotate.position.set(baseXPos, baseYPos, spacing * -2);
	cylinderRotate.scale.set(18, 16, 18);

	coneRotate = new THREE.Object3D();
	pathTracingScene.add(coneRotate);
	coneRotate.position.set(baseXPos, baseYPos, spacing * -1);
	coneRotate.scale.set(20, 20, 20);

	paraboloidRotate = new THREE.Object3D();
	pathTracingScene.add(paraboloidRotate);
	paraboloidRotate.position.set(baseXPos, baseYPos, spacing * 0);
	paraboloidRotate.scale.set(20, 20, 20);

	hyperboloidRotate = new THREE.Object3D();
	pathTracingScene.add(hyperboloidRotate);
	hyperboloidRotate.position.set(baseXPos, baseYPos + 1, spacing * 1);
	hyperboloidRotate.scale.set(20, 20, 20);

	hyperbolicParaboloidRotate = new THREE.Object3D();
	pathTracingScene.add(hyperbolicParaboloidRotate);
	hyperbolicParaboloidRotate.position.set(baseXPos, baseYPos, spacing * 2);
	hyperbolicParaboloidRotate.scale.set(20, 20, 20);


	// scaling models
	ellipsoidScale = new THREE.Object3D();
	pathTracingScene.add(ellipsoidScale);
	ellipsoidScale.position.set(-baseXPos, baseYPos, spacing * 2);
	ellipsoidScale.scale.set(20, 20, 20);

	cylinderScale = new THREE.Object3D();
	pathTracingScene.add(cylinderScale);
	cylinderScale.position.set(-baseXPos, baseYPos + 1, spacing * 1);
	cylinderScale.scale.set(20, 20, 20);

	coneScale = new THREE.Object3D();
	pathTracingScene.add(coneScale);
	coneScale.position.set(-baseXPos, baseYPos, spacing * 0);
	coneScale.scale.set(20, 20, 20);

	paraboloidScale = new THREE.Object3D();
	pathTracingScene.add(paraboloidScale);
	paraboloidScale.position.set(-baseXPos, baseYPos, spacing * -1);
	paraboloidScale.scale.set(20, 20, 20);

	hyperboloidScale = new THREE.Object3D();
	pathTracingScene.add(hyperboloidScale);
	hyperboloidScale.position.set(-baseXPos, baseYPos, spacing * -2);
	hyperboloidScale.scale.set(20, 20, 20);

	hyperbolicParaboloidScale = new THREE.Object3D();
	pathTracingScene.add(hyperbolicParaboloidScale);
	hyperbolicParaboloidScale.position.set(-baseXPos, baseYPos + 5, spacing * -3);
	hyperbolicParaboloidScale.scale.set(20, 20, 20);


	// clipping models
	ellipsoidClip = new THREE.Object3D();
	pathTracingScene.add(ellipsoidClip);
	ellipsoidClip.rotation.z = Math.PI * 0.5;
	ellipsoidClip.position.set(spacing * 2 + posXOffset, baseYPos + 3, -baseZPos);
	ellipsoidClip.scale.set(20, 20, 20);

	cylinderClip = new THREE.Object3D();
	pathTracingScene.add(cylinderClip);
	cylinderClip.position.set(spacing * 1 + posXOffset, baseYPos, -baseZPos);
	cylinderClip.scale.set(20, 20, 20);

	coneClip = new THREE.Object3D();
	pathTracingScene.add(coneClip);
	coneClip.position.set(spacing * 0 + posXOffset, baseYPos, -baseZPos);
	coneClip.scale.set(20, 20, 20);

	paraboloidClip = new THREE.Object3D();
	pathTracingScene.add(paraboloidClip);
	paraboloidClip.position.set(spacing * -1 + posXOffset, baseYPos - 3, -baseZPos);
	paraboloidClip.scale.set(20, 20, 20);

	hyperboloidClip = new THREE.Object3D();
	pathTracingScene.add(hyperboloidClip);
	hyperboloidClip.position.set(spacing * -2 + posXOffset, baseYPos, -baseZPos);
	hyperboloidClip.scale.set(20, 20, 20);

	hyperbolicParaboloidClip = new THREE.Object3D();
	pathTracingScene.add(hyperbolicParaboloidClip);
	hyperbolicParaboloidClip.position.set(spacing * -3 + posXOffset, baseYPos + 5, -baseZPos);
	hyperbolicParaboloidClip.scale.set(20, 20, 20);


	// init all angles to 0
	ellipsoidTranslateAngle = cylinderTranslateAngle = coneTranslateAngle = paraboloidTranslateAngle = hyperboloidTranslateAngle = hyperbolicParaboloidTranslateAngle =
		ellipsoidRotateAngle = cylinderRotateAngle = coneRotateAngle = paraboloidRotateAngle = hyperboloidRotateAngle = hyperbolicParaboloidRotateAngle =
		ellipsoidScaleAngle = cylinderScaleAngle = coneScaleAngle = paraboloidScaleAngle = hyperboloidScaleAngle = hyperbolicParaboloidScaleAngle =
		ellipsoidClipAngle = cylinderClipAngle = coneClipAngle = paraboloidClipAngle = hyperboloidClipAngle = hyperbolicParaboloidClipAngle = 0;

} // end function initSceneData()



// called automatically from within initTHREEjs() function
function initPathTracingShaders()
{
	// scene/demo-specific uniforms go here
	pathTracingUniforms.uEllipsoidTranslateInvMatrix = { type: "m4", value: new THREE.Matrix4() };
	pathTracingUniforms.uEllipsoidRotateInvMatrix = { type: "m4", value: new THREE.Matrix4() };
	pathTracingUniforms.uEllipsoidScaleInvMatrix = { type: "m4", value: new THREE.Matrix4() };
	pathTracingUniforms.uEllipsoidClipInvMatrix = { type: "m4", value: new THREE.Matrix4() };
	pathTracingUniforms.uCylinderTranslateInvMatrix = { type: "m4", value: new THREE.Matrix4() };
	pathTracingUniforms.uCylinderRotateInvMatrix = { type: "m4", value: new THREE.Matrix4() };
	pathTracingUniforms.uCylinderScaleInvMatrix = { type: "m4", value: new THREE.Matrix4() };
	pathTracingUniforms.uCylinderClipInvMatrix = { type: "m4", value: new THREE.Matrix4() };
	pathTracingUniforms.uConeTranslateInvMatrix = { type: "m4", value: new THREE.Matrix4() };
	pathTracingUniforms.uConeRotateInvMatrix = { type: "m4", value: new THREE.Matrix4() };
	pathTracingUniforms.uConeScaleInvMatrix = { type: "m4", value: new THREE.Matrix4() };
	pathTracingUniforms.uConeClipInvMatrix = { type: "m4", value: new THREE.Matrix4() };
	pathTracingUniforms.uParaboloidTranslateInvMatrix = { type: "m4", value: new THREE.Matrix4() };
	pathTracingUniforms.uParaboloidRotateInvMatrix = { type: "m4", value: new THREE.Matrix4() };
	pathTracingUniforms.uParaboloidScaleInvMatrix = { type: "m4", value: new THREE.Matrix4() };
	pathTracingUniforms.uParaboloidClipInvMatrix = { type: "m4", value: new THREE.Matrix4() };
	pathTracingUniforms.uHyperboloidTranslateInvMatrix = { type: "m4", value: new THREE.Matrix4() };
	pathTracingUniforms.uHyperboloidRotateInvMatrix = { type: "m4", value: new THREE.Matrix4() };
	pathTracingUniforms.uHyperboloidScaleInvMatrix = { type: "m4", value: new THREE.Matrix4() };
	pathTracingUniforms.uHyperboloidClipInvMatrix = { type: "m4", value: new THREE.Matrix4() };
	pathTracingUniforms.uHyperbolicParaboloidTranslateInvMatrix = { type: "m4", value: new THREE.Matrix4() };
	pathTracingUniforms.uHyperbolicParaboloidRotateInvMatrix = { type: "m4", value: new THREE.Matrix4() };
	pathTracingUniforms.uHyperbolicParaboloidScaleInvMatrix = { type: "m4", value: new THREE.Matrix4() };
	pathTracingUniforms.uHyperbolicParaboloidClipInvMatrix = { type: "m4", value: new THREE.Matrix4() };

	
	pathTracingDefines = {
		//NUMBER_OF_TRIANGLES: total_number_of_triangles
	};

	// load vertex and fragment shader files that are used in the pathTracing material, mesh and scene
	fileLoader.load('shaders/common_PathTracing_Vertex.glsl', function (shaderText)
	{
		pathTracingVertexShader = shaderText;

		createPathTracingMaterial();
	});

} // end function initPathTracingShaders()


// called automatically from within initPathTracingShaders() function above
function createPathTracingMaterial()
{

	fileLoader.load('shaders/Transforming_Quadric_Geometry_Showcase_Fragment.glsl', function (shaderText)
	{

		pathTracingFragmentShader = shaderText;

		pathTracingMaterial = new THREE.ShaderMaterial({
			uniforms: pathTracingUniforms,
			defines: pathTracingDefines,
			vertexShader: pathTracingVertexShader,
			fragmentShader: pathTracingFragmentShader,
			depthTest: false,
			depthWrite: false
		});

		pathTracingMesh = new THREE.Mesh(pathTracingGeometry, pathTracingMaterial);
		pathTracingScene.add(pathTracingMesh);

		// the following keeps the large scene ShaderMaterial quad right in front 
		//   of the camera at all times. This is necessary because without it, the scene 
		//   quad will fall out of view and get clipped when the camera rotates past 180 degrees.
		worldCamera.add(pathTracingMesh);

	});

} // end function createPathTracingMaterial()



// called automatically from within the animate() function
function updateVariablesAndUniforms()
{

	// ELLIPSOID TRANSLATE
	ellipsoidTranslateAngle += (0.1 * frameTime);
	ellipsoidTranslateAngle = ellipsoidTranslateAngle % TWO_PI;
	ellipsoidTranslate.position.x = (spacing * -3 + posXOffset) + (Math.cos(ellipsoidTranslateAngle) * 10);
	ellipsoidTranslate.position.z = baseZPos + (Math.sin(ellipsoidTranslateAngle) * 10);
	ellipsoidTranslate.updateMatrixWorld(true);
	pathTracingUniforms.uEllipsoidTranslateInvMatrix.value.copy(ellipsoidTranslate.matrixWorld).invert();

	// ELLIPSOID ROTATE
	ellipsoidRotateAngle += (1.0 * frameTime);
	ellipsoidRotateAngle = ellipsoidRotateAngle % TWO_PI;
	ellipsoidRotate.rotation.y = ellipsoidRotateAngle;
	ellipsoidRotate.updateMatrixWorld(true);
	pathTracingUniforms.uEllipsoidRotateInvMatrix.value.copy(ellipsoidRotate.matrixWorld).invert();

	// ELLIPSOID SCALE
	ellipsoidScaleAngle += (1.0 * frameTime);
	ellipsoidScaleAngle = ellipsoidScaleAngle % TWO_PI;
	ellipsoidScale.scale.set(Math.abs(Math.sin(ellipsoidScaleAngle)) * 20 + 0.1, Math.abs(Math.sin(ellipsoidScaleAngle)) * 20 + 0.01, Math.abs(Math.sin(ellipsoidScaleAngle)) * 20 + 0.01);
	ellipsoidScale.updateMatrixWorld(true);
	pathTracingUniforms.uEllipsoidScaleInvMatrix.value.copy(ellipsoidScale.matrixWorld).invert();

	// ELLIPSOID CLIP
	ellipsoidClip.updateMatrixWorld(true);
	pathTracingUniforms.uEllipsoidClipInvMatrix.value.copy(ellipsoidClip.matrixWorld).invert();


	// CYLINDER TRANSLATE
	cylinderTranslateAngle += (1.0 * frameTime);
	cylinderTranslateAngle = cylinderTranslateAngle % TWO_PI;
	cylinderTranslate.position.y = baseYPos + (Math.sin(cylinderTranslateAngle) * 10);
	cylinderTranslate.updateMatrixWorld(true);
	pathTracingUniforms.uCylinderTranslateInvMatrix.value.copy(cylinderTranslate.matrixWorld).invert();

	// CYLINDER ROTATE
	cylinderRotateAngle += (1.0 * frameTime);
	cylinderRotateAngle = cylinderRotateAngle % TWO_PI;
	cylinderRotate.rotation.x = cylinderRotateAngle;
	cylinderRotate.updateMatrixWorld(true);
	pathTracingUniforms.uCylinderRotateInvMatrix.value.copy(cylinderRotate.matrixWorld).invert();

	// CYLINDER SCALE
	cylinderScaleAngle += (0.2 * frameTime);
	cylinderScaleAngle = cylinderScaleAngle % TWO_PI;
	if (cylinderScaleAngle == 0) cylinderScaleAngle += 0.01;
	cylinderScale.scale.set((1.0 - Math.abs(Math.sin(cylinderScaleAngle))) * 15 + 5,
		Math.abs(Math.sin(cylinderScaleAngle)) * 200 + 20,
		(1.0 - Math.abs(Math.sin(cylinderScaleAngle))) * 15 + 5);
	cylinderScale.updateMatrixWorld(true);
	pathTracingUniforms.uCylinderScaleInvMatrix.value.copy(cylinderScale.matrixWorld).invert();

	// CYLINDER CLIP
	cylinderClip.updateMatrixWorld(true);
	pathTracingUniforms.uCylinderClipInvMatrix.value.copy(cylinderClip.matrixWorld).invert();


	// CONE TRANSLATE
	coneTranslateAngle += (1.0 * frameTime);
	coneTranslateAngle = coneTranslateAngle % TWO_PI;
	coneTranslate.position.x = (spacing * -1 + posXOffset) + (Math.cos(coneTranslateAngle) * 10);
	coneTranslate.position.y = baseYPos + (Math.sin(coneTranslateAngle) * 10);
	coneTranslate.updateMatrixWorld(true);
	pathTracingUniforms.uConeTranslateInvMatrix.value.copy(coneTranslate.matrixWorld).invert();

	// CONE ROTATE
	coneRotateAngle += (1.0 * frameTime);
	coneRotateAngle = coneRotateAngle % TWO_PI;
	coneRotate.rotation.z = coneRotateAngle;
	coneRotate.updateMatrixWorld(true);
	pathTracingUniforms.uConeRotateInvMatrix.value.copy(coneRotate.matrixWorld).invert();

	// CONE SCALE
	coneScaleAngle += (1.0 * frameTime);
	coneScaleAngle = coneScaleAngle % TWO_PI;
	if (coneScaleAngle == 0) coneScaleAngle += 0.01;
	coneScale.scale.set(20, 20, Math.abs(Math.sin(coneScaleAngle)) * 20 + 0.1);
	coneScale.updateMatrixWorld(true);
	pathTracingUniforms.uConeScaleInvMatrix.value.copy(coneScale.matrixWorld).invert();

	// CONE CLIP
	coneClip.updateMatrixWorld(true);
	pathTracingUniforms.uConeClipInvMatrix.value.copy(coneClip.matrixWorld).invert();

	// PARABOLOID TRANSLATE
	paraboloidTranslateAngle += (1.0 * frameTime);
	paraboloidTranslateAngle = paraboloidTranslateAngle % TWO_PI;
	paraboloidTranslate.position.x = (spacing * 0 + posXOffset) + (Math.sin(paraboloidTranslateAngle) * 10);
	paraboloidTranslate.updateMatrixWorld(true);
	pathTracingUniforms.uParaboloidTranslateInvMatrix.value.copy(paraboloidTranslate.matrixWorld).invert();

	// PARABOLOID ROTATE
	paraboloidRotateAngle += (1.0 * frameTime);
	paraboloidRotateAngle = paraboloidRotateAngle % TWO_PI;
	paraboloidRotate.rotation.x = paraboloidRotateAngle;
	paraboloidRotate.rotation.z = paraboloidRotateAngle;
	paraboloidRotate.updateMatrixWorld(true);
	pathTracingUniforms.uParaboloidRotateInvMatrix.value.copy(paraboloidRotate.matrixWorld).invert();

	// PARABOLOID SCALE
	paraboloidScaleAngle += (1.0 * frameTime);
	paraboloidScaleAngle = paraboloidScaleAngle % TWO_PI;
	if (paraboloidScaleAngle == 0) paraboloidScaleAngle += 0.01;
	paraboloidScale.scale.set(20, Math.sin(paraboloidScaleAngle) * 20 + 0.1, 20);
	paraboloidScale.updateMatrixWorld(true);
	pathTracingUniforms.uParaboloidScaleInvMatrix.value.copy(paraboloidScale.matrixWorld).invert();

	// PARABOLOID CLIP
	paraboloidClip.updateMatrixWorld(true);
	pathTracingUniforms.uParaboloidClipInvMatrix.value.copy(paraboloidClip.matrixWorld).invert();


	// HYPERBOLOID TRANSLATE
	hyperboloidTranslateAngle += (1.0 * frameTime);
	hyperboloidTranslateAngle = hyperboloidTranslateAngle % TWO_PI;
	hyperboloidTranslate.position.z = baseZPos + (Math.sin(hyperboloidTranslateAngle) * 10);
	hyperboloidTranslate.updateMatrixWorld(true);
	pathTracingUniforms.uHyperboloidTranslateInvMatrix.value.copy(hyperboloidTranslate.matrixWorld).invert();

	// HYPERBOLOID ROTATE
	hyperboloidRotateAngle += (1.0 * frameTime);
	hyperboloidRotateAngle = hyperboloidRotateAngle % TWO_PI;
	hyperboloidRotate.rotation.z = -hyperboloidRotateAngle;
	hyperboloidRotate.updateMatrixWorld(true);
	pathTracingUniforms.uHyperboloidRotateInvMatrix.value.copy(hyperboloidRotate.matrixWorld).invert();

	// HYPERBOLOID SCALE
	hyperboloidScaleAngle += (1.0 * frameTime);
	hyperboloidScaleAngle = hyperboloidScaleAngle % TWO_PI;
	if (hyperboloidScaleAngle == 0) hyperboloidScaleAngle += 0.01;
	hyperboloidScale.scale.set(Math.abs(Math.sin(hyperboloidScaleAngle)) * 20 + 10, 20, 20);
	hyperboloidScale.updateMatrixWorld(true);
	pathTracingUniforms.uHyperboloidScaleInvMatrix.value.copy(hyperboloidScale.matrixWorld).invert();

	// HYPERBOLOID CLIP
	hyperboloidClip.updateMatrixWorld(true);
	pathTracingUniforms.uHyperboloidClipInvMatrix.value.copy(hyperboloidClip.matrixWorld).invert();

	// HYPERBOLIC PARABOLOID TRANSLATE
	hyperbolicParaboloidTranslateAngle += (1.0 * frameTime);
	hyperbolicParaboloidTranslateAngle = hyperbolicParaboloidTranslateAngle % TWO_PI;
	hyperbolicParaboloidTranslate.position.x = (spacing * 2 + posXOffset) + (Math.cos(hyperbolicParaboloidTranslateAngle) * 10);
	hyperbolicParaboloidTranslate.position.z = baseZPos + (Math.sin(hyperbolicParaboloidTranslateAngle) * 10);
	hyperbolicParaboloidTranslate.updateMatrixWorld(true);
	pathTracingUniforms.uHyperbolicParaboloidTranslateInvMatrix.value.copy(hyperbolicParaboloidTranslate.matrixWorld).invert();

	// HYPERBOLIC PARABOLOID ROTATE
	hyperbolicParaboloidRotateAngle += (1.0 * frameTime);
	hyperbolicParaboloidRotateAngle = hyperbolicParaboloidRotateAngle % TWO_PI;
	hyperbolicParaboloidRotate.rotation.y = -hyperbolicParaboloidRotateAngle;
	hyperbolicParaboloidRotate.updateMatrixWorld(true);
	pathTracingUniforms.uHyperbolicParaboloidRotateInvMatrix.value.copy(hyperbolicParaboloidRotate.matrixWorld).invert();

	// HYPERBOLIC PARABOLOID SCALE
	hyperbolicParaboloidScaleAngle += (1.0 * frameTime);
	hyperbolicParaboloidScaleAngle = hyperbolicParaboloidScaleAngle % TWO_PI;
	if (hyperbolicParaboloidScaleAngle == 0) hyperbolicParaboloidScaleAngle += 0.01;
	hyperbolicParaboloidScale.scale.set(20, Math.sin(hyperbolicParaboloidScaleAngle) * 20, 20);
	hyperbolicParaboloidScale.updateMatrixWorld(true);
	pathTracingUniforms.uHyperbolicParaboloidScaleInvMatrix.value.copy(hyperbolicParaboloidScale.matrixWorld).invert();

	// HYPERBOLIC PARABOLOID CLIP
	hyperbolicParaboloidClip.updateMatrixWorld(true);
	pathTracingUniforms.uHyperbolicParaboloidClipInvMatrix.value.copy(hyperbolicParaboloidClip.matrixWorld).invert();


	// INFO
	cameraInfoElement.innerHTML = "FOV: " + worldCamera.fov + " / Aperture: " + apertureSize.toFixed(2) + " / FocusDistance: " + focusDistance + "<br>" + "Samples: " + sampleCounter;

} // end function updateUniforms()



init(); // init app and start animating
