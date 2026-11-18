///@description		NodeManager - Input: mode detection (button/cursor), blocking, consumption and global events.
///					Device bindings live in global.mnd_input (NodeSettings).

#region Enums & Events

/// Input block flags (combine with |)
enum MND_BLOCK
{
	BUTTON_NAV		= 1,	// Gamepad/keyboard directional navigation
	CURSOR_NAV		= 2,	// Mouse/touch hover selection
	BUTTON_ACTION	= 4,	// Accept in button mode
	CURSOR_ACTION	= 8,	// Accept in cursor mode
	NAV				= 3,	// BUTTON_NAV | CURSOR_NAV
	ACTION			= 12,	// BUTTON_ACTION | CURSOR_ACTION
	ALL				= 15
}

/// Global MiniNode events (MiniEvent). Connect like any MiniEvent:
///		global.mnd_events.input_mode_changed.connect(id, function(_mode) { ... });
///		global.mnd_events.focus_changed.connect(id, function(_focused_node, _previous_node) { ... });
global.mnd_events = {
	input_mode_changed: new MiniEvent(),	// (mode)
	focus_changed: new MiniEvent()			// (focused_node, previous_node) - both may be noone
};

#endregion

#region Mode

///@function			mnd_input_get_mode()
///@returns {Enum.MND_NAV_INPUT}
function mnd_input_get_mode()
{
	return __mnd().input_mode;
}

///@function						mnd_input_set_mode(_mode, _lock)
///@description						Set the input mode. Unless locked, automatic detection can change it again on the next step.
///@param {Enum.MND_NAV_INPUT} _mode
///@param {Bool} [_lock]			If true, automatic detection is disabled until mnd_input_unlock_mode() (default false)
function mnd_input_set_mode(_mode, _lock = false)
{
	var _m = __mnd();
	_m.__input_mode_locked = _lock;
	__mnd_input_apply_mode(_mode);
}

///@function			mnd_input_unlock_mode()
///@description			Re-enable automatic input mode detection
function mnd_input_unlock_mode()
{
	__mnd().__input_mode_locked = false;
}

function mnd_input_is_cursor() { return __mnd().input_mode == MND_NAV_INPUT.CURSOR; }
function mnd_input_is_button() { return __mnd().input_mode == MND_NAV_INPUT.BUTTON; }

///@function			__mnd_input_apply_mode(_mode)
///@description			Change the mode and fire input_mode_changed if it changed
function __mnd_input_apply_mode(_mode)
{
	var _m = __mnd();
	if (_m.input_mode == _mode) return;

	_m.input_mode = _mode;
	global.mnd_events.input_mode_changed.invoke(_mode);
}

#endregion

#region Blocking

/// Blocks are reference counted per flag: every mnd_input_block must be matched by a mnd_input_unblock
/// with the same flags. Independent systems (transitions, dialogs, cutscenes) never unblock each other.

///@function				mnd_input_block(_flags)
///@description				Block input (reference counted)
///@param {Enum.MND_BLOCK} [_flags]	Flags to block (default ALL)
function mnd_input_block(_flags = MND_BLOCK.ALL)
{
	var _counts = __mnd().__block_counts;
	for (var _i = 0; _i < 4; _i++)
	{
		if (_flags & (1 << _i)) _counts[_i]++;
	}
}

///@function				mnd_input_unblock(_flags)
///@description				Release a block added with mnd_input_block
///@param {Enum.MND_BLOCK} [_flags]	Flags to unblock (default ALL)
function mnd_input_unblock(_flags = MND_BLOCK.ALL)
{
	var _counts = __mnd().__block_counts;
	for (var _i = 0; _i < 4; _i++)
	{
		if (_flags & (1 << _i)) _counts[_i] = max(0, _counts[_i] - 1);
	}
}

///@function				mnd_input_is_blocked(_flags)
///@description				Check if any of the given flags is blocked
///@param {Enum.MND_BLOCK} [_flags]	Flags to check (default ALL)
///@returns {Bool}
function mnd_input_is_blocked(_flags = MND_BLOCK.ALL)
{
	var _counts = __mnd().__block_counts;
	for (var _i = 0; _i < 4; _i++)
	{
		if ((_flags & (1 << _i)) && _counts[_i] > 0) return true;
	}
	return false;
}

///@function			mnd_input_is_nav_blocked()
///@description			Check if navigation is blocked for the current input mode
///@returns {Bool}
function mnd_input_is_nav_blocked()
{
	return mnd_input_is_blocked(mnd_input_is_cursor() ? MND_BLOCK.CURSOR_NAV : MND_BLOCK.BUTTON_NAV);
}

///@function			mnd_input_is_action_blocked()
///@description			Check if actions are blocked for the current input mode
///@returns {Bool}
function mnd_input_is_action_blocked()
{
	return mnd_input_is_blocked(mnd_input_is_cursor() ? MND_BLOCK.CURSOR_ACTION : MND_BLOCK.BUTTON_ACTION);
}

///@function			mnd_input_reset_blocks()
///@description			Clear every block (emergency reset; prefer matching unblocks)
function mnd_input_reset_blocks()
{
	__mnd().__block_counts = [0, 0, 0, 0];
}

#endregion

#region Consumption

///@function			mnd_input_consume()
///@description			Consume the UI input for the current frame (navigation and actions are ignored until next step)
function mnd_input_consume()
{
	__mnd().__input_consumed = true;
}

///@function			mnd_input_is_consumed()
///@returns {Bool}
function mnd_input_is_consumed()
{
	return __mnd().__input_consumed;
}

#endregion

#region Update

///@function			__mnd_input_update()
///@description			Per-step input update, called by obj_node_manager: cursor tracking, consumption reset and mode detection
function __mnd_input_update()
{
	var _m = __mnd();
	var _input = global.mnd_input;

	_m.__input_consumed = false;
	_m.cursor_prev_x = _m.cursor_x;
	_m.cursor_prev_y = _m.cursor_y;
	_m.cursor_x = _input.cursor_x();
	_m.cursor_y = _input.cursor_y();

	if (_m.__input_mode_locked) return;

	if (_input.button_input_detected())
	{
		__mnd_input_apply_mode(MND_NAV_INPUT.BUTTON);
	}
	else if (_input.cursor_input_detected())
	{
		__mnd_input_apply_mode(MND_NAV_INPUT.CURSOR);
	}
}

#endregion
