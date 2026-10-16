to_string :: (unit: Length_Unit) -> string {
    if #complete unit == {
        case .NONE;    return "";
        case .PX;      return "px";
        case .CM;      return "cm";
        case .MM;      return "mm";
        case .Q;       return "Q";
        case .IN;      return "in";
        case .PC;      return "pc";
        case .PT;      return "pt";
        case .EM;      return "em";
        case .REM;     return "rem";
        case .EX;      return "ex";
        case .REX;     return "rex";
        case .CAP;     return "cap";
        case .RCAP;    return "rcap";
        case .CH;      return "ch";
        case .RCH;     return "rch";
        case .IC;      return "ic";
        case .RIC;     return "ric";
        case .LH;      return "lh";
        case .RLH;     return "rlh";
        case .PERCENT; return "%";
        case .VW;      return "vw";
        case .VH;      return "vh";
        case .VI;      return "vi";
        case .VB;      return "vb";
        case .VMIN;    return "vmin";
        case .VMAX;    return "vmax";
        case .SVW;     return "svw";
        case .SVH;     return "svh";
        case .SVI;     return "svi";
        case .SVB;     return "svb";
        case .SVMIN;   return "svmin";
        case .SVMAX;   return "svmax";
        case .LVW;     return "lvw";
        case .LVH;     return "lvh";
        case .LVI;     return "lvi";
        case .LVB;     return "lvb";
        case .LVMIN;   return "lvmin";
        case .LVMAX;   return "lvmax";
        case .DVW;     return "dvw";
        case .DVH;     return "dvh";
        case .DVI;     return "dvi";
        case .DVB;     return "dvb";
        case .DVMIN;   return "dvmin";
        case .DVMAX;   return "dvmax";
        case .CQW;     return "cqw";
        case .CQH;     return "cqh";
        case .CQI;     return "cqi";
        case .CQB;     return "cqb";
        case .CQMIN;   return "cqmin";
        case .CQMAX;   return "cqmax";
    }
}

to_string :: (css: Length) -> string {
    if cast(float) (cast(s64) css.value) == css.value {
        return tprint("%1%2", cast(s64) css.value, to_string(css.unit));
    }

    return tprint("%1%2", css.value, to_string(css.unit));
}

px :: (value: float) -> Length {
    return .{ value = value, unit = .PX };
}

cm :: (value: float) -> Length {
    return .{ value = value, unit = .CM };
}

mm :: (value: float) -> Length {
    return .{ value = value, unit = .MM };
}

q :: (value: float) -> Length {
    return .{ value = value, unit = .Q };
}

in :: (value: float) -> Length {
    return .{ value = value, unit = .IN };
}

pc :: (value: float) -> Length {
    return .{ value = value, unit = .PC };
}

pt :: (value: float) -> Length {
    return .{ value = value, unit = .PT };
}

em :: (value: float) -> Length {
    return .{ value = value, unit = .EM };
}

rem :: (value: float) -> Length {
    return .{ value = value, unit = .REM };
}

ex :: (value: float) -> Length {
    return .{ value = value, unit = .EX };
}

rex :: (value: float) -> Length {
    return .{ value = value, unit = .REX };
}

cap :: (value: float) -> Length {
    return .{ value = value, unit = .CAP };
}

rcap :: (value: float) -> Length {
    return .{ value = value, unit = .RCAP };
}

ch :: (value: float) -> Length {
    return .{ value = value, unit = .CH };
}

rch :: (value: float) -> Length {
    return .{ value = value, unit = .RCH };
}

ic :: (value: float) -> Length {
    return .{ value = value, unit = .IC };
}

ric :: (value: float) -> Length {
    return .{ value = value, unit = .RIC };
}

lh :: (value: float) -> Length {
    return .{ value = value, unit = .LH };
}

rlh :: (value: float) -> Length {
    return .{ value = value, unit = .RLH };
}

percent :: (value: float) -> Length {
    return .{ value = value, unit = .PERCENT };
}

vw :: (value: float) -> Length {
    return .{ value = value, unit = .VW };
}

vh :: (value: float) -> Length {
    return .{ value = value, unit = .VH };
}

vi :: (value: float) -> Length {
    return .{ value = value, unit = .VI };
}

vb :: (value: float) -> Length {
    return .{ value = value, unit = .VB };
}

vmin :: (value: float) -> Length {
    return .{ value = value, unit = .VMIN };
}

vmax :: (value: float) -> Length {
    return .{ value = value, unit = .VMAX };
}

svw :: (value: float) -> Length {
    return .{ value = value, unit = .SVW };
}

svh :: (value: float) -> Length {
    return .{ value = value, unit = .SVH };
}

svi :: (value: float) -> Length {
    return .{ value = value, unit = .SVI };
}

svb :: (value: float) -> Length {
    return .{ value = value, unit = .SVB };
}

svmin :: (value: float) -> Length {
    return .{ value = value, unit = .SVMIN };
}

svmax :: (value: float) -> Length {
    return .{ value = value, unit = .SVMAX };
}

lvw :: (value: float) -> Length {
    return .{ value = value, unit = .LVW };
}

lvh :: (value: float) -> Length {
    return .{ value = value, unit = .LVH };
}

lvi :: (value: float) -> Length {
    return .{ value = value, unit = .LVI };
}

lvb :: (value: float) -> Length {
    return .{ value = value, unit = .LVB };
}

lvmin :: (value: float) -> Length {
    return .{ value = value, unit = .LVMIN };
}

lvmax :: (value: float) -> Length {
    return .{ value = value, unit = .LVMAX };
}

dvw :: (value: float) -> Length {
    return .{ value = value, unit = .DVW };
}

dvh :: (value: float) -> Length {
    return .{ value = value, unit = .DVH };
}

dvi :: (value: float) -> Length {
    return .{ value = value, unit = .DVI };
}

dvb :: (value: float) -> Length {
    return .{ value = value, unit = .DVB };
}

dvmin :: (value: float) -> Length {
    return .{ value = value, unit = .DVMIN };
}

dvmax :: (value: float) -> Length {
    return .{ value = value, unit = .DVMAX };
}

cqw :: (value: float) -> Length {
    return .{ value = value, unit = .CQW };
}

cqh :: (value: float) -> Length {
    return .{ value = value, unit = .CQH };
}

cqi :: (value: float) -> Length {
    return .{ value = value, unit = .CQI };
}

cqb :: (value: float) -> Length {
    return .{ value = value, unit = .CQB };
}

cqmin :: (value: float) -> Length {
    return .{ value = value, unit = .CQMIN };
}

cqmax :: (value: float) -> Length {
    return .{ value = value, unit = .CQMAX };
}

fit_content :: (value: Length) -> Fit_Content {
    return cast(Fit_Content) tprint("fit-content(%)", to_string(value));
}

calc :: (expression: string) -> Css_Math {
    return cast(Css_Math) tprint("calc(%)", expression);
}

css_min :: (values: ..Length) -> Css_Math {
    b: String_Builder;

    append(*b, "min(");

    for values {
        if it_index > 0 append(*b, ", ");
        append(*b, to_string(it));
    }

    append(*b, ")");

    return cast(Css_Math) builder_to_string(*b);
}

css_min :: (expressions: ..string) -> Css_Math {
    b: String_Builder;

    append(*b, "min(");

    for expressions {
        if it_index > 0 append(*b, ", ");
        append(*b, it);
    }

    append(*b, ")");

    return cast(Css_Math) builder_to_string(*b);
}

css_max :: (values: ..Length) -> Css_Math {
    b: String_Builder;

    append(*b, "max(");

    for values {
        if it_index > 0 append(*b, ", ");
        append(*b, to_string(it));
    }

    append(*b, ")");

    return cast(Css_Math) builder_to_string(*b);
}

css_max :: (expressions: ..string) -> Css_Math {
    b: String_Builder;

    append(*b, "max(");

    for expressions {
        if it_index > 0 append(*b, ", ");
        append(*b, it);
    }

    append(*b, ")");

    return cast(Css_Math) builder_to_string(*b);
}

clamp :: (min_val: Length, preferred_val: Length, max_val: Length) -> Css_Math {
    return cast(Css_Math) tprint("clamp(%, %, %)", to_string(min_val), to_string(preferred_val), to_string(max_val));
}

clamp :: (min_val: string, preferred_val: string, max_val: string) -> Css_Math {
    return cast(Css_Math) tprint("clamp(%, %, %)", min_val, preferred_val, max_val);
}

var :: (name: string) -> Css_Var {
    if begins_with(name, "--") return cast(Css_Var) tprint("var(%)", name);

    return cast(Css_Var) tprint("var(--%)", name);
}

var :: (name: string, fallback: Length) -> Css_Var {
    if begins_with(name, "--") return cast(Css_Var) tprint("var(%, %)", name, to_string(fallback));

    return cast(Css_Var) tprint("var(--%, %)", name, to_string(fallback));
}

var :: (name: string, fallback: string) -> Css_Var {
    if begins_with(name, "--") return cast(Css_Var) tprint("var(%, %)", name, fallback);

    return cast(Css_Var) tprint("var(--%, %)", name, fallback);
}

hex :: (value: string) -> Hex {
    return value;
}

rgb :: (r: int, g: int, b: int) -> Color {
    return tprint("rgb(% % %)", r, g, b);
}

rgba :: (r: int, g: int, b: int, a: int) -> Color {
    return tprint("rgba(% % % %)", r, g, b, a);
}

hsl :: (h: int, s: int, l: int) -> Color {
    return tprint("hsl(% % %)", h, s, l);
}

hsla :: (h: int, s: int, l: int, a: int) -> Color {
    return tprint("hsla(% % % %)", h, s, l, a);
}

hwb :: (h: int, w: int, b: int) -> Color {
    return tprint("hwb(% % %)", h, w, b);
}

css_property :: (property: string, value: string) -> Declaration {
    return .{ property = property, value = value };
}

Color             :: #type,distinct string;
Hex               :: #type,distinct string;
Fit_Content       :: #type,distinct string;
Css_Math          :: #type,distinct string;
Css_Var           :: #type,distinct string;
Anchor_Size_Value :: #type,distinct string;

Length_Unit :: enum {
    NONE;
    PX;
    CM;
    MM;
    Q;
    IN;
    PC;
    PT;
    EM;
    REM;
    EX;
    REX;
    CAP;
    RCAP;
    CH;
    RCH;
    IC;
    RIC;
    LH;
    RLH;
    PERCENT;
    VW;
    VH;
    VI;
    VB;
    VMIN;
    VMAX;
    SVW;
    SVH;
    SVI;
    SVB;
    SVMIN;
    SVMAX;
    LVW;
    LVH;
    LVI;
    LVB;
    LVMIN;
    LVMAX;
    DVW;
    DVH;
    DVI;
    DVB;
    DVMIN;
    DVMAX;
    CQW;
    CQH;
    CQI;
    CQB;
    CQMIN;
    CQMAX;
}

Length :: struct {
    value: float;
    unit:  Length_Unit;
}

HTML_TAGS :: string.[
    "body", "html", "head", "div", "span", "p", "a", "button", "input",
    "textarea", "select", "option", "h1", "h2", "h3", "h4", "h5", "h6",
    "ul", "ol", "li", "table", "tr", "td", "th", "form", "label",
    "header", "footer", "main", "nav", "section", "article", "aside"
];

is_valid_css_token :: (s: string, allow_colon := true) -> bool {
    t     := s.data;
    max_t := t + s.count;

    while t < max_t {
        if t.* == "{" || t.* == "}" || t.* == ";" || t.* == "\r" || t.* == "\n" return false;
        if !allow_colon && t.* == ":"                                           return false;

        t += 1;
    }

    return true;
}

css :: (class_or_selector: string, declarations: ..Declaration) -> string {
    selector: string;

    assert(is_valid_css_token(class_or_selector), "Invalid characters in CSS selector");

    is_raw_selector := false;

    if class_or_selector.count > 0 {
        first_char := class_or_selector[0];

        if first_char == "." || first_char == "#" || first_char == ":" || first_char == "@" {
            is_raw_selector = true;
        } else if array_find(HTML_TAGS, class_or_selector) {
            is_raw_selector = true;
        } else {
            for class_or_selector {
                if it == " " {
                    is_raw_selector = true;
                    break;
                }
            }
        }
    }

    if is_raw_selector selector = class_or_selector;
    else               selector = tprint(".%", class_or_selector);

    if !array_find(compile_time_emitted_selectors, selector) {
        array_add(*compile_time_emitted_selectors, selector);

        print_to_builder(*compile_time_css_builder, "% {\n", selector);

        for declarations {
            assert(is_valid_css_token(it.property, allow_colon = false), "Invalid characters in CSS property name");
            assert(is_valid_css_token(it.value), "Invalid characters in CSS property value");
            print_to_builder(*compile_time_css_builder, "    %: %;\n", it.property, it.value);
        }

        append(*compile_time_css_builder, "}\n\n");
    }

    return class_or_selector;
}

css :: (class_or_selector: string, properties: Properties) -> string {
    declarations: [..] Declaration;

    if properties.font_family      array_add(*declarations, font_family(properties.font_family));
    if properties.background_color array_add(*declarations, background_color(properties.background_color));
    if properties.color            array_add(*declarations, color(properties.color));
    if properties.display          array_add(*declarations, display(properties.display));
    if properties.justify_content  array_add(*declarations, justify_content(properties.justify_content));
    if properties.padding_top.unit array_add(*declarations, padding_top(properties.padding_top));
    if properties.width.unit       array_add(*declarations, width(properties.width));
    if properties.width_keyword    array_add(*declarations, width(properties.width_keyword));

    return css(class_or_selector, ..declarations);
}

css_export_declaration :: () {
    b: String_Builder;

    content := builder_to_string(*compile_time_css_builder);

    append(*b, content);

    full_css := builder_to_string(*b);

    assert(!contains(full_css, "WEBJAI_CSS_END"), "CSS content must not contain heredoc delimiter WEBJAI_CSS_END");

    code := tprint("WEBJAI_EMITTED_CSS :: #string WEBJAI_CSS_END\n%1\nWEBJAI_CSS_END;\n", full_css);

    Compiler :: #import "Compiler";
    Compiler.add_build_string(code, -1);
}

Declaration :: struct {
    property: string;
    value:    string;
}

Properties :: struct {
    font_family:      string;
    background_color: string;
    color:            string;
    display:          Display;
    justify_content:  Justify_Content;
    padding_top:      Length;
    width:            Length;
    width_keyword:    Width;
}

#scope_file

compile_time_emitted_selectors: [..] string;
compile_time_css_builder: String_Builder;
