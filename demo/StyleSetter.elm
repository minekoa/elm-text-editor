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
    { bgColor : { index : String, list : List String }
    , fgColor : { index : String, list : List String }
    , fontFamily : { index : String, list : List String }
    , fontSize : { index : String, list : List String }

    , editTarget : EditTarget
    }

type EditTarget
   = EditColor      String (String -> Msg) (List String)
   | EditFontFamily String (String -> Msg) (List String)
   | EditFontSize   String (String -> Msg) (List String)


targetName : EditTarget -> String
targetName target =
    case target of
        EditColor s _ _ -> s
        EditFontFamily s _ _ -> s
        EditFontSize s _ _ -> s

init: Model
init =
    Model
    { index = "inherit", list = ["inherit", "black", "white", "linen", "dimgray", "whitesmoke", "midnightblue", "darkolivegreen", "darkslategray", "lavender"] }
    { index = "inherit", list = ["inherit", "black", "white", "aqua", "coral", "midnightblue", "darkslategray", "lavender", "palevioletred", "rosybrown"] }
    { index = "inherit", list = ["inherit", "cursive", "fantasy", "monospace", "sans-serif", "serif"] }
    { index = "inherit", list = ["inherit", "0.5em", "1em", "1.5em", "2em", "3em", "5em", "7em", "10em"] }
    (EditColor "bg-color" ChangeBGColor ["inherit", "black", "white", "linen", "dimgray", "whitesmoke", "midnightblue", "darkolivegreen", "darkslategray", "lavender"])

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
            ( { model
                  | bgColor = { index = s
                              , list = model.bgColor.list
                              }
              }
            , Cmd.none )

        ChangeFGColor s ->
            ( { model
                  | fgColor = { index = s
                              , list = model.fgColor.list
                              }
              }
            , Cmd.none )

        ChangeFontFamily s ->
            ( { model
                  | fontFamily = { index = s
                                 , list = model.fontFamily.list
                                 }
              }
            , Cmd.none )
        ChangeFontSize s ->
            ( { model
                  | fontSize = { index = s
                               , list = model.fontSize.list
                               }
              }
            , Cmd.none )

        TouchBackgroundColor ->
            ( { model
                  | editTarget = EditColor "bg-color" ChangeBGColor model.bgColor.list
              }
            , Cmd.none
            )
        TouchForegroundColor ->
            ( { model
                  | editTarget = EditColor "fg-color" ChangeFGColor model.fgColor.list
              }
            , Cmd.none
            )
        TouchFontSize ->
            ( { model
                  | editTarget = EditFontSize "font-size" ChangeFontSize model.fontSize.list
              }
            , Cmd.none
            )
        TouchFontFalily ->
            ( { model
                  | editTarget = EditFontFamily "font-family" ChangeFontFamily model.fontFamily.list
              }
            , Cmd.none
            )



view : Model -> Html Msg
view model =
    div [ style [ ("display", "flex"), ("flex-direction", "row"), ("justify-content", "space-between"), ("align-items", "center")
                , ("flex-grow", "2"), ("background-color", "whitesmoke"), ("color", "gray")
                , ("min-height", "17em")
                ]
        ]
        [ div [ class "style-itemlist"
              , style [ ("display", "flex"), ("flex-direction", "column")
                      , ("height", "16em")
                      , ("justify-content", "flex-start")
                      ]
              ]
              [ div [ onClick TouchBackgroundColor
                    , class <| if targetName model.editTarget == "bg-color" then "style-item-active" else "style-item"
                    ]
                    [ span [] [text "background-color: "]
                    , span [] [text model.bgColor.index ]
                    ]
              , div [ onClick TouchForegroundColor
                    , class <| if targetName model.editTarget == "fg-color" then "style-item-active" else "style-item"
                    ]
                    [ span [] [text "color: "]
                    , span [] [text model.fgColor.index ]
                    ]
              , div [ onClick TouchFontFalily
                    , class <| if targetName model.editTarget == "font-family" then "style-item-active" else "style-item"
                    ]
                    [ span [] [text "font-family: "]
                    , span [] [text model.fontFamily.index ]
                    ]
              , div [ onClick TouchFontSize
                    , class <| if targetName model.editTarget == "font-size" then "style-item-active" else "style-item"
                    ]
                    [ span [] [text "font-size: "]
                    , span [] [text model.fontSize.index ]
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

colorPalette : (String -> Msg) -> (List String) -> Html Msg
colorPalette tagger colorList =
    div [ class "style-palette"
        , style [ ("flex-grow", "1"), ("display", "flex"), ("align-content", "flex-start"), ("flex-wrap","wrap")
                ]
        ] <|
        List.map (\ color ->
                      div [ style [ ("height", "2em"), ("width", "12em"), ("display", "flex"), ("flex-directipn", "column"), ("padding", "1em") ]
                          ]
                          [ div [ style [ ("width", "1em"), ("height", "1em"), ("background-color", color), ("border", "1px solid black") ]
                                , onClick <| tagger color
                                ]
                                []
                          , div [ style [ ("padding-left", "0.5em") ]
                                , onClick <| tagger color
                                ]
                                [ text color
                                ]
                          ]
                 ) colorList

fontFamilySelector : (String -> Msg) -> (List String) -> Html Msg
fontFamilySelector tagger fontList =
    div [ class "style-palette"
        , style [ ("flex-grow", "1"), ("display", "flex"), ("flex-direction", "row"), ("flex-wrap","no-wrap")
                ]
        ] <|
        List.map (\ font ->
                      div [ style [ ("height", "2em"), ("size", "2em"), ("padding", "0.5em"), ("font-family", font), ("width", "100%")]
                          , onClick <| tagger font
                          ]
                          [ text font
                          ]
                 ) fontList

fontSizeSelector : (String -> Msg) -> (List String) -> Html Msg
fontSizeSelector tagger fontsizeList =
    div [ class "style-palette"
        , style [ ("flex-grow", "1"), ("display", "flex"), ("flex-direction", "row"), ("flex-wrap","no-wrap")
                ]
        ] <|
        List.map (\ fontsize ->
                      div [ style [ ("padding", "0.5rem"), ("font-size", fontsize), ("width", "100%") ]
                          , onClick <| tagger fontsize
                          ]
                          [ text fontsize
                          ]
                 ) fontsizeList



        
selectList: String -> List String -> (String -> msg) -> Html msg
selectList idx values tagger =
    select [on "change" (Json.map tagger (Json.at ["target","value"] Json.string))]
        ( List.map
              (\ v -> option
                   [ value v , selected (idx == v)]
                   [ text v ]
              ) values
        )

