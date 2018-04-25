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

import TextEditor.Buffer as Buffer
import FilerPorts exposing (..)

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
    | SaveFile

init : Model
init =
    { selectedSubMenu = Load
    , inDropZone = False
    }

update : Msg -> (String, Buffer.Model) -> Model -> (Model, Cmd Msg)
update msg (fname, buf) model =
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
        SaveFile ->
            ( model
            , filer_saveFile (fname, String.join "\n" buf.contents)
            )

view : Model -> Html Msg
view model =
    div [ class "filer-menu", class "menu-root"
        , style [ ("flex-grow", "2")
                , ("min-height", "17em")
                ]
        ]
        [ menuItemsView model
        , menuPalette model
        ]

menuItemsView : Model -> Html Msg
menuItemsView model =                
    div [ class "menu-itemlist" ]
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
            div [class "menu-palette"] [ fileSaveView model ]


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

fileSaveView : Model -> Html Msg
fileSaveView model =
    div [ class "filer-save"]
        [ div [ class "file_input_label"
              , onClick SaveFile
              ]
              [ text "Save current buffer" ]
        ]


