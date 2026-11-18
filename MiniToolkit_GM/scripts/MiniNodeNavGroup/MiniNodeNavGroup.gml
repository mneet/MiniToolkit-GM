///@function							MiniNodeNavGroup(_owner)
///@description							Navigation module that can be attached to any MiniNode.
///										Controls every MiniNodeNavItem in the owner's subtree (except subtrees that have their own group).
///										Only the group on top of the focus stack receives input (see mnd_nav_steal_focus / mnd_nav_release_focus).
///										AUTO mode calculates neighbours from the layout and caches them; links set by code always win.
///@param {Struct.MiniNode} _owner		The node that owns this navigation group
function MiniNodeNavGroup(_owner) constructor
{
	owner = _owner;

	// Configuration
	mode = MND_NAV_DEFAULT_MODE;			// NODE_NAV_MODE.AUTO or NODE_NAV_MODE.MANUAL
	wrap_h = MND_NAV_DEFAULT_WRAP_H;		// Auto links wrap around horizontally
	wrap_v = MND_NAV_DEFAULT_WRAP_V;		// Auto links wrap around vertically
	auto_focus = MND_NAV_AUTO_FOCUS;		// Take focus when enabled if no group has focus
	remember_last = MND_NAV_REMEMBER_LAST;	// Reselect the last selected item when focus comes back
	button_input = true;					// Gamepad/keyboard navigation
	cursor_input = true;					// Mouse/touch navigation

	// Selection state
	selected = noone;						// Currently selected node
	default_node = noone;					// Node (or id) selected when the group gains focus (noone = first item)
	last_selected = noone;					// Node selected when focus was lost

	// Focus events
	on_focus_gained = new MiniEvent();
	on_focus_lost = new MiniEvent();

	// Item cache
	__items = [];
	__dirty = true;

	static __dir_names = ["up", "down", "left", "right"];
	static __dir_x = [0, 0, -1, 1];
	static __dir_y = [-1, 1, 0, 0];

	#region Configuration

	///@function						nav_set_mode(_mode)
	///@description						AUTO calculates links from the layout (manual links still win). MANUAL only uses links set by code.
	///@param {Enum.NODE_NAV_MODE} _mode
	///@returns {Struct.MiniNodeNavGroup}	Self for chaining
	static nav_set_mode = function(_mode)
	{
		mode = _mode;
		__dirty = true;
		return self;
	}

	///@function						nav_set_wrap(_horizontal, _vertical)
	///@description						Enable wrap-around for automatic links on each axis
	///@param {Bool} _horizontal
	///@param {Bool} [_vertical]
	///@returns {Struct.MiniNodeNavGroup}	Self for chaining
	static nav_set_wrap = function(_horizontal, _vertical = _horizontal)
	{
		wrap_h = _horizontal;
		wrap_v = _vertical;
		__dirty = true;
		return self;
	}

	///@function						nav_set_default(_node)
	///@description						Set the node selected when the group gains focus
	///@param {Struct.MiniNode|String} _node	Node or node id (noone = first available item)
	///@returns {Struct.MiniNodeNavGroup}	Self for chaining
	static nav_set_default = function(_node)
	{
		default_node = (_node == undefined) ? noone : _node;
		return self;
	}

	///@function						nav_set_auto_focus(_enabled)
	///@description						If true, the group takes focus when its owner is enabled and no group has focus
	///@returns {Struct.MiniNodeNavGroup}	Self for chaining
	static nav_set_auto_focus = function(_enabled)
	{
		auto_focus = _enabled;
		return self;
	}

	///@function						nav_set_remember_last(_enabled)
	///@description						If true, the last selected item is reselected when focus comes back
	///@returns {Struct.MiniNodeNavGroup}	Self for chaining
	static nav_set_remember_last = function(_enabled)
	{
		remember_last = _enabled;
		return self;
	}

	///@function						nav_set_button_input(_enabled)
	///@returns {Struct.MiniNodeNavGroup}	Self for chaining
	static nav_set_button_input = function(_enabled)
	{
		button_input = _enabled;
		return self;
	}

	///@function						nav_set_cursor_input(_enabled)
	///@returns {Struct.MiniNodeNavGroup}	Self for chaining
	static nav_set_cursor_input = function(_enabled)
	{
		cursor_input = _enabled;
		return self;
	}

	#endregion

	#region Manual Links

	///@function						nav_link(_from, _direction, _to, _bidirectional)
	///@description						Link two items by code. Manual links have priority over automatic ones.
	///@param {Struct.MiniNode|String} _from	Source node or id
	///@param {String} _direction		"up", "down", "left" or "right"
	///@param {Struct.MiniNode|String} _to	Target node or id (noone clears the link)
	///@param {Bool} [_bidirectional]	Also link _to back to _from in the opposite direction (default true)
	///@returns {Struct.MiniNodeNavGroup}	Self for chaining
	static nav_link = function(_from, _direction, _to, _bidirectional = true)
	{
		var _from_node = __resolve_target(_from);
		if (_from_node == noone || _from_node.nav_item == noone)
		{
			show_debug_message($"[MiniNodeNavGroup] nav_link: '{__mnd_resolve_id(_from)}' is not a navigation item");
			return self;
		}

		_from_node.nav_item.set_link(_direction, _to);

		if (_bidirectional)
		{
			var _to_node = __resolve_target(_to);
			if (_to_node != noone && _to_node.nav_item != noone)
			{
				_to_node.nav_item.set_link(__opposite(_direction), _from_node);
			}
		}
		return self;
	}

	///@function						nav_link_list(_nodes, _axis, _wrap)
	///@description						Link an array of items in sequence (bidirectional)
	///@param {Array} _nodes			Nodes or ids in order
	///@param {Enum.NODE_AXIS} [_axis]	HORIZONTAL links left/right, VERTICAL links up/down (default VERTICAL)
	///@param {Bool} [_wrap]			Link the last item back to the first (default false)
	///@returns {Struct.MiniNodeNavGroup}	Self for chaining
	static nav_link_list = function(_nodes, _axis = NODE_AXIS.VERTICAL, _wrap = false)
	{
		var _next = (_axis == NODE_AXIS.HORIZONTAL) ? "right" : "down";
		var _len = array_length(_nodes);

		for (var _i = 0; _i < _len - 1; _i++)
		{
			nav_link(_nodes[_i], _next, _nodes[_i + 1], true);
		}
		if (_wrap && _len > 1)
		{
			nav_link(_nodes[_len - 1], _next, _nodes[0], true);
		}
		return self;
	}

	///@function						nav_link_grid(_nodes, _columns, _wrap_h, _wrap_v)
	///@description						Link an array of items as a grid (row by row).
	///									Edges without wrap are left unlinked, so they fall back to automatic links in AUTO mode.
	///@param {Array} _nodes			Nodes or ids, row by row
	///@param {Real} _columns			Number of columns
	///@param {Bool} [_wrap_h]			Wrap rows (default false)
	///@param {Bool} [_wrap_v]			Wrap columns (default false)
	///@returns {Struct.MiniNodeNavGroup}	Self for chaining
	static nav_link_grid = function(_nodes, _columns, _wrap_h = false, _wrap_v = false)
	{
		var _len = array_length(_nodes);
		if (_len == 0 || _columns <= 0) return self;

		for (var _i = 0; _i < _len; _i++)
		{
			var _node = __resolve_target(_nodes[_i]);
			if (_node == noone || _node.nav_item == noone) continue;

			var _item = _node.nav_item;
			var _col = _i mod _columns;
			var _row_start = _i - _col;
			var _row_end = min(_row_start + _columns, _len) - 1;

			// Right
			if (_i < _row_end)		_item.set_link("right", _nodes[_i + 1]);
			else if (_wrap_h)		_item.set_link("right", _nodes[_row_start]);

			// Left
			if (_i > _row_start)	_item.set_link("left", _nodes[_i - 1]);
			else if (_wrap_h)		_item.set_link("left", _nodes[_row_end]);

			// Down
			if (_i + _columns < _len)	_item.set_link("down", _nodes[_i + _columns]);
			else if (_wrap_v)			_item.set_link("down", _nodes[_col]);

			// Up
			if (_i - _columns >= 0)		_item.set_link("up", _nodes[_i - _columns]);
			else if (_wrap_v)
			{
				var _last = _col;
				while (_last + _columns < _len) _last += _columns;
				_item.set_link("up", _nodes[_last]);
			}
		}
		return self;
	}

	#endregion

	#region Cache

	///@function						nav_refresh()
	///@description						Collect the items again and rebuild the cached automatic links.
	///									Runs automatically when the structure/layout changes; call it after moving items by code.
	///@returns {Struct.MiniNodeNavGroup}	Self for chaining
	static nav_refresh = function()
	{
		// Detach old items
		var _old_len = array_length(__items);
		for (var _i = 0; _i < _old_len; _i++)
		{
			var _old = __items[_i].nav_item;
			if (_old != noone && _old.group == self) _old.group = noone;
		}

		__items = [];
		__collect_items(owner, __items);

		var _count = array_length(__items);
		var _rects = array_create(_count);
		for (var _i = 0; _i < _count; _i++)
		{
			_rects[_i] = __layout_rect(__items[_i]);
		}

		for (var _i = 0; _i < _count; _i++)
		{
			var _auto = __items[_i].nav_item.__auto_links;
			for (var _d = 0; _d < 4; _d++)
			{
				_auto[$ __dir_names[_d]] = (mode == NODE_NAV_MODE.AUTO) ? __find_auto_neighbor(_i, _d, _rects) : noone;
			}
		}

		__dirty = false;
		return self;
	}

	///@function						nav_get_items()
	///@description						Get the cached navigation items of this group
	///@returns {Array<Struct.MiniNode>}
	static nav_get_items = function()
	{
		if (__dirty) nav_refresh();
		return __items;
	}

	///@function						__collect_items(_node, _result)
	///@description						Pre-order collection of item nodes, skipping subtrees with their own group
	static __collect_items = function(_node, _result)
	{
		var _children = _node.__nested_nodes;
		var _len = array_length(_children);
		for (var _i = 0; _i < _len; _i++)
		{
			var _child = _children[_i];
			if (_child.nav_group != noone) continue;

			if (_child.nav_item != noone)
			{
				_child.nav_item.group = self;
				array_push(_result, _child);
			}
			__collect_items(_child, _result);
		}
	}

	///@function						__layout_rect(_node)
	///@description						Item center and size in layout space (unscaled local positions relative to the group owner).
	///									Ignores scale/alpha so animations do not affect navigation.
	///@returns {Struct}				{x, y, w, h}
	static __layout_rect = function(_node)
	{
		var _x = 0, _y = 0;
		var _current = _node;
		while (_current != noone && _current != owner)
		{
			_x += _current.local_transform.x;
			_y += _current.local_transform.y;
			_current = _current.parent;
		}

		var _w = _node.fixed_transform.width,
			_h = _node.fixed_transform.height;
		var _factor = NODE_ORIGIN_CONVERSION[_node.origin];

		return {
			x: _x + _w * (_factor[0] + 0.5),
			y: _y + _h * (_factor[1] + 0.5),
			w: _w,
			h: _h
		};
	}

	///@function						__find_auto_neighbor(_index, _dir, _rects)
	///@description						Find the best neighbour of an item in a direction.
	///									Score = distance along the direction, plus a penalty when the items do not overlap on the perpendicular axis.
	///@returns {String|Constant.noone}	Node id
	static __find_auto_neighbor = function(_index, _dir, _rects)
	{
		var _a = _rects[_index];
		var _vx = __dir_x[_dir],
			_vy = __dir_y[_dir];
		var _horizontal = (_vx != 0);
		var _count = array_length(_rects);

		var _best = -1,
			_best_score = infinity;

		for (var _j = 0; _j < _count; _j++)
		{
			if (_j == _index) continue;

			var _b = _rects[_j];
			var _dx = _b.x - _a.x,
				_dy = _b.y - _a.y;

			var _primary = _dx * _vx + _dy * _vy;
			if (_primary <= 0.5) continue;

			var _perp = _horizontal ? abs(_dy) : abs(_dx);
			var _overlap = _horizontal ? (abs(_dy) < (_a.h + _b.h) * 0.5) : (abs(_dx) < (_a.w + _b.w) * 0.5);
			var _score = _primary + (_overlap ? 0 : _perp * 2) + _perp * 0.01;

			if (_score < _best_score)
			{
				_best_score = _score;
				_best = _j;
			}
		}

		// Wrap: farthest aligned item in the opposite direction
		if (_best < 0 && (_horizontal ? wrap_h : wrap_v))
		{
			_best_score = infinity;
			for (var _j = 0; _j < _count; _j++)
			{
				if (_j == _index) continue;

				var _b = _rects[_j];
				var _dx = _b.x - _a.x,
					_dy = _b.y - _a.y;

				var _back = -(_dx * _vx + _dy * _vy);
				if (_back <= 0.5) continue;

				var _perp = _horizontal ? abs(_dy) : abs(_dx);
				var _overlap = _horizontal ? (abs(_dy) < (_a.h + _b.h) * 0.5) : (abs(_dx) < (_a.w + _b.w) * 0.5);
				if (!_overlap) continue;

				var _score = -_back + _perp * 0.01;
				if (_score < _best_score)
				{
					_best_score = _score;
					_best = _j;
				}
			}
		}

		return (_best >= 0) ? __items[_best] : noone;
	}

	#endregion

	#region Neighbours

	///@function						get_neighbor(_node, _direction)
	///@description						Resolve the node reached from an item in a direction.
	///									Priority: blocked > manual link > automatic link (AUTO mode). Unavailable targets are skipped
	///									by following their own link in the same direction.
	///@param {Struct.MiniNode|String} _node	Source item
	///@param {String} _direction		"up", "down", "left" or "right"
	///@returns {Struct.MiniNode|Constant.noone}
	static get_neighbor = function(_node, _direction)
	{
		_node = __resolve_target(_node);
		if (_node == noone || _node.nav_item == noone) return noone;
		if (_node.nav_item.blocked[$ _direction]) return noone;
		if (__dirty) nav_refresh();

		var _current = _node;
		repeat (array_length(__items) + 1)
		{
			var _target = __resolve_target(__resolve_link(_current.nav_item, _direction));
			if (_target == noone || _target == _node || _target.nav_item == noone) return noone;
			if (_target.nav_item.is_available()) return _target;
			_current = _target;
		}
		return noone;
	}

	///@function						__resolve_target(_target)
	///@description						Resolve a node reference or id: ids are searched in this group's subtree first, then globally
	///@returns {Struct.MiniNode|Constant.noone}
	static __resolve_target = function(_target)
	{
		if (is_struct(_target)) return _target;
		if (!is_string(_target)) return noone;
		
		var _found = owner.node_find(_target);
		return (_found != noone) ? _found : mnd_node_get(_target);
	}
	
	///@function						__resolve_link(_item, _direction)
	///@returns {Struct.MiniNode|String|Constant.noone}	Raw link (node, id or noone)
	static __resolve_link = function(_item, _direction)
	{
		var _manual = _item.links[$ _direction];
		if (_manual != noone) return _manual;
		if (mode == NODE_NAV_MODE.AUTO) return _item.__auto_links[$ _direction];
		return noone;
	}

	///@function						__opposite(_direction)
	///@returns {String}
	static __opposite = function(_direction)
	{
		switch (_direction)
		{
			case "up":		return "down";
			case "down":	return "up";
			case "left":	return "right";
			case "right":	return "left";
		}
		return _direction;
	}

	#endregion

	#region Selection

	///@function						select(_node)
	///@description						Select an item of this group
	///@param {Struct.MiniNode|String} _node	Node or node id
	///@returns {Struct.MiniNode|Constant.noone}	The selected node
	static select = function(_node)
	{
		_node = __resolve_target(_node);
		if (_node == noone || _node == selected) return selected;
		if (_node.nav_item == noone || !_node.nav_item.is_available()) return selected;

		deselect();
		selected = _node;
		_node.nav_item.__set_selected(true);

		return selected;
	}

	///@function						deselect()
	///@description						Deselect the current item
	///@returns {Struct.MiniNodeNavGroup}	Self for chaining
	static deselect = function()
	{
		if (selected == noone) return self;

		var _item = selected.nav_item;
		selected = noone;

		if (_item != noone)
		{
			_item.is_pressed = false;
			_item.__set_selected(false);
		}
		return self;
	}

	///@function						select_default()
	///@description						Select the default item, or the first available item
	///@returns {Struct.MiniNode|Constant.noone}
	static select_default = function()
	{
		if (__dirty) nav_refresh();

		var _default = __resolve_target(default_node);
		if (__is_own_available_item(_default)) return select(_default);

		var _len = array_length(__items);
		for (var _i = 0; _i < _len; _i++)
		{
			if (__items[_i].nav_item.is_available()) return select(__items[_i]);
		}
		return noone;
	}

	///@function						__select_initial()
	///@description						Select the last selected item (if remember_last) or the default one
	static __select_initial = function()
	{
		if (remember_last)
		{
			var _last = last_selected;
			if (__is_own_available_item(_last)) return select(_last);
		}
		return select_default();
	}

	///@function						__is_own_available_item(_node)
	///@returns {Bool}
	static __is_own_available_item = function(_node)
	{
		return _node != noone
			&& _node.nav_item != noone
			&& _node.nav_item.group == self
			&& _node.nav_item.is_available();
	}

	#endregion

	#region Focus

	///@function			has_focus()
	///@description			Check if this group is on top of the focus stack
	///@returns {Bool}
	static has_focus = function()
	{
		return mnd_nav_has_focus(owner);
	}

	///@function			__on_focus_gained()
	///@description			Called by the focus stack when this group becomes the focused one
	static __on_focus_gained = function()
	{
		if (__dirty) nav_refresh();
		on_focus_gained.invoke();

		if (mnd_input_is_button()) __select_initial();
	}

	///@function			__on_focus_lost()
	///@description			Called by the focus stack when this group stops being the focused one
	static __on_focus_lost = function()
	{
		if (selected != noone) last_selected = selected;
		deselect();
		on_focus_lost.invoke();
	}

	#endregion

	#region Input

	///@function			__process_input()
	///@description			Process input for this group. Called once per frame by obj_node_manager, only for the focused group.
	static __process_input = function()
	{
		if (__dirty) nav_refresh();

		// Drop a selection that is no longer valid
		if (selected != noone && !__is_own_available_item(selected))
		{
			deselect();
		}

		__process_cursor_input();
		__process_button_input();
		__process_action_input();
	}

	///@function			__point_in_node(_x, _y, _node)
	///@description			Check if a point is inside a node's drawn bounding box
	///@returns {Bool}
	static __point_in_node = function(_x, _y, _node)
	{
		var _x_origin = _node.transform.x + _node.sys_origin_offset[0],
			_y_origin = _node.transform.y + _node.sys_origin_offset[1];

		return point_in_rectangle(_x, _y, _x_origin, _y_origin, _x_origin + _node.transform.width, _y_origin + _node.transform.height);
	}

	///@function			__process_cursor_input()
	///@description			Mouse/touch: hover selects the topmost item under the cursor
	static __process_cursor_input = function()
	{
		if (!cursor_input || !mnd_input_is_cursor() || mnd_input_is_blocked(MND_BLOCK.CURSOR_NAV)) return;

		var _cx = global.mnd_input.cursor_x(),
			_cy = global.mnd_input.cursor_y();

		// Topmost = last collected (drawn last)
		var _hovered = noone;
		for (var _i = array_length(__items) - 1; _i >= 0; _i--)
		{
			var _node = __items[_i];
			if (!_node.nav_item.is_available()) continue;

			if (__point_in_node(_cx, _cy, _node))
			{
				_hovered = _node;
				break;
			}
		}

		if (_hovered != noone)
		{
			select(_hovered);
		}
		else if (selected != noone && !selected.nav_item.is_pressed)
		{
			// Keep the selection while pressed (e.g. dragging a slider outside its bounds)
			deselect();
		}
	}

	///@function			__process_button_input()
	///@description			Gamepad/keyboard: directional navigation
	static __process_button_input = function()
	{
		if (!button_input || !mnd_input_is_button() || mnd_input_is_blocked(MND_BLOCK.BUTTON_NAV)) return;
		if (mnd_input_is_consumed()) return;

		if (selected == noone)
		{
			__select_initial();
			return;
		}

		var _mov = global.mnd_input.navigate();
		var _x = _mov[0],
			_y = _mov[1];
		if (_x == 0 && _y == 0) return;

		// Listeners can consume the input (e.g. slider changing its value)
		if (selected.nav_item.__receive_navigation(_x, _y)) return;

		var _dir = "";
		if (abs(_x) > abs(_y))		_dir = (_x > 0) ? "right" : "left";
		else if (abs(_y) > abs(_x))	_dir = (_y > 0) ? "down" : "up";
		if (_dir == "") return;

		var _target = get_neighbor(selected, _dir);
		if (_target != noone) select(_target);
	}

	///@function			__process_action_input()
	///@description			Accept press/release on the selected item
	static __process_action_input = function()
	{
		if (mnd_input_is_action_blocked() || mnd_input_is_consumed()) return;
		if (selected == noone) return;

		var _item = selected.nav_item;

		if (global.mnd_input.accept_pressed())
		{
			_item.is_pressed = true;
			_item.on_action_pressed.invoke();
		}

		// Release only fires for an item that was pressed (avoids clicks carried over from another group)
		if (_item.is_pressed && global.mnd_input.accept_released())
		{
			_item.is_pressed = false;
			_item.on_action_released.invoke();
		}
	}

	#endregion

	#region Lifecycle

	owner.nav_group = self;

	// Auto focus when the owner is enabled (also fires on init for nodes that start enabled)
	owner.on_enabled.connect(self, function()
	{
		if (auto_focus && mnd_nav_get_focused_node() == noone)
		{
			mnd_nav_steal_focus(owner);
		}
	});

	#endregion
}
