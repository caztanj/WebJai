flex_grow :: (value: float) -> Declaration {
    return .{ property = "flex-grow", value = tprint("%", value) };
}