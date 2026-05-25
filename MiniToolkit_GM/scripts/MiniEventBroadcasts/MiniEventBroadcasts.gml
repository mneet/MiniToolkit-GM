/* 
    MiniEvent
    A basic event system based on the Observer Pattern
 
    Authors: M. Neet - https://github.com/mneet/MiniToolkit-GM
    Version: 1.0.0
*/

global.__mini_event_broadcasts = {};

///@function mini_event_broadcast(_broadcast)
///@description                 Emit a named broadcast. Any additional arguments are forwarded to registered listeners.
///@param {String} _broadcast   Name of the broadcast to emit
///@param {...Any} [args]       Optional arguments forwarded to registered callbacks
function mini_event_broadcast(_broadcast)
{
    if (!struct_exists(global.__mini_event_broadcasts, _broadcast))
        return;
    
    var _has_args = argument_count > 1;
    var _args = undefined;

    if (_has_args)
    {
        _args = [];
        for (var _i = 1; _i < argument_count; _i++) _args[_i-1] = argument[_i];
    }
    
    var _event = global.__mini_event_broadcasts[$ _broadcast];
    var _method = method(_event, _event.invoke);
    
    if (_has_args) method_call(_method, _args);
    else _method();
}

///@function mini_event_listen(_broadcast, _id, _callback, _once, _priority)
///@description                 Register a listener for a named broadcast. The `_id` can be an instance id or a struct used to own the connection.
///@param {String} _broadcast   Broadcast name
///@param {Any} _id             Connection identifier (instance id or struct)
///@param {Function} _callback  Callback invoked when the broadcast is emitted; receives forwarded args
///@param {Bool} [_once=false]  If true, the listener is removed after first invocation
///@param {Real} [_priority=0]  Priority level (higher = executed earlier)
function mini_event_listen(_broadcast, _id, _callback, _once = false, _priority = 0)
{
    if (!struct_exists(global.__mini_event_broadcasts, _broadcast))
        global.__mini_event_broadcasts[$ _broadcast] = new MiniEvent();
    
    global.__mini_event_broadcasts[$ _broadcast].connect(_id, _callback, _once, _priority);
}

///@function mini_event_clear_broadcast(_broadcast)
///@description                 Remove a named broadcast or clear all broadcasts if `_broadcast` is omitted.
///@param {String} [_broadcast] Optional broadcast name. If omitted, all broadcasts are cleared.
function mini_event_clear_broadcast(_broadcast = undefined)
{
    if (_broadcast == undefined)
    {
        global.__mini_event_broadcasts = {};
        show_debug_message("MiniEvent: Broadcasts were cleaned");
    }
    else 
    {
        if (struct_exists(global.__mini_event_broadcasts, _broadcast))
           struct_remove(global.__mini_event_broadcasts, _broadcast); 	
        
        show_debug_message($"MiniEvent: Broadcast '{_broadcast}' was removed");
    }
}

function test()
{
    show_debug_message($"TESTANDO {is_struct(other)} {other}");
}