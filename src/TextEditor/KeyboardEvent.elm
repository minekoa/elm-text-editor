module TextEditor.KeyboardEvent exposing
    ( KeyboardEvent
    , decodeKeyboardEvent
    , considerKeyboardEvent
    )

import Json.Decode

type alias KeyboardEvent = 
    { altKey : Bool
    , ctrlKey : Bool
    , keyCode : Int
    , metaKey : Bool
    , repeat : Bool
    , shiftKey : Bool
    }

decodeKeyboardEvent : Json.Decode.Decoder KeyboardEvent
decodeKeyboardEvent =
    Json.Decode.map6 KeyboardEvent
        (Json.Decode.field "altKey" Json.Decode.bool)
        (Json.Decode.field "ctrlKey" Json.Decode.bool)
        (Json.Decode.field "keyCode" Json.Decode.int)
        (Json.Decode.field "metaKey" Json.Decode.bool)
        (Json.Decode.field "repeat" Json.Decode.bool)
        (Json.Decode.field "shiftKey" Json.Decode.bool)    


considerKeyboardEvent : (KeyboardEvent -> Maybe msg) -> Json.Decode.Decoder msg
considerKeyboardEvent func =
    Json.Decode.andThen
        (\event ->
            case func event of
                Just msg ->
                    Json.Decode.succeed msg

                Nothing ->
                    Json.Decode.fail "Ignoring keyboard event"
        )
        decodeKeyboardEvent


