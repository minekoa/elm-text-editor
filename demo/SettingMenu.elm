module SettingMenu exposing
    ( Model
    , Msg
    , init
    , update
    , subscriptions
    , view
    )

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Json.Encode
import Json.Decode

import TextEditor.Option
import Ports.WebStrage as WebStrage


type alias Model =
    { options : TextEditor.Option.Option
    , selectedSubMenu : SubMenu
    }

type SubMenu
    = RenderingOptionMenu

init : TextEditor.Option.Option -> (Model, Cmd Msg)
init core_opts =
    ( { options         = core_opts
      , selectedSubMenu = RenderingOptionMenu
      }
    , WebStrage.localStrage_getItem "core.option"
    )

------------------------------------------------------------
-- update
------------------------------------------------------------

type Msg
    = LoadSetting (String, Maybe String)
    | SelectSubMenu SubMenu
    | ChangeShowCtrlChar Bool
    | ChangeTabOrder Int
    | ChangeIndentTabs Bool

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
    let
        core_opts = model.options
    in
        case msg of
            LoadSetting ("core.option", maybe_value) ->
                ( maybe_value
                    |> Result.fromMaybe "value is nothing"
                    |> Result.andThen (Json.Decode.decodeString decodeEditorOptions)
                    |> Result.withDefault core_opts
                    |> (\new_opts -> { model | options = new_opts })
                , Cmd.none
                )
            LoadSetting _ ->
                ( model, Cmd.none )

            SelectSubMenu s ->
                ( { model
                      | selectedSubMenu = s
                  }
                , Cmd.none
                )

            ChangeShowCtrlChar b ->
                let
                    new_opts = { core_opts | showControlCharactor = b }
                in
                    ( { model | options = new_opts }
                    , WebStrage.localStrage_setItem ("core.option"
                                                    , new_opts |> encodeEditorOptions |> Json.Encode.encode 0
                                                    )
                    )

            ChangeTabOrder i ->
                let
                    new_opts = { core_opts | tabOrder = i }
                in
                    ( { model | options = new_opts }
                    , WebStrage.localStrage_setItem ("core.option"
                                                    , new_opts  |> encodeEditorOptions |> Json.Encode.encode 0
                                                    )
                    )

            ChangeIndentTabs b ->
                let
                    new_opts = { core_opts | indentTabsMode = b }
                in
                    ( { model | options = new_opts }
                    , WebStrage.localStrage_setItem ("core.option"
                                                    , new_opts |> encodeEditorOptions |> Json.Encode.encode 0
                                                    )
                    )

------------------------------------------------------------
-- Subscriptions
------------------------------------------------------------

subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch [ WebStrage.localStrage_getItemEnded LoadSetting
              ]


------------------------------------------------------------
-- view
------------------------------------------------------------

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


renderingOptionView : TextEditor.Option.Option -> Html Msg
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


------------------------------------------------------------
-- encode / decode for save local strage
------------------------------------------------------------

encodeEditorOptions : TextEditor.Option.Option -> Json.Encode.Value
encodeEditorOptions core_opts =
    Json.Encode.object 
        [ ("tabOrder"            , core_opts.tabOrder |> Json.Encode.int)
        , ("indentTabsMode"      , core_opts.indentTabsMode  |> Json.Encode.bool)
        , ("showControlCharactor", core_opts.showControlCharactor |> Json.Encode.bool)
        ]

decodeEditorOptions : Json.Decode.Decoder TextEditor.Option.Option
decodeEditorOptions =
    Json.Decode.map3
        TextEditor.Option.Option
            (Json.Decode.field "tabOrder"             Json.Decode.int)
            (Json.Decode.field "indentTabsMode"       Json.Decode.bool)
            (Json.Decode.field "showControlCharactor" Json.Decode.bool)

