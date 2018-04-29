module EditorDebugger exposing
    ( Model
    , Msg
    , init
    , update
    , view
    )

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)

import TextEditor as Editor
import TextEditor.Buffer as Buffer

type alias Model =
    { selectedSubMenu : SubMenu
    }

type SubMenu
    = EditHistory
    | Clipboard
    | EventLog

type Msg
    = SelectSubMenu SubMenu
    | SetEventlogEnable Bool

init : Model
init =
    { selectedSubMenu = EditHistory
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
    [ div [ onClick <| SelectSubMenu EditHistory
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


historyView : Editor.Model -> Html Msg
historyView editorModel =
    div [ id "debug-pane-history"
        , style [ ("min-width", "8em")
                , ("flex-grow", "2")
                , ("height", "100%")
                ]
        ]
        [ div [ style [ ("background-color", "whitesmoke"), ("color", "gray"), ("height", "1em")]] [text "history:"]
        , div
              [ style [ ("overflow","scroll"), ("height", "calc( 100% - 1em )") ] ]
              ( List.map
                    (\ c ->
                         let
                             pos2str = \ row col -> "(" ++ (toString row) ++ ", " ++ (toString col) ++")" 
                             celstyle = style [("text-wrap", "none"), ("white-space","nowrap"), ("color", "gray")]
                         in
                             case c of
                                 Buffer.Cmd_Insert (row, col) (ar, ac) str ->
                                     div [celstyle] [ "Ins" ++ (pos2str row col) ++ " -> " ++ (pos2str ar ac) ++ "{" ++ str ++ "}" |> text ]
                                 Buffer.Cmd_Backspace (row, col) (ar, ac) str ->
                                     div [celstyle] [ "Bs_" ++ (pos2str row col) ++ " -> " ++ (pos2str ar ac) ++ "{" ++ str ++ "}" |> text ]
                                 Buffer.Cmd_Delete (row, col) (ar, ac) str ->
                                     div [celstyle] [ "Del" ++ (pos2str row col) ++ " -> " ++ (pos2str ar ac) ++ "{" ++ str ++ "}" |> text ]
                    ) editorModel.core.buffer.history
              )
        ]


clipboardView : Editor.Model -> Html Msg
clipboardView editorModel =
    div [ id "debug-pane-clipboard"
        , class "hbox"
        , style [ ("flex-grow", "2")
                , ("width", "100%")
                , ("height", "100%")
--                , ("min-height", "2em")
                , ("display", "flex"), ("flex-direction", "row")
                ]
        ]
        [ div [ style [ ("background-color","whitesmoke"), ("color", "gray"), ("width", "10ex")] ] [text "clipboard:"]
        , div [ style [ ("overflow","auto"), ("width", "100%"), ("color", "gray") ]
              ]
              ( List.map
                    (λ ln-> div [ style [("border-bottom", "1px dotted gainsboro"), ("height", "1em")] ] [ text ln ] )
                    (String.lines editorModel.core.copyStore)
              )
        ]


eventlogView : Editor.Model -> Html Msg
eventlogView editorModel =
    div [ id "debug-pane-eventlog"
        , class "hbox"
        , style [ ("flex-grow", "8")
                , ("width", "100%")
                , ("height", "100%")
--                , ("min-height", "2em")
                , ("display", "flex"), ("flex-direction", "row")
                ]
        ]
        [ div [ style [ ("background-color","whitesmoke"), ("color", "gray"), ("width", "10ex")] ]
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
        , div [ style [ ("overflow","scroll")
                      , ("width", "calc( 100% - 3px )")
                      , ("border-top", "3px solid whitesmoke")
                      , ("flex-grow", "8")
                      , ("color", "gray")
                      ]
              ]
              ( List.map (λ ln -> span [ style [("margin-right","0.2em")]] [text ln]) (Maybe.withDefault [] editorModel.event_log) )
        ]

