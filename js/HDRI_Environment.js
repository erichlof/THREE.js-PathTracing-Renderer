// scene/demo-specific variables go here
var sceneIsDynamic = false;
var camFlightSpeed = 60;
var hdrPath, hdrTexture, hdrLoader;
var modelMesh;
var modelScale = 1.0;
var modelPositionOffset = new THREE.Vector3();
var albedoTexture;
var total_number_of_triangles = 0;
var triangle_array;
var triangleMaterialMarkers = [];
var pathTracingMaterialList = [];
var uniqueMaterialTextures = [];
var meshList = [];
var geoList = [];
var triangleDataTexture;
var aabb_array;
var aabbDataTexture;
var totalWork;
var vp0 = new THREE.Vector3();
var vp1 = new THREE.Vector3();
var vp2 = new THREE.Vector3();
var vn0 = new THREE.Vector3();
var vn1 = new THREE.Vector3();
var vn2 = new THREE.Vector3();
var vt0 = new THREE.Vector2();
var vt1 = new THREE.Vector2();
var vt2 = new THREE.Vector2();

var gui;
var ableToEngagePointerLock = true;
var HDRI_ExposureController, material_TypeController, material_ColorController, material_RoughnessController;
var changeHDRI_Exposure = false;
var changeMaterialType = false;
var changeMaterialColor = false;
var changeMaterialRoughness = false;


function init_GUI() 
{

        HDRI_ExposureController = {
                HDRI_Exposure: 1.5
	};
	material_TypeController = {
                Material_Type: 3
        };
        material_ColorController = {
                Material_Color: [255, 255, 255]
        };
        material_RoughnessController = {
                Material_Roughness: 0.0
        };
        function HDRI_ExposureChanger() 
        {
                changeHDRI_Exposure = true;
	}
	function materialTypeChanger() 
        {
                changeMaterialType = true;
        }
        function materialColorChanger() 
        {
                changeMaterialColor = true;
        }
        function materialRoughnessChanger() 
        {
                changeMaterialRoughness = true;
        }

        gui = new dat.GUI();
        
	gui.add( HDRI_ExposureController, 'HDRI_Exposure', 0, 3, 0.05 ).onChange( HDRI_ExposureChanger );
	gui.add( material_TypeController, 'Material_Type', 2, 4, 1 ).onChange( materialTypeChanger );
        gui.addColor( material_ColorController, 'Material_Color' ).onChange( materialColorChanger );
        gui.add( material_RoughnessController, 'Material_Roughness', 0.0, 1.0, 0.01 ).onChange( materialRoughnessChanger );

	HDRI_ExposureChanger();
	materialTypeChanger();
        materialColorChanger();
        materialRoughnessChanger();

        gui.domElement.style.webkitUserSelect = "none";
        gui.domElement.style.MozUserSelect = "none";
        
        window.addEventListener('resize', onWindowResize, false);

        if ( 'ontouchstart' in window ) 
        {
                mouseControl = false;
                // if on mobile device, unpause the app because there is no ESC key and no mouse capture to do
                isPaused = false;
                
                ableToEngagePointerLock = true;

                mobileJoystickControls = new MobileJoystickControls ({
                        //showJoystick: true
                });	
        }

        if (mouseControl) 
        {

                window.addEventListener( 'wheel', onMouseWheel, false );

                window.addEventListener("click", function(event) 
                {
                        event.preventDefault();	
                }, false);
                window.addEventListener("dblclick", function(event) 
                {
                        event.preventDefault();	
                }, false);
                
                document.body.addEventListener("click", function(event) 
                {
                        if (!ableToEngagePointerLock)
                                return;
                        this.requestPointerLock = this.requestPointerLock || this.mozRequestPointerLock;
                        this.requestPointerLock();
                }, false);


                pointerlockChange = function (event)
                {
                        if (document.pointerLockElement === document.body ||
                                document.mozPointerLockElement === document.body || document.webkitPointerLockElement === document.body)
                        {
                                document.addEventListener('keydown', onKeyDown, false);
                                document.addEventListener('keyup', onKeyUp, false);
                                isPaused = false;
                        }
                        else
                        {
                                document.removeEventListener('keydown', onKeyDown, false);
                                document.removeEventListener('keyup', onKeyUp, false);
                                isPaused = true;
                        }
                };

                // Hook pointer lock state change events
                document.addEventListener( 'pointerlockchange', pointerlockChange, false );
                document.addEventListener( 'mozpointerlockchange', pointerlockChange, false );
                document.addEventListener( 'webkitpointerlockchange', pointerlockChange, false );

        }

        if (mouseControl) 
        {
                gui.domElement.addEventListener("mouseenter", function(event) 
                {
                                ableToEngagePointerLock = false;	
                }, false);
                gui.domElement.addEventListener("mouseleave", function(event) 
                {
                                ableToEngagePointerLock = true;
                }, false);
        }

        initTHREEjs(); // boilerplate: init necessary three.js items and scene/demo-specific objects

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

        var gltfLoader = new THREE.GLTFLoader();

        gltfLoader.load("models/StanfordDragon.glb", function( meshGroup ) // Triangles: 100,000
        // if you choose to load in the different models below, scroll down and change the *GLTF model settings* for this particular model
        //gltfLoader.load("models/TronTank.gltf", function( meshGroup ) { // Triangles: 17,533
        //gltfLoader.load("models/StanfordBunny.glb", function( meshGroup ) { // Triangles: 30,338
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
                modelScale = 2.0;
                modelPositionOffset.set(0, 28, -40);
                
                // settings for TronTank model
                //modelScale = 3.0;
                //modelMesh.geometry.rotateX(-Math.PI * 0.5);
                //modelPositionOffset.set(-60, 20, -30);

                // settings for StanfordBunny model
		//modelScale = 0.04;
                //modelPositionOffset.set(0, 28, -40);
                
                
                // now that the models have been loaded, we can init (with GUI for this demo)
                init_GUI();

        });

} // end function load_GLTF_Model()



// called automatically from within initTHREEjs() function
function initSceneData() 
{

        //pixelRatio = 1; // for computers with the latest GPUs!

        // scene/demo-specific three.js objects setup goes here
        EPS_intersect = mouseControl ? 0.01 : 1.0; // less precision on mobile

        // set camera's field of view
        worldCamera.fov = 60;
        focusDistance = 80.0;

        // position and orient camera
        cameraControlsObject.position.set(0, 30, 40);
        // look slightly downward
        //cameraControlsPitchObject.rotation.x = -0.2;
        
        total_number_of_triangles = modelMesh.geometry.attributes.position.array.length / 9;
        console.log("Triangle count:" + total_number_of_triangles);

        totalWork = new Uint32Array(total_number_of_triangles);

        triangle_array = new Float32Array(2048 * 2048 * 4);
        // 2048 = width of texture, 2048 = height of texture, 4 = r,g,b, and a components
        
        aabb_array = new Float32Array(2048 * 2048 * 4);
        // 2048 = width of texture, 2048 = height of texture, 4 = r,g,b, and a components

        
        var triangle_b_box_min = new THREE.Vector3();
        var triangle_b_box_max = new THREE.Vector3();
        var triangle_b_box_centroid = new THREE.Vector3();
        

        var vpa = new Float32Array(modelMesh.geometry.attributes.position.array);
        var vna = new Float32Array(modelMesh.geometry.attributes.normal.array);
        var vta = null;
        var modelHasUVs = false;
        if (modelMesh.geometry.attributes.uv !== undefined) 
        {
                vta = new Float32Array(modelMesh.geometry.attributes.uv.array);
                modelHasUVs = true;
        }
                
        var materialNumber = 0;

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

                triangle_b_box_centroid.set((triangle_b_box_min.x + triangle_b_box_max.x) * 0.5,
                                            (triangle_b_box_min.y + triangle_b_box_max.y) * 0.5,
                                            (triangle_b_box_min.z + triangle_b_box_max.z) * 0.5);

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


        hdrLoader = new THREE.RGBELoader();

	hdrPath = 'textures/symmetrical_garden_2k.hdr';
	//hdrPath = 'textures/cloud_layers_2k.hdr';
        //hdrPath = 'textures/delta_2_2k.hdr';
        //hdrPath = 'textures/kiara_5_noon_2k.hdr';
        //hdrPath = 'textures/noon_grass_2k.hdr';

        hdrTexture = hdrLoader.load( hdrPath, function ( texture, textureData ) 
        {
                texture.encoding = THREE.LinearEncoding;
                texture.minFilter = THREE.LinearFilter;
                texture.magFilter = THREE.LinearFilter;
                texture.generateMipmaps = false;
                texture.flipY = true;
        } );

} // end function initSceneData()



// called automatically from within initTHREEjs() function
function initPathTracingShaders() 
{
 
        // scene/demo-specific uniforms go here
        pathTracingUniforms.tTriangleTexture = { type: "t", value: triangleDataTexture };
        pathTracingUniforms.tAABBTexture = { type: "t", value: aabbDataTexture };
        pathTracingUniforms.tHDRTexture = { type: "t", value: hdrTexture };
        pathTracingUniforms.uMaterialType = { type: "i", value: 0 };
        pathTracingUniforms.uHDRI_Exposure = { type: "f", value: 1.0 };
        pathTracingUniforms.uRoughness = { type: "f", value: 0.0 };
        pathTracingUniforms.uMaterialColor = { type: "v3", value: new THREE.Color() };
        
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

        fileLoader.load('shaders/HDRI_Environment_Fragment.glsl', function (shaderText) 
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
        
        if (changeHDRI_Exposure) 
        {
                renderer.toneMappingExposure = HDRI_ExposureController.HDRI_Exposure;
                pathTracingUniforms.uHDRI_Exposure.value = HDRI_ExposureController.HDRI_Exposure;
                cameraIsMoving = true;
                changeHDRI_Exposure = false;
	}
	
	if (changeMaterialType) 
        {
                pathTracingUniforms.uMaterialType.value = material_TypeController.Material_Type;
                cameraIsMoving = true;
                changeMaterialType = false;
        }

        if (changeMaterialColor) 
        {
                pathTracingUniforms.uMaterialColor.value.setRGB( material_ColorController.Material_Color[0] / 255, 
                                                                 material_ColorController.Material_Color[1] / 255, 
                                                                 material_ColorController.Material_Color[2] / 255 );
                cameraIsMoving = true;
                changeMaterialColor = false;
        }

        if (changeMaterialRoughness) 
        {
                pathTracingUniforms.uRoughness.value = material_RoughnessController.Material_Roughness;
                cameraIsMoving = true;
                changeMaterialRoughness = false;
        }

        // INFO   
        cameraInfoElement.innerHTML = "FOV: " + worldCamera.fov + " / Aperture: " + apertureSize.toFixed(2) +
                " / FocusDistance: " + focusDistance + "<br>" + "Samples: " + sampleCounter;

} // end function updateUniforms()



load_GLTF_Model(); // load model, init app, and start animating
