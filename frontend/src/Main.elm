module Main exposing (main)

import Browser
import Html exposing (Html, button, div, img, text)
import Html.Attributes exposing (src)
import Html.Events exposing (onClick)



{-
   Imports an asset using vite from a certain string path.
-}


viteAsset : String -> String
viteAsset path =
    "VITE_PLUGIN_HELPER_ASSET" ++ path


main =
    Browser.sandbox { init = 0, update = update, view = view }


type Msg
    = Increment
    | Decrement


update msg model =
    case msg of
        Increment ->
            model + 1

        Decrement ->
            model - 1


view model =
    div []
        [ button [ onClick Decrement ] [ text "-" ]
        , div [] [ text (String.fromInt model) ]
        , button [ onClick Increment ] [ text "+" ]
        , img [ "./javascript.svg" |> viteAsset |> src ] []
        ]
