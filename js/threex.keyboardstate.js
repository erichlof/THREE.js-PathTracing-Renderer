// THREEx.KeyboardState.js keep the current state of the keyboard.
// It is possible to query it at any time. No need of an event.
// This is particularly convenient in loop driven case, like in
// 3D demos or games.

/** @namespace */
var THREEx	= THREEx 		|| {};

THREEx.KeyboardState	= function(domElement)
{
	this.domElement= domElement	|| document;
	// to store the current state
	this.keyCodes	= {};
	this.modifiers	= {};
	
	// create callback to bind/unbind keyboard events
	var _this	= this;
	this._onKeyDown	= function(event){ _this._onKeyChange(event);	};
	this._onKeyUp	= function(event){ _this._onKeyChange(event);	};

	// bind keyEvents
	this.domElement.addEventListener("keydown", this._onKeyDown, false);
	this.domElement.addEventListener("keyup", this._onKeyUp, false);
};

/**
 * To stop listening of the keyboard events
*/
THREEx.KeyboardState.prototype.destroy	= function()
{
	// unbind keyEvents
	this.domElement.removeEventListener("keydown", this._onKeyDown, false);
	this.domElement.removeEventListener("keyup", this._onKeyUp, false);
};

THREEx.KeyboardState.MODIFIERS	= ['shift', 'ctrl', 'alt', 'meta'];
THREEx.KeyboardState.ALIAS	= {
	'left'		: 37,
	'up'		: 38,
	'right'		: 39,
	'down'		: 40,
	'space'		: 32,
	'pageup'	: 33,
	'pagedown'	: 34,
	'tab'		: 9,
	'dash'		: 189,
	'equals'	: 187,
	'comma'		: 188,
	'period'	: 190,
	'escape'	: 27
};

/**
 * to process the keyboard dom event
*/
THREEx.KeyboardState.prototype._onKeyChange	= function(event)
{
	// log to debug
	//console.log("onKeyChange", event, event.keyCode, event.shiftKey, event.ctrlKey, event.altKey, event.metaKey)
	event.preventDefault();
	// update this.keyCodes
	var keyCode		= event.keyCode;
	var pressed		= event.type === 'keydown' ? true : false;
	this.keyCodes[keyCode]	= pressed;
	// update this.modifiers
	this.modifiers['shift']	= event.shiftKey;
	this.modifiers['ctrl']	= event.ctrlKey;
	this.modifiers['alt']	= event.altKey;
	this.modifiers['meta']	= event.metaKey;
};

/**
 * query keyboard state to know if a key is pressed of not
 *
 * @param {String} keyDesc the description of the key. format : modifiers+key e.g shift+A
 * @returns {Boolean} true if the key is pressed, false otherwise
*/
THREEx.KeyboardState.prototype.pressed	= function(keyDesc){
	var keys	= keyDesc.split("+");
	for(var i = 0; i < keys.length; i++){
		var key		= keys[i];
		var pressed	= false;
		if( THREEx.KeyboardState.MODIFIERS.indexOf( key ) !== -1 ){
			pressed	= this.modifiers[key];
		}else if( Object.keys(THREEx.KeyboardState.ALIAS).indexOf( key ) != -1 ){
			pressed	= this.keyCodes[ THREEx.KeyboardState.ALIAS[key] ];
		}else {
			pressed	= this.keyCodes[key.toUpperCase().charCodeAt(0)];
		}
		if( !pressed)	return false;
	}
	return true;
};

/**
 * return true if an event match a keyDesc
 * @param  {KeyboardEvent} event   keyboard event
 * @param  {String} keyDesc string description of the key
 * @return {Boolean}         true if the event match keyDesc, false otherwise
 */
THREEx.KeyboardState.prototype.eventMatches = function(event, keyDesc) {
	var aliases	= THREEx.KeyboardState.ALIAS;
	var aliasKeys	= Object.keys(aliases);
	var keys	= keyDesc.split("+");
	// log to debug
	// console.log("eventMatches", event, event.keyCode, event.shiftKey, event.ctrlKey, event.altKey, event.metaKey)
	for(var i = 0; i < keys.length; i++){
		var key		= keys[i];
		var pressed	= false;
		if( key === 'shift' ){
			pressed	= (event.shiftKey	? true : false);
		}else if( key === 'ctrl' ){
			pressed	= (event.ctrlKey	? true : false);
		}else if( key === 'alt' ){
			pressed	= (event.altKey		? true : false);
		}else if( key === 'meta' ){
			pressed	= (event.metaKey	? true : false);
		}else if( aliasKeys.indexOf( key ) !== -1 ){
			pressed	= (event.keyCode === aliases[key] ? true : false);
		}else if( event.keyCode === key.toUpperCase().charCodeAt(0) ){
			pressed	= true;
		}
		if( !pressed )	return false;
	}
	return true;
};


