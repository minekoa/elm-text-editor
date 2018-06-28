# Elm TextEditor

It is a simple text editor widget made with Elm. You can see it [here](https://minekoa.github.io/elm-text-editor).

There are the following advantages for textarea.

* Line number is displayed
* You can set your favorite key binding (however, as the browser allows it. For example, you can not change the key binding for access to the clipboard)
* Operation from Elm is easy to do
* Control code display (for example, line feed code, tab character, etc.)

The following does not correspond (yet).

* Syntax highlight


## Browser support

We use the following API, so it will not work on browsers that do not support it.

* [CompositionEvent](https://developer.mozilla.org/en-US/docs/Web/API/CompositionEvent)
* [ClipboardEvent](https://developer.mozilla.org/en-US/docs/Web/API/ClipboardEvent)
* [focusin](https://developer.mozilla.org/en-US/docs/Web/Events/focusin) / [focusout](https://developer.mozilla.org/en-US/docs/Web/Events/focusout) event

## How to use

It is used as follows:

```Elm
import TextEditor
import TextEditor.KeyBind

type alias FooModel =
    { editor : TextEditor.Model }

type FooMsg
    = EditorMsg (TextEditor.Msg)

main : Program Never Model Msg
main =
    Html.program
        { init = init
        , view = view
        , subscriptions = subscriptions
        , update = update
        }

init : (FooModel, Cmd FooMsg)
init =
    let
        (m, c) = Editor.init 
                     "editor-id1" 
                     (TextEditor.KeyBind.basic ++ TextEditor.KeyBind.gates ++ TextEditor.KeyBind.emacsLike)
                     "foobar hogehoge"
    in
        ( FooModel m
        , Cmd.map EditorMsg c
        )

update : FooMsg -> FooModel -> (FooModel, Cmd FooMsg)
update msg model =
    case msg of
        EditorMsg edmsg ->
            let
                (m, c) = TextEditor.update edmsg model.editor
            in
                ( { model | editor = m}, Cmd.map EditorMsg c)

subscriptions : FooModel -> Sub FooMsg
subscriptions model =
    Sub.map EditorMsg (TextEditor.subscriptions model.editor)

view : FooModel -> Html FooMsg
view model =
    div [] [ Html.map EditorMsg (TextEditor.view model.editor) ]
```


