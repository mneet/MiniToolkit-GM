///@description		NodeManager - Central hub for the MiniNode UI system.
///					State lives on the obj_node_manager singleton (created on demand by __mnd()).
///					Public functions use the mnd_ prefix with sub-namespaces:
///						mnd_root_*    root nodes (processed and drawn by the manager)
///						mnd_node_*    global lookup registry and node helpers
///						mnd_input_*   input mode, blocking and consumption   (NodeManagerInput)
///						mnd_nav_*     navigation focus stack                  (NodeManagerFocus)
///						mnd_show/hide, mnd_transition, mnd_screen_*            (NodeManagerScreens)
///					Every public function accepts a node reference or a node id, and returns noone when nothing is found.

#region Core

///@function		__mnd()
///@description		Get the manager instance, creating it if needed
///@returns {Id.Instance}
function __mnd()
{
	if (!instance_exists(obj_node_manager))
	{
		instance_create_depth(0, 0, 0, obj_node_manager);
	}
	return obj_node_manager;
}

///@function						__mnd_resolve_node(_node)
///@description						Resolve a node reference or id (searched with mnd_node_get) into a node struct
///@param {Struct.MiniNode|String} _node
///@returns {Struct.MiniNode|Constant.noone}
function __mnd_resolve_node(_node)
{
	if (is_struct(_node)) return _node;
	if (is_string(_node)) return mnd_node_get(_node);
	return noone;
}

///@function						__mnd_resolve_id(_node)
///@description						Resolve a node reference or id into a node id
///@param {Struct.MiniNode|String} _node
///@returns {String|Constant.noone}
function __mnd_resolve_id(_node)
{
	if (is_string(_node)) return _node;
	if (is_struct(_node)) return _node.id;
	return noone;
}

///@function						__mnd_forget_node(_node)
///@description						Remove every manager reference to a node (roots, registry, focus, screens). Used by node_destroy().
function __mnd_forget_node(_node)
{
	if (!instance_exists(obj_node_manager)) return;

	mnd_nav_release_focus(_node);
	mnd_root_remove(_node);
	mnd_node_unregister(_node);
	__mnd_screen_forget(_node);
}

#endregion

#region Roots

///@function								mnd_root_add(_node, _enabled)
///@description								Register a node as a root: it is processed and drawn by the manager (Draw GUI).
///											Roots are also registered for global lookup. Calling it on an existing root only applies _enabled = false.
///											MiniNodeCanvas registers itself automatically (see MND_CANVAS_AUTO_ROOT).
///@param {Struct.MiniNode} _node			The node (must not have a parent)
///@param {Bool} [_enabled]					If false, the node starts disabled (default true)
///@returns {Bool}							True if the node is a root after the call
function mnd_root_add(_node, _enabled = true)
{
	_node = __mnd_resolve_node(_node);
	if (_node == noone) return false;

	if (_node.parent != noone)
	{
		show_debug_message($"[NodeManager] mnd_root_add: '{_node.id}' has a parent and cannot be a root");
		return false;
	}

	var _m = __mnd();
	if (!mnd_root_is(_node))
	{
		array_push(_m.__roots, _node);
		mnd_node_register(_node);
	}

	if (!_enabled) _node.disable();
	return true;
}

///@function								mnd_root_remove(_node)
///@description								Stop processing/drawing a root (the node is not destroyed)
///@param {Struct.MiniNode|String} _node
///@returns {Bool}							True if it was a root
function mnd_root_remove(_node)
{
	if (!instance_exists(obj_node_manager)) return false;
	_node = __mnd_resolve_node(_node);
	if (_node == noone) return false;

	var _roots = obj_node_manager.__roots;
	var _idx = array_get_index(_roots, _node);
	if (_idx < 0) return false;

	_node.__nav_release_subtree();
	array_delete(_roots, _idx, 1);
	return true;
}

///@function								mnd_root_is(_node)
///@param {Struct.MiniNode|String} _node
///@returns {Bool}
function mnd_root_is(_node)
{
	if (!instance_exists(obj_node_manager)) return false;
	_node = __mnd_resolve_node(_node);
	return _node != noone && array_get_index(obj_node_manager.__roots, _node) >= 0;
}

///@function			mnd_root_get_all()
///@description			Get the roots in draw order (back to front). Do not modify the array.
///@returns {Array<Struct.MiniNode>}
function mnd_root_get_all()
{
	return __mnd().__roots;
}

///@function								mnd_root_set_order(_node, _index)
///@description								Change a root's position in the draw/process order
///@param {Struct.MiniNode|String} _node
///@param {Real} _index						New index (0 = back, -1 = front)
function mnd_root_set_order(_node, _index)
{
	_node = __mnd_resolve_node(_node);
	var _roots = __mnd().__roots;
	var _idx = array_get_index(_roots, _node);
	if (_idx < 0) return;

	array_delete(_roots, _idx, 1);

	if (_index < 0 || _index >= array_length(_roots)) array_push(_roots, _node);
	else array_insert(_roots, _index, _node);
}

function mnd_root_bring_to_front(_node) { mnd_root_set_order(_node, -1); }
function mnd_root_send_to_back(_node)   { mnd_root_set_order(_node, 0); }

#endregion

#region Registry & Nodes

///@function								mnd_node_register(_node)
///@description								Register a node for fast global lookup with mnd_node_get (roots are registered automatically).
///											Ids only need to be globally unique for registered nodes; use node.node_find() for local lookups.
///@param {Struct.MiniNode} _node
///@returns {Bool}							False if another living node already uses the id
function mnd_node_register(_node)
{
	var _registry = __mnd().__registry;
	var _id = _node.id;

	if (struct_exists(_registry, _id))
	{
		var _ref = _registry[$ _id];
		if (weak_ref_alive(_ref) && _ref.ref != _node && !_ref.ref.__destroyed)
		{
			show_debug_message($"[NodeManager] mnd_node_register: id '{_id}' is already registered by another node");
			return false;
		}
	}

	_registry[$ _id] = weak_ref_create(_node);
	return true;
}

///@function								mnd_node_unregister(_node)
///@param {Struct.MiniNode|String} _node
function mnd_node_unregister(_node)
{
	if (!instance_exists(obj_node_manager)) return;

	var _registry = obj_node_manager.__registry;
	var _id = __mnd_resolve_id(_node);
	if (!struct_exists(_registry, _id)) return;

	// Only remove if it points to this node (or a dead one)
	var _ref = _registry[$ _id];
	if (!is_struct(_node) || !weak_ref_alive(_ref) || _ref.ref == _node)
	{
		struct_remove(_registry, _id);
	}
}

///@function								mnd_node_get(_id)
///@description								Find a node by id: registered nodes first, then a search through every root subtree
///@param {String} _id
///@returns {Struct.MiniNode|Constant.noone}
function mnd_node_get(_id)
{
	if (!instance_exists(obj_node_manager)) return noone;
	var _m = obj_node_manager;

	// Registry
	if (struct_exists(_m.__registry, _id))
	{
		var _ref = _m.__registry[$ _id];
		if (weak_ref_alive(_ref) && !_ref.ref.__destroyed) return _ref.ref;
		struct_remove(_m.__registry, _id);
	}

	// Search roots
	var _roots = _m.__roots;
	var _len = array_length(_roots);
	for (var _i = 0; _i < _len; _i++)
	{
		var _found = _roots[_i].node_find(_id);
		if (_found != noone) return _found;
	}
	return noone;
}

///@function								mnd_node_exists(_id)
///@returns {Bool}
function mnd_node_exists(_id)
{
	return mnd_node_get(_id) != noone;
}

///@function								mnd_node_enable(_node)
///@description								Enable a node (see mnd_show to also give it navigation focus)
///@param {Struct.MiniNode|String} _node
function mnd_node_enable(_node)
{
	_node = __mnd_resolve_node(_node);
	if (_node != noone) _node.enable();
}

///@function								mnd_node_disable(_node, _delay)
///@param {Struct.MiniNode|String} _node
///@param {Real} [_delay]					Delay in seconds (on_disabling fires immediately)
function mnd_node_disable(_node, _delay = 0)
{
	_node = __mnd_resolve_node(_node);
	if (_node != noone) _node.disable(_delay);
}

///@function								mnd_node_destroy(_node)
///@description								Destroy a node and its subtree (see MiniNode.node_destroy)
///@param {Struct.MiniNode|String} _node
function mnd_node_destroy(_node)
{
	_node = __mnd_resolve_node(_node);
	if (_node != noone) _node.node_destroy();
}

///@function			mnd_destroy_all()
///@description			Destroy every root and reset the manager state (focus, screens, input blocks and mode)
function mnd_destroy_all()
{
	if (!instance_exists(obj_node_manager)) return;
	var _m = obj_node_manager;

	var _roots = [];
	array_copy(_roots, 0, _m.__roots, 0, array_length(_m.__roots));
	var _len = array_length(_roots);
	for (var _i = 0; _i < _len; _i++)
	{
		_roots[_i].node_destroy();
	}

	_m.__reset_state();
}

#endregion

#region Debug

global.__mnd_debug = {
	draw_size: MND_DEBUG_SIZE,
	draw_origin: MND_DEBUG_ORIGIN
};

///@function				mnd_debug_set(_draw_size, _draw_origin)
///@description				Toggle debug drawing at runtime (bounding boxes and origins of every drawn node)
///@param {Bool} _draw_size
///@param {Bool} [_draw_origin]
function mnd_debug_set(_draw_size, _draw_origin = _draw_size)
{
	global.__mnd_debug.draw_size = _draw_size;
	global.__mnd_debug.draw_origin = _draw_origin;
}

///@function								mnd_debug_print_tree(_node)
///@description								Print a node hierarchy to the output (all roots when omitted)
///@param {Struct.MiniNode|String} [_node]
function mnd_debug_print_tree(_node = undefined)
{
	if (_node == undefined)
	{
		var _roots = mnd_root_get_all();
		show_debug_message($"[NodeManager] {array_length(_roots)} root(s)");
		for (var _i = 0; _i < array_length(_roots); _i++) __mnd_debug_print_node(_roots[_i], 0);
		return;
	}

	_node = __mnd_resolve_node(_node);
	if (_node != noone) __mnd_debug_print_node(_node, 0);
}

///@function	__mnd_debug_print_node(_node, _depth)
function __mnd_debug_print_node(_node, _depth)
{
	var _flags = "";
	if (!_node.enabled)					_flags += " [disabled]";
	if (!_node.visible)					_flags += " [hidden]";
	if (!_node.is_initialized())		_flags += " [uninit]";
	if (_node.nav_group != noone)		_flags += mnd_nav_has_focus(_node) ? " [group:FOCUS]" : " [group]";
	if (_node.nav_item != noone)		_flags += _node.nav_item.is_selected ? " [item:SELECTED]" : " [item]";

	var _t = _node.transform;
	show_debug_message($"{string_repeat("  ", _depth)}- {_node.id} ({instanceof(_node)}) pos({_t.x}, {_t.y}) size({_t.width}x{_t.height}){_flags}");

	var _children = _node.__nested_nodes;
	for (var _i = 0; _i < array_length(_children); _i++) __mnd_debug_print_node(_children[_i], _depth + 1);
}

#endregion
