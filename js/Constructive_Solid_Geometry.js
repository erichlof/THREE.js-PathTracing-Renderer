// scene/demo-specific variables go here
let sceneIsDynamic = false;
let camFlightSpeed = 100;
let CSG_shapeA, CSG_shapeB;
let A_SkewMatrix = new THREE.Matrix4();
let B_SkewMatrix = new THREE.Matrix4();
let uniformScale = 1;

let gui;
let ableToEngagePointerLock = true;

let csgOperation_TypeController, csgOperation_TypeObject;

let transformA_Folder;
let positionA_Folder;
let scaleA_Folder;
let skewA_Folder;
let rotationA_Folder;
let transformA_PositionXController, transformA_PositionXObject;
let transformA_PositionYController, transformA_PositionYObject;
let transformA_PositionZController, transformA_PositionZObject;
let transformA_ScaleUniformController, transformA_ScaleUniformObject;
let transformA_ScaleXController, transformA_ScaleXObject;
let transformA_ScaleYController, transformA_ScaleYObject;
let transformA_ScaleZController, transformA_ScaleZObject;
let transformA_SkewX_YController, transformA_SkewX_YObject;
let transformA_SkewX_ZController, transformA_SkewX_ZObject;
let transformA_SkewY_XController, transformA_SkewY_XObject;
let transformA_SkewY_ZController, transformA_SkewY_ZObject;
let transformA_SkewZ_XController, transformA_SkewZ_XObject;
let transformA_SkewZ_YController, transformA_SkewZ_YObject;
let transformA_RotationXController, transformA_RotationXObject;
let transformA_RotationYController, transformA_RotationYObject;
let transformA_RotationZController, transformA_RotationZObject;
let shapeA_TypeController, shapeA_TypeObject;
let parameterA_kController, parameterA_kObject;
let materialA_TypeController, materialA_TypeObject;
let materialA_ColorController, materialA_ColorObject;
let needChangeAPosition = false;
let needChangeAScaleUniform = false;
let needChangeAScale = false;
let needChangeASkew = false;
let needChangeARotation = false;
let needChangeShapeAType = false;
let needChangeParameterAk = false;
let needChangeMaterialAType = false;
let needChangeMaterialAColor = false;
let currentAShapeType = '';

let transformB_Folder;
let positionB_Folder;
let scaleB_Folder;
let skewB_Folder;
let rotationB_Folder;
let transformB_PositionXController, transformB_PositionXObject;
let transformB_PositionYController, transformB_PositionYObject;
let transformB_PositionZController, transformB_PositionZObject;
let transformB_ScaleUniformController, transformB_ScaleUniformObject;
let transformB_ScaleXController, transformB_ScaleXObject;
let transformB_ScaleYController, transformB_ScaleYObject;
let transformB_ScaleZController, transformB_ScaleZObject;
let transformB_SkewX_YController, transformB_SkewX_YObject;
let transformB_SkewX_ZController, transformB_SkewX_ZObject;
let transformB_SkewY_XController, transformB_SkewY_XObject;
let transformB_SkewY_ZController, transformB_SkewY_ZObject;
let transformB_SkewZ_XController, transformB_SkewZ_XObject;
let transformB_SkewZ_YController, transformB_SkewZ_YObject;
let transformB_RotationXController, transformB_RotationXObject;
let transformB_RotationYController, transformB_RotationYObject;
let transformB_RotationZController, transformB_RotationZObject;
let shapeB_TypeController, shapeB_TypeObject;
let parameterB_kController, parameterB_kObject;
let materialB_TypeController, materialB_TypeObject;
let materialB_ColorController, materialB_ColorObject;
let needChangeBPosition = false;
let needChangeBScaleUniform = false;
let needChangeBScale = false;
let needChangeBSkew = false;
let needChangeBRotation = false;
let needChangeShapeBType = false;
let needChangeParameterBk = false;
let needChangeMaterialBType = false;
let needChangeMaterialBColor = false;
let currentBShapeType = '';

let needChangeOperationType = false;
let kValue = 0;


function init_GUI()
{
	csgOperation_TypeObject = {
		CSG_Operation: 'Union (A + B)'
	};

	// SHAPE A
	transformA_PositionXObject = {
		positionX: -12
	}
	transformA_PositionYObject = {
		positionY: -5
	}
	transformA_PositionZObject = {
		positionZ: -5
	}
	transformA_ScaleUniformObject = {
		uniformScale: 20
	}
	transformA_ScaleXObject = {
		scaleX: 20
	}
	transformA_ScaleYObject = {
		scaleY: 20
	}
	transformA_ScaleZObject = {
		scaleZ: 20
	}
	transformA_SkewX_YObject = {
		skewX_Y: 0
	}
	transformA_SkewX_ZObject = {
		skewX_Z: 0
	}
	transformA_SkewY_XObject = {
		skewY_X: 0
	}
	transformA_SkewY_ZObject = {
		skewY_Z: 0
	}
	transformA_SkewZ_XObject = {
		skewZ_X: 0
	}
	transformA_SkewZ_YObject = {
		skewZ_Y: 0
	}
	transformA_RotationXObject = {
		rotationX: 0
	}
	transformA_RotationYObject = {
		rotationY: 0
	}
	transformA_RotationZObject = {
		rotationZ: 0
	}
	shapeA_TypeObject = {
		A_Shape: 'Sphere'
	};
	parameterA_kObject = {
		A_kParameter: 2
	};
	materialA_TypeObject = {
		A_matType: 'Transparent Refractive'
	};
	materialA_ColorObject = {
		A_matColor: [0, 255, 0]
	};

	// SHAPE B
	transformB_PositionXObject = {
		positionX: 0
	}
	transformB_PositionYObject = {
		positionY: -5
	}
	transformB_PositionZObject = {
		positionZ: -10
	}
	transformB_ScaleUniformObject = {
		uniformScale: 17
	}
	transformB_ScaleXObject = {
		scaleX: 17
	}
	transformB_ScaleYObject = {
		scaleY: 17
	}
	transformB_ScaleZObject = {
		scaleZ: 17
	}
	transformB_SkewX_YObject = {
		skewX_Y: 0
	}
	transformB_SkewX_ZObject = {
		skewX_Z: 0
	}
	transformB_SkewY_XObject = {
		skewY_X: 0
	}
	transformB_SkewY_ZObject = {
		skewY_Z: 0
	}
	transformB_SkewZ_XObject = {
		skewZ_X: 0
	}
	transformB_SkewZ_YObject = {
		skewZ_Y: 0
	}
	transformB_RotationXObject = {
		rotationX: 0
	}
	transformB_RotationYObject = {
		rotationY: 0
	}
	transformB_RotationZObject = {
		rotationZ: 0
	}
	shapeB_TypeObject = {
		B_Shape: 'Box'
	};
	parameterB_kObject = {
		B_kParameter: 2
	};
	materialB_TypeObject = {
		B_matType: 'ClearCoat Diffuse'
	};
	materialB_ColorObject = {
		B_matColor: [255, 0, 255]
	};

	function handleOperationTypeChange()
	{
		needChangeOperationType = true;
	}

	function handleAPositionChange()
	{
		needChangeAPosition = true;
	}
	function handleAScaleUniformChange()
	{
		needChangeAScaleUniform = true;
	}
	function handleAScaleChange()
	{
		needChangeAScale = true;
	}
	function handleASkewChange()
	{
		needChangeASkew = true;
	}
	function handleARotationChange()
	{
		needChangeARotation = true;
	}
	function handleShapeATypeChange()
	{
		needChangeShapeAType = true;
	}
	function handleAParameterKChange()
	{
		needChangeParameterAk = true;
	}
	function handleMaterialATypeChange()
	{
		needChangeMaterialAType = true;
	}
	function handleMaterialAColorChange()
	{
		needChangeMaterialAColor = true;
	}

	function handleBPositionChange()
	{
		needChangeBPosition = true;
	}
	function handleBScaleUniformChange()
	{
		needChangeBScaleUniform = true;
	}
	function handleBScaleChange()
	{
		needChangeBScale = true;
	}
	function handleBSkewChange()
	{
		needChangeBSkew = true;
	}
	function handleBRotationChange()
	{
		needChangeBRotation = true;
	}
	function handleShapeBTypeChange()
	{
		needChangeShapeBType = true;
	}
	function handleBParameterKChange()
	{
		needChangeParameterBk = true;
	}
	function handleMaterialBTypeChange()
	{
		needChangeMaterialBType = true;
	}
	function handleMaterialBColorChange()
	{
		needChangeMaterialBColor = true;
	}
	gui = new dat.GUI();

	csgOperation_TypeController = gui.add(csgOperation_TypeObject, 'CSG_Operation', ['Union (A + B)', 'Difference (A - B)',
		'Intersection (A ^ B)']).onChange(handleOperationTypeChange);

	transformA_Folder = gui.addFolder('A_Transform');

	positionA_Folder = transformA_Folder.addFolder('A_Position');
	transformA_PositionXController = positionA_Folder.add(transformA_PositionXObject, 'positionX', -50, 50, 1).onChange(handleAPositionChange);
	transformA_PositionYController = positionA_Folder.add(transformA_PositionYObject, 'positionY', -50, 50, 1).onChange(handleAPositionChange);
	transformA_PositionZController = positionA_Folder.add(transformA_PositionZObject, 'positionZ', -50, 50, 1).onChange(handleAPositionChange);

	scaleA_Folder = transformA_Folder.addFolder('A_Scale');
	transformA_ScaleUniformController = scaleA_Folder.add(transformA_ScaleUniformObject, 'uniformScale', 1, 50, 1).onChange(handleAScaleUniformChange);
	transformA_ScaleXController = scaleA_Folder.add(transformA_ScaleXObject, 'scaleX', 1, 50, 1).onChange(handleAScaleChange);
	transformA_ScaleYController = scaleA_Folder.add(transformA_ScaleYObject, 'scaleY', 1, 50, 1).onChange(handleAScaleChange);
	transformA_ScaleZController = scaleA_Folder.add(transformA_ScaleZObject, 'scaleZ', 1, 50, 1).onChange(handleAScaleChange);

	skewA_Folder = transformA_Folder.addFolder('A_Skew');
	transformA_SkewX_YController = skewA_Folder.add(transformA_SkewX_YObject, 'skewX_Y', -0.9, 0.9, 0.1).onChange(handleASkewChange);
	transformA_SkewX_ZController = skewA_Folder.add(transformA_SkewX_ZObject, 'skewX_Z', -0.9, 0.9, 0.1).onChange(handleASkewChange);
	transformA_SkewY_XController = skewA_Folder.add(transformA_SkewY_XObject, 'skewY_X', -0.9, 0.9, 0.1).onChange(handleASkewChange);
	transformA_SkewY_ZController = skewA_Folder.add(transformA_SkewY_ZObject, 'skewY_Z', -0.9, 0.9, 0.1).onChange(handleASkewChange);
	transformA_SkewZ_XController = skewA_Folder.add(transformA_SkewZ_XObject, 'skewZ_X', -0.9, 0.9, 0.1).onChange(handleASkewChange);
	transformA_SkewZ_YController = skewA_Folder.add(transformA_SkewZ_YObject, 'skewZ_Y', -0.9, 0.9, 0.1).onChange(handleASkewChange);

	rotationA_Folder = transformA_Folder.addFolder('A_Rotation');
	transformA_RotationXController = rotationA_Folder.add(transformA_RotationXObject, 'rotationX', 0, 359, 1).onChange(handleARotationChange);
	transformA_RotationYController = rotationA_Folder.add(transformA_RotationYObject, 'rotationY', 0, 359, 1).onChange(handleARotationChange);
	transformA_RotationZController = rotationA_Folder.add(transformA_RotationZObject, 'rotationZ', 0, 359, 1).onChange(handleARotationChange);

	shapeA_TypeController = gui.add(shapeA_TypeObject, 'A_Shape', ['Sphere', 'Cylinder', 'Cone', 'Paraboloid', 'Hyperboloid_1Sheet', 'Hyperboloid_2Sheets',
		'Capsule', 'Box', 'Pyramid_Frustum', 'ConicalPrism', 'ParabolicPrism', 'HyperbolicPrism_1Sheet', 'HyperbolicPrism_2Sheets']).onChange(handleShapeATypeChange);

	parameterA_kController = gui.add(parameterA_kObject, 'A_kParameter', 0, 100, 0.5).onChange(handleAParameterKChange);

	materialA_TypeController = gui.add(materialA_TypeObject, 'A_matType', ['Diffuse', 'Transparent Refractive',
		'Metal', 'ClearCoat Diffuse']).onChange(handleMaterialATypeChange);

	materialA_ColorController = gui.addColor(materialA_ColorObject, 'A_matColor').onChange(handleMaterialAColorChange);


	transformB_Folder = gui.addFolder('B_Transform');

	positionB_Folder = transformB_Folder.addFolder('B_Position');
	transformB_PositionXController = positionB_Folder.add(transformB_PositionXObject, 'positionX', -50, 50, 1).onChange(handleBPositionChange);
	transformB_PositionYController = positionB_Folder.add(transformB_PositionYObject, 'positionY', -50, 50, 1).onChange(handleBPositionChange);
	transformB_PositionZController = positionB_Folder.add(transformB_PositionZObject, 'positionZ', -50, 50, 1).onChange(handleBPositionChange);

	scaleB_Folder = transformB_Folder.addFolder('B_Scale');
	transformB_ScaleUniformController = scaleB_Folder.add(transformB_ScaleUniformObject, 'uniformScale', 1, 50, 1).onChange(handleBScaleUniformChange);
	transformB_ScaleXController = scaleB_Folder.add(transformB_ScaleXObject, 'scaleX', 1, 50, 1).onChange(handleBScaleChange);
	transformB_ScaleYController = scaleB_Folder.add(transformB_ScaleYObject, 'scaleY', 1, 50, 1).onChange(handleBScaleChange);
	transformB_ScaleZController = scaleB_Folder.add(transformB_ScaleZObject, 'scaleZ', 1, 50, 1).onChange(handleBScaleChange);

	skewB_Folder = transformB_Folder.addFolder('B_Skew');
	transformB_SkewX_YController = skewB_Folder.add(transformB_SkewX_YObject, 'skewX_Y', -0.9, 0.9, 0.1).onChange(handleBSkewChange);
	transformB_SkewX_ZController = skewB_Folder.add(transformB_SkewX_ZObject, 'skewX_Z', -0.9, 0.9, 0.1).onChange(handleBSkewChange);
	transformB_SkewY_XController = skewB_Folder.add(transformB_SkewY_XObject, 'skewY_X', -0.9, 0.9, 0.1).onChange(handleBSkewChange);
	transformB_SkewY_ZController = skewB_Folder.add(transformB_SkewY_ZObject, 'skewY_Z', -0.9, 0.9, 0.1).onChange(handleBSkewChange);
	transformB_SkewZ_XController = skewB_Folder.add(transformB_SkewZ_XObject, 'skewZ_X', -0.9, 0.9, 0.1).onChange(handleBSkewChange);
	transformB_SkewZ_YController = skewB_Folder.add(transformB_SkewZ_YObject, 'skewZ_Y', -0.9, 0.9, 0.1).onChange(handleBSkewChange);

	rotationB_Folder = transformB_Folder.addFolder('B_Rotation');
	transformB_RotationXController = rotationB_Folder.add(transformB_RotationXObject, 'rotationX', 0, 359, 1).onChange(handleBRotationChange);
	transformB_RotationYController = rotationB_Folder.add(transformB_RotationYObject, 'rotationY', 0, 359, 1).onChange(handleBRotationChange);
	transformB_RotationZController = rotationB_Folder.add(transformB_RotationZObject, 'rotationZ', 0, 359, 1).onChange(handleBRotationChange);

	shapeB_TypeController = gui.add(shapeB_TypeObject, 'B_Shape', ['Sphere', 'Cylinder', 'Cone', 'Paraboloid', 'Hyperboloid_1Sheet', 'Hyperboloid_2Sheets',
		'Capsule', 'Box', 'Pyramid_Frustum', 'ConicalPrism', 'ParabolicPrism', 'HyperbolicPrism_1Sheet', 'HyperbolicPrism_2Sheets']).onChange(handleShapeBTypeChange);

	parameterB_kController = gui.add(parameterB_kObject, 'B_kParameter', 0, 100, 0.5).onChange(handleBParameterKChange);

	materialB_TypeController = gui.add(materialB_TypeObject, 'B_matType', ['Diffuse', 'Transparent Refractive',
		'Metal', 'ClearCoat Diffuse']).onChange(handleMaterialBTypeChange);

	materialB_ColorController = gui.addColor(materialB_ColorObject, 'B_matColor').onChange(handleMaterialBColorChange);


	// jumpstart all the gui change controller handlers so that the pathtracing fragment shader uniforms are correct and up-to-date
	handleOperationTypeChange();
	handleAPositionChange();
	handleAScaleUniformChange();
	handleAScaleChange();
	handleASkewChange();
	handleARotationChange();
	handleShapeATypeChange();
	handleAParameterKChange();
	handleMaterialATypeChange();
	handleMaterialAColorChange();
	handleBPositionChange();
	handleBScaleUniformChange();
	handleBScaleChange();
	handleBSkewChange();
	handleBRotationChange();
	handleShapeBTypeChange();
	handleBParameterKChange();
	handleMaterialBTypeChange();
	handleMaterialBColorChange();

	gui.domElement.style.webkitUserSelect = "none";
	gui.domElement.style.MozUserSelect = "none";

	window.addEventListener('resize', onWindowResize, false);

	if ('ontouchstart' in window)
	{
		mouseControl = false;
		// if on mobile device, unpause the app because there is no ESC key and no mouse capture to do
		isPaused = false;

		ableToEngagePointerLock = true;

		mobileJoystickControls = new MobileJoystickControls({
			//showJoystick: true
		});
	}

	if (mouseControl)
	{

		window.addEventListener('wheel', onMouseWheel, false);

		window.addEventListener("click", function (event)
		{
			event.preventDefault();
		}, false);
		window.addEventListener("dblclick", function (event)
		{
			event.preventDefault();
		}, false);

		document.body.addEventListener("click", function (event)
		{
			if (!ableToEngagePointerLock)
				return;
			this.requestPointerLock = this.requestPointerLock || this.mozRequestPointerLock;
			this.requestPointerLock();
		}, false);


		pointerlockChange = function (event)
		{
			if (document.pointerLockElement === document.body ||
				document.mozPointerLockElement === document.body || document.webkitPointerLockElement === document.body)
			{
				document.addEventListener('keydown', onKeyDown, false);
				document.addEventListener('keyup', onKeyUp, false);
				isPaused = false;
			}
			else
			{
				document.removeEventListener('keydown', onKeyDown, false);
				document.removeEventListener('keyup', onKeyUp, false);
				isPaused = true;
			}
		};

		// Hook pointer lock state change events
		document.addEventListener('pointerlockchange', pointerlockChange, false);
		document.addEventListener('mozpointerlockchange', pointerlockChange, false);
		document.addEventListener('webkitpointerlockchange', pointerlockChange, false);

	}

	if (mouseControl)
	{
		gui.domElement.addEventListener("mouseenter", function (event)
		{
			ableToEngagePointerLock = false;
		}, false);
		gui.domElement.addEventListener("mouseleave", function (event)
		{
			ableToEngagePointerLock = true;
		}, false);
	}

	initTHREEjs(); // boilerplate: init necessary three.js items and scene/demo-specific objects

} // end function init_GUI()



// called automatically from within initTHREEjs() function
function initSceneData()
{

	// scene/demo-specific three.js objects setup goes here
	EPS_intersect = mouseControl ? 0.01 : 1.0; // less precision on mobile

	// set camera's field of view
	worldCamera.fov = 60;
	focusDistance = 100.0;

	// position and orient camera
	cameraControlsObject.position.set(0, 4, 100);
	///cameraControlsYawObject.rotation.y = 0.0;
	// look slightly up or down
	//cameraControlsPitchObject.rotation.x = 0.0;


	CSG_shapeA = new THREE.Object3D();
	CSG_shapeB = new THREE.Object3D();

	pathTracingScene.add(CSG_shapeA);
	pathTracingScene.add(CSG_shapeB);

} // end function initSceneData()



// called automatically from within initTHREEjs() function
function initPathTracingShaders()
{

	// scene/demo-specific uniforms go here
	pathTracingUniforms.uCSG_OperationType = { type: "i", value: 0 };
	pathTracingUniforms.uShapeAType = { type: "i", value: 0 };
	pathTracingUniforms.uMaterialAType = { type: "i", value: 4 };
	pathTracingUniforms.uShapeBType = { type: "i", value: 0 };
	pathTracingUniforms.uMaterialBType = { type: "i", value: 1 };
	pathTracingUniforms.uA_kParameter = { type: "f", value: 2.0 };
	pathTracingUniforms.uB_kParameter = { type: "f", value: 2.0 };
	pathTracingUniforms.uMaterialAColor = { type: "v3", value: new THREE.Color(1.0, 1.0, 0.0) };
	pathTracingUniforms.uMaterialBColor = { type: "v3", value: new THREE.Color(1.0, 0.0, 1.0) };
	pathTracingUniforms.uCSG_ShapeA_InvMatrix = { type: "m4", value: new THREE.Matrix4() };
	pathTracingUniforms.uCSG_ShapeB_InvMatrix = { type: "m4", value: new THREE.Matrix4() };

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

	fileLoader.load('shaders/Constructive_Solid_Geometry_Fragment.glsl', function (shaderText)
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

	if (needChangeOperationType)
	{
		if (csgOperation_TypeController.getValue() == 'Union (A + B)')
		{
			pathTracingUniforms.uCSG_OperationType.value = 0;
		}
		else if (csgOperation_TypeController.getValue() == 'Difference (A - B)')
		{
			pathTracingUniforms.uCSG_OperationType.value = 1;
		}
		else if (csgOperation_TypeController.getValue() == 'Intersection (A ^ B)')
		{
			pathTracingUniforms.uCSG_OperationType.value = 2;
		}

		cameraIsMoving = true;
		needChangeOperationType = false;
	}

	// SHAPE A
	if (needChangeAPosition)
	{
		CSG_shapeA.position.set(transformA_PositionXController.getValue(),
			transformA_PositionYController.getValue(),
			transformA_PositionZController.getValue());

		cameraIsMoving = true;
		needChangeAPosition = false;
	}

	if (needChangeAScaleUniform)
	{
		uniformScale = transformA_ScaleUniformController.getValue();
		CSG_shapeA.scale.set(uniformScale, uniformScale, uniformScale);

		transformA_ScaleXController.setValue(uniformScale);
		transformA_ScaleYController.setValue(uniformScale);
		transformA_ScaleZController.setValue(uniformScale);

		cameraIsMoving = true;
		needChangeAScaleUniform = false;
	}

	if (needChangeAScale)
	{
		CSG_shapeA.scale.set(transformA_ScaleXController.getValue(),
			transformA_ScaleYController.getValue(),
			transformA_ScaleZController.getValue());

		cameraIsMoving = true;
		needChangeAScale = false;
	}

	if (needChangeASkew)
	{
		A_SkewMatrix.set(
			1, transformA_SkewX_YController.getValue(), transformA_SkewX_ZController.getValue(), 0,
			transformA_SkewY_XController.getValue(), 1, transformA_SkewY_ZController.getValue(), 0,
			transformA_SkewZ_XController.getValue(), transformA_SkewZ_YController.getValue(), 1, 0,
			0, 0, 0, 1
		);

		cameraIsMoving = true;
		needChangeASkew = false;
	}

	if (needChangeARotation)
	{
		CSG_shapeA.rotation.set(THREE.MathUtils.degToRad(transformA_RotationXController.getValue()),
			THREE.MathUtils.degToRad(transformA_RotationYController.getValue()),
			THREE.MathUtils.degToRad(transformA_RotationZController.getValue()));

		cameraIsMoving = true;
		needChangeARotation = false;
	}

	if (needChangeShapeAType)
	{
		currentAShapeType = shapeA_TypeController.getValue();

		if (currentAShapeType == 'Sphere')
		{
			pathTracingUniforms.uShapeAType.value = 0;
			parameterA_kController.domElement.hidden = true;
		}
		else if (currentAShapeType == 'Cylinder')
		{
			pathTracingUniforms.uShapeAType.value = 1;
			parameterA_kController.domElement.hidden = true;
		}
		else if (currentAShapeType == 'Cone')
		{
			pathTracingUniforms.uShapeAType.value = 2;
			parameterA_kController.domElement.hidden = false;
			parameterA_kController.min(0.0);
			parameterA_kController.max(1.0);
			parameterA_kController.step(0.01);
			parameterA_kController.setValue(1.0);
		}
		else if (currentAShapeType == 'Paraboloid')
		{
			pathTracingUniforms.uShapeAType.value = 3;
			parameterA_kController.domElement.hidden = true;
		}
		else if (currentAShapeType == 'Hyperboloid_1Sheet')
		{
			pathTracingUniforms.uShapeAType.value = 4;
			parameterA_kController.domElement.hidden = false;
			parameterA_kController.min(1);
			parameterA_kController.max(100);
			parameterA_kController.step(0.5);
			parameterA_kController.setValue(2);
		}
		else if (currentAShapeType == 'Hyperboloid_2Sheets')
		{
			pathTracingUniforms.uShapeAType.value = 5;
			parameterA_kController.domElement.hidden = false;
			parameterA_kController.min(1);
			parameterA_kController.max(100);
			parameterA_kController.step(0.5);
			parameterA_kController.setValue(10);
		}
		else if (currentAShapeType == 'Capsule')
		{
			pathTracingUniforms.uShapeAType.value = 6;
			parameterA_kController.domElement.hidden = false;
			parameterA_kController.min(0.1);
			parameterA_kController.max(5.0);
			parameterA_kController.step(0.1);
			parameterA_kController.setValue(0.5);
		}
		else if (currentAShapeType == 'Box')
		{
			pathTracingUniforms.uShapeAType.value = 7;
			parameterA_kController.domElement.hidden = true;
		}
		else if (currentAShapeType == 'Pyramid_Frustum')
		{
			pathTracingUniforms.uShapeAType.value = 8;
			parameterA_kController.domElement.hidden = false;
			parameterA_kController.min(0.0);
			parameterA_kController.max(1.0);
			parameterA_kController.step(0.01);
			parameterA_kController.setValue(1.0);
		}
		else if (currentAShapeType == 'ConicalPrism')
		{
			pathTracingUniforms.uShapeAType.value = 9;
			parameterA_kController.domElement.hidden = false;
			parameterA_kController.min(0.0);
			parameterA_kController.max(1.0);
			parameterA_kController.step(0.01);
			parameterA_kController.setValue(1.0);
		}
		else if (currentAShapeType == 'ParabolicPrism')
		{
			pathTracingUniforms.uShapeAType.value = 10;
			parameterA_kController.domElement.hidden = true;
		}
		else if (currentAShapeType == 'HyperbolicPrism_1Sheet')
		{
			pathTracingUniforms.uShapeAType.value = 11;
			parameterA_kController.domElement.hidden = false;
			parameterA_kController.min(1);
			parameterA_kController.max(100);
			parameterA_kController.step(0.5);
			parameterA_kController.setValue(2);
		}
		else if (currentAShapeType == 'HyperbolicPrism_2Sheets')
		{
			pathTracingUniforms.uShapeAType.value = 12;
			parameterA_kController.domElement.hidden = false;
			parameterA_kController.min(1);
			parameterA_kController.max(100);
			parameterA_kController.step(0.5);
			parameterA_kController.setValue(10);
		}

		cameraIsMoving = true;
		needChangeShapeAType = false;
	}

	if (needChangeParameterAk)
	{
		kValue = parameterA_kController.getValue();
		if (kValue > parameterA_kController.__max)
		{
			kValue = parameterA_kController.__max;
			parameterA_kController.setValue(kValue);
		}
			
		if (kValue < parameterA_kController.__min)
		{
			kValue = parameterA_kController.__min;
			parameterA_kController.setValue(kValue);
		}

		pathTracingUniforms.uA_kParameter.value = kValue;
		
		cameraIsMoving = true;
		needChangeParameterAk = false;
	}

	if (needChangeMaterialAType)
	{
		if (materialA_TypeController.getValue() == 'Diffuse')
		{
			pathTracingUniforms.uMaterialAType.value = 1;
		}
		else if (materialA_TypeController.getValue() == 'Transparent Refractive')
		{
			pathTracingUniforms.uMaterialAType.value = 2;
		}
		else if (materialA_TypeController.getValue() == 'Metal')
		{
			pathTracingUniforms.uMaterialAType.value = 3;
		}
		else if (materialA_TypeController.getValue() == 'ClearCoat Diffuse')
		{
			pathTracingUniforms.uMaterialAType.value = 4;
		}

		cameraIsMoving = true;
		needChangeMaterialAType = false;
	}

	if (needChangeMaterialAColor)
	{
		pathTracingUniforms.uMaterialAColor.value.setRGB(materialA_ColorController.getValue()[0] / 255,
			materialA_ColorController.getValue()[1] / 255,
			materialA_ColorController.getValue()[2] / 255);

		cameraIsMoving = true;
		needChangeMaterialAColor = false;
	}


	// SHAPE B
	if (needChangeBPosition)
	{
		CSG_shapeB.position.set(transformB_PositionXController.getValue(),
			transformB_PositionYController.getValue(),
			transformB_PositionZController.getValue());

		cameraIsMoving = true;
		needChangeBPosition = false;
	}

	if (needChangeBScaleUniform)
	{
		uniformScale = transformB_ScaleUniformController.getValue();
		CSG_shapeB.scale.set(uniformScale, uniformScale, uniformScale);

		transformB_ScaleXController.setValue(uniformScale);
		transformB_ScaleYController.setValue(uniformScale);
		transformB_ScaleZController.setValue(uniformScale);

		cameraIsMoving = true;
		needChangeBScaleUniform = false;
	}

	if (needChangeBScale)
	{
		CSG_shapeB.scale.set(transformB_ScaleXController.getValue(),
			transformB_ScaleYController.getValue(),
			transformB_ScaleZController.getValue());

		cameraIsMoving = true;
		needChangeBScale = false;
	}

	if (needChangeBSkew)
	{
		B_SkewMatrix.set(
			1, transformB_SkewX_YController.getValue(), transformB_SkewX_ZController.getValue(), 0,
			transformB_SkewY_XController.getValue(), 1, transformB_SkewY_ZController.getValue(), 0,
			transformB_SkewZ_XController.getValue(), transformB_SkewZ_YController.getValue(), 1, 0,
			0, 0, 0, 1
		);

		cameraIsMoving = true;
		needChangeBSkew = false;
	}

	if (needChangeBRotation)
	{
		CSG_shapeB.rotation.set(THREE.MathUtils.degToRad(transformB_RotationXController.getValue()),
			THREE.MathUtils.degToRad(transformB_RotationYController.getValue()),
			THREE.MathUtils.degToRad(transformB_RotationZController.getValue()));

		cameraIsMoving = true;
		needChangeBRotation = false;
	}

	if (needChangeShapeBType)
	{
		currentBShapeType = shapeB_TypeController.getValue();

		if (currentBShapeType == 'Sphere')
		{
			pathTracingUniforms.uShapeBType.value = 0;
			parameterB_kController.domElement.hidden = true;
		}
		else if (currentBShapeType == 'Cylinder')
		{
			pathTracingUniforms.uShapeBType.value = 1;
			parameterB_kController.domElement.hidden = true;
		}
		else if (currentBShapeType == 'Cone')
		{
			pathTracingUniforms.uShapeBType.value = 2;
			parameterB_kController.domElement.hidden = false;
			parameterB_kController.min(0.0);
			parameterB_kController.max(1.0);
			parameterB_kController.step(0.01);
			parameterB_kController.setValue(1.0);
		}
		else if (currentBShapeType == 'Paraboloid')
		{
			pathTracingUniforms.uShapeBType.value = 3;
			parameterB_kController.domElement.hidden = true;
		}
		else if (currentBShapeType == 'Hyperboloid_1Sheet')
		{
			pathTracingUniforms.uShapeBType.value = 4;
			parameterB_kController.domElement.hidden = false;
			parameterB_kController.min(1);
			parameterB_kController.max(100);
			parameterB_kController.step(0.5);
			parameterB_kController.setValue(2);
		}
		else if (currentBShapeType == 'Hyperboloid_2Sheets')
		{
			pathTracingUniforms.uShapeBType.value = 5;
			parameterB_kController.domElement.hidden = false;
			parameterB_kController.min(1);
			parameterB_kController.max(100);
			parameterB_kController.step(0.5);
			parameterB_kController.setValue(10);
		}
		else if (currentBShapeType == 'Capsule')
		{
			pathTracingUniforms.uShapeBType.value = 6;
			parameterB_kController.domElement.hidden = false;
			parameterB_kController.min(0.1);
			parameterB_kController.max(5.0);
			parameterB_kController.step(0.1);
			parameterB_kController.setValue(0.5);
		}
		else if (currentBShapeType == 'Box')
		{
			pathTracingUniforms.uShapeBType.value = 7;
			parameterB_kController.domElement.hidden = true;
		}
		else if (currentBShapeType == 'Pyramid_Frustum')
		{
			pathTracingUniforms.uShapeBType.value = 8;
			parameterB_kController.domElement.hidden = false;
			parameterB_kController.min(0.0);
			parameterB_kController.max(1.0);
			parameterB_kController.step(0.01);
			parameterB_kController.setValue(1.0);
		}
		else if (currentBShapeType == 'ConicalPrism')
		{
			pathTracingUniforms.uShapeBType.value = 9;
			parameterB_kController.domElement.hidden = false;
			parameterB_kController.min(0.0);
			parameterB_kController.max(1.0);
			parameterB_kController.step(0.01);
			parameterB_kController.setValue(1.0);
		}
		else if (currentBShapeType == 'ParabolicPrism')
		{
			pathTracingUniforms.uShapeBType.value = 10;
			parameterB_kController.domElement.hidden = true;
		}
		else if (currentBShapeType == 'HyperbolicPrism_1Sheet')
		{
			pathTracingUniforms.uShapeBType.value = 11;
			parameterB_kController.domElement.hidden = false;
			parameterB_kController.min(1);
			parameterB_kController.max(100);
			parameterB_kController.step(0.5);
			parameterB_kController.setValue(2);
		}
		else if (currentBShapeType == 'HyperbolicPrism_2Sheets')
		{
			pathTracingUniforms.uShapeBType.value = 12;
			parameterB_kController.domElement.hidden = false;
			parameterB_kController.min(1);
			parameterB_kController.max(100);
			parameterB_kController.step(0.5);
			parameterB_kController.setValue(10);
		}

		cameraIsMoving = true;
		needChangeShapeBType = false;
	}

	if (needChangeParameterBk)
	{
		kValue = parameterB_kController.getValue();
		if (kValue > parameterB_kController.__max)
		{
			kValue = parameterB_kController.__max;
			parameterB_kController.setValue(kValue);
		}

		if (kValue < parameterB_kController.__min)
		{
			kValue = parameterB_kController.__min;
			parameterB_kController.setValue(kValue);
		}

		pathTracingUniforms.uB_kParameter.value = kValue;

		cameraIsMoving = true;
		needChangeParameterBk = false;
	}

	if (needChangeMaterialBType)
	{
		if (materialB_TypeController.getValue() == 'Diffuse')
		{
			pathTracingUniforms.uMaterialBType.value = 1;
		}
		else if (materialB_TypeController.getValue() == 'Transparent Refractive')
		{
			pathTracingUniforms.uMaterialBType.value = 2;
		}
		else if (materialB_TypeController.getValue() == 'Metal')
		{
			pathTracingUniforms.uMaterialBType.value = 3;
		}
		else if (materialB_TypeController.getValue() == 'ClearCoat Diffuse')
		{
			pathTracingUniforms.uMaterialBType.value = 4;
		}

		cameraIsMoving = true;
		needChangeMaterialBType = false;
	}

	if (needChangeMaterialBColor)
	{
		pathTracingUniforms.uMaterialBColor.value.setRGB(materialB_ColorController.getValue()[0] / 255,
			materialB_ColorController.getValue()[1] / 255,
			materialB_ColorController.getValue()[2] / 255);

		cameraIsMoving = true;
		needChangeMaterialBColor = false;
	}

	
	CSG_shapeA.matrixWorld.multiply(A_SkewMatrix); // multiply shapeA's matrix by my custom skew(shear) matrix4
	
	pathTracingUniforms.uCSG_ShapeA_InvMatrix.value.copy(CSG_shapeA.matrixWorld).invert();
	

	CSG_shapeB.matrixWorld.multiply(B_SkewMatrix); // multiply shapeB's matrix by my custom skew(shear) matrix4
	
	pathTracingUniforms.uCSG_ShapeB_InvMatrix.value.copy(CSG_shapeB.matrixWorld).invert();
	
	
	// INFO
	cameraInfoElement.innerHTML = "FOV: " + worldCamera.fov + " / Aperture: " + apertureSize.toFixed(2) + " / FocusDistance: " + focusDistance + "<br>" + "Samples: " + sampleCounter;

} // end function updateVariablesAndUniforms()



init_GUI(); // first init GUI, then init app and start animating
