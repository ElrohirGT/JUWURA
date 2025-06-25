import gleam/string

pub type Icon {
  Search
  QuestionMark
}

pub fn to_uri(icon: Icon) -> String {
  [
    "/priv",
    "static",
    "icons",
    case icon {
      Search -> "search.svg"
      QuestionMark -> "question_mark.svg"
    },
  ]
  |> string.join("/")
}
