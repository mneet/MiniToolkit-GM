///@description		NodeManager - Showing/hiding nodes, transitions and the screen stack.
///					The screen stack is an optional layer for menu flows:
///						mnd_screen_push(main_menu);                 // base screen
///						mnd_screen_push("menu_options");            // hides main menu, shows options
///						mnd_screen_push("exit_popup", false);       // popup over the current screen
///						mnd_screen_pop();                           // back to the previous screen
///					Avoid mixing manual enable/disable of stacked screens with the stack functions.

#region Show / Hide / Transition

///@function								mnd_show(_node, _focus)
///@description								Enable a node and, if it has a nav_group, give it navigation focus (popup pattern)
///@param {Struct.MiniNode|String} _node
///@param {Bool} [_focus]					Steal the navigation focus (default true)
///@returns {Bool}							True if the node was found
function mnd_show(_node, _focus = true)
{
	_node = __mnd_resolve_node(_node);
	if (_node == noone)
	{
		show_debug_message("[NodeManager] mnd_show: node not found");
		return false;
	}

	_node.enable();
	if (_focus && _node.nav_group != noone) mnd_nav_steal_focus(_node);
	return true;
}

///@function								mnd_hide(_node, _delay)
///@description								Disable a node. Its navigation focus is released immediately (focus returns to the previous group).
///@param {Struct.MiniNode|String} _node
///@param {Real} [_delay]					Seconds before actually disabling; on_disabling fires immediately (default 0)
///@returns {Bool}							True if the node was found
function mnd_hide(_node, _delay = 0)
{
	_node = __mnd_resolve_node(_node);
	if (_node == noone)
	{
		show_debug_message("[NodeManager] mnd_hide: node not found");
		return false;
	}

	_node.disable(_delay);
	return true;
}

///@function								mnd_transition(_from_node, _to_node, _delay)
///@description								Disable a node and, once it is disabled, show another one (with focus).
///											All input is blocked during the transition (reference counted, see mnd_input_block).
///@param {Struct.MiniNode|String} _from_node	The node to disable
///@param {Struct.MiniNode|String} _to_node		The node to show after the first one is disabled
///@param {Real} [_delay]					Delay in seconds (exit animation time)
///@returns {Bool}							True if both nodes were found
function mnd_transition(_from_node, _to_node, _delay = 0)
{
	_from_node = __mnd_resolve_node(_from_node);
	_to_node   = __mnd_resolve_node(_to_node);

	if (_from_node == noone || _to_node == noone)
	{
		show_debug_message("[NodeManager] mnd_transition: node not found");
		return false;
	}

	mnd_input_block(MND_BLOCK.ALL);

	// Callback is bound to _to_node (MiniEvent rebinds self to the connection)
	_from_node.on_disabled.connect(_to_node, function()
	{
		mnd_show(self, true);
		mnd_input_unblock(MND_BLOCK.ALL);
	}, true);

	_from_node.disable(_delay);
	return true;
}

#endregion

#region Screen Stack

///@function								mnd_screen_push(_node, _hide_current, _delay)
///@description								Open a screen on top of the stack
///@param {Struct.MiniNode|String} _node	Screen node
///@param {Bool} [_hide_current]			True: transition from the current screen (menu). False: keep it visible below (popup). Default true
///@param {Real} [_delay]					Exit animation time of the current screen when hiding it (default 0)
///@returns {Bool}							True if pushed
function mnd_screen_push(_node, _hide_current = true, _delay = 0)
{
	_node = __mnd_resolve_node(_node);
	if (_node == noone)
	{
		show_debug_message("[NodeManager] mnd_screen_push: node not found");
		return false;
	}

	var _current = mnd_screen_get_current();
	if (_current == _node) return true;

	// A screen appears only once in the stack
	__mnd_screen_forget(_node);

	var _hides = _hide_current && _current != noone;
	array_push(__mnd().__screen_stack, { node: _node, hid_previous: _hides });

	if (_hides) mnd_transition(_current, _node, _delay);
	else mnd_show(_node, true);

	return true;
}

///@function				mnd_screen_pop(_delay)
///@description				Close the current screen and go back to the previous one
///@param {Real} [_delay]	Exit animation time of the closed screen (default 0)
///@returns {Struct.MiniNode|Constant.noone}	The screen that is now current
function mnd_screen_pop(_delay = 0)
{
	var _stack = __mnd().__screen_stack;
	if (array_length(_stack) == 0) return noone;

	var _entry = array_pop(_stack);
	var _previous = mnd_screen_get_current();

	if (_entry.hid_previous && _previous != noone) mnd_transition(_entry.node, _previous, _delay);
	else mnd_hide(_entry.node, _delay);

	return _previous;
}

///@function								mnd_screen_replace(_node, _delay)
///@description								Replace the current screen (no way back to it)
///@param {Struct.MiniNode|String} _node
///@param {Real} [_delay]
///@returns {Bool}
function mnd_screen_replace(_node, _delay = 0)
{
	_node = __mnd_resolve_node(_node);
	if (_node == noone) return false;

	var _stack = __mnd().__screen_stack;
	var _len = array_length(_stack);
	if (_len == 0) return mnd_screen_push(_node, true, _delay);

	var _entry = _stack[_len - 1];
	var _old = _entry.node;
	if (_old == _node) return true;

	__mnd_screen_forget(_node);
	_entry.node = _node;

	mnd_transition(_old, _node, _delay);
	return true;
}

///@function		mnd_screen_get_current()
///@returns {Struct.MiniNode|Constant.noone}
function mnd_screen_get_current()
{
	if (!instance_exists(obj_node_manager)) return noone;

	var _stack = obj_node_manager.__screen_stack;
	var _len = array_length(_stack);
	return (_len > 0) ? _stack[_len - 1].node : noone;
}

///@function		mnd_screen_get_count()
///@returns {Real}
function mnd_screen_get_count()
{
	return instance_exists(obj_node_manager) ? array_length(obj_node_manager.__screen_stack) : 0;
}

///@function		mnd_screen_clear()
///@description		Forget every screen (nodes are not hidden)
function mnd_screen_clear()
{
	if (instance_exists(obj_node_manager)) obj_node_manager.__screen_stack = [];
}

///@function		__mnd_screen_forget(_node)
///@description		Remove a node from the screen stack
function __mnd_screen_forget(_node)
{
	if (!instance_exists(obj_node_manager)) return;

	var _stack = obj_node_manager.__screen_stack;
	for (var _i = array_length(_stack) - 1; _i >= 0; _i--)
	{
		if (_stack[_i].node == _node) array_delete(_stack, _i, 1);
	}
}

#endregion
