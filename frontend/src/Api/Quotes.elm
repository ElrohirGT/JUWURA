module Api.Quotes exposing (getRandomQuoteDecoder)

import Data.Quote exposing (Quote)
import Json.Decode as Decode exposing (Decoder, int, string)
import Json.Decode.Pipeline exposing (required)


{-| Decodes the response from the getRandomQuote endpoint
-}
getRandomQuoteDecoder : Decoder Quote
getRandomQuoteDecoder =
    Decode.succeed Quote
        |> required "quote" string
        |> required "source" string
        |> required "author" string
        |> required "year" int
