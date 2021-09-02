// scene/demo-specific variables go here
var sceneIsDynamic = true;
var camFlightSpeed = 1000;
var sunAngle = 0;
var sunDirection = new THREE.Vector3();
var waterLevel = 0.0;
var cameraUnderWater = false;

// called automatically from within initTHREEjs() function
function initSceneData()
{
        // scene/demo-specific three.js objects setup goes here

        // pixelRatio is resolution - range: 0.5(half resolution) to 1.0(full resolution)
        pixelRatio = mouseControl ? 0.75 : 0.75; // less demanding on battery-powered mobile devices

        EPS_intersect = mouseControl ? 1.0 : 5.0; // less precision on mobile

        // set camera's field of view
        worldCamera.fov = 60;
        focusDistance = 2000.0;

        // position and orient camera
        cameraControlsObject.position.set(-7134, 1979, -4422);
        cameraControlsYawObject.rotation.y = 3.0;
        cameraControlsPitchObject.rotation.x = 0.0;

        PerlinNoiseTexture = new THREE.TextureLoader().load('textures/perlin256.png');
        PerlinNoiseTexture.wrapS = THREE.RepeatWrapping;
        PerlinNoiseTexture.wrapT = THREE.RepeatWrapping;
        PerlinNoiseTexture.flipY = false;
        PerlinNoiseTexture.minFilter = THREE.LinearFilter;
        PerlinNoiseTexture.magFilter = THREE.LinearFilter;
        PerlinNoiseTexture.generateMipmaps = false;

} // end function initSceneData()



// called automatically from within initTHREEjs() function
function initPathTracingShaders()
{

        // scene/demo-specific uniforms go here
        pathTracingUniforms.t_PerlinNoise = { type: "t", value: PerlinNoiseTexture };       
        pathTracingUniforms.uWaterLevel = { type: "f", value: 0.0 };
        pathTracingUniforms.uSunDirection = { type: "v3", value: new THREE.Vector3() };

        pathTracingDefines = {
                //NUMBER_OF_TRIANGLES: total_number_of_triangles
        };

        // load vertex and fragment shader files that are used in the pathTracing material, mesh and scene
        fileLoader.load('shaders/common_PathTracing_Vertex.glsl', function (shaderText)
        {
                pathTracingVertexShader = shaderText;

                createPathTracingMaterial();
        });

} // end function initPathTracingShaders()


// called automatically from within initPathTracingShaders() function above
function createPathTracingMaterial()
{

        fileLoader.load('shaders/Arctic_Circle_Fragment.glsl', function (shaderText)
        {

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

        // scene/demo-specific variables
        if (cameraControlsObject.position.y < 0.0)
                cameraUnderWater = true;
        else cameraUnderWater = false;

        sunAngle = ((elapsedTime * 0.04) + 0.5) % TWO_PI;
        sunDirection.set(Math.cos(sunAngle), Math.cos(sunAngle) * 0.2 + 0.2, Math.sin(sunAngle));
        sunDirection.normalize();

        // scene/demo-specific uniforms
        pathTracingUniforms.uWaterLevel.value = waterLevel;
        pathTracingUniforms.uSunDirection.value.copy(sunDirection);

        // INFO
        cameraInfoElement.innerHTML = "FOV: " + worldCamera.fov + " / Aperture: " + apertureSize.toFixed(2) + " / FocusDistance: " + focusDistance + "<br>" + "Samples: " + sampleCounter;

} // end function updateUniforms()



init(); // init app and start animating
