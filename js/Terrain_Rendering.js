// scene/demo-specific variables go here
var EPS_intersect;
var sceneIsDynamic = true;
var camFlightSpeed = 300;
var sunAngle = 0;
var sunDirection = new THREE.Vector3();
var waterLevel = 400;
var cameraUnderWater = 0.0;
var PerlinNoiseTexture;

// called automatically from within initTHREEjs() function
function initSceneData() {
        
        // scene/demo-specific three.js objects setup goes here
        EPS_intersect = mouseControl ? 0.2 : 4.0; // less precision on mobile

        // set camera's field of view
        worldCamera.fov = 60;
        focusDistance = 3000.0;

        // position and orient camera
        cameraControlsObject.position.set(-837, 1350, 2156);
	cameraControlsYawObject.rotation.y = 0.0;
	cameraControlsPitchObject.rotation.x = 0.0;
        
        PerlinNoiseTexture = new THREE.TextureLoader().load( 'textures/perlin256.png' );
        PerlinNoiseTexture.wrapS = THREE.RepeatWrapping;
        PerlinNoiseTexture.wrapT = THREE.RepeatWrapping;
        PerlinNoiseTexture.flipY = false;
        PerlinNoiseTexture.minFilter = THREE.LinearFilter;
        PerlinNoiseTexture.magFilter = THREE.LinearFilter;
        PerlinNoiseTexture.generateMipmaps = false;

} // end function initSceneData()



// called automatically from within initTHREEjs() function
function initPathTracingShaders() {
 
        // scene/demo-specific uniforms go here
        pathTracingUniforms.t_PerlinNoise = { type: "t", value: PerlinNoiseTexture };      
	pathTracingUniforms.uCameraUnderWater = { type: "f", value: 0.0 };
	pathTracingUniforms.uWaterLevel = { type: "f", value: 0.0 };  
	pathTracingUniforms.uSunDirection = { type: "v3", value: new THREE.Vector3() };

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
function createPathTracingMaterial() {

        fileLoader.load('shaders/Terrain_Rendering_Fragment.glsl', function (shaderText) {
                
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
function updateVariablesAndUniforms() {
        
        // scene/demo-specific variables
        sunAngle = (elapsedTime * 0.035) % (Math.PI + 0.2) - 0.11;
        sunDirection.set(Math.cos(sunAngle), Math.sin(sunAngle), -Math.cos(sunAngle) * 2.0);
        sunDirection.normalize();
        
        // scene/demo-specific uniforms
        if (cameraControlsObject.position.y < waterLevel)
                cameraUnderWater = 1.0;
        else cameraUnderWater = 0.0;

        pathTracingUniforms.uCameraUnderWater.value = cameraUnderWater;
        pathTracingUniforms.uWaterLevel.value = waterLevel;
        pathTracingUniforms.uSunDirection.value.copy(sunDirection);
        
        // INFO
        cameraInfoElement.innerHTML = "FOV: " + worldCamera.fov + " / Aperture: " + apertureSize.toFixed(2) + " / FocusDistance: " + focusDistance + "<br>" + "Samples: " + sampleCounter;
				
} // end function updateUniforms()



init(); // init app and start animating
