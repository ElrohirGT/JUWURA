// IMPORTS ---------------------------------------------------------------------

import gleam/int
import gleam/string
import gleam/uri.{type Uri}
import lustre
import lustre/attribute.{type Attribute}
import lustre/effect.{type Effect}
import lustre/element.{type Element}
import lustre/element/html
import styles
import theme

// Modem is a package providing effects and functionality for routing in SPAs.
// This means instead of links taking you to a new page and reloading everything,
// they are intercepted and your `update` function gets told about the new URL.
import modem

// MAIN ------------------------------------------------------------------------

pub fn main() {
  let app = lustre.application(init, update, view)
  let assert Ok(_) = lustre.start(app, "#app", Nil)

  Nil
}

// MODEL -----------------------------------------------------------------------

type Model {
  Model(route: Route)
}

type Route {
  Index
  Home(user_id: Int)
  TableView(project_id: Int)
  SenkuView(project_id: Int)
  NotFound(uri: Uri)
}

fn parse_route(uri: Uri) -> Route {
  case uri.path_segments(uri.path) {
    [] | [""] -> Index

    ["home", user_id] ->
      case int.parse(user_id) {
        Ok(user_id) -> Home(user_id: user_id)
        Error(_) -> NotFound(uri:)
      }

    ["table", project_id] ->
      case int.parse(project_id) {
        Ok(project_id) -> TableView(project_id: project_id)
        Error(_) -> NotFound(uri:)
      }

    ["senku", project_id] ->
      case int.parse(project_id) {
        Ok(project_id) -> SenkuView(project_id: project_id)
        Error(_) -> NotFound(uri:)
      }

    _ -> NotFound(uri:)
  }
}

fn href(route: Route) -> Attribute(msg) {
  let url = case route {
    Index -> "/"
    Home(id) -> "/home/" <> int.to_string(id)
    TableView(id) -> "/table/" <> int.to_string(id)
    SenkuView(id) -> "/senku/" <> int.to_string(id)
    NotFound(_) -> "/404"
  }

  attribute.href(url)
}

fn init(_) -> #(Model, Effect(Msg)) {
  // The server for a typical SPA will often serve the application to *any*
  // HTTP request, and let the app itself determine what to show. Modem stores
  // the first URL so we can parse it for the app's initial route.
  let route = case modem.initial_uri() {
    Ok(uri) -> parse_route(uri)
    Error(_) -> Index
  }

  let model = Model(route:)

  let effect =
    // We need to initialise modem in order for it to intercept links. To do that
    // we pass in a function that takes the `Uri` of the link that was clicked and
    // turns it into a `Msg`.
    modem.init(fn(uri) {
      uri
      |> parse_route
      |> UserNavigatedTo
    })

  #(model, effect)
}

// UPDATE ----------------------------------------------------------------------

type Msg {
  UserNavigatedTo(route: Route)
}

fn update(_: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    UserNavigatedTo(route:) -> #(Model(route:), effect.none())
  }
}

// VIEW ------------------------------------------------------------------------

fn view(_: Model) -> Element(Msg) {
  // Top App Container
  html.div([attribute.styles([styles.background_color("#191919")])], [
    html.div(
      [
        attribute.styles([
          styles.background_color(theme.black_400),
          styles.padding("1rem 1rem 1rem 6rem"),
          styles.display("flex"),
          styles.justify_content("space-between"),
        ]),
      ],
      [
        title("Home/"),
        html.div(
          [
            attribute.styles([
              styles.display("flex"),
              styles.justify_content("space-around"),
              styles.gap("30px"),
            ]),
          ],
          [
            search_bar("SEARCH..."),
            btn_secondary("SHORTCUTS"),
            btn_profile("none"),
          ],
        ),
      ],
    ),
  ])
}

// VIEW HELPERS ----------------------------------------------------------------

fn title(title: String) -> Element(msg) {
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

fn btn_secondary(text: String) -> Element(msg) {
  html.button(
    [
      attribute.styles([
        styles.color(theme.white_700),
        styles.font_size(theme.title_m),
        styles.font_family(theme.font_title),
        styles.padding("4px 10px"),
        styles.font_weight("bold"),
        styles.border_radius("4px"),
        styles.All("1px")
          |> styles.BorderInfo("solid", theme.black_300)
          |> styles.border,
      ]),
    ],
    [html.text(text)],
  )
}

fn btn_profile(pic_src: String) -> Element(msg) {
  html.img([
    attribute.src(pic_src),
    attribute.styles([
      styles.border_radius("50%"),
      styles.width("2rem"),
      styles.height("2rem"),
    ]),
  ])
}

fn search_bar(placeholder: String) -> Element(msg) {
  html.div(
    [
      attribute.styles([
        styles.display("flex"),
        styles.align_items("center"),
        styles.padding("4px 10px"),
        styles.color(theme.white_700),
        styles.font_size(theme.title_m),
        styles.font_family(theme.font_title),
        styles.border_radius("4px"),
        styles.All("1px")
          |> styles.BorderInfo("solid", theme.black_300)
          |> styles.border,
      ]),
    ],
    [
      html.svg(
        [attribute.styles([styles.width("1rem"), styles.height("1rem")])],
        [],
      ),
      html.input([
        attribute.type_("text"),
        attribute.name("search-bar"),
        attribute.styles([styles.font_weight("bold")]),
        attribute.placeholder(placeholder),
      ]),
      html.span([], [html.text("CTRL + K")]),
    ],
  )
}

/// In other frameworks you might see special `<Link />` components that are
/// used to handle navigation logic. Using modem, we can just use normal HTML
/// `<a>` elements and pass in the `href` attribute. This means we have the option
/// of rendering our app as static HTML in the future!
///
fn link(target: Route, title: String) -> Element(msg) {
  html.a(
    [
      href(target),
      attribute.class("text-purple-600 hover:underline cursor-pointer"),
    ],
    [html.text(title)],
  )
}
