main :: () {
    ui_init("app", app, handle_action);
}

app :: () -> *VNode {
    root := h("div");
    class_add(root, "app");
    child_add(root, todo_component());
    return root;
}

handle_action :: (action: Action, info: *Event_Info) {
    if scene == {
        case .TODO; handle_action_todo(action, info);
    }

    schedule_render();
}

#run css(
    "body",
    .{
        font_family      = "-apple-system, BlinkMacSystemFont, \"Segoe UI\", Roboto, Helvetica, Arial, sans-serif",
        background_color = "#f4f4f9",
        color            = "#333",
        display          = .FLEX,
        justify_content  = .CENTER,
        padding_top      = px(50),
    }
);

Scene :: enum {
    TODO;
}

scene: Scene;

#load "todo.jai";

#import "Basic";
#import "Hash";

#import,file "../../module.jai";