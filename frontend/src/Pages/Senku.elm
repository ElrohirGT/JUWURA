module Pages.Senku exposing (Model, Msg, init, update, view)

import Array exposing (Array)
import Css exposing (absolute, alignItems, backgroundColor, border, borderBottom3, borderColor, borderRadius, borderRadius4, borderWidth, color, displayFlex, fitContent, flexDirection, fontFamilies, fontSize, height, justifyContent, left, maxWidth, padding2, paddingBottom, paddingLeft, paddingRight, paddingTop, pct, position, px, row, solid, spaceBetween, stretch, top, vh, vw, width, zero)
import CustomComponents.Icon.Icon as Icon
import CustomComponents.SenkuCanvas.SenkuCanvas as SenkuCanvas exposing (onCreateConnection, onCreateTask, onTaskChangedCoordinates, onViewTask)
import Data.Issue exposing (Issue)
import Html.Styled exposing (button, div, text)
import Html.Styled.Attributes exposing (css, id)
import Theme exposing (cssColors, cssFontSizes, cssSpacing, spacing)
import Utils exposing (viteAsset)



-- MODEL


type ZoomLevel
    = Low
    | Medium
    | High


type alias Cell =
    Maybe
        { task : Issue
        }


type alias Model =
    { cells : Array (Array Cell)
    , zoomLevel : ZoomLevel
    }


gridSize : number
gridSize =
    10


init : Model
init =
    Model (Array.repeat gridSize <| Array.repeat gridSize Maybe.Nothing) Low



-- UPDATE


type Msg
    = CreateTask SenkuCanvas.CreateTaskEventDetail
    | TaskChangedCoords SenkuCanvas.TaskChangedCoordinatesEventDetail
    | CreateConnection SenkuCanvas.CreateConnectionEventDetail
    | ViewTask SenkuCanvas.ViewTaskEventDetail


update : Model -> Msg -> Model
update model msg =
    case msg of
        CreateTask ev ->
            let
                _ =
                    Debug.log "CREATE TASK MESSAGE!" ev
            in
            model

        TaskChangedCoords ev ->
            let
                _ =
                    Debug.log "TASK CHANGED COORDS MESSAGE!" ev
            in
            model

        CreateConnection ev ->
            let
                _ =
                    Debug.log "CONNECTION CREATED!" ev
            in
            model

        ViewTask ev ->
            let
                _ =
                    Debug.log "DISPLAY TASK INFO" ev
            in
            model



-- VIEW


view : Model -> { title : String, body : List (Html.Styled.Html Msg) }
view model =
    { title = "Senku View"
    , body = body model
    }


body : Model -> List (Html.Styled.Html Msg)
body model =
    let
        sidebardWidthPct : Float
        sidebardWidthPct =
            74.0 / 1976.0 * 100.0

        topbarHeightPct : Float
        topbarHeightPct =
            64.0 / 1117.0 * 100.0

        viewNavbarContainerStyles : List Css.Style
        viewNavbarContainerStyles =
            [ displayFlex
            , flexDirection row
            , Css.property "gap" spacing.xs
            , fontFamilies [ Theme.fontFamilies.label ]
            , fontSize cssFontSizes.label_extraLarge
            , maxWidth fitContent
            , paddingBottom cssSpacing.xs
            ]

        activeViewbarContainerStyles : List Css.Style
        activeViewbarContainerStyles =
            viewNavbarContainerStyles
                ++ [ color cssColors.white_400
                   , height (pct 100)
                   , borderBottom3 cssSpacing.xs_3 solid cssColors.white_400
                   ]

        juwuraButton : List Css.Style
        juwuraButton =
            [ padding2 cssSpacing.xs_2 cssSpacing.l
            , fontFamilies [ Theme.fontFamilies.title ]
            , fontSize cssFontSizes.title_medium
            , borderRadius cssSpacing.xs_2
            ]

        primaryButton : List Css.Style
        primaryButton =
            juwuraButton
                ++ [ backgroundColor cssColors.red_600
                   , color cssColors.white_50
                   , border zero
                   ]

        secondaryButton : List Css.Style
        secondaryButton =
            juwuraButton
                ++ [ backgroundColor cssColors.red_900
                   , borderColor cssColors.red_300
                   , borderWidth (px 1)
                   , color cssColors.white_50
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
                , paddingTop cssSpacing.xl
                , borderBottom3 (px 1) solid cssColors.black_300
                , displayFlex
                , flexDirection row
                , alignItems stretch
                , justifyContent spaceBetween
                , color cssColors.black_300
                ]
            , id "viewTopbar"
            ]
            [ div
                [ css
                    [ displayFlex
                    , Css.property "gap" spacing.xl
                    , alignItems stretch
                    ]
                ]
                [ div [ css viewNavbarContainerStyles ]
                    [ Icon.view (viteAsset "~icons/fa6-solid/table")
                    , text "BACKLOG"
                    ]
                , div [ css activeViewbarContainerStyles ]
                    [ Icon.view (viteAsset "~icons/fa6-solid/share-nodes")
                    , text "OVERVIEW"
                    ]
                , div [ css viewNavbarContainerStyles ]
                    [ Icon.view (viteAsset "~icons/fa6-solid/plus")
                    ]
                ]

            -- View Topbar buttons
            , div
                [ css
                    [ paddingBottom cssSpacing.xs
                    , displayFlex
                    , flexDirection row
                    , Css.property "gap" spacing.l
                    , alignItems stretch
                    , paddingRight cssSpacing.xl_8
                    ]
                ]
                [ button [ css secondaryButton ]
                    [ text "SAVE VIEW"
                    ]
                , button [ css primaryButton ]
                    [ text "NEW"
                    ]
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
                , borderRadius4 zero cssSpacing.l cssSpacing.l zero
                ]
            ]
            []
        , -- Main Content
          div [ css [ paddingLeft (vw sidebardWidthPct) ] ]
            [ SenkuCanvas.view (SenkuCanvas.init (100 - sidebardWidthPct) (100 - topbarHeightPct))
                [ onCreateTask CreateTask
                , onTaskChangedCoordinates TaskChangedCoords
                , onCreateConnection CreateConnection
                , onViewTask ViewTask
                ]
            ]
        ]
    ]
