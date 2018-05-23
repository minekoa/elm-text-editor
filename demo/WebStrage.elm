port module WebStrage exposing (..)

port localStrage_setItem : (String, String) -> Cmd msg
port localStrage_setItemEnded : ((String, Bool) -> msg) -> Sub msg

port localStrage_getItem : String -> Cmd msg
port localStrage_getItemEnded : ((String, Maybe String) -> msg) -> Sub msg

port localStrage_removeItem : (String) -> Cmd msg
port localStrage_removeItemEnded : ((String, Bool) -> msg) -> Sub msg

port localStrage_clear : () -> Cmd msg
