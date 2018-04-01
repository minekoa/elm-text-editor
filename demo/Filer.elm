module Filer exposing
    ( view
    )                       

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import FileReader

view : (FileReader.File -> msg) -> Html msg
view tagger =
    div []
        [ input (FileReader.fileInput (FileReader.Text "utf-8") tagger) []
        ]


