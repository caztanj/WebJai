to_string :: (value: Align_Items) -> string {
    if #complete value == {
        case .UNDEFINED;      return "";
        case .NORMAL;         return "normal";
        case .STRETCH;        return "stretch";
        case .CENTER;         return "center";
        case .START;          return "start";
        case .END;            return "end";
        case .FLEX_START;     return "flex-start";
        case .FLEX_END;       return "flex-end";
        case .SELF_START;     return "self-start";
        case .SELF_END;       return "self-end";
        case .ANCHOR_CENTER;  return "achor-center";
        case .BASELINE;       return "baseline";
        case .FIRST_BASELINE; return "first baseline";
        case .LAST_BASELINE;  return "last baseline";
        case .SAFE_CENTER;    return "safe center";
        case .UNSAFE_CENTER;  return "unsafe center";
        case .INHERIT;        return "inherit";
        case .INITIAL;        return "initial";
        case .REVERT;         return "revert";
        case .REVERT_LAYER;   return "revert-layer";
        case .UNSET;          return "unset";
    }
}

align_items :: (value: Align_Items) -> Declaration {
    return .{ property = "align-items", value = to_string(value) };
}

Align_Items :: enum {
    UNDEFINED;
    NORMAL;
    STRETCH;
    CENTER;
    START;
    END;
    FLEX_START;
    FLEX_END;
    SELF_START;
    SELF_END;
    ANCHOR_CENTER;
    BASELINE;
    FIRST_BASELINE;
    LAST_BASELINE;
    SAFE_CENTER;
    UNSAFE_CENTER;
    INHERIT;
    INITIAL;
    REVERT;
    REVERT_LAYER;
    UNSET;
}