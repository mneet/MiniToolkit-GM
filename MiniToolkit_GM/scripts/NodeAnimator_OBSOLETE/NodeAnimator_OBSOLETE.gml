#region Structs


function delta_time_seconds()
{
	return 1 / game_get_speed(gamespeed_fps);
}

///@function								NodeAnimationController(_node, _attribute_name, _target_value, _duration, _easing, _delay, _value_at_start, _callback)
///@description								Animation helper struct for interpolating node transform attributes
///@param {Struct.MiniNode} _node				The node to animate
///@param {String} _attribute_name			Transform attribute to animate (e.g., "x", "image_alpha")
///@param {Real} _target_value				Target value to animate towards
///@param {Real} _duration					Animation duration in seconds
///@param {Function} [_easing]	             Easing curve from PennersEasingAlgorithms script (default EaseInOutSine)
///@param {Real} [_delay]					Delay in seconds before animation starts (default 0)
///@param {Real} [_value_at_start]			Optional starting value override
///@param {Function} [_callback]			Optional callback function to call when animation completes
function NodeAnimationController(_node, _attribute_name, _target_value, _duration, _easing = EaseInOutSine, _delay = 0, _value_at_start = undefined, _callback = undefined) constructor
{
	id = 0;
	node = _node;

	attribute_name = _attribute_name;

	start_value = 0;
	value_at_start = _value_at_start;
	target_value = _target_value;
	value_diff = _target_value;
	
	duration = _duration;
	easing = _easing;
	timer = 0;
    delay_max = _delay;
    delay = _delay;

	callback = _callback;
	
	completed = false;
	__is_initialized = false; // Track if animation has been set up
	
	///@function		update()
	///@description		Update animation progress - returns true when complete (for temp process system)
	///@returns {Bool}	True if animation completed, false if still running
	static update = function()
	{
		if (!__is_initialized) reset();
		
		if (completed) return true;
		
        if (delay > 0)
        {
            delay -= delta_time_seconds();
            return false;
        }
        
		timer += delta_time_seconds();
		
		if (timer >= duration)
		{
			completed = true;
			node.transform_set_attribute(attribute_name, target_value);
			if (callback != undefined) callback();
			return true;
		}
		var _value = script_execute_ext(easing, [timer, start_value, value_diff, duration]);
		node.transform_set_attribute(attribute_name, _value);

		return false;
	}

	///@function		reset()
	///@description		Reset animation to beginning, capturing current value as start
	static reset = function()
	{
		if (value_at_start != undefined)
		{
			node.transform_set_attribute(attribute_name, value_at_start);
		}

        delay = delay_max;
		timer = 0;
		completed = false;
		
		start_value = node.local_transform[$ attribute_name];
		value_diff = target_value - start_value;
		__is_initialized = true;
	}
	
	///@function		generate_id()
	///@description		Generate unique ID for this animation controller
	///@returns {String} Unique identifier string
	static generate_id = function(_id_appendix = "")
	{
		id = $"animator_{attribute_name}_{_id_appendix}";
		return id;
	}
}

#endregion

#region ANIMATION HELPER FUNCTIONS

///@function								node_animate_on_event(_node, _trigger_event, _attribute_name, _value_to, _duration, _easing, _delay, _value_at_start, _callback)
///@description								Create an animation that plays when an event fires (one-shot, event-driven)
///@param {Struct.MiniNode} _node				The node to animate
///@param {Struct.MiniEvent} _trigger_event	Event that triggers the animation
///@param {String} _attribute_name			The transform attribute to animate (e.g., "image_alpha", "x")
///@param {Real} _value_to					Target value
///@param {Real} [_duration]				Duration in seconds (default 0.3)
///@param {Function} [_easing]	             Easing curve from PennersEasingAlgorithms script (default EaseInOutSine)
///@param {Real} [_delay]					Delay in seconds before animation starts (default 0)
///@param {Real} [_value_at_start]			Optional starting value override
///@param {Function} [_callback]			Optional callback function to call when animation completes
///@returns {Undefined}
function node_animate_on_event(_node, _trigger_event, _attribute_name, _value_to, _duration = 0.3, _easing = EaseInOutSine, _delay = 0, _value_at_start = undefined, _callback = undefined)
{
	var _controller = new NodeAnimationController(_node, _attribute_name, _value_to, _duration, _easing, _delay, _value_at_start, _callback);
	var _controller_id = _controller.generate_id(ptr(_trigger_event));
	_node.processor[$ _controller_id] = _controller;
	
	// When event fires, reset and start transition manually
	_trigger_event.connect(_controller, function() {
		reset();
        node.processor.add_process(method(self, update), true, 0, false);
		show_debug_message($"Animating node {node.id}");
	});
}

///@function								node_animate(_node, _attribute_name, _value_to, _duration, _easing, _delay, _value_at_start, _callback)
///@description								Immediately start an animation on the given node
///@param {Struct.MiniNode} _node				The node to animate
///@param {String} _attribute_name			The transform attribute to animate (e.g., "image_alpha", "x")
///@param {Real} _value_to					Target value
///@param {Real} [_duration]				Duration in seconds (default 0.3)
///@param {Function} [_easing]	             Easing curve from PennersEasingAlgorithms script (default EaseInOutSine)
///@param {Real} [_delay]					Delay in seconds before animation starts (default 0)
///@param {Real} [_value_at_start]			Optional starting value override
///@param {Function} [_callback]			Optional callback function to call when animation completes
///@returns {Undefined}
function node_animate(_node, _attribute_name, _value_to, _duration = 0.3, _easing = EaseInOutSine, _delay = 0, _value_at_start = undefined, _callback = undefined)
{
	var _controller = new NodeAnimationController(_node, _attribute_name, _value_to, _duration, _easing, _delay, _value_at_start, _callback);
	var _controller_id = _controller.generate_id();
	_node.processor[$ _controller_id] = _controller;
	
	// Fire animation
    _node.processor.add_process(method(_controller, _controller.update), true, 0, false);
}


#endregion