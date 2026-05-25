///@function									MiniNodeSimpleButton(_name, _text, _font, _width, _height, _origin)
///@description									A simple button with background and text, with focus color & scale feedback
///@param {String} _name						Unique identifier for this button
///@param {String} _text						Text to display on the button
///@param {Asset.GMFont} [_font]				Font asset (default fnt_noto_14)
///@param {Real} [_width]						Button width in pixels (default 180)
///@param {Real} [_height]						Button height in pixels (default 36)
///@param {Enum.NODE_ORIGIN} [_origin]			Anchor point for positioning
function MiniNodeSimpleButton(_name, _text, _font = fnt_noto_14, _width = 180, _height = 36, _origin = MND_BUTTON_DEFAULT_ORIGIN) : MiniNodeButton(_name, _origin) constructor 
{
    node_set_transform(0, 0, 1, 1, 1, 0, _width, _height);
    button_set_background(spr_frame);
    button_set_text(_text, _font);
    
    // Store reference for tween callbacks
    var _self = self;
    
    // Focus: Color + Scale pop animation
    navigator.on_node_selected.connect(self, function () {
        background_node.sprite_set_blend(c_aqua);
        // Scale up with a nice bounce effect
        mini_tween_node(self, 0.15)
            .tween("image_xscale", 1.08, EaseOutBack)
            .tween("image_yscale", 1.08, EaseOutBack);
    });
    
    // Unfocus: Reset color + smooth scale back
    navigator.on_node_deselected.connect(self, function () {
        background_node.sprite_set_blend(c_white);
        // Scale back to normal smoothly
		mini_tween_cancel_target(self);
        mini_tween_node(self, 0.12)
            .tween("image_xscale", 1.0, EaseOutSine)
            .tween("image_yscale", 1.0, EaseOutSine);
    });
    
    // Press: Quick squish effect
    on_button_pressed.connect(self, function() { 	
        mini_tween_node(self, 0.08)
            .tween("image_xscale", 0.95, EaseInSine)
            .tween("image_yscale", 0.95, EaseInSine);
    });
    
    // Release: Bounce back
    on_button_released.connect(self, function() {
		if (!navigator.is_selected) return;
		
        mini_tween_node(self, 0.12)
            .tween("image_xscale", 1.08, EaseOutBack)
            .tween("image_yscale", 1.08, EaseOutBack);
    });
}

///@function									MiniNodeSlider(_name, _min_value, _max_value, _initial_value, _origin)
///@description									A horizontal slider control for selecting a value within a range.
///												Uses custom draw for track/fill and a knob node that follows the value.
///@param {String} _name						Unique identifier for this slider
///@param {Real} [_min_value]					Minimum slider value (default 0)
///@param {Real} [_max_value]					Maximum slider value (default 100)
///@param {Real} [_initial_value]				Starting value (default 50)
///@param {Real} [_knob_height]					Knob height (default 12)
///@param {Enum.NODE_ORIGIN} [_origin]			Anchor point for positioning
function MiniNodeSlider(_name, _min_value = 0, _max_value = 100, _initial_value = 50, _knob_height = 12, _origin = MND_BUTTON_DEFAULT_ORIGIN) : MiniNodeButton(_name, _origin) constructor
{
	// Slider values
	min_value = _min_value;
	max_value = _max_value;
	current_value = clamp(_initial_value, _min_value, _max_value);
	
	// Visual settings
	track_sprite = spr_frame;
	fill_sprite = spr_fill;
	track_color = c_dkgray;
	fill_color = c_aqua;
	track_height_ratio = 0.4; // Track height as ratio of slider height
	
	// Knob node
	knob_node = noone;
	knob_height = _knob_height;
	
	// Events
	on_value_changed = new MiniEvent();
	
	#region SLIDER SETUP
	
	// Custom draw for track and fill (both drawn on the base node)
	renderer.render_set_custom_draw(function(_node)
	{
		var _transform = _node.transform;
		var _ratio = _node.slider_get_normalized();
		
		// Calculate track dimensions
		var _track_height = _transform.height * _node.track_height_ratio;
		var _track_y = _transform.y;
		var _track_x = _transform.x + _node.sys_origin_offset[0];
		
		// Draw fill (progress)
		var _fill_width = _transform.width * _ratio;
		if (_fill_width > 0)
		{
			draw_sprite_stretched_ext(
				_node.fill_sprite,
				0,
				_track_x,
				_track_y - _track_height / 2,
				_fill_width,
				_track_height,
				_node.fill_color,
				_transform.image_alpha
			);
		}
		
		// Draw track (background)
		draw_sprite_stretched_ext(
			_node.track_sprite,
			0,
			_track_x,
			_track_y - _track_height / 2,
			_transform.width,
			_track_height,
			_node.track_color,
			_transform.image_alpha
		);		

	});
	
	// Knob (visual node that follows the value)
	knob_node = new MiniNodeSprite($"{id}_knob", spr_knob, c_white, false, NODE_ORIGIN.MIDDLE_CENTER);
	with (knob_node)
	{
		var _knob_size = other.knob_height / 2;		
		node_set_transform(0, 0, 1, 1, 1, 0, _knob_size, _knob_size);
		sprite_expand_to_size();
	}
	
	node_add(knob_node);
	
	#endregion
	
	#region SLIDER METHODS
	
	///@function						slider_set_value(_value)
	///@description						Set the slider's current value
	///@param {Real} _value				The value to set (will be clamped to min/max range)
	///@returns {Struct.MiniNodeSlider}	Self for method chaining
	static slider_set_value = function(_value)
	{
		var _old_value = current_value;
		current_value = clamp(_value, min_value, max_value);
		
		if (_old_value != current_value)
		{
			on_value_changed.invoke();
		}
		
		return self;
	}
	
	///@function						slider_get_value()
	///@description						Get the slider's current value
	///@returns {Real}					The current slider value
	static slider_get_value = function()
	{
		return current_value;
	}
	
	///@function						slider_get_normalized()
	///@description						Get the slider's value as a normalized ratio (0 to 1)
	///@returns {Real}					The normalized value between 0 and 1
	static slider_get_normalized = function()
	{
		return (current_value - min_value) / (max_value - min_value);
	}
	
	///@function						__slider_drag_control()
	///@description						Handle mouse dragging for slider control
	static __slider_drag_control = function()
	{
		// Only update value while pressed/dragging (button_is_pressed is set by canvas action handler)
		if (!button_is_pressed) return;
		
		// Update value based on cursor position
		var _track_start = transform.x + sys_origin_offset[0];
		var _track_width = transform.width;
		
		var _mouse_ratio = clamp((global.mnd_input.cursor_x() - _track_start) / _track_width, 0, 1);
		var _new_value = lerp(min_value, max_value, _mouse_ratio);
		
		slider_set_value(_new_value);
	}
	
	///@function						__update_knob_position()
	///@description						Update the knob position based on value (called via event)
	///@param {Real} _value				The current slider value
	static __update_knob_position = function()
	{
		var _ratio = slider_get_normalized();			
		var _x = round((local_transform.width * _ratio) +  sys_origin_offset[0]);
		
		knob_node.transform_set_position(_x, 0);
	}
	
	#endregion
	
	// Add slider drag process
	processor.add_process(__slider_drag_control);
	
	// Connect value change event to update knob position
	on_value_changed.connect(self, __update_knob_position);
	
	// Set up initial knob position
	processor.on_post_init.connect(self, function () {
		var _ratio = slider_get_normalized();	
		
		// Get correct origin offset without animation influences
		var _origin_xoffset = local_transform.width * NODE_ORIGIN_CONVERSION[origin][0];		
		var _x = round((local_transform.width * _ratio) + _origin_xoffset);		
		knob_node.transform_set_position(_x, 0);	
	});
	
	// Selection feedback on knob
	navigator.on_node_selected.connect(self, function () {
		knob_node.sprite_set_blend(c_aqua);
	});
	
	navigator.on_node_deselected.connect(self, function () {
		knob_node.sprite_set_blend(c_white);
	});
}

///@function									MiniNodeToggle(_name, _label, _initial, _width, _height)
///@description									A toggle button with label
///@param {String} _name						Unique identifier
///@param {String} _label						Label text to display
///@param {Bool} [_initial]						Initial state (default false)
///@param {Real} [_width]						Total width (default 200)
///@param {Real} [_height]						Total height (default 36)
function MiniNodeToggle(_name, _label, _initial = false, _width = 200, _height = 36) : MiniNodeButton(_name, NODE_ORIGIN.MIDDLE_CENTER) constructor
{
	node_set_transform(0, 0, 1, 1, 1, 0, _width, _height);
	
	// State
	is_on = _initial;
	
	// Events
	on_toggled = new MiniEvent();
	
	// Background
	button_set_background(spr_frame);
	
	// Label (left side)
	label_node = new MiniNodeText($"{_name}_label", _label, fnt_noto_14, c_white, NODE_ORIGIN.MIDDLE_LEFT);
	with (label_node)
	{
		node_set_transform(-other.local_transform.width / 2 + 10, 0, 1, 1, 1, 0, 120, _height);
		text_set_alignment(fa_left, fa_middle);
	}
	
	// Toggle indicator (right side)
	toggle_indicator = new MiniNodeText($"{_name}_indicator", _initial ? "ON" : "OFF", fnt_noto_14, _initial ? c_lime : c_gray, NODE_ORIGIN.MIDDLE_RIGHT);
	with (toggle_indicator)
	{
		node_set_transform(other.local_transform.width / 2 - 10, 0, 1, 1, 1, 0, 40, _height);
		text_set_alignment(fa_right, fa_middle);
	}
	
	node_add(label_node, toggle_indicator);
	
	// Toggle on press
	on_button_released.connect(self, function() {
		is_on = !is_on;
		toggle_indicator.text_set(is_on ? "ON" : "OFF");
		toggle_indicator.text_set_color(is_on ? c_lime : c_gray);
		on_toggled.invoke();
	});
	
	// Focus feedback
	navigator.on_node_selected.connect(self, function () {
		background_node.sprite_set_blend(c_aqua);
	});
	
	navigator.on_node_deselected.connect(self, function () {
		background_node.sprite_set_blend(c_white);
	});
	
	// Methods
	static get_value = function()
	{
		return is_on;
	}
	
	static set_value = function(_value)
	{
		is_on = _value;
		toggle_indicator.text_set(is_on ? "ON" : "OFF");
		toggle_indicator.text_set_color(is_on ? c_lime : c_gray);
		return self;
	}
}

