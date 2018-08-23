module TextEditor.Buffer exposing
    ( Position
    , Range
--    , (@) --todo: ユーザ定義演算子なくなった対応
    , isPreviosPos
    , makeRange

    , Buffer
    , init

    , line
    , currentLine
    , readRange
    , selectedString

    -- history
    , EditCommand(..) --, EditCommand(Cmd_Insert, Cmd_Backspace, Cmd_Delete) -- todo: 隠蔽の再設計

    -- cursor move
    , moveForward
    , moveBackward
    , movePreviosLine
    , moveNextLine
    , moveNextWord
    , movePreviosWord
    , moveAt

    -- selection
    , selectBackward
    , selectForward
    , selectPreviosLine
    , selectNextLine
    , selectPreviosWord
    , selectNextWord
    , selectAt
    , selectionClear

    -- mark
    , Mark -- for elm-test
    , markSet
    , markClear
    , gotoMark
    , isMarkActive

    -- edit
    , insert
    , insertAt
    , backspace
    , backspaceAt
    , delete
    , deleteAt
    , deleteRange
    , deleteSelection
    , undo
    )

{-|

# Definition
@docs Buffer, Position, Range, Mark, EditCommand

# Position and Range helpers
@docs (@), isPreviosPos
@docs makeRange

# Mark operating
@docs markSet, markClear, gotoMark, isMarkActive

## Model Helpler
@docs init
@docs line, currentLine, readRange, selectedString

# Move cursor and move cursor while selecting
@docs moveForward, moveBackward, movePreviosLine, moveNextLine, moveNextWord, movePreviosWord, moveAt
@docs selectBackward, selectForward, selectPreviosLine, selectNextLine, selectPreviosWord, selectNextWord, selectAt, selectionClear

# Editing contents
@docs insert, insertAt
@docs backspace, backspaceAt
@docs delete, deleteAt, deleteRange, deleteSelection

# Undo / Redo
@docs undo
-}

import TextEditor.StringExtra as StringExtra

------------------------------------------------------------
-- Definitions
------------------------------------------------------------

{-| Charactor position. 0 origin.
-}
type alias Position =
    { row : Int
    , column : Int
    }

{-| Make position (Syntax Suger)

--Use like `row @ col`
---}
--(@) : Int -> Int -> Position
--(@) = Position


position_toTuple : Position -> (Int, Int)
position_toTuple pos = (pos.row, pos.column)

position_fromTuple : (Int, Int) -> Position
position_fromTuple (r, c) = { row = r, column=c }

{-| Range of charactor positions 
-}
type alias Range =
    { begin : Position
    , end : Position
    }

{-| Create a range from two tuples
-}
makeRange : (Int, Int) -> (Int, Int) -> Range
makeRange (br, bc) (er, ec) =
    Range (Position br bc) (Position er ec)

{-| The buffer model

* `cursor`    .. Current cursor Position
* `selection` .. selected text range. If you not selected text, this member is Nothing.
* `mark`      .. Emacs like mark. Has marked-position and (select by moving) is active? flag.
* `contents`  .. Line separated text.
* `history`   .. Operating history for `undo`/`redo`
-}
type alias Buffer =
    { cursor : Position
    , selection : Maybe Range
    , mark : Maybe Mark
    , contents : List String
    , history : List EditCommand
    }

{-| Create buffer.
-}
init : String -> Buffer
init text =
    Buffer (Position 0 0)         -- cursor
          Nothing                -- selection
          Nothing                -- mark
          (String.lines text)    -- contents
          []                     -- history


-- buffer > cursor

defaultCursor : List String -> Position
defaultCursor contents =             
    let
        n = List.length contents
    in
        Position (if n < 0 then 0 else n) 0

{-| Determine which of the two `Position` is before
-} 
isPreviosPos : Position -> Position -> Bool
isPreviosPos p q =
    if p.row == q.row
    then p.column < q.column
    else p.row < q.row


-- buffer > contents

{-| Get a line by line number
-}
line : Int -> Buffer -> Maybe String
line n buf =
    nth n buf.contents

{-| Get current line
-}
currentLine : Buffer -> String
currentLine buf =
    line buf.cursor.row buf |> Maybe.withDefault ""

nth : Int -> List a -> Maybe a
nth n lst =
    if n < 0
    then Nothing
    else List.head (List.drop n lst)

--(!!) : List a -> Int -> Maybe a
--(!!) lst n =
--    if n < 0
--    then Nothing
--    else List.head (List.drop n lst)

maxColumn: String -> Int
maxColumn l =
    (String.length l) - 1

maxRow : List String -> Int
maxRow contents =
    (List.length contents) - 1

-- selection

{-| Retrieve the character string in the specified range
-}
readRange : Range -> Buffer -> String
readRange sel model =
    let
        bpos = if (isPreviosPos sel.begin sel.end) then sel.begin else sel.end
        epos = if (isPreviosPos sel.begin sel.end) then sel.end else sel.begin

        lcnt = epos.row - bpos.row
    in
        case lcnt of
            0 ->
                let 
                    l = model.contents |> nth bpos.row  |> Maybe.withDefault ""
                in
                    l |> String.dropLeft bpos.column |> String.left (epos.column - bpos.column)
            _ ->
                let
                    bl = model.contents |> nth bpos.row |> Maybe.withDefault "" |> String.dropLeft bpos.column
                    el = model.contents |> nth epos.row |> Maybe.withDefault "" |> String.left epos.column

                    ls = model.contents |> List.drop (bpos.row + 1) |> List.take (lcnt - 1)
                in
                    String.join "\n" ((bl :: ls) ++ [el])

{-| Retrieve the selected character string
-}
selectedString : Buffer -> Maybe String
selectedString model =
    Maybe.andThen (\sel-> readRange sel model |> Just ) model.selection 

-- mark

{-| Emacs like Mark 
-}
type alias Mark =
    { pos : Position
    , actived : Bool
    }

{-| Set Mark to Position and make it active
-}
markSet : Buffer -> Buffer
markSet model =
    let
        pos = model.cursor
        new_mark = { pos = pos
                   , actived = True
                   }
    in
        { model
            | mark = Just new_mark 
            , selection = Just <| Range pos pos
        }

{-| Deactivate mark
-}
markClear : Buffer -> Buffer
markClear model =
    case model.mark of
        Just mk ->
            { model
                | mark      = Just <| { mk | actived = False }
                , selection = Nothing
            }
        Nothing ->
            model

{-| (It is inactive at the time of Nothing)
-}
isMarkActive : Buffer -> Bool
isMarkActive model =
    case model.mark of
        Just mk -> mk.actived
        Nothing -> False

{-| Move to the position where the cursor is marked and memorize the original cursor position in the mark.
-}
gotoMark : Buffer -> Buffer 
gotoMark model =
    case model.mark of
        Just mk ->
            model
                |> markSet
                |> moveAt mk.pos
        Nothing ->
            model

{- 編集に際して動いてしまったマーク位置の辻褄を合わせる
   (たとえば、マークの前の文字を削除すればその分マークは一つ前に動く)
 -}                
updateMark : EditCommand -> Buffer -> Buffer
updateMark cmd model =
    case model.mark of
        Just mk ->
            let
                count_lf             = String.lines >> List.length >> \n -> n - 1
                count_last_line_char = String.lines >> List.reverse >> List.head >> Maybe.withDefault "" >> String.length
            in
                case cmd of
                    Cmd_Insert bfr afr s _ ->
                        if mk.pos.row > bfr.row then
                            { model | mark = Just { mk | pos = (Position (mk.pos.row + afr.row - bfr.row) mk.pos.column) } }
                        else if (mk.pos.row == bfr.row) && (bfr.column <= mk.pos.column) then
                            let
                                add_line_cnt = count_lf s
                                new_col = if add_line_cnt == 0 then mk.pos.column + (afr.column - bfr.column)
                                                               else (count_last_line_char s) + (mk.pos.column - bfr.column)
                            in
                                { model | mark = Just { mk | pos = (Position (mk.pos.row + add_line_cnt) new_col) } }
                        else
                           model

                    Cmd_Backspace before_pos after_pos s _ ->
                        { model
                              | mark = Just <| { mk | pos = updateMarkPos_byDelete after_pos s mk.pos}
                        }

                    Cmd_Delete before_pos after_pos s _ ->
                        { model
                            | mark = Just <| { mk | pos = updateMarkPos_byDelete before_pos s mk.pos}
                        }
                            
        Nothing ->
            model


updateMarkPos_byDelete : Position -> String -> Position -> Position
updateMarkPos_byDelete bgn_pos s marked_pos =
    let
        count_lf             = String.lines >> List.length >> \n -> n - 1
        count_last_line_char = String.lines >> List.reverse >> List.head >> Maybe.withDefault "" >> String.length

        deleted_lf_cnt            = count_lf s
        deleted_lastline_char_cnt = count_last_line_char s

        (end_row, end_col) = ( bgn_pos.row + deleted_lf_cnt
                             , if (deleted_lf_cnt == 0) then bgn_pos.column + deleted_lastline_char_cnt else deleted_lastline_char_cnt
                             )
    in
        -- before mark
        if end_row < marked_pos.row then
            (Position (marked_pos.row - deleted_lf_cnt) marked_pos.column)

        else if (marked_pos.row == end_row) && (end_col < marked_pos.column) then
            if ( end_row /= bgn_pos.row) then
                (Position (marked_pos.row - deleted_lf_cnt) (marked_pos.column + bgn_pos.column))
            else
                (Position marked_pos.row (marked_pos.column - deleted_lastline_char_cnt))

        -- contain mark
        else if    ( (bgn_pos.row < marked_pos.row) || (bgn_pos.row == marked_pos.row && bgn_pos.column <= marked_pos.column) )
                && ( (marked_pos.row < end_row) || (end_row == marked_pos.row && marked_pos.column <= end_col ) ) then
            bgn_pos

        -- after mark
        else
            marked_pos

------------------------------------------------------------
-- History
------------------------------------------------------------

{-| Data for undo

Each data type has a cursor position before editing, 
a cursor position after editing, 
an edited character string (inserted string at `Cmd_Insert`, deleted string at `Cmd_Delete` and `Cmd_Backspace`),
and a mark position before editing.
-}
type EditCommand
    = Cmd_Insert Position Position String (Maybe Mark)    -- befor-cur after-cur inserted_str
    | Cmd_Backspace Position Position String (Maybe Mark) -- befor-cur after-cur deleted_str
    | Cmd_Delete Position Position String (Maybe Mark)    -- befor-cur after-cur deleted_str
--    | Cmd_Undo EditCommand

appendHistory: EditCommand -> Buffer -> Buffer
appendHistory cmd model =
    case (cmd, List.head model.history) of
        ( (Cmd_Insert befor after s mk), Just (Cmd_Insert old_befor old_after old_s old_mk) ) ->
            if (befor.row == old_befor.row) && (befor.column == old_after.column)
            then { model | history = (Cmd_Insert old_befor after (old_s ++ s) old_mk) :: List.drop 1 model.history }
            else { model | history = cmd :: model.history }

        ( (Cmd_Backspace befor after s mk), Just (Cmd_Backspace old_befor old_after old_s old_mk) ) ->
            if (befor.row == old_befor.row) && (befor.column == old_after.column)
            then { model | history = (Cmd_Backspace old_befor after (s ++ old_s) old_mk) :: List.drop 1 model.history }
            else { model | history = cmd :: model.history }

        ( (Cmd_Delete befor after s mk), Just (Cmd_Delete old_befor old_after old_s old_mk) ) ->
            if (befor.row == old_befor.row) && (befor.column == old_befor.column)
            then { model | history = (Cmd_Delete old_befor after (old_s ++ s) old_mk) :: List.drop 1 model.history }
            else { model | history = cmd :: model.history }

        (_ , _) ->
            { model | history = cmd :: model.history }

------------------------------------------------------------
-- Cursor move
------------------------------------------------------------

{-|
-}
moveForward : Buffer -> Buffer
moveForward model =
    case isMarkActive model of
        True  -> selectWithMove moveForwardProc model
        False -> model |> moveForwardProc |> selectionClear

{-|
-}
moveBackward : Buffer -> Buffer
moveBackward model =
    case isMarkActive model of
        True  -> selectWithMove moveBackwardProc model
        False -> model |> moveBackwardProc |> selectionClear

{-|
-}
movePreviosLine : Buffer -> Buffer
movePreviosLine model =
    case isMarkActive model of
        True  -> selectWithMove movePreviosLineProc model
        False -> model |> movePreviosLineProc |> selectionClear

{-|
-}
moveNextLine : Buffer -> Buffer
moveNextLine model =
    case isMarkActive model of
        True  -> selectWithMove moveNextLineProc model
        False -> model |>  moveNextLineProc |> selectionClear

{-|
-}
moveAt : Position -> Buffer -> Buffer
moveAt pos model =
    case isMarkActive model of
        True  -> selectWithMove (moveAtProc pos) model
        False -> model |>  moveAtProc pos |> selectionClear

{-|
-}
moveNextWord : Buffer -> Buffer
moveNextWord model =
    case isMarkActive model of
        True  -> selectWithMove (moveNextWordProc model.cursor) model
        False -> model |> moveNextWordProc model.cursor |> selectionClear
{-|
-}
movePreviosWord : Buffer -> Buffer
movePreviosWord model =
    case isMarkActive model of
        True  -> selectWithMove (movePreviosWordProc model.cursor) model
        False -> model |> movePreviosWordProc model.cursor |> selectionClear



moveForwardProc : Buffer -> Buffer
moveForwardProc model =
    let
        cur = model.cursor
    in
        model.contents |> nth cur.row
        |> Maybe.andThen
            (\ ln -> 
                case (cur.column < (maxColumn ln) + 1, cur.row < maxRow model.contents) of
                    (True , _    ) -> Just {cur| column = cur.column + 1}
                    (False, True ) -> Just {cur| column = 0, row = cur.row +1}
                    (False, False) -> Just cur

            )
        |> Maybe.withDefault (defaultCursor model.contents)
        |> (\ c -> {model | cursor = c})

moveBackwardProc : Buffer -> Buffer
moveBackwardProc model =
    let
        cur = model.cursor
        pln = model.contents |> nth (cur.row - 1) |> Maybe.withDefault ""
    in
        model.contents |> nth cur.row 
        |> Maybe.andThen
            (\ ln -> 
                case (cur.column > 0, cur.row > 0 ) of
                    (True , _    ) -> Just {cur| column = cur.column - 1}
                    (False, True ) -> Just {cur| column = (String.length pln), row = cur.row - 1}
                    (False, False) -> Just cur

            )
        |> Maybe.withDefault (defaultCursor model.contents)
        |> (\ c -> {model | cursor = c})

movePreviosLineProc : Buffer -> Buffer
movePreviosLineProc model =
    let
        cur = model.cursor
    in
        model.contents |> nth (cur.row - 1)
        |> Maybe.andThen
            (\ ln -> 
                case cur.column < (maxColumn ln) + 1 of
                    True  -> Just {cur| row = cur.row - 1}
                    False -> Just {cur| row = cur.row - 1, column = (maxColumn ln) + 1}
            )
        |> Maybe.withDefault cur
        |> (\ c -> {model | cursor = c})

moveNextLineProc : Buffer -> Buffer
moveNextLineProc model =
    let
        cur = model.cursor
    in
        model.contents |> nth (cur.row + 1)
        |> Maybe.andThen
            (\ ln -> 
                case cur.column < (maxColumn ln) + 1 of
                    True  -> Just {cur| row = cur.row + 1}
                    False -> Just {cur| row = cur.row + 1, column = (maxColumn ln) + 1}
            )
        |> Maybe.withDefault cur
        |> (\ c -> {model | cursor = c})

moveAtProc : Position -> Buffer -> Buffer
moveAtProc pos model =
    { model | cursor = pos }


moveNextWordProc : Position -> Buffer -> Buffer
moveNextWordProc cur model =
    let
        last_row = (List.length model.contents) - 1

        col = StringExtra.nextWordPos ( model.contents |> nth cur.row |> Maybe.withDefault "") cur.column
    in
        case col of
            Just nchar ->
                moveAtProc (Position cur.row nchar) model
            Nothing ->
                if cur.row + 1 > last_row then
                    moveAtProc (Position last_row (model.contents |> nth last_row
                                              |> Maybe.withDefault ""
                                              |> String.length
                                          )
                               ) model
                else
                    moveNextWordProc (Position (cur.row + 1) 0) model


movePreviosWordProc : Position -> Buffer -> Buffer
movePreviosWordProc cur model =
    let
        col = StringExtra.previosWordPos (model.contents |> nth cur.row |> Maybe.withDefault "") cur.column
    in
        case col of
            Just nchar ->
                moveAtProc (Position cur.row nchar) model
            Nothing ->
                if cur.row - 1  < 0 then
                    moveAtProc (Position 0 0) model
                else
                    movePreviosWordProc (Position
                                             (cur.row - 1)
                                             (model.contents |> nth (cur.row - 1) |> Maybe.withDefault "" |> String.length)
                                        ) model



------------------------------------------------------------
-- selection (with cursor move)
------------------------------------------------------------

{-|
-}
selectBackward: Buffer -> Buffer
selectBackward = selectWithMove moveBackwardProc
                 << \m -> if isMarkActive m then markClear m else m

{-|
-}
selectForward: Buffer -> Buffer
selectForward = selectWithMove moveForwardProc
                 << \m -> if isMarkActive m then markClear m else m


{-|
-}
selectPreviosLine: Buffer -> Buffer
selectPreviosLine = selectWithMove movePreviosLineProc
                 << \m -> if isMarkActive m then markClear m else m

{-|
-}
selectNextLine: Buffer -> Buffer
selectNextLine = selectWithMove moveNextLineProc
                 << \m -> if isMarkActive m then markClear m else m

{-|
-}
selectPreviosWord: Buffer -> Buffer
selectPreviosWord = selectWithMove (\m -> movePreviosWordProc m.cursor m)
                 << \m -> if isMarkActive m then markClear m else m

{-|
-}
selectNextWord: Buffer -> Buffer
selectNextWord = selectWithMove (\m -> moveNextWordProc m.cursor m)
                 << \m -> if isMarkActive m then markClear m else m


{-|
-}
selectAt: Position -> Buffer -> Buffer
selectAt pos = selectWithMove (moveAtProc pos)
                 << \m -> if isMarkActive m then markClear m else m


{-|
-}
selectionClear: Buffer -> Buffer
selectionClear model =
    { model
        | selection = Nothing
        , mark = model.mark |> Maybe.andThen (\mk -> Just { mk | actived = False })
    }




-- Tool

selectWithMove : (Buffer -> Buffer) -> Buffer -> Buffer
selectWithMove move_f model =
    model
        |> \m1 -> { m1 | selection = m1.selection |> Maybe.withDefault (Range m1.cursor m1.cursor) |> Just }
        |> move_f
        |> \m2 -> { m2 | selection = m2.selection |> Maybe.andThen (\s -> Just (Range s.begin m2.cursor)) }

------------------------------------------------------------
-- edit
------------------------------------------------------------


{-| Insert character at current cursor position.
-}
insert : String -> Buffer -> Buffer
insert text model=
    case model.selection of
        Nothing ->
            insertAt model.cursor text model
        Just s ->
            model
                |> deleteRange s
                |> selectionClear
                |> (\m -> insertAt m.cursor text m)

{-| Insert character at specified position
-}
insertAt: Position -> String -> Buffer -> Buffer
insertAt pos text model =
    model
    |> insert_proc pos text
    |> (\m ->
            let
                edtcmd = Cmd_Insert pos m.cursor text m.mark
            in
                m |> appendHistory edtcmd
                  |> updateMark edtcmd
       )

{-| Delete charactor before current cursor position, and cursor back to deleted char(s) before.
-}
backspace : Buffer -> Buffer
backspace model =
    case model.selection of
        Nothing ->
            backspaceAt model.cursor model
        Just s ->
            model
                |> deleteRange s
                |> selectionClear

{-| Delete charactor(s) before specified position, and cursor back to deleted char(s) before.
-}
backspaceAt: Position -> Buffer -> Buffer
backspaceAt pos model =
    let
        (m, deleted) = backspace_proc pos model 
    in
        case deleted of
            Nothing ->
                m
            Just s ->
                m
                |> (\m2 ->
                        let
                            edtcmd = Cmd_Backspace pos m2.cursor s m2.mark
                        in
                            m2 |> appendHistory edtcmd
                               |> updateMark edtcmd
                   )

{-| Delete charactor at current cursor positon.
-}
delete : Buffer -> Buffer
delete model =
    case model.selection of
        Nothing ->
            deleteAt model.cursor model
        Just s ->
            model
                |> deleteRange s
                |> selectionClear

{-| Delete charactor at specified positon.
-}
deleteAt: Position -> Buffer -> Buffer
deleteAt pos model =
    let
        (m, deleted) = delete_proc pos model
    in
        case deleted of
            Nothing ->
                m
            Just s ->
                m
                |> (\m2 ->
                        let
                            edtcmd = Cmd_Delete pos m2.cursor s m2.mark
                        in
                            m2 |> appendHistory edtcmd
                               |> updateMark edtcmd
                   )

{-| Delete charactor at specified positions range.
-}
deleteRange: Range -> Buffer -> Buffer
deleteRange range model =
    let
        deleted  = readRange range model
        head_pos = if (isPreviosPos range.begin range.end) then range.begin else range.end
    in
        case deleted of
            "" ->
                model
            _ ->
                model
                    |> delete_range_proc range
                    |> (\m ->
                            let
                                edtcmd = Cmd_Delete head_pos m.cursor deleted m.mark
                            in
                                m |> appendHistory edtcmd
                                  |> updateMark edtcmd
                       )


{-| Delete charactor at current selection range.
-}
deleteSelection: Buffer -> Buffer
deleteSelection model =
    case model.selection of
        Nothing ->
            model
        Just s  ->
            model
                |> deleteRange s
                |> selectionClear


{-| undo editing
-}
undo : Buffer -> Buffer
undo model =
    case List.head model.history of
        Nothing -> model
        Just cmd ->
            ( case cmd of
                  Cmd_Insert before_cur after_cur str mk   ->
                      model
                          |> undo_insert_proc before_cur after_cur str
                          |> \m -> { m | mark = mk}

                  Cmd_Backspace before_cur after_cur str mk ->
                      model
                          |> undo_backspace_proc before_cur after_cur str
                          |> \m -> { m | mark = mk }

                  Cmd_Delete before_cur after_cur str mk    ->
                      model
                          |> undo_delete_proc before_cur after_cur str
                          |> \m -> { m | mark = mk }
            )
            |> (\ m -> {m | history = List.drop 1 m.history })




------------------------------------------------------------
-- (private) edit
------------------------------------------------------------

insert_proc: Position -> String -> Buffer -> Buffer
insert_proc pos text model =
    let
        (row, col) = position_toTuple pos

        contents = model.contents
        prows = List.take row contents
        crow  = model.contents |> nth row |> Maybe.withDefault ""
        nrows = List.drop (row + 1) contents

        texts = (String.lines text)
        left  = (String.left col crow)
        right = (String.dropLeft (col) crow)

        car = List.head >> Maybe.withDefault ""
    in
        case List.length texts of
            0 ->
                model
            1 ->
                { model
                    | contents = prows ++ ((left ++ text ++ right) :: nrows)
                    , cursor = Position row (col + (String.length text))
                }
            2 ->
                let
                    fst_ln = car texts
                    lst_ln = car <| List.drop 1 texts
                in
                    { model
                        | contents = prows ++ [ left ++ fst_ln, lst_ln ++ right]
                                           ++ nrows
                         , cursor = Position (row + 1) (String.length lst_ln)
                    }
            n ->
                let
                    fst_ln = car texts
                    lst_ln = car <| List.drop (n - 1) texts
                in
                    { model
                        | contents = prows ++ [ left ++ fst_ln ] ++ (List.drop 1 (List.take (n - 1) texts)) ++ [lst_ln ++ right]
                                           ++ nrows
                        , cursor = Position (row + n - 1) (String.length lst_ln)
                    }

backspace_proc: Position -> Buffer -> (Buffer, Maybe String)
backspace_proc pos model =
    case (position_toTuple pos) of
        (0, 0) ->
            (model, Nothing)

        (row, 0) ->
            let
                prows  = List.take (row - 1) model.contents
                crow   = List.drop (row - 1) model.contents |> List.take 2 |> String.concat
                nrows  = List.drop (row + 1) model.contents

                n_col  = List.drop (row - 1) model.contents |> List.head |> Maybe.withDefault "" |> String.length
            in
                ( { model
                      | contents = prows ++ (crow :: nrows )
                      , cursor = Position (row - 1) (n_col)
                  }
                , Just "\n")

        (row, col) ->
            let
                prows = List.take row model.contents
                crow  = model.contents |> nth row |> Maybe.withDefault ""
                nrows = List.drop (row + 1) model.contents

                left  = (String.left (col - 1) crow)
                right = (String.dropLeft (col) crow)
            in
                ( { model
                      | contents = prows ++ ((left ++ right) :: nrows)
                      , cursor = Position row  (col - 1)
                  }
                , Just (crow |> String.dropLeft (col - 1) |> String.left 1) )


delete_proc: Position -> Buffer -> (Buffer, Maybe String)
delete_proc pos model =
    let
        (row, col) = position_toTuple pos

        ln      = model.contents |> nth row |> Maybe.withDefault ""
        max_row = maxRow model.contents
        max_col = maxColumn ln
    in
        case (row == max_row, col > max_col) of
             (True, True)  ->
                 (model , Nothing)

             (_   , False) ->
                 let
                     prows  = List.take row model.contents
                     nrows  = List.drop (row + 1) model.contents

                     current = (String.left (col) ln) ++ (String.dropLeft (col + 1) ln)
                 in
                     ( { model
                           | contents = prows ++ (current :: nrows)
                           , cursor = Position row col
                       }
                     , Just (ln |> String.dropLeft col |> String.left 1) )

             (_   , True) ->
                 let
                     prows  = List.take row model.contents
                     nxt    = model.contents |> nth (row + 1) |> Maybe.withDefault ""
                     nrows  = List.drop (row + 2) model.contents

                     current = ln ++ nxt
                 in
                     ( { model
                           | contents = prows ++ (current :: nrows)
                           , cursor = Position row col
                       }
                     , Just "\n" )


delete_range_proc : Range -> Buffer -> Buffer
delete_range_proc sel model =
    let
        bpos = if (isPreviosPos sel.begin sel.end) then sel.begin else sel.end
        epos = if (isPreviosPos sel.begin sel.end) then sel.end else sel.begin

        lcnt = epos.row - bpos.row
    in
        case lcnt of
            0 ->
                let 
                    ln  = model.contents |> nth bpos.row  |> Maybe.withDefault ""
                    current = (String.left bpos.column ln) ++ (String.dropLeft epos.column ln)

                    pls = List.take (bpos.row    ) model.contents
                    nls = List.drop (epos.row + 1) model.contents
                in
                    { model
                        | contents = pls ++ (current :: nls)
                        , cursor = bpos
                    }
            _ ->
                let
                    bln  = model.contents |> nth bpos.row |> Maybe.withDefault "" |> String.left bpos.column
                    eln  = model.contents |> nth epos.row |> Maybe.withDefault "" |> String.dropLeft epos.column
                    pls = List.take (bpos.row    ) model.contents
                    nls = List.drop (epos.row + 1) model.contents
                in
                    { model
                        | contents = pls ++ ((bln ++ eln) :: nls)
                        , cursor = bpos
                    }

    
undo_insert_proc : Position -> Position -> String -> Buffer -> Buffer
undo_insert_proc bf_pos af_pos str model =
    delete_range_proc (Range bf_pos af_pos) model

undo_backspace_proc : Position -> Position -> String -> Buffer ->Buffer
undo_backspace_proc bf_pos af_pos str model =
    insert_proc af_pos str model 

undo_delete_proc : Position -> Position -> String -> Buffer ->Buffer
undo_delete_proc bf_pos af_pos str model =
    insert_proc bf_pos str model
        |> (\m -> { m | cursor = bf_pos })

