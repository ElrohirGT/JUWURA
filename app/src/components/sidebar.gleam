// IMPORTS ------------------------------------------------------------------------
import gleam/dynamic/decode
import gleam/json
import helpers
import icons
import lustre
import lustre/attribute.{type Attribute}
import lustre/effect.{type Effect}
import lustre/element.{type Element}
import lustre/element/html
import lustre/event
import styles
import theme

const tag_name = "juwura-sidebar"

// MAIN ------------------------------------------------------------------------
pub fn register() -> Result(Nil, lustre.Error) {
  let component = lustre.component(init, update, view, [])
  lustre.register(component, tag_name)
}

pub fn element(attributes: List(Attribute(msg))) -> Element(msg) {
  element.element(tag_name, attributes, [])
}

pub fn on_toggle(handler: fn(Bool) -> msg) {
  event.on("toggle", decode.at(["detail"], decode.bool) |> decode.map(handler))
}

// MODEL ------------------------------------------------------------------------

type Model {
  Model(is_expanded: Bool)
}

fn init(_) -> #(Model, effect.Effect(msg)) {
  #(Model(False), effect.none())
}

// UPDATE ------------------------------------------------------------------------
type Msg {
  Expand
  Shrink
}

fn update(_: Model, msg: Msg) -> #(Model, effect.Effect(msg)) {
  let is_expanded = case msg {
    Expand -> True
    Shrink -> False
  }

  #(
    Model(is_expanded: is_expanded),
    event.emit("toggle", json.bool(is_expanded)),
  )
}

// VIEW ------------------------------------------------------------------------
fn view(model: Model) -> element.Element(Msg) {
  html.div(
    [
      attribute.styles([
        styles.background(
          "linear-gradient(180deg, "
          <> theme.black_400
          <> " 0%, "
          <> theme.white_50
          <> "00 100%)",
        ),
        styles.grid_area("sidebar"),
      ]),
    ],
    [
      html.div(
        [
          attribute.styles([
            styles.height("100vh"),
            styles.background_color(theme.black_500),
            styles.border_radius("0 10px 10px 0"),
            styles.display("flex"),
            styles.flex_direction("column"),
          ]),
        ],
        case model.is_expanded {
          True -> [
            helpers.btn_icon(
              icons.RightArrow,
              [
                styles.transform("rotateZ(180deg)"),
                styles.align_self("flex-end"),
                styles.transition(".3s"),
              ],
              on_click: Shrink,
            ),
          ]
          False -> [
            helpers.btn_icon(
              icons.RightArrow,
              [styles.transition(".3s")],
              on_click: Expand,
            ),
          ]
        },
      ),
    ],
  )
}
