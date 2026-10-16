h :: (tag: string, class_name := "", child: *VNode = null, children: [] *VNode = .[], text := UNSET_VALUE, value := UNSET_VALUE, on_click: Action = .{}, on_input: Action = .{}, key_id: int = 0, loc := #caller_location) -> *VNode {
    node := New(VNode);
    node.tag = copy_string(tag);

    if class_name class_add(node, class_name);
    if child      child_add(node, child);
    for children  if it child_add(node, it);

    if text != UNSET_VALUE  set_text(node, text);
    if value != UNSET_VALUE attr_add(node, "value", value);

    if on_click.type on(node, "click", on_click);
    if on_input.type on(node, "input", on_input);

    node.key    = loc;
    node.key_id = key_id;

    return node;
}

div    :: #bake_arguments h(tag = "div");
h1     :: #bake_arguments h(tag = "h1");
h2     :: #bake_arguments h(tag = "h2");
h3     :: #bake_arguments h(tag = "h3");
h4     :: #bake_arguments h(tag = "h4");
h5     :: #bake_arguments h(tag = "h5");
h6     :: #bake_arguments h(tag = "h6");
button :: #bake_arguments h(tag = "button");
input  :: #bake_arguments h(tag = "input");

text_node :: (content: string) -> *VNode {
    node := New(VNode);
    node.tag  = "";
    node.text = copy_string(content);
    return node;
}

attr_add :: (node: *VNode, name: string, value: string) {
    array_add(*node.props, .{ type = .ATTRIBUTE, name = copy_string(name), value = copy_string(value) });
}

style_add :: (node: *VNode, property: string, value: string) {
    array_add(*node.props, .{ type = .STYLE, name = copy_string(property), value = copy_string(value) });
}

class_add :: (node: *VNode, class_name: string) {
    array_add(*node.props, .{ type = .CLASS_ADD, name = copy_string(class_name) });
}

on :: (node: *VNode, event_type: string, action: Action) {
    array_add(*node.listeners, .{ event_type = copy_string(event_type), action = action });
}

child_add :: (node: *VNode, child: *VNode) {
    array_add(*node.children, child);
}

set_text :: (node: *VNode, text: string) {
    node.text = copy_string(text);
}

action :: (id: $T, hash: u64, index: int = -1, ) -> Action
#modify {
    info := cast(*Type_Info) T;
    if info.type != .ENUM return false;

    info_enum := cast(*Type_Info_Enum) info;
    return info_enum.internal_type.type == .INTEGER;
}
{
    return .{ type = T, message = cast(int) id, index = index, hash = hash };
}

// @Copypasta from jai/modules/GetRect/module.jai.
KNUTH_GOLDEN_RATIO_64 :: 11400714819323198485;

// @Copypasta from jai/modules/GetRect/module.jai.
get_hash :: (loc: Source_Code_Location, identifier: s64) -> u64 {
    Hash :: #import "Hash";
    // Maybe we should hash the filename pointer in order to better prevent collisions.
    name_hash := Hash.djb2_hash(loc.fully_pathed_filename);
    line_hash := Hash.knuth_hash(cast,no_check(u64) loc.line_number);
    identifier_hash := Hash.knuth_hash(cast,no_check(u64) identifier);

    result := combine_hashes(name_hash, combine_hashes(line_hash, identifier_hash));
    return result;
}

// @Copypasta from jai/modules/GetRect/module.jai.
combine_hashes :: (a: u64, b: u64) -> u64 #no_aoc {
    return a * KNUTH_GOLDEN_RATIO_64 + b;
}

find_or_create_state :: ($T: Type, hash: u64) -> *T, created: bool {
    push_allocator(context.default_allocator);

    found := table_find_multiple(*states, hash);
    for found {
        if it.type == T return cast(*T) it, false;
    }

    state := New(T);
    state.type = T;

    table_add(*states, hash, state);

    return state, true;
}

frame_allocator_proc :: (mode: Allocator_Mode, size: s64, old_size: s64, old_memory: *void, data: *void) -> *void {
    arena := cast(*Frame_Arena) data;

    if mode == .ALLOCATE || mode == .RESIZE {
        aligned := (arena.used + 7) & ~7;
        if aligned + xx size <= FRAME_ARENA_SIZE {
            ptr := arena.data + aligned;
            arena.used = aligned + xx size;

            return ptr;
        }

        ptr := alloc(size,, context.default_allocator);
        array_add(*arena.blocks, ptr,, context.default_allocator);

        return ptr;
    }

    return null;
}

frame_arena_allocator :: (index: int) -> Allocator {
    return .{ proc = frame_allocator_proc, data = *frame_arenas[index] };
}

handler_register :: (handle: Dom_Node, event_type: string, action: Action) {
    entries_ptr := table_find_pointer(*handlers, handle);

    if !entries_ptr {
        empty: [..] Listener_Entry;
        empty.allocator = context.default_allocator;
        table_set(*handlers, handle, empty);
        entries_ptr = table_find_pointer(*handlers, handle);
    }

    event_copy := copy_string(event_type,, context.default_allocator);
    array_add(entries_ptr, .{ event_type = event_copy, action = action });
}

handler_dispatch :: (handle: Dom_Node, info: *Event_Info) {
    handler := table_find_pointer(*handlers, handle);
    if handler {
        for handler.* {
            if root_update root_update(it.action, info);
        }
    }
}

handler_remove_all :: (handle: Dom_Node) {
    handler := table_find_pointer(*handlers, handle);
    if handler {
        for handler.* {
            if it.event_type.count > 0 && it.event_type.data {
                free(it.event_type,, context.default_allocator);
            }
        }
        array_free(handler.*);
        table_remove(*handlers, handle);
    }
}

apply_props :: (dom: Dom_Node, node: *VNode) {
    if node.text dom_set_text_content(dom, node.text);

    for node.props {
        if it.type == {
            case .ATTRIBUTE; dom_set_attribute(dom, it.name, it.value);
            case .STYLE;     dom_set_style(dom, it.name, it.value);
            case .CLASS_ADD; dom_add_class(dom, it.name);
        }
    }

    for node.listeners {
        dom_add_event_listener(dom, it.event_type);
        handler_register(dom, it.event_type, it.action);
    }
}

mount_vnode :: (parent: Dom_Node, vnode: *VNode, before: Dom_Node = NULL_NODE) {
    if vnode.tag == "" {
        dom := dom_create_text_node(vnode.text);
        if before dom_insert_before(parent, dom, before);
        else      dom_append_child(parent, dom);
        vnode.dom_node = dom;
        return;
    }

    dom := dom_create_element(vnode.tag);
    vnode.dom_node = dom;

    apply_props(dom, vnode);

    for vnode.children {
        mount_vnode(dom, it);
    }

    if before dom_insert_before(parent, dom, before);
    else      dom_append_child(parent, dom);
}

unmount_vnode :: (vnode: *VNode) {
    if vnode.dom_node == NULL_NODE return;

    for vnode.children {
        unmount_vnode(it);
    }

    handler_remove_all(vnode.dom_node);
    dom_remove(vnode.dom_node);
    dom_release(vnode.dom_node);
    vnode.dom_node = NULL_NODE;
}

patch_props :: (dom: Dom_Node, old_node: *VNode, new_node: *VNode) {
    for old_prop, i: old_node.props {
        found := false;

        if i < new_node.props.count {
            new_prop := new_node.props[i];
            if new_prop.type == old_prop.type && new_prop.name == old_prop.name {
                found = true;
            }
        }

        if !found {
            for new_prop: new_node.props {
                if new_prop.type == old_prop.type && old_prop.name == old_prop.name {
                    found = true;
                    break;
                }
            }
        }

        if !found {
            if old_prop.type == {
                case .ATTRIBUTE; dom_remove_attribute(dom, old_prop.name);
                case .STYLE;     dom_set_style(dom, old_prop.name, "");
                case .CLASS_ADD; dom_remove_class(dom, old_prop.name);
            }
        }
    }

    for new_prop, i: new_node.props {
        old_value: string;
        found     := false;

        if i < old_node.props.count {
            old_prop := old_node.props[i];
            if old_prop.type == new_prop.type && old_prop.name == new_prop.name {
                old_value = old_prop.value;
                found     = true;
            }
        }

        if !found {
            for old_prop: old_node.props {
                if old_prop.type == new_prop.type && old_prop.name == new_prop.name {
                    old_value = old_prop.value;
                    found     = true;
                    break;
                }
            }
        }

        if !found || new_prop.value != old_value {
            if new_prop.type == {
                case .ATTRIBUTE; dom_set_attribute(dom, new_prop.name, new_prop.value);
                case .STYLE;     dom_set_style(dom, new_prop.name, new_prop.value);
                case .CLASS_ADD; if !found dom_add_class(dom, new_prop.name);
            }
        }
    }

    if new_node.text != old_node.text {
        dom_set_text_content(dom, new_node.text);
    }

    for new_listener: new_node.listeners {
        already_registered := false;
        for old_listener: old_node.listeners {
            if old_listener.event_type == new_listener.event_type {
                already_registered = true;
                break;
            }
        }
        if !already_registered {
            dom_add_event_listener(dom, new_listener.event_type);
        }
    }

    handler_remove_all(dom);
    for new_node.listeners {
        handler_register(dom, it.event_type, it.action);
    }
}

same_vnode_key :: (a: *VNode, b: *VNode) -> bool {
    return a.tag == b.tag && a.key == b.key && a.key_id == b.key_id;
}

patch_children :: (parent: Dom_Node, old_node: *VNode, new_node: *VNode) {
    old_count := old_node.children.count;
    new_count := new_node.children.count;

    if old_count == 0 {
        for new_node.children mount_vnode(parent, it);
        return;
    }

    if new_count == 0 {
        for old_node.children unmount_vnode(it);
        return;
    }

    old_used := cast(*bool) alloc(old_count * size_of(bool),, temp);
    memset(old_used, 0, old_count * size_of(bool));

    for i: 0..new_count - 1 {
        new_child := new_node.children[i];
        found_old_index := -1;

        if i < old_count && !old_used[i] && same_vnode_key(old_node.children[i], new_child) {
            found_old_index = i;
        } else {
            for j: 0..old_count - 1 {
                if !old_used[j] && same_vnode_key(old_node.children[j], new_child) {
                    found_old_index = j;
                    break;
                }
            }
        }

        if found_old_index != -1 {
            old_child := old_node.children[found_old_index];
            old_used[found_old_index] = true;
            patch_vnode(parent, old_child, new_child);
        } else {
            anchor: Dom_Node = NULL_NODE;

            for k: i+1..new_count-1 {
                next_new := new_node.children[k];

                for j: 0..old_count - 1 {
                    if !old_used[j] && same_vnode_key(old_node.children[j], next_new) {
                        anchor = old_node.children[j].dom_node;
                        break;
                    }
                }

                if anchor break;
            }

            mount_vnode(parent, new_child, anchor);
        }
    }

    for i: 0..old_count - 1 {
        if !old_used[i] unmount_vnode(old_node.children[i]);
    }
}

patch_vnode :: (parent: Dom_Node, old_vnode: *VNode, new_vnode: *VNode) {
    if !same_vnode_key(old_vnode, new_vnode) {
        unmount_vnode(old_vnode);
        mount_vnode(parent, new_vnode);
        return;
    }

    new_vnode.dom_node = old_vnode.dom_node;

    patch_props(new_vnode.dom_node, old_vnode, new_vnode);
    patch_children(new_vnode.dom_node, old_vnode, new_vnode);
}

ui_init :: (container_id: string, component: Root_Component, update: Handle_Action_Proc = null) {
    root_container = dom_get_element_by_id(container_id);
    root_component = component;
    root_update    = update;
    previous_vnode = null;

    for * frame_arenas it.data = alloc(FRAME_ARENA_SIZE,, context.default_allocator);

    handlers.allocator = context.default_allocator;

    render_scheduled = false;

    do_render();
    flush();
}

schedule_render :: () {
    render_scheduled = true;
}

do_render :: () {
    current_frame_index += 1;

    next_arena_index := 1 - current_arena;

    arena := *frame_arenas[next_arena_index];

    for arena.blocks free(it,, context.default_allocator);
    arena.blocks.count = 0;

    arena.used = 0;

    new_vnode: *VNode;

    push_context .{ allocator = frame_arena_allocator(next_arena_index) } {
        new_vnode = root_component();
    }

    if previous_vnode == null mount_vnode(root_container, new_vnode);
    else                      patch_vnode(root_container, previous_vnode, new_vnode);

    previous_vnode = new_vnode;
    current_arena  = next_arena_index;

    reset_temporary_storage();
}

operator == :: (a: Source_Code_Location, b: Source_Code_Location) -> bool {
    return !memcmp(*a, *b, size_of(Source_Code_Location));
}

Event_Info :: struct {
    handle:   Dom_Node;
    client_x: float;
    client_y: float;
    extra:    float;
    value:    string;
}

Prop_Type :: enum u8 {
    ATTRIBUTE;
    STYLE;
    CLASS_ADD;
}

Prop :: struct {
    type:  Prop_Type;
    name:  string;
    value: string;
}

Listener_Entry :: struct {
    event_type: string;
    action:     Action;
}

VNode :: struct {
    tag:    string;
    key:    Source_Code_Location;
    key_id: int;
    text:   string;

    props:     [..] Prop;
    listeners: [..] Listener_Entry;
    children:  [..] *VNode;

    dom_node: Dom_Node;
}

State_Entry :: struct {
    key:   Source_Code_Location;
    value: *void;
    last_frame_accessed: s64;
}

Frame_Arena :: struct {
    data: *u8;
    used: int;

    blocks: [..] *void;
}

Action :: struct {
    type: Type;

    message: int;
    index:   int;

    hash: u64;
}

State :: struct {
    type: Type;
}

Root_Component     :: #type () -> *VNode;
Handle_Action_Proc :: #type (action: Action, info: *Event_Info) -> ();

FRAME_ARENA_SIZE :: 1024 * 256;

UNSET_VALUE :: "\x00_unset";

frame_arenas:  [2] Frame_Arena;
current_arena: int;
current_frame_index: s64;

handlers: Table(Dom_Node, [..] Listener_Entry);

root_component: Root_Component;
root_update:    Handle_Action_Proc;
root_container: Dom_Node;
previous_vnode: *VNode;

render_scheduled: bool;

states: Table(u64, *State);
