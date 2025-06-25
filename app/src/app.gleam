// IMPORTS ---------------------------------------------------------------------

import components/search_bar
import components/sidebar
import gleam/option
import helpers
import icons
import lustre
import lustre/attribute
import lustre/effect.{type Effect}
import lustre/element.{type Element}
import lustre/element/html
import routes.{type Route}
import styles
import theme

// Modem is a package providing effects and functionality for routing in SPAs.
// This means instead of links taking you to a new page and reloading everything,
// they are intercepted and your `update` function gets told about the new URL.
import modem

// MAIN ------------------------------------------------------------------------

pub fn main() {
  // Registering components
  let assert Ok(_) = search_bar.register()
  let assert Ok(_) = sidebar.register()

  let app = lustre.application(init, update, view)
  let assert Ok(_) = lustre.start(app, "#app", Nil)

  Nil
}

// MODEL -----------------------------------------------------------------------

type Model {
  Model(route: Route, sidebar_expanded: Bool)
}

fn init(_) -> #(Model, Effect(Msg)) {
  // The server for a typical SPA will often serve the application to *any*
  // HTTP request, and let the app itself determine what to show. Modem stores
  // the first URL so we can parse it for the app's initial route.
  let route = case modem.initial_uri() {
    Ok(uri) -> routes.parse_route(uri)
    Error(_) -> routes.Index
  }

  let model = Model(route:, sidebar_expanded: False)

  let effect =
    // We need to initialise modem in order for it to intercept links. To do that
    // we pass in a function that takes the `Uri` of the link that was clicked and
    // turns it into a `Msg`.
    modem.init(fn(uri) {
      uri
      |> routes.parse_route
      |> UserNavigatedTo
    })

  #(model, effect)
}

// UPDATE ----------------------------------------------------------------------

type Msg {
  UserNavigatedTo(route: Route)
  ToggleSidebar(expand: Bool)
}

fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    UserNavigatedTo(route:) -> #(Model(..model, route:), effect.none())
    ToggleSidebar(expand:) -> #(
      Model(..model, sidebar_expanded: expand),
      effect.none(),
    )
  }
}

// VIEW ------------------------------------------------------------------------

fn view(model: Model) -> Element(Msg) {
  // Top App Container
  html.div(
    [
      attribute.styles([
        styles.background_color("#191919"),
        styles.width("100vw"),
        styles.height("100vh"),
        styles.display("grid"),
        styles.grid_template_rows("6% 90%"),
        styles.grid_template_areas("\"sidebar header\" \"sidebar content\" "),
        case model.sidebar_expanded {
          True -> styles.grid_template_columns("10% auto")
          False -> styles.grid_template_columns("5% auto")
        },
      ]),
    ],
    [
      // Page Header
      html.div(
        [
          attribute.styles([
            styles.background_color(theme.black_400),
            styles.padding("1rem 1rem 1rem 3rem"),
            styles.display("flex"),
            styles.justify_content("space-between"),
            styles.align_items("center"),
            styles.grid_area("header"),
          ]),
        ],
        [
          helpers.title("Home/"),
          html.div(
            [
              attribute.styles([
                styles.display("flex"),
                styles.justify_content("space-around"),
                styles.gap("30px"),
              ]),
            ],
            [
              search_bar.element([search_bar.placeholder("SEARCH...")]),
              helpers.btn_secondary(
                "SHORTCUTS",
                option.Some(icons.QuestionMark),
              ),
              helpers.btn_profile("/priv/static/profile.webp"),
            ],
          ),
        ],
      ),
      // Page Sidebar
      sidebar.element([sidebar.on_toggle(ToggleSidebar)]),
    ],
  )
}
