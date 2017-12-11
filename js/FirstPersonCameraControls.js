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

	this.pitchObject = new THREE.Object3D();
	this.pitchObject.add( camera );

	this.yawObject = new THREE.Object3D();
	this.yawObject.add( this.pitchObject );
	
	var scope = this;

	var movementX = 0;
	var movementY = 0;
			
	var onMouseMove = function ( event ) {

		movementX = event.movementX || event.mozMovementX || 0;
		movementY = event.movementY || event.mozMovementY || 0;

		scope.yawObject.rotation.y -= movementX * 0.002;
		scope.pitchObject.rotation.x -= movementY * 0.002;

		scope.pitchObject.rotation.x = Math.max( - PI_2, Math.min( PI_2, scope.pitchObject.rotation.x ) );
			
	};

	document.addEventListener( 'mousemove', onMouseMove, false );
	

	this.getObject = function () {

		return scope.yawObject;

	};
	
	this.getYawObject = function () {

		return scope.yawObject;

	};
	
	this.getPitchObject = function () {

		return scope.pitchObject;

	};
/*	
	this.getDirection = function() {

		// assumes the camera itself is not rotated

		var direction = new THREE.Vector3( 0, 0, -1 );
		var rotation = new THREE.Euler( 0, 0, 0, "YXZ" );

		return function( v ) {

			rotation.set( scope.pitchObject.rotation.x, scope.yawObject.rotation.y, 0 );

			v.copy( direction ).applyEuler( rotation );

			return v;

		};

	}();
*/	
	this.getDirection = function() {

		var te = camera.matrixWorld.elements;

		return function( v ) {
			
			v.set( te[ 8 ], te[ 9 ], te[ 10 ] ).negate();
			
			return v;

		};

	}();
	
	this.getUpVector = function() {

		var te = camera.matrixWorld.elements;

		return function( v ) {
			
			v.set( te[ 4 ], te[ 5 ], te[ 6 ] );
			
			return v;

		};

	}();
	
	this.getRightVector = function() {

		var te = camera.matrixWorld.elements;

		return function( v ) {
			
			v.set( te[ 0 ], te[ 1 ], te[ 2 ] );
			
			return v;

		};

	}();

};
