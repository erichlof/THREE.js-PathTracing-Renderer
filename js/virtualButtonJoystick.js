var VJ_Stick_ctx;
var VJ_Base_ctx;
var VJ_Button1_ctx;
var VJ_Button2_ctx;
var VJ_Button3_ctx;
var VJ_touch = null;
var VJ_touches = [];
var VJ_testTouch = null;
var VJ_x = 0;
var VJ_y = 0;
var VJ_deltaX = 0;
var VJ_deltaY = 0;
var VJ_stickDistance = 0;
var VJ_stickNormalizedX = 0;
var VJ_stickNormalizedY = 0;

var VirtualJoystick = function(opts) {
	opts = opts || {};
	this._container = opts.container || document.body;
	this._strokeStyle = opts.strokeStyle || 'cyan';
	this._stickEl = opts.stickElement || this._buildJoystickStick();
	this._baseEl = opts.baseElement || this._buildJoystickBase();
	this._hideJoystick = opts.hideJoystick || false;
	this._hideButtons = opts.hideButtons || true;
	if('createTouch' in document) this._hideButtons = false;
	this._stationaryBase = opts.stationaryBase || false;
	this._add1Button = opts.add1Button || false;
	this._add2Buttons = opts.add2Buttons || false;
	this._add3Buttons = opts.add3Buttons || false;
	if (this._add2Buttons) this._add1Button = false;
	if (this._add3Buttons) {
		this._add1Button = false;
		this._add2Buttons = false;
	} 
	this._baseX = this._stickX = opts.baseX || 200;
	this._baseY = this._stickY = opts.baseY || 300;
	
	this._buttonCanvasWidth = 106;
	this._buttonCanvasHalfWidth = 53;
	
	if (this._add1Button) {
		this._strokeStyleButton1 = opts.strokeStyleButton1 || 'orange';
		this._button1El = opts.button1Element || this._buildButton1();
		this._button1PercentLeft = opts.button1PercentLeft || 40;
		this._button1PercentBottom = opts.button1PercentBottom || 1;
			
		if (!this._hideButtons) {
			this._container.appendChild(this._button1El);	
		}
		this._button1El.style.position = "absolute";
		this._button1El.style.display = "none";
		this.button1Pressed = false;
		
	}
	
	if (this._add2Buttons) {
		this._strokeStyleButton1 = opts.strokeStyleButton1 || 'orange';
		this._button1El = opts.button1Element || this._buildButton1();
		this._button1PercentLeft = opts.button1PercentLeft || 40;
		this._button1PercentBottom = opts.button1PercentBottom || 1;

		if (!this._hideButtons) {
			this._container.appendChild(this._button1El);	
		}
		this._button1El.style.position = "absolute";
		this._button1El.style.display = "none";
		this.button1Pressed = false;
		
		this._strokeStyleButton2 = opts.strokeStyleButton2 || 'magenta';
		this._button2El = opts.button2Element || this._buildButton2();
		this._button2PercentLeft = opts.button2PercentLeft || 50;
		this._button2PercentBottom = opts.button2PercentBottom || 1;
		
		if (!this._hideButtons) {
			this._container.appendChild(this._button2El);
		}
		this._button2El.style.position = "absolute";
		this._button2El.style.display = "none";
		this.button2Pressed = false;
		
	}
	
	if (this._add3Buttons) {
		
		this._buttonCanvasWidth = 80;
		this._buttonCanvasHalfWidth = 40;
		
		this._strokeStyleButton1 = opts.strokeStyleButton1 || 'orange';
		this._button1El = opts.button1Element || this._buildButton1();
		this._button1PercentLeft = opts.button1PercentLeft || 40;
		this._button1PercentBottom = opts.button1PercentBottom || 0;

		if (!this._hideButtons) {
			this._container.appendChild(this._button1El);	
		}
		this._button1El.style.position = "absolute";
		this._button1El.style.display = "none";
		this.button1Pressed = false;
		
		this._strokeStyleButton2 = opts.strokeStyleButton2 || 'magenta';
		this._button2El = opts.button2Element || this._buildButton2();
		this._button2PercentLeft = opts.button2PercentLeft || 50;
		this._button2PercentBottom = opts.button2PercentBottom || 0;
		
		if (!this._hideButtons) {
			this._container.appendChild(this._button2El);
		}
		this._button2El.style.position = "absolute";
		this._button2El.style.display = "none";
		this.button2Pressed = false;
		
		this._strokeStyleButton3 = opts.strokeStyleButton3 || 'lightgreen';
		this._button3El = opts.button3Element || this._buildButton3();
		this._button3PercentLeft = opts.button3PercentLeft || 45;
		this._button3PercentBottom = opts.button3PercentBottom || 11;
		
		if (!this._hideButtons) {
			this._container.appendChild(this._button3El);
		}
		this._button3El.style.position = "absolute";
		this._button3El.style.display = "none";
		this.button3Pressed = false;
		
	}
	
	if(this._hideJoystick)
		this._stationaryBase = false;

	this._limitStickTravel = opts.limitStickTravel || false;
	if (this._stationaryBase) this._limitStickTravel = true;
	this._stickRadius = opts.stickRadius || 100;
	if (this._stickRadius > 120) this._stickRadius = 120;

	this._container.style.position = "relative";

	this._container.appendChild(this._baseEl);
	this._baseEl.style.position = "absolute";
	this._baseEl.style.display = "none";

	this._container.appendChild(this._stickEl);
	this._stickEl.style.position = "absolute";
	this._stickEl.style.display = "none";

	this._pressed = false;
	this._touchIdx = null;
	
	
	//added for THREEx.FirstPersonControls use
	this.previousRotationX = 0;
	this.previousRotationY = 0;

	if (this._stationaryBase) {
		this._baseEl.style.display = "";
		this._baseEl.style.left = (this._baseX - this._baseEl.width / 2) + "px";
		this._baseEl.style.top = (this._baseY - this._baseEl.height / 2) + "px";
	}

	if (this._add1Button) {
		this._button1El.style.display = "";
		this._button1El.style.left = this._button1PercentLeft + "%";
		this._button1El.style.bottom = this._button1PercentBottom + "%";
		this._button1El.style.zIndex = "10";
	}
	if (this._add2Buttons) {
		this._button1El.style.display = "";
		this._button1El.style.left = this._button1PercentLeft + "%";
		this._button1El.style.bottom = this._button1PercentBottom + "%";
		this._button1El.style.zIndex = "10";
		
		this._button2El.style.display = "";
		this._button2El.style.left = this._button2PercentLeft + "%";
		this._button2El.style.bottom = this._button2PercentBottom + "%";
		this._button2El.style.zIndex = "10";
	}
	if (this._add3Buttons) {
		this._button1El.style.display = "";
		this._button1El.style.left = this._button1PercentLeft + "%";
		this._button1El.style.bottom = this._button1PercentBottom + "%";
		this._button1El.style.zIndex = "10";
		
		this._button2El.style.display = "";
		this._button2El.style.left = this._button2PercentLeft + "%";
		this._button2El.style.bottom = this._button2PercentBottom + "%";
		this._button2El.style.zIndex = "10";
		
		this._button3El.style.display = "";
		this._button3El.style.left = this._button3PercentLeft + "%";
		this._button3El.style.bottom = this._button3PercentBottom + "%";
		this._button3El.style.zIndex = "10";
	}

	var __bind = function(fn, me) {
		return function() {
			return fn.apply(me, arguments);
		};
	};
	this._$onTouchStart = __bind(this._onTouchStart, this);
	this._$onTouchEnd = __bind(this._onTouchEnd, this);
	this._$onTouchMove = __bind(this._onTouchMove, this);
	
	this._container.addEventListener('touchstart', this._$onTouchStart, false);
	this._container.addEventListener('touchend', this._$onTouchEnd, false);
	this._container.addEventListener('touchmove', this._$onTouchMove, false);	

};

VirtualJoystick.prototype.destroy = function() {

	this._container.removeChild(this._baseEl);
	this._container.removeChild(this._stickEl);
	
	this._container.removeEventListener('touchstart', this._$onTouchStart, false);
	this._container.removeEventListener('touchend', this._$onTouchEnd, false);
	this._container.removeEventListener('touchmove', this._$onTouchMove, false);
		
};

/**
 * @returns {Boolean} true if touchscreen is currently available, false otherwise
 */
VirtualJoystick.touchScreenAvailable = function() {
	return 'createTouch' in document ? true : false;
};

//////////////////////////////////////////////////////////////////////////////////
//                                                                                //
//////////////////////////////////////////////////////////////////////////////////

VirtualJoystick.prototype.deltaX = function() {
	return this._stickX - this._baseX;
};
VirtualJoystick.prototype.deltaY = function() {
	return this._stickY - this._baseY;
};

VirtualJoystick.prototype.up = function() {
	if (!this._pressed) return false;
	VJ_deltaX = this.deltaX();
	VJ_deltaY = this.deltaY();
	if (VJ_deltaY >= 0) return false;
	if (Math.abs(VJ_deltaX) > 2 * Math.abs(VJ_deltaY)) return false;
	return true;
};
VirtualJoystick.prototype.down = function() {
	if (!this._pressed) return false;
	VJ_deltaX = this.deltaX();
	VJ_deltaY = this.deltaY();
	if (VJ_deltaY <= 0) return false;
	if (Math.abs(VJ_deltaX) > 2 * Math.abs(VJ_deltaY)) return false;
	return true;
};
VirtualJoystick.prototype.right = function() {
	if (!this._pressed) return false;
	VJ_deltaX = this.deltaX();
	VJ_deltaY = this.deltaY();
	if (VJ_deltaX <= 0) return false;
	if (Math.abs(VJ_deltaY) > 2 * Math.abs(VJ_deltaX)) return false;
	return true;
};
VirtualJoystick.prototype.left = function() {
	if (!this._pressed) return false;
	VJ_deltaX = this.deltaX();
	VJ_deltaY = this.deltaY();
	if (VJ_deltaX >= 0) return false;
	if (Math.abs(VJ_deltaY) > 2 * Math.abs(VJ_deltaX)) return false;
	return true;
};

//////////////////////////////////////////////////////////////////////////////////
//										//
//////////////////////////////////////////////////////////////////////////////////

VirtualJoystick.prototype._onUp = function() {
	this._pressed = false;
	this._stickEl.style.display = "none";

	if (!this._stationaryBase) {
		this._baseEl.style.display = "none";

		this._baseX = this._baseY = 0;
		this._stickX = this._stickY = 0;
	}
};

VirtualJoystick.prototype._onDown = function(x, y) {
	
	this._pressed = true;
	if (!this._stationaryBase) {
		this._baseX = x;
		this._baseY = y;
		if(!this._hideJoystick){
			this._baseEl.style.display = "";
			this._move(this._baseEl.style, (this._baseX - this._baseEl.width / 2), (this._baseY - this._baseEl.height / 2));
		}
	}
	
	this._stickX = x;
	this._stickY = y;

	if (this._limitStickTravel) {
		VJ_deltaX = this.deltaX();
		VJ_deltaY = this.deltaY();
		VJ_stickDistance = Math.sqrt((VJ_deltaX * VJ_deltaX) + (VJ_deltaY * VJ_deltaY));
		if (VJ_stickDistance > this._stickRadius) {
			VJ_stickNormalizedX = VJ_deltaX / VJ_stickDistance;
			VJ_stickNormalizedY = VJ_deltaY / VJ_stickDistance;
			this._stickX = VJ_stickNormalizedX * this._stickRadius + this._baseX;
			this._stickY = VJ_stickNormalizedY * this._stickRadius + this._baseY;
		}
	}
	if(!this._hideJoystick){
		this._stickEl.style.display = "";
		this._move(this._stickEl.style, (this._stickX - this._stickEl.width / 2), (this._stickY - this._stickEl.height / 2));
	}
};

VirtualJoystick.prototype._onMove = function(x, y) {
	this._stickX = x;
	this._stickY = y;

	if (this._limitStickTravel) {
		VJ_deltaX = this.deltaX();
		VJ_deltaY = this.deltaY();
		VJ_stickDistance = Math.sqrt((VJ_deltaX * VJ_deltaX) + (VJ_deltaY * VJ_deltaY));
		if (VJ_stickDistance > this._stickRadius) {
			VJ_stickNormalizedX = VJ_deltaX / VJ_stickDistance;
			VJ_stickNormalizedY = VJ_deltaY / VJ_stickDistance;

			this._stickX = VJ_stickNormalizedX * this._stickRadius + this._baseX;
			this._stickY = VJ_stickNormalizedY * this._stickRadius + this._baseY;
		}
	}
	if(!this._hideJoystick){
		this._move(this._stickEl.style, (this._stickX - this._stickEl.width / 2), (this._stickY - this._stickEl.height / 2));
	}
};

VirtualJoystick.prototype._onButton1Up = function() {
	this.button1Pressed = false;
	
	VJ_Button1_ctx.beginPath();
	VJ_Button1_ctx.strokeStyle = 'orange';
	VJ_Button1_ctx.lineWidth = this._add3Buttons ? 4 : 6;
	if (this._add3Buttons) VJ_Button1_ctx.arc(this._buttonCanvasHalfWidth, this._buttonCanvasHalfWidth, 25, 0, Math.PI * 2, true);
	else VJ_Button1_ctx.arc(this._buttonCanvasHalfWidth, this._buttonCanvasHalfWidth, 35, 0, Math.PI * 2, true);
	VJ_Button1_ctx.stroke();
};

VirtualJoystick.prototype._onButton1Down = function() {
	this.button1Pressed = true;
	
	VJ_Button1_ctx.beginPath();
	VJ_Button1_ctx.strokeStyle = 'white';
	VJ_Button1_ctx.lineWidth = this._add3Buttons ? 4 : 6;
	if (this._add3Buttons) VJ_Button1_ctx.arc(this._buttonCanvasHalfWidth, this._buttonCanvasHalfWidth, 25, 0, Math.PI * 2, true);
	else VJ_Button1_ctx.arc(this._buttonCanvasHalfWidth, this._buttonCanvasHalfWidth, 35, 0, Math.PI * 2, true);
	VJ_Button1_ctx.stroke();
};

VirtualJoystick.prototype._onButton2Up = function() {
	this.button2Pressed = false;
	
	VJ_Button2_ctx.beginPath();
	VJ_Button2_ctx.strokeStyle = 'magenta';
	VJ_Button2_ctx.lineWidth = this._add3Buttons ? 4 : 6;
	if (this._add3Buttons) VJ_Button2_ctx.arc(this._buttonCanvasHalfWidth, this._buttonCanvasHalfWidth, 25, 0, Math.PI * 2, true);
	else VJ_Button2_ctx.arc(this._buttonCanvasHalfWidth, this._buttonCanvasHalfWidth, 35, 0, Math.PI * 2, true);
	VJ_Button2_ctx.stroke();
};

VirtualJoystick.prototype._onButton2Down = function() {
	this.button2Pressed = true;
	
	VJ_Button2_ctx.beginPath();
	VJ_Button2_ctx.strokeStyle = 'white';
	VJ_Button2_ctx.lineWidth = this._add3Buttons ? 4 : 6;
	if (this._add3Buttons) VJ_Button2_ctx.arc(this._buttonCanvasHalfWidth, this._buttonCanvasHalfWidth, 25, 0, Math.PI * 2, true);
	else VJ_Button2_ctx.arc(this._buttonCanvasHalfWidth, this._buttonCanvasHalfWidth, 35, 0, Math.PI * 2, true);
	VJ_Button2_ctx.stroke();
};

VirtualJoystick.prototype._onButton3Up = function() {
	this.button3Pressed = false;
	
	VJ_Button3_ctx.beginPath();
	VJ_Button3_ctx.strokeStyle = 'green';
	VJ_Button3_ctx.lineWidth = 3;
	VJ_Button3_ctx.arc(40, 40, 20, 0, Math.PI * 2, true);
	VJ_Button3_ctx.stroke();
};

VirtualJoystick.prototype._onButton3Down = function() {
	this.button3Pressed = true;
	
	VJ_Button3_ctx.beginPath();
	VJ_Button3_ctx.strokeStyle = 'white';
	VJ_Button3_ctx.lineWidth = 3;
	VJ_Button3_ctx.arc(40, 40, 20, 0, Math.PI * 2, true);
	VJ_Button3_ctx.stroke();
};


VirtualJoystick.prototype._onTouchStart = function(event) {

	event.preventDefault();
	VJ_testTouch = event.changedTouches[0];
	if (VJ_testTouch.target == this._button1El) {
		return this._onButton1Down();
	}
	else if (VJ_testTouch.target == this._button2El) {
		return this._onButton2Down();
	}
	else if (VJ_testTouch.target == this._button3El) {
		return this._onButton3Down();
	}

	VJ_touches = event.touches;
	if (VJ_touches.length == 2) {
		if (VJ_touches[0].target != this._button1El && VJ_touches[0].target != this._button2El && 
		    VJ_touches[0].target != this._button3El) {
			VJ_x = VJ_touches[0].pageX;
			VJ_y = VJ_touches[0].pageY;
			return this._onDown(VJ_x, VJ_y);
		} 
		else {
			VJ_x = VJ_touches[1].pageX;
			VJ_y = VJ_touches[1].pageY;
			return this._onDown(VJ_x, VJ_y);
		}
	}
	else if (VJ_touches.length == 3) {
		VJ_x = VJ_touches[2].pageX;
		VJ_y = VJ_touches[2].pageY;
		return this._onDown(VJ_x, VJ_y);
	}
	else if (VJ_touches.length >= 4) {
		VJ_x = VJ_touches[3].pageX;
		VJ_y = VJ_touches[3].pageY;
		return this._onDown(VJ_x, VJ_y);
	}
	else {
		VJ_x = VJ_touches[0].pageX;
		VJ_y = VJ_touches[0].pageY;
		return this._onDown(VJ_x, VJ_y);
	}
};

VirtualJoystick.prototype._onTouchEnd = function(event) {
  
	VJ_touch = event.changedTouches[0];
	if (VJ_touch.target == this._button1El) 
		return this._onButton1Up();
	if (VJ_touch.target == this._button2El) 
		return this._onButton2Up();
	if (VJ_touch.target == this._button3El) 
		return this._onButton3Up();
	
	this.previousRotationY = cameraControlsYawObject.rotation.y;
	this.previousRotationX = cameraControlsPitchObject.rotation.x;

	return this._onUp();
};

VirtualJoystick.prototype._onTouchMove = function(event) {

	VJ_touch = event.targetTouches[0];
	if (VJ_touch.target == this._button1El || VJ_touch.target == this._button2El || VJ_touch.target == this._button3El)
		return;
	VJ_x = VJ_touch.pageX;
	VJ_y = VJ_touch.pageY;
	return this._onMove(VJ_x, VJ_y);
};

//////////////////////////////////////////////////////////////////////////////////
//		build default stickEl and baseEl				//
//////////////////////////////////////////////////////////////////////////////////

/**
 * build the canvas for joystick base
 */
VirtualJoystick.prototype._buildJoystickBase = function() {
	var canvas = document.createElement('canvas');
	canvas.width = 126;
	canvas.height = 126;
	
	VJ_Base_ctx = canvas.getContext('2d');
	VJ_Base_ctx.beginPath();
	VJ_Base_ctx.strokeStyle = this._strokeStyle;
	VJ_Base_ctx.lineWidth = 6;
	VJ_Base_ctx.arc(canvas.width / 2, canvas.width / 2, 40, 0, Math.PI * 2, true);
	VJ_Base_ctx.stroke();

	VJ_Base_ctx.beginPath();
	VJ_Base_ctx.strokeStyle = this._strokeStyle;
	VJ_Base_ctx.lineWidth = 2;
	VJ_Base_ctx.arc(canvas.width / 2, canvas.width / 2, 60, 0, Math.PI * 2, true);
	VJ_Base_ctx.stroke();

	return canvas;
};

/**
 * build the canvas for joystick stick
 */
VirtualJoystick.prototype._buildJoystickStick = function() {
	var canvas = document.createElement('canvas');
	canvas.width = 86;
	canvas.height = 86;
	VJ_Stick_ctx = canvas.getContext('2d');
	VJ_Stick_ctx.beginPath();
	VJ_Stick_ctx.strokeStyle = this._strokeStyle;
	VJ_Stick_ctx.lineWidth = 6;
	VJ_Stick_ctx.arc(canvas.width / 2, canvas.width / 2, 40, 0, Math.PI * 2, true);
	VJ_Stick_ctx.stroke();
	return canvas;
};

/**
 * build the canvas for Button1
 */
VirtualJoystick.prototype._buildButton1 = function() {
	var canvas = document.createElement('canvas');
	canvas.width = this._buttonCanvasWidth;
	canvas.height = this._buttonCanvasWidth;
	if (this._add3Buttons) canvas.width = canvas.height = 80;

	VJ_Button1_ctx = canvas.getContext('2d');
	VJ_Button1_ctx.beginPath();
	VJ_Button1_ctx.strokeStyle = this._strokeStyleButton1;
	VJ_Button1_ctx.lineWidth = 6;
	if (this._add3Buttons) VJ_Button1_ctx.lineWidth = 4;
	if (this._add3Buttons) VJ_Button1_ctx.arc(this._buttonCanvasHalfWidth, this._buttonCanvasHalfWidth, 25, 0, Math.PI * 2, true);
	else VJ_Button1_ctx.arc(this._buttonCanvasHalfWidth, this._buttonCanvasHalfWidth, 35, 0, Math.PI * 2, true);
	VJ_Button1_ctx.stroke();

	VJ_Button1_ctx.beginPath();
	VJ_Button1_ctx.strokeStyle = 'red';
	VJ_Button1_ctx.lineWidth = 2;
	if (this._add3Buttons) VJ_Button1_ctx.lineWidth = 1;
	if (this._add3Buttons) VJ_Button1_ctx.arc(this._buttonCanvasHalfWidth, this._buttonCanvasHalfWidth, 35, 0, Math.PI * 2, true);
	else VJ_Button1_ctx.arc(this._buttonCanvasHalfWidth, this._buttonCanvasHalfWidth, 45, 0, Math.PI * 2, true);
	VJ_Button1_ctx.stroke();

	return canvas;
};

/**
 * build the canvas for Button2
 */
VirtualJoystick.prototype._buildButton2 = function() {
	var canvas = document.createElement('canvas');
	canvas.width = this._buttonCanvasWidth;
	canvas.height = this._buttonCanvasWidth;

	VJ_Button2_ctx = canvas.getContext('2d');
	VJ_Button2_ctx.beginPath();
	VJ_Button2_ctx.strokeStyle = this._strokeStyleButton2;
	VJ_Button2_ctx.lineWidth = 6;
	if (this._add3Buttons) VJ_Button2_ctx.lineWidth = 4;
	if (this._add3Buttons) VJ_Button2_ctx.arc(this._buttonCanvasHalfWidth, this._buttonCanvasHalfWidth, 25, 0, Math.PI * 2, true);
	else VJ_Button2_ctx.arc(this._buttonCanvasHalfWidth, this._buttonCanvasHalfWidth, 35, 0, Math.PI * 2, true);
	VJ_Button2_ctx.stroke();

	VJ_Button2_ctx.beginPath();
	VJ_Button2_ctx.strokeStyle = 'purple';
	VJ_Button2_ctx.lineWidth = 2;
	if (this._add3Buttons) VJ_Button2_ctx.lineWidth = 1;
	if (this._add3Buttons) VJ_Button2_ctx.arc(this._buttonCanvasHalfWidth, this._buttonCanvasHalfWidth, 35, 0, Math.PI * 2, true);
	else VJ_Button2_ctx.arc(this._buttonCanvasHalfWidth, this._buttonCanvasHalfWidth, 45, 0, Math.PI * 2, true);
	VJ_Button2_ctx.stroke();

	return canvas;
};

/**
 * build the canvas for Button3
 */
VirtualJoystick.prototype._buildButton3 = function() {
	var canvas = document.createElement('canvas');
	canvas.width = 80;
	canvas.height = 80;

	VJ_Button3_ctx = canvas.getContext('2d');
	VJ_Button3_ctx.beginPath();
	VJ_Button3_ctx.strokeStyle = this._strokeStyleButton3;
	VJ_Button3_ctx.lineWidth = 3;
	VJ_Button3_ctx.arc(canvas.width / 2, canvas.width / 2, 20, 0, Math.PI * 2, true);
	VJ_Button3_ctx.stroke();

	VJ_Button3_ctx.beginPath();
	VJ_Button3_ctx.strokeStyle = 'green';
	VJ_Button3_ctx.lineWidth = 1;
	VJ_Button3_ctx.arc(canvas.width / 2, canvas.width / 2, 30, 0, Math.PI * 2, true);
	VJ_Button3_ctx.stroke();

	return canvas;
};

VirtualJoystick.prototype._move = function(style, x, y)
{
		style.left = x + 'px';
		style.top = y + 'px';
};