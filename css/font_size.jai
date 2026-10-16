font_size :: (css: Length) -> Declaration {
    return .{ property = "font-size", value = to_string(css) };
}