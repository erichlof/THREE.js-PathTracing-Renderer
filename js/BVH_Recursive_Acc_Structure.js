/* BVH (Bounding Volume Hierarchy) Recursive Builder */
/*
Inspired by: Thanassis Tsiodras (ttsiodras on GitHub)
https://github.com/ttsiodras/renderer-cuda/blob/master/src/BVH.cpp

Edited and Ported from C++ to Javascript by: Erich Loftis (erichlof on GitHub)
https://github.com/erichlof/THREE.js-PathTracing-Renderer
*/

var nNodes = 0;
var nLeaves = 0;
var buildnodes = [];
var rightBranchCounter = 0;
var leftBranchCounter = 0;
var currentMinCorner = new THREE.Vector3();
var currentMaxCorner = new THREE.Vector3();
var testMinCorner = new THREE.Vector3();
var testMaxCorner = new THREE.Vector3();
var testCentroid = new THREE.Vector3();
var LBottomCorner = new THREE.Vector3();
var LTopCorner = new THREE.Vector3();
var RBottomCorner = new THREE.Vector3();
var RTopCorner = new THREE.Vector3();

function BVH_FlatNode() {

        this.isLeaf = 0;
        this.idSelf = 0;
        this.idLeftChild = 0;
        this.idRightChild = 0;
        this.idParent = 0;
        this.idTriangle = 0;
        this.minCorner = new THREE.Vector3();
        this.maxCorner = new THREE.Vector3();
}


function BVH_Build_Recursive(workList, idParent, isLeftBranch) {

        
        let k;
        let bestSplit;
        let bestAxis;
        let idSelf = 0; // needed for id on recursive build calls 

        // reset variables
        currentMinCorner.set(Infinity, Infinity, Infinity);
        currentMaxCorner.set(-Infinity, -Infinity, -Infinity);
        
        if (workList.length < 1) {
                return;
        }
        else if (workList.length == 1) {
                k = workList[0];
                // create leaf node and stop recursion
                let flatnode = new BVH_FlatNode();
                flatnode.isLeaf = 1.0;
                flatnode.idSelf = buildnodes.length;
                flatnode.idLeftChild = -1;
                flatnode.idRightChild = -1;
                flatnode.idParent = idParent;
                flatnode.idTriangle = k;
                flatnode.minCorner.set(aabb_array[9 * k + 0], aabb_array[9 * k + 1], aabb_array[9 * k + 2]);
                flatnode.maxCorner.set(aabb_array[9 * k + 3], aabb_array[9 * k + 4], aabb_array[9 * k + 5]);
                buildnodes.push(flatnode);
                //console.log(flatnode);
                
                // if this is a right branch, fill in parent's missing link to this right child, 
                // now that we have assigned this right child an ID
                if (!isLeftBranch && idParent > -1) 
                        buildnodes[idParent].idRightChild = flatnode.idSelf;

                nLeaves++;

                return;
        }
        else if (workList.length == 2) {

                // construct bounding box around the current workList's triangle AABBs
                for (let i = 0; i < workList.length; i++) {
                        k = workList[i];
                        testMinCorner.set(aabb_array[9 * k + 0], aabb_array[9 * k + 1], aabb_array[9 * k + 2]);
                        testMaxCorner.set(aabb_array[9 * k + 3], aabb_array[9 * k + 4], aabb_array[9 * k + 5]);
                        currentMinCorner.min(testMinCorner);
                        currentMaxCorner.max(testMaxCorner);
                }

                // create inner node
                let flatnode0 = new BVH_FlatNode();
                flatnode0.isLeaf = 0.0;
                flatnode0.idSelf = buildnodes.length;
                flatnode0.idLeftChild = buildnodes.length + 1;
                flatnode0.idRightChild = buildnodes.length + 2;
                flatnode0.idParent = idParent;
                flatnode0.idTriangle = -1;
                flatnode0.minCorner.copy(currentMinCorner);
                flatnode0.maxCorner.copy(currentMaxCorner);
                buildnodes.push(flatnode0);
                //console.log(flatnode0);

                // if this is a right branch, fill in parent's missing link to this right child, 
                // now that we have assigned this right child an ID
                if (!isLeftBranch && idParent > -1) 
                        buildnodes[idParent].idRightChild = flatnode0.idSelf;
                
                nNodes++;
                
                k = workList[0];
                // create 'left' leaf node
                let flatnode1 = new BVH_FlatNode();
                flatnode1.isLeaf = 1.0;
                flatnode1.idSelf = buildnodes.length;
                flatnode1.idLeftChild = -1;
                flatnode1.idRightChild = -1;
                flatnode1.idParent = flatnode0.idSelf;
                flatnode1.idTriangle = k;
                flatnode1.minCorner.set(aabb_array[9 * k + 0], aabb_array[9 * k + 1], aabb_array[9 * k + 2]);
                flatnode1.maxCorner.set(aabb_array[9 * k + 3], aabb_array[9 * k + 4], aabb_array[9 * k + 5]);
                leftBranchCounter++;
                buildnodes.push(flatnode1);
                //console.log(flatnode1);
                

                nLeaves++;
                
                k = workList[1];
                // create 'right' leaf node and stop recursion
                let flatnode2 = new BVH_FlatNode();
                flatnode2.isLeaf = 1.0;
                flatnode2.idSelf = buildnodes.length;
                flatnode2.idLeftChild = -1;
                flatnode2.idRightChild = -1;
                flatnode2.idParent = flatnode0.idSelf;
                flatnode2.idTriangle = k;
                flatnode2.minCorner.set(aabb_array[9 * k + 0], aabb_array[9 * k + 1], aabb_array[9 * k + 2]);
                flatnode2.maxCorner.set(aabb_array[9 * k + 3], aabb_array[9 * k + 4], aabb_array[9 * k + 5]);
                rightBranchCounter++;
                buildnodes.push(flatnode2);
                //console.log(flatnode2);
                
                nLeaves++;

                return;
        } // end else if (workList.length == 2)

        else if (workList.length > 2) {

                // construct bounding box around the current workList's triangle AABBs
                for (let i = 0; i < workList.length; i++) {
                        k = workList[i];
                        testMinCorner.set(aabb_array[9 * k + 0], aabb_array[9 * k + 1], aabb_array[9 * k + 2]);
                        testMaxCorner.set(aabb_array[9 * k + 3], aabb_array[9 * k + 4], aabb_array[9 * k + 5]);
                        currentMinCorner.min(testMinCorner);
                        currentMaxCorner.max(testMaxCorner);
                }

                // create inner node
                let flatnode = new BVH_FlatNode();
                flatnode.isLeaf = 0.0;
                flatnode.idSelf = buildnodes.length;
                idSelf = buildnodes.length; // need for id on recursive build calls
                flatnode.idLeftChild = buildnodes.length + 1; // traverse down the left branches first
                flatnode.idRightChild = 0; // missing link will be filled in soon, don't know how deep the left branches will go
                flatnode.idParent = idParent;     
                flatnode.idTriangle = -1;
                flatnode.minCorner.copy(currentMinCorner);
                flatnode.maxCorner.copy(currentMaxCorner);
                buildnodes.push(flatnode);
                //console.log(flatnode);

                // if this is a right branch, fill in parent's missing link to this right child, 
                // now that we have assigned this right child an ID
                if (!isLeftBranch && idParent > -1) 
                        buildnodes[idParent].idRightChild = flatnode.idSelf;
                
                nNodes++;

                let side1 = currentMaxCorner.x - currentMinCorner.x; // length bbox along X-axis
                let side2 = currentMaxCorner.y - currentMinCorner.y; // length bbox along Y-axis
                let side3 = currentMaxCorner.z - currentMinCorner.z; // length bbox along Z-axis

                let minCost = workList.length * (side1 * side2 + side2 * side3 + side3 * side1);

                // Try all 3 axises X, Y, Z
                for (let j = 0; j < 3; j++) { // 0 = X, 1 = Y, 2 = Z axis

                        let axis = j;

                        // we will try dividing the triangle AABBs based on the current axis,
                        // and we will try split values from "start" to "stop", one "step" at a time.
                        let start, stop, step;

                        // X-axis
                        if (axis == 0) {
                                start = currentMinCorner.x;
                                stop  = currentMaxCorner.x;
                        }
                        // Y-axis
                        else if (axis == 1) {
                                start = currentMinCorner.y;
                                stop  = currentMaxCorner.y;
                        }
                        // Z-axis
                        else {
                                start = currentMinCorner.z;
                                stop  = currentMaxCorner.z;
                        }

                        // In that axis, do the bounding boxes in the workList queue "span" across, (meaning distributed over a reasonable distance)?
                        // Or are they all already "packed" on the axis? Meaning that they are too close to each other
                        if (Math.abs(stop - start) < 1e-4)
                                // BBox side along this axis too short, we must move to a different axis!
                                continue; // go to next axis

                        // Binning: Try splitting at a uniform sampling (at equidistantly spaced planes) that gets smaller the deeper we go:
                        ///step = (stop - start) / (1024 / (depth + 1));
                        step = (stop - start) / 1024; 
                        // for each bin (equally spaced bins of size "step"):
                        for (let testSplit = start + step; testSplit < (stop - step); testSplit += step) {

                                // Create left and right bounding box
                                LBottomCorner.set(Infinity, Infinity, Infinity);
                                LTopCorner.set(-Infinity, -Infinity, -Infinity);
                                RBottomCorner.set(Infinity, Infinity, Infinity);
                                RTopCorner.set(-Infinity, -Infinity, -Infinity);

                                // The number of triangle AABBs in the left and right bboxes (needed to calculate SAH cost function)
                                let countLeft = 0;
                                let countRight = 0;

                                // For each test split (or bin), allocate triangle AABBs in remaining workList list based on their bbox centers
                                // this is a fast O(N) pass, no triangle AABB sorting needed (yet)
                                for (let i = 0; i < workList.length; i++) {

                                        k = workList[i];
                                        testMinCorner.set(aabb_array[9 * k + 0], aabb_array[9 * k + 1], aabb_array[9 * k + 2]);
                                        testMaxCorner.set(aabb_array[9 * k + 3], aabb_array[9 * k + 4], aabb_array[9 * k + 5]);
                                        testCentroid.set( aabb_array[9 * k + 6], aabb_array[9 * k + 7], aabb_array[9 * k + 8]);

                                        // get bbox center
                                        let value;
                                        if (axis == 0) value = testCentroid.x; // X-axis
                                        else if (axis == 1) value = testCentroid.y; // Y-axis
                                        else value = testCentroid.z; // Z-axis

                                        if (value < testSplit) {
                                                // if center is smaller then testSplit value, put triangle box in Left bbox
                                                LBottomCorner.min(testMinCorner);
                                                LTopCorner.max(testMaxCorner);
                                                countLeft++;
                                        } else {
                                                // else put triangle box in Right bbox
                                                RBottomCorner.min(testMinCorner);
                                                RTopCorner.max(testMaxCorner);
                                                countRight++;
                                        }
                                }

                                // Now use the Surface Area Heuristic to see if this split has a better "cost"

                                // First, check for bad partitionings, ie bins with 0 or 1 triangle AABBs make no sense
                                ///if (countLeft < 1 || countRight < 1) continue;

                                // It's a real partitioning, calculate the sides of Left and Right BBox
                                let lside1 = LTopCorner.x - LBottomCorner.x;
                                let lside2 = LTopCorner.y - LBottomCorner.y;
                                let lside3 = LTopCorner.z - LBottomCorner.z;

                                let rside1 = RTopCorner.x - RBottomCorner.x;
                                let rside2 = RTopCorner.y - RBottomCorner.y;
                                let rside3 = RTopCorner.z - RBottomCorner.z;

                                // calculate SurfaceArea of Left and Right BBox
                                let surfaceLeft =  (lside1 * lside2) + (lside2 * lside3) + (lside3 * lside1);
                                let surfaceRight = (rside1 * rside2) + (rside2 * rside3) + (rside3 * rside1);

                                // calculate total cost by multiplying left and right bbox by number of triangle AABBs in each
                                let totalCost = (surfaceLeft * countLeft) + (surfaceRight * countRight);

                                // keep track of cheapest split found so far
                                if (totalCost < minCost) {
                                        minCost = totalCost;
                                        bestSplit = testSplit;
                                        bestAxis = axis;
                                }

                        } // end of loop over all bins

                } // end of loop over all axises

        } // end else if (workList.length > 2)


        // at the end of this loop (which runs for every "bin" or "sample location"), 
        // we should have the best splitting plane, best splitting axis and bboxes with minimal traversal cost

        // Otherwise, create BVH inner node with L and R child nodes, split with the optimal value we found above
        let leftWorkList = [];
        let rightWorkList = [];
        
        // distribute the triangle AABBs in the left or right child nodes
        // for each triangle AABB in the workList set
        for (let i = 0; i < workList.length; i++) {
                k = workList[i];
                //testMinCorner.set(aabb_array[9 * k + 0], aabb_array[9 * k + 1], aabb_array[9 * k + 2]);
                //testMaxCorner.set(aabb_array[9 * k + 3], aabb_array[9 * k + 4], aabb_array[9 * k + 5]);
                testCentroid.set( aabb_array[9 * k + 6], aabb_array[9 * k + 7], aabb_array[9 * k + 8]);

                // get bbox center
                let value;
                if (bestAxis == 0) value = testCentroid.x; // X-axis
                else if (bestAxis == 1) value = testCentroid.y; // Y-axis
                else value = testCentroid.z; // Z-axis

                if (value < bestSplit) {
                        leftWorkList.push(k);
                } else {
                        rightWorkList.push(k);
                }
        }

        //console.log("building left with " + leftWorkList.length + " triangles");
        leftBranchCounter++;
        // recursively build the left branches
        BVH_Build_Recursive(leftWorkList, idSelf, true);

        //console.log("building right with " + rightWorkList.length + " triangles");
        rightBranchCounter++;
        // recursively build the right branches
        BVH_Build_Recursive(rightWorkList, idSelf, false);

} // end function BVH_Build_Recursive(workList, idParent)