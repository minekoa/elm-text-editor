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
    { inDropZone : Bool }

type Msg
    = DropZoneEntered
    | DropZoneLeaved    
    | FilesDropped (List FileReader.File)
    | ReadFile FileReader.File

init : Model
init =
    { inDropZone = False }

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
    case msg of
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

