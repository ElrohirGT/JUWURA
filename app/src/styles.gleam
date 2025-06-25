import gleam/string

pub fn width(width: String) -> #(String, String) {
  #("width", width)
}

pub fn height(height: String) -> #(String, String) {
  #("height", height)
}

pub fn padding(pad: String) -> #(String, String) {
  #("padding", pad)
}

pub fn flex_grow(grow: String) -> #(String, String) {
  #("flex-grow", grow)
}

pub fn overflow_x(ovflow: String) -> #(String, String) {
  #("overflow-x", ovflow)
}

pub fn background_color(color: String) -> #(String, String) {
  #("background-color", color)
}

pub fn color(color: String) -> #(String, String) {
  #("color", color)
}

pub fn font_weight(weight: String) -> #(String, String) {
  #("font-weight", weight)
}

pub fn font_size(size: String) -> #(String, String) {
  #("font-size", size)
}

pub fn font_family(family: String) -> #(String, String) {
  #("font-family", family)
}

pub fn display(display: String) -> #(String, String) {
  #("display", display)
}

pub fn justify_content(js: String) -> #(String, String) {
  #("justify-content", js)
}

pub type BoxDimensions {
  All(String)
  Box2(top_bottom: String, left_right: String)
  Box3(top: String, left_right: String, bottom: String)
  Box4(top: String, bottom: String, left: String, right: String)
}

fn box_to_string(dim: BoxDimensions) -> String {
  case dim {
    All(a) -> [a]
    Box2(top_bottom, left_right) -> [top_bottom, left_right]
    Box3(top, left_right, bottom) -> [top, left_right, bottom]
    Box4(top, right, bottom, left) -> [top, right, bottom, left]
  }
  |> string.join(" ")
}

pub type BorderStyle =
  String

pub type BorderColor =
  String

pub type BorderWidth =
  BoxDimensions

pub type BorderInfo {
  BorderInfo(width: BorderWidth, style: BorderStyle, color: BorderColor)
}

fn border_info_to_string(info: BorderInfo) -> String {
  let assert All(width) = info.width

  [width, info.style, info.color]
  |> string.join(" ")
}

pub fn border(border_info: BorderInfo) -> #(String, String) {
  border_info
  |> border_info_to_string()
  |> fn(a) { #("border", a) }
}

pub fn border_radius(rad: String) -> #(String, String) {
  #("border-radius", rad)
}

pub fn gap(gap: String) -> #(String, String) {
  #("gap", gap)
}

pub fn align_items(align: String) -> #(String, String) {
  #("align-items", align)
}

pub fn position(pos: String) -> #(String, String) {
  #("position", pos)
}

pub fn right(r: String) -> #(String, String) {
  #("right", r)
}

pub fn left(r: String) -> #(String, String) {
  #("left", r)
}

pub fn top(r: String) -> #(String, String) {
  #("top", r)
}

pub fn bottom(r: String) -> #(String, String) {
  #("bottom", r)
}
