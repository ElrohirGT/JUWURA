module Utils exposing (maybeEncoder, viteAsset)

{-| Common utilities used in the project
-}

import Json.Encode as Encode


{-| Imports an asset using vite from a certain string path.

For example:

    viteAsset "./javascript.svg"

-}
viteAsset : String -> String
viteAsset path =
    "VITE_PLUGIN_HELPER_ASSET" ++ path


maybeEncoder : (a -> Encode.Value) -> Maybe a -> Encode.Value
maybeEncoder encoder value =
    case value of
        Just a ->
            encoder a

        Nothing ->
            Encode.null
