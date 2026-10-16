border_radius :: (css: Length) -> Declaration {
    return .{ property = "border-radius", value = to_string(css) };
}

border_radius :: (value: string) -> Declaration {
    return .{ property = "border-radius", value = value };
}

border_radius :: (top_left: Length, top_right: Length, bottom_right: Length, bottom_left: Length) -> Declaration {
    return .{ property = "border-radius", value = tprint("% % % %", to_string(top_left), to_string(top_right), to_string(bottom_right), to_string(bottom_left)) };
}