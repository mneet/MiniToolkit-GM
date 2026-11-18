/// @description MiniNode Manager - singleton holding the NodeManager state
/// Created on demand by __mnd(). Functions in the NodeManager* scripts access this instance.

// Singleton guard - destroy any duplicate instance
if (instance_number(obj_node_manager) > 1)
{
	instance_destroy();
	exit;
}

///@function		__reset_state()
///@description		Reset every piece of manager state (used on create and by mnd_destroy_all)
__reset_state = function()
{
	// Nodes
	__roots = [];				// Root nodes in draw/process order (back to front)
	__registry = {};			// id -> weak_ref, for global lookup (mnd_node_get)
	
	// Navigation
	__focus_stack = [];			// Nodes with nav_group, top = focused
	__screen_stack = [];		// { node, hid_previous }
	
	// Input
	input_mode = MND_NAV_INPUT.BUTTON;
	__input_mode_locked = false;
	__block_counts = [0, 0, 0, 0];	// BUTTON_NAV, CURSOR_NAV, BUTTON_ACTION, CURSOR_ACTION
	__input_consumed = false;
	
	// Cursor tracking
	cursor_x = 0;
	cursor_y = 0;
	cursor_prev_x = 0;
	cursor_prev_y = 0;
}

__reset_state();
