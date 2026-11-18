/* 
    MiniEvent
    A basic event system based on the Observer Pattern
 
    Authors: M. Neet - https://github.com/mneet/MiniToolkit-GM
    Version: 1.0.1
*/

///@function			MiniEvent()
///@description			Constructor for a lightweight event system
///@returns {Struct.MiniEvent}
function MiniEvent() constructor
{
	// Unique ID for this event 
	__event_id = $"__evt_{ptr(self)}";
	
	// Centralized sorted array of callbacks
	__callbacks = [];
	
	// Reentrancy: while > 0, connect/disconnect work on a copy so the array being invoked is never mutated
	__invoke_depth = 0;

	#region Internal

	///@function					__callback_struct(_connection, _cb_key, _priority, _is_struct)
    ///@description						Struct for storing callback metadata
	///@param {Any} _connection    		Connection reference (weak_ref or instance id)
    ///@param {Function} _callback		Callback function
    ///@param {Real} _priority			Priority level
    static __callback_struct = function(_connection, _callback, _priority, _once) constructor
    {
        connection_is_struct = is_struct(_connection);
		connection = _connection;
        
        priority = _priority;
        once = _once;
        callback = _callback;
		removed = false;	// Flagged when disconnected/consumed, so an ongoing invoke skips it
    }
	
	///@function					__remove_flagged()
	///@description					Rebuild the callback array without removed entries (new array: ongoing invokes keep their snapshot)
	static __remove_flagged = function()
	{
		var _kept = [];
		var _count = array_length(__callbacks);
		for (var _i = 0; _i < _count; _i++)
		{
			if (!__callbacks[_i].removed) array_push(_kept, __callbacks[_i]);
		}
		__callbacks = _kept;
	}

	///@function					__set_callbacks(_connection, _callback, _once, _priority)
	///@description					Set up and push a callback for this event on a connection
	///@param {Any} _connection		Connection struct or instance
	///@param {Function} _callback	Callback function
	///@param {Bool} _once			Whether to remove after first invoke
	///@param {Real} _priority		Priority level (higher = executed first)
	static __set_callbacks = function(_connection, _callback, _once = false, _priority = 0)
	{	
		var _is_struct = is_struct(_connection);

		// Validate connection
		var _error_msg = noone;
		if (_connection == undefined) 
			_error_msg = $"MiniEvent {__event_id}: Cannot connect to undefined connection.";

		if (!_is_struct && !instance_exists(_connection))
			_error_msg = $"MiniEvent {__event_id}: Cannot connect to non-existing instance {string(_connection)}.";

		if (!is_callable(_callback))
			_error_msg = $"MiniEvent {__event_id}: Callback is not callable.";

		if (_error_msg != noone)
		{
			show_debug_message(_error_msg);
			return self;
		}
		
		// Insert into sorted array 
		var _entry = new __callback_struct(_is_struct ? weak_ref_create(_connection) : _connection, _callback, _priority, _once);
        
        var _low = 0,
            _high = array_length(__callbacks) - 1, 
            _mid = 0;

		while (_high >= _low)
        {
            _mid = floor((_low + _high) / 2);
			if (_mid >= array_length(__callbacks)) break;
			
			var _mid_priority = __callbacks[_mid].priority;
			if (_priority == _mid_priority)
			{
				_low = _mid;
				break;
			}
			else if (_priority < _mid_priority)
			{
				_low = _mid + 1;
			}
			else
			{
				_high = _mid - 1;
			}
        }
		
		// Never mutate the array an ongoing invoke is iterating
		if (__invoke_depth > 0)
		{
			var _copy = [];
			array_copy(_copy, 0, __callbacks, 0, array_length(__callbacks));
			__callbacks = _copy;
		}
		array_insert(__callbacks, _low, _entry);
	}
    
	#endregion
	
	#region Public 
	
	///@function						connect(_connection, _callback, _once, _priority)
	///@description						Connect a callback to this event.
	///@param {Any} _connection			Connection instance or struct
	///@param {Function} _callback		Callback function
	///@param {Bool} _once				If the callback is called only once
	///@param {Real} [_priority]		Priority level (higher = executed first, default 0)
	///@returns {Struct.MiniEvent}		Self for chaining
	static connect = function(_connection, _callback, _once = false, _priority = 0)
	{
		__set_callbacks(_connection, _callback, _once, _priority);
		return self;
	}

	///@function						disconnect(_connection, _callback)
	///@description						Disconnect callback(s) from this event.
	///@param {Any} _connection			Connection instance or struct
	///@param {Function} [_callback]	Specific callback to remove (if undefined, removes all from connection)
	///@returns {Struct.MiniEvent}		Self for chaining
	static disconnect = function(_connection, _callback = undefined)
	{
		var _count = array_length(__callbacks);
		var _any = false;
		
		for (var _i = 0; _i < _count; _i++)
		{
			var _cb = __callbacks[_i],
				_cb_connection = undefined;
			
			if (_cb.connection_is_struct)
			{
				var _ref = _cb.connection;
				if (!weak_ref_alive(_ref))
				{
					_cb.removed = true;
					_any = true;
					continue;
				}
				_cb_connection = _ref.ref;
			}
			else
			{
				_cb_connection = _cb.connection;
			}
			
			if (_cb_connection == _connection && (_callback == undefined || _callback == _cb.callback))
			{
				_cb.removed = true;
				_any = true;
			}
		}
		
		// Rebuilds into a new array, safe during invoke
		if (_any) __remove_flagged();
		
		return self;
	}

	///@function						invoke(...)
	///@description						Invoke all connected callbacks with optional arguments.
	///@param {...Any} [args]			Optional arguments to pass to callbacks
	///@returns {Struct.MiniEvent}		Self for chaining
	static invoke = function()
	{
		var _has_args = argument_count > 0;
		var _args = undefined;

		if (_has_args)
		{
			_args = array_create(argument_count);
			for (var _i = 0; _i < argument_count; _i++) _args[_i] = argument[_i];
		}
		
		// Iterate a snapshot: connect/disconnect inside callbacks never affect this loop
		var _list = __callbacks;
		var _count = array_length(_list);
		if (_count == 0) return self;
		
		var _needs_cleanup = false;
		__invoke_depth++;
		
		for (var _i = 0; _i < _count; _i++)
		{
			var _entry = _list[_i];
			if (_entry.removed) continue;	// Disconnected during this invoke
			
			// Validate connection
			var _connection = _entry.connection;
			if (_entry.connection_is_struct)
			{
				if (!weak_ref_alive(_connection))
				{
					_entry.removed = true;
					_needs_cleanup = true;
					continue;
				}
				_connection = _connection.ref;
			}
			else if (!instance_exists(_connection))
			{
				_entry.removed = true;
				_needs_cleanup = true;
				continue;
			}
			
			// Consume 'once' before calling, so a nested invoke can't fire it again
			if (_entry.once)
			{
				_entry.removed = true;
				_needs_cleanup = true;
			}
			
            var _method = method(_connection, _entry.callback);
            
            if (_has_args) method_call(_method, _args);
            else _method();
		}
		
		__invoke_depth--;
		if (_needs_cleanup) __remove_flagged();
		
		return self;
	}
	
	#endregion
}
