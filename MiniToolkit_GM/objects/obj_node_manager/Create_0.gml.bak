/// @description Node Manager Create

canvas_collection = [];
canvas_active = noone;
canvas_active_ind = 0;

canvas_exibiting = [0];
canvas_exibiting_amnt = 1;
canvas_main = 0;

__system_started = false;
__active_canvas = true;

#region SYSTEM FUNCTIONS

///@function					__system_define_canvas()
///@description					Define the active canvas and other system variables
__system_define_canvas = function()
{
	var _main_canvas_ind = canvas_exibiting[canvas_main]; 
	canvas_active = canvas_collection[_main_canvas_ind];
	canvas_active_ind = _main_canvas_ind;
	
	__node_canvas_input_define(id);
	__system_started = true;
}

#endregion

#region Utility Methods

///@function					canvas_change_active(_canvas_ind)
///@description					Change the active canvas to the given index of the canvas_collection array
///@param {real} _canvas_ind	Canvas index 
canvas_change_active = function(_canvas_ind)
{
	canvas_active.node_call_state(NODE_MOTION_STATE.LEAVE, __canvas_execute_change_active);
}

__canvas_execute_change_active = function()
{
	var _id = variable_clone(global.node_manager.__call_next_canvas_ind);
	if (_id != noone)
	{
		canvas_active.node_reset_nested_nodes();
		
		canvas_exibiting = [_id];
		__system_define_canvas();
				
		with (canvas_active)
		{
			update();
			node_call_state(NODE_MOTION_STATE.ENTER);
			nav_select_node(nav_default_path, false);
			if (nav_node_selected != noone)
			{
				input_set_cursor(variable_clone(nav_node_selected.transform.position));
			}
		}
		global.node_manager.__call_next_canvas_ind = noone;
	}
}

#endregion

__node_activate_manager_object(id);

