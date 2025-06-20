port module Ports.Ws.Ws exposing (WSRequests(..), WSResponses(..), onMessage, sendMessage)

import CustomComponents.SenkuCanvas.SenkuCanvas as SenkuCanvas
import Data.Task exposing (Task, taskDecoder)
import Json.Decode as Decode exposing (null, string)
import Json.Decode.Pipeline exposing (required)
import Json.Encode as Encode
import Utils exposing (maybeEncoder)


type WSRequests
    = ConnectRequest
        { projectId : Int
        , email : String
        }
    | GetSenkuStateRequest { projectId : Int }
    | CreateTaskRequest SenkuCanvas.CreateTaskEventDetail
    | TaskChangedCordsRequest SenkuCanvas.TaskChangedCoordinatesEventDetail
    | CreateTaskConnectionRequest SenkuCanvas.CreateConnectionEventDetail


type WSResponses
    = UserConnectedResponse String
    | ConnectionErrorResponse
    | GetSenkuStateResponse SenkuCanvas.SenkuState
    | CreateTaskResponse Task
    | TaskChangedCordsResponse Task
    | CreateTaskConnectionResponse SenkuCanvas.CellConnection


userConnectedResponseDecoder : Decode.Decoder WSResponses
userConnectedResponseDecoder =
    Decode.succeed UserConnectedResponse
        |> required "user_connected" string


connectionErrorResponseDecoder : Decode.Decoder WSResponses
connectionErrorResponseDecoder =
    let
        toDecoder : a -> WSResponses
        toDecoder _ =
            ConnectionErrorResponse
    in
    Decode.succeed toDecoder
        |> required "connection_error" (null ())


unit : a -> a
unit v =
    v


getSenkuStateResponseDecoder : Decode.Decoder WSResponses
getSenkuStateResponseDecoder =
    Decode.succeed GetSenkuStateResponse
        |> required "get_senku_state"
            (Decode.succeed unit
                |> required "state" SenkuCanvas.senkuStateDecoder
            )


createTaskResponseDecoder : Decode.Decoder WSResponses
createTaskResponseDecoder =
    Decode.succeed CreateTaskResponse
        |> required "create_task"
            (Decode.succeed unit
                |> required "task" taskDecoder
            )


taskChangedCordsResponseDecoder : Decode.Decoder WSResponses
taskChangedCordsResponseDecoder =
    Decode.succeed TaskChangedCordsResponse
        |> required "change_task_cords"
            (Decode.succeed unit
                |> required "task" taskDecoder
            )


createTaskConnectionResponseDecoder : Decode.Decoder WSResponses
createTaskConnectionResponseDecoder =
    Decode.succeed CreateTaskConnectionResponse
        |> required "create_task_connection"
            (Decode.succeed unit
                |> required "connection" SenkuCanvas.cellConnectionDecoder
            )


wsPortResponsesDecoder : Decode.Decoder WSResponses
wsPortResponsesDecoder =
    Decode.oneOf
        [ userConnectedResponseDecoder
        , connectionErrorResponseDecoder
        , getSenkuStateResponseDecoder
        , createTaskResponseDecoder
        , taskChangedCordsResponseDecoder
        , createTaskConnectionResponseDecoder
        ]


wsPortMessagesEncoder : WSRequests -> Encode.Value
wsPortMessagesEncoder value =
    case value of
        ConnectRequest payload ->
            Encode.object
                [ ( "type", Encode.string "CONNECT" )
                , ( "projectId", Encode.int payload.projectId )
                , ( "email", Encode.string payload.email )
                ]

        GetSenkuStateRequest payload ->
            Encode.object
                [ ( "type", Encode.string "GET_SENKU_STATE" )
                , ( "payload"
                  , Encode.object
                        [ ( "get_senku_state"
                          , Encode.object
                                [ ( "project_id", Encode.int payload.projectId )
                                ]
                          )
                        ]
                  )
                ]

        CreateTaskRequest payload ->
            Encode.object
                [ ( "type", Encode.string "CREATE_TASK_REQUEST" )
                , ( "payload"
                  , Encode.object
                        [ ( "create_task"
                          , Encode.object
                                [ ( "project_id", Encode.int payload.projectId )
                                , ( "parent_id", maybeEncoder Encode.int payload.parentId )
                                , ( "icon", Encode.string payload.icon )
                                , ( "cords", SenkuCanvas.cellCoordinatesEncoder payload.cords )
                                ]
                          )
                        ]
                  )
                ]

        TaskChangedCordsRequest payload ->
            Encode.object
                [ ( "type", Encode.string "TASK_CHANGED_CORDS_REQUEST" )
                , ( "payload"
                  , Encode.object
                        [ ( "change_task_cords"
                          , Encode.object
                                [ ( "task_id", Encode.int payload.taskId )
                                , ( "cords", SenkuCanvas.cellCoordinatesEncoder payload.coordinates )
                                ]
                          )
                        ]
                  )
                ]

        CreateTaskConnectionRequest payload ->
            Encode.object
                [ ( "type", Encode.string "CREATE_TASK_CONNECTION_REQUEST" )
                , ( "payload"
                  , Encode.object
                        [ ( "create_task_connection"
                          , Encode.object
                                [ ( "origin_id", Encode.int payload.originTaskId )
                                , ( "target_id", Encode.int payload.targetTaskId )
                                ]
                          )
                        ]
                  )
                ]


port wsSendMessage : Encode.Value -> Cmd msg


sendMessage : WSRequests -> Cmd msg
sendMessage message =
    wsSendMessage (wsPortMessagesEncoder message)


port wsMessageReceiver : (String -> msg) -> Sub msg


onMessage : (Result Decode.Error WSResponses -> msg) -> Sub msg
onMessage msgMapper =
    wsMessageReceiver (Decode.decodeString wsPortResponsesDecoder)
        |> Sub.map msgMapper
