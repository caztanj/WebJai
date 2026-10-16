padding :: (css: Length) -> Declaration {
    return .{ property = "padding", value = to_string(css) };
}

padding :: (vertical: Length, horizontal: Length) -> Declaration {
    return .{ property = "padding", value = tprint("% %", to_string(vertical), to_string(horizontal)) };
}