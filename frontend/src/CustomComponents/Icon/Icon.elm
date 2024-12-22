module CustomComponents.Icon.Icon exposing (view)

import Html.Styled exposing (Html, node)
import Html.Styled.Attributes exposing (attribute)


view : String -> Html msg
view html =
    node "uwu-icon" [ attribute "content" html ] []
