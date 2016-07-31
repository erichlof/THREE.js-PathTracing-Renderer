/**
 * @author mrdoob / http://mrdoob.com/
 * adapted for virtualButtonJoystick.js by erichlof
 * https://github.com/erichlof
 */

var FirstPersonCameraControls = function ( camera ) {

	camera.rotation.set( 0, 0, 0 );

	this.pitchObject = new THREE.Object3D();
	this.pitchObject.add( camera );

	this.yawObject = new THREE.Object3D();
	this.yawObject.add( this.pitchObject );
	
	var that = this;

	var movementX = 0;
	var movementY = 0;
			
	var onMouseMove = function ( event ) {

		movementX = event.movementX || event.mozMovementX || 0;
		movementY = event.movementY || event.mozMovementY || 0;

		that.yawObject.rotation.y -= movementX * 0.002;
		that.pitchObject.rotation.x -= movementY * 0.002;

		that.pitchObject.rotation.x = Math.max( - PI_2, Math.min( PI_2, that.pitchObject.rotation.x ) );
			
	};

	document.addEventListener( 'mousemove', onMouseMove, false );
	

	this.getObject = function () {

		return that.yawObject;

	};
	
	this.getYawObject = function () {

		return that.yawObject;

	};
	
	this.getPitchObject = function () {

		return that.pitchObject;

	};
/*	
	this.getDirection = function() {

		// assumes the camera itself is not rotated

		var direction = new THREE.Vector3( 0, 0, -1 );
		var rotation = new THREE.Euler( 0, 0, 0, "YXZ" );

		return function( v ) {

			rotation.set( that.pitchObject.rotation.x, that.yawObject.rotation.y, 0 );

			v.copy( direction ).applyEuler( rotation );

			return v;

		};

	}();
*/	
	this.getDirection = function() {

		var te = that.pitchObject.matrixWorld.elements;

		return function( v ) {
			
			v.set( te[ 8 ], te[ 9 ], te[ 10 ] ).negate();
			
			return v;

		};

	}();
	
	this.getUpVector = function() {

		var te = that.pitchObject.matrixWorld.elements;

		return function( v ) {
			
			v.set( te[ 4 ], te[ 5 ], te[ 6 ] );
			
			return v;

		};

	}();
	
	this.getRightVector = function() {

		var te = that.pitchObject.matrixWorld.elements;

		return function( v ) {
			
			v.set( te[ 0 ], te[ 1 ], te[ 2 ] );
			
			return v;

		};

	}();

};