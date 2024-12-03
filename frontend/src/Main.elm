module Main exposing (main)

import Browser
import Browser.Navigation as Nav
import Html
import Html.Styled exposing (toUnstyled)
import Html.Styled.Attributes exposing (css, href, src)
import Pages.Details as DetailsPage
import Pages.Home as HomePage
import Pages.Loading as LoadingPage
import Routing
import Url exposing (Url)


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
    = Loading
    | Home
    | Details DetailsPage.Model
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


{-| The application global store
-}
type alias Model =
    { key : Nav.Key
    , basePath : Maybe String
    , state : AppState
    }


{-| Props for initializing the application
-}
type alias Flags =
    Maybe String


init basePath url navKey =
    ( Model navKey basePath (fromUrlToAppState basePath url), Cmd.none )



-- SUBSCRIPTIONS


subscriptions model =
    Sub.none



-- UPDATE


type Msg
    = UrlChanged Url
    | LinkClicked Browser.UrlRequest
    | DetailsViewMsg DetailsPage.Msg


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
                    Debug.todo "This should never happen!"



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

        viewWithState viewFunc pagemodel msgWrapper =
            let
                { title, body } =
                    viewFunc pagemodel
            in
            { title = title
            , body = List.map (Html.map msgWrapper) (List.map toUnstyled body)
            }
    in
    case model.state of
        Loading ->
            viewStatic LoadingPage.view

        Home ->
            viewStatic HomePage.view

        Details pageModel ->
            viewWithState DetailsPage.view pageModel DetailsViewMsg

        NotFound ->
            Debug.todo "branch 'NotFound' not implemented"
