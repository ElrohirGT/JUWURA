module Data.Task exposing (..)

import Json.Decode as Decode exposing (int, list, nullable, string)
import Json.Decode.Pipeline exposing (required)


type alias TaskField =
    { id : Int
    , name : String
    , fieldType : String
    , value : Maybe String
    }


taskFieldDecoder : Decode.Decoder TaskField
taskFieldDecoder =
    Decode.succeed TaskField
        |> required "id" int
        |> required "name" string
        |> required "type" string
        |> required "value" (nullable string)


type alias Task =
    { id : Int
    , projectId : Int
    , parentId : Maybe Int
    , displayId : String
    , icon : String
    , fields : List TaskField
    }


taskDecoder : Decode.Decoder Task
taskDecoder =
    Decode.succeed Task
        |> required "id" int
        |> required "project_id" int
        |> required "parent_id" (nullable int)
        |> required "display_id" string
        |> required "icon" string
        |> required "fields" (list taskFieldDecoder)
