// scene/demo-specific variables go here
let modelMesh;
let modelScale = 1.0;
let modelPositionOffset = new THREE.Vector3();
let albedoTexture;
let total_number_of_triangles = 0;
let triangle_array;
let triangleMaterialMarkers = [];
let pathTracingMaterialList = [];
let uniqueMaterialTextures = [];
let meshList = [];
let geoList = [];
let triangleDataTexture;
let aabb_array;
let aabbDataTexture;
let totalWork;
let vp0 = new THREE.Vector3();
let vp1 = new THREE.Vector3();
let vp2 = new THREE.Vector3();
let vn0 = new THREE.Vector3();
let vn1 = new THREE.Vector3();
let vn2 = new THREE.Vector3();
let vt0 = new THREE.Vector2();
let vt1 = new THREE.Vector2();
let vt2 = new THREE.Vector2();

let rectangleLight0, rectangleLight1;
let fog_DensityObject, fog_DensityController;
let light0_PowerObject, light0_PowerController;
let light1_PowerObject, light1_PowerController;
let light0Position_Folder, light0Rotation_Folder;
let light1Position_Folder, light1Rotation_Folder;
let light0_PositionXObject, light0_PositionXController;
let light0_PositionYObject, light0_PositionYController;
let light0_PositionZObject, light0_PositionZController;
let light0_RotationXObject, light0_RotationXController;
let light0_RotationYObject, light0_RotationYController;
let light0_RotationZObject, light0_RotationZController;
let light1_PositionXObject, light1_PositionXController;
let light1_PositionYObject, light1_PositionYController;
let light1_PositionZObject, light1_PositionZController;
let light1_RotationXObject, light1_RotationXController;
let light1_RotationYObject, light1_RotationYController;
let light1_RotationZObject, light1_RotationZController;
let needChangeFogDensity = false;
let needChangeLight0Power = false;
let needChangeLight1Power = false;
let needChangeLight0Position = false;
let needChangeLight0Rotation = false;
let needChangeLight1Position = false;
let needChangeLight1Rotation = false;

let cameraZOffset;


function init_GUI() 
{

	fog_DensityObject = {
		Fog_Density: 0.03038
	};
	light0_PowerObject = {
		Light0_Power: 1000
	};
	light1_PowerObject = {
		Light1_Power: 1000
	};
	light0_PositionXObject = { positionX: -100 };
	light0_PositionYObject = { positionY: 107 };
	light0_PositionZObject = { positionZ: -5 };
	light0_RotationXObject = { rotationX: 0 };
	light0_RotationYObject = { rotationY: 32 };
	light0_RotationZObject = { rotationZ: 50 };

	light1_PositionXObject = { positionX: -10 };
	light1_PositionYObject = { positionY: 90 };
	light1_PositionZObject = { positionZ: -50 };
	light1_RotationXObject = { rotationX: 0 };
	light1_RotationYObject = { rotationY: 32 };
	light1_RotationZObject = { rotationZ: 148 };
	
	function handleFogDensityChange() 
	{
		needChangeFogDensity = true;
	}
	function handleLight0PowerChange() {
		needChangeLight0Power = true;
	}
	function handleLight1PowerChange() {
		needChangeLight1Power = true;
	}
	function handleLight0PositionChange() { 
		needChangeLight0Position = true; 
	}
	function handleLight1PositionChange() { 
		needChangeLight1Position = true; 
	}
	function handleLight0RotationChange() {
		needChangeLight0Rotation = true;
	}
	function handleLight1RotationChange() {
		needChangeLight1Rotation = true;
	}

	fog_DensityController = gui.add( fog_DensityObject, 'Fog_Density', 0.0, 0.2, 0.00001 ).onChange( handleFogDensityChange );
	light0_PowerController = gui.add(light0_PowerObject, 'Light0_Power', 1, 1000, 1).onChange(handleLight0PowerChange);
	light1_PowerController = gui.add(light1_PowerObject, 'Light1_Power', 1, 1000, 1).onChange(handleLight1PowerChange);
	
	light0Position_Folder = gui.addFolder('Light0_Position');
	light0_PositionXController = light0Position_Folder.add(light0_PositionXObject, 'positionX', -500, 500, 1).onChange(handleLight0PositionChange);
	light0_PositionYController = light0Position_Folder.add(light0_PositionYObject, 'positionY', -500, 500, 1).onChange(handleLight0PositionChange);
	light0_PositionZController = light0Position_Folder.add(light0_PositionZObject, 'positionZ', -500, 500, 1).onChange(handleLight0PositionChange);

	light0Rotation_Folder = gui.addFolder('Light0_Rotation');
	light0_RotationXController = light0Rotation_Folder.add(light0_RotationXObject, 'rotationX', 0, 359, 1).onChange(handleLight0RotationChange);
	light0_RotationYController = light0Rotation_Folder.add(light0_RotationYObject, 'rotationY', 0, 359, 1).onChange(handleLight0RotationChange);
	light0_RotationZController = light0Rotation_Folder.add(light0_RotationZObject, 'rotationZ', 0, 359, 1).onChange(handleLight0RotationChange);

	light1Position_Folder = gui.addFolder('Light1_Position');
	light1_PositionXController = light1Position_Folder.add(light1_PositionXObject, 'positionX', -500, 500, 1).onChange(handleLight1PositionChange);
	light1_PositionYController = light1Position_Folder.add(light1_PositionYObject, 'positionY', -500, 500, 1).onChange(handleLight1PositionChange);
	light1_PositionZController = light1Position_Folder.add(light1_PositionZObject, 'positionZ', -500, 500, 1).onChange(handleLight1PositionChange);

	light1Rotation_Folder = gui.addFolder('Light1_Rotation');
	light1_RotationXController = light1Rotation_Folder.add(light1_RotationXObject, 'rotationX', 0, 359, 1).onChange(handleLight1RotationChange);
	light1_RotationYController = light1Rotation_Folder.add(light1_RotationYObject, 'rotationY', 0, 359, 1).onChange(handleLight1RotationChange);
	light1_RotationZController = light1Rotation_Folder.add(light1_RotationZObject, 'rotationZ', 0, 359, 1).onChange(handleLight1RotationChange);

	handleFogDensityChange();
	handleLight0PowerChange();
	handleLight1PowerChange();
	handleLight0PositionChange();
	handleLight0RotationChange();
	handleLight1PositionChange();
	handleLight1RotationChange();

} // end function init_GUI()


function MaterialObject() 
{
	// a list of material types and their corresponding numbers are found in the 'pathTracingCommon.js' file
	this.type = 1; // default is '1': diffuse type 		
	this.albedoTextureID = -1; // which diffuse map to use for model's color / '-1' = no textures are used
	this.color = new THREE.Color(1.0, 1.0, 1.0); // takes on different meanings, depending on 'type' above
	this.roughness = 0.0; // 0.0 to 1.0 range, perfectly smooth to extremely rough
	this.metalness = 0.0; // 0.0 to 1.0 range, usually either 0 or 1, either non-metal or metal
	this.opacity = 1.0;   // 0.0 to 1.0 range, fully transparent to fully opaque
	this.refractiveIndex = 1.0; // 1.0=air, 1.33=water, 1.4=clearCoat, 1.5=glass, etc.
}


function load_GLTF_Model() 
{

	let gltfLoader = new THREE.GLTFLoader();

	//gltfLoader.load("models/StanfordDragon.glb", function( meshGroup ) // Triangles: 100,000
	// if you choose to load in the different models below, scroll down and change the *GLTF model settings* for this particular model
	//gltfLoader.load("models/Classic 1982 TRON Light Cycle.gltf", function( meshGroup ) // Triangles: 17,533
	//gltfLoader.load("models/StanfordBunny.glb", function( meshGroup ) // Triangles: 30,338
	gltfLoader.load("models/david.gltf", function (meshGroup)
	{
	
		if (meshGroup.scene) 
			meshGroup = meshGroup.scene;

		meshGroup.traverse( function ( child ) 
		{

			if ( child.isMesh ) 
			{ 
				let mat = new MaterialObject();
				mat.type = 1;
				mat.albedoTextureID = -1;
				//mat.color = child.material.color;
				mat.roughness = child.material.roughness || 0.0;
				mat.metalness = child.material.metalness || 0.0;
				mat.opacity = child.material.opacity || 1.0;
				mat.refractiveIndex = 1.0;
				pathTracingMaterialList.push(mat);
				triangleMaterialMarkers.push(child.geometry.attributes.position.array.length / 9);
				meshList.push(child);
			}
		} );

		modelMesh = meshList[0].clone();

		for (let i = 0; i < meshList.length; i++) 
		{
			geoList.push(meshList[i].geometry);
		}

		

		modelMesh.geometry = THREE.BufferGeometryUtils.mergeBufferGeometries(geoList);
		
		if (modelMesh.geometry.index)
			modelMesh.geometry = modelMesh.geometry.toNonIndexed();

		modelMesh.geometry.center();

		
		
		for (let i = 1; i < triangleMaterialMarkers.length; i++) 
		{
			triangleMaterialMarkers[i] += triangleMaterialMarkers[i-1];
		}
			
		for (let i = 0; i < meshList.length; i++) 
		{
			if (meshList[i].material.map != undefined)
				uniqueMaterialTextures.push(meshList[i].material.map);		
		}
		
		for (let i = 0; i < uniqueMaterialTextures.length; i++) 
		{
			for (let j = i + 1; j < uniqueMaterialTextures.length; j++) 
			{
				if (uniqueMaterialTextures[i].image.src == uniqueMaterialTextures[j].image.src) 
				{
					uniqueMaterialTextures.splice(j, 1);
					j -= 1;
				}
			}	
		}
		
		for (let i = 0; i < meshList.length; i++) 
		{
			if (meshList[i].material.map != undefined) 
			{
				for (let j = 0; j < uniqueMaterialTextures.length; j++) 
				{
					if (meshList[i].material.map.image.src == uniqueMaterialTextures[j].image.src) 
					{
						pathTracingMaterialList[i].albedoTextureID = j;
					}
				}
			}				
		}

		// ********* different GLTF Model Settings **********

		// settings for StanfordDragon model
		// modelScale = 2.0;
		// modelPositionOffset.set(0, 28, -40);
		
		// settings for TronTank model
		// modelScale = 10.0;
		// modelMesh.geometry.rotateX(-Math.PI * 0.5);
		// modelPositionOffset.set(-60, 20, -30);

		// settings for the David sculpture model
		modelScale = 0.04;
		modelPositionOffset.set(0, 0, 0);

		// now that the model has loaded, we can init the app
		init();
	}); // end gltfLoader.load()

} // end function load_GLTF_Model()



// called automatically from within initTHREEjs() function (located in InitCommon.js file)
function initSceneData() 
{
	demoFragmentShaderFileName = 'HDRI_Environment_Fragment.glsl';

	// scene/demo-specific three.js objects setup goes here
	sceneIsDynamic = false;

	// tell the engine that we will use our own custom camera controls
	useGenericInput = false;
	//cameraFlightSpeed = 60;

	// pixelRatio is resolution - range: 0.5(half resolution) to 1.0(full resolution)
	pixelRatio = mouseControl ? 0.75 : 0.7; // less demanding on battery-powered mobile devices
	//pixelRatio = 0.5;

	EPS_intersect = 0.001;

	// set camera's field of view
	worldCamera.fov = 50;
	
	cameraZOffset = 45; // how much the camera will be pulled back from its look-at target
	focusDistance = cameraZOffset;

	cameraControlsPitchObject.rotation.x = 0.252;
	cameraControlsYawObject.rotation.y = 0.5856;

	cameraControlsObject.position.copy(modelPositionOffset);
	cameraControlsObject.position.y += 40;
	
	worldCamera.position.set(0, 0, cameraZOffset);


	rectangleLight0 = new THREE.Object3D();
	rectangleLight1 = new THREE.Object3D();

	pathTracingScene.add(rectangleLight0);
	pathTracingScene.add(rectangleLight1);
	
	total_number_of_triangles = modelMesh.geometry.attributes.position.array.length / 9;
	console.log("Triangle count:" + total_number_of_triangles);

	totalWork = new Uint32Array(total_number_of_triangles);

	triangle_array = new Float32Array(2048 * 2048 * 4);
	// 2048 = width of texture, 2048 = height of texture, 4 = r,g,b, and a components
	
	aabb_array = new Float32Array(2048 * 2048 * 4);
	// 2048 = width of texture, 2048 = height of texture, 4 = r,g,b, and a components

	
	let triangle_b_box_min = new THREE.Vector3();
	let triangle_b_box_max = new THREE.Vector3();
	let triangle_b_box_centroid = new THREE.Vector3();
	
	if (modelMesh.geometry.attributes.normal === undefined)
	{
		modelMesh.geometry.computeVertexNormals();
	}
	
	let vpa = new Float32Array(modelMesh.geometry.attributes.position.array);
	let vna = new Float32Array(modelMesh.geometry.attributes.normal.array);
	let vta = null;
	let modelHasUVs = false;
	if (modelMesh.geometry.attributes.uv !== undefined) 
	{
		vta = new Float32Array(modelMesh.geometry.attributes.uv.array);
		modelHasUVs = true;
	}
		
	let materialNumber = 0;

	for (let i = 0; i < total_number_of_triangles; i++) 
	{
	
		triangle_b_box_min.set(Infinity, Infinity, Infinity);
		triangle_b_box_max.set(-Infinity, -Infinity, -Infinity);

		for (let j = 0; j < pathTracingMaterialList.length; j++) 
		{
			if (i < triangleMaterialMarkers[j]) 
			{
				materialNumber = j;
				break;
			}
		}

		// record vertex texture coordinates (UVs)
		if (modelHasUVs) 
		{
			vt0.set( vta[6 * i + 0], vta[6 * i + 1] );
			vt1.set( vta[6 * i + 2], vta[6 * i + 3] );
			vt2.set( vta[6 * i + 4], vta[6 * i + 5] );
		}
		else 
		{
			vt0.set( -1, -1 );
			vt1.set( -1, -1 );
			vt2.set( -1, -1 );
		}
		
		// record vertex normals
		vn0.set( vna[9 * i + 0], vna[9 * i + 1], vna[9 * i + 2] ).normalize();
		vn1.set( vna[9 * i + 3], vna[9 * i + 4], vna[9 * i + 5] ).normalize();
		vn2.set( vna[9 * i + 6], vna[9 * i + 7], vna[9 * i + 8] ).normalize();
		
		// record vertex positions
		vp0.set( vpa[9 * i + 0], vpa[9 * i + 1], vpa[9 * i + 2] );
		vp1.set( vpa[9 * i + 3], vpa[9 * i + 4], vpa[9 * i + 5] );
		vp2.set( vpa[9 * i + 6], vpa[9 * i + 7], vpa[9 * i + 8] );

		vp0.multiplyScalar(modelScale);
		vp1.multiplyScalar(modelScale);
		vp2.multiplyScalar(modelScale);

		vp0.add(modelPositionOffset);
		vp1.add(modelPositionOffset);
		vp2.add(modelPositionOffset);

		//slot 0
		triangle_array[32 * i +  0] = vp0.x; // r or x
		triangle_array[32 * i +  1] = vp0.y; // g or y 
		triangle_array[32 * i +  2] = vp0.z; // b or z
		triangle_array[32 * i +  3] = vp1.x; // a or w

		//slot 1
		triangle_array[32 * i +  4] = vp1.y; // r or x
		triangle_array[32 * i +  5] = vp1.z; // g or y
		triangle_array[32 * i +  6] = vp2.x; // b or z
		triangle_array[32 * i +  7] = vp2.y; // a or w

		//slot 2
		triangle_array[32 * i +  8] = vp2.z; // r or x
		triangle_array[32 * i +  9] = vn0.x; // g or y
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

		//slot 6
		triangle_array[32 * i + 24] = pathTracingMaterialList[materialNumber].type; // r or x 
		triangle_array[32 * i + 25] = pathTracingMaterialList[materialNumber].color.r; // g or y
		triangle_array[32 * i + 26] = pathTracingMaterialList[materialNumber].color.g; // b or z
		triangle_array[32 * i + 27] = pathTracingMaterialList[materialNumber].color.b; // a or w

		//slot 7
		triangle_array[32 * i + 28] = pathTracingMaterialList[materialNumber].albedoTextureID; // r or x
		triangle_array[32 * i + 29] = 0; // g or y
		triangle_array[32 * i + 30] = 0; // b or z
		triangle_array[32 * i + 31] = 0; // a or w

		triangle_b_box_min.copy(triangle_b_box_min.min(vp0));
		triangle_b_box_max.copy(triangle_b_box_max.max(vp0));
		triangle_b_box_min.copy(triangle_b_box_min.min(vp1));
		triangle_b_box_max.copy(triangle_b_box_max.max(vp1));
		triangle_b_box_min.copy(triangle_b_box_min.min(vp2));
		triangle_b_box_max.copy(triangle_b_box_max.max(vp2));

		triangle_b_box_centroid.copy(triangle_b_box_min).add(triangle_b_box_max).multiplyScalar(0.5);

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
	}


	// Build the BVH acceleration structure, which places a bounding box ('root' of the tree) around all of the 
	// triangles of the entire mesh, then subdivides each box into 2 smaller boxes.  It continues until it reaches 1 triangle,
	// which it then designates as a 'leaf'
	BVH_Build_Iterative(totalWork, aabb_array);
	

	triangleDataTexture = new THREE.DataTexture(triangle_array,
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
		THREE.LinearEncoding);

	triangleDataTexture.flipY = false;
	triangleDataTexture.generateMipmaps = false;
	triangleDataTexture.needsUpdate = true;

	aabbDataTexture = new THREE.DataTexture(aabb_array,
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
		THREE.LinearEncoding);

	aabbDataTexture.flipY = false;
	aabbDataTexture.generateMipmaps = false;
	aabbDataTexture.needsUpdate = true;


	init_GUI();


	// scene/demo-specific uniforms go here
	pathTracingUniforms.tTriangleTexture = { value: triangleDataTexture };
	pathTracingUniforms.tAABBTexture = { value: aabbDataTexture };
	pathTracingUniforms.uLight0_Matrix = { value: new THREE.Matrix4() };
	pathTracingUniforms.uLight1_Matrix = { value: new THREE.Matrix4() };
	pathTracingUniforms.uLight0_InvMatrix = { value: new THREE.Matrix4() };
	pathTracingUniforms.uLight1_InvMatrix = { value: new THREE.Matrix4() };
	pathTracingUniforms.uFogDensity = { value: 0.0 };
	pathTracingUniforms.uLight0Power = { value: 0.0 };
	pathTracingUniforms.uLight1Power = { value: 0.0 };

} // end function initSceneData()




// called automatically from within the animate() function (located in InitCommon.js file)
function updateVariablesAndUniforms()
{


	if ((keyPressed('a') || button1Pressed) && !(keyPressed('d') || button2Pressed))
	{
		cameraControlsObject.position.sub(cameraRightVector.multiplyScalar(cameraFlightSpeed * frameTime));
		cameraIsMoving = true;
	}
	if ((keyPressed('d') || button2Pressed) && !(keyPressed('a') || button1Pressed))
	{
		cameraControlsObject.position.add(cameraRightVector.multiplyScalar(cameraFlightSpeed * frameTime));
		cameraIsMoving = true;
	}
	if (keyPressed('w') && !keyPressed('s'))
	{
		cameraControlsObject.position.add(cameraUpVector.multiplyScalar(cameraFlightSpeed * frameTime));
		cameraIsMoving = true;
	}
	if (keyPressed('s') && !keyPressed('w'))
	{
		cameraControlsObject.position.sub(cameraUpVector.multiplyScalar(cameraFlightSpeed * frameTime));
		cameraIsMoving = true;
	}

	if ((keyPressed('up') || button5Pressed) && !(keyPressed('down') || button6Pressed))
	{
		increaseFocusDist = true;
	}
	if ((keyPressed('down') || button6Pressed) && !(keyPressed('up') || button5Pressed))
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

	if (keyPressed('period') && !keyPressed('comma'))
	{
		increaseFOV = true;
	}
	if (keyPressed('comma') && !keyPressed('period'))
	{
		decreaseFOV = true;
	}
	if (keyPressed('o') && canPress_O)
	{
		changeToOrthographicCamera = true;
		canPress_O = false;
	}
	if (!keyPressed('o'))
		canPress_O = true;

	if (keyPressed('p') && canPress_P)
	{
		changeToPerspectiveCamera = true;
		canPress_P = false;
	}
	if (!keyPressed('p'))
		canPress_P = true;


	if (dollyCameraIn) 
	{
		cameraZOffset -= 1;
		if (cameraZOffset < 0)
			cameraZOffset = 0;
		worldCamera.position.set(0, 0, cameraZOffset);
		cameraIsMoving = true;
		dollyCameraIn = false;
	}
	if (dollyCameraOut) 
	{
		cameraZOffset += 1;
		if (cameraZOffset > 1000)
			cameraZOffset = 1000;
		worldCamera.position.set(0, 0, cameraZOffset);
		cameraIsMoving = true;
		dollyCameraOut = false;
	}
	

	if (needChangeFogDensity) 
	{
		pathTracingUniforms.uFogDensity.value = fog_DensityController.getValue();
		cameraIsMoving = true;
		needChangeFogDensity = false;
	}

	if (needChangeLight0Power) 
	{
		pathTracingUniforms.uLight0Power.value = light0_PowerController.getValue();
		cameraIsMoving = true;
		needChangeLight0Power = false;
	}

	if (needChangeLight1Power) 
	{
		pathTracingUniforms.uLight1Power.value = light1_PowerController.getValue();
		cameraIsMoving = true;
		needChangeLight1Power = false;
	}

	if (needChangeLight0Position) 
	{
		rectangleLight0.position.set(light0_PositionXController.getValue(),
			light0_PositionYController.getValue(),
			light0_PositionZController.getValue());

		cameraIsMoving = true;
		needChangeLight0Position = false;
	}

	if (needChangeLight0Rotation) 
	{
		rectangleLight0.rotation.set(THREE.MathUtils.degToRad(light0_RotationXController.getValue()),
			THREE.MathUtils.degToRad(light0_RotationYController.getValue()),
			THREE.MathUtils.degToRad(light0_RotationZController.getValue()));

		cameraIsMoving = true;
		needChangeLight0Rotation = false;
	}

	if (needChangeLight1Position) 
	{
		rectangleLight1.position.set(light1_PositionXController.getValue(),
			light1_PositionYController.getValue(),
			light1_PositionZController.getValue());

		cameraIsMoving = true;
		needChangeLight1Position = false;
	}

	if (needChangeLight1Rotation) 
	{
		rectangleLight1.rotation.set(THREE.MathUtils.degToRad(light1_RotationXController.getValue()),
			THREE.MathUtils.degToRad(light1_RotationYController.getValue()),
			THREE.MathUtils.degToRad(light1_RotationZController.getValue()));

		cameraIsMoving = true;
		needChangeLight1Rotation = false;
	}

	pathTracingUniforms.uLight0_Matrix.value.copy(rectangleLight0.matrixWorld);
	pathTracingUniforms.uLight0_InvMatrix.value.copy(rectangleLight0.matrixWorld).invert();

	pathTracingUniforms.uLight1_Matrix.value.copy(rectangleLight1.matrixWorld);
	pathTracingUniforms.uLight1_InvMatrix.value.copy(rectangleLight1.matrixWorld).invert();

	// INFO   
	cameraInfoElement.innerHTML = "FOV: " + worldCamera.fov + " / Aperture: " + apertureSize.toFixed(2) +
		" / FocusDistance: " + focusDistance + "<br>" + "Samples: " + sampleCounter;

} // end function updateUniforms()



load_GLTF_Model(); // load model, init app, and start animating
