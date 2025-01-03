module CustomComponents.SenkuCanvas.SenkuCanvas exposing (..)

import Html.Styled exposing (Html, node)
import Html.Styled.Attributes exposing (attribute)
import Html.Styled.Events exposing (on)
import Json.Decode as Decode exposing (int, nullable, oneOf, string)
import Json.Decode.Pipeline exposing (optional, required)


type alias SenkuCanvasEvent detail =
    { detail : detail
    }


senkuCanvasEventDecoder : Decode.Decoder detailDecoder -> Decode.Decoder (SenkuCanvasEvent detailDecoder)
senkuCanvasEventDecoder detailDecoder =
    Decode.succeed SenkuCanvasEvent |> required "detail" detailDecoder


detailsMapper : SenkuCanvasEvent detail -> detail
detailsMapper ev =
    ev.detail



-- MODEL


type alias Model =
    { widthPct : Float
    , heightPct : Float
    }


init : Float -> Float -> Model
init widthPct heightPct =
    Model widthPct heightPct



-- EVENTS
-- CreateTaskEvent


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


onCreateTask : (CreateTaskEventDetail -> msg) -> Html.Styled.Attribute msg
onCreateTask mapper =
    on "uwu-senku:create-task"
        (senkuCanvasEventDecoder createTaskDetailDecoder
            |> Decode.map detailsMapper
            |> Decode.map mapper
        )



-- TaskChangedCoordinatesEvent


type alias CellCoordinates =
    { row : Int
    , column : Int
    }


type alias TaskChangedCoordinatesEventDetail =
    { taskId : Int
    , coordinates : CellCoordinates
    }


cellCoordsDecoder : Decode.Decoder CellCoordinates
cellCoordsDecoder =
    Decode.succeed CellCoordinates
        |> required "row" int
        |> required "column" int


taskChangedCoordinatesEventDetailDecoder : Decode.Decoder TaskChangedCoordinatesEventDetail
taskChangedCoordinatesEventDetailDecoder =
    Decode.succeed TaskChangedCoordinatesEventDetail
        |> required "taskId" int
        |> required "coordinates" cellCoordsDecoder


onTaskChangedCoordinates : (TaskChangedCoordinatesEventDetail -> msg) -> Html.Styled.Attribute msg
onTaskChangedCoordinates mapper =
    on "uwu-senku:task-changed-coordinates"
        (senkuCanvasEventDecoder taskChangedCoordinatesEventDetailDecoder
            |> Decode.map detailsMapper
            |> Decode.map mapper
        )



-- CreateConnectionEvent


type alias CreateConnectionEventDetail =
    { originTaskId : Int
    , targetTaskId : Int
    }


createConnectionEventDetailDecoder : Decode.Decoder CreateConnectionEventDetail
createConnectionEventDetailDecoder =
    Decode.succeed CreateConnectionEventDetail
        |> required "originTaskId" int
        |> required "targetTaskId" int


onCreateConnection : (CreateConnectionEventDetail -> msg) -> Html.Styled.Attribute msg
onCreateConnection mapper =
    on "uwu-senku:create-connection"
        (senkuCanvasEventDecoder createConnectionEventDetailDecoder
            |> Decode.map detailsMapper
            |> Decode.map mapper
        )



-- DeleteTaskEvent


type alias DeleteTaskEventDetail =
    { taskId : Int
    }


deleteTaskEventDetailDecoder : Decode.Decoder ViewTaskEventDetail
deleteTaskEventDetailDecoder =
    Decode.succeed DeleteTaskEventDetail
        |> required "taskId" int


onDeleteTask : (ViewTaskEventDetail -> msg) -> Html.Styled.Attribute msg
onDeleteTask mapper =
    on "uwu-senku:delete-task"
        (senkuCanvasEventDecoder deleteTaskEventDetailDecoder
            |> Decode.map detailsMapper
            |> Decode.map mapper
        )



-- ViewTaskEvent


type alias ViewTaskEventDetail =
    { taskId : Int
    }


viewTaskEventDetailDecoder : Decode.Decoder ViewTaskEventDetail
viewTaskEventDetailDecoder =
    Decode.succeed ViewTaskEventDetail
        |> required "taskId" int


onViewTask : (ViewTaskEventDetail -> msg) -> Html.Styled.Attribute msg
onViewTask mapper =
    on "uwu-senku:view-task"
        (senkuCanvasEventDecoder viewTaskEventDetailDecoder
            |> Decode.map detailsMapper
            |> Decode.map mapper
        )



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
