module Filer exposing
    ( Model
    , Msg(ReadFile, CreateNewBuffer, SaveFileAs)
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
    , newFileName : String
    }

type SubMenu
    = New
    | Load
    | Save
    | SaveAs

type Msg
    = TouchSubMenuSelect SubMenu
    | InputFileName String
    | CreateNewBuffer String
    | DropZoneEntered
    | DropZoneLeaved    
    | FilesDropped (List FileReader.File)
    | ReadFile FileReader.File
    | SaveFile
    | SaveFileAs String

init : Model
init =
    { selectedSubMenu = New
    , inDropZone = False
    , newFileName = ""
    }

update : Msg -> (String, Buffer.Model) -> Model -> (Model, Cmd Msg)
update msg (fname, buf) model =
    case msg of
        TouchSubMenuSelect submenu ->
            ( { model
                  | selectedSubMenu = submenu
                  , newFileName = ""
              }
            , Cmd.none
            )
        -- New:
        InputFileName s ->
            ( { model | newFileName = s }
            , Cmd.none
            )

        CreateNewBuffer s ->
            ( { model
                  | newFileName = ""
              }
            , Cmd.none
            )

        -- Load:
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

        -- Save:
        SaveFile ->
            ( model
            , filer_saveFile (fname, String.join "\n" buf.contents)
            )

        SaveFileAs s ->
            ( model
            , filer_saveFile (s, String.join "\n" buf.contents)
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
    [ div [ onClick <| TouchSubMenuSelect New
          , class <| if model.selectedSubMenu == New then "menu-item-active" else "menu-item"
          ]
          [ span [] [text "New"]
          ]
    , div [ onClick <| TouchSubMenuSelect Load
          , class <| if model.selectedSubMenu == Load then "menu-item-active" else "menu-item"
          ]
          [ span [] [text "Load"]
          ]
    , div [ onClick <| TouchSubMenuSelect Save
          , class <| if model.selectedSubMenu == Save then "menu-item-active" else "menu-item"
          ]
          [ span [] [text "Save"]
          ]
    , div [ onClick <| TouchSubMenuSelect SaveAs
          , class <| if model.selectedSubMenu == SaveAs then "menu-item-active" else "menu-item"
          ]
          [ span [] [text "Save as"]
          ]
    ]



menuPalette model =
    case model.selectedSubMenu of
        New ->
            div [class "menu-palette"] [ fileNewView model ]
        Load ->
            div [class "menu-palette"] [ fileLoadView model ]
        Save ->
            div [class "menu-palette"] [ fileSaveView model ]
        SaveAs ->
            div [class "menu-palette"] [ fileSaveAsView model ]


fileNewView : Model -> Html Msg
fileNewView model =
    div [ class "filer-new"]
        [ div []
              [ div []
                    [ text "new file name: "
                    , input [ class "file_name_input"
                            , placeholder "Please enter the file name here!"
                            , value model.newFileName
                            , onInput InputFileName
                            , style [ ("width", "24em") ]
                            ] []
                    ]
              , div [ style [ ("display", "flex")
                            , ("justify-content", "flex-end")
                            ]
                    ]
                    [ div ( if model.newFileName == ""
                            then [ class "filer_button_disabled" ]
                            else [ class "file_input_label"
                                 , onClick <| CreateNewBuffer model.newFileName
                                 ]
                          )
                          [ text "Create!" ]
                    ]
              ]
        ]


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

fileSaveAsView : Model -> Html Msg
fileSaveAsView model =
    div [ class "filer-save"]
        [ div []
              [ div []
                    [ text "file name (rename): "
                    , input [ class "file_name_input"
                            , placeholder "Please enter the file name here!"
                            , value model.newFileName
                            , onInput InputFileName
                            , style [ ("width", "24em") ]
                            ] []
                    ]
              , div [ style [ ("display", "flex")
                            , ("justify-content", "flex-end")
                            ]
                    ]
                    [ div ( if model.newFileName == ""
                            then [ class "filer_button_disabled" ]
                            else [ class "file_input_label"
                                 , onClick <| SaveFileAs model.newFileName
                                 ]
                          )
                          [ text "Save current buffer" ]
                    ]
              ]
        ]

