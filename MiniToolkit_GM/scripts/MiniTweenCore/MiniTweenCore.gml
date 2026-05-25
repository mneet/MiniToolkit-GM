/* 
    MiniTween
    A simple tweening system for GameMaker
 
    Authors: M. Neet - https://github.com/mneet/MiniToolkit-GM
    Version: 2.0.0
*/

#region Manager

/// @function		__mini_tween_ensure_manager()
/// @description	Ensure the tween manager object exists
function __mini_tween_ensure_manager()
{
	if (!instance_exists(obj_mini_tweener))
	{
		instance_create_depth(0, 0, 0, obj_mini_tweener);
	}
}

#endregion

#region MiniTween Constructor

/// @function					        MiniTween(_target, _duration)
/// @description				        Create a new tween for animating properties
/// @param {Struct|Instance} _target    Target to animate
/// @param {Real} _duration			    Duration in seconds
/// @returns {Struct.MiniTween}
function MiniTween(_target, _duration = 1.0) constructor
{
	// Target handling - weak ref for structs, direct for instances
	__is_struct = is_struct(_target);
	__target = __is_struct ? weak_ref_create(_target) : _target;
    __target_id = __is_struct ? ptr(__target.ref): ptr(_target);
    __tween_id = ptr(self);
	
	// Timing
	__duration = _duration;
	__elapsed = 0;
	__delay = 0;
	__delay_remaining = 0;
	
	// State
	__started = false;
	__paused = false;
	__destroyed = false;
	
	// Properties to tween: array of {name, from, to, diff, easing}
	__properties = [];
    __properties_amnt = 0;
	
	// loop/yoyo
	__loop_count = 0;		// 0 = no loop, -1 = infinite, N = loop N more times
	__yoyo = false;
	__yoyo_reversed = false;
	
	// Callbacks (stored as bound methods or undefined)
	__on_start = undefined;
	__on_update = undefined;
	__on_complete = undefined;
	__on_loop = undefined;
	__on_cancel = undefined;
	
	#region Builder Methods
	
	/// @function		tween(_property, _to, _easing)
	/// @description	Add a property to animate
	/// @param {String} _property	Property name on target
	/// @param {Real} _to			Target value
	/// @param {Real} [_easing]		Easing curve (default: SINE_IN_OUT)
	/// @returns {Struct.MiniTween}	Self for chaining
	static tween = function(_property, _to, _easing = MINI_TWEEN_DEFAULT_EASING)
	{
		// Check for duplicate property
		var _count = __properties_amnt;
		for (var _i = 0; _i < _count; _i++)
		{
			if (__properties[_i].name == _property)
			{
				// Update existing
				__properties[_i].to = _to;
				__properties[_i].easing = _easing;
				return self;
			}
		}
		
		// Add new property
		array_push(__properties, {
			name: _property,
			from: 0,	// Set on start
			to: _to,
			diff: 0,	// Calculated on start
			easing: _easing
		});
        __properties_amnt++;
		
		return self;
	}
	
	/// @function		delay(_seconds)
	/// @description	Set delay before tween starts
	/// @param {Real} _seconds	Delay in seconds
	/// @returns {Struct.MiniTween}
	static delay = function(_seconds)
	{
		__delay = _seconds;
		__delay_remaining = _seconds;
		return self;
	}
	
	/// @function		loop(_count, _yoyo)
	/// @description	Set loop behavior
	/// @param {Real} _count	loop count (0=none, -1=infinite, N=times)
	/// @param {Bool} [_yoyo]	Reverse direction each loop
	/// @returns {Struct.MiniTween}
	static loop = function(_count, _yoyo = false)
	{
		__loop_count = _count;
		__yoyo = _yoyo;
		return self;
	}
	
	/// @function		on_start(_callback)
	/// @description	Set callback for when tween starts (after delay)
	/// @param {Function} _callback
	/// @returns {Struct.MiniTween}
	static on_start = function(_callback)
	{
		__on_start = _callback;
		return self;
	}
	
	/// @function		on_update(_callback)
	/// @description	Set callback for each frame the tween updates values.
	///					Useful for integration with other systems (e.g., mark MiniNode transform dirty)
	/// @param {Function} _callback	Callback receives (target, progress) parameters
	/// @returns {Struct.MiniTween}
	static on_update = function(_callback)
	{
		__on_update = _callback;
		return self;
	}
	
	/// @function		on_complete(_callback)
	/// @description	Set callback for when tween completes (all loops done)
	/// @param {Function} _callback
	/// @returns {Struct.MiniTween}
	static on_complete = function(_callback)
	{
		__on_complete = _callback;
		return self;
	}
	
	/// @function		on_loop(_callback)
	/// @description	Set callback for each loop cycle
	/// @param {Function} _callback
	/// @returns {Struct.MiniTween}
	static on_loop = function(_callback)
	{
		__on_loop = _callback;
		return self;
	}
	
	/// @function		on_cancel(_callback)
	/// @description	Set callback for when tween is cancelled
	/// @param {Function} _callback
	/// @returns {Struct.MiniTween}
	static on_cancel = function(_callback)
	{
		__on_cancel = _callback;
		return self;
	}
	
	#endregion
	
	#region Control Methods
	
	/// @function		pause()
	/// @returns {Struct.MiniTween}
	static pause = function()
	{
		__paused = true;
		return self;
	}
	
	/// @function		resume()
	/// @returns {Struct.MiniTween}
	static resume = function()
	{
		__paused = false;
		return self;
	}
	
	/// @function		cancel()
	/// @description	Cancel tween and trigger on_cancel callback
	static cancel = function()
	{
		if (__destroyed) return;
		__destroyed = true;
		if (__on_cancel != undefined) __on_cancel();
	}
	
	/// @function		complete()
	/// @description	Immediately complete tween (jump to end values)
	static complete = function()
	{
		if (__destroyed) return;
		
		// Set all properties to final values
		var _target = __get_target();
		if (_target != undefined)
		{
			var _count = __properties_amnt;
			for (var _i = 0; _i < _count; _i++)
			{
				var _prop = __properties[_i];
                _target[$ _prop.name] = _prop.to;
			}
		}
		
		__destroyed = true;
		if (__on_complete != undefined) __on_complete();
	}
	
	#endregion
	
	#region Internal Methods
	
	/// @function		__get_target()
	/// @description	Get target
	/// @returns {Struct|Instance|undefined}
	static __get_target = function()
	{
		if (__is_struct)
		{
			return weak_ref_alive(__target) ? __target.ref : undefined;
		}
		return instance_exists(__target) ? __target : undefined;
	}

	/// @function		__step()
	/// @description	Process one frame of the tween
	/// @returns {Bool}	True if tween should continue, false if done
	static __step = function(_delta)
	{
		// Already destroyed?
		if (__destroyed) return false;
		
		// Target still exists?
		var _target = __get_target();
		if (_target == undefined)
		{
			__destroyed = true;
			return false;
		}
		
		// Paused?
		if (__paused) return true;
		
		// Handle delay
		if (__delay_remaining > 0)
		{
			__delay_remaining -= _delta;
			return true;
		}
		
		// Initialize on first real step
		if (!__started)
		{
			__started = true;
			
			// Capture starting values
			for (var _i = 0; _i < __properties_amnt; _i++)
			{
				var _prop = __properties[_i];
				_prop.from = _target[$ _prop.name]
				_prop.diff = _prop.to - _prop.from;
			}
			
			// Callback
			if (__on_start != undefined) __on_start();
		}
		
		// Update elapsed time
		__elapsed += _delta;
		var _progress = clamp(__elapsed / __duration, 0, 1);
		var _finished = (_progress >= 1);
		
		// Apply easing to all properties
		for (var _i = 0; _i < __properties_amnt; _i++)
		{
			var _prop = __properties[_i];
			
			if (_finished)
			{
				// Snap to final value
				_target[$ _prop.name] = _prop.to;
			}
			else
			{
				// Apply easing
				var _value = script_execute(_prop.easing,  __elapsed, _prop.from, _prop.diff, __duration);
                _target[$ _prop.name] = _value;
			}
		}
		
		// Notify on_update callback (for integration with other systems)
		if (__on_update != undefined) __on_update(_target, _progress);
		
		// Handle completion
		if (_finished)
		{
			return __handle_completion();
		}
		
		return true;
	}
	
	/// @function		__handle_completion()
	/// @description	Handle loop/yoyo/completion logic
	/// @returns {Bool}	True if should continue, false if fully done
	static __handle_completion = function()
	{
		// Check if we should loop
		if (__loop_count == 0)
		{
			// No more loops - fully complete
			__destroyed = true;
			if (__on_complete != undefined) __on_complete();
			return false;
		}
		
		// Decrement loop count (unless infinite)
		if (__loop_count > 0) __loop_count--;
		
		// Reset for next cycle
		__elapsed = 0;
		
		// Handle yoyo - swap from/to
		if (__yoyo)
		{
			for (var _i = 0; _i < __properties_amnt; _i++)
			{
				var _prop = __properties[_i];
				var _temp = _prop.from;
				_prop.from = _prop.to;
				_prop.to = _temp;
				_prop.diff = _prop.to - _prop.from;
			}
		}
		else
		{
			// Reset to starting values
			var _target = __get_target();
			if (_target != undefined)
			{
				for (var _i = 0; _i < __properties_amnt; _i++)
				{
					var _prop = __properties[_i];
                    _target[$ _prop.name] = _prop.from;
				}
			}
		}
		
		// Callback
		if (__on_loop != undefined) __on_loop();
		
		return true;
	}
	
	/// @function		__has_property(_name)
	/// @returns {Bool}
	static __has_property = function(_name)
	{
		var _count = __properties_amnt;
		for (var _i = 0; _i < _count; _i++)
		{
			if (__properties[_i].name == _name) return true;
		}
		return false;
	}
    
	#endregion
	
	// Auto-register with manager
	static _ensure = __mini_tween_ensure_manager();
	array_push(obj_mini_tweener.tweens, self);
    
}

#endregion
