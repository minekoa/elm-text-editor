import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Json.Encode as Encode

import TextEditor as Editor
import TextEditor.Core as Core
import TextEditor.Commands as Commands
import TextEditor.Buffer as Buffer
import TextEditor.KeyBind as KeyBind

import EditorDebugger
import SoftwareKeyboard
import StyleSetter

main : Program Never Model Msg
main =
    Html.program
        { init = init
        , view = view
        , subscriptions = subscriptions
        , update = update
        }

type alias Model =
    { editor : Editor.Model

    , pane : Pane
    , swkeyboard : SoftwareKeyboard.Model
    , style : StyleSetter.Model
    }

type Pane
    = NoPane
    | DebugPane
    | KeyboardPane
    | StyleEditorPane

type Msg
    = EditorMsg (Editor.Msg)
    | ChangePane Pane
    | DebuggerMsg (EditorDebugger.Msg)
    | SWKeyboardMsg (SoftwareKeyboard.Msg)
    | StyleSetterMsg (StyleSetter.Msg)

init : (Model, Cmd Msg)
init =
    let
        (bm, bc) = Editor.init "editor-sample1" (KeyBind.basic ++ KeyBind.gates ++ KeyBind.emacsLike) ""
    in
        ( Model bm
              NoPane
              SoftwareKeyboard.init
              StyleSetter.init
        , Cmd.map EditorMsg bc
        )



updateMap: Model -> (Editor.Model, Cmd Editor.Msg) -> (Model, Cmd Msg)
updateMap model (em, ec) =
    ( {model | editor = em}
    , Cmd.map EditorMsg ec
    )


update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
    case msg of
        ChangePane pane ->
            ( { model | pane = pane }
            , Cmd.none
            )

        -- ScenarioPage >> List
        EditorMsg msg ->
            let
                (m, c) = Editor.update msg model.editor
            in
                ( { model | editor = m}
                , Cmd.map EditorMsg c
                )

        DebuggerMsg dmsg ->
            let
                (em, dc) = EditorDebugger.update dmsg model.editor
            in
                ( { model | editor = em }
                , Cmd.map DebuggerMsg dc
                )

        SWKeyboardMsg swmsg ->
            let
                (kbd, edt) = SoftwareKeyboard.update swmsg model.swkeyboard model.editor
            in
                ( { model
                      | editor   = Tuple.first edt
                      , swkeyboard = Tuple.first kbd
                  }
                , Cmd.batch [ Cmd.map EditorMsg (Tuple.second edt)
                            , Cmd.map SWKeyboardMsg (Tuple.second kbd)
                            ]
                )

        StyleSetterMsg smsg ->
            let
                (m, c) = StyleSetter.update smsg model.style
            in
                ( { model
                      | style = m
                  }
                , Cmd.map StyleSetterMsg c
                )



subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch [ Sub.map EditorMsg  (Editor.subscriptions model.editor) ]


view : Model -> Html Msg
view model =
    div [ style [ ("margin", "0"), ("padding", "0"), ("width", "100%"), ("height", "100%")
                , ("display", "flex"), ("flex-direction", "column")
                ]
        ]
        [ h1 [] [text "TextEditor Sample"]
        , div [ style [ ("margin", "0"), ("padding", "0"), ("width", "100%"), ("height", "100%")
                      , ("overflow","hidden")
                      , ("flex-grow", "8")
                      , ("color", model.style.fgColor.index)
                      , ("background-color", model.style.bgColor.index)
                      , ("font-family", model.style.fontFamily.index)
                      , ("font-size", model.style.fontSize.index)
                      ]
              ]
              [ Html.map EditorMsg (Editor.view model.editor) ]
        , modeline model
        , paneChanger model
        , case model.pane of
              NoPane ->
                  text ""
              DebugPane ->
                  Html.map DebuggerMsg (EditorDebugger.view model.editor)
              KeyboardPane ->
                  Html.map SWKeyboardMsg (SoftwareKeyboard.view model.swkeyboard)
              StyleEditorPane ->
                  Html.map StyleSetterMsg (StyleSetter.view model.style)
        ]

paneChanger : Model -> Html Msg
paneChanger model =
    let
        tab = \ tgtPane s ->
              div [ style <| if model.pane == tgtPane
                             then [("margin", "2px 5px 0 2px"), ("padding", "0 1em"), ("border-width", "1px 1px 0px 1px"), ("border-color", "gray"), ("background-color", "whitesmoke"), ("color", "gray")]
                             else [("margin", "2px 5px 0 2px"), ("padding", "0 1em"), ("border", "none"), ("background-color", "darkgray"), ("color", "whitesmoke")]
                  , onClick <| ChangePane tgtPane
                  ]
                  [ text s ]
    in
    div [ style [ ("display", "flex"), ("flex-direction", "row"), ("align-items", "flex-end")
                , ("background-color", "darkgray"), ("min-height", "1.5em")
                ]
        ]
        [ div [ style [ ("border", "1px solid gray"), ("color", "gray"), if model.pane == NoPane then ("background-color", "inherit") else ("background-color", "silver")
                      , ("height", "1em"), ("width", "1em"), ("margin", "3px 1.5em 3px 0.5em"), ("text-align", "center")
                      ]
              , onClick (ChangePane NoPane)
              ]
              [text "x"]
        , tab DebugPane "debug"
        , tab KeyboardPane "keyboard"
        , tab StyleEditorPane "style"
        ]



modeline : Model -> Html msg
modeline model =
    let
        toCursorString    = \c -> "(" ++ (toString c.row) ++ ", " ++ (toString c.column) ++ ")"
        toIMEString       =
            \ compositionData -> compositionData
                          |> Maybe.andThen (\d -> Just <| "[IME] " ++ d )
                          |> Maybe.withDefault ""
        toSelectionString =
            \ selection -> selection
                        |> Maybe.andThen (\s-> Just <|
                                              " select:(" ++ (s.begin |> Tuple.first |> toString)
                                              ++ "," ++ (s.begin |> Tuple.second |> toString) 
                                              ++ ")-(" ++ (s.end |> Tuple.first |> toString)
                                              ++ "," ++ (s.end |> Tuple.second |> toString) ++ ")"
                                         )
                        |> Maybe.withDefault ""
    in
        div [ id "modeline"
            , style [ ("background-color","black")
                    , ("color", "white")
                    ]
            ]
            [ text <| toCursorString model.editor.core.buffer.cursor
            , text <| toIMEString model.editor.core.compositionPreview
            , text <| toSelectionString model.editor.core.buffer.selection
            ]




 
