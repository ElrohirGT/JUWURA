module CustomComponents.SenkuCanvas.SenkuCanvas exposing (Cell, CellConnection, CellCoordinates, CreateConnectionEventDetail, CreateTaskEventDetail, DeleteConnectionEventDetail, DeleteTaskEventDetail, Model, SenkuCanvasEvent, SenkuState, TaskChangedCoordinatesEventDetail, ViewTaskEventDetail, init, onCreateConnection, onCreateTask, onDeleteConnection, onDeleteTask, onTaskChangedCoordinates, onViewTask, senkuStateDecoder, view)

import Html.Styled exposing (Html, node)
import Html.Styled.Attributes exposing (attribute)
import Html.Styled.Events exposing (on)
import Json.Decode as Decode exposing (float, int, list, nullable, string)
import Json.Decode.Pipeline exposing (required)
import Json.Encode as Encode



-- EVENT HELPERS


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


type alias CellCoordinates =
    { row : Int
    , column : Int
    }


cellCoordinatesDecoder : Decode.Decoder CellCoordinates
cellCoordinatesDecoder =
    Decode.succeed CellCoordinates
        |> required "row" int
        |> required "column" int


cellCoordinatesEncoder : CellCoordinates -> Encode.Value
cellCoordinatesEncoder value =
    Encode.object
        [ ( "row", Encode.int value.row )
        , ( "column", Encode.int value.column )
        ]


type alias CellConnection =
    { start : CellCoordinates
    , end : CellCoordinates
    }


cellConnectionDecoder : Decode.Decoder CellConnection
cellConnectionDecoder =
    Decode.succeed CellConnection
        |> required "start" cellCoordinatesDecoder
        |> required "end" cellCoordinatesDecoder


cellConnectionEncoder : CellConnection -> Encode.Value
cellConnectionEncoder value =
    Encode.object
        [ ( "start", cellCoordinatesEncoder value.start )
        , ( "end", cellCoordinatesEncoder value.end )
        ]


type alias Cell =
    { id : Int
    , due_date : Maybe String
    , title : Maybe String
    , status : Maybe String
    , icon : String
    , progress : Float
    , coordinates : CellCoordinates
    }


cellDecoder : Decode.Decoder Cell
cellDecoder =
    Decode.succeed Cell
        |> required "id" int
        |> required "due_date" (nullable string)
        |> required "title" (nullable string)
        |> required "status" (nullable string)
        |> required "icon" string
        |> required "progress" float
        |> required "coordinates" cellCoordinatesDecoder


type alias SenkuState =
    { cells : List (List (Maybe Cell))
    , connections : List CellConnection
    }


senkuStateDecoder : Decode.Decoder SenkuState
senkuStateDecoder =
    Decode.succeed SenkuState
        |> required "cells" (list (list (nullable cellDecoder)))
        |> required "connections" (list cellConnectionDecoder)


maybeEncoder : (a -> Encode.Value) -> Maybe a -> Encode.Value
maybeEncoder encoder value =
    case value of
        Just a ->
            encoder a

        Nothing ->
            Encode.null


cellEncoder : Cell -> Encode.Value
cellEncoder cell =
    Encode.object
        [ ( "id", Encode.int cell.id )
        , ( "due_date", maybeEncoder Encode.string cell.due_date )
        , ( "title", maybeEncoder Encode.string cell.title )
        , ( "status", maybeEncoder Encode.string cell.status )
        , ( "icon", Encode.string cell.icon )
        , ( "progress", Encode.float cell.progress )
        , ( "coordinates"
          , cellCoordinatesEncoder cell.coordinates
          )
        ]


senkuStateEncoder : SenkuState -> Encode.Value
senkuStateEncoder state =
    Encode.object
        [ ( "cells", Encode.list (Encode.list (maybeEncoder cellEncoder)) state.cells )
        , ( "connections", Encode.list cellConnectionEncoder state.connections )
        ]


type alias Model =
    { widthPct : Float
    , heightPct : Float
    , state : SenkuState
    , projectId : Int
    }


init : Float -> Float -> SenkuState -> Int -> Model
init widthPct heightPct senkuState projectId =
    Model widthPct heightPct senkuState projectId



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



-- DeleteTaskEvent


type alias DeleteConnectionEventDetail =
    { originTaskId : Int
    , targetTaskId : Int
    }


deleteConnectionEventDetail : Decode.Decoder DeleteConnectionEventDetail
deleteConnectionEventDetail =
    Decode.succeed DeleteConnectionEventDetail
        |> required "originTaskId" int
        |> required "targetTaskId" int


onDeleteConnection : (DeleteConnectionEventDetail -> msg) -> Html.Styled.Attribute msg
onDeleteConnection mapper =
    on "uwu-senku:delete-connection"
        (senkuCanvasEventDecoder deleteConnectionEventDetail
            |> Decode.map detailsMapper
            |> Decode.map mapper
        )



-- VIEW


view : Model -> List (Html.Styled.Attribute msg) -> Html msg
view model attrs =
    node "uwu-senku"
        ([ attribute "widthPct" (String.fromFloat model.widthPct)
         , attribute "heightPct" (String.fromFloat model.heightPct)
         , attribute "senkuState" (Encode.encode 0 (senkuStateEncoder model.state))
         , attribute "projectId" (Encode.encode 0 (Encode.int model.projectId))
         ]
            ++ attrs
        )
        []
