///@function						MiniNodeCanvas(_name, _origin, _auto_root)
///@description						An organizational root node for UI hierarchies.
///									Registers itself as a root in the NodeManager (processed and drawn in Draw GUI).
///									To start disabled, call mnd_root_add(canvas, false) or mnd_hide(canvas).
///									To add navigation, attach a navigation group (works on any MiniNode):
///										var canvas = new MiniNodeCanvas("my_canvas");
///										canvas.node_add_nav_group().nav_set_wrap(false, true);
///@param {String} _name			Unique identifier for this canvas (globally unique, roots are registered)
///@param {Enum.NODE_ORIGIN} [_origin]	Anchor point for positioning
///@param {Bool} [_auto_root]		Register as root automatically (default MND_CANVAS_AUTO_ROOT)
function MiniNodeCanvas(_name, _origin = MND_CANVAS_DEFAULT_ORIGIN, _auto_root = MND_CANVAS_AUTO_ROOT) : MiniNode(_name, _origin) constructor
{ 
	// Safe before building the hierarchy: initialization only runs on the first manager step
	if (_auto_root) mnd_root_add(self);
	
	// Future: screen proportion, viewport management, safe area, etc.
}
