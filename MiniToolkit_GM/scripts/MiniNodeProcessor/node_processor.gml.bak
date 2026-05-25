function __node_processor() constructor
{
	owner = noone;		
	constant_processes = [];
	constant_processes_amnt = 0;
	constant_process = false;
	
	active_processes = [];
	active_processes_amnt = 0;
	active_process = false;
	
	step_processor = function()
	{
		if (constant_process)
		{
			for (var _i = 0; _i < constant_processes_amnt; _i++)
			{
				var _function = constant_processes[_i];
				_function(owner);	
			}
		}
		
		if (active_process && owner.node_active)
		{
			for (var _i = 0; _i < active_processes_amnt; _i++)
			{
				var _function = active_processes[_i];
				_function(owner);	
			}
		}
		
		for (var _i = 0; _i < owner.nested_nodes_amnt; _i++)
		{
			var _node = owner.nested_nodes[_i];
			if (_node.processor != noone) _node.processor.step_processor();
		}
	}
	
	static add_process = function(_process, _constant = true)
	{
		if (_constant)
		{
			array_push(constant_processes, _process);
			constant_process = true;
			constant_processes_amnt = array_length(constant_processes);
		}
		else
		{
			array_push(active_processes, _process);
			active_process = true;
			active_processes_amnt = array_length(active_processes);
		}
	}
}