module TextEditor exposing ( Model
                           , init
                           , update
                           , Msg(..)
                           , subscriptions
                           , view

                           , buffer
                           , setBuffer
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
    , drag : Bool

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
          False
          keymap
          Nothing
    , Cmd.map CoreMsg coreC
    )

buffer : Model -> Buffer.Model
buffer model =
    model.core.buffer

setBuffer : Buffer.Model -> Model -> Model
setBuffer newbuf model =
    let
        cm = model.core
    in
        { model
            | core = { cm | buffer= newbuf }
        }


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
    | DragStart MouseEvent
    | DragAt Mouse.Position
    | DragEnd Mouse.Position

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
                |> Tuple.mapFirst (\m -> {m|drag=False})
                |> Tuple.mapFirst (eventLog "pasted" s)
                |> Tuple.mapSecond (\c -> Cmd.batch [c, Cmd.map CoreMsg (Core.doFocus model.core)] )

        Copied s ->
            updateMap model (Commands.copy model.core)
                |> Tuple.mapFirst (\m -> {m|drag=False})
                |> Tuple.mapFirst (eventLog "copied" s)
                |> Tuple.mapSecond (\c -> Cmd.batch [c, Cmd.map CoreMsg (Core.doFocus model.core)] )

        Cutted s ->
            updateMap model (Commands.cut model.core)
                |> Tuple.mapFirst (\m -> {m|drag=False})
                |> Tuple.mapFirst (eventLog "cutted" s)
                |> Tuple.mapSecond (\c -> Cmd.batch [c, Cmd.map CoreMsg (Core.doFocus model.core)] )

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
            , Cmd.batch [ Cmd.map CoreMsg (Core.elaborateInputArea model.core)
                        , Cmd.map CoreMsg (Core.elaborateTapArea model.core)
                        ]
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

        DragStart mouseEvent  ->
            let
                xy = { x = mouseEvent.x, y = mouseEvent.y }

                rect = getBoundingClientRect (codeAreaID model.core)
                row = (xy.y - rect.top) // (emToPx model.core 1)
                ln = Buffer.line row model.core.buffer.contents |> Maybe.withDefault ""
                col = posToColumn model.core ln (xy.x - rect.left)

                (cm, cc) =  Commands.moveAt (row, col) model.core
            in
                case mouseEvent.button of
                    LeftMouse ->
                        ( { model | core = cm
                          , drag = True
                          }
                        |> eventLog "dragstart" (printDragInfo rect xy (row, col) )
                        |> blinkBlock
                        , Cmd.batch [ Cmd.map CoreMsg cc
                                    ]
                        )
                    _ ->
                        (model, Cmd.none)


        DragAt xy ->
            let
                rect = getBoundingClientRect (codeAreaID model.core)
                row = (xy.y - rect.top) // (emToPx model.core 1)
                ln = Buffer.line row model.core.buffer.contents |> Maybe.withDefault ""
                col = posToColumn model.core ln (xy.x - rect.left)

                (cm, cc) =  Commands.selectAt (row, col) model.core
            in
                ( { model | core = cm }
                  |> eventLog "dragat" (printDragInfo rect xy (row, col) )
                  |> blinkBlock
                , Cmd.batch [ Cmd.map CoreMsg cc
                            ]
                )

        DragEnd xy ->
            ( {model | drag = False }
                  |> eventLog "dragend" ""
            , Cmd.none
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
      |> eventLog "compositionupdate" data
    , Cmd.none
    )

compositionEnd : String -> Model -> (Model, Cmd Msg)
compositionEnd data model =
    -- note: 変換プレビューのクリアはするが、
    --        firefox ではこの後 input イベントがくるので、
    --        それを無視する為 enable-conposerは立てたままにする (keypressイベントで解除する、そちらを参照)
    let
        (m, c) = Core.compositionEnd data model.core
    in
        ( { model
              | core = m
          }
          |> eventLog "compositionend" data
        , Cmd.map CoreMsg c
        )

posToColumn : Core.Model -> String -> Int -> Int
posToColumn model line pos_x =
    let
        calc_w  = calcTextWidth (rulerID model)
        calc_col = (\ ln c x ->
                        if (calc_w (String.left c ln)) > x || String.length ln < c  then c - 1
                        else calc_col ln (c + 1)  x
                   )
    in
        calc_col line 0 pos_x

printDragInfo: Rect -> Mouse.Position -> (Int, Int) -> String
printDragInfo rect xy (row, col) =
    "pos=" ++ (toString xy.x) ++ "," ++ (toString xy.y)
        ++ "; offset_pos=" ++ (toString (xy.x - rect.left)) ++ "," ++ (toString (xy.y - rect.top))
        ++ "; row_col=" ++ (toString row) ++ "," ++(toString col)

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
                , ("position", "relative")
                , ("user-select", "none")
                , ("-webkit-user-select", "none")
                , ("-moz-user-select", "none")
                ]
        , onClick ClickScreen
        ]
        [ div [ id <| sceneID model.core
              , class "editor-scene"
              , style [ ("position", "relative") ]
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
        div [ id <| lineNumAreaID model
            , class "line-num-area"
            , style [ ("text-align", "right")
                    , ("padding-right", "0.8em")
                    ]
            ] <|
            List.map
                (λ n -> div [ class "line-num"
                             , style [ ("height", 1 |> emToPxString model)
                                     , ("text-wrap", "none")]
                             ] [ text (toString n) ])
                (List.range 1 (List.length contents))

codeArea : Core.Model -> Html Msg
codeArea model =
    div [ id <| codeAreaID model
        , class "code-area"
        , style [ ("margin", "0"), ("padding", "0"), ("border", "none")
                , ("flex-grow", "1") -- "line" の行末以降のタップでもカーソル移動したいので、いっぱいまで伸びるようにしておく
                , ("position", "relative")
                ]
        ]
        [ ruler model
        , cursorLayer model
        , tapControlLayer model
        , markerLayer model
        , codeLayer model
        ]

codeLayer: Core.Model  -> Html Msg
codeLayer model = 
    let
        contents = model.buffer.contents
        cursor = model.buffer.cursor
    in
        div [ class "code-layer"
            , style [ ("margin", "0"), ("padding", "0"), ("border", "none")
                    , ("width", "100%")
                    ]
            ] <|
            List.indexedMap
                (λ n ln ->
                      div [ class "line"
                          , style [ ("height", 1 |> emToPxString model)
                                  , ("width", "100%")
                                  , ("text-wrap", "none")
                                  , ("white-space", "pre")
                                  , ("pointer-events", "auto") -- マウスイベントの対象にする
                                  ]
                          ] <|
                          if n == cursor.row && model.compositionPreview /= Nothing then
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
                     , ("height", 1 |> emToPxString model)
                     , ("align-items" , "baseline")

                     , ("top" , model.buffer.cursor.row |> emToPxString model)
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
                                        , ("width", model.compositionPreview
                                                       |> Maybe.withDefault ""
                                                       |> String.length |> flip (+) 1
                                                       |> toEmString
                                          )
                                        , ("resize", "none")
                                        , ("height", 1 |> emToPxString model)
                                        , ("font-size", "1em") -- 親のスタイルにあわせて大きさを買えるために必要
                                        , ("font-family", "inherit")
                                        , ("position", "absolute")
                                        ]
                                ]
                           []
                     , span [ class "pad-composition-preview"
                            , style [ ("visibility", "hidden")
                                    , ("white-space", "nowrap")
                                    ]
                            ]
                           [compositionPreview model.compositionPreview]
                     , cursorView model
                     ]
               ]
        ]

tapControlLayer : Core.Model -> Html Msg
tapControlLayer model =
    div [ id <| tapAreaID model
        , style [ ("position", "absolute")
                , ("pointer-events", "auto")
                , ("width", "100%"), ("height", "100%")
                , ("z-index", "9")

                , ("color", "green")
--                , ("background-color", "red")
--                , ("opacity", "0.2")
                ]
        , contenteditable True
        , onClick ClickScreen
        , onPasted Pasted
        , onCopied Copied
        , onCutted Cutted
        , onMouseDown DragStart
        ]
        [ text <| Maybe.withDefault "" <| Buffer.selectedString model.buffer ]


markerLayer: Core.Model -> Html Msg
markerLayer model =
    case model.buffer.selection of
        Nothing ->
            text ""

        Just sel ->
            let
                bpos = if (Buffer.isPreviosPos sel.begin sel.end) then sel.begin else sel.end
                epos = if (Buffer.isPreviosPos sel.begin sel.end) then sel.end else sel.begin

                rect = getBoundingClientRect (codeAreaID model)
                calc_w  = calcTextWidth (rulerID model)
                bpix = calc_w (Buffer.line (Tuple.first bpos) model.buffer.contents |> Maybe.withDefault "" |> String.left (Tuple.second bpos))
                epix = calc_w (Buffer.line (Tuple.first epos) model.buffer.contents |> Maybe.withDefault "" |> String.left (Tuple.second epos))


                ms = List.range (Tuple.first bpos) (Tuple.first epos)
                   |> List.map (\ r ->
                                    let
                                        pb = if r == (Tuple.first bpos)
                                             then bpix
                                             else 0 -- rect.left
                                        pe = if r == (Tuple.first epos)
                                             then epix
                                             else rect.right - rect.left

                                        cb = if r == (Tuple.first bpos)
                                             then bpos |> Tuple.second
                                             else 0
                                        ce = if r == (Tuple.first epos)
                                             then epos |> Tuple.second
                                             else String.length <| (Buffer.line r model.buffer.contents |> Maybe.withDefault "")
                                    in
                                        {row =r, begin_col = cb, end_col = ce, begin_px = pb, end_px = pe}
                               )
            in
                div [ class "marker-layer"
                    , style [ ("position", "absolute")
                            , ("pointer-events", "none") -- マウスイベントの対象外にする
                            , ("z-index", "5") -- note: 範囲選択を一番上にしたいため 99 という数字自体に意味はない
                            ]
                    ]
                    ( List.map (\ m ->
                                  div [ style [ ("position", "absolute")
                                              , ("top" , m.row |> emToPxString model )
                                              , ("left" , m.begin_px |> toPxString)
                                              , ("width", m.end_px - m.begin_px |> toPxString)
                                              , ("height", 1 |> emToPxString model )

                                              , ("background-color", "blue")
                                              , ("color","white")
                                              , ("white-space", "pre")
                                              ]
                                      ]
                                      [ Buffer.line m.row model.buffer.contents |> Maybe.withDefault ""
                                            |> String.dropLeft m.begin_col
                                            |> String.left (m.end_col - m.begin_col)
                                            |> (\l -> if l == "" then " " else l)
                                            |> text
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



ruler : Core.Model -> Html msg
ruler model = 
    div [ class "ruler-layer"
        , style [ ("position", "absolute")
                , ("overflow", "hidden")
                , ("width", "0px")
                , ("opacity", "0")
                , ("pointer-events", "none") -- マウスイベントの対象外にする
                ]
        ]
        [ span [ id <| rulerID model
               , style [ ("white-space", "pre")
                       ]
               ]
               []
        , span [ id <| prototyleEmID model
               , style [ ("white-space", "pre")
                       ]
               ]
               [ text "箱"]
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
                , ("height", 1 |> emToPxString model )
                , ("width", "3px")
                , ("z-index", "5")
                ]
         , id <| cursorID model
         ]
    []


------------------------------------------------------------
-- Subscriptions
------------------------------------------------------------

subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch <| [ Sub.map CoreMsg  (Core.subscriptions model.core) ]
        ++ case model.drag of
               True -> [Mouse.moves DragAt, Mouse.ups DragEnd]
               False -> []


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

onMouseDown : (MouseEvent -> msg) -> Attribute msg
onMouseDown tagger =
    on "mousedown" (Json.map tagger mouseEvent)


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
-- em prottype
--     height : 1em しても、マルチバイト文字などでは文字表示にひつような高さが確保できない（ことがおおい）ため、
--     一度マルチバイト文字をレンダリングさせて、高さのpxを測り、それを指定するようにする
------------------------------------------------------------

emToPx : Core.Model -> Int -> Int
emToPx model n =
    prototyleEmID model
        |> getBoundingClientRect
        |> .height
        |>  flip (*) n

toPxString : Int -> String
toPxString = toString >> flip (++) "px"

toEmString : Int -> String
toEmString = toString >> flip (++) "em"

emToPxString : Core.Model -> Int -> String
emToPxString model = emToPx model >> toPxString



------------------------------------------------------------
-- Mouse Event
------------------------------------------------------------

type alias MouseEvent =
  { x : Int
  , y : Int
  , button : MouseButton
  }

type MouseButton
  = LeftMouse
  | MiddleMouse
  | RightMouse
  | X1Mouse
  | X2Mouse

mouseButton : Json.Decoder MouseButton
mouseButton =
    Json.int
        |> Json.andThen (\n ->
           case n of
               0 -> Json.succeed LeftMouse
               1 -> Json.succeed MiddleMouse
               2 -> Json.succeed RightMouse
               3 -> Json.succeed X1Mouse
               4 -> Json.succeed X2Mouse
               x -> Json.fail <| "unknown mouse button value (" ++ (toString x) ++ ")"
        )

mouseEvent : Json.Decoder MouseEvent
mouseEvent =
  Json.map3 MouseEvent
    (Json.field "pageX" Json.int)
    (Json.field "pageY" Json.int)
    (Json.field "button" mouseButton)


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


