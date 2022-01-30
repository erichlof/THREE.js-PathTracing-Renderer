// scene/demo-specific variables go here
var sceneIsDynamic = false;
var camFlightSpeed = 60;

var gui;
var ableToEngagePointerLock = true;
var material_TypeObject, material_ColorObject;
var material_TypeController, material_ColorController;
var changeMaterialType = false;
var changeMaterialColor = false;
var matType = 0;
var matColor;


function init_GUI() 
{

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

	// since I use the lil-gui.min.js minified version of lil-gui without modern exports, 
	//'g()' is 'GUI()' ('g' is the shortened version of 'GUI' inside the lil-gui.min.js file)
	gui = new g(); // same as gui = new GUI();
	
	material_TypeController = gui.add( material_TypeObject, 'Material_Preset', [ 'ClearCoat Diffuse', 'Transparent Refractive', 
		'Copper Metal', 'Aluminum Metal', 'Gold Metal', 'Silver Metal', 'ClearCoat Metal(Brass)' ] ).onChange( materialTypeChanger );
	
	material_ColorController = gui.addColor( material_ColorObject, 'Material_Color' ).onChange( materialColorChanger );
	
	materialTypeChanger();
	materialColorChanger();

	gui.domElement.style.userSelect = "none";
	gui.domElement.style.MozUserSelect = "none";
	
	window.addEventListener('resize', onWindowResize, false);

	if ( 'ontouchstart' in window ) 
	{
		mouseControl = false;
		// if on mobile device, unpause the app because there is no ESC key and no mouse capture to do
		isPaused = false;
		
		ableToEngagePointerLock = true;

		mobileJoystickControls = new MobileJoystickControls ({
			//showJoystick: true
		});	
	}

	if (mouseControl) 
	{

		window.addEventListener( 'wheel', onMouseWheel, false );

		// window.addEventListener("click", function(event) 
		// {
		// 	event.preventDefault();	
		// }, false);
		window.addEventListener("dblclick", function(event) 
		{
			event.preventDefault();	
		}, false);
		
		document.body.addEventListener("click", function(event) 
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
		document.addEventListener( 'pointerlockchange', pointerlockChange, false );
		document.addEventListener( 'mozpointerlockchange', pointerlockChange, false );
		document.addEventListener( 'webkitpointerlockchange', pointerlockChange, false );

	}

	if (mouseControl) 
	{
		gui.domElement.addEventListener("mouseenter", function(event) 
		{
			ableToEngagePointerLock = false;	
		}, false);
		gui.domElement.addEventListener("mouseleave", function(event) 
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

	// pixelRatio is resolution - range: 0.5(half resolution) to 1.0(full resolution)
	pixelRatio = mouseControl ? 0.75 : 0.75; // less demanding on battery-powered mobile devices

	EPS_intersect = 0.01;

	// set camera's field of view
	worldCamera.fov = 60;
	focusDistance = 130.0;

	// position and orient camera
	cameraControlsObject.position.set(0, 20, 120);
	///cameraControlsYawObject.rotation.y = 0.0;
	// look slightly downward
	///cameraControlsPitchObject.rotation.x = -0.4;

} // end function initSceneData()



// called automatically from within initTHREEjs() function
function initPathTracingShaders() 
{
 
	// scene/demo-specific uniforms go here
	pathTracingUniforms.uMaterialType = { type: "i", value: 4 };
	pathTracingUniforms.uMaterialColor = { type: "v3", value: new THREE.Color(0.0, 1.0, 1.0) };
	

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

	fileLoader.load('shaders/Material_Roughness_Fragment.glsl', function (shaderText) 
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

	if (changeMaterialType) {

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



init_GUI(); // init app and start animating
