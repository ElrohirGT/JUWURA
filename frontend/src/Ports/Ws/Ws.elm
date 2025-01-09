port module Ports.Ws.Ws exposing (WSRequests(..), WSResponses(..), onMessage, sendMessage)

import CustomComponents.SenkuCanvas.SenkuCanvas as SenkuCanvas
import Json.Decode as Decode exposing (null, string)
import Json.Decode.Pipeline exposing (required)
import Json.Encode as Encode


type WSRequests
    = ConnectRequest
        { projectId : Int
        , email : String
        }
    | GetSenkuState { projectId : Int }


type WSResponses
    = UserConnectedResponse String
    | ConnectionErrorResponse
    | GetSenkuStateResponse SenkuCanvas.SenkuState


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
        |> required "get_senku_state" (Decode.succeed unit |> required "state" SenkuCanvas.senkuStateDecoder)


wsPortResponsesDecoder : Decode.Decoder WSResponses
wsPortResponsesDecoder =
    Decode.oneOf [ userConnectedResponseDecoder, connectionErrorResponseDecoder, getSenkuStateResponseDecoder ]


wsPortMessagesEncoder : WSRequests -> Encode.Value
wsPortMessagesEncoder value =
    case value of
        ConnectRequest payload ->
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
