///@function						MiniNodeText(_name, _text, _font, _color, _origin)
///@description						A node that renders text with support for alignment, wrapping, and typewriter effect.
///@param {String} _name			Unique identifier for this node
///@param {String} _text			Text content to display
///@param {Asset.GMFont} _font		Font asset to use
///@param {Constant.Color} _color	Text color
///@param {Enum.NODE_ORIGIN} [_origin]	Anchor point for positioning
function MiniNodeText(_name, _text, _font, _color, _origin = NODE_ORIGIN.MIDDLE_CENTER) : MiniNode(_name, _origin) constructor 
{
	text =  _text;
	font = _font;
	
	// Text Attributes
	txt_color1 = _color;
	txt_color2 = _color;
	txt_color3 = _color;
	txt_color4 = _color;	
	
	h_alignment = fa_center;
	v_alignment = fa_middle;
	
	separation = -1;
	h_wrap = -1;

	text_xscale = 1;
	text_yscale = 1;
	
	// System Flags
	__fit_to_width = true;
	
	#region System Methods
	
	///@description Calculate the text size based on font and text content
	static __calculate_text_size = function()
	{
		draw_set_font(font);
		
		if (h_wrap > 0)
		{
			text = node_string_wrap(text, h_wrap);	
		}

		if (__fit_to_width)
		{
			var _txt_width = string_width(text);
			if (_txt_width > fixed_transform.width)
			{ 
				text_xscale = round((fixed_transform.width / _txt_width) * 10) / 10;
			}
			text_yscale = text_xscale;
		}
				
		draw_set_font(-1);
	}
	
	renderer.render_set_custom_draw(function(_node)
	{
		var _transform = _node.transform;
		
		// Draw sets
		draw_set_font(_node.font);
		draw_set_valign(_node.v_alignment);
		draw_set_halign(_node.h_alignment);
		
		// Drawing text
		draw_text_ext_transformed_color(
			_transform.x, 
			_transform.y, 
			_node.text, 
			_node.separation, 
			-1, 
			_node.text_xscale * _transform.image_xscale, 
			_node.text_yscale * _transform.image_yscale, 
			_transform.image_angle, 
			_node.txt_color1, _node.txt_color2, _node.txt_color3, _node.txt_color4, 
			_transform.image_alpha
		);

		// Reseting draw_set
		draw_set_font(-1);
		draw_set_valign(-1);
		draw_set_halign(-1);
			
	});
	
	// Calculate text size on initialization
	processor.on_init.connect(self, __calculate_text_size);
	
	#endregion
	
	#region Utility Methods

	///@function					text_set(_text)
	///@description					Set the text content
	///@param {String} _text		The text to display
	///@returns {Struct.MiniNodeText}	Self for method chaining
	static text_set = function(_text)
	{
		text = _text;
		return self;
	}

	///@function								text_set_alignment(_horizontal, _vertical)
	///@description								Define the text alignment
	///@param {Constant.HAlign} _horizontal	Horizontal alignment using fa_ constants (fa_left, fa_center, fa_right)
	///@param {Constant.VAlign} _vertical		Vertical alignment using fa_ constants (fa_top, fa_middle, fa_bottom)
	///@returns {Struct.MiniNodeText}				Self for method chaining
	static text_set_alignment = function(_horizontal, _vertical)
	{
		h_alignment = _horizontal;
		v_alignment = _vertical;
		
		return self;
	}
	
	///@function							text_align_to_node_origin()
	///@description						Align text alignment to match the node origin.
	///@returns {Struct.MiniNodeText}		Self for method chaining
	static text_align_to_node_origin = function()
	{
		switch (origin)
		{
			case NODE_ORIGIN.TOP_LEFT:
				h_alignment = fa_left;
				v_alignment = fa_top;
				break;
			case NODE_ORIGIN.TOP_CENTER:
				h_alignment = fa_center;
				v_alignment = fa_top;
				break;
			case NODE_ORIGIN.TOP_RIGHT:
				h_alignment = fa_right;
				v_alignment = fa_top;
				break;
			case NODE_ORIGIN.MIDDLE_LEFT:
				h_alignment = fa_left;
				v_alignment = fa_middle;
				break;
			case NODE_ORIGIN.MIDDLE_CENTER:
				h_alignment = fa_center;
				v_alignment = fa_middle;
				break;
			case NODE_ORIGIN.MIDDLE_RIGHT:
				h_alignment = fa_right;
				v_alignment = fa_middle;
				break;
			case NODE_ORIGIN.BOTTOM_LEFT:
				h_alignment = fa_left;
				v_alignment = fa_bottom;
				break;
			case NODE_ORIGIN.BOTTOM_CENTER:
				h_alignment = fa_center;
				v_alignment = fa_bottom;
				break;
			case NODE_ORIGIN.BOTTOM_RIGHT:
				h_alignment = fa_right;
				v_alignment = fa_bottom;
				break;
		}
		
		return self;
	}
	
	///@function							text_set_color(_c1, _c2, _c3, _c4)
	///@description							Define text gradient colors (top-left, top-right, bottom-right, bottom-left)
	///@param {Constant.Color} _c1			Top-left corner color
	///@param {Constant.Color} _c2			Top-right corner color
	///@param {Constant.Color} _c3			Bottom-right corner color
	///@param {Constant.Color} _c4			Bottom-left corner color
	///@returns {Struct.MiniNodeText}			Self for method chaining
	static text_set_color = function(_c1, _c2 = _c1, _c3 = _c1, _c4 = _c1)
	{
		txt_color1 = _c1;
		txt_color2 = _c2;
		txt_color3 = _c3;
		txt_color4 = _c4;
		
		return self;
	}
	
	///@function						text_set_wrap(_wrap_width)
	///@description						Define maximum width before text wraps to next line
	///@param {Real} _wrap_width		Maximum width in pixels before wrapping (-1 to disable)
	///@returns {Struct.MiniNodeText}		Self for method chaining
	static text_set_wrap = function(_wrap_width)
	{
		h_wrap = _wrap_width;
		return self;
	}
	
	#endregion

    text_align_to_node_origin();
}
