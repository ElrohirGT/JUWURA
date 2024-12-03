module Pages.NotFound exposing (view)

import Html.Styled exposing (div, h1, text)


view =
    { title = "Not found"
    , body = body
    }


body =
    [ div []
        [ h1 [] [ text "¡Not found page!" ]
        ]
    ]
