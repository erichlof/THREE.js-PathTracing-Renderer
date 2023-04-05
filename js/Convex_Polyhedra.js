// scene/demo-specific variables go here

let skewMatrix = new THREE.Matrix4();
let uniformScale = 1;

let transform_Folder;
let position_Folder;
let scale_Folder;
let skew_Folder;
let rotation_Folder;
let transform_PositionXController, transform_PositionXObject;
let transform_PositionYController, transform_PositionYObject;
let transform_PositionZController, transform_PositionZObject;
let transform_ScaleUniformController, transform_ScaleUniformObject;
let transform_ScaleXController, transform_ScaleXObject;
let transform_ScaleYController, transform_ScaleYObject;
let transform_ScaleZController, transform_ScaleZObject;
let transform_RotationXController, transform_RotationXObject;
let transform_RotationYController, transform_RotationYObject;
let transform_RotationZController, transform_RotationZObject;
let transform_SkewX_YController, transform_SkewX_YObject;
let transform_SkewX_ZController, transform_SkewX_ZObject;
let transform_SkewY_XController, transform_SkewY_XObject;
let transform_SkewY_ZController, transform_SkewY_ZObject;
let transform_SkewZ_XController, transform_SkewZ_XObject;
let transform_SkewZ_YController, transform_SkewZ_YObject;

let needChangePosition = false;
let needChangeScaleUniform = false;
let needChangeScale = false;
let needChangeSkew = false;
let needChangeRotation = false;

let material_TypeObject, material_TypeController;
let material_ColorObject, material_ColorController;
let material_RoughnessObject, material_RoughnessController;
let needChangeMaterialType = false;
let needChangeMaterialColor = false;
let needChangeMaterialRoughness = false;
let matType = 0;
let matColor;

let wallRadius = 50;
let shapeRadius = 10;
let convexPolyhedron;


// called automatically from within initTHREEjs() function (located in InitCommon.js file)
function initSceneData() 
{
	demoFragmentShaderFileName = 'Convex_Polyhedra_Fragment.glsl';

	// scene/demo-specific three.js objects setup goes here
	sceneIsDynamic = false;

	cameraFlightSpeed = 100;

	// pixelRatio is resolution - range: 0.5(half resolution) to 1.0(full resolution)
	pixelRatio = mouseControl ? 1.0 : 0.75; // less demanding on battery-powered mobile devices
	
	EPS_intersect = 0.01;

	// set camera's field of view
	worldCamera.fov = 50;
	focusDistance = 120.0;
	apertureChangeSpeed = 5;

	// position and orient camera
	cameraControlsObject.position.set(-32, 12, 116);

	// look right
	cameraControlsYawObject.rotation.y = -0.2436;
	// look downward
	cameraControlsPitchObject.rotation.x = -0.29;

	// CONVEX POLYHEDRA
	convexPolyhedron = new THREE.Object3D();
	convexPolyhedron.position.set(25, -wallRadius + shapeRadius + 5, 0);
	convexPolyhedron.scale.set(16, 16, 16);
	pathTracingScene.add(convexPolyhedron);

	// In addition to the default GUI on all demos, add any special GUI elements that this particular demo requires

	transform_PositionXObject = { positionX: 0 };
	transform_PositionYObject = { positionY: -wallRadius + shapeRadius + 5 };
	transform_PositionZObject = { positionZ: 0 };
	transform_ScaleUniformObject = { uniformScale: shapeRadius };
	transform_ScaleXObject = { scaleX: shapeRadius };
	transform_ScaleYObject = { scaleY: shapeRadius };
	transform_ScaleZObject = { scaleZ: shapeRadius };
	transform_RotationXObject = { rotationX: 0 };
	transform_RotationYObject = { rotationY: 0 };
	transform_RotationZObject = { rotationZ: 0 };
	transform_SkewX_YObject = { skewX_Y: 0 };
	transform_SkewX_ZObject = { skewX_Z: 0 };
	transform_SkewY_XObject = { skewY_X: 0 };
	transform_SkewY_ZObject = { skewY_Z: 0 };
	transform_SkewZ_XObject = { skewZ_X: 0 };
	transform_SkewZ_YObject = { skewZ_Y: 0 };

	material_TypeObject = { Material_Preset: 'ClearCoat Diffuse' };
	material_ColorObject = { Material_Color: [0, 1, 1] };
	material_RoughnessObject = { Material_Roughness: 0.0 };

	function handlePositionChange() { needChangePosition = true; }
	function handleScaleUniformChange() { needChangeScaleUniform = true; }
	function handleScaleChange() { needChangeScale = true; }
	function handleRotationChange() { needChangeRotation = true; }
	function handleSkewChange() { needChangeSkew = true; }

	function handleMaterialTypeChange() { needChangeMaterialType = true; }
	function handleMaterialColorChange() { needChangeMaterialColor = true; }
	function handleMaterialRoughnessChange() { needChangeMaterialRoughness = true; }


	material_TypeController = gui.add(material_TypeObject, 'Material_Preset', ['Diffuse', 'ClearCoat Diffuse', 'Transparent Refractive',
		'Copper Metal', 'Aluminum Metal', 'Gold Metal']).onChange(handleMaterialTypeChange);

	material_ColorController = gui.addColor(material_ColorObject, 'Material_Color').onChange(handleMaterialColorChange);
	material_RoughnessController = gui.add(material_RoughnessObject, 'Material_Roughness', 0.0, 1.0, 0.01).onChange(handleMaterialRoughnessChange);


	transform_Folder = gui.addFolder('All Objects Transform');

	scale_Folder = transform_Folder.addFolder('Scale').close();
	transform_ScaleUniformController = scale_Folder.add(transform_ScaleUniformObject, 'uniformScale', 1, 50, 1).onChange(handleScaleUniformChange);
	transform_ScaleXController = scale_Folder.add(transform_ScaleXObject, 'scaleX', 1, 50, 1).onChange(handleScaleChange);
	transform_ScaleYController = scale_Folder.add(transform_ScaleYObject, 'scaleY', 1, 50, 1).onChange(handleScaleChange);
	transform_ScaleZController = scale_Folder.add(transform_ScaleZObject, 'scaleZ', 1, 50, 1).onChange(handleScaleChange);

	rotation_Folder = transform_Folder.addFolder('Rotation').close();
	transform_RotationXController = rotation_Folder.add(transform_RotationXObject, 'rotationX', 0, 359, 1).onChange(handleRotationChange);
	transform_RotationYController = rotation_Folder.add(transform_RotationYObject, 'rotationY', 0, 359, 1).onChange(handleRotationChange);
	transform_RotationZController = rotation_Folder.add(transform_RotationZObject, 'rotationZ', 0, 359, 1).onChange(handleRotationChange);

	position_Folder = transform_Folder.addFolder('Position').close();
	transform_PositionXController = position_Folder.add(transform_PositionXObject, 'positionX', -50, 50, 1).onChange(handlePositionChange);
	transform_PositionYController = position_Folder.add(transform_PositionYObject, 'positionY', -50, 50, 1).onChange(handlePositionChange);
	transform_PositionZController = position_Folder.add(transform_PositionZObject, 'positionZ', -50, 50, 1).onChange(handlePositionChange);

	skew_Folder = transform_Folder.addFolder('Skew').close();
	transform_SkewX_YController = skew_Folder.add(transform_SkewX_YObject, 'skewX_Y', -0.9, 0.9, 0.1).onChange(handleSkewChange);
	transform_SkewX_ZController = skew_Folder.add(transform_SkewX_ZObject, 'skewX_Z', -0.9, 0.9, 0.1).onChange(handleSkewChange);
	transform_SkewY_XController = skew_Folder.add(transform_SkewY_XObject, 'skewY_X', -0.9, 0.9, 0.1).onChange(handleSkewChange);
	transform_SkewY_ZController = skew_Folder.add(transform_SkewY_ZObject, 'skewY_Z', -0.9, 0.9, 0.1).onChange(handleSkewChange);
	transform_SkewZ_XController = skew_Folder.add(transform_SkewZ_XObject, 'skewZ_X', -0.9, 0.9, 0.1).onChange(handleSkewChange);
	transform_SkewZ_YController = skew_Folder.add(transform_SkewZ_YObject, 'skewZ_Y', -0.9, 0.9, 0.1).onChange(handleSkewChange);

	
	// jumpstart some of the gui controller-change handlers so that the pathtracing fragment shader uniforms are correct and up-to-date
	handlePositionChange();
	handleScaleUniformChange();
	handleScaleChange();
	handleRotationChange();
	handleSkewChange();
	handleMaterialTypeChange();
	handleMaterialColorChange();
	handleMaterialRoughnessChange();
	

	// scene/demo-specific uniforms go here
	pathTracingUniforms.uConvexPolyhedronInvMatrix = { value: new THREE.Matrix4() };
	pathTracingUniforms.uMaterialType = { value: 4 };
	pathTracingUniforms.uMaterialColor = { value: new THREE.Color(0.0, 1.0, 1.0) };
	pathTracingUniforms.uRoughness = { value: 0.0 };

} // end function initSceneData()


let firstTimeFlag = true;
// called automatically from within the animate() function (located in InitCommon.js file)
function updateVariablesAndUniforms() 
{

	if (firstTimeFlag)
	{
		cameraIsMoving = true;
		firstTimeFlag = false;
	}

	if (needChangePosition)
	{
		convexPolyhedron.position.set(transform_PositionXController.getValue(),
			transform_PositionYController.getValue(),
			transform_PositionZController.getValue());

		cameraIsMoving = true;
		needChangePosition = false;
	}

	if (needChangeScaleUniform)
	{
		uniformScale = transform_ScaleUniformController.getValue();
		// convexPolyhedron.scale.set(uniformScale, uniformScale, uniformScale);

		transform_ScaleXController.setValue(uniformScale);
		transform_ScaleYController.setValue(uniformScale);
		transform_ScaleZController.setValue(uniformScale);

		cameraIsMoving = true;
		needChangeScaleUniform = false;
	}

	if (needChangeScale)
	{
		convexPolyhedron.scale.set(transform_ScaleXController.getValue(),
			transform_ScaleYController.getValue(),
			transform_ScaleZController.getValue());

		cameraIsMoving = true;
		needChangeScale = false;
	}

	if (needChangeRotation)
	{
		convexPolyhedron.rotation.set(THREE.MathUtils.degToRad(transform_RotationXController.getValue()),
			THREE.MathUtils.degToRad(transform_RotationYController.getValue()),
			THREE.MathUtils.degToRad(transform_RotationZController.getValue()));

		cameraIsMoving = true;
		needChangeRotation = false;
	}

	if (needChangeSkew)
	{
		skewMatrix.set(
			1, transform_SkewX_YController.getValue(), transform_SkewX_ZController.getValue(), 0,
			transform_SkewY_XController.getValue(), 1, transform_SkewY_ZController.getValue(), 0,
			transform_SkewZ_XController.getValue(), transform_SkewZ_YController.getValue(), 1, 0,
			0, 0, 0, 1
		);

		cameraIsMoving = true;
		needChangeSkew = false;
	}


	if (needChangeMaterialType) 
	{

		matType = material_TypeController.getValue();

		if (matType == 'Diffuse') 
		{
			pathTracingUniforms.uMaterialType.value = 1;
			pathTracingUniforms.uMaterialColor.value.setRGB(0.0, 0.8, 1.0);
		}
		else if (matType == 'ClearCoat Diffuse') 
		{
			pathTracingUniforms.uMaterialType.value = 4;
			pathTracingUniforms.uMaterialColor.value.setRGB(0.4, 0.0, 1.0);
		}
		else if (matType == 'Transparent Refractive') 
		{
			pathTracingUniforms.uMaterialType.value = 2;
			pathTracingUniforms.uMaterialColor.value.setRGB(1.0, 0.1, 0.0);
		}
		else if (matType == 'Copper Metal') 
		{
			pathTracingUniforms.uMaterialType.value = 3;
			pathTracingUniforms.uMaterialColor.value.setRGB(0.955008, 0.637427, 0.538163);
		}
		else if (matType == 'Aluminum Metal') 
		{
			pathTracingUniforms.uMaterialType.value = 3;
			pathTracingUniforms.uMaterialColor.value.setRGB(0.913183, 0.921494, 0.924524);
		}
		else if (matType == 'Gold Metal') 
		{
			pathTracingUniforms.uMaterialType.value = 3;
			pathTracingUniforms.uMaterialColor.value.setRGB(1.000000, 0.765557, 0.336057);
		}
			
		
		material_ColorController.setValue([ pathTracingUniforms.uMaterialColor.value.r,
						    pathTracingUniforms.uMaterialColor.value.g,
						    pathTracingUniforms.uMaterialColor.value.b ]);
		
		cameraIsMoving = true;
		needChangeMaterialType = false;
	}

	if (needChangeMaterialColor) 
	{
		matColor = material_ColorController.getValue();
		pathTracingUniforms.uMaterialColor.value.setRGB( matColor[0], matColor[1], matColor[2] );
		
		cameraIsMoving = true;
		needChangeMaterialColor = false;
	}

	if (needChangeMaterialRoughness) 
	{
		pathTracingUniforms.uRoughness.value = material_RoughnessController.getValue();
		cameraIsMoving = true;
		needChangeMaterialRoughness = false;
	}


	if (cameraIsMoving)
	{
		convexPolyhedron.updateMatrixWorld(true); // need to update matrix because we manually multiply it by skewMatrix on the next line
		convexPolyhedron.matrixWorld.multiply(skewMatrix); // multiply polyhedron's matrix by my custom skew(shear) matrix4
		pathTracingUniforms.uConvexPolyhedronInvMatrix.value.copy(convexPolyhedron.matrixWorld).invert();
	}
	

	// INFO
	cameraInfoElement.innerHTML = "FOV: " + worldCamera.fov + " / Aperture: " + apertureSize.toFixed(2) + " / FocusDistance: " + focusDistance + "<br>" + "Samples: " + sampleCounter;

} // end function updateVariablesAndUniforms()



init(); // init app and start animating
