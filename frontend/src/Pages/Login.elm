module Pages.Login exposing (..)

import Html.Styled exposing (div, h1, text)


view : { title : String, body : List (Html.Styled.Html msg) }
view =
    { title = "Juwura"
    , body = body
    }


body : List (Html.Styled.Html msg)
body =
    [ div []
        [ h1 [] [ text "Login!" ]
        ]
    ]
