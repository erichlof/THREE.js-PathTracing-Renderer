// BVH_Quick_Builder
// The core concepts of this BVH builder come from the fantastic online article series, "How To Build a BVH",
// by Jacco Bikker.  In particular, the "binning" techniques and other optimizations come from the 3rd article in
// this series - part 3, Quick Builds:   https://jacco.ompf2.com/2022/04/21/how-to-build-a-bvh-part-3-quick-builds/ 

// Jacco's original C++ source code can be found here: https://github.com/jbikker/bvh_article/blob/main/quickbuild.cpp 
// Ported to Javascript and modified for use with the Three.js PathTracing Renderer by Erich Loftis (erichlof on GitHub)

let bvhNode = [];
let bin = [];
let N_BINS = 16;// the higher the number of BINS, the better quality of resulting tree, but also increases build time
let aabb_array_copy = null;
let triIdx = null;
let leftArea = null;
let rightArea = null;
let leftCountSum = null;
let rightCountSum = null;
let N = 0;
let rootNodeIdx = 0;
let nodesUsed = 2;// the 2 offsets the left-right child pairs to even starting address boundaries (2-3, 4-5, 6-7, etc) 
let first = 0;
let k = 0; 
let kx9 = 0;
let axis = 'x'; 
let axisNum = 0;
let longestAxis = 'x';
let longestAxisNum = 0;
let tmp = 0;
let splitPos = 0;
let leftCount = 0;
let leftPrimCount = 0;
let rightPrimCount = 0;
let leftBoxArea = 0;
let rightBoxArea = 0;
let bestAxis = 0;
let bestSplitPos = 0;
let bestCost = 0;
let planeCost = 0;
let boundsMin = 0;
let boundsMax = 0;
let scale = 0;
let binIdx = 0;
let centroid = 0;
let leftSum = 0;
let rightSum = 0;
let leftBoxMin = new THREE.Vector3();
let leftBoxMax = new THREE.Vector3();
let rightBoxMin = new THREE.Vector3();
let rightBoxMax = new THREE.Vector3();
let extent = new THREE.Vector3();
let testMinCorner = new THREE.Vector3();
let testMaxCorner = new THREE.Vector3();


// these constructor functions work the same as a 'struct' in C/C++
function BVH_Node()
{
	this.minCorner = new THREE.Vector3();
	this.maxCorner = new THREE.Vector3();
	this.triCount = 0;
	this.leftFirst = 0;
}

function Bin()
{
	this.minBounds = new THREE.Vector3();
	this.maxBounds = new THREE.Vector3();
	this.triCount = 0;
}


function UpdateNodeBounds(nodeIdx)
{
	let node = bvhNode[nodeIdx];
	node.minCorner.set(Infinity, Infinity, Infinity);
	node.maxCorner.set(-Infinity, -Infinity, -Infinity);
	
	first = node.leftFirst;
	for (let i = 0; i < node.triCount; i++)
	{
		k = triIdx[first + i];
		kx9 = 9 * k;
		testMinCorner.set(aabb_array_copy[kx9 + 0], aabb_array_copy[kx9 + 1], aabb_array_copy[kx9 + 2]);
		testMaxCorner.set(aabb_array_copy[kx9 + 3], aabb_array_copy[kx9 + 4], aabb_array_copy[kx9 + 5]);
		node.minCorner.min(testMinCorner);
		node.maxCorner.max(testMaxCorner);
	}
}


function Subdivide(nodeIdx)
{
	
	let node = bvhNode[nodeIdx];
	// terminate recursion
	if (node.triCount < 2) 
	{
		node.leftFirst = triIdx[node.leftFirst];
		return;
	}

	// determine split axis using SAH and Binning
	bestCost = Infinity;
	bestAxis = 0;
	bestSplitPos = Infinity;
	first = node.leftFirst;

	for (let ax = 0; ax < 3; ax++)
	{
		boundsMin = Infinity; boundsMax = -Infinity;
		for (let i = 0; i < node.triCount; i++)
		{
			k = triIdx[first + i];
			centroid = aabb_array_copy[9 * k + 6 + ax];
			boundsMin = Math.min( boundsMin, centroid );
			boundsMax = Math.max( boundsMax, centroid );
		}
		if (boundsMin == boundsMax) continue;
		// re-initialize the bins
		for (let i = 0; i < N_BINS; i++)
		{
			bin[i].minBounds.set(Infinity, Infinity, Infinity);
			bin[i].maxBounds.set(-Infinity, -Infinity, -Infinity);
			bin[i].triCount = 0;
		}
		scale = N_BINS / (boundsMax - boundsMin);
		// populate the bins
		for (let i = 0; i < node.triCount; i++)
		{
			k = triIdx[first + i];
			kx9 = 9 * k;
			testMinCorner.set(aabb_array_copy[kx9 + 0], aabb_array_copy[kx9 + 1], aabb_array_copy[kx9 + 2]);
			testMaxCorner.set(aabb_array_copy[kx9 + 3], aabb_array_copy[kx9 + 4], aabb_array_copy[kx9 + 5]);
			centroid = aabb_array_copy[kx9 + 6 + ax];
			binIdx = Math.floor( Math.min(N_BINS - 1, (centroid - boundsMin) * scale) );
			bin[binIdx].triCount++;
			bin[binIdx].minBounds.min(testMinCorner);
			bin[binIdx].maxBounds.max(testMaxCorner);
		}
		// re-initialize variables
		leftSum = rightSum = 0;
		leftBoxMin.set(Infinity, Infinity, Infinity);
		leftBoxMax.set(-Infinity, -Infinity, -Infinity);
		rightBoxMin.set(Infinity, Infinity, Infinity);
		rightBoxMax.set(-Infinity, -Infinity, -Infinity);
		// gather data for the 7 planes between the 8 bins
		for (let i = 0; i < N_BINS - 1; i++)
		{
			leftSum += bin[i].triCount;
			leftCountSum[i] = leftSum;
			leftBoxMin.min( bin[i].minBounds );
			leftBoxMax.max( bin[i].maxBounds );
			extent.subVectors(leftBoxMax, leftBoxMin);
			leftArea[i] = (extent.x * extent.y) + (extent.y * extent.z) + (extent.z * extent.x);
			
			rightSum += bin[N_BINS - 1 - i].triCount;
			rightCountSum[N_BINS - 2 - i] = rightSum;
			rightBoxMin.min( bin[N_BINS - 1 - i].minBounds );
			rightBoxMax.max( bin[N_BINS - 1 - i].maxBounds );
			extent.subVectors(rightBoxMax, rightBoxMin);
			rightArea[N_BINS - 2 - i] = (extent.x * extent.y) + (extent.y * extent.z) + (extent.z * extent.x);
		}
		// calculate SAH cost for the 7 planes
		scale = (boundsMax - boundsMin) / N_BINS;
		for (let i = 0; i < N_BINS - 1; i++)
		{
			planeCost = (leftCountSum[i] * leftArea[i]) + (rightCountSum[i] * rightArea[i]);
			if (planeCost < bestCost)
			{
				bestCost = planeCost;
				bestAxis = ax;
				bestSplitPos = boundsMin + (scale * (i + 1));
			}		
		}
	} // end for (let ax = 0; ax < 3; ax++)
		
	axisNum = bestAxis;
	splitPos = bestSplitPos;
	extent.subVectors(node.maxCorner, node.minCorner); // extent of parent
	parentArea = (extent.x * extent.y) + (extent.y * extent.z) + (extent.z * extent.x);
	parentCost = node.triCount * parentArea;
	if (bestCost >= parentCost) 
		splitPos = Infinity;
	// in-place partition
	let i = node.leftFirst;
	let j = i + node.triCount - 1;
	while (i <= j)
	{
		if (aabb_array_copy[9 * triIdx[i] + 6 + axisNum] < splitPos)
			i++;
		else
		{
			tmp = triIdx[i];
			triIdx[i] = triIdx[j];
			triIdx[j] = tmp;
			j--;
		}		
	}
	
	leftCount = i - node.leftFirst;


	// BACKUP partitioning algo - Spatial Median Split

	if (leftCount == 0 || leftCount == node.triCount)
	{// if partition failed, try splitting by spatial median on the longest axis
		//console.log("trying spatial median split on longest axis, triCount: " + node.triCount);
		// determine split axis and position
		extent.subVectors(node.maxCorner, node.minCorner);
		axis = 'x'; 
		axisNum = 0;
		if (extent.y > extent.x) 
		{
			axis = 'y';
			axisNum = 1;
		}
		if (extent.z > extent[axis])
		{
			axis = 'z';
			axisNum = 2;
		}
		longestAxis = axis;
		longestAxisNum = axisNum;

		splitPos = node.minCorner[axis] + (extent[axis] * 0.5);
		// in-place partition
		i = node.leftFirst;
		j = i + node.triCount - 1;
		while (i <= j)
		{
			if (aabb_array_copy[9 * triIdx[i] + 6 + axisNum] < splitPos)
				i++;
			else
			{
				tmp = triIdx[i];
				triIdx[i] = triIdx[j];
				triIdx[j] = tmp;
				j--;
			}		
		}
		
		leftCount = i - node.leftFirst;
	}

	
	// FINAL BACKUP partitioning algo - Object Median Split
	
	if (leftCount == 0 || leftCount == node.triCount) 
	{ // if partition failed, try splitting by object median on longest axis (1st axis)
		//console.log("trying object median split on longest axis, triCount: " + node.triCount);

		axisNum = longestAxisNum;

		splitPos = 0;
		first = node.leftFirst;
		for (let n = 0; n < node.triCount; n++)
		{
			k = triIdx[first + n];
			splitPos += aabb_array_copy[9 * k + 6 + axisNum];
		}
		splitPos *= (1 / node.triCount);
		
		// in-place partition
		i = node.leftFirst;
		j = i + node.triCount - 1;
		while (i <= j)
		{
			if (aabb_array_copy[9 * triIdx[i] + 6 + axisNum] < splitPos)
				i++;
			else
			{
				tmp = triIdx[i];
				triIdx[i] = triIdx[j];
				triIdx[j] = tmp;
				j--;
			}		
		}

		leftCount = i - node.leftFirst;
	}

	if (leftCount == 0 || leftCount == node.triCount) 
	{ // if partition failed again, try splitting by object median along next axis (2nd axis)
		//console.log("trying object median split 2nd axis, triCount: " + node.triCount);
		if (axis == 'x') 
		{
			axis = 'y';
			axisNum = 1;
		}
		else if (axis == 'y')
		{
			axis = 'z';
			axisNum = 2;
		}
		else if (axis == 'z') 
		{
			axis = 'x';
			axisNum = 0;
		}

		splitPos = 0;
		first = node.leftFirst;
		for (let n = 0; n < node.triCount; n++)
		{
			k = triIdx[first + n];
			splitPos += aabb_array_copy[9 * k + 6 + axisNum];
		}
		splitPos *= (1 / node.triCount);
		
		// in-place partition
		i = node.leftFirst;
		j = i + node.triCount - 1;
		while (i <= j)
		{
			if (aabb_array_copy[9 * triIdx[i] + 6 + axisNum] < splitPos)
				i++;
			else
			{
				tmp = triIdx[i];
				triIdx[i] = triIdx[j];
				triIdx[j] = tmp;
				j--;
			}		
		}

		leftCount = i - node.leftFirst;
	}

	if (leftCount == 0 || leftCount == node.triCount) 
	{ // if partition failed again, try splitting by object median along 3rd axis (final axis)
		//console.log("trying object median split 3rd axis, triCount: " + node.triCount);
		if (axis == 'x') 
		{
			axis = 'y';
			axisNum = 1;
		}
		else if (axis == 'y')
		{
			axis = 'z';
			axisNum = 2;
		}
		else if (axis == 'z') 
		{
			axis = 'x';
			axisNum = 0;
		}

		splitPos = 0;
		first = node.leftFirst;
		for (let n = 0; n < node.triCount; n++)
		{
			k = triIdx[first + n];
			splitPos += aabb_array_copy[9 * k + 6 + axisNum];
		}
		splitPos *= (1 / node.triCount);
		
		// in-place partition
		i = node.leftFirst;
		j = i + node.triCount - 1;
		while (i <= j)
		{
			if (aabb_array_copy[9 * triIdx[i] + 6 + axisNum] < splitPos)
				i++;
			else
			{
				tmp = triIdx[i];
				triIdx[i] = triIdx[j];
				triIdx[j] = tmp;
				j--;
			}		
		}

		leftCount = i - node.leftFirst;
	}

	// check if one of the sides is still empty
	if (leftCount == 0 || leftCount == node.triCount) 
	{ // if partition still failed after all attempts, bail out and return
		console.log("partition failed, triCount: " + node.triCount);
		return;
	}

	// create child nodes
	let leftChildIdx = nodesUsed++;
	let rightChildIdx = nodesUsed++;
	bvhNode[leftChildIdx].leftFirst = node.leftFirst;
	bvhNode[leftChildIdx].triCount = leftCount;
	bvhNode[rightChildIdx].leftFirst = i;
	bvhNode[rightChildIdx].triCount = node.triCount - leftCount;
	node.leftFirst = leftChildIdx;
	node.triCount = 0;
	UpdateNodeBounds( leftChildIdx );
	UpdateNodeBounds( rightChildIdx );
	// recurse
	Subdivide( leftChildIdx );
	Subdivide( rightChildIdx );

} // end function Subdivide( nodeIdx )



function BVH_QuickBuild(primitiveAABB_IndexList, aabb_array, isTopLevel)
{
	// the 'primitiveAABB_IndexList' is a raw list of integer numbers in simple sequential order [0,1,2,3,4,5,6,..N-1](one for every primitive), 
	// where each number refers to a unique triangle (or other type of primitive) from the model's unordered 'triangle soup'.
	N = primitiveAABB_IndexList.length;
	triIdx = new Uint32Array(primitiveAABB_IndexList);
	// now that we have a copy of the index list (called triIdx), this triIdx list will be sorted in place as the bvhNodes building procedes

	// the user of this builder has to supply the aabb_array. Then we make a copy of the aabb_array,
	// so that this builder can use it, while referring to it with a generic variable name (like 'aabb_array_copy').
	// This allows users to build multiple different BVHs for all scene models, while using the same BVH_QuickBuild() function
	aabb_array_copy = new Float32Array(aabb_array);

	leftArea = new Float32Array(N_BINS - 1); 
	rightArea = new Float32Array(N_BINS - 1);
	leftCountSum = new Uint32Array(N_BINS - 1);
	rightCountSum = new Uint32Array(N_BINS - 1);

	nodesUsed = 2; // this must be reset in case BVH_QuickBuild() gets called multiple times during the same application

	bin = [];
	for (let i = 0; i < N_BINS; i++)
		bin[i] = new Bin();

	bvhNode = [];
	for (let i = 0; i < N * 2; i++)
		bvhNode[i] = new BVH_Node();

	// we don't want this output if the built BVH is a Top-Level BVH (which often gets rebuilt 60+ times a second!) 
	if (!isTopLevel)
	{
		console.time("BVH build time");
		console.log("Building BVH...");
	}
	
	// now build root node (rootNodeIdx = 0), and then recursively build the rest of the binary tree
	// assign all triangles to root node
	let root = bvhNode[rootNodeIdx];
	root.leftFirst = 0;
	root.triCount = N;
	UpdateNodeBounds( rootNodeIdx );
	// subdivide recursively
	Subdivide( rootNodeIdx );


	let ix8 = 0;
	// copy the bvhNode array into the aabb_array
	for (let i = 0; i < bvhNode.length; i++)
	{
		ix8 = 8 * i;
		// rgba texel 0
		aabb_array[ix8 + 0] = bvhNode[i].minCorner.x; // r or x component
		aabb_array[ix8 + 1] = bvhNode[i].minCorner.y; // g or y component
		aabb_array[ix8 + 2] = bvhNode[i].minCorner.z; // b or z component
		aabb_array[ix8 + 3] = bvhNode[i].maxCorner.x; // a or w component

		// rgba texel 1
		aabb_array[ix8 + 4] = bvhNode[i].maxCorner.y; // r or x component
		aabb_array[ix8 + 5] = bvhNode[i].maxCorner.z; // g or y component
		aabb_array[ix8 + 6] = bvhNode[i].triCount;    // b or z component
		aabb_array[ix8 + 7] = bvhNode[i].leftFirst;   // a or w component
	}

	if (!isTopLevel)
		console.timeEnd("BVH build time");

} // end function BVH_QuickBuild(primitiveAABB_IndexList, aabb_array)
