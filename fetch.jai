#scope_export

next_fetch_id :: () -> u32 {
    fetch_counter += 1;
    return fetch_counter;
}

fetch :: (url: string, callback: Fetch_Callback, user_data: *void = null) -> u32 {
    options: Fetch_Options;
    return fetch(url, options, callback, user_data);
}

fetch :: (url: string, response_type: Fetch_Response_Type, callback: Fetch_Callback, user_data: *void = null) -> u32 {
    options: Fetch_Options;
    options.response_type = response_type;
    return fetch(url, options, callback, user_data);
}

fetch_blob :: (url: string, callback: Fetch_Callback, user_data: *void = null) -> u32 {
    return fetch(url, .BLOB, callback, user_data);
}

fetch :: (url: string, options: Fetch_Options, callback: Fetch_Callback, user_data: *void = null) -> u32 {
    if active_fetches.allocator.proc == null {
        active_fetches.allocator = context.default_allocator;
    }

    id := next_fetch_id();
    entry: Active_Fetch;
    entry.callback = callback;
    entry.user_data = user_data;
    entry.response_type = options.response_type;
    table_set(*active_fetches, id, entry);

    builder: String_Builder;
    init_string_builder(*builder);
    for options.headers {
        if has_invalid_header_chars(it.name, disallow_colon = true) || has_invalid_header_chars(it.value, disallow_colon = false) {
            console_error("Invalid characters in fetch header");
            continue;
        }
        append(*builder, it.name);
        append(*builder, ": ");
        append(*builder, it.value);
        append(*builder, "\n");
    }
    headers_str := builder_to_string(*builder,, temp);

    body_ptr: *u8 = null;
    body_len: s64 = 0;
    if options.body_bytes.count > 0 {
        body_ptr = options.body_bytes.data;
        body_len = options.body_bytes.count;
    } else if options.body.count > 0 {
        body_ptr = options.body.data;
        body_len = options.body.count;
    }

    wasm_fetch(
        id,
        url.data, url.count,
        options.method.data, options.method.count,
        headers_str.data, headers_str.count,
        body_ptr, body_len,
        cast(s32) options.response_type
    );

    return id;
}

dispatch_fetch_response :: (id: u32, status: s32, ok: bool, response_type: Fetch_Response_Type, data: *u8, data_count: s64) {
    entry_ptr := table_find_pointer(*active_fetches, id);
    if !entry_ptr return;

    entry := entry_ptr.*;
    table_remove(*active_fetches, id);

    response: Fetch_Response;
    response.ok = ok;
    response.status = status;
    response.type = response_type;
    response.user_data = entry.user_data;

    if ok {
        response.text.data  = data;
        response.text.count = data_count;
        response.blob.data  = data;
        response.blob.count = data_count;
        response.error      = "";
    } else {
        response.text       = "";
        response.blob       = .[];
        response.error.data  = data;
        response.error.count = data_count;
    }

    if entry.callback {
        entry.callback(*response);
    }
}

wasm_fetch :: (
    id: u32,
    url_data: *u8, url_count: s64,
    method_data: *u8, method_count: s64,
    headers_data: *u8, headers_count: s64,
    body_data: *u8, body_count: s64,
    response_type: s32
) #foreign;

Fetch_Response_Type :: enum s32 {
    TEXT :: 0;
    BLOB :: 1;
}

Fetch_Header :: struct {
    name: string;
    value: string;
}

Fetch_Options :: struct {
    method: string = "GET";
    headers: [] Fetch_Header = .[];
    body: string = "";
    body_bytes: [] u8 = .[];
    response_type: Fetch_Response_Type = .TEXT;
}

Fetch_Response :: struct {
    ok: bool;
    status: s32;
    type: Fetch_Response_Type;
    text: string;
    blob: [] u8;
    error: string;
    user_data: *void;
}

Fetch_Callback :: #type (response: *Fetch_Response);

#scope_file

has_invalid_header_chars :: (s: string, disallow_colon: bool) -> bool {
    for i: 0..s.count-1 {
        c := s[i];
        if c == #char "\r" || c == #char "\n" return true;
        if disallow_colon && c == #char ":" return true;
    }
    return false;
}

Active_Fetch :: struct {
    callback: Fetch_Callback;
    user_data: *void;
    response_type: Fetch_Response_Type;
}

active_fetches: Table(u32, Active_Fetch);
fetch_counter: u32 = 0;
