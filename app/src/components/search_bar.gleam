// IMPORTS ------------------------------------------------------------------------
import gleam/dynamic/decode
import gleam/json
import gleam/list
import gleam/string
import icons
import lustre
import lustre/attribute.{type Attribute}
import lustre/component
import lustre/effect
import lustre/element.{type Element}
import lustre/element/html
import lustre/event
import styles
import theme

const tag_name = "search-bar"

// MAIN ------------------------------------------------------------------------
pub fn register() -> Result(Nil, lustre.Error) {
  let component =
    lustre.component(init, update, view, [
      component.on_attribute_change("placeholder", fn(pl) {
        pl
        |> PlaceholderChanged
        |> Ok
      }),
      component.on_property_change("placeholder", {
        decode.string |> decode.map(PlaceholderChanged)
      }),
    ])
  lustre.register(component, tag_name)
}

///The element to use for this component
pub fn element(attributes: List(Attribute(msg))) -> Element(msg) {
  element.element(tag_name, attributes, [])
}

/// The placeholder attribute.
pub fn placeholder(placeholder: String) -> Attribute(msg) {
  attribute.placeholder(placeholder)
}

/// Get's called every time the search bar input get's changed.
pub fn on_change(handler: fn(String) -> msg) -> Attribute(msg) {
  event.on("change", {
    decode.at(["detail"], decode.string) |> decode.map(handler)
  })
}

// MODEL ------------------------------------------------------------------------
type Model {
  Model(query: String, has_focus: Bool, placeholder: String)
}

fn init(_) -> #(Model, effect.Effect(Msg)) {
  #(Model(query: "", has_focus: False, placeholder: ""), effect.none())
}

// UPDATE ------------------------------------------------------------------------
type Msg {
  PlaceholderChanged(String)
  FocusChanged(Bool)
  QueryChanged(String)
}

fn update(model: Model, msg: Msg) -> #(Model, effect.Effect(Msg)) {
  case msg {
    PlaceholderChanged(new) -> #(
      Model(..model, placeholder: new),
      effect.none(),
    )

    FocusChanged(focus) -> #(Model(..model, has_focus: focus), effect.none())

    QueryChanged(query) -> #(
      Model(..model, query: query),
      event.emit("change", json.string(query)),
    )
  }
}

// VIEW ------------------------------------------------------------------------
fn view(model: Model) -> element.Element(Msg) {
  let container_styles = [
    styles.position("relative"),
    styles.display("flex"),
    styles.align_items("center"),
    styles.width("238px"),
    styles.padding("4px 10px"),
    styles.color(theme.white_700),
    styles.font_size(theme.title_m),
    styles.font_family(theme.font_title),
    styles.border_radius("4px"),
    styles.All("1px")
      |> styles.BorderInfo("solid", theme.black_300)
      |> styles.border,
  ]
  let search_bar_attributes = [
    attribute.type_("text"),
    attribute.name("search-bar"),
    attribute.styles(
      list.append(
        [
          styles.padding("0 0 0 10px"),
          styles.overflow_x("hidden"),
          styles.flex_grow("1"),
        ],
        case string.length(model.query) == 0 {
          True -> [styles.font_weight("bold")]
          False -> []
        },
      ),
    ),
    attribute.placeholder(model.placeholder),
    attribute.value(model.query),
    event.on_input(QueryChanged),
  ]

  let icon_attributes = [
    attribute.styles([styles.width("1rem"), styles.height("1rem")]),
    attribute.src(icons.to_uri(icons.Search)),
  ]

  case model.has_focus {
    True -> {
      html.div(
        [
          event.on("focusout", decode.success(FocusChanged(False))),
          attribute.styles(container_styles),
        ],
        [
          html.img(icon_attributes),
          html.input(
            list.append(search_bar_attributes, [attribute.autofocus(True)]),
          ),
        ],
      )
    }
    False ->
      html.div(
        [event.on_click(FocusChanged(True)), attribute.styles(container_styles)],
        [
          html.img(icon_attributes),
          html.p(search_bar_attributes, [
            html.text(case string.length(model.query) == 0 {
              True -> model.placeholder
              False -> model.query
            }),
          ]),
          html.span(
            [
              attribute.styles([
                styles.position("absolute"),
                styles.right("0"),
                styles.padding("0 10px"),
                styles.background_color(theme.black_400),
              ]),
            ],
            [html.text("CTRL + K")],
          ),
        ],
      )
  }
}
