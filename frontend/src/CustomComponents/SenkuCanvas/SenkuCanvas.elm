module CustomComponents.SenkuCanvas.SenkuCanvas exposing (..)

import Html.Styled exposing (Html, node)
import Html.Styled.Attributes exposing (attribute)
import Html.Styled.Events exposing (on)
import Json.Decode as Decode



-- MODEL


type alias Model =
    { widthPct : Float
    , heightPct : Float
    }


init : Float -> Float -> Model
init widthPct heightPct =
    Model widthPct heightPct



-- EVENTS


onCreateTask : msg -> Html.Styled.Attribute msg
onCreateTask msg =
    on "uwu-senku:create-task" (Decode.succeed msg)



-- VIEW


view : Model -> List (Html.Styled.Attribute msg) -> Html msg
view model attrs =
    node "uwu-senku"
        ([ attribute "widthPct" (String.fromFloat model.widthPct)
         , attribute "heightPct" (String.fromFloat model.heightPct)
         ]
            ++ attrs
        )
        []
