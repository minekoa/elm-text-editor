module StyleSetter exposing
    ( Model
    , init
    , Msg
    , update
    , view
    )

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Json.Decode as Json

type alias Model =
    { bgColor : SelectableList
    , fgColor : SelectableList
    , fontFamily : SelectableList
    , fontSize : SelectableList

    , editTarget : EditTarget
    }

type alias SelectableList =
    { value : String
    , list : List String
    }
        
type EditTarget
   = EditColor      String (String -> Msg) SelectableList
   | EditFontFamily String (String -> Msg) SelectableList
   | EditFontSize   String (String -> Msg) SelectableList

targetName : EditTarget -> String
targetName target =
    case target of
        EditColor s _ _ -> s
        EditFontFamily s _ _ -> s
        EditFontSize s _ _ -> s

init: Model
init =
    Model
    initBgColor
    initFgColor
    initFontFamily
    initFontColor
    (EditColor "bg-color" ChangeBGColor initBgColor)

initBgColor : SelectableList
initBgColor = { value = "inherit", list = ["inherit", "black", "white", "linen", "dimgray", "whitesmoke", "midnightblue", "darkolivegreen", "aquamarine", "beige", "mediumvioletred", "darkslategray", "lavender"] }

initFgColor : SelectableList
initFgColor = { value = "inherit", list = ["inherit", "black", "white", "aqua", "coral", "midnightblue", "darkslategray", "ghostwhite", "lavender", "palevioletred", "darkmagenta", "moccasin", "rosybrown"] }

initFontFamily : SelectableList
initFontFamily = { value = "inherit", list = ["inherit", "cursive", "fantasy", "monospace", "sans-serif", "serif"] }

initFontColor : SelectableList
initFontColor = { value = "inherit", list = ["inherit", "0.5em", "1em", "1.2em", "1.5em", "2em", "3em", "5em", "7em", "10em"] }


type Msg
    = ChangeBGColor String
    | ChangeFGColor String
    | ChangeFontFamily String
    | ChangeFontSize String
    | TouchBackgroundColor
    | TouchForegroundColor
    | TouchFontSize
    | TouchFontFalily


update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
    case msg of
        ChangeBGColor s ->
            let
                bgColor = model.bgColor
            in
                ( { model
                      | bgColor    = { bgColor | value = s }
                      , editTarget = EditColor "bg-color" ChangeBGColor { bgColor | value = s }
                  }
                , Cmd.none
                )
        ChangeFGColor s ->
            let
                fgColor = model.fgColor
            in
                ( { model
                      | fgColor    = { fgColor | value = s }
                      , editTarget = EditColor "fg-color" ChangeFGColor { fgColor | value = s }
                  }
                , Cmd.none
                )
        ChangeFontFamily s ->
            let
                fontFamily = model.fontFamily
            in
                ( { model
                      | fontFamily = { fontFamily | value = s }
                      , editTarget = EditFontFamily "font-family" ChangeFontFamily { fontFamily | value = s }
                  }
                , Cmd.none
                )
        ChangeFontSize s ->
            let
                fontSize = model.fontSize
            in
                ( { model
                      | fontSize = { fontSize | value = s }
                      , editTarget = EditFontSize "font-size" ChangeFontSize { fontSize | value = s }
                  }
                , Cmd.none
                )

        TouchBackgroundColor ->
            ( { model
                  | editTarget = EditColor "bg-color" ChangeBGColor model.bgColor
              }
            , Cmd.none
            )
        TouchForegroundColor ->
            ( { model
                  | editTarget = EditColor "fg-color" ChangeFGColor model.fgColor
              }
            , Cmd.none
            )
        TouchFontFalily ->
            ( { model
                  | editTarget = EditFontFamily "font-family" ChangeFontFamily model.fontFamily
              }
            , Cmd.none
            )
        TouchFontSize ->
            ( { model
                  | editTarget = EditFontSize "font-size" ChangeFontSize model.fontSize
              }
            , Cmd.none
            )



view : Model -> Html Msg
view model =
    div [ class "style-setter", class "menu-root"
        , style [ ("flex-grow", "2")
                , ("min-height", "17em")
                ]
        ]
        [ div [ class "menu-itemlist" ]
              [ div [ onClick TouchBackgroundColor
                    , class <| if targetName model.editTarget == "bg-color" then "menu-item-active" else "menu-item"
                    ]
                    [ span [] [text "background-color: "]
                    , span [] [text model.bgColor.value ]
                    ]
              , div [ onClick TouchForegroundColor
                    , class <| if targetName model.editTarget == "fg-color" then "menu-item-active" else "menu-item"
                    ]
                    [ span [] [text "color: "]
                    , span [] [text model.fgColor.value ]
                    ]
              , div [ onClick TouchFontFalily
                    , class <| if targetName model.editTarget == "font-family" then "menu-item-active" else "menu-item"
                    ]
                    [ span [] [text "font-family: "]
                    , span [] [text model.fontFamily.value ]
                    ]
              , div [ onClick TouchFontSize
                    , class <| if targetName model.editTarget == "font-size" then "menu-item-active" else "menu-item"
                    ]
                    [ span [] [text "font-size: "]
                    , span [] [text model.fontSize.value ]
                   ]
              ]
        , case model.editTarget of
            EditColor _ tagger list ->
                colorPalette tagger list
            EditFontFamily _ tagger list ->
                fontFamilySelector tagger list
            EditFontSize _ tagger list ->
                fontSizeSelector tagger list
        ]

colorPalette : (String -> Msg) -> SelectableList -> Html Msg
colorPalette tagger colorList =
    div [ class "menu-palette"
        , style [ ("flex-grow", "1"), ("display", "flex"), ("align-content", "flex-start"), ("flex-wrap","wrap")
                ]
        ] <|
        List.map (\ color ->
                      div [ class <|
                                if color == colorList.value
                                then "color-palette-item-active"
                                else "color-palette-item"
                          , style [ ("display", "flex"), ("flex-directipn", "column") ]
                          , onClick <| tagger color
                          ]
                          [ div [ style [ ("width", "1em"), ("height", "1em"), ("background-color", color), ("border", "1px solid black") ]
                                ]
                                []
                          , div [ style [ ("padding-left", "0.5em") ]
                                ]
                                [ text color
                                ]
                          ]
                 ) colorList.list

fontFamilySelector : (String -> Msg) -> SelectableList -> Html Msg
fontFamilySelector tagger fontList =
    div [ class "menu-palette"
        , style [ ("flex-grow", "1"), ("display", "flex"), ("flex-direction", "row"), ("flex-wrap","no-wrap")
                ]
        ] <|
        List.map (\ font ->
                      div [ class <|
                                if font == fontList.value
                                then "font-palette-item-active"
                                else "font-palette-item"
                          , style [ ("height", "2em"), ("size", "2em"), ("font-family", font), ("width", "100%")]
                          , onClick <| tagger font
                          ]
                          [ text font
                          ]
                 ) fontList.list

fontSizeSelector : (String -> Msg) -> SelectableList -> Html Msg
fontSizeSelector tagger fontsizeList =
    div [ class "style-palette"
        , style [ ("flex-grow", "1"), ("display", "flex"), ("flex-direction", "row"), ("flex-wrap","no-wrap")
                ]
        ] <|
        List.map (\ fontsize ->
                      div [ class <|
                                if fontsize == fontsizeList.value
                                then "font-palette-item-active"
                                else "font-palette-item"
                          , style [ ("font-size", fontsize), ("width", "100%") ]
                          , onClick <| tagger fontsize
                          ]
                          [ text fontsize
                          ]
                 ) fontsizeList.list



        
selectList: String -> List String -> (String -> msg) -> Html msg
selectList idx values tagger =
    select [on "change" (Json.map tagger (Json.at ["target","value"] Json.string))]
        ( List.map
              (\ v -> option
                   [ value v , selected (idx == v)]
                   [ text v ]
              ) values
        )

