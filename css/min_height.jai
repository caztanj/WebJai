min_height :: (css: Length) -> Declaration {
    return .{ property = "min-height", value = to_string(css) };
}