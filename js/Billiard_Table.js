// scene/demo-specific variables go here
let clothTexture, darkWoodTexture, lightWoodTexture;
let imageTexturesTotalCount = 3;
let numOfImageTexturesLoaded = 0;
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
	pixelRatio = mouseControl ? 1.0 : 0.6; // less demanding on battery-powered mobile devices

	EPS_intersect = 0.01;

	// set camera's field of view
	worldCamera.fov = 55;
	focusDistance = 145.0;
	apertureChangeSpeed = 10;

	// position and orient camera
	cameraControlsObject.position.set(100,50,140);
	// look left
	cameraControlsYawObject.rotation.y = 0.6;
	// look slightly downward
	cameraControlsPitchObject.rotation.x = -0.2;
	
	

	// scene/demo-specific uniforms go here   
	pathTracingUniforms.tClothTexture = { value: clothTexture };
	pathTracingUniforms.tDarkWoodTexture = { value: darkWoodTexture };
	pathTracingUniforms.tLightWoodTexture = { value: lightWoodTexture };

} // end function initSceneData()



// called automatically from within the animate() function (located in InitCommon.js file)
function updateVariablesAndUniforms() 
{
	// INFO
	cameraInfoElement.innerHTML = "FOV: " + worldCamera.fov + " / Aperture: " + apertureSize.toFixed(2) + " / FocusDistance: " + focusDistance + "<br>" + "Samples: " + sampleCounter;
				
} // end function updateUniforms()



clothTexture = textureLoader.load(
	// resource URL
	'textures/cloth.jpg',

	// onLoad callback
	function (texture)
	{
		texture.wrapS = THREE.RepeatWrapping;
		texture.wrapT = THREE.RepeatWrapping;
		texture.flipY = false;
		texture.minFilter = THREE.NearestFilter;
		texture.magFilter = THREE.NearestFilter;
		texture.generateMipmaps = false;

		numOfImageTexturesLoaded++;
		// if all textures have been loaded, we can init 
		if (numOfImageTexturesLoaded == imageTexturesTotalCount)
			init();
	}
);

darkWoodTexture = textureLoader.load(
	// resource URL
	'textures/darkWood.jpg',

	// onLoad callback
	function (texture)
	{
		texture.wrapS = THREE.RepeatWrapping;
		texture.wrapT = THREE.RepeatWrapping;
		texture.flipY = false;
		texture.minFilter = THREE.NearestFilter;
		texture.magFilter = THREE.NearestFilter;
		texture.generateMipmaps = false;

		numOfImageTexturesLoaded++;
		// if all textures have been loaded, we can init 
		if (numOfImageTexturesLoaded == imageTexturesTotalCount)
			init();
	}
);

lightWoodTexture = textureLoader.load(
	// resource URL
	'textures/lightWood.jpg',

	// onLoad callback
	function (texture)
	{
		texture.wrapS = THREE.RepeatWrapping;
		texture.wrapT = THREE.RepeatWrapping;
		texture.flipY = false;
		texture.minFilter = THREE.NearestFilter;
		texture.magFilter = THREE.NearestFilter;
		texture.generateMipmaps = false;

		numOfImageTexturesLoaded++;
		// if all textures have been loaded, we can init 
		if (numOfImageTexturesLoaded == imageTexturesTotalCount)
			init();
	}
);
