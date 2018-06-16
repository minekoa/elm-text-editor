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



