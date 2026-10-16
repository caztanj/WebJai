border_bottom :: (value: string) -> Declaration {
    return .{ property = "border-bottom", value = value };
}

border_bottom :: (line_width: Line_Width) -> Declaration {
    return .{ property = "border-bottom", value = to_string(line_width) };
}

border_bottom :: (line_style: Line_Style) -> Declaration {
    return .{ property = "border-bottom", value = to_string(line_style) };
}

border_bottom :: (color: Color) -> Declaration {
    return .{ property = "border-bottom", value = color };
}

border_bottom :: (line_width: Line_Width, line_style: Line_Style) -> Declaration {
    return .{ property = "border", value = tprint("% %", to_string(line_width), to_string(line_style)) };
}

border_bottom :: (line_width: Line_Width, color: Color) -> Declaration {
    return .{ property = "border", value = tprint("% %", to_string(line_width), color) };
}

border_bottom :: (line_style: Line_Style, color: Color) -> Declaration {
    return .{ property = "border", value = tprint("% %", to_string(line_style), color) };
}

border_bottom :: (line_width: Length) -> Declaration {
    return .{ property = "border", value = to_string(line_width) };
}

border_bottom :: (line_width: Length, line_style: Line_Style) -> Declaration {
    return .{ property = "border", value = tprint("% %", to_string(line_width), to_string(line_style)) };
}

border_bottom :: (line_width: Length, line_style: Line_Style, color: Color) -> Declaration {
    return .{ propery = "border", value = tprint("% % %", to_string(line_width), to_string(line_style), color) };
}