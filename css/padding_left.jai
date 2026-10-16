padding_left :: (css: Length) -> Declaration {
    return .{ property = "padding-left", value = to_string(css) };
}