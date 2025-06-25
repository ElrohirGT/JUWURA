import gleam/string

pub type Icon {
  Search
  QuestionMark
  RightArrow
}

pub fn to_uri(icon: Icon) -> String {
  [
    "/priv",
    "static",
    "icons",
    case icon {
      Search -> "search.svg"
      QuestionMark -> "question_mark.svg"
      RightArrow -> "right_arrow.svg"
    },
  ]
  |> string.join("/")
}
