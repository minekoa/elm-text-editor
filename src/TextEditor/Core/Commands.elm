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

    , batch
    )

import TextEditor.Buffer as Buffer
import TextEditor.Core as Core  exposing (Model, Msg)

import TextEditor.StringExtra exposing (..)


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

movePreviosLine : Model -> (Model, Cmd Msg)
movePreviosLine = editF Buffer.movePreviosLine

moveNextLine : Model -> (Model, Cmd Msg)
moveNextLine = editF Buffer.moveNextLine

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

moveNextWord : Model -> (Model, Cmd Msg)
moveNextWord = editF Buffer.moveNextWord

movePreviosWord : Model -> (Model, Cmd Msg)
movePreviosWord = editF Buffer.movePreviosWord


------------------------------------------------------------
-- selection
------------------------------------------------------------

selectBackward: Model -> (Model, Cmd Msg)
selectBackward = editF Buffer.selectBackward

selectForward: Model -> (Model, Cmd Msg)
selectForward = editF Buffer.selectForward

selectPreviosLine: Model -> (Model, Cmd Msg)
selectPreviosLine = editF Buffer.selectPreviosLine

selectNextLine: Model -> (Model, Cmd Msg)
selectNextLine = editF Buffer.selectNextLine

selectPreviosWord: Model -> (Model, Cmd Msg)
selectPreviosWord = editF Buffer.selectPreviosWord

selectNextWord: Model -> (Model, Cmd Msg)
selectNextWord = editF Buffer.selectNextWord


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
        (row, col) = model.buffer |> Buffer.nowCursorPos
        line = model.buffer.contents
                 |> Buffer.line row
                 |> Maybe.withDefault ""

        isEOFLine = \r -> (r + 1) >= List.length model.buffer.contents

        delete_str = line
                 |> String.dropLeft col
                 |> \l -> if (l == "") && (not (isEOFLine row)) then "\n" else l

        delete_range =  if delete_str == "\n" then Buffer.Range (row, col) (row + 1, 0)
                                              else Buffer.Range (row, col) (row, String.length line)
    in
        { model
            | copyStore = if model.lastCommand == Just "killLine" then model.copyStore ++ delete_str else delete_str
            , buffer = model.buffer
                           |> Buffer.deleteRange delete_range
                           |> Buffer.selectionClear
          }
        |> Core.blinkBlock
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
        (row, col) = Buffer.nowCursorPos model.buffer

        curline  = model.buffer.contents |> Buffer.line row |> Maybe.withDefault ""
        prevline = model.buffer.contents |> Buffer.line (row - 1) |> Maybe.withDefault ""

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
                               |> Buffer.insertAt (row, (String.length cur_indent)) indent_str
                               |> Buffer.moveAt ( row
                                                , col + (String.length indent_str)
                                                )
                       else
                           model.buffer 
                               |> Buffer.deleteRange (Buffer.Range (row, 0) (row, String.length cur_indent) )
                               |> Buffer.insertAt (row, 0) prev_indent
                               |> Buffer.moveAt ( row
                                                , col + ((String.length prev_indent ) - (String.length cur_indent)) |> max 0
                                                )
        }
            |> Core.blinkBlock
            |> Core.withEnsureVisibleCmd

unindent : Model -> (Model, Cmd Msg)
unindent model =
    let
        (row, col) = Buffer.nowCursorPos model.buffer

        curline  = model.buffer.contents |> Buffer.line row |> Maybe.withDefault ""
        prevline = model.buffer.contents |> Buffer.line (row - 1) |> Maybe.withDefault ""

        cur_indent  = indentString curline
        prev_indent = indentString prevline

        cur_level = indentLevel model.option.tabOrder cur_indent
        prev_level = indentLevel model.option.tabOrder prev_indent

        indent_str = (\n -> if model.option.indentTabsMode
                            then String.pad (n // model.option.tabOrder) '\t' (String.pad (n % model.option.tabOrder) ' ' "")
                            else String.pad n ' ' ""
                     )
    in
        { model
            | buffer = if prev_level == cur_level then 
                           let
                               new_indent = indent_str (prev_level - model.option.tabOrder)
                           in
                               model.buffer
                                   |> Buffer.deleteRange ( Buffer.Range (row, 0) (row, String.length cur_indent) )
                                   |> Buffer.insertAt (row, 0) new_indent
                                   |> Buffer.moveAt ( row
                                                    , col + ((String.length new_indent) - (String.length cur_indent)) |> max 0
                                                    )
                       else
                           model.buffer 
                               |> Buffer.deleteRange (Buffer.Range (row, 0) (row, (String.length cur_indent) ) )
                               |> Buffer.insertAt (row, 0) prev_indent
                               |> Buffer.moveAt ( row
                                                , col + ((String.length prev_indent ) - (String.length cur_indent)) |> max 0
                                                )
        }
            |> Core.blinkBlock
            |> Core.withEnsureVisibleCmd



