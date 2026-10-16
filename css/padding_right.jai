padding_right :: (css: Length) -> Declaration {
    return .{ property = "padding-right", value = to_string(css) };
}