module EditorDebugger exposing
    ( Msg
    , update
    , view
    )

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)

import TextEditor as Editor
import TextEditor.Buffer as Buffer



type Msg
    = SetEventlogEnable Bool

update : Msg -> Editor.Model -> (Editor.Model, Cmd Msg)
update msg model =
    case msg of
        SetEventlogEnable True ->
            ( { model | event_log = Just [] }
            , Cmd.none
            )

        SetEventlogEnable False ->
            ( { model | event_log = Nothing }
            , Cmd.none
            )

view : Editor.Model -> Html Msg
view model =
    div [ id "debug-pane"
        , class "hbox"
        , style [ ("display", "flex")
                , ("flex-direction", "row")
                , ("width" , "100%"), ("height", "100%")
                , ("flex-grow", "3")
                , ("min-height", "7em")
                , ("max-height", "14em")
                ]
        ]
        [ div [ id "debug-pane-history"
              , style [ ("min-width", "8em")
                      , ("flex-grow", "2")
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
                                   Buffer.Cmd_Insert (row, col) str ->
                                       div [celstyle] [ "Ins" ++ (pos2str row col) ++ "{" ++ str ++ "}" |> text ]
                                   Buffer.Cmd_Backspace (row, col) str ->
                                       div [celstyle] [ "Bs_" ++ (pos2str row col) ++ "{" ++ str ++ "}" |> text ]
                                   Buffer.Cmd_Delete (row, col) str ->
                                       div [celstyle] [ "Del" ++ (pos2str row col) ++ "{" ++ str ++ "}" |> text ]
                      ) model.core.buffer.history
                  )
              ]
        , div [ class "vbox"
              , style [ ("flex-grow", "8")
                      , ("display", "flex"), ("flex-direction", "column")
                      ]
              ]
              [ div [ id "debug-pane-clipboard"
                    , class "hbox"
                    , style [ ("flex-grow", "2")
                            , ("width", "100%")
                            , ("min-height", "2em")
                            , ("display", "flex"), ("flex-direction", "row")
                            ]
                    ]
                    [ div [ style [ ("background-color","whitesmoke"), ("color", "gray"), ("width", "10ex")] ] [text "clipboard:"]
                    , div [ style [ ("overflow","auto"), ("width", "100%"), ("color", "gray") ]
                          ]
                          ( List.map
                                (λ ln-> div [ style [("border-bottom", "1px dotted gainsboro"), ("height", "1em")] ] [ text ln ] )
                                (String.lines model.core.copyStore)
                          )
                    ]
              , div [ id "debug-pane-eventlog"
                    , class "hbox"
                    , style [ ("flex-grow", "8")
                            , ("width", "100%")
                            , ("min-height", "2em")
                            , ("display", "flex"), ("flex-direction", "row")
                            ]
                    ]
                    [ div [ style [ ("background-color","whitesmoke"), ("color", "gray"), ("width", "10ex")] ]
                          [ div [] [text "eventlog:"]
                          , div [ onClick (SetEventlogEnable (model.event_log == Nothing))
                                , style [ ("border", "1px solid gray")
                                        , ("opacity", if (model.event_log == Nothing) then "0.5" else "1.0" )
                                        , ("margin", "1ex")
                                        , ("text-align", "center")
                                        ]
                                ]
                                [text <| if (model.event_log == Nothing) then "OFF" else "ON"]
                          ]
                    , div [ style [ ("overflow","scroll")
                                  , ("width", "calc( 100% - 3px )")
                                  , ("border-top", "3px solid whitesmoke")
                                  , ("flex-grow", "8")
                                  , ("color", "gray")
                                  ]
                          ]
                          ( List.map (λ ln -> span [ style [("margin-right","0.2em")]] [text ln]) (Maybe.withDefault [] model.event_log) )
                    ]
              ]
        ]
