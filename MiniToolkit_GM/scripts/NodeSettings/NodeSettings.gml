
// NODE DEFAULTS
#macro MND_DEFAULT_ORIGIN NODE_ORIGIN.TOP_LEFT
#macro MND_CANVAS_DEFAULT_ORIGIN NODE_ORIGIN.TOP_LEFT
#macro MND_BUTTON_DEFAULT_ORIGIN NODE_ORIGIN.MIDDLE_CENTER
#macro MND_CONTAINER_DEFAULT_ORIGIN NODE_ORIGIN.MIDDLE_CENTER

// DEBUG - Set to true to enable by default
#macro MND_DEBUG_SIZE false
#macro MND_DEBUG_ORIGIN false

// LOCALIZATION
#macro MND_LOCALIZE_TEXT function (_key) { return _key; }

// Navigation Input Mode
enum MND_NAV_INPUT
{
	BUTTON,		// Gamepad/Keyboard navigation
	CURSOR		// Mouse/Touch navigation
}

#region Input System

/// The input system uses replaceable functions stored in global.mnd_input.
/// To customize input handling, override any function after initialization:
///
///		global.mnd_input.cursor_x = function() { return my_custom_cursor_x; };
///		global.mnd_input.accept_pressed = function() { return my_input_system_accept(); };
///		global.mnd_input.navigate = function() { return [my_h_axis, my_v_axis]; };
///

function __mnd_input_init()
{
	global.mnd_input = {
		
		// Cursor position (used for hover detection and slider dragging)
		cursor_x: function() { return device_mouse_x_to_gui(0); },
		cursor_y: function() { return device_mouse_y_to_gui(0); },
		
		// Accept action (confirm/select)
		accept_pressed: function()
		{
			return keyboard_check_pressed(vk_enter) 
				|| gamepad_button_check_pressed(0, gp_face1) 
				|| mouse_check_button_pressed(mb_left);
		},
		
		accept_released: function()
		{
			return keyboard_check_released(vk_enter) 
				|| gamepad_button_check_released(0, gp_face1) 
				|| mouse_check_button_released(mb_left);
		},
		
		// Navigation (directional input for button mode)
		navigate: function()
		{
			var _kx = keyboard_check_pressed(vk_right) - keyboard_check_pressed(vk_left),
				_ky = keyboard_check_pressed(vk_down) - keyboard_check_pressed(vk_up);
			
			// Gamepad d-pad
			var _gx = gamepad_button_check_pressed(0, gp_padr) - gamepad_button_check_pressed(0, gp_padl),
				_gy = gamepad_button_check_pressed(0, gp_padd) - gamepad_button_check_pressed(0, gp_padu);
			
			return [_kx + _gx, _ky + _gy];
		},
		
		// Input mode detection (determines if system is in cursor or button mode)
		button_input_detected: function()
		{
			return keyboard_check_pressed(vk_anykey) 
				|| gamepad_button_check_pressed(0, gp_face1) 
				|| gamepad_button_check_pressed(0, gp_face2) 
				|| gamepad_button_check_pressed(0, gp_padu) 
				|| gamepad_button_check_pressed(0, gp_padd) 
				|| gamepad_button_check_pressed(0, gp_padl) 
				|| gamepad_button_check_pressed(0, gp_padr) 
				|| abs(gamepad_axis_value(0, gp_axislh)) > 0.5 
				|| abs(gamepad_axis_value(0, gp_axislv)) > 0.5;
		},
		
		cursor_input_detected: function()
		{
			var _m = obj_node_manager;
			return (_m.cursor_x != _m.cursor_prev_x) || (_m.cursor_y != _m.cursor_prev_y);
		}
	};
}
__mnd_input_init();

#endregion