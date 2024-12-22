module Pages.Senku exposing (view)

import Html.Styled exposing (div, h1, text)


view : { title : String, body : List (Html.Styled.Html msg) }
view =
    { title = "Senku View"
    , body = body
    }


body : List (Html.Styled.Html msg)
body =
    [ div []
        [ h1 [] [ text "Senku View Page!" ]
        ]
    ]
