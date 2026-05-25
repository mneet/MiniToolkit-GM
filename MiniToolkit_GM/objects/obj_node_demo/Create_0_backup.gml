// Inherit the parent event
event_inherited();

#region Demo Canvas - Main Menu

// Main canvas covering the screen
canvas_main = new NodeCanvas("canvas_main", NODE_ORIGIN.TOP_LEFT);
with (canvas_main)
{
	node_set_transform(0, 0, 1, 1, 1, 0, 640, 360);
	
    var _frame = new NodeSprite("MainMenuFrame", spr_frame, c_gray, false, NODE_ORIGIN.MIDDLE_CENTER);
    with (_frame)
    {
        node_set_transform(320, 180, 1, 1, 1, 0, 200, 200, 0);
        sprite_expand_to_size();
        node_animate_on_event(self, on_enabled, "image_xscale", 1, 0.3, EASING_CURVES.SINE_OUT, 0, 0);
        
        var _v_container = new NodeContainer("MainMenuVContainer", 1, NODE_ORIGIN.MIDDLE_CENTER);
        with (_v_container)
        {
            node_set_transform(0, 0, 1, 1, 1, 0, 200, 200);
    		container_set_margin(0, 8);
    		container_set_flow(NODE_HFLOW.RIGHT, NODE_VFLOW.DOWN, NODE_AXIS.VERTICAL);
    		
    		// PLAY
    		var _btn_play = new MiniNodeSimpleButton("btn_play", "PLAY");
    		var _btn_options = new MiniNodeSimpleButton("btn_options", "OPTIONS");
			with (_btn_options)
			{
				on_button_released.connect(self, function() {
				    node_manager_transition("canvas_main", "canvas_options");
				});	
			}
			
    		var _btn_credits = new MiniNodeSimpleButton("btn_credits", "CREDITS");
    		
			var _btn_exit = new MiniNodeSimpleButton("btn_exit", "EXIT");          
			with (_btn_exit)
			{
				on_button_released.connect(self, function() {
					node_manager_enable_node("canvas_exit");
					node_manager_set_canvas_focus("canvas_exit");
				});	
			}
			
			
    		node_add(_btn_play, _btn_options, _btn_credits, _btn_exit);
        }
        
        node_add(_v_container);
    }
	
    node_add(_frame);
}

canvas_add(canvas_main, true, true);

#endregion

#region Demo Canvas - Options Menu

canvas_options = new NodeCanvas("canvas_options", NODE_ORIGIN.TOP_LEFT);
with (canvas_options)
{
	node_set_transform(0, 0, 1, 1, 1, 0, 640, 360);
	
	var _frame = new NodeSprite("OptionsFrame", spr_frame, c_gray, false, NODE_ORIGIN.MIDDLE_CENTER);
	with (_frame)
	{
		node_set_transform(320, 180, 1, 1, 1, 0, 280, 320);
		sprite_expand_to_size();
		node_animate_on_event(self, on_enabled, "image_xscale", 1, 0.4, EASING_CURVES.SINE_OUT, 0, 0);
		
		var _title = new NodeText("OptionsTitle", "OPTIONS", fnt_noto_16, c_white, NODE_ORIGIN.MIDDLE_CENTER);
		with (_title)
		{
			node_set_transform(0, -130, 1, 1, 1, 0, 200, 32);
		}
		
		var _v_container = new NodeContainer("OptionsVContainer", 1, NODE_ORIGIN.MIDDLE_CENTER);
		with (_v_container)
		{
			node_set_transform(0, 10, 1, 1, 1, 0, 240, 260);
			container_set_margin(0, 8);
			container_set_flow(NODE_HFLOW.RIGHT, NODE_VFLOW.DOWN, NODE_AXIS.VERTICAL);
			
			// Volume Sliders
			var _slider_main = new MiniNodeLabeledSlider("slider_main", "Main Volume", 0, 100, 80, 220, 24);
			var _slider_sfx = new MiniNodeLabeledSlider("slider_sfx", "SFX Volume", 0, 100, 100, 220, 24);
			var _slider_music = new MiniNodeLabeledSlider("slider_music", "Music Volume", 0, 100, 70, 220, 24);
			
			// Fullscreen Toggle
			var _toggle_fullscreen = new MiniNodeToggle("toggle_fullscreen", "Fullscreen", window_get_fullscreen(), 220, 36);
			with (_toggle_fullscreen)
			{
				on_toggled.connect(self, function() {
					window_set_fullscreen(is_on);
				});
			}
			
			// Back Button
			var _btn_back = new MiniNodeSimpleButton("btn_back", "BACK", fnt_noto_16, 220, 36);
			with (_btn_back)
			{
				on_button_released.connect(self, function() {
					node_manager_transition("canvas_options", "canvas_main");
				});
			}
			
			node_add(_slider_main, _slider_sfx, _slider_music, _toggle_fullscreen, _btn_back);
		}
		
		node_add(_title, _v_container);
	}
	
	node_add(_frame);
}

canvas_add(canvas_options, false);

#endregion

#region Demo Canvas - Exit Popup

canvas_exit = new NodeCanvas("canvas_exit", NODE_ORIGIN.TOP_LEFT);
with (canvas_exit)
{
	node_set_transform(0, 0, 1, 1, 1, 0, 640, 360);
	
	var _frame = new NodeSprite("ExitFrame", spr_frame_filled, c_gray, false, NODE_ORIGIN.MIDDLE_CENTER);
	with (_frame)
	{
		node_set_transform(320, 180, 1, 1, 1, 0, 280, 140);
		sprite_expand_to_size();
		
		node_animate_on_event(self, on_enabled, "image_yscale", 1, 0.3, EASING_CURVES.BACK_OUT, 0, 0);
		node_animate_on_event(self, on_disabling, "image_yscale", 0, 0.15, EASING_CURVES.BACK_IN, 0);
		
		var _title = new NodeText("ExitTitle", "Are you sure you want to exit?", fnt_noto_16, c_white, NODE_ORIGIN.MIDDLE_CENTER);
		with (_title)
		{
			node_set_transform(0, -30, 1, 1, 1, 0, 260, 32);
		}
		
		var _h_container = new NodeContainer("ExitHContainer", 2, NODE_ORIGIN.MIDDLE_CENTER);
		with (_h_container)
		{
			node_set_transform(0, 25, 1, 1, 1, 0, 260, 50);
			container_set_margin(16, 0);
			container_set_flow(NODE_HFLOW.RIGHT, NODE_VFLOW.DOWN, NODE_AXIS.HORIZONTAL);
			
			var _btn_yes = new MiniNodeSimpleButton("btn_yes", "YES", fnt_noto_16, 100, 36);
			with (_btn_yes)
			{
				on_button_released.connect(self, function() {
				    game_end();
				});		
			}
			
			var _btn_no = new MiniNodeSimpleButton("btn_no", "NO", fnt_noto_16, 100, 36);
			with (_btn_no)
			{
				on_button_released.connect(self, function() {
					node_manager_disable_node("canvas_exit", 0.15);
					node_manager_set_canvas_focus("canvas_main")
				});	
			}
			
			node_add(_btn_yes, _btn_no);
		}
		
		node_add(_title, _h_container);
	}
	
	node_add(_frame);
}

canvas_add(canvas_exit, false);

#endregion

#region MiniEvent Performance Benchmark

/// @description Benchmark for MiniEvent system
/// Tests: connect, invoke, disconnect performance

benchmark_mini_event = function()
{
	show_debug_message("\n========== MINI EVENT BENCHMARK ==========\n");
	
	var _iterations = 100;
	var _num_connections = 100;
	var _invoke_count = 100;
	
	// Create test structs to act as connections
	var _connections = array_create(_num_connections);
	for (var _i = 0; _i < _num_connections; _i++)
	{
		_connections[_i] = {
			call_count: 0,
			on_event: function() { call_count++; },
			on_event_with_args: function(_a, _b) { call_count += _a + _b; }
		};
	}
	
	// ===== TEST 1: Connect Performance =====
	var _event_connect = new MiniEvent();
	var _t_start = get_timer();
	
	for (var _iter = 0; _iter < _iterations; _iter++)
	{
		_event_connect.cleanup();
		for (var _i = 0; _i < _num_connections; _i++)
		{
			_event_connect.connect(_connections[_i], _connections[_i].on_event);
		}
	}
	
	var _t_connect = (get_timer() - _t_start) / 1000;
	var _connects_total = _iterations * _num_connections;
	show_debug_message($"[CONNECT] {_connects_total} connections in {_t_connect}ms ({_connects_total / _t_connect * 1000} connects/sec)");
	
	// ===== TEST 4: Disconnect Performance =====
	_t_start = get_timer();
	for (var _iter = 0; _iter < _iterations; _iter++)
	{
		//// Disconnect all
		for (var _i = 0; _i < _num_connections; _i++)
		{
			_event_connect.disconnect(_connections[_i], _connections[_i].on_event);
		}
	}
	var _t_disconnect = (get_timer() - _t_start) / 1000;
	var _disconnects_total = _iterations * _num_connections;
	show_debug_message($"[DISCONNECT] {_disconnects_total} connect+disconnect cycles in {_t_disconnect}ms");
	
	// ===== TEST 2: Invoke Performance (no args) =====
	var _event_invoke = new MiniEvent();
	for (var _i = 0; _i < _num_connections; _i++)
	{
		_connections[_i].call_count = 0;
		_event_invoke.connect(_connections[_i], _connections[_i].on_event);
	}
	
	_t_start = get_timer();
	for (var _iter = 0; _iter < _invoke_count; _iter++)
	{
		_event_invoke.invoke();
	}
	var _t_invoke = (get_timer() - _t_start) / 1000;
	var _invokes_total = _invoke_count * _num_connections;
	show_debug_message($"[INVOKE] {_invokes_total} callback executions in {_t_invoke}ms ({_invokes_total / _t_invoke * 1000} callbacks/sec)");
	show_debug_message($"         Verify: connection[0].call_count = {_connections[0].call_count} (expected {_invoke_count})");
	
	// ===== TEST 3: Invoke Performance (with args) =====
	var _event_invoke_args = new MiniEvent();
	for (var _i = 0; _i < _num_connections; _i++)
	{
		_connections[_i].call_count = 0;
		_event_invoke_args.connect(_connections[_i], _connections[_i].on_event_with_args);
	}
	
	_t_start = get_timer();
	for (var _iter = 0; _iter < _invoke_count; _iter++)
	{
		_event_invoke_args.invoke(1, 2);
	}
	var _t_invoke_args = (get_timer() - _t_start) / 1000;
	show_debug_message($"[INVOKE+ARGS] {_invokes_total} callback executions in {_t_invoke_args}ms ({_invokes_total / _t_invoke_args * 1000} callbacks/sec)");
	show_debug_message($"              Verify: connection[0].call_count = {_connections[0].call_count} (expected {_invoke_count * 3})");	
	
	// ===== SUMMARY =====
	show_debug_message("\n========== BENCHMARK SUMMARY ==========");
	show_debug_message($"Connections: {_num_connections}");
	show_debug_message($"Connect iterations: {_iterations}");
	show_debug_message($"Invoke iterations: {_invoke_count}");
	show_debug_message($"");
	show_debug_message($"Connect:      {_t_connect}ms");
	show_debug_message($"Invoke:       {_t_invoke}ms");
	show_debug_message($"Invoke+Args:  {_t_invoke_args}ms");
	show_debug_message($"Disconnect:   {_t_disconnect}ms");
	show_debug_message("==========================================\n");
	
	// Cleanup
	_event_connect.cleanup();
	_event_invoke.cleanup();
	_event_invoke_args.cleanup();
}

/// @description Functional tests for MiniEvent system
/// Tests: correctness of all features (priority, once, disconnect, cleanup, etc.)
benchmark_mini_event_functional = function()
{
	show_debug_message("\n========== MINI EVENT FUNCTIONAL TESTS ==========\n");
	
	var _tests_passed = 0;
	var _tests_total = 0;
	
	// Helper to log test results
	var _log_test = function(_name, _passed, _details = "")
	{
		var _status = _passed ? "✓ PASS" : "✗ FAIL";
		var _detail_str = _details != "" ? $" ({_details})" : "";
		show_debug_message($"[{_status}] {_name}{_detail_str}");
		return _passed;
	};
	
	// ===== TEST 1: Basic Connect & Invoke =====
	_tests_total++;
	var _evt1 = new MiniEvent();
	var _conn1 = { count: 0, on_event: function() { self.count++; } };
	_evt1.connect(_conn1, _conn1.on_event);
	_evt1.invoke();
	_evt1.invoke();
	if (_log_test("Basic Connect & Invoke", _conn1.count == 2, $"count={_conn1.count}, expected=2"))
		_tests_passed++;
	_evt1.cleanup();
	
	// ===== TEST 2: Invoke with Arguments =====
	_tests_total++;
	var _evt2 = new MiniEvent();
	var _conn2 = { result: 0, on_event: function(_a, _b, _c) { self.result = _a + _b + _c; } };
	_evt2.connect(_conn2, _conn2.on_event);
	_evt2.invoke(10, 20, 30);
	if (_log_test("Invoke with Arguments", _conn2.result == 60, $"result={_conn2.result}, expected=60"))
		_tests_passed++;
	_evt2.cleanup();
	
	// ===== TEST 3: Priority Ordering =====
	_tests_total++;
	var _evt3 = new MiniEvent();
	var _order3 = [];
	var _conn3_low = { order_ref: _order3, cb: function() { array_push(order_ref, "LOW"); } };
	var _conn3_med = { order_ref: _order3, cb: function() { array_push(order_ref, "MED"); } };
	var _conn3_high = { order_ref: _order3, cb: function() { array_push(order_ref, "HIGH"); } };
	var _conn3_highest = { order_ref: _order3, cb: function() { array_push(order_ref, "HIGHEST"); } };
	
	// Connect in random order with different priorities
	_evt3.connect(_conn3_low, _conn3_low.cb, false, 0);
	_evt3.connect(_conn3_highest, _conn3_highest.cb, false, 999);
	_evt3.connect(_conn3_med, _conn3_med.cb, false, 50);
	_evt3.connect(_conn3_high, _conn3_high.cb, false, 100);
	_evt3.invoke();
	
	var _priority_ok = (array_length(_order3) == 4 && 
		_order3[0] == "HIGHEST" && _order3[1] == "HIGH" && 
		_order3[2] == "MED" && _order3[3] == "LOW");
	if (_log_test("Priority Ordering", _priority_ok, $"order={_order3}"))
		_tests_passed++;
	_evt3.cleanup();
	
	// ===== TEST 4: Once Flag =====
	_tests_total++;
	var _evt4 = new MiniEvent();
	var _conn4 = { count: 0, cb: function() { self.count++; } };
	_evt4.connect(_conn4, _conn4.cb, true); // once = true
	_evt4.invoke();
	_evt4.invoke();
	_evt4.invoke();
	if (_log_test("Once Flag", _conn4.count == 1, $"count={_conn4.count}, expected=1"))
		_tests_passed++;
	_evt4.cleanup();
	
	// ===== TEST 5: Disconnect Specific Callback =====
	_tests_total++;
	var _evt5 = new MiniEvent();
	var _conn5 = { 
		count_a: 0, count_b: 0,
		cb_a: function() { self.count_a++; },
		cb_b: function() { self.count_b++; }
	};
	_evt5.connect(_conn5, _conn5.cb_a);
	_evt5.connect(_conn5, _conn5.cb_b);
	_evt5.invoke(); // Both fire: a=1, b=1
	_evt5.disconnect(_conn5, _conn5.cb_a); // Remove only cb_a
	_evt5.invoke(); // Only cb_b fires: a=1, b=2
	var _disconnect_ok = (_conn5.count_a == 1 && _conn5.count_b == 2);
	if (_log_test("Disconnect Specific Callback", _disconnect_ok, $"a={_conn5.count_a}(exp 1), b={_conn5.count_b}(exp 2)"))
		_tests_passed++;
	_evt5.cleanup();
	
	// ===== TEST 6: Disconnect All from Connection =====
	_tests_total++;
	var _evt6 = new MiniEvent();
	var _conn6 = { 
		count_a: 0, count_b: 0,
		cb_a: function() { self.count_a++; },
		cb_b: function() { self.count_b++; }
	};
	_evt6.connect(_conn6, _conn6.cb_a);
	_evt6.connect(_conn6, _conn6.cb_b);
	_evt6.invoke(); // Both fire: a=1, b=1
	_evt6.disconnect(_conn6); // Remove all from _conn6
	_evt6.invoke(); // Nothing fires: a=1, b=1
	var _disconnect_all_ok = (_conn6.count_a == 1 && _conn6.count_b == 1);
	if (_log_test("Disconnect All from Connection", _disconnect_all_ok, $"a={_conn6.count_a}(exp 1), b={_conn6.count_b}(exp 1)"))
		_tests_passed++;
	_evt6.cleanup();
	
	// ===== TEST 7: Multiple Connections to Same Event =====
	_tests_total++;
	var _evt7 = new MiniEvent();
	var _conn7a = { count: 0, cb: function() { self.count++; } };
	var _conn7b = { count: 0, cb: function() { self.count++; } };
	var _conn7c = { count: 0, cb: function() { self.count++; } };
	_evt7.connect(_conn7a, _conn7a.cb);
	_evt7.connect(_conn7b, _conn7b.cb);
	_evt7.connect(_conn7c, _conn7c.cb);
	_evt7.invoke();
	var _multi_ok = (_conn7a.count == 1 && _conn7b.count == 1 && _conn7c.count == 1);
	if (_log_test("Multiple Connections", _multi_ok, $"a={_conn7a.count}, b={_conn7b.count}, c={_conn7c.count}"))
		_tests_passed++;
	_evt7.cleanup();
	
	// ===== TEST 8: Same Callback Cannot Connect Twice =====
	_tests_total++;
	var _evt8 = new MiniEvent();
	var _conn8 = { count: 0, cb: function() { self.count++; } };
	_evt8.connect(_conn8, _conn8.cb);
	_evt8.connect(_conn8, _conn8.cb); // Should overwrite, not duplicate
	_evt8.invoke();
	if (_log_test("No Duplicate Callbacks", _conn8.count == 1, $"count={_conn8.count}, expected=1"))
		_tests_passed++;
	_evt8.cleanup();
	
	// ===== TEST 9: Disconnect Non-existent Callback (no crash) =====
	_tests_total++;
	var _evt9 = new MiniEvent();
	var _conn9 = { cb: function() {} };
	var _conn9_other = { cb: function() {} };
	_evt9.connect(_conn9, _conn9.cb);
	_evt9.disconnect(_conn9_other, _conn9_other.cb); // Should not crash
	_evt9.disconnect(_conn9, _conn9_other.cb); // Wrong callback, should not crash
	_evt9.invoke(); // Should still work
	if (_log_test("Disconnect Non-existent (no crash)", true))
		_tests_passed++;
	_evt9.cleanup();
	
	// ===== TEST 10: Auto-cleanup Dead Struct Connections =====
	_tests_total++;
	var _evt10 = new MiniEvent();
	var _alive_conn = { count: 0, cb: function() { self.count++; } };
	var _dead_conn = { cb: function() {} };
	_evt10.connect(_alive_conn, _alive_conn.cb);
	_evt10.connect(_dead_conn, _dead_conn.cb);
	_dead_conn = undefined;
	gc_collect();
	_evt10.invoke(); // Should handle dead connection gracefully
	if (_log_test("Auto-cleanup Dead Connections", _alive_conn.count == 1, $"alive.count={_alive_conn.count}"))
		_tests_passed++;
	_evt10.cleanup();
	
	// ===== TEST 11: Method Chaining =====
	_tests_total++;
	var _evt11 = new MiniEvent();
	var _conn11 = { count: 0, cb: function() { self.count++; } };
	var _chain_result = _evt11.connect(_conn11, _conn11.cb).invoke().invoke().invoke();
	var _chain_ok = (_chain_result == _evt11 && _conn11.count == 3);
	if (_log_test("Method Chaining", _chain_ok, $"returns self={_chain_result == _evt11}, count={_conn11.count}"))
		_tests_passed++;
	_evt11.cleanup();
	
	// ===== TEST 12: Cleanup Removes All =====
	_tests_total++;
	var _evt12 = new MiniEvent();
	var _conn12 = { count: 0, cb: function() { self.count++; } };
	_evt12.connect(_conn12, _conn12.cb);
	_evt12.invoke(); // count = 1
	_evt12.cleanup();
	_evt12.invoke(); // Should do nothing, count still 1
	if (_log_test("Cleanup Removes All", _conn12.count == 1, $"count={_conn12.count}, expected=1"))
		_tests_passed++;
	
	// ===== TEST 13: Mixed Once and Permanent =====
	_tests_total++;
	var _evt13 = new MiniEvent();
	var _conn13 = { 
		once_count: 0, perm_count: 0,
		cb_once: function() { self.once_count++; },
		cb_perm: function() { self.perm_count++; }
	};
	_evt13.connect(_conn13, _conn13.cb_once, true);  // once
	_evt13.connect(_conn13, _conn13.cb_perm, false); // permanent
	_evt13.invoke(); // once=1, perm=1
	_evt13.invoke(); // once=1, perm=2
	_evt13.invoke(); // once=1, perm=3
	var _mixed_ok = (_conn13.once_count == 1 && _conn13.perm_count == 3);
	if (_log_test("Mixed Once and Permanent", _mixed_ok, $"once={_conn13.once_count}(exp 1), perm={_conn13.perm_count}(exp 3)"))
		_tests_passed++;
	_evt13.cleanup();
	
	// ===== TEST 14: Connect with Function (not method) =====
	_tests_total++;
	var _evt14 = new MiniEvent();
	global.__test14_count = 0;
	var _conn14 = { dummy: 0 };
	var _standalone_func = function() { global.__test14_count++; };
	_evt14.connect(_conn14, _standalone_func);
	_evt14.invoke();
	_evt14.invoke();
	if (_log_test("Connect with Function", global.__test14_count == 2, $"count={global.__test14_count}, expected=2"))
		_tests_passed++;
	_evt14.cleanup();
	
	// ===== FINAL SUMMARY =====
	show_debug_message("\n========== FUNCTIONAL TEST SUMMARY ==========");
	show_debug_message($"Tests Passed: {_tests_passed}/{_tests_total}");
	if (_tests_passed == _tests_total)
		show_debug_message("✓ ALL TESTS PASSED!");
	else
		show_debug_message($"✗ {_tests_total - _tests_passed} TESTS FAILED");
	show_debug_message("==============================================\n");
	
	return _tests_passed == _tests_total;
}

// Run functional tests (comment out if not needed)
// benchmark_mini_event_functional();

#endregion

#region Node System Benchmark

/// @description Benchmark for Node UI system
/// Tests: node creation, hierarchy, transforms, processing, rendering simulation

benchmark_node_system = function()
{
	show_debug_message("\n========== NODE SYSTEM BENCHMARK ==========\n");
	
	var _iterations = 100;
	var _num_nodes = 100;
	var _hierarchy_depth = 5;
	var _process_iterations = 100;
	
	// ===== TEST 1: Node Creation Performance =====
	var _nodes = [];
	var _t_start = get_timer();
	
	for (var _iter = 0; _iter < _iterations; _iter++)
	{
		// Clear previous nodes
		_nodes = [];
		
		for (var _i = 0; _i < _num_nodes; _i++)
		{
			var _node = new Node($"bench_node_{_i}", NODE_ORIGIN.MIDDLE_CENTER);
			_node.node_set_transform(
				irandom(640), irandom(360),  // x, y
				1, 1,                         // scale
				1,                            // alpha
				0,                            // angle
				100, 50                       // width, height
			);
			array_push(_nodes, _node);
		}
	}
	
	var _t_create = (get_timer() - _t_start) / 1000;
	var _creates_total = _iterations * _num_nodes;
	show_debug_message($"[NODE CREATE] {_creates_total} nodes in {_t_create}ms ({_creates_total / _t_create * 1000} nodes/sec)");
	
	// ===== TEST 2: Hierarchy Building (node_add) =====
	_t_start = get_timer();
	
	for (var _iter = 0; _iter < _iterations; _iter++)
	{
		// Create a fresh canvas for each iteration
		var _canvas = new NodeCanvas($"bench_canvas_{_iter}", NODE_ORIGIN.TOP_LEFT);
		_canvas.node_set_transform(0, 0, 1, 1, 1, 0, 640, 360);
		
		// Create nested hierarchy
		var _parent = _canvas;
		for (var _depth = 0; _depth < _hierarchy_depth; _depth++)
		{
			var _children_count = floor(_num_nodes / _hierarchy_depth);
			for (var _i = 0; _i < _children_count; _i++)
			{
				var _child = new Node($"child_{_depth}_{_i}", NODE_ORIGIN.MIDDLE_CENTER);
				_child.node_set_transform(_i * 10, _depth * 20, 1, 1, 1, 0, 50, 30);
				_parent.node_add(_child);
			}
			// Next depth uses first child as parent
			if (array_length(_parent.__nested_nodes) > 0)
			{
				_parent = _parent.__nested_nodes[0];
			}
		}
	}
	
	var _t_hierarchy = (get_timer() - _t_start) / 1000;
	show_debug_message($"[HIERARCHY] {_iterations} hierarchies ({_hierarchy_depth} deep, ~{_num_nodes} nodes each) in {_t_hierarchy}ms");
	
	// ===== TEST 3: Transform Propagation =====
	// Build a deep hierarchy and measure transform updates
	var _transform_canvas = new NodeCanvas("transform_bench", NODE_ORIGIN.TOP_LEFT);
	_transform_canvas.node_set_transform(0, 0, 1, 1, 1, 0, 640, 360);
	
	// Build flat hierarchy with many children
	var _transform_nodes = [];
	for (var _i = 0; _i < _num_nodes; _i++)
	{
		var _node = new Node($"transform_node_{_i}", NODE_ORIGIN.MIDDLE_CENTER);
		_node.node_set_transform(irandom(640), irandom(360), 1, 1, 1, 0, 50, 30);
		_transform_canvas.node_add(_node);
		array_push(_transform_nodes, _node);
	}
	
	_t_start = get_timer();
	
	for (var _iter = 0; _iter < _process_iterations; _iter++)
	{
		// Mark root transform dirty (propagates to all children)
		_transform_canvas.__mark_transform_dirty();
		
		// Resolve all transforms
		_transform_canvas.__resolve_transform();
		for (var _i = 0; _i < _num_nodes; _i++)
		{
			_transform_nodes[_i].__resolve_transform();
		}
	}
	
	var _t_transform = (get_timer() - _t_start) / 1000;
	var _transform_ops = _process_iterations * (_num_nodes + 1);
	show_debug_message($"[TRANSFORM] {_transform_ops} transform resolves in {_t_transform}ms ({_transform_ops / _t_transform * 1000} ops/sec)");
	
	// ===== TEST 4: NodeContainer Layout =====
	var _containers = [];
	
	_t_start = get_timer();
	
	for (var _iter = 0; _iter < _iterations; _iter++)
	{
		var _container = new NodeContainer($"container_{_iter}", 5, NODE_ORIGIN.TOP_LEFT);
		_container.node_set_transform(0, 0, 1, 1, 1, 0, 400, 300);
		_container.container_set_margin(8, 8);
		_container.container_set_flow(NODE_HFLOW.RIGHT, NODE_VFLOW.DOWN, NODE_AXIS.HORIZONTAL);
		
		// Add children to container
		var _children_per_container = 20;
		for (var _i = 0; _i < _children_per_container; _i++)
		{
			var _child = new Node($"cont_child_{_iter}_{_i}", NODE_ORIGIN.TOP_LEFT);
			_child.node_set_transform(0, 0, 1, 1, 1, 0, 60, 40);
			_container.node_add(_child);
		}
		
		// Trigger layout calculation
		_container.__container_organize();
		array_push(_containers, _container);
	}
	
	var _t_container = (get_timer() - _t_start) / 1000;
	show_debug_message($"[CONTAINER] {_iterations} containers (20 children each) layout in {_t_container}ms");
	
	// ===== TEST 5: Process Execution =====
	var _process_canvas = new NodeCanvas("process_bench", NODE_ORIGIN.TOP_LEFT);
	_process_canvas.node_set_transform(0, 0, 1, 1, 1, 0, 640, 360);
	
	var _process_counter = { count: 0 };
	var _process_nodes = [];
	
	for (var _i = 0; _i < _num_nodes; _i++)
	{
		var _node = new Node($"process_node_{_i}", NODE_ORIGIN.MIDDLE_CENTER);
		_node.node_set_transform(0, 0, 1, 1, 1, 0, 50, 30);
		_node.__process_counter = _process_counter;
		
		// Add a simple process to each node
		_node.processor.add_process(function() {
			__process_counter.count++;
		});
		
		_process_canvas.node_add(_node);
		array_push(_process_nodes, _node);
	}
	
	// Initialize nodes (skip first frame init)
	for (var _i = 0; _i < _num_nodes; _i++)
	{
		_process_nodes[_i].processor.is_initialized = true;
	}
	
	_t_start = get_timer();
	
	for (var _iter = 0; _iter < _process_iterations; _iter++)
	{
		// Simulate stepping all processors
		for (var _i = 0; _i < _num_nodes; _i++)
		{
			_process_nodes[_i].processor.__step_processor();
		}
	}
	
	var _t_process = (get_timer() - _t_start) / 1000;
	var _process_total = _process_iterations * _num_nodes;
	show_debug_message($"[PROCESS] {_process_total} process steps in {_t_process}ms ({_process_total / _t_process * 1000} steps/sec)");
	show_debug_message($"          Verify: process_counter = {_process_counter.count} (expected {_process_total})");
	
	// ===== TEST 6: Node Lookup Performance =====
	// Register nodes in manager for lookup test
	var _lookup_nodes = [];
	for (var _i = 0; _i < _num_nodes; _i++)
	{
		var _node = new Node($"lookup_node_{_i}", NODE_ORIGIN.MIDDLE_CENTER);
		_node.node_set_transform(0, 0, 1, 1, 1, 0, 50, 30);
		array_push(_lookup_nodes, _node);
		
		// Manually register in node manager
		global.node_manager.__node_collection[$ _node.id] = weak_ref_create(_node);
	}
	
	_t_start = get_timer();
	
	for (var _iter = 0; _iter < _process_iterations; _iter++)
	{
		for (var _i = 0; _i < _num_nodes; _i++)
		{
			var _found = node_manager_get_node($"lookup_node_{_i}");
		}
	}
	
	var _t_lookup = (get_timer() - _t_start) / 1000;
	var _lookup_total = _process_iterations * _num_nodes;
	show_debug_message($"[LOOKUP] {_lookup_total} node lookups in {_t_lookup}ms ({_lookup_total / _t_lookup * 1000} lookups/sec)");
	
	// ===== TEST 7: Event Invocation on Nodes =====
	var _event_nodes = [];
	var _event_counter = { count: 0 };
	
	for (var _i = 0; _i < _num_nodes; _i++)
	{
		var _node = new Node($"event_node_{_i}", NODE_ORIGIN.MIDDLE_CENTER);
		_node.__event_counter = _event_counter;
		_node.on_transform_modified.connect(_node, function() {
			__event_counter.count++;
		});
		array_push(_event_nodes, _node);
	}
	
	_t_start = get_timer();
	
	for (var _iter = 0; _iter < _process_iterations; _iter++)
	{
		for (var _i = 0; _i < _num_nodes; _i++)
		{
			_event_nodes[_i].on_transform_modified.invoke();
		}
	}
	
	var _t_events = (get_timer() - _t_start) / 1000;
	var _event_total = _process_iterations * _num_nodes;
	show_debug_message($"[NODE EVENTS] {_event_total} event invocations in {_t_events}ms ({_event_total / _t_events * 1000} invokes/sec)");
	show_debug_message($"              Verify: event_counter = {_event_counter.count} (expected {_event_total})");
	
	// ===== SUMMARY =====
	show_debug_message("\n========== NODE BENCHMARK SUMMARY ==========");
	show_debug_message($"Nodes per test: {_num_nodes}");
	show_debug_message($"Iterations: {_iterations}");
	show_debug_message($"Process iterations: {_process_iterations}");
	show_debug_message($"");
	show_debug_message($"Node Create:     {_t_create}ms");
	show_debug_message($"Hierarchy Build: {_t_hierarchy}ms");
	show_debug_message($"Transform:       {_t_transform}ms");
	show_debug_message($"Container:       {_t_container}ms");
	show_debug_message($"Process:         {_t_process}ms");
	show_debug_message($"Lookup:          {_t_lookup}ms");
	show_debug_message($"Node Events:     {_t_events}ms");
	show_debug_message("=============================================\n");
	
	// Cleanup lookup nodes from manager
	for (var _i = 0; _i < _num_nodes; _i++)
	{
		struct_remove(global.node_manager.__node_collection, $"lookup_node_{_i}");
	}
}

// Run node benchmark (comment out if not needed)
// benchmark_node_system();

#endregion


method_test = function()
{
	show_debug_message("METHOD TEST");
}


function test_comparison()
{
	// do nothing	
}

var _method = method(id, test_comparison);


show_debug_message($"POINT TEST:\n FUNC {test_comparison}|{_method}\n COMPARISON {test_comparison == _method}");

#region MiniTween v2 Test Suite

/// @function		test_mini_tween_v2()
/// @description	Comprehensive test suite for MiniTween v2
function test_mini_tween_v2()
{
	show_debug_message("\n========== MINITWEEN V2 TEST SUITE ==========");
	
	var _tests_passed = 0;
	var _tests_failed = 0;
	var _test_results = [];
	
	// Helper function to log results
	var _log_test = function(_name, _passed, _message = "")
	{
		var _status = _passed ? "✓ PASS" : "✗ FAIL";
		var _msg = _message != "" ? $" - {_message}" : "";
		show_debug_message($"  [{_status}] {_name}{_msg}");
		return _passed;
	};
	
	// Clear any existing tweens
	mini_tween_cancel_all();
	
	// ===== TEST 1: Basic Tween Creation =====
	show_debug_message("\n--- Test 1: Basic Tween Creation ---");
	{
		var _target = { x: 0, y: 0, alpha: 1 };
		var _tween = mini_tween(_target, 1.0)
			.tween("x", 100)
			.tween("y", 200);
		
		var _passed = (_tween != undefined);
		_passed = _passed && (array_length(_tween.__properties) == 2);
		_passed = _passed && (mini_tween_count() == 1);
		
		if (_log_test("Basic tween creation", _passed, $"Properties: {array_length(_tween.__properties)}, Active: {mini_tween_count()}"))
			_tests_passed++;
		else
			_tests_failed++;
		
		_tween.cancel();
	}
	
	// ===== TEST 2: Delay Configuration =====
	show_debug_message("\n--- Test 2: Delay Configuration ---");
	{
		mini_tween_cancel_all();
		var _target = { value: 0 };
		var _tween = mini_tween(_target, 0.5)
			.tween("value", 100)
			.delay(0.3);
		
		var _passed = (_tween.__delay == 0.3);
		_passed = _passed && (_tween.__delay_remaining == 0.3);
		
		if (_log_test("Delay configuration", _passed, $"delay={_tween.__delay}, remaining={_tween.__delay_remaining}"))
			_tests_passed++;
		else
			_tests_failed++;
		
		_tween.cancel();
	}
	
	// ===== TEST 3: Repeat/Yoyo Configuration =====
	show_debug_message("\n--- Test 3: Repeat/Yoyo Configuration ---");
	{
		mini_tween_cancel_all();
		var _target = { scale: 1 };
		var _tween = mini_tween(_target, 0.5)
			.tween("scale", 2)
			.repeat(3, true);
		
		var _passed = (_tween.__repeat_count == 3);
		_passed = _passed && (_tween.__yoyo == true);
		
		if (_log_test("Repeat/Yoyo config", _passed, $"repeat={_tween.__repeat_count}, yoyo={_tween.__yoyo}"))
			_tests_passed++;
		else
			_tests_failed++;
		
		_tween.cancel();
	}
	
	// ===== TEST 4: Callback Registration =====
	show_debug_message("\n--- Test 4: Callback Registration ---");
	{
		mini_tween_cancel_all();
		var _target = { x: 0 };
		var _callback_data = { __start: false, __complete: false, __repeat: false, __cancel: false };
		
		var _tween = mini_tween(_target, 0.1)
			.tween("x", 100)
			.on_start(method(_callback_data, function() { __start = true; }))
			.on_complete(method(_callback_data, function() { __complete = true; }))
			.on_repeat(method(_callback_data, function() { __repeat = true; }))
			.on_cancel(method(_callback_data, function() { __cancel = true; }));
		
		var _passed = (_tween.__on_start != undefined);
		_passed = _passed && (_tween.__on_complete != undefined);
		_passed = _passed && (_tween.__on_repeat != undefined);
		_passed = _passed && (_tween.__on_cancel != undefined);
		
		if (_log_test("Callback registration", _passed))
			_tests_passed++;
		else
			_tests_failed++;
		
		_tween.cancel();
	}
	
	// ===== TEST 5: Pause/Resume =====
	show_debug_message("\n--- Test 5: Pause/Resume ---");
	{
		mini_tween_cancel_all();
		var _target = { x: 0 };
		var _tween = mini_tween(_target, 1.0)
			.tween("x", 100);
		
		_tween.pause();
		var _paused = _tween.__paused;
		
		_tween.resume();
		var _resumed = !_tween.__paused;
		
		var _passed = _paused && _resumed;
		
		if (_log_test("Pause/Resume", _passed, $"paused={_paused}, resumed={_resumed}"))
			_tests_passed++;
		else
			_tests_failed++;
		
		_tween.cancel();
	}
	
	// ===== TEST 6: Cancel with Callback =====
	show_debug_message("\n--- Test 6: Cancel with Callback ---");
	{
		mini_tween_cancel_all();
		var _target = { x: 0 };
		var _callback_data = { cancelled: false };
		
		var _tween = mini_tween(_target, 1.0)
			.tween("x", 100)
			.on_cancel(method(_callback_data, function() { cancelled = true; }));
		
		_tween.cancel();
		
		var _passed = _tween.__destroyed && _callback_data.cancelled;
		
		if (_log_test("Cancel with callback", _passed, $"destroyed={_tween.__destroyed}, callback_fired={_callback_data.cancelled}"))
			_tests_passed++;
		else
			_tests_failed++;
	}
	
	// ===== TEST 7: Complete (Jump to End) =====
	show_debug_message("\n--- Test 7: Complete (Jump to End) ---");
	{
		mini_tween_cancel_all();
		var _target = { x: 0, y: 0 };
		var _callback_data = { completed: false };
		
		var _tween = mini_tween(_target, 10.0)  // Long duration
			.tween("x", 100)
			.tween("y", 200)
			.on_complete(method(_callback_data, function() { completed = true; }));
		
		_tween.complete();  // Jump to end immediately
		
		var _passed = (_target.x == 100) && (_target.y == 200) && _callback_data.completed;
		
		if (_log_test("Complete (jump to end)", _passed, $"x={_target.x}, y={_target.y}, callback={_callback_data.completed}"))
			_tests_passed++;
		else
			_tests_failed++;
	}
	
	// ===== TEST 8: Shortcut - mini_tween_to =====
	show_debug_message("\n--- Test 8: Shortcut - mini_tween_to ---");
	{
		mini_tween_cancel_all();
		var _target = { x: 0, y: 0, alpha: 1 };
		
		var _tween = mini_tween_to(_target, 0.5, { x: 100, y: 200, alpha: 0.5 });
		
		var _passed = (array_length(_tween.__properties) == 3);
		var _has_x = _tween.__has_property("x");
		var _has_y = _tween.__has_property("y");
		var _has_alpha = _tween.__has_property("alpha");
		_passed = _passed && _has_x && _has_y && _has_alpha;
		
		if (_log_test("mini_tween_to shortcut", _passed, $"props={array_length(_tween.__properties)}, x={_has_x}, y={_has_y}, alpha={_has_alpha}"))
			_tests_passed++;
		else
			_tests_failed++;
		
		_tween.cancel();
	}
	
	// ===== TEST 9: Unique Mode (Cancel Conflicting) =====
	show_debug_message("\n--- Test 9: Unique Mode (Cancel Conflicting) ---");
	{
		mini_tween_cancel_all();
		var _target = { x: 0 };
		
		// Create first tween
		var _tween1 = mini_tween(_target, 5.0)
			.tween("x", 100);
		
		// Simulate it starting (so it registers properties)
		_tween1.__started = true;
		_tween1.__properties[0].from = 0;
		_tween1.__properties[0].diff = 100;
		
		// Create second unique tween on same property
		var _tween2 = mini_tween(_target, 0.5, true)  // unique = true
			.tween("x", 200);
		
		// Trigger the conflict check
		_tween2.__started = true;
		_tween2.__cancel_conflicting();
		
		var _passed = _tween1.__destroyed && !_tween2.__destroyed;
		
		if (_log_test("Unique mode cancels conflict", _passed, $"tween1_destroyed={_tween1.__destroyed}, tween2_active={!_tween2.__destroyed}"))
			_tests_passed++;
		else
			_tests_failed++;
		
		_tween2.cancel();
	}
	
	// ===== TEST 10: mini_tween_count and cancel_all =====
	show_debug_message("\n--- Test 10: Count and Cancel All ---");
	{
		mini_tween_cancel_all();
		var _targets = [];
		
		// Create multiple tweens
		for (var _i = 0; _i < 10; _i++)
		{
			var _t = { x: 0 };
			array_push(_targets, _t);
			mini_tween(_t, 1.0).tween("x", 100);
		}
		
		var _count_before = mini_tween_count();
		mini_tween_cancel_all();
		var _count_after = mini_tween_count();
		
		var _passed = (_count_before == 10) && (_count_after == 0);
		
		if (_log_test("Count and cancel_all", _passed, $"before={_count_before}, after={_count_after}"))
			_tests_passed++;
		else
			_tests_failed++;
	}
	
	// ===== TEST 11: mini_tween_cancel_target =====
	show_debug_message("\n--- Test 11: Cancel Target ---");
	{
		mini_tween_cancel_all();
		var _target1 = { x: 0 };
		var _target2 = { x: 0 };
		
		mini_tween(_target1, 1.0).tween("x", 100);
		mini_tween(_target1, 1.0).tween("x", 200);  // Same target
		mini_tween(_target2, 1.0).tween("x", 100);  // Different target
		
		var _count_before = mini_tween_count();
		mini_tween_cancel_target(_target1);
		
		// Process to remove cancelled tweens
		__mini_tween_process();
		
		var _count_after = mini_tween_count();
		
		var _passed = (_count_before == 3) && (_count_after == 1);
		
		if (_log_test("Cancel target", _passed, $"before={_count_before}, after={_count_after}"))
			_tests_passed++;
		else
			_tests_failed++;
		
		mini_tween_cancel_all();
	}
	
	// ===== TEST 12: Weak Reference (Struct Cleanup) =====
	show_debug_message("\n--- Test 12: Weak Reference Handling ---");
	{
		mini_tween_cancel_all();
		
		// Create a struct in local scope
		var _temp_target = { x: 0, y: 0 };
		var _tween = mini_tween(_temp_target, 1.0).tween("x", 100);
		
		// Verify weak ref was created for struct
		var _is_weak = _tween.__is_struct;
		var _target_alive = weak_ref_alive(_tween.__target);
		
		var _passed = _is_weak && _target_alive;
		
		if (_log_test("Weak reference for struct", _passed, $"is_struct={_is_weak}, alive={_target_alive}"))
			_tests_passed++;
		else
			_tests_failed++;
		
		_tween.cancel();
	}
	
	// ===== TEST 13: Pause/Resume All =====
	show_debug_message("\n--- Test 13: Pause/Resume All ---");
	{
		mini_tween_cancel_all();
		
		var _t1 = { x: 0 };
		var _t2 = { x: 0 };
		var _t3 = { x: 0 };
		
		var _tw1 = mini_tween(_t1, 1.0).tween("x", 100);
		var _tw2 = mini_tween(_t2, 1.0).tween("x", 100);
		var _tw3 = mini_tween(_t3, 1.0).tween("x", 100);
		
		mini_tween_pause_all();
		var _all_paused = _tw1.__paused && _tw2.__paused && _tw3.__paused;
		
		mini_tween_resume_all();
		var _all_resumed = !_tw1.__paused && !_tw2.__paused && !_tw3.__paused;
		
		var _passed = _all_paused && _all_resumed;
		
		if (_log_test("Pause/Resume all", _passed, $"all_paused={_all_paused}, all_resumed={_all_resumed}"))
			_tests_passed++;
		else
			_tests_failed++;
		
		mini_tween_cancel_all();
	}
	
	// ===== TEST 14: Chaining API =====
	show_debug_message("\n--- Test 14: Chaining API ---");
	{
		mini_tween_cancel_all();
		var _target = { x: 0, y: 0, scale: 1 };
		var _dummy = function() {};
		
		// Test that all methods return self for chaining
		var _tween = mini_tween(_target, 1.0)
			.tween("x", 100)
			.tween("y", 200)
			.tween("scale", 2)
			.delay(0.5)
			.repeat(2, true)
			.on_start(_dummy)
			.on_complete(_dummy)
			.on_repeat(_dummy)
			.on_cancel(_dummy)
			.pause()
			.resume();
		
		var _passed = (_tween != undefined);
		_passed = _passed && (array_length(_tween.__properties) == 3);
		_passed = _passed && (_tween.__delay == 0.5);
		_passed = _passed && (_tween.__repeat_count == 2);
		_passed = _passed && (_tween.__yoyo == true);
		
		if (_log_test("Chaining API", _passed))
			_tests_passed++;
		else
			_tests_failed++;
		
		_tween.cancel();
	}
	
	// ===== SUMMARY =====
	show_debug_message("\n========== MINITWEEN V2 TEST RESULTS ==========");
	show_debug_message($"  Tests Passed: {_tests_passed}");
	show_debug_message($"  Tests Failed: {_tests_failed}");
	show_debug_message($"  Total:        {_tests_passed + _tests_failed}");
	show_debug_message($"  Success Rate: {(_tests_passed / (_tests_passed + _tests_failed)) * 100}%");
	show_debug_message("==============================================\n");
	
	// Cleanup
	mini_tween_cancel_all();
	
	return _tests_failed == 0;
}

/// @function		benchmark_mini_tween_v2()
/// @description	Performance benchmark for MiniTween v2
function benchmark_mini_tween_v2()
{
	show_debug_message("\n========== MINITWEEN V2 PERFORMANCE BENCHMARK ==========");
	
	var _iterations = 1000;
	var _t_start, _t_end;
	
	// ===== TEST 1: Tween Creation =====
	mini_tween_cancel_all();
	var _targets = [];
	for (var _i = 0; _i < _iterations; _i++)
	{
		array_push(_targets, { x: 0, y: 0, alpha: 1 });
	}
	
	_t_start = get_timer();
	
	for (var _i = 0; _i < _iterations; _i++)
	{
		mini_tween(_targets[_i], 1.0)
			.tween("x", 100)
			.tween("y", 200)
			.tween("alpha", 0);
	}
	
	var _t_create = (get_timer() - _t_start) / 1000;
	show_debug_message($"[CREATE] {_iterations} tweens (3 props each) in {_t_create}ms ({_iterations / _t_create * 1000} tweens/sec)");
	
	// ===== TEST 2: Process Step (all tweens) =====
	var _process_iterations = 100;
	
	_t_start = get_timer();
	
	for (var _i = 0; _i < _process_iterations; _i++)
	{
		__mini_tween_process();
	}
	
	var _t_process = (get_timer() - _t_start) / 1000;
	var _total_ops = _process_iterations * _iterations;
	show_debug_message($"[PROCESS] {_total_ops} tween updates in {_t_process}ms ({_total_ops / _t_process * 1000} updates/sec)");
	
	// ===== TEST 3: Cancel All =====
	_t_start = get_timer();
	
	mini_tween_cancel_all();
	
	var _t_cancel_all = (get_timer() - _t_start) / 1000;
	show_debug_message($"[CANCEL ALL] {_iterations} tweens cancelled in {_t_cancel_all}ms");
	
	// ===== TEST 4: Cancel Target =====
	// Recreate tweens with grouped targets
	var _num_targets = 100;
	var _tweens_per_target = 10;
	var _grouped_targets = [];
	
	for (var _i = 0; _i < _num_targets; _i++)
	{
		var _target = { x: 0, y: 0 };
		array_push(_grouped_targets, _target);
		
		for (var _j = 0; _j < _tweens_per_target; _j++)
		{
			mini_tween(_target, 1.0).tween("x", random(100));
		}
	}
	
	_t_start = get_timer();
	
	for (var _i = 0; _i < _num_targets; _i++)
	{
		mini_tween_cancel_target(_grouped_targets[_i]);
	}
	
	var _t_cancel_target = (get_timer() - _t_start) / 1000;
	show_debug_message($"[CANCEL TARGET] {_num_targets} targets ({_num_targets * _tweens_per_target} tweens) in {_t_cancel_target}ms");
	
	// ===== TEST 5: Shortcut Functions =====
	mini_tween_cancel_all();
	
	_t_start = get_timer();
	
	for (var _i = 0; _i < _iterations; _i++)
	{
		mini_tween_to(_targets[_i], 0.5, { x: 100, y: 200, alpha: 0.5 });
	}
	
	var _t_shortcut = (get_timer() - _t_start) / 1000;
	show_debug_message($"[SHORTCUT] {_iterations} mini_tween_to calls in {_t_shortcut}ms ({_iterations / _t_shortcut * 1000} calls/sec)");
	
	// ===== TEST 6: Memory - Array Compaction =====
	// Test that cancelled tweens are properly removed
	var _count_before = mini_tween_count();
	
	// Cancel half the tweens
	for (var _i = 0; _i < _iterations; _i += 2)
	{
		global.__mini_tweens[_i].cancel();
	}
	
	_t_start = get_timer();
	__mini_tween_process();  // Should compact array
	var _t_compact = (get_timer() - _t_start) / 1000;
	
	var _count_after = mini_tween_count();
	show_debug_message($"[COMPACT] Array compaction: {_count_before} -> {_count_after} in {_t_compact}ms");
	
	// ===== SUMMARY =====
	show_debug_message("\n========== BENCHMARK SUMMARY ==========");
	show_debug_message($"Create:        {_t_create}ms ({_iterations} tweens)");
	show_debug_message($"Process:       {_t_process}ms ({_total_ops} updates)");
	show_debug_message($"Cancel All:    {_t_cancel_all}ms");
	show_debug_message($"Cancel Target: {_t_cancel_target}ms");
	show_debug_message($"Shortcut:      {_t_shortcut}ms");
	show_debug_message($"Compact:       {_t_compact}ms");
	show_debug_message("========================================\n");
	
	// Cleanup
	mini_tween_cancel_all();
}

/// @function		demo_mini_tween_v2()
/// @description	Visual demo of MiniTween v2 capabilities
function demo_mini_tween_v2()
{
	show_debug_message("\n--- Starting MiniTween v2 Visual Demo ---");
	
	// Create demo targets (these will be drawn in Draw event)
	global.tween_demo_targets = [];
	
	var _colors = [c_red, c_orange, c_yellow, c_lime, c_aqua, c_blue, c_fuchsia, c_white];
	var _start_y = 100;
	var _spacing = 40;
	
	for (var _i = 0; _i < 8; _i++)
	{
		var _target = {
			x: 50,
			y: _start_y + (_i * _spacing),
			scale: 1,
			alpha: 1,
			color: _colors[_i],
			rotation: 0
		};
		array_push(global.tween_demo_targets, _target);
	}
	
	// Demo 1: Basic move
	mini_tween(global.tween_demo_targets[0], 2.0)
		.tween("x", 500)
		.on_complete(function() { show_debug_message("Demo 1: Move complete"); });
	
	// Demo 2: Move with delay
	mini_tween(global.tween_demo_targets[1], 2.0)
		.tween("x", 500)
		.delay(0.5);
	
	// Demo 3: Move with ease out
	mini_tween(global.tween_demo_targets[2], 2.0)
		.tween("x", 500, EASING_CURVES.QUART_OUT);
	
	// Demo 4: Move with ease in
	mini_tween(global.tween_demo_targets[3], 2.0)
		.tween("x", 500, EASING_CURVES.QUART_IN);
	
	// Demo 5: Move with bounce
	mini_tween(global.tween_demo_targets[4], 2.0)
		.tween("x", 500, EASING_CURVES.BOUNCE_OUT);
	
	// Demo 6: Move with elastic
	mini_tween(global.tween_demo_targets[5], 2.0)
		.tween("x", 500, EASING_CURVES.ELASTIC_OUT);
	
	// Demo 7: Repeat (no yoyo)
	mini_tween(global.tween_demo_targets[6], 0.5)
		.tween("x", 500)
		.repeat(3, false);
	
	// Demo 8: Repeat with yoyo (infinite)
	mini_tween(global.tween_demo_targets[7], 1.0)
		.tween("x", 500)
		.repeat(-1, true);
	
	show_debug_message("Demo started! Watch the circles move with different easings.");
	show_debug_message("Press F5 to cancel demo, F6 to restart.");
}

// Store demo state
global.tween_demo_targets = [];
global.tween_demo_active = false;

#endregion

#region MiniTween v2 Visual Stress Test

/// @function		stress_test_mini_tween_v2(_count)
/// @description	Visual stress test - creates many tweening objects on screen
/// @param {Real} _count	Number of objects to create (default 500)
function stress_test_mini_tween_v2(_count = 500)
{
	show_debug_message($"\n========== MINITWEEN V2 STRESS TEST ({_count} objects) ==========");
	
	// Cancel any existing tweens
	mini_tween_cancel_all();
	
	// Initialize stress test state
	global.stress_test_active = true;
	global.stress_test_objects = [];
	global.stress_test_count = _count;
	global.stress_test_completed = 0;
	global.stress_test_start_time = get_timer();
	global.stress_test_fps_samples = [];
	global.stress_test_fps_min = 9999;
	global.stress_test_fps_max = 0;
	
	// Colors for variety
	var _colors = [c_red, c_orange, c_yellow, c_lime, c_aqua, c_blue, c_fuchsia, c_white, c_silver, c_maroon, c_green, c_navy, c_teal, c_purple, c_olive];
	
	// Create objects spread across the screen
	var _margin = 30;
	var _area_w = room_width - (_margin * 2);
	var _area_h = room_height - (_margin * 2) - 80; // Leave space for UI
	
	for (var _i = 0; _i < _count; _i++)
	{
		// Random starting position
		var _start_x = _margin + random(_area_w);
		var _start_y = _margin + 60 + random(_area_h); // Offset for header
		
		// Random target position
		var _end_x = _margin + random(_area_w);
		var _end_y = _margin + 60 + random(_area_h);
		
		// Create object
		var _obj = {
			x: _start_x,
			y: _start_y,
			start_x: _start_x,
			start_y: _start_y,
			end_x: _end_x,
			end_y: _end_y,
			scale: 0.5 + random(1.0),
			alpha: 0.5 + random(0.5),
			rotation: random(360),
			color: _colors[_i mod array_length(_colors)],
			size: 3 + irandom(5)
		};
		
		array_push(global.stress_test_objects, _obj);
		
		// Random duration between 1-4 seconds
		var _duration = 1.0 + random(3.0);
		
		// Random easing
		var _easings = [
			EASING_CURVES.LINEAR,
			EASING_CURVES.SINE_IN_OUT,
			EASING_CURVES.QUART_OUT,
			EASING_CURVES.CUBIC_OUT,
			EASING_CURVES.QUART_OUT,
			EASING_CURVES.BACK_OUT,
			EASING_CURVES.ELASTIC_OUT
		];
		var _easing = _easings[irandom(array_length(_easings) - 1)];
		
		// Create tween with infinite yoyo
		mini_tween(_obj, _duration)
			.tween("x", _end_x, _easing)
			.tween("y", _end_y, _easing)
			.tween("rotation", _obj.rotation + 360, EASING_CURVES.LINEAR)
			.delay(random(0.5))
			.repeat(-1, true);  // Infinite yoyo
	}
	
	show_debug_message($"Created {_count} objects with infinite tweens");
	show_debug_message("Press F5 to stop, +/- to add/remove 100 objects");
}

/// @function		stress_test_add_objects(_count)
/// @description	Add more objects to the stress test
function stress_test_add_objects(_count = 100)
{
	if (!global.stress_test_active) return;
	
	var _colors = [c_red, c_orange, c_yellow, c_lime, c_aqua, c_blue, c_fuchsia, c_white];
	var _margin = 30;
	var _area_w = room_width - (_margin * 2);
	var _area_h = room_height - (_margin * 2) - 80;
	
	for (var _i = 0; _i < _count; _i++)
	{
		var _start_x = _margin + random(_area_w);
		var _start_y = _margin + 60 + random(_area_h);
		var _end_x = _margin + random(_area_w);
		var _end_y = _margin + 60 + random(_area_h);
		
		var _obj = {
			x: _start_x,
			y: _start_y,
			start_x: _start_x,
			start_y: _start_y,
			end_x: _end_x,
			end_y: _end_y,
			scale: 0.5 + random(1.0),
			alpha: 0.5 + random(0.5),
			rotation: random(360),
			color: _colors[_i mod array_length(_colors)],
			size: 3 + irandom(5)
		};
		
		array_push(global.stress_test_objects, _obj);
		
		var _duration = 1.0 + random(3.0);
		
		mini_tween(_obj, _duration)
			.tween("x", _end_x, EASING_CURVES.SINE_IN_OUT)
			.tween("y", _end_y, EASING_CURVES.SINE_IN_OUT)
			.tween("rotation", _obj.rotation + 360, EASING_CURVES.LINEAR)
			.repeat(-1, true);
	}
	
	global.stress_test_count = array_length(global.stress_test_objects);
	show_debug_message($"Added {_count} objects. Total: {global.stress_test_count}");
}

/// @function		stress_test_remove_objects(_count)
/// @description	Remove objects from the stress test
function stress_test_remove_objects(_count = 100)
{
	if (!global.stress_test_active) return;
	
	var _to_remove = min(_count, array_length(global.stress_test_objects));
	
	for (var _i = 0; _i < _to_remove; _i++)
	{
		var _obj = array_pop(global.stress_test_objects);
		mini_tween_cancel_target(_obj);
	}
	
	global.stress_test_count = array_length(global.stress_test_objects);
	show_debug_message($"Removed {_to_remove} objects. Total: {global.stress_test_count}");
}

/// @function		stress_test_stop()
/// @description	Stop the stress test and show results
function stress_test_stop()
{
	if (!global.stress_test_active) return;
	
	var _duration = (get_timer() - global.stress_test_start_time) / 1000000;
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
	
	show_debug_message("\n========== STRESS TEST RESULTS ==========");
	show_debug_message($"Objects:     {global.stress_test_count}");
	show_debug_message($"Duration:    {_duration}s");
	show_debug_message($"Avg FPS:     {_avg_fps}");
	show_debug_message($"Min FPS:     {global.stress_test_fps_min}");
	show_debug_message($"Max FPS:     {global.stress_test_fps_max}");
	show_debug_message("==========================================\n");
	
	mini_tween_cancel_all();
	global.stress_test_active = false;
	global.stress_test_objects = [];
}

// Initialize stress test state
global.stress_test_active = false;
global.stress_test_objects = [];
global.stress_test_count = 0;
global.stress_test_completed = 0;
global.stress_test_start_time = 0;
global.stress_test_fps_samples = [];
global.stress_test_fps_min = 9999;
global.stress_test_fps_max = 0;

#endregion
