module TextEditor.Style exposing
    ( Style
    , CodeStyle
    , LineNumberStyle
    , FontFaceStyle
    , ColorStyle
    , notepadLikeStyle
    , editorLikeStyle
    , modernGoticStyle
    , modernMinchoStyle
    )

{-|
@docs Style, CodeStyle, LineNumberStyle, FontFaceStyle, ColorStyle
@docs notepadLikeStyle, editorLikeStyle, modernGoticStyle, modernMinchoStyle
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
notepadLikeStyle : Style
notepadLikeStyle =
    { common = Just { color="", backgroundColor="", opacity=""
                    , fontFamily="Consolas, 'Courier New', Courier, Monaco, monospace", fontSize=""
                    }
    , numberLine = Nothing
    , cursor= Just { color="blue", opacity="0.5"}
    , selection = Just { color="white", backgroundColor="blue", opacity=""}
    , composing = Just { color="blue", backgroundColor="", opacity="" }
    , fontFaces = [ ( "tab-face"    , {color="", backgroundColor="", opacity="0.2"} )
                  , ( "eol-face"    , {color="", backgroundColor="", opacity="0.2"} )
                  , ( "jaspace-face", {color="", backgroundColor="", opacity="0.2"} )
                  ]
    }

{-|
-}
editorLikeStyle : Style
editorLikeStyle =
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

