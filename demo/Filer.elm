module Filer exposing
    ( Model
    , Msg(ReadFile)
    , init
    , update
    , view
    )

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Task exposing (Task)
import FileReader

type alias Model =
    { selectedSubMenu: SubMenu
    , inDropZone : Bool
    }

type SubMenu
    = Load
    | Save

type Msg
    = TouchLoadSubMenu
    | TouchSaveSubMenu
    | DropZoneEntered
    | DropZoneLeaved    
    | FilesDropped (List FileReader.File)
    | ReadFile FileReader.File


init : Model
init =
    { selectedSubMenu = Load
    , inDropZone = False
    }

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
    case msg of
        TouchSaveSubMenu ->
            ( { model | selectedSubMenu = Save }
            , Cmd.none
            )
        TouchLoadSubMenu ->
            ( { model | selectedSubMenu = Load }
            , Cmd.none
            )
        DropZoneEntered ->
            ( { model | inDropZone = True }
            , Cmd.none
            )
        DropZoneLeaved  ->
            ( { model | inDropZone = False }
            , Cmd.none
            )
        FilesDropped filelist ->
            case List.head filelist of
                Just f ->
                    ( { model | inDropZone = False }
                    , Task.perform ReadFile (Task.succeed f)
                    )
                Nothing ->
                    ( model, Cmd.none )
        ReadFile _ ->
            ( model, Cmd.none )

view : Model -> Html Msg
view model =
    div [ class "menu-root"
        , style [ ("flex-grow", "2")
                , ("min-height", "17em")
                ]
        ]
        [ menuItemsView model
        , menuPalette model
        ]

menuItemsView : Model -> Html Msg
menuItemsView model =                
    div [ class "menu-itemlist"
        , style [ ("display", "flex"), ("flex-direction", "column")
                , ("height", "16em")
                , ("justify-content", "flex-start")
                ]
        ]
    [ div [ onClick TouchLoadSubMenu
          , class <| if model.selectedSubMenu == Load then "menu-item-active" else "menu-item"
          ]
          [ span [] [text "Load"]
          ]
    , div [ onClick TouchSaveSubMenu
          , class <| if model.selectedSubMenu == Save then "menu-item-active" else "menu-item"
          ]
          [ span [] [text "Save "]
          ]
    ]



menuPalette model =
    case model.selectedSubMenu of
        Load ->
            div [class "menu-palette"] [ fileLoadView model ]
        Save ->
            div [class "menu-palette"] [ text "save" ]


fileLoadView : Model -> Html Msg
fileLoadView model =
    div ( [ class "filer-dropzone"
          , style <|
                if model.inDropZone
                then [ ( "background", "lightblue" ) ]
                else []
          ] ++
              FileReader.dropZone
              { dataFormat = FileReader.Text "utf-8"
              , enterMsg = DropZoneEntered
              , leaveMsg = DropZoneLeaved
              , filesMsg = FilesDropped
              }
        )
        [ div [ class "filer-inner" ]
              [ Html.text "Drop a file here"
              , Html.br [] []
              , Html.text "or.."
              , Html.br [] []
              , Html.label
                  [ class "file_input_label" ]
                  [ Html.text "Select a file from PC"
                  , Html.input (FileReader.fileInput (FileReader.Text "utf-8") ReadFile) []
                  ]
              ]
        ]

