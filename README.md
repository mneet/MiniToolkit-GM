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


## 📄 License

Distributed under the **MIT License**.

---

## 👤 Author

**M. Neto** - GitHub: [@mneet](https://github.com/mneet/)

Nota do Autor:

Venho utilizando algumas dessas ferramentas nos meus projetos há alguns anos. Resolvi dar uma polida no código e disponibilizá-los publicamente para a comunidade, mas peço que leiam os avisos abaixo antes de utilizá-los:

- Mudança de Foco: O GameMaker não é mais a minha engine principal de desenvolvimento. Por conta disso, este repositório não receberá atualizações frequentes.

- Suporte e Responsabilidade: O uso destes sistemas é fornecido "como está" (as is). Não tenho como prestar suporte ativo, e a integração no seu projeto é de sua inteira responsabilidade. Ficarei feliz em receber relatos de bugs nas Issues, mas as correções serão feitas no meu próprio tempo e disponibilidade.

- Praticidade > Performance: O objetivo principal desses sistemas sempre foi facilitar e agilizar o desenvolvimento para as minhas próprias necessidades, e não necessariamente aplicar as práticas mais avançadas e performáticas do GM. Se o seu projeto exige otimização extrema, recomendo explorar outras alternativas na comunidade.

- Uso de IA: Para viabilizar este lançamento público, utilizei modelos de Inteligência Artificial como auxiliares para redigir parte da documentação, formatar comentários e realizar pequenas refatorações de código.

- Contribuições: São extremamente bem-vindas! Se você tem interesse em melhorar o código, criar forks ou trocar uma ideia para construir novas versões baseadas nestes sistemas, a porta está aberta. Fique à vontade para abrir um Pull Request ou entrar em contato.

---
