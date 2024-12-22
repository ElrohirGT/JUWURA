module Pages.Senku exposing (view)

import Css exposing (absolute, auto, backgroundColor, borderRadius4, calc, color, column, displayFlex, fitContent, flexDirection, fontFamilies, fontSize, height, left, maxWidth, padding, paddingLeft, plus, position, row, textTransform, top, uppercase, vh, vw, width, zero)
import CustomComponents.Icon.Icon as Icon
import Html.Styled exposing (div, text)
import Html.Styled.Attributes exposing (css)
import Theme exposing (cssColors, cssFontSizes, cssSpacing, fontSizes, spacing)
import Utils exposing (viteAsset)


view : { title : String, body : List (Html.Styled.Html msg) }
view =
    { title = "Senku View"
    , body = body
    }


body : List (Html.Styled.Html msg)
body =
    let
        sidebardWidthPct : Float
        sidebardWidthPct =
            72.0 / 1728.0 * 100.0

        topbarHeightPct : Float
        topbarHeightPct =
            64.0 / 1117.0 * 100.0

        viewNavbarContainerStyles =
            [ displayFlex
            , flexDirection row
            , Css.property "gap" spacing.xs
            , fontFamilies [ Theme.fontFamilies.label ]
            , fontSize cssFontSizes.label_extraLarge
            , maxWidth fitContent
            ]
    in
    [ div
        [ css
            [ height (vh 100)
            , backgroundColor cssColors.black_490
            ]
        ]
        [ -- Main Topbar
          div
            [ css
                [ height (vh topbarHeightPct)
                , backgroundColor cssColors.black_300
                , paddingLeft (vw sidebardWidthPct)
                ]
            ]
            []

        -- View Topbar
        , div
            [ css
                [ paddingLeft (vw (sidebardWidthPct + 2))
                , color cssColors.white_50
                , displayFlex
                , flexDirection row
                , Css.property "gap" spacing.xl
                ]
            ]
            [ div [ css viewNavbarContainerStyles ]
                [ Icon.view (viteAsset "~icons/fa6-solid/table")
                , text "BACKLOG"
                ]
            , div [ css viewNavbarContainerStyles ]
                [ Icon.view (viteAsset "~icons/fa6-solid/share-nodes")
                , text "OVERVIEW"
                ]
            ]
        , -- Sidebar
          div
            [ css
                [ position absolute
                , left zero
                , top zero
                , height (vh 100)
                , width (vw sidebardWidthPct)
                , backgroundColor cssColors.black_500
                , borderRadius4 zero cssSpacing.xl_3 zero zero
                ]
            ]
            []
        ]
    ]
