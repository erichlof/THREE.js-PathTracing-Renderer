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


var modelMesh;
var modelPositionOffset = new THREE.Vector3();
var modelScale = 1.0;
//var triangleIDMarker0, triangleIDMarker1, triangleIDMarker2;
var meshList = [];
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
var triangleMaterialMarkers = [];
var pathTracingMaterialList = [];


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

        //gltfLoader.load("models/StanfordBunny.glb", function( meshGroup ) { // Triangles: 30,338
        gltfLoader.load("models/UtahTeapot.glb", function( meshGroup ) { // Triangles: 30,338

                if (meshGroup.scene) 
                        meshGroup = meshGroup.scene;

                meshGroup.traverse( function ( child ) {

                        if ( child.isMesh ) {
                                
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
                } );

                modelMesh = meshList[0].clone();

                for (let i = 0; i < meshList.length; i++) {
                        geoList.push(meshList[i].geometry);
                }

                modelMesh.geometry = THREE.BufferGeometryUtils.mergeBufferGeometries(geoList);
                
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



// called automatically from within initTHREEjs() function
function initSceneData() {
        
        // scene/demo-specific three.js objects setup goes here
        EPS_intersect = mouseControl ? 0.01 : 0.5; // less precision on mobile

        // set camera's field of view
        worldCamera.fov = 50;
        focusDistance = 230.0;
        
        // position and orient camera
        cameraControlsObject.position.set(-11, -15, 30);
	// look slightly to the right
        cameraControlsYawObject.rotation.y = -0.2;
                

        total_number_of_triangles = modelMesh.geometry.attributes.position.array.length / 9;
        console.log("Triangle count:" + total_number_of_triangles);

        totalWork = new Uint32Array(total_number_of_triangles);

        var triangle_b_box_min = new THREE.Vector3();
        var triangle_b_box_max = new THREE.Vector3();
        var triangle_b_box_centroid = new THREE.Vector3();
        
        
        var vpa = new Float32Array(modelMesh.geometry.attributes.position.array);
        var vna = new Float32Array(modelMesh.geometry.attributes.normal.array);
        var vta = null;
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
        
        
        paintingTexture = new THREE.TextureLoader().load( 'textures/painting.jpg' );
        paintingTexture.wrapS = THREE.RepeatWrapping;
        paintingTexture.wrapT = THREE.RepeatWrapping;
        paintingTexture.minFilter = THREE.NearestFilter;
        paintingTexture.magFilter = THREE.NearestFilter;
        paintingTexture.generateMipmaps = false;
        
        darkWoodTexture = new THREE.TextureLoader().load( 'textures/darkWood.jpg' );
        darkWoodTexture.wrapS = THREE.RepeatWrapping;
        darkWoodTexture.wrapT = THREE.RepeatWrapping;
        darkWoodTexture.minFilter = THREE.NearestFilter; 
        darkWoodTexture.magFilter = THREE.NearestFilter;
        darkWoodTexture.generateMipmaps = false;
        
        lightWoodTexture = new THREE.TextureLoader().load( 'textures/tableWood.jpg' );
        lightWoodTexture.wrapS = THREE.RepeatWrapping;
        lightWoodTexture.wrapT = THREE.RepeatWrapping;
        lightWoodTexture.minFilter = THREE.NearestFilter; 
        lightWoodTexture.magFilter = THREE.NearestFilter;
        lightWoodTexture.generateMipmaps = false;
        
        marbleTexture = new THREE.TextureLoader().load( 'textures/whiteMarbleThinVein.jpg' );
        marbleTexture.wrapS = THREE.RepeatWrapping;
        marbleTexture.wrapT = THREE.RepeatWrapping;
        //marbleTexture.flipY = true;
        marbleTexture.minFilter = THREE.NearestFilter;
        marbleTexture.magFilter = THREE.NearestFilter;
        marbleTexture.generateMipmaps = false;

        hammeredMetalNormalMapTexture = new THREE.TextureLoader().load( 'textures/hammeredMetal_NormalMap.jpg' );
        hammeredMetalNormalMapTexture.wrapS = THREE.RepeatWrapping;
        hammeredMetalNormalMapTexture.wrapT = THREE.RepeatWrapping;
        //hammeredMetalNormalMapTexture.flipY = true;
        hammeredMetalNormalMapTexture.minFilter = THREE.NearestFilter;
        hammeredMetalNormalMapTexture.magFilter = THREE.NearestFilter;
        hammeredMetalNormalMapTexture.generateMipmaps = false;

} // end function initSceneData()



// called automatically from within initTHREEjs() function
function initPathTracingShaders() {
 
        // scene/demo-specific uniforms go here    
        pathTracingUniforms.tTriangleTexture = { type: "t", value: triangleDataTexture };
	pathTracingUniforms.tAABBTexture = { type: "t", value: aabbDataTexture };    
	pathTracingUniforms.tPaintingTexture = { type: "t", value: paintingTexture };
	pathTracingUniforms.tDarkWoodTexture = { type: "t", value: darkWoodTexture };
	pathTracingUniforms.tLightWoodTexture = { type: "t", value: lightWoodTexture };
	pathTracingUniforms.tMarbleTexture = { type: "t", value: marbleTexture };
	pathTracingUniforms.tHammeredMetalNormalMapTexture = { type: "t", value: hammeredMetalNormalMapTexture };  
	pathTracingUniforms.uDoorObjectInvMatrix = { type: "m4", value: new THREE.Matrix4() };
        pathTracingUniforms.uColorEdgeSharpeningRate = { type: "f", value: 0.01 };
        pathTracingUniforms.uNormalEdgeSharpeningRate = { type: "f", value: 0.005 };
        pathTracingUniforms.uObjectEdgeSharpeningRate = { type: "f", value: 0.01 };

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
        
        if (keyPressed('e') && !keyPressed('r')) {
					
                decreaseDoorAngle = true;
        }
        if (keyPressed('r') && !keyPressed('e')) {
                
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

        // DOOR
        doorObject.updateMatrixWorld(true); // 'true' forces immediate matrix update
        pathTracingUniforms.uDoorObjectInvMatrix.value.copy( doorObject.matrixWorld ).invert();
        
        // INFO
        cameraInfoElement.innerHTML = "Press E and R to open and close door: " + "<br>" + "FOV: " + worldCamera.fov + " / Aperture: " + 
                apertureSize.toFixed(2) + " / FocusDistance: " + focusDistance + "<br>" + "Samples: " + sampleCounter;
				
} // end function updateVariablesAndUniforms()



load_GLTF_Models(); // load model, init app, and start animating
