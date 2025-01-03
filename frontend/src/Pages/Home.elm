module Pages.Home exposing (Model, Msg, PageStatus, init, subscriptions, update, view)

import Css exposing (backgroundColor, border, borderRadius, color, column, cursor, displayFlex, fitContent, flexDirection, fontFamilies, fontSize, fontWeight, hover, int, maxWidth, padding2, pointer, px, zero)
import Html.Styled exposing (a, button, div, p, text)
import Html.Styled.Attributes exposing (css)
import Html.Styled.Events exposing (onClick)
import Ports.Auth.Auth as Auth
import Routing exposing (BasePath, NavigationHrefs, generateRoutingFuncs)
import Theme


type PageStatus
    = LoadingCredentials
    | Authorized
        { userCredentials : Auth.UserCredentials
        }


type alias Model =
    { pageStatus : PageStatus
    , navigationHrefs : NavigationHrefs Msg
    , replaceUrl : String -> Cmd Msg
    }


type Msg
    = StartLogout
    | GotUserCredentials (Maybe Auth.UserCredentials)


subscriptions : Model -> Sub Msg
subscriptions _ =
    Auth.onCheckedUserSession GotUserCredentials


init : BasePath -> (String -> Cmd Msg) -> ( Model, Cmd Msg )
init basePath replaceUrl =
    ( { pageStatus = LoadingCredentials
      , navigationHrefs = generateRoutingFuncs basePath
      , replaceUrl = replaceUrl
      }
    , Auth.checkUserSession ()
    )


update : Model -> Msg -> ( Model, Cmd Msg )
update model msg =
    case msg of
        StartLogout ->
            ( model, Auth.logoutRedirect () )

        GotUserCredentials credentials ->
            case credentials of
                Just v ->
                    ( { model | pageStatus = Authorized { userCredentials = v } }, Cmd.none )

                Nothing ->
                    ( model, model.replaceUrl "/login/" )


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
        , p [ css [ color Theme.cssColors.white_400 ] ]
            [ case model.pageStatus of
                Authorized _ ->
                    text "Authorized"

                _ ->
                    text "Loading credentials"
            ]
        , p []
            [ case model.pageStatus of
                Authorized v ->
                    text v.userCredentials.accessToken

                _ ->
                    text "Error!"
            ]
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
