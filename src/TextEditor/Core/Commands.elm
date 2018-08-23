module TextEditor.Core.Commands exposing
    ( moveForward
    , moveBackward
    , movePreviosLine
    , moveNextLine
    , moveBOL
    , moveEOL
    , moveAt
    , moveNextWord
    , movePreviosWord
    , selectForward
    , selectBackward
    , selectPreviosLine
    , selectNextLine
    , selectPreviosWord
    , selectNextWord
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
    , killWord

    , indent
    , unindent

    , nop

    , batch
    )

import TextEditor.Buffer as Buffer exposing (Position)
import TextEditor.Core as Core  exposing (Model, Msg)

import TextEditor.StringExtra exposing (..)


batch : List (Model -> (Model, Cmd Msg)) -> (Model -> (Model, Cmd Msg))
batch commands =
        batch_proc [] commands


batch_proc cmdMsgs editorCmds model =
    case editorCmds of
        x :: xs ->
            let
                (m1, c1) = x model
            in
                batch_proc (c1 :: cmdMsgs) xs m1
        [] ->
            (model, Cmd.batch cmdMsgs)




------------------------------------------------------------
-- cursor moving
------------------------------------------------------------

moveForward : Model -> (Model, Cmd Msg)
moveForward = moveF Buffer.moveForward

moveBackward : Model -> (Model, Cmd Msg)
moveBackward = moveF Buffer.moveBackward

movePreviosLine : Model -> (Model, Cmd Msg)
movePreviosLine = moveF Buffer.movePreviosLine

moveNextLine : Model -> (Model, Cmd Msg)
moveNextLine = moveF Buffer.moveNextLine

moveBOL : Model -> (Model, Cmd Msg)
moveBOL model = moveF (Buffer.moveAt (Position model.buffer.cursor.row 0)) model

moveEOL : Model -> (Model, Cmd Msg)
moveEOL model =
    let
        col = Buffer.currentLine model.buffer |> String.length
    in
        moveF (Buffer.moveAt (Position model.buffer.cursor.row col)) model

moveAt : Buffer.Position -> Model -> (Model, Cmd Msg)
moveAt pos =  moveF (Buffer.moveAt pos)

moveNextWord : Model -> (Model, Cmd Msg)
moveNextWord = moveF Buffer.moveNextWord

movePreviosWord : Model -> (Model, Cmd Msg)
movePreviosWord = moveF Buffer.movePreviosWord


------------------------------------------------------------
-- selection
------------------------------------------------------------

selectBackward: Model -> (Model, Cmd Msg)
selectBackward = moveF Buffer.selectBackward

selectForward: Model -> (Model, Cmd Msg)
selectForward = moveF Buffer.selectForward

selectPreviosLine: Model -> (Model, Cmd Msg)
selectPreviosLine = moveF Buffer.selectPreviosLine

selectNextLine: Model -> (Model, Cmd Msg)
selectNextLine = moveF Buffer.selectNextLine

selectPreviosWord: Model -> (Model, Cmd Msg)
selectPreviosWord = moveF Buffer.selectPreviosWord

selectNextWord: Model -> (Model, Cmd Msg)
selectNextWord = moveF Buffer.selectNextWord


selectAt: Buffer.Position -> Model -> (Model, Cmd Msg)
selectAt pos = moveF (Buffer.selectAt pos)

------------------------------------------------------------
-- mark
------------------------------------------------------------

markSet : Model -> (Model, Cmd Msg)
markSet = moveF Buffer.markSet

markClear : Model -> (Model, Cmd Msg)
markClear = moveF Buffer.markClear

markFlip : Model -> (Model, Cmd Msg)
markFlip = moveF (\m -> if Buffer.isMarkActive m then Buffer.markClear m else Buffer.markSet m)

gotoMark : Model -> (Model, Cmd Msg)
gotoMark = moveF Buffer.gotoMark


------------------------------------------------------------
-- edit buffer
------------------------------------------------------------

-- Tools

editF : (Buffer.Buffer -> Buffer.Buffer) -> Model -> (Model, Cmd Msg)
editF f model =
    { model | buffer = f model.buffer }
        |> Core.blinkBlock
        |> \m -> Core.setEventRequest (Core.EventInput m.buffer.contents) m
        |> Core.withEnsureVisibleCmd

moveF : (Buffer.Buffer -> Buffer.Buffer) -> Model -> (Model, Cmd Msg)
moveF f model =
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
        |> \m -> Core.setEventRequest (Core.EventInput m.buffer.contents) m
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
        |> \m -> Core.setEventRequest (Core.EventInput m.buffer.contents) m
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
        |> \m -> Core.setEventRequest (Core.EventInput m.buffer.contents) m
        |> Core.withEnsureVisibleCmd


killLine : Model -> (Model, Cmd Msg)
killLine model = 
    -- note: ブラウザのセキュリティ制約により、sytem の clipboard  にはコピーされません
    let
        cur = model.buffer.cursor
        line = Buffer.currentLine model.buffer
        isEOFLine = \r -> (r + 1) >= List.length model.buffer.contents

        delete_str = line
                 |> String.dropLeft cur.column
                 |> \l -> if (l == "") && (not (isEOFLine cur.row)) then "\n" else l

        delete_range =  if delete_str == "\n" then Buffer.Range cur (Position (cur.row + 1) 0)
                                              else Buffer.Range cur (Position cur.row (String.length line))
    in
        { model
            | copyStore = if model.lastCommand == Just "killLine" then model.copyStore ++ delete_str else delete_str
            , buffer = model.buffer
                           |> Buffer.deleteRange delete_range
                           |> Buffer.selectionClear
          }
        |> Core.blinkBlock
        |> \m -> Core.setEventRequest (Core.EventInput m.buffer.contents) m
        |> Core.withEnsureVisibleCmd


killWord : Model -> (Model, Cmd Msg)
killWord model =
    let
        bm  = (Buffer.selectionClear >> Buffer.selectNextWord) model.buffer
        delete_str = bm.selection
                     |> Maybe.andThen (\sel -> Buffer.readRange sel bm |> Just)
                     |> Maybe.withDefault ""
    in
        case bm.selection of
            Just sel ->
                { model
                    | copyStore = if model.lastCommand == Just "killWord" then model.copyStore ++ delete_str else delete_str
                    , buffer = bm |> Buffer.deleteRange sel |> Buffer.selectionClear
                }
                     |> Core.blinkBlock
                     |> Core.withEnsureVisibleCmd

            Nothing ->
                (model, Cmd.none)


indent : Model -> (Model, Cmd Msg)
indent model =
    let
        (row, col) = (model.buffer.cursor.row, model.buffer.cursor.column)

        curline  = model.buffer |> Buffer.currentLine
        prevline = model.buffer |> Buffer.line (row - 1) |> Maybe.withDefault ""

        cur_indent  = indentString curline
        prev_indent = indentString prevline

        cur_level = indentLevel model.option.tabOrder cur_indent
        prev_level = indentLevel model.option.tabOrder prev_indent

        indent_str = if model.option.indentTabsMode
                     then "\t"
                     else String.pad model.option.tabOrder ' ' ""
    in
        { model
            | buffer = if prev_level == cur_level then
                           model.buffer
                               |> Buffer.insertAt (Position row (String.length cur_indent)) indent_str
                               |> Buffer.moveAt ( Position
                                                      row
                                                      (col + (String.length indent_str))
                                                )
                       else
                           model.buffer 
                               |> Buffer.deleteRange (Buffer.Range (Position row 0) (Position row (String.length cur_indent)) )
                               |> Buffer.insertAt (Position row 0) prev_indent
                               |> Buffer.moveAt ( Position
                                                      row
                                                      (col + ((String.length prev_indent ) - (String.length cur_indent)) |> max 0)
                                                )
        }
            |> Core.blinkBlock
            |> \m -> Core.setEventRequest (Core.EventInput m.buffer.contents) m
            |> Core.withEnsureVisibleCmd

unindent : Model -> (Model, Cmd Msg)
unindent model =
    let
        (row, col) = (model.buffer.cursor.row, model.buffer.cursor.column)

        curline  = model.buffer |> Buffer.currentLine
        prevline = model.buffer |> Buffer.line (row - 1) |> Maybe.withDefault ""

        cur_indent  = indentString curline
        prev_indent = indentString prevline

        cur_level = indentLevel model.option.tabOrder cur_indent
        prev_level = indentLevel model.option.tabOrder prev_indent

        indent_str = (\n -> if model.option.indentTabsMode
                            then String.pad (n // model.option.tabOrder) '\t' (String.pad (modBy n  model.option.tabOrder) ' ' "")
                            else String.pad n ' ' ""
                     )
    in
        { model
            | buffer = if prev_level == cur_level then 
                           let
                               new_indent = indent_str (prev_level - model.option.tabOrder)
                           in
                               model.buffer
                                   |> Buffer.deleteRange ( Buffer.Range (Position row 0) (Position row (String.length cur_indent)) )
                                   |> Buffer.insertAt (Position row 0) new_indent
                                   |> Buffer.moveAt ( Position
                                                          row
                                                          (col + ((String.length new_indent) - (String.length cur_indent)) |> max 0)
                                                    )
                       else
                           model.buffer 
                               |> Buffer.deleteRange (Buffer.Range (Position row 0) (Position row (String.length cur_indent) ) )
                               |> Buffer.insertAt (Position row 0) prev_indent
                               |> Buffer.moveAt ( Position
                                                      row
                                                      (col + ((String.length prev_indent ) - (String.length cur_indent)) |> max 0)
                                                )
        }
            |> Core.blinkBlock
            |> \m -> Core.setEventRequest (Core.EventInput m.buffer.contents) m
            |> Core.withEnsureVisibleCmd


nop : Model -> (Model, Cmd Msg)
nop model =
    ( model, Cmd.none )

