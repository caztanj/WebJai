height :: (css: Length) -> Declaration {
    return .{ property = "height", value = to_string(css) };
}