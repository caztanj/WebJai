#scope_export

next_websocket_handle :: () -> WebSocket_Handle {
    websocket_handle_counter += 1;
    return cast(WebSocket_Handle) websocket_handle_counter;
}

websocket_connect :: (url: string, config: WebSocket_Config = .{}) -> WebSocket_Handle {
    if active_websockets.allocator.proc == null {
        active_websockets.allocator = context.default_allocator;
    }

    handle := next_websocket_handle();
    entry: Active_WebSocket;
    entry.handle = handle;
    entry.config = config;
    table_set(*active_websockets, cast(s32) handle, entry);

    wasm_websocket_connect(
        cast(s32) handle,
        url.data, url.count,
        config.protocols.data, config.protocols.count,
        cast(s32) config.binary_type
    );

    return handle;
}

websocket_connect :: (url: string, on_message: WebSocket_Message_Proc, user_data: *void = null) -> WebSocket_Handle {
    config: WebSocket_Config;
    config.on_message = on_message;
    config.user_data  = user_data;
    return websocket_connect(url, config);
}

websocket_send :: (socket: WebSocket_Handle, text: string) {
    wasm_websocket_send_text(cast(s32) socket, text.data, text.count);
}

websocket_send :: (socket: WebSocket_Handle, data: [] u8) {
    wasm_websocket_send_binary(cast(s32) socket, data.data, data.count);
}

websocket_send_blob :: (socket: WebSocket_Handle, data: [] u8) {
    websocket_send(socket, data);
}

websocket_close :: (socket: WebSocket_Handle, code: s32 = 1000, reason: string = "") {
    wasm_websocket_close(cast(s32) socket, code, reason.data, reason.count);
}

websocket_get_state :: (socket: WebSocket_Handle) -> WebSocket_State {
    return cast(WebSocket_State) wasm_websocket_get_state(cast(s32) socket);
}

websocket_set_on_open :: (socket: WebSocket_Handle, proc: WebSocket_Open_Proc) {
    entry := table_find_pointer(*active_websockets, cast(s32) socket);
    if entry entry.config.on_open = proc;
}

websocket_set_on_message :: (socket: WebSocket_Handle, proc: WebSocket_Message_Proc) {
    entry := table_find_pointer(*active_websockets, cast(s32) socket);
    if entry entry.config.on_message = proc;
}

websocket_set_on_error :: (socket: WebSocket_Handle, proc: WebSocket_Error_Proc) {
    entry := table_find_pointer(*active_websockets, cast(s32) socket);
    if entry entry.config.on_error = proc;
}

websocket_set_on_close :: (socket: WebSocket_Handle, proc: WebSocket_Close_Proc) {
    entry := table_find_pointer(*active_websockets, cast(s32) socket);
    if entry entry.config.on_close = proc;
}

dispatch_websocket_open :: (handle: WebSocket_Handle) {
    entry := table_find_pointer(*active_websockets, cast(s32) handle);
    if entry && entry.config.on_open {
        entry.config.on_open(handle, entry.config.user_data);
    }
}

dispatch_websocket_message :: (handle: WebSocket_Handle, is_blob: bool, data: *u8, count: s64) {
    entry := table_find_pointer(*active_websockets, cast(s32) handle);
    if entry && entry.config.on_message {
        msg: WebSocket_Message;
        msg.type = ifx is_blob then WebSocket_Message_Type.BLOB else .TEXT;
        msg.text.data  = data;
        msg.text.count = count;
        msg.data.data  = data;
        msg.data.count = count;

        entry.config.on_message(handle, *msg, entry.config.user_data);
    }
}

dispatch_websocket_error :: (handle: WebSocket_Handle, error_data: *u8, error_count: s64) {
    entry := table_find_pointer(*active_websockets, cast(s32) handle);
    if entry && entry.config.on_error {
        err_str: string;
        err_str.data  = error_data;
        err_str.count = error_count;
        entry.config.on_error(handle, err_str, entry.config.user_data);
    }
}

dispatch_websocket_close :: (handle: WebSocket_Handle, code: s32, reason_data: *u8, reason_count: s64, was_clean: bool) {
    entry_ptr := table_find_pointer(*active_websockets, cast(s32) handle);
    if entry_ptr {
        entry := entry_ptr.*;
        table_remove(*active_websockets, cast(s32) handle);

        if entry.config.on_close {
            reason: string;
            reason.data  = reason_data;
            reason.count = reason_count;
            entry.config.on_close(handle, code, reason, was_clean, entry.config.user_data);
        }
    }
}

wasm_websocket_connect     :: (handle: s32, url_data: *u8, url_count: s64, protocols_data: *u8, protocols_count: s64, binary_type: s32) #foreign;
wasm_websocket_send_text   :: (handle: s32, data: *u8, count: s64) #foreign;
wasm_websocket_send_binary :: (handle: s32, data: *u8, count: s64) #foreign;
wasm_websocket_close       :: (handle: s32, code: s32, reason_data: *u8, reason_count: s64) #foreign;
wasm_websocket_get_state   :: (handle: s32) -> s32 #foreign;

WebSocket_Handle :: #type,distinct s32;
NULL_WEBSOCKET: WebSocket_Handle : 0;

WebSocket_Binary_Type :: enum s32 {
    BLOB         :: 0;
    ARRAY_BUFFER :: 1;
}

WebSocket_Message_Type :: enum s32 {
    TEXT :: 0;
    BLOB :: 1;
}

WebSocket_State :: enum s32 {
    CONNECTING :: 0;
    OPEN       :: 1;
    CLOSING    :: 2;
    CLOSED     :: 3;
}

WebSocket_Message :: struct {
    type: WebSocket_Message_Type;
    text: string;
    data: [] u8;
}

WebSocket_Open_Proc    :: #type (socket: WebSocket_Handle, user_data: *void);
WebSocket_Message_Proc :: #type (socket: WebSocket_Handle, message: *WebSocket_Message, user_data: *void);
WebSocket_Error_Proc   :: #type (socket: WebSocket_Handle, error: string, user_data: *void);
WebSocket_Close_Proc   :: #type (socket: WebSocket_Handle, code: s32, reason: string, was_clean: bool, user_data: *void);

WebSocket_Config :: struct {
    protocols: string = "";
    binary_type: WebSocket_Binary_Type = .BLOB;
    user_data: *void = null;

    on_open:    WebSocket_Open_Proc    = null;
    on_message: WebSocket_Message_Proc = null;
    on_error:   WebSocket_Error_Proc   = null;
    on_close:   WebSocket_Close_Proc   = null;
}

#scope_file
Active_WebSocket :: struct {
    handle: WebSocket_Handle;
    config: WebSocket_Config;
}

active_websockets: Table(s32, Active_WebSocket);
websocket_handle_counter: s32 = 0;