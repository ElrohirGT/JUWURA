module Pages.Home exposing (Model, Msg, init, update, view)

import Css exposing (color, column, displayFlex, flexDirection, hex)
import Html.Styled exposing (a, button, div, input, text)
import Html.Styled.Attributes exposing (css, placeholder, value)
import Html.Styled.Events exposing (onClick, onInput)
import Routing exposing (BasePath, NavigationHrefs, generateRoutingFuncs)



{-
   Exercises:
   - Get familiar with how the navigation works!
   Try to make a navbar like the one below and
   use it on at least one of the other views!
   REMEMBER: This is ELM no rEaCt...
-}


type Msg
    = ChangeText String
    | Save


type alias Model msg =
    { navigationHrefs : NavigationHrefs msg
    , text : String
    }


init : BasePath -> ( Model Msg, Cmd Msg )
init basePath =
    ( { navigationHrefs = generateRoutingFuncs basePath
      , text = ""
      }
    , Cmd.none
    )


update : Model msg -> Msg -> ( Model msg, Cmd Msg )
update model msg =
    case msg of
        ChangeText newValue ->
            ( { model | text = newValue }, Cmd.none )

        Save ->
            let
                a =
                    Debug.log "Hellow" 3
            in
            ( model, Cmd.none )


view : Model Msg -> { title : String, body : List (Html.Styled.Html Msg) }
view model =
    { title = "Juwura"
    , body = body model
    }


body : Model Msg -> List (Html.Styled.Html Msg)
body model =
    let
        nav =
            model.navigationHrefs
    in
    [ div [ css [ displayFlex, flexDirection column ] ]
        [ a [ nav.goToRouteWithParams ] [ text "Go to details" ]
        , a [ nav.goToHttp 10 ] [ text "Go to HTTP example" ]
        , a [ nav.goToJson 10 ] [ text "Go to JSON example" ]
        , a [ nav.goToPorts ] [ text "Go to PORTS example" ]
        ]
    , div [ css [ color <| hex "#FFF" ] ]
        [ input [ placeholder "localStorage value", value model.text, onInput ChangeText ] []
        , button [ onClick Save ] [ text "Save" ]
        ]
    ]
