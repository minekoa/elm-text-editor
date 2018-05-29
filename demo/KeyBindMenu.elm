module KeyBindMenu exposing
    ( Model
    , Msg
    , init
    , update
    , view
    )

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Char
import Json.Decode as Json
import Dom
import Task

import TextEditor.KeyBind as KeyBind
import TextEditor.Core as Core
import TextEditor.Core.Commands as CoreCommands
import TextEditor.Commands as EditorCmds

type alias Model =
    { selectedSubMenu : SubMenu
    , mainsPage : KeybindMainsPage -- サブメニュー間移動しても残すため
    , currentIdx : Int
    , current : Maybe EditBuffer
    }

type alias EditBuffer =
    { keybind : KeyBind.KeyBind
    , target : EditTarget
    , insertS : Maybe String
    }

type EditTarget
    = TargetKeys
    | TargetCommand
    | TargetInsertValue
    | TargetNone

initEditBuffer : KeyBind.KeyBind -> EditBuffer
initEditBuffer kbind =
    let
        s = if (kbind.f.id |> String.left (String.length "insert")) == "insert"
            then (kbind.f.id |> String.dropLeft (String.length "insert" |> flip (+) 1) |> Just)
            else Nothing
    in
        { keybind =  kbind
        , target  = TargetNone
        , insertS = s
        }

type SubMenu
    = KeybindMain
    | InitKeybind

type KeybindMainsPage
    = ListPage
    | EditPage
    | AcceptPage

type Msg
    = SelectSubMenu SubMenu
    | SelectKeyBind Int
    | EditStart Int
    | EditCancel
    | ConfirmAccept
    | EditAccept
    | SetFocusToKeyEditor
    | KeyEditorFocus Bool
    | KeyDown KeyboardEvent
    | InputText String
    | ClickCmdArea
    | SelectCommand EditorCmds.Command
    | SetFocusToCmdInsertValue

init : Model
init =
    { selectedSubMenu = KeybindMain
    , mainsPage = ListPage
    , currentIdx = 0
    , current = Nothing
    }

update : Msg -> List KeyBind.KeyBind -> Model -> (List KeyBind.KeyBind, Model, Cmd Msg)
update msg keybinds model =
    case msg of
        SelectSubMenu submenu ->
            ( keybinds
            , { model
                  | selectedSubMenu = submenu
              }
            , Cmd.none
            )
        SelectKeyBind n ->
            ( keybinds
            , { model | currentIdx = n }
            , Cmd.none
            )
        EditStart n ->
            ( keybinds
            , { model
                  | selectedSubMenu = KeybindMain
                  , mainsPage = EditPage
                  , currentIdx = n
                  , current    = keybinds |> List.drop n |> List.head |> Maybe.andThen (initEditBuffer >> Just)
              }
            , Cmd.none
            )

        KeyDown e ->
            case model.current of
                Just editbuffer ->
                    case editbuffer.target of
                        TargetKeys ->
                            let
                                kbind = editbuffer.keybind
                                new_kbind = { kbind
                                                | ctrl = e.ctrlKey
                                                , alt = e.altKey
                                                , shift = e.shiftKey
                                                , code = e.keyCode
                                            }
                            in
                                ( keybinds
                                , { model
                                      | current = Just { editbuffer | keybind = new_kbind }
                                  }
                                , Cmd.none
                                )
                        _ ->
                            ( keybinds, model, Cmd.none )
                Nothing ->
                    ( keybinds, model, Cmd.none )
                
        InputText s ->
            case model.current of
                Just editbuffer ->
                    case editbuffer.target of
                        TargetInsertValue ->
                            let
                                kbind = editbuffer.keybind
                                new_kbind = { kbind
                                                | f = EditorCmds.insert s
                                            }
                            in
                                ( keybinds
                                , { model
                                      | current = Just { editbuffer
                                                           | keybind = new_kbind
                                                           , insertS = Just s
                                                       }
                                  }
                                , Cmd.none
                                )
                        _ ->
                            ( keybinds, model, Cmd.none )
                Nothing ->
                    ( keybinds, model, Cmd.none )

        EditCancel ->
            ( keybinds
            , { model
                  | selectedSubMenu = KeybindMain
                  , mainsPage = ListPage
                  , current = Nothing
              }
            , Cmd.none
            )

        ConfirmAccept ->
            ( keybinds
            , { model
                  | selectedSubMenu = KeybindMain
                  , mainsPage = AcceptPage
              }
            , Cmd.none
            )

        EditAccept ->
            ( case model.current of
                  Just editbuf ->
                      (List.take model.currentIdx keybinds) ++ (editbuf.keybind :: (List.drop (model.currentIdx + 1) keybinds))
                  Nothing ->
                      keybinds
            , { model
                  | selectedSubMenu = KeybindMain
                  , mainsPage = ListPage
                  , current = Nothing
              }
            , Cmd.none
            )

        SetFocusToKeyEditor ->
            ( keybinds
            , { model | current = model.current
                                      |> Maybe.andThen (\ editbuf -> { editbuf | target = TargetKeys } |> Just )
              }
            , doFocus
            )

        KeyEditorFocus True ->
            ( keybinds
            , model
            , Cmd.none
            )

        KeyEditorFocus False ->
            ( keybinds
            , { model | current = model.current
                                      |> Maybe.andThen (\ editbuf ->
                                                            { editbuf | target = case editbuf.target of
                                                                                     TargetKeys        -> TargetNone
                                                                                     TargetInsertValue -> TargetNone
                                                                                     otherwise         -> otherwise
                                                            } |> Just )
              }
            , Cmd.none
            )

        ClickCmdArea ->
            ( keybinds
            , { model | current = model.current
                                      |> Maybe.andThen (\ editbuf -> { editbuf | target = TargetCommand } |> Just )
              }
            , Cmd.none
            )

        SelectCommand edtcmd ->
            ( keybinds
            , { model | current = model.current
                                      |> Maybe.andThen
                                          (\ editbuf ->
                                               let
                                                   kbind   = editbuf.keybind
                                                   newbind = { kbind | f = edtcmd }
                                                   sval    = if (edtcmd.id |> String.left (String.length "insert")) == "insert"
                                                             then edtcmd.id |> String.dropLeft (String.length "insert" |> flip (+) 1) |> Just
                                                             else Nothing
                                               in
                                                   { editbuf
                                                       | keybind = newbind
                                                       , insertS = sval
                                                   }
                                                       |> Just
                                          )
              }
            , Cmd.none
            )

        SetFocusToCmdInsertValue ->
            ( keybinds
            , { model | current = model.current
                                      |> Maybe.andThen (\ editbuf -> { editbuf | target = TargetInsertValue } |> Just )
              }
            , doFocus
            )


------------------------------------------------------------
-- view
------------------------------------------------------------

view : List KeyBind.KeyBind -> Model -> Html Msg
view keybinds model =
    div [ class "keybind-menu", class "menu-root"
        , style [("min-height", "17em")]
        ]
        [ menuItemsView model
        , menuPalette keybinds model
        ]

menuItemsView : Model -> Html Msg
menuItemsView model =                
    div [ class "menu-itemlist" ]
    [ div [ onClick <| SelectSubMenu KeybindMain
          , class <| case model.selectedSubMenu of
                         KeybindMain  -> "menu-item-active"
                         _            -> "menu-item"
          ]
          [ span [] [ ( case model.mainsPage of
                            ListPage   -> "Keybinds"
                            EditPage   -> "Keybinds (Editing)"
                            AcceptPage -> "Keybinds (Accept?)"
                      ) |> text
                    ]
          ]
    , div [ onClick <| SelectSubMenu InitKeybind
          , class <| if model.selectedSubMenu == InitKeybind then "menu-item-active" else "menu-item"
          ]
          [ span [] [text "Initialize"]
          ]
    ]

menuPalette : List KeyBind.KeyBind -> Model ->  Html Msg
menuPalette keybinds model =
    case model.selectedSubMenu of
        KeybindMain ->
            case model.mainsPage of
                ListPage ->
                    div [class "menu-palette"] [ listPageView keybinds model ]
                EditPage -> 
                    case model.current of
                        Just editbuf ->
                            div [class "menu-palette"] [ editPageView editbuf model ]
                        Nothing ->
                            div [] []
                AcceptPage ->
                    div [class "menu-palette"] [ acceptPageView keybinds model ]

        InitKeybind -> 
            div [class "menu-palette"] [ initView keybinds ]

listPageView : List KeyBind.KeyBind -> Model -> Html Msg
listPageView keybinds model =
    div [ class "keybind-hbox" ]
        [ div [ class "keybind-item-list"] <|
              (List.indexedMap (keybindView model.currentIdx) keybinds) ++ [div [] [text "Add"]]
        , div [ class "keybind-next-button"
              , onClick <| EditStart model.currentIdx
              ]
            [ div [style [("text-align","center")]]
                  [ text ">"
                  , br [][]
                  , span [ style [ ("font-size", "0.8em")
                                 , ("color", "lightgray")
                                 ]
                         ]
                         [text "edit"]
                  ]
            ]
        ]


keybindView : Int -> Int -> KeyBind.KeyBind -> Html Msg
keybindView selected_idx idx keybind =
    div [ class <| if selected_idx == idx then "keybind-item-active" else "keybind-item"
        , style [("display","flex")]
        , onClick (SelectKeyBind idx)
        ]
        [ div [ style [("width","10rem")] ]
              [ [ if keybind.ctrl  then "Ctrl-" else ""
                , if keybind.alt   then "Alt-" else ""
                , if keybind.shift then "Shift-" else ""
                , keybind.code |> keyCodeToKeyName
                , " ("
                , keybind.code |> toString
                , ")"
                ] |> String.concat |> text
              ]
        , div [] [ keybind.f.id |> stringEscape |> text]
        ]



editPageView : EditBuffer -> Model ->  Html Msg
editPageView edtbuf model =
    div [ class "keybind-hbox" ]
        [ div [ class "keybind-prev-button"
              , onClick <| EditCancel
              ]
              [ div [style [("text-align","center")]]
                    [ text "<"
                    , br [][]
                    , span [ style [ ("font-size", "0.8em")
                                   , ("color", "lightgray")
                                   ]
                           ]
                          [text "cancel"]
                    ]
              ]

        , div [ style [ ("display", "flex")
                      , ("flex-direction", "column")
                      , ("flex-grow", "1")
                      , ("align-self" , "stretch")
                      ]
              ]
              [ currentKeybindView edtbuf model
              , textarea [ id "keybindmenu-keyevent-receiver"
                         , style [("opacity", "0"), ("height", "1px")]
                         , onKeyDown KeyDown
                         , onFocusIn KeyEditorFocus
                         , onFocusOut KeyEditorFocus
                         , onInput InputText
                         ] []
              , case edtbuf.target of
                    TargetKeys ->
                        keypressMessage model
                    TargetCommand ->
                        commandListView model
                    TargetInsertValue ->
                        insertValueMessage model
                    _ ->
                        div [] []
              ]

        ,  div [ class "keybind-next-button"
              , onClick <| ConfirmAccept
              ]
              [ div [style [("text-align","center")]]
                    [ text ">"
                    , br [][]
                    , span [ style [ ("font-size", "0.8em")
                                   , ("color", "lightgray")
                                   ]
                           ]
                          [text "accept"]
                    ]
              ]
        ]


currentKeybindView : EditBuffer -> Model -> Html Msg
currentKeybindView edtbuf model =
    div [ style [ ("display", "flex")
                , ("flex-direction", "row")
                , ("align-items", "center")
                ]
        ]
        (  [ currentKeybindView_keys edtbuf
           , div [style [("font-size","2em")]] [ text "⇒" ]
           , currentKeybindView_cmd edtbuf
           ]
        )


currentKeybindView_keys : EditBuffer -> Html Msg
currentKeybindView_keys edtbuf =
    div [ class <| if edtbuf.target == TargetKeys then "keybindmenu-keyeditor-focus" else "keybindmenu-keyeditor-disfocus"
        , style [ ("display", "flex")
                , ("flex-direction", "row")
                , ("align-items", "center")
                ]
        , onClick SetFocusToKeyEditor
        ]
        [ div [class <| if edtbuf.keybind.ctrl  then "keybind-edit-mod-enable" else "keybind-edit-mod-disable"] [text "Ctrl"]
        , div [style [("font-size","2em")]] [ text "+" ]
        , div [class <| if edtbuf.keybind.alt   then "keybind-edit-mod-enable" else "keybind-edit-mod-disable"] [text "Alt"]
        , div [style [("font-size","2em")]] [ text "+" ]
        , div [class <| if edtbuf.keybind.shift then "keybind-edit-mod-enable" else "keybind-edit-mod-disable"] [text "Shift"]
        , div [style [("font-size","2em")]] [ text "+" ]
        , div [class "keybind-edit-keycode"] [edtbuf.keybind.code |> keyCodeToKeyName |> text ]
        ]

currentKeybindView_cmd : EditBuffer -> Html Msg
currentKeybindView_cmd edtbuf =
    let
        fid = edtbuf.keybind.f.id |> String.split " " |> List.take 1 |> String.concat
    in
        div [ style [ ("display", "flex")
                    , ("flex-direction", "row")
                    ]
            ] 
            [ div [ class <| if edtbuf.target == TargetCommand then "keybindmenu-cmdselector-focus" else "keybindmenu-cmdselector-disfocus"
                  , style [ ("display", "flex")
                          , ("flex-direction", "row")
                          , ("align-items", "center")
                          ]
                  , onClick ClickCmdArea
                  ]
                  [ div [class "keybind-edit-command" ] [ fid |> text ] ]

            , case edtbuf.insertS of
                  Just insert_val ->
                      div [ class <| if edtbuf.target == TargetInsertValue then "keybindmenu-insertcmd-input-focus" else "keybindmenu-insertcmd-input-disfocus"
                          , onClick SetFocusToCmdInsertValue
                          ]
                          [ div [class "keybind-edit-insert-value"] [ insert_val |> stringEscape |> text ] ]

                  Nothing ->
                      text ""
            ]


commandListView : Model -> Html Msg
commandListView model =
    let
        cmdlist = [ EditorCmds.moveForward
                  , EditorCmds.moveBackward
                  , EditorCmds.movePrevios
                  , EditorCmds.moveNext
                  , EditorCmds.moveBOL
                  , EditorCmds.moveEOL
--                  , EditorCmds.moveAt
                  , EditorCmds.selectForward
                  , EditorCmds.selectBackward
                  , EditorCmds.selectPrevios
                  , EditorCmds.selectNext
--                  , EditorCmds.selectAt
                  , EditorCmds.markSet
                  , EditorCmds.markClear
                  , EditorCmds.markFlip
                  , EditorCmds.gotoMark
                  , EditorCmds.insert ""
                  , EditorCmds.backspace
                  , EditorCmds.delete
                  , EditorCmds.undo
                  , EditorCmds.copy
                  , EditorCmds.cut
                  , EditorCmds.paste
                  ]
    in
        div [ class "keybindmenu-editsupport" ]
            [ text "Select edit command"
            , div [ class "keybindmenu-cmdlist" ]
                (List.map (\cmd -> div [ class <|
                                             if (model.current |> Maybe.andThen (\c -> c.keybind.f.id == cmd.id |> Just) |> Maybe.withDefault False)
                                             then "keybindmenu-cmditem-selected"
                                             else "keybindmenu-cmditem"
                                       , onClick <| SelectCommand cmd
                                       ]
                                       [ cmd.id |> text ]
                          ) cmdlist
                )
            ]


keypressMessage : Model -> Html Msg
keypressMessage model =
    div [ class "keybindmenu-editsupport" ]
        [ text "Please press the key(s) you want to set" ]

insertValueMessage : Model -> Html Msg
insertValueMessage model =
    div [ class "keybindmenu-editsupport" ]
        [ text "Please input the string you want to set" ]


-- Accept(Confirm)Page

acceptPageView : List KeyBind.KeyBind -> Model ->  Html Msg
acceptPageView keybinds model =
    let
        kbind2str = (\kb ->
                         [ if kb.ctrl  then "Ctrl +" else ""
                         , if kb.alt   then "Alt +"  else ""
                         , if kb.shift then "Shift +" else ""
                         , kb.code |> keyCodeToKeyName
                         , " ⇒ "
                         , kb.f.id
                         ] |> String.concat
                    )
    in
        div [ class "keybind-hbox" ]
            [ div [ class "keybind-prev-button"
                  , onClick <| EditStart model.currentIdx
                  ]
                  [ div [style [("text-align","center")]]
                        [ text "<"
                        , br [][]
                        , span [ style [ ("font-size", "0.8em")
                                       , ("color", "lightgray")
                                       ]
                               ]
                              [text "return to the edit"]
                        ]
                  ]
            , div [ style [ ("display", "flex")
                          , ("flex-direction", "column")
                          , ("flex-grow", "1")
                          , ("align-self" , "stretch")
                          , ("align-items", "center")
                          ]
                  ]
                  [ div [ style [ ("font-size", "1.2em")
                                , ("color", "silver")
                                , ("padding-top", "1em")
                                ]
                        ]
                        [ text "Old: "
                        , span [ style [("color", "lightgray")] ]
                               [ case keybinds |> List.drop model.currentIdx |> List.head of
                                     Just kb -> kbind2str kb |> text
                                     Nothing -> "" |> text
                               ]
                        ]
                  , div [ style [ ("font-size", "2em") ] ]
                        [ text "↓" ]
                  , div [ style [ ("font-size", "1.2em")
                                , ("color", "silver")
                                ]
                        ]
                        [ text "New: "
                        , span [ style [("color", "royalblue")] ]
                               [ case model.current of
                                     Just edtbuf -> kbind2str edtbuf.keybind |> text
                                     Nothing -> "" |> text
                               ]
                        ]
                  , div [ style [ ("font-size", "1.2em")
                                , ("padding", "1.5em 0 1em 0")
                                ]
                        ]
                        [ text "Are you sure you want to update this keybind?" ]
                  , div [ class "file_input_label"
                        , onClick EditAccept
                        ]
                        [text "OK"]
                  ]
            ]




initView : List KeyBind.KeyBind -> Html Msg
initView editorModel =
    div [] []



------------------------------------------------------------
-- keyboard event (TextEditor コピペなのであとでどうにかしよう)
------------------------------------------------------------
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

------------------------------------------------------------
-- focus
------------------------------------------------------------

doFocus: Cmd Msg
doFocus  =
    Task.attempt (\_ -> KeyEditorFocus True) (Dom.focus "keybindmenu-keyevent-receiver")

onFocusIn : (Bool -> msg) -> Attribute msg
onFocusIn tagger =
    -- ほしいプロパティはないのでとりあえずダミーで bubbles を
    on "focusin" (Json.map (\dmy -> tagger True) (Json.field "bubbles" Json.bool))

onFocusOut : (Bool -> msg) -> Attribute msg
onFocusOut tagger =
    -- ほしいプロパティはないのでとりあえずダミーで bubbles を
    on "focusout" (Json.map (\dmy -> tagger False) (Json.field "bubbles" Json.bool))

------------------------------------------------------------
-- string tools
------------------------------------------------------------

keyCodeToKeyName : Int -> String
keyCodeToKeyName code =
    case code of
        49  -> "1"
        50  -> "2"
        51  -> "3"
        52  -> "4"
        53  -> "5"
        54  -> "6"
        55  -> "7"
        56  -> "8"
        57  -> "9"
        48  -> "0"
        65  -> "A"
        66  -> "B"
        67  -> "C"
        68  -> "D"
        69  -> "E"
        70  -> "F"
        71  -> "G"
        72  -> "H"
        73  -> "I"
        74  -> "J"
        75  -> "K"
        76  -> "L"
        77  -> "M"
        78  -> "N"
        79  -> "O"
        80  -> "P"
        81  -> "Q"
        82  -> "R"
        83  -> "S"
        84  -> "T"
        85  -> "U"
        86  -> "V"
        87  -> "W"
        88  -> "X"
        89  -> "Y"
        90  -> "Z"
        173 -> "-"
        160 -> "^"
        220 -> "\\"
        64  -> "@"
        219 -> "["
        221 -> "]"
        59  -> ";"
        58  -> ":"
        188 -> ","
        190 -> "."
        191 -> "/"
        97  -> "numkey 1"
        98  -> "numkey 2"
        99  -> "numkey 3"
        100 -> "numkey 4"
        101 -> "numkey 5"
        102 -> "numkey 6"
        103 -> "numkey 7"
        104 -> "numkey 8"
        105 -> "numkey 9"
        96  -> "numkey 0"
        111 -> "numkey /"
        106 -> "numkey *"
        109 -> "numkey -"
        107 -> "numkey +"
        110 -> "numkey ."
        112 -> "F1"
        113 -> "F2"
        114 -> "F3"
        115 -> "F4"
        116 -> "F5"
        117 -> "F6"
        118 -> "F7"
        119 -> "F8"
        120 -> "F9"
        121 -> "F10"
        122 -> "F11"
        123 -> "F12"
        38  -> "↑"
        40  -> "↓"
        37  -> "←"
        39  -> "→"
        13  -> "↵"
        16  -> "Shift"
        17  -> "Ctrl"
        18  -> "Alt"
        32  -> "Space"
        8   -> "BackSpace"
        27  -> "Esc"
        9   -> "Tab"
        20  -> "CapsLock"
        144 -> "NumLock"
        45  -> "Insert"
        46  -> "Delete"
        36  -> "Home"
        35  -> "End"
        33  -> "PgUp"
        34  -> "PgDn"
        145 -> "ScrLk"
        91  -> "Super"
        240 -> "Ei-Su"     -- 英数
        243 -> "Han/Zen"   -- 半角/全角
        244 -> "Kanji"     -- 漢字
        29  -> "Muhenkan"  -- 無変換
        28  -> "Henkan"    -- 変換
        242 -> "Kana"      -- "カタカナ/ひらがな/ローマ字
        otherwise   -> otherwise |> toString


stringEscape: String -> String
stringEscape str =
    str |> String.toList
        |> List.map (\ c ->
                         case c of
                             '\\' -> "\\\\"
                             '\0' -> "\\0"
                             '\a' -> "\\a"
                             '\b' -> "\\b"
                             '\f' -> "\\f"
                             '\n' -> "\\n"
                             '\r' -> "\\r"
                             '\t' -> "\\t"
                             '\v' -> "\\v"
                             otherwise -> String.fromChar otherwise
                    )
        |> String.concat
            

    
