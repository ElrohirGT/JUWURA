module Pages.Home exposing (Model, init, view)

import Css exposing (column, displayFlex, flexDirection)
import Html.Styled exposing (a, div, img, text)
import Html.Styled.Attributes exposing (css, src)
import Routing exposing (BasePath, NavigationHrefs, generateRoutingFuncs)
import Utils exposing (viteAsset)



{-
   Exercises:
   - Get familiar with how the navigation works!
   Try to make a navbar like the one below and
   use it on at least one of the other views!
   REMEMBER: This is ELM no rEaCt...
-}


type alias Model msg =
    NavigationHrefs msg


init : BasePath -> Model msg
init basePath =
    generateRoutingFuncs basePath


view : Model msg -> { title : String, body : List (Html.Styled.Html msg) }
view model =
    { title = "JUWURA"
    , body = body model
    }


body : Model msg -> List (Html.Styled.Html msg)
body model =
    [ div [ css [ displayFlex, flexDirection column ] ]
        [ a [ model.goToRouteWithParams ] [ text "Go to details" ]
        , a [ model.goToHttp 10 ] [ text "Go to HTTP example" ]
        , a [ model.goToJson 10 ] [ text "Go to JSON example" ]
        , a [ model.goToPorts ] [ text "Go to PORTS example" ]
        , img [ src <| viteAsset <| "./javascript.svg" ] []
        ]
    ]
