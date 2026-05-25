/// @function                   string_wrap(text, width);
/// @param  {string}    text    O texto utilizado
/// @param  {real}      width   Largura maxima do texto antes de uma quebra de linha ser feita
/// @description        Adiciona quebra de linhas em uma string para que o texto não ultrapasse a largura maxima especificada. 
function node_string_wrap(_text, _width)
{
	var _text_wrapped = "";
	var _space = -1;
	var _char_pos = 1;
	while (string_length(_text) >= _char_pos)
	{
		var _string_w = string_width(string_copy(_text, 1, _char_pos));
		if (_string_w > _width)
		{
			if (_space != -1)
			{
				_text_wrapped += string_copy(_text, 1, _space) + "\n";
				_text = string_copy(_text, _space + 1, string_length(_text) - (_space));
				_char_pos = 1;
				_space = -1;
			}
		}
		
		if (string_char_at(_text,_char_pos) == " ")
		{
			_space = _char_pos;
		}
		_char_pos += 1;
	}
	
	if (string_length(_text) > 0)
	{
		_text_wrapped += _text;
	}
	return _text_wrapped;
}


//	Vector 2
//	Stores two values, a y position and a x position
function Vector2(_x = 0, _y = _x) constructor {
	x = _x;
	y = _y;
					
	static get_magnitude = function()
	{
		var _mag = 0;
		_mag =  sqrt((x * x) + (y * y))				
		return _mag;
	}
		
	static normalize = function(){
		var _magnitude = get_magnitude();
		if (_magnitude == 0){
			x = 0;
			y = 0			
		}
		else
		{
			if (x != 0) x /= _magnitude;
			if (y != 0) y /= _magnitude;
		}
			
		return self;
	}

	static get_speed = function() {
		return point_distance(0, 0, x, y);
	}
		
	static get_direction = function(_x_origin = 0, _y_origin = 0) {
		return point_direction(_x_origin, _y_origin, x, y);
	}
		
	static is_null = function() {
		return ((x == noone) and (y == noone)) or ((x == undefined) and (y == undefined));
	}

	static lengthdir = function(_length, _dir) {
		x = lengthdir_x(_length, _dir);
		y = lengthdir_y(_length, _dir);
	
		return self;
	}
		
	static set_value = function(_x, _y) {
		x = _x;
		y = _y;	
		return self;
	}
		
	static lerpto = function(_vec2, _amount) {
		if is_vector2(_vec2) {
			x = lerp(x, _vec2.x, _amount);
			y = lerp(y, _vec2.y, _amount);
		}
		return self;
	}
		
	static compare = function(_vec2){
		return (x == _vec2.x && y == _vec2.y);	
	}
		
	static round_vec = function()
	{
		x = round(x);
		y = round(y);
	}
}

#macro VECTOR_RIGHT new Vector2(1,0)
#macro VECTOR_LEFT new Vector2(-1,0)
#macro VECTOR_UP new Vector2(0,1)
#macro VECTOR_DOWN new Vector2(0,-1)