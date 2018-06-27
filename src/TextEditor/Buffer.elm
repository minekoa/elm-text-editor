module TextEditor.Buffer exposing
    ( Position
    , Range
    , (@)
    , makeRange


                                  , Model
                                  , init

                                  , isPreviosPos
                                  , line
                                  , readRange
                                  , selectedString

                                  -- history
                                  , EditCommand(Cmd_Insert, Cmd_Backspace, Cmd_Delete)

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

# Definitions

@docs Position, Range

# Selections

                                  -- selection
                                  , selectBackward
                                  , selectForward
                                  , selectPreviosLine
                                  , selectNextLine
                                  , selectPreviosWord
                                  , selectNextWord
                                  , selectAt
                                  , selectionClear


# Marks

@docs Mark
@docs markSet, markClear, gotoMark, isMarkActive

# Editing

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

{-| Charactor position
-}
type alias Position =
    { row : Int
    , column : Int
    }

{-| Make position
-}
(@) : Int -> Int -> Position
(@) = Position


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

{-|
* `cursor`    .. Current cursor Position
* `selection` .. selected text range. If you not selected text, this member is Nothing.
* `mark`      .. Emacs like mark.
* `contents`  .. Line separated text.
* `history`   .. Operating history for `undo`/`redo`
-}
type alias Model =
    { cursor : Position
    , selection : Maybe Range
    , mark : Maybe Mark
    , contents : List String
    , history : List EditCommand
    }

init : String -> Model
init text =
    Model (Position 0 0)           -- cursor
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

nowCursorPos : Model -> (Int, Int)
nowCursorPos model = 
    model.cursor |> position_toTuple

isPreviosPos : Position -> Position -> Bool
isPreviosPos p q =
    if p.row == q.row
    then p.column < q.column
    else p.row < q.row


-- buffer > contents

line : Int -> List String -> Maybe String
line n lines =
    if n < 0
    then Nothing
    else List.head (List.drop n lines)

maxColumn: String -> Int
maxColumn line =
    (String.length line) - 1

maxRow : List String -> Int
maxRow contents =
    (List.length contents) - 1

-- selection

{-| Retrieve the character string in the specified range
-}
readRange : Range -> Model -> String
readRange sel model =
    let
        bpos = if (isPreviosPos sel.begin sel.end) then sel.begin else sel.end
        epos = if (isPreviosPos sel.begin sel.end) then sel.end else sel.begin

        lcnt = epos.row - bpos.row
    in
        case lcnt of
            0 ->
                let 
                    l = line bpos.row model.contents |> Maybe.withDefault ""
                in
                    l |> String.dropLeft bpos.column |> String.left (epos.column - bpos.column)
            _ ->
                let
                    bl = model.contents |> line bpos.row |> Maybe.withDefault "" |> String.dropLeft bpos.column
                    el = model.contents |> line epos.row |> Maybe.withDefault "" |> String.left epos.column

                    ls = model.contents |> List.drop (bpos.row + 1) |> List.take (lcnt - 1)
                in
                    String.join "\n" ((bl :: ls) ++ [el])

{-| Retrieve the selected character string
-}
selectedString : Model -> Maybe String
selectedString model =
    Maybe.andThen (\sel-> readRange sel model |> Just ) model.selection 

-- mark

type alias Mark =
    { pos : (Int, Int)
    , actived : Bool
    }

markSet : Model -> Model
markSet model =
    let
        pos = model.cursor
        new_mark = { pos = (pos |> position_toTuple)
                   , actived = True
                   }
    in
        { model
            | mark = Just new_mark 
            , selection = Just <| Range pos pos
        }

markClear : Model -> Model
markClear model =
    case model.mark of
        Just mk ->
            { model
                | mark      = Just <| { mk | actived = False }
                , selection = Nothing
            }
        Nothing ->
            model

isMarkActive : Model -> Bool
isMarkActive model =
    case model.mark of
        Just mk -> mk.actived
        Nothing -> False

gotoMark : Model -> Model 
gotoMark model =
    case model.mark of
        Just mk ->
            model
                |> markSet
                |> moveAt (mk.pos |> position_fromTuple)
        Nothing ->
            model

updateMark : EditCommand -> Model -> Model
updateMark cmd model =
    case model.mark of
        Just mk ->
            let
                mk_row = mk.pos |> Tuple.first
                mk_col = mk.pos |> Tuple.second

                count_lf             = String.lines >> List.length >> flip (-) 1
                count_last_line_char = String.lines >> List.reverse >> List.head >> Maybe.withDefault "" >> String.length
            in
                case cmd of
                    Cmd_Insert bfr afr s _ ->
                        if mk_row > bfr.row then
                            { model | mark = Just { mk | pos = (mk_row + afr.row - bfr.row, mk_col) } }
                        else if (mk_row == bfr.row) && (bfr.column <= mk_col) then
                            let
                                add_line_cnt = count_lf s
                                new_col = if add_line_cnt == 0 then mk_col + (afr.column - bfr.column)
                                                               else (count_last_line_char s) + (mk_col - bfr.column)
                            in
                                { model | mark = Just { mk | pos = (mk_row + add_line_cnt, new_col) } }
                        else
                           model

                    Cmd_Backspace before_pos after_pos s _ ->
                        { model
                              | mark = Just <| { mk | pos = updateMarkPos_byDelete (after_pos |> position_toTuple) s mk.pos}
                        }

                    Cmd_Delete before_pos after_pos s _ ->
                        { model
                            | mark = Just <| { mk | pos = updateMarkPos_byDelete (before_pos |> position_toTuple) s mk.pos}
                        }
                            
        Nothing ->
            model


updateMarkPos_byDelete : (Int, Int) -> String -> (Int, Int) -> (Int, Int)
updateMarkPos_byDelete bgn_pos s (mk_row, mk_col) =
    let
        count_lf             = String.lines >> List.length >> flip (-) 1
        count_last_line_char = String.lines >> List.reverse >> List.head >> Maybe.withDefault "" >> String.length

        deleted_lf_cnt            = count_lf s
        deleted_lastline_char_cnt = count_last_line_char s

        (bgn_row, bgn_col) = bgn_pos
        (end_row, end_col) = ( bgn_row + deleted_lf_cnt
                             , if (deleted_lf_cnt == 0) then bgn_col + deleted_lastline_char_cnt else deleted_lastline_char_cnt
                             )
    in
        -- before mark
        if end_row < mk_row then
            (mk_row - deleted_lf_cnt, mk_col)

        else if (mk_row == end_row) && (end_col < mk_col) then
            if ( end_row /= bgn_row) then
                (mk_row - deleted_lf_cnt, mk_col + bgn_col)
            else
                (mk_row, mk_col - deleted_lastline_char_cnt)

        -- contain mark
        else if    ( (bgn_row < mk_row) || (bgn_row == mk_row && bgn_col <= mk_col) )
                && ( (mk_row < end_row) || (end_row == mk_row && mk_col <= end_col ) ) then
            (bgn_row, bgn_col)

        -- after mark
        else
            (mk_row, mk_col)

------------------------------------------------------------
-- History
------------------------------------------------------------

type EditCommand
    = Cmd_Insert Position Position String (Maybe Mark)    -- befor-cur after-cur inserted_str
    | Cmd_Backspace Position Position String (Maybe Mark) -- befor-cur after-cur deleted_str
    | Cmd_Delete Position Position String (Maybe Mark)    -- befor-cur after-cur deleted_str
--    | Cmd_Undo EditCommand

appendHistory: EditCommand -> Model -> Model
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

moveForward : Model -> Model
moveForward model =
    case isMarkActive model of
        True  -> selectWithMove moveForwardProc model
        False -> model |> moveForwardProc |> selectionClear

moveBackward : Model -> Model
moveBackward model =
    case isMarkActive model of
        True  -> selectWithMove moveBackwardProc model
        False -> model |> moveBackwardProc |> selectionClear

movePreviosLine : Model -> Model
movePreviosLine model =
    case isMarkActive model of
        True  -> selectWithMove movePreviosLineProc model
        False -> model |> movePreviosLineProc |> selectionClear

moveNextLine : Model -> Model
moveNextLine model =
    case isMarkActive model of
        True  -> selectWithMove moveNextLineProc model
        False -> model |>  moveNextLineProc |> selectionClear

moveAt : Position -> Model -> Model
moveAt pos model =
    case isMarkActive model of
        True  -> selectWithMove (moveAtProc pos) model
        False -> model |>  moveAtProc pos |> selectionClear


moveForwardProc : Model -> Model
moveForwardProc model =
    let
        cur = model.cursor
    in
        line cur.row model.contents 
        |> Maybe.andThen
            ( λ ln -> 
                case (cur.column < (maxColumn ln) + 1, cur.row < maxRow model.contents) of
                    (True , _    ) -> Just {cur| column = cur.column + 1}
                    (False, True ) -> Just {cur| column = 0, row = cur.row +1}
                    (False, False) -> Just cur

            )
        |> Maybe.withDefault (defaultCursor model.contents)
        |> (λ c -> {model | cursor = c})

moveBackwardProc : Model -> Model
moveBackwardProc model =
    let
        cur = model.cursor
        pln = line (cur.row - 1) model.contents |> Maybe.withDefault ""
    in
        line cur.row model.contents 
        |> Maybe.andThen
            ( λ ln -> 
                case (cur.column > 0, cur.row > 0 ) of
                    (True , _    ) -> Just {cur| column = cur.column - 1}
                    (False, True ) -> Just {cur| column = (String.length pln), row = cur.row - 1}
                    (False, False) -> Just cur

            )
        |> Maybe.withDefault (defaultCursor model.contents)
        |> (λ c -> {model | cursor = c})

movePreviosLineProc : Model -> Model
movePreviosLineProc model =
    let
        cur = model.cursor
    in
        line (cur.row - 1) model.contents 
        |> Maybe.andThen
            ( λ ln -> 
                case cur.column < (maxColumn ln) + 1 of
                    True  -> Just {cur| row = cur.row - 1}
                    False -> Just {cur| row = cur.row - 1, column = (maxColumn ln) + 1}
            )
        |> Maybe.withDefault cur
        |> (λ c -> {model | cursor = c})

moveNextLineProc : Model -> Model
moveNextLineProc model =
    let
        cur = model.cursor
    in
        line (cur.row + 1) model.contents 
        |> Maybe.andThen
            ( λ ln -> 
                case cur.column < (maxColumn ln) + 1 of
                    True  -> Just {cur| row = cur.row + 1}
                    False -> Just {cur| row = cur.row + 1, column = (maxColumn ln) + 1}
            )
        |> Maybe.withDefault cur
        |> (λ c -> {model | cursor = c})

moveAtProc : Position -> Model -> Model
moveAtProc pos model =
    { model | cursor = pos }


moveNextWord : Model -> Model
moveNextWord model =
    case isMarkActive model of
        True  -> selectWithMove (moveNextWordProc model.cursor) model
        False -> model |> moveNextWordProc model.cursor |> selectionClear

moveNextWordProc : Position -> Model -> Model
moveNextWordProc cur model =
    let
        last_row = (List.length model.contents) - 1

        col = StringExtra.nextWordPos (line cur.row model.contents |> Maybe.withDefault "") cur.column
    in
        case col of
            Just nchar ->
                moveAtProc (Position cur.row nchar) model
            Nothing ->
                if cur.row + 1 > last_row then
                    moveAtProc (Position last_row (line last_row model.contents
                                              |> Maybe.withDefault ""
                                              |> String.length
                                          )
                               ) model
                else
                    moveNextWordProc (Position (cur.row + 1) 0) model


movePreviosWord : Model -> Model
movePreviosWord model =
    case isMarkActive model of
        True  -> selectWithMove (movePreviosWordProc model.cursor) model
        False -> model |> movePreviosWordProc model.cursor |> selectionClear

movePreviosWordProc : Position -> Model -> Model
movePreviosWordProc cur model =
    let
        col = StringExtra.previosWordPos (line cur.row model.contents |> Maybe.withDefault "") cur.column
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
                                             (line (cur.row - 1) model.contents |> Maybe.withDefault "" |> String.length)
                                        ) model



------------------------------------------------------------
-- selection (with cursor move)
------------------------------------------------------------

selectBackward: Model -> Model
selectBackward = selectWithMove moveBackwardProc
                 << \m -> if isMarkActive m then markClear m else m

selectForward: Model -> Model
selectForward = selectWithMove moveForwardProc
                 << \m -> if isMarkActive m then markClear m else m


selectPreviosLine: Model -> Model
selectPreviosLine = selectWithMove movePreviosLineProc
                 << \m -> if isMarkActive m then markClear m else m

selectNextLine: Model -> Model
selectNextLine = selectWithMove moveNextLineProc
                 << \m -> if isMarkActive m then markClear m else m

selectPreviosWord: Model -> Model
selectPreviosWord = selectWithMove (\m -> movePreviosWordProc m.cursor m)
                 << \m -> if isMarkActive m then markClear m else m

selectNextWord: Model -> Model
selectNextWord = selectWithMove (\m -> moveNextWordProc m.cursor m)
                 << \m -> if isMarkActive m then markClear m else m


selectAt: Position -> Model -> Model
selectAt pos = selectWithMove (moveAtProc pos)
                 << \m -> if isMarkActive m then markClear m else m


selectionClear: Model -> Model
selectionClear model =
    { model
        | selection = Nothing
        , mark = model.mark |> Maybe.andThen (\mk -> Just { mk | actived = False })
    }




-- Tool

selectWithMove : (Model -> Model) -> Model -> Model
selectWithMove move_f model =
    model
        |> \m -> { m | selection = m.selection |> Maybe.withDefault (Range m.cursor m.cursor) |> Just }
        |> move_f
        |> \m -> { m | selection = m.selection |> Maybe.andThen (\s -> Just (Range s.begin m.cursor)) }

------------------------------------------------------------
-- edit
------------------------------------------------------------


{-| Insert character at current cursor position
-}
insert : String -> Model -> Model
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
insertAt: Position -> String -> Model -> Model
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

backspace : Model -> Model
backspace model =
    case model.selection of
        Nothing ->
            backspaceAt model.cursor model
        Just s ->
            model
                |> deleteRange s
                |> selectionClear

backspaceAt: Position -> Model -> Model
backspaceAt pos model =
    let
        (m, deleted) = backspace_proc pos model 
    in
        case deleted of
            Nothing ->
                m
            Just s ->
                m
                |> (\m ->
                        let
                            edtcmd = Cmd_Backspace pos m.cursor s m.mark
                        in
                            m |> appendHistory edtcmd
                              |> updateMark edtcmd
       )

delete : Model -> Model
delete model =
    case model.selection of
        Nothing ->
            deleteAt model.cursor model
        Just s ->
            model
                |> deleteRange s
                |> selectionClear

deleteAt: Position -> Model -> Model
deleteAt pos model =
    let
        (m, deleted) = delete_proc pos model
    in
        case deleted of
            Nothing ->
                m
            Just s ->
                m
                |> (\m ->
                        let
                            edtcmd = Cmd_Delete pos m.cursor s m.mark
                        in
                            m |> appendHistory edtcmd
                              |> updateMark edtcmd
                   )

deleteRange: Range -> Model -> Model
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


deleteSelection: Model -> Model
deleteSelection model =
    case model.selection of
        Nothing ->
            model
        Just s  ->
            model
                |> deleteRange s
                |> selectionClear


undo : Model -> Model
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

insert_proc: Position -> String -> Model -> Model
insert_proc pos text model =
    let
        (row, col) = position_toTuple pos

        contents = model.contents
        prows = List.take row contents
        crow  = line row model.contents |> Maybe.withDefault ""
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

backspace_proc: Position -> Model -> (Model, Maybe String)
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
                crow  = line row model.contents |> Maybe.withDefault ""
                nrows = List.drop (row + 1) model.contents

                left  = (String.left (col - 1) crow)
                right = (String.dropLeft (col) crow)
            in
                ( { model
                      | contents = prows ++ ((left ++ right) :: nrows)
                      , cursor = Position row  (col - 1)
                  }
                , Just (crow |> String.dropLeft (col - 1) |> String.left 1) )


delete_proc: Position -> Model -> (Model, Maybe String)
delete_proc pos model =
    let
        (row, col) = position_toTuple pos

        ln      = line row model.contents |> Maybe.withDefault ""
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
                     nxt    = line (row + 1) model.contents |> Maybe.withDefault ""
                     nrows  = List.drop (row + 2) model.contents

                     current = ln ++ nxt
                 in
                     ( { model
                           | contents = prows ++ (current :: nrows)
                           , cursor = Position row col
                       }
                     , Just "\n" )


delete_range_proc : Range -> Model -> Model
delete_range_proc sel model =
    let
        bpos = if (isPreviosPos sel.begin sel.end) then sel.begin else sel.end
        epos = if (isPreviosPos sel.begin sel.end) then sel.end else sel.begin

        lcnt = epos.row - bpos.row
    in
        case lcnt of
            0 ->
                let 
                    ln  = line bpos.row model.contents |> Maybe.withDefault ""
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
                    bln  = line bpos.row model.contents |> Maybe.withDefault "" |> String.left bpos.column
                    eln  = line epos.row model.contents |> Maybe.withDefault "" |> String.dropLeft epos.column
                    pls = List.take (bpos.row    ) model.contents
                    nls = List.drop (epos.row + 1) model.contents
                in
                    { model
                        | contents = pls ++ ((bln ++ eln) :: nls)
                        , cursor = bpos
                    }

    
undo_insert_proc : Position -> Position -> String -> Model -> Model
undo_insert_proc bf_pos af_pos str model =
    delete_range_proc (Range bf_pos af_pos) model

undo_backspace_proc : Position -> Position -> String -> Model ->Model
undo_backspace_proc bf_pos af_pos str model =
    insert_proc af_pos str model 

undo_delete_proc : Position -> Position -> String -> Model ->Model
undo_delete_proc bf_pos af_pos str model =
    insert_proc bf_pos str model
        |> (\m -> { m | cursor = bf_pos })

