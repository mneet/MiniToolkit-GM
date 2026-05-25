/// @description MiniNode Manager Draw GUI - Render all root nodes

var _order = __root_draw_order;
var _roots = __root_nodes;
var _len   = array_length(_order);

for (var _i = 0; _i < _len; _i++)
{
	var _root_id = _order[_i];
	if (struct_exists(_roots, _root_id))
	{
		_roots[$ _root_id].renderer.__draw_node();
	}
}
