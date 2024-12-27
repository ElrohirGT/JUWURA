module Pages.LoginCallback exposing (..)

import Html.Styled exposing (div, h1, text)



init : a -> String
init _ = Debug.log "this is a callback" ""

view : { title : String, body : List (Html.Styled.Html msg) }
view =
    { title = "Juwura"
    , body = body
    }


body : List (Html.Styled.Html msg)
body =
    [ div []
        [ h1 [] [ text "Login Callback!" ]
        ]
    ]
