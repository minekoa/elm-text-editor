module TextEditor exposing ( Model
                           , init
                           , update
                           , Msg(..)
                           , subscriptions
                           , view
                           )

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Json.Decode as Json
import Json.Encode
import Mouse
import Task exposing (Task)

import TextEditor.Buffer as Buffer
import TextEditor.Core as Core exposing (..)
import TextEditor.Core.Commands as Commands
import TextEditor.KeyBind as KeyBind


import Native.Mice

{-| This module is simple texteditor.

-}

type alias Model =
    { core : Core.Model

    -- state
    , enableComposer : Bool -- ブラウザの互換のため、compositionEvent の遷移とは別の「IME入力中」判定フラグが必要

    -- options
    , keymap : List KeyBind.KeyBind

    -- for debug
    , event_log : Maybe (List String)
    }

init : String -> List KeyBind.KeyBind -> String -> (Model, Cmd Msg)
init id keymap text =
    let
        (coreM, coreC) = Core.init id text
    in
    ( Model
          coreM
          False
          keymap
          Nothing
    , Cmd.map CoreMsg coreC
    )


------------------------------------------------------------
-- update
------------------------------------------------------------

type Msg
    = CoreMsg Core.Msg
    | Pasted String
    | Copied String
    | Cutted String
    | Input String
    | KeyDown KeyboardEvent
    | KeyPress Int
    | CompositionStart String
    | CompositionUpdate String
    | CompositionEnd String
    | FocusIn Bool
    | FocusOut Bool
    | ClickScreen
    | DragStart Int Mouse.Position

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
    case msg of
        CoreMsg cmsg ->
            Core.update cmsg model.core
                |> Tuple.mapFirst (\cm -> { model | core = cm } )
                |> Tuple.mapSecond (Cmd.map CoreMsg)

        -- System-Clipboard's Action Notification (Do Fitting Elm's Model State)

        Pasted s ->
            updateMap model (Commands.paste s model.core)
                |> Tuple.mapFirst (eventLog "pasted" s)

        Copied s ->
            updateMap model (Commands.copy model.core)
                |> Tuple.mapFirst (eventLog "copied" s)

        Cutted s ->
            updateMap model (Commands.cut model.core)
                |> Tuple.mapFirst (eventLog "cutted" s)

        -- View Operation Event

        Input s ->
            input s model

        KeyDown keyevent ->
            keyDown keyevent model
 
        KeyPress code ->
            keyPress code model

        CompositionStart data ->
            compositionStart data model

        CompositionUpdate data ->
            compositionUpdate data model

        CompositionEnd data ->
            compositionEnd data model

        FocusIn _ ->
            let
                cm = model.core
            in
            ( { model | core = {cm | focus = True}  }
            , Cmd.map CoreMsg (Core.elaborateInputArea model.core)
            )

        FocusOut _ ->
            let
                cm = model.core
            in
            ( { model| core = {cm| focus = False }}
            , Cmd.none
            )

        ClickScreen ->
            ( model
                |> eventLog "setfocus" ""
            , Cmd.map CoreMsg (Core.doFocus model.core)
            )

        DragStart row xy ->
            let
                calc_w  = calcTextWidth (rulerID model.core)
                calc_col = (\ ln c x ->
                              if (calc_w (String.left c ln)) > x || String.length ln < c  then c - 1
                              else calc_col ln (c + 1)  x)

                ln = Buffer.line row model.core.buffer.contents |> Maybe.withDefault ""
                rect = getBoundingClientRect (codeLayerID model.core)

                col = (calc_col ln 0 (xy.x - rect.left))

                b1 = model.core.buffer
                b2 = { b1 | cursor = Buffer.Cursor row col }

                coremodel = model.core
            in
                ( { model | core = {coremodel |buffer = b2} }
                  |> eventLog "dragstart" ("pos=" ++ (toString xy.x) ++ "," ++ (toString xy.y)
                                               ++ "; offsetx=" ++ (toString (xy.x - rect.left))
                                               ++ "; row=" ++ (toString row)
                                               ++ "; calced_col=" ++ (toString col)
                                          )
                  |> blinkBlock
                , Cmd.map CoreMsg (Core.doFocus model.core)  -- firefox 限定で、たまーに、SetFocus が来ないことがあるので、ここでもやっとく。
                )


input: String -> Model -> (Model, Cmd Msg)
input s model =
    case model.enableComposer of
        True ->
            ( model
              |> eventLog "input (ignored)" s
            , Cmd.none )
        False ->
            updateMap model (Commands.insert (String.right 1 s) model.core)
                |> Tuple.mapFirst (eventLog "input" (String.right 1 s))


keyDown : KeyboardEvent -> Model -> (Model, Cmd Msg)
keyDown e model =
    case KeyBind.find (e.ctrlKey, e.altKey, e.shiftKey, e.keyCode) model.keymap of
        Just editorcmd ->
            updateMap model (editorcmd model.core)
                |> Tuple.mapFirst (eventLog "keydown" (keyboarEvent_toString e))
        Nothing ->
            ( model
                |> eventLog "keydown" (keyboarEvent_toString e)
            , Cmd.none
            )

keyPress : Int -> Model -> (Model, Cmd Msg)
keyPress code model =
    -- IME入力中にkeypress イベントがこないことを利用して IME入力モード(inputを反映するか否かのフラグ）を解除
    -- ※ compositonEnd で解除してしまうと、firefoxとchromeの振る舞いの違いでハマる
    --        chrome  :: keydown 229 -> compositionend s
    --        firefox ::   (null)    -> compositionend s -> input s
    ( model
        |> composerDisable
        |> eventLog "keypress" (toString code)
    , Cmd.none
    )

compositionStart : String -> Model -> (Model, Cmd Msg)
compositionStart data model =
    -- note: この data は入力された文字列 **ではない**
    ( { model
          | core = Core.compositionStart model.core
      }
      |> composerEnable
      |> eventLog "compositoinstart" data
    , Cmd.none
    )

compositionUpdate : String -> Model -> (Model, Cmd Msg)
compositionUpdate data model =
    ( { model
          | core = Core.compositionUpdate data model.core
      }
      |> blinkBlock
      |> eventLog "compositionupdate" data
    , Cmd.none
    )

compositionEnd : String -> Model -> (Model, Cmd Msg)
compositionEnd data model =
    -- note: 変換プレビューのクリアはするが、
    --        firefox ではこの後 input イベントがくるので、
    --        それを無視する為 enable-conposerは立てたままにする (keypressイベントで解除する、そちらを参照)
    ( { model
          | core = Core.compositionEnd data model.core
      }
      |> blinkBlock
      |> eventLog "compositionend" data
    , Cmd.none
    )
--        |> withEnsureVisibleCmd --TODO

------------------------------------------------------------
-- control state update
------------------------------------------------------------

eventLog : String -> String -> Model -> Model
eventLog ev data model =
    let
        s = "(" ++ ev ++ ":" ++ data ++ ") "
    in
        { model | event_log = Maybe.andThen (\logs -> Just (s :: logs)) model.event_log }

blinkBlock : Model -> Model
blinkBlock model =
    { model
        | core = Core.blinkBlock model.core
    }

composerEnable : Model -> Model
composerEnable model =
    { model
        | enableComposer = True
    }

composerDisable : Model -> Model
composerDisable model =
    { model
        | enableComposer = False
    }


------------------------------------------------------------
-- update > (extra)
------------------------------------------------------------

-- Tools

selectionClear : Model -> Model
selectionClear model =
    let
        coremodel = model.core
    in
        { model
            | core = { coremodel
                         | buffer = Buffer.selectionClear coremodel.buffer
                     }
        }

updateMap: Model -> (Core.Model, Cmd Core.Msg) -> (Model, Cmd Msg)
updateMap model (em, ec) =
    ( {model | core = em}
    , Cmd.map CoreMsg ec)


------------------------------------------------------------
-- View
------------------------------------------------------------

view : Model -> Html Msg
view model =
    div [ id <| frameID model.core
        , style [ ("margin", "0"), ("padding", "0"), ("width", "100%"), ("height", "100%")
                , ("overflow","auto")
                , ( "position", "relative")
                , ("user-select", "none")
                , ("-webkit-user-select", "none")
                , ("-moz-user-select", "none")
                ]
        , onClick ClickScreen
        ]
        [ div [ id <| sceneID model.core
              , class "editor-scene"
              , style [ ( "position", "relative") ]
              ]
              [ presentation model.core
              ]
        ]

presentation : Core.Model -> Html Msg
presentation model =
    div [ style [ ("display", "flex"), ("flex-direction", "row"), ("flex-wrap", "nowrap")
                , ("margin", "0"), ("padding", "0"), ("width", "100%"), ("height", "100%")
                , ("position", "relative")
                ]
        , onFocusIn FocusIn
        , onFocusOut FocusOut
        ]
        [ lineNumArea model
        , codeArea model
        ]

lineNumArea : Core.Model -> Html Msg
lineNumArea model =
    let
        contents = model.buffer.contents
    in
        div [ class "line-num-area"
            , style [ ("text-align", "right")
                    , ("padding-right", "0.2em")
                    ]
            ] <|
            List.map
                (λ n -> div [ class "line-num"
                             , style [ ("height", "1em")
                                     , ("text-wrap", "none")]
                             ] [ text (toString n) ])
                (List.range 1 (List.length contents))

codeArea : Core.Model -> Html Msg
codeArea model =
    div [ class "code-area"
        , style [ ("margin", "0"), ("padding", "0"), ("border", "none")
                , ("flex-grow", "1") -- "line" の行末以降のタップでもカーソル移動したいので、いっぱいまで伸びるようにしておく
                ]
        ]
        [ ruler <| rulerID model
        , cursorLayer model
        , markerLayer model
        , codeLayer model
        ]

codeLayer: Core.Model  -> Html Msg
codeLayer model = 
    let
        contents = model.buffer.contents
        cursor = model.buffer.cursor
    in
        div [ id <| codeLayerID model
            , class "code-layer"
            , style [ ("margin", "0"), ("padding", "0"), ("border", "none")
                    , ("width", "100%")
                    ]
            ] <|
            List.indexedMap
                (λ n ln ->
                      div [ class "line"
                          , style [ ("height", "1em")
                                  , ("width", "100%")
                                  , ("text-wrap", "none")
                                  , ("white-space", "pre")
                                  , ("pointer-events", "auto") -- マウスイベントの対象にする
                                  ]
                          , onMouseDown (DragStart n)
                          ] <|
                          if n == cursor.row then
                              [ span [ style [ ("position", "relative")
                                             , ("white-space", "pre")
                                             , ("pointer-events", "none") -- マウスイベントの対象外にする
                                             ]
                                     ]
                                     [ text <| String.left cursor.column ln]
                              , compositionPreview model.compositionPreview
                              , span [ style [ ("position", "relative")
                                             , ("white-space", "pre")
                                             , ("pointer-events", "none") -- マウスイベントの対象外にする
                                             ]
                                     ]
                                     [ text <| String.dropLeft cursor.column ln]                                  
                              ]
                          else
                              [text ln]
                ) contents

cursorLayer : Core.Model -> Html Msg
cursorLayer model =
    div [ class "cursor-layer"
        , style [ ("position", "absolute")
                , ("pointer-events", "none") -- マウスイベントの対象外にする
                ]
        ]
        [ div [style [ ("position", "relative")
                     , ("display" , "inline-flex")
                     , ("flex-direction", "row")
                     , ("flex-wrap", "nowrap")
                     , ("justify-content", "flex-start")
                     , ("height", "1em")
                     , ("align-items" , "baseline")

                     , ("top" , "calc( " ++ (model.buffer.cursor.row |> toString) ++ "em + 0.1em )")
                     , ("left", "0")
                     ]
               ]
               [ pad model
               , div
                     [ style [("position", "relative"), ("display" , "inline-flex")] ]
                     [ textarea [ id <| inputAreaID model
                                , onInput Input
                                , onKeyDown KeyDown
                                , onKeyPress KeyPress
                                , onCompositionStart CompositionStart
                                , onCompositionUpdate CompositionUpdate
                                , onCompositionEnd CompositionEnd
                                , onPasted Pasted
                                , onCopied Copied
                                , onCutted Cutted
                                , selecteddata <| Buffer.selectedString model.buffer
                                , spellcheck False
                                , wrap "off"
                                , style [ ("border", "none"), ("padding", "0"), ("margin","0"), ("outline", "none")
                                        , ("overflow", "hidden"), ("opacity", "0")
                                        , ("resize", "none")
                                        , ("height", "1em"), ("font-size", "1em") -- 親のスタイルにあわせて大きさを買えるために必要
                                        , ("position", "absolute")
                                        ]
                                ]
                           []
                     , span [ style [("visibility", "hidden") ]] [compositionPreview model.compositionPreview]
                     , cursorView model
                     ]
               ]
        ]

markerLayer: Core.Model -> Html Msg
markerLayer model =
    case model.buffer.selection of
        Nothing ->
            text ""

        Just sel ->
            let
                bpos = if (Buffer.isPreviosPos sel.begin sel.end) then sel.begin else sel.end
                epos = if (Buffer.isPreviosPos sel.begin sel.end) then sel.end else sel.begin

                ms = List.range (Tuple.first bpos) (Tuple.first epos)
                   |> List.map (\ r ->
                                    let
                                        cb = if r == (Tuple.first bpos)
                                             then bpos |> Tuple.second
                                             else 0
                                        ce = if r == (Tuple.first epos)
                                             then epos |> Tuple.second
                                             else String.length <| (Buffer.line r model.buffer.contents |> Maybe.withDefault "")
                                    in
                                        {row =r, begin_col = cb, end_col = ce}
                               )
            in
                div [ class "marker-layer"
                    , style [ ("position", "absolute")
                            , ("pointer-events", "none") -- マウスイベントの対象外にする
                            ]
                    ]
                    ( List.map (\ m ->
                                  div [ style [ ("position", "absolute")
                                              , ("display", "inline-flex")
                                              , ("top" , (m.row |> toString) ++ "em")
                                              , ("left", "0")
                                              ]
                                      ]
                                      [ padToCursor (m.row, m.begin_col) model
                                      , div [ class "selection"
                                            , style [ ("background-color", "blue")
                                                    , ("color","white")
                                                    , ("white-space", "pre")
                                                    , ("border","none"), ("padding", "0"), ("margin", "0")
                                                    , ("z-index", "99") -- note: 範囲選択を一番上にしたいため 99 という数字自体に意味はない
                                                    ]
                                            ]
                                            [ Buffer.line m.row model.buffer.contents |> Maybe.withDefault ""
                                              |> String.dropLeft m.begin_col
                                              |> String.left (m.end_col - m.begin_col)
                                              |> (\l -> if l == "" then " " else l)
                                              |> text
                                            ]
                                      ]
                             ) ms )

pad : Core.Model -> Html msg
pad model =
    let
        cur      = model.buffer.cursor
        contents = model.buffer.contents
    in
    span [ class "pad"
         , style [ ("position", "relative")
                 , ("white-space", "pre")
                 , ("visibility", "hidden")                     
                 , ("pointer-events", "none") -- マウスイベントの対象外にする
                 ]
         ]
         [ Buffer.line cur.row contents |> Maybe.withDefault "" |> String.left cur.column |> text ]

padToCursor : (Int, Int) -> Core.Model -> Html msg
padToCursor pos model =
    let
        contents = model.buffer.contents
    in
    span [ class "pad"
         , style [ ("position", "relative")
                 , ("white-space", "pre")
                 , ("visibility", "hidden")                     
                 , ("pointer-events", "none") -- マウスイベントの対象外にする
                 ]
         ]
         [ Buffer.line (Tuple.first pos) contents |> Maybe.withDefault "" |> String.left (Tuple.second pos) |> text ]



ruler : String -> Html msg
ruler ruler_id = 
    div [ class "ruler-layer"
        , style [ ("position", "absolute")
                , ("overflow", "hidden")
                , ("width", "0px")
                , ("opacity", "0")
                , ("pointer-events", "none") -- マウスイベントの対象外にする
                ]
        ]
        [ span [ id ruler_id
               , style [ ("white-space", "pre")
                       ]
               ]
               []
        ]

compositionPreview : Maybe String -> Html msg
compositionPreview compositionData =
    case compositionData of
        Just s ->
            span [ class "composition_data"
                 , style [ ("color", "blue")
                         , ("text-decoration", "underline")
                         ]
                 ] [ text s ]
        Nothing ->
            text ""

cursorView : Core.Model -> Html msg
cursorView model =
    let
        blink_off = (\blnk -> case blnk of
                                Blink b      -> b
                                BlinkBlocked -> True
                    ) >> not
    in
    span [style [ ("background-color", if model.focus then "blue" else "gray" )
                , ("opacity", if model.focus && (blink_off model.blink) then "0.0" else "0.5")
                , ("height", "1em")
                , ("width", "3px")
                , ("z-index", "99")
                ]
         , id <| cursorID model
         ]
    []


------------------------------------------------------------
-- Subscriptions
------------------------------------------------------------

subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch [ Sub.map CoreMsg  (Core.subscriptions model.core) ]


------------------------------------------------------------
-- html events / attributes (extra)
------------------------------------------------------------

-- Keyboard Event

type alias KeyboardEvent = 
    { altKey : Bool
    , ctrlKey : Bool
    , keyCode : Int
    , metaKey : Bool
    , repeat : Bool
    , shiftKey : Bool
    }

keyboarEvent_toString : KeyboardEvent -> String
keyboarEvent_toString e =
    String.concat
        [ if e.ctrlKey then "C-" else ""
        , if e.altKey then "A-" else ""
        , if e.metaKey then "M-" else ""
        , if e.shiftKey then "S-"else ""
        , toString e.keyCode
        ]

decodeKeyboardEvent : Json.Decoder KeyboardEvent
decodeKeyboardEvent =
    Json.map6 KeyboardEvent
        (Json.field "altKey" Json.bool)
        (Json.field "ctrlKey" Json.bool)
        (Json.field "keyCode" Json.int)
        (Json.field "metaKey" Json.bool)
        (Json.field "repeat" Json.bool)
        (Json.field "shiftKey" Json.bool)    

                
onKeyDown : (KeyboardEvent -> msg) -> Attribute msg
onKeyDown tagger =
    on "keydown" (Json.map tagger decodeKeyboardEvent)

onKeyPress : (Int -> msg) -> Attribute msg
onKeyPress tagger =
    on "keypress" (Json.map tagger keyCode)

onKeyUp: (Int -> msg) -> Attribute msg
onKeyUp tagger =
    on "keyup" (Json.map tagger keyCode)


-- Composition Event (IME)

onCompositionStart: (String -> msg) -> Attribute msg
onCompositionStart tagger =
    on "compositionstart" (Json.map tagger (Json.field "data" Json.string))

onCompositionEnd: (String -> msg) -> Attribute msg
onCompositionEnd tagger =
    on "compositionend" (Json.map tagger (Json.field "data" Json.string))

onCompositionUpdate: (String -> msg) -> Attribute msg
onCompositionUpdate tagger =
    on "compositionupdate" (Json.map tagger (Json.field "data" Json.string))

-- Focus Event

onFocusIn : (Bool -> msg) -> Attribute msg
onFocusIn tagger =
    -- ほしいプロパティはないのでとりあえずダミーで bubbles を
    on "focusin" (Json.map tagger (Json.field "bubbles" Json.bool))

onFocusOut : (Bool -> msg) -> Attribute msg
onFocusOut tagger =
    -- ほしいプロパティはないのでとりあえずダミーで bubbles を
    on "focusout" (Json.map tagger (Json.field "bubbles" Json.bool))

-- Mouse Event

onMouseDown : (Mouse.Position -> msg) -> Attribute msg
onMouseDown tagger =
    on "mousedown" (Json.map tagger Mouse.position)


-- CustomEvent (clipboard)

onPasted: (String -> msg) -> Attribute msg
onPasted tagger =
    on "pasted" (Json.map tagger (Json.field "detail" Json.string))

onCopied: (String -> msg) -> Attribute msg
onCopied tagger =
    on "copied" (Json.map tagger (Json.field "detail" Json.string))

onCutted: (String -> msg) -> Attribute msg
onCutted tagger =
    on "cutted" (Json.map tagger (Json.field "detail" Json.string))


-- CustomAttributes

selecteddata : Maybe String -> Attribute msg
selecteddata selected_str =
    selected_str
        |> Maybe.withDefault ""
        |> Json.Encode.string
        |> property "selecteddata"


------------------------------------------------------------
-- Native (Mice)
------------------------------------------------------------


-- Function

calcTextWidth : String -> String -> Int
calcTextWidth id txt = Native.Mice.calcTextWidth id txt


-- TODO: Core とコピペになってるのどうにかする
type alias Rect =
    { left :Int
    , top : Int
    , right: Int
    , bottom : Int
    , x : Int
    , y : Int
    , width :Int
    , height : Int
    }

getBoundingClientRect: String -> Rect
getBoundingClientRect id = Native.Mice.getBoundingClientRect id


