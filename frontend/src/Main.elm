module Main exposing (main)

import Browser
import Browser.Navigation as Nav
import Html.Styled exposing (toUnstyled)
import Html.Styled.Attributes exposing (css, href, src)
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
    | Details Int
    | NotFound


fromUrlToAppState : Maybe String -> Url -> AppState
fromUrlToAppState basePath url =
    case Routing.parseUrl basePath url of
        Routing.Home ->
            Home

        Routing.NotFound ->
            NotFound

        Routing.RouteWithParams param ->
            Details param


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


view : Model -> Browser.Document Msg
view model =
    let
        viewPage staticView =
            let
                { title, body } =
                    staticView
            in
            { title = title
            , body = List.map toUnstyled body
            }
    in
    case model.state of
        Loading ->
            viewPage LoadingPage.view

        Home ->
            Debug.todo "branch 'Home' not implemented"

        Details _ ->
            Debug.todo "branch 'Details _' not implemented"

        NotFound ->
            Debug.todo "branch 'NotFound' not implemented"
