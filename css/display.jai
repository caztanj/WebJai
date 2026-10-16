to_string :: (display: Display) -> string {
    if #complete display == {
        case .UNDEFINED;             return "";
        case .NONE;                  return "none";
        case .CONTENTS;              return "contents";
        case .BLOCK;                 return "block";
        case .FLOW_ROOT;             return "flow-root";
        case .INLINE;                return "inline";
        case .INLINE_BLOCK;          return "inline-block";
        case .LIST_ITEM;             return "list-item";
        case .INLINE_LIST_ITEM;      return "inline list-item";
        case .FLEX;                  return "flex";
        case .INLINE_FLEX;           return "inline-flex";
        case .GRID;                  return "grid";
        case .INLINE_GRID;           return "inline-grid";
        case .GRID_LANES;            return "grid-lanes";
        case .INLINE_GRID_LANES;     return "inline-grid-lanes";
        case .TABLE;                 return "table";
        case .INLINE_TABLE;          return "inline-table";
        case .INHERIT;               return "inherit";
        case .INITIAL;               return "initial";
        case .REVERT;                return "revert";
        case .REVERT_LAYER;          return "revert-layer";
        case .UNSET;                 return "unset";
    }
}

display :: (css: Display) -> Declaration {
    return .{ property = "display", value = to_string(css) };
}

Display :: enum {
    UNDEFINED;
    NONE;
    CONTENTS;
    BLOCK;
    FLOW_ROOT;
    INLINE;
    INLINE_BLOCK;
    LIST_ITEM;
    INLINE_LIST_ITEM;
    FLEX;
    INLINE_FLEX;
    GRID;
    INLINE_GRID;
    GRID_LANES;
    INLINE_GRID_LANES;
    TABLE;
    INLINE_TABLE;
    INHERIT;
    INITIAL;
    REVERT;
    REVERT_LAYER;
    UNSET;
}