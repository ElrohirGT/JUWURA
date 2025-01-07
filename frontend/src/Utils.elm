module Utils exposing (..)

{-| Common utilities used in the project
-}

import Css


{-| Imports an asset using vite from a certain string path.

For example:

    viteAsset "./javascript.svg"

-}
viteAsset : String -> String
viteAsset path =
    "VITE_PLUGIN_HELPER_ASSET" ++ path


displayGrid : Css.Style
displayGrid =
    Css.property "display" "grid"


gridTemplateRows : List String -> Css.Style
gridTemplateRows measures =
    Css.property "grid-template-rows" (measures |> List.map String.trim |> String.concat)


gridTemplateColumns : List String -> Css.Style
gridTemplateColumns measures =
    Css.property "grid-template-columns" (measures |> List.map String.trim |> String.join " ")


gridTemplateAreas : List (List String) -> Css.Style
gridTemplateAreas areas =
    let
        formatSingleArea area =
            case area of
                [] ->
                    ""

                first :: rest ->
                    "\"" ++ first ++ " " ++ String.join " " rest ++ "\""

        formatAreas list =
            list
                |> List.map formatSingleArea
                |> String.join "\n"
    in
    Css.property "grid-template-areas" (formatAreas areas)


gridArea : String -> Css.Style
gridArea area =
    Css.property "grid-area" area


gridGap : String -> Css.Style
gridGap gap =
    Css.property "grid-gap" gap


gridRowGap : String -> Css.Style
gridRowGap gap =
    Css.property "grid-row-gap" gap


gridColumnGap : String -> Css.Style
gridColumnGap gap =
    Css.property "grid-column-gap" gap


gridRepeat : String -> String -> String
gridRepeat mode measure =
    "repeat(" ++ mode ++ "," ++ measure ++ ")"


gridMinMax : String -> String -> String
gridMinMax min max =
    "minmax(" ++ min ++ "," ++ max ++ ")"
