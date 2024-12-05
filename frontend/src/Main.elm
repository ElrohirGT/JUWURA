module Main exposing (AppState, Model, Msg, main)

import Browser
import Browser.Navigation as Nav
import Html
import Html.Styled exposing (toUnstyled)
import Pages.Details as DetailsPage
import Pages.Home as HomePage
import Pages.Http as HttpPage
import Pages.Json as JsonPage
import Pages.NotFound as NotFoundPage
import Routing
import Url exposing (Url)


main : Program (Maybe String) Model Msg
main =
    Browser.application
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        , onUrlChange = UrlChanged
        , onUrlRequest = LinkClicked
        }



-- Browser.sandbox { init = 0, update = update, view = view >> toUnstyled }
-- MODEL


{-| The current app state

Used to represent the current page and state

-}
type AppState
    = Home
    | Details DetailsPage.Model
    | Http ( HttpPage.Model, Cmd HttpPage.Msg )
    | Json ( JsonPage.Model, Cmd JsonPage.Msg )
    | NotFound


fromUrlToAppState : Maybe String -> Url -> AppState
fromUrlToAppState basePath url =
    case Routing.parseUrl basePath url of
        Routing.Home ->
            Home

        Routing.NotFound ->
            NotFound

        Routing.RouteWithParams count ->
            Details { count = count }

        Routing.Http id ->
            Http (HttpPage.init id)

        Routing.Json id ->
            Json (JsonPage.init id)


{-| The application global store
-}
type alias Model =
    { key : Nav.Key
    , basePath : Maybe String
    , state : AppState
    }


init : Maybe String -> Url -> Nav.Key -> ( Model, Cmd Msg )
init basePath url navKey =
    let
        initialAppState =
            fromUrlToAppState basePath url
    in
    case initialAppState of
        Http ( _, command ) ->
            ( Model navKey basePath initialAppState, Cmd.map HttpViewMsg command )

        Json ( _, command ) ->
            ( Model navKey basePath initialAppState, Cmd.map JsonViewMsg command )

        _ ->
            ( Model navKey basePath initialAppState, Cmd.none )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub msg
subscriptions _ =
    Sub.none



-- UPDATE


type Msg
    = UrlChanged Url
    | LinkClicked Browser.UrlRequest
    | DetailsViewMsg DetailsPage.Msg
    | HttpViewMsg HttpPage.Msg
    | JsonViewMsg JsonPage.Msg


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        UrlChanged url ->
            ( { model
                | state = fromUrlToAppState model.basePath url
              }
            , Cmd.none
            )

        LinkClicked request ->
            case request of
                Browser.Internal url ->
                    ( model, Nav.pushUrl model.key (Url.toString url) )

                Browser.External href ->
                    ( model, Nav.load href )

        DetailsViewMsg innerMsg ->
            case model.state of
                Details innerModel ->
                    ( { model | state = Details (DetailsPage.update innerModel innerMsg) }, Cmd.none )

                _ ->
                    ( model, Cmd.none )

        HttpViewMsg innerMsg ->
            case model.state of
                Http innerModel ->
                    let
                        newModel =
                            HttpPage.update (Tuple.first innerModel) innerMsg
                    in
                    ( { model | state = Http newModel }, Cmd.map HttpViewMsg (Tuple.second newModel) )

                _ ->
                    ( model, Cmd.none )

        JsonViewMsg innerMsg ->
            case model.state of
                Json innerModel ->
                    let
                        newModel =
                            JsonPage.update (Tuple.first innerModel) innerMsg
                    in
                    ( { model | state = Json newModel }, Cmd.map JsonViewMsg (Tuple.second newModel) )

                _ ->
                    ( model, Cmd.none )



-- ( { model | state = Details (DetailsPage.update model.state innerMsg) }
-- , Cmd.none
-- )


view : Model -> Browser.Document Msg
view model =
    let
        viewStatic staticView =
            let
                { title, body } =
                    staticView
            in
            { title = title
            , body = List.map toUnstyled body
            }

        viewWithState viewFunc pageModel msgWrapper =
            let
                { title, body } =
                    viewFunc pageModel
            in
            { title = title
            , body = List.map (Html.map msgWrapper) (List.map toUnstyled body)
            }

        viewWithEffects viewFunc pageModel msgWrapper =
            let
                { title, body } =
                    viewFunc (Tuple.first pageModel)
            in
            { title = title
            , body = List.map (Html.map msgWrapper) (List.map toUnstyled body)
            }
    in
    case model.state of
        Home ->
            viewStatic HomePage.view

        Details pageModel ->
            viewWithState DetailsPage.view pageModel DetailsViewMsg

        Http pageModel ->
            viewWithEffects HttpPage.view pageModel HttpViewMsg

        Json pageModel ->
            viewWithEffects JsonPage.view pageModel JsonViewMsg

        NotFound ->
            viewStatic NotFoundPage.view
