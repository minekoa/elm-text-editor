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

import DebugMenu
import SoftwareKeyboard
import StyleMenu
import FileMenu
import KeyBindMenu

import Ports.WebStrage

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

    , pane : MenuPane
    , debugger : DebugMenu.Model
    , swkeyboard : SoftwareKeyboard.Model
    , style : StyleMenu.Model
    , filer : FileMenu.Model
    , keybindMenu : KeyBindMenu.Model
    }

type MenuPane
    = NoPane
    | DebugMenuPane
    | KeyboardPane
    | StyleMenuPane
    | FileMenuPane
    | KeyBindMenuPane
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
        (smm, smc) = StyleMenu.init
        (kmm, kmc) = KeyBindMenu.init
    in
        ( Model bm
              [ buf ]
              0
              buf.name
              NoPane
              DebugMenu.init
              SoftwareKeyboard.init
              smm
              FileMenu.init
              kmm
        , Cmd.batch [ Cmd.map EditorMsg bc
                    , Cmd.map StyleMenuMsg smc
                    , Cmd.map KeyBindMenuMsg kmc
                    ]
        )



------------------------------------------------------------
-- Update
------------------------------------------------------------

type Msg
    = EditorMsg (Editor.Msg)
    | ChangeBuffer Int
    | CloseBuffer Int
    | ChangePane MenuPane
    | DebugMenuMsg (DebugMenu.Msg)
    | SWKeyboardMsg (SoftwareKeyboard.Msg)
    | StyleMenuMsg (StyleMenu.Msg)
    | FileMenuMsg (FileMenu.Msg)
    | KeyBindMenuMsg (KeyBindMenu.Msg)
    | ClearSettings

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

        DebugMenuMsg dmsg ->
            let
                (em, dm, dc) = DebugMenu.update dmsg model.editor model.debugger
            in
                ( { model
                      | editor = em
                      , debugger = dm
                  }
                , Cmd.map DebugMenuMsg dc
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

        StyleMenuMsg smsg ->
            let
                (m, c) = StyleMenu.update smsg model.style
            in
                ( { model
                      | style = m
                  }
                , Cmd.map StyleMenuMsg c
                )

        -- FileMenu
        FileMenuMsg fmsg ->
            let
                bufname = bufferName model.currentBufferIndex model
                              |> Maybe.withDefault ""

                (m, c) = FileMenu.update fmsg (bufname, Editor.buffer model.editor) model.filer

            in
                case fmsg of
                    FileMenu.CreateNewBuffer name ->
                        ( { model | filer = m }
                              |> updateBufferContent model.currentBufferIndex (Editor.buffer model.editor)
                              |> insertBuffer (model.currentBufferIndex + 1) (makeBuffer name "")
                              |> selectBuffer (model.currentBufferIndex + 1)
                        , Cmd.map FileMenuMsg c
                        )

                    FileMenu.ReadFile file ->
                        case file.data of
                            Ok content ->
                                let
                                    newbuf = makeBuffer file.name content
                                in
                                    ( { model | filer = m }
                                        |> updateBufferContent model.currentBufferIndex (Editor.buffer model.editor)
                                        |> insertBuffer (model.currentBufferIndex + 1) newbuf
                                        |> selectBuffer (model.currentBufferIndex + 1)
                                    , Cmd.map FileMenuMsg c
                                    )
                            Err err ->
                                ( { model | filer = m}
                                , Cmd.map FileMenuMsg c
                                )
                    FileMenu.SaveFileAs name ->
                        ( { model | filer = m  }
                              |> updateBufferName model.currentBufferIndex name
                        , Cmd.map FileMenuMsg c
                        )

                    _ ->
                        ( { model | filer = m}
                        , Cmd.map FileMenuMsg c
                        )

        KeyBindMenuMsg kbindmsg ->
            let
                em = model.editor
                (kbinds, km, kc) = KeyBindMenu.update kbindmsg model.editor.keymap model.keybindMenu
            in
                ( { model
                      | editor = { em | keymap = kbinds }
                      , keybindMenu = km
                  }
                , Cmd.map KeyBindMenuMsg kc
                )

        -- about menu
        ClearSettings ->
            ( model
            , Ports.WebStrage.localStrage_clear ()
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
    Sub.batch [ Sub.map EditorMsg  (Editor.subscriptions model.editor)
              , Sub.map StyleMenuMsg (StyleMenu.subscriptions model.style)
              , Sub.map KeyBindMenuMsg (KeyBindMenu.subscriptions model.keybindMenu)
              ]


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
        [ menuBar model
        , case model.pane of
              NoPane ->
                  text ""
              DebugMenuPane ->
                  Html.map DebugMenuMsg (DebugMenu.view model.editor model.debugger)
              KeyboardPane ->
                  Html.map SWKeyboardMsg (SoftwareKeyboard.view model.swkeyboard)
              StyleMenuPane ->
                  Html.map StyleMenuMsg (StyleMenu.view model.style)
              FileMenuPane ->
                  Html.map FileMenuMsg (FileMenu.view model.filer)
              KeyBindMenuPane ->
                  Html.map KeyBindMenuMsg (KeyBindMenu.view model.editor.keymap model.keybindMenu)
              AboutPane ->
                  aboutPane model
        ]

menuBar : Model -> Html Msg
menuBar model =
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
        , tab FileMenuPane "File"
        , tab StyleMenuPane "Style"
        , tab KeyBindMenuPane "Keybind"
        , tab KeyboardPane "Keyboard"
        , tab DebugMenuPane "Debug"
        , tab AboutPane "About"
        ]

aboutPane : Model -> Html Msg
aboutPane model =
    div [ style [ ("flex-grow", "2")
                , ("min-height", "13em")
                , ("padding", "2em")
                , ("background-color", "whitesmoke")
                , ("color", "gray")
                ]
        ]
        [ h1 [] [ text "elm-text-editor demo" ]
        , a [ href "https://github.com/minekoa/elm-text-editor"] [text "https://github.com/minekoa/elm-text-editor"]
        , div [ style [ ("display", "flex")
                      , ("flex-direction", "row-reverse")
                      , ("padding", "1.5rem")
                      ]
              ]
              [ div [ class "menu_button"
                    , onClick ClearSettings
                    ]
                    [ text "Clear Settings" ]
              ]
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

        toMarkSetString =
            \ mark -> mark
                      |> Maybe.andThen (\mk -> Just <|
                                            if mk.actived then
                                                " mark-set:("
                                                ++ (mk.pos |> Tuple.first |> toString) ++ "," ++ (mk.pos |> Tuple.second |> toString)
                                                ++ ")"
                                            else
                                                ""
                                       )
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
            , text <| toMarkSetString model.editor.core.buffer.mark
            , text <| toSelectionString model.editor.core.buffer.selection
            ]




 
