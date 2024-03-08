// scene/demo-specific variables go here
let initialBoxGeometry;
let boxGeometry, boxMaterial, boxMesh;

let torus;
let torusRotationAngle = 0;
let torusScale = 0;
let torusHeight = 0;
let torusHoleSize = 0;
let scaleFactor = 0;

let torus_ScaleObject, torus_ScaleController;
let needChangeTorusScale = false;
let torus_HeightObject, torus_HeightController;
let needChangeTorusHeight = false;
let torus_HoleSizeObject, torus_HoleSizeController;
let needChangeTorusHoleSize = false;
let torus_HoleSizeFineObject, torus_HoleSizeFineController;
let needChangeTorusHoleSizeFine = false;
let showTorusAABB_ToggleController, showTorusAABB_ToggleObject;
let needChangeShowTorusAABB = false;

let material_TypeObject, material_TypeController;
let needChangeMaterialType = false;
let matType = 0;
let material_ColorObject, material_ColorController;
let needChangeMaterialColor = false;
let matColor;
let rotation_Folder;
let transform_RotationXController, transform_RotationXObject;
let transform_RotationYController, transform_RotationYObject;
let transform_RotationZController, transform_RotationZObject;
let needChangeRotation = false;


function init_GUI()
{
	torus_ScaleObject = { torusScale: 7 };
	torus_HeightObject = { torusHeight: 0.5 };
	torus_HoleSizeFineObject = { torusHoleSizeFine: 0.01 };
	torus_HoleSizeObject = { torusHoleSize: 0.01 };
	material_TypeObject = { torus_Material: 'Diffuse' };
	material_ColorObject = { torus_Color: [1, 1, 1] };
	showTorusAABB_ToggleObject = { show_torusAABB: false }
	transform_RotationXObject = { rotationX: 0 };
	transform_RotationYObject = { rotationY: 0 };
	transform_RotationZObject = { rotationZ: 0 };
	
	function handleTorusScaleChange() { needChangeTorusScale = true; }
	function handleTorusHeightChange() { needChangeTorusHeight = true; }
	function handleTorusHoleSizeFineChange() { needChangeTorusHoleSizeFine = true; }
	function handleTorusHoleSizeChange() { needChangeTorusHoleSize = true; }
	function handleMaterialTypeChange() { needChangeMaterialType = true; }
	function handleMaterialColorChange() { needChangeMaterialColor = true; }
	function handleShowTorusAABBChange(){ needChangeShowTorusAABB = true; }
	function handleRotationChange() { needChangeRotation = true; }
	
	torus_ScaleController = gui.add(torus_ScaleObject, 'torusScale', 1, 30, 0.1).onChange(handleTorusScaleChange);
	
	rotation_Folder = gui.addFolder('Rotation');
	transform_RotationXController = rotation_Folder.add(transform_RotationXObject, 'rotationX', 0, 359, 1).onChange(handleRotationChange);
	transform_RotationYController = rotation_Folder.add(transform_RotationYObject, 'rotationY', 0, 359, 1).onChange(handleRotationChange);
	transform_RotationZController = rotation_Folder.add(transform_RotationZObject, 'rotationZ', 0, 359, 1).onChange(handleRotationChange);
	
	torus_HeightController = gui.add(torus_HeightObject, 'torusHeight', 0.005, 0.7, 0.01).onChange(handleTorusHeightChange);
	torus_HoleSizeFineController = gui.add(torus_HoleSizeFineObject, 'torusHoleSizeFine', 0, 0.1, 0.0001).onChange(handleTorusHoleSizeFineChange);
	torus_HoleSizeController = gui.add(torus_HoleSizeObject, 'torusHoleSize', 0, 0.99, 0.001).onChange(handleTorusHoleSizeChange);
	material_TypeController = gui.add(material_TypeObject, 'torus_Material', ['Diffuse', 
		'Metal', 'ClearCoat Diffuse', 'Transparent Refractive']).onChange(handleMaterialTypeChange);
	material_ColorController = gui.addColor(material_ColorObject, 'torus_Color').onChange(handleMaterialColorChange);
	showTorusAABB_ToggleController = gui.add(showTorusAABB_ToggleObject, 'show_torusAABB', false).onChange(handleShowTorusAABBChange);

	handleTorusScaleChange();
	handleTorusHeightChange();
	handleTorusHoleSizeChange();
	handleTorusHoleSizeFineChange();
	handleMaterialTypeChange();
	handleMaterialColorChange();
	handleShowTorusAABBChange();
	handleRotationChange();

} // end function init_GUI()



// called automatically from within initTHREEjs() function (located in InitCommon.js file)
function initSceneData()
{
	demoFragmentShaderFileName = 'Cheap_Torus_Fragment.glsl';

	// scene/demo-specific three.js objects setup goes here
	sceneIsDynamic = false;

	edgeSharpenSpeed = 0.1;

	cameraFlightSpeed = 50;

	// pixelRatio is resolution - range: 0.5(half resolution) to 1.0(full resolution)
	pixelRatio = mouseControl ? 0.75 : 0.75;

	EPS_intersect = 0.001;

	// set camera's field of view
	worldCamera.fov = 60;
	focusDistance = 100.0;
	apertureChangeSpeed = 10;

	// position and orient camera
	cameraControlsObject.position.set(0, 20, 30);
	///cameraControlsYawObject.rotation.y = 0.0;
	// look slightly up or down
	cameraControlsPitchObject.rotation.x = -0.58;


	torus = new THREE.Object3D();
	torus.position.set(0, 0, 0);

	// even though this will eventually produce/render a box, instead of using THREE.BoxGeometry(2,2,2) (unit radius of 1 in all axes), 
	// I found that using THREE.CylinderGeometry produces a tighter-fitting AABB when the torus shape is rotated
	initialBoxGeometry = new THREE.CylinderGeometry(); // use Cylinder as a starting point instead of Box
	boxGeometry = new THREE.CylinderGeometry(); // use Cylinder as a starting point instead of Box
	boxMaterial = new THREE.MeshBasicMaterial();
	boxMesh = new THREE.Mesh( boxGeometry, boxMaterial );

	
	// scene/demo-specific uniforms go here
	pathTracingUniforms.uTorus_InvMatrix = { value: new THREE.Matrix4() };
	pathTracingUniforms.uBoxMinCorner = { value: new THREE.Vector3() };
	pathTracingUniforms.uBoxMaxCorner = { value: new THREE.Vector3() };
	pathTracingUniforms.uTorusHoleSize = { value: 0.01 };
	pathTracingUniforms.uMaterialType = { value: 0 };
	pathTracingUniforms.uMaterialColor = { value: new THREE.Color(1.0, 0.0, 1.0) };
	pathTracingUniforms.uShowTorusAABB = { type: "b1", value: false };

	init_GUI();

} // end function initSceneData()





// called automatically from within the animate() function (located in InitCommon.js file)
function updateVariablesAndUniforms()
{

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

	if (needChangeRotation)
	{
		torus.rotation.set(THREE.MathUtils.degToRad(transform_RotationXController.getValue()),
			THREE.MathUtils.degToRad(transform_RotationYController.getValue()),
			THREE.MathUtils.degToRad(transform_RotationZController.getValue()));

		torus.updateMatrixWorld(true);
		pathTracingUniforms.uTorus_InvMatrix.value.copy(torus.matrixWorld).invert();

		boxMesh.rotation.copy(torus.rotation);
		boxMesh.updateMatrixWorld(true);
		boxMesh.geometry.copy(initialBoxGeometry);
		boxMesh.geometry.applyMatrix4(boxMesh.matrixWorld);
		boxMesh.geometry.computeBoundingBox();
		pathTracingUniforms.uBoxMinCorner.value.copy(boxMesh.geometry.boundingBox.min);
		pathTracingUniforms.uBoxMaxCorner.value.copy(boxMesh.geometry.boundingBox.max);

		cameraIsMoving = true;
		needChangeRotation = false;
	}

	if (needChangeTorusScale || needChangeTorusHeight || needChangeTorusHoleSize || needChangeTorusHoleSizeFine)
	{
		if (needChangeTorusHoleSizeFine)
			torus_HoleSizeController.setValue(torus_HoleSizeFineController.getValue());

		if (needChangeTorusHoleSize && torus_HoleSizeController.getValue() <= 0.1)
			torus_HoleSizeFineController.setValue(torus_HoleSizeController.getValue());
		
		torusScale = torus_ScaleController.getValue();
		torusHeight = torus_HeightController.getValue();
		torusHoleSize = torus_HoleSizeController.getValue();

		if (needChangeTorusHoleSize)
		{
			// note: I tried to be clever and come up with a function f(x) that hits the following points on the sort-of exponential-looking 
			// curve which decreases the size of the torus height radius as a function of the torus hole getting bigger, but alas I failed.
			// Therefore, I did the next best thing and defined some points along that elbow-curve that I wanted to hit, and then did a 
			// linear interpolation from point to point along the curve (kind of like moving a video game character/camera along a pre-defined
			// path).  In the end though, 'torusHeight'(radius) is re-writable, if these points do not satisfy the torus shape you're after.
			     if (torusHoleSize < 0.01) torus_HeightController.setValue(THREE.MathUtils.mapLinear(torusHoleSize, 0.0,  0.01, 0.65,  0.4));
			else if (torusHoleSize < 0.03) torus_HeightController.setValue(THREE.MathUtils.mapLinear(torusHoleSize, 0.01, 0.03, 0.4,   0.2));
			else if (torusHoleSize < 0.05) torus_HeightController.setValue(THREE.MathUtils.mapLinear(torusHoleSize, 0.03, 0.05, 0.2,   0.15));
			else if (torusHoleSize < 0.1 ) torus_HeightController.setValue(THREE.MathUtils.mapLinear(torusHoleSize, 0.05, 0.1,  0.15,  0.1));
			else if (torusHoleSize < 0.2 ) torus_HeightController.setValue(THREE.MathUtils.mapLinear(torusHoleSize, 0.1,  0.2,  0.1,   0.055));
			else if (torusHoleSize < 0.3 ) torus_HeightController.setValue(THREE.MathUtils.mapLinear(torusHoleSize, 0.2,  0.3,  0.055, 0.035));
			else if (torusHoleSize < 0.4 ) torus_HeightController.setValue(THREE.MathUtils.mapLinear(torusHoleSize, 0.3,  0.4,  0.035, 0.03));
			else if (torusHoleSize < 0.5 ) torus_HeightController.setValue(THREE.MathUtils.mapLinear(torusHoleSize, 0.4,  0.5,  0.03,  0.025));
			else if (torusHoleSize < 0.6 ) torus_HeightController.setValue(THREE.MathUtils.mapLinear(torusHoleSize, 0.5,  0.6,  0.025, 0.02));
			else if (torusHoleSize < 0.8 ) torus_HeightController.setValue(THREE.MathUtils.mapLinear(torusHoleSize, 0.6,  0.8,  0.02,  0.015));
			else if (torusHoleSize < 1.01) torus_HeightController.setValue(THREE.MathUtils.mapLinear(torusHoleSize, 0.8,  1.0,  0.015, 0.01));
			
			torusHeight = torus_HeightController.getValue();
		}

		
		//torus.rotation.set(0, 0, Math.PI * 0.5);
		scaleFactor = THREE.MathUtils.mapLinear(torusHoleSize, 0, 1, 1, 50);
		scaleFactor = 1 / Math.sqrt(scaleFactor);
		torus.scale.set(torusScale * scaleFactor, torusScale * torusHeight, torusScale * scaleFactor);
		torus.updateMatrixWorld(true);
		// the following multiplication (torusHoleSize * 100) is for the quadric shape definition of the hyperboloid inside the fragment shader  
		pathTracingUniforms.uTorusHoleSize.value = torusHoleSize * 100;
		pathTracingUniforms.uTorus_InvMatrix.value.copy(torus.matrixWorld).invert();

		boxMesh.scale.set(torusScale * 1.45, torusScale * torusHeight * 2, torusScale * 1.45);
		boxMesh.updateMatrixWorld(true);
		boxMesh.geometry.copy(initialBoxGeometry);
		boxMesh.geometry.applyMatrix4(boxMesh.matrixWorld);
		boxMesh.geometry.computeBoundingBox();
		pathTracingUniforms.uBoxMinCorner.value.copy(boxMesh.geometry.boundingBox.min);
		pathTracingUniforms.uBoxMaxCorner.value.copy(boxMesh.geometry.boundingBox.max);
		
		
		cameraIsMoving = true;
		needChangeTorusScale = false;
		needChangeTorusHeight = false;
		needChangeTorusHoleSize = false;
		needChangeTorusHoleSizeFine = false;
	} // end if (needChangeTorusScale || needChangeTorusHeight || needChangeTorusHoleSize || needChangeTorusHoleSizeFine)


	if (needChangeShowTorusAABB)
	{
		pathTracingUniforms.uShowTorusAABB.value = showTorusAABB_ToggleController.getValue();
		cameraIsMoving = true;
		needChangeShowTorusAABB = false;
	}

	// torusRotationAngle += (0.4 * frameTime);
	// torusRotationAngle %= TWO_PI;
	// torus.rotation.set(0, torusRotationAngle, Math.PI * 0.1);
	// torus.updateMatrixWorld(true);
	// pathTracingUniforms.uTorus_InvMatrix.value.copy(torus.matrixWorld).invert();


	// INFO
	cameraInfoElement.innerHTML = "FOV: " + worldCamera.fov + " / Aperture: " + apertureSize.toFixed(2) + " / FocusDistance: " + focusDistance + "<br>" + "Samples: " + sampleCounter;

} // end function updateVariablesAndUniforms()



init(); // init app and start animating