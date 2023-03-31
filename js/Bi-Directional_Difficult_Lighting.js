// scene/demo-specific variables go here
let doorObject;
let paintingTexture, darkWoodTexture, lightWoodTexture, marbleTexture;
let hammeredMetalNormalMapTexture;
let imageTexturesTotalCount = 5;
let numOfImageTexturesLoaded = 0;
let increaseDoorAngle = false;
let decreaseDoorAngle = false;

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

let door_OpenCloseController, door_OpenCloseObject;
let needChangeDoorOpenClose = false;


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


function load_GLTF_Models() 
{

	let gltfLoader = new GLTFLoader();

	gltfLoader.load("models/UtahTeapot.glb", function (meshGroup) { // Triangles: 30,338

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
		
		// settings for UtahTeapot model
		modelScale = 2.3;
		modelPositionOffset.set(-70, -38.7, -180);

		// now that the models have been loaded, we can init 
		init();
	}); // end gltfLoader.load()

} // end function load_GLTF_Models()



// called automatically from within initTHREEjs() function (located in InitCommon.js file)
function initSceneData() 
{
	demoFragmentShaderFileName = 'Bi-Directional_Difficult_Lighting_Fragment.glsl';

	// scene/demo-specific three.js objects setup goes here
	sceneIsDynamic = false;
	
	edgeSharpenSpeed = 0.01;

	cameraFlightSpeed = 200;

	// pixelRatio is resolution - range: 0.5(half resolution) to 1.0(full resolution)
	pixelRatio = mouseControl ? 0.7 : 0.7;

	EPS_intersect = 0.001;

	// set camera's field of view
	worldCamera.fov = 50;
	focusDistance = 230.0;
	apertureChangeSpeed = 10;

	// position and orient camera
	cameraControlsObject.position.set(-11, -15, 30);
	// look slightly to the right
	cameraControlsYawObject.rotation.y = -0.2;


	total_number_of_triangles = modelMesh.geometry.attributes.position.array.length / 9;
	console.log("Triangle count:" + (total_number_of_triangles * 3));

	totalWork = new Uint32Array(total_number_of_triangles * 3);

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
	let numTrisx32 = total_number_of_triangles * 32;
	let numTrisx9 = total_number_of_triangles * 9;

	// 1st teapot (left side of table)
	for (let i = 0; i < total_number_of_triangles; i++)
	{
		ix32 = i * 32;
		ix9  = i * 9;

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

	
	// 2nd teapot (center of table)
	materialNumber = 0;
	modelPositionOffset.set(0, -38.7, -180);

	for (let i = 0; i < total_number_of_triangles; i++)
	{
		ix32 = i * 32;
		ix9  = i * 9;

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
		triangle_array[ix32 + 0 + numTrisx32] = vp0.x; // r or x
		triangle_array[ix32 + 1 + numTrisx32] = vp0.y; // g or y 
		triangle_array[ix32 + 2 + numTrisx32] = vp0.z; // b or z
		triangle_array[ix32 + 3 + numTrisx32] = vp1.x; // a or w

		//slot 1
		triangle_array[ix32 + 4 + numTrisx32] = vp1.y; // r or x
		triangle_array[ix32 + 5 + numTrisx32] = vp1.z; // g or y
		triangle_array[ix32 + 6 + numTrisx32] = vp2.x; // b or z
		triangle_array[ix32 + 7 + numTrisx32] = vp2.y; // a or w

		//slot 2
		triangle_array[ix32 + 8 + numTrisx32] = vp2.z; // r or x
		triangle_array[ix32 + 9 + numTrisx32] = vn0.x; // g or y
		triangle_array[ix32 + 10 + numTrisx32] = vn0.y; // b or z
		triangle_array[ix32 + 11 + numTrisx32] = vn0.z; // a or w

		//slot 3
		triangle_array[ix32 + 12 + numTrisx32] = vn1.x; // r or x
		triangle_array[ix32 + 13 + numTrisx32] = vn1.y; // g or y
		triangle_array[ix32 + 14 + numTrisx32] = vn1.z; // b or z
		triangle_array[ix32 + 15 + numTrisx32] = vn2.x; // a or w

		//slot 4
		triangle_array[ix32 + 16 + numTrisx32] = vn2.y; // r or x
		triangle_array[ix32 + 17 + numTrisx32] = vn2.z; // g or y
		triangle_array[ix32 + 18 + numTrisx32] = vt0.x; // b or z
		triangle_array[ix32 + 19 + numTrisx32] = vt0.y; // a or w

		//slot 5
		triangle_array[ix32 + 20 + numTrisx32] = vt1.x; // r or x
		triangle_array[ix32 + 21 + numTrisx32] = vt1.y; // g or y
		triangle_array[ix32 + 22 + numTrisx32] = vt2.x; // b or z
		triangle_array[ix32 + 23 + numTrisx32] = vt2.y; // a or w

		// the remaining slots are used for PBR material properties

		//slot 6
		triangle_array[ix32 + 24 + numTrisx32] = pathTracingMaterialList[materialNumber].type; // r or x 
		triangle_array[ix32 + 25 + numTrisx32] = pathTracingMaterialList[materialNumber].color.r; // g or y
		triangle_array[ix32 + 26 + numTrisx32] = pathTracingMaterialList[materialNumber].color.g; // b or z
		triangle_array[ix32 + 27 + numTrisx32] = pathTracingMaterialList[materialNumber].color.b; // a or w

		//slot 7
		triangle_array[ix32 + 28 + numTrisx32] = pathTracingMaterialList[materialNumber].albedoTextureID; // r or x
		triangle_array[ix32 + 29 + numTrisx32] = 1.0; // g or y
		triangle_array[ix32 + 30 + numTrisx32] = 0; // b or z
		triangle_array[ix32 + 31 + numTrisx32] = 0; // a or w

		triangle_b_box_min.copy(triangle_b_box_min.min(vp0));
		triangle_b_box_max.copy(triangle_b_box_max.max(vp0));
		triangle_b_box_min.copy(triangle_b_box_min.min(vp1));
		triangle_b_box_max.copy(triangle_b_box_max.max(vp1));
		triangle_b_box_min.copy(triangle_b_box_min.min(vp2));
		triangle_b_box_max.copy(triangle_b_box_max.max(vp2));

		triangle_b_box_centroid.copy(triangle_b_box_min).add(triangle_b_box_max).multiplyScalar(0.5);

		aabb_array[ix9 + 0 + numTrisx9] = triangle_b_box_min.x;
		aabb_array[ix9 + 1 + numTrisx9] = triangle_b_box_min.y;
		aabb_array[ix9 + 2 + numTrisx9] = triangle_b_box_min.z;
		aabb_array[ix9 + 3 + numTrisx9] = triangle_b_box_max.x;
		aabb_array[ix9 + 4 + numTrisx9] = triangle_b_box_max.y;
		aabb_array[ix9 + 5 + numTrisx9] = triangle_b_box_max.z;
		aabb_array[ix9 + 6 + numTrisx9] = triangle_b_box_centroid.x;
		aabb_array[ix9 + 7 + numTrisx9] = triangle_b_box_centroid.y;
		aabb_array[ix9 + 8 + numTrisx9] = triangle_b_box_centroid.z;

		totalWork[i + total_number_of_triangles] = i + total_number_of_triangles;
	}


	// 3rd teapot (right side of table)
	materialNumber = 0;
	modelPositionOffset.set(70, -38.7, -180);

	for (let i = 0; i < total_number_of_triangles; i++)
	{
		ix32 = i * 32;
		ix9  = i * 9;

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
		triangle_array[ix32 + 0 + numTrisx32 + numTrisx32] = vp0.x; // r or x
		triangle_array[ix32 + 1 + numTrisx32 + numTrisx32] = vp0.y; // g or y 
		triangle_array[ix32 + 2 + numTrisx32 + numTrisx32] = vp0.z; // b or z
		triangle_array[ix32 + 3 + numTrisx32 + numTrisx32] = vp1.x; // a or w

		//slot 1
		triangle_array[ix32 + 4 + numTrisx32 + numTrisx32] = vp1.y; // r or x
		triangle_array[ix32 + 5 + numTrisx32 + numTrisx32] = vp1.z; // g or y
		triangle_array[ix32 + 6 + numTrisx32 + numTrisx32] = vp2.x; // b or z
		triangle_array[ix32 + 7 + numTrisx32 + numTrisx32] = vp2.y; // a or w

		//slot 2
		triangle_array[ix32 + 8 + numTrisx32 + numTrisx32] = vp2.z; // r or x
		triangle_array[ix32 + 9 + numTrisx32 + numTrisx32] = vn0.x; // g or y
		triangle_array[ix32 + 10 + numTrisx32 + numTrisx32] = vn0.y; // b or z
		triangle_array[ix32 + 11 + numTrisx32 + numTrisx32] = vn0.z; // a or w

		//slot 3
		triangle_array[ix32 + 12 + numTrisx32 + numTrisx32] = vn1.x; // r or x
		triangle_array[ix32 + 13 + numTrisx32 + numTrisx32] = vn1.y; // g or y
		triangle_array[ix32 + 14 + numTrisx32 + numTrisx32] = vn1.z; // b or z
		triangle_array[ix32 + 15 + numTrisx32 + numTrisx32] = vn2.x; // a or w

		//slot 4
		triangle_array[ix32 + 16 + numTrisx32 + numTrisx32] = vn2.y; // r or x
		triangle_array[ix32 + 17 + numTrisx32 + numTrisx32] = vn2.z; // g or y
		triangle_array[ix32 + 18 + numTrisx32 + numTrisx32] = vt0.x; // b or z
		triangle_array[ix32 + 19 + numTrisx32 + numTrisx32] = vt0.y; // a or w

		//slot 5
		triangle_array[ix32 + 20 + numTrisx32 + numTrisx32] = vt1.x; // r or x
		triangle_array[ix32 + 21 + numTrisx32 + numTrisx32] = vt1.y; // g or y
		triangle_array[ix32 + 22 + numTrisx32 + numTrisx32] = vt2.x; // b or z
		triangle_array[ix32 + 23 + numTrisx32 + numTrisx32] = vt2.y; // a or w

		// the remaining slots are used for PBR material properties

		//slot 6
		triangle_array[ix32 + 24 + numTrisx32 + numTrisx32] = pathTracingMaterialList[materialNumber].type; // r or x 
		triangle_array[ix32 + 25 + numTrisx32 + numTrisx32] = pathTracingMaterialList[materialNumber].color.r; // g or y
		triangle_array[ix32 + 26 + numTrisx32 + numTrisx32] = pathTracingMaterialList[materialNumber].color.g; // b or z
		triangle_array[ix32 + 27 + numTrisx32 + numTrisx32] = pathTracingMaterialList[materialNumber].color.b; // a or w

		//slot 7
		triangle_array[ix32 + 28 + numTrisx32 + numTrisx32] = pathTracingMaterialList[materialNumber].albedoTextureID; // r or x
		triangle_array[ix32 + 29 + numTrisx32 + numTrisx32] = 2.0; // g or y
		triangle_array[ix32 + 30 + numTrisx32 + numTrisx32] = 0; // b or z
		triangle_array[ix32 + 31 + numTrisx32 + numTrisx32] = 0; // a or w

		triangle_b_box_min.copy(triangle_b_box_min.min(vp0));
		triangle_b_box_max.copy(triangle_b_box_max.max(vp0));
		triangle_b_box_min.copy(triangle_b_box_min.min(vp1));
		triangle_b_box_max.copy(triangle_b_box_max.max(vp1));
		triangle_b_box_min.copy(triangle_b_box_min.min(vp2));
		triangle_b_box_max.copy(triangle_b_box_max.max(vp2));

		triangle_b_box_centroid.copy(triangle_b_box_min).add(triangle_b_box_max).multiplyScalar(0.5);

		aabb_array[ix9 + 0 + numTrisx9 + numTrisx9] = triangle_b_box_min.x;
		aabb_array[ix9 + 1 + numTrisx9 + numTrisx9] = triangle_b_box_min.y;
		aabb_array[ix9 + 2 + numTrisx9 + numTrisx9] = triangle_b_box_min.z;
		aabb_array[ix9 + 3 + numTrisx9 + numTrisx9] = triangle_b_box_max.x;
		aabb_array[ix9 + 4 + numTrisx9 + numTrisx9] = triangle_b_box_max.y;
		aabb_array[ix9 + 5 + numTrisx9 + numTrisx9] = triangle_b_box_max.z;
		aabb_array[ix9 + 6 + numTrisx9 + numTrisx9] = triangle_b_box_centroid.x;
		aabb_array[ix9 + 7 + numTrisx9 + numTrisx9] = triangle_b_box_centroid.y;
		aabb_array[ix9 + 8 + numTrisx9 + numTrisx9] = triangle_b_box_centroid.z;

		totalWork[i + total_number_of_triangles + total_number_of_triangles] = i + total_number_of_triangles + total_number_of_triangles;
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



	// Door object
	doorObject = new THREE.Object3D();
	pathTracingScene.add(doorObject);
	// doorObject is just a data placeholder as well as an Object3D that can be transformed/manipulated by 
	// using familiar Three.js library commands. It is then fed into the GPU path tracing renderer
	// through its 'matrixWorld' matrix.
	doorObject.rotation.set(0, TWO_PI - 0.25, 0); // TWO_PI - 0.4
	doorObject.position.set(179, -5, -298);
	doorObject.updateMatrixWorld(true); // 'true' forces immediate matrix update


	
	// In addition to the default GUI on all demos, add any special GUI elements that this particular demo requires
	door_OpenCloseObject = {
		Door_Open_Close : 6.03
	}
	function handleDoorOpenCloseChange() 
	{
		needChangeDoorOpenClose = true;
	}

	door_OpenCloseController = gui.add(door_OpenCloseObject, 'Door_Open_Close', 3.27, 6.28, 0.01).onChange(handleDoorOpenCloseChange);

	// scene/demo-specific uniforms go here    
	pathTracingUniforms.tTriangleTexture = { value: triangleDataTexture };
	pathTracingUniforms.tAABBTexture = { value: aabbDataTexture };
	pathTracingUniforms.tPaintingTexture = { value: paintingTexture };
	pathTracingUniforms.tDarkWoodTexture = { value: darkWoodTexture };
	pathTracingUniforms.tLightWoodTexture = { value: lightWoodTexture };
	pathTracingUniforms.tMarbleTexture = { value: marbleTexture };
	pathTracingUniforms.tHammeredMetalNormalMapTexture = { value: hammeredMetalNormalMapTexture };
	pathTracingUniforms.uDoorObjectInvMatrix = { value: new THREE.Matrix4() };

} // end function initSceneData()



// called automatically from within the animate() function (located in InitCommon.js file)
function updateVariablesAndUniforms() 
{

	if (needChangeDoorOpenClose)
	{
		doorObject.rotation.y = door_OpenCloseController.getValue();

		cameraIsMoving = true;
		needChangeDoorOpenClose = false;
	}

	// DOOR
	doorObject.updateMatrixWorld(true); // 'true' forces immediate matrix update
	pathTracingUniforms.uDoorObjectInvMatrix.value.copy(doorObject.matrixWorld).invert();

	// INFO
	cameraInfoElement.innerHTML = "FOV: " + worldCamera.fov + " / Aperture: " +
		apertureSize.toFixed(2) + " / FocusDistance: " + focusDistance + "<br>" + "Samples: " + sampleCounter;

} // end function updateVariablesAndUniforms()


// load all resources
paintingTexture = textureLoader.load(
	// resource URL
	'textures/painting.jpg',

	// onLoad callback
	function (texture)
	{
		texture.wrapS = THREE.RepeatWrapping;
		texture.wrapT = THREE.RepeatWrapping;
		texture.minFilter = THREE.NearestFilter;
		texture.magFilter = THREE.NearestFilter;
		texture.generateMipmaps = false;

		numOfImageTexturesLoaded++;
		// if all textures have been loaded, we can load the models
		if (numOfImageTexturesLoaded == imageTexturesTotalCount)
			load_GLTF_Models(); // load models, init app, and start animating
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
		texture.minFilter = THREE.NearestFilter;
		texture.magFilter = THREE.NearestFilter;
		texture.generateMipmaps = false;

		numOfImageTexturesLoaded++;
		// if all textures have been loaded, we can load the models
		if (numOfImageTexturesLoaded == imageTexturesTotalCount)
			load_GLTF_Models(); // load models, init app, and start animating
	}
);

lightWoodTexture = textureLoader.load(
	// resource URL
	'textures/tableWood.jpg',

	// onLoad callback
	function (texture)
	{
		texture.wrapS = THREE.RepeatWrapping;
		texture.wrapT = THREE.RepeatWrapping;
		texture.minFilter = THREE.NearestFilter;
		texture.magFilter = THREE.NearestFilter;
		texture.generateMipmaps = false;

		numOfImageTexturesLoaded++;
		// if all textures have been loaded, we can load the models
		if (numOfImageTexturesLoaded == imageTexturesTotalCount)
			load_GLTF_Models(); // load models, init app, and start animating
	}
);

marbleTexture = textureLoader.load(
	// resource URL
	'textures/whiteMarbleThinVein.jpg',

	// onLoad callback
	function (texture)
	{
		texture.wrapS = THREE.RepeatWrapping;
		texture.wrapT = THREE.RepeatWrapping;
		texture.minFilter = THREE.NearestFilter;
		texture.magFilter = THREE.NearestFilter;
		texture.generateMipmaps = false;

		numOfImageTexturesLoaded++;
		// if all textures have been loaded, we can load the models
		if (numOfImageTexturesLoaded == imageTexturesTotalCount)
			load_GLTF_Models(); // load models, init app, and start animating
	}
);

hammeredMetalNormalMapTexture = textureLoader.load(
	// resource URL
	'textures/hammeredMetal_NormalMap.jpg',

	// onLoad callback
	function (texture)
	{
		texture.wrapS = THREE.RepeatWrapping;
		texture.wrapT = THREE.RepeatWrapping;
		texture.minFilter = THREE.NearestFilter;
		texture.magFilter = THREE.NearestFilter;
		texture.generateMipmaps = false;

		numOfImageTexturesLoaded++;
		// if all textures have been loaded, we can load the models
		if (numOfImageTexturesLoaded == imageTexturesTotalCount)
			load_GLTF_Models(); // load models, init app, and start animating
	}
);
