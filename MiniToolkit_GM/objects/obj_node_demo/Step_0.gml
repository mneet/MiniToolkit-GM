/// @description Debug shortcuts

// F1 - Bounding boxes
if (keyboard_check_pressed(vk_f1))
{
	debug_draw_size = !debug_draw_size;
	mnd_debug_set(debug_draw_size, debug_draw_origin);
}

// F2 - Origins
if (keyboard_check_pressed(vk_f2))
{
	debug_draw_origin = !debug_draw_origin;
	mnd_debug_set(debug_draw_size, debug_draw_origin);
}

// F3 - Print the node hierarchy to the output
if (keyboard_check_pressed(vk_f3))
{
	mnd_debug_print_tree();
}

// F4 - Print focus / screen stack state
if (keyboard_check_pressed(vk_f4))
{
	var _m = obj_node_manager;
	
	var _focus = "";
	for (var _i = 0; _i < array_length(_m.__focus_stack); _i++) _focus += $"{_m.__focus_stack[_i].id} > ";
	
	var _screens = "";
	for (var _i = 0; _i < array_length(_m.__screen_stack); _i++)
	{
		var _entry = _m.__screen_stack[_i];
		_screens += $"{_entry.node.id}{_entry.hid_previous ? "" : "(popup)"} > ";
	}
	
	show_debug_message($"[Demo] Focus stack (bottom > top): {_focus}");
	show_debug_message($"[Demo] Screen stack (bottom > top): {_screens}");
	show_debug_message($"[Demo] Block counts [btn_nav, cur_nav, btn_act, cur_act]: {_m.__block_counts}");
}

// F5 - Toggle an independent input block (transitions must not clear it)
if (keyboard_check_pressed(vk_f5))
{
	debug_input_blocked = !debug_input_blocked;
	if (debug_input_blocked) mnd_input_block(MND_BLOCK.ALL);
	else mnd_input_unblock(MND_BLOCK.ALL);
	debug_push_log($"demo input block {debug_input_blocked ? "ON" : "OFF"}");
}

// F12 - Toggle debug panel
if (keyboard_check_pressed(vk_f12))
{
	debug_show_panel = !debug_show_panel;
}
