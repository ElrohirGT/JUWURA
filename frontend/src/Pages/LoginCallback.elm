module Pages.LoginCallback exposing (..)

import Browser.Navigation
import Css exposing (alignItems, backgroundColor, borderRadius, center, ch, color, column, displayFlex, flexDirection, fontFamilies, fontSize, fontWeight, height, int, justifyContent, maxWidth, padding2, pct, px, textAlign, textOrientation, wait, width)
import Html.Styled exposing (div, h1, text)
import Html.Styled.Attributes exposing (css)
import Ports.Auth.Auth as Auth exposing (onOauthResult)
import Routing exposing (replaceUrlWithBasePath)
import Theme exposing (cssColors)


type Msg
    = CheckStatus Bool


type Status
    = Failed
    | Waiting


type alias Model =
    { status : Status
    }


init : ( Model, Cmd msg )
init =
    ( Model Waiting, Auth.parseCallback () )


update : Model -> Msg -> ( Model, Cmd Msg )
update model msg =
    case msg of
        CheckStatus result ->
            if result == True then
                ( { model | status = Failed }, Cmd.none )

            else
                ( { model | status = Failed }, Cmd.none )


subscriptions : Bool -> Sub Msg
subscriptions _ =
    onOauthResult CheckStatus


view : Model -> { title : String, body : List (Html.Styled.Html Msg) }
view model =
    { title = "Juwura"
    , body = body model
    }


body : Model -> List (Html.Styled.Html Msg)
body model =
    [ div
        [ css
            [ displayFlex
            , flexDirection column
            , alignItems center
            , justifyContent center
            , height (pct 100)
            ]
        ]
        [ div
            [ css
                [ backgroundColor cssColors.black_450
                , color cssColors.white_400
                , width (pct 80)
                , maxWidth (ch 40)
                , fontFamilies [ Theme.fontFamilies.body ]
                , fontWeight (int 600)
                , fontSize Theme.cssFontSizes.title_large
                , padding2 Theme.cssSpacing.s Theme.cssSpacing.xl
                , textAlign center
                , borderRadius (px 6)
                ]
            ]
            [ h1
                [ css
                    [ fontFamilies [ Theme.fontFamilies.body ]
                    , fontWeight (int 600)
                    , fontSize Theme.cssFontSizes.title_large
                    ]
                ]
                [ case model.status of
                    Waiting ->
                        text "Waiting"

                    Failed ->
                        text "Authentication failed"
                ]
            ]
        ]
    ]
