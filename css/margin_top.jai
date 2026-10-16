margin_top :: (css: Length) -> Declaration {
    return .{ property = "margin-top", value = to_string(css) };
}