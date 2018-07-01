module StyleMenu exposing
    ( Model
    , init
    , Msg
    , update
    , subscriptions
    , view
    )

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Json.Encode
import Json.Decode

import Ports.WebStrage as WebStrage
import TextEditor.Style as EditorStyle
import Dict

type alias Model =
    { style : EditorStyle.Style
    , editTarget : EditTarget
    }

type alias SelectableList =
    { value : String
    , list : List String
    }
        
type EditTarget
   = EditColor      String (String -> Msg) SelectableList
   | EditFontFamily String (String -> Msg) SelectableList
   | EditFontSize   String (String -> Msg) SelectableList

targetName : EditTarget -> String
targetName target =
    case target of
        EditColor s _ _ -> s
        EditFontFamily s _ _ -> s
        EditFontSize s _ _ -> s

init: EditorStyle.Style -> (Model , Cmd Msg)
init sty =
    ( Model
          sty
          (EditColor "bg-color" Change_Common_BGColor (bgColorList "inherit"))
    , Cmd.batch [ WebStrage.localStrage_getItem "style"
                ]
    )


bgColorList : String -> SelectableList
bgColorList v = { value = v, list = ["inherit", "black", "white", "linen", "dimgray", "whitesmoke", "midnightblue", "darkolivegreen", "aquamarine", "beige", "mediumvioletred", "darkslategray", "lavender"] }

fgColorList : String -> SelectableList
fgColorList v = { value = v, list = ["inherit", "black", "white", "aqua", "coral", "midnightblue", "darkslategray", "ghostwhite", "lavender", "palevioletred", "darkmagenta", "moccasin", "rosybrown"] }

fontFamilyList : String -> SelectableList
fontFamilyList v = { value = v, list = ["inherit", "cursive", "fantasy", "monospace", "sans-serif", "serif"] }

fontSizeList : String-> SelectableList
fontSizeList v = { value = v, list = ["inherit", "0.5em", "1em", "1.2em", "1.5em", "2em", "3em", "5em", "7em", "10em"] }


selectValue : String -> SelectableList -> SelectableList
selectValue s m =
    { m | value = s }

type Msg
    = Change_Common_BGColor String
    | Change_Common_FGColor String
    | Change_Common_FontFamily String
    | Change_Common_FontSize String
    | TouchBackgroundColor
    | TouchForegroundColor
    | TouchFontSize
    | TouchFontFalily
    | LoadSetting (String, Maybe String)


defaultCommonStyle : EditorStyle.CodeStyle
defaultCommonStyle =
    { color = "inherit"
    , backgroundColor = "inherit"
    , opacity = "inherit"
    , fontFamily = "inherit"
    , fontSize = "inherit"
    }


update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
    case msg of
        LoadSetting ("style", maybe_value) ->
            ( maybe_value
                |> Result.fromMaybe "value is nothing"
                |> Result.andThen (Json.Decode.decodeString decodeStyle)
                |> Debug.log "loadstyle-parse-msg"
                |> Result.withDefault model.style
                |> (\newstyle -> { model | style = newstyle })
            , Cmd.none
            )
        LoadSetting _ ->
            ( model, Cmd.none )

        Change_Common_BGColor s ->
            let
                updateCommonBgColor = \s edstyle ->
                                      let
                                          common = edstyle.common |> Maybe.withDefault defaultCommonStyle
                                      in
                                          { edstyle | common = Just { common | backgroundColor = s } }
                newstyle = updateCommonBgColor s model.style 
            in
                ( { model
                      | style      = newstyle
                      , editTarget = EditColor "bg-color" Change_Common_BGColor (bgColorList s)
                  }
                , WebStrage.localStrage_setItem ("style", encodeStyle newstyle |> Json.Encode.encode 0 )
                )

        Change_Common_FGColor s ->
            let
                updateCommonFgColor = \s edstyle ->
                                      let
                                          common = edstyle.common |> Maybe.withDefault defaultCommonStyle
                                      in
                                          { edstyle | common = Just { common | color = s } }
                newstyle      = updateCommonFgColor s model.style
            in
                ( { model
                      | style      = newstyle
                      , editTarget = EditColor "fg-color" Change_Common_FGColor (fgColorList s)
                  }
                , WebStrage.localStrage_setItem ("style", encodeStyle newstyle |> Json.Encode.encode 0 )
                )

        Change_Common_FontFamily s ->
            let
                updateCommonFtFamily = \s edstyle ->
                                      let
                                          common = edstyle.common |> Maybe.withDefault defaultCommonStyle
                                      in
                                          { edstyle | common = Just { common | fontFamily = s } }
                newstyle = updateCommonFtFamily s model.style
            in
                ( { model
                      | style      = newstyle
                      , editTarget = EditFontFamily "font-family" Change_Common_FontFamily (fontFamilyList s)
                  }
                , WebStrage.localStrage_setItem ("style", encodeStyle newstyle |> Json.Encode.encode 0)
                )
        Change_Common_FontSize s ->
            let
                updateCommonFtSize = \s edstyle ->
                                      let
                                          common = edstyle.common |> Maybe.withDefault defaultCommonStyle
                                      in
                                          { edstyle | common = Just { common | fontSize = s } }
                newstyle = updateCommonFtSize s model.style
            in
                ( { model
                      | style      = newstyle
                      , editTarget = EditFontSize "font-size" Change_Common_FontSize (fontSizeList s)
                  }
                , WebStrage.localStrage_setItem ("style", encodeStyle newstyle |> Json.Encode.encode 0)
                )

        TouchBackgroundColor ->
            ( { model
                  | editTarget = EditColor "bg-color" Change_Common_BGColor (model.style.common |> Maybe.andThen (\m -> Just m.backgroundColor) |> Maybe.withDefault "inherit" |> bgColorList)
              }
            , Cmd.none
            )
        TouchForegroundColor ->
            ( { model
                  | editTarget = EditColor "fg-color" Change_Common_FGColor (model.style.common |> Maybe.andThen (\m -> Just m.color) |>Maybe.withDefault "inherit" |> fgColorList)
              }
            , Cmd.none
            )
        TouchFontFalily ->
            ( { model
                  | editTarget = EditFontFamily "font-family" Change_Common_FontFamily (model.style.common |> Maybe.andThen (\m -> Just m.fontFamily) |> Maybe.withDefault "inherit" |> fontFamilyList)
              }
            , Cmd.none
            )
        TouchFontSize ->
            ( { model
                  | editTarget = EditFontSize "font-size" Change_Common_FontSize (model.style.common |> Maybe.andThen (\m -> Just m.fontSize) |> Maybe.withDefault "inherit" |> fontSizeList)
              }
            , Cmd.none
            )




------------------------------------------------------------
-- Subscriptions
------------------------------------------------------------

subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch [ WebStrage.localStrage_getItemEnded LoadSetting
              ]


------------------------------------------------------------
-- View
------------------------------------------------------------


view : Model -> Html Msg
view model =
    div [ class "style-setter", class "menu-root"
        , style [ ("flex-grow", "2")
                , ("min-height", "17em")
                ]
        ]
        [ div [ class "menu-itemlist" ]
              [ div [ onClick TouchBackgroundColor
                    , class <| if targetName model.editTarget == "bg-color" then "menu-item-active" else "menu-item"
                    ]
                    [ span [] [text "background-color: "]
                    , span [] [model.style.common |> Maybe.andThen (\m -> Just m.backgroundColor) |> Maybe.withDefault "" |> text ]
                    ]
              , div [ onClick TouchForegroundColor
                    , class <| if targetName model.editTarget == "fg-color" then "menu-item-active" else "menu-item"
                    ]
                    [ span [] [text "color: "]
                    , span [] [model.style.common |> Maybe.andThen (\m -> Just m.color) |> Maybe.withDefault "" |> text ]
                    ]
              , div [ onClick TouchFontFalily
                    , class <| if targetName model.editTarget == "font-family" then "menu-item-active" else "menu-item"
                    ]
                    [ span [] [text "font-family: "]
                    , span [] [model.style.common |> Maybe.andThen (\m -> Just m.fontFamily) |> Maybe.withDefault "" |> text ]
                    ]
              , div [ onClick TouchFontSize
                    , class <| if targetName model.editTarget == "font-size" then "menu-item-active" else "menu-item"
                    ]
                    [ span [] [text "font-size: "]
                    , span [] [model.style.common |> Maybe.andThen (\m -> Just m.fontSize) |> Maybe.withDefault "" |> text ]
                   ]
              ]
        , case model.editTarget of
            EditColor _ tagger list ->
                colorPalette tagger list
            EditFontFamily _ tagger list ->
                fontFamilySelector tagger list
            EditFontSize _ tagger list ->
                fontSizeSelector tagger list
        ]

colorPalette : (String -> Msg) -> SelectableList -> Html Msg
colorPalette tagger colorList =
    div [ class "menu-palette"
        , style [ ("flex-grow", "1"), ("display", "flex"), ("align-content", "flex-start"), ("flex-wrap","wrap")
                ]
        ] <|
        List.map (\ color ->
                      div [ class <|
                                if color == colorList.value
                                then "color-palette-item-active"
                                else "color-palette-item"
                          , style [ ("display", "flex"), ("flex-directipn", "column") ]
                          , onClick <| tagger color
                          ]
                          [ div [ style [ ("width", "1em"), ("height", "1em"), ("background-color", color), ("border", "1px solid black") ]
                                ]
                                []
                          , div [ style [ ("padding-left", "0.5em") ]
                                ]
                                [ text color
                                ]
                          ]
                 ) colorList.list

fontFamilySelector : (String -> Msg) -> SelectableList -> Html Msg
fontFamilySelector tagger fontList =
    div [ class "menu-palette"
        , style [ ("flex-grow", "1"), ("display", "flex"), ("flex-direction", "row"), ("flex-wrap","no-wrap")
                ]
        ] <|
        List.map (\ font ->
                      div [ class <|
                                if font == fontList.value
                                then "font-palette-item-active"
                                else "font-palette-item"
                          , style [ ("height", "2em"), ("size", "2em"), ("font-family", font), ("width", "100%")]
                          , onClick <| tagger font
                          ]
                          [ text font
                          ]
                 ) fontList.list

fontSizeSelector : (String -> Msg) -> SelectableList -> Html Msg
fontSizeSelector tagger fontsizeList =
    div [ class "menu-palette"
        , style [ ("flex-grow", "1"), ("display", "flex"), ("flex-direction", "row"), ("flex-wrap","no-wrap")
                ]
        ] <|
        List.map (\ fontsize ->
                      div [ class <|
                                if fontsize == fontsizeList.value
                                then "font-palette-item-active"
                                else "font-palette-item"
                          , style [ ("font-size", fontsize), ("width", "100%") ]
                          , onClick <| tagger fontsize
                          ]
                          [ text fontsize
                          ]
                 ) fontsizeList.list




------------------------------------------------------------
-- encode / decode for save local strage
------------------------------------------------------------

encodeStyle : EditorStyle.Style -> Json.Encode.Value
encodeStyle sty =
    Json.Encode.object 
        [ ("common"     , sty.common     |> Maybe.andThen (\s -> encodeCodeStyle s |> Just)       |> Maybe.withDefault Json.Encode.null)
        , ("numberLine" , sty.numberLine |> Maybe.andThen (\s -> encodeLineNumberStyle s |> Just) |> Maybe.withDefault Json.Encode.null)
        , ("cursor"     , sty.cursor     |> Maybe.andThen (\s -> encodeColorStyle s |> Just)      |> Maybe.withDefault Json.Encode.null)
        , ("selection"  , sty.selection  |> Maybe.andThen (\s -> encodeFontFaceStyle s |> Just)   |> Maybe.withDefault Json.Encode.null)
        , ("composing"  , sty.composing  |> Maybe.andThen (\s -> encodeFontFaceStyle s |> Just)   |> Maybe.withDefault Json.Encode.null)
        , ("fontFaces"  , sty.fontFaces  |> List.map (\ (k,v) -> (k, encodeFontFaceStyle v)) |> Json.Encode.object )
        ]

encodeCodeStyle : EditorStyle.CodeStyle -> Json.Encode.Value
encodeCodeStyle sty =
    Json.Encode.object
        [ ("color"          , sty.color |> Json.Encode.string)
        , ("backgroundColor", sty.backgroundColor |> Json.Encode.string)
        , ("opacity"        , sty.opacity |> Json.Encode.string)
        , ("fontFamily"     , sty.fontFamily |> Json.Encode.string)
        , ("fontSize"       , sty.fontSize |> Json.Encode.string)
        ]

encodeLineNumberStyle : EditorStyle.LineNumberStyle -> Json.Encode.Value
encodeLineNumberStyle sty =
    Json.Encode.object
        [ ("color"          , sty.color |> Json.Encode.string)
        , ("backgroundColor", sty.backgroundColor |> Json.Encode.string)
        , ("opacity"        , sty.opacity |> Json.Encode.string)
        , ("borderRight"    , sty.borderRight |> Json.Encode.string)
        , ("marginRight"    , sty.marginRight |> Json.Encode.string)
        ]

encodeFontFaceStyle : EditorStyle.FontFaceStyle -> Json.Encode.Value
encodeFontFaceStyle sty =
    Json.Encode.object
        [ ("color"          , sty.color |> Json.Encode.string)
        , ("backgroundColor", sty.backgroundColor |> Json.Encode.string)
        , ("opacity"        , sty.opacity |> Json.Encode.string)
        ]

encodeColorStyle : EditorStyle.ColorStyle -> Json.Encode.Value
encodeColorStyle sty =
    Json.Encode.object
        [ ("color"          , sty.color |> Json.Encode.string)
        , ("opacity"        , sty.opacity |> Json.Encode.string)
        ]


decodeStyle: Json.Decode.Decoder EditorStyle.Style
decodeStyle =
    Json.Decode.map6
        EditorStyle.Style
            (Json.Decode.field "common"     (Json.Decode.nullable decodeCodeStyle) )
            (Json.Decode.field "numberLine" (Json.Decode.nullable decodeLineNumberStyle))
            (Json.Decode.field "cursor"     (Json.Decode.nullable decodeColorStyle))
            (Json.Decode.field "selection"  (Json.Decode.nullable decodeFontFaceStyle))
            (Json.Decode.field "composing"  (Json.Decode.nullable decodeFontFaceStyle))
            (Json.Decode.field "fontFaces"  (Json.Decode.keyValuePairs decodeFontFaceStyle))

decodeCodeStyle : Json.Decode.Decoder EditorStyle.CodeStyle
decodeCodeStyle =
    Json.Decode.map5
        EditorStyle.CodeStyle
            (Json.Decode.field "color"             Json.Decode.string)
            (Json.Decode.field "backgroundColor"   Json.Decode.string)
            (Json.Decode.field "opacity"           Json.Decode.string)
            (Json.Decode.field "fontFamily"        Json.Decode.string)
            (Json.Decode.field "fontSize"          Json.Decode.string)

decodeLineNumberStyle : Json.Decode.Decoder EditorStyle.LineNumberStyle
decodeLineNumberStyle =
    Json.Decode.map5
        EditorStyle.LineNumberStyle
            (Json.Decode.field "color"             Json.Decode.string)
            (Json.Decode.field "backgroundColor"   Json.Decode.string)
            (Json.Decode.field "opacity"           Json.Decode.string)
            (Json.Decode.field "borderRight"       Json.Decode.string)
            (Json.Decode.field "marginRight"       Json.Decode.string)


decodeFontFaceStyle : Json.Decode.Decoder EditorStyle.FontFaceStyle
decodeFontFaceStyle =
    Json.Decode.map3
        EditorStyle.FontFaceStyle
            (Json.Decode.field "color"             Json.Decode.string)
            (Json.Decode.field "backgroundColor"   Json.Decode.string)
            (Json.Decode.field "opacity"           Json.Decode.string)

decodeColorStyle : Json.Decode.Decoder EditorStyle.ColorStyle
decodeColorStyle =
    Json.Decode.map2
        EditorStyle.ColorStyle
            (Json.Decode.field "color"             Json.Decode.string)
            (Json.Decode.field "opacity"           Json.Decode.string)

