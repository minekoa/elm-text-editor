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
