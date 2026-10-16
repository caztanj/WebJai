max_height :: (css: Length) -> Declaration {
    return .{ property = "max-height", value = to_string(css) };
}