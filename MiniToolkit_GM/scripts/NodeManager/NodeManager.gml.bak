global.node_manager = {};
with (global.node_manager)
{
	interface_obj = noone;
	prev_interface_obj = noone;
	nav_grid_cell_size = new Vector2(20,20);
	
	block_action = false;
	block_navigation = false;
	
	button_action = false;
	cursor_action = false;
	
	
	debug_size = false;
	debug_origin = false;
	
	cursor_navigation = false;
	
	__call_next_canvas_ind = noone;
	
	__reroll_object_function = noone;
	__new_interface_obj = noone;
}

function node_activate_manager(_object)
{
	global.node_manager.__new_interface_obj = _object;
	
	__node_call_manager_out(__node_activate_manager_object)
}

function node_reroll_manager(_function = __node_reroll_manager_object)
{	
	__node_call_manager_out(_function);
}

function __node_activate_manager_object(_new_object = global.node_manager.__new_interface_obj)
{
	with (global.node_manager)
	{
		if (instance_exists(interface_obj))
		{
			interface_obj.__active_canvas = false;
		}
		prev_interface_obj = variable_clone(interface_obj);
						
		if (instance_exists(_new_object))
		{
			_new_object.__active_canvas = true;			
			interface_obj = variable_clone(_new_object);
			__node_call_manager_in();
			__node_canvas_input_define(_new_object);
		}
	}
	global.node_manager.__new_interface_obj = noone;
}

function __node_set_manager_object(_obj)
{
	global.node_manager.interface_obj = _obj;
	
	__node_canvas_input_define(_obj);
}

function __node_reroll_manager_object()
{
	with (global.node_manager)
	{
		if (instance_exists(prev_interface_obj))
		{
			var _temp_active_obj = variable_clone(interface_obj);			
			_temp_active_obj.__active_canvas = false;
			
			interface_obj = variable_clone(prev_interface_obj);
			interface_obj.__active_canvas = true;
			
			prev_interface_obj = variable_clone(_temp_active_obj);	
			
			__node_call_manager_in();
		}
	}
}	

function __node_call_manager_in(_execute_after = noone)
{
	__node_canvas_input_define(global.node_manager.interface_obj);	
	input_unlock_all();
	
	with (global.node_manager.interface_obj)
	{
		if (canvas_active != noone)
		{
			canvas_active.node_reset_nested_nodes();	
			canvas_active.node_call_state(NODE_MOTION_STATE.ENTER, _execute_after);
		}
	}	
}

function __node_call_manager_out(_execute_after = noone)
{
	if (instance_exists(global.node_manager.interface_obj))
	{
		input_lock_all();
		with (global.node_manager.interface_obj)
		{
			if (canvas_active != noone) canvas_active.node_call_state(NODE_MOTION_STATE.LEAVE, _execute_after);				
		}		
	}
}

function __node_canvas_input_define(_obj)
{
	with (_obj)
	{
		if (canvas_active != noone)
		{
			global.node_manager.button_action = canvas_active.button_input;
			global.node_manager.cursor_action = canvas_active.cursor_input;
			global.node_manager.cursor_navigation = canvas_active.cursor_navigation;
		}
	}
}

function node_update_all_canvas()
{
	for (var _i = 0; _i < instance_number(obj_node_manager); _i++)
	{
		var _obj = instance_find(obj_node_manager, _i);
		for (var _j = 0; _j < array_length(_obj.canvas_collection); _j++)
		{
			_obj.canvas_collection[_j].update(_obj.canvas_collection[_j]);	
		}
	}
}

function node_check_cursor_navigation()
{
	return global.node_manager.cursor_navigation || input_compare_mode(INPUT_MODE.MOUSE);
}

function node_block_navigation()
{
	global.node_manager.block_navigation = !global.node_manager.block_navigation;
}	

function node_block_action()
{
	global.node_manager.block_action = !global.node_manager.block_action;
}

function node_block_input()
{
	node_block_navigation();
	node_block_action();
}

function node_unblock_input()
{
	global.node_manager.block_navigation = false;
	global.node_manager.block_action = false;
}	

function node_compare_active_canvas(_canvas_ind)
{
	var _compare = false;
	if (global.node_manager.interface_obj != noone)
	{
		_compare = global.node_manager.interface_obj.canvas_active_ind == _canvas_ind;	
	}
	return _compare
}

function node_change_active_canvas(_canvas_ind)
{
	var _obj = global.node_manager.interface_obj
	if (instance_exists(_obj))
	{
		global.node_manager.__call_next_canvas_ind = _canvas_ind;
		_obj.canvas_change_active(_canvas_ind);
	}
}

function node_get_active_canvas()
{
	var _canvas = noone;
	var _obj = global.node_manager.interface_obj
	if (instance_exists(_obj))
	{		
		_canvas = _obj.canvas_active;
	}
	return _canvas;
}