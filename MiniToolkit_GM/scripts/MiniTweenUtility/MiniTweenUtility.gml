/* 
    MiniTween
    A simple tweening system for GameMaker
 
    Authors: M. Neet - https://github.com/mneet/MiniToolkit-GM
    Version: 2.0.0
*/


/// @function		mini_tween(_target, _duration)
/// @description	Shorthand for creating a new tween
/// @returns {Struct.MiniTween}
function mini_tween(_target, _duration)
{
	return new MiniTween(_target, _duration);
}

/// @function		mini_tween_cancel_all()
/// @description	Cancel all active tweens
function mini_tween_cancel_all()
{
	var _tweens = obj_mini_tweener.tweens;
	var _count = array_length(_tweens);
	for (var _i = 0; _i < _count; _i++)
	{
		_tweens[_i].cancel();
	}
	array_resize(obj_mini_tweener.tweens, 0);
}

/// @function		mini_tween_cancel_target(_target)
/// @description	Cancel all tweens on a specific target
/// @param {Struct|Instance} _target
function mini_tween_cancel_target(_target)
{
	var _tweens = obj_mini_tweener.tweens;
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
	var _tweens = obj_mini_tweener.tweens;
	var _count = array_length(_tweens);
	for (var _i = 0; _i < _count; _i++)
	{
		_tweens[_i].pause();
	}
}

/// @function		mini_tween_resume_all()
function mini_tween_resume_all()
{
	var _tweens = obj_mini_tweener.tweens;
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
	return array_length(obj_mini_tweener.tweens);
}
