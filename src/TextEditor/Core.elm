module TextEditor.Core exposing
    ( Model
    , Msg(IgnoreResult)
    , init
    , update
    , subscriptions

    , frameID
    , sceneID
    , codeAreaID
    , lineNumAreaID
    , rulerID
    , prototyleEmID
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
import Dom

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
    | EnsureVisible
    | Tick Time

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
    case msg of
        IgnoreResult ->  -- Task Result (Native)
            (model, Cmd.none)

        EnsureVisible ->
            ( model
            , ensureVisible model
            )

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

codeAreaID : Model -> String
codeAreaID model =
    model.id ++ "-editor-codeArea"

lineNumAreaID : Model -> String
lineNumAreaID model =
    model.id ++ "-editor-lineNumArea"

rulerID : Model -> String
rulerID model =
    model.id ++ "-editor-ruler"

prototyleEmID : Model -> String
prototyleEmID model =
    model.id ++ "-editor-prototypeEm"

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
        | buffer = Buffer.deleteSelection model.buffer
        , compositionPreview = Just ""
    }
    |> blinkBlock

compositionUpdate : String -> Model -> Model
compositionUpdate data model =
    { model
        | compositionPreview = Just data
    }
    |> blinkBlock

compositionEnd : String -> Model -> (Model, Cmd Msg)
compositionEnd data model =
    { model
        | buffer = Buffer.insert data model.buffer
        , compositionPreview = Nothing
    }
    |> blinkBlock
    |> withEnsureVisibleCmd



-- Scroll (by Cursor)

withEnsureVisibleCmd : Model -> (Model, Cmd Msg)
withEnsureVisibleCmd model =
    ( model
    , Task.perform (\_ -> EnsureVisible) (Task.succeed True) 
    )
    -- note: 一度描画ループを回すことで
    --       model更新により更新されたDOMからカーソル位置をDOMから取得するトリック
    --       
    --       カーソルが画面外にいるときの、画面タップでのカーソル移動にて、
    --       こうしないと妙な挙動をした

------------------------------------------------------------
-- Cmd
------------------------------------------------------------

doFocus: Model -> Cmd Msg
doFocus model =
    Task.attempt (\_ -> IgnoreResult) (Dom.focus <| inputAreaID model)

elaborateInputArea: Model -> Cmd Msg
elaborateInputArea model =
    Task.perform (\_ -> IgnoreResult) (elaborateInputAreaTask (inputAreaID model))

ensureVisible: Model -> Cmd Msg
ensureVisible model =
    Task.perform (\_ -> IgnoreResult) (ensureVisibleTask (frameID model) (cursorID model))

------------------------------------------------------------
-- Native
------------------------------------------------------------

elaborateInputAreaTask: String  -> Task Never Bool
elaborateInputAreaTask input_area_id =
    Task.succeed (Native.Mice.elaborateInputArea input_area_id)

ensureVisibleTask : String -> String -> Task Never Bool
ensureVisibleTask frame_id target_id =
    Task.succeed (Native.Mice.ensureVisible frame_id target_id)



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

                     
