port module Ports.LocalStorage.LocalStorage exposing (getLocalStorage, onValueLocalStorage, setLocalStorage)

{-| A module to interact with localStorage using ports.


### Usage

1.  Use `set` to store a key-value pair in localStorage.
2.  Use `get` to retrieve a value by key.
3.  Use `subscribe` to listen for changes to localStorage values.

-}

-- Senders


port setLocalStorage : ( String, String ) -> Cmd msg


port getLocalStorage : String -> Cmd msg



-- Receiver


port onValueLocalStorage : (Maybe String -> msg) -> Sub msg
