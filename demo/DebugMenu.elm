module DebugMenu exposing
    ( Model
    , Msg
    , init
    , update
    , view
    )

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Date

import TextEditor as Editor
import TextEditor.Buffer as Buffer
import TextEditor.Core as Core

import StringTools exposing (..)


type alias Model =
    { selectedSubMenu : SubMenu
    }

type SubMenu
    = EditHistory
    | Clipboard
    | EventLog
    | Inspector

type Msg
    = SelectSubMenu SubMenu
    | SetEventlogEnable Bool

init : Model
init =
    { selectedSubMenu = Inspector
    }


update : Msg -> Editor.Model -> Model -> (Editor.Model, Model, Cmd Msg)
update msg editorModel model =
    case msg of
        SelectSubMenu submenu ->
            ( editorModel
            , { model | selectedSubMenu = submenu }
            , Cmd.none
            )

        SetEventlogEnable True ->
            ( { editorModel | event_log = Just [] }
            , model
            , Cmd.none
            )

        SetEventlogEnable False ->
            ( { editorModel | event_log = Nothing }
            , model
            , Cmd.none
            )

view : Editor.Model -> Model -> Html Msg
view editorModel model =
    div [ class "debugger-menu", class "menu-root"
        , style [("min-height", "17em")]
        ]
        [ menuItemsView model
        , menuPalette editorModel model
        ]

menuItemsView : Model -> Html Msg
menuItemsView model =                
    div [ class "menu-itemlist" ]
    [ div [ onClick <| SelectSubMenu Inspector
          , class <| if model.selectedSubMenu == Inspector then "menu-item-active" else "menu-item"
          ]
          [ span [] [text "Inspector (overview)"]
          ]
    , div [ onClick <| SelectSubMenu EditHistory
          , class <| if model.selectedSubMenu == EditHistory then "menu-item-active" else "menu-item"
          ]
          [ span [] [text "History"]
          ]
    , div [ onClick <| SelectSubMenu Clipboard
          , class <| if model.selectedSubMenu == Clipboard then "menu-item-active" else "menu-item"
          ]
          [ span [] [text "Clipboard"]
          ]
    , div [ onClick <| SelectSubMenu EventLog
          , class <| if model.selectedSubMenu == EventLog then "menu-item-active" else "menu-item"
          ]
          [ span [] [text "Event log"]
          ]
    ]


menuPalette : Editor.Model -> Model ->  Html Msg
menuPalette editorModel model =
    case model.selectedSubMenu of
        EditHistory -> 
            div [class "menu-palette"] [ historyView editorModel ]
        Clipboard ->
            div [class "menu-palette"] [ clipboardView editorModel ]
        EventLog ->
            div [class "menu-palette"] [ eventlogView editorModel ]
        Inspector ->
            div [class "menu-palette"] [ inspectorView editorModel ]


historyView : Editor.Model -> Html Msg
historyView editorModel =
    div [ id "debug-pane-history"
        , class "debugger-hbox"
        ]
        [ div [ class "debugger-submenu-title" ] [ text "history:" ]
        , div
              [ style [ ("overflow","auto"), ("width", "100%") ] ]
              ( List.map
                    (\ c ->
                         let
                             pos2str = \ p -> "(" ++ (toString p.row) ++ ", " ++ (toString p.column) ++")" 
                             mark2str = \ mk -> case mk of
                                                    Just m -> "{pos=" ++ (pos2str m.pos ) ++ ", actived=" ++ (toString m.actived) ++ "}"
                                                    Nothing -> "Nothing"
                             editParm2str = \ bfr afr str mk ->
                                 "{begin=" ++ (pos2str bfr) ++ ", end=" ++ (pos2str afr) ++ ", str=\"" ++ str ++ "\", mark=" ++ (mark2str mk) ++ "}"
                             celstyle = style [("text-wrap", "none"), ("white-space","nowrap"), ("color", "gray")]
                         in
                             case c of
                                 Buffer.Cmd_Insert bpos epos str mk ->
                                     div [celstyle] [ "Insert " ++ editParm2str bpos epos str mk |> text ]
                                 Buffer.Cmd_Backspace bpos epos str mk->
                                     div [celstyle] [ "Backspace " ++ editParm2str bpos epos str mk  |> text ]
                                 Buffer.Cmd_Delete bpos epos str mk ->
                                     div [celstyle] [ "Delete " ++ editParm2str bpos epos str mk  |> text ]
                    ) editorModel.core.buffer.history
              )
        ]


clipboardView : Editor.Model -> Html Msg
clipboardView editorModel =
    div [ id "debug-pane-clipboard"
        , class "debugger-hbox"
        ]
        [ div [ class "debugger-submenu-title" ] [ text "clipboard:" ]
        , div [ style [ ("overflow","auto"), ("width", "100%"), ("color", "gray"), ("background-color", "whitesmoke") ]
              ]
              ( List.map
                    (λ ln-> div [ style [("border-bottom", "1px dotted gainsboro"), ("background-color", "white"), ("height", "1em")] ] [ text ln ] )
                    (String.lines editorModel.core.copyStore)
              )
        ]


eventlogView : Editor.Model -> Html Msg
eventlogView editorModel =
    div [ id "debug-pane-eventlog"
        , class "debugger-hbox"
        ]
        [ div [ class "debugger-submenu-title" ]
              [ div [] [text "eventlog:"]
              , div [ onClick (SetEventlogEnable (editorModel.event_log == Nothing))
                    , style [ ("border", "1px solid gray")
                            , ("opacity", if (editorModel.event_log == Nothing) then "0.5" else "1.0" )
                            , ("margin", "1ex")
                            , ("text-align", "center")
                            ]
                    ]
                    [text <| if (editorModel.event_log == Nothing) then "OFF" else "ON"]
              ]
        , div [ style [ ("overflow","auto")
                      , ("width", "100%")
                      , ("color", "gray")
                      , ("user-select", "text")
                      , ("-webkit-user-select", "text")
                      , ("-moz-user-select", "text")
                      ]
              ]
              ( List.map (λ ev -> div [ style [("margin-right","0.2em")]] [text <| (dateToString ev.date) ++ " | " ++ (String.pad 16 ' ' ev.name) ++ ":" ++ (ev.data |> stringEscape) ]) (Maybe.withDefault [] editorModel.event_log) )
        ]


inspectorView : Editor.Model -> Html Msg
inspectorView editorModel =
    let
        string_cut_n = (\ n str ->
                            str |> String.left n
                                |> flip (++) (if String.length str <= n then "" else "…")
                       )


        histToString = (\ hist ->
                             case hist of
                                 Buffer.Cmd_Insert bp ep str mk ->
                                    "ins(" ++ (String.length str |> toString) ++ "char)"
                                 Buffer.Cmd_Backspace bp ep str mk->
                                    "bs(" ++ (String.length str |> toString) ++ "char)"
                                 Buffer.Cmd_Delete bp ep str mk ->
                                    "del(" ++ (String.length str |> toString) ++ "char)"
                       )
    in
        div [ id "debug-pane-eventlog"
            , class "debugger-vbox"
            ]
            [ table
                  [class "debuger-table" ]
                  [ tr [] [ th [] [ text "buffer.cursor"   ], td [] [ editorModel.core.buffer.cursor |> cursorToString |> text ] ]
                  , tr [] [ th [] [ text "buffer.contents" ], td [] [ editorModel.core.buffer.contents |> List.take 80 |> String.join "↵" |> string_cut_n 80 |> text ] ]
                  , tr [] [ th [] [ text "buffer.selection"], td [] [ editorModel.core.buffer.selection |> selectionToString |> text ] ]
                  , tr [] [ th [] [ text "buffer.mark"     ], td [] [ editorModel.core.buffer.mark |> markToString |> text ]]
                  , tr [] [ th [] [ text "buffer.history"  ], td [] [ editorModel.core.buffer.history |> List.take 10 |> List.map histToString |> String.join ", " |> flip (++) (if List.length editorModel.core.buffer.history <= 10 then "" else "…") |> text ] ]

--                  , tr [] [ th [] [ text "texteditor.core.id"                  ], td [] [ editorModel.core.id |> text ] ]
                  , tr [] [ th [] [ text "texteditor.core.copyStore"           ], td [] [ editorModel.core.copyStore |> string_cut_n 80 |> stringEscape |> text ]]
                  , tr [] [ th [] [ text "texteditor.core.lastCommand"         ], td [] [ editorModel.core.lastCommand |> Maybe.withDefault "Nothing" |> stringEscape |> text ] ]
                  , tr [] [ th [] [ text "texteditor.core.compositionPreview"  ], td [] [ editorModel.core.compositionPreview |> Maybe.withDefault "Nothing" |> text ] ]
                  , tr [] [ th [] [ text "texteditor.core.focus"               ], td [] [ editorModel.core.focus |> toString |> text ] ]
                  , tr [] [ th [] [ text "texteditor.core.blink"               ], td [] [ editorModel.core.blink |> Core.blinkStateToString |> text ] ]

                  , tr [] [ th [] [ text "texteditor.enableComposer"], td [] [ editorModel.enableComposer |> toString |> text ] ]
                  , tr [] [ th [] [ text "texteditor.drag"          ], td [] [ editorModel.drag |> toString |> text ] ]
                  , tr [] [ th [] [ text "texteditor.keymap"        ], td [] [ editorModel.keymap |> List.length |> toString |> flip (++) " binds" |> text ] ]
                  , tr [] [ th [] [ text "texteditor.event_log"     ], td [] [ editorModel.event_log |> Maybe.andThen
                                                                                   (\ evs ->
                                                                                        evs |> List.take 24
                                                                                            |> List.map (\ev -> ev.name ++ "(" ++ (ev.data |> stringEscape) ++ ")")
                                                                                            |> String.join "; "
                                                                                            |> flip (++) (if List.length evs < 10 then "" else "…")
                                                                                            |> Just
                                                                                   )
                                                                             |> Maybe.withDefault "(Disabled)" |> text ] ]
                  ]
            ]


cursorToString : Buffer.Position -> String
cursorToString cur =
    [ cur.row |> toString
    , ", "
    , cur.column |> toString
    ]
        |> String.concat

selectionToString : Maybe Buffer.Range -> String
selectionToString maybe_sel =
    case maybe_sel of
        Just sel ->
            [ "("
            , sel.begin.row |> toString
            , ","
            , sel.begin.column |> toString
            , ") ~ ("
            , sel.end.row |> toString
            , ","
            , sel.end.column |> toString
            , ")"
            ]
                 |> String.concat
        Nothing ->
            "Nothing"

markToString : Maybe Buffer.Mark -> String
markToString maybe_mark =
    case maybe_mark of
        Just mark ->
            [ "pos=("
            , mark.pos.row |> toString
            , ","
            , mark.pos.column |> toString
            , "), actived="
            , mark.actived |> toString
            ]
                 |> String.concat
        Nothing ->
            "Nothing"

------------------------------------------------------------
-- date tools
------------------------------------------------------------

dateToString : Date.Date -> String
dateToString date =
    [ Date.year date |> toString |> String.padLeft 4 '0'
    , "-"
    , Date.month date |> monthToInt |> toString |> String.padLeft 2 '0'
    , "-"
    , Date.day date |> toString |> String.padLeft 2 '0'
    , " "
    , Date.hour date |> toString |> String.padLeft 2 '0'
    , ":"
    , Date.minute date |> toString |> String.padLeft 2 '0'
    , ":"
    , Date.second date |> toString |> String.padLeft 2 '0'
    , "."
    , Date.millisecond date |> toString |> String.padRight 3 '0'
    ] |> String.concat



monthToInt : Date.Month -> Int
monthToInt month =
    case month of
        Date.Jan -> 1
        Date.Feb -> 2
        Date.Mar -> 3
        Date.Apr -> 4
        Date.May -> 5
        Date.Jun -> 6
        Date.Jul -> 7
        Date.Aug -> 8
        Date.Sep -> 9
        Date.Oct -> 10
        Date.Nov -> 11
        Date.Dec -> 12

    
