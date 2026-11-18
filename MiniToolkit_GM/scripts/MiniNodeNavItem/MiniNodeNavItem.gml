///@function						MiniNodeNavItem(_owner)
///@description						Navigation component that makes a node selectable inside a MiniNodeNavGroup.
///									Stores manual links, blocked directions, selection state and input events.
///									The owning group is assigned automatically when the group collects its items.
///@param {Struct.MiniNode} [_owner]	The node that owns this item
function MiniNodeNavItem(_owner = noone) constructor
{
	owner = _owner;
	group = noone;				// MiniNodeNavGroup that currently owns this item (set by the group)

	// State
	selectable = true;			// If false, the item is skipped by navigation and cursor hover
	is_selected = false;
	is_pressed = false;			// True between action pressed and action released

	// Selection events
	on_selected = new MiniEvent();
	on_deselected = new MiniEvent();

	// Action events
	on_action_pressed = new MiniEvent();
	on_action_released = new MiniEvent();

	// Navigation event - receives (x, y) input axes. Call consume_navigation() to cancel the default movement.
	on_navigated = new MiniEvent();

	// Manual links (node references, or ids resolved inside the group subtree). Have priority over automatic links.
	links = { up: noone, down: noone, left: noone, right: noone };

	// Blocked directions - navigation never leaves this item in a blocked direction
	blocked = { up: false, down: false, left: false, right: false };

	// Automatic links (node references) - cached and rebuilt by MiniNodeNavGroup.nav_refresh()
	__auto_links = { up: noone, down: noone, left: noone, right: noone };

	__navigation_consumed = false;

	#region Links

	///@function							set_link(_direction, _node)
	///@description							Manually link a direction to a node. Pass noone to clear the manual link.
	///@param {String} _direction			"up", "down", "left" or "right"
	///@param {Struct.MiniNode|String} _node	Target node or node id (noone to clear). Ids are resolved when navigating.
	///@returns {Struct.MiniNodeNavItem}	Self for chaining
	static set_link = function(_direction, _node)
	{
		links[$ _direction] = (_node == undefined) ? noone : _node;
		return self;
	}

	///@function							set_links(_up, _down, _left, _right)
	///@description							Set several manual links at once. undefined keeps the current link, noone clears it.
	///@param {Struct.MiniNode|String} [_up]
	///@param {Struct.MiniNode|String} [_down]
	///@param {Struct.MiniNode|String} [_left]
	///@param {Struct.MiniNode|String} [_right]
	///@returns {Struct.MiniNodeNavItem}	Self for chaining
	static set_links = function(_up = undefined, _down = undefined, _left = undefined, _right = undefined)
	{
		if (_up != undefined)		set_link("up", _up);
		if (_down != undefined)		set_link("down", _down);
		if (_left != undefined)		set_link("left", _left);
		if (_right != undefined)	set_link("right", _right);
		return self;
	}

	///@function							clear_links()
	///@description							Remove all manual links (automatic links are used again)
	///@returns {Struct.MiniNodeNavItem}	Self for chaining
	static clear_links = function()
	{
		links.up = noone;
		links.down = noone;
		links.left = noone;
		links.right = noone;
		return self;
	}

	///@function							block(_direction, _blocked)
	///@description							Block or unblock navigation leaving this item in a direction
	///@param {String} _direction			"up", "down", "left" or "right"
	///@param {Bool} [_blocked]				True to block (default true)
	///@returns {Struct.MiniNodeNavItem}	Self for chaining
	static block = function(_direction, _blocked = true)
	{
		blocked[$ _direction] = _blocked;
		return self;
	}

	///@function							block_all(_up, _down, _left, _right)
	///@description							Set the blocked state of every direction
	///@returns {Struct.MiniNodeNavItem}	Self for chaining
	static block_all = function(_up = false, _down = false, _left = false, _right = false)
	{
		blocked.up = _up;
		blocked.down = _down;
		blocked.left = _left;
		blocked.right = _right;
		return self;
	}

	#endregion

	#region State

	///@function							set_selectable(_selectable)
	///@description							Allow or prevent this item from being selected.
	///										A selected item that becomes unselectable is deselected by its group on the next input frame.
	///@param {Bool} _selectable
	///@returns {Struct.MiniNodeNavItem}	Self for chaining
	static set_selectable = function(_selectable)
	{
		selectable = _selectable;
		return self;
	}

	///@function			is_available()
	///@description			Check if this item can be selected right now (selectable and owner enabled)
	///@returns {Bool}
	static is_available = function()
	{
		return selectable && owner.is_enabled();
	}

	///@function			consume_navigation()
	///@description			Call inside an on_navigated callback to cancel the default directional movement
	static consume_navigation = function()
	{
		__navigation_consumed = true;
	}

	///@function			focus_group()
	///@description			Give navigation focus to the group that owns this item
	///@returns {Struct.MiniNodeNavItem}	Self for chaining
	static focus_group = function()
	{
		if (group != noone) mnd_nav_steal_focus(group.owner);
		return self;
	}

	#endregion

	#region Internal

	///@function			__set_selected(_selected)
	///@description			Change the selection state and fire events (called by MiniNodeNavGroup)
	static __set_selected = function(_selected)
	{
		if (is_selected == _selected) return;

		is_selected = _selected;
		if (_selected) on_selected.invoke();
		else on_deselected.invoke();
	}

	///@function			__receive_navigation(_x, _y)
	///@description			Fire on_navigated and report if a listener consumed the input
	///@returns {Bool}		True if the default navigation must be cancelled
	static __receive_navigation = function(_x, _y)
	{
		__navigation_consumed = false;
		on_navigated.invoke(_x, _y);
		return __navigation_consumed;
	}

	#endregion
}
