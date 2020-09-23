/* BVH (Bounding Volume Hierarchy) Iterative Builder */
/*
Inspired by: Thanassis Tsiodras (ttsiodras on GitHub)
https://github.com/ttsiodras/renderer-cuda/blob/master/src/BVH.cpp
Edited and Ported from C++ to Javascript by: Erich Loftis (erichlof on GitHub)
https://github.com/erichlof/THREE.js-PathTracing-Renderer
*/


let stackptr = 0;
let buildnodes = [];
let leftWorkLists = [];
let rightWorkLists = [];
let parentList = [];
let bestSplit = 0;
let bestAxis = 0;
let leftWorkCounter = 0;
let rightWorkCounter = 0;
let currentMinCorner = new THREE.Vector3();
let currentMaxCorner = new THREE.Vector3();
let testMinCorner = new THREE.Vector3();
let testMaxCorner = new THREE.Vector3();
let testCentroid = new THREE.Vector3();
let currentCentroid = new THREE.Vector3();
let centroidAverage = new THREE.Vector3();
let spatialAverage = new THREE.Vector3();
let LBottomCorner = new THREE.Vector3();
let LTopCorner = new THREE.Vector3();
let RBottomCorner = new THREE.Vector3();
let RTopCorner = new THREE.Vector3();
let k, value, side1, side2, side3, minCost, testSplit;
let axis, countLeft, countRight;
let lside1, lside2, lside3, rside1, rside2, rside3;
let surfaceLeft, surfaceRight, totalCost;
let currentList;

function BVH_FlatNode() {

        this.idSelf = 0;
        this.idLeftChild = 0;
        this.idRightChild = 0;
        this.idParent = 0;
        this.minCorner = new THREE.Vector3();
        this.maxCorner = new THREE.Vector3();
}


function BVH_Create_Node(workList, aabb_array, idParent, isLeftBranch) {

        // re-initialize bounding box extents 
        currentMinCorner.set(Infinity, Infinity, Infinity);
        currentMaxCorner.set(-Infinity, -Infinity, -Infinity);
        
        if (workList.length < 1) { // should never happen, but just in case...
                return;
        }
        else if (workList.length == 1) {
                // if we're down to 1 primitive aabb, quickly create a leaf node and return.
                k = workList[0];
                // create leaf node
                let flatLeafNode = new BVH_FlatNode();
                flatLeafNode.idSelf = buildnodes.length;
                flatLeafNode.idLeftChild = -k - 1; // a negative value signifies leaf node - used as triangle id
                flatLeafNode.idRightChild = -1;
                flatLeafNode.idParent = idParent;
                flatLeafNode.minCorner.set(aabb_array[9 * k + 0], aabb_array[9 * k + 1], aabb_array[9 * k + 2]);
                flatLeafNode.maxCorner.set(aabb_array[9 * k + 3], aabb_array[9 * k + 4], aabb_array[9 * k + 5]);
                buildnodes.push(flatLeafNode);
                
                // if this is a right branch, fill in parent's missing link to this right child, 
                // now that we have assigned this right child an ID
                if (!isLeftBranch) 
                        buildnodes[idParent].idRightChild = flatLeafNode.idSelf;

                return;
        } // end else if (workList.length == 1)

        else if (workList.length == 2) {
                // if we're down to 2 primitives, go ahead and quickly create a parent and 2 child leaf nodes and return. 
                // this takes the burden off of the later section which has to figure out how to sort arbitrary numbers of aabb's.
                
                // construct bounding box around the current workList's triangle AABBs
                for (let i = 0; i < workList.length; i++) {
                        k = workList[i];
                        testMinCorner.set(aabb_array[9 * k + 0], aabb_array[9 * k + 1], aabb_array[9 * k + 2]);
                        testMaxCorner.set(aabb_array[9 * k + 3], aabb_array[9 * k + 4], aabb_array[9 * k + 5]);
                        currentMinCorner.min(testMinCorner);
                        currentMaxCorner.max(testMaxCorner);
                }

                // create inner parent node
                let flatnode0 = new BVH_FlatNode();
                flatnode0.idSelf = buildnodes.length;
                flatnode0.idLeftChild = buildnodes.length + 1;
                flatnode0.idRightChild = buildnodes.length + 2;
                flatnode0.idParent = idParent;
                flatnode0.minCorner.copy(currentMinCorner);
                flatnode0.maxCorner.copy(currentMaxCorner);
                buildnodes.push(flatnode0);

                // if this is a right branch, fill in parent's missing link to this right child, 
                // now that we have assigned this right child an ID
                if (!isLeftBranch) 
                        buildnodes[idParent].idRightChild = flatnode0.idSelf;
                
                
                k = workList[0];
                // create 'left' child leaf node
                let flatnode1 = new BVH_FlatNode();
                flatnode1.idSelf = buildnodes.length;
                flatnode1.idLeftChild = -k - 1;
                flatnode1.idRightChild = -1;
                flatnode1.idParent = flatnode0.idSelf;
                flatnode1.minCorner.set(aabb_array[9 * k + 0], aabb_array[9 * k + 1], aabb_array[9 * k + 2]);
                flatnode1.maxCorner.set(aabb_array[9 * k + 3], aabb_array[9 * k + 4], aabb_array[9 * k + 5]);
                buildnodes.push(flatnode1);
                
                k = workList[1];
                // create 'right' child leaf node
                let flatnode2 = new BVH_FlatNode();
                flatnode2.idSelf = buildnodes.length;
                flatnode2.idLeftChild = -k - 1;
                flatnode2.idRightChild = -1;
                flatnode2.idParent = flatnode0.idSelf;
                flatnode2.minCorner.set(aabb_array[9 * k + 0], aabb_array[9 * k + 1], aabb_array[9 * k + 2]);
                flatnode2.maxCorner.set(aabb_array[9 * k + 3], aabb_array[9 * k + 4], aabb_array[9 * k + 5]);
                buildnodes.push(flatnode2);
                
                return;
        } // end else if (workList.length == 2)

        else if (workList.length > 2) {
                // this is where the real work happens: we must sort an arbitrary number of primitive aabb's.
                // to get a balanced tree, we hope for about half to be placed in left child, half to be placed in right child.
                centroidAverage.set(0,0,0);

                // construct bounding box around all of the current workList's triangle AABBs
                for (let i = 0; i < workList.length; i++) {
                        k = workList[i];
                        testMinCorner.set(aabb_array[9 * k + 0], aabb_array[9 * k + 1], aabb_array[9 * k + 2]);
                        testMaxCorner.set(aabb_array[9 * k + 3], aabb_array[9 * k + 4], aabb_array[9 * k + 5]);
                        currentCentroid.set(aabb_array[9 * k + 6], aabb_array[9 * k + 7], aabb_array[9 * k + 8]);
                        currentMinCorner.min(testMinCorner);
                        currentMaxCorner.max(testMaxCorner);
                        centroidAverage.add(currentCentroid); // will be used later for averaging
                }

		// calculate the middle point of the current box (aka 'spatial median')
                spatialAverage.copy(currentMinCorner);
                spatialAverage.add(currentMaxCorner);
                spatialAverage.multiplyScalar(0.5);

		// calculate the average point between all the triangles' aabb centroids in this list (aka 'object median')
		centroidAverage.multiplyScalar(1.0 / workList.length);

		// it has been shown statistically that the best location for a split plane is about halfway
		// between the spatial median and the object median.  Calculate this point between the two:
                centroidAverage.add(spatialAverage);
                centroidAverage.multiplyScalar(0.5);


                // create inner node
                let flatnode = new BVH_FlatNode();
                flatnode.idSelf = buildnodes.length;
                flatnode.idLeftChild = buildnodes.length + 1; // traverse down the left branches first
                flatnode.idRightChild = 0; // missing link will be filled in soon, don't know how deep the left branches will go
                flatnode.idParent = idParent;
                flatnode.minCorner.copy(currentMinCorner);
                flatnode.maxCorner.copy(currentMaxCorner);
                buildnodes.push(flatnode);

                // if this is a right branch, fill in parent's missing link to this right child, 
                // now that we have assigned this right child an ID
                if (!isLeftBranch) 
                        buildnodes[idParent].idRightChild = flatnode.idSelf;
                

                side1 = currentMaxCorner.x - currentMinCorner.x; // length bbox along X-axis
                side2 = currentMaxCorner.y - currentMinCorner.y; // length bbox along Y-axis
                side3 = currentMaxCorner.z - currentMinCorner.z; // length bbox along Z-axis

                bestAxis = 0;
                bestSplit = centroidAverage.x;

                // determine the longest extent of the box, and start with that as splitting dimension
                if (side1 > side2 && side1 > side3) {
                        bestAxis = 0;
                        bestSplit = centroidAverage.x;
                }      
                else if (side2 > side1 && side2 > side3) {
                        bestAxis = 1;
                        bestSplit = centroidAverage.y;
                }       
                else if (side3 > side1 && side3 > side2) {
                        bestAxis = 2;
                        bestSplit = centroidAverage.z;
                }
                        
                // try best axis first, then try the other two if necessary
                for (let j = 0; j < 3; j++) {
                        // distribute the triangle AABBs in the left or right child nodes
                        // reset counters for the loop coming up
                        leftWorkCounter = 0;
                        rightWorkCounter = 0;

                        // this loop is to count how many elements we need for the left branch and the right branch
                        for (let i = 0; i < workList.length; i++)
                        {
                                k = workList[i];
                                testCentroid.set(aabb_array[9 * k + 6], aabb_array[9 * k + 7], aabb_array[9 * k + 8]);

                                // get bbox center
                                if (bestAxis == 0) value = testCentroid.x; // X-axis
                                else if (bestAxis == 1) value = testCentroid.y; // Y-axis
                                else value = testCentroid.z; // Z-axis

                                if (value < bestSplit)
                                {
                                        leftWorkCounter++;
                                } else
                                {
                                        rightWorkCounter++;
                                }
                        }

                        if (leftWorkCounter > 0 && rightWorkCounter > 0) {
                                break; // success, move on to the next part
                        }
                        else if (leftWorkCounter == 0 || rightWorkCounter == 0) {
				// try another axis
                                if (bestAxis == 0) {
                                        bestAxis = 1;
                                        bestSplit = centroidAverage.y;
                                }
                                else if (bestAxis == 1)
                                {
                                        bestAxis = 2;
                                        bestSplit = centroidAverage.z;
                                }
                                else if (bestAxis == 2)
                                {
                                        bestAxis = 0;
                                        bestSplit = centroidAverage.x;
                                }

                                continue;
                        }

                } // end for (let j = 0; j < 3; j++)
		      
		// if the below if statement is true, then we have successfully sorted the triangle aabb's
                if (leftWorkCounter > 0 && rightWorkCounter > 0) {
                        // now that the size of each branch is known, we can initialize the left and right arrays
                        leftWorkLists[stackptr] = new Uint32Array(leftWorkCounter);
                        rightWorkLists[stackptr] = new Uint32Array(rightWorkCounter);

                        // reset counters for the loop coming up
                        leftWorkCounter = 0;
                        rightWorkCounter = 0;

                        // populate the current leftWorkLists and rightWorklists
                        for (let i = 0; i < workList.length; i++)
                        {
                                k = workList[i];
                                testCentroid.set(aabb_array[9 * k + 6], aabb_array[9 * k + 7], aabb_array[9 * k + 8]);

                                // get bbox center
                                if (bestAxis == 0) value = testCentroid.x; // X-axis
                                else if (bestAxis == 1) value = testCentroid.y; // Y-axis
                                else value = testCentroid.z; // Z-axis

                                if (value < bestSplit)
                                {
                                        leftWorkLists[stackptr][leftWorkCounter] = k;
                                        leftWorkCounter++;
                                } else
                                {
                                        rightWorkLists[stackptr][rightWorkCounter] = k;
                                        rightWorkCounter++;
                                }
                        }

			return; // success!
			
                } // end if (leftWorkCounter > 0 && rightWorkCounter > 0)
                

                // if we reached this point, the builder failed to find a decent splitting plane axis, so
                // manually populate the current leftWorkLists and rightWorklists.
                leftWorkCounter = 0;
                rightWorkCounter = 0;

                // this loop is to count how many elements we need for the left branch and the right branch
                for (let i = 0; i < workList.length; i++)
                {
                        if (i % 2 == 0)
                        {
                                leftWorkCounter++;
                        } else
                        {
                                rightWorkCounter++;
                        }
                }

                // now that the size of each branch is known, we can initialize the left and right arrays
                leftWorkLists[stackptr] = new Uint32Array(leftWorkCounter);
                rightWorkLists[stackptr] = new Uint32Array(rightWorkCounter);

                // reset counters for the loop coming up
                leftWorkCounter = 0;
                rightWorkCounter = 0;

                for (let i = 0; i < workList.length; i++)
                {
                        k = workList[i];

                        if (i % 2 == 0)
                        {
                                leftWorkLists[stackptr][leftWorkCounter] = k;
                                leftWorkCounter++;
                        } else
                        {
                                rightWorkLists[stackptr][rightWorkCounter] = k;
                                rightWorkCounter++;
                        }
                }
                
        } // end else if (workList.length > 2)

} // end function BVH_Create_Node(workList, aabb_array, idParent, isLeftBranch)



function BVH_Build_Iterative(workList, aabb_array) {
        
        currentList = workList;

        // reset BVH builder arrays;
        buildnodes = [];
        leftWorkLists = [];
        rightWorkLists = [];
        parentList = [];

        stackptr = 0;

        parentList.push(buildnodes.length - 1);

        // parent id of -1, meaning this is the root node, which has no parent
        BVH_Create_Node(currentList, aabb_array, -1, true); // build root node

        // build the tree using the "go down left branches until done, then ascend back up right branches" approach
        while (stackptr > -1) {
                
                // pop the next node off of the left-side stack
                currentList = leftWorkLists[stackptr];
                
                if (currentList != undefined) { // left side of tree
                        
                        leftWorkLists[stackptr] = null; // mark as processed
                        stackptr++;

                        parentList.push(buildnodes.length - 1);

                        // build the left node
                        BVH_Create_Node(currentList, aabb_array, buildnodes.length - 1, true);
                }
                else { // right side of tree
                        // pop the next node off of the right-side stack
                        currentList = rightWorkLists[stackptr];

                        if (currentList != undefined) {

                                rightWorkLists[stackptr] = null; // mark as processed
                                stackptr++;

                                // build the right node
                                BVH_Create_Node(currentList, aabb_array, parentList.pop(), false);
                        }
                        else {
                                stackptr--;
                        }
                }
                
        } // end while (stackptr > -1)

        
} // end function BVH_Build_Iterative(workList, aabb_array)
