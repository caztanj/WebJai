to_string :: (value: Justify_Content) -> string {
    if #complete value == {
        case .NONE;          return "";
        case .CENTER;        return "center";
        case .START;         return "start";
        case .END;           return "end";
        case .FLEX_START;    return "flex-start";
        case .FLEX_END;      return "flex-end";
        case .LEFT;          return "left";
        case .RIGHT;         return "right";
        case .NORMAL;        return "normal";
        case .SPACE_BETWEEN; return "space-between";
        case .SPACE_AROUND;  return "space-around";
        case .SPACE_EVENLY;  return "space-evenly";
        case .STRETCH;       return "stretch";
        case .SAFE_CENTER;   return "safe center";
        case .UNSAFE_CENTER; return "unsafe center";
        case .INHERIT;       return "inherit";
        case .INITIAL;       return "initial";
        case .REVERT;        return "revert";
        case .REVERT_LAYER;  return "revert-layer";
        case .UNSET;         return "unset";
    }
}

justify_content :: (value: Justify_Content) -> Declaration {
    return .{ property = "justify-content", value = to_string(value) };
}

Justify_Content :: enum {
    NONE;
    CENTER;
    START;
    END;
    FLEX_START;
    FLEX_END;
    LEFT;
    RIGHT;
    NORMAL;
    SPACE_BETWEEN;
    SPACE_AROUND;
    SPACE_EVENLY;
    STRETCH;
    SAFE_CENTER;
    UNSAFE_CENTER;
    INHERIT;
    INITIAL;
    REVERT;
    REVERT_LAYER;
    UNSET;
}