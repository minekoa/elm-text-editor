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

## Installation


This package is used because it contains `Native` module (≒ JavaScript ffi) for IME control, cursor position calculation, scroll control. Therefore, `elm-package install` can not be used.

Please use `elm-github-installer` instead.

[elm-github-installer](https://github.com/gdotdesign/elm-github-install)

After installing `elm-github-installer`, please modify your` elm-package.json` as follows.

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

Then execute the following command

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

## How to use

It is used as follows:

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
            TextEditor.init
                "editor-id1"
                (TextEditor.KeyBind.basic ++ TextEditor.KeyBind.gates ++ TextEditor.KeyBind.emacsLike)
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


