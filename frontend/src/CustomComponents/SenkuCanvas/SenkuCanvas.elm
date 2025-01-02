module CustomComponents.SenkuCanvas.SenkuCanvas exposing (..)

import Html.Styled exposing (Html, node)
import Html.Styled.Attributes exposing (attribute)



-- MODEL


type alias Model =
    { widthPct : Float
    , heightPct : Float
    }


init : Float -> Float -> Model
init widthPct heightPct =
    Model widthPct heightPct



-- VIEW


view : Model -> Html msg
view model =
    node "uwu-senku"
        [ attribute "widthPct" (String.fromFloat model.widthPct)
        , attribute "heightPct" (String.fromFloat model.heightPct)
        ]
        []
