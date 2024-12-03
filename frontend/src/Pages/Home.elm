module Pages.Home exposing (view)

import Html.Styled exposing (a, div, text, toUnstyled)
import Routing exposing (goToRouteWithParams)


view =
    { title = "JUWURA"
    , body = body
    }


body =
    [ div []
        [ a [ goToRouteWithParams 10 ] [ text "Go to details" ]
        ]
    ]
