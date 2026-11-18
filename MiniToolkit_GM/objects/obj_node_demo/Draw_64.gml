/// @description Debug panel

if (!debug_show_panel) exit;

var _focused = mnd_nav_get_focused_node();
var _selected = mnd_nav_get_selected_node();
var _screen = mnd_screen_get_current();

var _lines = [
	"F1 boxes  F2 origins  F3 tree  F4 stacks  F5 block  F12 panel",
	$"Input: {mnd_input_is_button() ? "BUTTON" : "CURSOR"}   Blocked: nav {mnd_input_is_nav_blocked()} / action {mnd_input_is_action_blocked()}",
	$"Focus: {(_focused != noone) ? _focused.id : "none"}   Selected: {(_selected != noone) ? _selected.id : "none"}",
	$"Screen: {(_screen != noone) ? _screen.id : "none"} ({mnd_screen_get_count()} on stack)   Roots: {array_length(mnd_root_get_all())}",
	"Events:"
];
for (var _i = 0; _i < array_length(debug_log); _i++) array_push(_lines, "  " + debug_log[_i]);

var _x = 8,
	_y = 8,
	_line_h = 18;

draw_set_font(fnt_noto_14);
draw_set_halign(fa_left);
draw_set_valign(fa_top);

draw_set_alpha(0.6);
draw_set_color(c_black);
draw_rectangle(_x - 4, _y - 4, _x + 560, _y + array_length(_lines) * _line_h + 4, false);
draw_set_alpha(1);

draw_set_color(c_white);
for (var _i = 0; _i < array_length(_lines); _i++)
{
	draw_text(_x, _y + _i * _line_h, _lines[_i]);
}

draw_set_font(-1);
draw_set_color(c_white);
