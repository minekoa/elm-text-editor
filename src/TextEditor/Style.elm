module TextEditor.Style exposing
    ( Style
    , CodeStyle
    , LineNumberStyle
    , FontFaceStyle
    , ColorStyle
    , defaultStyle
    )

{-|
@docs Style, CodeStyle, LineNumberStyle, FontFaceStyle, ColorStyle
@docs defaultStyle

-}

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
-}
type alias ColorStyle =
   { color: String
   , opacity: String
   }


{-|
-}
defaultStyle : Style
defaultStyle =               
    { common = Nothing
    , numberLine = Nothing
    , cursor= Just { color="blue", opacity="0.5"}
    , selection = Just { color="white", backgroundColor="blue", opacity=""}
    , composing = Just { color="blue", backgroundColor="", opacity="" }
    , fontFaces = [ ( "tab-face"    , {color="", backgroundColor="", opacity="0.2"} )
                  , ( "eol-face"    , {color="", backgroundColor="", opacity="0.2"} )
                  , ( "jaspace-face", {color="", backgroundColor="", opacity="0.2"} )
                  ]
    }

