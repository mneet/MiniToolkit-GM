/// @description MiniNode Manager Step - input update, root processing, navigation input

__mnd_input_update();

// Process roots (copy: handlers may add/remove roots while processing)
var _roots = [];
array_copy(_roots, 0, __roots, 0, array_length(__roots));

var _len = array_length(_roots);
for (var _i = 0; _i < _len; _i++)
{
	var _root = _roots[_i];
	if (!_root.__destroyed && _root.parent == noone)
	{
		_root.processor.__step_processor();
	}
}

// Navigation input - only the focused group receives input
var _focused_group = mnd_nav_get_focused_group();
if (_focused_group != noone)
{
	_focused_group.__process_input();
}
