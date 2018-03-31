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
   = EditColor (String -> Msg) (List String)
   | EditFontFamily (String -> Msg) (List String)
   | EditFontSize (String -> Msg) (List String)

init: Model
init =
    Model
    { index = "inherit", list = ["inherit", "black", "white", "linen", "dimgray", "whitesmoke", "midnightblue", "darkolivegreen", "darkslategray", "lavender"] }
    { index = "inherit", list = ["inherit", "black", "white", "aqua", "coral", "midnightblue", "darkslategray", "lavender", "palevioletred", "rosybrown"] }
    { index = "inherit", list = ["inherit", "cursive", "fantasy", "monospace", "sans-serif", "serif"] }
    { index = "inherit", list = ["inherit", "0.5em", "1em", "1.5em", "2em", "3em", "5em", "7em", "10em"] }
    (EditColor ChangeBGColor ["inherit", "black", "white", "linen", "dimgray", "whitesmoke", "midnightblue", "darkolivegreen", "darkslategray", "lavender"])

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
                  | editTarget = EditColor ChangeBGColor model.bgColor.list
              }
            , Cmd.none
            )
        TouchForegroundColor ->
            ( { model
                  | editTarget = EditColor ChangeFGColor model.fgColor.list
              }
            , Cmd.none
            )
        TouchFontSize ->
            ( { model
                  | editTarget = EditFontSize ChangeFontSize model.fontSize.list
              }
            , Cmd.none
            )
        TouchFontFalily ->
            ( { model
                  | editTarget = EditFontFamily ChangeFontFamily model.fontFamily.list
              }
            , Cmd.none
            )



view : Model -> Html Msg
view model =
    div [ style [ ("display", "flex"), ("flex-direction", "row"), ("justify-content", "space-between"), ("align-items", "center")
                , ("flex-grow", "2"), ("background-color", "whitesmoke"), ("color", "gray")
                , ("min-height", "10em")
                ]
        ]
        [ div [ style [("height", "100%"), ("width", "20em"), ("border-left", "1px solid gray")]
              ]
              [ div [ onClick TouchBackgroundColor
                    , style [ ("height", "2em") ]
                    ]
                    [ span [] [text "background-color: "]
                    , span [] [text model.bgColor.index ]
                    ]
              , div [ onClick TouchForegroundColor
                    , style [ ("height", "2em") ]
                    ]
                    [ span [] [text "color: "]
                    , span [] [text model.fgColor.index ]
                    ]
              , div [ onClick TouchFontFalily
                    , style [ ("height", "2em") ]
                    ]
                    [ span [] [text "font-family: "]
                    ]
              , div [ onClick TouchFontSize
                    , style [ ("height", "2em") ]
                    ]
                    [ span [] [text "font-size: "]
                   ]
              ]
        , case model.editTarget of
            EditColor tagger list ->
                colorPalette tagger list
            EditFontFamily  tagger list ->
                fontFamilySelector tagger list
            EditFontSize tagger list ->
                fontSizeSelector tagger list
        ]

colorPalette : (String -> Msg) -> (List String) -> Html Msg
colorPalette tagger colorList =
    div [ style [ ("flex-grow", "1"), ("display", "flex"), ("align-content", "flex-start"), ("flex-wrap","wrap")
                , ("height", "100%"), ("max-height", "100%"), ("min-height", "100%"), ("overflow","auto")
                , ("background-color", "white")
                ]
        ] <|
        List.map (\ color ->
                      div [ style [("height", "2em"), ("display", "flex"), ("flex-directipn", "column"), ("padding", "1em")]]
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
    div [ style [ ("flex-grow", "1"), ("display", "flex"), ("flex-direction", "row"), ("flex-wrap","no-wrap")
                , ("height", "100%"), ("max-height", "100%"), ("min-height", "100%"), ("overflow","auto")
                , ("background-color", "white")
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
    div [ style [ ("flex-grow", "1"), ("display", "flex"), ("flex-direction", "row"), ("flex-wrap","no-wrap")
                , ("height", "100%"), ("max-height", "100%"), ("min-height", "100%"), ("overflow","auto")
                , ("background-color", "white")
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

