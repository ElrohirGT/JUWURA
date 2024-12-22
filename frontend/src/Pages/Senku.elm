module Pages.Senku exposing (view)

import Css exposing (absolute, backgroundColor, borderRadius4, height, left, paddingLeft, position, top, vh, vw, width, zero)
import CustomComponents.Icon.Icon as Icon
import Html.Styled exposing (div, text)
import Html.Styled.Attributes exposing (css)
import Theme exposing (cssColors, cssSpacing)
import Utils exposing (viteAsset)


view : { title : String, body : List (Html.Styled.Html msg) }
view =
    { title = "Senku View"
    , body = body
    }


sidebardWidthPct : Float
sidebardWidthPct =
    72.0 / 1728.0 * 100.0


topbarHeightPct : Float
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
            , Icon.view (viteAsset "~icons/fa6-solid/table")

            -- , case toHtml None (viteAsset "~icons/fa6-solid/table") of
            --     Err err ->
            --         Debug.log err
            --
            --     Ok v ->
            --         v
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
