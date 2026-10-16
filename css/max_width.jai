max_width :: (css: Length) -> Declaration {
    return .{ property = "max-width", value = to_string(css) };
}