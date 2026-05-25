///@function				MiniNodeProcessor(_owner)
///@description				Simplified processor with lifecycle events and process management
function MiniNodeProcessor(_owner = noone) constructor
{
	owner = _owner;
	
	#region Lifecycle
	
	on_init = new MiniEvent();			// First initialization
	on_post_init = new MiniEvent();		// After initialization is completed
	
	is_initialized = false;				// Init has run
	
	#endregion
	
	#region Process Storage
	
	// Permanent processes - run every frame
	__processes = [];
	__processes_length = 0;
	
	// Temporary processes
	__temp_processes = [];
    __temp_processes_length = 0;

	#endregion
	
	#region Process Management
	
	///@function			add_process(_process, _temp, _priority, _make_method)
	///@description			Add a process function that runs every frame
	///@param {Function} _process		Function to run (receives no args if bound to owner)
	///@param {Bool} [_temp]			If true, process auto-removes when it returns true (default false)
	///@param {Real} [_priority]		Higher priority runs first (default 0)
	///@param {Bool} [_make_method]		If true, binds function to owner as method (default true)
	///@returns {Struct.MiniNodeProcessor}	Self for chaining
	static add_process = function(_process, _temp = false, _priority = 0, _make_method = true)
	{
		if (!is_callable(_process))
		{
			show_error("add_process: _process must be a callable function", true);
			return self;
		}
		
		var _func = _make_method ? method(owner, _process) : _process;
		var _entry = { func: _func, raw: _process, priority: _priority };
		
		if (_temp) 
        {
            __temp_processes = __insert_process_on_priority(__temp_processes, _entry, _priority);
            __temp_processes_length = array_length(__temp_processes);
        }
        else 
        {
            __processes = __insert_process_on_priority(__processes, _entry, _priority);
            __processes_length = array_length(__processes);
        }
		
		return self;
	}
    
	/// @function				__insert_process_on_priority(_array, _entry, _priority)
	/// @description			Insert a process entry sorted by priority (descending)
	/// @param {Array} _array	The process array to insert into
	/// @param {Struct} _entry	The entry struct containing {func, priority}
	/// @param {Real} _priority	The priority value for sorting
    static __insert_process_on_priority = function(_process_array, _entry, _priority)
    {
        // Insert sorted by priority (descending - higher priority first)
		var _inserted = false;
		var _len = array_length(_process_array);
		for (var _i = 0; _i < _len; _i++)
		{
			if (_process_array[_i].priority < _priority)
			{
				array_insert(_process_array, _i, _entry);
				_inserted = true;
				break;
			}
		}
		if (!_inserted) array_push(_process_array, _entry);
            
        return _process_array;
    }
    
	///@function					remove_process(_process)
	///@description					Remove a permanent process by function reference
	///@param {Function} _process	The process function to remove
	///@returns {Struct.MiniNodeProcessor} Self for chaining
	static remove_process = function(_process)
	{
		for (var _i = __processes_length - 1; _i >= 0; _i--)
		{
			if (__processes[_i].raw == _process || __processes[_i].func == _process)
			{
				array_delete(__processes, _i, 1);
				__processes_length--;
				break;
			}
		}
		return self;
	}
	
	#endregion
	
	#region System
	
	///@function			__step_processor()
	///@description			Main processing loop - called every frame by parent or NodeManager
	///						Handles: initialization, transform resolution, process execution, child recursion
	static __step_processor = function()
	{
		// Skip processing if node is disabled
        if (!owner.is_enabled() && is_initialized) return;
		
		// First frame: run init event
		if (!is_initialized)
		{
			is_initialized = true;
			on_init.invoke();
			
			call_later(1, time_source_units_frames, method(on_post_init, on_post_init.invoke));
			if (owner.is_enabled()) call_later(2, time_source_units_frames, method(owner.on_enabled, owner.on_enabled.invoke));
		}
		
        // Resolve any pending transform changes (deferred update pattern)
        owner.__resolve_transform();
                
        
        // Run permanent processes (highest priority first)
        for (var _i = 0; _i < __processes_length; _i++)
        {
            __processes[_i].func();
        }
        
        // Run temporary processes (iterate backwards for safe removal)
        for (var _i = __temp_processes_length - 1; _i >= 0; _i--)
        {
            var _temp = __temp_processes[_i];
            var _complete = _temp.func();
            
            // Remove if process signals completion (returns true)
            if (_complete)
            {
                array_delete(__temp_processes, _i, 1);
                __temp_processes_length--;
            }
        }
        
		// Recursively process all children
		var _children = owner.__nested_nodes;
		var _children_len = array_length(_children);
		for (var _i = 0; _i < _children_len; _i++)
		{
			_children[_i].processor.__step_processor();
		}
	}
    
	#endregion
}