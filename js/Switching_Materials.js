// scene/demo-specific variables go here
let material_TypeObject, material_ColorObject;
let material_LTypeController, material_LColorController;
let material_RTypeController, material_RColorController;
let matType = 0;
let matColor;
let changeLeftSphereMaterialType = false;
let changeRightSphereMaterialType = false;
let changeLeftSphereMaterialColor = false;
let changeRightSphereMaterialColor = false;



// called automatically from within initTHREEjs() function (located in InitCommon.js file)
function initSceneData() 
{
	demoFragmentShaderFileName = 'Switching_Materials_Fragment.glsl';

	// scene/demo-specific three.js objects setup goes here
	sceneIsDynamic = false;
	
	cameraFlightSpeed = 300;

	// pixelRatio is resolution - range: 0.5(half resolution) to 1.0(full resolution)
	pixelRatio = mouseControl ? 1.0 : 0.75; // less demanding on battery-powered mobile devices

	EPS_intersect = 0.01;

	// set camera's field of view
	worldCamera.fov = 50;
	focusDistance = 530.0;
	apertureChangeSpeed = 200;

	// position and orient camera
	cameraControlsObject.position.set(278, 170, 320);
	///cameraControlsYawObject.rotation.y = 0.0;
	// look slightly upward
	cameraControlsPitchObject.rotation.x = 0.005;


	// In addition to the default GUI on all demos, add any special GUI elements that this particular demo requires

	material_TypeObject = {
		LSphereMaterial: 4,
		RSphereMaterial: 2
	};
	material_ColorObject = {
		LSphereColor: [1, 1, 1],
		RSphereColor: [1, 1, 1]
	};

	function leftMatTypeChanger() 
	{
		changeLeftSphereMaterialType = true;
	}
	function rightMatTypeChanger() 
	{
		changeRightSphereMaterialType = true;
	}
	function leftMatColorChanger() 
	{
		changeLeftSphereMaterialColor = true;
	}
	function rightMatColorChanger() 
	{
		changeRightSphereMaterialColor = true;
	}

	material_LTypeController = gui.add(material_TypeObject, 'LSphereMaterial', 1, 7, 1).onChange(leftMatTypeChanger);
	material_RTypeController = gui.add(material_TypeObject, 'RSphereMaterial', 1, 7, 1).onChange(rightMatTypeChanger);
	material_LColorController = gui.addColor(material_ColorObject, 'LSphereColor').onChange(leftMatColorChanger);
	material_RColorController = gui.addColor(material_ColorObject, 'RSphereColor').onChange(rightMatColorChanger);

	leftMatTypeChanger();
	rightMatTypeChanger();
	leftMatColorChanger();
	rightMatColorChanger();


	// scene/demo-specific uniforms go here
	pathTracingUniforms.uLeftSphereMaterialType = { value: 0.0 };
	pathTracingUniforms.uRightSphereMaterialType = { value: 0.0 };
	pathTracingUniforms.uLeftSphereColor = { value: new THREE.Color() };
	pathTracingUniforms.uRightSphereColor = { value: new THREE.Color() };

} // end function initSceneData()



// called automatically from within the animate() function (located in InitCommon.js file)
function updateVariablesAndUniforms() 
{
	
	if (changeLeftSphereMaterialType) 
	{
					
		matType = Math.floor(material_LTypeController.getValue());
		pathTracingUniforms.uLeftSphereMaterialType.value = matType;

		//if (matType == 0) { // LIGHT
		//        pathTracingUniforms.uLeftSphereColor.value.setRGB(0.0, 0.0, 0.0);
		//        pathTracingUniforms.uLeftSphereEmissive.value.setRGB(1.0, 0.0, 1.0);
		//}
		if (matType == 1) 
		{ // DIFF
			pathTracingUniforms.uLeftSphereColor.value.setRGB(1.0, 1.0, 1.0);   
		}
		else if (matType == 2) 
		{ // REFR
			pathTracingUniforms.uLeftSphereColor.value.setRGB(0.6, 1.0, 0.9); 
		}
		else if (matType == 3) 
		{ // SPEC
			pathTracingUniforms.uLeftSphereColor.value.setRGB(1.000000, 0.765557, 0.336057); // Gold
			// other metals
			// Aluminum: (0.913183, 0.921494, 0.924524) / Copper: (0.955008, 0.637427, 0.538163) / Silver: (0.971519, 0.959915, 0.915324)   
		}
		else if (matType == 4) 
		{ // COAT
			pathTracingUniforms.uLeftSphereColor.value.setRGB(1.0, 1.0, 1.0);   
		}
		else if (matType == 5) 
		{ // CARCOAT
			pathTracingUniforms.uLeftSphereColor.value.setRGB(1.0, 0.001, 0.001);   
		}
		else if (matType == 6) 
		{ // TRANSLUCENT
			pathTracingUniforms.uLeftSphereColor.value.setRGB(0.5, 0.9, 1.0);
		}
		else if (matType == 7) 
		{ // SPECSUB
			pathTracingUniforms.uLeftSphereColor.value.setRGB(0.99, 0.99, 0.9);  
		}

		
		material_LColorController.setValue([ pathTracingUniforms.uLeftSphereColor.value.r,
						     pathTracingUniforms.uLeftSphereColor.value.g,
						     pathTracingUniforms.uLeftSphereColor.value.b ]);
		
		cameraIsMoving = true;
		changeLeftSphereMaterialType = false;
	}

	if (changeRightSphereMaterialType) 
	{

		matType = Math.floor(material_RTypeController.getValue());
		pathTracingUniforms.uRightSphereMaterialType.value = matType;

		//if (matType == 0) { // LIGHT
		//        pathTracingUniforms.uRightSphereColor.value.setRGB(0.0, 0.0, 0.0);
		//        pathTracingUniforms.uRightSphereEmissive.value.setRGB(1.0, 0.0, 1.0);    
		//}
		if (matType == 1) 
		{ // DIFF
			pathTracingUniforms.uRightSphereColor.value.setRGB(1.0, 1.0, 1.0);   
		}
		else if (matType == 2) 
		{ // REFR
			pathTracingUniforms.uRightSphereColor.value.setRGB(1.0, 1.0, 1.0);
		}
		else if (matType == 3) 
		{ // SPEC
			pathTracingUniforms.uRightSphereColor.value.setRGB(0.913183, 0.921494, 0.924524); // Aluminum
			// other metals
			// Gold: (1.000000, 0.765557, 0.336057) / Copper: (0.955008, 0.637427, 0.538163) / Silver: (0.971519, 0.959915, 0.915324)   
		}
		else if (matType == 4) 
		{ // COAT
			pathTracingUniforms.uRightSphereColor.value.setRGB(1.0, 1.0, 0.0);   
		}
		else if (matType == 5) 
		{ // CARCOAT
			pathTracingUniforms.uRightSphereColor.value.setRGB(0.2, 0.3, 0.6);
		}
		else if (matType == 6) 
		{ // TRANSLUCENT
			pathTracingUniforms.uRightSphereColor.value.setRGB(1.0, 0.82, 0.8);
		}
		else if (matType == 7) 
		{ // SPECSUB
			pathTracingUniforms.uRightSphereColor.value.setRGB(0.0, 0.99, 0.4); 
		}

		
		material_RColorController.setValue([ pathTracingUniforms.uRightSphereColor.value.r,
						     pathTracingUniforms.uRightSphereColor.value.g,
						     pathTracingUniforms.uRightSphereColor.value.b ]);
		
		cameraIsMoving = true;
		changeRightSphereMaterialType = false;
	}

	if (changeLeftSphereMaterialColor) 
	{
		matColor = material_LColorController.getValue();

		pathTracingUniforms.uLeftSphereColor.value.setRGB(matColor[0], matColor[1], matColor[2]);
		
		cameraIsMoving = true;
		changeLeftSphereMaterialColor = false;
	}
	
	if (changeRightSphereMaterialColor) 
	{
		matColor = material_RColorController.getValue();
		
		pathTracingUniforms.uRightSphereColor.value.setRGB(matColor[0], matColor[1], matColor[2]);
		
		cameraIsMoving = true;
		changeRightSphereMaterialColor = false;
	}

	// INFO
	cameraInfoElement.innerHTML = "FOV: " + worldCamera.fov + " / Aperture: " + apertureSize.toFixed(2) + " / FocusDistance: " + focusDistance + "<br>" + "Samples: " + sampleCounter;
				
} // end function updateVariablesAndUniforms()



init(); // init app and start animating
