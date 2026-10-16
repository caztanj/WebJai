padding_bottom :: (css: Length) -> Declaration {
    return .{ property = "padding-bottom", value = to_string(css) };
}