///@function						node_canvas(_name, _origin)
///@description						Create an canvas node to start an interface 
///@param {string} _name			Name used for identify the node
///@param {real} [_origin]			Determines the anchor point of the node using NODE_ORIGIN enum
function node_canvas(_name, _origin = NODE_ORIGIN.MIDDLE_CENTER) : node(_name,_origin) constructor
{
	add_component_renderer();
	add_component_processor();
		
	#region Navigation Brain
	
	nav_position = new Vector2(0,0);
	nav_node_selected = noone;
	nav_grid = [];
	nav_grid_dimension = new Vector2();
	nav_default_path = noone;
	nav_grid_cell_size = variable_clone(global.node_manager.nav_grid_cell_size);
	
	button_input = true;
	cursor_input = true;
	cursor_navigation = false;
	
	__grid_initiated = false;
	__bt_selected_this_frame = false;
	
	///@function					nav_select_node(_path, _play_sound)
	///@description					Select an given node 
	///@param {string} _path		Node path to be selected
	///@param {bool} _play_sound	IF the selection sound should be played
	static nav_select_node = function(_path, _play_sound = true)
	{
		if (__bt_selected_this_frame) return;
		
		if (!is_array(_path)) return;
		
		if (nav_node_selected != noone)
		{
			nav_node_selected.navigator.select_node();
		}
		nav_node_selected = node_find_by_path(_path);
		if (nav_node_selected != noone)
		{
			nav_node_selected.navigator.select_node(_play_sound);
			nav_position = variable_clone(nav_node_selected.transform.position);
			if (!input_compare_mode(INPUT_MODE.MOUSE) && !cursor_navigation)
			{
				input_set_cursor(variable_clone(nav_node_selected.transform.position));
			}
			__bt_selected_this_frame = true;
		}
	}
	
	///@function					nav_deselect_node()
	///@description					Remove the navigation selection from the current select node
	static nav_deselect_node = function()
	{
		if (nav_node_selected != noone)
		{
			nav_node_selected.navigator.select_node();
		}
		nav_node_selected = noone;
	}
	
	#region GRID BUILDER
	
	///@function					__nav_build_grid()
	///@description					Build the initial navigation grid
	static __nav_build_grid = function()
	{
		var _grid = [];
		var _row = floor(transform.fixed.size.x / nav_grid_cell_size.x),
			_column = floor(transform.fixed.size.y / nav_grid_cell_size.y);
		
		for (var _y = 0; _y < _column; _y++)
		{
			for (var _x = 0; _x < _row; _x++)
			{
				_grid[_x, _y] = noone;
			}
		}
		
		nav_grid = _grid;
		nav_grid_dimension.x = _row;
		nav_grid_dimension.y = _column;
	}
	
	///@function					__nav_snap_to_grid(_position)
	///@description					Snap a pixel position to a grid coordinate
	static __nav_snap_to_grid = function(_position)
	{
		var _grid_pos = new Vector2();
		var _origin_x = transform.fixed.position.x + system_origin_offset.x,
			_origin_y = transform.fixed.position.y + system_origin_offset.y;
			
		var _right_x = _origin_x + transform.fixed.size.x,
			_down_y = _origin_y + transform.fixed.size.y;
			
		if (_position.x > _right_x || _position.x < _origin_x)
		{
			_grid_pos = false;
		}
		else if (_position.y > _down_y || _position.y < _origin_y)
		{
			_grid_pos = false;
		}
		
		if (_grid_pos != false)
		{
			_grid_pos.x = abs(round(_position.x / nav_grid_cell_size.x));
			_grid_pos.y = abs(round(_position.y / nav_grid_cell_size.y));
		}
		
		return _grid_pos;
	}	
	
	///@function					__nav_clean_grid(_grid)
	///@description					Clean empty rows and columns from the grid
	static __nav_clean_grid = function(_grid = nav_grid)
	{
		
		var _temp_grid = variable_clone(_grid);
		var _delete_row = [];
		var _delete_column = [];

		// Verificar linhas vazias
		for (var _y = 0; _y < nav_grid_dimension.y; _y++) {
		    var _row_filled = false;
		    for (var _x = 0; _x < nav_grid_dimension.x; _x++) {
		        var _cell = _temp_grid[_x, _y];
		        if (_cell != noone) {
		            _row_filled = true;
		            break; // Não precisa continuar se já encontrou um valor preenchido
		        }
		    }
		    if (!_row_filled) {
		        array_push(_delete_row, _y);
		    }
		}

		// Verificar colunas vazias
		for (var _x = 0; _x < nav_grid_dimension.x; _x++) {
		    var _column_filled = false;
		    for (var _y = 0; _y < nav_grid_dimension.y; _y++) {
		        var _cell = _temp_grid[_x, _y];
		        if (_cell != noone) {
		            _column_filled = true;
		            break; // Não precisa continuar se já encontrou um valor preenchido
		        }
		    }
		    if (!_column_filled) {
		        array_push(_delete_column, _x);
		    }
		}

		// Deletar as linhas identificadas
		for (var i = array_length(_delete_row) - 1; i >= 0; i--) {
		    var _row = _delete_row[i];
		    for (var _x = 0; _x < nav_grid_dimension.x; _x++) {
		        array_delete(_temp_grid[_x], _row, 1); // Remove a linha das colunas
		    }
		}

		// Deletar as colunas identificadas
		for (var i = array_length(_delete_column) - 1; i >= 0; i--) {
		    var _column = _delete_column[i];
		    array_delete(_temp_grid, _column, 1); // Remove a coluna inteira
		}	
				
		
		nav_grid_dimension.x = array_length(_temp_grid);
		if (array_length(_temp_grid) > 0)
		{
			nav_grid_dimension.y = array_length(_temp_grid[0]);
		}
		
		return _temp_grid;
	}
	
	///@function					__nav_fill_holes(_grid)
	///@description					Fill holes in the grid with noone value
	static __nav_fill_holes = function(_grid = nav_grid)
	{
		for (var _x = 0; _x < nav_grid_dimension.x; _x++)
		{
			var _size = array_length(_grid[_x]);
			
			if (_size < nav_grid_dimension.y)
			{
				var _diff = nav_grid_dimension.y - _size;
				for (var _i = 0; _i < _diff; _i++)
				{
					array_push(_grid[_x], noone);	
				}
			}
		}
		
		return _grid;
	}
	
	///@function					__populate_nav_grid()
	///@description					Populate navigation grid with canvas nodes
	static __populate_nav_grid = function()
	{	
		var _path_cells = __get_navigation_paths();
				
		var _len = array_length(_path_cells); 
		for (var _i = 0; _i < _len; _i++)
		{
			var _cell = _path_cells[_i];
			var _grid_snap = __nav_snap_to_grid(_cell.position);
			if (_grid_snap != false) nav_grid[_grid_snap.x, _grid_snap.y] = variable_clone(_cell.path);
		}
				
		if (_len > 0) 
		{
			nav_grid = __nav_clean_grid();
			nav_grid = __nav_fill_holes();
		}
		else nav_grid = noone;	
	}
	
	#region NAV SEARCH
	
	static __nav_grid_find_cell_up = function(_origin_y, _x_search, _y_search, _grow_width = true)
	{
		var _node_check = noone;
		for (var _width = 0; _width < nav_grid_dimension.x; _width++)
		{			
			for (var _y = _y_search; _y >= 0; _y--)
			{
				if (_width > 0 && _grow_width)
				{
					var _left = _x_search - _width,
						_right = _x_search + _width;
					_left = clamp(_left, 0, nav_grid_dimension.x -1);
					_right = clamp(_right, 0, nav_grid_dimension.x -1);
					
					var _check_l = nav_grid[_left, _y];
					var _check_r = nav_grid[_right, _y];
					
					_node_check = _check_r != noone ? _check_r : _check_l;
					if (_node_check != noone && _origin_y != _y) break;
					else _node_check = noone;
				}
				else
				{
					_node_check = nav_grid[_x_search, _y];
					if (_node_check != noone && _origin_y != _y) break;
					else _node_check = noone;
				}
			}
			if (_node_check != noone) break;
		}
		return _node_check;		
	}
	
	static __nav_grid_find_cell_down = function(_origin_y, _x_search, _y_search, _grow_width = true)
	{
		var _node_check = noone;
		for (var _width = 0; _width < nav_grid_dimension.x; _width++)
		{			
			for (var _y = _y_search; _y < nav_grid_dimension.y; _y++)
			{
				if (_width > 0 && _grow_width)
				{
					var _left = _x_search - _width,
						_right = _x_search + _width;
					_left = clamp(_left, 0, nav_grid_dimension.x -1);
					_right = clamp(_right, 0, nav_grid_dimension.x -1);
					
					var _check_l = nav_grid[_left, _y];
					var _check_r = nav_grid[_right, _y];				
					_node_check = _check_r != noone ? _check_r : _check_l;
					
					if (_node_check != noone && _origin_y != _y) break;
					else _node_check = noone;
				}
				else
				{
					
					if (array_length(nav_grid[_x_search]) <= _y) break;
					
					_node_check = nav_grid[_x_search, _y];
					if (_node_check != noone && _origin_y != _y) break;
					else _node_check = noone;
				}
			}
			if (_node_check != noone) break
		}
		return _node_check;		
	}
	
	static __nav_grid_find_cell_left = function(_origin_x, _x_search, _y_search, _grow_height = true)
	{
		var _node_check = noone;
		for (var _height = 0; _height < nav_grid_dimension.y; _height++)
		{			
			for (var _x = _x_search; _x >= 0; _x--)
			{
				if (_height > 0 && _grow_height)
				{
					var _up = _y_search - _height,
						_down = _y_search + _height;
						
					_up = clamp(_up, 0, nav_grid_dimension.y - 1);
					_down = clamp(_down, 0, nav_grid_dimension.y - 1);
					
					var _check_u = nav_grid[_x, _up];
					var _check_d = nav_grid[_x, _down];				
					_node_check = _check_d != noone ? _check_d : _check_u;
					
					if (_node_check != noone && _origin_x != _x) break;
					else _node_check = noone;
				}
				else
				{
					_node_check = nav_grid[_x, _y_search];
					if (_node_check != noone && _origin_x != _x) break;
					else _node_check = noone;
				}
			}
			if (_node_check != noone) break
		}
		return _node_check;		
	}
	
	static __nav_grid_find_cell_right = function(_origin_x, _x_search, _y_search, _grow_height = true)
	{
		var _node_check = noone;
		for (var _height = 0; _height < nav_grid_dimension.y; _height++)
		{			
			for (var _x = _x_search; _x < nav_grid_dimension.x; _x++)
			{
				if (_height > 0 && _grow_height)
				{
					var _up = _y_search - _height,
						_down = _y_search + _height;
						
					_up = clamp(_up, 0, nav_grid_dimension.y - 1);
					_down = clamp(_down, 0, nav_grid_dimension.y - 1);
					
					var _check_u = nav_grid[_x, _up];
					var _check_d = nav_grid[_x, _down];				
					_node_check = _check_d != noone ? _check_d : _check_u;
					
					if (_node_check != noone && _origin_x != _x) break;
					else _node_check = noone;
				}
				else
				{
					if (array_length(nav_grid[_x]) <= _y_search) break;
					
					_node_check = nav_grid[_x, _y_search];
					if (_node_check != noone && _origin_x != _x) break;
					else _node_check = noone;
				}
			}
			if (_node_check != noone) break
		}
		return _node_check;		
	}
	
	static __nav_grid_search_cell_up = function(_cell_x, _cell_y)
	{
		var _path = noone;
		
		var _start_y = _cell_y - 1;
		_start_y = qwrap(_start_y, 0, nav_grid_dimension.y - 1);
		
		var _wrapped = _start_y >= _cell_y ? true : false;
		
		_path = __nav_grid_find_cell_up(_cell_y, _cell_x, _start_y, false);
		if (_path != noone) return _path;
		
		_path = __nav_grid_find_cell_up(_cell_y, _cell_x, _start_y, true);
		if (_path != noone) return _path;
		
		if (!_wrapped)
		{
			_path = __nav_grid_find_cell_up(_cell_y, _cell_x, nav_grid_dimension.y - 1, false);
			if (_path != noone) return _path;
		
			_path = __nav_grid_find_cell_up(_cell_y, _cell_x, nav_grid_dimension.y - 1, true);
			if (_path != noone) return _path;
		}	
		
		return _path
	}
	
	static __nav_grid_search_cell_down = function(_cell_x, _cell_y)
	{
		var _path = noone;
		
		var _start_y = _cell_y + 1;
		_start_y = qwrap(_start_y, 0, nav_grid_dimension.y - 1);
		
		var _wrapped = _start_y >= _cell_y ? true : false;
		
		_path = __nav_grid_find_cell_down(_cell_y, _cell_x, _start_y, false);
		if (_path != noone) return _path;
		
		_path = __nav_grid_find_cell_down(_cell_y, _cell_x, _start_y, true);
		if (_path != noone) return _path;
		
		if (!_wrapped)
		{
			_path = __nav_grid_find_cell_down(_cell_y, _cell_x, 0, false);
			if (_path != noone) return _path;
		
			_path = __nav_grid_find_cell_down(_cell_y, _cell_x, 0, true);
			if (_path != noone) return _path;
		}	
		
		return _path
	}
	
	static __nav_grid_search_cell_left = function(_cell_x, _cell_y)
	{
		var _path = noone;
		
		var _start_x = _cell_x - 1;
		_start_x = qwrap(_start_x, 0, nav_grid_dimension.x - 1);
		
		var _wrapped = _start_x >= _cell_x ? true : false;
		
		_path = __nav_grid_find_cell_left(_cell_x, _start_x, _cell_y, false);
		if (_path != noone) return _path;
		
		_path = __nav_grid_find_cell_left(_cell_x, _start_x, _cell_y, true);
		if (_path != noone) return _path;
		
		if (!_wrapped)
		{
			_path = __nav_grid_find_cell_left(_cell_x, nav_grid_dimension.x - 1, _cell_y, false);
			if (_path != noone) return _path;
			_path = __nav_grid_find_cell_left(_cell_x, nav_grid_dimension.x - 1, _cell_y, true);
			if (_path != noone) return _path;
		}	
		
		return _path
	}
	
	static __nav_grid_search_cell_right = function(_cell_x, _cell_y)
	{
		var _path = noone;
		
		var _start_x = _cell_x + 1;
		_start_x = qwrap(_start_x, 0, nav_grid_dimension.x - 1);
		
		var _wrapped = _start_x >= _cell_x ? true : false;
		
		_path = __nav_grid_find_cell_right(_cell_x, _start_x, _cell_y, false);
		if (_path != noone) return _path;
		
		_path = __nav_grid_find_cell_right(_cell_x, _start_x, _cell_y, true);
		if (_path != noone) return _path;
		
		if (!_wrapped)
		{
			_path = __nav_grid_find_cell_right(_cell_x, 0, _cell_y, false);
			if (_path != noone) return _path;
			
			_path = __nav_grid_find_cell_right(_cell_x, 0, _cell_y, true);
			if (_path != noone) return _path;
		}	
		
		return _path
	}
		
	#endregion
	
	///@function					__nav_build_navigations()
	///@description					Run system functions to build navigation grid
	static __nav_build_navigations = function()
	{
		
		for (var _y = 0; _y < nav_grid_dimension.y; _y++)
		{
			for (var _x = 0; _x < nav_grid_dimension.x; _x++)
			{
				var _cell = nav_grid[_x, _y];
				if (_cell != noone)
				{
					if (nav_default_path == noone) nav_default_path = variable_clone(_cell);
					
					var _node = node_find_by_path(_cell);
					_node.navigator.grid_position = new Vector2(_x, _y);
									
					var _path_up = __nav_grid_search_cell_up(_x, _y);
					var _path_down = __nav_grid_search_cell_down(_x, _y);
					var _path_left = __nav_grid_search_cell_left(_x, _y);					
					var _path_right = __nav_grid_search_cell_right(_x, _y);					
					
					_node.navigator.set_directions("up", _path_up);
					_node.navigator.set_directions("down", _path_down);
					_node.navigator.set_directions("left", _path_left);
					_node.navigator.set_directions("right", _path_right);
					
					//show_debug_message($"Connections for node {_node.name}\n   UP {_path_up}\n   DOWN {_path_down}\n   LEFT {_path_left}\n   RIGHT {_path_right}");
				}
			}
		}
	}
	
	#endregion
	
	#region INPUT
	
	///@function					__nav_input_manager()
	///@description					Handles grid input navigation
	static __nav_input_manager = function(_canvas)
	{
		if (global.node_manager.block_navigation || !_canvas.button_input) return;
		
		with (_canvas)
		{
			
			if (nav_grid == noone) return;
			
			if (nav_node_selected == noone) 
			{
				nav_select_node(nav_default_path, false);
				if (nav_node_selected == noone) return;
			}

		
			var _directions = nav_node_selected.navigator.directions,
				_blocked_dir = nav_node_selected.navigator.blocked_directions;
				
			var _mov_input = input_check_movement_accelerator();
						
			if (_mov_input.x > 0)
			{
				if (_directions.right != noone && !_blocked_dir.right) nav_select_node(_directions.right); 
			}
			else if (_mov_input.x < 0)
			{
				if (_directions.left != noone && !_blocked_dir.left) nav_select_node(_directions.left); 
			}
			else if (_mov_input.y > 0)
			{
				if (_directions.down != noone && !_blocked_dir.down) nav_select_node(_directions.down); 
			}
			else if (_mov_input.y < 0)
			{
				if (_directions.up != noone && !_blocked_dir.up) nav_select_node(_directions.up); 
			}
		}
	}	
	processor.add_process(__nav_input_manager);
	
	#endregion
	
	#region UTILITY
	
	///@function					navigation_set_grid_cell_size(_w, _h)
	///@description					Set the cell size of the navigation grid
	///@param {real} _w			Cell width
	///@param {real} _h			Cell height
	static navigation_set_grid_cell_size = function(_w, _h)
	{
		nav_grid_cell_size.x = _w;
		nav_grid_cell_size.y = _h;
		return self;
	}
	
	///@function					navigation_block_button_input()
	///@description					Block gamepad/keyboard input
	static navigation_block_button_input = function()
	{
		button_input = !button_input;
	}
	
	///@function					navigation_block_cursor_input()
	///@description					Block cursor input
	static navigation_block_cursor_input = function()
	{
		cursor_input = !cursor_input;
	}
	
	///@function					navigation_set_default_node(_node_name)
	///@description					Set the given node to be the default selected node when activating this canvas
	///@param {string} _node_name	Default node name
	static navigation_set_default_node = function(_node_name)
	{
		var _first_node = node_find_by_name(_node_name);
		if (_first_node != noone)
		{
			nav_default_path = _first_node.path;
		}
	}
	
	#endregion
	
	#endregion
	
	///@function					__nav_initiate_grid()
	///@description					Build grid, populate and select default node
	static __nav_initiate_grid = function()
	{
		__nav_build_grid();
		__populate_nav_grid();
		
		if (nav_grid != noone)
		{				
			__nav_build_navigations();		
			nav_select_node(nav_default_path, false);
		}
	}
	
	custom_awake = function()
	{
		__nav_initiate_grid();		
		if (nav_grid != noone) nav_deselect_node();
	}	
}
