// MiniNode demo interfaces

#region 1. Main Menu

node_main_menu = new MiniNodeCanvas("menu_main", NODE_ORIGIN.TOP_LEFT);

with (node_main_menu)
{
	node_add_nav_group();
	node_set_transform(0, 0, 1, 1, 1, 0, 1280, 720);
	
	var _gui_w = display_get_gui_width(),
		_gui_h = display_get_gui_height();
	
	// Title
	var _title = new MiniNodeText("MainTitle", "MINI NODE DEMO", fnt_noto_14, c_white, NODE_ORIGIN.MIDDLE_CENTER);
	with (_title)
	{
		node_set_transform(1280 /2, 720 * 0.2, 2, 2, 1, 0, 300, 40);
		on_enabled.connect(self, function() {
			transform_set_attribute("image_yscale", 0);
			transform_set_alpha(0);
			mini_tween_node(self, 0.4).tween("image_yscale", 2, EaseOutElastic).delay(0.1);
			mini_tween_node(self, 0.3).tween("image_alpha", 1, EaseOutSine);
		});
	}
	
	// Main Menu Frame
	var _frame = new MiniNodeSprite("MainMenuFrame", spr_frame, c_gray, false, NODE_ORIGIN.MIDDLE_CENTER);
	with (_frame)
	{
		node_set_transform(640, 420, 1, 1, 1, 0, 220, 220);
		sprite_expand_to_size();
		
		on_enabled.connect(self, function() {
			transform_set_scale(0, 0);
			mini_tween_node(self, 0.35)
				.tween("image_xscale", 1, EaseOutBack)
				.tween("image_yscale", 1, EaseOutBack)
				.delay(0.15);
		});
		
		var _v_container = new MiniNodeContainer("MainMenuVContainer", 1, NODE_ORIGIN.MIDDLE_CENTER);
		with (_v_container)
		{
			node_set_transform(0, 0, 1, 1, 1, 0, 200, 200);
			container_set_spacing(0, 8);
			container_set_flow(NODE_HFLOW.RIGHT, NODE_VFLOW.DOWN, NODE_AXIS.VERTICAL);
			
			// PLAY Button
			var _btn_play = new MiniNodeSimpleButton("btn_play", "PLAY");
			with (_btn_play)
			{
				on_button_released.connect(self, function() {
					mnd_screen_push("menu_level_select");
				});
			}
			
			// OPTIONS Button
			var _btn_options = new MiniNodeSimpleButton("btn_options", "OPTIONS");
			with (_btn_options)
			{
				on_button_released.connect(self, function() {
					mnd_screen_push("menu_options");
				});
			}
			
			// EXIT Button
			var _btn_exit = new MiniNodeSimpleButton("btn_exit", "EXIT");
			with (_btn_exit)
			{
				on_button_released.connect(self, function() {				
					// Popup: keeps the main menu visible below and steals the focus
					mnd_screen_push("exit_popup", false);
				});
			}
			
			node_add(_btn_play, _btn_options, _btn_exit);
		}
		node_add(_v_container);
	}
	
	node_add(_title, _frame);
}

// Canvases register themselves as roots. The main menu is the base screen of the screen stack.
mnd_screen_push(node_main_menu);

#endregion

#region 2. Exit PopUp


exit_popup = new MiniNode("exit_popup")
with (exit_popup)
{
	node_add_nav_group();
	node_set_transform(0, 0, 1, 1, 1, 0, 1280, 720);	
	
	// Main Menu Frame
	var _frame = new MiniNodeSprite("exit_popup_frame", spr_frame, c_gray, false, NODE_ORIGIN.MIDDLE_CENTER);
	with (_frame)
	{
		node_set_transform(1280 * 0.75, 720 / 2, 1, 1, 1, 0, 220, 220);
		sprite_expand_to_size();
		
		on_enabled.connect(self, function() {
			transform_set_scale(0, 0);
			mini_tween_node(self, 0.35)
				.tween("image_xscale", 1, EaseOutBack)
				.tween("image_yscale", 1, EaseOutBack)
				.delay(0.15);
		});
		
		var _h_container = new MiniNodeContainer("exit_popup_h_container", 1, NODE_ORIGIN.MIDDLE_CENTER);
		with (_h_container)
		{
			node_set_transform(0, 0, 1, 1, 1, 0, 200, 200);
			container_set_spacing(0, 8);
			container_set_flow(NODE_HFLOW.RIGHT, NODE_VFLOW.DOWN, NODE_AXIS.HORIZONTAL);
			
			// Yes Button
			var _btn_yes = new MiniNodeSimpleButton("exit_popup_yes_button", "YES");
			with (_btn_yes)
			{
				on_button_released.connect(self, function() {
					game_end();
				});
			}
			
			// No Button
			var _btn_no = new MiniNodeSimpleButton("exit_popup_no_button", "NO");
			with (_btn_no)
			{
				on_button_released.connect(self, function() {
					// Closing the popup gives the focus back to the main menu
					mnd_screen_pop();
				});
			}

			
			node_add(_btn_yes, _btn_no);
		}
		
	node_add(_h_container);
	}
	
	node_add(_frame);	
}

// Plain MiniNode: register as root manually, starting hidden
mnd_root_add(exit_popup, false);

#endregion

#region 3. Options Menu

var _menu_options = new MiniNodeCanvas("menu_options", NODE_ORIGIN.TOP_LEFT);
with (_menu_options)
{
	node_add_nav_group();
	node_set_transform(0, 0, 1, 1, 1, 0, 1280, 720);
	
	// Title
	var _title = new MiniNodeText("OptionsTitle", "OPTIONS", fnt_noto_14, c_white, NODE_ORIGIN.MIDDLE_CENTER);
	with (_title)
	{
		node_set_transform(1280 / 2, 720 * 0.15, 2, 2, 1, 0, 300, 40);
		on_enabled.connect(self, function() {
			transform_set_attribute("image_yscale", 0);
			transform_set_alpha(0);
			mini_tween_node(self, 0.4).tween("image_yscale", 2, EaseOutElastic).delay(0.1);
			mini_tween_node(self, 0.3).tween("image_alpha", 1, EaseOutSine);
		});
	}
	
	// Frame
	var _frame = new MiniNodeSprite("OptionsFrame", spr_frame, c_gray, false, NODE_ORIGIN.MIDDLE_CENTER);
	with (_frame)
	{
		node_set_transform(640, 420, 1, 1, 1, 0, 360, 380);
		sprite_expand_to_size();
		
		on_enabled.connect(self, function() {
			transform_set_scale(0, 0);
			mini_tween_node(self, 0.35)
				.tween("image_xscale", 1, EaseOutBack)
				.tween("image_yscale", 1, EaseOutBack)
				.delay(0.15);
		});
		
		var _v_container = new MiniNodeContainer("OptionsVContainer", 1, NODE_ORIGIN.MIDDLE_CENTER);
		with (_v_container)
		{
			node_set_transform(0, 0, 1, 1, 1, 0, 320, 340);
			container_set_spacing(0, 24);
			container_set_flow(NODE_HFLOW.RIGHT, NODE_VFLOW.DOWN, NODE_AXIS.VERTICAL);
			
			var _slider_prefab = function(_name, _title)
			{
				// SFX Volume Slider
				var _slider = new MiniNodeSlider(_name, 0, 100, 75, 24);
					_slider.node_set_transform_attribute("width", 200);
					_slider.node_set_transform_attribute("height", 32);
				
				var _label = new MiniNodeText($"{_name}_label", _title, fnt_noto_14, c_white);
					_label.node_set_transform(0, -24, 1, 1, 1, 0, 200, 32);
				
				_slider.node_add(_label);
				
				return _slider;
			}
			
			// Music Volume Slider
			var _slider_sfx = _slider_prefab("slider_SFX", "SFX VOLUME");
			var _slider_music = _slider_prefab("slider_music", "MUSIC VOLUME");
			
			// Mute Toggle
			var _toggle_mute = new MiniNodeToggle("toggle_mute", "Mute Audio", false, 280, 36);
			
			// Back Button
			var _btn_back = new MiniNodeSimpleButton("btn_options_back", "BACK");
			with (_btn_back)
			{
				on_button_released.connect(self, function() {
					mnd_screen_pop();
				});
			}
			
			node_add(_slider_sfx, _slider_music, _toggle_mute, _btn_back);
		}
		node_add(_v_container);
	}
	
	node_add(_title, _frame);
}
mnd_hide(_menu_options); // Canvas is already a root, start hidden

#endregion

#region 4. Level Select Menu

var _menu_level_select = new MiniNodeCanvas("menu_level_select", NODE_ORIGIN.TOP_LEFT);
with (_menu_level_select)
{
	var _level_group = node_add_nav_group();
	var _level_buttons = [];
	node_set_transform(0, 0, 1, 1, 1, 0, 1280, 720);
	
	// Title
	var _title = new MiniNodeText("LevelSelectTitle", "SELECT LEVEL", fnt_noto_14, c_white, NODE_ORIGIN.MIDDLE_CENTER);
	with (_title)
	{
		node_set_transform(1280 / 2, 720 * 0.15, 2, 2, 1, 0, 300, 40);
		on_enabled.connect(self, function() {
			transform_set_attribute("image_yscale", 0);
			transform_set_alpha(0);
			mini_tween_node(self, 0.4).tween("image_yscale", 2, EaseOutElastic).delay(0.1);
			mini_tween_node(self, 0.3).tween("image_alpha", 1, EaseOutSine);
		});
	}
	
	// Frame
	var _frame = new MiniNodeSprite("LevelSelectFrame", spr_frame, c_gray, false, NODE_ORIGIN.MIDDLE_CENTER);
	with (_frame)
	{
		node_set_transform(640, 420, 1, 1, 1, 0, 480, 320);
		sprite_expand_to_size();
		
		on_enabled.connect(self, function() {
			transform_set_scale(0, 0);
			mini_tween_node(self, 0.35)
				.tween("image_xscale", 1, EaseOutBack)
				.tween("image_yscale", 1, EaseOutBack)
				.delay(0.15);
		});
		
		var _v_container = new MiniNodeContainer("LevelSelectVContainer", 1, NODE_ORIGIN.MIDDLE_CENTER);
		with (_v_container)
		{
			node_set_transform(0, 0, 1, 1, 1, 0, 440, 280);
			container_set_spacing(0, 16);
			container_set_flow(NODE_HFLOW.RIGHT, NODE_VFLOW.DOWN, NODE_AXIS.VERTICAL);
			
			// Grid container for levels (5 columns, 2 rows)
			var _grid = new MiniNodeContainer("LevelSelectGrid", 5, NODE_ORIGIN.MIDDLE_CENTER);
			with (_grid)
			{
				container_set_spacing(12, 12);
				container_set_flow(NODE_HFLOW.RIGHT, NODE_VFLOW.DOWN, NODE_AXIS.HORIZONTAL);
				
				for (var _i = 1; _i <= 10; _i++)
				{
					var _btn_lvl = new MiniNodeSimpleButton($"btn_level_{_i}", string(_i), fnt_noto_14, 60, 60);
					with (_btn_lvl)
					{
						level_num = _i;
						on_button_released.connect(self, function() {
							show_debug_message($"LEVEL {level_num} SELECTED!");
						});
					}
					node_add(_btn_lvl);
					array_push(_level_buttons, _btn_lvl);
				}
			}
			
			// Back button
			var _btn_back = new MiniNodeSimpleButton("btn_level_back", "BACK");
			with (_btn_back)
			{
				on_button_released.connect(self, function() {
					mnd_screen_pop();
				});
			}
			
			node_add(_grid, _btn_back);
			
			// Manual navigation example: grid links with horizontal wrap.
			// Edges without links (e.g. down from the last row) fall back to the automatic navigation (BACK button).
			_level_group.nav_link_grid(_level_buttons, 5, true, false);
		}
		node_add(_v_container);
	}
	
	node_add(_title, _frame);
}
mnd_hide(_menu_level_select);

#endregion

#region 5. Debug tools

// F1 bounding boxes | F2 origins | F3 print tree | F4 print focus/screens | F5 toggle input block | F12 hide panel
debug_draw_size = false;
debug_draw_origin = false;
debug_input_blocked = false;
debug_show_panel = false;	// F12 to show
debug_log = [];		// Last global events, shown in the panel

debug_push_log = function(_text)
{
	array_insert(debug_log, 0, _text);
	if (array_length(debug_log) > 5) array_resize(debug_log, 5);
	show_debug_message($"[Demo] {_text}");
}

// Global MiniNode events (connection = this instance; dropped automatically when it is destroyed)
global.mnd_events.input_mode_changed.connect(id, function(_mode) {
	debug_push_log($"input_mode_changed -> {(_mode == MND_NAV_INPUT.BUTTON) ? "BUTTON" : "CURSOR"}");
});

global.mnd_events.focus_changed.connect(id, function(_focused, _previous) {
	var _new = (_focused != noone) ? _focused.id : "none";
	var _old = (_previous != noone) ? _previous.id : "none";
	debug_push_log($"focus_changed -> {_new} (was {_old})");
});

#endregion
