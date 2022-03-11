// scene/demo-specific variables go here
let clothTexture, darkWoodTexture, lightWoodTexture;
let increaseDoorAngle = false;
let decreaseDoorAngle = false;


// called automatically from within initTHREEjs() function (located in InitCommon.js file)
function initSceneData() 
{
	demoFragmentShaderFileName = 'Billiard_Table_Fragment.glsl';

	// scene/demo-specific three.js objects setup goes here
	sceneIsDynamic = false;

	edgeSharpenSpeed = 0.1;
	filterDecaySpeed = 0.005;

	cameraFlightSpeed = 100;

	// pixelRatio is resolution - range: 0.5(half resolution) to 1.0(full resolution)
	pixelRatio = mouseControl ? 0.75 : 0.6; // less demanding on battery-powered mobile devices

	EPS_intersect = 0.01;

	// set camera's field of view
	worldCamera.fov = 55;
	focusDistance = 145.0;

	// position and orient camera
	cameraControlsObject.position.set(100,50,140);
	// look left
	cameraControlsYawObject.rotation.y = 0.6;
	// look slightly downward
	cameraControlsPitchObject.rotation.x = -0.2;
	
	
	clothTexture = new THREE.TextureLoader().load( 'textures/cloth.jpg' );
	clothTexture.wrapS = THREE.RepeatWrapping;
	clothTexture.wrapT = THREE.RepeatWrapping;
	clothTexture.flipY = false;
	clothTexture.minFilter = THREE.LinearFilter; 
	clothTexture.magFilter = THREE.LinearFilter;
	clothTexture.generateMipmaps = false;
	
	darkWoodTexture = new THREE.TextureLoader().load( 'textures/darkWood.jpg' );
	darkWoodTexture.wrapS = THREE.RepeatWrapping;
	darkWoodTexture.wrapT = THREE.RepeatWrapping;
	darkWoodTexture.flipY = false;
	darkWoodTexture.minFilter = THREE.LinearFilter; 
	darkWoodTexture.magFilter = THREE.LinearFilter;
	darkWoodTexture.generateMipmaps = false;
	
	lightWoodTexture = new THREE.TextureLoader().load( 'textures/lightWood.jpg' );
	lightWoodTexture.wrapS = THREE.RepeatWrapping;
	lightWoodTexture.wrapT = THREE.RepeatWrapping;
	lightWoodTexture.flipY = false;
	lightWoodTexture.minFilter = THREE.LinearFilter; 
	lightWoodTexture.magFilter = THREE.LinearFilter;
	lightWoodTexture.generateMipmaps = false;


	// scene/demo-specific uniforms go here   
	pathTracingUniforms.tClothTexture = { type: "t", value: clothTexture };
	pathTracingUniforms.tDarkWoodTexture = { type: "t", value: darkWoodTexture };
	pathTracingUniforms.tLightWoodTexture = { type: "t", value: lightWoodTexture };

} // end function initSceneData()



// called automatically from within the animate() function (located in InitCommon.js file)
function updateVariablesAndUniforms() 
{
	// INFO
	cameraInfoElement.innerHTML = "FOV: " + worldCamera.fov + " / Aperture: " + apertureSize.toFixed(2) + " / FocusDistance: " + focusDistance + "<br>" + "Samples: " + sampleCounter;
				
} // end function updateUniforms()



init(); // init app and start animating
