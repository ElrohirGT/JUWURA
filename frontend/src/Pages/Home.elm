module Pages.Home exposing (Model, Msg, init, subscriptions, update, view)

import Css exposing (color, column, displayFlex, flexDirection, hex)
import Html.Styled exposing (a, button, div, input, text)
import Html.Styled.Attributes exposing (css, placeholder, value)
import Html.Styled.Events exposing (onClick, onInput)
import Ports.LocalStorage.LocalStorage exposing (getLocalStorage, onValueLocalStorage, setLocalStorage)
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
    | Retreive
    | TokenReceived (Maybe String)


type alias Model =
    { navigationHrefs : NavigationHrefs Msg
    , text : String
    , savedText : String
    }


init : BasePath -> ( Model, Cmd Msg )
init basePath =
    ( { navigationHrefs = generateRoutingFuncs basePath
      , text = ""
      , savedText = "hello"
      }
    , Cmd.none
    )


update : Model -> Msg -> ( Model, Cmd Msg )
update model msg =
    case msg of
        ChangeText newValue ->
            ( { model | text = newValue }, Cmd.none )

        Save ->
            let
                cmd =
                    setLocalStorage ( "token", model.text )
            in
            ( model, cmd )

        Retreive ->
            ( model, getLocalStorage "token" )

        TokenReceived maybeValue ->
            case maybeValue of
                Just text ->
                    ( { model | savedText = text }, Cmd.none )

                Nothing ->
                    ( { model | savedText = "Failed to retreive token" }, Cmd.none )


subscriptions : Maybe String -> Sub Msg
subscriptions _ =
    onValueLocalStorage TokenReceived


view : Model -> { title : String, body : List (Html.Styled.Html Msg) }
view model =
    { title = "Juwura"
    , body = body model
    }


body : Model -> List (Html.Styled.Html Msg)
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
    , div []
        [ input [ placeholder "localStorage value", value model.text, onInput ChangeText ] []
        , button [ onClick Save ] [ text "Save" ]
        , button [ onClick Retreive ] [ text "Get" ]
        , div [ css [ color <| hex "#FFF" ] ] [ text model.savedText ]
        ]
    ]
