module Utils exposing (..)

{-| Common utilities used in the project
-}


{-| Imports an asset using vite from a certain string path.

For example:

    viteAsset "./javascript.svg"

-}
viteAsset : String -> String
viteAsset path =
    "VITE_PLUGIN_HELPER_ASSET" ++ path
