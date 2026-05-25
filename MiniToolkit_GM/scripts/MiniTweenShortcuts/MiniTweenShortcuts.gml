/* 
    MiniTween
    A simple tweening system for GameMaker
 
    Authors: M. Neet - https://github.com/mneet/MiniToolkit-GM
    Version: 2.0.0
*/

/// @function		mini_tween_node(_node, _duration)
/// @description	Create a tween for a MiniNode that auto-marks transform dirty.
///					Use this when tweening MiniNode properties like local_x, local_y, etc.
/// @param {Struct.MiniNode} _node		The MiniNode to animate
/// @param {Real} [_duration]		Duration in seconds
/// @returns {Struct.MiniTween}
function mini_tween_node(_node, _duration = 1.0)
{
	return mini_tween(_node.local_transform, _duration)
		.on_update(function(_target, _progress) {
			_target.owner.__mark_transform_dirty();
		});
}

/// @function		mini_tween_to(_target, _duration, _props, _easing)
/// @description	Quick tween with struct of property:value pairs
/// @param {Struct|Instance} _target
/// @param {Real} _duration
/// @param {Struct} _props		{property_name: target_value, ...}
/// @param {Real} [_easing]
/// @returns {Struct.MiniTween}
function mini_tween_to(_target, _duration, _props, _easing = MINI_TWEEN_DEFAULT_EASING)
{
	var _tween = new MiniTween(_target, _duration);
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
function mini_tween_fade_in(_target, _duration, _easing = EaseOutSine)
{
    _target[$ "image_alpha"] = 0;
    
	return mini_tween(_target, _duration)
        .tween("image_alpha", 1, _easing);
}

/// @function		mini_tween_fade_out(_target, _duration, _easing)
/// @returns {Struct.MiniTween}
function mini_tween_fade_out(_target, _duration, _easing = EaseOutSine)
{
	return mini_tween(_target, _duration)
        .tween("image_alpha", 0, _easing);
}

/// @function		mini_tween_move_to(_target, _x, _y, _duration, _easing)
/// @returns {Struct.MiniTween}
function mini_tween_move_to(_target, _x, _y, _duration, _easing = EaseOutSine)
{
	return mini_tween(_target, _duration)
		.tween("x", _x, _easing)
		.tween("y", _y, _easing);
}

/// @function		mini_tween_scale_to(_target, _scale_x, _scale_y, _duration, _easing)
/// @returns {Struct.MiniTween}
function mini_tween_scale_to(_target, _scale_x, _scale_y = _scale_x, _duration = 1.0, _easing = EaseOutSine)
{
	return mini_tween(_target, _duration)
		.tween("image_xscale", _scale_x, _easing)
		.tween("image_yscale", _scale_y, _easing);
}

/// @function		mini_tween_pulse(_target, _scale, _duration, _easing)
/// @description	Create infinite pulsing scale effect
/// @returns {Struct.MiniTween}
function mini_tween_pulse(_target, _scale = 1.2, _duration = 0.5, _easing = EaseOutSine)
{
	return mini_tween_scale_to(_target, _scale, _scale, _duration, _easing)
		.loop(-1, true);
}

/// @function		mini_tween_flexi(_proxy, _duration)
/// @description	Create a tween targeting a FlexiElement's local_transform.
/// @param {Struct.FlexiElement} _proxy	The Element to animate
/// @param {Real} [_duration]		Duration in seconds
/// @returns {Struct.MiniTween}
function mini_tween_flexi(_proxy, _duration = 1.0)
{
	return mini_tween(_proxy.local_transform, _duration)
		.on_update(method({ proxy: _proxy }, function() {
				proxy.__fi_transform_dirty = true;
		}));
}
