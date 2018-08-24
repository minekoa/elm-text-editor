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
import Time

import TextEditor as Editor
import TextEditor.Buffer as Buffer
import TextEditor.Core as Core
--import Native.Mice

import StringTools exposing (..)


type alias Model =
    { selectedSubMenu : SubMenu
    }

type SubMenu
    = EditHistory
    | Clipboard
    | EventLog
    | Inspector
    | Geometory

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
        , style "min-height" "17em"
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
    , div [ onClick <| SelectSubMenu Geometory
          , class <| if model.selectedSubMenu == Geometory then "menu-item-active" else "menu-item"
          ]
          [ span [] [text "Geometries"]
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
        Geometory ->
            div [class "menu-palette"] [ geometoryView editorModel ]

historyView : Editor.Model -> Html Msg
historyView editorModel =
    div [ id "debug-pane-history"
        , class "debugger-hbox"
        ]
        [ div [ class "debugger-submenu-title" ] [ text "history:" ]
        , div
              [ style "overflow" "auto", style "width" "100%" ]
              ( List.map
                    (\ c ->
                         let
                             pos2str = \ p -> "(" ++ (String.fromInt p.row) ++ ", " ++ (String.fromInt p.column) ++")" 
                             mark2str = \ mk -> case mk of
                                                    Just m -> "{pos=" ++ (pos2str m.pos ) ++ ", actived=" ++ (stringFromBool m.actived) ++ "}"
                                                    Nothing -> "Nothing"
                             editParm2str = \ bfr afr str mk ->
                                 "{begin=" ++ (pos2str bfr) ++ ", end=" ++ (pos2str afr) ++ ", str=\"" ++ str ++ "\", mark=" ++ (mark2str mk) ++ "}"
                             celstyle = [ style "text-wrap" "none", style "white-space" "nowrap", style "color" "gray"]
                         in
                             case c of
                                 Buffer.Cmd_Insert bpos epos str mk ->
                                     div celstyle [ "Insert " ++ editParm2str bpos epos str mk |> text ]
                                 Buffer.Cmd_Backspace bpos epos str mk->
                                     div celstyle [ "Backspace " ++ editParm2str bpos epos str mk  |> text ]
                                 Buffer.Cmd_Delete bpos epos str mk ->
                                     div celstyle [ "Delete " ++ editParm2str bpos epos str mk  |> text ]
                    ) editorModel.core.buffer.history
              )
        ]


clipboardView : Editor.Model -> Html Msg
clipboardView editorModel =
    div [ id "debug-pane-clipboard"
        , class "debugger-hbox"
        ]
        [ div [ class "debugger-submenu-title" ] [ text "clipboard:" ]
        , div [ style "overflow" "auto", style "width" "100%", style "color" "gray", style "background-color" "whitesmoke" ]
              ( List.map
                    (\ ln-> div [ style "border-bottom" "1px dotted gainsboro", style "background-color" "white", style "height" "1em" ] [ text ln ] )
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
                    , style "border" "1px solid gray"
                    , style "opacity" (if (editorModel.event_log == Nothing) then "0.5" else "1.0" )
                    , style "margin" "1ex"
                    , style "text-align" "center"
                    ]
                    [text <| if (editorModel.event_log == Nothing) then "OFF" else "ON"]
              ]
        , div [ style "overflow" "auto"
              , style "width" "100%"
              , style "color" "gray"
              , style "user-select" "text"
              , style "-webkit-user-select" "text"
              , style "-moz-user-select" "text"
              ]
              ( List.map (\ev -> div [ style "margin-right" "0.2em"] [text <| (dateToString ev.date) ++ " | " ++ (String.pad 16 ' ' ev.name) ++ ":" ++ (ev.data |> stringEscape) ]) (Maybe.withDefault [] editorModel.event_log) )
        ]


inspectorView : Editor.Model -> Html Msg
inspectorView editorModel =
    let
        string_cut_n = (\ n str ->
                            str |> String.left n
                                |> ((++) (if String.length str <= n then "" else "…"))
                       )


        histToString = (\ hist ->
                             case hist of
                                 Buffer.Cmd_Insert bp ep str mk ->
                                    "ins(" ++ (String.length str |> String.fromInt) ++ "char)"
                                 Buffer.Cmd_Backspace bp ep str mk->
                                    "bs(" ++ (String.length str |> String.fromInt) ++ "char)"
                                 Buffer.Cmd_Delete bp ep str mk ->
                                    "del(" ++ (String.length str |> String.fromInt) ++ "char)"
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
                  , tr [] [ th [] [ text "buffer.history"  ], td [] [ editorModel.core.buffer.history |> List.take 10 |> List.map histToString |> String.join ", " |> ((++) (if List.length editorModel.core.buffer.history <= 10 then "" else "…")) |> text ] ]

--                  , tr [] [ th [] [ text "texteditor.core.id"                  ], td [] [ editorModel.core.id |> text ] ]
                  , tr [] [ th [] [ text "texteditor.core.copyStore"           ], td [] [ editorModel.core.copyStore |> string_cut_n 80 |> stringEscape |> text ]]
                  , tr [] [ th [] [ text "texteditor.core.lastCommand"         ], td [] [ editorModel.core.lastCommand |> Maybe.withDefault "Nothing" |> stringEscape |> text ] ]
                  , tr [] [ th [] [ text "texteditor.core.compositionPreview"  ], td [] [ editorModel.core.compositionPreview |> Maybe.withDefault "Nothing" |> text ] ]
                  , tr [] [ th [] [ text "texteditor.core.focus"               ], td [] [ editorModel.core.focus |> stringFromBool |> text ] ]
                  , tr [] [ th [] [ text "texteditor.core.blink"               ], td [] [ editorModel.core.blink |> Core.blinkStateToString |> text ] ]

                  , tr [] [ th [] [ text "texteditor.enableComposer"], td [] [ editorModel.enableComposer |> stringFromBool |> text ] ]
                  , tr [] [ th [] [ text "texteditor.drag"          ], td [] [ editorModel.drag |> stringFromBool |> text ] ]
                  , tr [] [ th [] [ text "texteditor.keymap"        ], td [] [ editorModel.keymap |> List.length |> String.fromInt |> ((++) " binds") |> text ] ]
                  , tr [] [ th [] [ text "texteditor.event_log"     ], td [] [ editorModel.event_log |> Maybe.andThen
                                                                                   (\ evs ->
                                                                                        evs |> List.take 24
                                                                                            |> List.map (\ev -> ev.name ++ "(" ++ (ev.data |> stringEscape) ++ ")")
                                                                                            |> String.join "; "
                                                                                            |> ((++) (if List.length evs < 10 then "" else "…"))
                                                                                            |> Just
                                                                                   )
                                                                             |> Maybe.withDefault "(Disabled)" |> text ] ]
                  ]
            ]


cursorToString : Buffer.Position -> String
cursorToString cur =
    [ cur.row |> String.fromInt
    , ", "
    , cur.column |> String.fromInt
    ]
        |> String.concat

selectionToString : Maybe Buffer.Range -> String
selectionToString maybe_sel =
    case maybe_sel of
        Just sel ->
            [ "("
            , sel.begin.row |> String.fromInt
            , ","
            , sel.begin.column |> String.fromInt
            , ") ~ ("
            , sel.end.row |> String.fromInt
            , ","
            , sel.end.column |> String.fromInt
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
            , mark.pos.row |> String.fromInt
            , ","
            , mark.pos.column |> String.fromInt
            , "), actived="
            , mark.actived |> stringFromBool 
            ]
                 |> String.concat
        Nothing ->
            "Nothing"

stringFromBool: Bool -> String
stringFromBool b =
    if b then "True" else "False"

geometoryView : Editor.Model -> Html Msg
geometoryView editorModel =
    div [ id "debug-pane-eventlog"
        , class "debugger-vbox"
        ]
        [ table 
              [ class "debuger-table" ]
              [ tr [] [ th [] [text "--"], th [] [text "left"], th [] [text "top"], th [] [text "right"], th [] [text "bottom"], th [] [text "width"], th [] [text "height"] ]
              -- , tr [] <| (th [] [ text "frame"            ]) :: (Core.frameID       editorModel.core |> getBoundingClientRect |> rectToTableColumn )
              -- , tr [] <| (th [] [ text "scene"            ]) :: (Core.sceneID       editorModel.core |> getBoundingClientRect |> rectToTableColumn )
              -- , tr [] <| (th [] [ text "code area"        ]) :: (Core.codeAreaID    editorModel.core |> getBoundingClientRect |> rectToTableColumn )
              -- , tr [] <| (th [] [ text "line number area" ]) :: (Core.lineNumAreaID editorModel.core |> getBoundingClientRect |> rectToTableColumn )
              -- , tr [] <| (th [] [ text "cursor"           ]) :: (Core.cursorID      editorModel.core |> getBoundingClientRect |> rectToTableColumn )
              -- , tr [] <| (th [] [ text "input area"       ]) :: (Core.inputAreaID   editorModel.core |> getBoundingClientRect |> rectToTableColumn )
              -- , tr [] <| (th [] [ text "tap area"         ]) :: (Core.tapAreaID     editorModel.core |> getBoundingClientRect |> rectToTableColumn )
              -- , tr [] <| (th [] [ text "frame (page)"            ]) :: (Core.frameID       editorModel.core |> getBoundingPageRect |> rectToTableColumn )
              -- , tr [] <| (th [] [ text "code area (page)"        ]) :: (Core.codeAreaID    editorModel.core |> getBoundingPageRect |> rectToTableColumn )
              ]
        ]

rectToTableColumn: Rect -> List (Html msg)
rectToTableColumn rct =
    [ td [] [ rct.left   |> String.fromInt |> text ]
    , td [] [ rct.top    |> String.fromInt |> text ]
    , td [] [ rct.right  |> String.fromInt |> text ]
    , td [] [ rct.bottom |> String.fromInt |> text ]
    , td [] [ rct.width  |> String.fromInt |> text ]
    , td [] [ rct.height |> String.fromInt |> text ]
    ]

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

--getBoundingClientRect: String -> Rect
--getBoundingClientRect id = Native.Mice.getBoundingClientRect id

--getBoundingPageRect: String -> Rect
--getBoundingPageRect id = Native.Mice.getBoundingPageRect id











------------------------------------------------------------
-- date tools
------------------------------------------------------------

dateToString : Time.Posix -> String
dateToString date =
    [ Time.toYear Time.utc date |> String.fromInt |> String.padLeft 4 '0'
    , "-"
    , Time.toMonth Time.utc date |> monthToInt |> String.fromInt |> String.padLeft 2 '0'
    , "-"
    , Time.toDay Time.utc date |> String.fromInt |> String.padLeft 2 '0'
    , " "
    , Time.toHour Time.utc date |> String.fromInt |> String.padLeft 2 '0'
    , ":"
    , Time.toMinute Time.utc date |> String.fromInt |> String.padLeft 2 '0'
    , ":"
    , Time.toSecond Time.utc date |> String.fromInt |> String.padLeft 2 '0'
    , "."
    , Time.toMillis Time.utc date |> String.fromInt |> String.padRight 3 '0'
    ] |> String.concat



monthToInt : Time.Month -> Int
monthToInt month =
    case month of
        Time.Jan -> 1
        Time.Feb -> 2
        Time.Mar -> 3
        Time.Apr -> 4
        Time.May -> 5
        Time.Jun -> 6
        Time.Jul -> 7
        Time.Aug -> 8
        Time.Sep -> 9
        Time.Oct -> 10
        Time.Nov -> 11
        Time.Dec -> 12

    
