module KeyBindMenu exposing
    ( Model
    , Msg
    , init
    , update
    , subscriptions
    , view
    )

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Json.Encode
import Json.Decode
import Dom
import Task

import TextEditor.KeyBind as KeyBind
import TextEditor.Core as Core
import TextEditor.Core.Commands as CoreCommands
import TextEditor.Commands as EditorCmds

import Ports.WebStrage as WebStrage
import StringTools exposing (..)

type alias Model =
    { selectedSubMenu : SubMenu
    , mainsPage : KeybindMainsPage -- サブメニュー間移動しても残すため
    , currentIdx : Int
    , current : Maybe EditBuffer
    , resetOptions : KeyBindsResetOptions
    }

type alias EditBuffer =
    { keybind : KeyBind.KeyBind
    , target : EditTarget
    , insertS : Maybe String
    , editmode : EditMode
    }

type EditTarget
    = TargetKeys
    | TargetCommand
    | TargetInsertValue
    | TargetNone

type EditMode
    = EditModeNew
    | EditModeUpdate
    | EditModeDelete

initEditNew : EditBuffer
initEditNew =
    let
        newkeybind = { ctrl = False
                     , alt = False
                     , shift = False
                     , code = 0
                     , f = EditorCmds.moveForward
                     }
    in
        { keybind =  newkeybind
        , target  = TargetNone
        , insertS = Nothing
        , editmode = EditModeNew
        }


initEditUpdate : KeyBind.KeyBind -> EditBuffer
initEditUpdate kbind =
    let
        s = if (kbind.f.id |> String.left (String.length "insert")) == "insert"
            then (kbind.f.id |> String.dropLeft (String.length "insert" |> flip (+) 1) |> Just)
            else Nothing
    in
        { keybind =  kbind
        , target  = TargetNone
        , insertS = s
        , editmode = EditModeUpdate
        }

initEditDelete : KeyBind.KeyBind -> EditBuffer
initEditDelete kbind =
    let
        s = if (kbind.f.id |> String.left (String.length "insert")) == "insert"
            then (kbind.f.id |> String.dropLeft (String.length "insert" |> flip (+) 1) |> Just)
            else Nothing
    in
        { keybind =  kbind
        , target  = TargetNone
        , insertS = s
        , editmode = EditModeDelete
        }


type SubMenu
    = KeybindMain
    | ResetKeybind

type KeybindMainsPage
    = ListPage
    | EditPage
    | AcceptPage


type alias KeyBindsResetOptions =
    { basic : Bool
    , gates : Bool
    , emacs : Bool
    }


initKeybindResetOptions : KeyBindsResetOptions
initKeybindResetOptions =
    { basic = True, gates = False, emacs = False }

type Msg
    = LoadSetting (String, Maybe String)
    | SelectSubMenu SubMenu
    | SelectKeyBind Int
    | EditStart Int
    | BackToEdit
    | BackToList
    | ConfirmAccept
    | ConfirmDelete
    | EditComplete
    | SetFocusToKeyEditor
    | SetFocusToCmdSelector
    | SetFocusToCmdInsertValue
    | KeyEditorFocus Bool
    | KeyDown KeyboardEvent
    | TabKeyDown KeyboardEvent
    | InputText String
    | SelectCommand EditorCmds.Command
    | AddKeyBind
    | SetResetOption String Bool
    | ResetKeyBinds

init: (Model , Cmd Msg)
init =
    ( { selectedSubMenu = KeybindMain
      , mainsPage = ListPage
      , currentIdx = 0
      , current = Nothing
      , resetOptions = initKeybindResetOptions
      }
    , WebStrage.localStrage_getItem "keybinds"
    )


------------------------------------------------------------
-- update
------------------------------------------------------------

update : Msg -> List KeyBind.KeyBind -> Model -> (List KeyBind.KeyBind, Model, Cmd Msg)
update msg keybinds model =
    case msg of
        LoadSetting ("keybinds", maybe_value) ->
            ( maybe_value
                  |> Result.fromMaybe "value is nothing"
                  |> Result.andThen (Json.Decode.decodeString decodeKeyBinds)
                  |> Result.withDefault keybinds
            , model
            , Cmd.none
            )
        LoadSetting _ ->
            ( keybinds
            , model
            , Cmd.none
            )

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
                  , current    = keybinds |> List.drop n |> List.head |> Maybe.andThen (initEditUpdate >> Just)
              }
            , Cmd.none
           )

        BackToEdit ->
            ( keybinds
            , { model
                  | selectedSubMenu = KeybindMain
                  , mainsPage = EditPage
                  , current   = model.current
                                  |> Maybe.andThen (\ edtbuf ->
                                                        { edtbuf | editmode = if edtbuf.editmode == EditModeDelete
                                                                              then EditModeUpdate
                                                                              else edtbuf.editmode
                                                        }
                                                        |> Just
                                                   )
              }
            , Cmd.none
            )

        BackToList ->
            ( keybinds
            , { model
                  | selectedSubMenu = KeybindMain
                  , mainsPage = ListPage
                  , current = Nothing
              }
            , Cmd.none
            )

        ConfirmDelete ->
            ( keybinds
            , { model
                  | selectedSubMenu = KeybindMain
                  , mainsPage = AcceptPage
                  , current   = model.current
                                  |> Maybe.andThen (\ edtbuf ->
                                                        { edtbuf | editmode = EditModeDelete
                                                        }
                                                        |> Just
                                                   )
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

        EditComplete ->
            let
                nkeybind = case model.current of
                               Just editbuf ->
                                   case editbuf.editmode of
                                       EditModeNew ->
                                           (List.take model.currentIdx keybinds) ++ (editbuf.keybind :: (List.drop (model.currentIdx) keybinds))
                                       EditModeUpdate ->
                                           (List.take model.currentIdx keybinds) ++ (editbuf.keybind :: (List.drop (model.currentIdx + 1) keybinds))
                                       EditModeDelete ->
                                           (List.take model.currentIdx keybinds) ++ (List.drop (model.currentIdx + 1) keybinds)
                               Nothing ->
                                   keybinds
            in
                ( nkeybind
                , { model
                      | selectedSubMenu = KeybindMain
                      , mainsPage = ListPage
                      , current = Nothing
                  }
                , WebStrage.localStrage_setItem ("keybinds", encodeKeyBinds nkeybind)
            )



        SetFocusToKeyEditor ->
            ( keybinds
            , { model | current = model.current
                                      |> Maybe.andThen (\ editbuf -> { editbuf | target = TargetKeys } |> Just )
              }
            , doFocus
            )

        SetFocusToCmdSelector ->
            ( keybinds
            , { model | current = model.current
                                      |> Maybe.andThen (\ editbuf -> { editbuf | target = TargetCommand } |> Just )
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

        TabKeyDown e ->
            let
                now_insertS = model.current |> Maybe.andThen (\ edtbuf -> edtbuf.insertS) |> Maybe.withDefault ""
            in
                update (InputText <| now_insertS ++ "\t" ) keybinds model
                
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

        AddKeyBind ->
            ( keybinds
            , { model
                  | current = initEditNew |> Just
                  , selectedSubMenu = KeybindMain
                  , mainsPage = EditPage
              }
            , Cmd.none
            )

        SetResetOption key value->
            let
                opts = model.resetOptions
            in
                (keybinds
                , { model | resetOptions = case key of
                                               "basic" -> { opts | basic = value }
                                               "gates" -> { opts | gates = value }
                                               "emacs" -> { opts | emacs = value }
                                               _ -> opts
                  }
                , Cmd.none
                )

        ResetKeyBinds ->
            let
                nkeybinds = [ if model.resetOptions.basic then KeyBind.basic else []
                            , if model.resetOptions.gates then KeyBind.gates else []
                            , if model.resetOptions.emacs then KeyBind.emacsLike else []
                            ] |> List.concat
            in
                ( nkeybinds
                , { model | resetOptions = initKeybindResetOptions }
                , WebStrage.localStrage_setItem ("keybinds", encodeKeyBinds nkeybinds)
                )


------------------------------------------------------------
-- Subscriptions
------------------------------------------------------------

subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch [ WebStrage.localStrage_getItemEnded LoadSetting
              ]

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
    , div [ onClick <| SelectSubMenu ResetKeybind
          , class <| if model.selectedSubMenu == ResetKeybind then "menu-item-active" else "menu-item"
          ]
          [ span [] [text "Reset"]
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

        ResetKeybind -> 
            div [class "menu-palette"] [ resetView model ]

listPageView : List KeyBind.KeyBind -> Model -> Html Msg
listPageView keybinds model =
    div [ class "keybind-hbox" ]
        [ div [ class "debugger-submenu-title" ]
              [ div [] [text "keybinds:"]
              ]

        , div [ class "keybind-item-list"] <|
              (List.indexedMap (keybindView model.currentIdx) keybinds)

        , div [ class "keybind-vbox" ]
              [ div [ class "keybind-next-button"
                    , style [ ("flex-grow", "4") ]
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
              , div [ class "keybind-next-button"
                    , style [ ("flex-grow", "1") ]
                    , onClick AddKeyBind
                    ]
                    [ div [style [("text-align","center")]]
                          [ text ">"
                          , br [][]
                          , span [ style [ ("font-size", "0.8em")
                                         , ("color", "lightgray")
                                         ]
                                 ]
                                [text "add"]
                          ]
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
    let
        isEditModeNew = (\ m -> case m.current of
                                    Just buf -> buf.editmode == EditModeNew
                                    Nothing -> False
                        )
    in
        div [ class "keybind-hbox" ]
            [ div [ class "keybind-prev-button"
                  , onClick <| BackToList
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
                  [ editPage_currentKeybindView edtbuf model
                  , textarea [ id "keybindmenu-keyevent-receiver"
                             , style [("opacity", "0"), ("height", "1px")]
                             , if edtbuf.target == TargetInsertValue
                               then onTabKeyDown TabKeyDown
                               else onKeyDown KeyDown
                             , onFocusIn KeyEditorFocus
                             , onFocusOut KeyEditorFocus
                             , onInput InputText
                             , value <| (edtbuf.insertS |> Maybe.withDefault "")
                             ] []
                  , case edtbuf.target of
                        TargetKeys ->
                            editPage_keypressMessage model
                        TargetCommand ->
                            editPage_commandListView model
                        TargetInsertValue ->
                            editPage_insertValueMessage model
                        _ ->
                            div [] []
                  ]

            , div [ class "keybind-vbox" ] <|
                  [ div [ class "keybind-next-button"
                        , style [ ("flex-grow", "4") ]
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
                  ] ++
                  ( if isEditModeNew model then
                        []
                    else
                        [ div [ class "keybind-next-button"
                              , style [ ("flex-grow", "1") ]
                              , onClick <| ConfirmDelete
                              ]
                              [ div [style [("text-align","center")]]
                                    [ text ">"
                                    , br [][]
                                    , span [ style [ ("font-size", "0.8em")
                                                   , ("color", "lightgray")
                                                   ]
                                           ]
                                          [text "delete"]
                                    ]
                              ]
                        ]
                  )
            ]

editPage_currentKeybindView : EditBuffer -> Model -> Html Msg
editPage_currentKeybindView edtbuf model =
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
                  , onClick SetFocusToCmdSelector
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


editPage_commandListView : Model -> Html Msg
editPage_commandListView model =
    let
        cmdlist = editorCommandList
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


editPage_keypressMessage : Model -> Html Msg
editPage_keypressMessage model =
    div [ class "keybindmenu-editsupport" ]
        [ text "Please press the key(s) you want to set" ]

editPage_insertValueMessage : Model -> Html Msg
editPage_insertValueMessage model =
    div [ class "keybindmenu-editsupport" ]
        [ text "Please input the string you want to set" ]

editPage_deleteKeyBindPanel : Model -> Html Msg
editPage_deleteKeyBindPanel model =
    div [ class "keybindmenu-editsupport" ]
        [ div [ style [ ("display", "flex")
                      , ("flex-direction", "row")
                      , ("justify-content", "flex-end")
                      ]
              ]
              [ div [ style [ ("border", "1px solid gray")
                            , ("margin", "1ex")
                            , ("text-align", "center")
                            , ("width", "5em")
                            ]
                    , onClick ConfirmDelete
                    ]
                    [text "Delete"]
              ]
        ]



-- Accept(Confirm)Page

acceptPageView : List KeyBind.KeyBind -> Model ->  Html Msg
acceptPageView keybinds model =
    div [ class "keybind-hbox" ]
        [ div [ class "keybind-prev-button"
              , onClick <| BackToEdit
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
              ( case model.current of
                    Just edtbuf ->
                        case edtbuf.editmode of
                            EditModeNew ->
                                (acceptPage_updateFromToView
                                     Nothing
                                     (model.current |> Maybe.andThen ((.keybind) >> Just))
                                ) ++
                                (acceptPage_confirmMessage "Are you sure you want to create this keybind?"
                                ) ++
                                (acceptPage_acceptButton "Create!")

                            EditModeUpdate ->
                                (acceptPage_updateFromToView
                                     (keybinds |> List.drop model.currentIdx |> List.head)
                                     (model.current |> Maybe.andThen ((.keybind) >> Just))
                                ) ++
                                (acceptPage_confirmMessage "Are you sure you want to update this keybind?"
                                ) ++
                                (acceptPage_acceptButton "Update!")

                            EditModeDelete ->
                                (acceptPage_updateFromToView
                                     (keybinds |> List.drop model.currentIdx |> List.head)
                                     Nothing
                                ) ++
                                (acceptPage_confirmMessage "Are you sure you want to delete this keybind?"
                                ) ++
                                (acceptPage_acceptButton "Delete!")
                    Nothing ->
                        []
              )
        ]


acceptPage_updateFromToView : Maybe KeyBind.KeyBind -> Maybe KeyBind.KeyBind -> List (Html Msg)
acceptPage_updateFromToView from to =
    let
        kbind2str = Maybe.andThen (\kb ->
                         [ if kb.ctrl  then "Ctrl +" else ""
                         , if kb.alt   then "Alt +"  else ""
                         , if kb.shift then "Shift +" else ""
                         , kb.code |> keyCodeToKeyName
                         , " ⇒ "
                         , kb.f.id |> stringEscape
                         ] |> String.concat |> Just
                    ) >> Maybe.withDefault "(Nothing)"
    in
        [ div [ style [ ("font-size", "1.2em")
                      , ("color", "silver")
                      , ("padding-top", "1em")
                      ]
              ]
              [ text "Old: "
              , span [ style [("color", "tomato")] ]
                     [ from |> kbind2str |> text ]
              ]

        , div [ style [ ("font-size", "2em") ] ]
              [ text "↓" ]

        , div [ style [ ("font-size", "1.2em")
                      , ("color", "silver")
                      ]
              ]
              [ text "New: "
              , span [ style [("color", "royalblue")] ]
                  [ to |> kbind2str |> text ]
              ]
        ]

acceptPage_confirmMessage : String -> List (Html Msg)
acceptPage_confirmMessage msg =
    [ div [ style [ ("font-size", "1.2em")
                  , ("padding", "1.5em 0 1em 0")
                  ]
          ]
          [ text msg ]
    ]

acceptPage_acceptButton : String -> List (Html Msg)
acceptPage_acceptButton label =
    [ div [ class "menu_button"
          , onClick EditComplete
          ]
          [text label]
    ]




resetView : Model-> Html Msg
resetView model =
    div [ class "keybind-vbox"]
        [ div [ style [ ("font-size", "1.5em")
                      , ("padding", "1em")
                      , ("justify-content", "center")
                      ]
              ]
              [ p [] [text "Are you sure you want to reset keybinds?" ] ]

        , div [ class "keybind-hbox"
              , style [ ("justify-content", "center")
                      , ("align-items", "center")
                      ]
              ]
              [ div [ class <| if model.resetOptions.basic then "menu_option_enabled" else "menu_option_disabled"
                    , onClick <| SetResetOption "basic" (not model.resetOptions.basic)
                    ] [ text "basic" ]
              , div [ style [("font-size", "2em")]] [ text "+"]
              , div [ class <| if model.resetOptions.gates then "menu_option_enabled" else "menu_option_disabled"
                    , onClick <| SetResetOption "gates" (not model.resetOptions.gates)
                    ] [ text "windows like" ]
              , div [ style [("font-size", "2em")]] [ text "+"]
              , div [ class <| if model.resetOptions.emacs then "menu_option_enabled" else "menu_option_disabled"
                    , onClick <| SetResetOption "emacs" (not model.resetOptions.emacs)
                    ] [ text "emacs like" ]
              ]

        , div [ class "keybind-hbox"
              , style [ ("justify-content", "center")
                      , ("align-items", "center")
                      ]
              ]
              [ div [ class <| if model.resetOptions.basic || model.resetOptions.gates || model.resetOptions.emacs
                               then "menu_button"
                               else "menu_button_disabled"
                    , onClick ResetKeyBinds
                    ]
                    [text "Reset!"]
              ]
        ]
            



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

decodeKeyboardEvent : Json.Decode.Decoder KeyboardEvent
decodeKeyboardEvent =
    Json.Decode.map6 KeyboardEvent
        (Json.Decode.field "altKey" Json.Decode.bool)
        (Json.Decode.field "ctrlKey" Json.Decode.bool)
        (Json.Decode.field "keyCode" Json.Decode.int)
        (Json.Decode.field "metaKey" Json.Decode.bool)
        (Json.Decode.field "repeat" Json.Decode.bool)
        (Json.Decode.field "shiftKey" Json.Decode.bool)    


considerKeyboardEvent : (KeyboardEvent -> Maybe msg) -> Json.Decode.Decoder msg
considerKeyboardEvent func =
    Json.Decode.andThen
        (\event ->
            case func event of
                Just msg ->
                    Json.Decode.succeed msg

                Nothing ->
                    Json.Decode.fail "Ignoring keyboard event"
        )
        decodeKeyboardEvent



onKeyDown : (KeyboardEvent -> msg) -> Attribute msg
onKeyDown tagger =
    on "keydown" (Json.Decode.map tagger decodeKeyboardEvent)

onTabKeyDown : (KeyboardEvent -> msg) -> Attribute msg
onTabKeyDown tagger = 
    onWithOptions "keydown" { stopPropagation = True, preventDefault = True } <|
        considerKeyboardEvent (\ kbd_ev ->
                                   if kbd_ev.keyCode == 9 then
                                       Just (tagger kbd_ev)
                                   else
                                       Nothing
                              )


------------------------------------------------------------
-- focus
------------------------------------------------------------

doFocus: Cmd Msg
doFocus  =
    Task.attempt (\_ -> KeyEditorFocus True) (Dom.focus "keybindmenu-keyevent-receiver")

onFocusIn : (Bool -> msg) -> Attribute msg
onFocusIn tagger =
    -- ほしいプロパティはないのでとりあえずダミーで bubbles を
    on "focusin" (Json.Decode.map (\dmy -> tagger True) (Json.Decode.field "bubbles" Json.Decode.bool))

onFocusOut : (Bool -> msg) -> Attribute msg
onFocusOut tagger =
    -- ほしいプロパティはないのでとりあえずダミーで bubbles を
    on "focusout" (Json.Decode.map (\dmy -> tagger False) (Json.Decode.field "bubbles" Json.Decode.bool))



------------------------------------------------------------
-- CommandTools
------------------------------------------------------------

editorCommandList : List EditorCmds.Command
editorCommandList =
    -- moveAt, selectAt は、引数を取り扱えないため、対象外とした
    [ EditorCmds.moveForward
    , EditorCmds.moveBackward
    , EditorCmds.movePrevios
    , EditorCmds.moveNext
    , EditorCmds.moveBOL
    , EditorCmds.moveEOL
    , EditorCmds.moveNextWord
    , EditorCmds.selectForward
    , EditorCmds.selectBackward
    , EditorCmds.selectPrevios
    , EditorCmds.selectNext
    , EditorCmds.markSet
    , EditorCmds.markClear
    , EditorCmds.markFlip
    , EditorCmds.gotoMark
    , EditorCmds.backspace
    , EditorCmds.delete
    , EditorCmds.insert ""
    , EditorCmds.indent
    , EditorCmds.copy
    , EditorCmds.cut
    , EditorCmds.paste
    , EditorCmds.killLine
    , EditorCmds.undo
    ]

fidToEditCmd : String -> Maybe EditorCmds.Command
fidToEditCmd str =
    let 
        cmdlist = editorCommandList
    in
        if (String.left 6 str) == "insert" then
            Just (EditorCmds.insert (String.dropLeft 7 str))
        else
            cmdlist 
                |> List.filter (\c -> c.id == str)
                |> List.head


decodeEditCmd : Json.Decode.Decoder EditorCmds.Command
decodeEditCmd =
    Json.Decode.string
        |> Json.Decode.andThen (fidToEditCmd >> (\v -> case v of
                                                           Just v  -> Json.Decode.succeed v
                                                           Nothing -> Json.Decode.fail "invalid f.id"
                                                )
                               )

decodeKeyBinds : Json.Decode.Decoder (List KeyBind.KeyBind)
decodeKeyBinds =
    Json.Decode.list decodeKeyBind

decodeKeyBind : Json.Decode.Decoder KeyBind.KeyBind
decodeKeyBind =
    Json.Decode.map5
        KeyBind.KeyBind
            (Json.Decode.field "ctrl"  Json.Decode.bool)
            (Json.Decode.field "alt"   Json.Decode.bool)
            (Json.Decode.field "shift" Json.Decode.bool)
            (Json.Decode.field "code"  Json.Decode.int)
            (Json.Decode.field "f"     decodeEditCmd )


encodeKeyBinds : List KeyBind.KeyBind-> String
encodeKeyBinds keybinds =
    keybinds
        |> List.map encodeKeyBind
        |> Json.Encode.list 
        |> Json.Encode.encode 0

encodeKeyBind : KeyBind.KeyBind -> Json.Encode.Value
encodeKeyBind keybind =
    Json.Encode.object 
        [ ("ctrl" , keybind.ctrl |> Json.Encode.bool)
        , ("alt"  , keybind.alt  |> Json.Encode.bool)
        , ("shift", keybind.shift |> Json.Encode.bool)
        , ("code" , keybind.code |> Json.Encode.int)
        , ("f"    , keybind.f.id |> Json.Encode.string)
        ]


