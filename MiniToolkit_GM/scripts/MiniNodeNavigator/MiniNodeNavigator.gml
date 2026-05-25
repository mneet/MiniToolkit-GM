///@function						MiniNodeNavigator(_owner)
///@description						Navigation component that enables navigation between nodes.
///									Stores directional links and focus state.
///									Uses parent_module (MiniNodeNavCenter) for navigation context.
///@param {Struct.MiniNode} [_owner]	The node that owns this navigator
function MiniNodeNavigator(_owner = noone) constructor
{
	owner = _owner;
    parent_module = noone;		// Cached reference to parent MiniNodeNavCenter
	is_selected = false;			// Current focus state
	
	// Focus events
	on_node_selected = new MiniEvent();
	on_node_deselected = new MiniEvent();
	
	// Action events
	on_action_pressed = new MiniEvent();
	on_action_released = new MiniEvent();

	// Navigation events
	on_navigated = new MiniEvent();

	// Navigation directions - stores node IDs
	directions = {
		up: noone,
		down: noone,
		left: noone,
		right: noone
	};
	
	// Track which directions were manually set
	manual_overrides = {
		up: false,
		down: false,
		left: false,
		right: false
	};
	
	// Blocked directions - prevents navigation in specific directions
	blocked_directions = {
		up: false,
		down: false,
		left: false,
		right: false
	};

	__navigation_input_consumed = false
	
	#region Navigation Callbacks

	///@function					__on_navigation_input_received(_x, _y)
	///@description					Internal callback for when navigation input is received
	///@param {Real} _x				Horizontal input axis value
	///@param {Real} _y				Vertical input axis value
	static __on_navigation_input_received = function(_x, _y)
	{	
		// Reset consumption flag	
		__navigation_input_consumed = false;

		on_navigated.invoke(_x, _y);
		
		// If input was not consumed by any event, perform default navigation
		if (!__navigation_input_consumed) 
		{
			__navigate_to(_x, _y);
		}
	}

	///@function					__navigate_to(_x, _y)
	///@description					Navigate to the node in the given direction based on input axes
	///@param {Real} _x				Horizontal input axis value
	///@param {Real} _y				Vertical input axis value
	static __navigate_to = function(_x, _y)
	{
		var _dir = "";
		if (abs(_x) > abs(_y))
		{
			_dir = _x > 0 ? "right" : "left";
		}
		else if (abs(_y) > abs(_x))	
		{
			_dir = _y > 0 ? "down" : "up";
		}

		if (blocked_directions[$ _dir]) return;

		var _target = directions[$ _dir];
		if (_target != noone)
		{
			var _module = get_module();
			if (_module != noone)
			{
				_module.select_node(_target);
			}
		}
	}

	#endregion

	#region Direction Configuration
	
	///@function						set_direction(_direction, _node)
	///@description						Set a navigation direction to point to a specific node
	///@param {string} _direction		Direction name: "up", "down", "left", "right"
	///@param {Struct.MiniNode|String} _node	Target node reference or node ID
	///@returns {Struct.MiniNodeNavigator} 	Self for chaining
	static set_direction = function(_direction, _node)
	{
		// Store as ID if node reference was passed
		if (is_string(_node))
		{
			directions[$ _direction] = _node;
		}
		else if (_node != noone && _node != undefined)
		{
			directions[$ _direction] = _node.id;
		}
		else
		{
			directions[$ _direction] = noone;
		}
		
		// Mark as manually set to prevent auto-rebuild override
		manual_overrides[$ _direction] = true;
		return self;
	}
	
	///@function						set_directions(_up, _down, _left, _right)
	///@description						Set all navigation directions at once
	///@param {Struct.MiniNode|String} _up		Target node or ID for up direction
	///@param {Struct.MiniNode|String} _down	Target node or ID for down direction
	///@param {Struct.MiniNode|String} _left	Target node or ID for left direction
	///@param {Struct.MiniNode|String} _right	Target node or ID for right direction
	///@returns {Struct.MiniNodeNavigator} 	Self for chaining
	static set_directions = function(_up = noone, _down = noone, _left = noone, _right = noone)
	{
		set_direction("up", _up);
		set_direction("down", _down);
		set_direction("left", _left);
		set_direction("right", _right);
		return self;
	}
	
	///@function						block_direction(_direction, _blocked)
	///@description						Block or unblock a specific direction
	///@param {string} _direction		Direction name: "up", "down", "left", "right"
	///@param {Bool} _blocked			Whether to block (true) or unblock (false) the direction
	///@returns {Struct.MiniNodeNavigator} 	Self for chaining
	static block_direction = function(_direction, _blocked = true)
	{
		blocked_directions[$ _direction] = _blocked;
		return self;
	}
	
	///@function						block_directions(_up, _down, _left, _right)
	///@description						Set blocked state for all directions
	///@param {Bool} _up				Block up direction
	///@param {Bool} _down				Block down direction
	///@param {Bool} _left				Block left direction
	///@param {Bool} _right				Block right direction
	///@returns {Struct.MiniNodeNavigator} Self for chaining
	static block_directions = function(_up = false, _down = false, _left = false, _right = false)
	{
		blocked_directions.up = _up;
		blocked_directions.down = _down;
		blocked_directions.left = _left;
		blocked_directions.right = _right;
		return self;
	}
	
	#endregion
	
	#region Selection/Focus
	
	///@function							select()
	///@description							Select this node (called by navigation module)
	///@returns {Struct.MiniNodeNavigator}	Self for chaining
	static select = function()
	{
		if (is_selected) return self;
		
		is_selected = true;
		on_node_selected.invoke();
		
		return self;
	}
	
	///@function							deselect()
	///@description							Remove selection from this node (called by navigation module)
	///@returns {Struct.MiniNodeNavigator}	Self for chaining
	static deselect = function()
	{
		if (!is_selected) return self;
		
		is_selected = false;
		on_node_deselected.invoke();
		
		return self;
	}
	
	
	#endregion
	
	#region Module Utility
	
	///@function					get_module()
	///@description					Find the parent navigation module by walking up the tree.
	///								Looks for ancestors that have a `navigation` (MiniNodeNavCenter).
	///@returns {Struct.MiniNodeNavCenter|Noone}	Parent module or noone
	static get_module = function()
	{
        return parent_module;
	}

	///@function							set_module(_module)
	///@description							Manually set the parent navigation module reference
	///@param {Struct.MiniNodeNavCenter} _module	Module reference
	///@returns {Struct.MiniNodeNavigator}		Self for chaining
	static set_module = function(_module)
	{
		parent_module = _module;
		return self;
	}
	
	#endregion
}
