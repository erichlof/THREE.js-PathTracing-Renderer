// scene/demo-specific variables go here
let UVGridTexture;
let initialBoxGeometry;
let boxGeometry, boxMaterial, boxMesh;

let torus;
let torusLargestScale = 1;
let torusTubeRadius = 0;
let torus_TubeRadiusObject, torus_TubeRadiusController;
let needChangeTorusTubeRadius = false;
let torus_ClipMinAngleObject, torus_ClipMinAngleController;
let torus_ClipMaxAngleObject, torus_ClipMaxAngleController;
let needChangeTorusClipAngleBounds = false;
let torus_ClipMinXObject, torus_ClipMinXController;
let torus_ClipMaxXObject, torus_ClipMaxXController;
let torus_ClipMinYObject, torus_ClipMinYController;
let torus_ClipMaxYObject, torus_ClipMaxYController;
let torus_ClipMinZObject, torus_ClipMinZController;
let torus_ClipMaxZObject, torus_ClipMaxZController;
let needChangeTorusClipXYZBounds = false;
let torus_ClipMinRadiusObject, torus_ClipMinRadiusController;
let torus_ClipMaxRadiusObject, torus_ClipMaxRadiusController;
let needChangeTorusClipRadiusBounds = false;
let showTorusUVs_ToggleController, showTorusUVs_ToggleObject;
let needChangeShowTorusUVs = false;
let showTorusUVs = false;
let torus_UVxObject, torus_UVxController;
let torus_UVyObject, torus_UVyController;
let needChangeTorusUVs = false;
let showTorusAABB_ToggleController, showTorusAABB_ToggleObject;
let needChangeShowTorusAABB = false;
let checkeredTorus_ToggleController, checkeredTorus_ToggleObject;
let needChangeCheckeredTorus = false;
let torusIsCheckered = false;
let material_TypeObject, material_TypeController;
let needChangeMaterialType = false;
let matType = 0;
let material_ColorObject, material_ColorController;
let needChangeMaterialColor = false;
let matColor;
let uniformScale = 1;
let scale_Folder;
let transform_ScaleUniformController, transform_ScaleUniformObject;
let transform_ScaleXController, transform_ScaleXObject;
let transform_ScaleYController, transform_ScaleYObject;
let transform_ScaleZController, transform_ScaleZObject;
let needChangeScaleUniform = false;
let needChangeScale = false;
let position_Folder;
let transform_PositionXController, transform_PositionXObject;
let transform_PositionYController, transform_PositionYObject;
let transform_PositionZController, transform_PositionZObject;
let needChangePosition = false;
let rotation_Folder;
let transform_RotationXController, transform_RotationXObject;
let transform_RotationYController, transform_RotationYObject;
let transform_RotationZController, transform_RotationZObject;
let needChangeRotation = false;


function init_GUI()
{
	torus_TubeRadiusObject = { torusTubeRadius: 0.5 };
	torus_ClipMinAngleObject = { clipMinAnglePercent: 0.0 };
	torus_ClipMaxAngleObject = { clipMaxAnglePercent: 1.0 };
	torus_ClipMinXObject = { clipMinX: -1.0 };
	torus_ClipMaxXObject = { clipMaxX: 1.0 };
	torus_ClipMinYObject = { clipMinY: -1.0 };
	torus_ClipMaxYObject = { clipMaxY: 1.0 };
	torus_ClipMinZObject = { clipMinZ: -1.0 };
	torus_ClipMaxZObject = { clipMaxZ: 1.0 };
	torus_ClipMinRadiusObject = { clipMinRadius: 0.0 };
	torus_ClipMaxRadiusObject = { clipMaxRadius: 1.0 };
	transform_ScaleUniformObject = { uniformScale: 12 };
	transform_ScaleXObject = { scaleX: 12 };
	transform_ScaleYObject = { scaleY: 12 };
	transform_ScaleZObject = { scaleZ: 12 };
	transform_PositionXObject = { positionX: 0 };
	transform_PositionYObject = { positionY: 0 };
	transform_PositionZObject = { positionZ: 0 };
	transform_RotationXObject = { rotationX: 0 };
	transform_RotationYObject = { rotationY: 0 };
	transform_RotationZObject = { rotationZ: 0 };
	material_TypeObject = { torus_Material: 'ClearCoat Diffuse' };
	material_ColorObject = { torus_Color: [1, 1, 1] };
	checkeredTorus_ToggleObject = { checkered_torus: false };
	showTorusUVs_ToggleObject = { show_torusUVs: false };
	torus_UVxObject = { torusUV_x: 8 };
	torus_UVyObject = { torusUV_y: 4 };
	showTorusAABB_ToggleObject = { show_torusAABB: false };
	
	function handleTorusTubeRadiusChange() { needChangeTorusTubeRadius = true; }
	function handleTorusClipAngleChange() { needChangeTorusClipAngleBounds = true; }
	function handleTorusClipXYZChange() { needChangeTorusClipXYZBounds = true; }
	function handleTorusClipRadiusChange() { needChangeTorusClipRadiusBounds = true; }
	function handleScaleUniformChange() { needChangeScaleUniform = true; }
	function handleScaleChange() { needChangeScale = true; }
	function handlePositionChange() { needChangePosition = true; }
	function handleRotationChange() { needChangeRotation = true; }
	function handleMaterialTypeChange() { needChangeMaterialType = true; }
	function handleMaterialColorChange() { needChangeMaterialColor = true; }
	function handleCheckeredTorusChange() { needChangeCheckeredTorus = true; }
	function handleShowTorusUVsChange() { needChangeShowTorusUVs = true; }
	function handleTorusUVsChange() { needChangeTorusUVs = true; }
	function handleShowTorusAABBChange(){ needChangeShowTorusAABB = true; }
	
	torus_TubeRadiusController = gui.add(torus_TubeRadiusObject, 'torusTubeRadius', 0.01, 1.0, 0.01).onChange(handleTorusTubeRadiusChange);
	torus_ClipMinAngleController = gui.add(torus_ClipMinAngleObject, 'clipMinAnglePercent', 0.00, 0.99, 0.01).onChange(handleTorusClipAngleChange);
	torus_ClipMaxAngleController = gui.add(torus_ClipMaxAngleObject, 'clipMaxAnglePercent', 0.01, 1.00, 0.01).onChange(handleTorusClipAngleChange);
	torus_ClipMinXController = gui.add(torus_ClipMinXObject, 'clipMinX', -1.0, 0.0, 0.01).onChange(handleTorusClipXYZChange);
	torus_ClipMaxXController = gui.add(torus_ClipMaxXObject, 'clipMaxX',  0.0, 1.0, 0.01).onChange(handleTorusClipXYZChange);
	torus_ClipMinYController = gui.add(torus_ClipMinYObject, 'clipMinY', -1.0, 0.0, 0.01).onChange(handleTorusClipXYZChange);
	torus_ClipMaxYController = gui.add(torus_ClipMaxYObject, 'clipMaxY',  0.0, 1.0, 0.01).onChange(handleTorusClipXYZChange);
	torus_ClipMinZController = gui.add(torus_ClipMinZObject, 'clipMinZ', -1.0, 0.0, 0.01).onChange(handleTorusClipXYZChange);
	torus_ClipMaxZController = gui.add(torus_ClipMaxZObject, 'clipMaxZ',  0.0, 1.0, 0.01).onChange(handleTorusClipXYZChange);
	torus_ClipMinRadiusController = gui.add(torus_ClipMinRadiusObject, 'clipMinRadius', 0.00, 0.99, 0.01).onChange(handleTorusClipRadiusChange);
	torus_ClipMaxRadiusController = gui.add(torus_ClipMaxRadiusObject, 'clipMaxRadius', 0.01, 1.00, 0.01).onChange(handleTorusClipRadiusChange);
	
	scale_Folder = gui.addFolder('Scale');
	transform_ScaleUniformController = scale_Folder.add(transform_ScaleUniformObject, 'uniformScale', 1, 40, 1).onChange(handleScaleUniformChange);
	transform_ScaleXController = scale_Folder.add(transform_ScaleXObject, 'scaleX', 1, 40, 1).onChange(handleScaleChange);
	transform_ScaleYController = scale_Folder.add(transform_ScaleYObject, 'scaleY', 1, 40, 1).onChange(handleScaleChange);
	transform_ScaleZController = scale_Folder.add(transform_ScaleZObject, 'scaleZ', 1, 40, 1).onChange(handleScaleChange);

	rotation_Folder = gui.addFolder('Rotation');
	transform_RotationXController = rotation_Folder.add(transform_RotationXObject, 'rotationX', 0, 359, 1).onChange(handleRotationChange);
	transform_RotationYController = rotation_Folder.add(transform_RotationYObject, 'rotationY', 0, 359, 1).onChange(handleRotationChange);
	transform_RotationZController = rotation_Folder.add(transform_RotationZObject, 'rotationZ', 0, 359, 1).onChange(handleRotationChange);
	
	position_Folder = gui.addFolder('Position');
	transform_PositionXController = position_Folder.add(transform_PositionXObject, 'positionX', -50, 50, 1).onChange(handlePositionChange);
	transform_PositionYController = position_Folder.add(transform_PositionYObject, 'positionY', -50, 50, 1).onChange(handlePositionChange);
	transform_PositionZController = position_Folder.add(transform_PositionZObject, 'positionZ', -50, 50, 1).onChange(handlePositionChange);
	position_Folder.close();

	material_TypeController = gui.add(material_TypeObject, 'torus_Material', ['Diffuse', 
		'Metal', 'ClearCoat Diffuse', 'Transparent Refractive']).onChange(handleMaterialTypeChange);
	material_ColorController = gui.addColor(material_ColorObject, 'torus_Color').onChange(handleMaterialColorChange);
	checkeredTorus_ToggleController = gui.add(checkeredTorus_ToggleObject, 'checkered_torus', false).onChange(handleCheckeredTorusChange);
	showTorusUVs_ToggleController = gui.add(showTorusUVs_ToggleObject, 'show_torusUVs', false).onChange(handleShowTorusUVsChange);
	torus_UVxController = gui.add(torus_UVxObject, 'torusUV_x', 1, 20, 1).onChange(handleTorusUVsChange);
	torus_UVyController = gui.add(torus_UVyObject, 'torusUV_y', 1, 20, 1).onChange(handleTorusUVsChange);

	showTorusAABB_ToggleController = gui.add(showTorusAABB_ToggleObject, 'show_torusAABB', false).onChange(handleShowTorusAABBChange);

	handleTorusTubeRadiusChange();
	handleTorusClipAngleChange();
	handleTorusClipRadiusChange();
	handleTorusClipXYZChange();
	handleScaleUniformChange();
	handleScaleChange();
	handlePositionChange();
	handleRotationChange();
	handleMaterialTypeChange();
	handleMaterialColorChange();
	handleCheckeredTorusChange();
	handleShowTorusUVsChange();
	handleTorusUVsChange();
	handleShowTorusAABBChange();

} // end function init_GUI()



// called automatically from within initTHREEjs() function (located in InitCommon.js file)
function initSceneData()
{
	demoFragmentShaderFileName = 'Classic_Torus_Fragment.glsl';

	// scene/demo-specific three.js objects setup goes here
	sceneIsDynamic = false;

	cameraFlightSpeed = 50;

	// pixelRatio is resolution - range: 0.5(half resolution) to 1.0(full resolution)
	pixelRatio = mouseControl ? 1.0 : 1.0;

	EPS_intersect = 0.001;

	// set camera's field of view
	worldCamera.fov = 50;
	focusDistance = 32.0;
	apertureChangeSpeed = 10;

	// position and orient camera
	cameraControlsObject.position.set(0, 0, 150);
	///cameraControlsYawObject.rotation.y = 0.0;
	// look slightly up or down
	//cameraControlsPitchObject.rotation.x = -0.2;


	torus = new THREE.Object3D();

	initialBoxGeometry = new THREE.SphereGeometry();
	boxGeometry = new THREE.SphereGeometry();
	boxMaterial = new THREE.MeshBasicMaterial();
	boxMesh = new THREE.Mesh( boxGeometry, boxMaterial );

	
	// scene/demo-specific uniforms go here
	pathTracingUniforms.uUVGridTexture = { value: UVGridTexture };
	pathTracingUniforms.uTorus_InvMatrix = { value: new THREE.Matrix4() };
	pathTracingUniforms.uTorusPosition = { value: new THREE.Vector3() };
	pathTracingUniforms.uTorusMinXYZ = { value: new THREE.Vector3() };
	pathTracingUniforms.uTorusMaxXYZ = { value: new THREE.Vector3() };
	pathTracingUniforms.uTorusUV = { value: new THREE.Vector2() };
	pathTracingUniforms.uTorusLargestScale = { value: 1.0 };
	pathTracingUniforms.uTorusTubeRadius = { value: 0.5 };
	pathTracingUniforms.uTorusMinAnglePercent = { value: 0.0 };
	pathTracingUniforms.uTorusMaxAnglePercent = { value: 1.0 };
	pathTracingUniforms.uTorusMinRadius = { value: 0.0 };
	pathTracingUniforms.uTorusMaxRadius = { value: 1.0 };
	pathTracingUniforms.uMaterialType = { value: 0 };
	pathTracingUniforms.uMaterialColor = { value: new THREE.Color(1.0, 0.0, 1.0) };
	pathTracingUniforms.uTorusIsCheckered = { value: false };
	pathTracingUniforms.uShowTorusUVs = { value: false };
	pathTracingUniforms.uShowTorusAABB = { value: false };

	init_GUI();

} // end function initSceneData()





// called automatically from within the animate() function (located in InitCommon.js file)
function updateVariablesAndUniforms()
{

	if (needChangeTorusTubeRadius)
	{
		torusTubeRadius = torus_TubeRadiusController.getValue();
		pathTracingUniforms.uTorusTubeRadius.value = torusTubeRadius;
		
		cameraIsMoving = true;
		needChangeTorusTubeRadius = false;

		needChangeScale = true;
	}

	if (needChangeTorusClipAngleBounds)
	{
		pathTracingUniforms.uTorusMinAnglePercent.value = torus_ClipMinAngleController.getValue();
		pathTracingUniforms.uTorusMaxAnglePercent.value = torus_ClipMaxAngleController.getValue();

		cameraIsMoving = true;
		needChangeTorusClipAngleBounds = false;
	}

	if (needChangeTorusClipRadiusBounds)
	{
		pathTracingUniforms.uTorusMinRadius.value = torus_ClipMinRadiusController.getValue();
		pathTracingUniforms.uTorusMaxRadius.value = torus_ClipMaxRadiusController.getValue();

		cameraIsMoving = true;
		needChangeTorusClipRadiusBounds = false;
	}

	if (needChangeTorusClipXYZBounds)
	{
		pathTracingUniforms.uTorusMinXYZ.value.set(torus_ClipMinXController.getValue(),
							   torus_ClipMinYController.getValue(),
							   torus_ClipMinZController.getValue());

		pathTracingUniforms.uTorusMaxXYZ.value.set(torus_ClipMaxXController.getValue(),
							   torus_ClipMaxYController.getValue(),
							   torus_ClipMaxZController.getValue());

		cameraIsMoving = true;
		needChangeTorusClipXYZBounds = false;
	}

	if (needChangeScaleUniform)
	{
		uniformScale = transform_ScaleUniformController.getValue();
		torus.scale.set(uniformScale, uniformScale, uniformScale);

		transform_ScaleXController.setValue(uniformScale);
		transform_ScaleYController.setValue(uniformScale);
		transform_ScaleZController.setValue(uniformScale);

		torus.updateMatrixWorld(true);
		pathTracingUniforms.uTorus_InvMatrix.value.copy(torus.matrixWorld).invert();

		torusLargestScale = uniformScale;
		pathTracingUniforms.uTorusLargestScale.value = torusLargestScale;

		cameraIsMoving = true;
		needChangeScaleUniform = false;
	}

	if (needChangeScale)
	{
		torus.scale.set(transform_ScaleXController.getValue(),
			transform_ScaleYController.getValue(),
			transform_ScaleZController.getValue());

		torus.updateMatrixWorld(true);
		pathTracingUniforms.uTorus_InvMatrix.value.copy(torus.matrixWorld).invert();
		
		let fract_Z = torus.scale.z * torusTubeRadius * 0.8;
		if (torus.scale.x >= torus.scale.y && torus.scale.x >= fract_Z)
			torusLargestScale = torus.scale.x;
		else if (torus.scale.y >= torus.scale.x && torus.scale.y >= fract_Z)
			torusLargestScale = torus.scale.y;
		else if (fract_Z > torus.scale.x && fract_Z > torus.scale.y)
			torusLargestScale = fract_Z;
		pathTracingUniforms.uTorusLargestScale.value = torusLargestScale;

		// in shader, final AABB is calculated by:
		//torusAABBmin = vec3(-1) * (uTorusLargestScale * (1.0 + uTorusTubeRadius));
		//torusAABBmax = vec3( 1) * (uTorusLargestScale * (1.0 + uTorusTubeRadius));

		cameraIsMoving = true;
		needChangeScale = false;
	}

	if (needChangeRotation)
	{
		torus.rotation.set(THREE.MathUtils.degToRad(transform_RotationXController.getValue()),
			THREE.MathUtils.degToRad(transform_RotationYController.getValue()),
			THREE.MathUtils.degToRad(transform_RotationZController.getValue()));

		torus.updateMatrixWorld(true);
		pathTracingUniforms.uTorus_InvMatrix.value.copy(torus.matrixWorld).invert();

		cameraIsMoving = true;
		needChangeRotation = false;
	}

	if (needChangePosition)
	{
		torus.position.set(transform_PositionXController.getValue(),
			transform_PositionYController.getValue(),
			transform_PositionZController.getValue());
		
		pathTracingUniforms.uTorusPosition.value.copy(torus.position);

		torus.updateMatrixWorld(true);
		pathTracingUniforms.uTorus_InvMatrix.value.copy(torus.matrixWorld).invert();

		cameraIsMoving = true;
		needChangePosition = false;
	}

	if (needChangeMaterialType) 
	{
		matType = material_TypeController.getValue();

		if (matType == 'Diffuse') 
		{
			pathTracingUniforms.uMaterialType.value = 1;
			pathTracingUniforms.uMaterialColor.value.setRGB(0.01, 0.6, 0.6);
		}
		else if (matType == 'Metal') 
		{
			pathTracingUniforms.uMaterialType.value = 3;
			//pathTracingUniforms.uMaterialColor.value.setRGB(1.000000, 0.765557, 0.336057);
			pathTracingUniforms.uMaterialColor.value.setRGB(0.955008, 0.637427, 0.538163);
		}
		else if (matType == 'ClearCoat Diffuse') 
		{
			pathTracingUniforms.uMaterialType.value = 4;
			pathTracingUniforms.uMaterialColor.value.setRGB(0.3, 0.01, 0.8);
		}
		else if (matType == 'Transparent Refractive') 
		{
			pathTracingUniforms.uMaterialType.value = 2;
			pathTracingUniforms.uMaterialColor.value.setRGB(0.1, 1.0, 0.6);
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
		pathTracingUniforms.uMaterialColor.value.setRGB(matColor[0], matColor[1], matColor[2]);
		
		cameraIsMoving = true;
		needChangeMaterialColor = false;
	}

	if (needChangeCheckeredTorus)
	{
		torusIsCheckered = checkeredTorus_ToggleController.getValue();
		pathTracingUniforms.uTorusIsCheckered.value = torusIsCheckered;

		if (torusIsCheckered)
		{
			torus_UVxController.show();
			torus_UVxController.min(2); torus_UVxController.max(50); torus_UVxController.step(2);
			torus_UVxController.setValue(12);
			torus_UVyController.show();
			torus_UVyController.min(2); torus_UVyController.max(50); torus_UVyController.step(2);
			torus_UVyController.setValue(8);
			
			showTorusUVs_ToggleController.hide();
		}
		else
		{
			showTorusUVs_ToggleController.show();
			if ( !showTorusUVs )
			{
				torus_UVxController.hide();
				torus_UVyController.hide();
			}
		}

		cameraIsMoving = true;
		needChangeCheckeredTorus = false;
	}

	if (needChangeShowTorusUVs)
	{
		showTorusUVs = showTorusUVs_ToggleController.getValue();
		pathTracingUniforms.uShowTorusUVs.value = showTorusUVs;

		if (showTorusUVs)
		{
			torusIsCheckered = false;
			checkeredTorus_ToggleController.setValue(torusIsCheckered);
			pathTracingUniforms.uTorusIsCheckered.value = torusIsCheckered;
			checkeredTorus_ToggleController.hide();
			torus_UVxController.show();
			torus_UVxController.min(0.1); torus_UVxController.max(10); torus_UVxController.step(0.1);
			torus_UVxController.setValue(1.0);
			torus_UVyController.show();
			torus_UVyController.min(0.1); torus_UVyController.max(10); torus_UVyController.step(0.1);
			torus_UVyController.setValue(1.0);
		}
		else
		{
			checkeredTorus_ToggleController.show();
			torus_UVxController.hide();
			torus_UVyController.hide();
		}

		cameraIsMoving = true;
		needChangeShowTorusUVs = false;
	}

	if (needChangeTorusUVs)
	{
		pathTracingUniforms.uTorusUV.value.set(torus_UVxController.getValue(), torus_UVyController.getValue());
		cameraIsMoving = true;
		needChangeTorusUVs = false;
	}

	if (needChangeShowTorusAABB)
	{
		pathTracingUniforms.uShowTorusAABB.value = showTorusAABB_ToggleController.getValue();
		cameraIsMoving = true;
		needChangeShowTorusAABB = false;
	}

	// INFO
	cameraInfoElement.innerHTML = "FOV: " + worldCamera.fov + " / Aperture: " + apertureSize.toFixed(2) + " / FocusDistance: " + focusDistance + "<br>" + "Samples: " + sampleCounter;
	
} // end function updateVariablesAndUniforms()



UVGridTexture = textureLoader.load(
	// resource URL
	'textures/uvGrid.jpg',

	// onLoad callback
	function (texture)
	{
		texture.wrapS = THREE.RepeatWrapping;
		texture.wrapT = THREE.RepeatWrapping;
		texture.flipY = false;
		texture.minFilter = THREE.NearestFilter;
		texture.magFilter = THREE.NearestFilter;
		texture.generateMipmaps = false;
		
		init(); // init app and start animating
	}
);
