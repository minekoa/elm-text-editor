module TextEditor exposing ( Model
                           , init
                           , initLikeNotepad
                           , initLikeCodeEditor
                           , initLikeModernEditor
                           , update
                           , Msg(UpdateContents)
                           , subscriptions
                           , view

                           , buffer
                           , setBuffer
                           , options
                           , setOptions

                           , EventInfo
                           , execCommand
                           )

{-| It is a simple text editor widget. It is a component.


It has one set required for HTML program - type `Model`,` Msg`, `update`,` subscriptions`, `view` function.

We will incorporate these into the HTML application you want to use a text editor and specify.

# Definition

@docs Model, Msg, EventInfo

# Buffer

@docs buffer, setBuffer

# Editor Options

@docs options, setOptions

# Editor Commands

@docs execCommand

# Component entry points (Determine a next model, subscriptions, create view)

@docs init, initLikeNotepad, initLikeCodeEditor, initLikeModernEditor
@docs update, subscriptions, view
-}


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

import TextEditor.KeyboardEvent exposing (..)
import TextEditor.TextMarker as TextMarker

import TextEditor.Commands
import TextEditor.Option
import TextEditor.Style
import TextEditor.KeyBind as KeyBind


import Native.Mice


{-| The `core` member is an essential model of the text editor and is subject to change with` TextEditor.Command`.
You shoud change this by use `execCommand` function.

The `keymap` member defines the editor command to be enforced for the keydown event. 
If an event is caught here, this `keydown` event handler return with `preventDefault=true`.

When the `event_log` menber is not `Nothing`, keyboard events and mouse events are logged here.

Other members (`enableComposer` and `drag`) are state variables for internal processing, you should not change directly.
-}
type alias Model =
    { core : Core.Model

    -- state
    , enableComposer : Bool -- ブラウザの互換のため、compositionEvent の遷移とは別の「IME入力中」判定フラグが必要
    , drag : Bool

    -- options
    , keymap : List KeyBind.KeyBind
    , style : TextEditor.Style.Style

    -- for debug
    , event_log : Maybe (List EventInfo)
    }

{-| Recode for the `event_log`
-}
type alias EventInfo =
    { date : Date.Date
    , name : String
    , data : String
    }

{-| Generate new `Model`.

The `id` argument is a unique id for TextEditor's Dom Elements used by JavaScript(Native).
The `keymap` argument is set as is in `Model.keymap`. (`Model.keymap` is dynamically changeable)

The `text` argument is a string for generating a buffer, which is processed into a list of charactors separated by `\n` and stored in `TextEditor.Buffer.contents`.
-}
init : String -> TextEditor.Option.Option -> TextEditor.Style.Style -> List KeyBind.KeyBind -> String -> (Model, Cmd Msg)
init id opts style keymap text =
    let
        (coreM, coreC) = Core.init id opts text
    in
    ( Model
          coreM
          False
          False
          keymap
          style
          Nothing
    , Cmd.map CoreMsg coreC
    )

{-|
-}
initLikeCodeEditor : String -> String -> (Model, Cmd Msg)
initLikeCodeEditor id text =
    init
        id
        TextEditor.Option.editorLikeOptions
        TextEditor.Style.editorLikeDarkStyle
        (KeyBind.basic ++ KeyBind.gates ++ KeyBind.emacsLike)        
        text

{-|
-}
initLikeNotepad : String -> String -> (Model, Cmd Msg)
initLikeNotepad id text =
    init
        id
        TextEditor.Option.notepadLikeOptions
        TextEditor.Style.notepadLikeStyle
        (KeyBind.basic ++ KeyBind.gates)        
        text

{-|
-}
initLikeModernEditor : String -> String -> (Model, Cmd Msg)
initLikeModernEditor id text =
    init
        id
        TextEditor.Option.editorLikeOptions
        TextEditor.Style.modernMinchoStyle
        (KeyBind.basic ++ KeyBind.gates ++ KeyBind.emacsLike)        
        text



{-| Get the buffer.
-}
buffer : Model -> Buffer.Buffer
buffer model =
    model.core.buffer

{-| Set a buffer.
-}
setBuffer : Buffer.Buffer -> Model -> Model
setBuffer newbuf model =
    let
        cm = model.core
    in
        { model
            | core = { cm
                         | buffer= newbuf
                         , lastCommand = Just "setBuffer"
                     }
        }

{-| Get now editor options -}
options : Model -> TextEditor.Option.Option
options model =
    model.core.option

{-|
-}        
setOptions : TextEditor.Option.Option -> Model -> Model
setOptions opts model =
    let
        cm = model.core
    in
        { model | core = { cm | option = opts } }

{-| Execute the Editor command. If you want to manipulate the Editor's model in the program, use here.
-}
execCommand : TextEditor.Commands.Command -> Model -> (Model, Cmd Msg)
execCommand cmd model =
    exec_command_proc cmd model
        |> invokeEvent
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

{-| Update events of TextEditor.

Processing can be separated according to message type, 
but it is not recommended because events occurring are not intuitive due to the convenience of browser implementation
(For example, `KeyDown` only occurs with keys defined in` Model.keymap`).

`Input s` is different from that of Html.textarea, s is not the full text of the buffer, it is only updated characters. 
Input does not occur with IME input confirmation (IME confirmation input is CompositionEnd).
-}
type Msg
    = CoreMsg Core.Msg
    | UpdateContents (List String)
    | Pasted String
    | Copied String
    | Cutted String
    | Input String
    | KeyDown KeyboardEvent
    | KeyPress Int
    | KeyUp Int
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


invokeEvent : (Model, Cmd Msg) -> (Model, Cmd Msg)
invokeEvent (model, cmdmsg) =
    case model.core.eventRequest of
        Just (Core.EventInput contents) ->
            ( { model | core = Core.clearEventRequest model.core }
            , Cmd.batch [ cmdmsg
                        , Task.perform (\_ -> UpdateContents contents) (Task.succeed True)
                        ]
            )
        Nothing ->
            (model, cmdmsg)

{-| Update model 
-}
update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
    case msg of
        CoreMsg cmsg ->
            let
                (cm, cc) = Core.update cmsg model.core
            in
                ( { model | core = cm  }
                , Cmd.map CoreMsg cc
                )
                |> invokeEvent

        -- invoke されるやつ
        UpdateContents contents ->
            ( model, Cmd.none )

        -- System-Clipboard's Action Notification (Do Fitting Elm's Model State)

        Pasted s ->
            updateMap model (Commands.paste s model.core)
                |> Tuple.mapFirst (\m -> {m|drag=False})
                |> setLastCommand "clipboard_pasete"
                |> logging "pasted" s
                |> Tuple.mapSecond (\c -> Cmd.batch [c, Cmd.map CoreMsg (Core.doFocus model.core)] )
                |> invokeEvent

        Copied s ->
            updateMap model (Commands.copy model.core)
                |> Tuple.mapFirst (\m -> {m|drag=False})
                |> setLastCommand "clipboard_copy"
                |> logging "copied" s
                |> invokeEvent

        Cutted s ->
            updateMap model (Commands.cut model.core)
                |> Tuple.mapFirst (\m -> {m|drag=False})
                |> setLastCommand "clipboard_cut"
                |> logging "cutted" s
                |> Tuple.mapSecond (\c -> Cmd.batch [c, Cmd.map CoreMsg (Core.doFocus model.core)] )
                |> invokeEvent

        -- View Operation Event

        Input s ->
            input s model
                |> invokeEvent

        KeyDown keyevent ->
            keyDown keyevent model
                |> invokeEvent
 
        KeyPress code ->
            keyPress code model

        KeyUp code ->
            keyUp code model

        CompositionStart data ->
            compositionStart data model

        CompositionUpdate data ->
            compositionUpdate data model

        CompositionEnd data ->
            compositionEnd data model
                |> invokeEvent

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
                xy = { x = mouseEvent.pageX, y = mouseEvent.pageY }
                chpos = geoPosToCharPos model.core xy

                (cm, cc) =  model.core
                              |> Commands.batch [ Commands.moveAt chpos
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
                            |> logging "dragstart" (printDragInfo xy chpos)

                    RightMouse ->
                        if model.core.buffer.selection == Nothing then
                            ( { model | core = cm }
                                |> blinkBlock
                            , Cmd.batch [ Cmd.map CoreMsg cc ]
                            )
                                |> setLastCommand ( ["moveTo (", chpos.row |> toString, ", ", chpos.column |> toString, ")"] |> String.concat )
                                |> logging "moveto" (printDragInfo xy chpos )
                                                    
                        else
                            (model, Cmd.none)
                    _ ->
                        (model, Cmd.none)


        DragAt xy ->
            let
                chpos = geoPosToCharPos model.core xy
                (cm, cc) =  Commands.selectAt chpos model.core
            in
                ( { model | core = cm }
                  |> blinkBlock
                , Cmd.batch [ Cmd.map CoreMsg cc
                            ]
                )
                    |> setLastCommand ( ["selectAt (", chpos.row |> toString, ", ", chpos.column |> toString, ")"] |> String.concat )
                    |> logging "dragat" (printDragInfo xy chpos )

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
    case model.enableComposer || String.isEmpty s of -- Firefox のcompositionEnd後のinputを弾くため、空文字判定 (JavaScript側で空にしている）
        True ->
            ( model
            , Cmd.none
            )
                |> logging "input (ignored)" s
        False ->
            updateMap model (Commands.insert (String.right 1 s) model.core)
                |> setLastCommand ( ["insert ", s] |> String.concat )
                |> logging "input" (String.right 1 s)

-- note:
--   compositionStart ~ ..End で ON/OFFしている enableComposer フラグは、
--   `inputEvent.isComposing` と状態が一致するので、こちらを使えば良いように思える。
-- 
--   しかし、
--
--   ```
--   on "input" Json.Decode.map2 tagger
--                  (Json.Decode.field "data" Json.Decode.string)
--                  (Json.Decode.field "isComposing" Json.Decode.bool)
--   ```
--
--    は、できあいの onInputと異なり、改行文字入力を拾えないため(chrome)、わざわざフラグ管理を行っている



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
    ( model, Cmd.none )
        |> logging "keypress" (toString code)

keyUp : Int -> Model -> (Model, Cmd Msg)
keyUp code model =
    ( model, Cmd.none )
        |> logging "keyup" (toString code)

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
    let
        (m, c) = Core.compositionEnd data model.core
    in
        ( { model
              | core = m
          }
              |> composerDisable
        , Cmd.map CoreMsg c
        )
          |> setLastCommand ( ["insert ", data] |> String.concat )
          |> logging "compositionend" data


geoPosToCharPos : Core.Model -> {x : Int, y : Int } -> Buffer.Position
geoPosToCharPos model pageXy =
    -- note: Mouse.move や Mouse.ups が返すxy は
    --       clientXY(スクリーンに対する座標）ではなく pageXY (ドキュメントに対する座標)
    --       なので、余計な手間(see. Nateve/Mice.js) だが PageXY座標系にて計算を行う
    let
        rect = getBoundingPageRect (codeAreaID model)
        row  = yToRow model (pageXy.y - rect.top)
        line = Buffer.line row model.buffer |> Maybe.withDefault ""
        col = xToColumn model line (pageXy.x - rect.left)
    in
        Buffer.Position row col

yToRow : Core.Model -> Int -> Int
yToRow model pos_y =
    Basics.min
        (pos_y // (emToPx model 1))
        (model.buffer.contents |> List.length  |> flip (-) 1)

xToColumn : Core.Model -> String -> Int -> Int
xToColumn model line pos_x =
    let
        calc_w  = calcTextWidth (rulerID model)
        markup_ln = TextMarker.markupChank model.option.showControlCharactor model.option.tabOrder >> TextMarker.toString
        calc_col = (\ ln c x ->
                        if (calc_w (String.left c ln |> markup_ln)) > x || String.length ln < c  then c - 1
                        else calc_col ln (c + 1)  x
                   )
    in
        calc_col line 0 pos_x

printDragInfo: Mouse.Position -> Buffer.Position -> String
printDragInfo xy rowcol =
    "pos=" ++ (toString xy.x) ++ ", " ++ (toString xy.y)
        ++ "; row_col=" ++ (toString rowcol.row) ++ ", " ++(toString rowcol.column)

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

{-| View of the text editor 
-}
view : Model -> Html Msg
view model =
    div [ id <| frameID model.core
        , class "elm-text-editor-frame"
        , style [ ("margin", "0"), ("padding", "0"), ("width", "100%"), ("height", "100%")
                , ("overflow","auto")
                , ("position", "relative")
                , ("user-select", "none")
                , ("-webkit-user-select", "none")
                , ("-moz-user-select", "none")
                ]
        , onClick ClickScreen
        ]
        [ stylesheet model.style (frameID model.core)
        , div [ id <| sceneID model.core
              , class "elm-text-editor-scene"
              , style [ ("position", "relative") 
                      , ("min-height", "100%")
                      , ("visibility", if (emToPx model.core 1) <= 0 then "hidden" else "visible")
                      ]
              ]
              [ presentation model
              ]
        ]


presentation : Model -> Html Msg
presentation model =
    div [ style [ ("display", "flex"), ("flex-direction", "row"), ("flex-wrap", "nowrap")
                , ("margin", "0"), ("padding", "0"), ("width", "100%"), ("height", "100%")
                , ("position", "relative")
                , ("line-height", emToPxString model.core 1)
                ]
        , onFocusIn FocusIn
        , onFocusOut FocusOut
        ]
        [ lineNumArea (model.core |>  \m -> if (emToPx m 1) <= 0 then {m| buffer= Buffer.init ""} else m)
        , codeArea model.keymap (model.core |>  \m -> if (emToPx m 1) <= 0 then {m| buffer= Buffer.init ""} else m)
        ]

lineNumArea : Core.Model -> Html Msg
lineNumArea model =
    let
        contents = model.buffer.contents
    in
        div [ id <| lineNumAreaID model
            , class "elm-text-editor-linenum"
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

codeArea : List KeyBind.KeyBind -> Core.Model -> Html Msg
codeArea keymap model =
    div [ id <| codeAreaID model
        , class "code-area"
        , style [ ("margin", "0"), ("padding", "0"), ("border", "none")
                , ("flex-grow", "1") -- "line" の行末以降のタップでもカーソル移動したいので、いっぱいまで伸びるようにしておく
                , ("position", "relative")
                ]
        ]
        [ ruler model
        , cursorLayer keymap model
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
                                     ( String.left cursor.column ln
                                             |> TextMarker.markupChank model.option.showControlCharactor model.option.tabOrder
                                             |> TextMarker.toHtml
                                     )
                              , compositionPreview model.compositionPreview
                              , span [ style [ ("position", "relative")
                                             , ("white-space", "pre")
                                             , ("pointer-events", "none") -- マウスイベントの対象外にする
                                             ]
                                     ]
                                     ( String.dropLeft cursor.column ln
                                           |> TextMarker.markupLine model.option.showControlCharactor model.option.tabOrder
                                           |> TextMarker.toHtml
                                     )
                              ]
                          else
                              ( ln
                                  |> TextMarker.markupLine model.option.showControlCharactor model.option.tabOrder
                                  |> TextMarker.toHtml
                              )
                ) contents


cursorLayer : List KeyBind.KeyBind -> Core.Model -> Html Msg
cursorLayer keymap model =
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
                                , onKeyDown keymap KeyDown
--                                , onKeyDownForDeepAnalayze KeyDown  -- すべてのkeydownイベントを見たい場合は onKeyDown を無効にしてこちらを有効にする
                                , onKeyPress KeyPress
                                , onKeyUp KeyUp
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
                (List.range bpos.row epos.row)
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
                                      [ Buffer.line row model.buffer |> Maybe.withDefault "" |> text ]
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
                bpix = calc_w (Buffer.line bpos.row model.buffer |> Maybe.withDefault "" |> String.left bpos.column |> TextMarker.markupChank model.option.showControlCharactor model.option.tabOrder |> TextMarker.toString )
                epix = calc_w (Buffer.line epos.row model.buffer |> Maybe.withDefault "" |> String.left epos.column |> TextMarker.markupChank model.option.showControlCharactor model.option.tabOrder |> TextMarker.toString )

                ms = List.range bpos.row epos.row
                   |> List.map (\ r ->
                                    let
                                        pb = if r == bpos.row
                                             then bpix
                                             else 0 -- rect.left
                                        pe = if r == epos.row
                                             then epix
                                             else rect.right - rect.left

                                        cb = if r == bpos.row
                                             then bpos.column
                                             else 0
                                        ce = if r == epos.row
                                             then epos.column
                                             else String.length <| (Buffer.line r model.buffer |> Maybe.withDefault "")
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
                                  div [ class "elm-text-editor-selection"
                                      , style [ ("position", "absolute")
                                              , ("top" , m.row |> emToPxString model )
                                              , ("left" , m.begin_px |> toPxString)
                                              , ("width", m.end_px - m.begin_px |> toPxString)
                                              , ("height", 1 |> emToPxString model )

                                              , ("white-space", "pre")
                                              ]
                                      ]
                                      ( Buffer.line m.row model.buffer |> Maybe.withDefault ""
                                            |> String.dropLeft m.begin_col
                                            |> String.left (m.end_col - m.begin_col)
                                            |> (\ln -> if (Buffer.line m.row model.buffer |> Maybe.withDefault "" |> String.length) == m.end_col
                                                       then TextMarker.markupLine  model.option.showControlCharactor model.option.tabOrder ln
                                                       else TextMarker.markupChank model.option.showControlCharactor model.option.tabOrder ln
                                               )
                                            |> TextMarker.toHtml
                                      )
                             ) ms )

pad : Core.Model -> Html msg
pad model =
    let
        cur      = model.buffer.cursor
    in
    span [ class "pad"
         , style [ ("position", "relative")
                 , ("white-space", "pre")
                 , ("visibility", "hidden")                     
                 , ("pointer-events", "none") -- マウスイベントの対象外にする
                 ]
         ]
         ( Buffer.currentLine model.buffer
               |> String.left cur.column
               |> TextMarker.markupChank model.option.showControlCharactor model.option.tabOrder
               |> TextMarker.toHtml
         )


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
               [ text "箱|□↵├"]
        ]

compositionPreview : Maybe String -> Html msg
compositionPreview compositionData =
    case compositionData of
        Just s ->
            span [ class "elm-text-editor-composing"
                 , style [ ("text-decoration", "underline")
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
    span [ class "elm-text-editor-cursor"
         , style <|
             [ ("height", 1 |> emToPxString model )
             , ("width", "3px")
             , ("z-index", "5")
             ]
               ++ ( if model.focus then [] else [ ("background-color", "gray") ] )
               ++ ( if model.focus && (blink_off model.blink) then [ ("opacity", "0.0") ] else [])
         , id <| cursorID model
         ]
    []


stylesheet : TextEditor.Style.Style -> String -> Html msg
stylesheet sty frameID =
    let
        tagstring = \ tag val -> if val == "" then "" else [ tag, ":", val, "; " ] |> String.concat

        codesty2str = \s ->
                      [ tagstring "color" s.color
                      , tagstring "background-color" s.backgroundColor
                      , tagstring "font-family" s.fontFamily
                      , tagstring "font-size" s.fontSize
                      , tagstring "opacity" s.opacity
                      ] |> String.concat

        lnumsty2str = \s ->
                      [ tagstring "color" s.color
                      , tagstring "background-color" s.backgroundColor
                      , tagstring "opacity" s.opacity
                      , tagstring "border-right" s.borderRight
                      , tagstring "margin-right" s.marginRight
                      ] |> String.concat

        ffacesty2str = \s ->
                       [ tagstring "color" s.color
                       , tagstring "background-color" s.backgroundColor
                       , tagstring "opacity" s.opacity
                       ] |> String.concat

        cursty2str = \s ->
                     [ tagstring "background-color" s.color
                     , tagstring "opacity" s.opacity
                     ] |> String.concat

        csscls = \clsname s ->
                 [ "#", frameID, " ", ".", clsname, " { ", s, " }\n"] |> String.concat
        cssid = \ s ->
                 [ "#", frameID, " { ", s, " }\n"] |> String.concat

    in
        node "style" [ type_ "text/css" ]
            [ ( [ sty.common     |> Maybe.andThen (\s -> codesty2str  s |> cssid                              |> Just) |> Maybe.withDefault ""
                , sty.numberLine |> Maybe.andThen (\s -> lnumsty2str  s |> csscls "elm-text-editor-linenum"   |> Just) |> Maybe.withDefault ""
                , sty.cursor     |> Maybe.andThen (\s -> cursty2str   s |> csscls "elm-text-editor-cursor"    |> Just) |> Maybe.withDefault ""
                , sty.selection  |> Maybe.andThen (\s -> ffacesty2str s |> csscls "elm-text-editor-selection" |> Just) |> Maybe.withDefault ""
                , sty.composing  |> Maybe.andThen (\s -> ffacesty2str s |> csscls "elm-text-editor-composing" |> Just) |> Maybe.withDefault ""
                ]
                  ++ ( List.map (\ s ->
                                     let
                                         cls = Tuple.first s
                                         val = Tuple.second s
                                     in
                                         csscls cls (ffacesty2str val)
                                ) sty.fontFaces
                     )
              ) |> String.concat |> text
            ]

------------------------------------------------------------
-- Subscriptions
------------------------------------------------------------

{-| Subscriptions
-}
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

keyboarEvent_toString : KeyboardEvent -> String
keyboarEvent_toString e =
    String.concat
        [ if e.ctrlKey then "C-" else ""
        , if e.altKey then "A-" else ""
        , if e.metaKey then "M-" else ""
        , if e.shiftKey then "S-"else ""
        , toString e.keyCode
        ]
                
onKeyDown : List KeyBind.KeyBind -> (KeyboardEvent -> msg) -> Attribute msg
onKeyDown keymap tagger =
    onWithOptions "keydown" { stopPropagation=True, preventDefault=True } <|
        -- note: considerKeyboardEvent は、Nothing の時 
        --       JsonDecodeを失敗させることで、
        --       stopPropagetion, preventDefault を有効にしたり無効にしたりする Durty Hack
        --       (なので、keymapにあるかどうか照合をここでやっている)
        considerKeyboardEvent (\e ->
                                   case KeyBind.find (e.ctrlKey, e.altKey, e.shiftKey, e.keyCode) keymap of
                                       Just _  -> Just (tagger e)
                                       Nothing -> Nothing
                              )

onKeyDownForDeepAnalayze : List KeyBind.KeyBind -> (KeyboardEvent -> msg) -> Attribute msg
onKeyDownForDeepAnalayze keymap tagger =
    -- すべてのkeydownイベントをフックするかわりに preventDefault しない版。挙動が変わる
    onWithOptions "keydown" { stopPropagation=False, preventDefault=False } <|
        -- eventlog 用に、onKeyDown で拾わなかったキーイベントのみ発火させる
        considerKeyboardEvent (\e ->
                                   case KeyBind.find (e.ctrlKey, e.altKey, e.shiftKey, e.keyCode) keymap of
                                       Just _  -> Just (tagger e)
                                       Nothing -> Just (tagger e)
                              )


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
    onWithOptions "mousedown" { stopPropagation=False, preventDefault=True } (Json.map tagger mouseEvent)


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

-- note: 初回描画時に畳み込まれてしまう問題を軽減するサク
--emToPxString model = emToPx model >> (\n-> if n == 0 then "1.25em" else toPxString n)



------------------------------------------------------------
-- Mouse Event
------------------------------------------------------------

type alias MouseEvent =
  { clientX : Int
  , clientY : Int
  , pageX : Int
  , pageY : Int
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
  Json.map5 MouseEvent
    (Json.field "clientX" Json.int)
    (Json.field "clientY" Json.int)
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

getBoundingPageRect: String -> Rect
getBoundingPageRect id = Native.Mice.getBoundingPageRect id



