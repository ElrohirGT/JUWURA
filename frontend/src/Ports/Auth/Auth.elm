port module Ports.Auth.Auth exposing (loginRedirect, logoutRedirect, onOauthResult, parseCallback)


port loginRedirect : () -> Cmd msg


port logoutRedirect : () -> Cmd msg


port parseCallback : () -> Cmd msg


port onOauthResult : (Bool -> msg) -> Sub msg
