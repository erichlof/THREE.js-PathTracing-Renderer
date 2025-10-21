// scene/demo-specific variables go here
let boxGeometry, boxMaterial;
let boxMeshes = [];
let boxGeometries = [];

let totalNumberOfShapes = 0;
let ix32 = 0; // used in loop
let ix9 = 0; // used in loop
let sphereTestPosition = new THREE.Vector3();
let testPoint = new THREE.Vector3(4, 0.2, 0);
let spherePositions = [];
let choose_mat = 0;
let tempColor = new THREE.Color();
let tempVector = new THREE.Vector3();
let shape = new THREE.Object3D();
let invMatrix = new THREE.Matrix4();
let el; // elements of the invMatrix
let shapeBoundingBox_minCorner = new THREE.Vector3();
let shapeBoundingBox_maxCorner = new THREE.Vector3();
let shapeBoundingBox_centroid = new THREE.Vector3();
let shape_array;
let shapeDataTexture;
let shape_aabb_array;
let aabbDataTexture;
let totalWorklist;

let animation_TypeObject, shape_TypeObject, showBVH_ToggleObject;
let animation_TypeController, shape_TypeController, showBVH_ToggleController;
let changeAnimationType = false;
let changeShapeType = false;
let toggleShowBVH = false;
let animationType, shapeType;
let shapeNumberCode = 1;


// called automatically from within initTHREEjs() function (located in InitCommon.js file)
function initSceneData() 
{
	demoFragmentShaderFileName = 'RayTracing_InOneWeekend_Fragment.glsl';

	// scene/demo-specific three.js objects setup goes here
	sceneIsDynamic = false;

	cameraFlightSpeed = 10;

	// pixelRatio is resolution - range: 0.5(half resolution) to 1.0(full resolution)
	pixelRatio = mouseControl ? 1.0 : 0.7;

	EPS_intersect = 0.01;

	// set camera's field of view
	worldCamera.fov = 25;
	apertureSize = 0.001;
	focusDistance = 10.0;
	apertureChangeSpeed = 0.005;
	focusDistanceChangeSpeed = 0.05;

	// position and orient camera
	cameraControlsObject.position.set(13, 2, 3);
	// look left
	cameraControlsYawObject.rotation.y = 1.35;
	// look slightly downward
	cameraControlsPitchObject.rotation.x = -0.13;


	

	shape_array = new Float32Array(2048 * 2048 * 4);
	// 2048 = width of texture, 2048 = height of texture, 4 = r,g,b, and a components

	shape_aabb_array = new Float32Array(2048 * 2048 * 4);
	// 2048 = width of texture, 2048 = height of texture, 4 = r,g,b, and a components

	
	for (let a = -11; a < 11; a++) 
	{
		for (let b = -11; b < 11; b++) 
		{
			sphereTestPosition.set( a + (0.9 * Math.random()), 0.2, b + (0.9 * Math.random()) );

			if (sphereTestPosition.distanceTo(testPoint) > 1.0)
			{
				spherePositions.push(new THREE.Vector3().copy(sphereTestPosition));
				totalNumberOfShapes++;
			}
		}
	}

	console.log("Shape count: " + totalNumberOfShapes);
	totalWorklist = new Uint32Array(totalNumberOfShapes);

	boxMaterial = new THREE.MeshBasicMaterial();

	for (let i = 0; i < totalNumberOfShapes; i++) 
	{
		ix32 = i * 32;
		ix9 = i * 9;

		shape.position.copy(spherePositions[i]);
		shape.rotation.set(0, 0, 0);
		shape.scale.set(0.2, 0.2, 0.2);
		
		shape.updateMatrixWorld(true); // 'true' forces immediate matrix update

		invMatrix.copy(shape.matrixWorld).invert();
		el = invMatrix.elements;

		//slot 0                       Shape transform Matrix 4x4 (16 elements total)
		shape_array[ix32 + 0] = el[0]; // r or x // shape transform Matrix element[0]
		shape_array[ix32 + 1] = el[1]; // g or y // shape transform Matrix element[1] 
		shape_array[ix32 + 2] = el[2]; // b or z // shape transform Matrix element[2]
		shape_array[ix32 + 3] = el[3]; // a or w // shape transform Matrix element[3]

		//slot 1
		shape_array[ix32 + 4] = el[4]; // r or x // shape transform Matrix element[4]
		shape_array[ix32 + 5] = el[5]; // g or y // shape transform Matrix element[5]
		shape_array[ix32 + 6] = el[6]; // b or z // shape transform Matrix element[6]
		shape_array[ix32 + 7] = el[7]; // a or w // shape transform Matrix element[7]

		//slot 2
		shape_array[ix32 + 8] = el[8]; // r or x // shape transform Matrix element[8]
		shape_array[ix32 + 9] = el[9]; // g or y // shape transform Matrix element[9]
		shape_array[ix32 + 10] = el[10]; // b or z // shape transform Matrix element[10]
		shape_array[ix32 + 11] = el[11]; // a or w // shape transform Matrix element[11]

		//slot 3
		shape_array[ix32 + 12] = el[12]; // r or x // shape transform Matrix element[12]
		shape_array[ix32 + 13] = el[13]; // g or y // shape transform Matrix element[13]
		shape_array[ix32 + 14] = el[14]; // b or z // shape transform Matrix element[14]
		shape_array[ix32 + 15] = el[15]; // a or w // shape transform Matrix element[15]

		//slot 4
		shape_array[ix32 + 16] = 1; // r or x // shape type id#  (0: box, 1: sphere, 2: cylinder, 3: cone, 4: paraboloid, etc)
		//shape_array[ix32 + 17] = 1; // g or y // material type id# (0: LIGHT, 1: DIFF, 2: REFR, 3: SPEC, 4: COAT, etc)
		shape_array[ix32 + 18] = 0.0; // b or z // material Metalness - default: 0.0(no metal, a dielectric), 1.0 would be purely metal
		shape_array[ix32 + 19] = 0.0; // a or w // material Roughness - default: 0.0(no roughness, totally smooth)

		choose_mat = Math.random();
		if (choose_mat < 0.8) 
		{
                    shape_array[ix32 + 17] = 1; // diffuse
		    tempColor.set( Math.random() * Math.random(), Math.random() * Math.random(), Math.random() * Math.random() );
                    
                } else if (choose_mat < 0.95) 
		{
                    shape_array[ix32 + 17] = 3; // metal
		    shape_array[ix32 + 19] = Math.random() * 0.5; // pick a random roughness between 0.0 and 0.5
                    tempColor.set( (Math.random() * 0.5) + 0.5, (Math.random() * 0.5) + 0.5, (Math.random() * 0.5) + 0.5 );
                
		} else 
		{
                    shape_array[ix32 + 17] = 2; // glass
                    tempColor.set(1, 1, 1);
                }

		//slot 5
		shape_array[ix32 + 20] = tempColor.r; // r or x // material albedo color R (if LIGHT, this is also its emissive color R)
		shape_array[ix32 + 21] = tempColor.g; // g or y // material albedo color G (if LIGHT, this is also its emissive color G)
		shape_array[ix32 + 22] = tempColor.b; // b or z // material albedo color B (if LIGHT, this is also its emissive color B)
		shape_array[ix32 + 23] = 1.0; // a or w // material Opacity (Alpha) - default: 1.0 (fully opaque), 0.0 is fully transparent

		//slot 6
		shape_array[ix32 + 24] = 1.0; // r or x // material Index of Refraction(IoR) - default: 1.0(air) (or 1.5(glass), 1.33(water), etc)
		shape_array[ix32 + 25] = 0.0; // g or y // material ClearCoat Roughness - default: 0.0 (no roughness, totally smooth)
		shape_array[ix32 + 26] = 1.5; // b or z // material ClearCoat IoR - default: 1.5(thick ClearCoat)
		shape_array[ix32 + 27] = 0; // a or w // material data

		tempVector.set(Math.random() * 2 - 1, Math.random() * 2 - 1, Math.random() * 2 - 1).normalize();
		//slot 7
		shape_array[ix32 + 28] = tempVector.x; // r or x // material data
		shape_array[ix32 + 29] = tempVector.y; // g or y // material data
		shape_array[ix32 + 30] = tempVector.z; // b or z // material data
		shape_array[ix32 + 31] = Math.random() * Math.PI * 2; // a or w // material data

		// if this shape is a Box, use THREE.BoxGeometry as starting point for this shape's AABB
		//if (shape_array[ix32 + 16] == 0) 
			boxGeometries[i] = new THREE.BoxGeometry(2, 2, 2); // 2,6,2
		//else // else use THREE.SphereGeometry, as it produces a tighter-fitting AABB when shape is rotated
		//	boxGeometries[i] = new THREE.SphereGeometry(1.4);

		boxMeshes[i] = new THREE.Mesh( boxGeometries[i], boxMaterial );
		
		boxMeshes[i].geometry.applyMatrix4(shape.matrixWorld);
		boxMeshes[i].geometry.computeBoundingBox();
		
		shapeBoundingBox_minCorner.copy(boxMeshes[i].geometry.boundingBox.min);
		shapeBoundingBox_maxCorner.copy(boxMeshes[i].geometry.boundingBox.max);
		boxMeshes[i].geometry.boundingBox.getCenter(shapeBoundingBox_centroid);


		shape_aabb_array[ix9 + 0] = shapeBoundingBox_minCorner.x;
		shape_aabb_array[ix9 + 1] = shapeBoundingBox_minCorner.y;
		shape_aabb_array[ix9 + 2] = shapeBoundingBox_minCorner.z;
		shape_aabb_array[ix9 + 3] = shapeBoundingBox_maxCorner.x;
		shape_aabb_array[ix9 + 4] = shapeBoundingBox_maxCorner.y;
		shape_aabb_array[ix9 + 5] = shapeBoundingBox_maxCorner.z;
		shape_aabb_array[ix9 + 6] = shapeBoundingBox_centroid.x;
		shape_aabb_array[ix9 + 7] = shapeBoundingBox_centroid.y;
		shape_aabb_array[ix9 + 8] = shapeBoundingBox_centroid.z;

		totalWorklist[i] = i;
	} // end for (let i = 0; i < totalNumberOfShapes; i++)


	for (let i = 0; i < totalNumberOfShapes * 2; i++)
		buildnodes[i] = new BVH_Node();

	console.log("BvhGeneration...");
	console.time("BvhGeneration");
	
	BVH_QuickBuild(totalWorklist, shape_aabb_array);
	
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
		THREE.NoColorSpace);

	shapeDataTexture.flipY = false;
	shapeDataTexture.generateMipmaps = false;
	shapeDataTexture.needsUpdate = true;

	aabbDataTexture = new THREE.DataTexture(shape_aabb_array,
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
		THREE.NoColorSpace);

	aabbDataTexture.flipY = false;
	aabbDataTexture.generateMipmaps = false;
	aabbDataTexture.needsUpdate = true;


	// In addition to the default GUI on all demos, add any special GUI elements that this particular demo requires
	animation_TypeObject = {
		Play_Animation: 'None'
	};
	shape_TypeObject = {
		Select_Shapes: 'Spheres'
	};
	showBVH_ToggleObject = {
		Show_BVH_Leaves: false
	};

	function handleAnimationTypeChange() 
	{
		changeAnimationType = true;
	}
	function handleShapeTypeChange() 
	{
		changeShapeType = true;
	}
	function handleToggleShowBVH()
	{
		toggleShowBVH = true;
	}

	animation_TypeController = gui.add(animation_TypeObject, 'Play_Animation', ['None', 'Translation Animation', 'Rotation Animation', 'Scaling Animation']).onChange(handleAnimationTypeChange);
	shape_TypeController = gui.add(shape_TypeObject, 'Select_Shapes', ['Spheres', 'Boxes', 'Cylinders', 'Cones', 'Paraboloids', 'Random']).onChange(handleShapeTypeChange);
	showBVH_ToggleController = gui.add(showBVH_ToggleObject, 'Show_BVH_Leaves', false).onChange(handleToggleShowBVH);

	// scene/demo-specific uniforms go here
	pathTracingUniforms.tShape_DataTexture = { value: shapeDataTexture };
	pathTracingUniforms.tAABB_DataTexture = { value: aabbDataTexture };
	pathTracingUniforms.uAnimationType = { value: 0.0 };
	pathTracingUniforms.uShowBVH_Leaves = { value: false };


} // end function initSceneData()



// called automatically from within the animate() function (located in InitCommon.js file)
function updateVariablesAndUniforms() 
{

	if (changeShapeType) 
	{
		shapeType = shape_TypeController.getValue();
		if (shapeType == 'Boxes') 
			shapeNumberCode = 0;
		else if (shapeType == 'Spheres') 
			shapeNumberCode = 1;
		else if (shapeType == 'Cylinders') 
			shapeNumberCode = 2;
		else if (shapeType == 'Cones') 
			shapeNumberCode = 3;
		else if (shapeType == 'Paraboloids') 
			shapeNumberCode = 4;

		for (let i = 0; i < totalNumberOfShapes; i++) 
		{
			ix32 = i * 32;
			if (shapeType == 'Random') 
				shapeNumberCode = Math.floor(Math.random() * 5);
			shape_array[ix32 + 16] = shapeNumberCode;
		}
		shapeDataTexture.needsUpdate = true;

		cameraIsMoving = true;
		changeShapeType = false;

		changeAnimationType = true;
	} // end if (changeShapeType)

	if (changeAnimationType) 
	{
		animationType = animation_TypeController.getValue();

		if (animationType == 'None') 
		{
			boxGeometries = [];
			boxMeshes = [];

			for (let i = 0; i < totalNumberOfShapes; i++) 
			{
				ix32 = i * 32;
				ix9 = i * 9;

				shape.position.copy(spherePositions[i]);
				shape.rotation.set(0, 0, 0);
				shape.scale.set(0.2, 0.2, 0.2);
				shape.updateMatrixWorld(true); // 'true' forces immediate matrix update
				// if this shape is a Box, use THREE.BoxGeometry as starting point for this shape's AABB
				//if (shape_array[ix32 + 16] == 0) 
					boxGeometries[i] = new THREE.BoxGeometry(2, 2, 2);
				//else // else use THREE.SphereGeometry, as it produces a tighter-fitting AABB when shape is rotated
				//	boxGeometries[i] = new THREE.SphereGeometry(1.4);

				boxMeshes[i] = new THREE.Mesh( boxGeometries[i], boxMaterial );
				
				boxMeshes[i].geometry.applyMatrix4(shape.matrixWorld);
				boxMeshes[i].geometry.computeBoundingBox();
				
				shapeBoundingBox_minCorner.copy(boxMeshes[i].geometry.boundingBox.min);
				shapeBoundingBox_maxCorner.copy(boxMeshes[i].geometry.boundingBox.max);
				boxMeshes[i].geometry.boundingBox.getCenter(shapeBoundingBox_centroid);

				shape_aabb_array[ix9 + 0] = shapeBoundingBox_minCorner.x;
				shape_aabb_array[ix9 + 1] = shapeBoundingBox_minCorner.y;
				shape_aabb_array[ix9 + 2] = shapeBoundingBox_minCorner.z;
				shape_aabb_array[ix9 + 3] = shapeBoundingBox_maxCorner.x;
				shape_aabb_array[ix9 + 4] = shapeBoundingBox_maxCorner.y;
				shape_aabb_array[ix9 + 5] = shapeBoundingBox_maxCorner.z;
				shape_aabb_array[ix9 + 6] = shapeBoundingBox_centroid.x;
				shape_aabb_array[ix9 + 7] = shapeBoundingBox_centroid.y;
				shape_aabb_array[ix9 + 8] = shapeBoundingBox_centroid.z;

				totalWorklist[i] = i;
			} // end for (let i = 0; i < totalNumberOfShapes; i++)

			// for the recursive Quick Builder, must set nodesUsed back to 1
			nodesUsed = 1;

			console.log("BvhGeneration...");
			console.time("BvhGeneration");
			
			BVH_QuickBuild(totalWorklist, shape_aabb_array);
			
			console.timeEnd("BvhGeneration");
			
			pathTracingUniforms.uAnimationType.value = 0.0;
			aabbDataTexture.needsUpdate = true;
			sceneIsDynamic = false;
		} // end if (animationType == 'None')
		else if (animationType == 'Translation Animation') 
		{
			boxGeometries = [];
			boxMeshes = [];

			for (let i = 0; i < totalNumberOfShapes; i++) 
			{
				ix32 = i * 32;
				ix9 = i * 9;

				shape.position.copy(spherePositions[i]);
				shape.rotation.set(0, 0, 0);
				shape.scale.set(0.2, 0.2, 0.2);
				shape.updateMatrixWorld(true); // 'true' forces immediate matrix update
				// if this shape is a Box, use THREE.BoxGeometry as starting point for this shape's AABB
				//if (shape_array[ix32 + 16] == 0) 
					boxGeometries[i] = new THREE.BoxGeometry(2, 5, 2);
				//else // else use THREE.SphereGeometry, as it produces a tighter-fitting AABB when shape is rotated
				//	boxGeometries[i] = new THREE.SphereGeometry(1.4);

				boxMeshes[i] = new THREE.Mesh( boxGeometries[i], boxMaterial );
				
				boxMeshes[i].geometry.applyMatrix4(shape.matrixWorld);
				boxMeshes[i].geometry.computeBoundingBox();
				
				shapeBoundingBox_minCorner.copy(boxMeshes[i].geometry.boundingBox.min);
				shapeBoundingBox_maxCorner.copy(boxMeshes[i].geometry.boundingBox.max);
				boxMeshes[i].geometry.boundingBox.getCenter(shapeBoundingBox_centroid);

				shape_aabb_array[ix9 + 0] = shapeBoundingBox_minCorner.x;
				shape_aabb_array[ix9 + 1] = shapeBoundingBox_minCorner.y;
				shape_aabb_array[ix9 + 2] = shapeBoundingBox_minCorner.z;
				shape_aabb_array[ix9 + 3] = shapeBoundingBox_maxCorner.x;
				shape_aabb_array[ix9 + 4] = shapeBoundingBox_maxCorner.y;
				shape_aabb_array[ix9 + 5] = shapeBoundingBox_maxCorner.z;
				shape_aabb_array[ix9 + 6] = shapeBoundingBox_centroid.x;
				shape_aabb_array[ix9 + 7] = shapeBoundingBox_centroid.y;
				shape_aabb_array[ix9 + 8] = shapeBoundingBox_centroid.z;

				totalWorklist[i] = i;
			} // end for (let i = 0; i < totalNumberOfShapes; i++)

			// for the recursive Quick Builder, must set nodesUsed back to 1
			nodesUsed = 1;

			console.log("BvhGeneration...");
			console.time("BvhGeneration");
			
			BVH_QuickBuild(totalWorklist, shape_aabb_array);
			
			console.timeEnd("BvhGeneration");

			pathTracingUniforms.uAnimationType.value = 1.0;
			aabbDataTexture.needsUpdate = true;
			sceneIsDynamic = true;
		} // end else if (animationType == 'Translation Animation')
		else if (animationType == 'Rotation Animation') 
		{
			boxGeometries = [];
			boxMeshes = [];

			for (let i = 0; i < totalNumberOfShapes; i++) 
			{
				ix32 = i * 32;
				ix9 = i * 9;

				shape.position.copy(spherePositions[i]);
				shape.rotation.set(0, 0, 0);
				shape.scale.set(0.2, 0.2, 0.2);
				shape.updateMatrixWorld(true); // 'true' forces immediate matrix update
				// if this shape is a Box, use THREE.BoxGeometry as starting point for this shape's AABB
				if (shape_array[ix32 + 16] == 0) 
					boxGeometries[i] = new THREE.SphereGeometry(1.6);
				else // else use THREE.SphereGeometry, as it produces a tighter-fitting AABB when shape is rotated
					boxGeometries[i] = new THREE.SphereGeometry(1.3);

				boxMeshes[i] = new THREE.Mesh( boxGeometries[i], boxMaterial );
				
				boxMeshes[i].geometry.applyMatrix4(shape.matrixWorld);
				boxMeshes[i].geometry.computeBoundingBox();
				
				shapeBoundingBox_minCorner.copy(boxMeshes[i].geometry.boundingBox.min);
				shapeBoundingBox_maxCorner.copy(boxMeshes[i].geometry.boundingBox.max);
				boxMeshes[i].geometry.boundingBox.getCenter(shapeBoundingBox_centroid);

				shape_aabb_array[ix9 + 0] = shapeBoundingBox_minCorner.x;
				shape_aabb_array[ix9 + 1] = shapeBoundingBox_minCorner.y;
				shape_aabb_array[ix9 + 2] = shapeBoundingBox_minCorner.z;
				shape_aabb_array[ix9 + 3] = shapeBoundingBox_maxCorner.x;
				shape_aabb_array[ix9 + 4] = shapeBoundingBox_maxCorner.y;
				shape_aabb_array[ix9 + 5] = shapeBoundingBox_maxCorner.z;
				shape_aabb_array[ix9 + 6] = shapeBoundingBox_centroid.x;
				shape_aabb_array[ix9 + 7] = shapeBoundingBox_centroid.y;
				shape_aabb_array[ix9 + 8] = shapeBoundingBox_centroid.z;

				totalWorklist[i] = i;
			} // end for (let i = 0; i < totalNumberOfShapes; i++)

			// for the recursive Quick Builder, must set nodesUsed back to 1
			nodesUsed = 1;

			console.log("BvhGeneration...");
			console.time("BvhGeneration");
			
			BVH_QuickBuild(totalWorklist, shape_aabb_array);
			
			console.timeEnd("BvhGeneration");

			pathTracingUniforms.uAnimationType.value = 2.0;
			aabbDataTexture.needsUpdate = true;
			sceneIsDynamic = true;
		} // end else if (animationType == 'Rotation Animation')
		else if (animationType == 'Scaling Animation') 
		{
			boxGeometries = [];
			boxMeshes = [];

			for (let i = 0; i < totalNumberOfShapes; i++) 
			{
				ix32 = i * 32;
				ix9 = i * 9;

				shape.position.copy(spherePositions[i]);
				shape.rotation.set(0, 0, 0);
				shape.scale.set(0.2, 0.2, 0.2);
				shape.updateMatrixWorld(true); // 'true' forces immediate matrix update
				// if this shape is a Box, use THREE.BoxGeometry as starting point for this shape's AABB
				//if (shape_array[ix32 + 16] == 0) 
					boxGeometries[i] = new THREE.BoxGeometry(4, 4, 4);
				//else // else use THREE.SphereGeometry, as it produces a tighter-fitting AABB when shape is rotated
				//	boxGeometries[i] = new THREE.SphereGeometry(1.4);

				boxMeshes[i] = new THREE.Mesh( boxGeometries[i], boxMaterial );
				
				boxMeshes[i].geometry.applyMatrix4(shape.matrixWorld);
				boxMeshes[i].geometry.computeBoundingBox();
				
				shapeBoundingBox_minCorner.copy(boxMeshes[i].geometry.boundingBox.min);
				shapeBoundingBox_maxCorner.copy(boxMeshes[i].geometry.boundingBox.max);
				boxMeshes[i].geometry.boundingBox.getCenter(shapeBoundingBox_centroid);

				shape_aabb_array[ix9 + 0] = shapeBoundingBox_minCorner.x;
				shape_aabb_array[ix9 + 1] = shapeBoundingBox_minCorner.y;
				shape_aabb_array[ix9 + 2] = shapeBoundingBox_minCorner.z;
				shape_aabb_array[ix9 + 3] = shapeBoundingBox_maxCorner.x;
				shape_aabb_array[ix9 + 4] = shapeBoundingBox_maxCorner.y;
				shape_aabb_array[ix9 + 5] = shapeBoundingBox_maxCorner.z;
				shape_aabb_array[ix9 + 6] = shapeBoundingBox_centroid.x;
				shape_aabb_array[ix9 + 7] = shapeBoundingBox_centroid.y;
				shape_aabb_array[ix9 + 8] = shapeBoundingBox_centroid.z;

				totalWorklist[i] = i;
			} // end for (let i = 0; i < totalNumberOfShapes; i++)

			// for the recursive Quick Builder, must set nodesUsed back to 1
			nodesUsed = 1;

			console.log("BvhGeneration...");
			console.time("BvhGeneration");
			
			BVH_QuickBuild(totalWorklist, shape_aabb_array);
			
			console.timeEnd("BvhGeneration");

			pathTracingUniforms.uAnimationType.value = 3.0;
			aabbDataTexture.needsUpdate = true;
			sceneIsDynamic = true;
		} // end else if (animationType == 'Scaling Animation')

		pathTracingUniforms.uSceneIsDynamic.value = sceneIsDynamic;
		screenOutputUniforms.uSceneIsDynamic.value = sceneIsDynamic;

		cameraIsMoving = true;
		changeAnimationType = false;

	} // end if (changeAnimationType)

	if (toggleShowBVH)
	{
		pathTracingUniforms.uShowBVH_Leaves.value = showBVH_ToggleController.getValue();
		cameraIsMoving = true;
		toggleShowBVH = false;
	}
	

	// INFO
	cameraInfoElement.innerHTML = "FOV: " + worldCamera.fov + " / Aperture: " + apertureSize.toFixed(3) + " / FocusDistance: " + focusDistance.toFixed(1) + "<br>" + "Samples: " + sampleCounter;

} // end function updateVariablesAndUniforms()



init(); // init app and start animating
