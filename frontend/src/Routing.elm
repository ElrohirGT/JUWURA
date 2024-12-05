module Routing exposing (BasePath, NavigationHrefs, Route(..), generateRoutingFuncs, parseUrl)

import Html.Styled exposing (Attribute)
import Html.Styled.Attributes exposing (href)
import Url exposing (Url)
import Url.Parser as P exposing ((</>), Parser, s)


{-| The base path for routing.

It's a maybe string since the application can be deployed to an environment
where there is no base path for routing.

-}
type alias BasePath =
    Maybe String



{- This code is based on: https://github.com/ElrohirGT/amazelm/blob/main/src/Routing.elm -}


type Route
    = Home
    | RouteWithParams
    | NotFound
    | Http Int
    | Json Int
    | Ports


{-| Generates a route parser given a base path.

In some cases the base path can be null,
in those cases we just navigate to the normal
route without the base path

-}
genRouteParser : BasePath -> Parser (Route -> a) a
genRouteParser maybeBasePath =
    case maybeBasePath of
        Just basePath ->
            P.oneOf
                -- /${basePath}/
                [ P.map Home (s basePath </> P.top)

                -- /${basePath}/details
                , P.map RouteWithParams (s basePath </> s "details")

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
                , P.map RouteWithParams (s "details")

                -- /http
                , P.map Http (s "http" </> P.int)

                -- /json
                , P.map Json (s "json" </> P.int)

                -- /json
                , P.map Ports (s "ports")
                ]


parseUrl : BasePath -> Url -> Route
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


{-| Holds all the functions that generate attributes to navigate between views.
-}
type alias NavigationHrefs msg =
    { goToPorts : Attribute msg
    , goToJson : Int -> Attribute msg
    , goToHttp : Int -> Attribute msg
    , goToRouteWithParams : Int -> Attribute msg
    , goToHome : Attribute msg
    }


generateRoutingFuncs : BasePath -> NavigationHrefs msg
generateRoutingFuncs basePath =
    { goToPorts = goToPorts basePath
    , goToJson = goToJson basePath
    , goToHttp = goToHttp basePath
    , goToRouteWithParams = goToRouteWithParams basePath
    , goToHome = goToHome basePath
    }


{-| Generates an href attribute to go to the PORTS page
-}
goToPorts : BasePath -> Attribute msg
goToPorts basePath =
    case basePath of
        Just s ->
            href (String.concat [ "/", s, "/ports/" ])

        Nothing ->
            href "/ports/"


{-| Generates an href attribute to go to the JSON page
-}
goToJson : BasePath -> Int -> Attribute msg
goToJson basePath id =
    case basePath of
        Just s ->
            href (String.concat [ "/", s, "/json/", String.fromInt id ])

        Nothing ->
            href (String.concat [ "/json/", String.fromInt id ])


{-| Generates an href attribute to go to the HTTP page
-}
goToHttp : BasePath -> Int -> Attribute msg
goToHttp basePath id =
    case basePath of
        Just s ->
            href (String.concat [ "/", s, "/http/", String.fromInt id ])

        Nothing ->
            href (String.concat [ "/http/", String.fromInt id ])


{-| Generates an href attribute to go to the details page
-}
goToRouteWithParams : BasePath -> Int -> Attribute msg
goToRouteWithParams basePath id =
    case basePath of
        Just s ->
            href (String.concat [ "/", s, "/details/", String.fromInt id ])

        Nothing ->
            href (String.concat [ "/details/", String.fromInt id ])


{-| Generates an href attribute to go to the home page
-}
goToHome : BasePath -> Attribute msg
goToHome basePath =
    case basePath of
        Just s ->
            href ("/" ++ s)

        Nothing ->
            href "/"
