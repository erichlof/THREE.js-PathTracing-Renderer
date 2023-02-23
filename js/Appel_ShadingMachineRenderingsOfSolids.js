// scene/demo-specific variables go here
let CSG_shapeA, CSG_shapeB, CSG_shapeC, CSG_shapeD, CSG_shapeE, CSG_shapeF;
let A_SkewMatrix = new THREE.Matrix4();
let B_SkewMatrix = new THREE.Matrix4();
let C_SkewMatrix = new THREE.Matrix4();
let D_SkewMatrix = new THREE.Matrix4();
let E_SkewMatrix = new THREE.Matrix4();
let F_SkewMatrix = new THREE.Matrix4();
let uniformScale = 1;
let lightTexture, medLightTexture, mediumTexture, medDarkTexture, darkTexture;
let imageTexturesTotalCount = 5;
let numOfImageTexturesLoaded = 0;

let sceneFrom1968Paper_PresetController, sceneFrom1968Paper_PresetObject;
let needChangeScenePreset = false;

let sunLight_DirectionXController, sunLight_DirectionXObject;
let sunLight_DirectionZController, sunLight_DirectionZObject;
let needChangeSunLightDirection = false;

let transformA_Folder, positionA_Folder, scaleA_Folder, skewA_Folder, rotationA_Folder;
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
let needChangeAPosition = false;
let needChangeAScaleUniform = false;
let needChangeAScale = false;
let needChangeASkew = false;
let needChangeARotation = false;
let needChangeAShapeType = false;
let needChangeAParameterK = false;
let currentAShapeType = '';

let transformB_Folder, positionB_Folder, scaleB_Folder, skewB_Folder, rotationB_Folder;
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
let needChangeBPosition = false;
let needChangeBScaleUniform = false;
let needChangeBScale = false;
let needChangeBSkew = false;
let needChangeBRotation = false;
let needChangeBShapeType = false;
let needChangeBParameterK = false;
let currentBShapeType = '';

let transformC_Folder, positionC_Folder, scaleC_Folder, skewC_Folder, rotationC_Folder;
let transformC_PositionXController, transformC_PositionXObject;
let transformC_PositionYController, transformC_PositionYObject;
let transformC_PositionZController, transformC_PositionZObject;
let transformC_ScaleUniformController, transformC_ScaleUniformObject;
let transformC_ScaleXController, transformC_ScaleXObject;
let transformC_ScaleYController, transformC_ScaleYObject;
let transformC_ScaleZController, transformC_ScaleZObject;
let transformC_SkewX_YController, transformC_SkewX_YObject;
let transformC_SkewX_ZController, transformC_SkewX_ZObject;
let transformC_SkewY_XController, transformC_SkewY_XObject;
let transformC_SkewY_ZController, transformC_SkewY_ZObject;
let transformC_SkewZ_XController, transformC_SkewZ_XObject;
let transformC_SkewZ_YController, transformC_SkewZ_YObject;
let transformC_RotationXController, transformC_RotationXObject;
let transformC_RotationYController, transformC_RotationYObject;
let transformC_RotationZController, transformC_RotationZObject;
let shapeC_TypeController, shapeC_TypeObject;
let parameterC_kController, parameterC_kObject;
let needChangeCPosition = false;
let needChangeCScaleUniform = false;
let needChangeCScale = false;
let needChangeCSkew = false;
let needChangeCRotation = false;
let needChangeCShapeType = false;
let needChangeCParameterK = false;
let currentCShapeType = '';

let transformD_Folder, positionD_Folder, scaleD_Folder, skewD_Folder, rotationD_Folder;
let transformD_PositionXController, transformD_PositionXObject;
let transformD_PositionYController, transformD_PositionYObject;
let transformD_PositionZController, transformD_PositionZObject;
let transformD_ScaleUniformController, transformD_ScaleUniformObject;
let transformD_ScaleXController, transformD_ScaleXObject;
let transformD_ScaleYController, transformD_ScaleYObject;
let transformD_ScaleZController, transformD_ScaleZObject;
let transformD_SkewX_YController, transformD_SkewX_YObject;
let transformD_SkewX_ZController, transformD_SkewX_ZObject;
let transformD_SkewY_XController, transformD_SkewY_XObject;
let transformD_SkewY_ZController, transformD_SkewY_ZObject;
let transformD_SkewZ_XController, transformD_SkewZ_XObject;
let transformD_SkewZ_YController, transformD_SkewZ_YObject;
let transformD_RotationXController, transformD_RotationXObject;
let transformD_RotationYController, transformD_RotationYObject;
let transformD_RotationZController, transformD_RotationZObject;
let shapeD_TypeController, shapeD_TypeObject;
let parameterD_kController, parameterD_kObject;
let needChangeDPosition = false;
let needChangeDScaleUniform = false;
let needChangeDScale = false;
let needChangeDSkew = false;
let needChangeDRotation = false;
let needChangeDShapeType = false;
let needChangeDParameterK = false;
let currentDShapeType = '';

let transformE_Folder, positionE_Folder, scaleE_Folder, skewE_Folder, rotationE_Folder;
let transformE_PositionXController, transformE_PositionXObject;
let transformE_PositionYController, transformE_PositionYObject;
let transformE_PositionZController, transformE_PositionZObject;
let transformE_ScaleUniformController, transformE_ScaleUniformObject;
let transformE_ScaleXController, transformE_ScaleXObject;
let transformE_ScaleYController, transformE_ScaleYObject;
let transformE_ScaleZController, transformE_ScaleZObject;
let transformE_SkewX_YController, transformE_SkewX_YObject;
let transformE_SkewX_ZController, transformE_SkewX_ZObject;
let transformE_SkewY_XController, transformE_SkewY_XObject;
let transformE_SkewY_ZController, transformE_SkewY_ZObject;
let transformE_SkewZ_XController, transformE_SkewZ_XObject;
let transformE_SkewZ_YController, transformE_SkewZ_YObject;
let transformE_RotationXController, transformE_RotationXObject;
let transformE_RotationYController, transformE_RotationYObject;
let transformE_RotationZController, transformE_RotationZObject;
let shapeE_TypeController, shapeE_TypeObject;
let parameterE_kController, parameterE_kObject;
let needChangeEPosition = false;
let needChangeEScaleUniform = false;
let needChangeEScale = false;
let needChangeESkew = false;
let needChangeERotation = false;
let needChangeEShapeType = false;
let needChangeEParameterK = false;
let currentEShapeType = '';

let transformF_Folder, positionF_Folder, scaleF_Folder, skewF_Folder, rotationF_Folder;
let transformF_PositionXController, transformF_PositionXObject;
let transformF_PositionYController, transformF_PositionYObject;
let transformF_PositionZController, transformF_PositionZObject;
let transformF_ScaleUniformController, transformF_ScaleUniformObject;
let transformF_ScaleXController, transformF_ScaleXObject;
let transformF_ScaleYController, transformF_ScaleYObject;
let transformF_ScaleZController, transformF_ScaleZObject;
let transformF_SkewX_YController, transformF_SkewX_YObject;
let transformF_SkewX_ZController, transformF_SkewX_ZObject;
let transformF_SkewY_XController, transformF_SkewY_XObject;
let transformF_SkewY_ZController, transformF_SkewY_ZObject;
let transformF_SkewZ_XController, transformF_SkewZ_XObject;
let transformF_SkewZ_YController, transformF_SkewZ_YObject;
let transformF_RotationXController, transformF_RotationXObject;
let transformF_RotationYController, transformF_RotationYObject;
let transformF_RotationZController, transformF_RotationZObject;
let shapeF_TypeController, shapeF_TypeObject;
let parameterF_kController, parameterF_kObject;
let needChangeFPosition = false;
let needChangeFScaleUniform = false;
let needChangeFScale = false;
let needChangeFSkew = false;
let needChangeFRotation = false;
let needChangeFShapeType = false;
let needChangeFParameterK = false;
let currentFShapeType = '';

let csgOperationAB_TypeController, csgOperationAB_TypeObject;
let csgOperationBC_TypeController, csgOperationBC_TypeObject;
let csgOperationCD_TypeController, csgOperationCD_TypeObject;
let csgOperationDE_TypeController, csgOperationDE_TypeObject;
let csgOperationEF_TypeController, csgOperationEF_TypeObject;
let needChangeOperationABType = false;
let needChangeOperationBCType = false;
let needChangeOperationCDType = false;
let needChangeOperationDEType = false;
let needChangeOperationEFType = false;
let kValue = 0;

let sunDirection = new THREE.Vector3();


function init_GUI()
{
	sceneFrom1968Paper_PresetObject = { Appel1968Scene_Preset: 'Scene 1' };

	sunLight_DirectionXObject = { sunLight_DirX: 0 };
	sunLight_DirectionZObject = { sunLight_DirZ: 0 };

	// SHAPE A
	shapeA_TypeObject = { A_Shape: 'Box' };
	parameterA_kObject = { A_kParameter: 1 };
	transformA_PositionXObject = { positionX: -100 };
	transformA_PositionYObject = { positionY: -5 };
	transformA_PositionZObject = { positionZ: -100 };
	transformA_ScaleUniformObject = { uniformScale: 20 };
	transformA_ScaleXObject = { scaleX: 20 };
	transformA_ScaleYObject = { scaleY: 20 };
	transformA_ScaleZObject = { scaleZ: 20 };
	transformA_RotationXObject = { rotationX: 0 };
	transformA_RotationYObject = { rotationY: 0 };
	transformA_RotationZObject = { rotationZ: 0 };
	transformA_SkewX_YObject = { skewX_Y: 0 };
	transformA_SkewX_ZObject = { skewX_Z: 0 };
	transformA_SkewY_XObject = { skewY_X: 0 };
	transformA_SkewY_ZObject = { skewY_Z: 0 };
	transformA_SkewZ_XObject = { skewZ_X: 0 };
	transformA_SkewZ_YObject = { skewZ_Y: 0 };
	
	csgOperationAB_TypeObject = { CSG_OperationAB: 'Union (A + B)' };

	// SHAPE B
	shapeB_TypeObject = { B_Shape: 'Box' };
	parameterB_kObject = { B_kParameter: 1 };
	transformB_PositionXObject = { positionX: -100 };
	transformB_PositionYObject = { positionY: -5 };
	transformB_PositionZObject = { positionZ: -100 };
	transformB_ScaleUniformObject = { uniformScale: 17 };
	transformB_ScaleXObject = { scaleX: 17 };
	transformB_ScaleYObject = { scaleY: 17 };
	transformB_ScaleZObject = { scaleZ: 17 };
	transformB_RotationXObject = { rotationX: 0 };
	transformB_RotationYObject = { rotationY: 0 };
	transformB_RotationZObject = { rotationZ: 0 };
	transformB_SkewX_YObject = { skewX_Y: 0 };
	transformB_SkewX_ZObject = { skewX_Z: 0 };
	transformB_SkewY_XObject = { skewY_X: 0 };
	transformB_SkewY_ZObject = { skewY_Z: 0 };
	transformB_SkewZ_XObject = { skewZ_X: 0 };
	transformB_SkewZ_YObject = { skewZ_Y: 0 };

	csgOperationBC_TypeObject = { CSG_OperationBC: 'Union (B + C)' };

	// SHAPE C
	shapeC_TypeObject = { C_Shape: 'Box' };
	parameterC_kObject = { C_kParameter: 1 };
	transformC_PositionXObject = { positionX: -50 };
	transformC_PositionYObject = { positionY: -5 };
	transformC_PositionZObject = { positionZ: -100 };
	transformC_ScaleUniformObject = { uniformScale: 12 };
	transformC_ScaleXObject = { scaleX: 12 };
	transformC_ScaleYObject = { scaleY: 12 };
	transformC_ScaleZObject = { scaleZ: 12 };
	transformC_RotationXObject = { rotationX: 0 };
	transformC_RotationYObject = { rotationY: 0 };
	transformC_RotationZObject = { rotationZ: 0 };
	transformC_SkewX_YObject = { skewX_Y: 0 };
	transformC_SkewX_ZObject = { skewX_Z: 0 };
	transformC_SkewY_XObject = { skewY_X: 0 };
	transformC_SkewY_ZObject = { skewY_Z: 0 };
	transformC_SkewZ_XObject = { skewZ_X: 0 };
	transformC_SkewZ_YObject = { skewZ_Y: 0 };
	
	csgOperationCD_TypeObject = { CSG_OperationCD: 'Union (C + D)' };

	// SHAPE D
	shapeD_TypeObject = { D_Shape: 'Box' };
	parameterD_kObject = { D_kParameter: 1 };
	transformD_PositionXObject = { positionX: 0 };
	transformD_PositionYObject = { positionY: 15 };
	transformD_PositionZObject = { positionZ: -100 };
	transformD_ScaleUniformObject = { uniformScale: 15 };
	transformD_ScaleXObject = { scaleX: 15 };
	transformD_ScaleYObject = { scaleY: 15 };
	transformD_ScaleZObject = { scaleZ: 15 };
	transformD_RotationXObject = { rotationX: 0 };
	transformD_RotationYObject = { rotationY: 0 };
	transformD_RotationZObject = { rotationZ: 0 };
	transformD_SkewX_YObject = { skewX_Y: 0 };
	transformD_SkewX_ZObject = { skewX_Z: 0 };
	transformD_SkewY_XObject = { skewY_X: 0 };
	transformD_SkewY_ZObject = { skewY_Z: 0 };
	transformD_SkewZ_XObject = { skewZ_X: 0 };
	transformD_SkewZ_YObject = { skewZ_Y: 0 };

	csgOperationDE_TypeObject = { CSG_OperationDE: 'Union (D + E)' };

	// SHAPE E
	shapeE_TypeObject = { E_Shape: 'Box' };
	parameterE_kObject = { E_kParameter: 1 };
	transformE_PositionXObject = { positionX: 50 };
	transformE_PositionYObject = { positionY: 15 };
	transformE_PositionZObject = { positionZ: -100 };
	transformE_ScaleUniformObject = { uniformScale: 10 };
	transformE_ScaleXObject = { scaleX: 10 };
	transformE_ScaleYObject = { scaleY: 10 };
	transformE_ScaleZObject = { scaleZ: 10 };
	transformE_RotationXObject = { rotationX: 0 };
	transformE_RotationYObject = { rotationY: 0 };
	transformE_RotationZObject = { rotationZ: 0 };
	transformE_SkewX_YObject = { skewX_Y: 0 };
	transformE_SkewX_ZObject = { skewX_Z: 0 };
	transformE_SkewY_XObject = { skewY_X: 0 };
	transformE_SkewY_ZObject = { skewY_Z: 0 };
	transformE_SkewZ_XObject = { skewZ_X: 0 };
	transformE_SkewZ_YObject = { skewZ_Y: 0 };
	
	csgOperationEF_TypeObject = { CSG_OperationEF: 'Union (E + F)' };

	// SHAPE F
	shapeF_TypeObject = { F_Shape: 'Box' };
	parameterF_kObject = { F_kParameter: 1 };
	transformF_PositionXObject = { positionX: 100 };
	transformF_PositionYObject = { positionY: 20 };
	transformF_PositionZObject = { positionZ: -100 };
	transformF_ScaleUniformObject = { uniformScale: 10 };
	transformF_ScaleXObject = { scaleX: 10 };
	transformF_ScaleYObject = { scaleY: 10 };
	transformF_ScaleZObject = { scaleZ: 10 };
	transformF_RotationXObject = { rotationX: 0 };
	transformF_RotationYObject = { rotationY: 0 };
	transformF_RotationZObject = { rotationZ: 0 };
	transformF_SkewX_YObject = { skewX_Y: 0 };
	transformF_SkewX_ZObject = { skewX_Z: 0 };
	transformF_SkewY_XObject = { skewY_X: 0 };
	transformF_SkewY_ZObject = { skewY_Z: 0 };
	transformF_SkewZ_XObject = { skewZ_X: 0 };
	transformF_SkewZ_YObject = { skewZ_Y: 0 };
	
	function handleScenePresetChange() { needChangeScenePreset = true; }

	function handleSunLightDirectionChange() { needChangeSunLightDirection = true; }

	function handleOperationABTypeChange() { needChangeOperationABType = true; }
	function handleOperationBCTypeChange() { needChangeOperationBCType = true; }
	function handleOperationCDTypeChange() { needChangeOperationCDType = true; }
	function handleOperationDETypeChange() { needChangeOperationDEType = true; }
	function handleOperationEFTypeChange() { needChangeOperationEFType = true; }

	function handleAPositionChange() { needChangeAPosition = true; }
	function handleAScaleUniformChange() { needChangeAScaleUniform = true; }
	function handleAScaleChange() { needChangeAScale = true; }
	function handleASkewChange() { needChangeASkew = true; }
	function handleARotationChange() { needChangeARotation = true; }
	function handleAShapeTypeChange() { needChangeAShapeType = true; }
	function handleAParameterKChange() { needChangeAParameterK = true; }

	function handleBPositionChange() { needChangeBPosition = true; }
	function handleBScaleUniformChange() { needChangeBScaleUniform = true; }
	function handleBScaleChange() { needChangeBScale = true; }
	function handleBSkewChange() { needChangeBSkew = true; }
	function handleBRotationChange() { needChangeBRotation = true; }
	function handleBShapeTypeChange() { needChangeBShapeType = true; }
	function handleBParameterKChange() { needChangeBParameterK = true; }

	function handleCPositionChange() { needChangeCPosition = true; }
	function handleCScaleUniformChange() { needChangeCScaleUniform = true; }
	function handleCScaleChange() { needChangeCScale = true; }
	function handleCSkewChange() { needChangeCSkew = true; }
	function handleCRotationChange() { needChangeCRotation = true; }
	function handleCShapeTypeChange() { needChangeCShapeType = true; }
	function handleCParameterKChange() { needChangeCParameterK = true; }

	function handleDPositionChange() { needChangeDPosition = true; }
	function handleDScaleUniformChange() { needChangeDScaleUniform = true; }
	function handleDScaleChange() { needChangeDScale = true; }
	function handleDSkewChange() { needChangeDSkew = true; }
	function handleDRotationChange() { needChangeDRotation = true; }
	function handleDShapeTypeChange() { needChangeDShapeType = true; }
	function handleDParameterKChange() { needChangeDParameterK = true; }

	function handleEPositionChange() { needChangeEPosition = true; }
	function handleEScaleUniformChange() { needChangeEScaleUniform = true; }
	function handleEScaleChange() { needChangeEScale = true; }
	function handleESkewChange() { needChangeESkew = true; }
	function handleERotationChange() { needChangeERotation = true; }
	function handleEShapeTypeChange() { needChangeEShapeType = true; }
	function handleEParameterKChange() { needChangeEParameterK = true; }

	function handleFPositionChange() { needChangeFPosition = true; }
	function handleFScaleUniformChange() { needChangeFScaleUniform = true; }
	function handleFScaleChange() { needChangeFScale = true; }
	function handleFSkewChange() { needChangeFSkew = true; }
	function handleFRotationChange() { needChangeFRotation = true; }
	function handleFShapeTypeChange() { needChangeFShapeType = true; }
	function handleFParameterKChange() { needChangeFParameterK = true; }
	

	// Scene preset
	sceneFrom1968Paper_PresetController = gui.add(sceneFrom1968Paper_PresetObject, 'Appel1968Scene_Preset', ['Scene 1', 'Scene 2', 'Scene 3', 'Scene 4', 'Scene 5', 'Scene 6']).onChange(handleScenePresetChange);

	// SunLight Direction
	sunLight_DirectionXController = gui.add(sunLight_DirectionXObject, 'sunLight_DirX', -2, 2, 0.02).onChange(handleSunLightDirectionChange);
	sunLight_DirectionZController = gui.add(sunLight_DirectionZObject, 'sunLight_DirZ', -2, 2, 0.02).onChange(handleSunLightDirectionChange);

	// Shape A
	shapeA_TypeController = gui.add(shapeA_TypeObject, 'A_Shape', ['Box', 'ConicalPrism']).onChange(handleAShapeTypeChange);
	
	transformA_Folder = gui.addFolder('A_Transform');

	parameterA_kController = transformA_Folder.add(parameterA_kObject, 'A_kParameter', 0, 1, 0.01).onChange(handleAParameterKChange);

	positionA_Folder = transformA_Folder.addFolder('A_Position');
	transformA_PositionXController = positionA_Folder.add(transformA_PositionXObject, 'positionX', -100, 100, 1).onChange(handleAPositionChange);
	transformA_PositionYController = positionA_Folder.add(transformA_PositionYObject, 'positionY', -100, 100, 1).onChange(handleAPositionChange);
	transformA_PositionZController = positionA_Folder.add(transformA_PositionZObject, 'positionZ', -100, 100, 1).onChange(handleAPositionChange);

	scaleA_Folder = transformA_Folder.addFolder('A_Scale');
	transformA_ScaleUniformController = scaleA_Folder.add(transformA_ScaleUniformObject, 'uniformScale', 1, 100, 1).onChange(handleAScaleUniformChange);
	transformA_ScaleXController = scaleA_Folder.add(transformA_ScaleXObject, 'scaleX', 1, 100, 1).onChange(handleAScaleChange);
	transformA_ScaleYController = scaleA_Folder.add(transformA_ScaleYObject, 'scaleY', 1, 100, 1).onChange(handleAScaleChange);
	transformA_ScaleZController = scaleA_Folder.add(transformA_ScaleZObject, 'scaleZ', 1, 100, 1).onChange(handleAScaleChange);

	rotationA_Folder = transformA_Folder.addFolder('A_Rotation');
	transformA_RotationXController = rotationA_Folder.add(transformA_RotationXObject, 'rotationX', 0, 359, 1).onChange(handleARotationChange);
	transformA_RotationYController = rotationA_Folder.add(transformA_RotationYObject, 'rotationY', 0, 359, 1).onChange(handleARotationChange);
	transformA_RotationZController = rotationA_Folder.add(transformA_RotationZObject, 'rotationZ', 0, 359, 1).onChange(handleARotationChange);

	skewA_Folder = transformA_Folder.addFolder('A_Skew');
	transformA_SkewX_YController = skewA_Folder.add(transformA_SkewX_YObject, 'skewX_Y', -0.9, 0.9, 0.1).onChange(handleASkewChange);
	transformA_SkewX_ZController = skewA_Folder.add(transformA_SkewX_ZObject, 'skewX_Z', -0.9, 0.9, 0.1).onChange(handleASkewChange);
	transformA_SkewY_XController = skewA_Folder.add(transformA_SkewY_XObject, 'skewY_X', -0.9, 0.9, 0.1).onChange(handleASkewChange);
	transformA_SkewY_ZController = skewA_Folder.add(transformA_SkewY_ZObject, 'skewY_Z', -0.9, 0.9, 0.1).onChange(handleASkewChange);
	transformA_SkewZ_XController = skewA_Folder.add(transformA_SkewZ_XObject, 'skewZ_X', -0.9, 0.9, 0.1).onChange(handleASkewChange);
	transformA_SkewZ_YController = skewA_Folder.add(transformA_SkewZ_YObject, 'skewZ_Y', -0.9, 0.9, 0.1).onChange(handleASkewChange);

	// A B Operation
	csgOperationAB_TypeController = gui.add(csgOperationAB_TypeObject, 'CSG_OperationAB', ['Union (A + B)', 'Difference (A - B)']).onChange(handleOperationABTypeChange);

	// Shape B
	shapeB_TypeController = gui.add(shapeB_TypeObject, 'B_Shape', ['Box', 'ConicalPrism']).onChange(handleBShapeTypeChange);

	transformB_Folder = gui.addFolder('B_Transform');

	parameterB_kController = transformB_Folder.add(parameterB_kObject, 'B_kParameter', 0, 1, 0.01).onChange(handleBParameterKChange);

	positionB_Folder = transformB_Folder.addFolder('B_Position');
	transformB_PositionXController = positionB_Folder.add(transformB_PositionXObject, 'positionX', -100, 100, 1).onChange(handleBPositionChange);
	transformB_PositionYController = positionB_Folder.add(transformB_PositionYObject, 'positionY', -100, 100, 1).onChange(handleBPositionChange);
	transformB_PositionZController = positionB_Folder.add(transformB_PositionZObject, 'positionZ', -100, 100, 1).onChange(handleBPositionChange);

	scaleB_Folder = transformB_Folder.addFolder('B_Scale');
	transformB_ScaleUniformController = scaleB_Folder.add(transformB_ScaleUniformObject, 'uniformScale', 1, 100, 1).onChange(handleBScaleUniformChange);
	transformB_ScaleXController = scaleB_Folder.add(transformB_ScaleXObject, 'scaleX', 1, 100, 1).onChange(handleBScaleChange);
	transformB_ScaleYController = scaleB_Folder.add(transformB_ScaleYObject, 'scaleY', 1, 100, 1).onChange(handleBScaleChange);
	transformB_ScaleZController = scaleB_Folder.add(transformB_ScaleZObject, 'scaleZ', 1, 100, 1).onChange(handleBScaleChange);

	rotationB_Folder = transformB_Folder.addFolder('B_Rotation');
	transformB_RotationXController = rotationB_Folder.add(transformB_RotationXObject, 'rotationX', 0, 359, 1).onChange(handleBRotationChange);
	transformB_RotationYController = rotationB_Folder.add(transformB_RotationYObject, 'rotationY', 0, 359, 1).onChange(handleBRotationChange);
	transformB_RotationZController = rotationB_Folder.add(transformB_RotationZObject, 'rotationZ', 0, 359, 1).onChange(handleBRotationChange);

	skewB_Folder = transformB_Folder.addFolder('B_Skew');
	transformB_SkewX_YController = skewB_Folder.add(transformB_SkewX_YObject, 'skewX_Y', -0.9, 0.9, 0.1).onChange(handleBSkewChange);
	transformB_SkewX_ZController = skewB_Folder.add(transformB_SkewX_ZObject, 'skewX_Z', -0.9, 0.9, 0.1).onChange(handleBSkewChange);
	transformB_SkewY_XController = skewB_Folder.add(transformB_SkewY_XObject, 'skewY_X', -0.9, 0.9, 0.1).onChange(handleBSkewChange);
	transformB_SkewY_ZController = skewB_Folder.add(transformB_SkewY_ZObject, 'skewY_Z', -0.9, 0.9, 0.1).onChange(handleBSkewChange);
	transformB_SkewZ_XController = skewB_Folder.add(transformB_SkewZ_XObject, 'skewZ_X', -0.9, 0.9, 0.1).onChange(handleBSkewChange);
	transformB_SkewZ_YController = skewB_Folder.add(transformB_SkewZ_YObject, 'skewZ_Y', -0.9, 0.9, 0.1).onChange(handleBSkewChange);

	// B C Operation
	csgOperationBC_TypeController = gui.add(csgOperationBC_TypeObject, 'CSG_OperationBC', ['Union (B + C)', 'Difference (B - C)']).onChange(handleOperationBCTypeChange);

	// Shape C
	shapeC_TypeController = gui.add(shapeC_TypeObject, 'C_Shape', ['Box', 'ConicalPrism']).onChange(handleCShapeTypeChange);

	transformC_Folder = gui.addFolder('C_Transform');

	parameterC_kController = transformC_Folder.add(parameterC_kObject, 'C_kParameter', 0, 1, 0.01).onChange(handleCParameterKChange);

	positionC_Folder = transformC_Folder.addFolder('C_Position');
	transformC_PositionXController = positionC_Folder.add(transformC_PositionXObject, 'positionX', -100, 100, 1).onChange(handleCPositionChange);
	transformC_PositionYController = positionC_Folder.add(transformC_PositionYObject, 'positionY', -100, 100, 1).onChange(handleCPositionChange);
	transformC_PositionZController = positionC_Folder.add(transformC_PositionZObject, 'positionZ', -100, 100, 1).onChange(handleCPositionChange);

	scaleC_Folder = transformC_Folder.addFolder('C_Scale');
	transformC_ScaleUniformController = scaleC_Folder.add(transformC_ScaleUniformObject, 'uniformScale', 1, 100, 1).onChange(handleCScaleUniformChange);
	transformC_ScaleXController = scaleC_Folder.add(transformC_ScaleXObject, 'scaleX', 1, 100, 1).onChange(handleCScaleChange);
	transformC_ScaleYController = scaleC_Folder.add(transformC_ScaleYObject, 'scaleY', 1, 100, 1).onChange(handleCScaleChange);
	transformC_ScaleZController = scaleC_Folder.add(transformC_ScaleZObject, 'scaleZ', 1, 100, 1).onChange(handleCScaleChange);

	rotationC_Folder = transformC_Folder.addFolder('C_Rotation');
	transformC_RotationXController = rotationC_Folder.add(transformC_RotationXObject, 'rotationX', 0, 359, 1).onChange(handleCRotationChange);
	transformC_RotationYController = rotationC_Folder.add(transformC_RotationYObject, 'rotationY', 0, 359, 1).onChange(handleCRotationChange);
	transformC_RotationZController = rotationC_Folder.add(transformC_RotationZObject, 'rotationZ', 0, 359, 1).onChange(handleCRotationChange);

	skewC_Folder = transformC_Folder.addFolder('C_Skew');
	transformC_SkewX_YController = skewC_Folder.add(transformC_SkewX_YObject, 'skewX_Y', -0.9, 0.9, 0.1).onChange(handleCSkewChange);
	transformC_SkewX_ZController = skewC_Folder.add(transformC_SkewX_ZObject, 'skewX_Z', -0.9, 0.9, 0.1).onChange(handleCSkewChange);
	transformC_SkewY_XController = skewC_Folder.add(transformC_SkewY_XObject, 'skewY_X', -0.9, 0.9, 0.1).onChange(handleCSkewChange);
	transformC_SkewY_ZController = skewC_Folder.add(transformC_SkewY_ZObject, 'skewY_Z', -0.9, 0.9, 0.1).onChange(handleCSkewChange);
	transformC_SkewZ_XController = skewC_Folder.add(transformC_SkewZ_XObject, 'skewZ_X', -0.9, 0.9, 0.1).onChange(handleCSkewChange);
	transformC_SkewZ_YController = skewC_Folder.add(transformC_SkewZ_YObject, 'skewZ_Y', -0.9, 0.9, 0.1).onChange(handleCSkewChange);


	// C D Operation
	csgOperationCD_TypeController = gui.add(csgOperationCD_TypeObject, 'CSG_OperationCD', ['Union (C + D)', 'Difference (C - D)']).onChange(handleOperationCDTypeChange);

	// Shape D
	shapeD_TypeController = gui.add(shapeD_TypeObject, 'D_Shape', ['Box', 'ConicalPrism']).onChange(handleDShapeTypeChange);

	transformD_Folder = gui.addFolder('D_Transform');

	parameterD_kController = transformD_Folder.add(parameterD_kObject, 'D_kParameter', 0, 1, 0.01).onChange(handleDParameterKChange);

	positionD_Folder = transformD_Folder.addFolder('D_Position');
	transformD_PositionXController = positionD_Folder.add(transformD_PositionXObject, 'positionX', -100, 100, 1).onChange(handleDPositionChange);
	transformD_PositionYController = positionD_Folder.add(transformD_PositionYObject, 'positionY', -100, 100, 1).onChange(handleDPositionChange);
	transformD_PositionZController = positionD_Folder.add(transformD_PositionZObject, 'positionZ', -100, 100, 1).onChange(handleDPositionChange);

	scaleD_Folder = transformD_Folder.addFolder('D_Scale');
	transformD_ScaleUniformController = scaleD_Folder.add(transformD_ScaleUniformObject, 'uniformScale', 1, 100, 1).onChange(handleDScaleUniformChange);
	transformD_ScaleXController = scaleD_Folder.add(transformD_ScaleXObject, 'scaleX', 1, 100, 1).onChange(handleDScaleChange);
	transformD_ScaleYController = scaleD_Folder.add(transformD_ScaleYObject, 'scaleY', 1, 100, 1).onChange(handleDScaleChange);
	transformD_ScaleZController = scaleD_Folder.add(transformD_ScaleZObject, 'scaleZ', 1, 100, 1).onChange(handleDScaleChange);

	rotationD_Folder = transformD_Folder.addFolder('D_Rotation');
	transformD_RotationXController = rotationD_Folder.add(transformD_RotationXObject, 'rotationX', 0, 359, 1).onChange(handleDRotationChange);
	transformD_RotationYController = rotationD_Folder.add(transformD_RotationYObject, 'rotationY', 0, 359, 1).onChange(handleDRotationChange);
	transformD_RotationZController = rotationD_Folder.add(transformD_RotationZObject, 'rotationZ', 0, 359, 1).onChange(handleDRotationChange);

	skewD_Folder = transformD_Folder.addFolder('D_Skew');
	transformD_SkewX_YController = skewD_Folder.add(transformD_SkewX_YObject, 'skewX_Y', -0.9, 0.9, 0.1).onChange(handleDSkewChange);
	transformD_SkewX_ZController = skewD_Folder.add(transformD_SkewX_ZObject, 'skewX_Z', -0.9, 0.9, 0.1).onChange(handleDSkewChange);
	transformD_SkewY_XController = skewD_Folder.add(transformD_SkewY_XObject, 'skewY_X', -0.9, 0.9, 0.1).onChange(handleDSkewChange);
	transformD_SkewY_ZController = skewD_Folder.add(transformD_SkewY_ZObject, 'skewY_Z', -0.9, 0.9, 0.1).onChange(handleDSkewChange);
	transformD_SkewZ_XController = skewD_Folder.add(transformD_SkewZ_XObject, 'skewZ_X', -0.9, 0.9, 0.1).onChange(handleDSkewChange);
	transformD_SkewZ_YController = skewD_Folder.add(transformD_SkewZ_YObject, 'skewZ_Y', -0.9, 0.9, 0.1).onChange(handleDSkewChange);


	// D E Operation
	csgOperationDE_TypeController = gui.add(csgOperationDE_TypeObject, 'CSG_OperationDE', ['Union (D + E)', 'Difference (D - E)']).onChange(handleOperationDETypeChange);

	// Shape E
	shapeE_TypeController = gui.add(shapeE_TypeObject, 'E_Shape', ['Box', 'ConicalPrism']).onChange(handleEShapeTypeChange);

	transformE_Folder = gui.addFolder('E_Transform');

	parameterE_kController = transformE_Folder.add(parameterE_kObject, 'E_kParameter', 0, 1, 0.01).onChange(handleEParameterKChange);

	positionE_Folder = transformE_Folder.addFolder('E_Position');
	transformE_PositionXController = positionE_Folder.add(transformE_PositionXObject, 'positionX', -100, 100, 1).onChange(handleEPositionChange);
	transformE_PositionYController = positionE_Folder.add(transformE_PositionYObject, 'positionY', -100, 100, 1).onChange(handleEPositionChange);
	transformE_PositionZController = positionE_Folder.add(transformE_PositionZObject, 'positionZ', -100, 100, 1).onChange(handleEPositionChange);

	scaleE_Folder = transformE_Folder.addFolder('E_Scale');
	transformE_ScaleUniformController = scaleE_Folder.add(transformE_ScaleUniformObject, 'uniformScale', 1, 100, 1).onChange(handleEScaleUniformChange);
	transformE_ScaleXController = scaleE_Folder.add(transformE_ScaleXObject, 'scaleX', 1, 100, 1).onChange(handleEScaleChange);
	transformE_ScaleYController = scaleE_Folder.add(transformE_ScaleYObject, 'scaleY', 1, 100, 1).onChange(handleEScaleChange);
	transformE_ScaleZController = scaleE_Folder.add(transformE_ScaleZObject, 'scaleZ', 1, 100, 1).onChange(handleEScaleChange);

	rotationE_Folder = transformE_Folder.addFolder('E_Rotation');
	transformE_RotationXController = rotationE_Folder.add(transformE_RotationXObject, 'rotationX', 0, 359, 1).onChange(handleERotationChange);
	transformE_RotationYController = rotationE_Folder.add(transformE_RotationYObject, 'rotationY', 0, 359, 1).onChange(handleERotationChange);
	transformE_RotationZController = rotationE_Folder.add(transformE_RotationZObject, 'rotationZ', 0, 359, 1).onChange(handleERotationChange);

	skewE_Folder = transformE_Folder.addFolder('E_Skew');
	transformE_SkewX_YController = skewE_Folder.add(transformE_SkewX_YObject, 'skewX_Y', -0.9, 0.9, 0.1).onChange(handleESkewChange);
	transformE_SkewX_ZController = skewE_Folder.add(transformE_SkewX_ZObject, 'skewX_Z', -0.9, 0.9, 0.1).onChange(handleESkewChange);
	transformE_SkewY_XController = skewE_Folder.add(transformE_SkewY_XObject, 'skewY_X', -0.9, 0.9, 0.1).onChange(handleESkewChange);
	transformE_SkewY_ZController = skewE_Folder.add(transformE_SkewY_ZObject, 'skewY_Z', -0.9, 0.9, 0.1).onChange(handleESkewChange);
	transformE_SkewZ_XController = skewE_Folder.add(transformE_SkewZ_XObject, 'skewZ_X', -0.9, 0.9, 0.1).onChange(handleESkewChange);
	transformE_SkewZ_YController = skewE_Folder.add(transformE_SkewZ_YObject, 'skewZ_Y', -0.9, 0.9, 0.1).onChange(handleESkewChange);


	// E F Operation
	csgOperationEF_TypeController = gui.add(csgOperationEF_TypeObject, 'CSG_OperationEF', ['Union (E + F)', 'Difference (E - F)']).onChange(handleOperationEFTypeChange);

	// Shape F
	shapeF_TypeController = gui.add(shapeF_TypeObject, 'F_Shape', ['Box', 'ConicalPrism']).onChange(handleFShapeTypeChange);

	transformF_Folder = gui.addFolder('F_Transform');

	parameterF_kController = transformF_Folder.add(parameterF_kObject, 'F_kParameter', 0, 1, 0.01).onChange(handleFParameterKChange);

	positionF_Folder = transformF_Folder.addFolder('F_Position');
	transformF_PositionXController = positionF_Folder.add(transformF_PositionXObject, 'positionX', -100, 100, 1).onChange(handleFPositionChange);
	transformF_PositionYController = positionF_Folder.add(transformF_PositionYObject, 'positionY', -100, 100, 1).onChange(handleFPositionChange);
	transformF_PositionZController = positionF_Folder.add(transformF_PositionZObject, 'positionZ', -100, 100, 1).onChange(handleFPositionChange);

	scaleF_Folder = transformF_Folder.addFolder('F_Scale');
	transformF_ScaleUniformController = scaleF_Folder.add(transformF_ScaleUniformObject, 'uniformScale', 1, 100, 1).onChange(handleFScaleUniformChange);
	transformF_ScaleXController = scaleF_Folder.add(transformF_ScaleXObject, 'scaleX', 1, 100, 1).onChange(handleFScaleChange);
	transformF_ScaleYController = scaleF_Folder.add(transformF_ScaleYObject, 'scaleY', 1, 100, 1).onChange(handleFScaleChange);
	transformF_ScaleZController = scaleF_Folder.add(transformF_ScaleZObject, 'scaleZ', 1, 100, 1).onChange(handleFScaleChange);

	rotationF_Folder = transformF_Folder.addFolder('F_Rotation');
	transformF_RotationXController = rotationF_Folder.add(transformF_RotationXObject, 'rotationX', 0, 359, 1).onChange(handleFRotationChange);
	transformF_RotationYController = rotationF_Folder.add(transformF_RotationYObject, 'rotationY', 0, 359, 1).onChange(handleFRotationChange);
	transformF_RotationZController = rotationF_Folder.add(transformF_RotationZObject, 'rotationZ', 0, 359, 1).onChange(handleFRotationChange);

	skewF_Folder = transformF_Folder.addFolder('F_Skew');
	transformF_SkewX_YController = skewF_Folder.add(transformF_SkewX_YObject, 'skewX_Y', -0.9, 0.9, 0.1).onChange(handleFSkewChange);
	transformF_SkewX_ZController = skewF_Folder.add(transformF_SkewX_ZObject, 'skewX_Z', -0.9, 0.9, 0.1).onChange(handleFSkewChange);
	transformF_SkewY_XController = skewF_Folder.add(transformF_SkewY_XObject, 'skewY_X', -0.9, 0.9, 0.1).onChange(handleFSkewChange);
	transformF_SkewY_ZController = skewF_Folder.add(transformF_SkewY_ZObject, 'skewY_Z', -0.9, 0.9, 0.1).onChange(handleFSkewChange);
	transformF_SkewZ_XController = skewF_Folder.add(transformF_SkewZ_XObject, 'skewZ_X', -0.9, 0.9, 0.1).onChange(handleFSkewChange);
	transformF_SkewZ_YController = skewF_Folder.add(transformF_SkewZ_YObject, 'skewZ_Y', -0.9, 0.9, 0.1).onChange(handleFSkewChange);


	transformA_Folder.close();
	transformB_Folder.close();
	transformC_Folder.close();
	transformD_Folder.close();
	transformE_Folder.close();
	transformF_Folder.close();

	// jumpstart all the gui change controller handlers so that the pathtracing fragment shader uniforms are correct and up-to-date
	
	handleScenePresetChange();
	handleSunLightDirectionChange();

	handleAPositionChange();
	handleAScaleUniformChange();
	handleAScaleChange();
	handleASkewChange();
	handleARotationChange();
	handleAShapeTypeChange();
	handleAParameterKChange();

	handleOperationABTypeChange();
	
	handleBPositionChange();
	handleBScaleUniformChange();
	handleBScaleChange();
	handleBSkewChange();
	handleBRotationChange();
	handleBShapeTypeChange();
	handleBParameterKChange();

	handleOperationBCTypeChange();

	handleCPositionChange();
	handleCScaleUniformChange();
	handleCScaleChange();
	handleCSkewChange();
	handleCRotationChange();
	handleCShapeTypeChange();
	handleCParameterKChange();

	handleOperationCDTypeChange();

	handleDPositionChange();
	handleDScaleUniformChange();
	handleDScaleChange();
	handleDSkewChange();
	handleDRotationChange();
	handleDShapeTypeChange();
	handleDParameterKChange();

	handleOperationDETypeChange();

	handleEPositionChange();
	handleEScaleUniformChange();
	handleEScaleChange();
	handleESkewChange();
	handleERotationChange();
	handleEShapeTypeChange();
	handleEParameterKChange();

	handleOperationEFTypeChange();

	handleFPositionChange();
	handleFScaleUniformChange();
	handleFScaleChange();
	handleFSkewChange();
	handleFRotationChange();
	handleFShapeTypeChange();
	handleFParameterKChange();

} // end function init_GUI()



// called automatically from within initTHREEjs() function (located in InitCommon.js file)
function initSceneData()
{
	demoFragmentShaderFileName = 'Appel_ShadingRenderingsOfSolids_Fragment.glsl';

	// scene/demo-specific three.js objects setup goes here
	sceneIsDynamic = false;
	
	cameraFlightSpeed = 100;

	apertureChangeSpeed = 20;

	// This is a classic black and white digital plotter scene, so we don't have light source values exceeding 1.0.
	//  All color values will already be in the normalized rgb 0.0-1.0 range, so no tone mapper is needed.
	useToneMapping = false;

	// change webpage's info text to black so it shows up against the white background 
	infoElement.style.color = 'rgb(0,0,0)';
	cameraInfoElement.style.color = 'rgb(0,0,0)';

	// pixelRatio is resolution - range: 0.5(half resolution) to 1.0(full resolution)
	pixelRatio = mouseControl ? 1.0 : 1.0;

	EPS_intersect = 0.01;


	CSG_shapeA = new THREE.Object3D();
	CSG_shapeB = new THREE.Object3D();
	CSG_shapeC = new THREE.Object3D();
	CSG_shapeD = new THREE.Object3D();
	CSG_shapeE = new THREE.Object3D();
	CSG_shapeF = new THREE.Object3D();

	pathTracingScene.add(CSG_shapeA);
	pathTracingScene.add(CSG_shapeB);
	pathTracingScene.add(CSG_shapeC);
	pathTracingScene.add(CSG_shapeD);
	pathTracingScene.add(CSG_shapeE);
	pathTracingScene.add(CSG_shapeF);


	
	init_GUI();


	// scene/demo-specific uniforms go here
	pathTracingUniforms.tLightTexture = { value: lightTexture };
	pathTracingUniforms.tMedLightTexture = { value: medLightTexture };
	pathTracingUniforms.tMediumTexture = { value: mediumTexture };
	pathTracingUniforms.tMedDarkTexture = { value: medDarkTexture };
	pathTracingUniforms.tDarkTexture = { value: darkTexture };
	pathTracingUniforms.uCSG_OperationABType = { value: 0 };
	pathTracingUniforms.uCSG_OperationBCType = { value: 0 };
	pathTracingUniforms.uCSG_OperationCDType = { value: 0 };
	pathTracingUniforms.uCSG_OperationDEType = { value: 0 };
	pathTracingUniforms.uCSG_OperationEFType = { value: 0 };
	pathTracingUniforms.uShapeAType = { value: 0 };
	pathTracingUniforms.uShapeBType = { value: 0 };
	pathTracingUniforms.uShapeCType = { value: 0 };
	pathTracingUniforms.uShapeDType = { value: 0 };
	pathTracingUniforms.uShapeEType = { value: 0 };
	pathTracingUniforms.uShapeFType = { value: 0 };
	pathTracingUniforms.uA_kParameter = { value: 1.0 };
	pathTracingUniforms.uB_kParameter = { value: 1.0 };
	pathTracingUniforms.uC_kParameter = { value: 1.0 };
	pathTracingUniforms.uD_kParameter = { value: 1.0 };
	pathTracingUniforms.uE_kParameter = { value: 1.0 };
	pathTracingUniforms.uF_kParameter = { value: 1.0 };
	pathTracingUniforms.uSunDirection = { value: new THREE.Vector3() };
	pathTracingUniforms.uCSG_ShapeA_InvMatrix = { value: new THREE.Matrix4() };
	pathTracingUniforms.uCSG_ShapeB_InvMatrix = { value: new THREE.Matrix4() };
	pathTracingUniforms.uCSG_ShapeC_InvMatrix = { value: new THREE.Matrix4() };
	pathTracingUniforms.uCSG_ShapeD_InvMatrix = { value: new THREE.Matrix4() };
	pathTracingUniforms.uCSG_ShapeE_InvMatrix = { value: new THREE.Matrix4() };
	pathTracingUniforms.uCSG_ShapeF_InvMatrix = { value: new THREE.Matrix4() };

} // end function initSceneData()





// called automatically from within the animate() function (located in InitCommon.js file)
function updateVariablesAndUniforms()
{
	// Scene preset
	if (needChangeScenePreset)
	{
		if (sceneFrom1968Paper_PresetController.getValue() == 'Scene 1')
		{
			infoElement.innerHTML = 'three.js PathTracing Renderer - Classic Scene: Shading Machine Renderings of Solids, Appel 1968 (Scene #1)';
			
			// set camera's field of view
			worldCamera.fov = 30;
			fovScale = worldCamera.fov * 0.5 * (Math.PI / 180.0);
			pathTracingUniforms.uVLen.value = Math.tan(fovScale);
			pathTracingUniforms.uULen.value = pathTracingUniforms.uVLen.value * worldCamera.aspect;
			focusDistance = 260.0;
			pathTracingUniforms.uFocusDistance.value = focusDistance;

			// position and orient camera
			cameraControlsObject.position.set(130, 55, 230);
			// look slightly left(+) or right(-)
			cameraControlsYawObject.rotation.y = 0.5;
			// look slightly up(+) or down(-)
			cameraControlsPitchObject.rotation.x = -0.25;

			// set sunLight direction
			sunLight_DirectionXController.setValue(0.4);
			sunLight_DirectionZController.setValue(0.5);
			needChangeSunLightDirection = true;

			// lower-right front section of model
			shapeA_TypeController.setValue('Box');
			parameterA_kController.setValue(1);
			transformA_PositionXController.setValue(20); transformA_PositionYController.setValue(0); transformA_PositionZController.setValue(20);
			transformA_ScaleUniformController.setValue(20); // default - will be overwritten by the following statements
			transformA_ScaleXController.setValue(30); transformA_ScaleYController.setValue(8); transformA_ScaleZController.setValue(30);
			transformA_RotationXController.setValue(0); transformA_RotationYController.setValue(0); transformA_RotationZController.setValue(0);
			transformA_SkewX_YController.setValue(0); transformA_SkewX_ZController.setValue(0);
			transformA_SkewY_XController.setValue(0); transformA_SkewY_ZController.setValue(0);
			transformA_SkewZ_XController.setValue(0); transformA_SkewZ_YController.setValue(0);
			
			csgOperationAB_TypeController.setValue('Union (A + B)');

			// wedge-shaped prism at back of model
			shapeB_TypeController.setValue('ConicalPrism');
			parameterB_kController.setValue(1);
			transformB_PositionXController.setValue(0); transformB_PositionYController.setValue(28); transformB_PositionZController.setValue(20);
			transformB_ScaleUniformController.setValue(20); // default - will be overwritten by the following statements
			transformB_ScaleXController.setValue(20); transformB_ScaleYController.setValue(20); transformB_ScaleZController.setValue(30);
			transformB_RotationXController.setValue(0); transformB_RotationYController.setValue(0); transformB_RotationZController.setValue(0);
			transformB_SkewX_YController.setValue(-0.5); transformB_SkewX_ZController.setValue(0);
			transformB_SkewY_XController.setValue(0); transformB_SkewY_ZController.setValue(0);
			transformB_SkewZ_XController.setValue(0); transformB_SkewZ_YController.setValue(0);

			csgOperationBC_TypeController.setValue('Difference (B - C)');

			// hole (negative space) inside lower-right front section of model
			shapeC_TypeController.setValue('Box');
			parameterC_kController.setValue(1);
			transformC_PositionXController.setValue(22); transformC_PositionYController.setValue(0); transformC_PositionZController.setValue(20);
			transformC_ScaleUniformController.setValue(20); // default - will be overwritten by the following statements
			transformC_ScaleXController.setValue(29); transformC_ScaleYController.setValue(7); transformC_ScaleZController.setValue(29);
			transformC_RotationXController.setValue(0); transformC_RotationYController.setValue(0); transformC_RotationZController.setValue(0);
			transformC_SkewX_YController.setValue(0); transformC_SkewX_ZController.setValue(0);
			transformC_SkewY_XController.setValue(0); transformC_SkewY_ZController.setValue(0);
			transformC_SkewZ_XController.setValue(0); transformC_SkewZ_YController.setValue(0);

			csgOperationCD_TypeController.setValue('Difference (C - D)');

			// square hole (negative space) inside the top of the wedge shape
			shapeD_TypeController.setValue('Box');
			parameterD_kController.setValue(1);
			transformD_PositionXController.setValue(10); transformD_PositionYController.setValue(28); transformD_PositionZController.setValue(20);
			transformD_ScaleUniformController.setValue(20); // default - will be overwritten by the following statements
			transformD_ScaleXController.setValue(10); transformD_ScaleYController.setValue(18); transformD_ScaleZController.setValue(15);
			transformD_RotationXController.setValue(0); transformD_RotationYController.setValue(0); transformD_RotationZController.setValue(0);
			transformD_SkewX_YController.setValue(0); transformD_SkewX_ZController.setValue(0);
			transformD_SkewY_XController.setValue(0); transformD_SkewY_ZController.setValue(0);
			transformD_SkewZ_XController.setValue(0); transformD_SkewZ_YController.setValue(0);


			csgOperationDE_TypeController.setValue('Union (D + E)');

			// ground plane below model (very thin box)
			shapeE_TypeController.setValue('Box');
			parameterE_kController.setValue(1);
			transformE_PositionXController.setValue(-10); transformE_PositionYController.setValue(-60); transformE_PositionZController.setValue(-20);
			transformE_ScaleUniformController.setValue(20); // default - will be overwritten by the following statements
			transformE_ScaleXController.setValue(60); transformE_ScaleYController.setValue(1); transformE_ScaleZController.setValue(60);
			transformE_RotationXController.setValue(0); transformE_RotationYController.setValue(0); transformE_RotationZController.setValue(0);
			transformE_SkewX_YController.setValue(0); transformE_SkewX_ZController.setValue(0);
			transformE_SkewY_XController.setValue(0); transformE_SkewY_ZController.setValue(0);
			transformE_SkewZ_XController.setValue(0); transformE_SkewZ_YController.setValue(0);


			csgOperationEF_TypeController.setValue('Union (E + F)');

			// this box is not needed for this model, so stick it below the ground plane
			shapeF_TypeController.setValue('Box');
			parameterF_kController.setValue(1);
			transformF_PositionXController.setValue(-10); transformF_PositionYController.setValue(-61); transformF_PositionZController.setValue(-20);
			transformF_ScaleUniformController.setValue(20); // default - will be overwritten by the following statements
			transformF_ScaleXController.setValue(1); transformF_ScaleYController.setValue(1); transformF_ScaleZController.setValue(1);
			transformF_RotationXController.setValue(0); transformF_RotationYController.setValue(0); transformF_RotationZController.setValue(0);
			transformF_SkewX_YController.setValue(0); transformF_SkewX_ZController.setValue(0);
			transformF_SkewY_XController.setValue(0); transformF_SkewY_ZController.setValue(0);
			transformF_SkewZ_XController.setValue(0); transformF_SkewZ_YController.setValue(0);

		} // end if Scene 1
		else if (sceneFrom1968Paper_PresetController.getValue() == 'Scene 2')
		{
			infoElement.innerHTML = 'three.js PathTracing Renderer - Classic Scene: Shading Machine Renderings of Solids, Appel 1968 (Scene #2)';
			
			// set camera's field of view
			worldCamera.fov = 30;
			fovScale = worldCamera.fov * 0.5 * (Math.PI / 180.0);
			pathTracingUniforms.uVLen.value = Math.tan(fovScale);
			pathTracingUniforms.uULen.value = pathTracingUniforms.uVLen.value * worldCamera.aspect;
			focusDistance = 260.0;
			pathTracingUniforms.uFocusDistance.value = focusDistance;

			// position and orient camera
			cameraControlsObject.position.set(130, -80, 230);
			// look slightly left(+) or right(-)
			cameraControlsYawObject.rotation.y = 0.605;
			// look slightly up(+) or down(-)
			cameraControlsPitchObject.rotation.x = 0.3;

			// set sunLight direction
			sunLight_DirectionXController.setValue(0.78);
			sunLight_DirectionZController.setValue(0.26);
			needChangeSunLightDirection = true;

			// shape A is not needed on this model in Scene #2
			shapeA_TypeController.setValue('Box');
			parameterA_kController.setValue(1);
			transformA_PositionXController.setValue(-5); transformA_PositionYController.setValue(20); transformA_PositionZController.setValue(0);
			transformA_ScaleUniformController.setValue(20); // default - will be overwritten by the following statements
			transformA_ScaleXController.setValue(1); transformA_ScaleYController.setValue(1); transformA_ScaleZController.setValue(1);
			transformA_RotationXController.setValue(0); transformA_RotationYController.setValue(0); transformA_RotationZController.setValue(0);
			transformA_SkewX_YController.setValue(0); transformA_SkewX_ZController.setValue(0);
			transformA_SkewY_XController.setValue(0); transformA_SkewY_ZController.setValue(0);
			transformA_SkewZ_XController.setValue(0); transformA_SkewZ_YController.setValue(0);

			csgOperationAB_TypeController.setValue('Union (A + B)');

			// conical prism at back of model
			shapeB_TypeController.setValue('ConicalPrism');
			parameterB_kController.setValue(0.6);
			transformB_PositionXController.setValue(-60); transformB_PositionYController.setValue(0); transformB_PositionZController.setValue(0);
			transformB_ScaleUniformController.setValue(20); // default - will be overwritten by the following statements
			transformB_ScaleXController.setValue(75); transformB_ScaleYController.setValue(40); transformB_ScaleZController.setValue(10);
			transformB_RotationXController.setValue(0); transformB_RotationYController.setValue(90); transformB_RotationZController.setValue(0);
			transformB_SkewX_YController.setValue(0); transformB_SkewX_ZController.setValue(0);
			transformB_SkewY_XController.setValue(0); transformB_SkewY_ZController.setValue(0);
			transformB_SkewZ_XController.setValue(0); transformB_SkewZ_YController.setValue(0);

			csgOperationBC_TypeController.setValue('Union (B + C)');

			// box in lower-left section of model
			shapeC_TypeController.setValue('Box');
			parameterC_kController.setValue(1);
			transformC_PositionXController.setValue(-60); transformC_PositionYController.setValue(-20); transformC_PositionZController.setValue(0);
			transformC_ScaleUniformController.setValue(20); // default - will be overwritten by the following statements
			transformC_ScaleXController.setValue(10); transformC_ScaleYController.setValue(20); transformC_ScaleZController.setValue(52);
			transformC_RotationXController.setValue(0); transformC_RotationYController.setValue(0); transformC_RotationZController.setValue(0);
			transformC_SkewX_YController.setValue(0); transformC_SkewX_ZController.setValue(0);
			transformC_SkewY_XController.setValue(0); transformC_SkewY_ZController.setValue(0);
			transformC_SkewZ_XController.setValue(0); transformC_SkewZ_YController.setValue(0);

			csgOperationCD_TypeController.setValue('Difference (C - D)');

			// (negative space) on the left lower-front section of model
			shapeD_TypeController.setValue('Box');
			parameterD_kController.setValue(1);
			transformD_PositionXController.setValue(-60); transformD_PositionYController.setValue(-20); transformD_PositionZController.setValue(72);
			transformD_ScaleUniformController.setValue(20); // default - will be overwritten by the following statements
			transformD_ScaleXController.setValue(10); transformD_ScaleYController.setValue(30); transformD_ScaleZController.setValue(20);
			transformD_RotationXController.setValue(0); transformD_RotationYController.setValue(0); transformD_RotationZController.setValue(0);
			transformD_SkewX_YController.setValue(0); transformD_SkewX_ZController.setValue(0);
			transformD_SkewY_XController.setValue(0); transformD_SkewY_ZController.setValue(0);
			transformD_SkewZ_XController.setValue(0); transformD_SkewZ_YController.setValue(0);


			csgOperationDE_TypeController.setValue('Difference (D - E)');

			// (negative space) on the left lower-back section of model
			shapeE_TypeController.setValue('Box');
			parameterE_kController.setValue(1);
			transformE_PositionXController.setValue(-60); transformE_PositionYController.setValue(-20); transformE_PositionZController.setValue(-72);
			transformE_ScaleUniformController.setValue(20); // default - will be overwritten by the following statements
			transformE_ScaleXController.setValue(10); transformE_ScaleYController.setValue(30); transformE_ScaleZController.setValue(20);
			transformE_RotationXController.setValue(0); transformE_RotationYController.setValue(0); transformE_RotationZController.setValue(0);
			transformE_SkewX_YController.setValue(0); transformE_SkewX_ZController.setValue(0);
			transformE_SkewY_XController.setValue(0); transformE_SkewY_ZController.setValue(0);
			transformE_SkewZ_XController.setValue(0); transformE_SkewZ_YController.setValue(0);


			csgOperationEF_TypeController.setValue('Union (E + F)');

			// large box on upper-right front section of model
			shapeF_TypeController.setValue('Box');
			parameterF_kController.setValue(1);
			transformF_PositionXController.setValue(-5); transformF_PositionYController.setValue(20); transformF_PositionZController.setValue(0);
			transformF_ScaleUniformController.setValue(20); // default - will be overwritten by the following statements
			transformF_ScaleXController.setValue(45); transformF_ScaleYController.setValue(20); transformF_ScaleZController.setValue(30);
			transformF_RotationXController.setValue(0); transformF_RotationYController.setValue(0); transformF_RotationZController.setValue(0);
			transformF_SkewX_YController.setValue(0); transformF_SkewX_ZController.setValue(0);
			transformF_SkewY_XController.setValue(0); transformF_SkewY_ZController.setValue(0);
			transformF_SkewZ_XController.setValue(0); transformF_SkewZ_YController.setValue(0);

		} // end if Scene 2
		else if (sceneFrom1968Paper_PresetController.getValue() == 'Scene 3')
		{
			infoElement.innerHTML = 'three.js PathTracing Renderer - Classic Scene: Shading Machine Renderings of Solids, Appel 1968 (Scene #3)';

			// set camera's field of view
			worldCamera.fov = 30;
			fovScale = worldCamera.fov * 0.5 * (Math.PI / 180.0);
			pathTracingUniforms.uVLen.value = Math.tan(fovScale);
			pathTracingUniforms.uULen.value = pathTracingUniforms.uVLen.value * worldCamera.aspect;
			focusDistance = 260.0;
			pathTracingUniforms.uFocusDistance.value = focusDistance;

			// position and orient camera
			cameraControlsObject.position.set(100, 180, 230);
			// look slightly left(+) or right(-)
			cameraControlsYawObject.rotation.y = 0.4;
			// look slightly up(+) or down(-)
			cameraControlsPitchObject.rotation.x = -0.6;

			// set sunLight direction
			sunLight_DirectionXController.setValue(0.4);
			sunLight_DirectionZController.setValue(0.5);
			needChangeSunLightDirection = true;

			// main tall box section of model
			shapeA_TypeController.setValue('Box');
			parameterA_kController.setValue(1);
			transformA_PositionXController.setValue(0); transformA_PositionYController.setValue(0); transformA_PositionZController.setValue(0);
			transformA_ScaleUniformController.setValue(20); // default - will be overwritten by the following statements
			transformA_ScaleXController.setValue(50); transformA_ScaleYController.setValue(60); transformA_ScaleZController.setValue(30);
			transformA_RotationXController.setValue(0); transformA_RotationYController.setValue(0); transformA_RotationZController.setValue(0);
			transformA_SkewX_YController.setValue(0); transformA_SkewX_ZController.setValue(0);
			transformA_SkewY_XController.setValue(0); transformA_SkewY_ZController.setValue(0);
			transformA_SkewZ_XController.setValue(0); transformA_SkewZ_YController.setValue(0);

			csgOperationAB_TypeController.setValue('Difference (A - B)');

			// square hole (negative space) in upper part of tall main box
			shapeB_TypeController.setValue('Box');
			parameterB_kController.setValue(1);
			transformB_PositionXController.setValue(0); transformB_PositionYController.setValue(40); transformB_PositionZController.setValue(0);
			transformB_ScaleUniformController.setValue(20); // default - will be overwritten by the following statements
			transformB_ScaleXController.setValue(32); transformB_ScaleYController.setValue(40); transformB_ScaleZController.setValue(40);
			transformB_RotationXController.setValue(0); transformB_RotationYController.setValue(0); transformB_RotationZController.setValue(0);
			transformB_SkewX_YController.setValue(0); transformB_SkewX_ZController.setValue(0);
			transformB_SkewY_XController.setValue(0); transformB_SkewY_ZController.setValue(0);
			transformB_SkewZ_XController.setValue(0); transformB_SkewZ_YController.setValue(0);

			csgOperationBC_TypeController.setValue('Difference (B - C)');

			// rectangular hole (negative space) taken from lower front section of main tall box
			shapeC_TypeController.setValue('Box');
			parameterC_kController.setValue(1);
			transformC_PositionXController.setValue(0); transformC_PositionYController.setValue(-50); transformC_PositionZController.setValue(32);
			transformC_ScaleUniformController.setValue(20); // default - will be overwritten by the following statements
			transformC_ScaleXController.setValue(60); transformC_ScaleYController.setValue(15); transformC_ScaleZController.setValue(15);
			transformC_RotationXController.setValue(0); transformC_RotationYController.setValue(0); transformC_RotationZController.setValue(0);
			transformC_SkewX_YController.setValue(0); transformC_SkewX_ZController.setValue(0);
			transformC_SkewY_XController.setValue(0); transformC_SkewY_ZController.setValue(0);
			transformC_SkewZ_XController.setValue(0); transformC_SkewZ_YController.setValue(0);

			csgOperationCD_TypeController.setValue('Union (C + D)');

			// this box is not needed for this model
			shapeD_TypeController.setValue('Box');
			parameterD_kController.setValue(1);
			transformD_PositionXController.setValue(0); transformD_PositionYController.setValue(-20); transformD_PositionZController.setValue(0);
			transformD_ScaleUniformController.setValue(20); // default - will be overwritten by the following statements
			transformD_ScaleXController.setValue(1); transformD_ScaleYController.setValue(1); transformD_ScaleZController.setValue(1);
			transformD_RotationXController.setValue(0); transformD_RotationYController.setValue(0); transformD_RotationZController.setValue(0);
			transformD_SkewX_YController.setValue(0); transformD_SkewX_ZController.setValue(0);
			transformD_SkewY_XController.setValue(0); transformD_SkewY_ZController.setValue(0);
			transformD_SkewZ_XController.setValue(0); transformD_SkewZ_YController.setValue(0);


			csgOperationDE_TypeController.setValue('Union (D + E)');

			// this box is not needed for this model
			shapeE_TypeController.setValue('Box');
			parameterE_kController.setValue(1);
			transformE_PositionXController.setValue(0); transformE_PositionYController.setValue(-20); transformE_PositionZController.setValue(0);
			transformE_ScaleUniformController.setValue(20); // default - will be overwritten by the following statements
			transformE_ScaleXController.setValue(1); transformE_ScaleYController.setValue(1); transformE_ScaleZController.setValue(1);
			transformE_RotationXController.setValue(0); transformE_RotationYController.setValue(0); transformE_RotationZController.setValue(0);
			transformE_SkewX_YController.setValue(0); transformE_SkewX_ZController.setValue(0);
			transformE_SkewY_XController.setValue(0); transformE_SkewY_ZController.setValue(0);
			transformE_SkewZ_XController.setValue(0); transformE_SkewZ_YController.setValue(0);


			csgOperationEF_TypeController.setValue('Union (E + F)');

			// this box is not needed for this model
			shapeF_TypeController.setValue('Box');
			parameterF_kController.setValue(1);
			transformF_PositionXController.setValue(0); transformF_PositionYController.setValue(-20); transformF_PositionZController.setValue(0);
			transformF_ScaleUniformController.setValue(20); // default - will be overwritten by the following statements
			transformF_ScaleXController.setValue(1); transformF_ScaleYController.setValue(1); transformF_ScaleZController.setValue(1);
			transformF_RotationXController.setValue(0); transformF_RotationYController.setValue(0); transformF_RotationZController.setValue(0);
			transformF_SkewX_YController.setValue(0); transformF_SkewX_ZController.setValue(0);
			transformF_SkewY_XController.setValue(0); transformF_SkewY_ZController.setValue(0);
			transformF_SkewZ_XController.setValue(0); transformF_SkewZ_YController.setValue(0);

		} // end if Scene 3
		else if (sceneFrom1968Paper_PresetController.getValue() == 'Scene 4')
		{
			infoElement.innerHTML = 'three.js PathTracing Renderer - Classic Scene: Shading Machine Renderings of Solids, Appel 1968 (Scene #4)';

			// set camera's field of view
			worldCamera.fov = 30;
			fovScale = worldCamera.fov * 0.5 * (Math.PI / 180.0);
			pathTracingUniforms.uVLen.value = Math.tan(fovScale);
			pathTracingUniforms.uULen.value = pathTracingUniforms.uVLen.value * worldCamera.aspect;
			focusDistance = 260.0;
			pathTracingUniforms.uFocusDistance.value = focusDistance;

			// position and orient camera
			cameraControlsObject.position.set(160, 140, 260);
			// look slightly left(+) or right(-)
			cameraControlsYawObject.rotation.y = 0.55;
			// look slightly up(+) or down(-)
			cameraControlsPitchObject.rotation.x = -0.45;

			// set sunLight direction
			sunLight_DirectionXController.setValue(0.4);
			sunLight_DirectionZController.setValue(0.5);
			needChangeSunLightDirection = true;

			// main tall box section of model
			shapeA_TypeController.setValue('Box');
			parameterA_kController.setValue(1);
			transformA_PositionXController.setValue(0); transformA_PositionYController.setValue(0); transformA_PositionZController.setValue(0);
			transformA_ScaleUniformController.setValue(20); // default - will be overwritten by the following statements
			transformA_ScaleXController.setValue(50); transformA_ScaleYController.setValue(60); transformA_ScaleZController.setValue(30);
			transformA_RotationXController.setValue(0); transformA_RotationYController.setValue(0); transformA_RotationZController.setValue(0);
			transformA_SkewX_YController.setValue(0); transformA_SkewX_ZController.setValue(0);
			transformA_SkewY_XController.setValue(0); transformA_SkewY_ZController.setValue(0);
			transformA_SkewZ_XController.setValue(0); transformA_SkewZ_YController.setValue(0);

			csgOperationAB_TypeController.setValue('Difference (A - B)');

			// square hole (negative space) in upper part of tall main box
			shapeB_TypeController.setValue('Box');
			parameterB_kController.setValue(1);
			transformB_PositionXController.setValue(0); transformB_PositionYController.setValue(40); transformB_PositionZController.setValue(0);
			transformB_ScaleUniformController.setValue(20); // default - will be overwritten by the following statements
			transformB_ScaleXController.setValue(32); transformB_ScaleYController.setValue(40); transformB_ScaleZController.setValue(40);
			transformB_RotationXController.setValue(0); transformB_RotationYController.setValue(0); transformB_RotationZController.setValue(0);
			transformB_SkewX_YController.setValue(0); transformB_SkewX_ZController.setValue(0);
			transformB_SkewY_XController.setValue(0); transformB_SkewY_ZController.setValue(0);
			transformB_SkewZ_XController.setValue(0); transformB_SkewZ_YController.setValue(0);

			csgOperationBC_TypeController.setValue('Difference (B - C)');

			// rectangular hole (negative space) taken from lower front section of main tall box
			shapeC_TypeController.setValue('Box');
			parameterC_kController.setValue(1);
			transformC_PositionXController.setValue(0); transformC_PositionYController.setValue(-50); transformC_PositionZController.setValue(32);
			transformC_ScaleUniformController.setValue(20); // default - will be overwritten by the following statements
			transformC_ScaleXController.setValue(60); transformC_ScaleYController.setValue(15); transformC_ScaleZController.setValue(15);
			transformC_RotationXController.setValue(0); transformC_RotationYController.setValue(0); transformC_RotationZController.setValue(0);
			transformC_SkewX_YController.setValue(0); transformC_SkewX_ZController.setValue(0);
			transformC_SkewY_XController.setValue(0); transformC_SkewY_ZController.setValue(0);
			transformC_SkewZ_XController.setValue(0); transformC_SkewZ_YController.setValue(0);

			csgOperationCD_TypeController.setValue('Union (C + D)');

			// conical prism at the front of model
			shapeD_TypeController.setValue('ConicalPrism');
			parameterD_kController.setValue(0.4);
			transformD_PositionXController.setValue(0); transformD_PositionYController.setValue(20); transformD_PositionZController.setValue(40);
			transformD_ScaleUniformController.setValue(20); // default - will be overwritten by the following statements
			transformD_ScaleXController.setValue(50); transformD_ScaleYController.setValue(20); transformD_ScaleZController.setValue(10);
			transformD_RotationXController.setValue(0); transformD_RotationYController.setValue(0); transformD_RotationZController.setValue(0);
			transformD_SkewX_YController.setValue(0); transformD_SkewX_ZController.setValue(0);
			transformD_SkewY_XController.setValue(0); transformD_SkewY_ZController.setValue(0);
			transformD_SkewZ_XController.setValue(0); transformD_SkewZ_YController.setValue(0);


			csgOperationDE_TypeController.setValue('Union (D + E)');

			// large box in center of model
			shapeE_TypeController.setValue('Box');
			parameterE_kController.setValue(1);
			transformE_PositionXController.setValue(0); transformE_PositionYController.setValue(20); transformE_PositionZController.setValue(-10);
			transformE_ScaleUniformController.setValue(20); // default - will be overwritten by the following statements
			transformE_ScaleXController.setValue(30); transformE_ScaleYController.setValue(20); transformE_ScaleZController.setValue(40);
			transformE_RotationXController.setValue(0); transformE_RotationYController.setValue(0); transformE_RotationZController.setValue(0);
			transformE_SkewX_YController.setValue(0); transformE_SkewX_ZController.setValue(0);
			transformE_SkewY_XController.setValue(0); transformE_SkewY_ZController.setValue(0);
			transformE_SkewZ_XController.setValue(0); transformE_SkewZ_YController.setValue(0);


			csgOperationEF_TypeController.setValue('Union (E + F)');

			// rectangular box on lower front of model
			shapeF_TypeController.setValue('Box');
			parameterF_kController.setValue(1);
			transformF_PositionXController.setValue(0); transformF_PositionYController.setValue(-18); transformF_PositionZController.setValue(40);
			transformF_ScaleUniformController.setValue(20); // default - will be overwritten by the following statements
			transformF_ScaleXController.setValue(50); transformF_ScaleYController.setValue(18); transformF_ScaleZController.setValue(10);
			transformF_RotationXController.setValue(0); transformF_RotationYController.setValue(0); transformF_RotationZController.setValue(0);
			transformF_SkewX_YController.setValue(0); transformF_SkewX_ZController.setValue(0);
			transformF_SkewY_XController.setValue(0); transformF_SkewY_ZController.setValue(0);
			transformF_SkewZ_XController.setValue(0); transformF_SkewZ_YController.setValue(0);

		} // end if Scene 4
		else if (sceneFrom1968Paper_PresetController.getValue() == 'Scene 5')
		{
			infoElement.innerHTML = 'three.js PathTracing Renderer - Classic Scene: Shading Machine Renderings of Solids, Appel 1968 (Scene #5)';

			// set camera's field of view
			worldCamera.fov = 30;
			fovScale = worldCamera.fov * 0.5 * (Math.PI / 180.0);
			pathTracingUniforms.uVLen.value = Math.tan(fovScale);
			pathTracingUniforms.uULen.value = pathTracingUniforms.uVLen.value * worldCamera.aspect;
			focusDistance = 260.0;
			pathTracingUniforms.uFocusDistance.value = focusDistance;

			// position and orient camera
			cameraControlsObject.position.set(130, 190, 200);
			// look slightly left(+) or right(-)
			cameraControlsYawObject.rotation.y = 0.55;
			// look slightly up(+) or down(-)
			cameraControlsPitchObject.rotation.x = -0.7;

			// set sunLight direction
			sunLight_DirectionXController.setValue(0.4);
			sunLight_DirectionZController.setValue(0.5);
			needChangeSunLightDirection = true;

			// main tall box in back of model
			shapeA_TypeController.setValue('Box');
			parameterA_kController.setValue(1);
			transformA_PositionXController.setValue(0); transformA_PositionYController.setValue(0); transformA_PositionZController.setValue(-20);
			transformA_ScaleUniformController.setValue(20); // default - will be overwritten by the following statements
			transformA_ScaleXController.setValue(30); transformA_ScaleYController.setValue(40); transformA_ScaleZController.setValue(10);
			transformA_RotationXController.setValue(0); transformA_RotationYController.setValue(0); transformA_RotationZController.setValue(0);
			transformA_SkewX_YController.setValue(0); transformA_SkewX_ZController.setValue(0);
			transformA_SkewY_XController.setValue(0); transformA_SkewY_ZController.setValue(0);
			transformA_SkewZ_XController.setValue(0); transformA_SkewZ_YController.setValue(0);

			csgOperationAB_TypeController.setValue('Difference (A - B)');

			// rectangular hole (negative space) in tall main box
			shapeB_TypeController.setValue('Box');
			parameterB_kController.setValue(1);
			transformB_PositionXController.setValue(0); transformB_PositionYController.setValue(15); transformB_PositionZController.setValue(-20);
			transformB_ScaleUniformController.setValue(20); // default - will be overwritten by the following statements
			transformB_ScaleXController.setValue(20); transformB_ScaleYController.setValue(15); transformB_ScaleZController.setValue(15);
			transformB_RotationXController.setValue(0); transformB_RotationYController.setValue(0); transformB_RotationZController.setValue(0);
			transformB_SkewX_YController.setValue(0); transformB_SkewX_ZController.setValue(0);
			transformB_SkewY_XController.setValue(0); transformB_SkewY_ZController.setValue(0);
			transformB_SkewZ_XController.setValue(0); transformB_SkewZ_YController.setValue(0);

			csgOperationBC_TypeController.setValue('Union (B + C)');

			// wedge-shaped conical prism on right side
			shapeC_TypeController.setValue('ConicalPrism');
			parameterC_kController.setValue(1);
			transformC_PositionXController.setValue(35); transformC_PositionYController.setValue(-20); transformC_PositionZController.setValue(4);
			transformC_ScaleUniformController.setValue(20); // default - will be overwritten by the following statements
			transformC_ScaleXController.setValue(10); transformC_ScaleYController.setValue(20); transformC_ScaleZController.setValue(34);
			transformC_RotationXController.setValue(0); transformC_RotationYController.setValue(0); transformC_RotationZController.setValue(0);
			transformC_SkewX_YController.setValue(-0.5); transformC_SkewX_ZController.setValue(0);
			transformC_SkewY_XController.setValue(0); transformC_SkewY_ZController.setValue(0);
			transformC_SkewZ_XController.setValue(0); transformC_SkewZ_YController.setValue(0);

			csgOperationCD_TypeController.setValue('Union (C + D)');

			// matching wedge-shaped conical prism on left side
			shapeD_TypeController.setValue('ConicalPrism');
			parameterD_kController.setValue(1);
			transformD_PositionXController.setValue(-35); transformD_PositionYController.setValue(-20); transformD_PositionZController.setValue(4);
			transformD_ScaleUniformController.setValue(20); // default - will be overwritten by the following statements
			transformD_ScaleXController.setValue(10); transformD_ScaleYController.setValue(20); transformD_ScaleZController.setValue(34);
			transformD_RotationXController.setValue(0); transformD_RotationYController.setValue(0); transformD_RotationZController.setValue(0);
			transformD_SkewX_YController.setValue(0.5); transformD_SkewX_ZController.setValue(0);
			transformD_SkewY_XController.setValue(0); transformD_SkewY_ZController.setValue(0);
			transformD_SkewZ_XController.setValue(0); transformD_SkewZ_YController.setValue(0);


			csgOperationDE_TypeController.setValue('Union (D + E)');

			// rectangular box on lower front of model
			shapeE_TypeController.setValue('Box');
			parameterE_kController.setValue(1);
			transformE_PositionXController.setValue(0); transformE_PositionYController.setValue(-32); transformE_PositionZController.setValue(30);
			transformE_ScaleUniformController.setValue(20); // default - will be overwritten by the following statements
			transformE_ScaleXController.setValue(30); transformE_ScaleYController.setValue(8); transformE_ScaleZController.setValue(8);
			transformE_RotationXController.setValue(0); transformE_RotationYController.setValue(0); transformE_RotationZController.setValue(0);
			transformE_SkewX_YController.setValue(0); transformE_SkewX_ZController.setValue(0);
			transformE_SkewY_XController.setValue(0); transformE_SkewY_ZController.setValue(0);
			transformE_SkewZ_XController.setValue(0); transformE_SkewZ_YController.setValue(0);


			csgOperationEF_TypeController.setValue('Union (E + F)');

			// this box is not needed for this model
			shapeF_TypeController.setValue('Box');
			parameterF_kController.setValue(1);
			transformF_PositionXController.setValue(0); transformF_PositionYController.setValue(-20); transformF_PositionZController.setValue(-20);
			transformF_ScaleUniformController.setValue(20); // default - will be overwritten by the following statements
			transformF_ScaleXController.setValue(1); transformF_ScaleYController.setValue(1); transformF_ScaleZController.setValue(1);
			transformF_RotationXController.setValue(0); transformF_RotationYController.setValue(0); transformF_RotationZController.setValue(0);
			transformF_SkewX_YController.setValue(0); transformF_SkewX_ZController.setValue(0);
			transformF_SkewY_XController.setValue(0); transformF_SkewY_ZController.setValue(0);
			transformF_SkewZ_XController.setValue(0); transformF_SkewZ_YController.setValue(0);

		} // end if Scene 5
		else if (sceneFrom1968Paper_PresetController.getValue() == 'Scene 6')
		{
			infoElement.innerHTML = 'three.js PathTracing Renderer - Classic Scene: Shading Machine Renderings of Solids, Appel 1968 (Scene #6)';

			// set camera's field of view
			worldCamera.fov = 30;
			fovScale = worldCamera.fov * 0.5 * (Math.PI / 180.0);
			pathTracingUniforms.uVLen.value = Math.tan(fovScale);
			pathTracingUniforms.uULen.value = pathTracingUniforms.uVLen.value * worldCamera.aspect;
			focusDistance = 260.0;
			pathTracingUniforms.uFocusDistance.value = focusDistance;

			// position and orient camera
			cameraControlsObject.position.set(160, 140, 260);
			// look slightly left(+) or right(-)
			cameraControlsYawObject.rotation.y = 0.55;
			// look slightly up(+) or down(-)
			cameraControlsPitchObject.rotation.x = -0.425;

			// set sunLight direction
			sunLight_DirectionXController.setValue(0.4);
			sunLight_DirectionZController.setValue(0.5);
			needChangeSunLightDirection = true;

			// main tall box section of model
			shapeA_TypeController.setValue('Box');
			parameterA_kController.setValue(1);
			transformA_PositionXController.setValue(0); transformA_PositionYController.setValue(11); transformA_PositionZController.setValue(0);
			transformA_ScaleUniformController.setValue(20); // default - will be overwritten by the following statements
			transformA_ScaleXController.setValue(50); transformA_ScaleYController.setValue(49); transformA_ScaleZController.setValue(30);
			transformA_RotationXController.setValue(0); transformA_RotationYController.setValue(0); transformA_RotationZController.setValue(0);
			transformA_SkewX_YController.setValue(0); transformA_SkewX_ZController.setValue(0);
			transformA_SkewY_XController.setValue(0); transformA_SkewY_ZController.setValue(0);
			transformA_SkewZ_XController.setValue(0); transformA_SkewZ_YController.setValue(0);

			csgOperationAB_TypeController.setValue('Difference (A - B)');

			// square hole (negative space) in upper part of tall main box
			shapeB_TypeController.setValue('Box');
			parameterB_kController.setValue(1);
			transformB_PositionXController.setValue(0); transformB_PositionYController.setValue(40); transformB_PositionZController.setValue(0);
			transformB_ScaleUniformController.setValue(20); // default - will be overwritten by the following statements
			transformB_ScaleXController.setValue(32); transformB_ScaleYController.setValue(40); transformB_ScaleZController.setValue(40);
			transformB_RotationXController.setValue(0); transformB_RotationYController.setValue(0); transformB_RotationZController.setValue(0);
			transformB_SkewX_YController.setValue(0); transformB_SkewX_ZController.setValue(0);
			transformB_SkewY_XController.setValue(0); transformB_SkewY_ZController.setValue(0);
			transformB_SkewZ_XController.setValue(0); transformB_SkewZ_YController.setValue(0);

			csgOperationBC_TypeController.setValue('Union (B + C)');

			// large conical prism in the middle of model
			shapeC_TypeController.setValue('ConicalPrism');
			parameterC_kController.setValue(0.6);
			transformC_PositionXController.setValue(0); transformC_PositionYController.setValue(0); transformC_PositionZController.setValue(0);
			transformC_ScaleUniformController.setValue(20); // default - will be overwritten by the following statements
			transformC_ScaleXController.setValue(70); transformC_ScaleYController.setValue(45); transformC_ScaleZController.setValue(50);
			transformC_RotationXController.setValue(0); transformC_RotationYController.setValue(0); transformC_RotationZController.setValue(0);
			transformC_SkewX_YController.setValue(0); transformC_SkewX_ZController.setValue(0);
			transformC_SkewY_XController.setValue(0); transformC_SkewY_ZController.setValue(0);
			transformC_SkewZ_XController.setValue(0); transformC_SkewZ_YController.setValue(0);

			csgOperationCD_TypeController.setValue('Union (C + D)');

			// rectangular box on lower front of model - slightly oversized, making slits/lines on lower front of model
			shapeD_TypeController.setValue('Box');
			parameterD_kController.setValue(1);
			transformD_PositionXController.setValue(0); transformD_PositionYController.setValue(-15); transformD_PositionZController.setValue(40);
			transformD_ScaleUniformController.setValue(20); // default - will be overwritten by the following statements
			transformD_ScaleXController.setValue(50); transformD_ScaleYController.setValue(14); transformD_ScaleZController.setValue(11);
			transformD_RotationXController.setValue(0); transformD_RotationYController.setValue(0); transformD_RotationZController.setValue(0);
			transformD_SkewX_YController.setValue(0); transformD_SkewX_ZController.setValue(0);
			transformD_SkewY_XController.setValue(0); transformD_SkewY_ZController.setValue(0);
			transformD_SkewZ_XController.setValue(0); transformD_SkewZ_YController.setValue(0);


			csgOperationDE_TypeController.setValue('Union (D + E)');

			// this box is not needed on this model
			shapeE_TypeController.setValue('Box');
			parameterE_kController.setValue(1);
			transformE_PositionXController.setValue(0); transformE_PositionYController.setValue(20); transformE_PositionZController.setValue(-10);
			transformE_ScaleUniformController.setValue(20); // default - will be overwritten by the following statements
			transformE_ScaleXController.setValue(1); transformE_ScaleYController.setValue(1); transformE_ScaleZController.setValue(1);
			transformE_RotationXController.setValue(0); transformE_RotationYController.setValue(0); transformE_RotationZController.setValue(0);
			transformE_SkewX_YController.setValue(0); transformE_SkewX_ZController.setValue(0);
			transformE_SkewY_XController.setValue(0); transformE_SkewY_ZController.setValue(0);
			transformE_SkewZ_XController.setValue(0); transformE_SkewZ_YController.setValue(0);


			csgOperationEF_TypeController.setValue('Union (E + F)');

			// rectangular box in upper back of the model
			shapeF_TypeController.setValue('Box');
			parameterF_kController.setValue(1);
			transformF_PositionXController.setValue(0); transformF_PositionYController.setValue(29); transformF_PositionZController.setValue(-41);
			transformF_ScaleUniformController.setValue(20); // default - will be overwritten by the following statements
			transformF_ScaleXController.setValue(50); transformF_ScaleYController.setValue(31); transformF_ScaleZController.setValue(10);
			transformF_RotationXController.setValue(0); transformF_RotationYController.setValue(0); transformF_RotationZController.setValue(0);
			transformF_SkewX_YController.setValue(0); transformF_SkewX_ZController.setValue(0);
			transformF_SkewY_XController.setValue(0); transformF_SkewY_ZController.setValue(0);
			transformF_SkewZ_XController.setValue(0); transformF_SkewZ_YController.setValue(0);

		} // end if Scene 6

		needChangeAShapeType = needChangeAParameterK = needChangeAPosition = needChangeARotation = needChangeAScale = needChangeASkew = true;
		needChangeBShapeType = needChangeBParameterK = needChangeBPosition = needChangeBRotation = needChangeBScale = needChangeBSkew = true;
		needChangeCShapeType = needChangeCParameterK = needChangeCPosition = needChangeCRotation = needChangeCScale = needChangeCSkew = true;
		needChangeDShapeType = needChangeDParameterK = needChangeDPosition = needChangeDRotation = needChangeDScale = needChangeDSkew = true;
		needChangeEShapeType = needChangeEParameterK = needChangeEPosition = needChangeERotation = needChangeEScale = needChangeESkew = true;
		needChangeFShapeType = needChangeFParameterK = needChangeFPosition = needChangeFRotation = needChangeFScale = needChangeFSkew = true;

		needChangeOperationABType = needChangeOperationBCType = needChangeOperationCDType = needChangeOperationDEType = needChangeOperationEFType = true;

		// set the following uniform scale flags to false because they would overwrite any individual x, y, or z scaling changes that we wanted to make
		needChangeAScaleUniform = needChangeBScaleUniform = needChangeCScaleUniform = 
			needChangeDScaleUniform = needChangeEScaleUniform = needChangeFScaleUniform = false;
		
		cameraIsMoving = true;
		needChangeScenePreset = false;
	}

	// Sunlight Direction
	if (needChangeSunLightDirection)
	{
		sunDirection.set(sunLight_DirectionXController.getValue(),
			1,
			sunLight_DirectionZController.getValue());

		sunDirection.normalize();
		pathTracingUniforms.uSunDirection.value.copy(sunDirection);

		cameraIsMoving = true;
		needChangeSunLightDirection = false;
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

	if (needChangeAShapeType)
	{
		currentAShapeType = shapeA_TypeController.getValue();

		if (currentAShapeType == 'Box')
		{
			pathTracingUniforms.uShapeAType.value = 7;
			parameterA_kController.domElement.hidden = true;
		}
		else if (currentAShapeType == 'ConicalPrism')
		{
			pathTracingUniforms.uShapeAType.value = 9;
			parameterA_kController.domElement.hidden = false;
			//parameterA_kController.setValue(1);
		}
		
		cameraIsMoving = true;
		needChangeAShapeType = false;
	}

	if (needChangeAParameterK)
	{
		kValue = parameterA_kController.getValue();
		//parameterA_kController.setValue(kValue);
		pathTracingUniforms.uA_kParameter.value = kValue;

		cameraIsMoving = true;
		needChangeAParameterK = false;
	}

	if (needChangeOperationABType)
	{
		if (csgOperationAB_TypeController.getValue() == 'Union (A + B)')
		{
			pathTracingUniforms.uCSG_OperationABType.value = 0;
		}
		else if (csgOperationAB_TypeController.getValue() == 'Difference (A - B)')
		{
			pathTracingUniforms.uCSG_OperationABType.value = 1;
		}

		cameraIsMoving = true;
		needChangeOperationABType = false;
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

	if (needChangeBShapeType)
	{
		currentBShapeType = shapeB_TypeController.getValue();

		
		if (currentBShapeType == 'Box')
		{
			pathTracingUniforms.uShapeBType.value = 7;
			parameterB_kController.domElement.hidden = true;
		}
		else if (currentBShapeType == 'ConicalPrism')
		{
			pathTracingUniforms.uShapeBType.value = 9;
			parameterB_kController.domElement.hidden = false;
			//parameterB_kController.setValue(1);
		}

		cameraIsMoving = true;
		needChangeBShapeType = false;
	}

	if (needChangeBParameterK)
	{
		kValue = parameterB_kController.getValue();
		//parameterB_kController.setValue(kValue);
		pathTracingUniforms.uB_kParameter.value = kValue;

		cameraIsMoving = true;
		needChangeBParameterK = false;
	}


	if (needChangeOperationBCType)
	{
		if (csgOperationBC_TypeController.getValue() == 'Union (B + C)')
		{
			pathTracingUniforms.uCSG_OperationBCType.value = 0;
		}
		else if (csgOperationBC_TypeController.getValue() == 'Difference (B - C)')
		{
			pathTracingUniforms.uCSG_OperationBCType.value = 1;
		}

		cameraIsMoving = true;
		needChangeOperationBCType = false;
	}

	// SHAPE C
	if (needChangeCPosition)
	{
		CSG_shapeC.position.set(transformC_PositionXController.getValue(),
					transformC_PositionYController.getValue(),
					transformC_PositionZController.getValue());

		cameraIsMoving = true;
		needChangeCPosition = false;
	}

	if (needChangeCScaleUniform)
	{
		uniformScale = transformC_ScaleUniformController.getValue();
		CSG_shapeC.scale.set(uniformScale, uniformScale, uniformScale);

		transformC_ScaleXController.setValue(uniformScale);
		transformC_ScaleYController.setValue(uniformScale);
		transformC_ScaleZController.setValue(uniformScale);

		cameraIsMoving = true;
		needChangeCScaleUniform = false;
	}

	if (needChangeCScale)
	{
		CSG_shapeC.scale.set(transformC_ScaleXController.getValue(),
				     transformC_ScaleYController.getValue(),
				     transformC_ScaleZController.getValue());

		cameraIsMoving = true;
		needChangeCScale = false;
	}

	if (needChangeCSkew)
	{
		C_SkewMatrix.set(
			1, transformC_SkewX_YController.getValue(), transformC_SkewX_ZController.getValue(), 0,
			transformC_SkewY_XController.getValue(), 1, transformC_SkewY_ZController.getValue(), 0,
			transformC_SkewZ_XController.getValue(), transformC_SkewZ_YController.getValue(), 1, 0,
			0, 0, 0, 1
		);

		cameraIsMoving = true;
		needChangeCSkew = false;
	}

	if (needChangeCRotation)
	{
		CSG_shapeC.rotation.set(THREE.MathUtils.degToRad(transformC_RotationXController.getValue()),
			THREE.MathUtils.degToRad(transformC_RotationYController.getValue()),
			THREE.MathUtils.degToRad(transformC_RotationZController.getValue()));

		cameraIsMoving = true;
		needChangeCRotation = false;
	}

	if (needChangeCShapeType)
	{
		currentCShapeType = shapeC_TypeController.getValue();


		if (currentCShapeType == 'Box')
		{
			pathTracingUniforms.uShapeCType.value = 7;
			parameterC_kController.domElement.hidden = true;
		}
		else if (currentCShapeType == 'ConicalPrism')
		{
			pathTracingUniforms.uShapeCType.value = 9;
			parameterC_kController.domElement.hidden = false;
			//parameterC_kController.setValue(1);
		}

		cameraIsMoving = true;
		needChangeCShapeType = false;
	}

	if (needChangeCParameterK)
	{
		kValue = parameterC_kController.getValue();
		//parameterC_kController.setValue(kValue);
		pathTracingUniforms.uC_kParameter.value = kValue;

		cameraIsMoving = true;
		needChangeCParameterK = false;
	}


	if (needChangeOperationCDType)
	{
		if (csgOperationCD_TypeController.getValue() == 'Union (C + D)')
		{
			pathTracingUniforms.uCSG_OperationCDType.value = 0;
		}
		else if (csgOperationCD_TypeController.getValue() == 'Difference (C - D)')
		{
			pathTracingUniforms.uCSG_OperationCDType.value = 1;
		}

		cameraIsMoving = true;
		needChangeOperationCDType = false;
	}

	// SHAPE D
	if (needChangeDPosition)
	{
		CSG_shapeD.position.set(transformD_PositionXController.getValue(),
					transformD_PositionYController.getValue(),
					transformD_PositionZController.getValue());

		cameraIsMoving = true;
		needChangeDPosition = false;
	}

	if (needChangeDScaleUniform)
	{
		uniformScale = transformD_ScaleUniformController.getValue();
		CSG_shapeD.scale.set(uniformScale, uniformScale, uniformScale);

		transformD_ScaleXController.setValue(uniformScale);
		transformD_ScaleYController.setValue(uniformScale);
		transformD_ScaleZController.setValue(uniformScale);

		cameraIsMoving = true;
		needChangeDScaleUniform = false;
	}

	if (needChangeDScale)
	{
		CSG_shapeD.scale.set(transformD_ScaleXController.getValue(),
				     transformD_ScaleYController.getValue(),
				     transformD_ScaleZController.getValue());

		cameraIsMoving = true;
		needChangeDScale = false;
	}

	if (needChangeDSkew)
	{
		D_SkewMatrix.set(
			1, transformD_SkewX_YController.getValue(), transformD_SkewX_ZController.getValue(), 0,
			transformD_SkewY_XController.getValue(), 1, transformD_SkewY_ZController.getValue(), 0,
			transformD_SkewZ_XController.getValue(), transformD_SkewZ_YController.getValue(), 1, 0,
			0, 0, 0, 1
		);

		cameraIsMoving = true;
		needChangeDSkew = false;
	}

	if (needChangeDRotation)
	{
		CSG_shapeD.rotation.set(THREE.MathUtils.degToRad(transformD_RotationXController.getValue()),
			THREE.MathUtils.degToRad(transformD_RotationYController.getValue()),
			THREE.MathUtils.degToRad(transformD_RotationZController.getValue()));

		cameraIsMoving = true;
		needChangeDRotation = false;
	}

	if (needChangeDShapeType)
	{
		currentDShapeType = shapeD_TypeController.getValue();


		if (currentDShapeType == 'Box')
		{
			pathTracingUniforms.uShapeDType.value = 7;
			parameterD_kController.domElement.hidden = true;
		}
		else if (currentDShapeType == 'ConicalPrism')
		{
			pathTracingUniforms.uShapeDType.value = 9;
			parameterD_kController.domElement.hidden = false;
			//parameterD_kController.setValue(1);
		}

		cameraIsMoving = true;
		needChangeDShapeType = false;
	}

	if (needChangeDParameterK)
	{
		kValue = parameterD_kController.getValue();
		//parameterD_kController.setValue(kValue);
		pathTracingUniforms.uD_kParameter.value = kValue;

		cameraIsMoving = true;
		needChangeDParameterK = false;
	}


	if (needChangeOperationDEType)
	{
		if (csgOperationDE_TypeController.getValue() == 'Union (D + E)')
		{
			pathTracingUniforms.uCSG_OperationDEType.value = 0;
		}
		else if (csgOperationDE_TypeController.getValue() == 'Difference (D - E)')
		{
			pathTracingUniforms.uCSG_OperationDEType.value = 1;
		}

		cameraIsMoving = true;
		needChangeOperationDEType = false;
	}

	// SHAPE E
	if (needChangeEPosition)
	{
		CSG_shapeE.position.set(transformE_PositionXController.getValue(),
					transformE_PositionYController.getValue(),
					transformE_PositionZController.getValue());

		cameraIsMoving = true;
		needChangeEPosition = false;
	}

	if (needChangeEScaleUniform)
	{
		uniformScale = transformE_ScaleUniformController.getValue();
		CSG_shapeE.scale.set(uniformScale, uniformScale, uniformScale);

		transformE_ScaleXController.setValue(uniformScale);
		transformE_ScaleYController.setValue(uniformScale);
		transformE_ScaleZController.setValue(uniformScale);

		cameraIsMoving = true;
		needChangeEScaleUniform = false;
	}

	if (needChangeEScale)
	{
		CSG_shapeE.scale.set(transformE_ScaleXController.getValue(),
				     transformE_ScaleYController.getValue(),
				     transformE_ScaleZController.getValue());

		cameraIsMoving = true;
		needChangeEScale = false;
	}

	if (needChangeESkew)
	{
		E_SkewMatrix.set(
			1, transformE_SkewX_YController.getValue(), transformE_SkewX_ZController.getValue(), 0,
			transformE_SkewY_XController.getValue(), 1, transformE_SkewY_ZController.getValue(), 0,
			transformE_SkewZ_XController.getValue(), transformE_SkewZ_YController.getValue(), 1, 0,
			0, 0, 0, 1
		);

		cameraIsMoving = true;
		needChangeESkew = false;
	}

	if (needChangeERotation)
	{
		CSG_shapeE.rotation.set(THREE.MathUtils.degToRad(transformE_RotationXController.getValue()),
			THREE.MathUtils.degToRad(transformE_RotationYController.getValue()),
			THREE.MathUtils.degToRad(transformE_RotationZController.getValue()));

		cameraIsMoving = true;
		needChangeERotation = false;
	}

	if (needChangeEShapeType)
	{
		currentEShapeType = shapeE_TypeController.getValue();


		if (currentEShapeType == 'Box')
		{
			pathTracingUniforms.uShapeEType.value = 7;
			parameterE_kController.domElement.hidden = true;
		}
		else if (currentEShapeType == 'ConicalPrism')
		{
			pathTracingUniforms.uShapeEType.value = 9;
			parameterE_kController.domElement.hidden = false;
			//parameterE_kController.setValue(1);
		}

		cameraIsMoving = true;
		needChangeEShapeType = false;
	}

	if (needChangeEParameterK)
	{
		kValue = parameterE_kController.getValue();
		//parameterE_kController.setValue(kValue);
		pathTracingUniforms.uE_kParameter.value = kValue;

		cameraIsMoving = true;
		needChangeEParameterK = false;
	}


	if (needChangeOperationEFType)
	{
		if (csgOperationEF_TypeController.getValue() == 'Union (E + F)')
		{
			pathTracingUniforms.uCSG_OperationEFType.value = 0;
		}
		else if (csgOperationEF_TypeController.getValue() == 'Difference (E - F)')
		{
			pathTracingUniforms.uCSG_OperationEFType.value = 1;
		}

		cameraIsMoving = true;
		needChangeOperationEFType = false;
	}

	// SHAPE F
	if (needChangeFPosition)
	{
		CSG_shapeF.position.set(transformF_PositionXController.getValue(),
					transformF_PositionYController.getValue(),
					transformF_PositionZController.getValue());

		cameraIsMoving = true;
		needChangeFPosition = false;
	}

	if (needChangeFScaleUniform)
	{
		uniformScale = transformF_ScaleUniformController.getValue();
		CSG_shapeF.scale.set(uniformScale, uniformScale, uniformScale);

		transformF_ScaleXController.setValue(uniformScale);
		transformF_ScaleYController.setValue(uniformScale);
		transformF_ScaleZController.setValue(uniformScale);

		cameraIsMoving = true;
		needChangeFScaleUniform = false;
	}

	if (needChangeFScale)
	{
		CSG_shapeF.scale.set(transformF_ScaleXController.getValue(),
				     transformF_ScaleYController.getValue(),
				     transformF_ScaleZController.getValue());

		cameraIsMoving = true;
		needChangeFScale = false;
	}

	if (needChangeFSkew)
	{
		F_SkewMatrix.set(
			1, transformF_SkewX_YController.getValue(), transformF_SkewX_ZController.getValue(), 0,
			transformF_SkewY_XController.getValue(), 1, transformF_SkewY_ZController.getValue(), 0,
			transformF_SkewZ_XController.getValue(), transformF_SkewZ_YController.getValue(), 1, 0,
			0, 0, 0, 1
		);

		cameraIsMoving = true;
		needChangeFSkew = false;
	}

	if (needChangeFRotation)
	{
		CSG_shapeF.rotation.set(THREE.MathUtils.degToRad(transformF_RotationXController.getValue()),
			THREE.MathUtils.degToRad(transformF_RotationYController.getValue()),
			THREE.MathUtils.degToRad(transformF_RotationZController.getValue()));

		cameraIsMoving = true;
		needChangeFRotation = false;
	}

	if (needChangeFShapeType)
	{
		currentFShapeType = shapeF_TypeController.getValue();


		if (currentFShapeType == 'Box')
		{
			pathTracingUniforms.uShapeFType.value = 7;
			parameterF_kController.domElement.hidden = true;
		}
		else if (currentFShapeType == 'ConicalPrism')
		{
			pathTracingUniforms.uShapeFType.value = 9;
			parameterF_kController.domElement.hidden = false;
			//parameterF_kController.setValue(1);
		}

		cameraIsMoving = true;
		needChangeFShapeType = false;
	}

	if (needChangeFParameterK)
	{
		kValue = parameterF_kController.getValue();
		//parameterF_kController.setValue(kValue);
		pathTracingUniforms.uF_kParameter.value = kValue;

		cameraIsMoving = true;
		needChangeFParameterK = false;
	}



	CSG_shapeA.matrixWorld.multiply(A_SkewMatrix); // multiply shapeA's matrix by my custom skew(shear) matrix4
	pathTracingUniforms.uCSG_ShapeA_InvMatrix.value.copy(CSG_shapeA.matrixWorld).invert();

	CSG_shapeB.matrixWorld.multiply(B_SkewMatrix);
	pathTracingUniforms.uCSG_ShapeB_InvMatrix.value.copy(CSG_shapeB.matrixWorld).invert();

	CSG_shapeC.matrixWorld.multiply(C_SkewMatrix);
	pathTracingUniforms.uCSG_ShapeC_InvMatrix.value.copy(CSG_shapeC.matrixWorld).invert();

	CSG_shapeD.matrixWorld.multiply(D_SkewMatrix);
	pathTracingUniforms.uCSG_ShapeD_InvMatrix.value.copy(CSG_shapeD.matrixWorld).invert();

	CSG_shapeE.matrixWorld.multiply(E_SkewMatrix);
	pathTracingUniforms.uCSG_ShapeE_InvMatrix.value.copy(CSG_shapeE.matrixWorld).invert();

	CSG_shapeF.matrixWorld.multiply(F_SkewMatrix);
	pathTracingUniforms.uCSG_ShapeF_InvMatrix.value.copy(CSG_shapeF.matrixWorld).invert();


	// INFO
	cameraInfoElement.innerHTML = "FOV: " + worldCamera.fov + " / Aperture: " + apertureSize.toFixed(2) + " / FocusDistance: " + focusDistance + "<br>" + "Samples: " + sampleCounter;

} // end function updateVariablesAndUniforms()



// load all resources
lightTexture = textureLoader.load(
	// resource URL
	'textures/plusSignLight.png',

	// onLoad callback
	function (texture)
	{
		texture.wrapS = THREE.RepeatWrapping;
		texture.wrapT = THREE.RepeatWrapping;
		texture.minFilter = THREE.NearestFilter;
		texture.magFilter = THREE.NearestFilter;
		texture.generateMipmaps = false;

		numOfImageTexturesLoaded++;
		// if all textures have been loaded, we can init 
		if (numOfImageTexturesLoaded == imageTexturesTotalCount)
			init();
	}
);

medLightTexture = textureLoader.load(
	// resource URL
	'textures/plusSignMedLight.png',

	// onLoad callback
	function (texture)
	{
		texture.wrapS = THREE.RepeatWrapping;
		texture.wrapT = THREE.RepeatWrapping;
		texture.minFilter = THREE.NearestFilter;
		texture.magFilter = THREE.NearestFilter;
		texture.generateMipmaps = false;

		numOfImageTexturesLoaded++;
		// if all textures have been loaded, we can init 
		if (numOfImageTexturesLoaded == imageTexturesTotalCount)
			init();
	}
);

mediumTexture = textureLoader.load(
	// resource URL
	'textures/plusSignMedium.png',

	// onLoad callback
	function (texture)
	{
		texture.wrapS = THREE.RepeatWrapping;
		texture.wrapT = THREE.RepeatWrapping;
		texture.minFilter = THREE.NearestFilter;
		texture.magFilter = THREE.NearestFilter;
		texture.generateMipmaps = false;

		numOfImageTexturesLoaded++;
		// if all textures have been loaded, we can init 
		if (numOfImageTexturesLoaded == imageTexturesTotalCount)
			init();
	}
);

medDarkTexture = textureLoader.load(
	// resource URL
	'textures/plusSignMedDark.png',

	// onLoad callback
	function (texture)
	{
		texture.wrapS = THREE.RepeatWrapping;
		texture.wrapT = THREE.RepeatWrapping;
		texture.minFilter = THREE.NearestFilter;
		texture.magFilter = THREE.NearestFilter;
		texture.generateMipmaps = false;

		numOfImageTexturesLoaded++;
		// if all textures have been loaded, we can init 
		if (numOfImageTexturesLoaded == imageTexturesTotalCount)
			init();
	}
);

darkTexture = textureLoader.load(
	// resource URL
	'textures/plusSignDark.png',

	// onLoad callback
	function (texture)
	{
		texture.wrapS = THREE.RepeatWrapping;
		texture.wrapT = THREE.RepeatWrapping;
		texture.minFilter = THREE.NearestFilter;
		texture.magFilter = THREE.NearestFilter;
		texture.generateMipmaps = false;

		numOfImageTexturesLoaded++;
		// if all textures have been loaded, we can init 
		if (numOfImageTexturesLoaded == imageTexturesTotalCount)
			init();
	}
);
