// exposed global variables/elements that your program can access
var joystickDeltaX = 0;
var joystickDeltaY = 0;
var pinchWidthX = 0;
var pinchWidthY = 0;
var joystickPressed = false;
var button1Pressed = false;
var button2Pressed = false;
var button3Pressed = false;
var button4Pressed = false;
var button5Pressed = false;
var button6Pressed = false;

var stickElement = null;
var baseElement = null;
var button1Element = null;
var button2Element = null;
var button3Element = null;
var button4Element = null;
var button5Element = null;
var button6Element = null;

// the following variables marked with an underscore ( _ ) are for internal use
var _touches = [];
var _testTouch = null;
var _stickDistance;
var _stickNormalizedX;
var _stickNormalizedY;
var _buttonCanvasWidth = 70;
var _buttonCanvasReducedWidth = 50;
var _buttonCanvasHalfWidth = _buttonCanvasWidth * 0.5;
var _smallButtonCanvasWidth = 40;
var _smallButtonCanvasReducedWidth = 28;
var _smallButtonCanvasHalfWidth = _smallButtonCanvasWidth * 0.5;
var _enableMultiTouch;
var _showJoystick;
var _showButtons;
var _stationaryBase;
var _limitStickTravel;
var _stickRadius;
var _baseX;
var _baseY;
var _stickX;
var _stickY;
var _container;



var MobileJoystickControls = function( opts ) {
	
	opts = opts || {};
	_container = document.body;
	//_container.style.position = "relative";
	joystickPressed = false;
	
	//create joystick Base
	baseElement = document.createElement('canvas');
	baseElement.width = 126;
	baseElement.height = 126;
	_container.appendChild(baseElement);
	baseElement.style.position = "absolute";
	baseElement.style.display = "none";
	
	_Base_ctx = baseElement.getContext('2d');
	_Base_ctx.strokeStyle = 'rgba(255,255,255,0.2)';
	_Base_ctx.lineWidth = 2;
	_Base_ctx.beginPath();
	_Base_ctx.arc(baseElement.width / 2, baseElement.width / 2, 40, 0, Math.PI * 2, true);
	_Base_ctx.stroke();
	
	//create joystick Stick
	stickElement = document.createElement('canvas');
	stickElement.width = 86;
	stickElement.height = 86;
	_container.appendChild(stickElement);
	stickElement.style.position = "absolute";
	stickElement.style.display = "none";
	
	_Stick_ctx = stickElement.getContext('2d');
	_Stick_ctx.strokeStyle = 'rgba(255,255,255,0.2)';
	_Stick_ctx.lineWidth = 3;
	_Stick_ctx.beginPath();
	_Stick_ctx.arc(stickElement.width / 2, stickElement.width / 2, 30, 0, Math.PI * 2, true);
	_Stick_ctx.stroke();
		
	//create button1
	button1Element = document.createElement('canvas');
	button1Element.width = _buttonCanvasReducedWidth; // for Triangle Button
	//button1Element.width = _buttonCanvasWidth; // for Circle Button
	button1Element.height = _buttonCanvasWidth;

	_container.appendChild(button1Element);		
	button1Element.style.position = "absolute";
	button1Element.style.display = "none";
	button1Element.style.zIndex = "10";
	button1Pressed = false;

	_Button1_ctx = button1Element.getContext('2d');
	_Button1_ctx.strokeStyle = 'rgba(255,255,255,0.2)';
	_Button1_ctx.lineWidth = 3;
	
	// Triangle Button
	_Button1_ctx.beginPath();
	_Button1_ctx.moveTo(0, _buttonCanvasHalfWidth);
	_Button1_ctx.lineTo(_buttonCanvasReducedWidth, _buttonCanvasWidth);
	_Button1_ctx.lineTo(_buttonCanvasReducedWidth, 0);
	_Button1_ctx.closePath();
	_Button1_ctx.stroke();
	
	/*
	// Circle Button
	_Button1_ctx.beginPath();
	_Button1_ctx.arc(_buttonCanvasHalfWidth, _buttonCanvasHalfWidth, _buttonCanvasHalfWidth - 8, 0, Math.PI * 2);
	_Button1_ctx.stroke();
	_Button1_ctx.lineWidth = 1;
	_Button1_ctx.beginPath();
	_Button1_ctx.arc(_buttonCanvasHalfWidth, _buttonCanvasHalfWidth, _buttonCanvasHalfWidth - 1, 0, Math.PI * 2);
	_Button1_ctx.stroke();
	*/
	
	//create button2
	button2Element = document.createElement('canvas');
	button2Element.width = _buttonCanvasReducedWidth; // for Triangle Button
	//button2Element.width = _buttonCanvasWidth; // for Circle Button
	button2Element.height = _buttonCanvasWidth;
	
	_container.appendChild(button2Element);	
	button2Element.style.position = "absolute";
	button2Element.style.display = "none";
	button2Element.style.zIndex = "10";
	button2Pressed = false;

	_Button2_ctx = button2Element.getContext('2d');
	_Button2_ctx.strokeStyle = 'rgba(255,255,255,0.2)';
	_Button2_ctx.lineWidth = 3;
	
	// Triangle Button
	_Button2_ctx.beginPath();
	_Button2_ctx.moveTo(_buttonCanvasReducedWidth, _buttonCanvasHalfWidth);
	_Button2_ctx.lineTo(0, 0);
	_Button2_ctx.lineTo(0, _buttonCanvasWidth);
	_Button2_ctx.closePath();
	_Button2_ctx.stroke();
	
	/*
	// Circle Button
	_Button2_ctx.beginPath();
	_Button2_ctx.arc(_buttonCanvasHalfWidth, _buttonCanvasHalfWidth, _buttonCanvasHalfWidth - 8, 0, Math.PI * 2);
	_Button2_ctx.stroke();
	_Button2_ctx.lineWidth = 1;
	_Button2_ctx.beginPath();
	_Button2_ctx.arc(_buttonCanvasHalfWidth, _buttonCanvasHalfWidth, _buttonCanvasHalfWidth - 1, 0, Math.PI * 2);
	_Button2_ctx.stroke();
	*/
	
	//create button3
	button3Element = document.createElement('canvas');
	button3Element.width = _buttonCanvasWidth;
	button3Element.height = _buttonCanvasReducedWidth; // for Triangle Button
	//button3Element.height = _buttonCanvasWidth; // for Circle Button
		
	_container.appendChild(button3Element);	
	button3Element.style.position = "absolute";
	button3Element.style.display = "none";
	button3Element.style.zIndex = "10";
	button3Pressed = false;

	_Button3_ctx = button3Element.getContext('2d');
	_Button3_ctx.strokeStyle = 'rgba(255,255,255,0.2)';
	_Button3_ctx.lineWidth = 3;
	
	// Triangle Button
	_Button3_ctx.beginPath();
	_Button3_ctx.moveTo(_buttonCanvasHalfWidth, 0);
	_Button3_ctx.lineTo(0, _buttonCanvasReducedWidth);
	_Button3_ctx.lineTo(_buttonCanvasWidth, _buttonCanvasReducedWidth);
	_Button3_ctx.closePath();
	_Button3_ctx.stroke();
	
	/*
	// Circle Button
	_Button3_ctx.beginPath();
	_Button3_ctx.arc(_buttonCanvasHalfWidth, _buttonCanvasHalfWidth, _buttonCanvasHalfWidth - 8, 0, Math.PI * 2);
	_Button3_ctx.stroke();
	_Button3_ctx.lineWidth = 1;
	_Button3_ctx.beginPath();
	_Button3_ctx.arc(_buttonCanvasHalfWidth, _buttonCanvasHalfWidth, _buttonCanvasHalfWidth - 1, 0, Math.PI * 2);
	_Button3_ctx.stroke();
	*/
	
	//create button4
	button4Element = document.createElement('canvas');
	button4Element.width = _buttonCanvasWidth;
	button4Element.height = _buttonCanvasReducedWidth; // for Triangle Button
	//button4Element.height = _buttonCanvasWidth; // for Circle Button
	
	_container.appendChild(button4Element);	
	button4Element.style.position = "absolute";
	button4Element.style.display = "none";
	button4Element.style.zIndex = "10";
	button4Pressed = false;

	_Button4_ctx = button4Element.getContext('2d');
	_Button4_ctx.strokeStyle = 'rgba(255,255,255,0.2)';
	_Button4_ctx.lineWidth = 3;
	
	// Triangle Button
	_Button4_ctx.beginPath();
	_Button4_ctx.moveTo(_buttonCanvasHalfWidth, _buttonCanvasReducedWidth);
	_Button4_ctx.lineTo(_buttonCanvasWidth, 0);
	_Button4_ctx.lineTo(0, 0);
	_Button4_ctx.closePath();
	_Button4_ctx.stroke();
	
	/*
	// Circle Button
	_Button4_ctx.beginPath();
	_Button4_ctx.arc(_buttonCanvasHalfWidth, _buttonCanvasHalfWidth, _buttonCanvasHalfWidth - 8, 0, Math.PI * 2);
	_Button4_ctx.stroke();
	_Button4_ctx.lineWidth = 1;
	_Button4_ctx.beginPath();
	_Button4_ctx.arc(_buttonCanvasHalfWidth, _buttonCanvasHalfWidth, _buttonCanvasHalfWidth - 1, 0, Math.PI * 2);
	_Button4_ctx.stroke();
	*/
	
	//create button5
	button5Element = document.createElement('canvas');
	button5Element.width = _smallButtonCanvasWidth;
	button5Element.height = _smallButtonCanvasReducedWidth; // for Triangle Button
	//button5Element.height = _smallButtonCanvasWidth; // for Circle Button
		
	_container.appendChild(button5Element);	
	button5Element.style.position = "absolute";
	button5Element.style.display = "none";
	button5Element.style.zIndex = "10";
	button5Pressed = false;

	_Button5_ctx = button5Element.getContext('2d');
	_Button5_ctx.strokeStyle = 'rgba(255,255,255,0.2)';
	_Button5_ctx.lineWidth = 3;
	
	// Triangle Button
	_Button5_ctx.beginPath();
	_Button5_ctx.moveTo(_smallButtonCanvasHalfWidth, 0);
	_Button5_ctx.lineTo(0, _smallButtonCanvasReducedWidth);
	_Button5_ctx.lineTo(_smallButtonCanvasWidth, _smallButtonCanvasReducedWidth);
	_Button5_ctx.closePath();
	_Button5_ctx.stroke();
	
	/*
	// Circle Button
	_Button5_ctx.beginPath();
	_Button5_ctx.arc(_smallButtonCanvasHalfWidth, _smallButtonCanvasHalfWidth, _smallButtonCanvasHalfWidth - 8, 0, Math.PI * 2);
	_Button5_ctx.stroke();
	_Button5_ctx.lineWidth = 1;
	_Button5_ctx.beginPath();
	_Button5_ctx.arc(_smallButtonCanvasHalfWidth, _smallButtonCanvasHalfWidth, _smallButtonCanvasHalfWidth - 1, 0, Math.PI * 2);
	_Button5_ctx.stroke();
	*/
	
	//create button6
	button6Element = document.createElement('canvas');
	button6Element.width = _smallButtonCanvasWidth;
	button6Element.height = _smallButtonCanvasReducedWidth; // for Triangle Button
	//button6Element.height = _buttonCanvasWidth; // for Circle Button
	
	_container.appendChild(button6Element);	
	button6Element.style.position = "absolute";
	button6Element.style.display = "none";
	button6Element.style.zIndex = "10";
	button6Pressed = false;

	_Button6_ctx = button6Element.getContext('2d');
	_Button6_ctx.strokeStyle = 'rgba(255,255,255,0.2)';
	_Button6_ctx.lineWidth = 3;
	
	// Triangle Button
	_Button6_ctx.beginPath();
	_Button6_ctx.moveTo(_smallButtonCanvasHalfWidth, _smallButtonCanvasReducedWidth);
	_Button6_ctx.lineTo(_smallButtonCanvasWidth, 0);
	_Button6_ctx.lineTo(0, 0);
	_Button6_ctx.closePath();
	_Button6_ctx.stroke();
	
	/*
	// Circle Button
	_Button6_ctx.beginPath();
	_Button6_ctx.arc(_smallButtonCanvasHalfWidth, _smallButtonCanvasHalfWidth, _smallButtonCanvasHalfWidth - 8, 0, Math.PI * 2);
	_Button6_ctx.stroke();
	_Button6_ctx.lineWidth = 1;
	_Button6_ctx.beginPath();
	_Button6_ctx.arc(_smallButtonCanvasHalfWidth, _smallButtonCanvasHalfWidth, _smallButtonCanvasHalfWidth - 1, 0, Math.PI * 2);
	_Button6_ctx.stroke();
	*/
	
	// options
	_showJoystick = opts.showJoystick || false;
	_showButtons = opts.showButtons || true;
	if('createTouch' in document) _showButtons = true;
	_enableMultiTouch = opts.enableMultiTouch || false;
	
	_stationaryBase = opts.stationaryBase || false;
	_baseX = _stickX = opts.baseX || 100;
	_baseY = _stickY = opts.baseY || 200;

	_limitStickTravel = opts.limitStickTravel || false;
	if (_limitStickTravel || _stationaryBase) _showJoystick = true;
	if (_stationaryBase) _limitStickTravel = true;
	_stickRadius = opts.stickRadius || 50;
	if (_stickRadius > 100) _stickRadius = 100;

	if (_stationaryBase) {
		baseElement.style.display = "";
		baseElement.style.left = (_baseX - baseElement.width / 2) + "px";
		baseElement.style.top = (_baseY - baseElement.height / 2) + "px";
		stickElement.style.display = "";
		stickElement.style.left = (_baseX - stickElement.width / 2) + "px";
		stickElement.style.top = (_baseY - stickElement.height / 2) + "px";
	}
	
	_container.addEventListener('touchstart', _onTouchStart, false);
	_container.addEventListener('touchend', _onTouchEnd, false);
	_container.addEventListener('touchmove', _onTouchMove, false);	

};


function _move(style, x, y) {
	style.left = x + 'px';
	style.top = y + 'px';
}

function _onButton1Down() {
	button1Pressed = true;
	
	_Button1_ctx.strokeStyle = 'rgba(255,255,255,0.5)';
	_Button1_ctx.lineWidth = 3;
	
	// Triangle Button
	_Button1_ctx.beginPath();
	_Button1_ctx.moveTo(0, _buttonCanvasHalfWidth);
	_Button1_ctx.lineTo(_buttonCanvasReducedWidth, _buttonCanvasWidth);
	_Button1_ctx.lineTo(_buttonCanvasReducedWidth, 0);
	_Button1_ctx.closePath();
	_Button1_ctx.stroke();
	
	/*
	// Circle Button
	_Button1_ctx.beginPath();
	_Button1_ctx.arc(_buttonCanvasHalfWidth, _buttonCanvasHalfWidth, _buttonCanvasHalfWidth - 8, 0, Math.PI * 2);
	_Button1_ctx.stroke();
	_Button1_ctx.strokeStyle = 'rgba(255,255,255,0.2)';
	_Button1_ctx.lineWidth = 1;
	_Button1_ctx.beginPath();
	_Button1_ctx.arc(_buttonCanvasHalfWidth, _buttonCanvasHalfWidth, _buttonCanvasHalfWidth - 1, 0, Math.PI * 2);
	_Button1_ctx.stroke();
	*/
}

function _onButton1Up() {
	button1Pressed = false;
	
	_Button1_ctx.clearRect(0, 0, _buttonCanvasWidth, _buttonCanvasWidth);
	_Button1_ctx.strokeStyle = 'rgba(255,255,255,0.2)';
	_Button1_ctx.lineWidth = 3;
	
	// Triangle Button
	_Button1_ctx.beginPath();
	_Button1_ctx.moveTo(0, _buttonCanvasHalfWidth);
	_Button1_ctx.lineTo(_buttonCanvasReducedWidth, _buttonCanvasWidth);
	_Button1_ctx.lineTo(_buttonCanvasReducedWidth, 0);
	_Button1_ctx.closePath();
	_Button1_ctx.stroke();
	
	/*
	// Circle Button
	_Button1_ctx.beginPath();
	_Button1_ctx.arc(_buttonCanvasHalfWidth, _buttonCanvasHalfWidth, _buttonCanvasHalfWidth - 8, 0, Math.PI * 2);
	_Button1_ctx.stroke();
	_Button1_ctx.lineWidth = 1;
	_Button1_ctx.beginPath();
	_Button1_ctx.arc(_buttonCanvasHalfWidth, _buttonCanvasHalfWidth, _buttonCanvasHalfWidth - 1, 0, Math.PI * 2);
	_Button1_ctx.stroke();
	*/
}

function _onButton2Down() {
	button2Pressed = true;
	
	_Button2_ctx.strokeStyle = 'rgba(255,255,255,0.5)';
	_Button2_ctx.lineWidth = 3;
	
	// Triangle Button
	_Button2_ctx.beginPath();
	_Button2_ctx.moveTo(_buttonCanvasReducedWidth, _buttonCanvasHalfWidth);
	_Button2_ctx.lineTo(0, 0);
	_Button2_ctx.lineTo(0, _buttonCanvasWidth);
	_Button2_ctx.closePath();
	_Button2_ctx.stroke();
	
	/*
	// Circle Button
	_Button2_ctx.beginPath();
	_Button2_ctx.arc(_buttonCanvasHalfWidth, _buttonCanvasHalfWidth, _buttonCanvasHalfWidth - 8, 0, Math.PI * 2);
	_Button2_ctx.stroke();
	_Button2_ctx.strokeStyle = 'rgba(255,255,255,0.2)';
	_Button2_ctx.lineWidth = 1;
	_Button2_ctx.beginPath();
	_Button2_ctx.arc(_buttonCanvasHalfWidth, _buttonCanvasHalfWidth, _buttonCanvasHalfWidth - 1, 0, Math.PI * 2);
	_Button2_ctx.stroke();
	*/
}

function _onButton2Up() {
	button2Pressed = false;
	
	_Button2_ctx.clearRect(0, 0, _buttonCanvasWidth, _buttonCanvasWidth);
	_Button2_ctx.strokeStyle = 'rgba(255,255,255,0.2)';
	_Button2_ctx.lineWidth = 3;
	
	// Triangle Button
	_Button2_ctx.beginPath();
	_Button2_ctx.moveTo(_buttonCanvasReducedWidth, _buttonCanvasHalfWidth);
	_Button2_ctx.lineTo(0, 0);
	_Button2_ctx.lineTo(0, _buttonCanvasWidth);
	_Button2_ctx.closePath();
	_Button2_ctx.stroke();
	
	/*
	// Circle Button
	_Button2_ctx.beginPath();
	_Button2_ctx.arc(_buttonCanvasHalfWidth, _buttonCanvasHalfWidth, _buttonCanvasHalfWidth - 8, 0, Math.PI * 2);
	_Button2_ctx.stroke();
	_Button2_ctx.lineWidth = 1;
	_Button2_ctx.beginPath();
	_Button2_ctx.arc(_buttonCanvasHalfWidth, _buttonCanvasHalfWidth, _buttonCanvasHalfWidth - 1, 0, Math.PI * 2);
	_Button2_ctx.stroke();
	*/
}

function _onButton3Down() {
	button3Pressed = true;
	
	_Button3_ctx.strokeStyle = 'rgba(255,255,255,0.5)';
	_Button3_ctx.lineWidth = 3;
	
	// Triangle Button
	_Button3_ctx.beginPath();
	_Button3_ctx.moveTo(_buttonCanvasHalfWidth, 0);
	_Button3_ctx.lineTo(0, _buttonCanvasReducedWidth);
	_Button3_ctx.lineTo(_buttonCanvasWidth, _buttonCanvasReducedWidth);
	_Button3_ctx.closePath();
	_Button3_ctx.stroke();
	
	/*
	// Circle Button
	_Button3_ctx.beginPath();
	_Button3_ctx.arc(_buttonCanvasHalfWidth, _buttonCanvasHalfWidth, _buttonCanvasHalfWidth - 8, 0, Math.PI * 2);
	_Button3_ctx.stroke();
	_Button3_ctx.strokeStyle = 'rgba(255,255,255,0.2)';
	_Button3_ctx.lineWidth = 1;
	_Button3_ctx.beginPath();
	_Button3_ctx.arc(_buttonCanvasHalfWidth, _buttonCanvasHalfWidth, _buttonCanvasHalfWidth - 1, 0, Math.PI * 2);
	_Button3_ctx.stroke();
	*/
}

function _onButton3Up() {
	button3Pressed = false;
	
	_Button3_ctx.clearRect(0, 0, _buttonCanvasWidth, _buttonCanvasWidth);
	_Button3_ctx.strokeStyle = 'rgba(255,255,255,0.2)';
	_Button3_ctx.lineWidth = 3;
	
	// Triangle Button
	_Button3_ctx.beginPath();
	_Button3_ctx.moveTo(_buttonCanvasHalfWidth, 0);
	_Button3_ctx.lineTo(0, _buttonCanvasReducedWidth);
	_Button3_ctx.lineTo(_buttonCanvasWidth, _buttonCanvasReducedWidth);
	_Button3_ctx.closePath();
	_Button3_ctx.stroke();
	
	/*
	// Circle Button
	_Button3_ctx.beginPath();
	_Button3_ctx.arc(_buttonCanvasHalfWidth, _buttonCanvasHalfWidth, _buttonCanvasHalfWidth - 8, 0, Math.PI * 2);
	_Button3_ctx.stroke();
	_Button3_ctx.lineWidth = 1;
	_Button3_ctx.beginPath();
	_Button3_ctx.arc(_buttonCanvasHalfWidth, _buttonCanvasHalfWidth, _buttonCanvasHalfWidth - 1, 0, Math.PI * 2);
	_Button3_ctx.stroke();
	*/
}

function _onButton4Down() {
	button4Pressed = true;
	
	_Button4_ctx.strokeStyle = 'rgba(255,255,255,0.5)';
	_Button4_ctx.lineWidth = 3;
	
	// Triangle Button
	_Button4_ctx.beginPath();
	_Button4_ctx.moveTo(_buttonCanvasHalfWidth, _buttonCanvasReducedWidth);
	_Button4_ctx.lineTo(_buttonCanvasWidth, 0);
	_Button4_ctx.lineTo(0, 0);
	_Button4_ctx.closePath();
	_Button4_ctx.stroke();
	
	/*
	// Circle Button
	_Button4_ctx.beginPath();
	_Button4_ctx.arc(_buttonCanvasHalfWidth, _buttonCanvasHalfWidth, _buttonCanvasHalfWidth - 8, 0, Math.PI * 2);
	_Button4_ctx.stroke();
	_Button4_ctx.strokeStyle = 'rgba(255,255,255,0.2)';
	_Button4_ctx.lineWidth = 1;
	_Button4_ctx.beginPath();
	_Button4_ctx.arc(_buttonCanvasHalfWidth, _buttonCanvasHalfWidth, _buttonCanvasHalfWidth - 1, 0, Math.PI * 2);
	_Button4_ctx.stroke();
	*/
}

function _onButton4Up() {
	button4Pressed = false;
	
	_Button4_ctx.clearRect(0, 0, _buttonCanvasWidth, _buttonCanvasWidth);
	_Button4_ctx.strokeStyle = 'rgba(255,255,255,0.2)';
	_Button4_ctx.lineWidth = 3;
	
	// Triangle Button
	_Button4_ctx.beginPath();
	_Button4_ctx.moveTo(_buttonCanvasHalfWidth, _buttonCanvasReducedWidth);
	_Button4_ctx.lineTo(_buttonCanvasWidth, 0);
	_Button4_ctx.lineTo(0, 0);
	_Button4_ctx.closePath();
	_Button4_ctx.stroke();
	
	/*
	// Circle Button
	_Button4_ctx.beginPath();
	_Button4_ctx.arc(_buttonCanvasHalfWidth, _buttonCanvasHalfWidth, _buttonCanvasHalfWidth - 8, 0, Math.PI * 2);
	_Button4_ctx.stroke();
	_Button4_ctx.lineWidth = 1;
	_Button4_ctx.beginPath();
	_Button4_ctx.arc(_buttonCanvasHalfWidth, _buttonCanvasHalfWidth, _buttonCanvasHalfWidth - 1, 0, Math.PI * 2);
	_Button4_ctx.stroke();
	*/
}

function _onButton5Down() {
	button5Pressed = true;
	
	_Button5_ctx.strokeStyle = 'rgba(255,255,255,0.5)';
	_Button5_ctx.lineWidth = 3;
	
	// Triangle Button
	_Button5_ctx.beginPath();
	_Button5_ctx.moveTo(_smallButtonCanvasHalfWidth, 0);
	_Button5_ctx.lineTo(0, _smallButtonCanvasReducedWidth);
	_Button5_ctx.lineTo(_smallButtonCanvasWidth, _smallButtonCanvasReducedWidth);
	_Button5_ctx.closePath();
	_Button5_ctx.stroke();
	
	/*
	// Circle Button
	_Button5_ctx.beginPath();
	_Button5_ctx.arc(_smallButtonCanvasHalfWidth, _smallButtonCanvasHalfWidth, _smallButtonCanvasHalfWidth - 8, 0, Math.PI * 2);
	_Button5_ctx.stroke();
	_Button5_ctx.lineWidth = 1;
	_Button5_ctx.beginPath();
	_Button5_ctx.arc(_smallButtonCanvasHalfWidth, _smallButtonCanvasHalfWidth, _smallButtonCanvasHalfWidth - 1, 0, Math.PI * 2);
	_Button5_ctx.stroke();
	*/
}

function _onButton5Up() {
	button5Pressed = false;
	
	_Button5_ctx.clearRect(0, 0, _smallButtonCanvasWidth, _smallButtonCanvasWidth);
	_Button5_ctx.strokeStyle = 'rgba(255,255,255,0.2)';
	_Button5_ctx.lineWidth = 3;
	
	// Triangle Button
	_Button5_ctx.beginPath();
	_Button5_ctx.moveTo(_smallButtonCanvasHalfWidth, 0);
	_Button5_ctx.lineTo(0, _smallButtonCanvasReducedWidth);
	_Button5_ctx.lineTo(_smallButtonCanvasWidth, _smallButtonCanvasReducedWidth);
	_Button5_ctx.closePath();
	_Button5_ctx.stroke();
	
	/*
	// Circle Button
	_Button5_ctx.beginPath();
	_Button5_ctx.arc(_smallButtonCanvasHalfWidth, _smallButtonCanvasHalfWidth, _smallButtonCanvasHalfWidth - 8, 0, Math.PI * 2);
	_Button5_ctx.stroke();
	_Button5_ctx.lineWidth = 1;
	_Button5_ctx.beginPath();
	_Button5_ctx.arc(_smallButtonCanvasHalfWidth, _smallButtonCanvasHalfWidth, _smallButtonCanvasHalfWidth - 1, 0, Math.PI * 2);
	_Button5_ctx.stroke();
	*/
}

function _onButton6Down() {
	button6Pressed = true;
	
	_Button6_ctx.strokeStyle = 'rgba(255,255,255,0.5)';
	_Button6_ctx.lineWidth = 3;
	
	// Triangle Button
	_Button6_ctx.beginPath();
	_Button6_ctx.moveTo(_smallButtonCanvasHalfWidth, _smallButtonCanvasReducedWidth);
	_Button6_ctx.lineTo(_smallButtonCanvasWidth, 0);
	_Button6_ctx.lineTo(0, 0);
	_Button6_ctx.closePath();
	_Button6_ctx.stroke();
	
	/*
	// Circle Button
	_Button6_ctx.beginPath();
	_Button6_ctx.arc(_smallButtonCanvasHalfWidth, _smallButtonCanvasHalfWidth, _smallButtonCanvasHalfWidth - 8, 0, Math.PI * 2);
	_Button6_ctx.stroke();
	_Button6_ctx.lineWidth = 1;
	_Button6_ctx.beginPath();
	_Button6_ctx.arc(_smallButtonCanvasHalfWidth, _smallButtonCanvasHalfWidth, _smallButtonCanvasHalfWidth - 1, 0, Math.PI * 2);
	_Button6_ctx.stroke();
	*/
}

function _onButton6Up() {
	button6Pressed = false;
	
	_Button6_ctx.clearRect(0, 0, _smallButtonCanvasWidth, _smallButtonCanvasWidth);
	_Button6_ctx.strokeStyle = 'rgba(255,255,255,0.2)';
	_Button6_ctx.lineWidth = 3;
	
	// Triangle Button
	_Button6_ctx.beginPath();
	_Button6_ctx.moveTo(_smallButtonCanvasHalfWidth, _smallButtonCanvasReducedWidth);
	_Button6_ctx.lineTo(_smallButtonCanvasWidth, 0);
	_Button6_ctx.lineTo(0, 0);
	_Button6_ctx.closePath();
	_Button6_ctx.stroke();
	
	/*
	// Circle Button
	_Button6_ctx.beginPath();
	_Button6_ctx.arc(_smallButtonCanvasHalfWidth, _smallButtonCanvasHalfWidth, _smallButtonCanvasHalfWidth - 8, 0, Math.PI * 2);
	_Button6_ctx.stroke();
	_Button6_ctx.lineWidth = 1;
	_Button6_ctx.beginPath();
	_Button6_ctx.arc(_smallButtonCanvasHalfWidth, _smallButtonCanvasHalfWidth, _smallButtonCanvasHalfWidth - 1, 0, Math.PI * 2);
	_Button6_ctx.stroke();
	*/
}


function _onTouchStart( event ) {

	event.preventDefault();
	
	_testTouch = event.changedTouches[0];
	if (_testTouch.target == button1Element) {
		return _onButton1Down();
	}
	else if (_testTouch.target == button2Element) {
		return _onButton2Down();
	}
	else if (_testTouch.target == button3Element) {
		return _onButton3Down();
	}
	else if (_testTouch.target == button4Element) {
		return _onButton4Down();
	}
	else if (_testTouch.target == button5Element) {
		return _onButton5Down();
	}
	else if (_testTouch.target == button6Element) {
		return _onButton6Down();
	}
	
	_touches = event.touches;
	joystickPressed = true;

	if (_touches.length == 1) {
		_stickX = _testTouch.pageX;
		_stickY = _testTouch.pageY;
	}
	if (_touches.length == 2) {
		
		_stickX = _testTouch.pageX;
		_stickY = _testTouch.pageY;
		
		joystickDeltaX = _stickX - _baseX;
		joystickDeltaY = _stickY - _baseY;
	
	}
	
	if (!_stationaryBase) {
		joystickDeltaX = joystickDeltaY = 0;
		_baseX = _stickX;
		_baseY = _stickY;
		if (_showJoystick) {
			baseElement.style.display = "";
			_move(baseElement.style, (_baseX - baseElement.width / 2), (_baseY - baseElement.height / 2));
		}
	}
	
	if (_limitStickTravel) {
		_stickDistance = Math.sqrt((joystickDeltaX * joystickDeltaX) + (joystickDeltaY * joystickDeltaY));
		
		if (_stickDistance > _stickRadius) {
			_stickNormalizedX = joystickDeltaX / _stickDistance;
			_stickNormalizedY = joystickDeltaY / _stickDistance;
			
			_stickX = _stickNormalizedX * _stickRadius + _baseX;
			_stickY = _stickNormalizedY * _stickRadius + _baseY;
			
			joystickDeltaX = _stickX - _baseX;
			joystickDeltaY = _stickY - _baseY;
		}
	}
	
	if (_showJoystick) {
		stickElement.style.display = "";
		_move(stickElement.style, (_stickX - stickElement.width / 2), (_stickY - stickElement.height / 2));
	}
		
}

function _onTouchEnd( event ) {
  
	event.preventDefault();
	
	_testTouch = event.changedTouches[0];
	if (_testTouch.target == button1Element) 
		return _onButton1Up();
	else if (_testTouch.target == button2Element) 
		return _onButton2Up();
	else if (_testTouch.target == button3Element) 
		return _onButton3Up();
	else if (_testTouch.target == button4Element) 
		return _onButton4Up();
	else if (_testTouch.target == button5Element) 
		return _onButton5Up();
	else if (_testTouch.target == button6Element) 
		return _onButton6Up();

	joystickPressed = false;
	joystickDeltaX = joystickDeltaY = 0;
	
	_touches = event.touches;
	
	if (_stationaryBase) {
		_stickX = _baseX;
		_stickY = _baseY;
		if (_touches.length > 1) {
				
			_stickX = _touches[1].pageX;
			_stickY = _touches[1].pageY;
			
		}
	}
	
	if (!_stationaryBase) {
		baseElement.style.display = "none";
		stickElement.style.display = "none";
		
		if (_touches.length > 1) {
				
			_stickX = _baseX = _touches[1].pageX;
			_stickY = _baseY = _touches[1].pageY;
			
		}
	}
	
	if (_showJoystick) {
		_move(stickElement.style, (_stickX - stickElement.width / 2), (_stickY - stickElement.height / 2));
	}
	
}

function _onTouchMove( event ) {

	event.preventDefault();
	
	_testTouch = event.changedTouches[0];

	if ( _testTouch.target == button1Element || _testTouch.target == button2Element || 
	     _testTouch.target == button3Element || _testTouch.target == button4Element ||
	     _testTouch.target == button5Element || _testTouch.target == button6Element ) {

		return;
	}
	_touches = event.touches;
	
	if (_touches.length == 1) {
		if ( _touches[0].target != button1Element && _touches[0].target != button2Element && 
		     _touches[0].target != button3Element && _touches[0].target != button4Element && 
		     _touches[0].target != button5Element && _touches[0].target != button6Element ) {

			_stickX = _touches[0].pageX;
			_stickY = _touches[0].pageY;
		}

	}
	if (_touches.length == 2) {
		
		if ( _touches[0].target == button1Element || _touches[0].target == button2Element || 
		     _touches[0].target == button3Element || _touches[0].target == button4Element ||
		     _touches[0].target == button5Element || _touches[0].target == button6Element ) {

			_stickX = _touches[1].pageX;
			_stickY = _touches[1].pageY;
		}
	    	else if (_touches[1].target == button1Element || _touches[1].target == button2Element || 
		         _touches[1].target == button3Element || _touches[1].target == button4Element ||
		         _touches[1].target == button5Element || _touches[1].target == button6Element ) {
			
			_stickX = _touches[0].pageX;
			_stickY = _touches[0].pageY;
		}
		else if ( _enableMultiTouch ) {
			
			pinchWidthX = Math.abs(_touches[1].pageX - _touches[0].pageX);
			pinchWidthY = Math.abs(_touches[1].pageY - _touches[0].pageY);
			
		}
		
	}
	
	if (_limitStickTravel) {
		_stickDistance = Math.sqrt((joystickDeltaX * joystickDeltaX) + (joystickDeltaY * joystickDeltaY));
		
		if (_stickDistance > _stickRadius) {
			_stickNormalizedX = joystickDeltaX / _stickDistance;
			_stickNormalizedY = joystickDeltaY / _stickDistance;

			_stickX = _stickNormalizedX * _stickRadius + _baseX;
			_stickY = _stickNormalizedY * _stickRadius + _baseY;
		}
	}
	
	joystickDeltaX = _stickX - _baseX;
	joystickDeltaY = _stickY - _baseY;
	
	if (_showJoystick) {
		_move(stickElement.style, (_stickX - stickElement.width / 2), (_stickY - stickElement.height / 2));
	}
	
}
