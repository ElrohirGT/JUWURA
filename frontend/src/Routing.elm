module Routing exposing (..)

import Html.Styled.Attributes exposing (href)
import Url exposing (Url)
import Url.Parser as P exposing ((</>), Parser, s)



{- This code is based on: https://github.com/ElrohirGT/amazelm/blob/main/src/Routing.elm -}


type Route
    = Home
    | RouteWithParams Int
    | NotFound


{-| Generates a route parser given a base path.

In some cases the base path can be null,
in those cases we just navigate to the normal
route without the base path

-}
genRouteParser : Maybe String -> Parser (Route -> a) a
genRouteParser maybeBasePath =
    case maybeBasePath of
        Just basePath ->
            P.oneOf
                -- /${basePath}/
                [ P.map Home (s basePath </> P.top)

                -- /${basePath}/details
                , P.map RouteWithParams (s basePath </> s "details" </> P.int)
                ]

        Nothing ->
            P.oneOf
                -- /
                [ P.map Home P.top

                -- /details
                , P.map RouteWithParams (s "details" </> P.int)
                ]


parseUrl : Maybe String -> Url -> Route
parseUrl basePath url =
    let
        routeParser =
            genRouteParser basePath
    in
    case P.parse routeParser url of
        Just a ->
            a

        Nothing ->
            NotFound


{-| Generates an href attribute to go to the details page
-}
goToRouteWithParams id =
    href (String.concat [ "details/", String.fromInt id ])


{-| Generates an href attribute to go to the home page
-}
goToHome =
    href "/"
