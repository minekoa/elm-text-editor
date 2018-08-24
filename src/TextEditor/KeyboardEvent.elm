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


considerKeyboardEvent : (KeyboardEvent -> Result msg msg) -> Json.Decode.Decoder { message : msg, stopPropagation : Bool, preventDefault : Bool }
considerKeyboardEvent func =
    Json.Decode.andThen
        (\event ->
            case func event of
                Ok okmsg ->
                    Json.Decode.succeed { message = okmsg, stopPropagation = True, preventDefault = True }

                Err ngmsg ->
                    Json.Decode.succeed { message = ngmsg, stopPropagation = False, preventDefault = False }
        )
        decodeKeyboardEvent


