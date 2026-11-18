///@description		NodeManager - Navigation focus stack.
///					The stack holds nodes that own a MiniNodeNavGroup. The top is the focused group, the only one that receives input.
///					Stealing pushes a group on top; releasing removes it and gives focus back to the previous valid group.
///					Disabling, detaching or destroying a node releases its focus automatically.
///					Every change fires global.mnd_events.focus_changed(focused_node, previous_node).

///@function								mnd_nav_steal_focus(_node)
///@description								Give navigation focus to a node's group, keeping the current one on the stack
///@param {Struct.MiniNode|String} _node	Node (with nav_group) or node id
///@returns {Bool}							True if the node is now focused
function mnd_nav_steal_focus(_node)
{
	_node = __mnd_resolve_node(_node);
	if (_node == noone || _node.nav_group == noone)
	{
		show_debug_message("[NodeManager] mnd_nav_steal_focus: node not found or without nav_group");
		return false;
	}
	if (!_node.is_enabled())
	{
		show_debug_message($"[NodeManager] mnd_nav_steal_focus: node '{_node.id}' is disabled");
		return false;
	}

	var _current = mnd_nav_get_focused_node();
	if (_current == _node) return true;

	if (_current != noone) _current.nav_group.__on_focus_lost();

	var _stack = __mnd().__focus_stack;
	var _idx = array_get_index(_stack, _node);
	if (_idx >= 0) array_delete(_stack, _idx, 1);
	array_push(_stack, _node);

	_node.nav_group.__on_focus_gained();
	global.mnd_events.focus_changed.invoke(_node, _current);
	return true;
}

///@function								mnd_nav_release_focus(_node)
///@description								Remove a node from the focus stack. If it was focused, the previous valid group gains focus.
///@param {Struct.MiniNode|String} [_node]	Node or node id (default: the focused node)
function mnd_nav_release_focus(_node = undefined)
{
	if (!instance_exists(obj_node_manager)) return;

	var _stack = obj_node_manager.__focus_stack;
	var _len = array_length(_stack);
	if (_len == 0) return;

	_node = (_node == undefined) ? _stack[_len - 1] : __mnd_resolve_node(_node);
	var _idx = array_get_index(_stack, _node);
	if (_idx < 0) return;

	var _was_top = (_idx == _len - 1);
	if (_was_top && _node.nav_group != noone) _node.nav_group.__on_focus_lost();

	array_delete(_stack, _idx, 1);

	if (_was_top)
	{
		var _new_focus = __mnd_nav_focus_top();
		global.mnd_events.focus_changed.invoke(_new_focus, _node);
	}
}

///@function		__mnd_nav_focus_top()
///@description		Give focus to the topmost valid node of the stack, dropping invalid entries
///@returns {Struct.MiniNode|Constant.noone}	The focused node
function __mnd_nav_focus_top()
{
	var _stack = obj_node_manager.__focus_stack;
	while (array_length(_stack) > 0)
	{
		var _top = _stack[array_length(_stack) - 1];
		if (__mnd_nav_is_valid(_top))
		{
			_top.nav_group.__on_focus_gained();
			return _top;
		}
		array_pop(_stack);
	}
	return noone;
}

///@function		__mnd_nav_is_valid(_node)
///@returns {Bool}	True if the node can hold focus
function __mnd_nav_is_valid(_node)
{
	return is_struct(_node) && !_node.__destroyed && _node.nav_group != noone && _node.is_enabled();
}

///@function		mnd_nav_clear_focus()
///@description		Remove focus from every group and clear the stack
function mnd_nav_clear_focus()
{
	if (!instance_exists(obj_node_manager)) return;

	var _current = mnd_nav_get_focused_node();
	if (_current != noone) _current.nav_group.__on_focus_lost();

	obj_node_manager.__focus_stack = [];
	if (_current != noone) global.mnd_events.focus_changed.invoke(noone, _current);
}

///@function		mnd_nav_get_focused_node()
///@description		Get the node whose group currently has focus
///@returns {Struct.MiniNode|Constant.noone}
function mnd_nav_get_focused_node()
{
	if (!instance_exists(obj_node_manager)) return noone;

	var _stack = obj_node_manager.__focus_stack;
	var _len = array_length(_stack);
	if (_len == 0) return noone;

	var _node = _stack[_len - 1];
	return (!_node.__destroyed && _node.nav_group != noone) ? _node : noone;
}

///@function		mnd_nav_get_focused_group()
///@description		Get the focused navigation group
///@returns {Struct.MiniNodeNavGroup|Constant.noone}
function mnd_nav_get_focused_group()
{
	var _node = mnd_nav_get_focused_node();
	return (_node != noone) ? _node.nav_group : noone;
}

///@function								mnd_nav_has_focus(_node)
///@description								Check if a node's group is the focused one
///@param {Struct.MiniNode|String} _node	Node or node id
///@returns {Bool}
function mnd_nav_has_focus(_node)
{
	var _focused = mnd_nav_get_focused_node();
	if (_focused == noone) return false;
	return is_string(_node) ? (_focused.id == _node) : (_focused == _node);
}

///@function		mnd_nav_get_selected_node()
///@description		Get the node selected in the focused group
///@returns {Struct.MiniNode|Constant.noone}
function mnd_nav_get_selected_node()
{
	var _group = mnd_nav_get_focused_group();
	return (_group != noone) ? _group.selected : noone;
}
