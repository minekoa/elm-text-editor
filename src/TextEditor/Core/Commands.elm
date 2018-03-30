module TextEditor.Core.Commands exposing
    ( moveForward
    , moveBackward
    , movePrevios
    , moveNext
    , moveBOL
    , moveEOL
    , selectForward
    , selectBackward
    , selectPrevios
    , selectNext
    , insert
    , backspace
    , delete
    , undo
    , copy
    , cut
    , paste
    )

import TextEditor.Buffer as Buffer
import TextEditor.Core as Core  exposing (Model, Msg)

------------------------------------------------------------
-- cursor moving
------------------------------------------------------------

-- Tools

moveF : (Buffer.Model -> Buffer.Model) -> Model -> (Model, Cmd Msg)
moveF f model =
    { model | buffer = (f >> Buffer.selectionClear) model.buffer }
        |> Core.blinkBlock
        |> Core.withEnsureVisibleCmd

-- API

moveForward : Model -> (Model, Cmd Msg)
moveForward = moveF Buffer.moveForward

moveBackward : Model -> (Model, Cmd Msg)
moveBackward = moveF Buffer.moveBackward

movePrevios : Model -> (Model, Cmd Msg)
movePrevios = moveF Buffer.movePrevios

moveNext : Model -> (Model, Cmd Msg)
moveNext = moveF Buffer.moveNext

moveBOL : Model -> (Model, Cmd Msg)
moveBOL = moveF (\m -> {m | cursor = Buffer.Cursor m.cursor.row 0})

moveEOL : Model -> (Model, Cmd Msg)
moveEOL = moveF (\m ->
                     {m | cursor = Buffer.Cursor m.cursor.row (Buffer.line m.cursor.row m.contents
                                                              |> Maybe.withDefault ""
                                                              |> String.length
                                                              )
                     }
                )

------------------------------------------------------------
-- selection
------------------------------------------------------------

-- Tools

selectF : (Buffer.Model -> Buffer.Model) -> Model -> (Model, Cmd Msg)
selectF f model =
    { model | buffer = f model.buffer }
        |> Core.blinkBlock
        |> Core.withEnsureVisibleCmd

-- API

selectBackward: Model -> (Model, Cmd Msg)
selectBackward = selectF Buffer.selectBackward

selectForward: Model -> (Model, Cmd Msg)
selectForward = selectF Buffer.selectForward

selectPrevios: Model -> (Model, Cmd Msg)
selectPrevios = selectF Buffer.selectPrevios

selectNext: Model -> (Model, Cmd Msg)
selectNext = selectF Buffer.selectNext


------------------------------------------------------------
-- edit buffer
------------------------------------------------------------

-- Tools

editF : (Buffer.Model -> Buffer.Model) -> Model -> (Model, Cmd Msg)
editF f model =
    { model | buffer = f model.buffer }
        |> Core.blinkBlock
        |> Core.withEnsureVisibleCmd


-- API

insert: String -> Model-> (Model, Cmd Msg)
insert text = editF (Buffer.insert text)

backspace: Model -> (Model, Cmd Msg)
backspace = editF Buffer.backspace

delete: Model ->  (Model, Cmd Msg)
delete = editF Buffer.delete


------------------------------------------------------------
-- update > undo / redo
------------------------------------------------------------

-- API

undo : Model -> (Model, Cmd Msg)
undo model =
    { model | buffer = (Buffer.undo >> Buffer.selectionClear) model.buffer }
        |> Core.blinkBlock
        |> Core.withEnsureVisibleCmd


------------------------------------------------------------
-- update > clipboard action
------------------------------------------------------------

-- API (for User and Browser's clipboard action (Copied, Cutted, Pasted (custom events)) )

copy : Model -> (Model, Cmd Msg)
copy model =
    -- note: ブラウザのセキュリティ制約により、sytem の clipboard  にはコピーされません
    ( case model.buffer.selection of
          Nothing -> model
          Just sel ->
          { model
              | copyStore = Buffer.readRange sel model.buffer
              , buffer = Buffer.selectionClear model.buffer
          }
    )
        |> Core.blinkBlock
        |> (\m -> (m, Cmd.none))


cut : Model -> (Model, Cmd Msg)
cut model =
    -- note: ブラウザのセキュリティ制約により、sytem の clipboard  にはコピーされません
    ( case model.buffer.selection of
          Nothing -> model
          Just sel ->
          { model
              | copyStore = Buffer.readRange sel model.buffer
              , buffer = model.buffer |> Buffer.deleteRange sel |> Buffer.selectionClear
          }
    )
        |> Core.blinkBlock
        |> Core.withEnsureVisibleCmd

paste : String -> Model -> (Model, Cmd Msg)
paste text model =
    { model
        | buffer = model.buffer
                       |> Buffer.insert text
                       |> Buffer.selectionClear
        , copyStore = text  -- clipboard経由のペーストもあるので、copyStoreを更新しておく
    }
        |> Core.blinkBlock
        |> Core.withEnsureVisibleCmd




