// scene/demo-specific variables go here
let material_TypeObject, material_ColorObject;
let material_TypeController, material_ColorController;
let changeMaterialType = false;
let changeMaterialColor = false;
let matType = 0;
let matColor;


// called automatically from within initTHREEjs() function (located in InitCommon.js file)
function initSceneData() 
{
	demoFragmentShaderFileName = 'Material_Roughness_Fragment.glsl';

	// scene/demo-specific three.js objects setup goes here
	sceneIsDynamic = false;
	
	cameraFlightSpeed = 60;

	// pixelRatio is resolution - range: 0.5(half resolution) to 1.0(full resolution)
	pixelRatio = mouseControl ? 0.75 : 0.75;

	EPS_intersect = 0.01;

	// set camera's field of view
	worldCamera.fov = 60;
	focusDistance = 130.0;
	apertureChangeSpeed = 2;

	// position and orient camera
	cameraControlsObject.position.set(0, 20, 120);
	///cameraControlsYawObject.rotation.y = 0.0;
	// look slightly downward
	///cameraControlsPitchObject.rotation.x = -0.4;


	// In addition to the default GUI on all demos, add any special GUI elements that this particular demo requires

	material_TypeObject = {
		Material_Preset: 'ClearCoat Diffuse'
	};
	material_ColorObject = {
		Material_Color: [0, 1, 1]
	};

	function materialTypeChanger() 
	{
		changeMaterialType = true;
	}
	function materialColorChanger() 
	{
		changeMaterialColor = true;
	}

	material_TypeController = gui.add(material_TypeObject, 'Material_Preset', ['ClearCoat Diffuse', 'Transparent Refractive',
		'Copper Metal', 'Aluminum Metal', 'Gold Metal', 'Silver Metal', 'ClearCoat Metal(Brass)']).onChange(materialTypeChanger);

	material_ColorController = gui.addColor(material_ColorObject, 'Material_Color').onChange(materialColorChanger);


	// scene/demo-specific uniforms go here
	pathTracingUniforms.uMaterialType = { value: 4 };
	pathTracingUniforms.uMaterialColor = { value: new THREE.Color(0.0, 1.0, 1.0) };

} // end function initSceneData()



// called automatically from within the animate() function (located in InitCommon.js file)
function updateVariablesAndUniforms() 
{

	if (changeMaterialType) 
	{

		matType = material_TypeController.getValue();

		if (matType == 'ClearCoat Diffuse') 
		{
			pathTracingUniforms.uMaterialType.value = 4;
			pathTracingUniforms.uMaterialColor.value.setRGB(0.0, 1.0, 1.0);
		}
		else if (matType == 'Transparent Refractive') 
		{
			pathTracingUniforms.uMaterialType.value = 2;
			pathTracingUniforms.uMaterialColor.value.setRGB(0.1, 1.0, 0.6);
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
		else if (matType == 'Silver Metal') 
		{
			pathTracingUniforms.uMaterialType.value = 3;
			pathTracingUniforms.uMaterialColor.value.setRGB(0.971519, 0.959915, 0.915324);
		}
		else if (matType == 'ClearCoat Metal(Brass)') 
		{
			pathTracingUniforms.uMaterialType.value = 18;
			pathTracingUniforms.uMaterialColor.value.setRGB(0.956863, 0.894118, 0.678431);
		}
			
		
		material_ColorController.setValue([ pathTracingUniforms.uMaterialColor.value.r,
						    pathTracingUniforms.uMaterialColor.value.g,
						    pathTracingUniforms.uMaterialColor.value.b ]);
		
		cameraIsMoving = true;
		changeMaterialType = false;
	}

	if (changeMaterialColor) 
	{
		matColor = material_ColorController.getValue();
		pathTracingUniforms.uMaterialColor.value.setRGB( matColor[0], matColor[1], matColor[2] );
		
		cameraIsMoving = true;
		changeMaterialColor = false;
	}

	// INFO
	cameraInfoElement.innerHTML = "FOV: " + worldCamera.fov + " / Aperture: " + apertureSize.toFixed(2) + " / FocusDistance: " + focusDistance + "<br>" + "Samples: " + sampleCounter;

} // end function updateUniforms()



init(); // init app and start animating
