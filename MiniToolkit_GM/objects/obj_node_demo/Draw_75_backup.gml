
//var _node = node_manager_get_node("OptionsVContainer")
//if (_node != noone) draw_text_ext(20, 20, _node.transform, -1, 200);

draw_text(20, 20, node_manager_get_input_mode());
draw_text(20, 30, node_manager_get_selected_node_id());

// MiniTween v2 Visual Demo Drawing
if (global.tween_demo_active && array_length(global.tween_demo_targets) > 0)
{
	draw_set_alpha(1);
	
	// Draw title
	draw_set_color(c_white);
	draw_text(50, 60, "MiniTween v2 Demo (F5=Cancel, F6=Restart)");
	
	// Draw labels
	var _labels = [
		"1. Basic Move",
		"2. With Delay (0.5s)",
		"3. Ease Out (Quad)",
		"4. Ease In (Quad)",
		"5. Bounce Out",
		"6. Elastic Out",
		"7. Repeat x3 (no yoyo)",
		"8. Infinite Yoyo"
	];
	
	// Draw each demo target
	for (var _i = 0; _i < array_length(global.tween_demo_targets); _i++)
	{
		var _t = global.tween_demo_targets[_i];
		
		// Draw label
		draw_set_color(c_gray);
		draw_text(550, _t.y - 8, _labels[_i]);
		
		// Draw circle
		draw_set_color(_t.color);
		draw_set_alpha(_t.alpha);
		draw_circle(_t.x, _t.y, 12 * _t.scale, false);
		
		// Draw outline
		draw_set_color(c_white);
		draw_circle(_t.x, _t.y, 12 * _t.scale, true);
	}
	
	draw_set_alpha(1);
	draw_set_color(c_white);
	
	// Draw active tween count
	draw_text(50, 400, $"Active Tweens: {mini_tween_count()}");
}

// MiniTween v2 Stress Test Drawing
if (global.stress_test_active && array_length(global.stress_test_objects) > 0)
{
	// Draw all stress test objects
	var _count = array_length(global.stress_test_objects);
	
	for (var _i = 0; _i < _count; _i++)
	{
		var _obj = global.stress_test_objects[_i];
		
		draw_set_alpha(_obj.alpha);
		draw_set_color(_obj.color);
		
		// Draw as small circle
		draw_circle(_obj.x, _obj.y, _obj.size * _obj.scale, false);
	}
	
	draw_set_alpha(1);
	
	// Draw UI overlay
	draw_set_color(c_black);
	draw_set_alpha(0.7);
	draw_rectangle(0, 0, room_width, 55, false);
	draw_set_alpha(1);
	
	// Calculate average FPS
	var _avg_fps = 0;
	var _samples = array_length(global.stress_test_fps_samples);
	if (_samples > 0)
	{
		var _sum = 0;
		for (var _i = 0; _i < _samples; _i++)
		{
			_sum += global.stress_test_fps_samples[_i];
		}
		_avg_fps = _sum / _samples;
	}
	
	// FPS color based on performance
	var _fps_color = c_lime;
	if (fps_real < 30) _fps_color = c_red;
	else if (fps_real < 50) _fps_color = c_orange;
	else if (fps_real < 55) _fps_color = c_yellow;
	
	// Draw stats
	draw_set_color(c_white);
	draw_set_font(fnt_noto_16);
	draw_text(10, 5, $"MINITWEEN V2 STRESS TEST");
	
	draw_set_color(_fps_color);
	draw_text(10, 25, $"FPS: {floor(fps_real)} (Avg: {floor(_avg_fps)} | Min: {floor(global.stress_test_fps_min)} | Max: {floor(global.stress_test_fps_max)})");
	
	draw_set_color(c_aqua);
	draw_text(350, 5, $"Objects: {_count}");
	draw_text(350, 25, $"Active Tweens: {mini_tween_count()}");
	
	draw_set_color(c_silver);
	draw_text(550, 5, $"[+/-] Add/Remove 100");
	draw_text(550, 25, $"[F5] Stop Test");
	
	draw_set_color(c_white);
}

// Draw key hints at bottom
draw_set_color(c_dkgray);
draw_text(10, room_height - 100, "F1 = MiniEvent Tests | F2 = Restart Room");
draw_text(10, room_height - 80, "F3 = MiniTween Tests | F4 = MiniTween Benchmark");
draw_text(10, room_height - 60, "F5 = Cancel/Stop     | F6 = Visual Demo");
draw_text(10, room_height - 40, "F7 = Stress 500      | F8 = Stress 1000 | F9 = Stress 2000");
draw_set_color(c_white);