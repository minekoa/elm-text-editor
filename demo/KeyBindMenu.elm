module KeyBindMenu exposing
    ( Model
    , Msg
    , init
    , update
    , view
    )

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Char

import TextEditor.KeyBind as KeyBind
import TextEditor.Core as Core
import TextEditor.Commands as EditorCmds

type alias Model =
    { selectedSubMenu : SubMenu
    }

type SubMenu
    = EditKeybind
    | InitKeybind

type Msg
    = SelectSubMenu SubMenu



init : Model
init =
    { selectedSubMenu = EditKeybind
    }

update : Msg -> List KeyBind.KeyBind -> Model -> (List KeyBind.KeyBind, Model, Cmd Msg)
update msg keybinds model =
    case msg of
        SelectSubMenu submenu ->
            ( keybinds
            , { model | selectedSubMenu = submenu }
            , Cmd.none
            )

view : List KeyBind.KeyBind -> Model -> Html Msg
view keybinds model =
    div [ class "debugger-menu", class "menu-root"
        , style [("min-height", "17em")]
        ]
        [ menuItemsView model
        , menuPalette keybinds model
        ]

menuItemsView : Model -> Html Msg
menuItemsView model =                
    div [ class "menu-itemlist" ]
    [ div [ onClick <| SelectSubMenu EditKeybind
          , class <| if model.selectedSubMenu == EditKeybind then "menu-item-active" else "menu-item"
          ]
          [ span [] [text "Edit"]
          ]
    , div [ onClick <| SelectSubMenu InitKeybind
          , class <| if model.selectedSubMenu == InitKeybind then "menu-item-active" else "menu-item"
          ]
          [ span [] [text "Initialize"]
          ]
    ]

menuPalette : List KeyBind.KeyBind -> Model ->  Html Msg
menuPalette keybinds model =
    case model.selectedSubMenu of
        EditKeybind -> 
            div [class "menu-palette"] [ editView keybinds ]
        InitKeybind -> 
            div [class "menu-palette"] [ initView keybinds ]

editView : List KeyBind.KeyBind -> Html Msg
editView keybinds =
    div [] (List.map keybindView keybinds)


keybindView : KeyBind.KeyBind -> Html Msg
keybindView keybind =
    div [ style [("display","flex")]]
        [ div [ style [("width","10em")] ]
              [ [ if keybind.ctrl  then "Ctrl-" else ""
                , if keybind.alt   then "Alt-" else ""
                , if keybind.shift then "Shift-" else ""
                , keybind.code |> Char.fromCode |> toString
                , " ("
                , keybind.code |> toString
                , ")"
                ] |> String.concat |> text
              ]
        , div [] [ keybind.f.id |> text]
        ]




initView : List KeyBind.KeyBind -> Html Msg
initView editorModel =
    div [] []


