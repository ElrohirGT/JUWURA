import gleam/list
import gleam/option.{type Option}
import gleam/string
import icons
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html
import lustre/event
import routes.{type Route}
import styles
import theme

pub fn title(title: String) -> Element(msg) {
  html.h1(
    [
      attribute.styles([
        styles.color(theme.white_400),
        styles.font_weight("bold"),
        styles.font_family(theme.font_title),
        styles.font_size(theme.title_l),
      ]),
    ],
    [html.text(title |> string.uppercase())],
  )
}

pub fn btn_icon(
  icon: icons.Icon,
  styles: List(#(String, String)),
  on_click onclick: msg,
) -> Element(msg) {
  html.button(
    [
      event.on_click(onclick),
      attribute.styles(
        [
          styles.color(theme.white_700),
          styles.font_size(theme.title_m),
          styles.font_family(theme.font_title),
          styles.padding("4px 10px"),
          styles.font_weight("bold"),
          styles.display("flex"),
          styles.justify_content("center"),
        ]
        |> list.append(styles),
      ),
    ],
    [html.img([attribute.src(icons.to_uri(icon))])],
  )
}

pub fn btn_secondary(text: String, icon: Option(icons.Icon)) -> Element(msg) {
  html.button(
    [
      attribute.styles([
        styles.color(theme.white_700),
        styles.font_size(theme.title_m),
        styles.font_family(theme.font_title),
        styles.padding("4px 10px"),
        styles.font_weight("bold"),
        styles.border_radius("4px"),
        styles.display("flex"),
        styles.gap("10px"),
        styles.All("1px")
          |> styles.BorderInfo("solid", theme.black_300)
          |> styles.border,
      ]),
    ],
    [
      case icon {
        option.Some(icon) -> html.img([attribute.src(icons.to_uri(icon))])
        option.None -> {
          html.span([], [])
        }
      },
      html.text(text),
    ],
  )
}

pub fn btn_profile(pic_src: String) -> Element(msg) {
  html.img([
    attribute.src(pic_src),
    attribute.styles([
      styles.border_radius("50%"),
      styles.width("2rem"),
      styles.height("2rem"),
    ]),
  ])
}

/// In other frameworks you might see special `<Link />` components that are
/// used to handle navigation logic. Using modem, we can just use normal HTML
/// `<a>` elements and pass in the `href` attribute. This means we have the option
/// of rendering our app as static HTML in the future!
///
pub fn link(target: Route, title: String) -> Element(msg) {
  html.a(
    [
      routes.href(target),
      attribute.class("text-purple-600 hover:underline cursor-pointer"),
    ],
    [html.text(title)],
  )
}
