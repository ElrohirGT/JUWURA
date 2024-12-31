module Main exposing (AppState, Model, Msg, main)

import Browser
import Browser.Navigation as Nav
import Html
import Html.Styled exposing (toUnstyled)
import Pages.Details as DetailsPage
import Pages.Home as HomePage
import Pages.Http as HttpPage
import Pages.Json as JsonPage
import Pages.Login as LoginPage
import Pages.LoginCallback as LoginCallbackPage
import Pages.NotFound as NotFoundPage
import Pages.Ports as PortsPage
import Pages.Senku as SenkuPage
import Routing
import Url exposing (Url)



{-
   All ViewPages have exercises for you to prove you understand Elm!
   You're free to look around for _inspiration_ and yoink anything you like.

   You probably will need to modify other files in the project and not
   only the {PageView}.elm file in question! Don't be afraid to experiment!

   Please follow the order of the pages specified by the AppState enum...
   For example the first one would be NotFound.elm because NotFound is
   the first element inside the AppState enum.

   Good Luck!
-}


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



-- MODEL


{-| The current app state

Used to represent the current page and state

-}
type AppState
    = NotFound
    | Login
    | LoginCallback ( LoginCallbackPage.Model, Cmd LoginCallbackPage.Msg )
    | Senku SenkuPage.Model
    | Details DetailsPage.Model
    | Home ( HomePage.Model, Cmd HomePage.Msg )
    | Http ( HttpPage.Model, Cmd HttpPage.Msg )
    | Json ( JsonPage.Model, Cmd JsonPage.Msg )
    | Ports ( PortsPage.Model, Cmd PortsPage.Msg )


fromUrlToAppState : Maybe String -> Url -> Nav.Key -> AppState
fromUrlToAppState basePath url navKey =
    let
        replaceUrl =
            Routing.replaceUrlWithBasePath navKey basePath
    in
    case Routing.parseUrl basePath url of
        Routing.Home ->
            Home (HomePage.init basePath)

        Routing.Login ->
            Login

        Routing.LoginCallback ->
            LoginCallback (LoginCallbackPage.init replaceUrl)

        Routing.NotFound ->
            NotFound

        Routing.Senku ->
            Senku SenkuPage.init

        Routing.RouteWithParams ->
            Details (DetailsPage.init basePath)

        Routing.Http id ->
            Http (HttpPage.init id)

        Routing.Json id ->
            Json (JsonPage.init id)

        Routing.Ports ->
            Ports PortsPage.init


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
            fromUrlToAppState basePath url navKey
    in
    case initialAppState of
        LoginCallback ( _, command ) ->
            ( Model navKey basePath initialAppState, Cmd.map LoginCallbackViewMsg command )

        Home ( _, command ) ->
            ( Model navKey basePath initialAppState, Cmd.map HomeViewMsg command )

        Http ( _, command ) ->
            ( Model navKey basePath initialAppState, Cmd.map HttpViewMsg command )

        Json ( _, command ) ->
            ( Model navKey basePath initialAppState, Cmd.map JsonViewMsg command )

        _ ->
            ( Model navKey basePath initialAppState, Cmd.none )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    case model.state of
        LoginCallback _ ->
            Sub.map LoginCallbackViewMsg (LoginCallbackPage.subscriptions True)

        Home innerModel ->
            Sub.map HomeViewMsg (HomePage.subscriptions (Tuple.first innerModel))

        Ports innerModel ->
            Sub.map PortsViewMsg (PortsPage.subscriptions (Tuple.first innerModel))

        _ ->
            Sub.none



-- UPDATE


type Msg
    = UrlChanged Url
    | LinkClicked Browser.UrlRequest
    | ReplaceUrl String
    | LoginViewMsg LoginPage.Msg
    | LoginCallbackViewMsg LoginCallbackPage.Msg
    | HomeViewMsg HomePage.Msg
    | DetailsViewMsg DetailsPage.Msg
    | HttpViewMsg HttpPage.Msg
    | JsonViewMsg JsonPage.Msg
    | PortsViewMsg PortsPage.Msg


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        UrlChanged url ->
            ( { model
                | state = fromUrlToAppState model.basePath url model.key
              }
            , Cmd.none
            )

        LinkClicked request ->
            case request of
                Browser.Internal url ->
                    ( model, Nav.pushUrl model.key (Url.toString url) )

                Browser.External href ->
                    ( model, Nav.load href )

        ReplaceUrl url ->
            case model.basePath of
                Just s ->
                    ( model, Nav.replaceUrl model.key (s ++ url) )

                Nothing ->
                    ( model, Nav.replaceUrl model.key url )

        LoginViewMsg innerMsg ->
            case model.state of
                Login ->
                    let
                        newCmd =
                            LoginPage.update innerMsg
                    in
                    ( model, Cmd.map LoginViewMsg newCmd )

                _ ->
                    ( model, Cmd.none )

        LoginCallbackViewMsg innerMsg ->
            case model.state of
                LoginCallback innerModel ->
                    let
                        ( newModel, newCmd ) =
                            LoginCallbackPage.update (Tuple.first innerModel) innerMsg
                    in
                    ( { model | state = LoginCallback ( newModel, newCmd ) }, Cmd.map LoginCallbackViewMsg newCmd )

                _ ->
                    ( model, Cmd.none )

        HomeViewMsg innerMsg ->
            case model.state of
                Home innerModel ->
                    let
                        ( newModel, newCmd ) =
                            HomePage.update (Tuple.first innerModel) innerMsg
                    in
                    ( { model | state = Home ( newModel, newCmd ) }, Cmd.map HomeViewMsg newCmd )

                _ ->
                    ( model, Cmd.none )

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

        PortsViewMsg innerMsg ->
            case model.state of
                Ports innerModel ->
                    let
                        newModel =
                            PortsPage.update (Tuple.first innerModel) innerMsg
                    in
                    ( { model | state = Ports newModel }, Cmd.map PortsViewMsg (Tuple.second newModel) )

                _ ->
                    ( model, Cmd.none )



-- ( { model | state = Details (DetailsPage.update model.state innerMsg) }
-- , Cmd.none
-- )


view : Model -> Browser.Document Msg
view model =
    let
        viewStateLess staticView =
            let
                { title, body } =
                    staticView
            in
            { title = title
            , body = List.map toUnstyled body
            }

        viewWithMsg staticView msgWrapper =
            let
                { title, body } =
                    staticView
            in
            { title = title
            , body = List.map (Html.map msgWrapper) (List.map toUnstyled body)
            }

        viewStatic staticView pageModel =
            let
                { title, body } =
                    staticView pageModel
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
        Login ->
            viewWithMsg LoginPage.view LoginViewMsg

        LoginCallback pageModel ->
            viewWithEffects LoginCallbackPage.view pageModel LoginCallbackViewMsg

        Home pageModel ->
            viewWithEffects HomePage.view pageModel HomeViewMsg

        Details pageModel ->
            viewWithState DetailsPage.view pageModel DetailsViewMsg

        Http pageModel ->
            viewWithEffects HttpPage.view pageModel HttpViewMsg

        Json pageModel ->
            viewWithEffects JsonPage.view pageModel JsonViewMsg

        Ports pageModel ->
            viewWithEffects PortsPage.view pageModel PortsViewMsg

        NotFound ->
            viewStateLess NotFoundPage.view

        Senku pageModel ->
            viewStatic SenkuPage.view pageModel
