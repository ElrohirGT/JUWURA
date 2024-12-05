module Pages.Json exposing (Model(..), Msg(..), init, update, view)

import Api.Quotes exposing (getRandomQuoteDecoder)
import Css exposing (block, display, right, textAlign)
import Data.Quote exposing (Quote)
import Html.Styled exposing (blockquote, button, cite, div, h2, p, text)
import Html.Styled.Attributes exposing (css)
import Html.Styled.Events exposing (onClick)
import Http


getRandomQuote : Cmd Msg
getRandomQuote =
    Http.get
        { url = "https://elm-lang.org/api/random-quotes"
        , expect = Http.expectJson GotQuote getRandomQuoteDecoder
        }



-- MODEL


type Model
    = Loading
    | Failure
    | Success Quote


init : a -> ( Model, Cmd Msg )
init _ =
    ( Loading, getRandomQuote )



-- UPDATE


type Msg
    = GetAnother
    | GotQuote (Result Http.Error Quote)


update : Model -> Msg -> ( Model, Cmd Msg )
update _ msg =
    case msg of
        GetAnother ->
            ( Loading, getRandomQuote )

        GotQuote result ->
            case result of
                Ok quote ->
                    ( Success quote, Cmd.none )

                Err _ ->
                    ( Failure, Cmd.none )


view : Model -> { title : String, body : List (Html.Styled.Html Msg) }
view model =
    { title = "JSON example"
    , body =
        [ div []
            [ h2 [] [ text "Random Quotes" ]
            , viewQuote model
            ]
        ]
    }


viewQuote : Model -> Html.Styled.Html Msg
viewQuote model =
    case model of
        Failure ->
            div []
                [ text "I could not load a random quote for some reason. "
                , button [ onClick GetAnother ] [ text "Try Again!" ]
                ]

        Loading ->
            text "Loading..."

        Success quote ->
            div []
                [ button
                    [ onClick GetAnother
                    , css
                        [ display block
                        ]
                    ]
                    [ text "More Please!" ]
                , blockquote [] [ text quote.quote ]
                , p
                    [ css
                        [ textAlign right
                        ]
                    ]
                    [ text "— "
                    , cite [] [ text quote.source ]
                    , text (String.concat [ " by ", quote.author, " (", String.fromInt quote.year, ")" ])
                    ]
                ]
