module Routing exposing (Route(..), goToHome, goToHttp, goToJson, goToPorts, goToRouteWithParams, parseUrl)

import Html.Styled exposing (Attribute)
import Html.Styled.Attributes exposing (href)
import Url exposing (Url)
import Url.Parser as P exposing ((</>), Parser, s)



{- This code is based on: https://github.com/ElrohirGT/amazelm/blob/main/src/Routing.elm -}


type Route
    = Home
    | RouteWithParams Int
    | NotFound
    | Http Int
    | Json Int
    | Ports


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

                -- /${basePath}/http
                , P.map Http (s basePath </> s "http" </> P.int)

                -- /${basePath}/json
                , P.map Json (s basePath </> s "json" </> P.int)

                -- /${basePath}/ports
                , P.map Ports (s basePath </> s "ports")
                ]

        Nothing ->
            P.oneOf
                -- /
                [ P.map Home P.top

                -- /details
                , P.map RouteWithParams (s "details" </> P.int)

                -- /http
                , P.map Http (s "http" </> P.int)

                -- /json
                , P.map Json (s "json" </> P.int)

                -- /json
                , P.map Ports (s "ports")
                ]


parseUrl : Maybe String -> Url -> Route
parseUrl basePath url =
    let
        routeParser : Parser (Route -> a) a
        routeParser =
            genRouteParser basePath

        parsedUrl : Maybe Route
        parsedUrl =
            P.parse routeParser url
    in
    case parsedUrl of
        Just a ->
            a

        Nothing ->
            NotFound


{-| Generates an href attribute to go to the PORTS page
-}
goToPorts : Attribute msg
goToPorts =
    href "ports/"


{-| Generates an href attribute to go to the JSON page
-}
goToJson : Int -> Attribute msg
goToJson id =
    href (String.concat [ "json/", String.fromInt id ])


{-| Generates an href attribute to go to the HTTP page
-}
goToHttp : Int -> Attribute msg
goToHttp id =
    href (String.concat [ "http/", String.fromInt id ])


{-| Generates an href attribute to go to the details page
-}
goToRouteWithParams : Int -> Attribute msg
goToRouteWithParams id =
    href (String.concat [ "details/", String.fromInt id ])


{-| Generates an href attribute to go to the home page
-}
goToHome : Attribute msg
goToHome =
    href "/"
