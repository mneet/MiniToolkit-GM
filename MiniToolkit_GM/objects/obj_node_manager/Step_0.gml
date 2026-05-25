/// @description MiniNode Manager Step - Process all root nodes

// Update input mode detection (cursor tracking + button/cursor swap)
var _input = global.mnd_input;
__input_consumed = false;
cursor_prev_x = cursor_x;
cursor_prev_y = cursor_y;
cursor_x = _input.cursor_x();
cursor_y = _input.cursor_y();

if (_input.button_input_detected())
{
	input_mode = MND_NAV_INPUT.BUTTON;
}
else if (_input.cursor_input_detected())
{
	input_mode = MND_NAV_INPUT.CURSOR;
}

// Process all root nodes in draw order
var _order = __root_draw_order;
var _roots = __root_nodes;
var _len   = array_length(_order);

for (var _i = 0; _i < _len; _i++)
{
	var _root_id = _order[_i];
	if (struct_exists(_roots, _root_id))
	{
		_roots[$ _root_id].processor.__step_processor();
	}
}
