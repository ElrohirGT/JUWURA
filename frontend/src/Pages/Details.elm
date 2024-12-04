module Pages.Details exposing (Model, Msg, update, view)

import Css exposing (column, displayFlex, flexDirection)
import Html.Styled exposing (a, button, div, h1, text)
import Html.Styled.Attributes exposing (css)
import Html.Styled.Events exposing (onClick)
import Routing exposing (goToHome)



-- MODEL


type alias Model =
    { count : Int
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
        , a [ goToHome ] [ text "Return to Home..." ]
        ]
    ]
