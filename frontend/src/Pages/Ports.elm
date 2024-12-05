port module Pages.Ports exposing (Model, Msg(..), init, subscriptions, update, view)

import Html.Styled exposing (button, div, h1, input, li, text, ul)
import Html.Styled.Attributes exposing (placeholder, type_, value)
import Html.Styled.Events exposing (on, onClick, onInput)
import Json.Decode as D



{-
   Excersice:
   - Modify the JS por file to throw an exception 80% of the time when it send a message.
   What happens? Can we make the application display an error message instead?
-}
-- PORTS


port sendMessage : String -> Cmd msg


port messageReceiver : (String -> msg) -> Sub msg



-- MODEL


type alias Model =
    { draft : String
    , messages : List String
    }


init : ( Model, Cmd Msg )
init =
    ( { draft = "", messages = [] }
    , Cmd.none
    )



-- UPDATE


type Msg
    = DraftChanged String
    | Send
    | Recv String



-- Use the `sendMessage` port when someone presses ENTER or clicks
-- the "Send" button. Check out index.html to see the corresponding
-- JS where this is piped into a WebSocket.
--


update : Model -> Msg -> ( Model, Cmd Msg )
update model msg =
    case msg of
        DraftChanged draft ->
            ( { model | draft = draft }
            , Cmd.none
            )

        Send ->
            ( { model | draft = "" }
            , sendMessage model.draft
            )

        Recv message ->
            ( { model | messages = model.messages ++ [ message ] }
            , Cmd.none
            )



-- SUBSCRIPTIONS
-- Subscribe to the `messageReceiver` port to hear about messages coming in
-- from JS. Check out the index.html file to see how this is hooked up to a
-- WebSocket.
--


subscriptions : Model -> Sub Msg
subscriptions _ =
    messageReceiver Recv



-- VIEW


view : Model -> { title : String, body : List (Html.Styled.Html Msg) }
view model =
    { title = "Ports Example"
    , body =
        [ div []
            [ h1 [] [ text "Echo Chat" ]
            , ul []
                (List.map (\msg -> li [] [ text msg ]) model.messages)
            , input
                [ type_ "text"
                , placeholder "Draft"
                , onInput DraftChanged
                , on "keydown" (ifIsEnter Send)
                , value model.draft
                ]
                []
            , button [ onClick Send ] [ text "Send" ]
            ]
        ]
    }



-- DETECT ENTER


ifIsEnter : msg -> D.Decoder msg
ifIsEnter msg =
    D.field "key" D.string
        |> D.andThen
            (\key ->
                if key == "Enter" then
                    D.succeed msg

                else
                    D.fail "some other key"
            )
