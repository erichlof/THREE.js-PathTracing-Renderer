/* BVH (Bounding Volume Hierarchy) Iterative SAH (Surface Area Heuristic) Builder */
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
let bestSplit = null;
let bestAxis = null;
let rightBranchCounter = 0;
let leftBranchCounter = 0;
let leftWorkCounter = 0;
let rightWorkCounter = 0;
let nullCodePathReached = false;
let currentMinCorner = new THREE.Vector3();
let currentMaxCorner = new THREE.Vector3();
let testMinCorner = new THREE.Vector3();
let testMaxCorner = new THREE.Vector3();
let testCentroid = new THREE.Vector3();
let currentCentroid = new THREE.Vector3();
let centroidAverage = new THREE.Vector3();
let LBottomCorner = new THREE.Vector3();
let LTopCorner = new THREE.Vector3();
let RBottomCorner = new THREE.Vector3();
let RTopCorner = new THREE.Vector3();
let k, value, side1, side2, side3, minCost, testSplit;
let axis, countLeft, countRight;
let lside1, lside2, lside3, rside1, rside2, rside3;
let surfaceLeft, surfaceRight, totalCost;
let currentList;

function BVH_FlatNode()
{

        this.idSelf = 0;
        this.idLeftChild = 0;
        this.idRightChild = 0;
        this.idParent = 0;
        this.minCorner = new THREE.Vector3();
        this.maxCorner = new THREE.Vector3();
}


function BVH_Create_Node(workList, aabb_array, idParent, isLeftBranch)
{

        // re-initialize bounding box extents
        currentMinCorner.set(Infinity, Infinity, Infinity);
        currentMaxCorner.set(-Infinity, -Infinity, -Infinity);

        if (workList.length < 1)
        {
                return;
        }
        else if (workList.length == 1)
        {
                //console.log("worklist.length = 1 code path reached");
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
                //console.log(flatLeafNode);

                // if this is a right branch, fill in parent's missing link to this right child, 
                // now that we have assigned this right child an ID
                if (!isLeftBranch)
                        buildnodes[idParent].idRightChild = flatLeafNode.idSelf;

                return;
        } // end else if (workList.length == 1)

        else if (workList.length == 2)
        {

                // construct bounding box around the current workList's triangle AABBs
                for (let i = 0; i < workList.length; i++)
                {
                        k = workList[i];
                        testMinCorner.set(aabb_array[9 * k + 0], aabb_array[9 * k + 1], aabb_array[9 * k + 2]);
                        testMaxCorner.set(aabb_array[9 * k + 3], aabb_array[9 * k + 4], aabb_array[9 * k + 5]);
                        currentMinCorner.min(testMinCorner);
                        currentMaxCorner.max(testMaxCorner);
                }

                // create inner node
                let flatnode0 = new BVH_FlatNode();
                flatnode0.idSelf = buildnodes.length;
                flatnode0.idLeftChild = buildnodes.length + 1;
                flatnode0.idRightChild = buildnodes.length + 2;
                flatnode0.idParent = idParent;
                flatnode0.minCorner.copy(currentMinCorner);
                flatnode0.maxCorner.copy(currentMaxCorner);
                buildnodes.push(flatnode0);
                //console.log(flatnode0);

                // if this is a right branch, fill in parent's missing link to this right child, 
                // now that we have assigned this right child an ID
                if (!isLeftBranch)
                        buildnodes[idParent].idRightChild = flatnode0.idSelf;


                k = workList[0];
                // create 'left' leaf node
                let flatnode1 = new BVH_FlatNode();
                flatnode1.idSelf = buildnodes.length;
                flatnode1.idLeftChild = -k - 1;
                flatnode1.idRightChild = -1;
                flatnode1.idParent = flatnode0.idSelf;
                flatnode1.minCorner.set(aabb_array[9 * k + 0], aabb_array[9 * k + 1], aabb_array[9 * k + 2]);
                flatnode1.maxCorner.set(aabb_array[9 * k + 3], aabb_array[9 * k + 4], aabb_array[9 * k + 5]);
                buildnodes.push(flatnode1);
                //console.log(flatnode1);

                k = workList[1];
                // create 'right' leaf node
                let flatnode2 = new BVH_FlatNode();
                flatnode2.idSelf = buildnodes.length;
                flatnode2.idLeftChild = -k - 1;
                flatnode2.idRightChild = -1;
                flatnode2.idParent = flatnode0.idSelf;
                flatnode2.minCorner.set(aabb_array[9 * k + 0], aabb_array[9 * k + 1], aabb_array[9 * k + 2]);
                flatnode2.maxCorner.set(aabb_array[9 * k + 3], aabb_array[9 * k + 4], aabb_array[9 * k + 5]);
                buildnodes.push(flatnode2);
                //console.log(flatnode2);

                return;
        } // end else if (workList.length == 2)

        else if (workList.length > 2)
        {

                centroidAverage.set(0, 0, 0);

                // construct bounding box around all of the current workList's triangle AABBs
                for (let i = 0; i < workList.length; i++)
                {
                        k = workList[i];
                        testMinCorner.set(aabb_array[9 * k + 0], aabb_array[9 * k + 1], aabb_array[9 * k + 2]);
                        testMaxCorner.set(aabb_array[9 * k + 3], aabb_array[9 * k + 4], aabb_array[9 * k + 5]);
                        currentCentroid.set(aabb_array[9 * k + 6], aabb_array[9 * k + 7], aabb_array[9 * k + 8]);
                        currentMinCorner.min(testMinCorner);
                        currentMaxCorner.max(testMaxCorner);
                        centroidAverage.add(currentCentroid);
                }

                centroidAverage.divideScalar(workList.length);

                // create inner node
                let flatnode = new BVH_FlatNode();
                flatnode.idSelf = buildnodes.length;
                flatnode.idLeftChild = buildnodes.length + 1; // traverse down the left branches first
                flatnode.idRightChild = 0; // missing link will be filled in soon, don't know how deep the left branches will go
                flatnode.idParent = idParent;
                flatnode.minCorner.copy(currentMinCorner);
                flatnode.maxCorner.copy(currentMaxCorner);
                buildnodes.push(flatnode);
                //console.log(flatnode);

                // if this is a right branch, fill in parent's missing link to this right child, 
                // now that we have assigned this right child an ID
                if (!isLeftBranch)
                        buildnodes[idParent].idRightChild = flatnode.idSelf;


                side1 = currentMaxCorner.x - currentMinCorner.x; // length bbox along X-axis
                side2 = currentMaxCorner.y - currentMinCorner.y; // length bbox along Y-axis
                side3 = currentMaxCorner.z - currentMinCorner.z; // length bbox along Z-axis

                minCost = workList.length * (side1 * side2 + side2 * side3 + side3 * side1);

                // reset bestSplit and bestAxis
                bestSplit = null;
                bestAxis = null;

                // Try all 3 axises X, Y, Z
                for (let j = 0; j < 3; j++)
                { // 0 = X, 1 = Y, 2 = Z axis

                        axis = j;

                        // we will try dividing the triangle AABBs based on the current axis

                        // Create left and right bounding box
                        LBottomCorner.set(Infinity, Infinity, Infinity);
                        LTopCorner.set(-Infinity, -Infinity, -Infinity);
                        RBottomCorner.set(Infinity, Infinity, Infinity);
                        RTopCorner.set(-Infinity, -Infinity, -Infinity);

                        // The number of triangle AABBs in the left and right bboxes (needed to calculate SAH cost function)
                        countLeft = 0;
                        countRight = 0;

                        // allocate triangle AABBs in remaining workList list based on their bbox centers
                        // this is a fast O(N) pass, no triangle AABB sorting needed (yet)
                        for (let i = 0; i < workList.length; i++)
                        {

                                k = workList[i];
                                testMinCorner.set(aabb_array[9 * k + 0], aabb_array[9 * k + 1], aabb_array[9 * k + 2]);
                                testMaxCorner.set(aabb_array[9 * k + 3], aabb_array[9 * k + 4], aabb_array[9 * k + 5]);
                                testCentroid.set(aabb_array[9 * k + 6], aabb_array[9 * k + 7], aabb_array[9 * k + 8]);

                                // get bbox center
                                if (axis == 0)
                                { // X-axis
                                        value = testCentroid.x;
                                        testSplit = centroidAverage.x;
                                }
                                else if (axis == 1)
                                { // Y-axis
                                        value = testCentroid.y;
                                        testSplit = centroidAverage.y;
                                }
                                else
                                { // Z-axis
                                        value = testCentroid.z;
                                        testSplit = centroidAverage.z;
                                }

                                if (value < testSplit)
                                {
                                        // if center is smaller then testSplit value, put triangle box in Left bbox
                                        LBottomCorner.min(testMinCorner);
                                        LTopCorner.max(testMaxCorner);
                                        countLeft++;
                                } else
                                {
                                        // else put triangle box in Right bbox
                                        RBottomCorner.min(testMinCorner);
                                        RTopCorner.max(testMaxCorner);
                                        countRight++;
                                }
                        }

                        // First, check for bad partitionings, ie bins with 0 triangle AABBs make no sense
                        if (countLeft < 1 || countRight < 1) continue;

                        // Now use the Surface Area Heuristic to see if this split has a better "cost"

                        // It's a real partitioning, calculate the sides of Left and Right BBox
                        lside1 = LTopCorner.x - LBottomCorner.x;
                        lside2 = LTopCorner.y - LBottomCorner.y;
                        lside3 = LTopCorner.z - LBottomCorner.z;

                        rside1 = RTopCorner.x - RBottomCorner.x;
                        rside2 = RTopCorner.y - RBottomCorner.y;
                        rside3 = RTopCorner.z - RBottomCorner.z;

                        // calculate SurfaceArea of Left and Right BBox
                        surfaceLeft = (lside1 * lside2) + (lside2 * lside3) + (lside3 * lside1);
                        surfaceRight = (rside1 * rside2) + (rside2 * rside3) + (rside3 * rside1);

                        // calculate total cost by multiplying left and right bbox by number of triangle AABBs in each
                        totalCost = (surfaceLeft * countLeft) + (surfaceRight * countRight);

                        // keep track of cheapest split found so far
                        if (totalCost < minCost)
                        {
                                minCost = totalCost;
                                bestSplit = testSplit;
                                bestAxis = axis;
                        }


                } // end for (let j = 0; j < 3; j++)

                // if no bestSplit was found (bestSplit still equals null), manually populate left/right lists later
                if (bestSplit == null)
                {
                        nullCodePathReached = true;
                        //console.log("bestSplit==null code path reached");
                        //console.log("workList length: " + workList.length);
                }

        } // end else if (workList.length > 2)


        leftWorkCounter = 0;
        rightWorkCounter = 0;

        // manually populate the current leftWorkLists and rightWorklists
        if (nullCodePathReached)
        {

                nullCodePathReached = false;
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

                return; // bail out
        }

        // the following code can only be reached if (workList.length > 2) and bestSplit has been successfully set: 
        // other branches will 'return;' earlier

        // distribute the triangle AABBs in the left or right child nodes
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

} // end function BVH_Create_Node(workList, aabb_array, idParent, isLeftBranch)



function BVH_Build_Iterative(workList, aabb_array)
{

        currentList = workList;

        //console.log("building root with " + currentList.length + " triangle AABBs");
        //console.log(currentList);

        // reset BVH builder arrays;
        buildnodes = [];
        leftWorkLists = [];
        rightWorkLists = [];
        parentList = [];

        stackptr = 0;
        nullCodePathReached = false;

        parentList.push(buildnodes.length - 1);

        // parent id of -1, meaning this is the root node, which has no parent
        BVH_Create_Node(currentList, aabb_array, -1, true); // build root node

        // build the tree using the "go down left branches until done, then ascend back up right branches" approach
        while (stackptr > -1)
        {

                // pop the next node off the stack
                currentList = leftWorkLists[stackptr];
                leftWorkLists[stackptr] = null;

                if (currentList != undefined)
                {

                        //console.log("building left with " + currentList.length + " triangle AABBs");
                        //console.log(currentList);

                        stackptr++;
                        //console.log("stackptr: " + stackptr);

                        parentList.push(buildnodes.length - 1);

                        // build the left node
                        BVH_Create_Node(currentList, aabb_array, buildnodes.length - 1, true);

                        leftBranchCounter++;
                }
                else
                {
                        currentList = rightWorkLists[stackptr];
                        if (currentList != undefined)
                        {
                                //console.log("building right with " + currentList.length + " triangle AABBs");
                                //console.log(currentList);

                                stackptr++;
                                //console.log("stackptr: " + stackptr);

                                // build the right node
                                BVH_Create_Node(currentList, aabb_array, parentList.pop(), false);
                                rightWorkLists[stackptr - 1] = null;

                                rightBranchCounter++;
                        }
                        else
                        {
                                stackptr--;
                                //console.log("stackptr: " + stackptr);
                        }
                }

        } // end while (stackptr > -1)


} // end function BVH_Build_Iterative(workList, aabb_array)
