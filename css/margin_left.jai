margin_left :: (css: Length) -> Declaration {
    return .{ property = "margin-left", value = to_string(css) };
}