// scene/demo-specific variables go here
let quadricShape_PresetController;
let quadricShape_PresetObject;

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


let quadricA_ParameterController, quadricB_ParameterController, quadricC_ParameterController, quadricD_ParameterController,
	quadricE_ParameterController, quadricF_ParameterController, quadricG_ParameterController, quadricH_ParameterController,
	quadricI_ParameterController, quadricJ_ParameterController;
let quadricA_ParameterObject, quadricB_ParameterObject, quadricC_ParameterObject, quadricD_ParameterObject,
	quadricE_ParameterObject, quadricF_ParameterObject, quadricG_ParameterObject, quadricH_ParameterObject,
	quadricI_ParameterObject, quadricJ_ParameterObject;

let needChangePosition = false;
let needChangeScaleUniform = false;
let needChangeScale = false;
let needChangeSkew = false;
let needChangeRotation = false;
let needChangeShapePreset = false;
let needChangeQuadricParameter = false;
let wallRadius = 50;
let shapeRadius = 16;
let quadricShape;


// called automatically from within initTHREEjs() function (located in InitCommon.js file)
function initSceneData() 
{
	demoFragmentShaderFileName = 'Quadric_Shapes_Explorer_Fragment.glsl';

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
	cameraControlsObject.position.set(0, -20, 120);
	///cameraControlsYawObject.rotation.y = 0.0;
	// look slightly upward
	cameraControlsPitchObject.rotation.x = 0.005;

	quadricShape = new THREE.Object3D();
	pathTracingScene.add(quadricShape);

	// In addition to the default GUI on all demos, add any special GUI elements that this particular demo requires

	quadricShape_PresetObject = {
		Shape_Preset: 'Sphere(Ellipsoid)'
	};

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

	quadricA_ParameterObject = { quadric_A: 1 };
	quadricB_ParameterObject = { quadric_B: 0 };
	quadricC_ParameterObject = { quadric_C: 0 };
	quadricD_ParameterObject = { quadric_D: 0 };
	quadricE_ParameterObject = { quadric_E: 1 };
	quadricF_ParameterObject = { quadric_F: 0 };
	quadricG_ParameterObject = { quadric_G: 0 };
	quadricH_ParameterObject = { quadric_H: 1 };
	quadricI_ParameterObject = { quadric_I: 0 };
	quadricJ_ParameterObject = { quadric_J: 0 };

	function handleShapePresetChange() { needChangeShapePreset = true; }
	function handlePositionChange() { needChangePosition = true; }
	function handleScaleUniformChange() { needChangeScaleUniform = true; }
	function handleScaleChange() { needChangeScale = true; }
	function handleRotationChange() { needChangeRotation = true; }
	function handleSkewChange() { needChangeSkew = true; }
	function handleQuadricParameterChange() { needChangeQuadricParameter = true; }

	quadricShape_PresetController = gui.add(quadricShape_PresetObject, 'Shape_Preset', ['Sphere(Ellipsoid)', 'Cylinder', 'Cone', 
		'Paraboloid', 'Hyperboloid_1Sheet', 'Hyperboloid_2Sheets', 'HyperbolicParaboloid', 'Plane', 'IntersectingPlanes', 
		'ParabolicPlane', 'HyperbolicPlanes', 'TwistedPlane', 'Custom_1', 'Custom_2', 'Custom_3']).onChange(handleShapePresetChange);

	
	transform_Folder = gui.addFolder('Transform').close();

	position_Folder = transform_Folder.addFolder('Position');
	transform_PositionXController = position_Folder.add(transform_PositionXObject, 'positionX', -50, 50, 1).onChange(handlePositionChange);
	transform_PositionYController = position_Folder.add(transform_PositionYObject, 'positionY', -50, 50, 1).onChange(handlePositionChange);
	transform_PositionZController = position_Folder.add(transform_PositionZObject, 'positionZ', -50, 50, 1).onChange(handlePositionChange);

	scale_Folder = transform_Folder.addFolder('Scale');
	transform_ScaleUniformController = scale_Folder.add(transform_ScaleUniformObject, 'uniformScale', 1, 50, 1).onChange(handleScaleUniformChange);
	transform_ScaleXController = scale_Folder.add(transform_ScaleXObject, 'scaleX', 1, 50, 1).onChange(handleScaleChange);
	transform_ScaleYController = scale_Folder.add(transform_ScaleYObject, 'scaleY', 1, 50, 1).onChange(handleScaleChange);
	transform_ScaleZController = scale_Folder.add(transform_ScaleZObject, 'scaleZ', 1, 50, 1).onChange(handleScaleChange);

	rotation_Folder = transform_Folder.addFolder('Rotation');
	transform_RotationXController = rotation_Folder.add(transform_RotationXObject, 'rotationX', 0, 359, 1).onChange(handleRotationChange);
	transform_RotationYController = rotation_Folder.add(transform_RotationYObject, 'rotationY', 0, 359, 1).onChange(handleRotationChange);
	transform_RotationZController = rotation_Folder.add(transform_RotationZObject, 'rotationZ', 0, 359, 1).onChange(handleRotationChange);

	skew_Folder = transform_Folder.addFolder('Skew');
	transform_SkewX_YController = skew_Folder.add(transform_SkewX_YObject, 'skewX_Y', -0.9, 0.9, 0.1).onChange(handleSkewChange);
	transform_SkewX_ZController = skew_Folder.add(transform_SkewX_ZObject, 'skewX_Z', -0.9, 0.9, 0.1).onChange(handleSkewChange);
	transform_SkewY_XController = skew_Folder.add(transform_SkewY_XObject, 'skewY_X', -0.9, 0.9, 0.1).onChange(handleSkewChange);
	transform_SkewY_ZController = skew_Folder.add(transform_SkewY_ZObject, 'skewY_Z', -0.9, 0.9, 0.1).onChange(handleSkewChange);
	transform_SkewZ_XController = skew_Folder.add(transform_SkewZ_XObject, 'skewZ_X', -0.9, 0.9, 0.1).onChange(handleSkewChange);
	transform_SkewZ_YController = skew_Folder.add(transform_SkewZ_YObject, 'skewZ_Y', -0.9, 0.9, 0.1).onChange(handleSkewChange);


	quadricA_ParameterController = gui.add(quadricA_ParameterObject, 'quadric_A', -4, 4, 0.02).onChange(handleQuadricParameterChange);
	quadricB_ParameterController = gui.add(quadricB_ParameterObject, 'quadric_B', -4, 4, 0.02).onChange(handleQuadricParameterChange);
	quadricC_ParameterController = gui.add(quadricC_ParameterObject, 'quadric_C', -4, 4, 0.02).onChange(handleQuadricParameterChange);
	quadricD_ParameterController = gui.add(quadricD_ParameterObject, 'quadric_D', -4, 4, 0.02).onChange(handleQuadricParameterChange);
	quadricE_ParameterController = gui.add(quadricE_ParameterObject, 'quadric_E', -4, 4, 0.02).onChange(handleQuadricParameterChange);
	quadricF_ParameterController = gui.add(quadricF_ParameterObject, 'quadric_F', -4, 4, 0.02).onChange(handleQuadricParameterChange);
	quadricG_ParameterController = gui.add(quadricG_ParameterObject, 'quadric_G', -4, 4, 0.02).onChange(handleQuadricParameterChange);
	quadricH_ParameterController = gui.add(quadricH_ParameterObject, 'quadric_H', -4, 4, 0.02).onChange(handleQuadricParameterChange);
	quadricI_ParameterController = gui.add(quadricI_ParameterObject, 'quadric_I', -4, 4, 0.02).onChange(handleQuadricParameterChange);
	quadricJ_ParameterController = gui.add(quadricJ_ParameterObject, 'quadric_J', -4, 4, 0.02).onChange(handleQuadricParameterChange);
	
	
	// jumpstart some of the gui controller-change handlers so that the pathtracing fragment shader uniforms are correct and up-to-date
	handleShapePresetChange();
	handlePositionChange();
	handleScaleUniformChange();
	handleScaleChange();
	handleRotationChange();
	handleSkewChange();
	

	// scene/demo-specific uniforms go here
	pathTracingUniforms.uQuadricShapePresetMatrix = { value: new THREE.Matrix4() };
	pathTracingUniforms.uQuadricShapeInvMatrix = { value: new THREE.Matrix4() };

} // end function initSceneData()



// called automatically from within the animate() function (located in InitCommon.js file)
function updateVariablesAndUniforms() 
{

	if (needChangeShapePreset)
	{
		if (quadricShape_PresetController.getValue() == 'Sphere(Ellipsoid)')
		{
			quadricA_ParameterController.setValue(1); quadricB_ParameterController.setValue(0); quadricC_ParameterController.setValue(0); quadricD_ParameterController.setValue(0);
			quadricE_ParameterController.setValue(1); quadricF_ParameterController.setValue(0); quadricG_ParameterController.setValue(0); 
			quadricH_ParameterController.setValue(1); quadricI_ParameterController.setValue(0); 
			quadricJ_ParameterController.setValue(-1); 
		}
		else if (quadricShape_PresetController.getValue() == 'Cylinder')
		{
			quadricA_ParameterController.setValue(1); quadricB_ParameterController.setValue(0); quadricC_ParameterController.setValue(0); quadricD_ParameterController.setValue(0);
			quadricE_ParameterController.setValue(0); quadricF_ParameterController.setValue(0); quadricG_ParameterController.setValue(0);
			quadricH_ParameterController.setValue(1); quadricI_ParameterController.setValue(0);
			quadricJ_ParameterController.setValue(-1);
		}
		else if (quadricShape_PresetController.getValue() == 'Cone')
		{
			quadricA_ParameterController.setValue(1); quadricB_ParameterController.setValue(0); quadricC_ParameterController.setValue(0); quadricD_ParameterController.setValue(0);
			quadricE_ParameterController.setValue(-1); quadricF_ParameterController.setValue(0); quadricG_ParameterController.setValue(0);
			quadricH_ParameterController.setValue(1); quadricI_ParameterController.setValue(0);
			quadricJ_ParameterController.setValue(0);
		}
		else if (quadricShape_PresetController.getValue() == 'Paraboloid')
		{
			quadricA_ParameterController.setValue(1); quadricB_ParameterController.setValue(0); quadricC_ParameterController.setValue(0); quadricD_ParameterController.setValue(0);
			quadricE_ParameterController.setValue(0); quadricF_ParameterController.setValue(0); quadricG_ParameterController.setValue(0.25);
			quadricH_ParameterController.setValue(1); quadricI_ParameterController.setValue(0);
			quadricJ_ParameterController.setValue(-0.5);
		}
		else if (quadricShape_PresetController.getValue() == 'Hyperboloid_1Sheet')
		{
			quadricA_ParameterController.setValue(1); quadricB_ParameterController.setValue(0); quadricC_ParameterController.setValue(0); quadricD_ParameterController.setValue(0);
			quadricE_ParameterController.setValue(-0.9); quadricF_ParameterController.setValue(0); quadricG_ParameterController.setValue(0);
			quadricH_ParameterController.setValue(1); quadricI_ParameterController.setValue(0);
			quadricJ_ParameterController.setValue(-0.1);
		}
		else if (quadricShape_PresetController.getValue() == 'Hyperboloid_2Sheets')
		{
			quadricA_ParameterController.setValue(1); quadricB_ParameterController.setValue(0); quadricC_ParameterController.setValue(0); quadricD_ParameterController.setValue(0);
			quadricE_ParameterController.setValue(-0.9); quadricF_ParameterController.setValue(0); quadricG_ParameterController.setValue(0);
			quadricH_ParameterController.setValue(1); quadricI_ParameterController.setValue(0);
			quadricJ_ParameterController.setValue(0.1);
		}
		else if (quadricShape_PresetController.getValue() == 'HyperbolicParaboloid')
		{
			quadricA_ParameterController.setValue(-1); quadricB_ParameterController.setValue(0); quadricC_ParameterController.setValue(0); quadricD_ParameterController.setValue(0);
			quadricE_ParameterController.setValue(0); quadricF_ParameterController.setValue(0); quadricG_ParameterController.setValue(0.5);
			quadricH_ParameterController.setValue(1); quadricI_ParameterController.setValue(0);
			quadricJ_ParameterController.setValue(0);
		}
		else if (quadricShape_PresetController.getValue() == 'Plane')
		{
			quadricA_ParameterController.setValue(0); quadricB_ParameterController.setValue(0); quadricC_ParameterController.setValue(0); quadricD_ParameterController.setValue(0);
			quadricE_ParameterController.setValue(1); quadricF_ParameterController.setValue(0); quadricG_ParameterController.setValue(1);
			quadricH_ParameterController.setValue(0); quadricI_ParameterController.setValue(0);
			quadricJ_ParameterController.setValue(0);
		}
		else if (quadricShape_PresetController.getValue() == 'IntersectingPlanes')
		{
			quadricA_ParameterController.setValue(0); quadricB_ParameterController.setValue(0); quadricC_ParameterController.setValue(0); quadricD_ParameterController.setValue(0);
			quadricE_ParameterController.setValue(0); quadricF_ParameterController.setValue(1); quadricG_ParameterController.setValue(0);
			quadricH_ParameterController.setValue(0); quadricI_ParameterController.setValue(0);
			quadricJ_ParameterController.setValue(0);
		}
		else if (quadricShape_PresetController.getValue() == 'ParabolicPlane')
		{
			quadricA_ParameterController.setValue(1); quadricB_ParameterController.setValue(0); quadricC_ParameterController.setValue(0); quadricD_ParameterController.setValue(0);
			quadricE_ParameterController.setValue(0.001); quadricF_ParameterController.setValue(0); quadricG_ParameterController.setValue(-1);
			quadricH_ParameterController.setValue(0); quadricI_ParameterController.setValue(0);
			quadricJ_ParameterController.setValue(0);
		}
		else if (quadricShape_PresetController.getValue() == 'HyperbolicPlanes')
		{
			quadricA_ParameterController.setValue(1); quadricB_ParameterController.setValue(0); quadricC_ParameterController.setValue(0); quadricD_ParameterController.setValue(0);
			quadricE_ParameterController.setValue(-1); quadricF_ParameterController.setValue(0); quadricG_ParameterController.setValue(0);
			quadricH_ParameterController.setValue(0); quadricI_ParameterController.setValue(0);
			quadricJ_ParameterController.setValue(0.01);
		}
		else if (quadricShape_PresetController.getValue() == 'TwistedPlane')
		{
			quadricA_ParameterController.setValue(0); quadricB_ParameterController.setValue(0); quadricC_ParameterController.setValue(1); quadricD_ParameterController.setValue(0);
			quadricE_ParameterController.setValue(0); quadricF_ParameterController.setValue(0); quadricG_ParameterController.setValue(1);
			quadricH_ParameterController.setValue(0); quadricI_ParameterController.setValue(0);
			quadricJ_ParameterController.setValue(0);
		}
		else if (quadricShape_PresetController.getValue() == 'Custom_1')
		{
			quadricA_ParameterController.setValue(1); quadricB_ParameterController.setValue(0); quadricC_ParameterController.setValue(0); quadricD_ParameterController.setValue(0);
			quadricE_ParameterController.setValue(0); quadricF_ParameterController.setValue(0); quadricG_ParameterController.setValue(-0.25);
			quadricH_ParameterController.setValue(-1); quadricI_ParameterController.setValue(0);
			quadricJ_ParameterController.setValue(-0.5);
		}
		else if (quadricShape_PresetController.getValue() == 'Custom_2')
		{
			quadricA_ParameterController.setValue(1); quadricB_ParameterController.setValue(0); quadricC_ParameterController.setValue(0); quadricD_ParameterController.setValue(0);
			quadricE_ParameterController.setValue(-1); quadricF_ParameterController.setValue(0); quadricG_ParameterController.setValue(0);
			quadricH_ParameterController.setValue(0); quadricI_ParameterController.setValue(0.01);
			quadricJ_ParameterController.setValue(0);
		}
		else if (quadricShape_PresetController.getValue() == 'Custom_3')
		{
			quadricA_ParameterController.setValue(-1); quadricB_ParameterController.setValue(0); quadricC_ParameterController.setValue(0); quadricD_ParameterController.setValue(0);
			quadricE_ParameterController.setValue(1); quadricF_ParameterController.setValue(0); quadricG_ParameterController.setValue(0);
			quadricH_ParameterController.setValue(-0.5); quadricI_ParameterController.setValue(0);
			quadricJ_ParameterController.setValue(0.5);
		}

		needChangeQuadricParameter = true;
		needChangeShapePreset = false;
	} // end if (needChangeShapePreset)



	if (needChangePosition)
	{
		quadricShape.position.set(transform_PositionXController.getValue(),
			transform_PositionYController.getValue(),
			transform_PositionZController.getValue());

		cameraIsMoving = true;
		needChangePosition = false;
	}

	if (needChangeScaleUniform)
	{
		uniformScale = transform_ScaleUniformController.getValue();
		quadricShape.scale.set(uniformScale, uniformScale, uniformScale);

		transform_ScaleXController.setValue(uniformScale);
		transform_ScaleYController.setValue(uniformScale);
		transform_ScaleZController.setValue(uniformScale);

		cameraIsMoving = true;
		needChangeScaleUniform = false;
	}

	if (needChangeScale)
	{
		quadricShape.scale.set(transform_ScaleXController.getValue(),
			transform_ScaleYController.getValue(),
			transform_ScaleZController.getValue());

		cameraIsMoving = true;
		needChangeScale = false;
	}

	if (needChangeRotation)
	{
		quadricShape.rotation.set(THREE.MathUtils.degToRad(transform_RotationXController.getValue()),
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

	

	if (needChangeQuadricParameter)
	{
		// matrix's parameter layout from 2004 paper, 'Ray Tracing Arbitrary Objects on the GPU' by Wood, et al.  
		// [A] [B] [C] [D]
		// [B] [E] [F] [G]
		// [C] [F] [H] [I]
		// [D] [G] [I] [J]
		pathTracingUniforms.uQuadricShapePresetMatrix.value.set(
			quadricA_ParameterController.getValue(), quadricB_ParameterController.getValue(), quadricC_ParameterController.getValue(), quadricD_ParameterController.getValue(),
			quadricB_ParameterController.getValue(), quadricE_ParameterController.getValue(), quadricF_ParameterController.getValue(), quadricG_ParameterController.getValue(),
			quadricC_ParameterController.getValue(), quadricF_ParameterController.getValue(), quadricH_ParameterController.getValue(), quadricI_ParameterController.getValue(),
			quadricD_ParameterController.getValue(), quadricG_ParameterController.getValue(), quadricI_ParameterController.getValue(), quadricJ_ParameterController.getValue()
		);

		cameraIsMoving = true;
		needChangeQuadricParameter = false;
	}

	// QUADRIC SHAPE
	quadricShape.matrixWorld.multiply(skewMatrix); // multiply quadricShape's matrix by my custom skew(shear) matrix4
	pathTracingUniforms.uQuadricShapeInvMatrix.value.copy(quadricShape.matrixWorld).invert();
	

	// INFO
	cameraInfoElement.innerHTML = "FOV: " + worldCamera.fov + " / Aperture: " + apertureSize.toFixed(2) + " / FocusDistance: " + focusDistance + "<br>" + "Samples: " + sampleCounter;

} // end function updateVariablesAndUniforms()



init(); // init app and start animating
