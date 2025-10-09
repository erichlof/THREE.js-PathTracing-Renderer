let buildnodes = [];
let leftWorklist = [];
let rightWorklist = [];
let nodesUsed = 1;
let aabb_array_copy;
let k, value, side0, side1, side2;
let bestSplit, goodSplit, okaySplit;
let bestAxis, goodAxis, okayAxis;
let currentMinCorner = new THREE.Vector3();
let currentMaxCorner = new THREE.Vector3();
let testMinCorner = new THREE.Vector3();
let testMaxCorner = new THREE.Vector3();
let testCentroid = new THREE.Vector3();
let spatialAverage = new THREE.Vector3();


function BVH_Node()
{
	this.minCorner = new THREE.Vector3();
	this.maxCorner = new THREE.Vector3();
	this.primitiveCount = 0;
	this.leafOrChild_ID = 0;
}


function BVH_Create_Node(worklist, nodeIndex)
{
	// re-initialize bounding box extents 
	currentMinCorner.set(Infinity, Infinity, Infinity);
	currentMaxCorner.set(-Infinity, -Infinity, -Infinity);

	if (worklist.length == 1)
	{
		// if we're down to 1 primitive aabb, quickly create a leaf node and return.
		k = worklist[0];
		// create leaf node
		let leafNode = buildnodes[nodeIndex];
		leafNode.minCorner.set(aabb_array_copy[9 * k + 0], aabb_array_copy[9 * k + 1], aabb_array_copy[9 * k + 2]);
		leafNode.maxCorner.set(aabb_array_copy[9 * k + 3], aabb_array_copy[9 * k + 4], aabb_array_copy[9 * k + 5]);
		leafNode.primitiveCount = 1;
		leafNode.leafOrChild_ID = k;
		return;
	} // end if (worklist.length == 1)

	else if (worklist.length > 1)
	{
		// this is where the real work happens: we must sort an arbitrary number of primitives (usually triangles).
		// to get a balanced tree, we hope for about half to be placed in left child, other half to be placed in right child.

		// construct/grow bounding box around all of the current worklist's primitives
		for (let i = 0; i < worklist.length; i++)
		{
			k = worklist[i];
			testMinCorner.set(aabb_array_copy[9 * k + 0], aabb_array_copy[9 * k + 1], aabb_array_copy[9 * k + 2]);
			testMaxCorner.set(aabb_array_copy[9 * k + 3], aabb_array_copy[9 * k + 4], aabb_array_copy[9 * k + 5]);
			currentMinCorner.min(testMinCorner);
			currentMaxCorner.max(testMaxCorner);
		}

		// create an inner node to represent this newly grown bounding box
		let innerNode = buildnodes[nodeIndex];
		// this inner node will spawn 2 children: a leftChild and a rightChild
		nodesUsed++; // 'nodesUsed' now matches the index of the leftChild (the 1st child to be created)
		innerNode.minCorner.copy(currentMinCorner);
		innerNode.maxCorner.copy(currentMaxCorner);
		innerNode.primitiveCount = 0;//worklist.length;
		innerNode.leafOrChild_ID = nodesUsed; // 'innerNode.leafOrChild_ID' now also points to the index of the leftChild
		// we must now incrememnt the nodesUsed counter, because a 2nd child (the rightChild) will also be created
		nodesUsed++; // 'nodesUsed' now matches the index of the rightChild (the 2nd child to be created) 

		let leftChildIndex = innerNode.leafOrChild_ID;
		let rightChildIndex = innerNode.leafOrChild_ID + 1; // the rightChild's index is always the leftChild's index + 1
		
		// Begin Spatial Median split plane determination and primitive sorting

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
		else // if (side2 >= side0 && side2 >= side1)
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
			leftWorklist = [];
			rightWorklist = [];

			// this loop is to count how many elements we will need for the left branch and the right branch
			for (let i = 0; i < worklist.length; i++)
			{
				k = worklist[i];
				testCentroid.set(aabb_array_copy[9 * k + 6], aabb_array_copy[9 * k + 7], aabb_array_copy[9 * k + 8]);

				// get bbox center
				if (bestAxis == 0) value = testCentroid.x; // X-axis
				else if (bestAxis == 1) value = testCentroid.y; // Y-axis
				else value = testCentroid.z; // Z-axis

				if (value < bestSplit)
					leftWorklist.push(k);
				else
					rightWorklist.push(k);
				
			}

			if (leftWorklist.length > 0 && rightWorklist.length > 0)
			{
				break; // success, move on to the next part
			}
			else// if (leftWorklist.length == 0 || rightWorklist.length == 0)
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
			}

		} // end for (let axis = 0; axis < 3; axis++)


		// if the below if statement is true, then we have successfully sorted the primitive(triangle) AABBs
		if (leftWorklist.length > 0 && rightWorklist.length > 0)
		{
			let leftWorklistCopy = new Uint32Array(leftWorklist);
			let rightWorklistCopy = new Uint32Array(rightWorklist);
			// recurse
			BVH_Create_Node(leftWorklistCopy, leftChildIndex);
			BVH_Create_Node(rightWorklistCopy, rightChildIndex);
		}

		else //if (leftWorklist.length == 0 || rightWorklist.length == 0)
		{
			// if we reached this point, the builder failed to find a decent splitting plane axis, so
			// we try another strategy to populate the current leftWorkLists and rightWorklists.
			leftWorklist = [];
			rightWorklist = [];
			
			spatialAverage.set(0, 0, 0);

			// this loop is to count how many elements we will need for the left branch and the right branch
			for (let i = 0; i < worklist.length; i++)
			{
				k = worklist[i];
				testCentroid.set(aabb_array_copy[9 * k + 6], aabb_array_copy[9 * k + 7], aabb_array_copy[9 * k + 8]);
				spatialAverage.add(testCentroid);
			}
			spatialAverage.multiplyScalar(1 / worklist.length);

			for (let i = 0; i < worklist.length; i++)
			{
				k = worklist[i];
				testCentroid.set(aabb_array_copy[9 * k + 6], aabb_array_copy[9 * k + 7], aabb_array_copy[9 * k + 8]);

				if (testCentroid.x != spatialAverage.x)
				{
					if (testCentroid.x < spatialAverage.x)
						leftWorklist.push(k);
					else
						rightWorklist.push(k);
				}
				else if (testCentroid.y != spatialAverage.y)
				{
					if (testCentroid.y < spatialAverage.y)
						leftWorklist.push(k);
					else
						rightWorklist.push(k);
				}
				else if (testCentroid.z != spatialAverage.z)
				{
					if (testCentroid.z < spatialAverage.z)
						leftWorklist.push(k);
					else
						rightWorklist.push(k);
				}
			}
			
			let leftWorklistCopy = new Uint32Array(leftWorklist);
			let rightWorklistCopy = new Uint32Array(rightWorklist);
			// recurse
			BVH_Create_Node(leftWorklistCopy, leftChildIndex);
			BVH_Create_Node(rightWorklistCopy, rightChildIndex);

		} // end else //if (leftWorklist.length == 0 || rightWorklist.length == 0)

		if (leftWorklist.length == 0 || rightWorklist.length == 0)
		{
			//console.log("entered fail case, worklist item count: " + worklist.length);
			// if we reached this point, the builder failed to find a decent splitting plane axis, so
			// manually populate the current leftWorkLists and rightWorklists.
			leftWorklist = [];
			rightWorklist = [];
			
			for (let i = 0; i < worklist.length; i++)
			{
				k = worklist[i];
				if (i % 2 != 0)
					leftWorklist.push(k);
				else
					rightWorklist.push(k);
			}

			let leftWorklistCopy = new Uint32Array(leftWorklist);
			let rightWorklistCopy = new Uint32Array(rightWorklist);
			// recurse
			BVH_Create_Node(leftWorklistCopy, leftChildIndex);
			BVH_Create_Node(rightWorklistCopy, rightChildIndex);
		} // end if (leftWorklist.length == 0 || rightWorklist.length == 0)

	} // end if (worklist.length > 1)


	return; // finished

} // end function BVH_Create_Node(worklist, nodeIndex)



function BVH_QuickBuild(primitiveAABB_IndexList, aabb_array)
{
	// the user of this builder has to supply the aabb_array. Then we make a copy of the aabb_array,
	// so that this builder can use it, while referring to it with a generic variable name (like 'aabb_array_copy').
	// This allows users to build multiple different BVHs for all scene models, while using the same BVH_QuickBuild() function
	aabb_array_copy = new Float32Array(aabb_array);

	// the 'primitiveAABB_IndexList' is a raw list of integer numbers in simple sequential order [0,1,2,3,4,5,6,..N-1](one for every primitive), 
	// where each number refers to a unique triangle (or other type of primitive) from the model's unordered 'triangle soup'(or 'primitive soup').

	// now build root node (root nodeIndex = 0), and then recursively build the rest of the binary tree
	BVH_Create_Node(primitiveAABB_IndexList, 0);

	let nx8 = 0;
	// Copy the buildnodes array into the aabb_array
	for (let n = 0; n < buildnodes.length; n++)
	{
		nx8 = n * 8;
		// slot 0
		aabb_array[nx8 + 0] = buildnodes[n].minCorner.x;  // r or x component
		aabb_array[nx8 + 1] = buildnodes[n].minCorner.y;  // g or y component
		aabb_array[nx8 + 2] = buildnodes[n].minCorner.z;  // b or z component
		aabb_array[nx8 + 3] = buildnodes[n].maxCorner.x;  // a or w component

		// slot 1
		aabb_array[nx8 + 4] = buildnodes[n].maxCorner.y; // r or x component
		aabb_array[nx8 + 5] = buildnodes[n].maxCorner.z;  // g or y component
		aabb_array[nx8 + 6] = buildnodes[n].primitiveCount;  // b or z component
		aabb_array[nx8 + 7] = buildnodes[n].leafOrChild_ID;  // a or w component
	}

} // end function BVH_QuickBuild(primitiveAABB_IndexList, aabb_array)