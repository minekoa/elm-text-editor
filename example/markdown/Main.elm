module Main exposing (..)

import TextEditor
import TextEditor.KeyBind
import TextEditor.Style
import TextEditor.Option
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Markdown


type alias Model =
    { editor : TextEditor.Model
    , contents : List String
    }


type Msg
    = EditorMsg TextEditor.Msg


main : Program Never Model Msg
main =
    Html.program
        { init = init
        , view = view
        , subscriptions = subscriptions
        , update = update
        }


defaultText : String
defaultText =
    "# Realtime markdown editor (expampke)\n\n* lv1\n* lv1\n    * lv2\n\nabcd efg \nhijk lmn\n\n    opqr stu\n\n> vw\nxyz\n\n```\n01234 567\n```\n\n|果物|個数|\n|----|----|\n|りんご|1|\n|ばなな!|∞|\n"


styleSetting : TextEditor.Style.Style -> TextEditor.Style.Style
styleSetting sty =
    { sty
        | common =
            Just
                { color = "snow"
                , backgroundColor = "dimgray"
                , opacity = ""
                , fontFamily = "monospace"
                , fontSize = "1.2em"
                }
    }


optionSetting : TextEditor.Option.Option -> TextEditor.Option.Option
optionSetting opt =
    { opt
        | showControlCharactor = True
    }


init : ( Model, Cmd Msg )
init =
    let
        ( m, c ) =
            (TextEditor.init
                "editor-id1"
                (TextEditor.KeyBind.basic ++ TextEditor.KeyBind.gates ++ TextEditor.KeyBind.emacsLike)
                defaultText
            )
                |> (\( m, c ) ->
                        ( { m | style = styleSetting m.style }
                            |> \m -> TextEditor.setOptions (optionSetting (TextEditor.options m)) m
                        , c
                        )
                   )
    in
        ( Model m (TextEditor.buffer m).contents
        , Cmd.map EditorMsg c
        )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        EditorMsg edmsg ->
            let
                ( m, c ) =
                    TextEditor.update edmsg model.editor
            in
                case edmsg of
                    TextEditor.UpdateContents contents ->
                        ( { model | editor = m, contents = contents }, Cmd.map EditorMsg c )

                    _ ->
                        ( { model | editor = m }, Cmd.map EditorMsg c )


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.map EditorMsg (TextEditor.subscriptions model.editor)


view : Model -> Html Msg
view model =
    div
        [ style
            [ ( "display", "flex" )
            , ( "width", "100%" )
            , ( "height", "100%" )
            ]
        ]
        [ div [ style [ ( "height", "100%" ), ( "width", "50%" ) ] ] [ Html.map EditorMsg (TextEditor.view model.editor) ]
        , div [ style [ ( "height", "100%" ), ( "width", "50%" ) ] ] [ Markdown.toHtmlWith markdownOptions [ class "md" ] (String.join "\n" model.contents) ]
        ]


markdownOptions : Markdown.Options
markdownOptions =
    { githubFlavored = Just { tables = True, breaks = True }
    , defaultHighlighting = Nothing
    , sanitize = False
    , smartypants = False
    }
