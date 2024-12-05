module Pages.Http exposing (Model(..), Msg(..), init, update, view)

import Css exposing (column, displayFlex, flexDirection)
import Html.Styled exposing (button, pre, text)
import Html.Styled.Attributes exposing (css)
import Html.Styled.Events exposing (onClick)
import Http



{-
   Exercises:
   - Try to make the Failure state more specific!
   Can you inform the user why the request failed?
-}
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
    | Refresh


update : Model -> Msg -> ( Model, Cmd Msg )
update _ msg =
    case msg of
        GotText result ->
            case result of
                Ok fulltext ->
                    ( Success fulltext, Cmd.none )

                Err _ ->
                    ( Failure, Cmd.none )

        Refresh ->
            ( Loading, Http.get { url = "https://elm-lang.org/assets/public-opinion.txt", expect = Http.expectString GotText } )



-- SUBSCRIPTIONS
-- VIEW


view : Model -> { title : String, body : List (Html.Styled.Html Msg) }
view model =
    { title = "HTTP Example"
    , body = body model
    }


body : Model -> List (Html.Styled.Html Msg)
body model =
    [ button
        [ onClick Refresh
        , css
            [ displayFlex
            , flexDirection column
            ]
        ]
        [ text "Refresh!" ]
    , case model of
        Failure ->
            text "Sorry an error has occurred during the request!"

        Loading ->
            text "Loading..."

        Success s ->
            pre [] [ text s ]
    ]
