module Pages.Home exposing (view)

import Html.Styled exposing (a, div, img, text)
import Html.Styled.Attributes exposing (src)
import Routing exposing (goToRouteWithParams)
import Utils exposing (viteAsset)


view : { title : String, body : List (Html.Styled.Html msg) }
view =
    { title = "JUWURA"
    , body = body
    }


body : List (Html.Styled.Html msg)
body =
    [ div []
        [ a [ goToRouteWithParams 10 ] [ text "Go to details" ]
        , img [ src <| viteAsset <| "./javascript.svg" ] []
        ]
    ]
