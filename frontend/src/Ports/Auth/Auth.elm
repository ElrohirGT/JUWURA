port module Ports.Auth.Auth exposing (UserProfile, checkUserSession, loginRedirect, logoutRedirect, onCheckedUserSession, onOauthResult, parseCallback)

import Pages.Http exposing (Model(..))


type alias UserProfile =
    { username : String
    , email : String
    , photo : String
    }


port loginRedirect : () -> Cmd msg


port logoutRedirect : () -> Cmd msg


port parseCallback : () -> Cmd msg


port onOauthResult : (Bool -> msg) -> Sub msg


port checkUserSession : () -> Cmd msg


port onCheckedUserSession : ({ success : Bool, profile : Maybe UserProfile } -> msg) -> Sub msg
