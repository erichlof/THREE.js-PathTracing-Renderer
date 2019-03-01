// scene/demo-specific variables go here

var doorObject;
var paintingTexture, darkWoodTexture, lightWoodTexture, marbleTexture;
var hammeredMetalNormalMapTexture;
var increaseDoorAngle = false;
var decreaseDoorAngle = false;
var sceneIsDynamic = false;
var camFlightSpeed = 200;

var vp0 = new THREE.Vector3(); // vertex positions data
var vp1 = new THREE.Vector3();
var vp2 = new THREE.Vector3();
var vn0 = new THREE.Vector3(); // vertex normals data
var vn1 = new THREE.Vector3();
var vn2 = new THREE.Vector3();
var vt0 = new THREE.Vector2(); // vertex texture-coordinates(UV) data
var vt1 = new THREE.Vector2();
var vt2 = new THREE.Vector2();

var modelMesh_0;
var modelScale_0 = 1.0;
var modelPositionOffset_0 = new THREE.Vector3();
//var albedoMap_0, emissiveMap_0, metallicRoughnessMap_0, normalMap_0;
var triangleMaterialMarkers = [];
var pathTracingMaterialList = [];
var meshList = [];
var geoList_0 = [];

var modelMesh_1;
var modelScale_1 = 1.0;
var modelPositionOffset_1 = new THREE.Vector3();
//var albedoMap_1, emissiveMap_1, metallicRoughnessMap_1, normalMap_1;
var geoList_1 = [];

var modelMesh_2;
var modelScale_2 = 1.0;
var modelPositionOffset_2 = new THREE.Vector3();
//var albedoMap_2, emissiveMap_2, metallicRoughnessMap_2, normalMap_2;
var geoList_2 = [];

var modelMesh;
var triangleIDMarker0, triangleIDMarker1, triangleIDMarker2;
var geoList = [];
var triangleDataTexture;
var aabbDataTexture;
var totalGeometryCount = 0;
var total_number_of_triangles = 0;
var totalWork;
var triangle_array = new Float32Array(2048 * 2048 * 4);
// 2048 = width of texture, 2048 = height of texture, 4 = r,g,b, and a components
var aabb_array = new Float32Array(2048 * 2048 * 4);
// 2048 = width of texture, 2048 = height of texture, 4 = r,g,b, and a components


function MaterialObject() {
// a list of material types and their corresponding numbers are found in the 'pathTracingCommon.js' file
        this.type = 1; // default is '1': diffuse type 		
        this.albedoTextureID = -1; // which diffuse map to use for model's color / '-1' = no textures are used
        this.color = new THREE.Color(1.0, 1.0, 1.0); // takes on different meanings, depending on 'type' above
        this.roughness = 0.0; // 0.0 to 1.0 range, perfectly smooth to extremely rough
        this.metalness = 0.0; // 0.0 to 1.0 range, usually either 0 or 1, either non-metal or metal
        this.opacity = 1.0;   // 0.0 to 1.0 range, fully transparent to fully opaque
        this.refractiveIndex = 1.0; // 1.0=air, 1.33=water, 1.4=clearCoat, 1.5=glass, etc.
}


function load_GLTF_Models() {

        var gltfLoader = new THREE.GLTFLoader();

        // teapot_0
        gltfLoader.load("models/UtahTeapot.glb", function( meshGroup ) { // Triangles: 4,032

                if (meshGroup.scene) 
                        meshGroup = meshGroup.scene;

                meshGroup.traverse( function ( child ) {

                        if ( child.isMesh ) {
                                
                                let mat = new MaterialObject();
                                mat.type = 3;
                                mat.albedoTextureID = 0; // allow albedo texturing
                                mat.color.setRGB(0.7, 0.7, 0.7);
                                mat.roughness = child.material.roughness || 0.0;
                                mat.metalness = child.material.metalness || 0.0;
                                mat.opacity = child.material.opacity || 1.0;
                                mat.refractiveIndex = 1.0;
                                pathTracingMaterialList.push(mat);
                                totalGeometryCount += child.geometry.index.count / 3;
                                triangleMaterialMarkers.push(totalGeometryCount);
                                meshList.push(child);
                                geoList_0.push(child.geometry);
                        }
                } );

                modelMesh_0 = new THREE.Mesh();

                modelMesh_0.geometry = THREE.BufferGeometryUtils.mergeBufferGeometries(geoList_0);

                // settings for UtahTeapot model_0
                modelScale_0 = 1.4;
                modelPositionOffset_0.set(-70, -56.5, -180);
                
        }); // end gltfLoader.load()

        // teapot_1
        gltfLoader.load("models/UtahTeapot.glb", function( meshGroup ) { // Triangles: 4,032

                if (meshGroup.scene) 
                        meshGroup = meshGroup.scene;

                meshGroup.traverse( function ( child ) {

                        if ( child.isMesh ) {
                                
                                let mat = new MaterialObject();
                                mat.type = 4;
                                mat.albedoTextureID = 0; // allow albedo texturing
                                mat.color.setRGB(1, 1, 1);
                                mat.roughness = child.material.roughness || 0.0;
                                mat.metalness = child.material.metalness || 0.0;
                                mat.opacity = child.material.opacity || 1.0;
                                mat.refractiveIndex = 1.0;
                                pathTracingMaterialList.push(mat);
                                totalGeometryCount += child.geometry.index.count / 3;
                                triangleMaterialMarkers.push(totalGeometryCount);
                                meshList.push(child);
                                geoList_1.push(child.geometry);
                        }
                } );

                modelMesh_1 = new THREE.Mesh();
                modelMesh_1.geometry = THREE.BufferGeometryUtils.mergeBufferGeometries(geoList_1);

                // settings for UtahTeapot model_1
                modelScale_1 = 1.4;
                modelPositionOffset_1.set(0, -56.5, -180);
                
        }); // end gltfLoader.load()

        // teapot_2
        gltfLoader.load("models/UtahTeapot.glb", function( meshGroup ) { // Triangles: 4,032

                if (meshGroup.scene) 
                        meshGroup = meshGroup.scene;

                meshGroup.traverse( function ( child ) {

                        if ( child.isMesh ) {
                                
                                let mat = new MaterialObject();
                                mat.type = 2;
                                mat.albedoTextureID = 0; // allow albedo texturing
                                mat.color.setRGB(1, 1, 1);
                                mat.roughness = child.material.roughness || 0.0;
                                mat.metalness = child.material.metalness || 0.0;
                                mat.opacity = child.material.opacity || 1.0;
                                mat.refractiveIndex = 1.0;
                                pathTracingMaterialList.push(mat);
                                totalGeometryCount += child.geometry.index.count / 3;
                                triangleMaterialMarkers.push(totalGeometryCount);
                                meshList.push(child);
                                geoList_2.push(child.geometry);
                        }
                } );

                modelMesh_2 = new THREE.Mesh();
                modelMesh_2.geometry = THREE.BufferGeometryUtils.mergeBufferGeometries(geoList_2);

                // settings for UtahTeapot model_2
                modelScale_2 = 1.4;
                modelPositionOffset_2.set(70, -56.5, -180);
                
                // now that the models have been loaded, we can init 
                init();
        }); // end gltfLoader.load()

} // end function load_GLTF_Models()



// called automatically from within initTHREEjs() function
function initSceneData() {
        
        // scene/demo-specific three.js objects setup goes here

        // set camera's field of view
        worldCamera.fov = 50;

        // position and orient camera
        cameraControlsObject.position.set(-11, -15, 30);
        
	// look slightly to the right
        cameraControlsYawObject.rotation.y = -0.2;

        
        triangleIDMarker0 = (modelMesh_0.geometry.index.count / 3);
        triangleIDMarker1 = triangleIDMarker0 + (modelMesh_1.geometry.index.count / 3);
        triangleIDMarker2 = triangleIDMarker1 + (modelMesh_2.geometry.index.count / 3);
        
        var geoList = [];
        geoList.push(modelMesh_0.geometry);
        geoList.push(modelMesh_1.geometry);
        geoList.push(modelMesh_2.geometry);
        modelMesh = new THREE.Mesh();
        modelMesh.geometry = THREE.BufferGeometryUtils.mergeBufferGeometries(geoList);

        if (modelMesh.geometry.index)
                modelMesh.geometry = modelMesh.geometry.toNonIndexed();
        
        
        for (let i = 0; i < meshList.length; i++) {
                if (meshList[i].material.map != undefined) {
                        pathTracingMaterialList[i].albedoTextureID = 0;	
                }				
        }
                

        total_number_of_triangles = (modelMesh.geometry.attributes.position.array.length / 9);
        console.log("Triangle count:" + total_number_of_triangles);

        totalWork = new Uint32Array(total_number_of_triangles);

        var triangle_b_box_min = new THREE.Vector3();
        var triangle_b_box_max = new THREE.Vector3();
        var triangle_b_box_centroid = new THREE.Vector3();
        
        
        var vpa = new Float32Array(modelMesh.geometry.attributes.position.array);
        var vna = new Float32Array(modelMesh.geometry.attributes.normal.array);
        var vta;
        var modelHasUVs = false;
        if (modelMesh.geometry.attributes.uv !== undefined) {
                vta = new Float32Array(modelMesh.geometry.attributes.uv.array);
                modelHasUVs = true;
        }
                
        var materialNumber = 0;

        for (let i = 0; i < total_number_of_triangles; i++) {
        
                triangle_b_box_min.set(Infinity, Infinity, Infinity);
                triangle_b_box_max.set(-Infinity, -Infinity, -Infinity);

                for (let j = 0; j < pathTracingMaterialList.length; j++) {
                        if (i < triangleMaterialMarkers[j]) {
                                materialNumber = j;
                                break;
                        }
                }

                // record vertex texture coordinates (UVs)
                if (modelHasUVs) {
                        vt0.set( vta[6 * i + 0], vta[6 * i + 1] );
                        vt1.set( vta[6 * i + 2], vta[6 * i + 3] );
                        vt2.set( vta[6 * i + 4], vta[6 * i + 5] );
                }
                else {
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
                if (i < triangleIDMarker0) {
                        vp0.multiplyScalar(modelScale_0);
                        vp1.multiplyScalar(modelScale_0);
                        vp2.multiplyScalar(modelScale_0);

                        vp0.add(modelPositionOffset_0);
                        vp1.add(modelPositionOffset_0);
                        vp2.add(modelPositionOffset_0);
                }
                else if (i < triangleIDMarker1) {
                        vp0.multiplyScalar(modelScale_1);
                        vp1.multiplyScalar(modelScale_1);
                        vp2.multiplyScalar(modelScale_1);

                        vp0.add(modelPositionOffset_1);
                        vp1.add(modelPositionOffset_1);
                        vp2.add(modelPositionOffset_1);
                }
                else if (i < triangleIDMarker2) {
                        vp0.multiplyScalar(modelScale_2);
                        vp1.multiplyScalar(modelScale_2);
                        vp2.multiplyScalar(modelScale_2);

                        vp0.add(modelPositionOffset_2);
                        vp1.add(modelPositionOffset_2);
                        vp2.add(modelPositionOffset_2);
                }
                

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
        //console.log(buildnodes);

        // Copy the buildnodes array into the aabb_array_0
        for (let n = 0; n < buildnodes.length; n++) {
                // slot 0
                aabb_array[8 * n + 0] = buildnodes[n].idLeftChild;  // r or x component
                aabb_array[8 * n + 1] = buildnodes[n].minCorner.x;  // g or y component
                aabb_array[8 * n + 2] = buildnodes[n].minCorner.y;  // b or z component
                aabb_array[8 * n + 3] = buildnodes[n].minCorner.z;  // a or w component

                // slot 1
                aabb_array[8 * n + 4] = buildnodes[n].idRightChild; // r or x component
                aabb_array[8 * n + 5] = buildnodes[n].maxCorner.x;  // g or y component
                aabb_array[8 * n + 6] = buildnodes[n].maxCorner.y;  // b or z component
                aabb_array[8 * n + 7] = buildnodes[n].maxCorner.z;  // a or w component
        }

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
        doorObject.rotation.set(0, Math.PI * 2.0 - 0.4, 0);
        doorObject.position.set(179, -5, -298);
        doorObject.updateMatrixWorld(true); // 'true' forces immediate matrix update
        
        
        paintingTexture = new THREE.TextureLoader().load( 'textures/painting.jpg' );
        paintingTexture.wrapS = THREE.RepeatWrapping;
        paintingTexture.wrapT = THREE.RepeatWrapping;
        paintingTexture.minFilter = THREE.LinearFilter; 
        paintingTexture.magFilter = THREE.LinearFilter;
        paintingTexture.generateMipmaps = false;
        
        darkWoodTexture = new THREE.TextureLoader().load( 'textures/darkWood.jpg' );
        darkWoodTexture.wrapS = THREE.RepeatWrapping;
        darkWoodTexture.wrapT = THREE.RepeatWrapping;
        darkWoodTexture.minFilter = THREE.LinearFilter; 
        darkWoodTexture.magFilter = THREE.LinearFilter;
        darkWoodTexture.generateMipmaps = false;
        
        lightWoodTexture = new THREE.TextureLoader().load( 'textures/tableWood.jpg' );
        lightWoodTexture.wrapS = THREE.RepeatWrapping;
        lightWoodTexture.wrapT = THREE.RepeatWrapping;
        lightWoodTexture.minFilter = THREE.LinearFilter; 
        lightWoodTexture.magFilter = THREE.LinearFilter;
        lightWoodTexture.generateMipmaps = false;
        
        marbleTexture = new THREE.TextureLoader().load( 'textures/whiteMarbleThinVein.jpg' );
        marbleTexture.wrapS = THREE.RepeatWrapping;
        marbleTexture.wrapT = THREE.RepeatWrapping;
        //marbleTexture.flipY = true;
        marbleTexture.minFilter = THREE.LinearFilter; 
        marbleTexture.magFilter = THREE.LinearFilter;
        marbleTexture.generateMipmaps = false;

        hammeredMetalNormalMapTexture = new THREE.TextureLoader().load( 'textures/hammeredMetal_NormalMap.jpg' );
        hammeredMetalNormalMapTexture.wrapS = THREE.RepeatWrapping;
        hammeredMetalNormalMapTexture.wrapT = THREE.RepeatWrapping;
        hammeredMetalNormalMapTexture.flipY = true;
        hammeredMetalNormalMapTexture.minFilter = THREE.LinearFilter;
        hammeredMetalNormalMapTexture.magFilter = THREE.LinearFilter;
        hammeredMetalNormalMapTexture.generateMipmaps = false;

} // end function initSceneData()



// called automatically from within initTHREEjs() function
function initPathTracingShaders() {
 
        // scene/demo-specific uniforms go here
        pathTracingUniforms = {
					
                tPreviousTexture: { type: "t", value: screenTextureRenderTarget.texture },
                tTriangleTexture: { type: "t", value: triangleDataTexture },
                tAABBTexture: { type: "t", value: aabbDataTexture },
                
                tPaintingTexture: { type: "t", value: paintingTexture },
                tDarkWoodTexture: { type: "t", value: darkWoodTexture },
                tLightWoodTexture: { type: "t", value: lightWoodTexture },
                tMarbleTexture: { type: "t", value: marbleTexture },
                tHammeredMetalNormalMapTexture: { type: "t", value: hammeredMetalNormalMapTexture },
                
                uCameraIsMoving: { type: "b1", value: false },
                uCameraJustStartedMoving: { type: "b1", value: false },
                uTime: { type: "f", value: 0.0 },
                uSampleCounter: { type: "f", value: 0.0 },
                uFrameCounter: { type: "f", value: 1.0 },
                uULen: { type: "f", value: 1.0 },
                uVLen: { type: "f", value: 1.0 },
                uApertureSize: { type: "f", value: 0.0 },
                uFocusDistance: { type: "f", value: 230.0 },
                
                uResolution: { type: "v2", value: new THREE.Vector2() },
                
                uRandomVector: { type: "v3", value: new THREE.Vector3() },
        
                uCameraMatrix: { type: "m4", value: new THREE.Matrix4() },
                
                uDoorObjectInvMatrix: { type: "m4", value: new THREE.Matrix4() },
                uDoorObjectNormalMatrix: { type: "m3", value: new THREE.Matrix3() }

        };

        pathTracingDefines = {
        	//NUMBER_OF_TRIANGLES: total_number_of_triangles_0
        };

        // load vertex and fragment shader files that are used in the pathTracing material, mesh and scene
        fileLoader.load('shaders/common_PathTracing_Vertex.glsl', function (shaderText) {
                pathTracingVertexShader = shaderText;

                createPathTracingMaterial();
        });

} // end function initPathTracingShaders()



// called automatically from within initPathTracingShaders() function above
function createPathTracingMaterial() {

        fileLoader.load('shaders/Bi-Directional_Difficult_Lighting_Fragment.glsl', function (shaderText) {
                
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
        
        if ( keyboard.pressed('E') && !keyboard.pressed('R') ) {
					
                decreaseDoorAngle = true;
        }
        if ( keyboard.pressed('R') && !keyboard.pressed('E') ) {
                
                increaseDoorAngle = true;
        }

        if (decreaseDoorAngle) {
                doorObject.rotation.y -= 0.01;
                if (doorObject.rotation.y < Math.PI + 0.13)
                        doorObject.rotation.y = Math.PI + 0.13;

                cameraIsMoving = true;
                decreaseDoorAngle = false;
        }
        
        if (increaseDoorAngle) {
                
                doorObject.rotation.y += 0.01;
                if (doorObject.rotation.y > (Math.PI * 2.0))
                        doorObject.rotation.y = (Math.PI * 2.0);

                cameraIsMoving = true;
                increaseDoorAngle = false;
        }

        if (cameraIsMoving) {
                sampleCounter = 1.0;
                frameCounter += 1.0;

                if (!cameraRecentlyMoving) {
                        cameraJustStartedMoving = true;
                        cameraRecentlyMoving = true;
                }
        }

        if ( !cameraIsMoving ) {
                sampleCounter += 1.0; // for progressive refinement of image
                if (sceneIsDynamic)
                        sampleCounter = 1.0; // reset for continuous updating of image
                
                frameCounter  += 1.0;
                if (cameraRecentlyMoving)
                        frameCounter = 1.0;

                cameraRecentlyMoving = false;  
        }

        pathTracingUniforms.uCameraIsMoving.value = cameraIsMoving;
        pathTracingUniforms.uCameraJustStartedMoving.value = cameraJustStartedMoving;
        pathTracingUniforms.uSampleCounter.value = sampleCounter;
        pathTracingUniforms.uFrameCounter.value = frameCounter;
        pathTracingUniforms.uRandomVector.value = randomVector.set( Math.random(), Math.random(), Math.random() );
        
        // DOOR
        doorObject.updateMatrixWorld(true); // 'true' forces immediate matrix update
        pathTracingUniforms.uDoorObjectInvMatrix.value.getInverse( doorObject.matrixWorld );
        pathTracingUniforms.uDoorObjectNormalMatrix.value.getNormalMatrix( doorObject.matrixWorld );
        
        // CAMERA
        cameraControlsObject.updateMatrixWorld(true);			
        pathTracingUniforms.uCameraMatrix.value.copy( worldCamera.matrixWorld );
        screenOutputMaterial.uniforms.uOneOverSampleCounter.value = 1.0 / sampleCounter;
        
        cameraInfoElement.innerHTML = "Press E and R to open and close door: " + "<br>" + "FOV: " + worldCamera.fov + " / Aperture: " + 
                apertureSize.toFixed(2) + " / FocusDistance: " + focusDistance + "<br>" + "Samples: " + sampleCounter;
				
} // end function updateVariablesAndUniforms()



load_GLTF_Models(); // load model, init app, and start animating
