// A renderer is made to be used inside a Node
// It can store sprites or text to be displayed in the interface

function __node_renderer() constructor
{
	owner = noone;
	custom_draw = noone;
	skip_draw = false;
	///@function				draw(_node)
	///@description				Call the drawing function of the given node
	///@param {struct} _node	Parent node of the renderer
	draw = function(_node = owner)
	{
		if (_node.__skip_render) return;
		
		if (custom_draw != noone) custom_draw(_node);
		
		for (var _i = 0; _i < owner.nested_nodes_amnt; _i++)
		{
			var _element = owner.nested_nodes[owner.nested_depth_order[_i]];
			_element.renderer.draw(_element);
		}
		
		if (global.node_manager.debug_size) debug_draw_size();
		if (global.node_manager.debug_origin) debug_draw_origin();

	}
		
	debug_draw_size = function(_node = owner)
	{
		var _origin_x = _node.transform.position.x + _node.system_origin_offset.x,
			_origin_y = _node.transform.position.y + _node.system_origin_offset.y;
		
		var _size_x = _origin_x + _node.transform.fixed.size.x,
			_size_y = _origin_y + _node.transform.fixed.size.y;
			
		draw_rectangle(_origin_x, _origin_y, _size_x, _size_y, true);
	}
	
	debug_draw_origin = function(_node = owner)
	{
		var _origin_x = _node.transform.position.x + _node.system_origin_offset.x,
			_origin_y = _node.transform.position.y + _node.system_origin_offset.y;
			
		draw_circle_color(_origin_x, _origin_y, 5, c_red, c_red, false);
		draw_circle_color(_node.transform.position.x, _node.transform.position.y, 5, c_orange, c_orange, false);
	}
		
	static set_custom_draw = function(_draw_function)
	{
		if (is_callable(_draw_function))
		{
			custom_draw = _draw_function;	
		}
		return self;
	}

	__awake_renderer = function()
	{
		//Do nothing by default
	}	
}