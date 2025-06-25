import gleam/int
import gleam/uri.{type Uri}
import lustre/attribute.{type Attribute}

pub type Route {
  Index
  Home(user_id: Int)
  TableView(project_id: Int)
  SenkuView(project_id: Int)
  NotFound(uri: Uri)
}

pub fn parse_route(uri: Uri) -> Route {
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

pub fn href(route: Route) -> Attribute(msg) {
  let url = case route {
    Index -> "/"
    Home(id) -> "/home/" <> int.to_string(id)
    TableView(id) -> "/table/" <> int.to_string(id)
    SenkuView(id) -> "/senku/" <> int.to_string(id)
    NotFound(_) -> "/404"
  }

  attribute.href(url)
}
