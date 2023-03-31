// scene/demo-specific variables go here

let doorObject3D;
let paintingTexture;
let increaseDoorAngle = false;
let decreaseDoorAngle = false;
let door_OpenCloseController, door_OpenCloseObject;
let needChangeDoorOpenClose = false;

// triangular model 
let vp0 = new THREE.Vector3(); // vertex positions data
let vp1 = new THREE.Vector3();
let vp2 = new THREE.Vector3();
let vn0 = new THREE.Vector3(); // vertex normals data
let vn1 = new THREE.Vector3();
let vn2 = new THREE.Vector3();
let vt0 = new THREE.Vector2(); // vertex texture-coordinates(UV) data
let vt1 = new THREE.Vector2();
let vt2 = new THREE.Vector2();
let modelMesh;
let modelPositionOffset = new THREE.Vector3();
let modelScale = 1.0;
let meshList = [];
let geoList = [];
let triangleDataTexture;
let aabbDataTexture;
let totalGeometryCount = 0;
let total_number_of_triangles = 0;
let totalWork;
let triangle_array = new Float32Array(2048 * 2048 * 4);
// 2048 = width of texture, 2048 = height of texture, 4 = r,g,b, and a components
let aabb_array = new Float32Array(2048 * 2048 * 4);
// 2048 = width of texture, 2048 = height of texture, 4 = r,g,b, and a components
let triangleMaterialMarkers = [];
let pathTracingMaterialList = [];

// quadric shapes models
let invMatrix = new THREE.Matrix4();
let el; // elements of the invMatrix
let shapes_array;
let shapesDataTexture;
let shapes_aabb_array;
let shapes_aabbDataTexture;
let totalShapesWork;
let shapeBoundingBox_minCorner = new THREE.Vector3();
let shapeBoundingBox_maxCorner = new THREE.Vector3();
let shapeBoundingBox_centroid = new THREE.Vector3();
let boundingBoxMaterial = new THREE.MeshBasicMaterial();
let boundingBoxMeshes = [];
let boundingBoxGeometries = [];
let largestScaleComponent = 1;
let sceneShapeMeshes = [];

let tableGeometry, tableMaterial, tableMesh;
let tableLegGeometry1, tableLegMaterial1, tableLegMesh1;
let tableLegGeometry2, tableLegMaterial2, tableLegMesh2;
let tableLegGeometry3, tableLegMaterial3, tableLegMesh3;
let tableLegGeometry4, tableLegMaterial4, tableLegMesh4;
let tableLegFootGeometry1, tableLegFootMaterial1, tableLegFootMesh1;
let tableLegFootGeometry2, tableLegFootMaterial2, tableLegFootMesh2;
let tableLegFootGeometry3, tableLegFootMaterial3, tableLegFootMesh3;
let tableLegFootGeometry4, tableLegFootMaterial4, tableLegFootMesh4;
let drinkingGlassGeometry1, drinkingGlassMaterial1, drinkingGlassMesh1;
let drinkingGlassGeometry2, drinkingGlassMaterial2, drinkingGlassMesh2;
let glassBottomGeometry1, glassBottomMaterial1, glassBottomMesh1;
let glassBottomGeometry2, glassBottomMaterial2, glassBottomMesh2;
let liquidTopGeometry1, liquidTopMaterial1, liquidTopMesh1;
let liquidTopGeometry2, liquidTopMaterial2, liquidTopMesh2;
let bookshelfTopHorizontalGeometry, bookshelfTopHorizontalMaterial, bookshelfTopHorizontalMesh;
let bookshelfMidHorizontalGeometry, bookshelfMidHorizontalMaterial, bookshelfMidHorizontalMesh;
let bookshelfLowHorizontalGeometry, bookshelfLowHorizontalMaterial, bookshelfLowHorizontalMesh;
let bookshelfLeftVerticalGeometry, bookshelfLeftVerticalMaterial, bookshelfLeftVerticalMesh;
let bookshelfMidVerticalGeometry, bookshelfMidVerticalMaterial, bookshelfMidVerticalMesh;
let bookshelfRightVerticalGeometry, bookshelfRightVerticalMaterial, bookshelfRightVerticalMesh;
let glassSphereGeometry, glassSphereMaterial, glassSphereMesh;
let blueBookGeometry, blueBookMaterial, blueBookMesh;
let orangeBookGeometry, orangeBookMaterial, orangeBookMesh;
let yellowBookGeometry, yellowBookMaterial, yellowBookMesh;
let glassCandleHolderGeometry1, glassCandleHolderMaterial1, glassCandleHolderMesh1;
let glassCandleHolderGeometry2, glassCandleHolderMaterial2, glassCandleHolderMesh2;
let candleGeometry1, candleMaterial1, candleMesh1;
let candleGeometry2, candleMaterial2, candleMesh2;
let candleTopGeometry1, candleTopMaterial1, candleTopMesh1;
let candleTopGeometry2, candleTopMaterial2, candleTopMesh2;
let candleWickGeometry1, candleWickMaterial1, candleWickMesh1;
let candleWickGeometry2, candleWickMaterial2, candleWickMesh2;
let floorLampBaseGeometry1, floorLampBaseMaterial1, floorLampBaseMesh1;
let floorLampBaseGeometry2, floorLampBaseMaterial2, floorLampBaseMesh2;
let floorLampPoleGeometry1, floorLampPoleMaterial1, floorLampPoleMesh1;
let floorLampPoleGeometry2, floorLampPoleMaterial2, floorLampPoleMesh2;
let floorLampShadeGeometry1, floorLampShadeMaterial1, floorLampShadeMesh1;
let floorLampShadeGeometry2, floorLampShadeMaterial2, floorLampShadeMesh2;
let couchBottomFrameGeometry, couchBottomFrameMaterial, couchBottomFrameMesh;
let couchFootGeometry1, couchFootMaterial1, couchFootMesh1;
let couchFootGeometry2, couchFootMaterial2, couchFootMesh2;
let couchFootGeometry3, couchFootMaterial3, couchFootMesh3;
let couchFootGeometry4, couchFootMaterial4, couchFootMesh4;
let couchSeatGeometry, couchSeatMaterial, couchSeatMesh;
let couchLeftSideGeometry, couchLeftSideMaterial, couchLeftSideMesh;
let couchRightSideGeometry, couchRightSideMaterial, couchRightSideMesh;
let couchBackGeometry, couchBackMaterial, couchBackMesh;
let couchLeftArmGeometry, couchLeftArmMaterial, couchLeftArmMesh;
let couchRightArmGeometry, couchRightArmMaterial, couchRightArmMesh;
let couchBackTopGeometry, couchBackTopMaterial, couchBackTopMesh;
let couchLeftArmCapGeometry, couchLeftArmCapMaterial, couchLeftArmCapMesh;
let couchRightArmCapGeometry, couchRightArmCapMaterial, couchRightArmCapMesh;
let redPillowGeometry, redPillowMaterial, redPillowMesh;



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

	let gltfLoader = new GLTFLoader();

	gltfLoader.load("models/UtahTeapot.glb", function (meshGroup)
	{ // Triangles: 992

		if (meshGroup.scene)
			meshGroup = meshGroup.scene;

		meshGroup.traverse(function (child)
		{

			if (child.isMesh)
			{
				let mat = new MaterialObject();
				mat.type = 1;
				mat.albedoTextureID = -1;
				mat.color = child.material.color;
				mat.roughness = child.material.roughness || 0.0;
				mat.metalness = child.material.metalness || 0.0;
				mat.opacity = child.material.opacity || 1.0;
				mat.refractiveIndex = 1.0;
				pathTracingMaterialList.push(mat);
				triangleMaterialMarkers.push(child.geometry.attributes.position.array.length / 9);
				meshList.push(child);
			}
		});

		modelMesh = meshList[0].clone();

		for (let i = 0; i < meshList.length; i++)
		{
			geoList.push(meshList[i].geometry);
		}

		modelMesh.geometry = mergeGeometries(geoList);

		if (modelMesh.geometry.index)
			modelMesh.geometry = modelMesh.geometry.toNonIndexed();

		modelMesh.geometry.center();

		/* // settings for UtahTeapot model
		modelScale = 0.75;
		modelPositionOffset.set(0, 20, -20); */

		// now that the model has loaded, we can init
		init();

	}); // end gltfLoader.load()

} // end function load_GLTF_Model()


// called automatically from within initTHREEjs() function (located in InitCommon.js file)
function initSceneData() 
{
	demoFragmentShaderFileName = 'Invisible_Date_Fragment.glsl';

	// scene/demo-specific three.js objects setup goes here
	sceneIsDynamic = false;

	cameraFlightSpeed = 100;

	// pixelRatio is resolution - range: 0.5(half resolution) to 1.0(full resolution)
	pixelRatio = mouseControl ? 0.75 : 0.75;

	EPS_intersect = 0.01;

	// set camera's field of view
	worldCamera.fov = 50;
	focusDistance = 135;
	apertureChangeSpeed = 5;


	// position and orient camera
	cameraControlsObject.position.set(8, 59, 86);
	cameraControlsYawObject.rotation.y = 0.4597;
	// look slightly downward
	cameraControlsPitchObject.rotation.x = -0.13;

	// scale and place Utah teapot glTF model 
	modelMesh.scale.set(0.5, 0.5, 0.5);
	modelMesh.rotation.set(0, Math.PI, -0.5);
	modelMesh.position.set(0, 30, -50);
	modelMesh.updateMatrixWorld(true); // 'true' forces immediate matrix update

	// In addition to the default GUI on all demos, add any special GUI elements that this particular demo requires
	door_OpenCloseObject = {
		Door_Open_Close: 6.0
	}
	function handleDoorOpenCloseChange() 
	{
		needChangeDoorOpenClose = true;
	}

	door_OpenCloseController = gui.add(door_OpenCloseObject, 'Door_Open_Close', 3.27, 6.28, 0.01).onChange(handleDoorOpenCloseChange);



	// Door object
	doorObject3D = new THREE.Object3D();
	pathTracingScene.add(doorObject3D);
	// doorObject3D is just a data placeholder as well as an Object3D that can be transformed/manipulated by 
	// using familiar Three.js library commands. It is then fed into the GPU path tracing renderer
	// through its 'matrixWorld' matrix.
	doorObject3D.position.set(-101, 40, 60);
	doorObject3D.updateMatrixWorld(true); // 'true' forces immediate matrix update

	// jumpstart initial door rotation
	handleDoorOpenCloseChange();



	total_number_of_triangles = modelMesh.geometry.attributes.position.array.length / 9;
	console.log("Triangle count:" + (total_number_of_triangles));

	totalWork = new Uint32Array(total_number_of_triangles);

	let triangle_b_box_min = new THREE.Vector3();
	let triangle_b_box_max = new THREE.Vector3();
	let triangle_b_box_centroid = new THREE.Vector3();


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
	let ix32, ix9;

	for (let i = 0; i < total_number_of_triangles; i++)
	{
		ix32 = i * 32;
		ix9 = i * 9;

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
			vt0.set(vta[6 * i + 0], vta[6 * i + 1]);
			vt1.set(vta[6 * i + 2], vta[6 * i + 3]);
			vt2.set(vta[6 * i + 4], vta[6 * i + 5]);
		}
		else
		{
			vt0.set(-1, -1);
			vt1.set(-1, -1);
			vt2.set(-1, -1);
		}

		// record vertex normals
		vn0.set(vna[ix9 + 0], vna[ix9 + 1], vna[ix9 + 2]).normalize();
		vn1.set(vna[ix9 + 3], vna[ix9 + 4], vna[ix9 + 5]).normalize();
		vn2.set(vna[ix9 + 6], vna[ix9 + 7], vna[ix9 + 8]).normalize();

		// record vertex positions
		vp0.set(vpa[ix9 + 0], vpa[ix9 + 1], vpa[ix9 + 2]);
		vp1.set(vpa[ix9 + 3], vpa[ix9 + 4], vpa[ix9 + 5]);
		vp2.set(vpa[ix9 + 6], vpa[ix9 + 7], vpa[ix9 + 8]);

		vp0.multiplyScalar(modelScale);
		vp1.multiplyScalar(modelScale);
		vp2.multiplyScalar(modelScale);

		vp0.add(modelPositionOffset);
		vp1.add(modelPositionOffset);
		vp2.add(modelPositionOffset);

		//slot 0
		triangle_array[ix32 + 0] = vp0.x; // r or x
		triangle_array[ix32 + 1] = vp0.y; // g or y 
		triangle_array[ix32 + 2] = vp0.z; // b or z
		triangle_array[ix32 + 3] = vp1.x; // a or w

		//slot 1
		triangle_array[ix32 + 4] = vp1.y; // r or x
		triangle_array[ix32 + 5] = vp1.z; // g or y
		triangle_array[ix32 + 6] = vp2.x; // b or z
		triangle_array[ix32 + 7] = vp2.y; // a or w

		//slot 2
		triangle_array[ix32 + 8] = vp2.z; // r or x
		triangle_array[ix32 + 9] = vn0.x; // g or y
		triangle_array[ix32 + 10] = vn0.y; // b or z
		triangle_array[ix32 + 11] = vn0.z; // a or w

		//slot 3
		triangle_array[ix32 + 12] = vn1.x; // r or x
		triangle_array[ix32 + 13] = vn1.y; // g or y
		triangle_array[ix32 + 14] = vn1.z; // b or z
		triangle_array[ix32 + 15] = vn2.x; // a or w

		//slot 4
		triangle_array[ix32 + 16] = vn2.y; // r or x
		triangle_array[ix32 + 17] = vn2.z; // g or y
		triangle_array[ix32 + 18] = vt0.x; // b or z
		triangle_array[ix32 + 19] = vt0.y; // a or w

		//slot 5
		triangle_array[ix32 + 20] = vt1.x; // r or x
		triangle_array[ix32 + 21] = vt1.y; // g or y
		triangle_array[ix32 + 22] = vt2.x; // b or z
		triangle_array[ix32 + 23] = vt2.y; // a or w

		// the remaining slots are used for PBR material properties

		//slot 6
		triangle_array[ix32 + 24] = pathTracingMaterialList[materialNumber].type; // r or x 
		triangle_array[ix32 + 25] = pathTracingMaterialList[materialNumber].color.r; // g or y
		triangle_array[ix32 + 26] = pathTracingMaterialList[materialNumber].color.g; // b or z
		triangle_array[ix32 + 27] = pathTracingMaterialList[materialNumber].color.b; // a or w

		//slot 7
		triangle_array[ix32 + 28] = pathTracingMaterialList[materialNumber].albedoTextureID; // r or x
		triangle_array[ix32 + 29] = 0.0; // g or y
		triangle_array[ix32 + 30] = 0; // b or z
		triangle_array[ix32 + 31] = 0; // a or w

		triangle_b_box_min.copy(triangle_b_box_min.min(vp0));
		triangle_b_box_max.copy(triangle_b_box_max.max(vp0));
		triangle_b_box_min.copy(triangle_b_box_min.min(vp1));
		triangle_b_box_max.copy(triangle_b_box_max.max(vp1));
		triangle_b_box_min.copy(triangle_b_box_min.min(vp2));
		triangle_b_box_max.copy(triangle_b_box_max.max(vp2));

		triangle_b_box_centroid.copy(triangle_b_box_min).add(triangle_b_box_max).multiplyScalar(0.5);

		aabb_array[ix9 + 0] = triangle_b_box_min.x;
		aabb_array[ix9 + 1] = triangle_b_box_min.y;
		aabb_array[ix9 + 2] = triangle_b_box_min.z;
		aabb_array[ix9 + 3] = triangle_b_box_max.x;
		aabb_array[ix9 + 4] = triangle_b_box_max.y;
		aabb_array[ix9 + 5] = triangle_b_box_max.z;
		aabb_array[ix9 + 6] = triangle_b_box_centroid.x;
		aabb_array[ix9 + 7] = triangle_b_box_centroid.y;
		aabb_array[ix9 + 8] = triangle_b_box_centroid.z;

		totalWork[i] = i;
	}



	console.time("BvhGeneration");
	console.log("BvhGeneration...");

	// Build the BVH acceleration structure, which places a bounding box ('root' of the tree) around all of the
	// triangles of the entire mesh, then subdivides each box into 2 smaller boxes.  It continues until it reaches 1 triangle,
	// which it then designates as a 'leaf'
	BVH_Build_Iterative(totalWork, aabb_array);
	//console.log(buildnodes);

	console.timeEnd("BvhGeneration");


	triangleDataTexture = new THREE.DataTexture(
		triangle_array,
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


	aabbDataTexture = new THREE.DataTexture(
		aabb_array,
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



	// SHAPES

	// glass coffee table top
	tableGeometry = new THREE.BoxGeometry();
	tableMaterial = new THREE.MeshPhysicalMaterial({
		color: new THREE.Color(0.1, 0.8, 1.0), // (r,g,b) range: 0.0 to 1.0 / default is rgb(1,1,1) white
		opacity: 0.0, // range: 0.0 to 1.0 / default is 1.0 (fully opaque)
		ior: 1.5, // range: 1.0(air) to 2.33(diamond) / default is 1.5(glass) / other useful ior is 1.33(water)
		clearcoat: 0.0, // range: 0.0 to 1.0 / default is 0.0 (no clearcoat)
		metalness: 0.0, // range: either 0.0 or 1.0 / default is 0.0 (not metal)
		roughness: 0.0 // range: 0.0 to 1.0 / default is 0.0 (no roughness, perfectly smooth)
	});
	tableMesh = new THREE.Mesh(tableGeometry, tableMaterial);
	tableMesh.scale.set(13, 0.3, 12);
	tableMesh.position.set(-10, 20, -50);
	sceneShapeMeshes.push(tableMesh);

	// coffee table metal Legs
	tableLegGeometry1 = new THREE.BoxGeometry();
	tableLegMaterial1 = new THREE.MeshPhysicalMaterial({ color: new THREE.Color(1.0, 1.0, 1.0), metalness: 1.0, roughness: 0.2 });
	tableLegMesh1 = new THREE.Mesh(tableLegGeometry1, tableLegMaterial1);
	tableLegMesh1.scale.set(0.5, 10, 0.5);
	tableLegMesh1.position.set(-19, 10, -58);
	sceneShapeMeshes.push(tableLegMesh1);

	tableLegGeometry2 = new THREE.BoxGeometry();
	tableLegMaterial2 = new THREE.MeshPhysicalMaterial({ color: new THREE.Color(1.0, 1.0, 1.0), metalness: 1.0, roughness: 0.2 });
	tableLegMesh2 = new THREE.Mesh(tableLegGeometry2, tableLegMaterial2);
	tableLegMesh2.scale.set(0.5, 10, 0.5);
	tableLegMesh2.position.set(-1, 10, -58);
	sceneShapeMeshes.push(tableLegMesh2);

	tableLegGeometry3 = new THREE.BoxGeometry();
	tableLegMaterial3 = new THREE.MeshPhysicalMaterial({ color: new THREE.Color(1.0, 1.0, 1.0), metalness: 1.0, roughness: 0.2 });
	tableLegMesh3 = new THREE.Mesh(tableLegGeometry3, tableLegMaterial3);
	tableLegMesh3.scale.set(0.5, 10, 0.5);
	tableLegMesh3.position.set(-1, 10, -42);
	sceneShapeMeshes.push(tableLegMesh3);

	tableLegGeometry4 = new THREE.BoxGeometry();
	tableLegMaterial4 = new THREE.MeshPhysicalMaterial({ color: new THREE.Color(1.0, 1.0, 1.0), metalness: 1.0, roughness: 0.2 });
	tableLegMesh4 = new THREE.Mesh(tableLegGeometry4, tableLegMaterial4);
	tableLegMesh4.scale.set(0.5, 10, 0.5);
	tableLegMesh4.position.set(-19, 10, -42);
	sceneShapeMeshes.push(tableLegMesh4);

	// coffee table Leg feet
	tableLegFootGeometry1 = new THREE.BoxGeometry();
	tableLegFootMaterial1 = new THREE.MeshPhysicalMaterial({ color: new THREE.Color(0.0, 0.0, 0.0) });
	tableLegFootMesh1 = new THREE.Mesh(tableLegFootGeometry1, tableLegFootMaterial1);
	tableLegFootMesh1.scale.set(0.75, 0.2, 0.75);
	tableLegFootMesh1.position.set(-19, 0.2, -58);
	sceneShapeMeshes.push(tableLegFootMesh1);

	tableLegFootGeometry2 = new THREE.BoxGeometry();
	tableLegFootMaterial2 = new THREE.MeshPhysicalMaterial({ color: new THREE.Color(0.0, 0.0, 0.0) });
	tableLegFootMesh2 = new THREE.Mesh(tableLegFootGeometry2, tableLegFootMaterial2);
	tableLegFootMesh2.scale.set(0.75, 0.2, 0.75);
	tableLegFootMesh2.position.set(-1, 0.2, -58);
	sceneShapeMeshes.push(tableLegFootMesh2);

	tableLegFootGeometry3 = new THREE.BoxGeometry();
	tableLegFootMaterial3 = new THREE.MeshPhysicalMaterial({ color: new THREE.Color(0.0, 0.0, 0.0) });
	tableLegFootMesh3 = new THREE.Mesh(tableLegFootGeometry3, tableLegFootMaterial3);
	tableLegFootMesh3.scale.set(0.75, 0.2, 0.75);
	tableLegFootMesh3.position.set(-1, 0.2, -42);
	sceneShapeMeshes.push(tableLegFootMesh3);

	tableLegFootGeometry4 = new THREE.BoxGeometry();
	tableLegFootMaterial4 = new THREE.MeshPhysicalMaterial({ color: new THREE.Color(0.0, 0.0, 0.0) });
	tableLegFootMesh4 = new THREE.Mesh(tableLegFootGeometry4, tableLegFootMaterial4);
	tableLegFootMesh4.scale.set(0.75, 0.2, 0.75);
	tableLegFootMesh4.position.set(-19, 0.2, -42);
	sceneShapeMeshes.push(tableLegFootMesh4);

	// drinking glasses
	drinkingGlassGeometry1 = new THREE.CylinderGeometry();
	drinkingGlassMaterial1 = new THREE.MeshPhysicalMaterial({ color: new THREE.Color(0.0, 3.0, 2.0), opacity: 0.0, ior: 1.5 });
	drinkingGlassMesh1 = new THREE.Mesh(drinkingGlassGeometry1, drinkingGlassMaterial1);
	drinkingGlassMesh1.scale.set(1.1, 3.25, 1.1);
	//position(-10, 20, -40); // coffee table
	drinkingGlassMesh1.position.set(-14, 23.55, -54);
	sceneShapeMeshes.push(drinkingGlassMesh1);

	drinkingGlassGeometry2 = new THREE.CylinderGeometry();
	drinkingGlassMaterial2 = new THREE.MeshPhysicalMaterial({ color: new THREE.Color(0.0, 3.0, 2.0), opacity: 0.0, ior: 1.5 });
	drinkingGlassMesh2 = new THREE.Mesh(drinkingGlassGeometry2, drinkingGlassMaterial2);
	drinkingGlassMesh2.scale.set(1.1, 3.25, 1.1);
	//position(-10, 20, -40); // coffee table
	drinkingGlassMesh2.position.set(-9, 23.55, -50);
	sceneShapeMeshes.push(drinkingGlassMesh2);

	// glass bottom of drinking glasses
	glassBottomGeometry1 = new THREE.SphereGeometry();
	glassBottomMaterial1 = new THREE.MeshPhysicalMaterial({ color: new THREE.Color(0.0, 3.0, 2.0), opacity: 0.0, ior: 1.5 });
	glassBottomMesh1 = new THREE.Mesh(glassBottomGeometry1, glassBottomMaterial1);
	glassBottomMesh1.scale.set(1.25, 0.5, 1.25);
	glassBottomMesh1.position.set(-14, 20.8, -54);
	sceneShapeMeshes.push(glassBottomMesh1);

	glassBottomGeometry2 = new THREE.SphereGeometry();
	glassBottomMaterial2 = new THREE.MeshPhysicalMaterial({ color: new THREE.Color(0.0, 3.0, 2.0), opacity: 0.0, ior: 1.5 });
	glassBottomMesh2 = new THREE.Mesh(glassBottomGeometry2, glassBottomMaterial2);
	glassBottomMesh2.scale.set(1.25, 0.5, 1.25);
	glassBottomMesh2.position.set(-9, 20.8, -50);
	sceneShapeMeshes.push(glassBottomMesh2);

	// liquid top inside drinking glasses
	liquidTopGeometry1 = new THREE.SphereGeometry();
	liquidTopMaterial1 = new THREE.MeshPhysicalMaterial({ color: new THREE.Color(1.0, 1.0, 1.0), opacity: 0.0, ior: 1.33 });
	liquidTopMesh1 = new THREE.Mesh(liquidTopGeometry1, liquidTopMaterial1);
	liquidTopMesh1.scale.set(1.0, 0.1, 1.0);
	liquidTopMesh1.position.set(-14, 24.5, -54);
	sceneShapeMeshes.push(liquidTopMesh1);

	liquidTopGeometry2 = new THREE.SphereGeometry();
	liquidTopMaterial2 = new THREE.MeshPhysicalMaterial({ color: new THREE.Color(1.0, 1.0, 1.0), opacity: 0.0, ior: 1.33 });
	liquidTopMesh2 = new THREE.Mesh(liquidTopGeometry2, liquidTopMaterial2);
	liquidTopMesh2.scale.set(1.0, 0.1, 1.0);
	liquidTopMesh2.position.set(-9, 22.5, -50);
	sceneShapeMeshes.push(liquidTopMesh2);

	// bookshelf
	bookshelfTopHorizontalGeometry = new THREE.BoxGeometry();
	bookshelfTopHorizontalMaterial = new THREE.MeshPhysicalMaterial({ color: new THREE.Color(0.1, 0.1, 0.1) });
	bookshelfTopHorizontalMesh = new THREE.Mesh(bookshelfTopHorizontalGeometry, bookshelfTopHorizontalMaterial);
	bookshelfTopHorizontalMesh.scale.set(6, 0.5, 28);
	bookshelfTopHorizontalMesh.position.set(-93, 36, -30);
	sceneShapeMeshes.push(bookshelfTopHorizontalMesh);

	bookshelfMidHorizontalGeometry = new THREE.BoxGeometry();
	bookshelfMidHorizontalMaterial = new THREE.MeshPhysicalMaterial({ color: new THREE.Color(0.1, 0.1, 0.1) });
	bookshelfMidHorizontalMesh = new THREE.Mesh(bookshelfMidHorizontalGeometry, bookshelfMidHorizontalMaterial);
	bookshelfMidHorizontalMesh.scale.set(6, 0.5, 28);
	bookshelfMidHorizontalMesh.position.set(-93, 23, -30);
	sceneShapeMeshes.push(bookshelfMidHorizontalMesh);

	bookshelfLowHorizontalGeometry = new THREE.BoxGeometry();
	bookshelfLowHorizontalMaterial = new THREE.MeshPhysicalMaterial({ color: new THREE.Color(0.1, 0.1, 0.1) });
	bookshelfLowHorizontalMesh = new THREE.Mesh(bookshelfLowHorizontalGeometry, bookshelfLowHorizontalMaterial);
	bookshelfLowHorizontalMesh.scale.set(6, 0.5, 28);
	bookshelfLowHorizontalMesh.position.set(-93, 10, -30);
	sceneShapeMeshes.push(bookshelfLowHorizontalMesh);

	bookshelfLeftVerticalGeometry = new THREE.BoxGeometry();
	bookshelfLeftVerticalMaterial = new THREE.MeshPhysicalMaterial({ color: new THREE.Color(0.1, 0.1, 0.1) });
	bookshelfLeftVerticalMesh = new THREE.Mesh(bookshelfLeftVerticalGeometry, bookshelfLeftVerticalMaterial);
	bookshelfLeftVerticalMesh.scale.set(5, 19.5, 0.5);
	bookshelfLeftVerticalMesh.position.set(-93, 19.5, -4);
	sceneShapeMeshes.push(bookshelfLeftVerticalMesh);

	bookshelfMidVerticalGeometry = new THREE.BoxGeometry();
	bookshelfMidVerticalMaterial = new THREE.MeshPhysicalMaterial({ color: new THREE.Color(0.1, 0.1, 0.1) });
	bookshelfMidVerticalMesh = new THREE.Mesh(bookshelfMidVerticalGeometry, bookshelfMidVerticalMaterial);
	bookshelfMidVerticalMesh.scale.set(5, 19.5, 0.5);
	bookshelfMidVerticalMesh.position.set(-93, 19.5, -30);
	sceneShapeMeshes.push(bookshelfMidVerticalMesh);

	bookshelfRightVerticalGeometry = new THREE.BoxGeometry();
	bookshelfRightVerticalMaterial = new THREE.MeshPhysicalMaterial({ color: new THREE.Color(0.1, 0.1, 0.1) });
	bookshelfRightVerticalMesh = new THREE.Mesh(bookshelfRightVerticalGeometry, bookshelfRightVerticalMaterial);
	bookshelfRightVerticalMesh.scale.set(5, 19.5, 0.5);
	bookshelfRightVerticalMesh.position.set(-93, 19.5, -56);
	sceneShapeMeshes.push(bookshelfRightVerticalMesh);

	// large glass sphere on top of bookshelf
	glassSphereGeometry = new THREE.SphereGeometry();
	glassSphereMaterial = new THREE.MeshPhysicalMaterial({ color: new THREE.Color(0.0, 1.0, 1.0), opacity: 0.0, ior: 1.5 });
	glassSphereMesh = new THREE.Mesh(glassSphereGeometry, glassSphereMaterial);
	glassSphereMesh.scale.set(6, 6, 6);
	glassSphereMesh.position.set(-93, 42, -11);
	sceneShapeMeshes.push(glassSphereMesh);

	// 3 books on bookshelf
	blueBookGeometry = new THREE.BoxGeometry();
	blueBookMaterial = new THREE.MeshPhysicalMaterial({ color: new THREE.Color(0.0, 0.3, 1.0) });
	blueBookMesh = new THREE.Mesh(blueBookGeometry, blueBookMaterial);
	blueBookMesh.scale.set(4.5, 4, 1);
	blueBookMesh.position.set(-93, 14, -49.5);
	sceneShapeMeshes.push(blueBookMesh);

	orangeBookGeometry = new THREE.BoxGeometry();
	orangeBookMaterial = new THREE.MeshPhysicalMaterial({ color: new THREE.Color(1.0, 0.2, 0.0) });
	orangeBookMesh = new THREE.Mesh(orangeBookGeometry, orangeBookMaterial);
	orangeBookMesh.scale.set(4.5, 5, 1);
	orangeBookMesh.position.set(-93, 15, -52);
	sceneShapeMeshes.push(orangeBookMesh);

	yellowBookGeometry = new THREE.BoxGeometry();
	yellowBookMaterial = new THREE.MeshPhysicalMaterial({ color: new THREE.Color(1.0, 1.0, 0.0) });
	yellowBookMesh = new THREE.Mesh(yellowBookGeometry, yellowBookMaterial);
	yellowBookMesh.scale.set(4.5, 5.5, 0.5);
	yellowBookMesh.position.set(-93, 15.5, -54);
	sceneShapeMeshes.push(yellowBookMesh);

	// glass candlestick holders on top of bookshelf
	glassCandleHolderGeometry1 = new THREE.SphereGeometry();
	glassCandleHolderMaterial1 = new THREE.MeshPhysicalMaterial({ color: new THREE.Color(1.0, 1.0, 1.0), opacity: 0.0, ior: 1.5 });
	glassCandleHolderMesh1 = new THREE.Mesh(glassCandleHolderGeometry1, glassCandleHolderMaterial1);
	glassCandleHolderMesh1.scale.set(3, 1.5, 3);
	glassCandleHolderMesh1.position.set(-92, 38, -38);
	sceneShapeMeshes.push(glassCandleHolderMesh1);

	glassCandleHolderGeometry2 = new THREE.SphereGeometry();
	glassCandleHolderMaterial2 = new THREE.MeshPhysicalMaterial({ color: new THREE.Color(1.0, 1.0, 1.0), opacity: 0.0, ior: 1.5 });
	glassCandleHolderMesh2 = new THREE.Mesh(glassCandleHolderGeometry2, glassCandleHolderMaterial2);
	glassCandleHolderMesh2.scale.set(3.5, 2, 3.5);
	glassCandleHolderMesh2.position.set(-93, 38, -46);
	sceneShapeMeshes.push(glassCandleHolderMesh2);

	// red candle sticks on top of bookshelf
	candleGeometry1 = new THREE.CylinderGeometry();
	candleMaterial1 = new THREE.MeshPhysicalMaterial({ color: new THREE.Color(1.0, 0.0, 0.0), clearcoat: 1.0 });
	candleMesh1 = new THREE.Mesh(candleGeometry1, candleMaterial1);
	candleMesh1.scale.set(0.5, 4, 0.5);
	candleMesh1.position.set(-92, 42, -38);
	sceneShapeMeshes.push(candleMesh1);

	candleGeometry2 = new THREE.CylinderGeometry();
	candleMaterial2 = new THREE.MeshPhysicalMaterial({ color: new THREE.Color(1.0, 0.0, 0.0), clearcoat: 1.0 });
	candleMesh2 = new THREE.Mesh(candleGeometry2, candleMaterial2);
	candleMesh2.scale.set(0.5, 5.5, 0.5);
	candleMesh2.position.set(-93, 43.5, -46);
	sceneShapeMeshes.push(candleMesh2);

	// the tops (flattened spheres) of the 2 red candle sticks
	candleTopGeometry1 = new THREE.SphereGeometry();
	candleTopMaterial1 = new THREE.MeshPhysicalMaterial({ color: new THREE.Color(1.0, 0.0, 0.0), clearcoat: 1.0 });
	candleTopMesh1 = new THREE.Mesh(candleTopGeometry1, candleTopMaterial1);
	candleTopMesh1.scale.set(0.5, 0.2, 0.5);
	candleTopMesh1.position.set(-92, 46, -38);
	sceneShapeMeshes.push(candleTopMesh1);

	candleTopGeometry2 = new THREE.SphereGeometry();
	candleTopMaterial2 = new THREE.MeshPhysicalMaterial({ color: new THREE.Color(1.0, 0.0, 0.0), clearcoat: 1.0 });
	candleTopMesh2 = new THREE.Mesh(candleTopGeometry2, candleTopMaterial2);
	candleTopMesh2.scale.set(0.5, 0.2, 0.5);
	candleTopMesh2.position.set(-93, 49, -46);
	sceneShapeMeshes.push(candleTopMesh2);

	// the wicks for the 2 red candle sticks
	candleWickGeometry1 = new THREE.CylinderGeometry();
	candleWickMaterial1 = new THREE.MeshPhysicalMaterial({ color: new THREE.Color(0.0, 0.0, 0.0) });
	candleWickMesh1 = new THREE.Mesh(candleWickGeometry1, candleWickMaterial1);
	candleWickMesh1.scale.set(0.075, 0.5, 0.075);
	candleWickMesh1.position.set(-92, 46.25, -38);
	sceneShapeMeshes.push(candleWickMesh1);

	candleWickGeometry2 = new THREE.CylinderGeometry();
	candleWickMaterial2 = new THREE.MeshPhysicalMaterial({ color: new THREE.Color(0.0, 0.0, 0.0) });
	candleWickMesh2 = new THREE.Mesh(candleWickGeometry2, candleWickMaterial2);
	candleWickMesh2.scale.set(0.075, 0.5, 0.075);
	candleWickMesh2.position.set(-93, 49.25, -46);
	sceneShapeMeshes.push(candleWickMesh2);

	// the 2 floor lamps' bases
	floorLampBaseGeometry1 = new THREE.BoxGeometry();
	floorLampBaseMaterial1 = new THREE.MeshPhysicalMaterial({ color: new THREE.Color(0.2, 0.2, 0.2), metalness: 1.0, roughness: 0.2 });
	floorLampBaseMesh1 = new THREE.Mesh(floorLampBaseGeometry1, floorLampBaseMaterial1);
	floorLampBaseMesh1.scale.set(4, 0.5, 4);
	floorLampBaseMesh1.position.set(20, 0.5, -80);
	sceneShapeMeshes.push(floorLampBaseMesh1);

	floorLampBaseGeometry2 = new THREE.BoxGeometry();
	floorLampBaseMaterial2 = new THREE.MeshPhysicalMaterial({ color: new THREE.Color(0.2, 0.2, 0.2), metalness: 1.0, roughness: 0.2 });
	floorLampBaseMesh2 = new THREE.Mesh(floorLampBaseGeometry2, floorLampBaseMaterial2);
	floorLampBaseMesh2.scale.set(6, 0.5, 6);
	floorLampBaseMesh2.position.set(33, 0.5, -85);
	sceneShapeMeshes.push(floorLampBaseMesh2);

	// the 2 floor lamps' poles
	floorLampPoleGeometry1 = new THREE.BoxGeometry();
	floorLampPoleMaterial1 = new THREE.MeshPhysicalMaterial({ color: new THREE.Color(0.2, 0.2, 0.2), metalness: 1.0, roughness: 0.2 });
	floorLampPoleMesh1 = new THREE.Mesh(floorLampPoleGeometry1, floorLampPoleMaterial1);
	floorLampPoleMesh1.scale.set(0.7, 26, 0.7);
	floorLampPoleMesh1.position.set(20, 27, -80);
	sceneShapeMeshes.push(floorLampPoleMesh1);

	floorLampPoleGeometry2 = new THREE.BoxGeometry();
	floorLampPoleMaterial2 = new THREE.MeshPhysicalMaterial({ color: new THREE.Color(0.2, 0.2, 0.2), metalness: 1.0, roughness: 0.2 });
	floorLampPoleMesh2 = new THREE.Mesh(floorLampPoleGeometry2, floorLampPoleMaterial2);
	floorLampPoleMesh2.scale.set(0.7, 31, 0.7);
	floorLampPoleMesh2.position.set(33, 32, -85);
	sceneShapeMeshes.push(floorLampPoleMesh2);

	// the 2 floor lamps' shades
	floorLampShadeGeometry1 = new THREE.ConeGeometry();
	floorLampShadeMaterial1 = new THREE.MeshPhysicalMaterial({ color: new THREE.Color(0.2, 0.2, 0.2), metalness: 1.0, roughness: 0.2 });
	floorLampShadeMesh1 = new THREE.Mesh(floorLampShadeGeometry1, floorLampShadeMaterial1);
	floorLampShadeMesh1.scale.set(5, 2.5, 5);
	floorLampShadeMesh1.rotation.set(0, 0, Math.PI);
	floorLampShadeMesh1.position.set(20, 53.5, -80);
	sceneShapeMeshes.push(floorLampShadeMesh1);

	floorLampShadeGeometry2 = new THREE.ConeGeometry();
	floorLampShadeMaterial2 = new THREE.MeshPhysicalMaterial({ color: new THREE.Color(0.2, 0.2, 0.2), metalness: 1.0, roughness: 0.2 });
	floorLampShadeMesh2 = new THREE.Mesh(floorLampShadeGeometry2, floorLampShadeMaterial2);
	floorLampShadeMesh2.scale.set(7, 3, 7);
	floorLampShadeMesh2.rotation.set(0, 0, Math.PI);
	floorLampShadeMesh2.position.set(33, 65, -85);
	sceneShapeMeshes.push(floorLampShadeMesh2);

	// couch bottom metal frame
	couchBottomFrameGeometry = new THREE.BoxGeometry();
	couchBottomFrameMaterial = new THREE.MeshPhysicalMaterial({ color: new THREE.Color(1.0, 1.0, 1.0), metalness: 1.0, roughness: 0.2 });
	couchBottomFrameMesh = new THREE.Mesh(couchBottomFrameGeometry, couchBottomFrameMaterial);
	//couchSeatMesh.scale(31, 3, 12);
	//couchSeatMesh.position(-25, 13, -84);
	couchBottomFrameMesh.scale.set(32, 1, 11);
	couchBottomFrameMesh.position.set(-25, 9, -84);
	sceneShapeMeshes.push(couchBottomFrameMesh);

	// couch metal feet
	//couchBottomFrameMesh.scale(30, 1, 11); // for reference
	//couchBottomFrameMesh.position(-25, 9, -84); // for reference
	couchFootGeometry1 = new THREE.BoxGeometry();
	couchFootMaterial1 = new THREE.MeshPhysicalMaterial({ color: new THREE.Color(1.0, 1.0, 1.0), metalness: 1.0, roughness: 0.2 });
	couchFootMesh1 = new THREE.Mesh(couchFootGeometry1, couchFootMaterial1);
	couchFootMesh1.scale.set(0.4, 4, 0.4);
	couchFootMesh1.rotation.set(0, 0, -0.1);
	couchFootMesh1.position.set(-52, 4, -74);
	sceneShapeMeshes.push(couchFootMesh1);

	couchFootGeometry2 = new THREE.BoxGeometry();
	couchFootMaterial2 = new THREE.MeshPhysicalMaterial({ color: new THREE.Color(1.0, 1.0, 1.0), metalness: 1.0, roughness: 0.2 });
	couchFootMesh2 = new THREE.Mesh(couchFootGeometry2, couchFootMaterial2);
	couchFootMesh2.scale.set(0.4, 4, 0.4);
	couchFootMesh2.rotation.set(0, 0, 0.1);
	couchFootMesh2.position.set(2, 4, -74);
	sceneShapeMeshes.push(couchFootMesh2);

	couchFootGeometry3 = new THREE.BoxGeometry();
	couchFootMaterial3 = new THREE.MeshPhysicalMaterial({ color: new THREE.Color(1.0, 1.0, 1.0), metalness: 1.0, roughness: 0.2 });
	couchFootMesh3 = new THREE.Mesh(couchFootGeometry3, couchFootMaterial3);
	couchFootMesh3.scale.set(0.4, 4, 0.4);
	couchFootMesh3.rotation.set(0, 0, 0.1);
	couchFootMesh3.position.set(2, 4, -93);
	sceneShapeMeshes.push(couchFootMesh3);

	couchFootGeometry4 = new THREE.BoxGeometry();
	couchFootMaterial4 = new THREE.MeshPhysicalMaterial({ color: new THREE.Color(1.0, 1.0, 1.0), metalness: 1.0, roughness: 0.2 });
	couchFootMesh4 = new THREE.Mesh(couchFootGeometry4, couchFootMaterial4);
	couchFootMesh4.scale.set(0.4, 4, 0.4);
	couchFootMesh4.rotation.set(0, 0, -0.1);
	couchFootMesh4.position.set(-52, 4, -93);
	sceneShapeMeshes.push(couchFootMesh4);

	// couch seat cushion
	couchSeatGeometry = new THREE.BoxGeometry();
	couchSeatMaterial = new THREE.MeshPhysicalMaterial({ color: new THREE.Color(0.0, 0.0, 0.02) });
	couchSeatMesh = new THREE.Mesh(couchSeatGeometry, couchSeatMaterial);
	couchSeatMesh.scale.set(33, 3, 12);
	couchSeatMesh.position.set(-25, 13, -84);
	sceneShapeMeshes.push(couchSeatMesh);

	// couch back cushion
	couchBackGeometry = new THREE.BoxGeometry();
	couchBackMaterial = new THREE.MeshPhysicalMaterial({ color: new THREE.Color(0.0, 0.0, 0.02) });
	couchBackMesh = new THREE.Mesh(couchBackGeometry, couchBackMaterial);
	couchBackMesh.scale.set(33, 9, 3);
	couchBackMesh.position.set(-25, 25, -93);
	sceneShapeMeshes.push(couchBackMesh);

	// couch left side
	couchLeftSideGeometry = new THREE.BoxGeometry();
	couchLeftSideMaterial = new THREE.MeshPhysicalMaterial({ color: new THREE.Color(0.0, 0.0, 0.02) });
	couchLeftSideMesh = new THREE.Mesh(couchLeftSideGeometry, couchLeftSideMaterial);
	couchLeftSideMesh.scale.set(3, 9, 12);
	couchLeftSideMesh.position.set(-55, 25, -84);
	sceneShapeMeshes.push(couchLeftSideMesh);

	// couch right side
	couchRightSideGeometry = new THREE.BoxGeometry();
	couchRightSideMaterial = new THREE.MeshPhysicalMaterial({ color: new THREE.Color(0.0, 0.0, 0.02) });
	couchRightSideMesh = new THREE.Mesh(couchRightSideGeometry, couchRightSideMaterial);
	couchRightSideMesh.scale.set(3, 9, 12);
	couchRightSideMesh.position.set(5, 25, -84);
	sceneShapeMeshes.push(couchRightSideMesh);

	// couch back top
	couchBackTopGeometry = new THREE.CylinderGeometry();
	couchBackTopMaterial = new THREE.MeshPhysicalMaterial({ color: new THREE.Color(0.0, 0.0, 0.02) });
	couchBackTopMesh = new THREE.Mesh(couchBackTopGeometry, couchBackTopMaterial);
	couchBackTopMesh.scale.set(3, 32, 4);
	couchBackTopMesh.rotation.set(0, 0, Math.PI * 0.5)
	couchBackTopMesh.position.set(-25, 34, -93);
	sceneShapeMeshes.push(couchBackTopMesh);

	// couch left arm top
	couchLeftArmGeometry = new THREE.CylinderGeometry();
	couchLeftArmMaterial = new THREE.MeshPhysicalMaterial({ color: new THREE.Color(0.0, 0.0, 0.02) });
	couchLeftArmMesh = new THREE.Mesh(couchLeftArmGeometry, couchLeftArmMaterial);
	couchLeftArmMesh.scale.set(4, 12, 3);
	couchLeftArmMesh.rotation.set(Math.PI * 0.5, -0.6, 0);
	couchLeftArmMesh.position.set(-55.5, 34, -84);
	sceneShapeMeshes.push(couchLeftArmMesh);

	// couch right arm top
	couchRightArmGeometry = new THREE.CylinderGeometry();
	couchRightArmMaterial = new THREE.MeshPhysicalMaterial({ color: new THREE.Color(0.0, 0.0, 0.02) });
	couchRightArmMesh = new THREE.Mesh(couchRightArmGeometry, couchRightArmMaterial);
	couchRightArmMesh.scale.set(4, 12, 3);
	couchRightArmMesh.rotation.set(Math.PI * 0.5, 0.6, 0);
	couchRightArmMesh.position.set(5.5, 34, -84);
	sceneShapeMeshes.push(couchRightArmMesh);

	// couch left arm cap (flattened sphere cap)
	couchLeftArmCapGeometry = new THREE.SphereGeometry();
	couchLeftArmCapMaterial = new THREE.MeshPhysicalMaterial({ color: new THREE.Color(0.0, 0.0, 0.02) });
	couchLeftArmCapMesh = new THREE.Mesh(couchLeftArmCapGeometry, couchLeftArmCapMaterial);
	couchLeftArmCapMesh.scale.set(4, 3, 0.75);
	couchLeftArmCapMesh.rotation.set(0, 0, -0.6);
	couchLeftArmCapMesh.position.set(-55.5, 34, -72);
	sceneShapeMeshes.push(couchLeftArmCapMesh);

	// couch right arm cap (flattened sphere cap)
	couchRightArmCapGeometry = new THREE.SphereGeometry();
	couchRightArmCapMaterial = new THREE.MeshPhysicalMaterial({ color: new THREE.Color(0.0, 0.0, 0.02) });
	couchRightArmCapMesh = new THREE.Mesh(couchRightArmCapGeometry, couchRightArmCapMaterial);
	couchRightArmCapMesh.scale.set(4, 3, 0.75);
	couchRightArmCapMesh.rotation.set(0, 0, 0.6);
	couchRightArmCapMesh.position.set(5.5, 34, -72);
	sceneShapeMeshes.push(couchRightArmCapMesh);

	// red pillow
	redPillowGeometry = new THREE.SphereGeometry();
	redPillowMaterial = new THREE.MeshPhysicalMaterial({ color: new THREE.Color(1.0, 0.0, 0.0) });
	redPillowMesh = new THREE.Mesh(redPillowGeometry, redPillowMaterial);
	redPillowMesh.scale.set(7, 3, 7);
	redPillowMesh.rotation.set(0.1, 0, -0.6);
	redPillowMesh.position.set(-47, 20, -84.5);
	sceneShapeMeshes.push(redPillowMesh);



	console.log("Shape count: " + sceneShapeMeshes.length);


	totalShapesWork = new Uint32Array(sceneShapeMeshes.length);

	shapes_array = new Float32Array(2048 * 2048 * 4);
	// 2048 = width of texture, 2048 = height of texture, 4 = r,g,b, and a components

	shapes_aabb_array = new Float32Array(2048 * 2048 * 4);
	// 2048 = width of texture, 2048 = height of texture, 4 = r,g,b, and a components


	for (let i = 0; i < sceneShapeMeshes.length; i++) 
	{

		sceneShapeMeshes[i].updateMatrixWorld(true); // 'true' forces immediate matrix update
		invMatrix.copy(sceneShapeMeshes[i].matrixWorld).invert();
		el = invMatrix.elements;

		//slot 0                       Shape transform Matrix 4x4 (16 elements total)
		shapes_array[32 * i + 0] = el[0]; // r or x // shape transform Matrix element[0]
		shapes_array[32 * i + 1] = el[1]; // g or y // shape transform Matrix element[1] 
		shapes_array[32 * i + 2] = el[2]; // b or z // shape transform Matrix element[2]
		shapes_array[32 * i + 3] = el[3]; // a or w // shape transform Matrix element[3]

		//slot 1
		shapes_array[32 * i + 4] = el[4]; // r or x // shape transform Matrix element[4]
		shapes_array[32 * i + 5] = el[5]; // g or y // shape transform Matrix element[5]
		shapes_array[32 * i + 6] = el[6]; // b or z // shape transform Matrix element[6]
		shapes_array[32 * i + 7] = el[7]; // a or w // shape transform Matrix element[7]

		//slot 2
		shapes_array[32 * i + 8] = el[8]; // r or x // shape transform Matrix element[8]
		shapes_array[32 * i + 9] = el[9]; // g or y // shape transform Matrix element[9]
		shapes_array[32 * i + 10] = el[10]; // b or z // shape transform Matrix element[10]
		shapes_array[32 * i + 11] = el[11]; // a or w // shape transform Matrix element[11]

		//slot 3
		shapes_array[32 * i + 12] = el[12]; // r or x // shape transform Matrix element[12]
		shapes_array[32 * i + 13] = el[13]; // g or y // shape transform Matrix element[13]
		shapes_array[32 * i + 14] = el[14]; // b or z // shape transform Matrix element[14]
		shapes_array[32 * i + 15] = el[15]; // a or w // shape transform Matrix element[15]

		//slot 4
		if (sceneShapeMeshes[i].geometry.type == "BoxGeometry")
			shapes_array[32 * i + 16] = 0; // r or x // shape type id#  (0: box, 1: sphere, 2: cylinder, 3: cone, 4: paraboloid, etc)
		else if (sceneShapeMeshes[i].geometry.type == "SphereGeometry")
			shapes_array[32 * i + 16] = 1; // r or x // shape type id#  (0: box, 1: sphere, 2: cylinder, 3: cone, 4: paraboloid, etc)
		else if (sceneShapeMeshes[i].geometry.type == "CylinderGeometry")
			shapes_array[32 * i + 16] = 2; // r or x // shape type id#  (0: box, 1: sphere, 2: cylinder, 3: cone, 4: paraboloid, etc)
		else if (sceneShapeMeshes[i].geometry.type == "ConeGeometry")
			shapes_array[32 * i + 16] = 3; // r or x // shape type id#  (0: box, 1: sphere, 2: cylinder, 3: cone, 4: paraboloid, etc)
		else // "ParaboloidGeometry"
			shapes_array[32 * i + 16] = 4; // r or x // shape type id#  (0: box, 1: sphere, 2: cylinder, 3: cone, 4: paraboloid, etc)

		// default = 1 = Diffuse material
		shapes_array[32 * i + 17] = 1; // g or y // material type id# (0: LIGHT, 1: DIFF, 2: REFR, 3: SPEC, 4: COAT, etc)
		if (sceneShapeMeshes[i].material.metalness > 0.0)
			shapes_array[32 * i + 17] = 3; // g or y // material type id# (0: LIGHT, 1: DIFF, 2: REFR, 3: SPEC, 4: COAT, etc)
		if (sceneShapeMeshes[i].material.clearcoat > 0.0)
			shapes_array[32 * i + 17] = 4; // g or y // material type id# (0: LIGHT, 1: DIFF, 2: REFR, 3: SPEC, 4: COAT, etc)
		if (sceneShapeMeshes[i].material.opacity < 1.0)
			shapes_array[32 * i + 17] = 2; // g or y // material type id# (0: LIGHT, 1: DIFF, 2: REFR, 3: SPEC, 4: COAT, etc)
		shapes_array[32 * i + 18] = sceneShapeMeshes[i].material.metalness; // b or z // material Metalness
		shapes_array[32 * i + 19] = sceneShapeMeshes[i].material.roughness; // a or w // material Roughness

		//slot 5
		shapes_array[32 * i + 20] = sceneShapeMeshes[i].material.color.r; // r or x // material albedo color R (if LIGHT, this is also its emissive color R)
		shapes_array[32 * i + 21] = sceneShapeMeshes[i].material.color.g; // g or y // material albedo color G (if LIGHT, this is also its emissive color G)
		shapes_array[32 * i + 22] = sceneShapeMeshes[i].material.color.b; // b or z // material albedo color B (if LIGHT, this is also its emissive color B)
		shapes_array[32 * i + 23] = sceneShapeMeshes[i].material.opacity; // a or w // material Opacity (Alpha)

		//slot 6
		shapes_array[32 * i + 24] = sceneShapeMeshes[i].material.ior; // r or x // material Index of Refraction(IoR)
		shapes_array[32 * i + 25] = sceneShapeMeshes[i].material.clearcoat; // g or y // material ClearCoat Amount
		shapes_array[32 * i + 26] = sceneShapeMeshes[i].material.clearcoatRoughness; // b or z // material ClearCoat Roughness (0.0-1.0, default: 0.0)
		shapes_array[32 * i + 27] = 1.5; // a or w // material ClearCoat IoR / not part of the three.js material spec / calculated here from 'clearcoat' value above

		//slot 7
		shapes_array[32 * i + 28] = 0; // r or x // material data
		shapes_array[32 * i + 29] = 0; // g or y // material data
		shapes_array[32 * i + 30] = 0; // b or z // material data
		shapes_array[32 * i + 31] = 0; // a or w // material data


		boundingBoxGeometries[i] = new THREE.BoxGeometry(2, 2, 2); // Box with Unit Radius of 1, so a Diameter(length) of 2 in each dimension / min:(-1,-1,-1), max(+1,+1,+1)
		boundingBoxMeshes[i] = new THREE.Mesh(boundingBoxGeometries[i], boundingBoxMaterial);

		boundingBoxMeshes[i].geometry.applyMatrix4(sceneShapeMeshes[i].matrixWorld);
		boundingBoxMeshes[i].geometry.computeBoundingBox();

		shapeBoundingBox_minCorner.copy(boundingBoxMeshes[i].geometry.boundingBox.min);
		shapeBoundingBox_maxCorner.copy(boundingBoxMeshes[i].geometry.boundingBox.max);
		boundingBoxMeshes[i].geometry.boundingBox.getCenter(shapeBoundingBox_centroid);


		shapes_aabb_array[9 * i + 0] = shapeBoundingBox_minCorner.x;
		shapes_aabb_array[9 * i + 1] = shapeBoundingBox_minCorner.y;
		shapes_aabb_array[9 * i + 2] = shapeBoundingBox_minCorner.z;
		shapes_aabb_array[9 * i + 3] = shapeBoundingBox_maxCorner.x;
		shapes_aabb_array[9 * i + 4] = shapeBoundingBox_maxCorner.y;
		shapes_aabb_array[9 * i + 5] = shapeBoundingBox_maxCorner.z;
		shapes_aabb_array[9 * i + 6] = shapeBoundingBox_centroid.x;
		shapes_aabb_array[9 * i + 7] = shapeBoundingBox_centroid.y;
		shapes_aabb_array[9 * i + 8] = shapeBoundingBox_centroid.z;

		totalShapesWork[i] = i;
	} // end for (let i = 0; i < sceneShapeMeshes.length; i++)


	console.time("BvhGeneration");
	console.log("BvhGeneration...");

	// Build the BVH acceleration structure, which starts with a large bounding box ('root' of the tree) 
	// that surrounds all of the shapes.  It then subdivides each 'parent' box into 2 smaller 'child' boxes.  
	// It continues until it reaches 1 shape, which it then designates as a 'leaf'
	BVH_Build_Iterative(totalShapesWork, shapes_aabb_array);
	//console.log(buildnodes);

	console.timeEnd("BvhGeneration");


	shapesDataTexture = new THREE.DataTexture(shapes_array,
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

	shapesDataTexture.flipY = false;
	shapesDataTexture.generateMipmaps = false;
	shapesDataTexture.needsUpdate = true;

	shapes_aabbDataTexture = new THREE.DataTexture(shapes_aabb_array,
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

	shapes_aabbDataTexture.flipY = false;
	shapes_aabbDataTexture.generateMipmaps = false;
	shapes_aabbDataTexture.needsUpdate = true;


	// scene/demo-specific uniforms go here
	pathTracingUniforms.tTriangleTexture = { value: triangleDataTexture };
	pathTracingUniforms.tAABBTexture = { value: aabbDataTexture };
	pathTracingUniforms.tShapes_DataTexture = { value: shapesDataTexture };
	pathTracingUniforms.tShapes_AABB_DataTexture = { value: shapes_aabbDataTexture };
	pathTracingUniforms.tPaintingTexture = { value: paintingTexture };
	pathTracingUniforms.uModelObject3DInvMatrix = { value: modelMesh.matrixWorld.invert() };
	pathTracingUniforms.uDoorObject3DInvMatrix = { value: new THREE.Matrix4() };


} // end function initSceneData()



// called automatically from within the animate() function (located in InitCommon.js file)
function updateVariablesAndUniforms() 
{

	if (needChangeDoorOpenClose)
	{
		doorObject3D.rotation.y = door_OpenCloseController.getValue();

		// DOOR
		doorObject3D.updateMatrixWorld(true); // 'true' forces immediate matrix update
		pathTracingUniforms.uDoorObject3DInvMatrix.value.copy(doorObject3D.matrixWorld).invert();

		cameraIsMoving = true;
		needChangeDoorOpenClose = false;
	}


	// INFO
	cameraInfoElement.innerHTML = "FOV: " + worldCamera.fov + " / Aperture: " + apertureSize.toFixed(2) + " / FocusDistance: " + focusDistance + "<br>" + "Samples: " + sampleCounter;

} // end function updateVariablesAndUniforms()



// load a resource
paintingTexture = textureLoader.load(
	// resource URL
	'textures/Piet_Mondrian_Tableau2.png',

	// onLoad callback
	function (texture)
	{
		texture.wrapS = THREE.RepeatWrapping;
		texture.wrapT = THREE.RepeatWrapping;
		texture.minFilter = THREE.NearestFilter;
		texture.magFilter = THREE.NearestFilter;
		texture.generateMipmaps = false;
		
		// now that the texture has been loaded, we can load the model
		load_GLTF_Model(); // load model, init app, and start animating
	}
);
