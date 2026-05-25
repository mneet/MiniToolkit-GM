/// @description MiniNode Manager Create - State initialization & root node lifecycle driver
/// All NodeManager state lives here as instance variables.
/// Functions in NodeManager.gml access this via obj_node_manager.

// Singleton guard - destroy any duplicate instance
if (instance_number(obj_node_manager) > 1)
{
	instance_destroy();
	exit;
}

// MiniNode storage (weak references)
__node_collection = {};

// Root node management
__root_nodes = {};
__root_draw_order = [];
root_count = 0;

// Navigation 
focused_node_id = noone;	
prev_focused_node_id = noone;

selected_node_id = noone; 
prev_selected_node_id = noone;

// Navigation behavior
input_mode = MND_NAV_INPUT.BUTTON;

// Input blocking flags
block_button_navigation = false;
block_cursor_navigation = false;
block_button_action     = false;
block_cursor_action     = false;

// Input consumption
__input_consumed = false;

// Cursor tracking
cursor_x      = 0;
cursor_y      = 0;
cursor_prev_x = 0;
cursor_prev_y = 0;

// Statistics
node_count = 0;

reset_all = function()
{
	__node_collection = {};
	__root_nodes = {};
	__root_draw_order = [];
	root_count = 0;

	focused_node_id = noone;	
	prev_focused_node_id = noone;

	block_button_navigation = false;
	block_cursor_navigation = false;
	block_button_action     = false;
	block_cursor_action     = false;

	node_count = 0;	
}
