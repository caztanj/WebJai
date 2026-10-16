# WebJai

A web frontend framework written in Jai targeting WebAssembly.

It includes a virtual DOM UI library, compile-time CSS generation, and bindings for many Web APIs.

Examples can be found in the `examples` folder.

## Building

To build the todo example in `examples/todo`, run `jai first.jai` (or `jai first.jai - release` for a release build).

This outputs `main.wasm`, `style.css`, and `runtime.js` to `examples/todo/public`, which can then be served with any HTTP server.
