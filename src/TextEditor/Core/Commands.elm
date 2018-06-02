module TextEditor.Core.Commands exposing
    ( moveForward
    , moveBackward
    , movePrevios
    , moveNext
    , moveBOL
    , moveEOL
    , moveAt
    , selectForward
    , selectBackward
    , selectPrevios
    , selectNext
    , selectAt
    , markSet
    , markClear
    , markFlip
    , gotoMark
    , insert
    , backspace
    , delete
    , undo
    , copy
    , cut
    , paste
    , killLine

    , batch
    )

import TextEditor.Buffer as Buffer
import TextEditor.Core as Core  exposing (Model, Msg)


batch : List (Model -> (Model, Cmd Msg)) -> (Model -> (Model, Cmd Msg))
batch commands =
    let
        batch_proc = (\ cmdMsgs editorCmds model ->
                          case editorCmds of
                              x :: xs ->
                                  let
                                      (m1, c1) = x model
                                  in
                                      batch_proc (c1 :: cmdMsgs) xs m1
                              [] ->
                                  (model, Cmd.batch cmdMsgs)
                     )
    in
        batch_proc [] commands


------------------------------------------------------------
-- cursor moving
------------------------------------------------------------

moveForward : Model -> (Model, Cmd Msg)
moveForward = editF Buffer.moveForward

moveBackward : Model -> (Model, Cmd Msg)
moveBackward = editF Buffer.moveBackward

movePrevios : Model -> (Model, Cmd Msg)
movePrevios = editF Buffer.movePrevios

moveNext : Model -> (Model, Cmd Msg)
moveNext = editF Buffer.moveNext

moveBOL : Model -> (Model, Cmd Msg)
moveBOL model = editF (Buffer.moveAt (model.buffer.cursor.row, 0)) model

moveEOL : Model -> (Model, Cmd Msg)
moveEOL model =
    let
        col = Buffer.line model.buffer.cursor.row model.buffer.contents
                |> Maybe.withDefault ""
                |> String.length
    in
        editF (Buffer.moveAt (model.buffer.cursor.row, col)) model

moveAt : (Int, Int) -> Model -> (Model, Cmd Msg)
moveAt pos =  editF (Buffer.moveAt pos)

------------------------------------------------------------
-- selection
------------------------------------------------------------

selectBackward: Model -> (Model, Cmd Msg)
selectBackward = editF Buffer.selectBackward

selectForward: Model -> (Model, Cmd Msg)
selectForward = editF Buffer.selectForward

selectPrevios: Model -> (Model, Cmd Msg)
selectPrevios = editF Buffer.selectPrevios

selectNext: Model -> (Model, Cmd Msg)
selectNext = editF Buffer.selectNext

selectAt: (Int, Int) -> Model -> (Model, Cmd Msg)
selectAt pos = editF (Buffer.selectAt pos)

------------------------------------------------------------
-- mark
------------------------------------------------------------

markSet : Model -> (Model, Cmd Msg)
markSet = editF Buffer.markSet

markClear : Model -> (Model, Cmd Msg)
markClear = editF Buffer.markClear

markFlip : Model -> (Model, Cmd Msg)
markFlip = editF (\m -> if Buffer.isMarkActive m then Buffer.markClear m else Buffer.markSet m)

gotoMark : Model -> (Model, Cmd Msg)
gotoMark = editF Buffer.gotoMark


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


killLine : Model -> (Model, Cmd Msg)
killLine model = 
    -- note: ブラウザのセキュリティ制約により、sytem の clipboard  にはコピーされません
    let
        row = model.buffer |> Buffer.nowCursorPos |> Tuple.first
        line = model.buffer.contents |> Buffer.line row |> Maybe.withDefault ""
    in
        { model
            | copyStore = line
            , buffer = model.buffer
                           |> Buffer.deleteRange (Buffer.Range (row, 0) (row, String.length line))
                           |> Buffer.selectionClear
          }
        |> Core.blinkBlock
        |> Core.withEnsureVisibleCmd
