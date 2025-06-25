import gleam/string

pub type Icon {
  Search
}

pub fn to_uri(icon: Icon) -> String {
  [
    "/priv",
    "static",
    "icons",
    case icon {
      Search -> "search.svg"
    },
  ]
  |> string.join("/")
}
