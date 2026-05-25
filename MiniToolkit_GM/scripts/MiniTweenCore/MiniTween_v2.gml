/* MiniTween v2
   A simple, efficient tweening system for GameMaker
   Philosophy: SIMPLICITY - minimal overhead, maximum usability

   Authors: M. Neet
   Version: 2.0.0
   
   Changes from v1:
   - Simplified storage: single array instead of multiple databases
   - Fixed on_complete callback (was never called!)
   - Cleaner repeat logic with proper decrement
   - Removed redundant owner_db tracking
   - Optimized iteration with direct array access
   - Better memory management with automatic cleanup
*/

#region Settings

#macro MINI_TWEEN_TIME_SCALE 1

/// @function		mini_tween_delta_time(_time_scale)
/// @description	Get delta time in seconds, adjusted by time scale
/// @param {Real} [_time_scale]	Time multiplier (default: MINI_TWEEN_TIME_SCALE)
/// @returns {Real}	Delta time in seconds
function mini_tween_delta_time(_time_scale = MINI_TWEEN_TIME_SCALE)
{
	return (1 / game_get_speed(gamespeed_fps)) * _time_scale;
}

#endregion

#region Manager

// Global tween storage - simple array, no complex databases
global.__mini_tweens = [];
global.__mini_tween_manager = noone;

/// @function		__mini_tween_ensure_manager()
/// @description	Ensure the tween manager object exists
function __mini_tween_ensure_manager()
{
	if (!instance_exists(global.__mini_tween_manager))
	{
		global.__mini_tween_manager = instance_create_depth(0, 0, 0, obj_mini_tweener);
	}
}

/// @function		__mini_tween_process()
/// @description	Process all active tweens (called by manager each step)
function __mini_tween_process()
{
	var _tweens = global.__mini_tweens;
	var _count = array_length(_tweens);
	var _write_idx = 0;
	
	for (var _i = 0; _i < _count; _i++)
	{
		var _tween = _tweens[_i];
		
		// Process tween, check if should keep
		if (!_tween.__step())
		{
			// Tween finished/destroyed - skip (don't copy to write position)
			continue;
		}
		
		// Keep tween - copy to write position (compacts array)
		_tweens[_write_idx++] = _tween;
	}
	
	// Resize array to remove finished tweens
	if (_write_idx < _count)
	{
		array_resize(_tweens, _write_idx);
	}
}

#endregion

#region MiniTween Constructor

/// @function					MiniTween(_target, _duration, _unique)
/// @description				Create a new tween for animating properties
/// @param {Struct|Instance} _target	Target to animate
/// @param {Real} _duration			Duration in seconds
/// @param {Bool} [_unique]			Cancel conflicting tweens on same target/properties
/// @returns {Struct.MiniTween}
function MiniTween(_target, _duration = 1.0, _unique = false) constructor
{
	// Target handling - weak ref for structs, direct for instances
	__is_struct = is_struct(_target);
	__target = __is_struct ? weak_ref_create(_target) : _target;
	__unique = _unique;
	
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
	
	// Repeat/yoyo
	__repeat_count = 0;		// 0 = no repeat, -1 = infinite, N = repeat N more times
	__yoyo = false;
	__yoyo_reversed = false;
	
	// Callbacks (stored as bound methods or undefined)
	__on_start = undefined;
	__on_complete = undefined;
	__on_repeat = undefined;
	__on_cancel = undefined;
	__on_update = undefined;
	
	#region Builder Methods
	
	/// @function		tween(_property, _to, _easing)
	/// @description	Add a property to animate
	/// @param {String} _property	Property name on target
	/// @param {Real} _to			Target value
	/// @param {Real} [_easing]		Easing curve (default: SINE_IN_OUT)
	/// @returns {Struct.MiniTween}	Self for chaining
	static tween = function(_property, _to, _easing = EASING_CURVES.SINE_IN_OUT)
	{
		// Check for duplicate property
		var _count = array_length(__properties);
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
	
	/// @function		repeat(_count, _yoyo)
	/// @description	Set repeat behavior
	/// @param {Real} _count	Repeat count (0=none, -1=infinite, N=times)
	/// @param {Bool} [_yoyo]	Reverse direction each repeat
	/// @returns {Struct.MiniTween}
	static repeat = function(_count, _yoyo = false)
	{
		__repeat_count = _count;
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
	
	/// @function		on_complete(_callback)
	/// @description	Set callback for when tween completes (all repeats done)
	/// @param {Function} _callback
	/// @returns {Struct.MiniTween}
	static on_complete = function(_callback)
	{
		__on_complete = _callback;
		return self;
	}
	
	/// @function		on_repeat(_callback)
	/// @description	Set callback for each repeat cycle
	/// @param {Function} _callback
	/// @returns {Struct.MiniTween}
	static on_repeat = function(_callback)
	{
		__on_repeat = _callback;
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
	
	/// @function		on_update(_callback)
	/// @description	Set callback for each step
	/// @param {Function} _callback
	/// @returns {Struct.MiniTween}
	static on_update = function(_callback)
	{
		__on_update = _callback;
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
			var _count = array_length(__properties);
			for (var _i = 0; _i < _count; _i++)
			{
				var _prop = __properties[_i];
				__set_value(_target, _prop.name, _prop.to);
			}
		}
		
		__destroyed = true;
		if (__on_complete != undefined) __on_complete();
	}
	
	#endregion
	
	#region Internal Methods
	
	/// @function		__get_target()
	/// @description	Get target, handling weak refs
	/// @returns {Struct|Instance|undefined}
	static __get_target = function()
	{
		if (__is_struct)
		{
			return weak_ref_alive(__target) ? __target.ref : undefined;
		}
		return instance_exists(__target) ? __target : undefined;
	}
	
	/// @function		__get_value(_target, _property)
	static __get_value = function(_target, _property)
	{
		return __is_struct 
			? variable_struct_get(_target, _property) 
			: variable_instance_get(_target, _property);
	}
	
	/// @function		__set_value(_target, _property, _value)
	static __set_value = function(_target, _property, _value)
	{
		if (__is_struct)
			variable_struct_set(_target, _property, _value);
		else
			variable_instance_set(_target, _property, _value);
	}
	
	/// @function		__step()
	/// @description	Process one frame of the tween
	/// @returns {Bool}	True if tween should continue, false if done
	static __step = function()
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
			__delay_remaining -= mini_tween_delta_time();
			return true;
		}
		
		// Initialize on first real step
		if (!__started)
		{
			__started = true;
			
			// Capture starting values
			var _count = array_length(__properties);
			for (var _i = 0; _i < _count; _i++)
			{
				var _prop = __properties[_i];
				_prop.from = __get_value(_target, _prop.name);
				_prop.diff = _prop.to - _prop.from;
			}
			
			// Cancel conflicting tweens if unique
			if (__unique)
			{
				__cancel_conflicting();
			}
			
			// Callback
			if (__on_start != undefined) __on_start();
		}
		
		// Update elapsed time
		__elapsed += mini_tween_delta_time();
		var _progress = clamp(__elapsed / __duration, 0, 1);
		var _finished = (_progress >= 1);
		
		// Apply easing to all properties
		var _count = array_length(__properties);
		for (var _i = 0; _i < _count; _i++)
		{
			var _prop = __properties[_i];
			
			if (_finished)
			{
				// Snap to final value
				__set_value(_target, _prop.name, _prop.to);
			}
			else
			{
				// Apply easing
				var _value = global.easing_functions[_prop.easing](
					__elapsed, _prop.from, _prop.diff, __duration
				);
				__set_value(_target, _prop.name, _value);
			}
		}
		
		if (__on_update != undefined) __on_update();

		// Handle completion
		if (_finished)
		{
			return __handle_completion();
		}
		
		return true;
	}
	
	/// @function		__handle_completion()
	/// @description	Handle repeat/yoyo/completion logic
	/// @returns {Bool}	True if should continue, false if fully done
	static __handle_completion = function()
	{
		// Check if we should repeat
		if (__repeat_count == 0)
		{
			// No more repeats - fully complete
			__destroyed = true;
			if (__on_complete != undefined) __on_complete();
			return false;
		}
		
		// Decrement repeat count (unless infinite)
		if (__repeat_count > 0) __repeat_count--;
		
		// Reset for next cycle
		__elapsed = 0;
		
		// Handle yoyo - swap from/to
		if (__yoyo)
		{
			var _count = array_length(__properties);
			for (var _i = 0; _i < _count; _i++)
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
				var _count = array_length(__properties);
				for (var _i = 0; _i < _count; _i++)
				{
					var _prop = __properties[_i];
					__set_value(_target, _prop.name, _prop.from);
				}
			}
		}
		
		// Callback
		if (__on_repeat != undefined) __on_repeat();
		
		return true;
	}
	
	/// @function		__cancel_conflicting()
	/// @description	Cancel other tweens on same target with overlapping properties
	static __cancel_conflicting = function()
	{
		var _tweens = global.__mini_tweens;
		var _count = array_length(_tweens);
		var _my_target = __get_target();
		
		for (var _i = 0; _i < _count; _i++)
		{
			var _other = _tweens[_i];
			if (_other == self || _other.__destroyed) continue;
			
			var _other_target = _other.__get_target();
			if (_other_target != _my_target) continue;
			
			// Same target - check for property conflicts
			var _my_props = __properties;
			var _other_props = _other.__properties;
			var _my_count = array_length(_my_props);
			var _other_count = array_length(_other_props);
			
			for (var _j = 0; _j < _my_count; _j++)
			{
				for (var _k = 0; _k < _other_count; _k++)
				{
					if (_my_props[_j].name == _other_props[_k].name)
					{
						_other.cancel();
						break;
					}
				}
				if (_other.__destroyed) break;
			}
		}
	}
	
	/// @function		__has_property(_name)
	/// @returns {Bool}
	static __has_property = function(_name)
	{
		var _count = array_length(__properties);
		for (var _i = 0; _i < _count; _i++)
		{
			if (__properties[_i].name == _name) return true;
		}
		return false;
	}
	
	#endregion
	
	// Auto-register with manager
	__mini_tween_ensure_manager();
	array_push(global.__mini_tweens, self);
}

#endregion

#region Utility Functions

/// @function		mini_tween(_target, _duration, _unique)
/// @description	Shorthand for creating a new tween
/// @returns {Struct.MiniTween}
function mini_tween(_target, _duration, _unique = false)
{
	return new MiniTween(_target, _duration, _unique);
}

/// @function		mini_tween_cancel_all()
/// @description	Cancel all active tweens
function mini_tween_cancel_all()
{
	var _tweens = global.__mini_tweens;
	var _count = array_length(_tweens);
	for (var _i = 0; _i < _count; _i++)
	{
		_tweens[_i].cancel();
	}
	array_resize(global.__mini_tweens, 0);
}

/// @function		mini_tween_cancel_target(_target)
/// @description	Cancel all tweens on a specific target
/// @param {Struct|Instance} _target
function mini_tween_cancel_target(_target)
{
	var _tweens = global.__mini_tweens;
	var _count = array_length(_tweens);
	
	for (var _i = 0; _i < _count; _i++)
	{
		var _tween = _tweens[_i];
		if (_tween.__get_target() == _target)
		{
			_tween.cancel();
		}
	}
}

/// @function		mini_tween_pause_all()
function mini_tween_pause_all()
{
	var _tweens = global.__mini_tweens;
	var _count = array_length(_tweens);
	for (var _i = 0; _i < _count; _i++)
	{
		_tweens[_i].pause();
	}
}

/// @function		mini_tween_resume_all()
function mini_tween_resume_all()
{
	var _tweens = global.__mini_tweens;
	var _count = array_length(_tweens);
	for (var _i = 0; _i < _count; _i++)
	{
		_tweens[_i].resume();
	}
}

/// @function		mini_tween_count()
/// @description	Get number of active tweens
/// @returns {Real}
function mini_tween_count()
{
	return array_length(global.__mini_tweens);
}

#endregion

#region Shortcut Functions

/// @function		mini_tween_to(_target, _duration, _props, _easing, _unique)
/// @description	Quick tween with struct of property:value pairs
/// @param {Struct|Instance} _target
/// @param {Real} _duration
/// @param {Struct} _props		{property_name: target_value, ...}
/// @param {Real} [_easing]
/// @param {Bool} [_unique]
/// @returns {Struct.MiniTween}
function mini_tween_to(_target, _duration, _props, _easing = EASING_CURVES.SINE_IN_OUT, _unique = true)
{
	var _tween = new MiniTween(_target, _duration, _unique);
	var _names = struct_get_names(_props);
	var _count = array_length(_names);
	
	for (var _i = 0; _i < _count; _i++)
	{
		var _name = _names[_i];
		_tween.tween(_name, _props[$ _name], _easing);
	}
	
	return _tween;
}

/// @function		mini_tween_fade_in(_target, _duration, _easing)
/// @returns {Struct.MiniTween}
function mini_tween_fade_in(_target, _duration, _easing = EASING_CURVES.LINEAR)
{
	if (is_struct(_target))
		_target.image_alpha = 0;
	else
		_target.image_alpha = 0;
		
	return mini_tween(_target, _duration, true).tween("image_alpha", 1, _easing);
}

/// @function		mini_tween_fade_out(_target, _duration, _easing)
/// @returns {Struct.MiniTween}
function mini_tween_fade_out(_target, _duration, _easing = EASING_CURVES.LINEAR)
{
	return mini_tween(_target, _duration, true).tween("image_alpha", 0, _easing);
}

/// @function		mini_tween_move_to(_target, _x, _y, _duration, _easing)
/// @returns {Struct.MiniTween}
function mini_tween_move_to(_target, _x, _y, _duration, _easing = EASING_CURVES.SINE_IN_OUT)
{
	return mini_tween(_target, _duration, true)
		.tween("x", _x, _easing)
		.tween("y", _y, _easing);
}

/// @function		mini_tween_scale_to(_target, _scale_x, _scale_y, _duration, _easing)
/// @returns {Struct.MiniTween}
function mini_tween_scale_to(_target, _scale_x, _scale_y = undefined, _duration = 1.0, _easing = EASING_CURVES.SINE_IN_OUT)
{
	if (_scale_y == undefined) _scale_y = _scale_x;
	
	return mini_tween(_target, _duration, true)
		.tween("image_xscale", _scale_x, _easing)
		.tween("image_yscale", _scale_y, _easing);
}

/// @function		mini_tween_pulse(_target, _scale, _duration, _easing)
/// @description	Create infinite pulsing scale effect
/// @returns {Struct.MiniTween}
function mini_tween_pulse(_target, _scale = 1.2, _duration = 0.5, _easing = EASING_CURVES.SINE_IN_OUT)
{
	return mini_tween_scale_to(_target, _scale, _scale, _duration, _easing)
		.repeat(-1, true);
}

#endregion
