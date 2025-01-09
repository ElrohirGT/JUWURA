module Pages.Project exposing (Model, Msg, PageState, init, subscriptions, update, view)

import Css exposing (absolute, alignItems, backgroundColor, border, borderBottom3, borderColor, borderRadius, borderRadius4, borderWidth, color, displayFlex, fitContent, flexDirection, fontFamilies, fontSize, height, justifyContent, left, maxWidth, padding2, paddingBottom, paddingLeft, paddingRight, paddingTop, pct, position, px, row, solid, spaceBetween, stretch, top, vh, vw, width, zero)
import CustomComponents.Icon.Icon as Icon
import CustomComponents.SenkuCanvas.SenkuCanvas as SenkuCanvas exposing (onCreateConnection, onCreateTask, onDeleteConnection, onDeleteTask, onTaskChangedCoordinates, onViewTask)
import Html.Styled exposing (button, div, pre, text)
import Html.Styled.Attributes exposing (css, id)
import Html.Styled.Events exposing (onClick)
import Json.Decode as Decode
import Platform.Cmd as Cmd
import Ports.Ws.Ws as WsPort
import Theme exposing (cssColors, cssFontSizes, cssSpacing, spacing)
import Utils exposing (viteAsset)



-- MODEL


type PageState
    = WSConnecting
    | WSConnectionError
    | WSParsingError Decode.Error
    | Loading
    | SenkuView SenkuCanvas.SenkuState
    | TableView


type alias Model =
    { projectId : Int
    , email : String
    , state : PageState
    }


init : Int -> String -> ( Model, Cmd msg )
init projectId email =
    ( { projectId = projectId
      , email = email
      , state = WSConnecting
      }
    , WsPort.sendMessage (WsPort.ConnectRequest { projectId = projectId, email = email })
    )



-- UPDATE


type Msg
    = CreateTask SenkuCanvas.CreateTaskEventDetail
    | TaskChangedCoords SenkuCanvas.TaskChangedCoordinatesEventDetail
    | CreateConnection SenkuCanvas.CreateConnectionEventDetail
    | ViewTask SenkuCanvas.ViewTaskEventDetail
    | DeleteTask SenkuCanvas.DeleteTaskEventDetail
    | DeleteConnection SenkuCanvas.DeleteConnectionEventDetail
    | GoToBacklog
    | GoToOverview
    | WSMessage (Result Decode.Error WsPort.WSResponses)


update : Model -> Msg -> ( Model, Cmd Msg )
update model msg =
    case msg of
        WSMessage result ->
            case result of
                Ok response ->
                    case response of
                        WsPort.ConnectionErrorResponse ->
                            ( { model | state = WSConnectionError }, Cmd.none )

                        WsPort.GetSenkuStateResponse state ->
                            ( { model | state = SenkuView state }, Cmd.none )

                        WsPort.UserConnectedResponse email ->
                            if email == model.email then
                                ( { model | state = TableView }, Cmd.none )

                            else
                                ( model, Cmd.none )

                        WsPort.CreateTaskResponse _ ->
                            ( model, WsPort.sendMessage (WsPort.GetSenkuStateRequest { projectId = model.projectId }) )

                Err error ->
                    ( { model | state = WSParsingError error }, Cmd.none )

        GoToBacklog ->
            ( { model | state = TableView }, Cmd.none )

        GoToOverview ->
            ( { model | state = Loading }, WsPort.sendMessage (WsPort.GetSenkuStateRequest { projectId = model.projectId }) )

        CreateTask info ->
            ( model, WsPort.sendMessage (WsPort.CreateTaskRequest info) )

        TaskChangedCoords _ ->
            ( model, Cmd.none )

        CreateConnection _ ->
            ( model, Cmd.none )

        ViewTask _ ->
            ( model, Cmd.none )

        DeleteTask _ ->
            ( model, Cmd.none )

        DeleteConnection _ ->
            ( model, Cmd.none )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions _ =
    WsPort.onMessage WSMessage



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

        mainContentTopBar : Html.Styled.Html Msg
        mainContentTopBar =
            case model.state of
                SenkuView _ ->
                    div
                        [ css
                            [ displayFlex
                            , Css.property "gap" spacing.xl
                            , alignItems stretch
                            ]
                        ]
                        [ div
                            [ css viewNavbarContainerStyles
                            , onClick GoToBacklog
                            ]
                            [ Icon.view (viteAsset "~icons/fa6-solid/table")
                            , text "BACKLOG"
                            ]
                        , div
                            [ css activeViewbarContainerStyles
                            , onClick GoToOverview
                            ]
                            [ Icon.view (viteAsset "~icons/fa6-solid/share-nodes")
                            , text "OVERVIEW"
                            ]
                        , div [ css viewNavbarContainerStyles ]
                            [ Icon.view (viteAsset "~icons/fa6-solid/plus")
                            ]
                        ]

                TableView ->
                    div
                        [ css
                            [ displayFlex
                            , Css.property "gap" spacing.xl
                            , alignItems stretch
                            ]
                        ]
                        [ div
                            [ css activeViewbarContainerStyles
                            , onClick GoToBacklog
                            ]
                            [ Icon.view (viteAsset "~icons/fa6-solid/table")
                            , text "BACKLOG"
                            ]
                        , div
                            [ css viewNavbarContainerStyles
                            , onClick GoToOverview
                            ]
                            [ Icon.view (viteAsset "~icons/fa6-solid/share-nodes")
                            , text "OVERVIEW"
                            ]
                        , div [ css viewNavbarContainerStyles ]
                            [ Icon.view (viteAsset "~icons/fa6-solid/plus")
                            ]
                        ]

                _ ->
                    div
                        [ css
                            [ displayFlex
                            , Css.property "gap" spacing.xl
                            , alignItems stretch
                            ]
                        ]
                        [ div
                            [ css viewNavbarContainerStyles
                            , onClick GoToBacklog
                            ]
                            [ Icon.view (viteAsset "~icons/fa6-solid/table")
                            , text "BACKLOG"
                            ]
                        , div
                            [ css viewNavbarContainerStyles
                            , onClick GoToOverview
                            ]
                            [ Icon.view (viteAsset "~icons/fa6-solid/share-nodes")
                            , text "OVERVIEW"
                            ]
                        , div [ css viewNavbarContainerStyles ]
                            [ Icon.view (viteAsset "~icons/fa6-solid/plus")
                            ]
                        ]

        mainContent : List (Html.Styled.Html Msg)
        mainContent =
            case model.state of
                SenkuView state ->
                    [ SenkuCanvas.view (SenkuCanvas.init (100 - sidebardWidthPct) (100 - topbarHeightPct) state model.projectId)
                        [ onCreateTask CreateTask
                        , onTaskChangedCoordinates TaskChangedCoords
                        , onCreateConnection CreateConnection
                        , onViewTask ViewTask
                        , onDeleteTask DeleteTask
                        , onDeleteConnection DeleteConnection
                        ]
                    ]

                WSConnectionError ->
                    [ pre [ css [ color Theme.cssColors.white_50 ] ]
                        [ text "An error ocurred connecting to the websocket!" ]
                    ]

                Loading ->
                    [ pre [ css [ color Theme.cssColors.white_50 ] ]
                        [ text "Cargando..." ]
                    ]

                WSParsingError err ->
                    [ pre [ css [ color Theme.cssColors.white_50 ] ]
                        [ text (String.join "\n" [ "Parsing websocket message error:", Decode.errorToString err ]) ]
                    ]

                _ ->
                    []
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
            [ mainContentTopBar
            , -- View Topbar buttons
              div
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
          div [ css [ paddingLeft (vw sidebardWidthPct) ] ] mainContent
        ]
    ]
