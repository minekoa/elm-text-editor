module TextEditor.Core exposing
    ( Model
    , Msg
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
    , tapAreaID

    , BlinkState(..)
    , blinkStateToString
    , blinkBlock
    , compositionStart
    , compositionUpdate
    , compositionEnd
    , withEnsureVisibleCmd

    , doFocus
    , elaborateInputArea
    , elaborateTapArea
    , measureSelectionGeometory

    , EventType(..)
    , setEventRequest
    , clearEventRequest
    )

import Time exposing (Posix, toMillis)
import Task exposing (Task)
import Browser.Dom as Dom

import TextEditor.Buffer as Buffer
import TextEditor.Option as Option

------------------------------------------------------------
-- Model
------------------------------------------------------------

type alias Model =
    { id : String -- frame id
    , buffer : Buffer.Buffer

    , option : Option.Option

    , copyStore : String
    , lastCommand : Maybe String
    , eventRequest : Maybe EventType

    -- frame
    , compositionPreview : Maybe String --IMEで返還中の未確定文字

    , focus : Bool
    , blink : BlinkState
    , blinkSpan : Float -- msec order


    -- geometory
    , selectionGeometory : Maybe MarkGeometory
    }


init : String -> Option.Option -> String -> (Model, Cmd Msg)
init id opts text =
    ( Model
          id                     -- id
          (Buffer.init text)
          opts

          ""                     -- copyStore
          Nothing                -- last_command
          Nothing

          -- frame states
          Nothing                -- COMPOSER STATE
          False                  -- focus
          BlinkBlocked           -- blink
          1                      -- blinkSpan

          -- geometory
          Nothing                -- selectionGeometory



    , Cmd.none
    )

type EventType
    = EventInput (List String)

setEventRequest : EventType -> Model -> Model
setEventRequest evnt model =
    { model | eventRequest = Just evnt }

clearEventRequest: Model -> Model
clearEventRequest model =
    { model | eventRequest = Nothing }


------------------------------------------------------------
type alias MarkGeometory =
    { codeAreaWidth : Float
    , markBgnWidth : Float
    , markEndWidth : Float
    }
                      
getMarkGeometoryTask : String -> String -> String -> Task Dom.Error MarkGeometory
getMarkGeometoryTask codeArea_id markBgnRuler_id markEndRuler_id =
    Task.sequence [ Dom.getElement codeArea_id     |> Task.andThen (\info -> Task.succeed (info.element.width))
                  , Dom.getElement markBgnRuler_id |> Task.andThen (\info -> Task.succeed (info.element.width))
                  , Dom.getElement markEndRuler_id |> Task.andThen (\info -> Task.succeed (info.element.width))
                  ]
        |> Task.andThen (\widthList ->
                             case ( widthList |> List.head
                                  , widthList |> List.drop 1 |> List.head
                                  , widthList |> List.drop 2 |> List.head
                                  )
                             of
                                 (Just codeArea_w, Just markBgn_w, Just markEnd_w) ->
                                     Task.succeed <| MarkGeometory codeArea_w markBgn_w markEnd_w
                                 _ ->
                                     Task.fail <| Dom.NotFound (codeArea_id ++ " or " ++ markBgnRuler_id ++ " or " ++ markEndRuler_id)
                        )


------------------------------------------------------------

ensureVisibleTask : String -> String -> Task Dom.Error ()
ensureVisibleTask frame_id target_id =
    getFrameViewPortAndTagetPositon frame_id target_id
        |> Task.andThen (\ vp_and_pos ->
                             let
                                 xy = calcNewFrameViewPort vp_and_pos
                             in
                                 Dom.setViewportOf frame_id xy.x xy.y
                        )


getFrameViewPortAndTagetPositon : String -> String -> Task Dom.Error (Dom.Viewport, Dom.Element)
getFrameViewPortAndTagetPositon frame_id target_id =
    Task.sequence [ Dom.getViewportOf frame_id |> Task.andThen (\ vport -> Task.succeed ( (Just vport, Nothing) ))
                  , Dom.getElement target_id   |> Task.andThen (\ elem  -> Task.succeed ( Nothing    , Just elem))
                  ]
        |> Task.andThen (\ lst ->
                             case ( lst |> List.head |> Maybe.andThen Tuple.first
                                  , lst |> List.drop 1 |> List.head |> Maybe.andThen Tuple.second
                                  )
                             of
                                 (Just frame_vport, Just target_elm) -> 
                                     Task.succeed (frame_vport, target_elm)
                                 _ ->
                                     Task.fail <| Dom.NotFound (frame_id ++ " or " ++ target_id)
                        )

--calcNewFrameViewPort : (Dom.Viewport, Dom.Element) -> { x: Float, y: Float }
calcNewFrameViewPort (frame_vp, target_pos) =
    let
        margin = target_pos.element.height * 2.1

        target = { top    = target_pos.element.y + frame_vp.viewport.y
                 , bottom = target_pos.element.y + frame_vp.viewport.y + target_pos.element.height
                 , left   = target_pos.element.x + frame_vp.viewport.x
                 , right  = target_pos.element.x + frame_vp.viewport.x + target_pos.element.width
                 }
        frame  = { top    = frame_vp.viewport.y
                 , bottom = frame_vp.viewport.y + frame_vp.viewport.height
                 , left   = frame_vp.viewport.x
                 , right  = frame_vp.viewport.x + frame_vp.viewport.width
                 }

        new_scr_top = if      (target.top    - margin < frame.top)    then frame.top + (target.top    - frame.top)    - margin
                      else if (target.bottom + margin > frame.bottom) then frame.top + (target.bottom - frame.bottom) + margin
                      else                                                 frame.top

        new_scr_left = if      (target.left  - margin < frame.left)  then frame.left + (target.left  - frame.left)  - margin
                       else if (target.right + margin > frame.right) then frame.left + (target.right - frame.right) + margin
                       else                                               frame.left
    in
--        { y = new_scr_top, x = new_scr_left }
        Debug.log "new_pos" { y = new_scr_top, x = new_scr_left
                            , oy = (frame.top,frame.bottom)
                            , ox = (frame.left,frame.right)
                            , tx = (target.left, target.right)
                            , ty = (target.top, target.bottom)
                            } --oy ox tx ty はデバッグプリント用




------------------------------------------------------------
-- update
------------------------------------------------------------

type Msg
    = IgnoreResult
    | EnsureVisible
    | MeasuredSelectionGeometory (Maybe MarkGeometory)
    | Tick Posix

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
    case msg of
        IgnoreResult ->  -- Task Result (Native)
            (model, Cmd.none)

        EnsureVisible ->
            ( model
            , ensureVisible model
            )

        MeasuredSelectionGeometory geo ->
            ( { model | selectionGeometory = geo }
            , Cmd.none
            )

        Tick new_time ->
            ( { model | blink = blinkTransition model.blink
              , blinkSpan=500 -- note: 初回更新だけとても早くしたい（描画結果のフィードバックがほしい）ので スパンが変更される
              }
            , Cmd.none )


------------------------------------------------------------
-- Subscriptions
------------------------------------------------------------

subscriptions : Model -> Sub Msg
subscriptions model = 
    Sub.batch [ Time.every (model.blinkSpan) Tick ]


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

tapAreaID : Model -> String
tapAreaID model =
    model.id ++ "-editor-tap"


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

blinkStateToString : BlinkState -> String
blinkStateToString blnk =
    case blnk of
        BlinkBlocked -> "BlinkBlocked"
        Blink True   -> "Blink (True)"
        Blink False  -> "Blink (False)"

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
    |> \m -> setEventRequest (EventInput m.buffer.contents) m
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

elaborateTapArea: Model -> Cmd Msg
elaborateTapArea model =
    Task.perform (\_ -> IgnoreResult) (elaborateTapAreaTask (tapAreaID model))


ensureVisible: Model -> Cmd Msg
ensureVisible model =
    Task.attempt (\r ->
                      case r of
                          Ok _  -> IgnoreResult
                          Err _ -> IgnoreResult
                 )
        (ensureVisibleTask (frameID model) (cursorID model))

measureSelectionGeometory: Model -> Cmd Msg
measureSelectionGeometory model =
    Task.attempt (\r ->
                      case r of
                          Ok geo -> MeasuredSelectionGeometory (Just geo)
                          Err e  -> MeasuredSelectionGeometory Nothing
                 )
        ( getMarkGeometoryTask (codeAreaID model)
                               ((rulerID model) ++ "_selectionBgn")
                               ((rulerID model) ++ "_selectionEnd")
        )

------------------------------------------------------------
-- Native
------------------------------------------------------------

elaborateInputAreaTask: String  -> Task Never Bool
elaborateInputAreaTask input_area_id =
--    Task.succeed (Native.Mice.elaborateInputArea input_area_id)
-- dummy code
    Task.succeed True

elaborateTapAreaTask: String  -> Task Never Bool
elaborateTapAreaTask input_area_id =
--    Task.succeed (Native.Mice.elaborateTapArea input_area_id)
-- dummy code
    Task.succeed True



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
--getBoundingClientRect id = Native.Mice.getBoundingClientRect id
getBoundingClientRect id =
    -- dummy code
    { left = 0
    , top = 0
    , right = 100
    , bottom = 200
    , x = 0
    , y = 0
    , width = 100
    , height = 200
    }

                     
