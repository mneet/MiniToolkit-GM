function __node_animator() constructor
{
	owner = noone;
	motion_state = NODE_MOTION_STATE.ENTER;
	complete_state_function = noone;
	motion_state_set = false;
	
	restart_anim = false;
	
	ac_enter = new __node_animator_ac_control(EASING_CURVES.LINEAR);
	ac_leave = new __node_animator_ac_control(EASING_CURVES.LINEAR);
	ac_idle = new __node_animator_ac_control(EASING_CURVES.LINEAR);
	ac_out = new __node_animator_ac_control(EASING_CURVES.LINEAR);
	ac_restart = new __node_animator_ac_control(EASING_CURVES.LINEAR);
	
	event_state = [];
	
	#region STATE MACHINE
	
	///@function		state_machine_brain(_node)
	///@description		State machine controller
	static state_machine_brain = function(_node)
	{	
		var _animator = _node.animator;		
		_animator.state_trigger(_node, _animator);
		
		switch (_animator.motion_state)
		{
			case NODE_MOTION_STATE.ENTER:
				_animator.state_motion_enter(_node, _animator.ac_enter);
				break;
			
			case NODE_MOTION_STATE.IDLE:
				_animator.state_motion_idle(_node, _animator.ac_idle);
				break;
			
			case NODE_MOTION_STATE.LEAVE:
				_animator.state_motion_leave(_node, _animator.ac_leave);
				break;
			
			case NODE_MOTION_STATE.OUT:
				_animator.state_motion_out(_node, _animator.ac_out);
				break;
				
			case NODE_MOTION_STATE.RESTART:
				_animator.state_motion_restart(_node, _animator.ac_restart);
				break;
		}
	}
	
	///@function		state_motion_enter(_node)
	///@description		State behaviour when enter
	state_motion_enter = function(_node, _animator)
	{
		if (!motion_state_set)
		{
			motion_state_set = true;		
			call_function_when_complete();
			animator_change_state(NODE_MOTION_STATE.IDLE);
		}
	}
	
	///@function		state_motion_idle(_node)
	///@description		State behaviour when idle
	state_motion_idle = function(_node, _animator)
	{
		
	}
	
	///@function		state_motion_leave(_node)
	///@description		State behaviour when leave
	state_motion_leave = function(_node, _animator)
	{
		if (!motion_state_set)
		{			
			motion_state_set = true;
			call_function_when_complete();			
			if (!restart_anim)
			{
				animator_change_state(NODE_MOTION_STATE.OUT);
			}
			else 
			{
				owner.update();
				animator_change_state(NODE_MOTION_STATE.ENTER);
			}
		}
	}
	
	///@function		state_motion_restart(_node)
	///@description		State behaviour when restart
	state_motion_restart = function(_node, _animator)
	{
		if (!motion_state_set)
		{			
			motion_state_set = true;
			call_function_when_complete();	
			restart_anim = true;
			animator_change_state(NODE_MOTION_STATE.LEAVE);
		}
	}
	
	///@function		state_motion_out(_node)
	///@description		State behaviour when out
	state_motion_out = function(_node, _animator)
	{		
		if (!motion_state_set)
		{		
			//_node.__skip_render = true;
			motion_state_set = true;				
			call_function_when_complete();
		}
	}
	
	///@function		state_trigger(_node)
	///@description		Trigger states absed on custom events
	state_trigger = function(_node, _animator)
	{
			
	}
	
	///@function		animator_change_state(_node)
	///@description		Change state machine state and call a function at end
	animator_change_state = function(_state, _execute_at_end = noone)
	{
		if (_state != motion_state)
		{
			motion_state = _state;
			motion_state_set = false;
			owner.__skip_render = false;
		
			complete_state_function = _execute_at_end;
			
			__animator_execute_events(_state);
		
			switch (motion_state)
			{
				case NODE_MOTION_STATE.ENTER:
					ac_enter.reset_control();
					break;
			
				case NODE_MOTION_STATE.IDLE:
					ac_idle.reset_control();
					break;
			
				case NODE_MOTION_STATE.LEAVE:
					ac_leave.reset_control();
					break;
			
				case NODE_MOTION_STATE.OUT:
					ac_out.reset_control();
					break;
				
				case NODE_MOTION_STATE.RESTART:
					ac_restart.reset_control();
					break;
			}
			
		}
		return self;
	}
	
	///@function		call_function_when_complete()
	///@description		Call at end function
	call_function_when_complete = function()
	{
		if (complete_state_function != noone)
		{
			complete_state_function();
			complete_state_function = noone;
		}
	}
		
	#endregion	
		
	#region UTILITY
	
	///@function		set_state_motion(_state, _function)
	///@description		Set the behavious for a given state
	static set_state_motion = function (_state, _function)
	{
		switch (_state)
		{
			case NODE_MOTION_STATE.ENTER: state_motion_enter = _function; break;	
			case NODE_MOTION_STATE.IDLE: state_motion_idle = _function; break;	
			case NODE_MOTION_STATE.LEAVE: state_motion_leave = _function; break;	
			case NODE_MOTION_STATE.OUT: state_motion_out = _function; break;	
		}
		return self;
	}
	
	///@function		set_state_trigger(_function)
	///@description		Set the trigger for new states
	static set_state_trigger = function(_function)
	{
		state_trigger = _function;
		return self;
	}
	
	///@function		set_default_anim_scale(_state, _curve, _value_to, _timer_max, _delay)
	static set_default_anim_scale = function(_state, _curve, _value_to, _timer_max = 0.3, _delay = 0)
	{
		var _controller =  new __node_animator_ac_control(_curve, _timer_max, _delay);
		
		// Calculando valores para função de Easing
		_controller.value_to = _value_to;

		// Define animação padrão de escala
		set_state_motion(_state, global.node_animator_db.simple_scale_animation);
		
		switch (_state)
		{
			case NODE_MOTION_STATE.ENTER:
				ac_enter = variable_clone(_controller);			
				break;
			case NODE_MOTION_STATE.LEAVE:
				ac_leave = variable_clone(_controller);
				break;	
			case NODE_MOTION_STATE.IDLE:
				ac_idle = variable_clone(_controller);
				break;	
		}	
	}
	
	///@function		motion_state_compare(_state)
	///@description		Compare the active state
	static motion_state_compare = function(_state)
	{
		return motion_state == _state;	
	}
	
	#endregion
		
	#region EVENT
	
	for (var _i = 0; _i < NODE_MOTION_STATE.LENGTH;	_i++)
	{
		event_state[_i] = [];
	}
	
	///@function		animator_bind_event(_state, _event_funct)
	///@description		Bind an function to run every time an state starts
	static animator_bind_event = function(_state, _event_funct)
	{
		array_push(event_state[_state], _event_funct);
		return self;
	}
	
	///@function		__animator_execute_events(_state)
	///@description		Execute state event functions
	static __animator_execute_events = function(_state)
	{
		for (var _i = 0; _i < array_length(event_state[_state]); _i++)
		{
			var _event = event_state[_state][_i];
			if (is_callable(_event)) _event(owner);
		}
	}
	
	#endregion
}

function __node_animator_ac_control(_curve, _timer_max = .3, _start_delay = 0) constructor
{
	curve = _curve;
	
	timer_max = _timer_max;
	timer = 0;
	
	value_start = 0;
	value_to = 0;
	value_diff = 0;
	
	timer_delay_max = _start_delay;
	timer_delay = _start_delay;
	
	animation_completed = false;
	value_calculated  = false;
	
	reset_control = function()
	{
		value_start = 0;
		value_diff = 0;
		
		animation_completed = false;
		value_calculated  = false;
		
		timer_delay = timer_delay_max;
		timer = 0;
	}	
}

global.node_animator_db = {};
with (global.node_animator_db)
{	
	simple_scale_animation = function(_node, _event_ctrl)
	{		
		// Checa se a animação já completou
		if (!_event_ctrl.animation_completed)
		{
			// Calcula valores no inicio da animação
			if (!_event_ctrl.value_calculated)
			{
				// Valor inicial no momento que a animação começou
				_event_ctrl.value_start = variable_clone(_node.transform.scale.x);
				
				// Calculando a diferença do valor para o desejado 
				_event_ctrl.value_diff = _event_ctrl.value_to - _event_ctrl.value_start;
				
				
				_event_ctrl.value_calculated = true;
			}
			
			var _animator = _node.animator;
			var _easing_func = global.easing_functions[_event_ctrl.curve];
		
			// Timer da animação
			_event_ctrl.timer += delta_time_seconds();
		
			// Utilizando função de Easing do script PennersEasingAlgorithms
			var _scale_target = _easing_func(_event_ctrl.timer, _event_ctrl.value_start, _event_ctrl.value_diff, _event_ctrl.timer_max);	
			
			// Aplicando escala no node
			_node.transform.scale.x = _scale_target;
			_node.transform.scale.y = _scale_target;
			
			// Atualizando transform dos nodes aninhados
			_node.update_nested_transform();
					
			// Checando fim da animação
			if (_event_ctrl.timer >= _event_ctrl.timer_max)
			{
				_event_ctrl.animation_completed = true;	
				_animator.call_function_when_complete();
				
				if (_animator.motion_state_compare(NODE_MOTION_STATE.LEAVE))
				{
					_animator.animator_change_state(NODE_MOTION_STATE.OUT);	
				}
			}
		}

	}
}