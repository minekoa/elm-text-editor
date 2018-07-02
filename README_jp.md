# Elm TextEditor

Elmで作られたシンプルなテキストエディタウィジェットです。[ここ](https://minekoa.github.io/elm-text-editor/demo/)で見てみることが出来ます。
(Exampleは[こちら](https://minekoa.github.io/elm-text-editor/example/))

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

## インストール方法

このパッケージは、IMEの制御やクリップボードへのアクセス、カーソル位置の計算、スクロール制御に Native モジュール(≒JavaScript ffi) を含むため使用しています。
そのため、`elm-package install` は使えません。

代わりに `elm-github-install` を使用してください。

[elm-github-install](https://github.com/gdotdesign/elm-github-install)


`elm-github-install` をインストールしたら、あなたの `elm-package.json` を以下のように修正してください。

```json
    "dependencies": {
        "elm-lang/core": "5.1.1 <= v < 6.0.0",
        "elm-lang/html": "2.0.0 <= v < 3.0.0",
        "minekoa/elm-text-editor": "1.0.0 <= v < 2.0.0"
    },
    "dependency-sources": {
        "minekoa/elm-text-editor": {
            "url": "git@github.com:minekoa/elm-text-editor",
            "ref": "master"
        }
    },
```

そして、以下のコマンドを実行します

```console
$ elm-install 
Resolving packages...
  ▶ Package: https://github.com/elm-lang/core not found in cache, cloning...
  ▶ Package: https://github.com/elm-lang/html not found in cache, cloning...
  ▶ Package: https://github.com/elm-lang/virtual-dom not found in cache, cloning...
  ▶ Package: git@github.com:minekoa/elm-text-editor not found in cache, cloning...
  ▶ Package: https://github.com/elm-lang/mouse not found in cache, cloning...
  ▶ Package: https://github.com/elm-lang/dom not found in cache, cloning...
Solving dependencies...
  ● elm-lang/core - https://github.com/elm-lang/core (5.1.1)
  ● elm-lang/html - https://github.com/elm-lang/html (2.0.0)
  ● minekoa/elm-text-editor - git@github.com:minekoa/elm-text-editor at master (1.0.0)
  ● elm-lang/mouse - https://github.com/elm-lang/mouse (1.0.1)
  ● elm-lang/dom - https://github.com/elm-lang/dom (1.1.1)
  ● elm-lang/virtual-dom - https://github.com/elm-lang/virtual-dom (2.0.4)
Packages configured successfully!
```


## 使い方

こんな感じで使用します

```elm
module Main exposing (..)

import TextEditor
import TextEditor.KeyBind
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)


type alias Model =
    { editor : TextEditor.Model }


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
            TextEditor.initLikeNotepad
                "editor-id1"
                "foobar hogehoge"
    in
        ( Model m
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
                ( { model | editor = m }, Cmd.map EditorMsg c )


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.map EditorMsg (TextEditor.subscriptions model.editor)


view : Model -> Html Msg
view model =
    div [] [ Html.map EditorMsg (TextEditor.view model.editor) ]
```

