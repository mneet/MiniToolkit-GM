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
		if (!owner.processor.is_initialized) return; // Never draw before the init phases ran

		// Resolve transform changes made after the step (e.g. on_enabled fired by an input/transition handler),
		// otherwise the node is drawn one frame with its stale transform. Parent resolves before children.
		owner.__resolve_transform();

		// Clipping: only touch the scissor when this node clips (no per-node GPU state/allocations otherwise)
		var _scissor = undefined;
		if (__clip_node_content)
		{
			_scissor = gpu_get_scissor();
			
			// Intersect with the current scissor so nested clips never escape their parent clip
			var _x1 = owner.transform.x + owner.sys_origin_offset[0],
				_y1 = owner.transform.y + owner.sys_origin_offset[1];
			var _x2 = min(_x1 + owner.transform.width, _scissor.x + _scissor.w),
				_y2 = min(_y1 + owner.transform.height, _scissor.y + _scissor.h);
			_x1 = max(_x1, _scissor.x);
			_y1 = max(_y1, _scissor.y);
			
			gpu_set_scissor(_x1, _y1, max(0, _x2 - _x1), max(0, _y2 - _y1));
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
			
		// Restore scissor
		if (_scissor != undefined) gpu_set_scissor(_scissor);
		
		// DEBUG DRAWS
		if (global.__mnd_debug.draw_size) debug_draw_size();
		if (global.__mnd_debug.draw_origin) debug_draw_origin();
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