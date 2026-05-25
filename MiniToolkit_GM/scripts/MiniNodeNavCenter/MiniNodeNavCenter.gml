///@function							MiniNodeNavCenter(_owner, _depth)
///@description							Standalone navigation component that can be attached to any MiniNode.
///										Manages navigable child nodes, directional links, input processing, and focus.
///										Only ONE NavCenter receives input at a time (the one with focus).
///@param {Struct.MiniNode} _owner		The node that owns this navigation module
function MiniNodeNavCenter(_owner) constructor
{
	owner = _owner;

	// Focus state
	has_focus = false;
	
	// Navigation state
	nav_node_selected = noone;
	nav_default_node_id = noone;
	nav_last_selected_node_id = noone;
	__navigable_nodes = [];
	
	// Configuration
	nav_tolerance = 20;			// Pixels of tolerance for directional matching
	button_input = true;		// Enable gamepad/keyboard navigation
	cursor_input = true;		// Enable mouse/cursor navigation
	
	#region MiniNode Selection
	
	///@function					select_node(_node)
	///@description					Select a navigable node
	///@param {Struct.MiniNode|String} _node	The node to select (reference or ID string)
	///@returns {Struct.MiniNode|Undefined}	The selected node or undefined
	static select_node = function(_node)
	{
		// Resolve node if string id was passed
		if (is_string(_node)) _node = mnd_get_node(_node);
		
		// Validate node
		if (_node == undefined || _node == noone || _node == nav_node_selected) return undefined;
		if (_node.navigator == noone) return undefined;
		
		// Deselect current node first
		deselect_node();
		
		// Select new node
		nav_node_selected = _node;
		nav_node_selected.navigator.select();
		

		return nav_node_selected;
	}
	
	///@function					deselect_node()
	///@description					Deselect the currently selected node
	static deselect_node = function()
	{
		if (nav_node_selected != noone && nav_node_selected.navigator != noone)
		{
			nav_node_selected.navigator.deselect();
		}
        
        nav_node_selected = noone;
	}
	
	///@function					select_default()
	///@description					Select the default navigation node
	static select_default = function()
	{
		// Fall back to default node
		if (nav_default_node_id != noone)
		{
			select_node(nav_default_node_id);
		}
		else if (array_length(__navigable_nodes) > 0)
		{
			select_node(__navigable_nodes[0]);
		}
	}
	
	#endregion
	
	#region Navigation Building
	
	///@function					__collect_navigable_nodes()
	///@description					Recursively collect all nodes with navigator component from owner subtree
	///@returns {Array<Struct.MiniNode>}	Array of navigable nodes
	static __collect_navigable_nodes = function()
	{
		var _result = [];
		var _stack = [owner];
		
		while (array_length(_stack) > 0)
		{
			var _current = array_pop(_stack);
			var _children = _current.node_get_children();
			var _len = array_length(_children);
			
			for (var _i = 0; _i < _len; _i++)
			{
				var _child = _children[_i];
				
				// Skip subtrees that have their own nav center
				if (_child.nav_module != noone) continue;
				
				if (_child.navigator != noone)
				{
					array_push(_result, _child);
					_child.navigator.set_module(self);
				}
				
				// Continue descending into this child's subtree
				array_push(_stack, _child);
			}
		}
		
		return _result;
	}
	
	///@function					build_directions()
	///@description					Build navigation directions for all navigable nodes.
	///								Also sets parent_module on each navigator.
	static build_directions = function()
	{
		__navigable_nodes = __collect_navigable_nodes();
		var _count = array_length(__navigable_nodes);
		
		if (_count == 0) return;
		
		// Set module reference on each navigator
		for (var _i = 0; _i < _count; _i++)
		{
			__navigable_nodes[_i].navigator.parent_module = self;
		}
		
		// For each navigable node, find closest neighbors in each direction
		for (var _i = 0; _i < _count; _i++)
		{
			var _node = __navigable_nodes[_i];
			var _nx = _node.transform.x;
			var _ny = _node.transform.y;
			
			var _closest_up = noone;
			var _closest_down = noone;
			var _closest_left = noone;
			var _closest_right = noone;
			
			var _dist_up = infinity;
			var _dist_down = infinity;
			var _dist_left = infinity;
			var _dist_right = infinity;
			
			// Compare against all other nodes
			for (var _j = 0; _j < _count; _j++)
			{
				if (_i == _j) continue;
				
				var _other = __navigable_nodes[_j];
				var _ox = _other.transform.x;
				var _oy = _other.transform.y;
				
				var _dx = _ox - _nx;
				var _dy = _oy - _ny;
				var _dist = point_distance(_nx, _ny, _ox, _oy);
				
				// Check RIGHT: other is to the right AND within vertical tolerance
				if (!_node.navigator.manual_overrides.right && _dx > 0 && abs(_dy) <= nav_tolerance)
				{
					if (_dist < _dist_right)
					{
						_dist_right = _dist;
						_closest_right = _other;
					}
				}
				
				// Check LEFT: other is to the left AND within vertical tolerance
				if (!_node.navigator.manual_overrides.left && _dx < 0 && abs(_dy) <= nav_tolerance)
				{
					if (_dist < _dist_left)
					{
						_dist_left = _dist;
						_closest_left = _other;
					}
				}
				
				// Check DOWN: other is below AND within horizontal tolerance
				if (!_node.navigator.manual_overrides.down && _dy > 0 && abs(_dx) <= nav_tolerance)
				{
					if (_dist < _dist_down)
					{
						_dist_down = _dist;
						_closest_down = _other;
					}
				}
				
				// Check UP: other is above AND within horizontal tolerance
				if (!_node.navigator.manual_overrides.up && _dy < 0 && abs(_dx) <= nav_tolerance)
				{
					if (_dist < _dist_up)
					{
						_dist_up = _dist;
						_closest_up = _other;
					}
				}
			}
			
			// Set navigation directions 
			_node.navigator.directions.up = _closest_up != noone ? _closest_up.id : noone;
			_node.navigator.directions.down = _closest_down != noone ? _closest_down.id : noone;
			_node.navigator.directions.left = _closest_left != noone ? _closest_left.id : noone;
			_node.navigator.directions.right = _closest_right != noone ? _closest_right.id : noone;
		}
		
		// Set default node if not already set
		if (nav_default_node_id == noone && _count > 0)
		{
			nav_default_node_id = __navigable_nodes[0].id;
		}
	}
	
	#endregion
	
	#region Input Handling
	
	///@function					__point_in_node(_x, _y, _node)
	///@description					Check if a point is inside a node's bounding box
	///@param {Real} _x				X coordinate
	///@param {Real} _y				Y coordinate
	///@param {Struct.MiniNode} _node	The node to check
	///@returns {Bool}				True if point is inside
	static __point_in_node = function(_x, _y, _node)
	{
		var _x_origin = _node.transform.x + _node.sys_origin_offset[0];
		var _y_origin = _node.transform.y + _node.sys_origin_offset[1];
		
		return point_in_rectangle(
			_x, 
			_y, 
			_x_origin,
			_y_origin,
			_x_origin + _node.transform.width,
			_y_origin + _node.transform.height
		);
	}
	
	///@function					__process_cursor_input()
	///@description					Handle mouse/cursor input for navigation
	static __process_cursor_input = function()
	{
		if (!cursor_input || !mnd_is_cursor_mode() || mnd_is_cursor_navigation_blocked()) return;
		
		var _count = array_length(__navigable_nodes);
		if (_count == 0) return;
		
		var _hovered_node = noone;
		
		// Find topmost node under cursor 
		for (var _i = _count - 1; _i >= 0; _i--)
		{
			var _node = __navigable_nodes[_i];
			if (!_node.is_enabled()) continue;
			
			if (__point_in_node(global.mnd_input.cursor_x(), global.mnd_input.cursor_y(), _node))
			{
				_hovered_node = _node;
				break;
			}
		}
		
		// Update selection based on hover state
		if (_hovered_node != noone)
		{
			if (_hovered_node != nav_node_selected)
			{
				select_node(_hovered_node);
			}
		}
		else if (nav_node_selected != noone)
		{
			var _is_pressed = variable_struct_exists(nav_node_selected, "button_is_pressed") 
				&& nav_node_selected.button_is_pressed;
			
			if (!_is_pressed)
			{
				deselect_node();
			}
		}
	}
	
	///@function					__process_button_input()
	///@description					Handle directional button/keyboard input for navigation
	static __process_button_input = function()
	{
		if (!button_input || !mnd_is_button_mode() || mnd_is_button_navigation_blocked()) return;

		// Select default if nothing selected
		if (nav_node_selected == noone)
		{
			select_default();
			return;
		}
		
		var _navigator = nav_node_selected.navigator;
		
		// Get navigation input
		var _mov = global.mnd_input.navigate();
		
		// Invoke directional events
		if (abs(_mov[0]) > 0 || abs(_mov[1]) > 0)
		{
			_navigator.__on_navigation_input_received(_mov[0], _mov[1]);	
		}
	}
	
	///@function					__process_action_input()
	///@description					Handle accept/cancel action input for the selected node
	static __process_action_input = function()
	{
		if (mnd_is_action_blocked()) return;
		if (mnd_is_input_consumed()) return;
		
		if (nav_node_selected == noone || nav_node_selected.navigator == noone) return;
		
		var _navigator = nav_node_selected.navigator;
		
		// Check for accept press
		if (global.mnd_input.accept_pressed())
		{
			_navigator.on_action_pressed.invoke();
		}
		
		// Check for accept release
		if (global.mnd_input.accept_released())
		{
			_navigator.on_action_released.invoke();
		}
	}
	
	///@function					__process_input()
	///@description					Handle input methods
	static __process_input = function()
	{
		if (!has_focus) return;
		
		__process_cursor_input();
		__process_button_input();
		__process_action_input();
	}	
	
	#endregion
	
	#region Focus Management
	
	///@function						gain_focus()
	///@description						Focus this navigator
	///@returns {Struct.MiniNodeNavCenter}	Self for chaining
	static gain_focus = function()
	{
		has_focus = true;
		
		if (mnd_is_button_mode())
		{
			if (nav_last_selected_node_id != noone) select_node(nav_last_selected_node_id);
			else select_default();
		}
		
		return self;
	}
	
	///@function						release_focus()
	///@description						Release navigation focus from this module.
	///@returns {Struct.MiniNodeNavCenter}	Self for chaining
	static release_focus = function()
	{
		has_focus = false;	
		
		// Store last selected node before releasing
		if (nav_node_selected != noone)
		{
			nav_last_selected_node_id = nav_node_selected.id;
		}
		
		deselect_node();	
		
		return self;
	}
	
	#endregion
	
	#region Configuration
	
	///@function						set_default_node(_node)
	///@description						Set the default node to select when module activates
	///@param {Struct.MiniNode|String} _node	MiniNode reference or node id string
	///@returns {Struct.MiniNodeNavCenter}	Self for chaining
	static set_default_node = function(_node)
	{
		if (is_string(_node))
		{
			nav_default_node_id = _node;
		}
		else if (_node != noone && _node != undefined)
		{
			nav_default_node_id = _node.id;
		}
		else
		{
			nav_default_node_id = noone;
		}
		return self;
	}
	
	///@function						set_tolerance(_tolerance)
	///@description						Set the directional tolerance for navigation
	///@param {Real} _tolerance			Pixels of tolerance
	///@returns {Struct.MiniNodeNavCenter}	Self for chaining
	static set_tolerance = function(_tolerance)
	{
		nav_tolerance = _tolerance;
		return self;
	}
	
	///@function						set_button_input(_enabled)
	///@description						Enable or disable button/keyboard navigation
	///@returns {Struct.MiniNodeNavCenter}	Self for chaining
	static set_button_input = function(_enabled)
	{
		button_input = _enabled;
		return self;
	}
	
	///@function						set_cursor_input(_enabled)
	///@description						Enable or disable cursor/mouse navigation
	///@returns {Struct.MiniNodeNavCenter}	Self for chaining
	static set_cursor_input = function(_enabled)
	{
		cursor_input = _enabled;
		return self;
	}
		
	///@function						rebuild_navigation()
	///@description						Rebuild cached navigable nodes and directional links
	///@returns {Struct.MiniNodeNavCenter}	Self for chaining
	static rebuild_navigation = function()
	{
		build_directions();
		return self;
	}
	
	#endregion
	
	#region Lifecycle
	
	// Register input processes on the owner's processor
	owner.processor.add_process(method(self, __process_input), false, 0, false);
	
	// Build directions on owner post_init
	owner.processor.on_post_init.connect(self, function()
	{
		build_directions();
		
		// Auto-request focus if no module currently has focus
		if (mnd_nav_get_focused_module() == undefined)
		{
			mnd_nav_set_focus(owner);
		}
	});
	
	// Set the navigation reference on the owner
	owner.nav_module = self;
	
	#endregion
}
