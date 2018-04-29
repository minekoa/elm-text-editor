import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Json.Encode as Encode

import Task
import FileReader

import TextEditor as Editor
import TextEditor.Core as Core
import TextEditor.Commands as Commands
import TextEditor.Buffer
import TextEditor.KeyBind as KeyBind

import EditorDebugger
import SoftwareKeyboard
import StyleSetter
import Filer

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
    , buffers : List Buffer
    , currentBufferIndex : Int
    , currentBufferName : String

    , pane : Pane
    , debugger : EditorDebugger.Model
    , swkeyboard : SoftwareKeyboard.Model
    , style : StyleSetter.Model
    , filer : Filer.Model
    }

type Pane
    = NoPane
    | DebugPane
    | KeyboardPane
    | StyleEditorPane
    | FilerPane
    | AboutPane

type alias Buffer =
    { name : String
    , buffer : TextEditor.Buffer.Model
    }

makeBuffer: String -> String -> Buffer
makeBuffer name content =
    { name = name
    , buffer = TextEditor.Buffer.init content
    }

init : (Model, Cmd Msg)
init =
    let
        content = ""
        buf = makeBuffer "*scratch*" content
        (bm, bc) = Editor.init "editor-sample1" (KeyBind.basic ++ KeyBind.gates ++ KeyBind.emacsLike) content
    in
        ( Model bm
              [ buf ]
              0
              buf.name
              NoPane
              EditorDebugger.init
              SoftwareKeyboard.init
              StyleSetter.init
              Filer.init
        , Cmd.map EditorMsg bc
        )



------------------------------------------------------------
-- Update
------------------------------------------------------------

type Msg
    = EditorMsg (Editor.Msg)
    | ChangeBuffer Int
    | CloseBuffer Int
    | ChangePane Pane
    | DebuggerMsg (EditorDebugger.Msg)
    | SWKeyboardMsg (SoftwareKeyboard.Msg)
    | StyleSetterMsg (StyleSetter.Msg)
    | FilerMsg (Filer.Msg)


updateMap: Model -> (Editor.Model, Cmd Editor.Msg) -> (Model, Cmd Msg)
updateMap model (em, ec) =
    ( {model | editor = em}
    , Cmd.map EditorMsg ec
    )


update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
    case msg of
        ChangeBuffer i ->
            ( model
                |> updateBufferContent model.currentBufferIndex (Editor.buffer model.editor)
                |> selectBuffer i
            , Cmd.none
            )

        CloseBuffer i ->
            ( model
                |> removeBuffer i
                |> \m -> if i == m.currentBufferIndex then
                             selectBuffer i m
                         else if i < m.currentBufferIndex then
                                  { m | currentBufferIndex = m.currentBufferIndex - 1 }
                              else
                                  m
            , Cmd.none
            )

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
                (em, dm, dc) = EditorDebugger.update dmsg model.editor model.debugger
            in
                ( { model
                      | editor = em
                      , debugger = dm
                  }
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

        -- Filer
        FilerMsg fmsg ->
            let
                bufname = bufferName model.currentBufferIndex model
                              |> Maybe.withDefault ""

                (m, c) = Filer.update fmsg (bufname, Editor.buffer model.editor) model.filer

            in
                case fmsg of
                    Filer.CreateNewBuffer name ->
                        ( { model | filer = m }
                              |> updateBufferContent model.currentBufferIndex (Editor.buffer model.editor)
                              |> insertBuffer (model.currentBufferIndex + 1) (makeBuffer name "")
                              |> selectBuffer (model.currentBufferIndex + 1)
                        , Cmd.map FilerMsg c
                        )

                    Filer.ReadFile file ->
                        case file.data of
                            Ok content ->
                                let
                                    newbuf = makeBuffer file.name content
                                in
                                    ( { model | filer = m }
                                        |> updateBufferContent model.currentBufferIndex (Editor.buffer model.editor)
                                        |> insertBuffer (model.currentBufferIndex + 1) newbuf
                                        |> selectBuffer (model.currentBufferIndex + 1)
                                    , Cmd.map FilerMsg c
                                    )
                            Err err ->
                                ( { model | filer = m}
                                , Cmd.map FilerMsg c
                                )
                    Filer.SaveFileAs name ->
                        ( { model | filer = m  }
                              |> updateBufferName model.currentBufferIndex name
                        , Cmd.map FilerMsg c
                        )

                    _ ->
                        ( { model | filer = m}
                        , Cmd.map FilerMsg c
                        )


updateBufferContent : Int -> TextEditor.Buffer.Model -> Model -> Model
updateBufferContent i content model =
    case model.buffers |> List.drop i |> List.head of
        Just buf ->
            { model
                | buffers = (List.take i model.buffers)
                            ++ ({ buf | buffer = content } :: List.drop (i + 1) model.buffers)
            }
        Nothing ->
            model

updateBufferName : Int -> String -> Model -> Model
updateBufferName i name model =
    case model.buffers |> List.drop i |> List.head of
        Just buf ->
            { model
                | buffers = (List.take i model.buffers)
                            ++ ({ buf | name = name } :: List.drop (i + 1) model.buffers)
            }
        Nothing ->
            model

bufferName : Int -> Model -> Maybe String
bufferName i model =
    model.buffers
        |> List.drop i |> List.head
        |> Maybe.andThen (\ buf -> Just buf.name) 

selectBuffer : Int -> Model -> Model
selectBuffer i model =
    case model.buffers |> List.drop i |> List.head of
        Just buf ->
            { model
                | currentBufferIndex = i
                , currentBufferName  = buf.name
                , editor = Editor.setBuffer buf.buffer model.editor
            }
        Nothing ->
            if List.isEmpty model.buffers then
                model
            else
                selectBuffer (model.buffers |> List.length |> flip (-) 1) model

insertBuffer : Int -> Buffer -> Model -> Model
insertBuffer i buf model =
    { model
        | buffers = (List.take i model.buffers) ++ (buf :: (List.drop i model.buffers))
    }

removeBuffer : Int -> Model -> Model
removeBuffer i model =
    { model
        | buffers = (List.take i model.buffers) ++ (List.drop (i + 1) model.buffers)
    }


------------------------------------------------------------
-- Subscriptions
------------------------------------------------------------

subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch [ Sub.map EditorMsg  (Editor.subscriptions model.editor) ]


------------------------------------------------------------
-- View
------------------------------------------------------------

view : Model -> Html Msg
view model =
    div [ style [ ("margin", "0"), ("padding", "0"), ("width", "100%"), ("height", "100%")
                , ("display", "flex"), ("flex-direction", "column")
                ]
        ]
        [ bufferTab model
        , div [ style [ ("margin", "0"), ("padding", "0"), ("width", "100%"), ("height", "100%")
                      , ("overflow","hidden")
                      , ("flex-grow", "8")
                      , ("color", model.style.fgColor.value)
                      , ("background-color", model.style.bgColor.value)
                      , ("font-family", model.style.fontFamily.value)
                      , ("font-size", model.style.fontSize.value)
                      ]
              ]
              [ Html.map EditorMsg (Editor.view model.editor) ]
        , modeline model
        , applicationMenu model
        ]


applicationMenu : Model -> Html Msg
applicationMenu model =
    div [ class "app-menu"
        ]
        [ paneChanger model
        , case model.pane of
              NoPane ->
                  text ""
              DebugPane ->
                  Html.map DebuggerMsg (EditorDebugger.view model.editor model.debugger)
              KeyboardPane ->
                  Html.map SWKeyboardMsg (SoftwareKeyboard.view model.swkeyboard)
              StyleEditorPane ->
                  Html.map StyleSetterMsg (StyleSetter.view model.style)
              FilerPane ->
                  Html.map FilerMsg (Filer.view model.filer)
              AboutPane ->
                  div [ style [ ("flex-grow", "2")
                              , ("min-height", "13em")
                              , ("padding", "2em")
                              , ("background-color", "whitesmoke")
                              , ("color", "gray")
                              ]
                      ]
                      [ h1 [] [ text "elm-text-editor demo" ]
                      , a [ href "https://github.com/minekoa/elm-text-editor"] [text "https://github.com/minekoa/elm-text-editor"]
                      ]
        ]

paneChanger : Model -> Html Msg
paneChanger model =
    let
        tab = \ tgtPane s ->
              div [ class <| if model.pane == tgtPane then "app-menu-item-active" else "app-menu-item"
                  , onClick <| if model.pane == tgtPane then ChangePane NoPane else ChangePane tgtPane
                  ]
                  [ text s ]
    in
    div [ class "app-menu-bar" ]
        [ div [ class <| if model.pane == NoPane then "app-menu-close-button" else "app-menu-close-button-active"
              , onClick <| ChangePane NoPane
              ]
              [text "x"]
        , tab FilerPane "File"
        , tab StyleEditorPane "Style"
        , tab KeyboardPane "Keyboard"
        , tab DebugPane "Debug"
        , tab AboutPane "About"
        ]


bufferTab : Model -> Html Msg
bufferTab model =
    div [ class "buf-tab-bar" ]
        ( List.indexedMap (\i buf ->
                        div [ class <| if model.currentBufferIndex == i then "buf-tab-active" else "buf-tab"
                            ]
                            [ span [ onClick <| ChangeBuffer i ] [text buf.name]
                            , div  [ class "buf-tab-close-button"
                                   , onClick <| CloseBuffer i
                                   ]
                                   [ text "☓" ]
                            ]
                   ) model.buffers
        )


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




 
