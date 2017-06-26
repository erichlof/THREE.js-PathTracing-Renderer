/* BVH (Bounding Volume Hierarchy) Builder */
/*
Original author: Brandon Pelfrey (brandonpelfrey@gmail.com) (brandonpelfrey on GitHub)
https://github.com/brandonpelfrey/Fast-BVH

Edited and Ported from C++ to Javascript by: Erich Loftis (erichlof on GitHub)
https://github.com/erichlof/THREE.js-PathTracing-Renderer
*/
var nNodes = 0;
var nLeafs = 0;
var leafSize = 4;
var flatTree = [];

function BBox(_min, _max) {
	
	this.minCorner = new THREE.Vector3(Infinity,Infinity,Infinity);
	if (_min) this.minCorner.copy(_min);
	this.maxCorner = new THREE.Vector3(-Infinity,-Infinity,-Infinity);
	if (_max) this.maxCorner.copy(_max);
	
	this.extentVec = new THREE.Vector3();

	this.expandToIncludePoint = function(p) {
		this.minCorner.min(p);
		this.maxCorner.max(p);
		this.extentVec.subVectors(this.maxCorner, this.minCorner);
	};

	this.expandToIncludeBox = function(b) {
		this.minCorner.min(b.minCorner);
		this.maxCorner.max(b.maxCorner);
		this.extentVec.subVectors(this.maxCorner, this.minCorner);
	};

	this.maxDimension = function() {
		var result = 0;
		if (this.extentVec.y > this.extentVec.x) {
			result = 1;
			if (this.extentVec.z > this.extentVec.y) 
				result = 2;
		} 
		else if (this.extentVec.z > this.extentVec.x) result = 2;

		return result;
	}

	this.surfaceArea = function() {
		return 2 * ( this.extentVec.x * this.extentVec.z +
			     this.extentVec.x * this.extentVec.y + 
			     this.extentVec.y * this.extentVec.z );
	}

} // end function BBox(_min, _max) {

function BVH_BuildEntry() {
	// If non-zero then this is the index of the parent. (used in offsets)
	this.parent = 0;
	// The range of objects in the object list covered by this node.
	this.start = 0;
	this.end = 0;
}

function BVH_FlatNode() {
	this.rightOffset = 0;
	this.nPrims = 0;
	this.start = 0;
	this.bbox = new BBox();
}

/*! Build the BVH, given an input data set
 *  - Handling our own stack is quite a bit faster than the recursive style.
 *  - Each build stack entry's parent field eventually stores the offset
 *    to the parent of that node. Before that is finally computed, it will
 *    equal exactly three other values. (These are the magic values Untouched,
 *    Untouched-1, and TouchedTwice).
 *  - The partition here was also slightly faster than std::partition.
 */	
function BVH_Build() {
	
	var todo = [];
	var buildnodes = [];
	var stackptr = 0;
	var Untouched = 0xffffffff;
	var TouchedTwice = 0xfffffffd;
	
	var testBox = new BBox();
	var testPoint = new THREE.Vector3();
	var tempMin = new THREE.Vector3();
	var tempMax = new THREE.Vector3();
	var tempCen = new THREE.Vector3();
	var tempV1 = new THREE.Vector3();
	var tempV2 = new THREE.Vector3();
	var tempV3 = new THREE.Vector3();

	for (var i = 0; i < 128; i++) {
		todo[i] = new BVH_BuildEntry();
	}
	// Push the root
	todo[stackptr].start = 0;
	todo[stackptr].end = total_number_of_triangles;
	todo[stackptr].parent = 0xfffffffc;
	stackptr++;

	while (stackptr > 0) {
		
		nNodes++;
		
		// Pop the next item off of the stack
		stackptr--;
		var split_dim = 0;	
		var split_coord = 0;
		var bnode = todo[stackptr];
		var start = bnode.start;
		var mid = 0;
		var end = bnode.end;
		var nPrims = end - start;
		
		var node = new BVH_FlatNode();
		node.start = start;
		node.nPrims = nPrims;
		node.rightOffset = Untouched;
		
		// Calculate the bounding box for this node
		var bb = new BBox();
		var bc = new BBox();
		
		bb.minCorner.set( aabb_array[9*start+0], aabb_array[9*start+1], aabb_array[9*start+2] );
		bb.maxCorner.set( aabb_array[9*start+3], aabb_array[9*start+4], aabb_array[9*start+5] );
		bc.minCorner.set( aabb_array[9*start+6], aabb_array[9*start+7], aabb_array[9*start+8] );
		//bc.maxCorner.set(-Infinity,-Infinity,-Infinity);
		for (var p = start + 1; p < end; ++p) {
			testBox.minCorner.set( aabb_array[9*p+0], aabb_array[9*p+1], aabb_array[9*p+2] );
			testBox.maxCorner.set( aabb_array[9*p+3], aabb_array[9*p+4], aabb_array[9*p+5] );
			bb.expandToIncludeBox(testBox);
			testPoint.set( aabb_array[9*p+6], aabb_array[9*p+7], aabb_array[9*p+8] );
			bc.expandToIncludePoint(testPoint);
		}
		node.bbox = bb;

		// If the number of primitives at this point is less than the leaf
		// size, then this will become a leaf. (Signified by rightOffset == 0)
		if (nPrims <= leafSize) {
			node.rightOffset = 0;
			nLeafs++;
		}

		buildnodes.push(node);

		// Child touches parent...
		// Special case: Don't do this for the root (root is 0xfffffffc).
		if (bnode.parent != 0xfffffffc) {
			buildnodes[bnode.parent].rightOffset--;

			// When this is the second touch, this is the right child.
			// The right child sets up the offset for the flat tree.
			if (buildnodes[bnode.parent].rightOffset == TouchedTwice) {
				buildnodes[bnode.parent].rightOffset = nNodes - 1 - bnode.parent;
			}
		}

		// If this is a leaf, no need to subdivide.
		if (node.rightOffset == 0)
			continue;

		// Set the split dimensions
		split_dim = bc.maxDimension();
			
		// Split on the center of the longest axis, then
		// Partition the list of objects on this split
		mid = start;
		if (split_dim == 0) {
			// Split on the center of the X axis
			split_coord = 0.5 * (bc.minCorner.x + bc.maxCorner.x);
								
			for (var i = start; i < end; ++i) {
				if (aabb_array[9*i+6] < split_coord) {
					//swap [i] and [mid] bbox data
					tempMin.set( aabb_array[9*i+0], aabb_array[9*i+1], aabb_array[9*i+2] );
					tempMax.set( aabb_array[9*i+3], aabb_array[9*i+4], aabb_array[9*i+5] ); 
					tempCen.set( aabb_array[9*i+6], aabb_array[9*i+7], aabb_array[9*i+8] ); 
					
					aabb_array[9*i+0] = aabb_array[9*mid+0]; aabb_array[9*i+1] = aabb_array[9*mid+1]; aabb_array[9*i+2] = aabb_array[9*mid+2];
					aabb_array[9*i+3] = aabb_array[9*mid+3]; aabb_array[9*i+4] = aabb_array[9*mid+4]; aabb_array[9*i+5] = aabb_array[9*mid+5];
					aabb_array[9*i+6] = aabb_array[9*mid+6]; aabb_array[9*i+7] = aabb_array[9*mid+7]; aabb_array[9*i+8] = aabb_array[9*mid+8];
					
					aabb_array[9*mid+0] = tempMin.x; aabb_array[9*mid+1] = tempMin.y; aabb_array[9*mid+2] = tempMin.z;
					aabb_array[9*mid+3] = tempMax.x; aabb_array[9*mid+4] = tempMax.y; aabb_array[9*mid+5] = tempMax.z;
					aabb_array[9*mid+6] = tempCen.x; aabb_array[9*mid+7] = tempCen.y; aabb_array[9*mid+8] = tempCen.z;
					
					//swap [i] and [mid] triangle data
					tempV1.set( triangle_array[9*i+0], triangle_array[9*i+1], triangle_array[9*i+2] );
					tempV2.set( triangle_array[9*i+3], triangle_array[9*i+4], triangle_array[9*i+5] ); 
					tempV3.set( triangle_array[9*i+6], triangle_array[9*i+7], triangle_array[9*i+8] ); 
					
					triangle_array[9*i+0] = triangle_array[9*mid+0]; triangle_array[9*i+1] = triangle_array[9*mid+1]; triangle_array[9*i+2] = triangle_array[9*mid+2];
					triangle_array[9*i+3] = triangle_array[9*mid+3]; triangle_array[9*i+4] = triangle_array[9*mid+4]; triangle_array[9*i+5] = triangle_array[9*mid+5];
					triangle_array[9*i+6] = triangle_array[9*mid+6]; triangle_array[9*i+7] = triangle_array[9*mid+7]; triangle_array[9*i+8] = triangle_array[9*mid+8];
					
					triangle_array[9*mid+0] = tempV1.x; triangle_array[9*mid+1] = tempV1.y; triangle_array[9*mid+2] = tempV1.z;
					triangle_array[9*mid+3] = tempV2.x; triangle_array[9*mid+4] = tempV2.y; triangle_array[9*mid+5] = tempV2.z;
					triangle_array[9*mid+6] = tempV3.x; triangle_array[9*mid+7] = tempV3.y; triangle_array[9*mid+8] = tempV3.z;
					
					++mid;
				}
			}
		} // end if (split_dim == 0) {
		else if (split_dim == 1) {
			// Split on the center of the Y axis
			split_coord = 0.5 * (bc.minCorner.y + bc.maxCorner.y);
			
			for (var i = start; i < end; ++i) {
				if (aabb_array[9*i+7] < split_coord) {
					//swap [i] and [mid] bbox data
					tempMin.set( aabb_array[9*i+0], aabb_array[9*i+1], aabb_array[9*i+2] );
					tempMax.set( aabb_array[9*i+3], aabb_array[9*i+4], aabb_array[9*i+5] ); 
					tempCen.set( aabb_array[9*i+6], aabb_array[9*i+7], aabb_array[9*i+8] ); 
					
					aabb_array[9*i+0] = aabb_array[9*mid+0]; aabb_array[9*i+1] = aabb_array[9*mid+1]; aabb_array[9*i+2] = aabb_array[9*mid+2];
					aabb_array[9*i+3] = aabb_array[9*mid+3]; aabb_array[9*i+4] = aabb_array[9*mid+4]; aabb_array[9*i+5] = aabb_array[9*mid+5];
					aabb_array[9*i+6] = aabb_array[9*mid+6]; aabb_array[9*i+7] = aabb_array[9*mid+7]; aabb_array[9*i+8] = aabb_array[9*mid+8];
					
					aabb_array[9*mid+0] = tempMin.x; aabb_array[9*mid+1] = tempMin.y; aabb_array[9*mid+2] = tempMin.z;
					aabb_array[9*mid+3] = tempMax.x; aabb_array[9*mid+4] = tempMax.y; aabb_array[9*mid+5] = tempMax.z;
					aabb_array[9*mid+6] = tempCen.x; aabb_array[9*mid+7] = tempCen.y; aabb_array[9*mid+8] = tempCen.z;
					
					//swap [i] and [mid] triangle data
					tempV1.set( triangle_array[9*i+0], triangle_array[9*i+1], triangle_array[9*i+2] );
					tempV2.set( triangle_array[9*i+3], triangle_array[9*i+4], triangle_array[9*i+5] ); 
					tempV3.set( triangle_array[9*i+6], triangle_array[9*i+7], triangle_array[9*i+8] ); 
					
					triangle_array[9*i+0] = triangle_array[9*mid+0]; triangle_array[9*i+1] = triangle_array[9*mid+1]; triangle_array[9*i+2] = triangle_array[9*mid+2];
					triangle_array[9*i+3] = triangle_array[9*mid+3]; triangle_array[9*i+4] = triangle_array[9*mid+4]; triangle_array[9*i+5] = triangle_array[9*mid+5];
					triangle_array[9*i+6] = triangle_array[9*mid+6]; triangle_array[9*i+7] = triangle_array[9*mid+7]; triangle_array[9*i+8] = triangle_array[9*mid+8];
					
					triangle_array[9*mid+0] = tempV1.x; triangle_array[9*mid+1] = tempV1.y; triangle_array[9*mid+2] = tempV1.z;
					triangle_array[9*mid+3] = tempV2.x; triangle_array[9*mid+4] = tempV2.y; triangle_array[9*mid+5] = tempV2.z;
					triangle_array[9*mid+6] = tempV3.x; triangle_array[9*mid+7] = tempV3.y; triangle_array[9*mid+8] = tempV3.z;
					
					++mid;
				}
			}
		} // end else if (split_dim == 1) {
		else if (split_dim == 2) {
			// Split on the center of the Z axis
			split_coord = 0.5 * (bc.minCorner.z + bc.maxCorner.z);
			
			for (var i = start; i < end; ++i) {
				if (aabb_array[9*i+8] < split_coord) {
					//swap [i] and [mid] bbox data
					tempMin.set( aabb_array[9*i+0], aabb_array[9*i+1], aabb_array[9*i+2] );
					tempMax.set( aabb_array[9*i+3], aabb_array[9*i+4], aabb_array[9*i+5] ); 
					tempCen.set( aabb_array[9*i+6], aabb_array[9*i+7], aabb_array[9*i+8] ); 
					
					aabb_array[9*i+0] = aabb_array[9*mid+0]; aabb_array[9*i+1] = aabb_array[9*mid+1]; aabb_array[9*i+2] = aabb_array[9*mid+2];
					aabb_array[9*i+3] = aabb_array[9*mid+3]; aabb_array[9*i+4] = aabb_array[9*mid+4]; aabb_array[9*i+5] = aabb_array[9*mid+5];
					aabb_array[9*i+6] = aabb_array[9*mid+6]; aabb_array[9*i+7] = aabb_array[9*mid+7]; aabb_array[9*i+8] = aabb_array[9*mid+8];
					
					aabb_array[9*mid+0] = tempMin.x; aabb_array[9*mid+1] = tempMin.y; aabb_array[9*mid+2] = tempMin.z;
					aabb_array[9*mid+3] = tempMax.x; aabb_array[9*mid+4] = tempMax.y; aabb_array[9*mid+5] = tempMax.z;
					aabb_array[9*mid+6] = tempCen.x; aabb_array[9*mid+7] = tempCen.y; aabb_array[9*mid+8] = tempCen.z;
					
					//swap [i] and [mid] triangle data
					tempV1.set( triangle_array[9*i+0], triangle_array[9*i+1], triangle_array[9*i+2] );
					tempV2.set( triangle_array[9*i+3], triangle_array[9*i+4], triangle_array[9*i+5] ); 
					tempV3.set( triangle_array[9*i+6], triangle_array[9*i+7], triangle_array[9*i+8] ); 
					
					triangle_array[9*i+0] = triangle_array[9*mid+0]; triangle_array[9*i+1] = triangle_array[9*mid+1]; triangle_array[9*i+2] = triangle_array[9*mid+2];
					triangle_array[9*i+3] = triangle_array[9*mid+3]; triangle_array[9*i+4] = triangle_array[9*mid+4]; triangle_array[9*i+5] = triangle_array[9*mid+5];
					triangle_array[9*i+6] = triangle_array[9*mid+6]; triangle_array[9*i+7] = triangle_array[9*mid+7]; triangle_array[9*i+8] = triangle_array[9*mid+8];
					
					triangle_array[9*mid+0] = tempV1.x; triangle_array[9*mid+1] = tempV1.y; triangle_array[9*mid+2] = tempV1.z;
					triangle_array[9*mid+3] = tempV2.x; triangle_array[9*mid+4] = tempV2.y; triangle_array[9*mid+5] = tempV2.z;
					triangle_array[9*mid+6] = tempV3.x; triangle_array[9*mid+7] = tempV3.y; triangle_array[9*mid+8] = tempV3.z;
					
					++mid;
				}
			}
		} // end else if (split_dim == 2) {
		
		// If we get a bad split, just choose the center...
		if (mid == start || mid == end) {
			mid = start + (end - start) * 0.5;
		}

		// Push right child
		todo[stackptr].start = mid;
		todo[stackptr].end = end;
		todo[stackptr].parent = nNodes - 1;
		stackptr++;

		// Push left child
		todo[stackptr].start = start;
		todo[stackptr].end = mid;
		todo[stackptr].parent = nNodes - 1;
		stackptr++;
		
	} // end while (stackptr > 0) {

	// Copy the temp node data to the flat array
	for (var n = 0; n < nNodes; ++n) {
		flatTree[n] = buildnodes[n];	
	}
	
	// Copy the flat array to the aabb_array
	for (var n = 0; n < nNodes; ++n) {
		
		aabb_array[9 * n + 0] = flatTree[n].rightOffset;
		aabb_array[9 * n + 1] = flatTree[n].nPrims;
		aabb_array[9 * n + 2] = flatTree[n].start;
		
		aabb_array[9 * n + 3] = flatTree[n].bbox.minCorner.x;
		aabb_array[9 * n + 4] = flatTree[n].bbox.minCorner.y;
		aabb_array[9 * n + 5] = flatTree[n].bbox.minCorner.z;
		
		aabb_array[9 * n + 6] = flatTree[n].bbox.maxCorner.x;
		aabb_array[9 * n + 7] = flatTree[n].bbox.maxCorner.y;
		aabb_array[9 * n + 8] = flatTree[n].bbox.maxCorner.z;
		
	}

} // end function BVH_Build() {	