margin_bottom :: (css: Length) -> Declaration {
    return .{ property = "margin-bottom", value = to_string(css) };
}