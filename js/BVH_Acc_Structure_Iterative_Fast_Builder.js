/* BVH (Bounding Volume Hierarchy) Iterative Fast Builder */
/*
Inspired by: Thanassis Tsiodras (ttsiodras on GitHub)
https://github.com/ttsiodras/renderer-cuda/blob/master/src/BVH.cpp
Edited and Ported from C++ to Javascript by: Erich Loftis (erichlof on GitHub)
https://github.com/erichlof/THREE.js-PathTracing-Renderer
*/


let stackptr = 0;
let workListLength = 0;
let buildnodes = [];
let leftWorkLists = [];
let rightWorkLists = [];
let parentList = [];
let currentList;
let k, value, side0, side1, side2;
let bestSplit, goodSplit, okaySplit;
let bestAxis, goodAxis, okayAxis;
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


function BVH_FlatNode()
{

        this.idSelf = 0;
        this.idObject = -1; // negative id means that this is another inner node
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
        { // should never happen, but just in case...
                return;
        }
        else if (workList.length == 1)
        {
                // if we're down to 1 primitive aabb, quickly create a leaf node and return.
                k = workList[0];
                // create leaf node
                let flatLeafNode = new BVH_FlatNode();
                flatLeafNode.idSelf = buildnodes.length;
                flatLeafNode.idObject = k;
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

        else if (workList.length > 1)
        {
                // this is where the real work happens: we must sort an arbitrary number of primitive aabb's.
                // to get a balanced tree, we hope for about half to be placed in left child, half to be placed in right child.
                centroidAverage.set(0, 0, 0);

                workListLength = workList.length;
                // construct bounding box around all of the current workList's triangle AABBs
                for (let i = 0; i < workListLength; i++)
                {
                        k = workList[i];
                        testMinCorner.set(aabb_array[9 * k + 0], aabb_array[9 * k + 1], aabb_array[9 * k + 2]);
                        testMaxCorner.set(aabb_array[9 * k + 3], aabb_array[9 * k + 4], aabb_array[9 * k + 5]);
                        currentCentroid.set(aabb_array[9 * k + 6], aabb_array[9 * k + 7], aabb_array[9 * k + 8]);
                        currentMinCorner.min(testMinCorner);
                        currentMaxCorner.max(testMaxCorner);
                }

                // calculate the middle point of the current box (aka 'spatial median')
                spatialAverage.copy(currentMinCorner);
                spatialAverage.add(currentMaxCorner);
                spatialAverage.multiplyScalar(0.5);

                // this simply uses the spatial average of the longest box extent to determine the split plane, 
                // which is very fast and results in a fair-to-good quality, balanced binary tree structure
                centroidAverage.copy(spatialAverage);


                // create inner node
                let flatnode = new BVH_FlatNode();
                flatnode.idSelf = buildnodes.length;
                flatnode.idObject = -1; // negative id means that this is another inner node
                flatnode.idRightChild = 0; // missing link will be filled in soon, don't know how deep the left branches will go
                flatnode.idParent = idParent;
                flatnode.minCorner.copy(currentMinCorner);
                flatnode.maxCorner.copy(currentMaxCorner);
                buildnodes.push(flatnode);

                // if this is a right branch, fill in parent's missing link to this right child, 
                // now that we have assigned this right child an ID
                if (!isLeftBranch)
                        buildnodes[idParent].idRightChild = flatnode.idSelf;


                side0 = currentMaxCorner.x - currentMinCorner.x; // length bbox along X-axis
                side1 = currentMaxCorner.y - currentMinCorner.y; // length bbox along Y-axis
                side2 = currentMaxCorner.z - currentMinCorner.z; // length bbox along Z-axis

                // initialize variables
                bestAxis = 0; goodAxis = 1; okayAxis = 2;
                bestSplit = centroidAverage.x; goodSplit = centroidAverage.y; okaySplit = centroidAverage.z;

                // determine the longest extent of the box, and start with that as splitting dimension
                if (side0 >= side1 && side0 >= side2)
                {
                        bestAxis = 0;
                        bestSplit = centroidAverage.x;
                        if (side1 >= side2)
                        {
                                goodAxis = 1;
                                goodSplit = centroidAverage.y;
                                okayAxis = 2;
                                okaySplit = centroidAverage.z;
                        }
                        else
                        {
                                goodAxis = 2;
                                goodSplit = centroidAverage.z;
                                okayAxis = 1;
                                okaySplit = centroidAverage.y;
                        }
                }
                else if (side1 > side0 && side1 >= side2)
                {
                        bestAxis = 1;
                        bestSplit = centroidAverage.y;
                        if (side0 >= side2)
                        {
                                goodAxis = 0;
                                goodSplit = centroidAverage.x;
                                okayAxis = 2;
                                okaySplit = centroidAverage.z;
                        }
                        else
                        {
                                goodAxis = 2;
                                goodSplit = centroidAverage.z;
                                okayAxis = 0;
                                okaySplit = centroidAverage.x;
                        }
                }
                else if (side2 > side0 && side2 > side1)
                {
                        bestAxis = 2;
                        bestSplit = centroidAverage.z;
                        if (side0 >= side1)
                        {
                                goodAxis = 0;
                                goodSplit = centroidAverage.x;
                                okayAxis = 1;
                                okaySplit = centroidAverage.y;
                        }
                        else
                        {
                                goodAxis = 1;
                                goodSplit = centroidAverage.y;
                                okayAxis = 0;
                                okaySplit = centroidAverage.x;
                        }
                }

                // try best axis first, then try the other two if necessary
                for (let j = 0; j < 3; j++)
                {
                        // distribute the triangle AABBs in the left or right child nodes
                        // reset counters for the loop coming up
                        leftWorkCounter = 0;
                        rightWorkCounter = 0;

                        workListLength = workList.length;
                        // this loop is to count how many elements we need for the left branch and the right branch
                        for (let i = 0; i < workListLength; i++)
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

                        if (leftWorkCounter > 0 && rightWorkCounter > 0)
                        {
                                break; // success, move on to the next part
                        }
                        else if (leftWorkCounter == 0 || rightWorkCounter == 0)
                        {
                                // try another axis
                                if (j == 0)
                                {
                                        bestAxis = goodAxis;
                                        bestSplit = goodSplit;
                                }
                                else if (j == 1)
                                {
                                        bestAxis = okayAxis;
                                        bestSplit = okaySplit;
                                }

                                continue;
                        }

                } // end for (let j = 0; j < 3; j++)


                // if the below if statement is true, then we have successfully sorted the triangle aabb's
                if (leftWorkCounter > 0 && rightWorkCounter > 0)
                {
                        // now that the size of each branch is known, we can initialize the left and right arrays
                        leftWorkLists[stackptr] = new Uint32Array(leftWorkCounter);
                        rightWorkLists[stackptr] = new Uint32Array(rightWorkCounter);

                        // reset counters for the loop coming up
                        leftWorkCounter = 0;
                        rightWorkCounter = 0;

                        workListLength = workList.length;
                        // populate the current leftWorkLists and rightWorklists
                        for (let i = 0; i < workListLength; i++)
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

                workListLength = workList.length;
                // this loop is to count how many elements we need for the left branch and the right branch
                for (let i = 0; i < workListLength; i++)
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

                workListLength = workList.length;
                for (let i = 0; i < workListLength; i++)
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

        } // end else if (workList.length > 1)

} // end function BVH_Create_Node(workList, aabb_array, idParent, isLeftBranch)



function BVH_Build_Iterative(workList, aabb_array)
{

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
        while (stackptr > -1)
        {

                // pop the next node off of the left-side stack
                currentList = leftWorkLists[stackptr];

                if (currentList != undefined)
                { // left side of tree

                        leftWorkLists[stackptr] = null; // mark as processed
                        stackptr++;

                        parentList.push(buildnodes.length - 1);

                        // build the left node
                        BVH_Create_Node(currentList, aabb_array, buildnodes.length - 1, true);
                }
                else
                { // right side of tree
                        // pop the next node off of the right-side stack
                        currentList = rightWorkLists[stackptr];

                        if (currentList != undefined)
                        {

                                rightWorkLists[stackptr] = null; // mark as processed
                                stackptr++;

                                // build the right node
                                BVH_Create_Node(currentList, aabb_array, parentList.pop(), false);
                        }
                        else
                        {
                                stackptr--;
                        }
                }

        } // end while (stackptr > -1)

        //console.log(buildnodes);

        buildnodesLength = buildnodes.length;
        // Copy the buildnodes array into the aabb_array
        for (let n = 0; n < buildnodesLength; n++)
        {

                // slot 0
                aabb_array[8 * n + 0] = buildnodes[n].idObject;   // r or x component
                aabb_array[8 * n + 1] = buildnodes[n].minCorner.x;  // g or y component
                aabb_array[8 * n + 2] = buildnodes[n].minCorner.y;  // b or z component
                aabb_array[8 * n + 3] = buildnodes[n].minCorner.z;  // a or w component

                // slot 1
                aabb_array[8 * n + 4] = buildnodes[n].idRightChild; // r or x component
                aabb_array[8 * n + 5] = buildnodes[n].maxCorner.x;  // g or y component
                aabb_array[8 * n + 6] = buildnodes[n].maxCorner.y;  // b or z component
                aabb_array[8 * n + 7] = buildnodes[n].maxCorner.z;  // a or w component

        }


} // end function BVH_Build_Iterative(workList, aabb_array)
