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

    , indent

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
        line = model.buffer.contents
                 |> Buffer.line row
                 |> Maybe.withDefault ""
                 |> \l -> if l == "" then "\n" else l

        delete_range =  if line == "\n" then Buffer.Range (row, 0) (row + 1, 0)
                                        else Buffer.Range (row, 0) (row, String.length line)
    in
        { model
            | copyStore = if model.lastCommand == Just "killLine" then model.copyStore ++ line else line
            , buffer = model.buffer
                           |> Buffer.deleteRange delete_range
                           |> Buffer.selectionClear
          }
        |> Core.blinkBlock
        |> Core.withEnsureVisibleCmd



indent : Model -> (Model, Cmd Msg)
indent model =
    let
        (row, col) = Buffer.nowCursorPos model.buffer

        line     = model.buffer.contents |> Buffer.line row |> Maybe.withDefault ""
        prevline = model.buffer.contents |> Buffer.line (row - 1) |> Maybe.withDefault ""

        getIndentString = (\l indent_str->
                               case l of
                                   [] ->
                                       indent_str |> List.reverse
                                   x :: xs ->
                                       if (x == ' ') || (x == '\t') then
                                           getIndentString xs (x :: indent_str)
                                       else
                                           indent_str |> List.reverse
                          )

        prev_indent = getIndentString (prevline |> String.toList) []  |> String.fromList
        cur_indent  = getIndentString (line |> String.toList) []  |> String.fromList
    in
        { model
            | buffer = if prev_indent == cur_indent then
                           let
                               plus_indent = if prev_indent == "" then "    " else prev_indent
                           in
                               model.buffer
                                   |> Buffer.moveAt (row, (String.length cur_indent))
                                   |> Buffer.insert plus_indent
                                   |> Buffer.moveAt ( row
                                                    , col + (String.length plus_indent)
                                                    )
                       else
                           model.buffer 
                               |> Buffer.deleteRange (Buffer.Range (row, 0) (row, (String.length line) - (String.trimLeft line |> String.length) ) )
                               |> Buffer.moveAt (row, 0)
                               |> Buffer.insert prev_indent
                               |> Buffer.moveAt ( row
                                                , col + ((String.length prev_indent ) - (String.length cur_indent))
                                                )
        }
            |> Core.blinkBlock
            |> Core.withEnsureVisibleCmd
