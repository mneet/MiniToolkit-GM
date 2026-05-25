function __node_container(_name, _origin  = NODE_ORIGIN.MIDDLE_CENTER) : node(_name, _origin) constructor
{
	pattern = noone;
	type = noone;
		
	margin = new Vector2(0,0);
	start_margin = new Vector2(0,0);
		
	add_component_renderer();	
	add_component_processor();
	
	///@function				__container_organize()
	///@description				Organize nested nodes in the right pattern
	__container_organize = function()
	{
		// DO SOMETHING	
	}
	
	#region UTILITY
	
	///@function				container_set_margin(_x, _y)
	///@description				Set the margin between nodes
	///@param {real} _x			Horizontal margin 
	///@param {real} _y			Vertical margin
	static container_set_margin = function(_x, _y)
	{
		margin.x = _x;
		margin.y = _y;
		
		start_margin = variable_clone(margin);
		return self;
	}
	
	#endregion
		
	custom_awake = function()
	{
		margin.x = start_margin.x * transform.scale.x;
		margin.y = start_margin.y * transform.scale.y;
		
		__container_organize();		
		__node_get_system_origin_offset();
	}
}

///@function						node_container_horizontal(_name, _origin, _pattern)
///@description						Create an container node that distributes its nested nodes in an horizontal box
///@param {string} _name			Name used for identify the node
///@param {real} [_pattern]			Pattern that nested nodes will be placed using NODE_HORIZONTAL_PATTERN enum
///@param {real} [_origin]			Determines the anchor point of the node using NODE_ORIGIN enum
function node_container_horizontal(_name, _pattern = NODE_HORIZONTAL_PATTERN.LEFT_RIGHT, _origin = NODE_ORIGIN.MIDDLE_CENTER) : __node_container(_name, _origin) constructor
{
	pattern = _pattern;
	type = NODE_CONTAINER.HORIZONTAL;	
	origin = _origin;
	
	__container_organize = function()
	{
		var _container_w = 0,
			_container_h = 0;
			
		for (var _i = 0; _i < nested_nodes_amnt; _i++)
		{
			var _node = nested_nodes[_i];
			_container_h = _node.transform.fixed.size.y > _container_h ? _node.transform.fixed.size.y : _container_h;
			_container_w += _node.transform.fixed.size.x;
			_container_w += _i > 0 ?  margin.x : 0;
		}
		
		node_set_size(_container_w, _container_h);
		
		var _filled_width = 0;
		
		for (var _i = 0; _i < nested_nodes_amnt; _i++)
		{
			var _node = nested_nodes[_i];
			
			var _node_origin_x =  _node.system_origin_offset.x;
			var _node_origin_y =  _node.system_origin_offset.y;			
			
			var _node_converted_origin = _node.node_get_converted_origin(origin);
			
			var _x = (system_origin_offset.x) + (_node_origin_x * -1);
			var _y = (_node_converted_origin.y * -1);
			
			show_debug_message(transform.fixed.size)
			switch (pattern)
			{
				case NODE_HORIZONTAL_PATTERN.LEFT_RIGHT:
					_filled_width += _i > 0 ?  margin.x : 0;
					_x += (_filled_width);
					_filled_width += _node.transform.fixed.size.x;
					break;
				
				case NODE_HORIZONTAL_PATTERN.RIGHT_LEFT:
					_filled_width += _i > 0 ?  margin.x : 0;
					_x += (transform.size.x - _node.transform.size.x) - (_filled_width);
					_filled_width += _node.transform.fixed.size.x;
					break;				
			}
			
			_node.node_set_position(_x, _y);
			_node.transform.__containter_update();
			_node.__node_get_system_origin_offset();
		}
	}
	
}

///@function						node_container_vertical(_name, _origin, _pattern)
///@description						Create an container node that distributes its nested nodes in an vertical box
///@param {string} _name			Name used for identify the node
///@param {real} [_pattern]			Pattern that nested nodes will be placed using NODE_VERTICAL_PATTERN enum
///@param {real} [_origin]			Determines the anchor point of the node using NODE_ORIGIN enum
function node_container_vertical(_name, _pattern = NODE_VERTICAL_PATTERN.UP_DOWN, _origin = NODE_ORIGIN.MIDDLE_CENTER) : __node_container(_name, _origin) constructor
{
	pattern = _pattern;
	type = NODE_CONTAINER.VERTICAL;	
	
	__container_organize = function()
	{
		var _container_w = 0,
			_container_h = 0;
			
		for (var _i = 0; _i < nested_nodes_amnt; _i++)
		{
			var _node = nested_nodes[_i];
			_container_w = _node.transform.fixed.size.y > _container_w ? _node.transform.fixed.size.x : _container_w;
			_container_h += _node.transform.fixed.size.y;
			_container_h += _i > 0 ?  margin.y : 0;
		}
		
		node_set_size(_container_w, _container_h);
		
		var _filled_height = 0;		
		
		for (var _i = 0; _i < nested_nodes_amnt; _i++)
		{
			var _node = nested_nodes[_i];
			
			var _node_origin_x = _node.system_origin_offset.x;
			var _node_origin_y = _node.system_origin_offset.y;
			
			var _node_converted_origin = _node.node_get_converted_origin(origin);

			var _y = (system_origin_offset.y) + (_node_origin_y * -1);
			var _x = (_node_converted_origin.x * -1);

			switch (pattern)
			{
				case NODE_VERTICAL_PATTERN.UP_DOWN:
					_filled_height += _i > 0 ?  margin.y : 0;
					_y += (_filled_height);
					_filled_height += _node.transform.fixed.size.y;
					break;
				
				case NODE_VERTICAL_PATTERN.DOWN_UP:
					_filled_height += _i > 0 ?  margin.x : 0;
					_y += (transform.fixed.size.y - _node.transform.fixed.size.y) - (_filled_height);
					_filled_height += _node.transform.fixed.size.y;
					break;				
			}
			
			_node.node_set_position(_x, _y);
			_node.transform.__containter_update();
			_node.__node_get_system_origin_offset();
		}
	}

}

///@function						node_container_grid(_name, _origin, _pattern)
///@description						Create an container node that distributes its nested nodes in an vertical box
///@param {string} _name			Name used for identify the node
///@param {struct} _grid_dimension	Number of rows and columns of the grid in a Vector2
///@param {struct} _cell_size		Size in pixels of each cell using an Vector2
///@param {real} [_pattern]			Pattern that nested nodes will be placed using NODE_GRID_PATTERN enum
///@param {real} [_origin]			Determines the anchor point of the node using NODE_ORIGIN enum
function node_container_grid(_name, _grid_dimension, _cell_size, _pattern = NODE_GRID_PATTERN.RIGHT_DOWN, _origin = NODE_ORIGIN.MIDDLE_CENTER) : __node_container(_name,_origin) constructor
{
	pattern = _pattern;
	type = NODE_CONTAINER.GRID;	
	
	grid_dimension = _grid_dimension;
	grid_cell_size = _cell_size;
	grid_size = new Vector2(0,0);
	
	
	__container_organize = function()
	{
		grid_size.x = (grid_cell_size.x * grid_dimension.x) + (margin.x * grid_dimension.x) - margin.x;
		grid_size.y = (grid_cell_size.y * grid_dimension.y) + (margin.y * grid_dimension.y) - margin.y;
		
		node_set_size(grid_size.x, grid_size.y);
					
		var _filled_height = 0;
		
		var _node_ind = 0;
		
		var _container_origin_x = system_origin_offset.x,
			_container_origin_y	= system_origin_offset.y;
		for (var _y = 0; _y < grid_dimension.y; _y++)
		{
			var _filled_width = 0;
			for (var _x = 0; _x < grid_dimension.x; _x++)
			{
				if (_node_ind >= nested_nodes_amnt) break;
				var _node = nested_nodes[_node_ind];		
				
				var _cell_x = _container_origin_x;
				var _cell_y = _container_origin_y;
				
				switch (pattern)
				{
					case NODE_GRID_PATTERN.LEFT_DOWN:
						_cell_x += (grid_size.x - grid_cell_size.x) + (_node.system_origin_offset.x * - 1) - ((grid_cell_size.x * _x));
						_cell_y += (_node.system_origin_offset.y * - 1) + (grid_cell_size.y * _y);
						break;
					case NODE_GRID_PATTERN.LEFT_UP:
 						_cell_x += (grid_size.x - grid_cell_size.x) + (_node.system_origin_offset.x * - 1) - ((grid_cell_size.x * _x));
						_cell_y += (grid_size.y - grid_cell_size.y) + (_node.system_origin_offset.y * - 1) - ((grid_cell_size.y * _y));
						break;
					case NODE_GRID_PATTERN.RIGHT_DOWN:
						_cell_x += (_node.system_origin_offset.x * - 1) + (grid_cell_size.x * _x);
						_cell_y += (_node.system_origin_offset.y * - 1) + (grid_cell_size.y * _y);
						break;
					case NODE_GRID_PATTERN.RIGHT_UP:
						_cell_x +=(_node.system_origin_offset.x * - 1) + (grid_cell_size.x * _x);
						_cell_y += (grid_size.y - grid_cell_size.y) + (_node.system_origin_offset.y * - 1) - ((grid_cell_size.y * _y));
						break;
				}
				
				_cell_x += margin.x * _x;
				_cell_y += margin.y * _y;
				_node.node_set_position(_cell_x, _cell_y);
				_node.transform.__containter_update();
				_node.__node_get_system_origin_offset();
				_node_ind++;
				
			}	
		}
	}
}
