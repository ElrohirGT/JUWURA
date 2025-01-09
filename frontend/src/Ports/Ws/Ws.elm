port module Ports.Ws.Ws exposing (WSRequests(..), WSResponses(..), onMessage, sendMessage)

import Json.Decode as Decode exposing (string)
import Json.Decode.Pipeline exposing (required)
import Json.Encode as Encode


type WSRequests
    = Connect
        { projectId : Int
        , email : String
        }
    | GetSenkuState { projectId : Int }


type WSResponses
    = UserConnected String


userConnectedResponseDecoder : Decode.Decoder WSResponses
userConnectedResponseDecoder =
    Decode.succeed UserConnected
        |> required "user_connected" string


wsPortResponsesDecoder : Decode.Decoder WSResponses
wsPortResponsesDecoder =
    Decode.oneOf [ userConnectedResponseDecoder ]


wsPortMessagesEncoder : WSRequests -> Encode.Value
wsPortMessagesEncoder value =
    case value of
        Connect payload ->
            Encode.object
                [ ( "type", Encode.string "CONNECT" )
                , ( "projectId", Encode.int payload.projectId )
                , ( "email", Encode.string payload.email )
                ]

        GetSenkuState payload ->
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


port wsSendMessage : Encode.Value -> Cmd msg


sendMessage : WSRequests -> Cmd msg
sendMessage message =
    wsSendMessage (wsPortMessagesEncoder message)


port wsMessageReceiver : (String -> msg) -> Sub msg


onMessage : (Result Decode.Error WSResponses -> msg) -> Sub msg
onMessage msgMapper =
    wsMessageReceiver (Decode.decodeString wsPortResponsesDecoder)
        |> Sub.map msgMapper
