module Pages.Home exposing (view)

import Css exposing (column, displayFlex, flexDirection)
import Html.Styled exposing (a, div, img, text)
import Html.Styled.Attributes exposing (css, src)
import Routing exposing (goToHttp, goToJson, goToRouteWithParams)
import Utils exposing (viteAsset)


view : { title : String, body : List (Html.Styled.Html msg) }
view =
    { title = "JUWURA"
    , body = body
    }


body : List (Html.Styled.Html msg)
body =
    [ div [ css [ displayFlex, flexDirection column ] ]
        [ a [ goToRouteWithParams 10 ] [ text "Go to details" ]
        , a [ goToHttp 10 ] [ text "Go to HTTP example" ]
        , a [ goToJson 10 ] [ text "Go to JSON example" ]
        , img [ src <| viteAsset <| "./javascript.svg" ] []
        ]
    ]
