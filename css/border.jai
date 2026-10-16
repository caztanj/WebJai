border :: (value: string) -> Declaration {
    return .{ property = "border", value = value };
}

border :: (line_width: Line_Width) -> Declaration {
    return .{ property = "border", value = to_string(line_width) };
}

border :: (line_style: Line_Style) -> Declaration {
    return .{ property = "border", value = to_string(line_style) };
}

border :: (color: Color) -> Declaration {
    return .{ property = "border", value = color };
}

border :: (line_width: Line_Width, line_style: Line_Style) -> Declaration {
    return .{ property = "border", value = tprint("% %", to_string(line_width), to_string(line_style)) };
}

border :: (line_width: Line_Width, color: Color) -> Declaration {
    return .{ property = "border", value = tprint("% %", to_string(line_width), color) };
}

border :: (line_style: Line_Style, color: Color) -> Declaration {
    return .{ property = "border", value = tprint("% %", to_string(line_style), color) };
}

border :: (line_width: Length) -> Declaration {
    return .{ property = "border", value = to_string(line_width) };
}

border :: (line_width: Length, line_style: Line_Style) -> Declaration {
    return .{ property = "border", value = tprint("% %", to_string(line_width), to_string(line_style)) };
}

border :: (line_width: Length, line_style: Line_Style, color: Color) -> Declaration {
    return .{ propery = "border", value = tprint("% % %", to_string(line_width), to_string(line_style), color) };
}

to_string :: (value: Line_Style) -> string {
    if #complete value == {
        case .NONE;   return "none";
        case .HIDDEN; return "hidden";
        case .DOTTED; return "dotted";
        case .DASHED; return "dashed";
        case .SOLID;  return "solid";
        case .DOUBLE; return "double";
        case .GROOVE; return "groove";
        case .RIDGE;  return "ridge";
        case .INSET;  return "inset";
        case .OUTSET; return "outset";
    }
}

to_string :: (value: Line_Width) -> string {
    if #complete value == {
        case .HAIRLINE; return "hairline";
        case .THIN;     return "thin";
        case .MEDIUM;   return "medium";
        case .THICK;    return "thick";
    }
}

Line_Width :: enum {
    HAIRLINE;
    THIN;
    MEDIUM;
    THICK;
}

Line_Style :: enum {
    NONE;
    HIDDEN;
    DOTTED;
    DASHED;
    SOLID;
    DOUBLE;
    GROOVE;
    RIDGE;
    INSET;
    OUTSET;
}