// scene/demo-specific variables go here
let totalNumberOfShapes = 0;
let shape_array;
let shapeDataTexture;
let aabb_array;
let aabbDataTexture;
let totalWork;
let shapeBoundingBox_minCorner = new THREE.Vector3();
let shapeBoundingBox_maxCorner = new THREE.Vector3();
let shapeBoundingBox_centroid = new THREE.Vector3();
let boxGeometry, boxMaterial;
let boxMeshes = [];
let boxGeometries = [];
let spheres = [];
let currentSphereScale = 1;
let parentSphereScale = 1;
let currentParentSpherePosition = new THREE.Vector3();
let positionVector = new THREE.Vector3();
let normalVectors = [];
let normalVector = new THREE.Vector3();
let tempUpVector = new THREE.Vector3();
let tangentVector = new THREE.Vector3();
let bitangentVector = new THREE.Vector3();
let worldUpVector = new THREE.Vector3(0, 1, 0);
let worldRightVector = new THREE.Vector3(1, 0, 0);
let s1_Angle = THREE.MathUtils.degToRad(60);
let s2_Angle = THREE.MathUtils.degToRad(120);

let shape = new THREE.Object3D();
let invMatrix = new THREE.Matrix4();
let el; // elements of the invMatrix

let material_TypeObject;
let material_TypeController;
let changeMaterialType = false;
let matType = 0;



// called automatically from within initTHREEjs() function (located in InitCommon.js file)
function initSceneData() 
{
	demoFragmentShaderFileName = 'Sphereflake_Fragment.glsl';

	// scene/demo-specific three.js objects setup goes here
	sceneIsDynamic = false;

	cameraFlightSpeed = 100;

	// pixelRatio is resolution - range: 0.5(half resolution) to 1.0(full resolution)
	pixelRatio = mouseControl ? 0.75 : 0.75;

	EPS_intersect = 0.01;

	// set camera's field of view
	worldCamera.fov = 60;
	focusDistance = 120.0;
	apertureChangeSpeed = 5;

	// position and orient camera
	cameraControlsObject.position.set(0, 160, 500);
	///cameraControlsYawObject.rotation.y = 0.0;
	// look slightly upward
	cameraControlsPitchObject.rotation.x = 0.005;



	totalNumberOfShapes = 0;

	// FIRST, CREATE LARGEST CENTRAL SPHERE
	currentSphereScale = 100;
	parentSphereScale = currentSphereScale;
	spheres[totalNumberOfShapes] = new THREE.Object3D();
	spheres[totalNumberOfShapes].position.set(0, 0, 0);
	normalVectors[totalNumberOfShapes] = new THREE.Vector3();
	normalVectors[totalNumberOfShapes].copy(worldUpVector);
	positionVector.copy(normalVectors[totalNumberOfShapes]);
	positionVector.multiplyScalar(currentSphereScale);
	currentParentSpherePosition.copy(positionVector);
	spheres[totalNumberOfShapes].position.copy(currentParentSpherePosition);
	spheres[totalNumberOfShapes].scale.set(currentSphereScale, currentSphereScale, currentSphereScale);
	spheres[totalNumberOfShapes].updateMatrixWorld(true);
	totalNumberOfShapes++;

	// NOW RECURSIVELY CREATE SMALLER SPHERES IN FRACTAL FASHION

	// ITERATION 1, will result in 1 large root parent sphere + 9 child spheres = 10 total spheres
		currentParentSpherePosition.copy(spheres[0].position);
		normalVector.copy(normalVectors[0]);

		parentSphereScale = currentSphereScale;
		currentSphereScale *= (1 / 3);
		
		if (Math.abs(normalVector.y) < 0.9)
			tangentVector.crossVectors(worldUpVector, normalVector);
		else
			tangentVector.crossVectors(worldRightVector, normalVector);

		tangentVector.normalize();
		bitangentVector.crossVectors(tangentVector, normalVector);
		tangentVector.multiplyScalar(parentSphereScale + currentSphereScale);

		for (let s1 = totalNumberOfShapes; s1 < (totalNumberOfShapes + 6); s1++)
		{
			tangentVector.applyAxisAngle(normalVector, s1_Angle);
			normalVectors[s1] = new THREE.Vector3();
			normalVectors[s1].copy(tangentVector).normalize();
			spheres[s1] = new THREE.Object3D();
			spheres[s1].position.copy(currentParentSpherePosition);
			spheres[s1].position.add(tangentVector);
			spheres[s1].scale.set(currentSphereScale, currentSphereScale, currentSphereScale);
			spheres[s1].updateMatrixWorld(true);
		}
		totalNumberOfShapes += 6;

		tangentVector.applyAxisAngle(bitangentVector, THREE.MathUtils.degToRad(55));
		tangentVector.applyAxisAngle(normalVector, THREE.MathUtils.degToRad(30));

		for (let s2 = totalNumberOfShapes; s2 < (totalNumberOfShapes + 3); s2++)
		{
			tangentVector.applyAxisAngle(normalVector, s2_Angle);
			normalVectors[s2] = new THREE.Vector3();
			normalVectors[s2].copy(tangentVector).normalize();
			spheres[s2] = new THREE.Object3D();
			spheres[s2].position.copy(currentParentSpherePosition);
			spheres[s2].position.add(tangentVector);
			spheres[s2].scale.set(currentSphereScale, currentSphereScale, currentSphereScale);
			spheres[s2].updateMatrixWorld(true);
		}
		totalNumberOfShapes += 3;


	// ITERATION 2, will result in 1 root parent sphere + 9 + (9*9) child spheres = 91 total spheres
	parentSphereScale = currentSphereScale;
	currentSphereScale *= (1 / 3);

	for (let i = 1; i < 10; i++)
	{
		currentParentSpherePosition.copy(spheres[i].position);
		normalVector.copy(normalVectors[i]);
		
		if (Math.abs(normalVector.y) < 0.9)
			tangentVector.crossVectors(worldUpVector, normalVector);
		else
			tangentVector.crossVectors(worldRightVector, normalVector);

		tangentVector.normalize();
		bitangentVector.crossVectors(tangentVector, normalVector);
		tangentVector.multiplyScalar(parentSphereScale + currentSphereScale);

		for (let s1 = totalNumberOfShapes; s1 < (totalNumberOfShapes + 6); s1++)
		{
			tangentVector.applyAxisAngle(normalVector, s1_Angle);
			normalVectors[s1] = new THREE.Vector3();
			normalVectors[s1].copy(tangentVector).normalize();
			spheres[s1] = new THREE.Object3D();
			spheres[s1].position.copy(currentParentSpherePosition);
			spheres[s1].position.add(tangentVector);
			spheres[s1].scale.set(currentSphereScale, currentSphereScale, currentSphereScale);
			spheres[s1].updateMatrixWorld(true);
		}
		totalNumberOfShapes += 6;

		tangentVector.applyAxisAngle(bitangentVector, THREE.MathUtils.degToRad(55));
		tangentVector.applyAxisAngle(normalVector, THREE.MathUtils.degToRad(30));

		for (let s2 = totalNumberOfShapes; s2 < (totalNumberOfShapes + 3); s2++)
		{
			tangentVector.applyAxisAngle(normalVector, s2_Angle);
			normalVectors[s2] = new THREE.Vector3();
			normalVectors[s2].copy(tangentVector).normalize();
			spheres[s2] = new THREE.Object3D();
			spheres[s2].position.copy(currentParentSpherePosition);
			spheres[s2].position.add(tangentVector);
			spheres[s2].scale.set(currentSphereScale, currentSphereScale, currentSphereScale);
			spheres[s2].updateMatrixWorld(true);
		}
		totalNumberOfShapes += 3;
	} // end for (let i = 1; i < 10; i++)


	// ITERATION 3, will result in 1 root parent sphere + 9 + (9*9) + (9*9*9) child spheres = 820 total spheres
	parentSphereScale = currentSphereScale;
	currentSphereScale *= (1 / 3);

	for (let i = 10; i < 91; i++)
	{
		currentParentSpherePosition.copy(spheres[i].position);
		normalVector.copy(normalVectors[i]);
		
		if (Math.abs(normalVector.y) < 0.9)
			tangentVector.crossVectors(worldUpVector, normalVector);
		else
			tangentVector.crossVectors(worldRightVector, normalVector);

		tangentVector.normalize();
		bitangentVector.crossVectors(tangentVector, normalVector);
		tangentVector.multiplyScalar(parentSphereScale + currentSphereScale);

		for (let s1 = totalNumberOfShapes; s1 < (totalNumberOfShapes + 6); s1++)
		{
			tangentVector.applyAxisAngle(normalVector, s1_Angle);
			normalVectors[s1] = new THREE.Vector3();
			normalVectors[s1].copy(tangentVector).normalize();
			spheres[s1] = new THREE.Object3D();
			spheres[s1].position.copy(currentParentSpherePosition);
			spheres[s1].position.add(tangentVector);
			spheres[s1].scale.set(currentSphereScale, currentSphereScale, currentSphereScale);
			spheres[s1].updateMatrixWorld(true);
		}
		totalNumberOfShapes += 6;

		tangentVector.applyAxisAngle(bitangentVector, THREE.MathUtils.degToRad(55));
		tangentVector.applyAxisAngle(normalVector, THREE.MathUtils.degToRad(30));

		for (let s2 = totalNumberOfShapes; s2 < (totalNumberOfShapes + 3); s2++)
		{
			tangentVector.applyAxisAngle(normalVector, s2_Angle);
			normalVectors[s2] = new THREE.Vector3();
			normalVectors[s2].copy(tangentVector).normalize();
			spheres[s2] = new THREE.Object3D();
			spheres[s2].position.copy(currentParentSpherePosition);
			spheres[s2].position.add(tangentVector);
			spheres[s2].scale.set(currentSphereScale, currentSphereScale, currentSphereScale);
			spheres[s2].updateMatrixWorld(true);
		}
		totalNumberOfShapes += 3;
	} // end for (let i = 11; i < 91; i++)


	// ITERATION 4, will result in 1 root parent sphere + 9 + (9*9) + (9*9*9) + (9*9*9*9) child spheres = 7,381 total spheres
	parentSphereScale = currentSphereScale;
	currentSphereScale *= (1 / 3);

	for (let i = 91; i < 820; i++)
	{
		currentParentSpherePosition.copy(spheres[i].position);
		normalVector.copy(normalVectors[i]);
		
		if (Math.abs(normalVector.y) < 0.9)
			tangentVector.crossVectors(worldUpVector, normalVector);
		else
			tangentVector.crossVectors(worldRightVector, normalVector);

		tangentVector.normalize();
		bitangentVector.crossVectors(tangentVector, normalVector);
		tangentVector.multiplyScalar(parentSphereScale + currentSphereScale);

		for (let s1 = totalNumberOfShapes; s1 < (totalNumberOfShapes + 6); s1++)
		{
			tangentVector.applyAxisAngle(normalVector, s1_Angle);
			normalVectors[s1] = new THREE.Vector3();
			normalVectors[s1].copy(tangentVector).normalize();
			spheres[s1] = new THREE.Object3D();
			spheres[s1].position.copy(currentParentSpherePosition);
			spheres[s1].position.add(tangentVector);
			spheres[s1].scale.set(currentSphereScale, currentSphereScale, currentSphereScale);
			spheres[s1].updateMatrixWorld(true);
		}
		totalNumberOfShapes += 6;

		tangentVector.applyAxisAngle(bitangentVector, THREE.MathUtils.degToRad(55));
		tangentVector.applyAxisAngle(normalVector, THREE.MathUtils.degToRad(30));

		for (let s2 = totalNumberOfShapes; s2 < (totalNumberOfShapes + 3); s2++)
		{
			tangentVector.applyAxisAngle(normalVector, s2_Angle);
			normalVectors[s2] = new THREE.Vector3();
			normalVectors[s2].copy(tangentVector).normalize();
			spheres[s2] = new THREE.Object3D();
			spheres[s2].position.copy(currentParentSpherePosition);
			spheres[s2].position.add(tangentVector);
			spheres[s2].scale.set(currentSphereScale, currentSphereScale, currentSphereScale);
			spheres[s2].updateMatrixWorld(true);
		}
		totalNumberOfShapes += 3;
	} // end for (let i = 91; i < 820; i++)


	// ITERATION 5, will result in 1 root parent sphere + 9 + (9*9) + (9*9*9) + (9*9*9*9) + (9*9*9*9*9) child spheres = 66,430 total spheres
	parentSphereScale = currentSphereScale;
	currentSphereScale *= (1 / 3);

	for (let i = 820; i < 7381; i++)
	{
		currentParentSpherePosition.copy(spheres[i].position);
		normalVector.copy(normalVectors[i]);
		
		if (Math.abs(normalVector.y) < 0.9)
			tangentVector.crossVectors(worldUpVector, normalVector);
		else
			tangentVector.crossVectors(worldRightVector, normalVector);

		tangentVector.normalize();
		bitangentVector.crossVectors(tangentVector, normalVector);
		tangentVector.multiplyScalar(parentSphereScale + currentSphereScale);

		for (let s1 = totalNumberOfShapes; s1 < (totalNumberOfShapes + 6); s1++)
		{
			tangentVector.applyAxisAngle(normalVector, s1_Angle);
			// the following 2 lines are not needed for this final iteration
			///normalVectors[s1] = new THREE.Vector3();
			///normalVectors[s1].copy(tangentVector).normalize();
			spheres[s1] = new THREE.Object3D();
			spheres[s1].position.copy(currentParentSpherePosition);
			spheres[s1].position.add(tangentVector);
			spheres[s1].scale.set(currentSphereScale, currentSphereScale, currentSphereScale);
			spheres[s1].updateMatrixWorld(true);
		}
		totalNumberOfShapes += 6;

		tangentVector.applyAxisAngle(bitangentVector, THREE.MathUtils.degToRad(55));
		tangentVector.applyAxisAngle(normalVector, THREE.MathUtils.degToRad(30));

		for (let s2 = totalNumberOfShapes; s2 < (totalNumberOfShapes + 3); s2++)
		{
			tangentVector.applyAxisAngle(normalVector, s2_Angle);
			// the following 2 lines are not needed for this final iteration
			///normalVectors[s2] = new THREE.Vector3();
			///normalVectors[s2].copy(tangentVector).normalize();
			spheres[s2] = new THREE.Object3D();
			spheres[s2].position.copy(currentParentSpherePosition);
			spheres[s2].position.add(tangentVector);
			spheres[s2].scale.set(currentSphereScale, currentSphereScale, currentSphereScale);
			spheres[s2].updateMatrixWorld(true);
		}
		totalNumberOfShapes += 3;
	} // end for (let i = 820; i < 7381; i++)




	console.log("Shape count: " + totalNumberOfShapes);

	totalWork = new Uint32Array(totalNumberOfShapes);

	shape_array = new Float32Array(2048 * 2048 * 4);
	// 2048 = width of texture, 2048 = height of texture, 4 = r,g,b, and a components

	aabb_array = new Float32Array(2048 * 2048 * 4);
	// 2048 = width of texture, 2048 = height of texture, 4 = r,g,b, and a components


	for (let i = 0; i < totalNumberOfShapes; i++) 
	{
		invMatrix.copy(spheres[i].matrixWorld).invert();
		el = invMatrix.elements;

		//slot 0                       Shape inverse transform Matrix 4x4 (16 elements total)
		shape_array[32 * i + 0] = el[0]; // r or x // shape inv transform Matrix elements[0]
		shape_array[32 * i + 1] = el[1]; // g or y // shape inv transform Matrix elements[1] 
		shape_array[32 * i + 2] = el[2]; // b or z // shape inv transform Matrix elements[2]
		shape_array[32 * i + 3] = el[3]; // a or w // shape inv transform Matrix elements[3]

		//slot 1
		shape_array[32 * i + 4] = el[4]; // r or x // shape inv transform Matrix elements[4]
		shape_array[32 * i + 5] = el[5]; // g or y // shape inv transform Matrix elements[5]
		shape_array[32 * i + 6] = el[6]; // b or z // shape inv transform Matrix elements[6]
		shape_array[32 * i + 7] = el[7]; // a or w // shape inv transform Matrix elements[7]

		//slot 2
		shape_array[32 * i + 8] = el[8]; // r or x // shape inv transform Matrix elements[8]
		shape_array[32 * i + 9] = el[9]; // g or y // shape inv transform Matrix elements[9]
		shape_array[32 * i + 10] = el[10]; // b or z // shape inv transform Matrix elements[10]
		shape_array[32 * i + 11] = el[11]; // a or w // shape inv transform Matrix elements[11]

		//slot 3
		shape_array[32 * i + 12] = el[12]; // r or x // shape transform Matrix elements[12]
		shape_array[32 * i + 13] = el[13]; // g or y // shape transform Matrix elements[13]
		shape_array[32 * i + 14] = el[14]; // b or z // shape transform Matrix elements[14]
		shape_array[32 * i + 15] = el[15]; // a or w // shape transform Matrix elements[15]

		//slot 4
		shape_array[32 * i + 16] = 1; // r or x // shape type id#  (0: box, 1: sphere, 2: cylinder, 3: cone, 4: paraboloid, etc)
		shape_array[32 * i + 17] = Math.floor(Math.random() * 4) + 1; // g or y // material type id# (0: LIGHT, 1: DIFF, 2: REFR, 3: SPEC, 4: COAT, etc)
		shape_array[32 * i + 18] = 0.0; // b or z // material Metalness - default: 0.0(no metal, a dielectric), 1.0 would be purely metal
		shape_array[32 * i + 19] = 0.0; // a or w // material Roughness - default: 0.0(no roughness, totally smooth)

		//slot 5
		shape_array[32 * i + 20] = Math.random(); // r or x // material albedo color R (if LIGHT, this is also its emissive color R)
		shape_array[32 * i + 21] = Math.random(); // g or y // material albedo color G (if LIGHT, this is also its emissive color G)
		shape_array[32 * i + 22] = Math.random(); // b or z // material albedo color B (if LIGHT, this is also its emissive color B)
		shape_array[32 * i + 23] = 1.0; // a or w // material Opacity (Alpha) - default: 1.0 (fully opaque), 0.0 is fully transparent

		//slot 6
		shape_array[32 * i + 24] = 1.0; // r or x // material Index of Refraction(IoR) - default: 1.0(air) (or 1.5(glass), 1.33(water), etc)
		shape_array[32 * i + 25] = 0.0; // g or y // material ClearCoat Roughness - default: 0.0 (no roughness, totally smooth)
		shape_array[32 * i + 26] = 1.5; // b or z // material ClearCoat IoR - default: 1.5(thick ClearCoat)
		shape_array[32 * i + 27] = 0; // a or w // material data

		//slot 7
		shape_array[32 * i + 28] = 0; // r or x // material data
		shape_array[32 * i + 29] = 0; // g or y // material data
		shape_array[32 * i + 30] = 0; // b or z // material data
		shape_array[32 * i + 31] = 0; // a or w // material data


		shapeBoundingBox_minCorner.set(-1, -1, -1);
		shapeBoundingBox_maxCorner.set(1, 1, 1);
		shapeBoundingBox_minCorner.multiplyScalar(spheres[i].scale.x);
		shapeBoundingBox_maxCorner.multiplyScalar(spheres[i].scale.x);
		shapeBoundingBox_minCorner.add(spheres[i].position);
		shapeBoundingBox_maxCorner.add(spheres[i].position);
		shapeBoundingBox_centroid.copy(spheres[i].position);

		aabb_array[9 * i + 0] = shapeBoundingBox_minCorner.x;
		aabb_array[9 * i + 1] = shapeBoundingBox_minCorner.y;
		aabb_array[9 * i + 2] = shapeBoundingBox_minCorner.z;
		aabb_array[9 * i + 3] = shapeBoundingBox_maxCorner.x;
		aabb_array[9 * i + 4] = shapeBoundingBox_maxCorner.y;
		aabb_array[9 * i + 5] = shapeBoundingBox_maxCorner.z;
		aabb_array[9 * i + 6] = shapeBoundingBox_centroid.x;
		aabb_array[9 * i + 7] = shapeBoundingBox_centroid.y;
		aabb_array[9 * i + 8] = shapeBoundingBox_centroid.z;

		totalWork[i] = i;
	} // end for (let i = 0; i < totalNumberOfShapes; i++)


	console.time("BvhGeneration");
	console.log("BvhGeneration...");

	// Build the BVH acceleration structure, which starts with a large bounding box ('root' of the tree) 
	// that surrounds all of the shapes.  It then subdivides each 'parent' box into 2 smaller 'child' boxes.  
	// It continues until it reaches 1 shape, which it then designates as a 'leaf'
	BVH_Build_Iterative(totalWork, aabb_array);
	//console.log(buildnodes);

	console.timeEnd("BvhGeneration");


	shapeDataTexture = new THREE.DataTexture(shape_array,
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

	shapeDataTexture.flipY = false;
	shapeDataTexture.generateMipmaps = false;
	shapeDataTexture.needsUpdate = true;

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


	// In addition to the default GUI on all demos, add any special GUI elements that this particular demo requires

	material_TypeObject = {
		Sphereflake_Material: 'ClearCoat Diffuse'
	};
	
	function handleMaterialTypeChange() 
	{
		changeMaterialType = true;
	}
	

	material_TypeController = gui.add(material_TypeObject, 'Sphereflake_Material', ['Diffuse', 
		'Transparent Refractive', 'Metal', 'ClearCoat Diffuse', 'Random']).onChange(handleMaterialTypeChange);

	
	// scene/demo-specific uniforms go here
	pathTracingUniforms.tShape_DataTexture = { value: shapeDataTexture };
	pathTracingUniforms.tAABB_DataTexture = { value: aabbDataTexture };
	pathTracingUniforms.uMaterialType = { value: 4 };


} // end function initSceneData()



// called automatically from within the animate() function (located in InitCommon.js file)
function updateVariablesAndUniforms() 
{

	if (changeMaterialType) 
	{
		matType = material_TypeController.getValue();

		if (matType == 'Diffuse') 
		{
			pathTracingUniforms.uMaterialType.value = 1;
		}
		else if (matType == 'Transparent Refractive') 
		{
			pathTracingUniforms.uMaterialType.value = 2;
		}
		else if (matType == 'Metal') 
		{
			pathTracingUniforms.uMaterialType.value = 3;	
		}
		else if (matType == 'ClearCoat Diffuse') 
		{
			pathTracingUniforms.uMaterialType.value = 4;	
		}
		else if (matType == 'Random') 
		{
			pathTracingUniforms.uMaterialType.value = 1000;	
		}
			
		cameraIsMoving = true;
		changeMaterialType = false;
	}


	// INFO
	cameraInfoElement.innerHTML = "FOV: " + worldCamera.fov + " / Aperture: " + apertureSize.toFixed(2) + " / FocusDistance: " + focusDistance + "<br>" + "Samples: " + sampleCounter;

} // end function updateVariablesAndUniforms()



init(); // init app and start animating
