push_command :: (type: Wasm_Command_Type, handle: Dom_Node = NULL_NODE, arg1: Dom_Node = NULL_NODE, arg2: Dom_Node = NULL_NODE, data: string = "", extra: string = "") {
    data_copy  := ifx data.count  > 0 then copy_string(data,,  context.default_allocator) else "";
    extra_copy := ifx extra.count > 0 then copy_string(extra,, context.default_allocator) else "";

    command: Wasm_Command;
    command.type        = type;
    command.handle      = handle;
    command.arg1        = arg1;
    command.arg2        = arg2;
    command.data        = data_copy.data;
    command.count       = data_copy.count;
    command.extra       = extra_copy.data;
    command.extra_count = extra_copy.count;

    array_add(*command_buffer, command);
}

dom_get_element_by_id :: (id: string) -> Dom_Node {
    handle := next_dom_handle();
    push_command(.Dom_Get_Element_By_Id, handle=handle, data=id);
    return handle;
}

dom_get_elements_by_name :: (name: string, loc := #caller_location) -> [] Dom_Node {
    if command_buffer.count > 0  flush();

    count := wasm_get_elements_by_name(name.data, name.count, null, 0, 0);
    if count <= 0 return .[];

    result := NewArray(count, Dom_Node, initialized = false);
    start_handle := dom_handle_counter + 1;
    dom_handle_counter += cast(s32) count;

    for 0..count-1 {
        result[it] = cast(Dom_Node) (start_handle + cast(s32) it);
    }

    wasm_get_elements_by_name(name.data, name.count, result.data, cast(s32) count, cast(Dom_Node) start_handle);

    return result;
}

dom_create_element :: (tag: string) -> Dom_Node {
    handle := next_dom_handle();
    push_command(.Dom_Create_Element, handle=handle, data=tag);
    return handle;
}

dom_create_text_node :: (text: string) -> Dom_Node {
    handle := next_dom_handle();
    push_command(.Dom_Create_Text_Node, handle=handle, data=text);
    return handle;
}

dom_append_child :: (parent: Dom_Node, child: Dom_Node) {
    push_command(.Dom_Append_Child, handle=parent, arg1=child);
}

dom_remove_child :: (parent: Dom_Node, child: Dom_Node) {
    push_command(.Dom_Remove_Child, handle=parent, arg1=child);
}

dom_remove :: (node: Dom_Node) {
    push_command(.Dom_Remove, handle=node);
}

dom_set_text_content :: (node: Dom_Node, text: string) {
    push_command(.Dom_Set_Text_Content, handle=node, data=text);
}

dom_set_inner_html :: (node: Dom_Node, html: string) {
    push_command(.Dom_Set_Inner_Html, handle=node, data=html);
}

dom_set_attribute :: (node: Dom_Node, name: string, value: string) {
    push_command(.Dom_Set_Attribute, handle=node, data=name, extra=value);
}

dom_remove_attribute :: (node: Dom_Node, name: string) {
    push_command(.Dom_Remove_Attribute, handle=node, data=name);
}

dom_add_class :: (node: Dom_Node, class_name: string) {
    push_command(.Dom_Add_Class, handle=node, data=class_name);
}

dom_remove_class :: (node: Dom_Node, class_name: string) {
    push_command(.Dom_Remove_Class, handle=node, data=class_name);
}

dom_toggle_class :: (node: Dom_Node, class_name: string) {
    push_command(.Dom_Toggle_Class, handle=node, data=class_name);
}

dom_set_style :: (node: Dom_Node, property: string, value: string) {
    push_command(.Dom_Set_Style, handle=node, data=property, extra=value);
}

dom_add_event_listener :: (node: Dom_Node, event_type: string) {
    push_command(.Dom_Add_Event_Listener, handle=node, data=event_type);
}

dom_release :: (node: Dom_Node) {
    push_command(.Dom_Release, handle=node);
}

dom_insert_before :: (parent: Dom_Node, child: Dom_Node, before: Dom_Node) {
    push_command(.Dom_Insert_Before, handle=parent, arg1=child, arg2=before);
}

console_log :: (s: string) {
    push_command(.Console_Log, data=s);
}

console_error :: (s: string) {
    push_command(.Console_Error, data=s);
}

flush :: () {
    if command_buffer.count <= 0 return;

    wasm_send_command_buffer_to_js(xx command_buffer.data, command_buffer.count, size_of(Wasm_Command));

    for command_buffer {
        if it.count > 0 && it.data        free(it.data,,  context.default_allocator);
        if it.extra_count > 0 && it.extra free(it.extra,, context.default_allocator);
    }

    command_buffer.count = 0;
}

next_dom_handle :: () -> Dom_Node {
    dom_handle_counter += 1;
    return xx dom_handle_counter;
}

JS_COMMAND_BUFFER_CAPACITY :: 128;

#program_export
wasm_get_js_command_buffer_ptr :: () -> *Js_Command #c_call {
    push_context {
        if js_command_buffer.allocated < JS_COMMAND_BUFFER_CAPACITY {
            array_reserve(*js_command_buffer, JS_COMMAND_BUFFER_CAPACITY,, context.default_allocator);
        }

        return js_command_buffer.data;
    }
}

#program_export
wasm_handle_js_commands :: (count: s32) #c_call {
    push_context {
        if count <= 0 return;

        valid_count := cast(s64) count;
        if valid_count > js_command_buffer.allocated {
            valid_count = js_command_buffer.allocated;
        }
        js_command_buffer.count = valid_count;

        for js_command_buffer {
            info: Event_Info;
            info.handle      = it.arg_handle;
            info.client_x    = it.arg1;
            info.client_y    = it.arg2;
            info.extra       = it.arg3;
            info.value.data  = it.arg_string;
            info.value.count = it.arg_string_count;

            if it.type == {
                case .Mouse_Down;
                    handler_dispatch(NULL_NODE, *info);

                case .Dom_Event;
                    handler_dispatch(it.arg_handle, *info);

                case .Fetch_Response;
                    dispatch_fetch_response(cast(u32) it.arg_handle, cast(s32) it.arg1, cast(bool) (it.arg2 != 0), cast(Fetch_Response_Type) cast(s32) it.arg3, it.arg_string, it.arg_string_count);

                case .WebSocket_Open;
                    dispatch_websocket_open(cast(WebSocket_Handle) it.arg_handle);

                case .WebSocket_Message;
                    dispatch_websocket_message(cast(WebSocket_Handle) it.arg_handle, cast(bool) (it.arg1 != 0), it.arg_string, it.arg_string_count);

                case .WebSocket_Error;
                    dispatch_websocket_error(cast(WebSocket_Handle) it.arg_handle, it.arg_string, it.arg_string_count);

                case .WebSocket_Close;
                    dispatch_websocket_close(cast(WebSocket_Handle) it.arg_handle, cast(s32) it.arg1, it.arg_string, it.arg_string_count, cast(bool) (it.arg2 != 0));
            }
        }

        for js_string_allocations {
            free(it,, context.default_allocator);
        }
        js_string_allocations.count = 0;

        if render_scheduled {
            render_scheduled = false;
            do_render();
            flush();
        }
    }
}

#program_export
wasm_push_string :: (count: s32) -> *u8 #c_call {
    push_context {
        if count <= 0 return null;
        ptr := cast(*u8) alloc(count,, context.default_allocator);
        if ptr array_add(*js_string_allocations, ptr,, context.default_allocator);
        return ptr;
    }
}

wasm_debug_break               :: () #foreign;
wasm_send_command_buffer_to_js :: (data: *u8, count: s64, size: s64) #foreign;
wasm_get_elements_by_name      :: (name_data: *u8, name_count: s64, handles_out: *Dom_Node, max_handles: s32, start_handle: Dom_Node) -> s32 #foreign;

Dom_Node :: #type,distinct s32;

NULL_NODE: Dom_Node : 0;

Wasm_Command_Type :: enum s32 {
    Console_Assert          :: 0;
    Console_Clear           :: 1;
    Console_Count           :: 2;
    Console_Count_Reset     :: 3;
    Console_Debug           :: 4;
    Console_Dir             :: 5;
    Console_Dir_Xml         :: 6;
    Console_Error           :: 7;
    Console_Group           :: 8;
    Console_Group_Collapsed :: 9;
    Console_Group_End       :: 10;
    Console_Info            :: 11;
    Console_Log             :: 12;
    Console_Profile         :: 13;
    Console_Profile_End     :: 14;
    Console_Table           :: 15;
    Console_Time            :: 16;
    Console_Time_End        :: 17;
    Console_Time_Log        :: 18;
    Console_Time_Stamp      :: 19;
    Console_Trace           :: 20;
    Console_Warn            :: 21;

    Dom_Get_Element_By_Id  :: 32;
    Dom_Create_Element     :: 33;
    Dom_Append_Child       :: 34;
    Dom_Remove_Child       :: 35;
    Dom_Remove             :: 36;
    Dom_Set_Text_Content   :: 37;
    Dom_Set_Inner_Html     :: 38;
    Dom_Set_Attribute      :: 39;
    Dom_Remove_Attribute   :: 40;
    Dom_Add_Class          :: 41;
    Dom_Remove_Class       :: 42;
    Dom_Toggle_Class       :: 43;
    Dom_Set_Style          :: 44;
    Dom_Add_Event_Listener :: 45;
    Dom_Release            :: 46;
    Dom_Create_Text_Node   :: 47;
    Dom_Insert_Before :: 48;
}

Wasm_Command :: struct {
    type: Wasm_Command_Type; //  0 (4 bytes)

    handle: Dom_Node;        //  4 (4 bytes)
    arg1:   Dom_Node;        //  8 (4 bytes)
    arg2:   Dom_Node;        // 12 (4 bytes)

    data:  *u8;              // 16 (8 bytes)
    count: s64;              // 24 (8 bytes)

    extra: *u8;              // 32 (8 bytes)
    extra_count: s64;        // 40 (8 bytes)
}

Js_Command_Type :: enum s32 {
    Mouse_Down        :: 0;
    Dom_Event         :: 1;
    Fetch_Response    :: 2;
    WebSocket_Open    :: 3;
    WebSocket_Message :: 4;
    WebSocket_Error   :: 5;
    WebSocket_Close   :: 6;
}

Js_Command :: struct {
    type: Js_Command_Type; //  0 (4 bytes)

    arg_handle: Dom_Node;  //  4 (4 bytes)

    arg1: float;           //  8 (4 bytes)
    arg2: float;           // 12 (4 bytes)
    arg3: float;           // 16 (4 bytes)

    _pad: s32;             // 20 (4 bytes)

    arg_string:       *u8; // 24 (8 bytes)
    arg_string_count: s64; // 32 (8 bytes)
}

dom_handle_counter: s32 = 0;

command_buffer:    [..] Wasm_Command;
js_command_buffer: [..] Js_Command;

js_string_allocations: [..] *u8;

#load "ui.jai";
#load "fetch.jai";
#load "websocket.jai";

#load "css/align_items.jai";
#load "css/background.jai";
#load "css/background_color.jai";
#load "css/border.jai";
#load "css/border_bottom.jai";
#load "css/border_radius.jai";
#load "css/box_shadow.jai";
#load "css/color.jai";
#load "css/css.jai";
#load "css/cursor.jai";
#load "css/display.jai";
#load "css/flex_grow.jai";
#load "css/font_family.jai";
#load "css/font_size.jai";
#load "css/height.jai";
#load "css/justify_content.jai";
#load "css/margin.jai";
#load "css/margin_bottom.jai";
#load "css/margin_left.jai";
#load "css/margin_right.jai";
#load "css/margin_top.jai";
#load "css/max_height.jai";
#load "css/max_width.jai";
#load "css/min_height.jai";
#load "css/min_width.jai";
#load "css/padding.jai";
#load "css/padding_bottom.jai";
#load "css/padding_left.jai";
#load "css/padding_right.jai";
#load "css/padding_top.jai";
#load "css/text_align.jai";
#load "css/transform.jai";
#load "css/width.jai";

#import "Basic";
#import "Hash";
#import "Hash_Table";
#import "String";
