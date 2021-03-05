let SCREEN_WIDTH;
let SCREEN_HEIGHT;
let canvas, context;
let container, stats;
let controls;
let pathTracingScene, screenCopyScene, screenOutputScene;
let pathTracingUniforms, screenCopyUniforms, screenOutputUniforms;
let pathTracingDefines;
let pathTracingVertexShader, pathTracingFragmentShader;
let screenCopyVertexShader, screenCopyFragmentShader;
let screenOutputVertexShader, screenOutputFragmentShader;
let pathTracingGeometry, pathTracingMaterial, pathTracingMesh;
let screenCopyGeometry, screenCopyMaterial, screenCopyMesh;
let screenOutputGeometry, screenOutputMaterial, screenOutputMesh;
let pathTracingRenderTarget, screenCopyRenderTarget;
let quadCamera, worldCamera;
let renderer, clock;
let frameTime, elapsedTime;
let fovScale;
let increaseFOV = false;
let decreaseFOV = false;
let dollyCameraIn = false;
let dollyCameraOut = false;
let apertureSize = 0.0;
let increaseAperture = false;
let decreaseAperture = false;
let focusDistance = 132.0;
let increaseFocusDist = false;
let decreaseFocusDist = false;
let pixelRatio = 0.5;
let windowIsBeingResized = false;
let TWO_PI = Math.PI * 2;
let sampleCounter = 1.0;
let frameCounter = 1.0;
//let keyboard = null;
let cameraIsMoving = false;
let cameraRecentlyMoving = false;
let isPaused = true;
let oldYawRotation, oldPitchRotation;
let mobileJoystickControls = null;
let oldDeltaX = 0;
let oldDeltaY = 0;
let newDeltaX = 0;
let newDeltaY = 0;
let mobileControlsMoveX = 0;
let mobileControlsMoveY = 0;
let oldPinchWidthX = 0;
let oldPinchWidthY = 0;
let pinchDeltaX = 0;
let pinchDeltaY = 0;
let fontAspect;
let useGenericInput = true;
let sunAngularDiameterCos;
let EPS_intersect;
let blueNoiseTexture;

const KEYS = {
	a: 65, b: 66, c: 67, d: 68, e: 69, f: 70, g: 71, h: 72, i: 73, j: 74, k: 75, l: 76, m: 77,
	n: 78, o: 79, p: 80, q: 81, r: 82, s: 83, t: 84, u: 85, v: 86, w: 87, x: 88, y: 89, z: 90,
	left: 37, up: 38, right: 39, down: 40, space: 32, pageup: 33, pagedown: 34, tab: 9,
	dash: 189, equals: 187, comma: 188, period: 190, escape: 27, enter: 13, return: 13
}
let KeyboardState = {
	a: false, b: false, c: false, d: false, e: false, f: false, g: false, h: false, i: false, j: false, k: false, l: false, m: false,
	n: false, o: false, p: false, q: false, r: false, s: false, t: false, u: false, v: false, w: false, x: false, y: false, z: false,
	left: false, up: false, right: false, down: false, space: false, pageup: false, pagedown: false, tab: false,
	dash: false, equals: false, comma: false, period: false, escape: false, enter: false, return: false
}

// the following variables will be used to calculate rotations and directions from the camera
let cameraDirectionVector = new THREE.Vector3(); //for moving where the camera is looking
let cameraRightVector = new THREE.Vector3(); //for strafing the camera right and left
let cameraUpVector = new THREE.Vector3(); //for moving camera up and down
let cameraWorldQuaternion = new THREE.Quaternion(); //for rotating scene objects to match camera's current rotation
let cameraControlsObject; //for positioning and moving the camera itself
let cameraControlsYawObject; //allows access to control camera's left/right movements through mobile input
let cameraControlsPitchObject; //allows access to control camera's up/down movements through mobile input

let PI_2 = Math.PI / 2; //used by controls below

let infoElement = document.getElementById('info');
infoElement.style.cursor = "default";
infoElement.style.userSelect = "none";
infoElement.style.MozUserSelect = "none";

let cameraInfoElement = document.getElementById('cameraInfo');
cameraInfoElement.style.cursor = "default";
cameraInfoElement.style.userSelect = "none";
cameraInfoElement.style.MozUserSelect = "none";

let mouseControl = true;
let pointerlockChange;
let fileLoader = new THREE.FileLoader();


function onKeyDown(event)
{
	event.preventDefault();

	for (const key in KEYS)
	{
		if (KEYS[key] == event.keyCode)
		{
			KeyboardState[key] = true;
			return;
		}	
	}
}

function onKeyUp(event)
{
	event.preventDefault();

	for (const key in KEYS)
	{
		if (KEYS[key] == event.keyCode)
		{
			KeyboardState[key] = false;
			return;
		}	
	}
}

function keyPressed(keyName)
{
	if (!mouseControl)
		return;

	return KeyboardState[keyName];
}


function onMouseWheel(event)
{
	if (isPaused)
		return;
		
	// use the following instead, because event.preventDefault() gives errors in console
	event.stopPropagation(); 

	if (event.deltaY > 0)
	{
		increaseFOV = true;
	} 
	else if (event.deltaY < 0)
	{
		decreaseFOV = true;
	}
}


function onWindowResize(event)
{

	windowIsBeingResized = true;

	// the following change to document.body.clientWidth and Height works better for mobile, especially iOS
	// suggestion from Github user q750831855  - Thank you!
	SCREEN_WIDTH = document.body.clientWidth; //window.innerWidth; 
	SCREEN_HEIGHT = document.body.clientHeight; //window.innerHeight;

	renderer.setPixelRatio(pixelRatio);
	renderer.setSize(SCREEN_WIDTH, SCREEN_HEIGHT);

	fontAspect = (SCREEN_WIDTH / 175) * (SCREEN_HEIGHT / 200);
	if (fontAspect > 25) fontAspect = 25;
	if (fontAspect < 4) fontAspect = 4;
	fontAspect *= 2;

	pathTracingUniforms.uResolution.value.x = context.drawingBufferWidth;
	pathTracingUniforms.uResolution.value.y = context.drawingBufferHeight;

	pathTracingRenderTarget.setSize(context.drawingBufferWidth, context.drawingBufferHeight);
	screenCopyRenderTarget.setSize(context.drawingBufferWidth, context.drawingBufferHeight);

	worldCamera.aspect = SCREEN_WIDTH / SCREEN_HEIGHT;
	worldCamera.updateProjectionMatrix();

	// the following scales all scene objects by the worldCamera's field of view,
	// taking into account the screen aspect ratio and multiplying the uniform uULen,
	// the x-coordinate, by this ratio
	fovScale = worldCamera.fov * 0.5 * (Math.PI / 180.0);
	pathTracingUniforms.uVLen.value = Math.tan(fovScale);
	pathTracingUniforms.uULen.value = pathTracingUniforms.uVLen.value * worldCamera.aspect;

	if (!mouseControl)
	{
		button1Element.style.display = "";
		button2Element.style.display = "";
		button3Element.style.display = "";
		button4Element.style.display = "";
		button5Element.style.display = "";
		button6Element.style.display = "";
		// check if mobile device is in portrait or landscape mode and position buttons accordingly
		if (SCREEN_WIDTH < SCREEN_HEIGHT)
		{
			button1Element.style.right = 36 + "%";
			button2Element.style.right = 2 + "%";
			button3Element.style.right = 16 + "%";
			button4Element.style.right = 16 + "%";
			button5Element.style.right = 3 + "%";
			button6Element.style.right = 3 + "%";

			button1Element.style.bottom = 5 + "%";
			button2Element.style.bottom = 5 + "%";
			button3Element.style.bottom = 13 + "%";
			button4Element.style.bottom = 2 + "%";
			button5Element.style.bottom = 25 + "%";
			button6Element.style.bottom = 18 + "%";
		} 
		else
		{
			button1Element.style.right = 22 + "%";
			button2Element.style.right = 3 + "%";
			button3Element.style.right = 11 + "%";
			button4Element.style.right = 11 + "%";
			button5Element.style.right = 3 + "%";
			button6Element.style.right = 3 + "%";

			button1Element.style.bottom = 10 + "%";
			button2Element.style.bottom = 10 + "%";
			button3Element.style.bottom = 26 + "%";
			button4Element.style.bottom = 4 + "%";
			button5Element.style.bottom = 48 + "%";
			button6Element.style.bottom = 34 + "%";
		}
	} // end if ( !mouseControl ) {

} // end function onWindowResize( event )



function init()
{

	window.addEventListener('resize', onWindowResize, false);

	if ('ontouchstart' in window)
	{
		mouseControl = false;

		mobileJoystickControls = new MobileJoystickControls({
			//showJoystick: true
		});
	}

	sunAngularDiameterCos = mouseControl ? 0.9998 : 0.9995; // makes Sun a little bigger on mobile

	// if on mobile device, unpause the app because there is no ESC key and no mouse capture to do
	if (!mouseControl)
		isPaused = false;

	if (mouseControl)
	{

		window.addEventListener('wheel', onMouseWheel, false);

		document.body.addEventListener("click", function () {
			this.requestPointerLock = this.requestPointerLock || this.mozRequestPointerLock;
			this.requestPointerLock();
		}, false);

		window.addEventListener("click", function (event) {
			event.preventDefault();
		}, false);

		window.addEventListener("dblclick", function (event) {
			event.preventDefault();
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
		document.addEventListener('pointerlockchange', pointerlockChange, false);
		document.addEventListener('mozpointerlockchange', pointerlockChange, false);
		document.addEventListener('webkitpointerlockchange', pointerlockChange, false);

	}

	/*
	// Fullscreen API
	document.addEventListener("click", function() {
		
		if ( !document.fullscreenElement && !document.mozFullScreenElement && !document.webkitFullscreenElement ) 
		{
			if (document.documentElement.requestFullscreen) 
			{
				document.documentElement.requestFullscreen();	
			} 
			else if (document.documentElement.mozRequestFullScreen) 
			{
				document.documentElement.mozRequestFullScreen();
			} else if (document.documentElement.webkitRequestFullscreen) 
			{
				document.documentElement.webkitRequestFullscreen();
			}
		}
	});
	*/

	initTHREEjs(); // boilerplate: init necessary three.js items and scene/demo-specific objects

} // end function init()



function initTHREEjs()
{

	canvas = document.createElement('canvas');

	renderer = new THREE.WebGLRenderer({ canvas: canvas, context: canvas.getContext('webgl2') });
	//suggestion: set to false for production
	renderer.debug.checkShaderErrors = true;

	renderer.autoClear = false;

	renderer.toneMapping = THREE.ReinhardToneMapping;

	//required by WebGL 2.0 for rendering to FLOAT textures
	context = renderer.getContext();
	context.getExtension('EXT_color_buffer_float');

	container = document.getElementById('container');
	container.appendChild(renderer.domElement);

	stats = new Stats();
	stats.domElement.style.position = 'absolute';
	stats.domElement.style.top = '0px';
	stats.domElement.style.cursor = "default";
	stats.domElement.style.webkitUserSelect = "none";
	stats.domElement.style.MozUserSelect = "none";
	container.appendChild(stats.domElement);


	clock = new THREE.Clock();

	pathTracingScene = new THREE.Scene();
	screenCopyScene = new THREE.Scene();
	screenOutputScene = new THREE.Scene();

	// quadCamera is simply the camera to help render the full screen quad (2 triangles),
	// hence the name.  It is an Orthographic camera that sits facing the view plane, which serves as
	// the window into our 3d world. This camera will not move or rotate for the duration of the app.
	quadCamera = new THREE.OrthographicCamera(-1, 1, 1, -1, 0, 1);
	screenCopyScene.add(quadCamera);
	screenOutputScene.add(quadCamera);

	// worldCamera is the dynamic camera 3d object that will be positioned, oriented and 
	// constantly updated inside the 3d scene.  Its view will ultimately get passed back to the 
	// stationary quadCamera, which renders the scene to a fullscreen quad (made up of 2 large triangles).
	worldCamera = new THREE.PerspectiveCamera(60, document.body.clientWidth / document.body.clientHeight, 1, 1000);
	pathTracingScene.add(worldCamera);

	controls = new FirstPersonCameraControls(worldCamera);

	cameraControlsObject = controls.getObject();
	cameraControlsYawObject = controls.getYawObject();
	cameraControlsPitchObject = controls.getPitchObject();

	pathTracingScene.add(cameraControlsObject);


	// setup render targets...
	pathTracingRenderTarget = new THREE.WebGLRenderTarget(context.drawingBufferWidth, context.drawingBufferHeight, {
		minFilter: THREE.NearestFilter,
		magFilter: THREE.NearestFilter,
		format: THREE.RGBAFormat,
		type: THREE.FloatType,
		depthBuffer: false,
		stencilBuffer: false
	});
	pathTracingRenderTarget.texture.generateMipmaps = false;

	screenCopyRenderTarget = new THREE.WebGLRenderTarget(context.drawingBufferWidth, context.drawingBufferHeight, {
		minFilter: THREE.NearestFilter,
		magFilter: THREE.NearestFilter,
		format: THREE.RGBAFormat,
		type: THREE.FloatType,
		depthBuffer: false,
		stencilBuffer: false
	});
	screenCopyRenderTarget.texture.generateMipmaps = false;

	// blueNoise texture used in all demos
	blueNoiseTexture = new THREE.TextureLoader().load('textures/BlueNoise_RGBA256.png');
	blueNoiseTexture.wrapS = THREE.RepeatWrapping;
	blueNoiseTexture.wrapT = THREE.RepeatWrapping;
	blueNoiseTexture.flipY = false;
	blueNoiseTexture.minFilter = THREE.NearestFilter;
	blueNoiseTexture.magFilter = THREE.NearestFilter;
	blueNoiseTexture.generateMipmaps = false;


	// setup scene/demo-specific objects, variables, and data
	initSceneData();


	// setup screen-size quad geometry and shaders....

	// this full-screen quad mesh performs the path tracing operations and produces a screen-sized image
	pathTracingGeometry = new THREE.PlaneBufferGeometry(2, 2);
	pathTracingUniforms = {

		tPreviousTexture: { type: "t", value: screenCopyRenderTarget.texture },
		tBlueNoiseTexture: { type: "t", value: blueNoiseTexture },

		uCameraIsMoving: { type: "b1", value: false },
		uSceneIsDynamic: { type: "b1", value: sceneIsDynamic },

		uEPS_intersect: { type: "f", value: EPS_intersect },
		uTime: { type: "f", value: 0.0 },
		uSampleCounter: { type: "f", value: 0.0 },
		uFrameCounter: { type: "f", value: 1.0 },
		uULen: { type: "f", value: 1.0 },
		uVLen: { type: "f", value: 1.0 },
		uApertureSize: { type: "f", value: apertureSize },
		uFocusDistance: { type: "f", value: focusDistance },
		uSunAngularDiameterCos: { type: "f", value: sunAngularDiameterCos },

		uResolution: { type: "v2", value: new THREE.Vector2() },
		uRandomVec2: { type: "v2", value: new THREE.Vector2() },

		uCameraMatrix: { type: "m4", value: new THREE.Matrix4() }
	};

	initPathTracingShaders();


	// this full-screen quad mesh copies the image output of the pathtracing shader and feeds it back in to that shader as a 'previousTexture'
	screenCopyGeometry = new THREE.PlaneBufferGeometry(2, 2);

	screenCopyUniforms = {
		tPathTracedImageTexture: { type: "t", value: null }
	};

	fileLoader.load('shaders/ScreenCopy_Fragment.glsl', function (shaderText) {
		
		screenCopyFragmentShader = shaderText;

		screenCopyMaterial = new THREE.ShaderMaterial({
			uniforms: screenCopyUniforms,
			vertexShader: pathTracingVertexShader,
			fragmentShader: screenCopyFragmentShader,
			depthWrite: false,
			depthTest: false
		});

		screenCopyMaterial.uniforms.tPathTracedImageTexture.value = pathTracingRenderTarget.texture;

		screenCopyMesh = new THREE.Mesh(screenCopyGeometry, screenCopyMaterial);
		screenCopyScene.add(screenCopyMesh);
	});


	// this full-screen quad mesh takes the image output of the path tracing shader (which is a continuous blend of the previous frame and current frame),
	// and applies gamma correction (which brightens the entire image), and then displays the final accumulated rendering to the screen
	screenOutputGeometry = new THREE.PlaneBufferGeometry(2, 2);

	screenOutputUniforms = {
		uOneOverSampleCounter: { type: "f", value: 0.0 },
		tPathTracedImageTexture: { type: "t", value: null }
	};

	fileLoader.load('shaders/ScreenOutput_Fragment.glsl', function (shaderText) {

		screenOutputFragmentShader = shaderText;

		screenOutputMaterial = new THREE.ShaderMaterial({
			uniforms: screenOutputUniforms,
			vertexShader: pathTracingVertexShader,
			fragmentShader: screenOutputFragmentShader,
			depthWrite: false,
			depthTest: false
		});

		screenOutputMaterial.uniforms.tPathTracedImageTexture.value = pathTracingRenderTarget.texture;

		screenOutputMesh = new THREE.Mesh(screenOutputGeometry, screenOutputMaterial);
		screenOutputScene.add(screenOutputMesh);
	});


	// this 'jumpstarts' the initial dimensions and parameters for the window and renderer
	onWindowResize();

	// everything is set up, now we can start animating
	animate();

} // end function initTHREEjs()




function animate()
{

	frameTime = clock.getDelta();

	elapsedTime = clock.getElapsedTime() % 1000;

	// reset flags
	cameraIsMoving = false;

	if (windowIsBeingResized)
	{
		cameraIsMoving = true;
		windowIsBeingResized = false;
	}

	// check user controls
	if (mouseControl)
	{
		// movement detected
		if (oldYawRotation != cameraControlsYawObject.rotation.y ||
			oldPitchRotation != cameraControlsPitchObject.rotation.x)
		{
			cameraIsMoving = true;
		}

		// save state for next frame
		oldYawRotation = cameraControlsYawObject.rotation.y;
		oldPitchRotation = cameraControlsPitchObject.rotation.x;

	} // end if (mouseControl)

	// if on mobile device, get input from the mobileJoystickControls
	if (!mouseControl)
	{

		newDeltaX = joystickDeltaX;

		if (newDeltaX)
		{
			cameraIsMoving = true;
			mobileControlsMoveX = oldDeltaX - newDeltaX;
			// mobileJoystick X movement (left and right) affects camera rotation around the Y axis	
			cameraControlsYawObject.rotation.y += (mobileControlsMoveX) * 0.01;
		}

		newDeltaY = joystickDeltaY;

		if (newDeltaY)
		{
			cameraIsMoving = true;
			mobileControlsMoveY = oldDeltaY - newDeltaY;
			// mobileJoystick Y movement (up and down) affects camera rotation around the X axis	
			cameraControlsPitchObject.rotation.x += (mobileControlsMoveY) * 0.01;
		}

		// clamp the camera's vertical movement (around the x-axis) to the scene's 'ceiling' and 'floor',
		// so you can't accidentally flip the camera upside down
		cameraControlsPitchObject.rotation.x = Math.max(-PI_2, Math.min(PI_2, cameraControlsPitchObject.rotation.x));

		// save state for next frame
		oldDeltaX = newDeltaX;
		oldDeltaY = newDeltaY;

		newPinchWidthX = pinchWidthX;
		newPinchWidthY = pinchWidthY;
		pinchDeltaX = newPinchWidthX - oldPinchWidthX;
		pinchDeltaY = newPinchWidthY - oldPinchWidthY;

		if (Math.abs(pinchDeltaX) > Math.abs(pinchDeltaY))
		{
			if (pinchDeltaX < -1)
			{
				increaseFOV = true;
				dollyCameraOut = true;
			}
			if (pinchDeltaX > 1)
			{
				decreaseFOV = true;
				dollyCameraIn = true;
			}
		}

		if (Math.abs(pinchDeltaY) >= Math.abs(pinchDeltaX))
		{
			if (pinchDeltaY > 1)
			{
				increaseAperture = true;
			}
			if (pinchDeltaY < -1)
			{
				decreaseAperture = true;
			}
		}

		// save state for next frame
		oldPinchWidthX = newPinchWidthX;
		oldPinchWidthY = newPinchWidthY;

	} // end if ( !mouseControl )

	// this gives us a vector in the direction that the camera is pointing,
	// which will be useful for moving the camera 'forward' and shooting projectiles in that direction
	controls.getDirection(cameraDirectionVector);
	cameraDirectionVector.normalize();
	controls.getUpVector(cameraUpVector);
	cameraUpVector.normalize();
	controls.getRightVector(cameraRightVector);
	cameraRightVector.normalize();

	// the following gives us a rotation quaternion (4D vector), which will be useful for 
	// rotating scene objects to match the camera's rotation
	worldCamera.getWorldQuaternion(cameraWorldQuaternion);

	if (useGenericInput)
	{
		
		if (!isPaused)
		{
			if ( (keyPressed('w') || button3Pressed) && !(keyPressed('s') || button4Pressed) )
			{
				cameraControlsObject.position.add(cameraDirectionVector.multiplyScalar(camFlightSpeed * frameTime));
				cameraIsMoving = true;
			}
			if ( (keyPressed('s') || button4Pressed) && !(keyPressed('w') || button3Pressed) )
			{
				cameraControlsObject.position.sub(cameraDirectionVector.multiplyScalar(camFlightSpeed * frameTime));
				cameraIsMoving = true;
			}
			if ( (keyPressed('a') || button1Pressed) && !(keyPressed('d') || button2Pressed) )
			{
				cameraControlsObject.position.sub(cameraRightVector.multiplyScalar(camFlightSpeed * frameTime));
				cameraIsMoving = true;
			}
			if ( (keyPressed('d') || button2Pressed) && !(keyPressed('a') || button1Pressed) )
			{
				cameraControlsObject.position.add(cameraRightVector.multiplyScalar(camFlightSpeed * frameTime));
				cameraIsMoving = true;
			}
			if (keyPressed('q') && !keyPressed('z'))
			{
				cameraControlsObject.position.add(cameraUpVector.multiplyScalar(camFlightSpeed * frameTime));
				cameraIsMoving = true;
			}
			if (keyPressed('z') && !keyPressed('q'))
			{
				cameraControlsObject.position.sub(cameraUpVector.multiplyScalar(camFlightSpeed * frameTime));
				cameraIsMoving = true;
			}
			if ( (keyPressed('up') || button5Pressed) && !(keyPressed('down') || button6Pressed) )
			{
				increaseFocusDist = true;
			}
			if ( (keyPressed('down') || button6Pressed) && !(keyPressed('up') || button5Pressed) )
			{
				decreaseFocusDist = true;
			}
			if (keyPressed('right') && !keyPressed('left'))
			{
				increaseAperture = true;
			}
			if (keyPressed('left') && !keyPressed('right'))
			{
				decreaseAperture = true;
			}
		} // end if (!isPaused)

		
		
		if (increaseFOV)
		{
			worldCamera.fov++;
			if (worldCamera.fov > 150)
				worldCamera.fov = 150;
			fovScale = worldCamera.fov * 0.5 * (Math.PI / 180.0);
			pathTracingUniforms.uVLen.value = Math.tan(fovScale);
			pathTracingUniforms.uULen.value = pathTracingUniforms.uVLen.value * worldCamera.aspect;

			cameraIsMoving = true;
			increaseFOV = false;
		}
		if (decreaseFOV)
		{
			worldCamera.fov--;
			if (worldCamera.fov < 1)
				worldCamera.fov = 1;
			fovScale = worldCamera.fov * 0.5 * (Math.PI / 180.0);
			pathTracingUniforms.uVLen.value = Math.tan(fovScale);
			pathTracingUniforms.uULen.value = pathTracingUniforms.uVLen.value * worldCamera.aspect;

			cameraIsMoving = true;
			decreaseFOV = false;
		}

		if (increaseFocusDist)
		{
			focusDistance += 1;
			pathTracingUniforms.uFocusDistance.value = focusDistance;
			cameraIsMoving = true;
			increaseFocusDist = false;
		}
		if (decreaseFocusDist)
		{
			focusDistance -= 1;
			if (focusDistance < 1)
				focusDistance = 1;
			pathTracingUniforms.uFocusDistance.value = focusDistance;
			cameraIsMoving = true;
			decreaseFocusDist = false;
		}

		if (increaseAperture)
		{
			apertureSize += 0.1;
			if (apertureSize > 100.0)
				apertureSize = 100.0;
			pathTracingUniforms.uApertureSize.value = apertureSize;
			cameraIsMoving = true;
			increaseAperture = false;
		}
		if (decreaseAperture)
		{
			apertureSize -= 0.1;
			if (apertureSize < 0.0)
				apertureSize = 0.0;
			pathTracingUniforms.uApertureSize.value = apertureSize;
			cameraIsMoving = true;
			decreaseAperture = false;
		}

	} // end if (useGenericInput)


	// update scene/demo-specific input(if custom), variables and uniforms every animation frame
	updateVariablesAndUniforms();

	// now update uniforms that are common to all scenes
	if (!cameraIsMoving)
	{
		if (sceneIsDynamic)
			sampleCounter = 1.0; // reset for continuous updating of image
		else sampleCounter += 1.0; // for progressive refinement of image

		frameCounter += 1.0;

		cameraRecentlyMoving = false;
	}

	if (cameraIsMoving)
	{
		sampleCounter = 1.0;
		frameCounter += 1.0;

		if (!cameraRecentlyMoving)
		{
			frameCounter = 1.0;
			cameraRecentlyMoving = true;
		}
	}

	pathTracingUniforms.uTime.value = elapsedTime;
	pathTracingUniforms.uCameraIsMoving.value = cameraIsMoving;
	pathTracingUniforms.uSampleCounter.value = sampleCounter;
	pathTracingUniforms.uFrameCounter.value = frameCounter;
	pathTracingUniforms.uRandomVec2.value.set(Math.random(), Math.random());

	// CAMERA
	cameraControlsObject.updateMatrixWorld(true);
	worldCamera.updateMatrixWorld(true);
	pathTracingUniforms.uCameraMatrix.value.copy(worldCamera.matrixWorld);

	// PROGRESSIVE SAMPLE WEIGHT (reduces intensity of each successive animation frame's image)
	screenOutputUniforms.uOneOverSampleCounter.value = 1.0 / sampleCounter;


	// RENDERING in 3 steps

	// STEP 1
	// Perform PathTracing and Render(save) into pathTracingRenderTarget, a full-screen texture.
	// Read previous screenCopyRenderTarget(via texelFetch inside fragment shader) to use as a new starting point to blend with
	renderer.setRenderTarget(pathTracingRenderTarget);
	renderer.render(pathTracingScene, worldCamera);

	// STEP 2
	// Render(copy) the pathTracingScene output(pathTracingRenderTarget above) into screenCopyRenderTarget.
	// This will be used as a new starting point for Step 1 above (essentially creating ping-pong buffers)
	renderer.setRenderTarget(screenCopyRenderTarget);
	renderer.render(screenCopyScene, quadCamera);

	// STEP 3
	// Render full screen quad with generated pathTracingRenderTarget in STEP 1 above.
	// After applying tonemapping and gamma-correction to the image, it will be shown on the screen as the final accumulated output
	renderer.setRenderTarget(null);
	renderer.render(screenOutputScene, quadCamera);

	stats.update();

	requestAnimationFrame(animate);

} // end function animate()