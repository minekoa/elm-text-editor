module TextEditor.Style exposing
    ( Style
    , CodeStyle
    , LineNumberStyle
    , FontFaceStyle
    , ColorStyle
    , notepadLikeStyle
    , editorLikeDarkStyle
    , modernGoticStyle
    , modernMinchoStyle
    , jsonEncode
    , jsonDecode
    )

{-|
@docs Style, CodeStyle, LineNumberStyle, FontFaceStyle, ColorStyle

## Default styles
@docs notepadLikeStyle, editorLikeDarkStyle, modernGoticStyle, modernMinchoStyle

## JSON encode / JSON decode
@docs jsonEncode, jsonDecode
-}

import Json.Encode
import Json.Decode


{-| TextEditor's style

Generate the following css class in the style element.

* common .. elm-text-editor-scene
* numberLine .. elm-text-editor-linenum
* cursor .. elm-text-editor-cursor
* selection .. elm-text-editor-selection
* composing elm-text-editor-composing

To prepare a css file separately and specify the style, set the target member to Nothing

-}
type alias Style =
    { common : Maybe CodeStyle
    , numberLine : Maybe LineNumberStyle
    , cursor: Maybe ColorStyle
    , selection : Maybe FontFaceStyle
    , composing : Maybe FontFaceStyle
    , fontFaces : List (String, FontFaceStyle)
    }

{-|
If you do not want to specify it, set an empty string.
Please note that CSS syntax checking is not done.

For each member, a CSS global value (ex "inherit") and an empty string can be specified.
If you specify an empty string, that item is not specified in CSS.

```elm
{ color= "red"             -- Specify a CSS <color> value (ex "red", "#FF03EE", "rgba(0,255,64,0.5)" etc.)
, backgroundColor= "green" -- Specify a CSS <color> value (ex "red", "#FF03EE", "rgba(0,255,64,0.5)" etc.)
, opacity= "1.0"           -- Specify a value from 0 to 1. It is not `Float` type to allow "inherit"
, fontFamily = "monospace" -- Specify a font name or Comma separated list of font names. If font name contains spaces, enclose with `'`
, fontSize = "1.2em"       -- Specify a CSS <length> value(ex "1px", "1em"), a <percentage> value (ex "80%"), a <relative-size> value (ex "smaller") and a <absolute-size> value(ex "xx-small").
}
```
-}
type alias CodeStyle =
    { color: String
    , backgroundColor : String
    , opacity : String
    , fontFamily : String
    , fontSize: String
    }

{-|
If you do not want to specify it, set an empty string.
Please note that CSS syntax checking is not done.

For each member, a CSS global value (ex "inherit") and an empty string can be specified.
If you specify an empty string, that item is not specified in CSS.

```elm
{ color= "red"                    -- Specify a CSS <color> value (ex "red", "#FF03EE", "rgba(0,255,64,0.5)" etc.)
, backgroundColor= "green"        -- Specify a CSS <color> value (ex "red", "#FF03EE", "rgba(0,255,64,0.5)" etc.)
, opacity= "1.0"                  -- Specify a value from 0 to 1. It is not `Float` type to allow "inherit"
, borederRight = "1px solid gray" -- Specify the size (CSS <br-width>), style (<br-width>) and color (<color>) of the right border of the line number.
, marginRight = "1.2em"           -- Specify the Keyword 'auto' or a CSS <length> value or a <percentage> value.
}
```
-}
type alias LineNumberStyle =
   { color: String
   , backgroundColor: String
   , opacity: String
   , borderRight: String
   , marginRight : String
   }

{-|
If you do not want to specify it, set an empty string.
Please note that CSS syntax checking is not done.
-}
type alias FontFaceStyle =
    { color: String
    , backgroundColor : String
    , opacity : String
    }

{-|
Style for designating colors.

Whether color eventually becomes `color` or` background-color` depends on the object.

If you do not want to specify it, set an empty string.
Please note that CSS syntax checking is not done.

For each member, a CSS global value (ex "inherit") and an empty string can be specified.
If you specify an empty string, that item is not specified in CSS.

```elm
{ color= "red"             -- Specify a CSS <color> value (ex "red", "#FF03EE", "rgba(0,255,64,0.5)" etc.)
, backgroundColor= "green" -- Specify a CSS <color> value (ex "red", "#FF03EE", "rgba(0,255,64,0.5)" etc.)
, opacity= "1.0"           -- Specify a value from 0 to 1. It is not `Float` type to allow "inherit"
}
-}
type alias ColorStyle =
   { color: String
   , opacity: String
   }


{-|
-}
notepadLikeStyle : Style
notepadLikeStyle =
    { common = Just { color="", backgroundColor="", opacity=""
                    , fontFamily="Consolas, 'Courier New', Courier, Monaco, monospace", fontSize=""
                    }
    , numberLine = Just { color="", backgroundColor="", opacity="0.5"
                        , borderRight="1px solid silver",marginRight="0.25em"
                        }
    , cursor= Just { color="blue", opacity="0.5"}
    , selection = Just { color="white", backgroundColor="blue", opacity=""}
    , composing = Just { color="blue", backgroundColor="", opacity="" }
    , fontFaces = [ ( "tab-face"    , {color="", backgroundColor="", opacity="0.2"} )
                  , ( "eol-face"    , {color="", backgroundColor="", opacity="0.2"} )
                  , ( "jaspace-face", {color="", backgroundColor="", opacity="0.2"} )
                  ]
    }

------------------------------------------------------------
-- Default styles
------------------------------------------------------------

{-|
-}
editorLikeDarkStyle : Style
editorLikeDarkStyle =
    { common = Just { color="#d4d4d4", backgroundColor="#1e1e1e", opacity=""
                    , fontFamily="'Ricty Diminished', 'Source Han Code JP', 'Noto Sans Mono CJK JP', 'IPA Gothic', 'takao gothic', 'VL Gothic', 'ms gothic', Consolas, 'Courier New', Courier, Monaco, monospace", fontSize=""
                    }
    , numberLine = Just { color="", backgroundColor="#303030", opacity=""
                        , borderRight="",marginRight="0.2em"
                        }
    , cursor= Just { color="#007acc", opacity="1.0"}
    , selection = Just { color="white", backgroundColor="#264f78", opacity=""}
    , composing = Just { color="lavender", backgroundColor="dimgray", opacity="" }
    , fontFaces = [ ( "tab-face"    , {color="", backgroundColor="", opacity="0.2"} )
                  , ( "eol-face"    , {color="", backgroundColor="", opacity="0.2"} )
                  , ( "jaspace-face", {color="", backgroundColor="", opacity="0.2"} )
                  ]
    }

{-|
-}
modernGoticStyle : Style
modernGoticStyle =
    { common = Just { color="", backgroundColor="", opacity=""
                    , fontFamily="helvetica, arial, 'hiragino kaku gothic pro', meiryo, 'ms pgothic', sans-serif", fontSize=""
                    }
    , numberLine = Just { color="dimgray", backgroundColor="whitesmoke", opacity=""
                        , borderRight="1px solid lightgray", marginRight="0.2em"
                        }
    , cursor= Just { color="blue", opacity="0.5"}
    , selection = Just { color="black", backgroundColor="lavender", opacity=""}
    , composing = Just { color="black", backgroundColor="lightpink", opacity="" }
    , fontFaces = [ ( "tab-face"    , {color="", backgroundColor="", opacity="0.2"} )
                  , ( "eol-face"    , {color="", backgroundColor="", opacity="0.2"} )
                  , ( "jaspace-face", {color="", backgroundColor="", opacity="0.2"} )
                  ]
    }

{-|
-}
modernMinchoStyle : Style
modernMinchoStyle =
    { common = Just { color="", backgroundColor="", opacity=""
                    , fontFamily="YuMincho, 'Hiragino Mincho ProN', 'ms pmincho', serif", fontSize=""
                    }
    , numberLine = Just { color="dimgray", backgroundColor="whitesmoke", opacity=""
                        , borderRight="1px solid lightgray", marginRight="0.2em"
                        }
    , cursor= Just { color="blue", opacity="0.5"}
    , selection = Just { color="black", backgroundColor="lavender", opacity=""}
    , composing = Just { color="black", backgroundColor="lightpink", opacity="" }
    , fontFaces = [ ( "tab-face"    , {color="", backgroundColor="", opacity="0.2"} )
                  , ( "eol-face"    , {color="", backgroundColor="", opacity="0.2"} )
                  , ( "jaspace-face", {color="", backgroundColor="", opacity="0.2"} )
                  ]
    }






------------------------------------------------------------
-- encode / decode for save local strage
------------------------------------------------------------

{-| Encode to JSON
-}
jsonEncode : Style -> Json.Encode.Value
jsonEncode sty =
    Json.Encode.object 
        [ ("common"     , sty.common     |> Maybe.andThen (\s -> encodeCodeStyle s |> Just)       |> Maybe.withDefault Json.Encode.null)
        , ("numberLine" , sty.numberLine |> Maybe.andThen (\s -> encodeLineNumberStyle s |> Just) |> Maybe.withDefault Json.Encode.null)
        , ("cursor"     , sty.cursor     |> Maybe.andThen (\s -> encodeColorStyle s |> Just)      |> Maybe.withDefault Json.Encode.null)
        , ("selection"  , sty.selection  |> Maybe.andThen (\s -> encodeFontFaceStyle s |> Just)   |> Maybe.withDefault Json.Encode.null)
        , ("composing"  , sty.composing  |> Maybe.andThen (\s -> encodeFontFaceStyle s |> Just)   |> Maybe.withDefault Json.Encode.null)
        , ("fontFaces"  , sty.fontFaces  |> List.map (\ (k,v) -> (k, encodeFontFaceStyle v)) |> Json.Encode.object )
        ]

encodeCodeStyle : CodeStyle -> Json.Encode.Value
encodeCodeStyle sty =
    Json.Encode.object
        [ ("color"          , sty.color |> Json.Encode.string)
        , ("backgroundColor", sty.backgroundColor |> Json.Encode.string)
        , ("opacity"        , sty.opacity |> Json.Encode.string)
        , ("fontFamily"     , sty.fontFamily |> Json.Encode.string)
        , ("fontSize"       , sty.fontSize |> Json.Encode.string)
        ]

encodeLineNumberStyle : LineNumberStyle -> Json.Encode.Value
encodeLineNumberStyle sty =
    Json.Encode.object
        [ ("color"          , sty.color |> Json.Encode.string)
        , ("backgroundColor", sty.backgroundColor |> Json.Encode.string)
        , ("opacity"        , sty.opacity |> Json.Encode.string)
        , ("borderRight"    , sty.borderRight |> Json.Encode.string)
        , ("marginRight"    , sty.marginRight |> Json.Encode.string)
        ]

encodeFontFaceStyle : FontFaceStyle -> Json.Encode.Value
encodeFontFaceStyle sty =
    Json.Encode.object
        [ ("color"          , sty.color |> Json.Encode.string)
        , ("backgroundColor", sty.backgroundColor |> Json.Encode.string)
        , ("opacity"        , sty.opacity |> Json.Encode.string)
        ]

encodeColorStyle : ColorStyle -> Json.Encode.Value
encodeColorStyle sty =
    Json.Encode.object
        [ ("color"          , sty.color |> Json.Encode.string)
        , ("opacity"        , sty.opacity |> Json.Encode.string)
        ]

{-| Decode from JSON
-}
jsonDecode: Json.Decode.Decoder Style
jsonDecode =
    Json.Decode.map6
        Style
            (Json.Decode.field "common"     (Json.Decode.nullable decodeCodeStyle) )
            (Json.Decode.field "numberLine" (Json.Decode.nullable decodeLineNumberStyle))
            (Json.Decode.field "cursor"     (Json.Decode.nullable decodeColorStyle))
            (Json.Decode.field "selection"  (Json.Decode.nullable decodeFontFaceStyle))
            (Json.Decode.field "composing"  (Json.Decode.nullable decodeFontFaceStyle))
            (Json.Decode.field "fontFaces"  (Json.Decode.keyValuePairs decodeFontFaceStyle))

decodeCodeStyle : Json.Decode.Decoder CodeStyle
decodeCodeStyle =
    Json.Decode.map5
        CodeStyle
            (Json.Decode.field "color"             Json.Decode.string)
            (Json.Decode.field "backgroundColor"   Json.Decode.string)
            (Json.Decode.field "opacity"           Json.Decode.string)
            (Json.Decode.field "fontFamily"        Json.Decode.string)
            (Json.Decode.field "fontSize"          Json.Decode.string)

decodeLineNumberStyle : Json.Decode.Decoder LineNumberStyle
decodeLineNumberStyle =
    Json.Decode.map5
        LineNumberStyle
            (Json.Decode.field "color"             Json.Decode.string)
            (Json.Decode.field "backgroundColor"   Json.Decode.string)
            (Json.Decode.field "opacity"           Json.Decode.string)
            (Json.Decode.field "borderRight"       Json.Decode.string)
            (Json.Decode.field "marginRight"       Json.Decode.string)


decodeFontFaceStyle : Json.Decode.Decoder FontFaceStyle
decodeFontFaceStyle =
    Json.Decode.map3
        FontFaceStyle
            (Json.Decode.field "color"             Json.Decode.string)
            (Json.Decode.field "backgroundColor"   Json.Decode.string)
            (Json.Decode.field "opacity"           Json.Decode.string)

decodeColorStyle : Json.Decode.Decoder ColorStyle
decodeColorStyle =
    Json.Decode.map2
        ColorStyle
            (Json.Decode.field "color"             Json.Decode.string)
            (Json.Decode.field "opacity"           Json.Decode.string)



