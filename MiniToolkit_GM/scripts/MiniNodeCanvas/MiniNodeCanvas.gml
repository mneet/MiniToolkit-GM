///@function						MiniNodeCanvas(_name, _origin)
///@description						An organizational root node for UI hierarchies.
///									Serves as a logical grouping node that can be registered as a root in the NodeManager.
///									To add navigation, attach a MiniNodeNavCenter:
///										var canvas = new MiniNodeCanvas("my_canvas");
///										var nav = new MiniNodeNavCenter(canvas, 0);
///@param {String} _name			Unique identifier for this canvas
///@param {Enum.NODE_ORIGIN} [_origin]	Anchor point for positioning
function MiniNodeCanvas(_name, _origin = MND_CANVAS_DEFAULT_ORIGIN) : MiniNode(_name, _origin) constructor
{ 
	// Future: screen proportion, viewport management, safe area, etc.
}
