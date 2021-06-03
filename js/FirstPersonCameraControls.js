/**
 * originally from https://github.com/mrdoob/three.js/blob/dev/examples/js/controls/PointerLockControls.js
 * @author mrdoob / http://mrdoob.com/
 *
 * edited by Erich Loftis (erichlof on GitHub)
 * https://github.com/erichlof
 * Btw, this is the most consice and elegant way to implement first person camera rotation/movement that I've ever seen -
 * look at how short it is, without spaces/braces it would be around 30 lines!  Way to go, mrdoob!
 */

var FirstPersonCameraControls = function ( camera ) {

	camera.rotation.set( 0, 0, 0 );

	var pitchObject = new THREE.Object3D();
	pitchObject.add( camera );

	var yawObject = new THREE.Object3D();
	yawObject.add( pitchObject );

	var movementX = 0;
	var movementY = 0;
			
	var onMouseMove = function ( event ) {

		if (isPaused)
			return;
		movementX = event.movementX || event.mozMovementX || 0;
		movementY = event.movementY || event.mozMovementY || 0;

		yawObject.rotation.y -= movementX * 0.0012 * cameraRotationSpeed;
		pitchObject.rotation.x -= movementY * 0.001 * cameraRotationSpeed;
		// clamp the camera's vertical movement (around the x-axis) to the scene's 'ceiling' and 'floor'
		pitchObject.rotation.x = Math.max( - PI_2, Math.min( PI_2, pitchObject.rotation.x ) );
			
	};

	document.addEventListener( 'mousemove', onMouseMove, false );
	

	this.getObject = function () {

		return yawObject;

	};
	
	this.getYawObject = function () {

		return yawObject;

	};
	
	this.getPitchObject = function () {

		return pitchObject;

	};

	this.getDirection = function() {

		var te = pitchObject.matrixWorld.elements;

		return function( v ) {
			
			v.set( te[ 8 ], te[ 9 ], te[ 10 ] ).negate();
			
			return v;

		};

	}();
	
	this.getUpVector = function() {

		var te = pitchObject.matrixWorld.elements;

		return function( v ) {
			
			v.set( te[ 4 ], te[ 5 ], te[ 6 ] );
			
			return v;

		};

	}();
	
	this.getRightVector = function() {

		var te = pitchObject.matrixWorld.elements;

		return function( v ) {
			
			v.set( te[ 0 ], te[ 1 ], te[ 2 ] );
			
			return v;

		};

	}();

};
