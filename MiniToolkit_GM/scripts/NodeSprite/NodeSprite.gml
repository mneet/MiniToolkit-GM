///@function						MiniNodeSprite(_name, _sprite, _color, _animate, _origin)
///@description							A node that renders a sprite with optional animation.
///@param {String} _name				Unique identifier for this node
///@param {Asset.GMSprite} _sprite		Sprite asset to render
///@param {Constant.Color} [_color]		Blend color (default c_white)
///@param {Bool} [_animate]				Whether to auto-animate sprite frames (default false)
///@param {Enum.NODE_ORIGIN} [_origin]	Anchor point for positioning
function MiniNodeSprite(_name, _sprite, _color = c_white, _animate = false, _origin = NODE_ORIGIN.MIDDLE_CENTER) : MiniNode(_name, _origin) constructor 
{
	// Sprite attributes
	sprite_index = _sprite;
	image_index = 0;
	image_blend = c_white;
	animate = _animate;
    
    sprite_xscale = 1;
    sprite_yscale = 1;
	
	sprite_origin_offset_x = 0;
	sprite_origin_offset_y = 0;
	
	#region SYSTEM
	
	node_set_transform(0, 0, 1, 1, 1, 0, sprite_get_width(sprite_index), sprite_get_height(sprite_index));
	
	// Draw methods
	renderer.render_set_custom_draw(function(_node)
	{
		var _transform = _node.transform;
		
		if (_node.sprite_index != noone)
		{ 
			var _scale_x = _transform.image_xscale * _node.sprite_xscale;
			var _scale_y = _transform.image_yscale * _node.sprite_yscale;
			
			draw_sprite_ext(
				_node.sprite_index, 
				_node.image_index, 
				_transform.x + (_node.sprite_origin_offset_x * _scale_x),
				_transform.y + (_node.sprite_origin_offset_y * _scale_y),
				_scale_x,
				_scale_y,
				_transform.image_angle,
				_node.image_blend, 
				_transform.image_alpha
			); 
			
			if (_node.animate)
			{
				_node.image_index += sprite_get_speed(_node.sprite_index) / game_get_speed(gamespeed_fps);
				_node.image_index = _node.image_index % sprite_get_number(_node.sprite_index);
			}
		}						
	});
	
	#endregion
	
	#region UTILITY
	
	///@function							sprite_set_blend(_color)
	///@description							Set the sprite blend color
	///@param {Constant.Color} _color		Blend color to apply
	///@returns {Struct.MiniNodeSprite}			Self for method chaining
	static sprite_set_blend = function(_color)
	{
		image_blend = _color;
		return self;
	}	
	
	///@function							sprite_set_image_index(_index)
	///@description							Set the current sprite frame index
	///@param {Real} _index					Frame index to display
	///@returns {Struct.MiniNodeSprite}			Self for method chaining
	static sprite_set_image_index = function(_index)
	{
		image_index = _index;
		return self;
	}
    
	///@function						sprite_expand_to_size()
	///@description						Scale the sprite to fill the node's local transform dimensions
	///@returns {Struct.MiniNodeSprite}		Self for method chaining
	static sprite_expand_to_size = function()
	{
		var _xscale = local_transform.width / sprite_get_width(sprite_index),
			_yscale = local_transform.height / sprite_get_height(sprite_index);
		
		sprite_xscale = _xscale;
		sprite_yscale = _yscale;
		
		return self;
	}
	
	///@function						sprite_align_to_node_origin()
	///@description						Align the sprite's origin to match the node's origin.
	///@returns {Struct.MiniNodeSprite}		Self for method chaining
	static sprite_align_to_node_origin = function()
	{
		if (sprite_index == noone)
		{
			sprite_origin_offset_x = 0;
			sprite_origin_offset_y = 0;
			return self;
		}
		
		var _sprite_w = sprite_get_width(sprite_index);
		var _sprite_h = sprite_get_height(sprite_index);
		
		var _factor = NODE_ORIGIN_CONVERSION[origin];
		var _desired_origin_x = -_factor[0] * _sprite_w;
		var _desired_origin_y = -_factor[1] * _sprite_h;
		
		var _sprite_origin_x = sprite_get_xoffset(sprite_index);
		var _sprite_origin_y = sprite_get_yoffset(sprite_index);
		
		sprite_origin_offset_x = _sprite_origin_x - _desired_origin_x;
		sprite_origin_offset_y = _sprite_origin_y - _desired_origin_y;
		
		return self;
	}
    
	#endregion
}
