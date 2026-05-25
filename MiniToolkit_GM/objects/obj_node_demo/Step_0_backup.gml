// Inherit the parent event
event_inherited();

//if (keyboard_check_pressed(vk_f1))
//{
//	benchmark_mini_event_functional();	
//}

//if (keyboard_check_pressed(vk_f2))
//{
//	room_restart();
//}

// MiniTween v2 Test Controls
if (keyboard_check_pressed(vk_f3))
{
	test_mini_tween_v2();  // Run functional tests
}

if (keyboard_check_pressed(vk_f4))
{
	benchmark_mini_tween_v2();  // Run performance benchmark
}

if (keyboard_check_pressed(vk_f5))
{
	// Cancel demo / all tweens
	mini_tween_cancel_all();
	global.tween_demo_targets = [];
	global.tween_demo_active = false;
	show_debug_message("Demo cancelled, all tweens cleared.");
}

if (keyboard_check_pressed(vk_f6))
{
	// Start visual demo
	mini_tween_cancel_all();
	global.tween_demo_active = true;
	demo_mini_tween_v2();
}

// Stress Test Controls
if (keyboard_check_pressed(vk_f7))
{
	// Start stress test with 500 objects
	global.tween_demo_active = false;
	global.tween_demo_targets = [];
	stress_test_mini_tween_v2(500);
}

if (keyboard_check_pressed(vk_f8))
{
	// Start stress test with 1000 objects
	global.tween_demo_active = false;
	global.tween_demo_targets = [];
	stress_test_mini_tween_v2(1000);
}

if (keyboard_check_pressed(vk_f9))
{
	// Start stress test with 2000 objects
	global.tween_demo_active = false;
	global.tween_demo_targets = [];
	stress_test_mini_tween_v2(2000);
}

// Add/Remove objects during stress test
if (global.stress_test_active)
{
	if (keyboard_check_pressed(vk_add) || keyboard_check_pressed(ord("=")))
	{
		stress_test_add_objects(100);
	}
	
	if (keyboard_check_pressed(vk_subtract) || keyboard_check_pressed(ord("-")))
	{
		stress_test_remove_objects(100);
	}
	
	// Track FPS
	var _fps = fps_real;
	array_push(global.stress_test_fps_samples, _fps);
	
	// Keep only last 60 samples for rolling average
	if (array_length(global.stress_test_fps_samples) > 60)
	{
		array_delete(global.stress_test_fps_samples, 0, 1);
	}
	
	global.stress_test_fps_min = min(global.stress_test_fps_min, _fps);
	global.stress_test_fps_max = max(global.stress_test_fps_max, _fps);
}