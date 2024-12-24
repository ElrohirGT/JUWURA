module Data.Issue exposing (..)


type alias IssueField =
    { id : Int
    , name : String
    , issueType : String
    , value : Maybe String
    }


type alias Issue =
    { id : Int
    , parentId : Maybe Int
    , projectId : Int
    , shortTitle : String
    , icon : String
    , fields : List IssueField
    }
