min_width :: (css: Length) -> Declaration {
    return .{ property = "min-width", value = to_string(css) };
}