module Main exposing (..)

import TextEditor
import TextEditor.KeyBind
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


init : ( Model, Cmd Msg )
init =
    let
        ( m, c ) =
            (TextEditor.init
                "editor-id1"
                (TextEditor.KeyBind.basic ++ TextEditor.KeyBind.gates ++ TextEditor.KeyBind.emacsLike)
                "foobar hogehoge"
            ) |> (\(m,c) ->
                      let
                          sty = m.style
                      in
                          ( { m | style =
                                { sty | common = Just { color="snow", backgroundColor="dimgray", opacity="", fontFamily="monospace", fontSize="1.2em"} }
                            }
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
                        ( { model | editor = m , contents = contents }, Cmd.map EditorMsg c )
                    _ ->
                        ( { model | editor = m }, Cmd.map EditorMsg c )


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.map EditorMsg (TextEditor.subscriptions model.editor)


view : Model -> Html Msg
view model =
    div [ style [ ("display", "flex")
                , ("width", "100%")
                , ("height", "100%")
                ]
        ] 
        [ div [ style [("height", "100%"), ("width", "50%")] ] [ Html.map EditorMsg (TextEditor.view model.editor) ]
        , div [ style [("height", "100%"), ("width", "50%")] ] [ Markdown.toHtmlWith markdownOptions [class "md"] (String.join "\n" model.contents) ]
        ]




markdownOptions: Markdown.Options
markdownOptions =
  { githubFlavored = Just { tables = True, breaks = True }
  , defaultHighlighting = Nothing
  , sanitize = False
  , smartypants = False
  }

