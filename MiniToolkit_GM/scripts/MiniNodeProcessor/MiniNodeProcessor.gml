///@function				MiniNodeProcessor(_owner)
///@description				Simplified processor with lifecycle events and process management
function MiniNodeProcessor(_owner = noone) constructor
{
	owner = _owner;
	
	#region Lifecycle
	
	// Initialization runs in phases, all in the same frame, before the node is ever drawn:
	//   1. on_init        (top-down)  setup that depends on construction (text size, etc.)
	//   2. resolve        (top-down)  world transforms
	//   3. layout         (bottom-up) node.__layout() hook (containers organize children)
	//   4. resolve        (top-down)  transforms changed by layout
	//   5. on_ready       (top-down)  size, layout and transforms are final
	//   6. on_enabled     (top-down)  only for enabled nodes (entry animations, auto focus)
	on_init = new MiniEvent();
	on_ready = new MiniEvent();

	is_initialized = false;				// Init phases have run
	
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

	///@function			__initialize_subtree()
	///@description			Run every init phase for the uninitialized nodes of the owner's subtree, in the same frame.
	///						See the phase list at the top of this constructor.
	static __initialize_subtree = function()
	{
		var _nodes = [];
		__collect_uninitialized(owner, _nodes);
		var _len = array_length(_nodes);

		// 1. on_init (top-down)
		for (var _i = 0; _i < _len; _i++)
		{
			var _processor = _nodes[_i].processor;
			_processor.is_initialized = true;
			_processor.on_init.invoke();
		}

		// 2. Resolve transforms (top-down)
		owner.__resolve_transform_tree();

		// 3. Layout (bottom-up: reversed pre-order puts descendants before ancestors)
		for (var _i = _len - 1; _i >= 0; _i--)
		{
			_nodes[_i].__layout();
		}

		// 4. Resolve transforms changed by the layout
		owner.__resolve_transform_tree();

		// 5. on_ready (top-down)
		for (var _i = 0; _i < _len; _i++)
		{
			_nodes[_i].processor.on_ready.invoke();
		}

		// 6. on_enabled for enabled nodes (top-down)
		for (var _i = 0; _i < _len; _i++)
		{
			var _node = _nodes[_i];
			if (_node.is_enabled()) _node.on_enabled.invoke();
		}
	}

	///@function			__collect_uninitialized(_node, _result)
	///@description			Pre-order collection of the uninitialized nodes in a subtree
	static __collect_uninitialized = function(_node, _result)
	{
		if (!_node.processor.is_initialized) array_push(_result, _node);

		var _children = _node.__nested_nodes;
		var _len = array_length(_children);
		for (var _i = 0; _i < _len; _i++)
		{
			__collect_uninitialized(_children[_i], _result);
		}
	}

	///@function			__step_processor()
	///@description			Main processing loop - called every frame by parent or NodeManager
	///						Handles: initialization, transform resolution, process execution, child recursion
	static __step_processor = function()
	{
		// First step: initialize this node and its whole subtree (disabled nodes are initialized too)
		if (!is_initialized) __initialize_subtree();

		// Skip processing if node is disabled
        if (!owner.is_enabled()) return;

		// Resolve pending transform changes (the renderer resolves again before drawing)
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