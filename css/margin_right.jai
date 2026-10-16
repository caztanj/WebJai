margin_right :: (css: Length) -> Declaration {
    return .{ property = "margin-right", value = to_string(css) };
}