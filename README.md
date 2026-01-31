# GML Mini Toolkit 🛠️

A collection of simple systems developed to streamline GameMaker projects.

## 📦 Modules Included

### 🧩 MiniNodes

A code-driven interface builder for creating quick and functional GUIs. Includes components like containers, canvases, and navigators for building user interfaces programmatically without using the Room Editor.

### ✨ MiniTweens

A small tweening system for animating numeric properties of objects and structs. Supports easing curves, loops, delays, and callbacks.

### 📡 MiniEvents

A simple event system based on the Observer Pattern.

---

## 📖 Usage

### MiniTweens Example

```gml
// Create a tween to move an object
// Arguments: Target, Duration (seconds)
var _tween = mini_tween(obj_player, 2.0)
    .tween("x", 100, EASING_CURVES.SINE_OUT)
    .tween("y", 200, EASING_CURVES.SINE_IN)
    .set_delay(0.5)
    .on_complete(function() {
        show_debug_message("Movement complete!");
    });

// Or use fire-and-forget shortcuts
mini_tween_fade_in(obj_menu_bg, 1.0);

```

### MiniEvents Example

```gml
// 1. Create an event dispatcher
evt_level_up = new MiniEvent();

// 2. Connect listeners 
// The first argument is the an reference to the listener (id for instances, self for structs)
evt_level_up.connect(id, function(_level) { 
    show_debug_message("Level Up! New Level: " + string(_level));
});

// 3. Invoke the event (broadcast to all listeners)
evt_level_up.invoke(5);

```

### MiniNodes Example

```gml
// Create a UI Canvas attached to the top-left
main_canvas = new NodeCanvas("my_canvas", NODE_ORIGIN.TOP_LEFT);

with (main_canvas)
{
    // Create a button
    var _button = new NodeButton("play_button");
    
    with (_button)
    {
        button_set_text("START GAME", fnt_arial_12);
        
        // Connect button event
        on_button_pressed.connect(other.id, function() {
            room_goto(rm_game);
        });
    }
    
    // Add button to canvas
    node_add(_button);
}

```

---

## 🤝 Contributing

Contributions are welcome! Please feel free to submit issues, feature requests, or pull requests.

---

## 📄 License

Distributed under the **MIT License**.

---

## 👤 Author

**M. Neto** - GitHub: [@mneet](https://github.com/mneet/)

---
