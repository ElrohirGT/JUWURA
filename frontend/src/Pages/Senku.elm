module Pages.Senku exposing (view)

import Css exposing (absolute, backgroundColor, borderRadius4, calc, column, displayFlex, flexDirection, height, hidden, int, left, minus, overflowY, paddingLeft, paddingRight, pct, position, px, row, top, transform, translateY, vh, vw, width, zIndex, zero)
import Html.Styled exposing (div, h1, text)
import Html.Styled.Attributes exposing (css)
import Theme exposing (colors, cssColors, cssSpacing, spacing)


view : { title : String, body : List (Html.Styled.Html msg) }
view =
    { title = "Senku View"
    , body = body
    }


sidebardWidthPct =
    72.0 / 1728.0 * 100.0


topbarHeightPct =
    64.0 / 1117.0 * 100.0


body : List (Html.Styled.Html msg)
body =
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
                [ paddingLeft (vw sidebardWidthPct)
                ]
            ]
            [ text "View Top bar"
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
