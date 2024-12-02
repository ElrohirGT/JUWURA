module Main exposing (main)

import Browser
import Css exposing (display, inlineBlock, padding, rem)
import Html.Styled exposing (Html, button, div, img, text, toUnstyled)
import Html.Styled.Attributes exposing (css, src)
import Html.Styled.Events exposing (onClick)



{-
   Imports an asset using vite from a certain string path.
-}


viteAsset : String -> String
viteAsset path =
    "VITE_PLUGIN_HELPER_ASSET" ++ path


main =
    Browser.sandbox { init = 0, update = update, view = view >> toUnstyled }


type Msg
    = Increment
    | Decrement


update : Msg -> number -> number
update msg model =
    case msg of
        Increment ->
            model + 1

        Decrement ->
            model - 1


view : Int -> Html Msg
view model =
    div []
        [ button [ onClick Decrement ] [ text "-" ]
        , div [] [ text (String.fromInt model) ]
        , button
            [ onClick Increment
            , css
                [ display inlineBlock
                , padding (1 |> rem)
                ]
            ]
            [ text "+" ]
        , img [ "./javascript.svg" |> viteAsset |> src ] []
        ]
