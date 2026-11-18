/// @description MiniNode Manager Draw GUI - render roots back to front

var _len = array_length(__roots);
for (var _i = 0; _i < _len; _i++)
{
	__roots[_i].renderer.__draw_node();
}
