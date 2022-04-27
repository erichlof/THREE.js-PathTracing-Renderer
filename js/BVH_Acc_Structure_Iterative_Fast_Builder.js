/* BVH (Bounding Volume Hierarchy) Iterative Fast Builder */
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
let k, value, side0, side1, side2;
let bestSplit, goodSplit, okaySplit;
let bestAxis, goodAxis, okayAxis;
let leftWorkCount = 0;
let rightWorkCount = 0;
let currentMinCorner = new THREE.Vector3();
let currentMaxCorner = new THREE.Vector3();
let testMinCorner = new THREE.Vector3();
let testMaxCorner = new THREE.Vector3();
let testCentroid = new THREE.Vector3();
let currentCentroid = new THREE.Vector3();
let spatialAverage = new THREE.Vector3();


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

	else if (workList.length > 1)
	{
		// this is where the real work happens: we must sort an arbitrary number of primitive (usually triangles) AABBs.
		// to get a balanced tree, we hope for about half to be placed in left child, half to be placed in right child.

		// construct/grow bounding box around all of the current workList's primitive(triangle) AABBs
		for (let i = 0; i < workList.length; i++)
		{
			k = workList[i];
			testMinCorner.set(aabb_array_copy[9 * k + 0], aabb_array_copy[9 * k + 1], aabb_array_copy[9 * k + 2]);
			testMaxCorner.set(aabb_array_copy[9 * k + 3], aabb_array_copy[9 * k + 4], aabb_array_copy[9 * k + 5]);
			currentMinCorner.min(testMinCorner);
			currentMaxCorner.max(testMaxCorner);
		}

		// create an inner node to represent this newly grown bounding box
		let flatnode = new BVH_FlatNode();
		flatnode.idSelf = buildnodes.length; // its own id matches the number of nodes we've created so far
		flatnode.idPrimitive = -1; // a negative primitive id means that this is just another inner node (with pointers to children), no triangle
		flatnode.idRightChild = 0; // missing RightChild link will be filled in soon; don't know how deep the left branches will go while constructing top-to-bottom
		flatnode.idParent = idParent;
		flatnode.minCorner.copy(currentMinCorner);
		flatnode.maxCorner.copy(currentMaxCorner);
		buildnodes.push(flatnode);

		// if this is a right branch, fill in parent's missing link to this right child, 
		// now that we have assigned this right child an ID
		if (isRightBranch)
			buildnodes[idParent].idRightChild = flatnode.idSelf;


		// Begin Spatial Median split plane determination and primitive AABB sorting

		side0 = currentMaxCorner.x - currentMinCorner.x; // length along X-axis
		side1 = currentMaxCorner.y - currentMinCorner.y; // length along Y-axis
		side2 = currentMaxCorner.z - currentMinCorner.z; // length along Z-axis

		// calculate the middle point of this newly-grown bounding box (aka the 'spatial median')
		// this simply uses the spatial average of the longest box extent to determine the split plane,
		// which is very fast and results in a fair quality, fairly balanced binary tree structure
		spatialAverage.copy(currentMinCorner).add(currentMaxCorner).multiplyScalar(0.5);

		// initialize variables
		bestAxis = 0; goodAxis = 1; okayAxis = 2;
		bestSplit = spatialAverage.x; goodSplit = spatialAverage.y; okaySplit = spatialAverage.z;

		// determine the longest extent of the box, and start with that as splitting dimension
		if (side0 >= side1 && side0 >= side2)
		{
			bestAxis = 0;
			bestSplit = spatialAverage.x;
			if (side1 >= side2)
			{
				goodAxis = 1;
				goodSplit = spatialAverage.y;
				okayAxis = 2;
				okaySplit = spatialAverage.z;
			}
			else
			{
				goodAxis = 2;
				goodSplit = spatialAverage.z;
				okayAxis = 1;
				okaySplit = spatialAverage.y;
			}
		}
		else if (side1 >= side0 && side1 >= side2)
		{
			bestAxis = 1;
			bestSplit = spatialAverage.y;
			if (side0 >= side2)
			{
				goodAxis = 0;
				goodSplit = spatialAverage.x;
				okayAxis = 2;
				okaySplit = spatialAverage.z;
			}
			else
			{
				goodAxis = 2;
				goodSplit = spatialAverage.z;
				okayAxis = 0;
				okaySplit = spatialAverage.x;
			}
		}
		else// if (side2 >= side0 && side2 >= side1)
		{
			bestAxis = 2;
			bestSplit = spatialAverage.z;
			if (side0 >= side1)
			{
				goodAxis = 0;
				goodSplit = spatialAverage.x;
				okayAxis = 1;
				okaySplit = spatialAverage.y;
			}
			else
			{
				goodAxis = 1;
				goodSplit = spatialAverage.y;
				okayAxis = 0;
				okaySplit = spatialAverage.x;
			}
		}

		// try best axis first, then try the other two if necessary
		for (let axis = 0; axis < 3; axis++)
		{
			// distribute the triangle AABBs in either the left child or right child
			// reset counters for the loop coming up
			leftWorkCount = 0;
			rightWorkCount = 0;

			// this loop is to count how many elements we will need for the left branch and the right branch
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

			if (leftWorkCount > 0 && rightWorkCount > 0)
			{
				break; // success, move on to the next part
			}
			else// if (leftWorkCount == 0 || rightWorkCount == 0)
			{
				// try another axis
				if (axis == 0)
				{
					bestAxis = goodAxis;
					bestSplit = goodSplit;
				}
				else if (axis == 1)
				{
					bestAxis = okayAxis;
					bestSplit = okaySplit;
				}

				continue;
			}

		} // end for (let axis = 0; axis < 3; axis++)


		// if the below if statement is true, then we have successfully sorted the primitive(triangle) AABBs
		if (leftWorkCount > 0 && rightWorkCount > 0)
		{
			// now that the size of each branch is known, we can initialize the left and right arrays
			leftWorkLists[stackptr] = new Uint32Array(leftWorkCount);
			rightWorkLists[stackptr] = new Uint32Array(rightWorkCount);

			// reset counters for the loop coming up
			leftWorkCount = 0;
			rightWorkCount = 0;

			// sort the primitives and populate the current leftWorkLists and rightWorklists
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

			return; // success!

		} // end if (leftWorkCount > 0 && rightWorkCount > 0)


		// if we reached this point, the builder failed to find a decent splitting plane axis, so
		// manually populate the current leftWorkLists and rightWorklists.
		// reset counters to 0
		leftWorkCount = 0;
		rightWorkCount = 0;

		// this loop is to count how many elements we will need for the left branch and the right branch
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

	} // end else if (workList.length > 1)

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
		{ // right side of tree
			// pop the next node off of the right-side stack
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
