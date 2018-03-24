module TextEditor.Core exposing
    ( Model
    , Msg(IgnoreResult)
    , init
    , update
    , subscriptions

    , frameID
    , sceneID
    , codeLayerID
    , rulerID
    , cursorID
    , inputAreaID

    , BlinkState(..)
    , blinkBlock
    , compositionStart
    , compositionUpdate
    , compositionEnd
    , withEnsureVisibleCmd

    , doFocus
    , elaborateInputArea
    )

import Time exposing (Time, second)
import Task exposing (Task)

import TextEditor.Buffer as Buffer


------------------------------------------------------------
-- Model
------------------------------------------------------------

type alias Model =
    { id : String -- frame id
    , buffer : Buffer.Model

    , copyStore : String

    -- frame
    , compositionPreview : Maybe String --IMEで返還中の未確定文字

    , focus : Bool
    , blink : BlinkState
    }


init : String -> String -> (Model, Cmd Msg)
init id text =
    ( Model
          id                     -- id
          (Buffer.init text)
          ""                     -- copyStore

          -- frame states
          Nothing                -- COMPOSER STATE
          False                  -- focus
          BlinkBlocked           -- blink
    , Cmd.none
    )


------------------------------------------------------------
-- update
------------------------------------------------------------

type Msg
    = IgnoreResult
    | Tick Time

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
    case msg of
        IgnoreResult ->  -- Task Result (Native)
            (model, Cmd.none)

        Tick new_time ->
            ( {model | blink = blinkTransition model.blink }
            , Cmd.none )


------------------------------------------------------------
-- Subscriptions
------------------------------------------------------------

subscriptions : Model -> Sub Msg
subscriptions model = 
    Sub.batch [ Time.every (0.5 * second) Tick ]


------------------------------------------------------------
-- Other
------------------------------------------------------------

-- id gen

frameID : Model -> String
frameID model =
    model.id ++ "-editor-frame"

sceneID : Model -> String
sceneID model =
    model.id ++ "-editor-scene"

codeLayerID : Model -> String
codeLayerID model =
    model.id ++ "-editor-codeLayer"

rulerID : Model -> String
rulerID model =
    model.id ++ "-editor-ruler"

cursorID : Model -> String
cursorID model =
    model.id ++ "-editor-cursor"

inputAreaID : Model -> String
inputAreaID model =
    model.id ++ "-editor-input"



-- Blink Cursor

type BlinkState
    = Blink Bool
    | BlinkBlocked


blinkTransition : BlinkState -> BlinkState
blinkTransition blnk =
    case blnk of
        BlinkBlocked -> Blink True
        Blink True   -> Blink False
        Blink False  -> Blink True

blinkBlock : Model -> Model
blinkBlock model =
    {model | blink = BlinkBlocked}


-- Composition Input

compositionStart : Model -> Model
compositionStart model =
    { model
        | buffer = buffer_delete_selection model.buffer
        , compositionPreview = Just ""
    }
    |> blinkBlock

compositionUpdate : String -> Model -> Model
compositionUpdate data model =
    { model
        | compositionPreview = Just data
    }
    |> blinkBlock

compositionEnd : String -> Model -> Model
compositionEnd data model =
    { model
        | buffer = buffer_insert data model.buffer
        , compositionPreview = Nothing
    }



-- Scroll (by Cursor)

withEnsureVisibleCmd : Model -> (Model, Cmd Msg)
withEnsureVisibleCmd model =
    ( model
    , ensureVisible model (\_ -> IgnoreResult)
    )

ensureVisible : Model -> (Bool -> msg) -> Cmd msg
ensureVisible model tagger =
    Cmd.batch
        [ calcVScrollPos model
              |> Maybe.andThen
                  (\n -> Just <| Task.perform tagger (setScrollTop (frameID model) n))
              |> Maybe.withDefault Cmd.none
        , calcHScrollPos model
              |> Maybe.andThen
                  (\n -> Just <| Task.perform tagger (setScrollLeft (frameID model) n))
              |> Maybe.withDefault Cmd.none
        ]

calcVScrollPos : Model -> Maybe Int
calcVScrollPos model =
    let
        frameRect  = getBoundingClientRect <| frameID model
        cursorRect = getBoundingClientRect <| cursorID model
        scrtop = getScrollTop (frameID model)

        margin = cursorRect.height * 3
    in
        if  cursorRect.top - margin < frameRect.top then
            Just ( scrtop + (cursorRect.top - frameRect.top ) - margin)
        else
            if  cursorRect.bottom + margin > frameRect.bottom then
                Just ( scrtop + (cursorRect.bottom - frameRect.bottom ) + margin)
            else 
                Nothing

calcHScrollPos : Model -> Maybe Int
calcHScrollPos model =
    let
        frameRect  = getBoundingClientRect <| frameID model
        cursorRect = getBoundingClientRect <| cursorID model
        scrleft    = getScrollLeft (frameID model)

        margin = cursorRect.height * 3
    in
        if cursorRect.left - margin < frameRect.left then
            Just ( scrleft + (cursorRect.left - frameRect.left ) - margin)
        else
            if  cursorRect.right + margin > frameRect.right then
                Just ( scrleft + (cursorRect.right - frameRect.right ) + margin)
            else 
                Nothing



------------------------------------------------------------
-- あとでどうにかするコピペ
------------------------------------------------------------

buffer_delete_selection : Buffer.Model -> Buffer.Model
buffer_delete_selection bufmodel =
    case bufmodel.selection of
        Nothing ->
            bufmodel
        Just s  ->
            bufmodel
                |> Buffer.deleteRange s
                |> Buffer.selectionClear

buffer_insert : String -> Buffer.Model -> Buffer.Model
buffer_insert text bufmodel=
    case bufmodel.selection of
        Nothing ->
            Buffer.insert (Buffer.nowCursorPos bufmodel) text bufmodel
        Just s ->
            bufmodel
                |> Buffer.deleteRange s
                |> Buffer.selectionClear
                |> (\m -> Buffer.insert (Buffer.nowCursorPos m) text m)



------------------------------------------------------------
-- Cmd
------------------------------------------------------------

doFocus: Model -> Cmd Msg
doFocus model =
    Task.perform (\_ -> IgnoreResult) (doFocusTask <| inputAreaID model)

elaborateInputArea: Model -> Cmd Msg
elaborateInputArea model =
    Task.perform (\_ -> IgnoreResult) (elaborateInputAreaTask (inputAreaID model))

------------------------------------------------------------
-- Native
------------------------------------------------------------

setScrollTop : String -> Int -> Task Never Bool
setScrollTop id pixels =
    Task.succeed (Native.Mice.setScrollTop id pixels)

setScrollLeft : String -> Int -> Task Never Bool
setScrollLeft id pixels =
    Task.succeed (Native.Mice.setScrollLeft id pixels)

doFocusTask : String -> Task Never Bool
doFocusTask id =
    Task.succeed (Native.Mice.doFocus id)

elaborateInputAreaTask: String  -> Task Never Bool
elaborateInputAreaTask input_area_id =
    Task.succeed (Native.Mice.elaborateInputArea input_area_id)


-- Function

type alias Rect =
    { left :Int
    , top : Int
    , right: Int
    , bottom : Int
    , x : Int
    , y : Int
    , width :Int
    , height : Int
    }

getBoundingClientRect: String -> Rect
getBoundingClientRect id = Native.Mice.getBoundingClientRect id

getScrollTop: String -> Int
getScrollTop id = Native.Mice.getScrollTop id

getScrollLeft: String -> Int
getScrollLeft id = Native.Mice.getScrollLeft id

getScrollHeight : String -> Int
getScrollHeight id = Native.Mice.getScrollHeight







                     
