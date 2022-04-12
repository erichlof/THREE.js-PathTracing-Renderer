// scene/demo-specific variables go here
let quadricShape_PresetController;
let quadricShape_PresetObject;
let quadricA_CoefficientController, quadricB_CoefficientController, quadricC_CoefficientController, quadricD_CoefficientController,
	quadricE_CoefficientController, quadricF_CoefficientController, quadricG_CoefficientController, quadricH_CoefficientController,
	quadricI_CoefficientController, quadricJ_CoefficientController, quadricK_CoefficientController, quadricL_CoefficientController,
	quadricM_CoefficientController, quadricN_CoefficientController, quadricO_CoefficientController, quadricP_CoefficientController;
let quadricA_CoefficientObject, quadricB_CoefficientObject, quadricC_CoefficientObject, quadricD_CoefficientObject,
	quadricE_CoefficientObject, quadricF_CoefficientObject, quadricG_CoefficientObject, quadricH_CoefficientObject,
	quadricI_CoefficientObject, quadricJ_CoefficientObject, quadricK_CoefficientObject, quadricL_CoefficientObject,
	quadricM_CoefficientObject, quadricN_CoefficientObject, quadricO_CoefficientObject, quadricP_CoefficientObject;

let needChangeShapePreset = false;
let needChangeQuadricCoefficient = false;
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
	pixelRatio = mouseControl ? 0.75 : 0.8;

	EPS_intersect = 0.01;

	// set camera's field of view
	worldCamera.fov = 50;
	focusDistance = 530.0;

	// position and orient camera
	cameraControlsObject.position.set(0, -20, 120);
	///cameraControlsYawObject.rotation.y = 0.0;
	// look slightly upward
	cameraControlsPitchObject.rotation.x = 0.005;

	quadricShape = new THREE.Object3D();
	pathTracingScene.add(quadricShape);
	quadricShape.position.set(0, -wallRadius + shapeRadius + 0.01, 0);
	quadricShape.scale.set(shapeRadius, shapeRadius, shapeRadius);
	quadricShape.updateMatrixWorld(true); // 'true' forces immediate matrix update

	// In addition to the default GUI on all demos, add any special GUI elements that this particular demo requires

	quadricShape_PresetObject = {
		Shape_Preset: 'Sphere(Ellipsoid)'
	};

	quadricA_CoefficientObject = { quadric_A: 1 };
	quadricB_CoefficientObject = { quadric_B: 0 };
	quadricC_CoefficientObject = { quadric_C: 0 };
	quadricD_CoefficientObject = { quadric_D: 0 };
	quadricE_CoefficientObject = { quadric_E: 0 };
	quadricF_CoefficientObject = { quadric_F: 1 };
	quadricG_CoefficientObject = { quadric_G: 0 };
	quadricH_CoefficientObject = { quadric_H: 0 };
	quadricI_CoefficientObject = { quadric_I: 0 };
	quadricJ_CoefficientObject = { quadric_J: 0 };
	quadricK_CoefficientObject = { quadric_K: 1 };
	quadricL_CoefficientObject = { quadric_L: 0 };
	quadricM_CoefficientObject = { quadric_M: 0 };
	quadricN_CoefficientObject = { quadric_N: 0 };
	quadricO_CoefficientObject = { quadric_O: 0 };
	quadricP_CoefficientObject = { quadric_P:-1 };

	function handleShapePresetChange() 
	{
		needChangeShapePreset = true;
	}
	function handleQuadricCoefficientChange() 
	{
		needChangeQuadricCoefficient = true;
	}

	quadricShape_PresetController = gui.add(quadricShape_PresetObject, 'Shape_Preset', ['Sphere(Ellipsoid)', 'Cylinder', 'Cone', 'Paraboloid', 'Hyperboloid_1Sheet', 
		'Hyperboloid_2Sheets', 'HyperbolicParaboloid', 'ParabolicPlane', 'IntersectingPlanes', 'WarpedPlanes']).onChange(handleShapePresetChange);

	quadricA_CoefficientController = gui.add(quadricA_CoefficientObject, 'quadric_A', -4, 4, 0.02).onChange(handleQuadricCoefficientChange);
	quadricB_CoefficientController = gui.add(quadricB_CoefficientObject, 'quadric_B', -4, 4, 0.02).onChange(handleQuadricCoefficientChange);
	quadricC_CoefficientController = gui.add(quadricC_CoefficientObject, 'quadric_C', -4, 4, 0.02).onChange(handleQuadricCoefficientChange);
	quadricD_CoefficientController = gui.add(quadricD_CoefficientObject, 'quadric_D', -4, 4, 0.02).onChange(handleQuadricCoefficientChange);
	quadricE_CoefficientController = gui.add(quadricE_CoefficientObject, 'quadric_E', -4, 4, 0.02).onChange(handleQuadricCoefficientChange);
	quadricF_CoefficientController = gui.add(quadricF_CoefficientObject, 'quadric_F', -4, 4, 0.02).onChange(handleQuadricCoefficientChange);
	quadricG_CoefficientController = gui.add(quadricG_CoefficientObject, 'quadric_G', -4, 4, 0.02).onChange(handleQuadricCoefficientChange);
	quadricH_CoefficientController = gui.add(quadricH_CoefficientObject, 'quadric_H', -4, 4, 0.02).onChange(handleQuadricCoefficientChange);
	quadricI_CoefficientController = gui.add(quadricI_CoefficientObject, 'quadric_I', -4, 4, 0.02).onChange(handleQuadricCoefficientChange);
	quadricJ_CoefficientController = gui.add(quadricJ_CoefficientObject, 'quadric_J', -4, 4, 0.02).onChange(handleQuadricCoefficientChange);
	quadricK_CoefficientController = gui.add(quadricK_CoefficientObject, 'quadric_K', -4, 4, 0.02).onChange(handleQuadricCoefficientChange);
	quadricL_CoefficientController = gui.add(quadricL_CoefficientObject, 'quadric_L', -4, 4, 0.02).onChange(handleQuadricCoefficientChange);
	quadricM_CoefficientController = gui.add(quadricM_CoefficientObject, 'quadric_M', -4, 4, 0.02).onChange(handleQuadricCoefficientChange);
	quadricN_CoefficientController = gui.add(quadricN_CoefficientObject, 'quadric_N', -4, 4, 0.02).onChange(handleQuadricCoefficientChange);
	quadricO_CoefficientController = gui.add(quadricO_CoefficientObject, 'quadric_O', -4, 4, 0.02).onChange(handleQuadricCoefficientChange);
	quadricP_CoefficientController = gui.add(quadricP_CoefficientObject, 'quadric_P', -4, 4, 0.02).onChange(handleQuadricCoefficientChange);
	
	// scene/demo-specific uniforms go here
	pathTracingUniforms.uQuadricShapePresetMatrix = { type: "m4", value: new THREE.Matrix4() };
	pathTracingUniforms.uQuadricShapeInvMatrix = { type: "m4", value: new THREE.Matrix4() };
	

	//TODO add uShapeRadius and check for unit box * radius in shader
	pathTracingUniforms.uQuadricShapePresetMatrix.value.set(
		1, 0, 0, 0,
		0, 1, 0, 0,
		0, 0, 1, 0,
		0, 0, 0, -1);
	pathTracingUniforms.uQuadricShapeInvMatrix.value.copy(quadricShape.matrixWorld).invert();

} // end function initSceneData()



// called automatically from within the animate() function (located in InitCommon.js file)
function updateVariablesAndUniforms() 
{

	if (needChangeShapePreset)
	{
		if (quadricShape_PresetController.getValue() == 'Sphere(Ellipsoid)')
		{
			quadricA_CoefficientController.setValue(1); quadricB_CoefficientController.setValue(0); quadricC_CoefficientController.setValue(0); quadricD_CoefficientController.setValue(0);
			quadricE_CoefficientController.setValue(0); quadricF_CoefficientController.setValue(1); quadricG_CoefficientController.setValue(0); quadricH_CoefficientController.setValue(0);
			quadricI_CoefficientController.setValue(0); quadricJ_CoefficientController.setValue(0); quadricK_CoefficientController.setValue(1); quadricL_CoefficientController.setValue(0);
			quadricM_CoefficientController.setValue(0); quadricN_CoefficientController.setValue(0); quadricO_CoefficientController.setValue(0); quadricP_CoefficientController.setValue(-1);
				// 1, 0, 0, 0,
				// 0, 1, 0, 0,
				// 0, 0, 1, 0,
				// 0, 0, 0, -1
		}
		else if (quadricShape_PresetController.getValue() == 'Cylinder')
		{
			quadricA_CoefficientController.setValue(1); quadricB_CoefficientController.setValue(0); quadricC_CoefficientController.setValue(0); quadricD_CoefficientController.setValue(0);
			quadricE_CoefficientController.setValue(0); quadricF_CoefficientController.setValue(0); quadricG_CoefficientController.setValue(0); quadricH_CoefficientController.setValue(0);
			quadricI_CoefficientController.setValue(0); quadricJ_CoefficientController.setValue(0); quadricK_CoefficientController.setValue(1); quadricL_CoefficientController.setValue(0);
			quadricM_CoefficientController.setValue(0); quadricN_CoefficientController.setValue(0); quadricO_CoefficientController.setValue(0); quadricP_CoefficientController.setValue(-1);
				// 1, 0, 0, 0,
				// 0, 0, 0, 0,
				// 0, 0, 1, 0,
				// 0, 0, 0, -1
		}
		else if (quadricShape_PresetController.getValue() == 'Cone')
		{
			quadricA_CoefficientController.setValue(1); quadricB_CoefficientController.setValue(0); quadricC_CoefficientController.setValue(0); quadricD_CoefficientController.setValue(0);
			quadricE_CoefficientController.setValue(0); quadricF_CoefficientController.setValue(-1); quadricG_CoefficientController.setValue(0); quadricH_CoefficientController.setValue(0);
			quadricI_CoefficientController.setValue(0); quadricJ_CoefficientController.setValue(0); quadricK_CoefficientController.setValue(1); quadricL_CoefficientController.setValue(0);
			quadricM_CoefficientController.setValue(0); quadricN_CoefficientController.setValue(0); quadricO_CoefficientController.setValue(0); quadricP_CoefficientController.setValue(0);
				// 1, 0, 0, 0,
				// 0, -1, 0, 0,
				// 0, 0, 1, 0,
				// 0, 0, 0, 0
		}
		else if (quadricShape_PresetController.getValue() == 'Paraboloid')
		{
			quadricA_CoefficientController.setValue(1); quadricB_CoefficientController.setValue(0); quadricC_CoefficientController.setValue(0); quadricD_CoefficientController.setValue(0);
			quadricE_CoefficientController.setValue(0); quadricF_CoefficientController.setValue(0); quadricG_CoefficientController.setValue(0); quadricH_CoefficientController.setValue(0.25);
			quadricI_CoefficientController.setValue(0); quadricJ_CoefficientController.setValue(0); quadricK_CoefficientController.setValue(1); quadricL_CoefficientController.setValue(0);
			quadricM_CoefficientController.setValue(0); quadricN_CoefficientController.setValue(0.25); quadricO_CoefficientController.setValue(0); quadricP_CoefficientController.setValue(-0.5);
				// 1, 0, 0, 0,
				// 0, 0, 0, 0.25,
				// 0, 0, 1, 0,
				// 0, 0.25, 0, -0.5
		}
		else if (quadricShape_PresetController.getValue() == 'Hyperboloid_1Sheet')
		{
			quadricA_CoefficientController.setValue(1); quadricB_CoefficientController.setValue(0); quadricC_CoefficientController.setValue(0); quadricD_CoefficientController.setValue(0);
			quadricE_CoefficientController.setValue(0); quadricF_CoefficientController.setValue(-0.95); quadricG_CoefficientController.setValue(0); quadricH_CoefficientController.setValue(0);
			quadricI_CoefficientController.setValue(0); quadricJ_CoefficientController.setValue(0); quadricK_CoefficientController.setValue(1); quadricL_CoefficientController.setValue(0);
			quadricM_CoefficientController.setValue(0); quadricN_CoefficientController.setValue(0); quadricO_CoefficientController.setValue(0); quadricP_CoefficientController.setValue(-0.05);
				// 1, 0, 0, 0,
				// 0, -0.95, 0, 0,
				// 0, 0, 1, 0,
				// 0, 0, 0, -0.05
		}
		else if (quadricShape_PresetController.getValue() == 'Hyperboloid_2Sheets')
		{
			quadricA_CoefficientController.setValue(1); quadricB_CoefficientController.setValue(0); quadricC_CoefficientController.setValue(0); quadricD_CoefficientController.setValue(0);
			quadricE_CoefficientController.setValue(0); quadricF_CoefficientController.setValue(-1); quadricG_CoefficientController.setValue(0); quadricH_CoefficientController.setValue(0);
			quadricI_CoefficientController.setValue(0); quadricJ_CoefficientController.setValue(0); quadricK_CoefficientController.setValue(1); quadricL_CoefficientController.setValue(0);
			quadricM_CoefficientController.setValue(0); quadricN_CoefficientController.setValue(0); quadricO_CoefficientController.setValue(0); quadricP_CoefficientController.setValue(0.01);
				// 1, 0, 0, 0,
				// 0, -1, 0, 0,
				// 0, 0, 1, 0,
				// 0, 0, 0, 0.01
		}
		else if (quadricShape_PresetController.getValue() == 'HyperbolicParaboloid')
		{
			quadricA_CoefficientController.setValue(-1); quadricB_CoefficientController.setValue(0); quadricC_CoefficientController.setValue(0); quadricD_CoefficientController.setValue(0);
			quadricE_CoefficientController.setValue(0); quadricF_CoefficientController.setValue(0); quadricG_CoefficientController.setValue(0); quadricH_CoefficientController.setValue(0.5);
			quadricI_CoefficientController.setValue(0); quadricJ_CoefficientController.setValue(0); quadricK_CoefficientController.setValue(1); quadricL_CoefficientController.setValue(0);
			quadricM_CoefficientController.setValue(0); quadricN_CoefficientController.setValue(0.5); quadricO_CoefficientController.setValue(0); quadricP_CoefficientController.setValue(0);
				//-1, 0, 0, 0,
				// 0, 0, 0, 0.5,
				// 0, 0, 1, 0,
				// 0, 0.5, 0, 0
		}
		else if (quadricShape_PresetController.getValue() == 'ParabolicPlane')
		{
			quadricA_CoefficientController.setValue(1); quadricB_CoefficientController.setValue(0); quadricC_CoefficientController.setValue(0); quadricD_CoefficientController.setValue(0);
			quadricE_CoefficientController.setValue(0); quadricF_CoefficientController.setValue(0); quadricG_CoefficientController.setValue(0); quadricH_CoefficientController.setValue(1);
			quadricI_CoefficientController.setValue(0); quadricJ_CoefficientController.setValue(0); quadricK_CoefficientController.setValue(1); quadricL_CoefficientController.setValue(0);
			quadricM_CoefficientController.setValue(0); quadricN_CoefficientController.setValue(1); quadricO_CoefficientController.setValue(0); quadricP_CoefficientController.setValue(0);
				// 1, 0, 0, 0,
				// 0, 0, 0, 1,
				// 0, 0, 1, 0,
				// 0, 1, 0, 0
		}
		else if (quadricShape_PresetController.getValue() == 'IntersectingPlanes')
		{
			quadricA_CoefficientController.setValue(0); quadricB_CoefficientController.setValue(0); quadricC_CoefficientController.setValue(0); quadricD_CoefficientController.setValue(0);
			quadricE_CoefficientController.setValue(0); quadricF_CoefficientController.setValue(0); quadricG_CoefficientController.setValue(1); quadricH_CoefficientController.setValue(0);
			quadricI_CoefficientController.setValue(0); quadricJ_CoefficientController.setValue(1); quadricK_CoefficientController.setValue(0); quadricL_CoefficientController.setValue(0);
			quadricM_CoefficientController.setValue(0); quadricN_CoefficientController.setValue(0); quadricO_CoefficientController.setValue(0); quadricP_CoefficientController.setValue(0);
				// 0, 0, 0, 0,
				// 0, 0, 1, 0,
				// 0, 1, 0, 0,
				// 0, 0, 0, 0
		}
		else if (quadricShape_PresetController.getValue() == 'WarpedPlanes')
		{
			quadricA_CoefficientController.setValue(0); quadricB_CoefficientController.setValue(1); quadricC_CoefficientController.setValue(1); quadricD_CoefficientController.setValue(0);
			quadricE_CoefficientController.setValue(1); quadricF_CoefficientController.setValue(0); quadricG_CoefficientController.setValue(0); quadricH_CoefficientController.setValue(1);
			quadricI_CoefficientController.setValue(1); quadricJ_CoefficientController.setValue(0); quadricK_CoefficientController.setValue(0); quadricL_CoefficientController.setValue(0);
			quadricM_CoefficientController.setValue(0); quadricN_CoefficientController.setValue(1); quadricO_CoefficientController.setValue(0); quadricP_CoefficientController.setValue(0);
				// 0, 1, 1, 0,
				// 1, 0, 0, 1,
				// 1, 0, 0, 0,
				// 0, 1, 0, 0
		}

		// X -> A: 1, F: -1

		needChangeQuadricCoefficient = true;
		needChangeShapePreset = false;
	}


	if (needChangeQuadricCoefficient)
	{
		pathTracingUniforms.uQuadricShapePresetMatrix.value.set(
			quadricA_CoefficientController.getValue(), quadricB_CoefficientController.getValue(), quadricC_CoefficientController.getValue(), quadricD_CoefficientController.getValue(),
			quadricE_CoefficientController.getValue(), quadricF_CoefficientController.getValue(), quadricG_CoefficientController.getValue(), quadricH_CoefficientController.getValue(),
			quadricI_CoefficientController.getValue(), quadricJ_CoefficientController.getValue(), quadricK_CoefficientController.getValue(), quadricL_CoefficientController.getValue(),
			quadricM_CoefficientController.getValue(), quadricN_CoefficientController.getValue(), quadricO_CoefficientController.getValue(), quadricP_CoefficientController.getValue()
		);

		cameraIsMoving = true;
		needChangeQuadricCoefficient = false;
	}

	// QUADRIC SHAPE (if its transform is dynamically changing)
	///pathTracingUniforms.uQuadricShapeInvMatrix.value.copy(quadricShape.matrixWorld).invert();

	// INFO
	cameraInfoElement.innerHTML = "FOV: " + worldCamera.fov + " / Aperture: " + apertureSize.toFixed(2) + " / FocusDistance: " + focusDistance + "<br>" + "Samples: " + sampleCounter;

} // end function updateVariablesAndUniforms()



init(); // init app and start animating