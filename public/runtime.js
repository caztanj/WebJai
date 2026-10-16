let memory;
let instance;

const COMMAND_CONSOLE_ASSERT          = 0;
const COMMAND_CONSOLE_CLEAR           = 1;
const COMMAND_CONSOLE_COUNT           = 2;
const COMMAND_CONSOLE_COUNT_RESET     = 3;
const COMMAND_CONSOLE_DEBUG           = 4;
const COMMAND_CONSOLE_DIR             = 5;
const COMMAND_CONSOLE_DIR_XML         = 6;
const COMMAND_CONSOLE_ERROR           = 7;
const COMMAND_CONSOLE_GROUP           = 8;
const COMMAND_CONSOLE_GROUP_COLLAPSED = 9;
const COMMAND_CONSOLE_GROUP_END       = 10;
const COMMAND_CONSOLE_INFO            = 11;
const COMMAND_CONSOLE_LOG             = 12;
const COMMAND_CONSOLE_PROFILE         = 13;
const COMMAND_CONSOLE_PROFILE_END     = 14;
const COMMAND_CONSOLE_TABLE           = 15;
const COMMAND_CONSOLE_TIME            = 16;
const COMMAND_CONSOLE_TIME_END        = 17;
const COMMAND_CONSOLE_TIME_LOG        = 18;
const COMMAND_CONSOLE_TIME_STAMP      = 19;
const COMMAND_CONSOLE_TRACE           = 20;
const COMMAND_CONSOLE_WARN            = 21;

const COMMAND_DOM_GET_ELEMENT_BY_ID  = 32;
const COMMAND_DOM_CREATE_ELEMENT     = 33;
const COMMAND_DOM_APPEND_CHILD       = 34;
const COMMAND_DOM_REMOVE_CHILD       = 35;
const COMMAND_DOM_REMOVE             = 36;
const COMMAND_DOM_SET_TEXT_CONTENT   = 37;
const COMMAND_DOM_SET_INNER_HTML     = 38;
const COMMAND_DOM_SET_ATTRIBUTE      = 39;
const COMMAND_DOM_REMOVE_ATTRIBUTE   = 40;
const COMMAND_DOM_ADD_CLASS          = 41;
const COMMAND_DOM_REMOVE_CLASS       = 42;
const COMMAND_DOM_TOGGLE_CLASS       = 43;
const COMMAND_DOM_SET_STYLE          = 44;
const COMMAND_DOM_ADD_EVENT_LISTENER = 45;
const COMMAND_DOM_RELEASE            = 46;
const COMMAND_DOM_CREATE_TEXT_NODE   = 47;
const COMMAND_DOM_INSERT_BEFORE      = 48;

const JS_COMMAND_MOUSE_DOWN        = 0;
const JS_COMMAND_DOM_EVENT         = 1;
const JS_COMMAND_FETCH_RESPONSE    = 2;
const JS_COMMAND_WEBSOCKET_OPEN    = 3;
const JS_COMMAND_WEBSOCKET_MESSAGE = 4;
const JS_COMMAND_WEBSOCKET_ERROR   = 5;
const JS_COMMAND_WEBSOCKET_CLOSE   = 6;

const WASM_COMMAND_SIZE = 48; // @Todo: Generate this at compile time.
const JS_COMMAND_SIZE   = 40; // @Todo: Generate this at compile time.
const MAX_JS_COMMANDS   = 128;

const COMMAND_OFFSET_TYPE        = 0;
const COMMAND_OFFSET_HANDLE      = 4;
const COMMAND_OFFSET_ARG1        = 8;
const COMMAND_OFFSET_ARG2        = 12;
const COMMAND_OFFSET_DATA        = 16;
const COMMAND_OFFSET_COUNT       = 24;
const COMMAND_OFFSET_EXTRA       = 32;
const COMMAND_OFFSET_EXTRA_COUNT = 40;

const BLOCKED_TAGS = new Set(["script", "object", "embed", "base", "applet"]);
const URL_ATTRIBUTES = new Set(["href", "src", "xlink:href", "action", "formaction", "srcdoc"]);

const node_table = new Map();
const registered_listeners = new WeakMap();

const node_get = (handle) => {
    const element = node_table.get(handle);

    if (!element) {
        console.warn(`[dom] unknown handle ${handle}`);
    }

    return element;
};

const node_set = (handle, element) => node_table.set(handle, element);

const socket_table = new Map();

const is_unsafe_url = (value) => {
    const normalized = String(value).replace(/[\u0000-\u0020]+/g, "").toLowerCase();

    return (
        normalized.startsWith("javascript:") ||
        normalized.startsWith("vbscript:") ||
        normalized.startsWith("data:text/html")
    );
};

const sanitize_html = (html) => {
    const template = document.createElement("template");
    template.innerHTML = html;

    const clean_node = (root) => {
        const elements = root.querySelectorAll("*");
        for (const element of elements) {
            const tag = element.tagName.toLowerCase();

            if (BLOCKED_TAGS.has(tag) || tag === "iframe") {
                element.remove();
                continue;
            }

            for (const attr of Array.from(element.attributes)) {
                const name = attr.name.toLowerCase();

                if (name.startsWith("on") || (URL_ATTRIBUTES.has(name) && is_unsafe_url(attr.value))) {
                    element.removeAttribute(attr.name);
                }
            }
        }
    };

    clean_node(template.content);
    return template.innerHTML;
};

let command_buffer_ptr;
let command_count = 0;

function flush() {
    if (command_count <= 0) return;
    const count_to_flush = command_count;
    command_count = 0;
    instance.exports.wasm_handle_js_commands(count_to_flush);
}

const push_js_command = (type, handle, arg1 = 0, arg2 = 0, arg3 = 0, str_bytes = null) => {
    if (!instance || !memory) return;

    if (command_count >= MAX_JS_COMMANDS) {
        flush();
    }

    let str_ptr = 0n;
    let str_len = 0;

    if (str_bytes && str_bytes.length > 0) {
        str_len = str_bytes.length;
        const allocated_ptr = BigInt(instance.exports.wasm_push_string(str_len));
        if (allocated_ptr > 0n && Number(allocated_ptr) + str_len <= memory.buffer.byteLength) {
            str_ptr = allocated_ptr;
            const u8 = new Uint8Array(memory.buffer);
            u8.set(str_bytes, Number(str_ptr));
        } else {
            str_len = 0;
        }
    }

    command_buffer_ptr = Number(instance.exports.wasm_get_js_command_buffer_ptr());
    const offset = command_buffer_ptr + command_count * JS_COMMAND_SIZE;
    if (command_buffer_ptr <= 0 || offset + JS_COMMAND_SIZE > memory.buffer.byteLength) {
        console.error("[wasm] Invalid js_command_buffer pointer or bounds");
        return;
    }

    const view = new DataView(memory.buffer, offset, JS_COMMAND_SIZE);

    view.setUint32(0, type, true);
    view.setUint32(4, handle, true);
    view.setFloat32(8, Number(arg1), true);
    view.setFloat32(12, Number(arg2), true);
    view.setFloat32(16, Number(arg3), true);
    view.setBigInt64(24, BigInt(str_ptr), true);
    view.setBigInt64(32, BigInt(str_len), true);

    command_count++;
    flush();
};

const exported_js_functions = {
    wasm_write_string: (s_count, s_data, to_standard_error) => {
        const s = js_string_from_jai_string(s_data, s_count);
        write_to_console_log(s, to_standard_error);
    },

    wasm_get_elements_by_name: (name_ptr, name_length, handles_out_ptr, max_handles, start_handle) => {
        const name = js_string_from_jai_string(name_ptr, name_length);
        const elements = document.getElementsByName(name);
        const count = elements.length;

        const outPtr = Number(handles_out_ptr);
        if (!outPtr || Number(max_handles) <= 0) {
            return count;
        }

        const n = Math.min(count, Number(max_handles));
        if (outPtr < 0 || outPtr + n * 4 > memory.buffer.byteLength) {
            console.error("[wasm] Out-of-bounds buffer in wasm_get_elements_by_name");
            return 0;
        }

        const view = new DataView(memory.buffer, outPtr, n * 4);
        const baseHandle = Number(start_handle);

        for (let i = 0; i < n; i++) {
            const handle = baseHandle + i;
            view.setInt32(i * 4, handle, true);
            node_set(handle, elements[i]);
        }

        return n;
    },

    wasm_fetch: (id, url_ptr, url_len, method_ptr, method_len, headers_ptr, headers_len, body_ptr, body_len, response_type) => {
        const url = js_string_from_jai_string(url_ptr, url_len);
        const method = method_len > 0 ? js_string_from_jai_string(method_ptr, method_len) : "GET";
        const headers_str = headers_len > 0 ? js_string_from_jai_string(headers_ptr, headers_len) : "";

        const headers = {};
        if (headers_str) {
            for (const line of headers_str.split("\n")) {
                const trimmed = line.trim();
                if (!trimmed) continue;
                const colon = trimmed.indexOf(":");
                if (colon !== -1) {
                    const key = trimmed.slice(0, colon).trim();
                    const val = trimmed.slice(colon + 1).trim();
                    if (key && !/[\r\n]/.test(key) && !/[\r\n]/.test(val)) {
                        headers[key] = val;
                    }
                }
            }
        }

        const init = { method };
        if (Object.keys(headers).length > 0) {
            init.headers = headers;
        }

        const bPtr = Number(body_ptr);
        const bLen = Number(body_len);
        if (bLen > 0 && bPtr > 0 && bPtr + bLen <= memory.buffer.byteLength) {
            const u8 = new Uint8Array(memory.buffer);
            init.body = u8.slice(bPtr, bPtr + bLen);
        }

        fetch(url, init)
            .then(async (response) => {
                const status = response.status;
                const ok = response.ok ? 1 : 0;
                let bytes;

                if (Number(response_type) === 1) { // BLOB
                    const blob = await response.blob();
                    const ab = await blob.arrayBuffer();
                    bytes = new Uint8Array(ab);
                } else { // TEXT
                    const text = await response.text();
                    bytes = text_encoder.encode(text);
                }

                push_js_command(JS_COMMAND_FETCH_RESPONSE, Number(id), status, ok, Number(response_type), bytes);
            })
            .catch((err) => {
                const errMsg = err ? (err.message || String(err)) : "Fetch error";
                const bytes = text_encoder.encode(errMsg);
                push_js_command(JS_COMMAND_FETCH_RESPONSE, Number(id), 0, 0, Number(response_type), bytes);
            });
    },

    wasm_websocket_connect: (handle, url_ptr, url_len, protocols_ptr, protocols_len, binary_type) => {
        const url = js_string_from_jai_string(url_ptr, url_len);
        const protocols = protocols_len > 0 ? js_string_from_jai_string(protocols_ptr, protocols_len) : undefined;
        const protoList = protocols ? protocols.split(",").map(s => s.trim()) : undefined;

        let ws;
        try {
            ws = protoList ? new WebSocket(url, protoList) : new WebSocket(url);
        } catch (e) {
            const errMsg = e ? (e.message || String(e)) : "WebSocket constructor error";
            const bytes = text_encoder.encode(errMsg);
            push_js_command(JS_COMMAND_WEBSOCKET_ERROR, Number(handle), 0, 0, 0, bytes);
            return;
        }

        ws.binaryType = (Number(binary_type) === 0) ? "blob" : "arraybuffer";
        socket_table.set(Number(handle), ws);

        ws.onopen = () => {
            push_js_command(JS_COMMAND_WEBSOCKET_OPEN, Number(handle));
        };

        ws.onmessage = async (event) => {
            let isBlob = 0;
            let bytes;

            if (typeof event.data === "string") {
                bytes = text_encoder.encode(event.data);
                isBlob = 0;
            } else if (event.data instanceof Blob) {
                const ab = await event.data.arrayBuffer();
                bytes = new Uint8Array(ab);
                isBlob = 1;
            } else if (event.data instanceof ArrayBuffer) {
                bytes = new Uint8Array(event.data);
                isBlob = 1;
            } else {
                bytes = new Uint8Array(0);
            }

            push_js_command(JS_COMMAND_WEBSOCKET_MESSAGE, Number(handle), isBlob, 0, 0, bytes);
        };

        ws.onerror = (event) => {
            const errMsg = "WebSocket error";
            const bytes = text_encoder.encode(errMsg);
            push_js_command(JS_COMMAND_WEBSOCKET_ERROR, Number(handle), 0, 0, 0, bytes);
        };

        ws.onclose = (event) => {
            const reasonBytes = text_encoder.encode(event.reason || "");
            push_js_command(JS_COMMAND_WEBSOCKET_CLOSE, Number(handle), event.code, event.wasClean ? 1 : 0, 0, reasonBytes);
            socket_table.delete(Number(handle));
        };
    },

    wasm_websocket_send_text: (handle, data_ptr, data_len) => {
        const ws = socket_table.get(Number(handle));
        if (ws && ws.readyState === WebSocket.OPEN) {
            ws.send(js_string_from_jai_string(data_ptr, data_len));
        } else {
            console.warn(`[websocket] send_text failed: socket ${handle} is not open`);
        }
    },

    wasm_websocket_send_binary: (handle, data_ptr, data_len) => {
        const ws = socket_table.get(Number(handle));
        if (ws && ws.readyState === WebSocket.OPEN) {
            const ptr = Number(data_ptr);
            const len = Number(data_len);
            if (len >= 0 && ptr > 0 && ptr + len <= memory.buffer.byteLength) {
                const u8 = new Uint8Array(memory.buffer);
                const slice = u8.slice(ptr, ptr + len);
                ws.send(slice.buffer);
            }
        } else {
            console.warn(`[websocket] send_binary failed: socket ${handle} is not open`);
        }
    },

    wasm_websocket_close: (handle, code, reason_ptr, reason_len) => {
        const ws = socket_table.get(Number(handle));
        if (ws) {
            const reason = reason_len > 0 ? js_string_from_jai_string(reason_ptr, reason_len) : undefined;
            ws.close(Number(code), reason);
            socket_table.delete(Number(handle));
        }
    },

    wasm_websocket_get_state: (handle) => {
        const ws = socket_table.get(Number(handle));
        return ws ? ws.readyState : 3; // 3 = CLOSED
    },

    wasm_debug_break: () => {
        debugger;
    },

    wasm_send_command_buffer_to_js: (data, count, size) => {
        const commandCount = Number(count);
        const commandSize  = Number(size);
        const dataOffset   = Number(data);

        if (commandCount <= 0 || commandSize < WASM_COMMAND_SIZE) return;
        if (dataOffset <= 0 || dataOffset + commandCount * commandSize > memory.buffer.byteLength) {
            console.error("[wasm] Invalid command buffer range");
            return;
        }

        const view = new DataView(memory.buffer, dataOffset, commandCount * commandSize);

        for (let i = 0; i < commandCount; i++) {
            const base = i * commandSize;

            // @Todo: Generate this at compile time to get the offsets right.
            const type   = view.getUint32(base + COMMAND_OFFSET_TYPE,   true);
            const handle = view.getUint32(base + COMMAND_OFFSET_HANDLE, true);
            const arg1   = view.getUint32(base + COMMAND_OFFSET_ARG1,   true);
            const ptr    = view.getBigUint64(base + COMMAND_OFFSET_DATA,  true);
            const length = view.getBigInt64(base + COMMAND_OFFSET_COUNT, true);

            const extra_ptr    = view.getBigUint64(base + COMMAND_OFFSET_EXTRA,       true);
            const extra_length = view.getBigInt64(base + COMMAND_OFFSET_EXTRA_COUNT, true);

            switch (type) {
                case COMMAND_CONSOLE_LOG:
                    command_console_log(ptr, length);
                    break;

                case COMMAND_CONSOLE_ERROR:
                    command_console_error(ptr, length);
                    break;

                case COMMAND_DOM_GET_ELEMENT_BY_ID: {
                    const id = js_string_from_jai_string(ptr, length);
                    const element = document.getElementById(id);

                    if (!element) {
                        console.warn(`[dom] getElementById("${id}") returned null`);
                    }

                    node_set(handle, element);
                    break;
                }

                case COMMAND_DOM_CREATE_ELEMENT: {
                    const tag = js_string_from_jai_string(ptr, length).toLowerCase();
                    if (BLOCKED_TAGS.has(tag)) {
                        console.error(`[security] Blocked creation of <${tag}> element`);
                        break;
                    }
                    node_set(handle, document.createElement(tag));
                    break;
                }

                case COMMAND_DOM_APPEND_CHILD: {
                    const parent = node_get(handle);
                    const child = node_get(arg1);
                    if (parent && child) parent.appendChild(child);
                    break;
                }

                case COMMAND_DOM_REMOVE_CHILD: {
                    const parent = node_get(handle);
                    const child = node_get(arg1);
                    if (parent && child) parent.removeChild(child);
                    break;
                }

                case COMMAND_DOM_REMOVE: {
                    const element = node_get(handle);
                    if (element) element.remove();
                    break;
                }

                case COMMAND_DOM_SET_TEXT_CONTENT: {
                    const element = node_get(handle);
                    if (element) element.textContent = js_string_from_jai_string(ptr, length);
                    break;
                }

                case COMMAND_DOM_SET_INNER_HTML: {
                    const element = node_get(handle);
                    if (element) {
                        const rawHtml = js_string_from_jai_string(ptr, length);
                        element.innerHTML = sanitize_html(rawHtml);
                    }
                    break;
                }

                case COMMAND_DOM_SET_ATTRIBUTE: {
                    const element = node_get(handle);
                    if (!element) break;

                    const name  = js_string_from_jai_string(ptr, length);
                    const value = js_string_from_jai_string(extra_ptr, extra_length);
                    const lowerName = name.toLowerCase().trim();

                    if (lowerName.startsWith("on")) {
                        console.error(`[security] Blocked inline event handler attribute: ${name}`);
                        break;
                    }
                    if (URL_ATTRIBUTES.has(lowerName) && is_unsafe_url(value)) {
                        console.error(`[security] Blocked unsafe URL in attribute ${name}`);
                        break;
                    }

                    if (name === "value") {
                        element.value = value;
                    }
                    element.setAttribute(name, value);
                    break;
                }

                case COMMAND_DOM_REMOVE_ATTRIBUTE: {
                    const element = node_get(handle);
                    if (element) element.removeAttribute(js_string_from_jai_string(ptr, length));
                    break;
                }

                case COMMAND_DOM_ADD_CLASS: {
                    const element = node_get(handle);
                    if (element) element.classList.add(js_string_from_jai_string(ptr, length));
                    break;
                }

                case COMMAND_DOM_REMOVE_CLASS: {
                    const element = node_get(handle);
                    if (element) element.classList.remove(js_string_from_jai_string(ptr, length));
                    break;
                }

                case COMMAND_DOM_TOGGLE_CLASS: {
                    const element = node_get(handle);
                    if (element) element.classList.toggle(js_string_from_jai_string(ptr, length));
                    break;
                }

                case COMMAND_DOM_SET_STYLE: {
                    const element = node_get(handle);
                    if (!element) break;
                    const property = js_string_from_jai_string(ptr, length);
                    const value    = js_string_from_jai_string(extra_ptr, extra_length);
                    element.style[property] = value;
                    break;
                }

                case COMMAND_DOM_ADD_EVENT_LISTENER: {
                    const element = node_get(handle);
                    if (!element) break;

                    const event_type = js_string_from_jai_string(ptr, length);
                    let element_events = registered_listeners.get(element);
                    if (!element_events) {
                        element_events = new Set();
                        registered_listeners.set(element, element_events);
                    }
                    if (element_events.has(event_type)) {
                        break;
                    }
                    element_events.add(event_type);

                    element.addEventListener(event_type, (event) => {
                        let text_bytes = null;
                        if (event.target && event.target.value !== undefined) {
                            text_bytes = text_encoder.encode(String(event.target.value));
                        }

                        push_js_command(
                            JS_COMMAND_DOM_EVENT,
                            handle,
                            event.clientX || 0,
                            event.clientY || 0,
                            0,
                            text_bytes
                        );
                    });

                    break;
                }

                case COMMAND_DOM_RELEASE:
                    node_table.delete(handle);
                    break;

                case COMMAND_DOM_CREATE_TEXT_NODE: {
                    const text = js_string_from_jai_string(ptr, length);
                    node_set(handle, document.createTextNode(text));
                    break;
                }

                case COMMAND_DOM_INSERT_BEFORE: {
                    const parent = node_get(handle);
                    const child = node_get(arg1);
                    const before = node_get(view.getUint32(base + COMMAND_OFFSET_ARG2, true));
                    if (parent && child) parent.insertBefore(child, before || null);
                    break;
                }

                default:
                    console.warn(`[wasm_send_command_buffer_to_js] unknown command type ${type}`);
                    break;
            }
        }
    },

    memcmp: (ptr1, ptr2, length) => {
        const p1  = Number(ptr1);
        const p2  = Number(ptr2);
        const len = Number(length);
        const bytes = new Uint8Array(memory.buffer);

        if (len <= 0) return 0;
        if (p1 < 0 || p2 < 0 || p1 + len > bytes.byteLength || p2 + len > bytes.byteLength) {
            return -1;
        }

        for (let i = 0; i < len; i++) {
            const diff = bytes[p1 + i] - bytes[p2 + i];
            if (diff !== 0) return diff;
        }

        return 0;
    }
};

const imports = {
    env: new Proxy(exported_js_functions, {
        get(target, prop, receiver) {
            if (target.hasOwnProperty(prop)) {
                return target[prop];
            }

            return () => { throw new Error("Missing function: " + prop); };
        }
    }),
};

WebAssembly.instantiateStreaming(fetch("main.wasm"), imports)
    .then((obj) => {
        instance = obj.instance;
        memory   = instance.exports.memory;

        command_buffer_ptr = Number(instance.exports.wasm_get_js_command_buffer_ptr());

        instance.exports.main(0, BigInt(0));
    });

const text_decoder = new TextDecoder();
const text_encoder = new TextEncoder();

const js_string_from_jai_string = (pointer, length) => {
    const ptr = Number(pointer);
    const len = Number(length);
    if (len <= 0 || ptr <= 0 || ptr + len > memory.buffer.byteLength) {
        return "";
    }
    const u8 = new Uint8Array(memory.buffer);
    const bytes = u8.subarray(ptr, ptr + len);
    return text_decoder.decode(bytes);
};

let console_buffer = "";
let console_buffer_is_standard_error = false;

const write_to_console_log = (s, to_standard_error) => {
    if (console_buffer && console_buffer_is_standard_error !== to_standard_error) {
        flush_buffer();
    }

    console_buffer_is_standard_error = to_standard_error;

    console_buffer += s;

    let newlineIndex;

    while ((newlineIndex = console_buffer.indexOf("\n")) !== -1) {
        const line = console_buffer.slice(0, newlineIndex);

        if (console_buffer_is_standard_error) {
            console.error(line);
        } else {
            console.log(line);
        }

        console_buffer = console_buffer.slice(newlineIndex + 1);
    }
};


const flush_buffer = () => {
    if (!console_buffer) return;

    if (console_buffer_is_standard_error) {
        console.error(console_buffer);
    } else {
        console.log(console_buffer);
    }

    console_buffer = "";
};

const command_console_log = (data, length) => {
    let s = js_string_from_jai_string(data, length);

    if (!s.endsWith("\n")) {
        s += "\n";
    }

    write_to_console_log(s, false);
};

const command_console_error = (data, length) => {
    let s = js_string_from_jai_string(data, length);

    if (!s.endsWith("\n")) {
        s += "\n";
    }

    write_to_console_log(s, true);
};

window.addEventListener("mousedown", (event) => {
    if (!instance) return;

    push_js_command(
        JS_COMMAND_MOUSE_DOWN,
        0,
        event.clientX,
        event.clientY,
        event.button,
        null
    );
});
