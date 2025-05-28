// scene/demo-specific variables go here
let frontLeft_VertexMoveController, frontLeft_VertexMoveObject;
let frontMiddle_VertexMoveController, frontMiddle_VertexMoveObject;
let frontRight_VertexMoveController, frontRight_VertexMoveObject;
let rearLeft_VertexMoveController, rearLeft_VertexMoveObject;
let rearMiddle_VertexMoveController, rearMiddle_VertexMoveObject;
let rearRight_VertexMoveController, rearRight_VertexMoveObject;
let needChangePatchVertex = false;
let useVertexNormals_ToggleController, useVertexNormals_ToggleObject;
let needChangeUseVertexNormals = false;

let skewMatrix = new THREE.Matrix4();
let uniformScale = 1;
let transform_Folder, position_Folder, scale_Folder, skew_Folder, rotation_Folder;
let transform_PositionXController, transform_PositionXObject;
let transform_PositionYController, transform_PositionYObject;
let transform_PositionZController, transform_PositionZObject;
let transform_ScaleUniformController, transform_ScaleUniformObject;
let transform_ScaleXController, transform_ScaleXObject;
let transform_ScaleYController, transform_ScaleYObject;
let transform_ScaleZController, transform_ScaleZObject;
let transform_SkewX_YController, transform_SkewX_YObject;
let transform_SkewX_ZController, transform_SkewX_ZObject;
let transform_SkewY_XController, transform_SkewY_XObject;
let transform_SkewY_ZController, transform_SkewY_ZObject;
let transform_SkewZ_XController, transform_SkewZ_XObject;
let transform_SkewZ_YController, transform_SkewZ_YObject;
let transform_RotationXController, transform_RotationXObject;
let transform_RotationYController, transform_RotationYObject;
let transform_RotationZController, transform_RotationZObject;
let needChangePosition = false;
let needChangeScaleUniform = false;
let needChangeScale = false;
let needChangeSkew = false;
let needChangeRotation = false;

let QuadsOnlyOBJModel;
let modelGeometryScale = 1.0;
let modelGeometryPositionOffset = new THREE.Vector3(0, -0.5, 0);
let YAxis = new THREE.Vector3(0, 1, 0);
let modelGeometryRotationY = Math.PI;
let QuadModelTransform = new THREE.Object3D();
let albedoTexture;
let total_number_of_quads = 0;
let quad_array;
let quadDataTexture;
let aabb_array;
let aabbDataTexture;
let totalWork;
let vp0 = new THREE.Vector3();
let vp1 = new THREE.Vector3();
let vp2 = new THREE.Vector3();
let vp3 = new THREE.Vector3();
let vn0 = new THREE.Vector3();
let vn1 = new THREE.Vector3();
let vn2 = new THREE.Vector3();
let vn3 = new THREE.Vector3();
let vt0 = new THREE.Vector2();
let vt1 = new THREE.Vector2();
let vt2 = new THREE.Vector2();
let vt3 = new THREE.Vector2();

function loadQuadsOnlyOBJModel()
{
	new MTLLoader()
		.setPath('models/')
		.load('Duck_toQuads.mtl', function(materials)
		{
			materials.preload();

			new OBJLoader_QuadsOnly()
				.setMaterials(materials)
				.setPath('models/')
				.load('Duck_toQuads.obj', function(object)
				{
					QuadsOnlyOBJModel = object;
					
					// now that the model has loaded, we can init app and start animating
					init();
				});
		});
}


// called automatically from within initTHREEjs() function (located in InitCommon.js file)
function initSceneData() 
{
	if (!mouseControl)
		demoFragmentShaderFileName = 'Quads_Only_Modeling_Fragment_Mobile.glsl';
	else demoFragmentShaderFileName = 'Quads_Only_Modeling_Fragment.glsl';

	// scene/demo-specific three.js objects setup goes here
	sceneIsDynamic = false;

	cameraFlightSpeed = 100;

	// pixelRatio is resolution - range: 0.5(half resolution) to 1.0(full resolution)
	pixelRatio = mouseControl ? 1.0 : 0.75; 

	EPS_intersect = 0.01;

	// set camera's field of view
	worldCamera.fov = 50;
	focusDistance = 120.0;
	apertureChangeSpeed = 5;

	// position and orient camera
	cameraControlsObject.position.set(0, -2, 140);
	///cameraControlsYawObject.rotation.y = 0.0;
	// look slightly upward
	//cameraControlsPitchObject.rotation.x = 0.005;

	
	// prepare OBJ model to send to the GPU
	total_number_of_quads = QuadsOnlyOBJModel.geometry.vertices.length / 12;
	console.log("quad count:" + total_number_of_quads);

	totalWork = new Uint32Array(total_number_of_quads);

	quad_array = new Float32Array(4096 * 4096 * 4);
	// 4096 = width of texture, 4096 = height of texture, 4 = r,g,b, and a components

	aabb_array = new Float32Array(4096 * 4096 * 4);
	// 4096 = width of texture, 4096 = height of texture, 4 = r,g,b, and a components


	let quad_b_box_min = new THREE.Vector3();
	let quad_b_box_max = new THREE.Vector3();
	let quad_b_box_centroid = new THREE.Vector3();


	let vpa = new Float32Array(QuadsOnlyOBJModel.geometry.vertices);
	let vna = new Float32Array(QuadsOnlyOBJModel.geometry.normals);
	let vta = null;
	let modelHasUVs = false;
	if (QuadsOnlyOBJModel.geometry.hasUVIndices) 
	{
		vta = new Float32Array(QuadsOnlyOBJModel.geometry.uvs);
		modelHasUVs = true;
	}


	let ix8 = 0; // for iterating through uv array
	let ix9 = 0; // for iterating through aabb array (for aabb data texture)
	let ix12 = 0; // for iterating through vertex positions/normals arrays
	let ix64 = 0; // for iterating through quads array (for quad data texture)

	for (let i = 0; i < total_number_of_quads; i++) 
	{
		ix8 = i * 8;
		ix9 = i * 9;
		ix12 = i * 12;
		ix64 = i * 64;

		quad_b_box_min.set(Infinity, Infinity, Infinity);
		quad_b_box_max.set(-Infinity, -Infinity, -Infinity);

		// record vertex positions
		vp0.set(vpa[ix12 + 0], vpa[ix12 + 1], vpa[ix12 + 2]);
		vp1.set(vpa[ix12 + 3], vpa[ix12 + 4], vpa[ix12 + 5]);
		vp2.set(vpa[ix12 + 6], vpa[ix12 + 7], vpa[ix12 + 8]);
		vp3.set(vpa[ix12 + 9], vpa[ix12 + 10], vpa[ix12 + 11]);

		// change loaded vertex position geometry (object's vertex positions, rotation, and scaling)
		// for this demo, I wanted the initial loaded Duck model to be facing to the left instead of right, 
		// so rotate it on the Y axis by 180 degrees, or PI
		vp0.applyAxisAngle(YAxis, modelGeometryRotationY); // modelGeometryRotationY = 180 (or PI)
		vp1.applyAxisAngle(YAxis, modelGeometryRotationY);
		vp2.applyAxisAngle(YAxis, modelGeometryRotationY);
		vp3.applyAxisAngle(YAxis, modelGeometryRotationY);

		// the initial Duck vertex positions are all 5 units above center, so lower all loaded vertices by 5 units in Y direction
		vp0.add(modelGeometryPositionOffset); // modelGeometryPositionOffset = Vector3(0, -5, 0)
		vp1.add(modelGeometryPositionOffset);
		vp2.add(modelGeometryPositionOffset);
		vp3.add(modelGeometryPositionOffset);

		// Duck's scale is left at 1.0 here, because this demo's GUI sliders will update the transform later
		vp0.multiplyScalar(modelGeometryScale); // modelGeometryScale = 1.0, so essentially this does nothing
		vp1.multiplyScalar(modelGeometryScale);
		vp2.multiplyScalar(modelGeometryScale);
		vp3.multiplyScalar(modelGeometryScale);

		

		// record vertex normals
		vn0.set(vna[ix12 + 0], vna[ix12 + 1], vna[ix12 + 2]).normalize().applyAxisAngle(YAxis, modelGeometryRotationY);
		vn1.set(vna[ix12 + 3], vna[ix12 + 4], vna[ix12 + 5]).normalize().applyAxisAngle(YAxis, modelGeometryRotationY);
		vn2.set(vna[ix12 + 6], vna[ix12 + 7], vna[ix12 + 8]).normalize().applyAxisAngle(YAxis, modelGeometryRotationY);
		vn3.set(vna[ix12 + 9], vna[ix12 + 10], vna[ix12 + 11]).normalize().applyAxisAngle(YAxis, modelGeometryRotationY);

		// record vertex texture coordinates (UVs)
		if (modelHasUVs) 
		{
			vt0.set(vta[ix8 + 0], vta[ix8 + 1]);
			vt1.set(vta[ix8 + 2], vta[ix8 + 3]);
			vt2.set(vta[ix8 + 4], vta[ix8 + 5]);
			vt3.set(vta[ix8 + 6], vta[ix8 + 7]);
		}
		
		// align data to be placed inside a data texture on the GPU
		// each texel of this texture will have r,g,b,a components that can be accessed in the shader as a texture lookup
		//texel 0
		quad_array[ix64  + 0] = vp0.x; // r or x
		quad_array[ix64  + 1] = vp0.y; // g or y 
		quad_array[ix64  + 2] = vp0.z; // b or z
		quad_array[ix64  + 3] = vp1.x; // a or w

		//texel 1
		quad_array[ix64  + 4] = vp1.y; // r or x
		quad_array[ix64  + 5] = vp1.z; // g or y
		quad_array[ix64  + 6] = vp2.x; // b or z
		quad_array[ix64  + 7] = vp2.y; // a or w

		//texel 2
		quad_array[ix64  + 8] = vp2.z; // r or x
		quad_array[ix64  + 9] = vp3.x; // g or y
		quad_array[ix64 + 10] = vp3.y; // b or z
		quad_array[ix64 + 11] = vp3.z; // a or w

		//texel 3
		quad_array[ix64 + 12] = vn0.x; // r or x
		quad_array[ix64 + 13] = vn0.y; // g or y
		quad_array[ix64 + 14] = vn0.z; // b or z
		quad_array[ix64 + 15] = vn1.x; // a or w

		//texel 4
		quad_array[ix64 + 16] = vn1.y; // r or x
		quad_array[ix64 + 17] = vn1.z; // g or y
		quad_array[ix64 + 18] = vn2.x; // b or z
		quad_array[ix64 + 19] = vn2.y; // a or w

		//texel 5
		quad_array[ix64 + 20] = vn2.z; // r or x
		quad_array[ix64 + 21] = vn3.x; // g or y
		quad_array[ix64 + 22] = vn3.y; // b or z
		quad_array[ix64 + 23] = vn3.z; // a or w

		//texel 6
		quad_array[ix64 + 24] = vt0.x; // r or x 
		quad_array[ix64 + 25] = vt0.y; // g or y
		quad_array[ix64 + 26] = vt1.x; // b or z
		quad_array[ix64 + 27] = vt1.y; // a or w

		//texel 7
		quad_array[ix64 + 28] = vt2.x; // r or x
		quad_array[ix64 + 29] = vt2.y; // g or y
		quad_array[ix64 + 30] = vt3.x; // b or z
		quad_array[ix64 + 31] = vt3.y; // a or w

		// the remaining texels are used for PBR material properties

		//texel 8
		quad_array[ix64 + 32] = Math.random(); // r or x // pick random face color r component
		quad_array[ix64 + 33] = Math.random(); // g or y // pick random face color g component
		quad_array[ix64 + 34] = Math.random(); // b or z // pick random face color b component
		quad_array[ix64 + 35] = 0; // a or w

		//texel 9
		quad_array[ix64 + 36] = 0; // r or x
		quad_array[ix64 + 37] = 0; // g or y
		quad_array[ix64 + 38] = 0; // b or z
		quad_array[ix64 + 39] = 0; // a or w

		//texel 10
		quad_array[ix64 + 40] = 0; // r or x
		quad_array[ix64 + 41] = 0; // g or y
		quad_array[ix64 + 42] = 0; // b or z
		quad_array[ix64 + 43] = 0; // a or w

		//texel 11
		quad_array[ix64 + 44] = 0; // r or x
		quad_array[ix64 + 45] = 0; // g or y
		quad_array[ix64 + 46] = 0; // b or z
		quad_array[ix64 + 47] = 0; // a or w

		//texel 12
		quad_array[ix64 + 48] = 0; // r or x
		quad_array[ix64 + 49] = 0; // g or y
		quad_array[ix64 + 50] = 0; // b or z
		quad_array[ix64 + 51] = 0; // a or w

		//texel 13
		quad_array[ix64 + 52] = 0; // r or x
		quad_array[ix64 + 53] = 0; // g or y
		quad_array[ix64 + 54] = 0; // b or z
		quad_array[ix64 + 55] = 0; // a or w

		//texel 14
		quad_array[ix64 + 56] = 0; // r or x 
		quad_array[ix64 + 57] = 0; // g or y
		quad_array[ix64 + 58] = 0; // b or z
		quad_array[ix64 + 59] = 0; // a or w

		//texel 15
		quad_array[ix64 + 60] = 0; // r or x
		quad_array[ix64 + 61] = 0; // g or y
		quad_array[ix64 + 62] = 0; // b or z
		quad_array[ix64 + 63] = 0; // a or w




		quad_b_box_min.copy(quad_b_box_min.min(vp0));
		quad_b_box_max.copy(quad_b_box_max.max(vp0));
		quad_b_box_min.copy(quad_b_box_min.min(vp1));
		quad_b_box_max.copy(quad_b_box_max.max(vp1));
		quad_b_box_min.copy(quad_b_box_min.min(vp2));
		quad_b_box_max.copy(quad_b_box_max.max(vp2));
		quad_b_box_min.copy(quad_b_box_min.min(vp3));
		quad_b_box_max.copy(quad_b_box_max.max(vp3));

		//quad_b_box_centroid.copy(quad_b_box_min).add(quad_b_box_max).multiplyScalar(0.5);
		quad_b_box_centroid.copy(vp0).add(vp1).add(vp2).add(vp3).multiplyScalar(0.25);

		aabb_array[ix9 + 0] = quad_b_box_min.x;
		aabb_array[ix9 + 1] = quad_b_box_min.y;
		aabb_array[ix9 + 2] = quad_b_box_min.z;
		aabb_array[ix9 + 3] = quad_b_box_max.x;
		aabb_array[ix9 + 4] = quad_b_box_max.y;
		aabb_array[ix9 + 5] = quad_b_box_max.z;
		aabb_array[ix9 + 6] = quad_b_box_centroid.x;
		aabb_array[ix9 + 7] = quad_b_box_centroid.y;
		aabb_array[ix9 + 8] = quad_b_box_centroid.z;

		totalWork[i] = i;
	}


	console.time("BvhGeneration");
	console.log("BvhGeneration...");

	// Build the BVH acceleration structure, which places a bounding box ('root' of the tree) around all of the
	// quads of the entire mesh, then subdivides each box into 2 smaller boxes. It continues until it reaches 
	// a single quad, which it then designates as a 'leaf'
	BVH_Build_Iterative(totalWork, aabb_array);
	//console.log(buildnodes);

	console.timeEnd("BvhGeneration");


	quadDataTexture = new THREE.DataTexture(quad_array,
		4096,
		4096,
		THREE.RGBAFormat,
		THREE.FloatType,
		THREE.Texture.DEFAULT_MAPPING,
		THREE.ClampToEdgeWrapping,
		THREE.ClampToEdgeWrapping,
		THREE.NearestFilter,
		THREE.NearestFilter,
		1,
		THREE.NoColorSpace);

	quadDataTexture.flipY = false;
	quadDataTexture.generateMipmaps = false;
	quadDataTexture.needsUpdate = true;

	aabbDataTexture = new THREE.DataTexture(aabb_array,
		4096,
		4096,
		THREE.RGBAFormat,
		THREE.FloatType,
		THREE.Texture.DEFAULT_MAPPING,
		THREE.ClampToEdgeWrapping,
		THREE.ClampToEdgeWrapping,
		THREE.NearestFilter,
		THREE.NearestFilter,
		1,
		THREE.NoColorSpace);

	aabbDataTexture.flipY = false;
	aabbDataTexture.generateMipmaps = false;
	aabbDataTexture.needsUpdate = true;


	// In addition to the default GUI on all demos, add any special GUI elements that this particular demo requires
	frontLeft_VertexMoveObject = { FrontLeftVertexHeight: -5 };
	frontMiddle_VertexMoveObject = { FrontMiddleVertexHeight: -10 };
	frontRight_VertexMoveObject = { FrontRightVertexHeight: 0 };
	rearLeft_VertexMoveObject = { RearLeftVertexHeight: -13 };
	rearMiddle_VertexMoveObject = { RearMiddleVertexHeight: 10 };
	rearRight_VertexMoveObject = { RearRightVertexHeight: -8 };

	useVertexNormals_ToggleObject = { ModelUsesVertexNormals: true };

	transform_PositionXObject = { positionX: 10 };
	transform_PositionYObject = { positionY: 0 };
	transform_PositionZObject = { positionZ: 0 };
	transform_ScaleUniformObject = { uniformScale: 10 };
	transform_ScaleXObject = { scaleX: 10 };
	transform_ScaleYObject = { scaleY: 10 };
	transform_ScaleZObject = { scaleZ: 10 };
	transform_SkewX_YObject = { skewX_Y: 0 };
	transform_SkewX_ZObject = { skewX_Z: 0 };
	transform_SkewY_XObject = { skewY_X: 0 };
	transform_SkewY_ZObject = { skewY_Z: 0 };
	transform_SkewZ_XObject = { skewZ_X: 0 };
	transform_SkewZ_YObject = { skewZ_Y: 0 };
	transform_RotationXObject = { rotationX: 0 };
	transform_RotationYObject = { rotationY: 0 };
	transform_RotationZObject = { rotationZ: 0 };

	function handlePatchVertexChange() { needChangePatchVertex = true; }
	function handleUseVertexNormalsChange(){ needChangeUseVertexNormals = true; }
	function handlePositionChange() { needChangePosition = true; }
	function handleScaleUniformChange() { needChangeScaleUniform = true; }
	function handleScaleChange() { needChangeScale = true; }
	function handleSkewChange() { needChangeSkew = true; }
	function handleRotationChange() { needChangeRotation = true; }

	frontLeft_VertexMoveController = gui.add(frontLeft_VertexMoveObject, 'FrontLeftVertexHeight', -25, 25, 0.01).onChange(handlePatchVertexChange);
	frontMiddle_VertexMoveController = gui.add(frontMiddle_VertexMoveObject, 'FrontMiddleVertexHeight', -25, 25, 0.01).onChange(handlePatchVertexChange);
	frontRight_VertexMoveController = gui.add(frontRight_VertexMoveObject, 'FrontRightVertexHeight', -25, 25, 0.01).onChange(handlePatchVertexChange);
	rearLeft_VertexMoveController = gui.add(rearLeft_VertexMoveObject, 'RearLeftVertexHeight', -25, 25, 0.01).onChange(handlePatchVertexChange);
	rearMiddle_VertexMoveController = gui.add(rearMiddle_VertexMoveObject, 'RearMiddleVertexHeight', -25, 25, 0.01).onChange(handlePatchVertexChange);
	rearRight_VertexMoveController = gui.add(rearRight_VertexMoveObject, 'RearRightVertexHeight', -25, 25, 0.01).onChange(handlePatchVertexChange);

	useVertexNormals_ToggleController = gui.add(useVertexNormals_ToggleObject, 'ModelUsesVertexNormals', true).onChange(handleUseVertexNormalsChange);

	transform_Folder = gui.addFolder('Transform');

	position_Folder = transform_Folder.addFolder('Position');
	transform_PositionXController = position_Folder.add(transform_PositionXObject, 'positionX', -50, 50, 1).onChange(handlePositionChange);
	transform_PositionYController = position_Folder.add(transform_PositionYObject, 'positionY', -50, 50, 1).onChange(handlePositionChange);
	transform_PositionZController = position_Folder.add(transform_PositionZObject, 'positionZ', -50, 50, 1).onChange(handlePositionChange);

	scale_Folder = transform_Folder.addFolder('Scale');
	transform_ScaleUniformController = scale_Folder.add(transform_ScaleUniformObject, 'uniformScale', 1, 40, 1).onChange(handleScaleUniformChange);
	transform_ScaleXController = scale_Folder.add(transform_ScaleXObject, 'scaleX', 1, 40, 1).onChange(handleScaleChange);
	transform_ScaleYController = scale_Folder.add(transform_ScaleYObject, 'scaleY', 1, 40, 1).onChange(handleScaleChange);
	transform_ScaleZController = scale_Folder.add(transform_ScaleZObject, 'scaleZ', 1, 40, 1).onChange(handleScaleChange);

	skew_Folder = transform_Folder.addFolder('Skew');
	transform_SkewX_YController = skew_Folder.add(transform_SkewX_YObject, 'skewX_Y', -0.9, 0.9, 0.1).onChange(handleSkewChange);
	transform_SkewX_ZController = skew_Folder.add(transform_SkewX_ZObject, 'skewX_Z', -0.9, 0.9, 0.1).onChange(handleSkewChange);
	transform_SkewY_XController = skew_Folder.add(transform_SkewY_XObject, 'skewY_X', -0.9, 0.9, 0.1).onChange(handleSkewChange);
	transform_SkewY_ZController = skew_Folder.add(transform_SkewY_ZObject, 'skewY_Z', -0.9, 0.9, 0.1).onChange(handleSkewChange);
	transform_SkewZ_XController = skew_Folder.add(transform_SkewZ_XObject, 'skewZ_X', -0.9, 0.9, 0.1).onChange(handleSkewChange);
	transform_SkewZ_YController = skew_Folder.add(transform_SkewZ_YObject, 'skewZ_Y', -0.9, 0.9, 0.1).onChange(handleSkewChange);

	rotation_Folder = transform_Folder.addFolder('Rotation');
	transform_RotationXController = rotation_Folder.add(transform_RotationXObject, 'rotationX', 0, 359, 1).onChange(handleRotationChange);
	transform_RotationYController = rotation_Folder.add(transform_RotationYObject, 'rotationY', 0, 359, 1).onChange(handleRotationChange);
	transform_RotationZController = rotation_Folder.add(transform_RotationZObject, 'rotationZ', 0, 359, 1).onChange(handleRotationChange);

	position_Folder.close();
	scale_Folder.close();
	skew_Folder.close();
	rotation_Folder.close();

	// jumpstart all the gui change controller handlers so that the pathtracing fragment shader uniforms are correct and up-to-date
	handlePatchVertexChange();
	handleUseVertexNormalsChange();
	handlePositionChange();
	handleScaleUniformChange();
	handleScaleChange();
	handleSkewChange();
	handleRotationChange();


	// scene/demo-specific uniforms go here
	pathTracingUniforms.tQuadTexture = { value: quadDataTexture };
	pathTracingUniforms.tAABBTexture = { value: aabbDataTexture };
	pathTracingUniforms.tAlbedoTexture = { value: albedoTexture };
	pathTracingUniforms.uQuadModel_InvMatrix = { value: new THREE.Matrix4() };
	pathTracingUniforms.uFrontLeftVertexHeight = { value: 0.0 };
	pathTracingUniforms.uFrontMiddleVertexHeight = { value: 0.0 };
	pathTracingUniforms.uFrontRightVertexHeight = { value: 0.0 };
	pathTracingUniforms.uRearLeftVertexHeight = { value: 0.0 };
	pathTracingUniforms.uRearMiddleVertexHeight = { value: 0.0 };
	pathTracingUniforms.uRearRightVertexHeight = { value: 0.0 };
	pathTracingUniforms.uModelUsesVertexNormals = { type: "b1", value: true };

} // end function initSceneData()



// called automatically from within the animate() function (located in InitCommon.js file)
function updateVariablesAndUniforms() 
{

	if (needChangePatchVertex)
	{
		pathTracingUniforms.uFrontLeftVertexHeight.value = frontLeft_VertexMoveController.getValue();
		pathTracingUniforms.uFrontMiddleVertexHeight.value = frontMiddle_VertexMoveController.getValue();
		pathTracingUniforms.uFrontRightVertexHeight.value = frontRight_VertexMoveController.getValue();

		pathTracingUniforms.uRearLeftVertexHeight.value = rearLeft_VertexMoveController.getValue();
		pathTracingUniforms.uRearMiddleVertexHeight.value = rearMiddle_VertexMoveController.getValue();
		pathTracingUniforms.uRearRightVertexHeight.value = rearRight_VertexMoveController.getValue();

		cameraIsMoving = true;
		needChangePatchVertex = false;
	}

	if (needChangeUseVertexNormals)
	{
		pathTracingUniforms.uModelUsesVertexNormals.value = useVertexNormals_ToggleController.getValue();

		cameraIsMoving = true;
		needChangeUseVertexNormals = false;
	}

	if (needChangePosition)
	{
		QuadModelTransform.position.set(transform_PositionXController.getValue(),
			transform_PositionYController.getValue(),
			transform_PositionZController.getValue());

		cameraIsMoving = true;
		needChangePosition = false;
	}

	if (needChangeScaleUniform)
	{
		uniformScale = transform_ScaleUniformController.getValue();
		QuadModelTransform.scale.set(uniformScale, uniformScale, uniformScale);

		transform_ScaleXController.setValue(uniformScale);
		transform_ScaleYController.setValue(uniformScale);
		transform_ScaleZController.setValue(uniformScale);

		cameraIsMoving = true;
		needChangeScaleUniform = false;
	}

	if (needChangeScale)
	{
		QuadModelTransform.scale.set(transform_ScaleXController.getValue(),
			transform_ScaleYController.getValue(),
			transform_ScaleZController.getValue());

		cameraIsMoving = true;
		needChangeScale = false;
	}

	if (needChangeSkew)
	{
		skewMatrix.set(
			1, transform_SkewX_YController.getValue(), transform_SkewX_ZController.getValue(), 0,
			transform_SkewY_XController.getValue(), 1, transform_SkewY_ZController.getValue(), 0,
			transform_SkewZ_XController.getValue(), transform_SkewZ_YController.getValue(), 1, 0,
			0, 0, 0, 1
		);

		cameraIsMoving = true;
		needChangeSkew = false;
	}

	if (needChangeRotation)
	{
		QuadModelTransform.rotation.set(THREE.MathUtils.degToRad(transform_RotationXController.getValue()),
			THREE.MathUtils.degToRad(transform_RotationYController.getValue()),
			THREE.MathUtils.degToRad(transform_RotationZController.getValue()));

		cameraIsMoving = true;
		needChangeRotation = false;
	}

	QuadModelTransform.updateMatrixWorld();
	QuadModelTransform.matrixWorld.multiply(skewMatrix);
	
	pathTracingUniforms.uQuadModel_InvMatrix.value.copy(QuadModelTransform.matrixWorld).invert();

	// INFO
	cameraInfoElement.innerHTML = "FOV: " + worldCamera.fov + " / Aperture: " + apertureSize.toFixed(2) + " / FocusDistance: " + focusDistance + "<br>" + "Samples: " + sampleCounter;

} // end function updateVariablesAndUniforms()


// load a resource
albedoTexture = textureLoader.load(
	// resource URL
	'models/DuckCM.png',

	// onLoad callback
	function (texture)
	{
		texture.wrapS = THREE.RepeatWrapping;
		texture.wrapT = THREE.RepeatWrapping;
		texture.minFilter = THREE.NearestFilter;
		texture.magFilter = THREE.NearestFilter;
		texture.generateMipmaps = false;
		
		// now that the texture has been loaded, we can load the model
		loadQuadsOnlyOBJModel(); // load model, init app, and start animating
	}
);
