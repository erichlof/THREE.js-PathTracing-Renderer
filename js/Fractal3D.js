// scene/demo-specific variables go here
let totalNumberOfShapes = 0;
let totalNumberOfParents = 0;
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
let boxes = [];
let currentBoxFractalScale = 1000;
let parentBoxFractalScale = 1;
let currentParentPosition = new THREE.Vector3();
let parentBoxFractalPositions = [];
let positionOffsetVector = new THREE.Vector3();
let X, Y, Z;


let shape = new THREE.Object3D();
let invMatrix = new THREE.Matrix4();
let el; // elements of the invMatrix

// let material_TypeObject;
// let material_TypeController;
// let changeMaterialType = false;
// let matType = 0;

let sunDirTransform_RotateXController, sunDirTransform_RotateXObject;
let sunDirTransform_RotateYController, sunDirTransform_RotateYObject;
let needChangeSunDirRotation = false;
let viewpoint_PresetController;
let viewpoint_PresetObject;
let needChangeViewpointPreset = false;
let sunObject3D = new THREE.Object3D();
let sunDirRotationX, sunDirRotationY;
let sunPitchObject = new THREE.Object3D();
//sunPitchObject.add(sunObject3D);
let sunYawObject = new THREE.Object3D();
sunYawObject.add(sunPitchObject);


function createBoxFrameFractal(parentPositionX, parentPositionY, parentPositionZ)
{
	
	currentParentPosition.set(parentPositionX, parentPositionY + currentBoxFractalScale, parentPositionZ);
	
	// bottom front rectangular box
	boxes[totalNumberOfShapes] = new THREE.Object3D();
	boxes[totalNumberOfShapes].scale.set(currentBoxFractalScale, currentBoxFractalScale * 0.2, currentBoxFractalScale * 0.2);
	
	boxes[totalNumberOfShapes].position.copy(currentParentPosition);
	positionOffsetVector.set(0, -currentBoxFractalScale * 0.8, currentBoxFractalScale * 0.8);
	boxes[totalNumberOfShapes].position.add(positionOffsetVector);
	
	boxes[totalNumberOfShapes].updateMatrixWorld(true);
	totalNumberOfShapes++;
	// bottom back rectangular box
	boxes[totalNumberOfShapes] = new THREE.Object3D();
	boxes[totalNumberOfShapes].scale.set(currentBoxFractalScale, currentBoxFractalScale * 0.2, currentBoxFractalScale * 0.2);
	
	boxes[totalNumberOfShapes].position.copy(currentParentPosition);
	positionOffsetVector.set(0, -currentBoxFractalScale * 0.8, -currentBoxFractalScale * 0.8);
	boxes[totalNumberOfShapes].position.add(positionOffsetVector);
	
	boxes[totalNumberOfShapes].updateMatrixWorld(true);
	totalNumberOfShapes++;

	// top front rectangular box
	boxes[totalNumberOfShapes] = new THREE.Object3D();
	boxes[totalNumberOfShapes].scale.set(currentBoxFractalScale, currentBoxFractalScale * 0.2, currentBoxFractalScale * 0.2);
	
	boxes[totalNumberOfShapes].position.copy(currentParentPosition);
	positionOffsetVector.set(0, currentBoxFractalScale * 0.8, currentBoxFractalScale * 0.8);
	boxes[totalNumberOfShapes].position.add(positionOffsetVector);
	
	boxes[totalNumberOfShapes].updateMatrixWorld(true);
	totalNumberOfShapes++;
	// top back rectangular box
	boxes[totalNumberOfShapes] = new THREE.Object3D();
	boxes[totalNumberOfShapes].scale.set(currentBoxFractalScale, currentBoxFractalScale * 0.2, currentBoxFractalScale * 0.2);
	
	boxes[totalNumberOfShapes].position.copy(currentParentPosition);
	positionOffsetVector.set(0, currentBoxFractalScale * 0.8, -currentBoxFractalScale * 0.8);
	boxes[totalNumberOfShapes].position.add(positionOffsetVector);
	
	boxes[totalNumberOfShapes].updateMatrixWorld(true);
	totalNumberOfShapes++;

	// left front vertical rectangular box
	boxes[totalNumberOfShapes] = new THREE.Object3D();
	boxes[totalNumberOfShapes].scale.set(currentBoxFractalScale * 0.2, currentBoxFractalScale * 0.6, currentBoxFractalScale * 0.2);
	
	boxes[totalNumberOfShapes].position.copy(currentParentPosition);
	positionOffsetVector.set(-currentBoxFractalScale * 0.8, 0, currentBoxFractalScale * 0.8);
	boxes[totalNumberOfShapes].position.add(positionOffsetVector);
	
	boxes[totalNumberOfShapes].updateMatrixWorld(true);
	totalNumberOfShapes++;
	// right front vertical rectangular box
	boxes[totalNumberOfShapes] = new THREE.Object3D();
	boxes[totalNumberOfShapes].scale.set(currentBoxFractalScale * 0.2, currentBoxFractalScale * 0.6, currentBoxFractalScale * 0.2);
	
	boxes[totalNumberOfShapes].position.copy(currentParentPosition);
	positionOffsetVector.set(currentBoxFractalScale * 0.8, 0, currentBoxFractalScale * 0.8);
	boxes[totalNumberOfShapes].position.add(positionOffsetVector);
	
	boxes[totalNumberOfShapes].updateMatrixWorld(true);
	totalNumberOfShapes++;

	// left back vertical rectangular box
	boxes[totalNumberOfShapes] = new THREE.Object3D();
	boxes[totalNumberOfShapes].scale.set(currentBoxFractalScale * 0.2, currentBoxFractalScale * 0.6, currentBoxFractalScale * 0.2);
	
	boxes[totalNumberOfShapes].position.copy(currentParentPosition);
	positionOffsetVector.set(-currentBoxFractalScale * 0.8, 0, -currentBoxFractalScale * 0.8);
	boxes[totalNumberOfShapes].position.add(positionOffsetVector);
	
	boxes[totalNumberOfShapes].updateMatrixWorld(true);
	totalNumberOfShapes++;
	// right back vertical rectangular box
	boxes[totalNumberOfShapes] = new THREE.Object3D();
	boxes[totalNumberOfShapes].scale.set(currentBoxFractalScale * 0.2, currentBoxFractalScale * 0.6, currentBoxFractalScale * 0.2);
	
	boxes[totalNumberOfShapes].position.copy(currentParentPosition);
	positionOffsetVector.set(currentBoxFractalScale * 0.8, 0, -currentBoxFractalScale * 0.8);
	boxes[totalNumberOfShapes].position.add(positionOffsetVector);
	
	boxes[totalNumberOfShapes].updateMatrixWorld(true);
	totalNumberOfShapes++;

	// left side bottom horizontal rectangular box
	boxes[totalNumberOfShapes] = new THREE.Object3D();
	boxes[totalNumberOfShapes].scale.set(currentBoxFractalScale * 0.2, currentBoxFractalScale * 0.2, currentBoxFractalScale * 0.6);
	
	boxes[totalNumberOfShapes].position.copy(currentParentPosition);
	positionOffsetVector.set(-currentBoxFractalScale * 0.8, -currentBoxFractalScale * 0.8, 0);
	boxes[totalNumberOfShapes].position.add(positionOffsetVector);
	
	boxes[totalNumberOfShapes].updateMatrixWorld(true);
	totalNumberOfShapes++;
	// right side bottom vertical rectangular box
	boxes[totalNumberOfShapes] = new THREE.Object3D();
	boxes[totalNumberOfShapes].scale.set(currentBoxFractalScale * 0.2, currentBoxFractalScale * 0.2, currentBoxFractalScale * 0.6);
	
	boxes[totalNumberOfShapes].position.copy(currentParentPosition);
	positionOffsetVector.set(currentBoxFractalScale * 0.8, -currentBoxFractalScale * 0.8, 0);
	boxes[totalNumberOfShapes].position.add(positionOffsetVector);
	
	boxes[totalNumberOfShapes].updateMatrixWorld(true);
	totalNumberOfShapes++;

	// left side top horizontal rectangular box
	boxes[totalNumberOfShapes] = new THREE.Object3D();
	boxes[totalNumberOfShapes].scale.set(currentBoxFractalScale * 0.2, currentBoxFractalScale * 0.2, currentBoxFractalScale * 0.6);
	
	boxes[totalNumberOfShapes].position.copy(currentParentPosition);
	positionOffsetVector.set(-currentBoxFractalScale * 0.8, currentBoxFractalScale * 0.8, 0);
	boxes[totalNumberOfShapes].position.add(positionOffsetVector);
	
	boxes[totalNumberOfShapes].updateMatrixWorld(true);
	totalNumberOfShapes++;
	// right side top vertical rectangular box
	boxes[totalNumberOfShapes] = new THREE.Object3D();
	boxes[totalNumberOfShapes].scale.set(currentBoxFractalScale * 0.2, currentBoxFractalScale * 0.2, currentBoxFractalScale * 0.6);
	
	boxes[totalNumberOfShapes].position.copy(currentParentPosition);
	positionOffsetVector.set(currentBoxFractalScale * 0.8, currentBoxFractalScale * 0.8, 0);
	boxes[totalNumberOfShapes].position.add(positionOffsetVector);
	
	boxes[totalNumberOfShapes].updateMatrixWorld(true);
	totalNumberOfShapes++;

} // end function createBoxFrameFractal(parentPositionX, parentPositionY, parentPositionZ)



// called automatically from within initTHREEjs() function (located in InitCommon.js file)
function initSceneData() 
{
	demoFragmentShaderFileName = 'Fractal3D_Fragment.glsl';

	// scene/demo-specific three.js objects setup goes here
	sceneIsDynamic = false;

	cameraFlightSpeed = 200;

	// pixelRatio is resolution - range: 0.5(half resolution) to 1.0(full resolution)
	pixelRatio = mouseControl ? 0.75 : 0.75;

	EPS_intersect = 0.01;

	// set camera's field of view
	worldCamera.fov = 60;
	focusDistance = 600.0;
	apertureChangeSpeed = 20;

	// position and orient camera
	cameraControlsObject.position.set(0, 800, 2500);
	///cameraControlsYawObject.rotation.y = 0.0;
	// look slightly upward
	///cameraControlsPitchObject.rotation.x = 0.005;

	
	//sunPitchObject.add(sunObject3D);
	sunYawObject.add(sunPitchObject);


	// FIRST, CREATE LARGEST CENTRAL BOX FRAME (made from 12 rectangular box pieces altogether)
	parentBoxFractalPositions[totalNumberOfParents] = new THREE.Vector3();
	parentBoxFractalPositions[totalNumberOfParents].set(0, 0, 0);
	X = parentBoxFractalPositions[totalNumberOfParents].x;
	Y = parentBoxFractalPositions[totalNumberOfParents].y;
	Z = parentBoxFractalPositions[totalNumberOfParents].z;
	createBoxFrameFractal(X, Y, Z);
	totalNumberOfParents++;
	

	// NOW CREATE SMALLER CHILDREN BOX FRAMES IN A FRACTAL FASHION
	currentBoxFractalScale *= 0.5;

	for (let i = 0; i < 1; i++) 
	{
		X = parentBoxFractalPositions[i].x;
		Y = parentBoxFractalPositions[i].y;
		Z = parentBoxFractalPositions[i].z;
		
		// front left
		createBoxFrameFractal(X - currentBoxFractalScale * 2.2, Y, Z + currentBoxFractalScale * 2.2);
		parentBoxFractalPositions[totalNumberOfParents] = new THREE.Vector3(X - currentBoxFractalScale * 2.2, Y, Z + currentBoxFractalScale * 2.2);
		totalNumberOfParents++;
		// front right
		createBoxFrameFractal(X + currentBoxFractalScale * 2.2, Y, Z + currentBoxFractalScale * 2.2);
		parentBoxFractalPositions[totalNumberOfParents] = new THREE.Vector3(X + currentBoxFractalScale * 2.2, Y, Z + currentBoxFractalScale * 2.2);
		totalNumberOfParents++;
		// back left
		createBoxFrameFractal(X - currentBoxFractalScale * 2.2, Y, Z - currentBoxFractalScale * 2.2);
		parentBoxFractalPositions[totalNumberOfParents] = new THREE.Vector3(X - currentBoxFractalScale * 2.2, Y, Z - currentBoxFractalScale * 2.2);
		totalNumberOfParents++;
		// back right
		createBoxFrameFractal(X + currentBoxFractalScale * 2.2, Y, Z - currentBoxFractalScale * 2.2);
		parentBoxFractalPositions[totalNumberOfParents] = new THREE.Vector3(X + currentBoxFractalScale * 2.2, Y, Z - currentBoxFractalScale * 2.2);
		totalNumberOfParents++;
	}


	currentBoxFractalScale *= 0.5;

	for (let i = 1; i < 5; i++) 
	{
		X = parentBoxFractalPositions[i].x;
		Y = parentBoxFractalPositions[i].y;
		Z = parentBoxFractalPositions[i].z;
		
		// front left
		createBoxFrameFractal(X - currentBoxFractalScale * 2.2, Y, Z + currentBoxFractalScale * 2.2);
		parentBoxFractalPositions[totalNumberOfParents] = new THREE.Vector3(X - currentBoxFractalScale * 2.2, Y, Z + currentBoxFractalScale * 2.2);
		totalNumberOfParents++;
		// front right
		createBoxFrameFractal(X + currentBoxFractalScale * 2.2, Y, Z + currentBoxFractalScale * 2.2);
		parentBoxFractalPositions[totalNumberOfParents] = new THREE.Vector3(X + currentBoxFractalScale * 2.2, Y, Z + currentBoxFractalScale * 2.2);
		totalNumberOfParents++;
		// back left
		createBoxFrameFractal(X - currentBoxFractalScale * 2.2, Y, Z - currentBoxFractalScale * 2.2);
		parentBoxFractalPositions[totalNumberOfParents] = new THREE.Vector3(X - currentBoxFractalScale * 2.2, Y, Z - currentBoxFractalScale * 2.2);
		totalNumberOfParents++;
		// back right
		createBoxFrameFractal(X + currentBoxFractalScale * 2.2, Y, Z - currentBoxFractalScale * 2.2);
		parentBoxFractalPositions[totalNumberOfParents] = new THREE.Vector3(X + currentBoxFractalScale * 2.2, Y, Z - currentBoxFractalScale * 2.2);
		totalNumberOfParents++;
	}


	currentBoxFractalScale *= 0.5;
	
	for (let i = 5; i < 21; i++) 
	{
		X = parentBoxFractalPositions[i].x;
		Y = parentBoxFractalPositions[i].y;
		Z = parentBoxFractalPositions[i].z;
		
		// front left
		createBoxFrameFractal(X - currentBoxFractalScale * 2.2, Y, Z + currentBoxFractalScale * 2.2);
		parentBoxFractalPositions[totalNumberOfParents] = new THREE.Vector3(X - currentBoxFractalScale * 2.2, Y, Z + currentBoxFractalScale * 2.2);
		totalNumberOfParents++;
		// front right
		createBoxFrameFractal(X + currentBoxFractalScale * 2.2, Y, Z + currentBoxFractalScale * 2.2);
		parentBoxFractalPositions[totalNumberOfParents] = new THREE.Vector3(X + currentBoxFractalScale * 2.2, Y, Z + currentBoxFractalScale * 2.2);
		totalNumberOfParents++;
		// back left
		createBoxFrameFractal(X - currentBoxFractalScale * 2.2, Y, Z - currentBoxFractalScale * 2.2);
		parentBoxFractalPositions[totalNumberOfParents] = new THREE.Vector3(X - currentBoxFractalScale * 2.2, Y, Z - currentBoxFractalScale * 2.2);
		totalNumberOfParents++;
		// back right
		createBoxFrameFractal(X + currentBoxFractalScale * 2.2, Y, Z - currentBoxFractalScale * 2.2);
		parentBoxFractalPositions[totalNumberOfParents] = new THREE.Vector3(X + currentBoxFractalScale * 2.2, Y, Z - currentBoxFractalScale * 2.2);
		totalNumberOfParents++;
	}


	currentBoxFractalScale *= 0.5;
	
	for (let i = 21; i < 85; i++) 
	{
		X = parentBoxFractalPositions[i].x;
		Y = parentBoxFractalPositions[i].y;
		Z = parentBoxFractalPositions[i].z;
		
		// front left
		createBoxFrameFractal(X - currentBoxFractalScale * 2.2, Y, Z + currentBoxFractalScale * 2.2);
		parentBoxFractalPositions[totalNumberOfParents] = new THREE.Vector3(X - currentBoxFractalScale * 2.2, Y, Z + currentBoxFractalScale * 2.2);
		totalNumberOfParents++;
		// front right
		createBoxFrameFractal(X + currentBoxFractalScale * 2.2, Y, Z + currentBoxFractalScale * 2.2);
		parentBoxFractalPositions[totalNumberOfParents] = new THREE.Vector3(X + currentBoxFractalScale * 2.2, Y, Z + currentBoxFractalScale * 2.2);
		totalNumberOfParents++;
		// back left
		createBoxFrameFractal(X - currentBoxFractalScale * 2.2, Y, Z - currentBoxFractalScale * 2.2);
		parentBoxFractalPositions[totalNumberOfParents] = new THREE.Vector3(X - currentBoxFractalScale * 2.2, Y, Z - currentBoxFractalScale * 2.2);
		totalNumberOfParents++;
		// back right
		createBoxFrameFractal(X + currentBoxFractalScale * 2.2, Y, Z - currentBoxFractalScale * 2.2);
		parentBoxFractalPositions[totalNumberOfParents] = new THREE.Vector3(X + currentBoxFractalScale * 2.2, Y, Z - currentBoxFractalScale * 2.2);
		totalNumberOfParents++;
	}


	currentBoxFractalScale *= 0.5;
	
	for (let i = 85; i < 341; i++) 
	{
		X = parentBoxFractalPositions[i].x;
		Y = parentBoxFractalPositions[i].y;
		Z = parentBoxFractalPositions[i].z;
		
		// front left
		createBoxFrameFractal(X - currentBoxFractalScale * 2.2, Y, Z + currentBoxFractalScale * 2.2);
		parentBoxFractalPositions[totalNumberOfParents] = new THREE.Vector3(X - currentBoxFractalScale * 2.2, Y, Z + currentBoxFractalScale * 2.2);
		totalNumberOfParents++;
		// front right
		createBoxFrameFractal(X + currentBoxFractalScale * 2.2, Y, Z + currentBoxFractalScale * 2.2);
		parentBoxFractalPositions[totalNumberOfParents] = new THREE.Vector3(X + currentBoxFractalScale * 2.2, Y, Z + currentBoxFractalScale * 2.2);
		totalNumberOfParents++;
		// back left
		createBoxFrameFractal(X - currentBoxFractalScale * 2.2, Y, Z - currentBoxFractalScale * 2.2);
		parentBoxFractalPositions[totalNumberOfParents] = new THREE.Vector3(X - currentBoxFractalScale * 2.2, Y, Z - currentBoxFractalScale * 2.2);
		totalNumberOfParents++;
		// back right
		createBoxFrameFractal(X + currentBoxFractalScale * 2.2, Y, Z - currentBoxFractalScale * 2.2);
		parentBoxFractalPositions[totalNumberOfParents] = new THREE.Vector3(X + currentBoxFractalScale * 2.2, Y, Z - currentBoxFractalScale * 2.2);
		totalNumberOfParents++;
	}


	currentBoxFractalScale *= 0.5;
	
	for (let i = 341; i < 1365; i++) 
	{
		X = parentBoxFractalPositions[i].x;
		Y = parentBoxFractalPositions[i].y;
		Z = parentBoxFractalPositions[i].z;
		
		// front left
		createBoxFrameFractal(X - currentBoxFractalScale * 2.2, Y, Z + currentBoxFractalScale * 2.2);
		parentBoxFractalPositions[totalNumberOfParents] = new THREE.Vector3(X - currentBoxFractalScale * 2.2, Y, Z + currentBoxFractalScale * 2.2);
		totalNumberOfParents++;
		// front right
		createBoxFrameFractal(X + currentBoxFractalScale * 2.2, Y, Z + currentBoxFractalScale * 2.2);
		parentBoxFractalPositions[totalNumberOfParents] = new THREE.Vector3(X + currentBoxFractalScale * 2.2, Y, Z + currentBoxFractalScale * 2.2);
		totalNumberOfParents++;
		// back left
		createBoxFrameFractal(X - currentBoxFractalScale * 2.2, Y, Z - currentBoxFractalScale * 2.2);
		parentBoxFractalPositions[totalNumberOfParents] = new THREE.Vector3(X - currentBoxFractalScale * 2.2, Y, Z - currentBoxFractalScale * 2.2);
		totalNumberOfParents++;
		// back right
		createBoxFrameFractal(X + currentBoxFractalScale * 2.2, Y, Z - currentBoxFractalScale * 2.2);
		parentBoxFractalPositions[totalNumberOfParents] = new THREE.Vector3(X + currentBoxFractalScale * 2.2, Y, Z - currentBoxFractalScale * 2.2);
		totalNumberOfParents++;
	}


	currentBoxFractalScale *= 0.5;
	
	for (let i = 1365; i < 5461; i++) 
	{
		X = parentBoxFractalPositions[i].x;
		Y = parentBoxFractalPositions[i].y;
		Z = parentBoxFractalPositions[i].z;
		
		// front left
		createBoxFrameFractal(X - currentBoxFractalScale * 2.2, Y, Z + currentBoxFractalScale * 2.2);
		parentBoxFractalPositions[totalNumberOfParents] = new THREE.Vector3(X - currentBoxFractalScale * 2.2, Y, Z + currentBoxFractalScale * 2.2);
		totalNumberOfParents++;
		// front right
		createBoxFrameFractal(X + currentBoxFractalScale * 2.2, Y, Z + currentBoxFractalScale * 2.2);
		parentBoxFractalPositions[totalNumberOfParents] = new THREE.Vector3(X + currentBoxFractalScale * 2.2, Y, Z + currentBoxFractalScale * 2.2);
		totalNumberOfParents++;
		// back left
		createBoxFrameFractal(X - currentBoxFractalScale * 2.2, Y, Z - currentBoxFractalScale * 2.2);
		parentBoxFractalPositions[totalNumberOfParents] = new THREE.Vector3(X - currentBoxFractalScale * 2.2, Y, Z - currentBoxFractalScale * 2.2);
		totalNumberOfParents++;
		// back right
		createBoxFrameFractal(X + currentBoxFractalScale * 2.2, Y, Z - currentBoxFractalScale * 2.2);
		parentBoxFractalPositions[totalNumberOfParents] = new THREE.Vector3(X + currentBoxFractalScale * 2.2, Y, Z - currentBoxFractalScale * 2.2);
		totalNumberOfParents++;
	}
	
	

	console.log("Shape count: " + totalNumberOfShapes);

	totalWork = new Uint32Array(totalNumberOfShapes);

	shape_array = new Float32Array(2048 * 2048 * 4);
	// 2048 = width of texture, 2048 = height of texture, 4 = r,g,b, and a components

	aabb_array = new Float32Array(2048 * 2048 * 4);
	// 2048 = width of texture, 2048 = height of texture, 4 = r,g,b, and a components


	for (let i = 0; i < totalNumberOfShapes; i++) 
	{
		invMatrix.copy(boxes[i].matrixWorld).invert();
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
		shape_array[32 * i + 16] = 0; // r or x // shape type id#  (0: box, 1: sphere, 2: cylinder, 3: cone, 4: paraboloid, etc)
		shape_array[32 * i + 17] = 1; // g or y // material type id# (0: LIGHT, 1: DIFF, 2: REFR, 3: SPEC, 4: COAT, etc)
		shape_array[32 * i + 18] = 0.0; // b or z // material Metalness - default: 0.0(no metal, a dielectric), 1.0 would be purely metal
		shape_array[32 * i + 19] = 0.0; // a or w // material Roughness - default: 0.0(no roughness, totally smooth)

		//slot 5
		shape_array[32 * i + 20] = 1.0;//Math.random(); // r or x // material albedo color R (if LIGHT, this is also its emissive color R)
		shape_array[32 * i + 21] = 1.0;//Math.random(); // g or y // material albedo color G (if LIGHT, this is also its emissive color G)
		shape_array[32 * i + 22] = 1.0;//Math.random(); // b or z // material albedo color B (if LIGHT, this is also its emissive color B)
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
		shapeBoundingBox_minCorner.multiply(boxes[i].scale);
		shapeBoundingBox_maxCorner.multiply(boxes[i].scale);
		shapeBoundingBox_minCorner.add(boxes[i].position);
		shapeBoundingBox_maxCorner.add(boxes[i].position);
		shapeBoundingBox_centroid.copy(boxes[i].position);

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
	
	sunDirTransform_RotateXObject = {
		sunDir_RotateX: 345//298
	}
	sunDirTransform_RotateYObject = {
		sunDir_RotateY: 205//318
	}
	viewpoint_PresetObject = {
		Viewpoint_Preset: 'Viewpoint 1'
	};

	function handleSunDirRotationChange()
	{
		needChangeSunDirRotation = true;
	}

	function handleViewpointPresetChange() 
	{ 
		needChangeViewpointPreset = true; 
	}

	sunDirTransform_RotateXController = gui.add(sunDirTransform_RotateXObject, 'sunDir_RotateX', 179, 361, 1).onChange(handleSunDirRotationChange);
	sunDirTransform_RotateYController = gui.add(sunDirTransform_RotateYObject, 'sunDir_RotateY', 0, 359, 1).onChange(handleSunDirRotationChange);

	viewpoint_PresetController = gui.add(viewpoint_PresetObject, 'Viewpoint_Preset', ['Viewpoint 1', 'Viewpoint 2', 'Viewpoint 3', 'Viewpoint 4', 
		'Viewpoint 5', 'Viewpoint 6', 'Viewpoint 7', 'Viewpoint 8', 'Viewpoint 9', 'Viewpoint 10']).onChange(handleViewpointPresetChange);

	// jumpstart setting of initial camera viewpoint when the demo begins
	handleViewpointPresetChange();
	
	// scene/demo-specific uniforms go here
	pathTracingUniforms.tShape_DataTexture = { value: shapeDataTexture };
	pathTracingUniforms.tAABB_DataTexture = { value: aabbDataTexture };
	pathTracingUniforms.uSunDirection = { value: new THREE.Vector3() };


} // end function initSceneData()



// called automatically from within the animate() function (located in InitCommon.js file)
function updateVariablesAndUniforms() 
{

	if (needChangeViewpointPreset)
	{
		if (viewpoint_PresetController.getValue() == 'Viewpoint 1')
		{
			sunDirTransform_RotateXController.setValue(305);
			sunDirTransform_RotateYController.setValue(205);
			cameraControlsObject.position.set(0, 800, 3323);
			cameraControlsPitchObject.rotation.x = 0;
			cameraControlsYawObject.rotation.y = 0;
		}
		else if (viewpoint_PresetController.getValue() == 'Viewpoint 2')
		{
			sunDirTransform_RotateXController.setValue(216);
			sunDirTransform_RotateYController.setValue(205);
			cameraControlsObject.position.set(476, 1072.9, 527.3);
			cameraControlsPitchObject.rotation.x = -0.741;
			cameraControlsYawObject.rotation.y = -5.466;
		}
		else if (viewpoint_PresetController.getValue() == 'Viewpoint 3')
		{
			sunDirTransform_RotateXController.setValue(200);
			sunDirTransform_RotateYController.setValue(205);
			cameraControlsObject.position.set(163.7, 225.5, 2380.9);
			cameraControlsPitchObject.rotation.x = 0.016;
			cameraControlsYawObject.rotation.y = -0.612;
		}
		else if (viewpoint_PresetController.getValue() == 'Viewpoint 4')
		{
			sunDirTransform_RotateXController.setValue(305);
			sunDirTransform_RotateYController.setValue(205);
			cameraControlsObject.position.set(0, 1035.4, -969.1);
			cameraControlsPitchObject.rotation.x = -1.057;
			cameraControlsYawObject.rotation.y = 0;
		}
		else if (viewpoint_PresetController.getValue() == 'Viewpoint 5')
		{
			sunDirTransform_RotateXController.setValue(301);
			sunDirTransform_RotateYController.setValue(249);
			cameraControlsObject.position.set(5, 20.5, -1164);
			cameraControlsPitchObject.rotation.x = -0.136;
			cameraControlsYawObject.rotation.y = -0.794;
		}
		else if (viewpoint_PresetController.getValue() == 'Viewpoint 6')
		{
			sunDirTransform_RotateXController.setValue(305);
			sunDirTransform_RotateYController.setValue(205);
			cameraControlsObject.position.set(0, 296.4, 2250.9);
			cameraControlsPitchObject.rotation.x = -0.540;
			cameraControlsYawObject.rotation.y = 0;
		}
		else if (viewpoint_PresetController.getValue() == 'Viewpoint 7')
		{
			sunDirTransform_RotateXController.setValue(181);
			sunDirTransform_RotateYController.setValue(205);
			cameraControlsObject.position.set(-1928.6, 1066, -290.3);
			cameraControlsPitchObject.rotation.x = -0.038;
			cameraControlsYawObject.rotation.y = -1.966;
		}
		else if (viewpoint_PresetController.getValue() == 'Viewpoint 8')
		{
			sunDirTransform_RotateXController.setValue(305);
			sunDirTransform_RotateYController.setValue(205);
			cameraControlsObject.position.set(0, 2617.4, 0);
			cameraControlsPitchObject.rotation.x = -1.547;
			cameraControlsYawObject.rotation.y = 0;
		}
		else if (viewpoint_PresetController.getValue() == 'Viewpoint 9')
		{
			sunDirTransform_RotateXController.setValue(305);
			sunDirTransform_RotateYController.setValue(205);
			cameraControlsObject.position.set(-1368, 1122.7, -1385);
			cameraControlsPitchObject.rotation.x = -1.028;
			cameraControlsYawObject.rotation.y = -2.359;
		}
		else if (viewpoint_PresetController.getValue() == 'Viewpoint 10')
		{
			sunDirTransform_RotateXController.setValue(352);
			sunDirTransform_RotateYController.setValue(205);
			cameraControlsObject.position.set(0, 11.5, -2574.1);
			cameraControlsPitchObject.rotation.x = 0.456;
			cameraControlsYawObject.rotation.y = 3.145;
		}
		

		needChangeSunDirRotation = true;
		needChangeViewpointPreset = false;
	} // end if (needChangeViewpointPreset)


	if (needChangeSunDirRotation)
	{
		sunDirRotationX = sunDirTransform_RotateXController.getValue();
		sunDirRotationY = sunDirTransform_RotateYController.getValue();
		
		sunDirRotationX *= (Math.PI / 180);
		sunDirRotationY *= (Math.PI / 180);

		sunPitchObject.rotation.x = sunDirRotationX;
		sunPitchObject.updateMatrixWorld(true);
		
		sunYawObject.rotation.y = sunDirRotationY;
		sunYawObject.updateMatrixWorld(true);
		
		
		// update Sun direction uniform
		pathTracingUniforms.uSunDirection.value.set( sunPitchObject.matrixWorld.elements[ 8 ], 
			sunPitchObject.matrixWorld.elements[ 9 ],
			sunPitchObject.matrixWorld.elements[ 10 ] ).normalize();
		
		cameraIsMoving = true;
		needChangeSunDirRotation = false;
	}

	

	// INFO (debug)
	/* cameraInfoElement.innerHTML = cameraControlsObject.position.x.toFixed(1) + ", " + cameraControlsObject.position.y.toFixed(1) + ", " + cameraControlsObject.position.z.toFixed(1) + "<br>" +
		"rotX: " + cameraControlsPitchObject.rotation.x.toFixed(3) + " rotY: " + cameraControlsYawObject.rotation.y.toFixed(3) + "<br>" +
		"FOV: " + worldCamera.fov + " / Aperture: " + apertureSize.toFixed(2) + " / FocusDistance: " + focusDistance + "<br>" + "Samples: " + sampleCounter; 
	*/
	
	// INFO
	cameraInfoElement.innerHTML = "FOV: " + worldCamera.fov + " / Aperture: " + apertureSize.toFixed(2) + " / FocusDistance: " + focusDistance + "<br>" + 
		"Samples: " + sampleCounter; 
	
} // end function updateVariablesAndUniforms()



init(); // init app and start animating