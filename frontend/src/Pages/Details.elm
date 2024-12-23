module Pages.Details exposing (Model, Msg, init, update, view)

import Css exposing (column, displayFlex, flexDirection)
import Html.Styled exposing (a, button, div, h1, text)
import Html.Styled.Attributes exposing (css)
import Html.Styled.Events exposing (onClick)
import Routing exposing (BasePath, NavigationHrefs, generateRoutingFuncs)



{-

   Exercises:
   - Try to make the initial count depend on a URL parameter!
   So if I navigate to /details/10 it should start in 10 instead of 0!

-}
-- MODEL


type alias Model =
    { count : Int
    , navigation : NavigationHrefs Msg
    }


init : BasePath -> Model
init basePath =
    { count = 0
    , navigation = generateRoutingFuncs basePath
    }



-- UPDATE


type Msg
    = Increment
    | Decrement


update : Model -> Msg -> Model
update model msg =
    case msg of
        Increment ->
            { model | count = model.count + 1 }

        Decrement ->
            { model | count = model.count - 1 }



-- VIEW


view : Model -> { title : String, body : List (Html.Styled.Html Msg) }
view model =
    { title = "Details!"
    , body = body model
    }


body : Model -> List (Html.Styled.Html Msg)
body model =
    [ div
        [ css
            [ displayFlex
            , flexDirection column
            ]
        ]
        [ button [ onClick Decrement ] [ text "-" ]
        , h1 [] [ text (String.fromInt model.count) ]
        , button [ onClick Increment ] [ text "+" ]
        , a [ model.navigation.goToHome ] [ text "Return to Home..." ]
        ]
    ]
