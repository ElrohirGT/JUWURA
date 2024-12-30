module Pages.Login exposing (..)

import Css exposing (alignItems, backgroundColor, bold, border, borderRadius, center, color, column, cursor, displayFlex, fitContent, flexDirection, fontFamilies, fontSize, fontStyle, fontWeight, height, hex, hover, inline, inlineBlock, int, justifyContent, maxWidth, padding2, pct, pointer, px, zero)
import Html.Styled exposing (button, div, text)
import Html.Styled.Attributes exposing (css)
import Html.Styled.Events exposing (onClick)
import Ports.Auth.Auth exposing (loginRedirect)
import Theme


type Msg
    = StartLogin


view : { title : String, body : List (Html.Styled.Html Msg) }
view =
    { title = "Juwura"
    , body = body
    }


update : Msg -> Cmd Msg
update msg =
    case msg of
        StartLogin ->
            loginRedirect ()


body : List (Html.Styled.Html Msg)
body =
    [ div
        [ css
            [ displayFlex
            , flexDirection column
            , alignItems center
            , justifyContent center
            , height (pct 100)
            ]
        ]
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
            , onClick StartLogin
            ]
            [ text "Login!" ]
        ]
    ]
