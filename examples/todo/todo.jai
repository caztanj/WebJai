todo_component :: (loc := #caller_location, identifier := 0) -> *VNode {
    hash  := get_hash(loc, identifier);
    state := find_or_create_state(Todo_State, hash);

    items_nodes: [..] *VNode;
    items_nodes.allocator = temp;

    print("HERE\n");

    for * state.todos {
        item := it;

        text_style := ifx item.done then "line-through" else "none";

        row := div(
            class_name = Todo_Row,
            key_id = item.id,
            children = .[
                h(
                    "input",
                    on_click = action(Todo_List_Message.TOGGLE_TODO, hash, index = it_index)
                ),
                div(
                    text = item.text,
                    class_name = Todo_Text,
                ),
                button(
                    text = "Ta bort",
                    on_click = action(Todo_List_Message.REMOVE_TODO, hash, index = it_index)
                )
            ]
        );

        checkbox := row.children[0];
        attr_add(checkbox, "type", "checkbox");
        if item.done then attr_add(checkbox, "checked", "true");

        style_add(row.children[1], "text-decoration", text_style);

        array_add(*items_nodes, row);
    }

    return div(
        class_name = Todo_App,
        children = .[
            h1(text = "Att-göra-lista"),
            div(
                class_name = Todo_Input_Row,
                children = .[
                    input(
                        value = state.text_input,
                        on_input = action(Todo_List_Message.INPUT_CHANGE, hash),
                    ),
                    button(
                        text = "Lägg till",
                        on_click = action(Todo_List_Message.ADD_TODO, hash),
                    )
                ]
            ),
            div(
                class_name = "todo-list",
                children = items_nodes
            )
        ]
    );
}

handle_action_todo :: (action: Action, info: *Event_Info) {
    if action.type == Todo_List_Message {
        message := cast(Todo_List_Message) action.message;
        state := find_or_create_state(Todo_State, action.hash);

        if message == {
            case Todo_List_Message.INPUT_CHANGE;
                if state.text_input free(state.text_input);
                state.text_input = copy_string(info.value);

            case Todo_List_Message.ADD_TODO;
                if state.text_input.count > 0 {
                    state.next_id += 1;
                    array_add(*state.todos, .{ id = state.next_id, text = copy_string(state.text_input), done = false });
                    free(state.text_input);
                    state.text_input = "";
                }

            case Todo_List_Message.TOGGLE_TODO;
                if action.index >= 0 && action.index < state.todos.count {
                    state.todos[action.index].done = !state.todos[action.index].done;
                }

            case Todo_List_Message.REMOVE_TODO;
                if action.index >= 0 && action.index < state.todos.count {
                    if state.todos[action.index].text free(state.todos[action.index].text);
                    array_ordered_remove_by_index(*state.todos, action.index);
                }
        }
    }
}

#scope_file

Todo_State :: struct {
    #as using base: State;

    next_id:    int;
    text_input: string;
    todos:      [..] Todo;
}

Todo :: struct {
    id:   int;
    text: string;
    done: bool;
}

Todo_List_Message :: enum {
    NONE;
    INPUT_CHANGE;
    ADD_TODO;
    TOGGLE_TODO;
    REMOVE_TODO;
}
Todo_Input_Row :: #run css(
    "todo-input-row",
    display(.FLEX),
    margin_bottom(px(20)),
);

Todo_App :: #run css(
    "todo-app",
    background("white"),
    padding(px(30)),
    border_radius(px(10)),
    width(percent(100)),
    max_width(px(400)),
    box_shadow("0 4px 6px rgba(0,0,0,0.1)"),
);
#run css(
    ".todo-app h1",
    margin_top(px(0)),
    font_size(px(24)),
    text_align("center"),
);

#run css(
    ".todo-input-row input",
    flex_grow(1),
    padding(px(10)),
    border("1px solid #ccc"),
    border_radius(px(4), px(0), px(0), px(4)),
    font_size(px(16)),
);

#run css(
    ".todo-input-row button",
    padding(px(10), px(15)),
    border("none"),
    background_color("#007bff"),
    color("white"),
    font_size(px(16)),
    cursor("pointer"),
    border_radius(px(0), px(4), px(4), px(0)),
);

#run css(
    ".todo-input-row button:hover",
    background_color("#0056b3"),
);

Todo_Row :: #run css(
    "todo-row",
    display(.FLEX),
    align_items(.CENTER),
    padding(px(10), px(0)),
    border_bottom("1px solid #eee"),
);

#run css(
    ".todo-row:last-child",
    border_bottom("none"),
);

#run css(
    ".todo-row input[type=\"checkbox\"]",
    margin_right(px(15)),
    transform("scale(1.5)"),
);

Todo_Text :: #run css(
    "todo-text",
    flex_grow(1),
    font_size(px(18)),
);

#run css(
    ".todo-row button",
    background_color("#dc3545"),
    color("white"),
    border("none"),
    padding(px(5), px(10)),
    border_radius(px(4)),
    cursor("pointer"),
);

#run css(
    ".todo-row button:hover",
    background_color("#c82333"),
);
