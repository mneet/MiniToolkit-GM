#region ENUMs n Macros
/// Horizontal flow direction for MiniNodeContainer
enum NODE_HFLOW
{
	LEFT = -1,		// ← Right to left
	RIGHT = 1		// → Left to right (default)
}

/// Vertical flow direction for MiniNodeContainer
enum NODE_VFLOW
{
	UP = -1,		// ↑ Bottom to top
	DOWN = 1		// ↓ Top to bottom (default)
}

/// Primary axis for MiniNodeContainer fill order
enum NODE_AXIS
{
	HORIZONTAL,		// Fill horizontally first, then next row
	VERTICAL		// Fill vertically first, then next column
}
#endregion

#region Structs

///@function						MiniNodeContainer(_name, _columns, _origin)
///@description						A container node that automatically arranges its children in a grid/list layout.
///									Supports horizontal/vertical flow directions and primary axis control.
///@param {String} _name			Unique identifier for this node
///@param {Real} [_columns]			Number of columns (0 = single row, 1 = single column, N = grid)
///@param {Enum.NODE_ORIGIN} [_origin]	Anchor point for positioning
function MiniNodeContainer(_name, _columns = 0, _origin = MND_CONTAINER_DEFAULT_ORIGIN) : MiniNode(_name, _origin) constructor
{
	// Layout configuration
	columns = _columns;						// 0 = unlimited columns (horizontal list)
	h_flow = NODE_HFLOW.RIGHT;				// Horizontal fill direction
	v_flow = NODE_VFLOW.DOWN;				// Vertical fill direction
	primary_axis = NODE_AXIS.HORIZONTAL;	// Which axis fills first
	
	// Spacing between children
	spacing = { x: 0, y: 0 };
	__base_spacing = { x: 0, y: 0 };
	
	// Padding around content inside the container
	padding = { x: 0, y: 0 };
	
	// Origin override for children (noone = use each child's own origin)
	__children_origin_override = noone;
	
	// Size mode
	auto_size = true;						// true = container resizes to fit content
	
	// Calculated layout info
	__layout_width = 0;
	__layout_height = 0;
	__row_heights = [];
	__col_widths = [];
	
	__organized_once = false;

	#region CONFIGURATION
	
	///@function				container_set_spacing(_x, _y)
	///@description				Set the spacing between child nodes
	///@param {Real} _x			Horizontal spacing in pixels
	///@param {Real} _y			Vertical spacing in pixels
	///@returns {Struct.MiniNodeContainer} Self for chaining
	static container_set_spacing = function(_x, _y)
	{
		__base_spacing.x = _x;
		__base_spacing.y = _y;
		spacing.x = _x;
		spacing.y = _y;
		return self;
	}
	
	///@function				container_set_padding(_x, _y)
	///@description				Set internal padding around the content area
	///@param {Real} _x			Horizontal padding in pixels
	///@param {Real} _y			Vertical padding in pixels
	///@returns {Struct.MiniNodeContainer} Self for chaining
	static container_set_padding = function(_x, _y)
	{
		padding.x = _x;
		padding.y = _y;
		return self;
	}
	
	///@function				container_set_columns(_columns)
	///@description				Set the number of columns (0 = unlimited, 1 = vertical list, N = grid)
	///@param {Real} _columns	Number of columns
	///@returns {Struct.MiniNodeContainer} Self for chaining
	static container_set_columns = function(_columns)
	{
		columns = _columns;
		return self;
	}
	
	///@function				container_set_flow(_h_flow, _v_flow, _primary_axis)
	///@description				Set the flow directions and primary axis
	///@param {Enum.NODE_HFLOW} _h_flow		Horizontal direction
	///@param {Enum.NODE_VFLOW} _v_flow		Vertical direction
	///@param {Enum.NODE_AXIS} [_primary]	Which axis fills first
	///@returns {Struct.MiniNodeContainer} Self for chaining
	static container_set_flow = function(_h_flow, _v_flow, _primary_axis = NODE_AXIS.HORIZONTAL)
	{
		h_flow = _h_flow;
		v_flow = _v_flow;
		primary_axis = _primary_axis;
		return self;
	}
	
	///@function								container_override_children_origin(_origin)
	///@description								Override the origin used for positioning all children within their cells.
	///											By default (noone), each child's own origin determines its alignment.
	///											Set to a NODE_ORIGIN value to force all children to align the same way.
	///@param {Enum.NODE_ORIGIN|Constant.noone} _origin	Origin to force, or noone to use each child's own
	///@returns {Struct.MiniNodeContainer} Self for chaining
	static container_override_children_origin = function(_origin)
	{
		__children_origin_override = _origin;
		return self;
	}
	
	///@function				container_set_auto_size(_enabled)
	///@description				Enable or disable auto-sizing to fit content.
	///							When disabled, the container keeps its set size.
	///@param {Bool} _enabled	True to auto-size (default), false for fixed size
	///@returns {Struct.MiniNodeContainer} Self for chaining
	static container_set_auto_size = function(_enabled)
	{
		auto_size = _enabled;
		return self;
	}
	
	#endregion
	
	#region LAYOUT SYSTEM
	
	///@function				container_layout()
	///@description				Recalculate and apply layout positions for all children.
	///							Call this after adding/removing children or changing sizes at runtime.
	///@returns {Struct.MiniNodeContainer} Self for chaining
	static container_layout = function()
	{
		__container_organize();
		return self;
	}
	
	///@function				__container_organize()
	///@description				Calculate and apply layout positions for all children
	static __container_organize = function()
	{
		var _children = __nested_nodes;
		var _count = array_length(_children);
		
		if (_count == 0) return;

		for (var _i = 0; _i < _count; _i++)
		{
			if (is_instanceof(_children[_i], MiniNodeContainer))
			{
				_children[_i].__container_organize();
			}
		}
		__organized_once = true;
	
		// Scale spacing
		var _spacing_x = __base_spacing.x * abs(transform.image_xscale);
		var _spacing_y = __base_spacing.y * abs(transform.image_yscale);
		spacing.x = _spacing_x;
		spacing.y = _spacing_y;
		
		// Scale padding
		var _padding_x = padding.x * abs(transform.image_xscale);
		var _padding_y = padding.y * abs(transform.image_yscale);
		
		// Calculate grid dimensions
		var _cols = columns <= 0 ? _count : columns;
		var _rows = ceil(_count / _cols);
		
		// Calculate cell sizes from children
		__row_heights = array_create(_rows, 0);
		__col_widths = array_create(_cols, 0);
		
		for (var _i = 0; _i < _count; _i++)
		{
			var _node = _children[_i];
			
			var _col, _row;
			if (primary_axis == NODE_AXIS.HORIZONTAL)
			{
				_col = _i mod _cols;
				_row = _i div _cols;
			}
			else
			{
				_row = _i mod _rows;
				_col = _i div _rows;
			}
			
			var _w = _node.fixed_transform.width * abs(_node.transform.image_xscale);
			var _h = _node.fixed_transform.height * abs(_node.transform.image_yscale);
			
			__col_widths[_col] = max(__col_widths[_col], _w);
			__row_heights[_row] = max(__row_heights[_row], _h);
		}
		
		// Calculate total content size
		__layout_width = 0;
		__layout_height = 0;
		
		for (var _i = 0; _i < _cols; _i++) __layout_width += __col_widths[_i];
		for (var _i = 0; _i < _rows; _i++) __layout_height += __row_heights[_i];
		
		__layout_width += _spacing_x * max(0, _cols - 1);
		__layout_height += _spacing_y * max(0, _rows - 1);
		
		// Update container size
		if (auto_size)
		{
			var _total_w = __layout_width + _padding_x * 2;
			var _total_h = __layout_height + _padding_y * 2;
			
			var _abs_sx = abs(transform.image_xscale);
			var _abs_sy = abs(transform.image_yscale);
			
			fixed_transform.width = _abs_sx != 0 ? _total_w / _abs_sx : _total_w;
			fixed_transform.height = _abs_sy != 0 ? _total_h / _abs_sy : _total_h;
			transform.width = _total_w;
			transform.height = _total_h;
		}
		
		// Recalculate origin offset after size is set
		__transform_set_system_origin_offset();
		
		// Position children
		__position_children(_children, _count, _cols, _rows, _spacing_x, _spacing_y, _padding_x, _padding_y);
	}
	
	///@function				__position_children(...)
	///@description				Position all children based on calculated cell sizes, flow, alignment
	static __position_children = function(_children, _count, _cols, _rows, _spacing_x, _spacing_y, _padding_x, _padding_y)
	{
		// Container's TOP_LEFT position
		var _base_x = sys_origin_offset[0] + _padding_x;
		var _base_y = sys_origin_offset[1] + _padding_y;
		
		// Adjust starting position based on flow direction
		var _start_x = (h_flow == NODE_HFLOW.LEFT) ? _base_x + __layout_width : _base_x;
		var _start_y = (v_flow == NODE_VFLOW.UP) ? _base_y + __layout_height : _base_y;
		
		var _cumulative_y = 0;
		
		for (var _row = 0; _row < _rows; _row++)
		{
			var _cumulative_x = 0;
			var _row_h = __row_heights[_row];
			
			for (var _col = 0; _col < _cols; _col++)
			{
				// Get child index based on primary axis
				var _idx = (primary_axis == NODE_AXIS.HORIZONTAL) 
					? _row * _cols + _col 
					: _col * _rows + _row;
				
				if (_idx >= _count) continue;
				
				var _node = _children[_idx];
				var _col_w = __col_widths[_col];
				
				// Calculate cell TOP_LEFT position
				var _cell_x = (h_flow > 0) 
					? _start_x + _cumulative_x 
					: _start_x - _cumulative_x - _col_w;
					
				var _cell_y = (v_flow > 0) 
					? _start_y + _cumulative_y 
					: _start_y - _cumulative_y - _row_h;
				
				// Get child dimensions
				var _node_w = _node.fixed_transform.width * abs(_node.transform.image_xscale);
				var _node_h = _node.fixed_transform.height * abs(_node.transform.image_yscale);
				
				// Determine the origin used for cell alignment
				var _cell_origin = (__children_origin_override != noone) ? __children_origin_override : _node.origin;
				var _cell_factor = NODE_ORIGIN_CONVERSION[_cell_origin];
				
				// Align child within cell using origin factors (0 = start, -0.5 = center, -1 = end)
				_cell_x += (_col_w - _node_w) * (-_cell_factor[0]);
				_cell_y += (_row_h - _node_h) * (-_cell_factor[1]);
				
				// Get child's own origin offset and calculate final position
				var _factor = NODE_ORIGIN_CONVERSION[_node.origin];
				var _node_x = _cell_x - (_node_w * _factor[0]);
				var _node_y = _cell_y - (_node_h * _factor[1]);
				
				_node.node_set_transform_attribute("x", _node_x);
				_node.node_set_transform_attribute("y", _node_y);
				
				_cumulative_x += _col_w + _spacing_x;
			}
			
			_cumulative_y += _row_h + _spacing_y;
		}
	}
	
	#endregion
	
	#region INITIALIZATION
	
	// Organize children on init and on update
	processor.on_init.connect(self, function()
	{
		if (!__organized_once) __container_organize();
	}, false, 100);
	
	
	#endregion
}

#endregion
