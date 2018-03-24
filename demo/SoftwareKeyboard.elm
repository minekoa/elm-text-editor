module SoftwareKeyboard exposing
    ( Model
    , Msg
    , init
    , update
    , view
    )                       

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)

import TextEditor as Editor
import TextEditor.Commands as Commands


type alias Model =
    { mode : KeyboardMode
    }

init: Model
init =
    Model SmallLetter


type KeyboardMode
    = CapitalLetter
    | SmallLetter
    | Hiragana
    | Katakana

type Msg
    = ChangeMode KeyboardMode
    | MoveForward
    | MoveBackword
    | MovePrevios
    | MoveNext
    | Insert String
    | Backspace
    | Delete
    | Copy
    | Cut
    | Paste
    | Undo


update : Msg -> Model -> Editor.Model -> ((Model, Cmd Msg), (Editor.Model, Cmd Editor.Msg))
update msg model editor =
    case msg of
        ChangeMode mode ->
            ( ({ model | mode = mode}, Cmd.none)
            , ( editor, Cmd.none )
            )
        MoveForward ->
            ( ( model, Cmd.none)
            , Commands.moveForward editor
            )
        MoveBackword ->
            ( ( model, Cmd.none)
            , Commands.moveBackward editor
            )
        MovePrevios ->
            ( ( model, Cmd.none)
            , Commands.movePrevios editor
            )
        MoveNext ->
            ( ( model, Cmd.none)
            , Commands.moveNext editor
            )
        Insert s ->
            ( ( model, Cmd.none)
            , Commands.insert s editor
            )
        Backspace ->
            ( ( model, Cmd.none)
            , Commands.backspace editor
            )
        Delete ->
            ( ( model, Cmd.none)
            , Commands.delete editor
            )
        Copy ->
            ( ( model, Cmd.none)
            , Commands.copy editor
            )
        Cut ->
            ( ( model, Cmd.none)
            , Commands.cut editor
            )
        Paste ->
            ( ( model, Cmd.none)
            , Commands.paste editor
            )
        Undo ->
            ( ( model, Cmd.none)
            , Commands.undo editor
            )

view : Model -> Html Msg
view model =
    div [ class "software_keyboard"
        , style []
        ]
        [ keyboardSwitcher model
        , mainkey model
        , editcmdkey model
        ]

keyboardSwitcher: Model -> Html Msg
keyboardSwitcher model =
    div [ class "kbd_switcher"
        , style []
        ]
        [ div [ class   <| if model.mode == CapitalLetter then "kbd_button_active" else "kbd_button"
              , onClick <| ChangeMode CapitalLetter
              ]
              [ text "A" ]
        , div [ class   <| if model.mode == SmallLetter then "kbd_button_active" else "kbd_button"
              , onClick <| ChangeMode SmallLetter
              ]
              [ text "a" ]
        , div [ class   <| if model.mode == Hiragana then "kbd_button_active" else "kbd_button"
              , onClick <| ChangeMode Hiragana
              ]
              [ text "あ" ]
        , div [ class   <| if model.mode == Katakana then "kbd_button_active" else "kbd_button"
              , onClick <| ChangeMode Katakana
              ]
              [ text "ア" ]
        ]

mainkey: Model -> Html Msg
mainkey model =
    case model.mode of
        CapitalLetter ->
            capitalKeys model
        SmallLetter ->
            smallKeys model
        Hiragana ->
            hiraganaKeys model
        Katakana ->
            katakanaKeys model

capitalKeys : Model -> Html Msg
capitalKeys model =
    div [ class "kbd_mainkey" ]
        [ div [class "kbd_mainkey_row"] [     key "!", key "@", key "#", key "$", key "%", key "^", key "&", key "*", key "(", key ")", key "_", key "+", backspaceKey ]
        , div [class "kbd_mainkey_row"] [ pad 1, key "Q", key "W", key "E", key "R", key "T", key "Y", key "U", key "I", key "O", key "P", key "{", key "}", key "|" ]
        , div [class "kbd_mainkey_row"] [ pad 2,    key "A", key "S", key "D", key "F", key "G", key "H", key "J", key "K", key "L", key ":", key "\"" , enterKey]
        , div [class "kbd_mainkey_row"] [ tabKey,       key "Z", key "X", key "C", key "V", key "B", key "N", key "M", key "<", key ">", key "?", key "~" ]
        , div [class "kbd_mainkey_row"] [ pad 8
                                        , spaceKey
                                        , pad 2
                                        , div [ class "kbd_key", onClick MoveBackword, style [ ("width", "1.5em") ] ] [ text "←" ]
                                        , div [ class "kbd_key", onClick MovePrevios , style [ ("width", "1.5em") ] ] [ text "↑" ]
                                        , div [ class "kbd_key", onClick MoveNext    , style [ ("width", "1.5em") ] ] [ text "↓" ]
                                        , div [ class "kbd_key", onClick MoveForward , style [ ("width", "1.5em") ] ] [ text "→" ]
                                        ]
        ]

smallKeys : Model -> Html Msg
smallKeys model =
    div [ class "kbd_mainkey" ]
        [ div [class "kbd_mainkey_row"] [     key "1", key "2", key "3", key "4", key "5", key "6", key "7", key "8", key "9", key "0", key "-", key "=", backspaceKey]
        , div [class "kbd_mainkey_row"] [ pad 1, key "q", key "w", key "e", key "r", key "t", key "y", key "u", key "i", key "o", key "p", key "[", key "]", key "\\" ]
        , div [class "kbd_mainkey_row"] [ pad 2,    key "a", key "s", key "d", key "f", key "g", key "h", key "j", key "k", key "l", key ";", key "'" , enterKey]
        , div [class "kbd_mainkey_row"] [ tabKey,       key "z", key "x", key "c", key "v", key "b", key "n", key "m", key ",", key ".", key "/", key "`" ]
        , div [class "kbd_mainkey_row"] [ pad 8
                                        , spaceKey
                                        , pad 2
                                        , div [ class "kbd_key", onClick MoveBackword, style [ ("width", "1.5em") ] ] [ text "←" ]
                                        , div [ class "kbd_key", onClick MovePrevios , style [ ("width", "1.5em") ] ] [ text "↑" ]
                                        , div [ class "kbd_key", onClick MoveNext    , style [ ("width", "1.5em") ] ] [ text "↓" ]
                                        , div [ class "kbd_key", onClick MoveForward , style [ ("width", "1.5em") ] ] [ text "→" ]
                                        ]
        ]

hiraganaKeys : Model -> Html Msg
hiraganaKeys model =
    div [ class "kbd_mainkey" ]
        [ div [class "kbd_mainkey_row"] [key "あ", key "い", key "う", key "え", key "お", pad 0.5, key "な", key "に", key "ぬ", key "ね", key "の", pad 0.5, key "や", key "ゆ", key "よ"]
        , div [class "kbd_mainkey_row"] [key "か", key "き", key "く", key "け", key "こ", pad 0.5, key "は", key "ひ", key "ふ", key "へ", key "ほ", pad 0.5, key "わ", key "ん", key "ー"]
        , div [class "kbd_mainkey_row"] [key "さ", key "し", key "す", key "せ", key "そ", pad 0.5, key "ま", key "み", key "む", key "め", key "も", pad 0.5, key "、", pad 0.5, backspaceKey]
        , div [class "kbd_mainkey_row"] [key "た", key "ち", key "つ", key "て", key "と", pad 0.5, key "ら", key "り", key "る", key "れ", key "ろ", pad 0.5, key "。", pad 0.5,enterKey]
        , div [class "kbd_mainkey_row"] [ pad 8
                                        , zenkakuSpaceKey
                                        , pad 2
                                        , div [ class "kbd_key", onClick MoveBackword, style [ ("width", "1.5em") ] ] [ text "←" ]
                                        , div [ class "kbd_key", onClick MovePrevios , style [ ("width", "1.5em") ] ] [ text "↑" ]
                                        , div [ class "kbd_key", onClick MoveNext    , style [ ("width", "1.5em") ] ] [ text "↓" ]
                                        , div [ class "kbd_key", onClick MoveForward , style [ ("width", "1.5em") ] ] [ text "→" ]
                                        ]
        ]

katakanaKeys : Model -> Html Msg
katakanaKeys model =
    div [ class "kbd_mainkey" ]
        [ div [class "kbd_mainkey_row"] [key "ア", key "イ", key "ウ", key "エ", key "オ", pad 0.5, key "ナ", key "ニ", key "ヌ", key "ネ", key "ノ", pad 0.5, key "ヤ", key "ユ", key "ヨ"]
        , div [class "kbd_mainkey_row"] [key "カ", key "キ", key "ク", key "ケ", key "コ", pad 0.5, key "ハ", key "ヒ", key "フ", key "ヘ", key "ホ", pad 0.5, key "ワ", key "ン", key "ー"]
        , div [class "kbd_mainkey_row"] [key "サ", key "シ", key "ス", key "セ", key "ソ", pad 0.5, key "マ", key "ミ", key "ム", key "メ", key "モ", pad 0.5, key "、", pad 0.5, backspaceKey]
        , div [class "kbd_mainkey_row"] [key "タ", key "チ", key "ツ", key "テ", key "ト", pad 0.5, key "ラ", key "リ", key "ル", key "レ", key "ロ", pad 0.5, key "。", pad 0.5,enterKey]
        , div [class "kbd_mainkey_row"] [ pad 8
                                        , zenkakuSpaceKey
                                        , pad 2
                                        , div [ class "kbd_key", onClick MoveBackword, style [ ("width", "1.5em") ] ] [ text "←" ]
                                        , div [ class "kbd_key", onClick MovePrevios , style [ ("width", "1.5em") ] ] [ text "↑" ]
                                        , div [ class "kbd_key", onClick MoveNext    , style [ ("width", "1.5em") ] ] [ text "↓" ]
                                        , div [ class "kbd_key", onClick MoveForward , style [ ("width", "1.5em") ] ] [ text "→" ]
                                        ]
        ]


editcmdkey : Model -> Html Msg
editcmdkey model =
    div [ class "kbd_editcmd" ]
        [ div [ class "kbd_button"
              , onClick Undo
              ]
              [ text "undo"]
        , div [ class "kbd_button"
              , onClick Delete
              ]
              [ text "Del"]
        , div [ class "kbd_button"
              , onClick Cut
              ]
              [ text "cut"]
        , div [ class "kbd_button"
              , onClick Copy
              ]
              [ text "copy"]
        , div [ class "kbd_button"
              , onClick Paste
              ]
              [ text "paste"]
        ]

key : String -> Html Msg
key s =
    div [ class "kbd_key"
        , onClick <| Insert s
        , style [ ("width", "1.5em") ]
        ]
        [ text s ]

enterKey: Html Msg
enterKey =
    div [ class "kbd_key"
        , onClick <| Insert "\n"
        , style [ ("width", 1.5 * 1.5 |> toString |> flip (++) "em") ]
        ]
        [ text "⏎" ]

backspaceKey: Html Msg
backspaceKey =
    div [ class "kbd_key"
        , onClick <| Backspace
        , style [ ("width", 1.5 * 1.5 |> toString |> flip (++) "em") ]
        ]
        [ text "BS" ]

tabKey : Html Msg
tabKey =
    div [ class "kbd_key"
        , onClick <| Insert "\t"
        , style [ ("width", 1.5 * 1.5 |> toString |> flip (++) "em") ]
        ]
        [ text "tab" ]

spaceKey : Html Msg
spaceKey =
    div [ class "kbd_key"
        , onClick <| Insert " "
        , style [ ("width", "6em") ]
        ]
        [ text "space" ]

zenkakuSpaceKey : Html Msg
zenkakuSpaceKey =
    div [ class "kbd_key"
        , onClick <| Insert "　"
        , style [ ("width", "6em") ]
        ]
        [ text "スペース" ]



pad : Float -> Html msg
pad n =
    div [ class "kbd_pad"
        , style [ ("width",  n * 0.5 * 1.5 |> toString |> flip (++) "em") ]
        ]
        []

            
