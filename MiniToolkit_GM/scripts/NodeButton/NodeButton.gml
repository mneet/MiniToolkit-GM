///@function						MiniNodeButton(_name, _origin)
///@description						An interactive button node with navigation support and state events.
///									Can contain text and background child nodes.
///@param {String} _name			Unique identifier for this button
///@param {Enum.NODE_ORIGIN} [_origin]	Anchor point for positioning
function MiniNodeButton(_name, _origin = MND_BUTTON_DEFAULT_ORIGIN) : MiniNode(_name, _origin) constructor
{
	navigator = new MiniNodeNavigator(self);
	
	// Visual nodes
	background_node = noone;
	text_node = noone;
	
	// Events
	on_button_pressed = new MiniEvent();
	on_button_released = new MiniEvent();
	on_button_selected = new MiniEvent();
	on_button_deselected = new MiniEvent();
	
	// Flags
	button_is_pressed = false;
		
	#region BUTTON BUILDER
	
	///@function						button_set_text(_text, _font, _width, _color)
	///@description						Set a text node inside the button, you can access it with the variable text_node
	///@param {String} _text			String to be displayed
	///@param {Asset.GMFont} _font		Font asset
	///@param {Real} [_width]			Maximum text width (default 64)
	///@param {Constant.Color} [_color]	Text color (default c_white)
	///@returns {Struct.MiniNodeText}		The created text node
	static button_set_text = function(_text, _font, _width = 64, _color = c_white)
	{
		txt_normal = _text;		
		text_node = new MiniNodeText($"{id}_text", _text, _font, _color);
		text_node.fixed_transform.width = _width;
		
		node_add(text_node);
		
		return text_node;
	}
	
	///@function							button_set_background(_sprite, _color, _fill_size)
	///@description							Set a background node inside the button, you can access it with the variable background_node
	///@param {Asset.GMSprite} _sprite		Sprite asset to use as background
	///@param {Constant.Color} [_color]		Blend color (default c_white)
	///@param {Bool} [_fill_size]			If the sprite should expand to fill the button size (default true)
	///@returns {Struct.MiniNodeSprite}			The created background node
	static button_set_background = function(_sprite, _color = c_white,  _fill_size = true)
	{
		bg_normal = _sprite;
		bg_selected = _sprite;

		background_node = new MiniNodeSprite($"{id}_background", _sprite);
		
		if (_fill_size)
		{
			var _xscale = local_transform.width / background_node.local_transform.width,
				_yscale = local_transform.height / background_node.local_transform.height;
			
			background_node.transform_set_scale(_xscale, _yscale);
		}
		
		node_add(background_node);
		return background_node;
	}
	
	#endregion

	#region BUTTON SYSTEM
	
	// Connect navigator action events to button events
	navigator.on_action_pressed.connect(self, function() {
		button_is_pressed = true;
		on_button_pressed.invoke();
	});
	
	navigator.on_action_released.connect(self, function() {
		button_is_pressed = false;
		on_button_released.invoke();
	});
	
	// Connect focus events from navigator to button events
	navigator.on_node_selected.connect(self, function() {
		on_button_selected.invoke();
	});
	
	navigator.on_node_deselected.connect(self, function() {
		on_button_deselected.invoke();
	});
	

	#endregion 
}