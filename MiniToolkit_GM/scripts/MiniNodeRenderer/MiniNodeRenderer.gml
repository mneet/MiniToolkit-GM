///@function					MiniNodeRenderer(_owner)
///@description					Rendering component that handles drawing a node and its children.
///								Supports custom draw functions and content clipping.
///@param {Struct.MiniNode} [_owner]	The node that owns this renderer
function MiniNodeRenderer(_owner = noone) constructor
{
	owner = _owner;
	
	__custom_draw_function = function (_node) {};	// Custom draw callback
	__skip_draw = false;							// Flag to skip rendering
	__clip_node_content = false;					// Enable scissor clipping
	
	///@function		__draw_node()
	///@description		Main draw function - draws self and all children recursively.
	///					Uses `visible` flag to control rendering (separate from `enabled`).
	static __draw_node = function()
	{
		if (__skip_draw) return;
		if (!owner.visible || !owner.is_enabled()) return;
		
		// Save current scissor state for restoration
		var _scissor = gpu_get_scissor();
		
		// Apply clipping if enabled
		if (__clip_node_content)
		{
			var _x = owner.transform.x + owner.sys_origin_offset[0],
				_y = owner.transform.y + owner.sys_origin_offset[1];
			
			gpu_set_scissor(_x, _y, owner.transform.width, owner.transform.height);
		}
		
		// Draw self
		if (__custom_draw_function != noone) 
		{
			__custom_draw_function(owner);
		}
		
		// Draw children nodes (optimized array access)
		var _children = owner.__nested_nodes;
		var _len = array_length(_children);
		for (var _i = 0; _i < _len; _i++)
		{ 
			_children[_i].renderer.__draw_node();
		}
			
		// Reset scissor
		gpu_set_scissor(_scissor);
		
		// DEBUG DRAWS
		if (MND_DEBUG_SIZE) debug_draw_size();
		if (MND_DEBUG_ORIGIN) debug_draw_origin();
	}
	
	#region DEBUG
	
	static debug_draw_size = function(_node = owner)
	{
		var _origin_x = _node.transform.x + _node.sys_origin_offset[0],
			_origin_y = _node.transform.y + _node.sys_origin_offset[1];
		
		var _size_x = _origin_x + _node.transform.width,
			_size_y = _origin_y + _node.transform.height;
			
		draw_rectangle(_origin_x, _origin_y, _size_x, _size_y, true);
	}
	
	static debug_draw_origin = function(_node = owner)
	{
		var _origin_x = _node.transform.x + _node.sys_origin_offset[0],
			_origin_y = _node.transform.y + _node.sys_origin_offset[1];
			
		draw_circle_color(_origin_x, _origin_y, 5, c_red, c_red, false);
		draw_circle_color(_node.transform.x, _node.transform.y, 5, c_orange, c_orange, false);
	}
	
	#endregion
	
	#region UTILITY
	
	///@function								render_set_custom_draw(_draw_function)
	///@description								Set a custom draw function for this node's rendering
	///@param {Function} _draw_function			Callback function that receives the node as parameter: function(_node)
	///@returns {Struct.MiniNodeRenderer}			Self for method chaining
	static render_set_custom_draw = function(_draw_function)
	{
		if (is_callable(_draw_function))
		{
			__custom_draw_function = _draw_function;	
		}
		return self;
	}
	
	///@function							render_clip_draw()
	///@description							Enable scissor clipping to constrain child rendering within node bounds
	///@returns {Struct.MiniNodeRenderer}		Self for method chaining
	static render_clip_draw = function()
	{
		__clip_node_content = true;
		return self;
	}
	
	#endregion
}