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
    """# Markdown editor

## Bullet

* lv1
* lv1
    * lv2
        * lv3


1. lv1
2. lv1
   1. lv2

## Paragraph

abcd efg
nhijk lmn

    opqr stu

> vw
xyz

```
toDiviaablePhrase = λ divi phr (n, s) ->
    case n % divi of
        0 -> (n, s |> Maybe.withDefault "" |> flip (++) phr)
        _ -> (n, s)

toFizz = toDiviaablePhrase 3 "Fizz"
toBuzz = toDiviaablePhrase 5 "Buzz"

toFizzBuzz = List.map <|
                 (λn -> (n, Nothing))
                     >> toFizz >> toBuzz 
                     >> λ(n,s) -> Maybe.withDefault (toString n) s

view : Model -> Html msg
view model =
    div [] [ List.range 1 100
               |> toFizzBuzz
               |> String.join ", "
               |> text
           ]
```

## Table

|果物   |個数|
|-------|----|
|りんご |1   |
|ばなな!|∞  |

"""

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
        , div [ style [ ( "height", "100%" ), ( "width", "50%" ), ("overflow","auto") ] ] [ Markdown.toHtmlWith markdownOptions [ class "md" ] (String.join "\n" model.contents) ]
        ]


markdownOptions : Markdown.Options
markdownOptions =
    { githubFlavored = Just { tables = True, breaks = True }
    , defaultHighlighting = Nothing
    , sanitize = False
    , smartypants = False
    }
