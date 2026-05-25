// An MiniNode is the basic interface element, it has the default variables for control and visual display

#region ENUMs n Macros

enum NODE_ORIGIN
{
	TOP_LEFT,
	TOP_CENTER,
	TOP_RIGHT,
	MIDDLE_LEFT,
	MIDDLE_CENTER,
	MIDDLE_RIGHT,
	BOTTOM_LEFT,
	BOTTOM_CENTER,
	BOTTOM_RIGHT
}

#macro NODE_ORIGIN_CONVERSION [[0, 0],[-0.5, 0],[-1, 0],[0, -0.5],[-0.5, -0.5],[-1, -0.5],[0, -1],[-0.5, -1],[-1, -1]]

#endregion

#region Structs

///@function						MiniNode(_id, _origin)
///@description						Base interface element with transform, rendering, and processing capabilities.
///									All UI elements inherit from this struct.
///@param {String} _id				Unique identifier for this node
///@param {Enum.NODE_ORIGIN} [_origin]	Anchor point for positioning (default MIDDLE_CENTER)
function MiniNode(_id, _origin = NODE_ORIGIN.MIDDLE_CENTER) constructor
{
	// System variables
	id = _id;
	parent = noone;
	origin = _origin;
	sys_origin_offset = [0,0]; // Offset calculated from origin to top-left corner
	
    // MiniNode storage
	__nested_nodes = [];
	__sibling_index = 0; // Index within parent's __nested_nodes array
    
	// Components 
	renderer = new MiniNodeRenderer(self);
	processor = new MiniNodeProcessor(self);
	navigator = noone;
	nav_module = noone;		// MiniNodeNavCenter — if set, this node manages navigation for its children
	
    // Transform
	transform = new NodeTransform(self);
	local_transform = new NodeTransform(self);
	fixed_transform = new NodeTransform(self);
	start_transform = noone;
	
	// MiniNode events
	on_node_updated = new MiniEvent();
	on_transform_modified = new MiniEvent();
    on_enabled = new MiniEvent();
	on_disabling = new MiniEvent();
    on_disabled = new MiniEvent();
	
    // System flags
	__node_init_block = true;
	__transform_dirty = false;
    enabled = true;
	visible = true;
	__disable_timer = undefined;
	
	#region NODE BUILDER

	///@function			node_add(_node1, _node2, ...)
	///@description			Add one or more child nodes to this node
	///@param {Struct.MiniNode}	_nodes Variable number of nodes to add
	///@returns {Struct.MiniNode} Self for chaining
	static node_add = function(_nodes)
	{
		for (var _i = 0; _i < argument_count; _i++)
		{
			var _node = argument[_i];
			if (_node == self)
			{
				throw("MiniNode cannot be added to itself");
			}
            
            _node.parent = self;
            _node.__sibling_index = array_length(__nested_nodes);
            array_push(__nested_nodes, _node);
            
            mnd_create_node(_node, true, false);
		}		
		return self;
	}
	
	///@function			node_add_navigation_module()
	///@description			Enable navigation control for the children nodes
	static node_add_navigation_module = function()
	{
		navigation = new MiniNodeNavCenter(self);
		return self;
	}

	///@function			node_get_children()
	///@description		Get an array with all nested nodes
	///@returns {Array<Struct.MiniNode>} Array of descendants
	static node_get_children = function()
	{
		return __nested_nodes;
	}

	///@function			node_get_all_children()
	///@description		Get an array with all nested nodes (children, grandchildren, etc.)
	///@returns {Array<Struct.MiniNode>} Array of all descendants
	static node_get_all_children = function()
	{
		var _result = [];
		var _stack = __nested_nodes;
		var _len = array_length(_stack);
		for (var _i = 0; _i < _len; _i++)
		{
			var _child = _stack[_i];
			array_push(_result, _child);
			var _grand = _child.node_get_all_children();
			if (array_length(_grand) > 0)
			{
				_result = array_concat(_result, _grand);
			}
		}
		return _result;
	}
	
	///@function				node_remove(_node)
	///@description				Remove a nested node by reference
	///@param {Struct.MiniNode}		_node The node to remove
	///@returns {Struct.MiniNode}	Self for chaining
	static node_remove = function(_node)
	{
		var _index = _node.__sibling_index;
		if (_index != undefined && _index < array_length(__nested_nodes))
		{
			// Remove all node descendants from manager
			var _descendants = _node.node_get_all_children();
			var _desc_count = array_length(_descendants);
			for (var _d = 0; _d < _desc_count; _d++)
			{
				var _child = _descendants[_d];
				mnd_remove_node(_child.id);
			}

			// Remove the node itself from nested array and manager
			array_delete(__nested_nodes, _index, 1);
			mnd_remove_node(_node.id);

			// Update sibling indices for nodes after the removed one
			var _len = array_length(__nested_nodes);
			for (var _i = _index; _i < _len; _i++)
			{
				__nested_nodes[_i].__sibling_index = _i;
			}
		}
		return self;
	}
	
	///@function				node_get_root()
	///@description				Get the root node (topmost parent, usually a MiniNodeCanvas)
	///@returns {Struct.MiniNode}	The root node in the hierarchy
	static node_get_root = function()
	{
		var _current = self;
		while (_current.parent != noone)
		{
			_current = _current.parent;
		}
		return _current;
	}
	
	
	///@function				node_set_transform(_x, _y, _xscale, _yscale, _alpha, _angle, _width, _height, _depth)
	///@description				Set all node transform properties at once (sets both local and fixed)
	///@param {Real} _x			X position
	///@param {Real} _y			Y position
	///@param {Real} _xscale		Horizontal scale
	///@param {Real} _yscale		Vertical scale
	///@param {Real} _alpha			Alpha/opacity (0-1)
	///@param {Real} _angle			Rotation angle in degrees
	///@param {Real} _width			Width in pixels
	///@param {Real} _height		Height in pixels
	///@param {Real} [_depth]		Depth layer (default 0)
	static node_set_transform = function(_x, _y, _xscale, _yscale, _alpha, _angle, _width, _height, _depth = 0)
	{
		with (local_transform)
		{
			x = _x;
			y = _y;
			
			image_xscale = _xscale;
			image_yscale = _yscale; 
			
			image_alpha = _alpha;
			image_angle = _angle;
			
			width = _width;
			height = _height;
		}
		fixed_transform = variable_clone(local_transform);
	}	
    
    	///@function				node_set_transform(_x, _y, _xscale, _yscale, _alpha, _angle, _width, _height, _depth)
	///@description				    Set all node transform properties at once (sets both local and fixed)
	///@param {String} _attribute   Attribute name
	///@param {Real} _value		    Attribute value
	static node_set_transform_attribute = function(_attribute, _value)
	{
		local_transform[$ _attribute] = _value;
		fixed_transform[$ _attribute] = variable_clone(local_transform[$ _attribute]);
	}	
	
	#endregion
	
	#region TRANSFORM
	
	///@function			__mark_transform_dirty()
	///@description			Mark this node's transform as dirty for deferred recalculation.
	///						Automatically propagates to all children.
	static __mark_transform_dirty = function()
	{
		if (__transform_dirty) return;
            
		__transform_dirty = true;			
	}
	
	///@function			__resolve_transform()
	///@description			Resolve dirty transform if flagged. Called once per frame before processing.
	///						Invokes on_transform_modified event after update.
	static __resolve_transform = function()
	{
		if (!__transform_dirty) return;
		
		__transform_dirty = false;
		__transform_update();		
		
        on_transform_modified.invoke();
		
		// Mark children
		var _len = array_length(__nested_nodes);
		for (var _i = 0; _i < _len; _i++)
		{
			__nested_nodes[_i].__mark_transform_dirty();
		}
	}
	
	///@function			__transform_update()
	///@description			Recalculate world transform from local transform and parent.
	///						Handles position, scale, alpha, rotation inheritance and rotation offset.
	static __transform_update = function()
	{
		// If the node has a parent, recalculate transform properties
		if (parent != noone)
		{
			transform.x = (local_transform.x * parent.transform.image_xscale) + parent.transform.x;
			transform.y = (local_transform.y * parent.transform.image_yscale) + parent.transform.y;
			
			transform.image_xscale = local_transform.image_xscale * parent.transform.image_xscale;
			transform.image_yscale = local_transform.image_yscale * parent.transform.image_yscale;
			
			transform.image_alpha = local_transform.image_alpha * parent.transform.image_alpha;
			transform.image_angle = local_transform.image_angle + parent.transform.image_angle;
			
			transform.x += transform.offset_x;
			transform.y += transform.offset_y;
			
			// If parent is rotated, calculate new position
			if (parent.transform.image_angle != 0) 
			{
				transform.image_angle = parent.transform.image_angle + local_transform.image_angle;
				
				var _origin_x = local_transform.x + parent.transform.x,
					_origin_y = local_transform.y + parent.transform.y;

				var _distance = point_distance(_origin_x, _origin_y, parent.transform.x, parent.transform.y);
				
				var _new_x = parent.transform.x + lengthdir_x(_distance, parent.transform.image_angle),	
					_new_y = parent.transform.y + lengthdir_y(_distance, parent.transform.image_angle);
				
				transform.x = _new_x;
				transform.y = _new_y;
			}
		}
		else 
		{
			transform = local_transform;	
		}
		
		// Recalculate node width and height
		transform.width = fixed_transform.width * abs(transform.image_xscale);
		transform.height = fixed_transform.height * abs(transform.image_yscale);
		
		// Recalculate origin
		__transform_set_system_origin_offset();
	}
	
	///@function			__transform_set_system_origin_offset()
	///@description			Recalculate sys_origin_offset array based on current origin and size.
	///						Offset represents distance from origin point to top-left corner.
    static __transform_set_system_origin_offset = function()
	{
		var _factor = NODE_ORIGIN_CONVERSION[origin];
		sys_origin_offset[0] = transform.width * _factor[0];
		sys_origin_offset[1] = transform.height * _factor[1];
	}
    
	///@function				transform_set_rotation(_rotation)
	///@description				Set the node's rotation angle
	///@param {Real} _rotation	Rotation angle in degrees
	static transform_set_rotation = function(_rotation)
	{
		local_transform.image_angle = _rotation;
		__mark_transform_dirty();	
	}
	
	///@function				transform_set_depth(_depth)
	///@description				Set the node's depth layer
	///@param {Real} _depth		Depth value (lower = drawn on top)
	static transform_set_depth = function(_depth)
	{
		local_transform.depth = _depth;
		__mark_transform_dirty();
	}
		
	///@function					transform_set_scale(_xscale, _yscale)
	///@description					Set the node's scale multipliers
	///@param {Real} _xscale			Horizontal scale (1 = 100%)
	///@param {Real} _yscale			Vertical scale (1 = 100%)
	static transform_set_scale = function(_xscale, _yscale)
	{
		local_transform.image_xscale = _xscale;
		local_transform.image_yscale = _yscale;	
		
		__mark_transform_dirty();	
	}
	
	///@function				transform_set_position(_x, _y)
	///@description				Set the node's local position relative to parent
	///@param {Real} _x			X position in pixels
	///@param {Real} _y			Y position in pixels
	static transform_set_position = function(_x, _y)
	{
		local_transform.x = _x;
		local_transform.y = _y;
		
		__mark_transform_dirty();
	}
	
	///@function				transform_set_alpha(_alpha)
	///@description				Set the node's alpha/opacity
	///@param {Real} _alpha		Alpha value (0 = transparent, 1 = opaque)
	static transform_set_alpha = function(_alpha)
	{
		local_transform.image_alpha = _alpha;
		__mark_transform_dirty();
	}

	///@function				transform_set_size(_width, _height)
	///@description				Set the node's base size in pixels
	///@param {Real} _width		Width in pixels
	///@param {Real} _height	Height in pixels
	static transform_set_size = function(_width, _height)
	{
		local_transform.width = _width;
		local_transform.height = _height;
		
		__mark_transform_dirty();
	}

	///@function						transform_set_attribute(_attribute_name, _value)
	///@description						Set any transform attribute by name (for animation system)
	///@param {String} _attribute_name	Name of the attribute (e.g., "x", "image_alpha")
	///@param {Real} _value				Value to set
	static transform_set_attribute = function(_attribute_name, _value)
	{
		if (!struct_exists(local_transform, _attribute_name)) return;
		
		local_transform[$ _attribute_name] = _value;
		__mark_transform_dirty();
	}
	
	///@function					transform_add_rotation(_rotation)
	///@description					Add to the node's current rotation angle
	///@param {Real} _rotation		Rotation to add in degrees
	static transform_add_rotation = function(_rotation)
	{
		local_transform.image_angle += _rotation;
		__mark_transform_dirty();	
	}
	
	///@function				transform_add_depth(_depth)
	///@description				Add to the node's current depth
	///@param {Real} _depth		Depth value to add
	static transform_add_depth = function(_depth)
	{
		local_transform.depth += _depth;
		__mark_transform_dirty();
	}
	
	///@function					transform_add_scale(_xscale, _yscale)
	///@description					Add to the node's current scale values
	///@param {Real} _xscale			Horizontal scale to add
	///@param {Real} _yscale			Vertical scale to add
	static transform_add_scale = function(_xscale, _yscale)
	{
		local_transform.image_xscale += _xscale;
		local_transform.image_yscale += _yscale;	
		
		__mark_transform_dirty();	
	}
	
	///@function					transform_add_position(_x, _y)
	///@description					Add to the node's current position (relative movement)
	///@param {Real} _x				X offset to add in pixels
	///@param {Real} _y				Y offset to add in pixels
	static transform_add_position = function(_x, _y)
	{
		local_transform.x += _x;
		local_transform.y += _y;
		
		__mark_transform_dirty();
	}
	
	///@function					transform_add_alpha(_alpha)
	///@description					Add to the node's current alpha value
	///@param {Real} _alpha			Alpha to add (can be negative)
	static transform_add_alpha = function(_alpha)
	{
		local_transform.image_alpha += _alpha;

		__mark_transform_dirty();
	}
	
	#endregion
	
	#region UTILITY
	
	///@function							origin_get_converted(_origin_to_convert)
	///@description							Get offset from current origin to a different origin point
	///@param {Enum.NODE_ORIGIN} _origin_to_convert	Target origin to calculate offset for
	///@returns {Array<Real>}				Array [x_offset, y_offset] from current to target origin
	static origin_get_converted = function(_origin_to_convert) 
	{
		var _offset = sys_origin_offset;
		
		var _factor = NODE_ORIGIN_CONVERSION[_origin_to_convert];
		_offset[0] += transform.width * _factor[0];
		_offset[1] += transform.height * _factor[1];
		
		return _offset;
	}
	
	///@function			is_enabled()
	///@description			Check if node is enabled for processing
	///@returns {Bool}		True if enabled
	static is_enabled = function()
	{
		return enabled;
	}
	
	///@function			is_visible()
	///@description			Check if node is visible for rendering
	///@returns {Bool}		True if visible
	static is_visible = function()
	{
		return visible;
	}

	///@function			is_initialized()
	///@description			Check if node has completed its initialization phase
	///@returns {Bool}		True if on_init has been invoked
	static is_initialized = function()
	{
		return processor.is_initialized;
	}
	
	#endregion
	
	#endregion
	
	#region VISIBILITY
	
	///@function					set_visible(_visible)
	///@description					Set the visibility of this node (controls rendering only)
	///@param {Bool} _visible		True to show, false to hide
	///@returns {Struct.MiniNode}		Self for chaining
	static set_visible = function(_visible)
	{
		visible = _visible;
		return self;
	}
	
	///@function			show()
	///@description			Make this node visible
	///@returns {Struct.MiniNode}	Self for chaining
	static show = function()
	{
		visible = true;
		return self;
	}
	
	///@function			hide()
	///@description			Hide this node from rendering
	///@returns {Struct.MiniNode}	Self for chaining
	static hide = function()
	{
		visible = false;
		return self;
	}
	
	#endregion
    
	#region ENABLE / DISABLE

	///@function			enable()
	///@description			Enable the node for processing. Invokes on_enabled event.
    static enable = function()
    {
		if (enabled) return; // Guard against re-entry
		
		enabled = true;
		
		// Cancel any pending disable timer
		if (__disable_timer != undefined)
		{
			call_cancel(__disable_timer);
			__disable_timer = undefined;
		}
		
		var _len = array_length(__nested_nodes);
		for (var _i = 0; _i < _len; _i++)
		{
			__nested_nodes[_i].enable();
		}
							
        on_enabled.invoke();
    }
    
	///@function					disable(_delay)
	///@description					Disable the node from processing.
	///								If delay > 0, fires on_disabling immediately and on_disabled after the delay.
	///								If delay <= 0, disables immediately and fires on_disabled.
	///@param {Real} [_delay]		Delay in seconds before actually disabling (default 0)
    static disable = function(_delay = 0)
    {
		if (_delay > 0)
		{
			on_disabling.invoke();
			__propagate_disabling();
			__disable_timer = call_later(_delay, time_source_units_seconds, method(self, function() {
				__disable_timer = undefined;
				disable();
			}));
		}
		else
		{
			// Cancel any pending disable timer
			if (__disable_timer != undefined)
			{
				call_cancel(__disable_timer);
				__disable_timer = undefined;
			}
			
			enabled = false;
			on_disabled.invoke();
			
			// Propagate disabled state to all children
			var _len = array_length(__nested_nodes);
			for (var _i = 0; _i < _len; _i++)
			{
				__nested_nodes[_i].__force_disable();
			}
		}
    }
	
	///@function			__force_disable()
	///@description			Force disable this node and all children without delay.
	///						Sets enabled=false and invokes on_disabled, then propagates.
	static __force_disable = function()
	{
		enabled = false;
		on_disabled.invoke();
		var _len = array_length(__nested_nodes);
		for (var _i = 0; _i < _len; _i++)
		{
			__nested_nodes[_i].__force_disable();
		}
	}
	
	///@function			__propagate_disabling()
	///@description			Propagate on_disabling event to all children recursively.
	///						Children only fire their event for animations, they don't disable themselves.
	static __propagate_disabling = function()
	{
		var _len = array_length(__nested_nodes);
		for (var _i = 0; _i < _len; _i++)
		{
			var _child = __nested_nodes[_i];
			_child.on_disabling.invoke();
			_child.__propagate_disabling();
		}
	}

    
	#endregion
	
	#region SYSTEM
		
	///@function			update()
	///@description			Trigger a manual update of this node. Invokes on_node_updated event.
	///						Use when node content needs refresh (e.g., language change, state change).
	static update = function()
	{
		on_node_updated.invoke(); 
	}

	///@function			__node_system_update()
	///@description			Internal system update handler. Marks transform dirty and propagates
	///						update() call to all nested children. Connected to on_node_updated.
	static __node_system_update = function()
	{
		// Update transform
		__mark_transform_dirty();
				
		// Call update on all nested nodes
		var _len = array_length(__nested_nodes);
		for (var _i = 0; _i < _len; _i++)
		{
			__nested_nodes[_i].update();
		}
	}
    
	///@function			__node_init()
	///@description			Internal initialization handler. Clears init block and marks transform dirty.
	///						Connected to processor.on_init event.
	static __node_init = function()
	{
		__node_init_block = false;	
		__mark_transform_dirty();
	}
    
	// Connecting system events
	on_node_updated.connect(self, __node_system_update);
    processor.on_init.connect(self, __node_init);

	#endregion
}

///@function			NodeTransform()
///@description			Transform data structure holding position, scale, rotation, alpha, and size.
///						Used for local_transform, transform (world), and fixed_transform.
///@param {Struct.MiniNode} _owner	Owner node of this transform
function NodeTransform(_owner) constructor
{
	owner = _owner;

	x = 0;
	y = 0;
	
	image_xscale = 1;
	image_yscale = 1;
	
	image_angle = 0;
	image_alpha = 1;

	width = 8;
	height = 8;
	
	offset_x = 0;
	offset_y = 0;
	
	depth = 0;
}	

#endregion