module TextEditor.Option exposing
    ( Option
    , editorLikeOptions
    , notepadLikeOptions
    , jsonEncode
    , jsonDecode
    )
{-|
@docs Option

## Default options

@docs notepadLikeOptions, editorLikeOptions

## JSON encode / JSON decode

@docs jsonEncode, jsonDecode
-}

import Json.Encode
import Json.Decode

{-| Editor Options, for Command and Rendering
-}
type alias Option =
    { tabOrder : Int
    , indentTabsMode : Bool
    , showControlCharactor : Bool
    }


{-| Create Editor Options (notepad like style)

* tabOrder = 8
* indentTabsMode = True
* showControlCharactor = False
-}
notepadLikeOptions : Option
notepadLikeOptions =
    { tabOrder = 8
    , indentTabsMode = True
    , showControlCharactor = False
    }

{-| Create Editor Options (text editor like)

* tabOrder = 4
* indentTabsMode = False
* showControlCharactor = False
-}
editorLikeOptions : Option
editorLikeOptions =
    { tabOrder = 4
    , indentTabsMode = False
    , showControlCharactor = True
    }


{-| Encode to JSON

```json
{ "tabOrder" : 8               // int
, "indentTabsMode" : true      // bool
, "showControlCharactor": true // bool
```
-}
jsonEncode : Option -> Json.Encode.Value
jsonEncode opt =
    Json.Encode.object 
        [ ("tabOrder"            , opt.tabOrder |> Json.Encode.int)
        , ("indentTabsMode"      , opt.indentTabsMode  |> Json.Encode.bool)
        , ("showControlCharactor", opt.showControlCharactor |> Json.Encode.bool)
        ]
{-| Decode from JSON

```json
{ "tabOrder" : 8               // int
, "indentTabsMode" : true      // bool
, "showControlCharactor": true // bool
```
-}
jsonDecode : Json.Decode.Decoder Option
jsonDecode =
    Json.Decode.map3
        Option
            (Json.Decode.field "tabOrder"             Json.Decode.int)
            (Json.Decode.field "indentTabsMode"       Json.Decode.bool)
            (Json.Decode.field "showControlCharactor" Json.Decode.bool)



