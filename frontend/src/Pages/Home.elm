module Pages.Home exposing (Model, Msg, init, subscriptions, update, view)

import Css exposing (backgroundColor, border, borderRadius, color, column, cursor, displayFlex, fitContent, flexDirection, fontFamilies, fontSize, fontWeight, hex, hover, int, maxWidth, padding2, pointer, px, zero)
import Html.Styled exposing (a, button, div, input, text)
import Html.Styled.Attributes exposing (css, placeholder, value)
import Html.Styled.Events exposing (onClick, onInput)
import Ports.Auth.Auth exposing (logoutRedirect)
import Routing exposing (BasePath, NavigationHrefs, generateRoutingFuncs)
import Theme



{-
   Exercises:
   - Get familiar with how the navigation works!
   Try to make a navbar like the one below and
   use it on at least one of the other views!
   REMEMBER: This is ELM no rEaCt...
-}


type Msg
    = StartLogout


type alias Model =
    { navigationHrefs : NavigationHrefs Msg
    }


init : BasePath -> ( Model, Cmd Msg )
init basePath =
    ( { navigationHrefs = generateRoutingFuncs basePath
      }
    , Cmd.none
    )


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none


update : Model -> Msg -> ( Model, Cmd Msg )
update model msg =
    case msg of
        StartLogout ->
            ( model, logoutRedirect () )


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
        [ button
            [ css
                [ backgroundColor Theme.cssColors.red_600
                , color Theme.cssColors.white_400
                , padding2 Theme.cssSpacing.xs Theme.cssSpacing.xl_7
                , maxWidth fitContent
                , fontFamilies [ Theme.fontFamilies.body ]
                , fontWeight (int 400)
                , fontSize Theme.cssFontSizes.title_large
                , border zero
                , cursor pointer
                , borderRadius (px 5)
                , hover
                    [ backgroundColor Theme.cssColors.red_400
                    ]
                , Css.property "transition" "0.2s"
                ]
            , onClick StartLogout
            ]
            [ text "Logout!" ]
        ]
    ]
