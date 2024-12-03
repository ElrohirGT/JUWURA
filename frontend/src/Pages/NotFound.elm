module Pages.NotFound exposing (view)

import Html.Styled exposing (div, h1, text)


view : { title : String, body : List (Html.Styled.Html msg) }
view =
    { title = "Not found"
    , body = body
    }


body : List (Html.Styled.Html msg)
body =
    [ div []
        [ h1 [] [ text "¡Not found page!" ]
        ]
    ]
