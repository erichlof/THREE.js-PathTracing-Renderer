// scene/demo-specific variables go here

let scene_SelectionController, scene_SelectionObject;
let needChangeSceneSelection = false;



function init_GUI()
{
	scene_SelectionObject = { Scene_selection: 'Scene #1' };


	function handleSceneSelectionChange() { needChangeSceneSelection = true; }


	scene_SelectionController = gui.add(scene_SelectionObject, 'Scene_selection', ['Scene #1', 'Scene #2',
		'Scene #3']).onChange(handleSceneSelectionChange);

	
} // end function init_GUI()



// called automatically from within initTHREEjs() function (located in InitCommon.js file)
function initSceneData()
{
	demoFragmentShaderFileName = 'Global_Illumination_Wikipedia1_Fragment.glsl';
	// FOR TESTING
	//demoFragmentShaderFileName = 'Global_Illumination_Wikipedia2_Fragment.glsl';
	// FOR TESTING
	//demoFragmentShaderFileName = 'Global_Illumination_Wikipedia3_Fragment.glsl';

	// scene/demo-specific three.js objects setup goes here
	sceneIsDynamic = false;

	cameraFlightSpeed = 100;

	// pixelRatio is resolution - range: 0.5(half resolution) to 1.0(full resolution)
	pixelRatio = mouseControl ? 1.0 : 0.75; // less demanding on battery-powered mobile devices

	EPS_intersect = 0.01;

	// set camera's field of view
	worldCamera.fov = 50;
	focusDistance = 191.0;
	apertureChangeSpeed = 1;

	// Scene #1 camera settings
	// position and orient camera
	cameraControlsObject.position.set(100, 0, 165);
	// look slightly left or right
	cameraControlsYawObject.rotation.y = 0.45;
	// look slightly up or down
	//cameraControlsPitchObject.rotation.x = 0.0;

	if (!mouseControl) 
		infoElement.innerHTML = "Global Illumination on Wikipedia" + "<br>" + "(Scene 1 of 3)";


	init_GUI();


	// scene/demo-specific uniforms go here
	
	

} // end function initSceneData()





// called automatically from within the animate() function (located in InitCommon.js file)
function updateVariablesAndUniforms()
{

	if (needChangeSceneSelection)
	{
		cameraControlsPitchObject.rotation.set(0,0,0);
		cameraControlsPitchObject.updateMatrixWorld();
		cameraControlsYawObject.rotation.set(0,0,0);
		cameraControlsYawObject.updateMatrixWorld();
		
		if (scene_SelectionController.getValue() == 'Scene #1')
		{
			demoFragmentShaderFileName = 'Global_Illumination_Wikipedia1_Fragment.glsl';
			infoElement.innerHTML = "three.js PathTracing Renderer - Global Illumination on Wikipedia" + "<br>" + "(Scene 1 of 3)";
			if (!mouseControl) 
				infoElement.innerHTML = "Global Illumination on Wikipedia" + "<br>" + "(Scene 1 of 3)";
			worldCamera.fov = 50;
			focusDistance = 191.0;
			apertureSize = 0.0;
			apertureChangeSpeed = 1;
			cameraControlsObject.position.set(100, 0, 165);
			cameraControlsYawObject.rotation.y = 0.45;
			cameraControlsPitchObject.rotation.x = 0.0;
		}
		else if (scene_SelectionController.getValue() == 'Scene #2')
		{
			demoFragmentShaderFileName = 'Global_Illumination_Wikipedia2_Fragment.glsl';
			infoElement.innerHTML = "three.js PathTracing Renderer - Global Illumination on Wikipedia" + "<br>" + "(Scene 2 of 3)";
			if (!mouseControl) 
				infoElement.innerHTML = "Global Illumination on Wikipedia" + "<br>" + "(Scene 2 of 3)";
			worldCamera.fov = 25;
			focusDistance = 56.5;
			apertureSize = 5.0;
			apertureChangeSpeed = 0.5;
			cameraControlsObject.position.set(2, 10, 55);
			cameraControlsYawObject.rotation.y = 0.022;
			cameraControlsPitchObject.rotation.x = -0.1;
		}
		else if (scene_SelectionController.getValue() == 'Scene #3')
		{
			demoFragmentShaderFileName = 'Global_Illumination_Wikipedia3_Fragment.glsl';
			infoElement.innerHTML = "three.js PathTracing Renderer - Global Illumination on Wikipedia" + "<br>" + "(Scene 3 of 3)";
			if (!mouseControl) 
				infoElement.innerHTML = "Global Illumination on Wikipedia" + "<br>" + "(Scene 3 of 3)";
			worldCamera.fov = 50;
			focusDistance = 42.0;
			apertureSize = 0.5;
			apertureChangeSpeed = 0.1;
			cameraControlsObject.position.set(0, 5, 42);
			cameraControlsYawObject.rotation.y = 0.0;
			cameraControlsPitchObject.rotation.x = 0.06;
		}

		pathTracingFragmentShader = null;

		fileLoader.load('shaders/' + demoFragmentShaderFileName, function (fragmentShaderText)
		{
			pathTracingFragmentShader = fragmentShaderText;

			pathTracingMesh.material = new THREE.ShaderMaterial({
				uniforms: pathTracingUniforms,
				uniformsGroups: pathTracingUniformsGroups,
				defines: pathTracingDefines,
				vertexShader: pathTracingVertexShader,
				fragmentShader: pathTracingFragmentShader,
				depthTest: false,
				depthWrite: false
			});
		});

		// update camera uniforms in shader
		fovScale = worldCamera.fov * 0.5 * (Math.PI / 180.0);
		pathTracingUniforms.uVLen.value = Math.tan(fovScale);
		pathTracingUniforms.uULen.value = pathTracingUniforms.uVLen.value * worldCamera.aspect;
		pathTracingUniforms.uFocusDistance.value = focusDistance;

		cameraIsMoving = true;
		needChangeSceneSelection = false;

	} // end if (needChangeSceneSelection)

	
	
	// INFO
	cameraInfoElement.innerHTML = "FOV: " + worldCamera.fov + " / Aperture: " + apertureSize.toFixed(2) + " / FocusDistance: " + focusDistance + "<br>" + "Samples: " + sampleCounter;

} // end function updateVariablesAndUniforms()



init();