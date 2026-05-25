///@description		NodeManager - Central hub for the MiniNode UI system.
///					All state is stored on obj_node_manager instance variables. Functions use the mnd_ prefix.

#region Input Mode

function mnd_get_input_mode()      { return obj_node_manager.input_mode; }
function mnd_set_input_mode(_mode) { obj_node_manager.input_mode = _mode; }

function mnd_is_cursor_mode()    { return obj_node_manager.input_mode == MND_NAV_INPUT.CURSOR; }
function mnd_is_button_mode()    { return obj_node_manager.input_mode == MND_NAV_INPUT.BUTTON; }
function mnd_is_input_consumed() { return obj_node_manager.__input_consumed; }
function mnd_consume_input()     { obj_node_manager.__input_consumed = true; }

#endregion

#region MiniNode Collection Management

///@function					mnd_create_node(_node, _enabled, _root)
///@description					Register a node in the collection using a weak reference.
///								If _root is true, also registers it as a root node (processed & drawn by obj_node_manager).
///@param {Struct.MiniNode} _node	The node to register
///@param {Bool} [_enabled]		Whether the node starts enabled (default true)
///@param {Bool} [_root]		Whether to register as a root node (default false)
///@returns {Bool}				True if registered, false if ID already exists
function mnd_create_node(_node, _enabled = true, _root = true)
{
	if (!instance_exists(obj_node_manager))
	{
		instance_create_depth(0, 0, 0, obj_node_manager);
	}
	
	var _m = obj_node_manager;
	var _collection = _m.__node_collection;
	
	if (struct_exists(_collection, _node.id))
	{
		show_debug_message($"[NodeManager] Warning: MiniNode ID '{_node.id}' already exists");
		return false;
	}
	
	_collection[$ _node.id] = weak_ref_create(_node);
	_m.node_count++;
	
	// Register as root if flagged
	if (_root)
	{
		_m.__root_nodes[$ _node.id] = _node;
		array_push(_m.__root_draw_order, _node.id);
		_m.root_count++;
	}
	
	if (!_enabled) _node.disable();
	
	return true;
}

///@function					mnd_remove_node(_node_id)
///@description					Remove a node from the collection.
///								If the node is also a root, removes it from root tracking too.
///@param {String} _node_id		The node ID to remove
///@returns {Bool}				True if removed
function mnd_remove_node(_node_id)
{
	var _m = obj_node_manager;
	var _collection = _m.__node_collection;
	
	if (!struct_exists(_collection, _node_id)) return false;
	
	// If it's a root, clean up root tracking
	if (struct_exists(_m.__root_nodes, _node_id))
	{
		var _node = _m.__root_nodes[$ _node_id];
		
		// Release navigation focus if active
		if (_node.nav_module != noone && _node.nav_module.has_focus)
		{
			_node.nav_module.release_focus();
		}
		
		struct_remove(_m.__root_nodes, _node_id);
		
		var _idx = array_get_index(_m.__root_draw_order, _node_id);
		if (_idx >= 0) array_delete(_m.__root_draw_order, _idx, 1);
		
		_m.root_count = max(0, _m.root_count - 1);
	}
	
	struct_remove(_collection, _node_id);
	_m.node_count = max(0, _m.node_count - 1);
	return true;
}

///@function					mnd_get_node(_node_id)
///@description					Get a node by its ID from the collection
///@param {String} _node_id		The node ID to find
///@returns {Struct.MiniNode|Undefined}
function mnd_get_node(_node_id)
{
	var _collection = obj_node_manager.__node_collection;
	
	if (struct_exists(_collection, _node_id))
	{
		var _weak_ref = _collection[$ _node_id];
		
		if (weak_ref_alive(_weak_ref))
		{
			return _weak_ref.ref;
		}
		else
		{
			struct_remove(_collection, _node_id);
		}
	}
	return undefined;
}

///@function								mnd_enable_node(_node)
///@description								Enable a node by its reference or ID
///@param {Struct.MiniNode|String} _node	The node or node ID
function mnd_enable_node(_node, _grab_focus = false)
{
	if (is_string(_node)) _node = mnd_get_node(_node);
	
	if (_node != undefined)
	{
		if (_grab_focus) _node.on_enabled.connect(_node, function () {
			call_later(1, time_source_units_frames, method(self, function() {
				mnd_nav_set_focus(self.id);
			}));
		}, true);
		_node.enable();
	}
}

///@function							mnd_disable_node(_node, _delay)
///@description							Disable a node by its reference or ID
///@param {Struct.MiniNode|String} _node	The node or node ID
///@param {Real} [_delay]				Delay in seconds (default 0)
function mnd_disable_node(_node, _delay = 0)
{
	if (is_string(_node)) _node = mnd_get_node(_node);
	if (_node != undefined) _node.disable(_delay);
}

function mnd_node_exists(_node_id) { return mnd_get_node(_node_id) != undefined; }

///@function			mnd_cleanup_dead_refs()
///@description			Remove all dead weak references from the collection
///@returns {Real}		Number of dead references removed
function mnd_cleanup_dead_refs()
{
	var _m = obj_node_manager;
	var _collection = _m.__node_collection;
	var _keys = struct_get_names(_collection);
	var _removed = 0;
	
	for (var _i = array_length(_keys) - 1; _i >= 0; _i--)
	{
		var _key = _keys[_i];
		if (!weak_ref_alive(_collection[$ _key]))
		{
			struct_remove(_collection, _key);
			_removed++;
		}
	}
	
	_m.node_count = max(0, _m.node_count - _removed);
	return _removed;
}

function mnd_destroy_all()
{
	if (instance_exists(obj_node_manager)) obj_node_manager.reset_all();
}

#endregion

#region Root MiniNode Management

///@function				mnd_set_root_draw_order(_id, _index)
///@description				Change a root node's position in the draw order
///@param {String} _id		The root node ID
///@param {Real} _index		New index (0 = back, -1 = front)
function mnd_set_root_draw_order(_id, _index)
{
	var _order = obj_node_manager.__root_draw_order;
	var _current_idx = array_get_index(_order, _id);
	if (_current_idx < 0) return;
	
	array_delete(_order, _current_idx, 1);
	
	if (_index < 0 || _index >= array_length(_order))
		array_push(_order, _id);
	else
		array_insert(_order, _index, _id);
}

function mnd_bring_root_to_front(_id) { mnd_set_root_draw_order(_id, -1); }
function mnd_send_root_to_back(_id)   { mnd_set_root_draw_order(_id, 0); }
function mnd_get_all_roots()          { return obj_node_manager.__root_draw_order; }

#endregion

#region Navigation Focus Management (Depth-based Stack)

function mnd_nav_set_focus(_node)
{
	if (is_string(_node)) _node = mnd_get_node(_node);
	
	if (_node.nav_module == noone) return;

	var _current_module = mnd_nav_get_focused_module();
	if (_current_module != undefined)
	{
		obj_node_manager.prev_focused_node_id = obj_node_manager.focused_node_id;
		_current_module.release_focus();	
	}
	
	obj_node_manager.focused_node_id = _node.id;
	_node.nav_module.gain_focus();
}

///@function								mnd_nav_pop_focus()
///@description								Remove focus from the current module and set the previous one as focused.
function mnd_nav_pop_focus()
{
	var _current_module = mnd_nav_get_focused_module();
	if (_current_module != undefined)
	{
		_current_module.release_focus();
	}
	
	if (obj_node_manager.prev_focused_node_id != noone)
	{
		mnd_nav_set_focus(obj_node_manager.prev_focused_node_id);	
	}
	
}

///@function		mnd_nav_get_focused_module()
///@description		Get the currently focused navigation module
///@returns {Struct.MiniNodeNavCenter|Undefined}
function mnd_nav_get_focused_module()
{
	var _node = mnd_get_node(obj_node_manager.focused_node_id);
	
	if (_node == noone || _node == undefined) return undefined;
	
	return _node.nav_module;
}

///@function									mnd_nav_has_focus(_module)
///@description									Check if a specific module currently has input focus
///@param {Struct.MiniNodeNavCenter} _module
///@returns {Bool}
function mnd_nav_has_focus(_node)
{
	return obj_node_manager.focused_node_id == _node.id;
}

///@function		mnd_nav_clear_focus()
///@description		Clear all module focus from the stack
function mnd_nav_clear_focus()
{
	var _current_module = mnd_get_focused_module();
	if (_current_module != undefined)
	{
		_current_module.release_focus();
	}
	obj_node_manager.focused_node_id = noone;
	obj_node_manager.prev_focused_node_id = noone;
}

#endregion

#region Selected MiniNode Tracking

///@function		mnd_get_selected_node()
///@description		Get the currently selected node
///@returns {Struct.MiniNode|Undefined}
function mnd_get_selected_node()
{
	var _module = mnd_nav_get_focused_module();
	if (_module == undefined) return undefined;
	
	return _module.nav_node_selected;
}

#endregion

#region Input Blocking

function mnd_block_button_navigation(_block)
{
	var _m = obj_node_manager;
	_m.block_button_navigation = _block;
}

function mnd_block_cursor_navigation(_block)
{
	var _m = obj_node_manager;
	_m.block_cursor_navigation = _block;
}

function mnd_block_button_action(_block)
{
	var _m = obj_node_manager;
	_m.block_button_action = _block;
}

function mnd_block_cursor_action(_block)
{
	var _m = obj_node_manager;
	_m.block_cursor_action = _block
}

function mnd_block_all_navigation(_block)
{
	mnd_block_button_navigation(_block);
	mnd_block_cursor_navigation(_block);
}

function mnd_block_all_actions(_block)
{
	mnd_block_button_action(_block);
	mnd_block_cursor_action(_block);
}

function mnd_block_all_input(_block)
{
	mnd_block_all_navigation(_block);
	mnd_block_all_actions(_block);
}

function mnd_is_button_navigation_blocked() { return obj_node_manager.block_button_navigation; }
function mnd_is_cursor_navigation_blocked() { return obj_node_manager.block_cursor_navigation; }
function mnd_is_button_action_blocked()     { return obj_node_manager.block_button_action; }
function mnd_is_cursor_action_blocked()     { return obj_node_manager.block_cursor_action; }

function mnd_is_action_blocked()
{
	var _m = obj_node_manager;
	var _cursor = _m.input_mode == MND_NAV_INPUT.CURSOR && _m.block_cursor_action;
	var _button = _m.input_mode == MND_NAV_INPUT.BUTTON && _m.block_button_action;
	return _cursor || _button;
}

function mnd_is_navigation_blocked()
{
	var _m = obj_node_manager;
	var _cursor = _m.input_mode == MND_NAV_INPUT.CURSOR && _m.block_cursor_navigation;
	var _button = _m.input_mode == MND_NAV_INPUT.BUTTON && _m.block_button_navigation;
	return _cursor || _button;
}

#endregion

#region Transition Management

///@function								mnd_transition(_from_node, _to_node, _delay)
///@description								Transition between nodes. Disables the first and enables the second.
///											If the target has a NavigationModule, gives it focus.
///@param {Struct.MiniNode|String} _from_node	The node to disable
///@param {Struct.MiniNode|String} _to_node		The node to enable after transition
///@param {Real} [_delay]					Delay in seconds (default 0)
function mnd_transition(_from_node, _to_node, _delay = 0)
{
	if (is_string(_from_node)) _from_node = mnd_get_node(_from_node);
	if (is_string(_to_node))   _to_node   = mnd_get_node(_to_node);
	
	if (_from_node == undefined)
	{
		show_debug_message("[NodeManager] Transition error: from_node not found");
		return;
	}
	if (_to_node == undefined)
	{
		show_debug_message("[NodeManager] Transition error: to_node not found");
		return;
	}
	
	mnd_block_all_input(true);
	
	var _method = method(_to_node, function ()
	{
		call_later(1, time_source_units_frames,
		function()
		{
			enable();
			// If target has a navigation module, give it focus
			if (navigation != noone)
			{
				mnd_nav_set_focus(self);
			}
			mnd_block_all_input(false);
		});
	});
	
	_from_node.on_disabled.connect(_to_node, _method, true);
	_from_node.disable(_delay);
}

#endregion
