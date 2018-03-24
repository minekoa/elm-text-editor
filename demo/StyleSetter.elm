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
    }

init: Model
init =
    Model
    { index = "inherit", list = ["inherit", "black", "white", "linen", "dimgray", "whitesmoke", "midnightblue", "darkolivegreen", "darkslategray", "lavender"] }
    { index = "inherit", list = ["inherit", "black", "white", "aqua", "coral", "midnightblue", "darkslategray", "lavender", "palevioletred", "rosybrown"] }
    { index = "inherit", list = ["inherit", "cursive", "fantasy", "monospace", "sans-serif", "serif"] }
    { index = "inherit", list = ["inherit", "0.5em", "1em", "1.5em", "2em", "3em", "5em", "7em", "10em"] }

type Msg
    = ChangeBGColor String
    | ChangeFGColor String
    | ChangeFontFamily String
    | ChangeFontSize String

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


view : Model -> Html Msg
view model =
    div [ style [ ("display", "flex"), ("flex-direction", "row"), ("justify-content", "space-between"), ("align-items", "center")
                , ("height", "2em"), ("flex-grow", "2"), ("background-color", "whitesmoke"), ("color", "gray")
                ]
        ]
        [ div [] [ span [] [text "background-color: "]
                 , selectList model.bgColor.index model.bgColor.list ChangeBGColor
                 ]
        , div [] [ span [] [text "color: "]
                 , selectList model.fgColor.index model.fgColor.list ChangeFGColor
                 ]
        , div [] [ span [] [text "font-family: "]
                 , selectList model.fontFamily.index model.fontFamily.list ChangeFontFamily
                 ]
        , div [] [ span [] [text "font-size: "]
                 , selectList model.fontSize.index model.fontSize.list ChangeFontSize
                 ]
        ]

selectList: String -> List String -> (String -> msg) -> Html msg
selectList idx values tagger =
    select [on "change" (Json.map tagger (Json.at ["target","value"] Json.string))]
        ( List.map
              (\ v -> option
                   [ value v , selected (idx == v)]
                   [ text v ]
              ) values
        )

