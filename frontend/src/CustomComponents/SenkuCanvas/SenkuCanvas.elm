module CustomComponents.SenkuCanvas.SenkuCanvas exposing (..)

import Html.Styled exposing (Html, node)
import Html.Styled.Attributes exposing (attribute)
import Html.Styled.Events exposing (on)
import Json.Decode as Decode exposing (int, nullable, oneOf, string)
import Json.Decode.Pipeline exposing (optional, required)



-- MODEL


type alias Model =
    { widthPct : Float
    , heightPct : Float
    }


init : Float -> Float -> Model
init widthPct heightPct =
    Model widthPct heightPct



-- EVENTS


type alias CreateTaskEventDetail =
    { parentId : Maybe Int
    , projectId : Int
    , icon : String
    }


createTaskDetailDecoder : Decode.Decoder CreateTaskEventDetail
createTaskDetailDecoder =
    Decode.succeed CreateTaskEventDetail
        |> required "parent_id" (nullable int)
        |> required "project_id" int
        |> required "icon" string


type alias CreateTaskEvent =
    { detail : CreateTaskEventDetail
    }


createTaskEventDecoder : Decode.Decoder CreateTaskEvent
createTaskEventDecoder =
    Decode.succeed CreateTaskEvent
        |> required "detail" createTaskDetailDecoder


onCreateTask : (CreateTaskEvent -> msg) -> Html.Styled.Attribute msg
onCreateTask mapper =
    on "uwu-senku:create-task" (Decode.map mapper createTaskEventDecoder)



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
