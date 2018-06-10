module SettingMenu exposing
    ( Model
    , Msg
    , init
    , update
    , view
    )

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)

import TextEditor.Core


type alias Model =
    { options : TextEditor.Core.Option
    , selectedSubMenu : SubMenu
    }

type SubMenu
    = RenderingOptionMenu

init : TextEditor.Core.Option -> Model
init core_opts =
    { options         = core_opts
    , selectedSubMenu = RenderingOptionMenu
    }

type Msg
    = SelectSubMenu SubMenu
    | ChangeShowCtrlChar Bool
    | ChangeTabOrder Int
    | ChangeIndentTabs Bool

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
    let
        core_opts = model.options
    in
        case msg of
            SelectSubMenu s ->
                ( { model
                      | selectedSubMenu = s
                  }
                , Cmd.none
                )

            ChangeShowCtrlChar b ->
                ( { model
                      | options = { core_opts | showControlCharactor = b }
                  }
                , Cmd.none
                )
            ChangeTabOrder i ->
                ( { model
                      | options = { core_opts | tabOrder = i }
                  }
                , Cmd.none
                )

            ChangeIndentTabs b ->
                ( { model
                      | options = { core_opts | indentTabsMode = b }
                  }
                , Cmd.none
                )

view : Model -> Html Msg
view model =
    div [ class "setting-menu", class "menu-root"
        , style [("min-height", "17em")]
        ]
        [ menuItemsView model
        , menuPalette model
        ]

menuItemsView : Model -> Html Msg
menuItemsView model =                
    div [ class "menu-itemlist" ]
    [ div [ onClick <| SelectSubMenu RenderingOptionMenu
          , class <| if model.selectedSubMenu == RenderingOptionMenu then "menu-item-active" else "menu-item"
          ]
          [ span [] [text "Rendering Options"]
          ]
    ]


menuPalette : Model ->  Html Msg
menuPalette model =
    case model.selectedSubMenu of
        RenderingOptionMenu -> 
            div [class "menu-palette"] [ renderingOptionView model.options ]


renderingOptionView : TextEditor.Core.Option -> Html Msg
renderingOptionView core_opts =
    div []
        [ boolSettingControl "show ctrl charactor" ChangeShowCtrlChar core_opts.showControlCharactor
        , intOptionSettingControl "tab order"      ChangeTabOrder     [2, 4, 8, 16] core_opts.tabOrder
        , boolSettingControl "indent tabs mode"    ChangeIndentTabs   core_opts.indentTabsMode
        ]

boolSettingControl : String -> (Bool -> msg) -> Bool -> Html msg
boolSettingControl label tagger value =
    div [ class "settingmenu-option"]
        [ div [ class "settingmenu-option-label" ] [ text label ]
        , div [ class "settingmenu-option-control"]
              [ div [ class <| if value then "setting-option-value-active"
                                        else "setting-option-value-disactive"
                    , onClick <| tagger (not value)
                    ]
                    [ value |> toString |> text ]
              ]
        ]

intOptionSettingControl : String -> (Int -> msg) -> List Int -> Int -> Html msg
intOptionSettingControl label tagger opts value =
    div [ class "settingmenu-option"]
        [ div [ class "settingmenu-option-label" ] [ text label ]
        , div [ class "settingmenu-option-control"]
              ( opts
                  |> List.map (\i -> 
                                   div [ class <| if value == i then "setting-option-value-active"
                                                                else "setting-option-value-disactive"
                                       , onClick <| tagger i
                                       ]
                                       [ i |> toString |> text ]
                              )
              )
        ]

