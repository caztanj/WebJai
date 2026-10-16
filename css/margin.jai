margin :: (css: Length) -> Declaration {
    return .{ property = "margin", value = to_string(css) };
}

margin :: (vertical: Length, horizontal: Length) -> Declaration {
    return .{ property = "margin", value = tprint("% %", to_string(vertical), to_string(horizontal)) };
}