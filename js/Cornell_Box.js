// scene/demo-specific variables go here
var sceneIsDynamic = false;
var camFlightSpeed = 300;
var tallBoxGeometry, tallBoxMaterial, tallBoxMesh;
var shortBoxGeometry, shortBoxMaterial, shortBoxMesh;

// called automatically from within initTHREEjs() function
function initSceneData() 
{
	// scene/demo-specific three.js objects setup goes here

	// pixelRatio is resolution - range: 0.5(half resolution) to 1.0(full resolution)
	pixelRatio = mouseControl ? 1.0 : 0.75; // less demanding on battery-powered mobile devices

	EPS_intersect = 0.01;

	// Boxes
	tallBoxGeometry = new THREE.BoxGeometry(1,1,1);
	tallBoxMaterial = new THREE.MeshPhysicalMaterial( {
		color: new THREE.Color(0.95, 0.95, 0.95), //RGB, ranging from 0.0 - 1.0
		roughness: 1.0 // ideal Diffuse material	
	} );
	
	tallBoxMesh = new THREE.Mesh(tallBoxGeometry, tallBoxMaterial);
	pathTracingScene.add(tallBoxMesh);
	tallBoxMesh.visible = false; // disable normal Three.js rendering updates of this object: 
	// it is just a data placeholder as well as an Object3D that can be transformed/manipulated by 
	// using familiar Three.js library commands. It is then fed into the GPU path tracing renderer
	// through its 'matrixWorld' matrix. See below:
	tallBoxMesh.rotation.set(0, Math.PI * 0.1, 0);
	tallBoxMesh.position.set(180, 170, -350);
	tallBoxMesh.updateMatrixWorld(true); // 'true' forces immediate matrix update
	
	
	shortBoxGeometry = new THREE.BoxGeometry(1,1,1);
	shortBoxMaterial = new THREE.MeshPhysicalMaterial( {
		color: new THREE.Color(0.95, 0.95, 0.95), //RGB, ranging from 0.0 - 1.0
		roughness: 1.0 // ideal Diffuse material	
	} );
	
	shortBoxMesh = new THREE.Mesh(shortBoxGeometry, shortBoxMaterial);
	pathTracingScene.add(shortBoxMesh);
	shortBoxMesh.visible = false;
	shortBoxMesh.rotation.set(0, -Math.PI * 0.09, 0);
	shortBoxMesh.position.set(370, 85, -170);
	shortBoxMesh.updateMatrixWorld(true); // 'true' forces immediate matrix update
	

	// set camera's field of view
	worldCamera.fov = 31;
	focusDistance = 1180.0;

	// position and orient camera
	cameraControlsObject.position.set(278, 270, 1050);
	///cameraControlsYawObject.rotation.y = 0.0;
	// look slightly upward
	cameraControlsPitchObject.rotation.x = 0.005;

} // end function initSceneData()



// called automatically from within initTHREEjs() function
function initPathTracingShaders() 
{
	// scene/demo-specific uniforms go here     
	pathTracingUniforms.uTallBoxInvMatrix = { type: "m4", value: new THREE.Matrix4() };
	pathTracingUniforms.uShortBoxInvMatrix = { type: "m4", value: new THREE.Matrix4() };
	
	
	pathTracingDefines = {
		//NUMBER_OF_TRIANGLES: total_number_of_triangles
	};

	// load vertex and fragment shader files that are used in the pathTracing material, mesh and scene
	fileLoader.load('shaders/common_PathTracing_Vertex.glsl', function (shaderText) {
		pathTracingVertexShader = shaderText;

		createPathTracingMaterial();
	});

} // end function initPathTracingShaders()


// called automatically from within initPathTracingShaders() function above
function createPathTracingMaterial() 
{
	fileLoader.load('shaders/Cornell_Box_Fragment.glsl', function (shaderText) {
		
		pathTracingFragmentShader = shaderText;

		pathTracingMaterial = new THREE.ShaderMaterial({
			uniforms: pathTracingUniforms,
			defines: pathTracingDefines,
			vertexShader: pathTracingVertexShader,
			fragmentShader: pathTracingFragmentShader,
			depthTest: false,
			depthWrite: false
		});

		pathTracingMesh = new THREE.Mesh(pathTracingGeometry, pathTracingMaterial);
		pathTracingScene.add(pathTracingMesh);

		// the following keeps the large scene ShaderMaterial quad right in front 
		//   of the camera at all times. This is necessary because without it, the scene 
		//   quad will fall out of view and get clipped when the camera rotates past 180 degrees.
		worldCamera.add(pathTracingMesh);
		
	});

} // end function createPathTracingMaterial()



// called automatically from within the animate() function
function updateVariablesAndUniforms() 
{   
	// BOXES
	pathTracingUniforms.uTallBoxInvMatrix.value.copy(tallBoxMesh.matrixWorld).invert();
	pathTracingUniforms.uShortBoxInvMatrix.value.copy(shortBoxMesh.matrixWorld).invert();
	
	// INFO
	cameraInfoElement.innerHTML = "FOV: " + worldCamera.fov + " / Aperture: " + apertureSize.toFixed(2) + " / FocusDistance: " + focusDistance + "<br>" + "Samples: " + sampleCounter;

} // end function updateVariablesAndUniforms()



init(); // init app and start animating
