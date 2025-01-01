module Routing exposing (BasePath, NavigationHrefs, Route(..), generateRoutingFuncs, parseUrl, pushUrlWithBasePath, replaceUrlWithBasePath)

import Browser.Navigation exposing (pushUrl, replaceUrl)
import Html.Styled exposing (Attribute)
import Html.Styled.Attributes exposing (href)
import Url exposing (Url)
import Url.Parser as P exposing ((</>), Parser, s)


{-| The base path for routing.

It's a maybe string since the application can be deployed to an environment
where there is no base path for routing.

The base path should not have any end or start slashes.
For example: "/JUWURA/" is not a valid value but "JUWURA" is!

-}
type alias BasePath =
    Maybe String



{- This code is based on: https://github.com/ElrohirGT/amazelm/blob/main/src/Routing.elm -}


type Route
    = Login
    | LoginCallback
    | Home
    | RouteWithParams
    | NotFound
    | Http Int
    | Json Int
    | Ports
    | Senku


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

                -- /${basePath}/login
                , P.map Login (s basePath </> s "login" </> P.top)

                -- /${basePath}/callback
                , P.map LoginCallback (s basePath </> s "callback" </> P.top)

                -- /${basePath}/details
                , P.map RouteWithParams (s basePath </> s "details")

                -- /${basePath}/http
                , P.map Http (s basePath </> s "http" </> P.int)

                -- /${basePath}/json
                , P.map Json (s basePath </> s "json" </> P.int)

                -- /${basePath}/ports
                , P.map Ports (s basePath </> s "ports")

                -- /${basePath}/senku
                , P.map Senku (s basePath </> s "senku")
                ]

        Nothing ->
            P.oneOf
                -- /
                [ P.map Home P.top

                -- /login
                , P.map Login (s "login")

                -- /login
                , P.map LoginCallback (s "callback")

                -- /details
                , P.map RouteWithParams (s "details")

                -- /http
                , P.map Http (s "http" </> P.int)

                -- /json
                , P.map Json (s "json" </> P.int)

                -- /json
                , P.map Ports (s "ports")

                -- /json
                , P.map Senku (s "senku")
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


replaceUrlWithBasePath : Browser.Navigation.Key -> BasePath -> String -> Cmd msg
replaceUrlWithBasePath key basepath url =
    case basepath of
        Just s ->
            replaceUrl key ("/" ++ s ++ url)

        Nothing ->
            replaceUrl key url


pushUrlWithBasePath : Browser.Navigation.Key -> BasePath -> String -> Cmd msg
pushUrlWithBasePath key basepath url =
    case basepath of
        Just s ->
            pushUrl key ("/" ++ s ++ url)

        Nothing ->
            pushUrl key url


{-| Holds all the functions that generate attributes to navigate between views.
-}
type alias NavigationHrefs msg =
    { goToPorts : Attribute msg
    , goToJson : Int -> Attribute msg
    , goToHttp : Int -> Attribute msg
    , goToRouteWithParams : Attribute msg
    , goToLogin : Attribute msg
    , goToHome : Attribute msg
    , goToSenku : Attribute msg
    }


generateRoutingFuncs : BasePath -> NavigationHrefs msg
generateRoutingFuncs basePath =
    { goToPorts = goToPorts basePath
    , goToJson = goToJson basePath
    , goToHttp = goToHttp basePath
    , goToRouteWithParams = goToRouteWithParams basePath
    , goToLogin = goToLogin basePath
    , goToHome = goToHome basePath
    , goToSenku = goToSenku basePath
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
goToRouteWithParams : BasePath -> Attribute msg
goToRouteWithParams basePath =
    case basePath of
        Just s ->
            href (String.concat [ "/", s, "/details/" ])

        Nothing ->
            href "/details/"


{-| Generates an href attribute to go to the login page
-}
goToLogin : BasePath -> Attribute msg
goToLogin basePath =
    case basePath of
        Just s ->
            href (String.concat [ "/", s, "/login/" ])

        Nothing ->
            href "/login/"


{-| Generates an href attribute to go to the home page
-}
goToHome : BasePath -> Attribute msg
goToHome basePath =
    case basePath of
        Just s ->
            href ("/" ++ s)

        Nothing ->
            href "/"


{-| Generates an href attribute to go to the senku page
-}
goToSenku : BasePath -> Attribute msg
goToSenku basePath =
    case basePath of
        Just s ->
            href (String.concat [ "/", s, "/senku" ])

        Nothing ->
            href "/"
