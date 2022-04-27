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
let currentList, aabb_array_copy;
let bestSplit = null;
let bestAxis = null;
let leftWorkCount = 0;
let rightWorkCount = 0;
let bestSplitHasBeenFound = false;
let currentMinCorner = new THREE.Vector3();
let currentMaxCorner = new THREE.Vector3();
let testMinCorner = new THREE.Vector3();
let testMaxCorner = new THREE.Vector3();
let testCentroid = new THREE.Vector3();
let currentCentroid = new THREE.Vector3();
let minCentroid = new THREE.Vector3();
let maxCentroid = new THREE.Vector3();
let centroidAverage = new THREE.Vector3();
let spatialAverage = new THREE.Vector3();
let LBottomCorner = new THREE.Vector3();
let LTopCorner = new THREE.Vector3();
let RBottomCorner = new THREE.Vector3();
let RTopCorner = new THREE.Vector3();
let k, value, side0, side1, side2, minCost, testSplit, testStep;
let countLeft, countRight;
let currentAxis, longestAxis, mediumAxis, shortestAxis;
let lside0, lside1, lside2, rside0, rside1, rside2;
let surfaceLeft, surfaceRight, totalCost;
let numBins = 4; // must be 2 or higher for the BVH to work properly



function BVH_FlatNode()
{
	this.idSelf = 0;
	this.idPrimitive = -1; // a negative primitive id means that this is another inner node
	this.idRightChild = 0;
	this.idParent = 0;
	this.minCorner = new THREE.Vector3();
	this.maxCorner = new THREE.Vector3();
}


function BVH_Create_Node(workList, idParent, isRightBranch)
{
	// reset flag
	bestSplitHasBeenFound = false;

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
		flatLeafNode.idPrimitive = k; // id of primitive (usually a triangle) that is stored inside this AABB leaf node
		flatLeafNode.idRightChild = -1; // leaf nodes do not have children
		flatLeafNode.idParent = idParent;
		flatLeafNode.minCorner.set(aabb_array_copy[9 * k + 0], aabb_array_copy[9 * k + 1], aabb_array_copy[9 * k + 2]);
		flatLeafNode.maxCorner.set(aabb_array_copy[9 * k + 3], aabb_array_copy[9 * k + 4], aabb_array_copy[9 * k + 5]);
		buildnodes.push(flatLeafNode);

		// if this is a right branch, fill in parent's missing link to this right child, 
		// now that we have assigned this right child an ID
		if (isRightBranch)
			buildnodes[idParent].idRightChild = flatLeafNode.idSelf;

		return;
	} // end else if (workList.length == 1)

	else if (workList.length == 2)
	{
		// if we're down to 2 primitive AABBs, quickly create 1 interior node (that holds both), and 2 leaf nodes, then return.
		
		// construct bounding box around the current workList's triangle AABBs
		for (let i = 0; i < 2; i++)
		{
			k = workList[i];
			testMinCorner.set(aabb_array_copy[9 * k + 0], aabb_array_copy[9 * k + 1], aabb_array_copy[9 * k + 2]);
			testMaxCorner.set(aabb_array_copy[9 * k + 3], aabb_array_copy[9 * k + 4], aabb_array_copy[9 * k + 5]);
			currentMinCorner.min(testMinCorner);
			currentMaxCorner.max(testMaxCorner);
		}

		// create inner node
		let flatnode0 = new BVH_FlatNode();
		flatnode0.idSelf = buildnodes.length;
		flatnode0.idPrimitive = -1; // a negative primitive id means that this is just another inner node (with pointers to children)
		flatnode0.idRightChild = buildnodes.length + 2;
		flatnode0.idParent = idParent;
		flatnode0.minCorner.copy(currentMinCorner);
		flatnode0.maxCorner.copy(currentMaxCorner);
		buildnodes.push(flatnode0);

		// if this is a right branch, fill in parent's missing link to this right child, 
		// now that we have assigned this right child an ID
		if (isRightBranch)
			buildnodes[idParent].idRightChild = flatnode0.idSelf;


		// create 'left' leaf node
		k = workList[0];
		let flatnode1 = new BVH_FlatNode();
		flatnode1.idSelf = buildnodes.length;
		flatnode1.idPrimitive = k; // id of primitive (usually a triangle) that is stored inside this AABB leaf node
		flatnode1.idRightChild = -1; // leaf nodes do not have children
		flatnode1.idParent = flatnode0.idSelf;
		flatnode1.minCorner.set(aabb_array_copy[9 * k + 0], aabb_array_copy[9 * k + 1], aabb_array_copy[9 * k + 2]);
		flatnode1.maxCorner.set(aabb_array_copy[9 * k + 3], aabb_array_copy[9 * k + 4], aabb_array_copy[9 * k + 5]);
		buildnodes.push(flatnode1);

		// create 'right' leaf node
		k = workList[1];
		let flatnode2 = new BVH_FlatNode();
		flatnode2.idSelf = buildnodes.length;
		flatnode2.idPrimitive = k; // id of primitive (usually a triangle) that is stored inside this AABB leaf node
		flatnode2.idRightChild = -1; // leaf nodes do not have children
		flatnode2.idParent = flatnode0.idSelf;
		flatnode2.minCorner.set(aabb_array_copy[9 * k + 0], aabb_array_copy[9 * k + 1], aabb_array_copy[9 * k + 2]);
		flatnode2.maxCorner.set(aabb_array_copy[9 * k + 3], aabb_array_copy[9 * k + 4], aabb_array_copy[9 * k + 5]);
		buildnodes.push(flatnode2);

		return;

	} // end else if (workList.length == 2)

	else if (workList.length > 2)
	{
		// this is where the real work happens: we must sort an arbitrary number of primitive (usually triangles) AABBs.
		// to get a balanced tree, we hope for about half to be placed in left child, half to be placed in right child.
		
		// re-initialize min/max centroids
		minCentroid.set(Infinity, Infinity, Infinity);
		maxCentroid.set(-Infinity, -Infinity, -Infinity);
		centroidAverage.set(0, 0, 0);

		// construct/grow bounding box around all of the current workList's primitive(triangle) AABBs
		// also, calculate the average position of all the aabb's centroids
		for (let i = 0; i < workList.length; i++)
		{
			k = workList[i];

			testMinCorner.set(aabb_array_copy[9 * k + 0], aabb_array_copy[9 * k + 1], aabb_array_copy[9 * k + 2]);
			testMaxCorner.set(aabb_array_copy[9 * k + 3], aabb_array_copy[9 * k + 4], aabb_array_copy[9 * k + 5]);
			currentCentroid.set(aabb_array_copy[9 * k + 6], aabb_array_copy[9 * k + 7], aabb_array_copy[9 * k + 8]);
			
			currentMinCorner.min(testMinCorner);
			currentMaxCorner.max(testMaxCorner);

			minCentroid.min(currentCentroid);
			maxCentroid.max(currentCentroid);

			centroidAverage.add(currentCentroid); // sum up all aabb centroid positions
		}
		// divide the aabb centroid sum by the number of centroids to get average
		centroidAverage.divideScalar(workList.length);

		// calculate the middle point of this newly-grown bounding box (aka the 'spatial median')
		//spatialAverage.copy(currentMinCorner).add(currentMaxCorner).multiplyScalar(0.5);

		// create inner node
		let flatnode = new BVH_FlatNode();
		flatnode.idSelf = buildnodes.length; // its own id matches the number of nodes we've created so far
		flatnode.idPrimitive = -1; // a negative primitive id means that this is just another inner node (with pointers to children)
		flatnode.idRightChild = 0; // missing RightChild link will be filled in soon; don't know how deep the left branches will go while constructing top-to-bottom
		flatnode.idParent = idParent;
		flatnode.minCorner.copy(currentMinCorner);
		flatnode.maxCorner.copy(currentMaxCorner);
		buildnodes.push(flatnode);

		// if this is a right branch, fill in parent's missing link to this right child, 
		// now that we have assigned this right child an ID
		if (isRightBranch)
			buildnodes[idParent].idRightChild = flatnode.idSelf;


		// Begin split plane determination using the Surface Area Heuristic(SAH) strategy

		side0 = currentMaxCorner.x - currentMinCorner.x; // length along X-axis
		side1 = currentMaxCorner.y - currentMinCorner.y; // length along Y-axis
		side2 = currentMaxCorner.z - currentMinCorner.z; // length along Z-axis

		minCost = workList.length * ((side0 * side1) + (side1 * side2) + (side2 * side0));

		// reset bestSplit and bestAxis
		bestSplit = null;
		bestAxis = null;

		// Try all 3 axes X, Y, Z
		for (let axis = 0; axis < 3; axis++)
		{ // 0 = X, 1 = Y, 2 = Z axis
			// we will try dividing the triangle AABBs based on the current axis

			if (axis == 0)
			{
				testSplit = currentMinCorner.x;
				testStep = side0 / numBins;
				//testSplit = minCentroid.x;
				//testStep = (maxCentroid.x - minCentroid.x) / numBins;
			}
			else if (axis == 1)
			{
				testSplit = currentMinCorner.y;
				testStep = side1 / numBins;
				//testSplit = minCentroid.y;
				//testStep = (maxCentroid.y - minCentroid.y) / numBins;
			}
			else // if (axis == 2)
			{
				testSplit = currentMinCorner.z;
				testStep = side2 / numBins;
				//testSplit = minCentroid.z;
				//testStep = (maxCentroid.z - minCentroid.z) / numBins;
			}

			for (let partition = 1; partition < numBins; partition++)
			{
				testSplit += testStep;

				// Create potential left and right bounding boxes
				LBottomCorner.set(Infinity, Infinity, Infinity);
				LTopCorner.set(-Infinity, -Infinity, -Infinity);
				RBottomCorner.set(Infinity, Infinity, Infinity);
				RTopCorner.set(-Infinity, -Infinity, -Infinity);

				// The number of triangle AABBs in the left and right bboxes (needed to calculate SAH cost function)
				countLeft = 0;
				countRight = 0;

				// allocate triangle AABBs in workList based on their bbox centers
				// this is a fast O(N) pass, no triangle AABB sorting needed (yet)
				for (let i = 0; i < workList.length; i++)
				{
					k = workList[i];
					testMinCorner.set(aabb_array_copy[9 * k + 0], aabb_array_copy[9 * k + 1], aabb_array_copy[9 * k + 2]);
					testMaxCorner.set(aabb_array_copy[9 * k + 3], aabb_array_copy[9 * k + 4], aabb_array_copy[9 * k + 5]);
					testCentroid.set(aabb_array_copy[9 * k + 6], aabb_array_copy[9 * k + 7], aabb_array_copy[9 * k + 8]);

					// get bbox center
					if (axis == 0)
					{ // X-axis
						value = testCentroid.x;
					}
					else if (axis == 1)
					{ // Y-axis
						value = testCentroid.y;
					}
					else
					{ // Z-axis
						value = testCentroid.z;
					}

					if (value < testSplit)
					{
						// if centroid is smaller then testSplit, put triangle box in Left bbox
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
				} // end for (let i = 0; i < workList.length; i++)

				// First, check for bad partitionings, i.e. bins with 0 triangle AABBs make no sense
				if (countLeft < 1 || countRight < 1) 
					continue;

				// Now use the Surface Area Heuristic to see if this split has a better "cost"

				// It's a real partitioning, calculate the sides of Left and Right BBox
				lside0 = LTopCorner.x - LBottomCorner.x;
				lside1 = LTopCorner.y - LBottomCorner.y;
				lside2 = LTopCorner.z - LBottomCorner.z;

				rside0 = RTopCorner.x - RBottomCorner.x;
				rside1 = RTopCorner.y - RBottomCorner.y;
				rside2 = RTopCorner.z - RBottomCorner.z;

				// calculate SurfaceArea of Left and Right BBox
				surfaceLeft = (lside0 * lside1) + (lside1 * lside2) + (lside2 * lside0);
				surfaceRight = (rside0 * rside1) + (rside1 * rside2) + (rside2 * rside0);

				// calculate total cost by multiplying left and right bbox by number of triangle AABBs in each
				totalCost = (surfaceLeft * countLeft) + (surfaceRight * countRight);

				// keep track of cheapest split found so far
				if (totalCost < minCost)
				{
					minCost = totalCost;
					bestSplit = testSplit;
					bestAxis = axis;
					bestSplitHasBeenFound = true;
				}
			} // end for (let partition = 1; partition < numBins; partition++)

		} // end for (let axis = 0; axis < 3; axis++)

	} // end else if (workList.length > 2)


	// If the SAH strategy failed, now try to populate the current leftWorkLists and rightWorklists with the Object Median strategy
	if ( !bestSplitHasBeenFound )
	{
		//console.log("bestSplit not found, now trying Object Median strategy...");
		//console.log("num of AABBs remaining: " + workList.length);

		// determine the longest extent of the box, and start with that as splitting dimension
		if (side0 >= side1 && side0 >= side2)
		{
			longestAxis = 0;
			if (side1 >= side2)
			{
				mediumAxis = 1; shortestAxis = 2;
			}
			else
			{
				mediumAxis = 2; shortestAxis = 1;
			}
		}
		else if (side1 >= side0 && side1 >= side2)
		{
			longestAxis = 1;
			if (side0 >= side2)
			{
				mediumAxis = 0; shortestAxis = 2;
			}
			else
			{
				mediumAxis = 2;	shortestAxis = 0;	
			}
		}
		else// if (side2 >= side0 && side2 >= side1)
		{
			longestAxis = 2;
			if (side0 >= side1)
			{
				mediumAxis = 0;	shortestAxis = 1;	
			}
			else
			{
				mediumAxis = 1;	shortestAxis = 0;	
			}
		}

		// try longest axis first, then try the other two if necessary
		currentAxis = longestAxis; // a split along the longest axis would be optimal, so try this first
		// reset counters for the loop coming up
		leftWorkCount = 0;
		rightWorkCount = 0;

		// this loop is to count how many elements we will need for the left branch and the right branch
		for (let i = 0; i < workList.length; i++)
		{
			k = workList[i];
			testCentroid.set(aabb_array_copy[9 * k + 6], aabb_array_copy[9 * k + 7], aabb_array_copy[9 * k + 8]);

			// get bbox center
			if (currentAxis == 0) 
			{
				value = testCentroid.x; // X-axis
				testSplit = centroidAverage.x;
				//testSplit = spatialAverage.x;
			}
			else if (currentAxis == 1) 
			{
				value = testCentroid.y; // Y-axis
				testSplit = centroidAverage.y;
				//testSplit = spatialAverage.y;
			}
			else 
			{
				value = testCentroid.z; // Z-axis
				testSplit = centroidAverage.z;
				//testSplit = spatialAverage.z;
			}

			if (value < testSplit)
			{
				leftWorkCount++;
			} else
			{
				rightWorkCount++;
			}
		}

		if (leftWorkCount > 0 && rightWorkCount > 0)
		{
			bestSplit = testSplit;
			bestAxis = currentAxis;
			bestSplitHasBeenFound = true;
		}

		if ( !bestSplitHasBeenFound ) // if longest axis failed
		{
			currentAxis = mediumAxis; // try middle-length axis next
			// reset counters for the loop coming up
			leftWorkCount = 0;
			rightWorkCount = 0;

			// this loop is to count how many elements we will need for the left branch and the right branch
			for (let i = 0; i < workList.length; i++)
			{
				k = workList[i];
				testCentroid.set(aabb_array_copy[9 * k + 6], aabb_array_copy[9 * k + 7], aabb_array_copy[9 * k + 8]);

				// get bbox center
				if (currentAxis == 0) 
				{
					value = testCentroid.x; // X-axis
					testSplit = centroidAverage.x;
					//testSplit = spatialAverage.x;
				}
				else if (currentAxis == 1) 
				{
					value = testCentroid.y; // Y-axis
					testSplit = centroidAverage.y;
					//testSplit = spatialAverage.y;
				}
				else 
				{
					value = testCentroid.z; // Z-axis
					testSplit = centroidAverage.z;
					//testSplit = spatialAverage.z;
				}

				if (value < testSplit)
				{
					leftWorkCount++;
				} else
				{
					rightWorkCount++;
				}
			}

			if (leftWorkCount > 0 && rightWorkCount > 0)
			{
				bestSplit = testSplit;
				bestAxis = currentAxis;
				bestSplitHasBeenFound = true;
			}
		} // end if ( !bestSplitHasBeenFound ) // if longest axis failed

		if ( !bestSplitHasBeenFound ) // if middle-length axis failed
		{
			currentAxis = shortestAxis; // try shortest axis last
			// reset counters for the loop coming up
			leftWorkCount = 0;
			rightWorkCount = 0;

			// this loop is to count how many elements we will need for the left branch and the right branch
			for (let i = 0; i < workList.length; i++)
			{
				k = workList[i];
				testCentroid.set(aabb_array_copy[9 * k + 6], aabb_array_copy[9 * k + 7], aabb_array_copy[9 * k + 8]);

				// get bbox center
				if (currentAxis == 0) 
				{
					value = testCentroid.x; // X-axis
					testSplit = centroidAverage.x;
					//testSplit = spatialAverage.x;
				}
				else if (currentAxis == 1) 
				{
					value = testCentroid.y; // Y-axis
					testSplit = centroidAverage.y;
					//testSplit = spatialAverage.y;
				}
				else 
				{
					value = testCentroid.z; // Z-axis
					testSplit = centroidAverage.z;
					//testSplit = spatialAverage.z;
				}

				if (value < testSplit)
				{
					leftWorkCount++;
				} else
				{
					rightWorkCount++;
				}
			}

			if (leftWorkCount > 0 && rightWorkCount > 0)
			{
				bestSplit = testSplit;
				bestAxis = currentAxis;
				bestSplitHasBeenFound = true;
			}
		} // end if ( !bestSplitHasBeenFound ) // if middle-length axis failed
		
	} // end if ( !bestSplitHasBeenFound ) // If the SAH strategy failed


	leftWorkCount = 0;
	rightWorkCount = 0;

	// if all strategies have failed, we must manually populate the current leftWorkLists and rightWorklists
	if ( !bestSplitHasBeenFound )
	{
		//console.log("bestSplit still not found, resorting to manual placement...");
		//console.log("num of AABBs remaining: " + workList.length);
		
		// this loop is to count how many elements we need for the left branch and the right branch
		for (let i = 0; i < workList.length; i++)
		{
			if (i % 2 == 0)
			{
				leftWorkCount++;
			} else
			{
				rightWorkCount++;
			}
		}

		// now that the size of each branch is known, we can initialize the left and right arrays
		leftWorkLists[stackptr] = new Uint32Array(leftWorkCount);
		rightWorkLists[stackptr] = new Uint32Array(rightWorkCount);

		// reset counters for the loop coming up
		leftWorkCount = 0;
		rightWorkCount = 0;

		for (let i = 0; i < workList.length; i++)
		{
			k = workList[i];

			if (i % 2 == 0)
			{
				leftWorkLists[stackptr][leftWorkCount] = k;
				leftWorkCount++;
			} else
			{
				rightWorkLists[stackptr][rightWorkCount] = k;
				rightWorkCount++;
			}
		}

		return; // return early
	} // end if ( !bestSplitHasBeenFound )


	// the following code can only be reached if (workList.length > 2) and bestSplit has been successfully found. 
	// Other unsuccessful conditions will have been handled and will 'return' earlier

	// distribute the triangle AABBs in the left or right child nodes
	leftWorkCount = 0;
	rightWorkCount = 0;

	// this loop is to count how many elements we need for the left branch and the right branch
	for (let i = 0; i < workList.length; i++)
	{
		k = workList[i];
		testCentroid.set(aabb_array_copy[9 * k + 6], aabb_array_copy[9 * k + 7], aabb_array_copy[9 * k + 8]);

		// get bbox center
		if (bestAxis == 0) value = testCentroid.x; // X-axis
		else if (bestAxis == 1) value = testCentroid.y; // Y-axis
		else value = testCentroid.z; // Z-axis

		if (value < bestSplit)
		{
			leftWorkCount++;
		} else
		{
			rightWorkCount++;
		}
	}

	// now that the size of each branch is known, we can initialize the left and right arrays
	leftWorkLists[stackptr] = new Uint32Array(leftWorkCount);
	rightWorkLists[stackptr] = new Uint32Array(rightWorkCount);

	// reset counters for the loop coming up
	leftWorkCount = 0;
	rightWorkCount = 0;

	// populate the current leftWorkLists and rightWorklists
	for (let i = 0; i < workList.length; i++)
	{
		k = workList[i];
		testCentroid.set(aabb_array_copy[9 * k + 6], aabb_array_copy[9 * k + 7], aabb_array_copy[9 * k + 8]);

		// get bbox center
		if (bestAxis == 0) value = testCentroid.x; // X-axis
		else if (bestAxis == 1) value = testCentroid.y; // Y-axis
		else value = testCentroid.z; // Z-axis

		if (value < bestSplit)
		{
			leftWorkLists[stackptr][leftWorkCount] = k;
			leftWorkCount++;
		} else
		{
			rightWorkLists[stackptr][rightWorkCount] = k;
			rightWorkCount++;
		}
	}

} // end function BVH_Create_Node(workList, idParent, isRightBranch)




function BVH_Build_Iterative(workList, aabb_array)
{

	currentList = workList;
	// save a global copy of the supplied aabb_array, so that it can be used by the various functions in this file
	aabb_array_copy = new Float32Array(aabb_array);

	// reset BVH builder arrays;
	buildnodes = [];
	leftWorkLists = [];
	rightWorkLists = [];
	parentList = [];

	// initialize variables
	stackptr = 0;

	// parent id of -1, meaning this is the root node, which has no parent
	parentList.push(-1);
	BVH_Create_Node(currentList, -1, false); // build root node

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
			BVH_Create_Node(currentList, buildnodes.length - 1, false);
		}
		else
		{
			currentList = rightWorkLists[stackptr];

			if (currentList != undefined)
			{
				rightWorkLists[stackptr] = null; // mark as processed
				stackptr++;

				// build the right node
				BVH_Create_Node(currentList, parentList.pop(), true);
			}
			else
			{
				stackptr--;
			}
		}

	} // end while (stackptr > -1)


	// Copy the buildnodes array into the aabb_array
	for (let n = 0; n < buildnodes.length; n++)
	{
		// slot 0
		aabb_array[8 * n + 0] = buildnodes[n].idPrimitive;  // r or x component
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
