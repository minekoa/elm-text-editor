module Main exposing (..)

import TextEditor
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Browser

type alias Model =
    { notepad : TextEditor.Model
    , editor : TextEditor.Model
    , modern : TextEditor.Model
    }


type Msg
    = NotepadMsg TextEditor.Msg
    | EditorMsg TextEditor.Msg
    | ModernMsg TextEditor.Msg


main =
    Browser.element
        { init = init
        , view = view
        , subscriptions = subscriptions
        , update = update
        }


defaultText =
    """ABCDEFG HIJKLMN
OPQRSTU VWXYZ

01234 56789

\tabcdefg hijklmn
\t\topqrstu vwxyz

あいうえお\u{3000}かきくけこ
さしすせそ\u{3000}たちつてと
なにぬねの\u{3000}はひふへほ
まみむめも\u{3000}や\u{3000}ゆ\u{3000}よ
らりるれろ\u{3000}わゐ\u{3000}ゑを
ん
"""


init : Maybe Int -> ( Model, Cmd Msg )
init flgs =
    let
        ( m1, c1 ) =
            TextEditor.initLikeNotepad "id_notepad" defaultText

        ( m2, c2 ) =
            TextEditor.initLikeCodeEditor "id_editor" defaultText

        ( m3, c3 ) =
            TextEditor.initLikeModernEditor "id_modern" defaultText
    in
        ( Model m1 m2 m3
        , Cmd.batch
            [ Cmd.map NotepadMsg c1
            , Cmd.map EditorMsg c2
            , Cmd.map ModernMsg c3
            ]
        )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NotepadMsg edmsg ->
            let
                ( m, c ) =
                    TextEditor.update edmsg model.notepad
            in
                ( { model | notepad = m }, Cmd.map NotepadMsg c )

        EditorMsg edmsg ->
            let
                ( m, c ) =
                    TextEditor.update edmsg model.editor
            in
                ( { model | editor = m }, Cmd.map EditorMsg c )

        ModernMsg edmsg ->
            let
                ( m, c ) =
                    TextEditor.update edmsg model.modern
            in
                ( { model | modern = m }, Cmd.map ModernMsg c )


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ Sub.map NotepadMsg (TextEditor.subscriptions model.notepad)
        , Sub.map EditorMsg (TextEditor.subscriptions model.editor)
        , Sub.map ModernMsg (TextEditor.subscriptions model.modern)
        ]


view : Model -> Html Msg
view model =
    div
        []
        [ h1 [] [ text "defaultStyles" ]
        , a [ href "https://github.com/minekoa/elm-text-editor/tree/master/example/defaultStyles" ] [ text "Browse source" ]
        , text " | "
        , a [ href "../index.html" ] [ text "More examples" ]

        , h2 [] [ code [] [ text "TextEditor.initLikeNotepad" ] ]
        , div
            [ style "height" "12em", style "border" "1px solid black", style  "margin" "0.5em 1em" ]
            [ Html.map NotepadMsg (TextEditor.view model.notepad) ]

        , h2 [] [ code [] [ text "TextEditor.initLikeCodeEditor" ] ]
        , div
            [ style "height" "12em", style "border" "1px solid black", style  "margin" "0.5em 1em" ]
            [ Html.map EditorMsg (TextEditor.view model.editor) ]

        , h2 [] [ code [] [ text "TextEditor.initLikeModernEditor" ] ]
        , div
            [ style "height" "12em", style "border" "1px solid black", style  "margin" "0.5em 1em" ]
            [ Html.map ModernMsg (TextEditor.view model.modern) ]
        ]
