module Pages.Http exposing (..)

import Html.Styled exposing (pre, text)
import Http



-- MODEL


type Model
    = Failure
    | Loading
    | Success String


init : a -> ( Model, Cmd Msg )
init _ =
    ( Loading
    , Http.get
        { url = "https://elm-lang.org/assets/public-opinion.txt"
        , expect = Http.expectString GotText
        }
    )



-- UPDATE


type Msg
    = GotText (Result Http.Error String)


update : Model -> Msg -> ( Model, Cmd msg )
update _ msg =
    case msg of
        GotText result ->
            case result of
                Ok fulltext ->
                    ( Success fulltext, Cmd.none )

                Err _ ->
                    ( Failure, Cmd.none )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub msg
subscriptions _ =
    Sub.none



-- VIEW


view : Model -> { title : String, body : List (Html.Styled.Html Msg) }
view model =
    { title = "HTTP Example"
    , body = body model
    }


body : Model -> List (Html.Styled.Html Msg)
body model =
    [ case model of
        Failure ->
            text "Sorry an error has occurred during the request!"

        Loading ->
            text "Loading..."

        Success s ->
            pre [] [ text s ]
    ]
