to_string :: (value: Width) -> string {
    if #complete value == {
        case .UNDEFINED;    return "";
        case .AUTO;         return "auto";
        case .MAX_CONTENT;  return "max-content";
        case .MIN_CONTENT;  return "min-content";
        case .FIT_CONTENT;  return "fit-content";
        case .STRETCH;      return "stretch";
        case .CONTAIN;      return "contain";
        case .INHERIT;      return "inherit";
        case .INITIAL;      return "initial";
        case .REVERT;       return "revert";
        case .REVERT_LAYER; return "revert-layer";
        case .UNSET;        return "unset";
    }
}

to_string :: (value: Anchor_Size) -> string {
    if #complete value == {
        case .UNDEFINED;   return "";
        case .WIDTH;       return "width";
        case .HEIGHT;      return "height";
        case .BLOCK;       return "block";
        case .INLINE;      return "inline";
        case .SELF_BLOCK;  return "self-block";
        case .SELF_INLINE; return "self-inline";
    }
}

anchor_size :: (size: Anchor_Size) -> Anchor_Size_Value {
    return cast(Anchor_Size_Value) tprint("anchor-size(%)", to_string(size));
}

anchor_size :: (size: Anchor_Size, fallback: Length) -> Anchor_Size_Value {
    return cast(Anchor_Size_Value) tprint("anchor-size(%, %)", to_string(size), to_string(fallback));
}

anchor_size :: (anchor_name: string, size: Anchor_Size = .UNDEFINED) -> Anchor_Size_Value {
    norm_name := ifx begins_with(anchor_name, "--") then anchor_name else tprint("--%", anchor_name);

    if size == .UNDEFINED {
        return cast(Anchor_Size_Value) tprint("anchor-size(%)", norm_name);
    }

    return cast(Anchor_Size_Value) tprint("anchor-size(% %)", norm_name, to_string(size));
}

anchor_size :: (anchor_name: string, size: Anchor_Size, fallback: Length) -> Anchor_Size_Value {
    norm_name := ifx begins_with(anchor_name, "--") then anchor_name else tprint("--%", anchor_name);

    if size == .UNDEFINED {
        return cast(Anchor_Size_Value) tprint("anchor-size(%, %)", norm_name, to_string(fallback));
    }

    return cast(Anchor_Size_Value) tprint("anchor-size(% %, %)", norm_name, to_string(size), to_string(fallback));
}

width :: (css: Length) -> Declaration {
    return .{ property = "width", value = to_string(css) };
}

width :: (value: Width) -> Declaration {
    return .{ property = "width", value = to_string(value) };
}

width :: (keyword: Width, value: Length) -> Declaration {
    assert(keyword == .FIT_CONTENT, "Only .FIT_CONTENT takes a Length argument in width(Width, Length)");

    return .{ property = "width", value = tprint("fit-content(%)", to_string(value)) };
}

width :: (value: Fit_Content) -> Declaration {
    return .{ property = "width", value = cast(string) value };
}

width :: (value: Anchor_Size_Value) -> Declaration {
    return .{ property = "width", value = cast(string) value };
}

width :: (value: Css_Math) -> Declaration {
    return .{ property = "width", value = cast(string) value };
}

width :: (value: Css_Var) -> Declaration {
    return .{ property = "width", value = cast(string) value };
}

width :: (value: string) -> Declaration {
    return .{ property = "width", value = value };
}

Width :: enum {
    UNDEFINED;
    AUTO;
    MAX_CONTENT;
    MIN_CONTENT;
    FIT_CONTENT;
    STRETCH;
    CONTAIN;
    INHERIT;
    INITIAL;
    REVERT;
    REVERT_LAYER;
    UNSET;
}

Anchor_Size :: enum {
    UNDEFINED;
    WIDTH;
    HEIGHT;
    BLOCK;
    INLINE;
    SELF_BLOCK;
    SELF_INLINE;
}
