/* 
    MiniTween
    A simple tweening system for GameMaker
 
    Authors: M. Neet - https://github.com/mneet/MiniToolkit-GM
    Version: 2.0.1
*/


/// @function		mini_tween(_target, _duration)
/// @description	Shorthand for creating a new tween
/// @returns {Struct.MiniTween}
function mini_tween(_target, _duration)
{
	return new MiniTween(_target, _duration);
}

/// @function		mini_tween_cancel_all()
/// @description	Cancel all active tweens (on_cancel fires for each; tweens created inside on_cancel are kept)
function mini_tween_cancel_all()
{
	var _tweens = __mini_tween_snapshot();
	var _count = array_length(_tweens);
	for (var _i = 0; _i < _count; _i++)
	{
		_tweens[_i].cancel();
	}
	// Cancelled tweens are removed by the manager on its next step
}

/// @function		mini_tween_cancel_target(_target)
/// @description	Cancel all tweens on a specific target
/// @param {Struct|Instance} _target
function mini_tween_cancel_target(_target)
{
	var _tweens = __mini_tween_snapshot();
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
	var _tweens = __mini_tween_manager().tweens;
	var _count = array_length(_tweens);
	for (var _i = 0; _i < _count; _i++)
	{
		_tweens[_i].pause();
	}
}

/// @function		mini_tween_resume_all()
function mini_tween_resume_all()
{
	var _tweens = __mini_tween_manager().tweens;
	var _count = array_length(_tweens);
	for (var _i = 0; _i < _count; _i++)
	{
		_tweens[_i].resume();
	}
}

/// @function		mini_tween_count()
/// @description	Get number of active tweens (cancelled/completed ones awaiting removal are not counted)
/// @returns {Real}
function mini_tween_count()
{
	var _tweens = __mini_tween_manager().tweens;
	var _count = array_length(_tweens);
	var _active = 0;
	for (var _i = 0; _i < _count; _i++)
	{
		if (!_tweens[_i].__destroyed) _active++;
	}
	return _active;
}

/// @function		__mini_tween_snapshot()
/// @description	Copy of the tween list (safe to iterate while callbacks create/cancel tweens)
/// @returns {Array<Struct.MiniTween>}
function __mini_tween_snapshot()
{
	var _tweens = __mini_tween_manager().tweens;
	var _copy = [];
	array_copy(_copy, 0, _tweens, 0, array_length(_tweens));
	return _copy;
}
