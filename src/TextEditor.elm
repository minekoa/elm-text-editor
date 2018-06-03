module TextEditor exposing ( Model
                           , init
                           , update
                           , Msg(..)
                           , subscriptions
                           , view

                           , buffer
                           , setBuffer
                           , EventInfo
                           , execCommand
                           )

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Json.Decode as Json
import Json.Encode
import Mouse
import Task exposing (Task)
import Date

import TextEditor.Buffer as Buffer
import TextEditor.Core as Core exposing (..)
import TextEditor.Core.Commands as Commands

import TextEditor.Commands
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
    , event_log : Maybe (List EventInfo)
    }

type alias EventInfo =
    { date : Date.Date
    , name : String
    , data : String
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

execCommand : TextEditor.Commands.Command -> Model -> (Model, Cmd Msg)
execCommand cmd model =
    exec_command_proc cmd model
        |> logging "exec-comd" cmd.id

exec_command_proc : TextEditor.Commands.Command -> Model -> (Model, Cmd Msg)
exec_command_proc cmd model =
    let
        (cm, cc) = cmd.f model.core
    in
        ( { model
              | core = { cm | lastCommand = Just cmd.id }
          }
        , Cmd.map CoreMsg cc
        )

setLastCommand : String -> (Model, Cmd Msg) -> (Model, Cmd Msg)
setLastCommand id (model, cmdmsg) =
    let
        cm = model.core
    in
        ( { model
              | core = { cm | lastCommand = Just id }
          }
        , cmdmsg
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
    | DragStart MouseEvent
    | DragAt Mouse.Position
    | DragEnd Mouse.Position
    | Logging String String Date.Date

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
                |> setLastCommand "clipboard_pasete"
                |> logging "pasted" s
                |> Tuple.mapSecond (\c -> Cmd.batch [c, Cmd.map CoreMsg (Core.doFocus model.core)] )

        Copied s ->
            updateMap model (Commands.copy model.core)
                |> Tuple.mapFirst (\m -> {m|drag=False})
                |> setLastCommand "clipboard_copy"
                |> logging "copied" s
                |> Tuple.mapSecond (\c -> Cmd.batch [c, Cmd.map CoreMsg (Core.doFocus model.core)] )

        Cutted s ->
            updateMap model (Commands.cut model.core)
                |> Tuple.mapFirst (\m -> {m|drag=False})
                |> setLastCommand "clipboard_cut"
                |> logging "cutted" s
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
            , Cmd.map CoreMsg (Core.doFocus model.core)
            )
                |> logging "setfocus" ""

        DragStart mouseEvent  ->
            let
                xy = { x = mouseEvent.x, y = mouseEvent.y }
                (row, col) = posToRowColumn model.core xy

                (cm, cc) =  model.core
                              |> Commands.batch [ Commands.moveAt (row, col)
                                                , Commands.markClear
                                                ]
            in
                case mouseEvent.button of
                    LeftMouse ->
                        ( { model | core = cm
                          , drag = True
                          }
                            |> blinkBlock
                        , Cmd.batch [ Cmd.map CoreMsg cc ]
                        )
                            |> logging "dragstart" (printDragInfo xy (row, col))

                    RightMouse ->
                        if model.core.buffer.selection == Nothing then
                            ( { model | core = cm }
                                |> blinkBlock
                            , Cmd.batch [ Cmd.map CoreMsg cc ]
                            )
                                |> setLastCommand ( ["moveTo (", row |> toString, ", ", col |> toString, ")"] |> String.concat )
                                |> logging "moveto" (printDragInfo xy (row, col) )
                                                    
                        else
                            (model, Cmd.none)
                    _ ->
                        (model, Cmd.none)


        DragAt xy ->
            let
                (row, col) = posToRowColumn model.core xy
                (cm, cc) =  Commands.selectAt (row, col) model.core
            in
                ( { model | core = cm }
                  |> blinkBlock
                , Cmd.batch [ Cmd.map CoreMsg cc
                            ]
                )
                    |> setLastCommand ( ["selectAt (", row |> toString, ", ", col |> toString, ")"] |> String.concat )
                    |> logging "dragat" (printDragInfo xy (row, col) )

        DragEnd xy ->
            ( {model | drag = False }
            , Cmd.none
            )
                |> if model.drag then logging "dragend" "" else identity

        Logging name data date ->
            let
                new_event = { name = name
                            , data = data
                            , date = date
                            }
            in
                ( { model | event_log = Maybe.andThen (\logs -> Just (new_event :: logs)) model.event_log }
                , Cmd.none
                )


input: String -> Model -> (Model, Cmd Msg)
input s model =
    case model.enableComposer of
        True ->
            ( model
            , Cmd.none
            )
                |> logging "input (ignored)" s
        False ->
            updateMap model (Commands.insert (String.right 1 s) model.core)
                |> setLastCommand ( ["insert ", s] |> String.concat )
                |> logging "input" (String.right 1 s)


keyDown : KeyboardEvent -> Model -> (Model, Cmd Msg)
keyDown e model =
    case KeyBind.find (e.ctrlKey, e.altKey, e.shiftKey, e.keyCode) model.keymap of
        Just editorcmd ->
            exec_command_proc editorcmd model
                |> logging "keydown" ((keyboarEvent_toString e) ++ ", editorcmd=" ++ editorcmd.id)
        Nothing ->
            ( model
            , Cmd.none
            )
                |> logging "keydown" (keyboarEvent_toString e)


keyPress : Int -> Model -> (Model, Cmd Msg)
keyPress code model =
    -- IME入力中にkeypress イベントがこないことを利用して IME入力モード(inputを反映するか否かのフラグ）を解除
    -- ※ compositonEnd で解除してしまうと、firefoxとchromeの振る舞いの違いでハマる
    --        chrome  :: keydown 229 -> compositionend s
    --        firefox ::   (null)    -> compositionend s -> input s
    ( model
        |> composerDisable
    , Cmd.none
    )
        |> logging "keypress" (toString code)


compositionStart : String -> Model -> (Model, Cmd Msg)
compositionStart data model =
    -- note: この data は入力された文字列 **ではない**
    ( { model
          | core = Core.compositionStart model.core
      }
      |> composerEnable
    , Cmd.none
    )
      |> logging "compositoinstart" data


compositionUpdate : String -> Model -> (Model, Cmd Msg)
compositionUpdate data model =
    ( { model
          | core = Core.compositionUpdate data model.core
      }
    , Cmd.none
    )
      |> logging "compositionupdate" data

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
        , Cmd.map CoreMsg c
        )
          |> setLastCommand ( ["insert ", data] |> String.concat )
          |> logging "compositionend" data


posToRowColumn : Core.Model -> {x : Int, y : Int } -> (Int, Int)
posToRowColumn model xy =
    let
        rect = getBoundingClientRect (codeAreaID model)
        row  = yToRow model (xy.y - rect.top)
        line = Buffer.line row model.buffer.contents |> Maybe.withDefault ""
        col = xToColumn model line (xy.x - rect.left)
    in
        (row, col)

yToRow : Core.Model -> Int -> Int
yToRow model pos_y =
    Basics.min
        (pos_y // (emToPx model 1))
        (model.buffer.contents |> List.length  |> flip (-) 1)

xToColumn : Core.Model -> String -> Int -> Int
xToColumn model line pos_x =
    let
        calc_w  = calcTextWidth (rulerID model)
        calc_col = (\ ln c x ->
                        if (calc_w (String.left c ln)) > x || String.length ln < c  then c - 1
                        else calc_col ln (c + 1)  x
                   )
    in
        calc_col line 0 pos_x

printDragInfo: Mouse.Position -> (Int, Int) -> String
printDragInfo xy (row, col) =
    "pos=" ++ (toString xy.x) ++ "," ++ (toString xy.y)
        ++ "; row_col=" ++ (toString row) ++ "," ++(toString col)

------------------------------------------------------------
-- control state update
------------------------------------------------------------

logging : String -> String -> (Model, Cmd Msg) -> (Model, Cmd Msg)
logging ev_name ev_data (model, cmd_msg) =
    case model.event_log of
        Just log ->
            ( model
            , Cmd.batch [ cmd_msg
                        , Task.perform (Logging ev_name ev_data) Date.now
                        ]
            )
        Nothing ->
            (model, cmd_msg)


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

-- for debug
--                , ("color", "green")
--                , ("background-color", "red")
--                , ("opacity", "0.8")
                , ("opacity", "0")
                ]
        , contenteditable True
        , onPasted Pasted
        , onCopied Copied
        , onCutted Cutted
        , onMouseDown DragStart
        , selecteddata <| Buffer.selectedString model.buffer
        ]
        (selectedTouchPad model)

selectedTouchPad : Core.Model -> List (Html Msg)
selectedTouchPad model =
    case model.buffer.selection of
        Nothing -> []
        Just sel ->
            -- 選択範囲を右クリックしたときに、大体の位置に選択されたテキストがあればいいので、
            -- 行単位で選択領域を再現（列はみない）
            let
                bpos = if (Buffer.isPreviosPos sel.begin sel.end) then sel.begin else sel.end
                epos = if (Buffer.isPreviosPos sel.begin sel.end) then sel.end else sel.begin
            in
                (List.range (Tuple.first bpos) (Tuple.first epos))
                   |> List.map (\ row ->
                                  div [ style [ ("position", "absolute")
                                              , ("top" , row |> emToPxString model )
                                              , ("left" , "0")
                                              , ("height", 1 |> emToPxString model )

                                              , ("background-color", "gray")
                                              , ("color","white")
                                              , ("white-space", "pre")
                                              ]
                                      ]
                                      [ Buffer.line row model.buffer.contents |> Maybe.withDefault "" |> text ]
                               )



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
        ++ [ Mouse.ups DragEnd ]
        ++ case model.drag of
               True -> [ Mouse.moves DragAt ]
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


