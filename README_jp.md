# Elm TextEditor

Elmで作られたシンプルなテキストエディタウィジェットです。[ここ](https://minekoa.github.io/elm-text-editor)で見てみることが出来ます。

textareaに対して以下の利点があります。

* 行番号が表示されます
* お好きなキーバインドを設定できます（ただし、ブラウザが許す範囲で。例えば、クリップボードへのアクセスは、キーバインドを変更できません）
* Elm からの操作がやりやすいです
* 制御コードの表示（例えば改行コードやタブ文字など）

以下は（まだ）対応していません。

* シンタックスハイライト

## ブラウザサポート

以下のAPIを使用してますので、サポートしていないブラウザでは動作しません。

* [CompositionEvent](https://developer.mozilla.org/en-US/docs/Web/API/CompositionEvent)
* [ClipboardEvent](https://developer.mozilla.org/en-US/docs/Web/API/ClipboardEvent)
* [focusin](https://developer.mozilla.org/en-US/docs/Web/Events/focusin) / [focusout](https://developer.mozilla.org/en-US/docs/Web/Events/focusout) event


## 使い方

こんな感じで使用します

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

