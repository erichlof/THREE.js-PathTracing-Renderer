// Three.js related variables
let container, canvas, stats, controls, renderer, clock;
let frameTime;
// PathTracing scene variables
let pathTracingScene, screenTextureScene, screenOutputScene;
let pathTracingUniforms, screenTextureUniforms, screenOutputUniforms, pathTracingDefines, screenOutputMaterial, pathTracingRenderTarget;
let blueNoiseTexture;
// Camera variables
let quadCamera, worldCamera;
let cameraDirectionVector = new THREE.Vector3(), cameraRightVector = new THREE.Vector3(), cameraUpVector = new THREE.Vector3();
// HDR image variables
var hdrPath, hdrTexture, hdrLoader, hdrExposure = 1.0;
// Environment variables
var skyLightIntensity = 2.0, sunLightIntensity = 2.0, sunColor = [255, 250, 235];
var skyLightIntensityChanged = false, sunLightIntensityChanged = false, sunColorChanged = false;
var cameraControlsObject; //for positioning and moving the camera itself
var cameraControlsYawObject; //allows access to control camera's left/right movements through mobile input
var cameraControlsPitchObject; //allows access to control camera's up/down movements through mobile input
// Camera setting variables
var apertureSize = 0.0, focusDistance = 100.0, speed = 60, camFlightSpeed;
var fovScale;
// Rendering variables
var pixelRatio = 0.5; // 1 is full resolution, 0.5 is half, 0.25 is quarter, etc. (must be > than 0.0)
var sunAngle = Math.PI / 2.5;
var sampleCounter = 1.0, frameCounter = 1.0;
var forceUpdate = false, cameraIsMoving = false, cameraRecentlyMoving = false;
var sceneIsDynamic = false;
// Input variables
var isPaused = true;
var oldYawRotation = 0, oldPitchRotation = 0, oldDeltaX = 0, oldDeltaY = 0, newDeltaX = 0, newDeltaY = 0;
var mouseControl = true;
var mobileJoystickControls = null;
// Mobile Input variables
var newPinchWidthX;
var newPinchWidthY;
var mobileControlsMoveX = 0, mobileControlsMoveY = 0, oldPinchWidthX = 0, oldPinchWidthY = 0, pinchDeltaX = 0, pinchDeltaY = 0;
var stillFlagX = true, stillFlagY = true;
var fontAspect;
// Geometry variables
let triangleMaterialMarkers = [];
let pathTracingMaterialList = [];
let uniqueMaterialTextures = [];
var aabb_array;
// Menu variables
var gui;
var ableToEngagePointerLock = true;
var lightingSettingsFolder;
var cameraSettingsFolder;
const minFov = 1, maxFov = 150;
const minFocusDistance = 1;
const minApertureSize = 0, maxApertureSize = 20;
var fovChanged = false, focusDistanceChanged = false, apertureSizeChanged = false;
// Constants
const PI_2 = Math.PI / 2; // used in animation method
const samplesSpanEl = document.querySelector("#samples span");
const loadingSpinner = document.querySelector("#loadingSpinner");

/////////////////
// Model setup //
/////////////////
let modelPaths = [
    "models/00_001_011.gltf",
    "models/00_002_003.gltf",
    "models/00_003_000.gltf",
    "models/00_004_003.gltf",
    "models/00_005_025.gltf",
    "models/00_006_004.gltf",
    "models/00_007_003.gltf",
    "models/00_008_004.gltf",
    "models/00_009_008.gltf",
    "models/00_010_013.gltf",
    "models/00_011_013.gltf",
    "models/00_012_001.gltf",
    "models/00_013_003.gltf",
    "models/00_014_004.gltf",
    "models/00_015_004.gltf",
    "models/00_017_001.gltf",
    "models/00_019_001.gltf",
    "models/00_020_002.gltf",
    "models/00_standard.gltf",
]
let modelScale = 10.0;
let modelRotationY = Math.PI; // in radians
let modelPositionOffset = new THREE.Vector3(0, 0, 0);
let sunDirection = new THREE.Vector3();

var gltfLoader = new THREE.GLTFLoader();
var fileLoader = new THREE.FileLoader();

// Based on source from: https://blackthread.io/blog/promisifying-threejs-loaders/
function gltfPromiseLoader(url, onProgress) {
    return new Promise((resolve, reject) => {
        gltfLoader.load(url, resolve, onProgress, reject);
    });
}

function filePromiseLoader(url, onProgress) {
    return new Promise((resolve, reject) => {
        fileLoader.load(url, resolve, onProgress, reject);
    });
}

const KEYCODE_NAMES = {
	65: 'a', 66: 'b', 67: 'c', 68: 'd', 69: 'e', 70: 'f', 71: 'g', 72: 'h', 73: 'i', 74: 'j', 75: 'k', 76: 'l', 77: 'm',
	78: 'n', 79: 'o', 80: 'p', 81: 'q', 82: 'r', 83: 's', 84: 't', 85: 'u', 86: 'v', 87: 'w', 88: 'x', 89: 'y', 90: 'z',
	37: 'left', 38: 'up', 39: 'right', 40: 'down', 32: 'space', 33: 'pageup', 34: 'pagedown', 9: 'tab',
	189: 'dash', 187: 'equals', 188: 'comma', 190: 'period', 27: 'escape', 13: 'enter'
}
let KeyboardState = {
	a: false, b: false, c: false, d: false, e: false, f: false, g: false, h: false, i: false, j: false, k: false, l: false, m: false,
	n: false, o: false, p: false, q: false, r: false, s: false, t: false, u: false, v: false, w: false, x: false, y: false, z: false,
	left: false, up: false, right: false, down: false, space: false, pageup: false, pagedown: false, tab: false,
	dash: false, equals: false, comma: false, period: false, escape: false, enter: false
}

function onKeyDown(event)
{
	event.preventDefault();
	
	KeyboardState[KEYCODE_NAMES[event.keyCode]] = true;
}

function onKeyUp(event)
{
	event.preventDefault();
	
	KeyboardState[KEYCODE_NAMES[event.keyCode]] = false;
}

function keyPressed(keyName)
{
	if (!mouseControl)
		return;

	return KeyboardState[keyName];
}


// init Three.js
initThree();

// init menu
initMenu();

// init models
initModels(modelPaths);

function onMouseWheel(event) {

    if (isPaused)
	return;
    event.stopPropagation();

    if (event.deltaY > 0)
        increaseFov();
    else if (event.deltaY < 0)
        decreaseFov();

}

function increaseFov() {
    if (worldCamera.fov < maxFov) {
        worldCamera.fov++;
        fovChanged = true;
    }
}

function decreaseFov() {
    if (worldCamera.fov > minFov) {
        worldCamera.fov--;
        fovChanged = true;
    }
}

function increaseApertureSize() {
    if (apertureSize < maxApertureSize) {
        apertureSize += 0.1;
        apertureSizeChanged = true;
    }
}

function decreaseApertureSize() {
    if (apertureSize > minApertureSize) {
        apertureSize -= 0.1;
        apertureSizeChanged = true;
    }
}

function MaterialObject(material, pathTracingMaterialList) {
    // a list of material types and their corresponding numbers are found in the 'pathTracingCommon.js' file
    this.type = material.opacity < 1 ? 2 : 1; // default is 1 = diffuse opaque, 2 = glossy transparent, 4 = glossy opaque;
    this.albedoTextureID = -1; // which diffuse map to use for model's color, '-1' = no textures are used
    this.color = material.color ? material.color.copy(material.color) : new THREE.Color(1.0, 1.0, 1.0); // takes on different meanings, depending on 'type' above
    this.roughness = material.roughness || 0.0; // 0.0 to 1.0 range, perfectly smooth to extremely rough
    this.metalness = material.metalness || 0.0; // 0.0 to 1.0 range, usually either 0 or 1, either non-metal or metal
    this.opacity = material.opacity || 1.0; // 0.0 to 1.0 range, fully transparent to fully opaque
    // this seems to be unused
    // this.refractiveIndex = this.type === 4 ? 1.0 : 1.5; // 1.0=air, 1.33=water, 1.4=clearCoat, 1.5=glass, etc.
    pathTracingMaterialList.push(this);
}

async function loadModels(modelPaths) {
    pathTracingMaterialList = [];
    triangleMaterialMarkers = [];
    uniqueMaterialTextures = [];
    let promises = [];

    for (let i = 0; i < modelPaths.length; i++) {
        let modelPath = modelPaths[i];
        console.log(`Loading model ${modelPath}`);

        let promiseLoader = await gltfPromiseLoader(modelPath)
                .then(loadedObject => traverseModel(loadedObject, pathTracingMaterialList, triangleMaterialMarkers))
                .catch(err => console.error(err));

        promises.push(promiseLoader);
    }

    return Promise.all(promises);
}

function traverseModel(meshGroup, pathTracingMaterialList, triangleMaterialMarkers) {
    if (meshGroup.scene)
        meshGroup = meshGroup.scene;

    let meshes = [];
    let matrixStack = [];
    let parent;
    matrixStack.push(new THREE.Matrix4());
    meshGroup.traverse(function (child) {
        if (child.isMesh) {
            if (parent !== undefined && parent.name !== child.parent.name) {
                matrixStack.pop();
                parent = undefined;
            }

            child.geometry.applyMatrix4(child.matrix.multiply(matrixStack[matrixStack.length - 1]));

            if (child.material.length > 0) {
                for (let i = 0; i < child.material.length; i++)
                    new MaterialObject(child.material[i], pathTracingMaterialList);
            } else {
                new MaterialObject(child.material, pathTracingMaterialList);
            }

            if (child.geometry.groups.length > 0) {
                for (let i = 0; i < child.geometry.groups.length; i++) {
                    triangleMaterialMarkers.push((triangleMaterialMarkers.length > 0 ? triangleMaterialMarkers[triangleMaterialMarkers.length - 1] : 0) + child.geometry.groups[i].count / 3);
                }
            } else {
                triangleMaterialMarkers.push((triangleMaterialMarkers.length > 0 ? triangleMaterialMarkers[triangleMaterialMarkers.length - 1] : 0) + child.geometry.index.count / 3);
            }

            meshes.push(child);
        } else if (child.isObject3D) {
            if (parent !== undefined)
                matrixStack.pop();

            let matrixPeek = new THREE.Matrix4().copy(matrixStack[matrixStack.length - 1]).multiply(child.matrix);
            matrixStack.push(matrixPeek);
            parent = child;
        }
    });

    return meshes;
}

function initThree() {
    console.time("InitThree");

    container = document.getElementById('container');
    canvas = document.createElement('canvas');
    let context = canvas.getContext('webgl2');

    // if on mobile device, set mouseControl to false, pixelRatio to 0.5, and unpause the app because there is no ESC key and no mouse capture to do
    if ('ontouchstart' in window) {
        mouseControl = false;
        pixelRatio = 0.5;
        isPaused = false;

        mobileJoystickControls = new MobileJoystickControls({
            //showJoystick: true,
            enableMultiTouch: true
        });
    }

    if (mouseControl) {

        window.addEventListener('wheel', onMouseWheel, false);

        document.body.addEventListener("click", function () {
		if (!ableToEngagePointerLock)
                                return;
            this.requestPointerLock = this.requestPointerLock || this.mozRequestPointerLock;
            this.requestPointerLock();
        }, false);

        var pointerlockChange = () => {
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

        window.addEventListener("click", function (event) {
            event.preventDefault();
        }, false);
        window.addEventListener("dblclick", function (event) {
            event.preventDefault();
        }, false);

    }

    renderer = new THREE.WebGLRenderer({canvas: canvas, context: context});
    renderer.autoClear = false;
    renderer.setPixelRatio(pixelRatio);
    renderer.setSize(window.innerWidth, window.innerHeight);
    //required by WebGL 2.0 for rendering to FLOAT textures
    renderer.getContext().getExtension('EXT_color_buffer_float');
	renderer.toneMapping = THREE.ReinhardToneMapping;
    renderer.toneMappingExposure = hdrExposure;

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
    screenTextureScene = new THREE.Scene();
    screenOutputScene = new THREE.Scene();

    // quadCamera is simply the camera to help render the full screen quad (2 triangles),
    // hence the name.  It is an Orthographic camera that sits facing the view plane, which serves as
    // the window into our 3d world. This camera will not move or rotate for the duration of the app.
    quadCamera = new THREE.OrthographicCamera(-1, 1, 1, -1, 0, 1);
    screenTextureScene.add(quadCamera);
    screenOutputScene.add(quadCamera);

    // worldCamera is the dynamic camera 3d object that will be positioned, oriented and
    // constantly updated inside the 3d scene.  Its view will ultimately get passed back to the
    // stationary quadCamera, which renders the scene to a fullscreen quad (made up of 2 large triangles).
    worldCamera = new THREE.PerspectiveCamera(50, window.innerWidth / window.innerHeight, 1, 1000);
    pathTracingScene.add(worldCamera);

    controls = new FirstPersonCameraControls(worldCamera);
    cameraControlsObject = controls.getObject();
    cameraControlsYawObject = controls.getYawObject();
    cameraControlsPitchObject = controls.getPitchObject();

    pathTracingScene.add(cameraControlsObject);

    // for flyCam
    cameraControlsObject.position.set(-100, 120, 0);

    // look slightly downward
    cameraControlsPitchObject.rotation.x = -0.95;
    cameraControlsYawObject.rotation.y = Math.PI / -1.333;

    oldYawRotation = cameraControlsYawObject.rotation.y;
    oldPitchRotation = cameraControlsPitchObject.rotation.x;

    // now that we moved and rotated the camera, the following line force-updates the camera's matrix,
    // and prevents rendering the very first frame in the old default camera position/orientation
    cameraControlsObject.updateMatrixWorld(true);

    pathTracingRenderTarget = new THREE.WebGLRenderTarget((window.innerWidth * pixelRatio), (window.innerHeight * pixelRatio), {
        minFilter: THREE.NearestFilter,
        magFilter: THREE.NearestFilter,
        format: THREE.RGBAFormat,
        type: THREE.FloatType,
        depthBuffer: false,
        stencilBuffer: false
    });

    screenTextureRenderTarget = new THREE.WebGLRenderTarget((window.innerWidth * pixelRatio), (window.innerHeight * pixelRatio), {
        minFilter: THREE.NearestFilter,
        magFilter: THREE.NearestFilter,
        format: THREE.RGBAFormat,
        type: THREE.FloatType,
        depthBuffer: false,
        stencilBuffer: false
    });

    console.timeEnd("InitThree");
}

async function initModels(modelPaths) {
    console.time("LoadingGltf");

    // Show the loading spinner
    loadingSpinner.classList.remove("hidden");

    // Wait until all models are loaded
    var meshList = await loadModels(modelPaths);
    var flattenedMeshList = [].concat.apply([], meshList);

    // Start listening to window resize events
    window.addEventListener('resize', onWindowResize, false);

    // Prepare geometry for path tracing
    prepareGeometryForPT(flattenedMeshList, pathTracingMaterialList, triangleMaterialMarkers);
}

async function prepareGeometryForPT(meshList, pathTracingMaterialList, triangleMaterialMarkers) {
    // Gather all geometry from the mesh list that now contains loaded models
    let geoList = [];
    for (let i = 0; i < meshList.length; i++)
        geoList.push(meshList[i].geometry);

    // Merge geometry from all models into one new mesh
    let modelMesh = new THREE.Mesh(THREE.BufferGeometryUtils.mergeBufferGeometries(geoList));
    if (modelMesh.geometry.index)
        modelMesh.geometry = modelMesh.geometry.toNonIndexed(); // why do we need NonIndexed geometry?

    // divide by 9 because of nonIndexed geometry (each triangle has 3 floats with each float constisting of 3 components)
    let total_number_of_triangles = modelMesh.geometry.attributes.position.array.length / 9;

    // Gather all textures from materials
    for (let i = 0; i < meshList.length; i++) {
        if (meshList[i].material.length > 0) {
            for (let j = 0; j < meshList[i].material.length; j++) {
                if (meshList[i].material[j].map)
                    uniqueMaterialTextures.push(meshList[i].material[j].map);
            }
        } else if (meshList[i].material.map) {
            uniqueMaterialTextures.push(meshList[i].material.map);
        }
    }

    // Remove duplicate entries
    uniqueMaterialTextures = Array.from(new Set(uniqueMaterialTextures));

    // Assign textures to the path tracing material with the correct id
    for (let i = 0; i < meshList.length; i++) {
        if (meshList[i].material.length > 0) {
            for (let j = 0; j < meshList[i].material.length; j++) {
                if (meshList[i].material[j].map) {
                    for (let k = 0; k < uniqueMaterialTextures.length; k++) {
                        if (meshList[i].material[j].map.image.src === uniqueMaterialTextures[k].image.src) {
                            pathTracingMaterialList[i].albedoTextureID = k;
                        }
                    }
                }
            }
        } else if (meshList[i].material.map) {
            for (let j = 0; j < uniqueMaterialTextures.length; j++) {
                if (meshList[i].material.map.image.src === uniqueMaterialTextures[j].image.src) {
                    pathTracingMaterialList[i].albedoTextureID = j;
                }
            }
        }
    }

    console.log(`Loaded ${modelPaths.length} model(s) consisting of ${total_number_of_triangles} total triangles that are using ${uniqueMaterialTextures.length} textures.`);

    console.timeEnd("LoadingGltf");

    console.time("BvhGeneration");
    console.log("BvhGeneration...");

    modelMesh.geometry.rotateY(modelRotationY);

    let totalWork = new Uint32Array(total_number_of_triangles);

    // Initialize triangle and aabb arrays where 2048 = width and height of texture and 4 are the r, g, b and a components
    let triangle_array = new Float32Array(2048 * 2048 * 4);
    aabb_array = new Float32Array(2048 * 2048 * 4);

    var triangle_b_box_min = new THREE.Vector3();
    var triangle_b_box_max = new THREE.Vector3();
    var triangle_b_box_centroid = new THREE.Vector3();

    var vpa = new Float32Array(modelMesh.geometry.attributes.position.array);
    if (modelMesh.geometry.attributes.normal === undefined)
        modelMesh.geometry.computeVertexNormals();
    var vna = new Float32Array(modelMesh.geometry.attributes.normal.array);

    var modelHasUVs = false;
    if (modelMesh.geometry.attributes.uv !== undefined) {
        var vta = new Float32Array(modelMesh.geometry.attributes.uv.array);
        modelHasUVs = true;
    }

    let materialNumber = 0;
    for (let i = 0; i < total_number_of_triangles; i++) {

        triangle_b_box_min.set(Infinity, Infinity, Infinity);
        triangle_b_box_max.set(-Infinity, -Infinity, -Infinity);

        let vt0 = new THREE.Vector3();
        let vt1 = new THREE.Vector3();
        let vt2 = new THREE.Vector3();
        // record vertex texture coordinates (UVs)
        if (modelHasUVs) {
            vt0.set(vta[6 * i + 0], vta[6 * i + 1]);
            vt1.set(vta[6 * i + 2], vta[6 * i + 3]);
            vt2.set(vta[6 * i + 4], vta[6 * i + 5]);
        } else {
            vt0.set(-1, -1);
            vt1.set(-1, -1);
            vt2.set(-1, -1);
        }

        // record vertex normals
        let vn0 = new THREE.Vector3(vna[9 * i + 0], vna[9 * i + 1], vna[9 * i + 2]).normalize();
        let vn1 = new THREE.Vector3(vna[9 * i + 3], vna[9 * i + 4], vna[9 * i + 5]).normalize();
        let vn2 = new THREE.Vector3(vna[9 * i + 6], vna[9 * i + 7], vna[9 * i + 8]).normalize();

        // record vertex positions
        let vp0 = new THREE.Vector3(vpa[9 * i + 0], vpa[9 * i + 1], vpa[9 * i + 2]);
        let vp1 = new THREE.Vector3(vpa[9 * i + 3], vpa[9 * i + 4], vpa[9 * i + 5]);
        let vp2 = new THREE.Vector3(vpa[9 * i + 6], vpa[9 * i + 7], vpa[9 * i + 8]);

        vp0.multiplyScalar(modelScale);
        vp1.multiplyScalar(modelScale);
        vp2.multiplyScalar(modelScale);

        vp0.add(modelPositionOffset);
        vp1.add(modelPositionOffset);
        vp2.add(modelPositionOffset);

        //slot 0
        triangle_array[32 * i + 0] = vp0.x; // r or x
        triangle_array[32 * i + 1] = vp0.y; // g or y
        triangle_array[32 * i + 2] = vp0.z; // b or z
        triangle_array[32 * i + 3] = vp1.x; // a or w

        //slot 1
        triangle_array[32 * i + 4] = vp1.y; // r or x
        triangle_array[32 * i + 5] = vp1.z; // g or y
        triangle_array[32 * i + 6] = vp2.x; // b or z
        triangle_array[32 * i + 7] = vp2.y; // a or w

        //slot 2
        triangle_array[32 * i + 8] = vp2.z; // r or x
        triangle_array[32 * i + 9] = vn0.x; // g or y
        triangle_array[32 * i + 10] = vn0.y; // b or z
        triangle_array[32 * i + 11] = vn0.z; // a or w

        //slot 3
        triangle_array[32 * i + 12] = vn1.x; // r or x
        triangle_array[32 * i + 13] = vn1.y; // g or y
        triangle_array[32 * i + 14] = vn1.z; // b or z
        triangle_array[32 * i + 15] = vn2.x; // a or w

        //slot 4
        triangle_array[32 * i + 16] = vn2.y; // r or x
        triangle_array[32 * i + 17] = vn2.z; // g or y
        triangle_array[32 * i + 18] = vt0.x; // b or z
        triangle_array[32 * i + 19] = vt0.y; // a or w

        //slot 5
        triangle_array[32 * i + 20] = vt1.x; // r or x
        triangle_array[32 * i + 21] = vt1.y; // g or y
        triangle_array[32 * i + 22] = vt2.x; // b or z
        triangle_array[32 * i + 23] = vt2.y; // a or w

        // the remaining slots are used for PBR material properties

        if (i >= triangleMaterialMarkers[materialNumber])
            materialNumber++;

        //slot 6
        triangle_array[32 * i + 24] = pathTracingMaterialList[materialNumber].type; // r or x
        triangle_array[32 * i + 25] = pathTracingMaterialList[materialNumber].color.r; // g or y
        triangle_array[32 * i + 26] = pathTracingMaterialList[materialNumber].color.g; // b or z
        triangle_array[32 * i + 27] = pathTracingMaterialList[materialNumber].color.b; // a or w

        //slot 7
        triangle_array[32 * i + 28] = pathTracingMaterialList[materialNumber].albedoTextureID; // r or x
        triangle_array[32 * i + 29] = pathTracingMaterialList[materialNumber].opacity; // g or y
        triangle_array[32 * i + 30] = 0; // b or z
        triangle_array[32 * i + 31] = 0; // a or w

        triangle_b_box_min.copy(triangle_b_box_min.min(vp0));
        triangle_b_box_max.copy(triangle_b_box_max.max(vp0));
        triangle_b_box_min.copy(triangle_b_box_min.min(vp1));
        triangle_b_box_max.copy(triangle_b_box_max.max(vp1));
        triangle_b_box_min.copy(triangle_b_box_min.min(vp2));
        triangle_b_box_max.copy(triangle_b_box_max.max(vp2));

        triangle_b_box_centroid.set((triangle_b_box_min.x + triangle_b_box_max.x) * 0.5,
            (triangle_b_box_min.y + triangle_b_box_max.y) * 0.5,
            (triangle_b_box_min.z + triangle_b_box_max.z) * 0.5);

        aabb_array[9 * i + 0] = triangle_b_box_min.x;
        aabb_array[9 * i + 1] = triangle_b_box_min.y;
        aabb_array[9 * i + 2] = triangle_b_box_min.z;
        aabb_array[9 * i + 3] = triangle_b_box_max.x;
        aabb_array[9 * i + 4] = triangle_b_box_max.y;
        aabb_array[9 * i + 5] = triangle_b_box_max.z;
        aabb_array[9 * i + 6] = triangle_b_box_centroid.x;
        aabb_array[9 * i + 7] = triangle_b_box_centroid.y;
        aabb_array[9 * i + 8] = triangle_b_box_centroid.z;

        totalWork[i] = i;

    } // end for (let i = 0; i < total_number_of_triangles; i++)

    // Build the BVH acceleration structure, which places a bounding box ('root' of the tree) around all of the
    // triangles of the entire mesh, then subdivides each box into 2 smaller boxes.  It continues until it reaches 1 triangle,
    // which it then designates as a 'leaf'
    BVH_Build_Iterative(totalWork, aabb_array);
    //console.log(buildnodes);

    // Copy the buildnodes array into the aabb_array
    for (let n = 0; n < buildnodes.length; n++) {

        // slot 0
        aabb_array[8 * n + 0] = buildnodes[n].idLeftChild;  // r or x component
        aabb_array[8 * n + 1] = buildnodes[n].minCorner.x;  // g or y component
        aabb_array[8 * n + 2] = buildnodes[n].minCorner.y;  // b or z component
        aabb_array[8 * n + 3] = buildnodes[n].minCorner.z;  // a or w component

        // slot 1
        aabb_array[8 * n + 4] = buildnodes[n].idRightChild; // r or x component
        aabb_array[8 * n + 5] = buildnodes[n].maxCorner.x;  // g or y component
        aabb_array[8 * n + 6] = buildnodes[n].maxCorner.y;  // b or z component
        aabb_array[8 * n + 7] = buildnodes[n].maxCorner.z;  // a or w component

    }

    let triangleDataTexture = new THREE.DataTexture(triangle_array,
        2048,
        2048,
        THREE.RGBAFormat,
        THREE.FloatType,
        THREE.Texture.DEFAULT_MAPPING,
        THREE.ClampToEdgeWrapping,
        THREE.ClampToEdgeWrapping,
        THREE.NearestFilter,
        THREE.NearestFilter,
        1,
        THREE.LinearEncoding
    );

    triangleDataTexture.flipY = false;
    triangleDataTexture.generateMipmaps = false;
    triangleDataTexture.needsUpdate = true;

    let aabbDataTexture = new THREE.DataTexture(aabb_array,
        2048,
        2048,
        THREE.RGBAFormat,
        THREE.FloatType,
        THREE.Texture.DEFAULT_MAPPING,
        THREE.ClampToEdgeWrapping,
        THREE.ClampToEdgeWrapping,
        THREE.NearestFilter,
        THREE.NearestFilter,
        1,
        THREE.LinearEncoding
    );

    aabbDataTexture.flipY = false;
    aabbDataTexture.generateMipmaps = false;
    aabbDataTexture.needsUpdate = true;


    hdrLoader = new THREE.RGBELoader();
    hdrPath = 'textures/daytime.hdr';

    hdrTexture = hdrLoader.load( hdrPath, function ( texture, textureData ) {
        texture.encoding = THREE.RGBEEncoding;
        texture.minFilter = THREE.NearestFilter;
        texture.magFilter = THREE.NearestFilter;
        texture.flipY = true;
    } );
	
	// blueNoise texture for efficient random number generation on calls to rand()
	blueNoiseTexture = new THREE.TextureLoader().load('textures/BlueNoise_RGBA256.png');
	blueNoiseTexture.wrapS = THREE.RepeatWrapping;
	blueNoiseTexture.wrapT = THREE.RepeatWrapping;
	blueNoiseTexture.flipY = false;
	blueNoiseTexture.minFilter = THREE.NearestFilter;
	blueNoiseTexture.magFilter = THREE.NearestFilter;
	blueNoiseTexture.generateMipmaps = false;

    pathTracingUniforms = {

        tPreviousTexture: {type: "t", value: screenTextureRenderTarget.texture},
        tTriangleTexture: {type: "t", value: triangleDataTexture},
        tAABBTexture: {type: "t", value: aabbDataTexture},
        tAlbedoTextures: {type: "t", value: uniqueMaterialTextures},
        tHDRTexture: { type: "t", value: hdrTexture },
		tBlueNoiseTexture: { type: "t", value: blueNoiseTexture },

        uCameraIsMoving: {type: "b1", value: false},

        uTime: {type: "f", value: 0.0},
        uFrameCounter: {type: "f", value: 1.0},
        uULen: {type: "f", value: 1.0},
        uVLen: {type: "f", value: 1.0},
        uApertureSize: {type: "f", value: apertureSize},
        uFocusDistance: {type: "f", value: focusDistance},
        uSkyLightIntensity: {type: "f", value: skyLightIntensity},
        uSunLightIntensity: {type: "f", value: sunLightIntensity},
        uSunColor: {type: "v3", value: new THREE.Color().fromArray(sunColor.map(x => x / 255))},

        uResolution: {type: "v2", value: new THREE.Vector2()},
		uRandomVec2: { type: "v2", value: new THREE.Vector2() },
	    
        uSunDirection: {type: "v3", value: new THREE.Vector3()},
        uCameraMatrix: {type: "m4", value: new THREE.Matrix4()},

    };

    pathTracingDefines = {
        //N_ALBEDO_MAPS: uniqueMaterialTextures.length
    };

	// load vertex and fragment shader files that are used in the pathTracing material, mesh and scene
    let vertexShader = await filePromiseLoader('shaders/common_PathTracing_Vertex.glsl');
    let fragmentShader = await filePromiseLoader('shaders/Gltf_Viewer.glsl');

    let pathTracingMaterial = new THREE.ShaderMaterial({
        uniforms: pathTracingUniforms,
        defines: pathTracingDefines,
        vertexShader: vertexShader,
        fragmentShader: fragmentShader,
        depthTest: false,
        depthWrite: false
    });

    let pathTracingGeometry = new THREE.PlaneBufferGeometry(2, 2);
    let pathTracingMesh = new THREE.Mesh(pathTracingGeometry, pathTracingMaterial);
    pathTracingScene.add(pathTracingMesh);

    // the following keeps the large scene ShaderMaterial quad right in front
    //   of the camera at all times. This is necessary because without it, the scene
    //   quad will fall out of view and get clipped when the camera rotates past 180 degrees.
    worldCamera.add(pathTracingMesh);
	
	screenTextureUniforms = {
    	tPathTracedImageTexture: { type: "t", value: null }
    };
    let screenTextureFragmentShader = await filePromiseLoader('shaders/ScreenCopy_Fragment.glsl');
	
    let screenTextureGeometry = new THREE.PlaneBufferGeometry(2, 2);

    let screenTextureMaterial = new THREE.ShaderMaterial({
        uniforms: screenTextureUniforms,
        vertexShader: vertexShader,
        fragmentShader: screenTextureFragmentShader,
        depthWrite: false,
        depthTest: false
    });
    screenTextureUniforms.tPathTracedImageTexture.value = pathTracingRenderTarget.texture;

    let screenTextureMesh = new THREE.Mesh(screenTextureGeometry, screenTextureMaterial);
    screenTextureScene.add(screenTextureMesh);


	screenOutputUniforms = {
    	uOneOverSampleCounter: { type: "f", value: 0.0 },
    	tPathTracedImageTexture: { type: "t", value: null }
    };
    let screenOutputFragmentShader = await filePromiseLoader('shaders/ScreenOutput_Fragment.glsl');
	
	let screenOutputGeometry = new THREE.PlaneBufferGeometry(2, 2);
	
    screenOutputMaterial = new THREE.ShaderMaterial({
        uniforms: screenOutputUniforms,
        vertexShader: vertexShader,
        fragmentShader: screenOutputFragmentShader,
        depthWrite: false,
        depthTest: false
    });
    screenOutputUniforms.tPathTracedImageTexture.value = pathTracingRenderTarget.texture;

    let screenOutputMesh = new THREE.Mesh(screenOutputGeometry, screenOutputMaterial);
    screenOutputScene.add(screenOutputMesh);

    /*
    // Fullscreen API
    document.addEventListener("click", function() {

        if ( !document.fullscreenElement && !document.mozFullScreenElement && !document.webkitFullscreenElement ) {

            if (document.documentElement.requestFullscreen) {
                document.documentElement.requestFullscreen();

            } else if (document.documentElement.mozRequestFullScreen) {
                document.documentElement.mozRequestFullScreen();

            } else if (document.documentElement.webkitRequestFullscreen) {
                document.documentElement.webkitRequestFullscreen();

            }

        }
    });
    */

    console.timeEnd("BvhGeneration");

    // Hide loading spinning and show menu
    loadingSpinner.classList.add("hidden");
    gui.domElement.classList.remove("hidden");

    // onWindowResize() must be at the end of the initModels() function
    onWindowResize();

    // everything is set up, now we can start animating
    animate();

} // end function initModels()

function initMenu() {
    let context = renderer.getContext();
    if (gui)
        return;

    gui = new dat.GUI();
	if (mouseControl) {
		gui.domElement.addEventListener("mouseenter", function(event) {
				ableToEngagePointerLock = false;	
		}, false);
		gui.domElement.addEventListener("mouseleave", function(event) {
				ableToEngagePointerLock = true;
		}, false);
	}
    gui.domElement.classList.add("hidden");

    gui.add(this, 'pixelRatio', 0.25, 1).step(0.01).onChange(function (value) {
        renderer.setPixelRatio(value);

        pathTracingUniforms.uResolution.value.x = context.drawingBufferWidth;
        pathTracingUniforms.uResolution.value.y = context.drawingBufferHeight;

        pathTracingRenderTarget.setSize(context.drawingBufferWidth, context.drawingBufferHeight);
        screenTextureRenderTarget.setSize(context.drawingBufferWidth, context.drawingBufferHeight);

        forceUpdate = true;
    });
    lightingSettingsFolder = gui.addFolder("Lighting Settings");
    lightingSettingsFolder.add(this, 'sunAngle', 0, Math.PI).step(Math.PI/100).onChange(() => {
        forceUpdate = true;
    });
    lightingSettingsFolder.add(this, 'hdrExposure', 0, 10).step(10/100).onChange(() => {
        renderer.toneMappingExposure = hdrExposure;
        forceUpdate = true;
    });
    lightingSettingsFolder.add(this, 'skyLightIntensity', 0, 5).step(5/100).onChange(() => {
        skyLightIntensityChanged = true;
        forceUpdate = true;
    });
    lightingSettingsFolder.add(this, 'sunLightIntensity', 0, 5).step(5/100).onChange(() => {
        sunLightIntensityChanged = true;
        forceUpdate = true;
    });
    lightingSettingsFolder.addColor(this, 'sunColor').onChange(() => {
        sunColorChanged = true;
        forceUpdate = true;
    });
    cameraSettingsFolder = gui.addFolder("Camera Settings");
    cameraSettingsFolder.add(worldCamera, 'fov', minFov, maxFov).onChange(() => {
        fovChanged = true;
    });
    cameraSettingsFolder.add(this, 'apertureSize', minApertureSize, maxApertureSize).step(maxApertureSize/100).onChange(() => {
        apertureSizeChanged = true;
    });
    cameraSettingsFolder.add(this, 'focusDistance', minFocusDistance).step(1).onChange(() => {
        focusDistanceChanged = true;
    });
    cameraSettingsFolder.add(this, 'speed').step(1);
}

function onWindowResize() {

    let context = renderer.getContext();
    let screenWidth = window.innerWidth;
    let screenHeight = window.innerHeight;

    renderer.setPixelRatio(pixelRatio);
    renderer.setSize(screenWidth, screenHeight);

    fontAspect = (screenWidth / 175) * (screenHeight / 200);
    if (fontAspect > 25) fontAspect = 25;
    if (fontAspect < 4) fontAspect = 4;
    fontAspect *= 2;

    pathTracingUniforms.uResolution.value.x = context.drawingBufferWidth;
    pathTracingUniforms.uResolution.value.y = context.drawingBufferHeight;

    pathTracingRenderTarget.setSize(context.drawingBufferWidth, context.drawingBufferHeight);
    screenTextureRenderTarget.setSize(context.drawingBufferWidth, context.drawingBufferHeight);

    worldCamera.aspect = renderer.domElement.clientWidth / renderer.domElement.clientHeight;
    worldCamera.updateProjectionMatrix();

    // the following scales all scene objects by the worldCamera's field of view,
    // taking into account the screen aspect ratio and multiplying the uniform uULen,
    // the x-coordinate, by this ratio
    var fovScale = worldCamera.fov * 0.5 * (Math.PI / 180.0);
    pathTracingUniforms.uVLen.value = Math.tan(fovScale);
    pathTracingUniforms.uULen.value = pathTracingUniforms.uVLen.value * worldCamera.aspect;

    forceUpdate = true;

    if (!mouseControl) {

        button1Element.style.display = "";
        button2Element.style.display = "";
        button3Element.style.display = "";
        button4Element.style.display = "";
        button5Element.style.display = "";
        button6Element.style.display = "";
        // check if mobile device is in portrait or landscape mode and position buttons accordingly
        if (screenWidth < screenHeight) {

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

        } else {

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

function animate() {

    frameTime = clock.getDelta();

    //elapsedTime = clock.getElapsedTime() % 1000;

    // reset flags
    cameraIsMoving = false;
    if (forceUpdate) {
        cameraIsMoving = true;
        forceUpdate = false;
    }

    // check user controls
    if (mouseControl) {
        // movement detected
        if (oldYawRotation !== cameraControlsYawObject.rotation.y || oldPitchRotation !== cameraControlsPitchObject.rotation.x)
            cameraIsMoving = true;

        // save state for next frame
        oldYawRotation = cameraControlsYawObject.rotation.y;
        oldPitchRotation = cameraControlsPitchObject.rotation.x;

    } // end if (mouseControl)

    // if not playing on desktop, get input from the mobileJoystickControls
    if (!mouseControl) {

        newDeltaX = joystickDeltaX;

        if (newDeltaX) {

            mobileControlsMoveX = oldDeltaX - newDeltaX;
            // smooth out jerkiness if camera was sitting still
            if (stillFlagX) {
                mobileControlsMoveX *= 0.1;
                stillFlagX = false;
            }
            // mobileJoystick X movement (left and right) affects camera rotation around the Y axis
            cameraControlsYawObject.rotation.y += (mobileControlsMoveX) * 0.01;
        }

        newDeltaY = joystickDeltaY;

        if (newDeltaY) {

            mobileControlsMoveY = oldDeltaY - newDeltaY;
            // smooth out jerkiness if camera was sitting still
            if (stillFlagY) {
                mobileControlsMoveY *= 0.1;
                stillFlagY = false;
            }
            // mobileJoystick Y movement (up and down) affects camera rotation around the X axis
            cameraControlsPitchObject.rotation.x += (mobileControlsMoveY) * 0.01;
        }

        // clamp the camera's vertical movement (around the x-axis) to the scene's 'ceiling' and 'floor',
        // so you can't accidentally flip the camera upside down
        cameraControlsPitchObject.rotation.x = Math.max(-PI_2, Math.min(PI_2, cameraControlsPitchObject.rotation.x));

        // save state for next frame
        oldDeltaX = newDeltaX;
        oldDeltaY = newDeltaY;

        // movement detected
        if (newDeltaX || newDeltaY) {

            cameraIsMoving = true;
        } else {
            stillFlagX = true;
            stillFlagY = true;
        }

        newPinchWidthX = pinchWidthX;
        newPinchWidthY = pinchWidthY;
        pinchDeltaX = newPinchWidthX - oldPinchWidthX;
        pinchDeltaY = newPinchWidthY - oldPinchWidthY;

        if (Math.abs(pinchDeltaX) > Math.abs(pinchDeltaY)) {
            if (pinchDeltaX < -3) increaseFov();
            if (pinchDeltaX > 3) decreaseFov();
        }

        if (Math.abs(pinchDeltaY) >= Math.abs(pinchDeltaX)) {
            if (pinchDeltaY > 1) increaseApertureSize();
            if (pinchDeltaY < -1) decreaseApertureSize();
        }

        // save state for next frame
        oldPinchWidthX = newPinchWidthX;
        oldPinchWidthY = newPinchWidthY;

    } // end if ( !mouseControl )

    // the following variables will be used to calculate rotations and directions from the camera
    // this gives us a vector in the direction that the camera is pointing,
    // which will be useful for moving the camera 'forward' and shooting projectiles in that direction
    controls.getDirection(cameraDirectionVector); //for moving where the camera is looking
    cameraDirectionVector.normalize();
    controls.getRightVector(cameraRightVector); //for strafing the camera right and left
    controls.getUpVector(cameraUpVector); //for moving camera up and down

    camFlightSpeed = speed;

    // allow flying camera
    if ((keyPressed('w') || button3Pressed) && !(keyPressed('s') || button4Pressed)) {

        cameraControlsObject.position.add(cameraDirectionVector.multiplyScalar(camFlightSpeed * frameTime));
        cameraIsMoving = true;
    }
    if ((keyPressed('s') || button4Pressed) && !(keyPressed('w') || button3Pressed)) {

        cameraControlsObject.position.sub(cameraDirectionVector.multiplyScalar(camFlightSpeed * frameTime));
        cameraIsMoving = true;
    }
    if ((keyPressed('a') || button1Pressed) && !(keyPressed('d') || button2Pressed)) {

        cameraControlsObject.position.sub(cameraRightVector.multiplyScalar(camFlightSpeed * frameTime));
        cameraIsMoving = true;
    }
    if ((keyPressed('d') || button2Pressed) && !(keyPressed('a') || button1Pressed)) {

        cameraControlsObject.position.add(cameraRightVector.multiplyScalar(camFlightSpeed * frameTime));
        cameraIsMoving = true;
    }
    if (keyPressed('e') && !keyPressed('q')) {

        cameraControlsObject.position.add(cameraUpVector.multiplyScalar(camFlightSpeed * frameTime));
        cameraIsMoving = true;
    }
    if (keyPressed('q') && !keyPressed('e')) {

        cameraControlsObject.position.sub(cameraUpVector.multiplyScalar(camFlightSpeed * frameTime));
        cameraIsMoving = true;
    }
    if ((keyPressed('up') || button5Pressed) && !(keyPressed('down') || button6Pressed)) {
        focusDistance++;
        focusDistanceChanged = true;
    }
    if ((keyPressed('down') || button6Pressed) && !(keyPressed('up') || button5Pressed)) {
        if (focusDistance > minFocusDistance) {
            focusDistance--;
            focusDistanceChanged = true;
        }
    }
    if (keyPressed('right') && !keyPressed('left')) {
        increaseApertureSize();
    }
    if (keyPressed('left') && !keyPressed('right')) {
        decreaseApertureSize()
    }

    if (fovChanged || apertureSizeChanged || focusDistanceChanged) {
        cameraIsMoving = true;

        // Iterate over all GUI controllers
        for (let i in cameraSettingsFolder.__controllers)
            cameraSettingsFolder.__controllers[i].updateDisplay();
    }

    if (fovChanged) {
        fovScale = worldCamera.fov * 0.5 * (Math.PI / 180.0);
        pathTracingUniforms.uVLen.value = Math.tan(fovScale);
        pathTracingUniforms.uULen.value = pathTracingUniforms.uVLen.value * worldCamera.aspect;
        fovChanged = false;
    }

    if (apertureSizeChanged) {
        pathTracingUniforms.uApertureSize.value = apertureSize;
        apertureSizeChanged = false;
    }

    if (focusDistanceChanged) {
        pathTracingUniforms.uFocusDistance.value = focusDistance;
        focusDistanceChanged = false;
    }

    if (skyLightIntensityChanged) {
        pathTracingUniforms.uSkyLightIntensity.value = skyLightIntensity;
        skyLightIntensityChanged = false;
    }

    if (sunLightIntensityChanged) {
        pathTracingUniforms.uSunLightIntensity.value = sunLightIntensity;
        sunLightIntensityChanged = false;
    }

    if (sunColorChanged) {
        pathTracingUniforms.uSunColor.value = new THREE.Color().fromArray(sunColor.map(x => x / 255));
        sunColorChanged = false;
    }

    if ( !cameraIsMoving ) {
                
    	if (sceneIsDynamic)
        	sampleCounter = 1.0; // reset for continuous updating of image
    	else sampleCounter += 1.0; // for progressive refinement of image
                
    	frameCounter += 1.0;

    	cameraRecentlyMoving = false;  
	}

	if (cameraIsMoving) {
		sampleCounter = 1.0;
		frameCounter += 1.0;

		if (!cameraRecentlyMoving) {
				frameCounter = 1.0;
				cameraRecentlyMoving = true;
		}
	}

    //sunAngle = (elapsedTime * 0.03) % Math.PI;
    // sunAngle = Math.PI / 2.5;
    sunDirection.set(Math.cos(sunAngle) * 1.2, Math.sin(sunAngle), -Math.cos(sunAngle) * 3.0);
    sunDirection.normalize();

    pathTracingUniforms.uSunDirection.value.copy(sunDirection);
    //pathTracingUniforms.uTime.value = elapsedTime;
    pathTracingUniforms.uCameraIsMoving.value = cameraIsMoving;
    pathTracingUniforms.uFrameCounter.value = frameCounter;
	pathTracingUniforms.uRandomVec2.value.set(Math.random(), Math.random());
	
    // CAMERA
    cameraControlsObject.updateMatrixWorld(true);
    pathTracingUniforms.uCameraMatrix.value.copy(worldCamera.matrixWorld);
    screenOutputUniforms.uOneOverSampleCounter.value = 1.0 / sampleCounter;

    samplesSpanEl.innerHTML = `Samples: ${sampleCounter}`;

    // RENDERING in 3 steps

    // STEP 1
    // Perform PathTracing and Render(save) into pathTracingRenderTarget, a full-screen texture.
    // Read previous screenTextureRenderTarget(via texelFetch inside fragment shader) to use as a new starting point to blend with
    renderer.setRenderTarget(pathTracingRenderTarget);
    renderer.render(pathTracingScene, worldCamera);

    // STEP 2
    // Render(copy) the pathTracingScene output(pathTracingRenderTarget above) into screenTextureRenderTarget.
    // This will be used as a new starting point for Step 1 above (essentially creating ping-pong buffers)
    renderer.setRenderTarget(screenTextureRenderTarget);
    renderer.render(screenTextureScene, quadCamera);

    // STEP 3
    // Render full screen quad with generated pathTracingRenderTarget in STEP 1 above.
    // After the image is gamma-corrected, it will be shown on the screen as the final accumulated output
    renderer.setRenderTarget(null);
    renderer.render(screenOutputScene, quadCamera);

    stats.update();
	
	requestAnimationFrame(animate);

} // end function animate()
