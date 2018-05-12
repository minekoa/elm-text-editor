module TextEditor.Buffer exposing ( Model
                                  , init
                                      
                                  , Cursor
                                  , nowCursorPos
                                  , isPreviosPos
                                  , line
                                  , Range
                                  , readRange
                                  , selectedString

                                  -- history
                                  , EditCommand(Cmd_Insert, Cmd_Backspace, Cmd_Delete)

                                  -- cursor move
                                  , moveForward
                                  , moveBackward
                                  , movePrevios
                                  , moveNext
                                  , moveAt

                                  -- selection
                                  , selectBackward
                                  , selectForward
                                  , selectPrevios
                                  , selectNext
                                  , selectAt
                                  , selectionClear

                                  -- mark
                                  , markSet
                                  , markClear
                                  , gotoMark

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

type alias Model =
    { cursor : Cursor
    , selection : Maybe Range
    , mark : Maybe Mark
    , contents : List String
    , history : List EditCommand
    }

init : String -> Model
init text =
    Model (Cursor 0 0)           -- cursor
          Nothing                -- selection
          Nothing                -- mark
          (String.lines text)    -- contents
          []                     -- history


-- buffer > cursor

type alias Cursor =
    { row : Int
    , column : Int
    }

defaultCursor : List String -> Cursor
defaultCursor contents =             
    let
        n = List.length contents
    in
        Cursor (if n < 0 then 0 else n) 0

nowCursorPos : Model -> (Int, Int)
nowCursorPos model = 
    ( model.cursor.row, model.cursor.column )

isPreviosPos : (Int, Int) -> (Int, Int) -> Bool
isPreviosPos p q =
    if Tuple.first p == Tuple.first q
    then Tuple.second p < Tuple.second q
    else Tuple.first p < Tuple.first q


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

type alias Range =
    { begin : (Int, Int)
    , end : (Int, Int)
    }

readRange : Range -> Model -> String
readRange sel model =
    let
        bpos = if (isPreviosPos sel.begin sel.end) then sel.begin else sel.end
        epos = if (isPreviosPos sel.begin sel.end) then sel.end else sel.begin

        lcnt = (Tuple.first epos) - (Tuple.first bpos)
    in
        case lcnt of
            0 ->
                let 
                    l = line (Tuple.first bpos) model.contents |> Maybe.withDefault ""
                in
                    l |> String.dropLeft (Tuple.second bpos) |> String.left ((Tuple.second epos) - (Tuple.second bpos))
            _ ->
                let
                    bl = model.contents |> line (Tuple.first bpos) |> Maybe.withDefault "" |> String.dropLeft (Tuple.second bpos)
                    el = model.contents |> line (Tuple.first epos) |> Maybe.withDefault "" |> String.left (Tuple.second epos)

                    ls = model.contents |> List.drop ((Tuple.first bpos) + 1) |> List.take (lcnt - 1)
                in
                    String.join "\n" ((bl :: ls) ++ [el])

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
        pos = nowCursorPos model
        new_mark = { pos = pos
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
                |> moveAt mk.pos
        Nothing ->
            model


------------------------------------------------------------
-- History
------------------------------------------------------------

type EditCommand
    = Cmd_Insert (Int, Int) (Int, Int) String    -- befor-cur after-cur inserted_str
    | Cmd_Backspace (Int, Int) (Int, Int) String -- befor-cur after-cur deleted_str
    | Cmd_Delete (Int, Int) (Int, Int) String    -- befor-cur after-cur deleted_str
--    | Cmd_Undo EditCommand

appendHistory: EditCommand -> Model -> Model
appendHistory cmd model =
    let
        row = Tuple.first
        col = Tuple.second
    in
    case (cmd, List.head model.history) of
        ( (Cmd_Insert befor after s), Just (Cmd_Insert old_befor old_after old_s) ) ->
            if ((befor |> row) == (old_befor |> row)) && ((befor |> col) == (old_after |> col))
            then { model | history = (Cmd_Insert old_befor after (old_s ++ s)) :: List.drop 1 model.history }
            else { model | history = cmd :: model.history }

        ( (Cmd_Backspace befor after s), Just (Cmd_Backspace old_befor old_after old_s) ) ->
            if ((befor |> row) == (old_befor |> row)) && ((befor |> col) == (old_after |> col))
            then { model | history = (Cmd_Backspace old_befor after (s ++ old_s)) :: List.drop 1 model.history }
            else { model | history = cmd :: model.history }

        ( (Cmd_Delete befor after s), Just (Cmd_Delete old_befor old_after old_s) ) ->
            if ((befor |> row) == (old_befor |> row)) && ((befor |> col) == (old_befor |> col))
            then { model | history = (Cmd_Delete old_befor after (old_s ++ s)) :: List.drop 1 model.history }
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

movePrevios : Model -> Model
movePrevios model =
    case isMarkActive model of
        True  -> selectWithMove movePreviosProc model
        False -> model |> movePreviosProc |> selectionClear

moveNext : Model -> Model
moveNext model =
    case isMarkActive model of
        True  -> selectWithMove moveNextProc model
        False -> model |>  moveNextProc |> selectionClear

moveAt : (Int, Int) -> Model -> Model
moveAt (row, col) model =
    case isMarkActive model of
        True  -> selectWithMove (moveAtProc (row, col)) model
        False -> model |>  moveAtProc (row, col) |> selectionClear


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

movePreviosProc : Model -> Model
movePreviosProc model =
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

moveNextProc : Model -> Model
moveNextProc model =
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

moveAtProc : (Int, Int) -> Model -> Model
moveAtProc (row, col) model =
    { model | cursor = Cursor row col }



------------------------------------------------------------
-- selection (with cursor move)
------------------------------------------------------------

selectBackward: Model -> Model
selectBackward = selectWithMove moveBackwardProc

selectForward: Model -> Model
selectForward = selectWithMove moveForwardProc

selectPrevios: Model -> Model
selectPrevios = selectWithMove movePreviosProc

selectNext: Model -> Model
selectNext = selectWithMove moveNextProc

selectAt: (Int, Int) -> Model -> Model
selectAt pos = selectWithMove (moveAtProc pos)

selectionClear: Model -> Model
selectionClear model =
    { model | selection = Nothing }

-- Tool

selectWithMove : (Model -> Model) -> Model -> Model
selectWithMove move_f model =
    model
        |> \m -> { m | selection = m.selection |> Maybe.withDefault (Range (nowCursorPos m) (nowCursorPos m)) |> Just }
        |> move_f
        |> \m -> { m | selection = m.selection |> Maybe.andThen (\s -> Just (Range s.begin (nowCursorPos m))) }

------------------------------------------------------------
-- edit
------------------------------------------------------------


insert : String -> Model -> Model
insert text model=
    case model.selection of
        Nothing ->
            insertAt (nowCursorPos model) text model
        Just s ->
            model
                |> deleteRange s
                |> selectionClear
                |> (\m -> insertAt (nowCursorPos m) text m)

insertAt: (Int, Int) -> String -> Model -> Model
insertAt (row, col) text model =
    model
    |> insert_proc (row, col) text
    |> (\m -> appendHistory (Cmd_Insert (row, col) (nowCursorPos m) text) m)


backspace : Model -> Model
backspace model =
    case model.selection of
        Nothing ->
            backspaceAt (nowCursorPos model) model
        Just s ->
            model
                |> deleteRange s
                |> selectionClear

backspaceAt: (Int, Int) -> Model -> Model
backspaceAt (row, col) model =
    let
        (m, deleted) = backspace_proc (row, col) model 
    in
        case deleted of
            Nothing ->
                m
            Just s ->
                m
                |> (\m -> appendHistory (Cmd_Backspace (row, col) (nowCursorPos m) s) m)

delete : Model -> Model
delete model =
    case model.selection of
        Nothing ->
            deleteAt (nowCursorPos model) model
        Just s ->
            model
                |> deleteRange s
                |> selectionClear

deleteAt: (Int, Int) -> Model -> Model
deleteAt (row, col) model =
    let
        (m, deleted) = delete_proc (row, col) model
    in
        case deleted of
            Nothing ->
                m
            Just s ->
                m
                |> (\m -> appendHistory (Cmd_Delete (row, col) (nowCursorPos m) s) m)


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
                    |> (\m -> appendHistory (Cmd_Delete head_pos (nowCursorPos m) deleted) m)


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
                  Cmd_Insert before_cur after_cur str    ->
                      undo_insert_proc before_cur after_cur str model

                  Cmd_Backspace before_cur after_cur str ->
                      undo_backspace_proc before_cur after_cur str model

                  Cmd_Delete before_cur after_cur str    ->
                      undo_delete_proc before_cur after_cur str model
            )
            |> (\ m -> {m | history = List.drop 1 m.history })




------------------------------------------------------------
-- (private) edit
------------------------------------------------------------

insert_proc: (Int, Int) -> String -> Model -> Model
insert_proc (row, col) text model =
    let
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
                    , cursor = Cursor row (col + (String.length text))
                }
            2 ->
                let
                    fst_ln = car texts
                    lst_ln = car <| List.drop 1 texts
                in
                    { model
                        | contents = prows ++ [ left ++ fst_ln, lst_ln ++ right]
                                           ++ nrows
                         , cursor = Cursor (row + 1) (String.length lst_ln)
                    }
            n ->
                let
                    fst_ln = car texts
                    lst_ln = car <| List.drop (n - 1) texts
                in
                    { model
                        | contents = prows ++ [ left ++ fst_ln ] ++ (List.drop 1 (List.take (n - 1) texts)) ++ [lst_ln ++ right]
                                           ++ nrows
                        , cursor = Cursor (row + n - 1) (String.length lst_ln)
                    }

backspace_proc: (Int, Int) -> Model -> (Model, Maybe String)
backspace_proc (row, col) model =
    case (row, col) of
        (0, 0) ->
            (model, Nothing)

        (_, 0) ->
            let
                prows  = List.take (row - 1) model.contents
                crow   = List.drop (row - 1) model.contents |> List.take 2 |> String.concat
                nrows  = List.drop (row + 1) model.contents

                n_col  = List.drop (row - 1) model.contents |> List.head |> Maybe.withDefault "" |> String.length
            in
                ( { model
                      | contents = prows ++ (crow :: nrows )
                      , cursor = Cursor (row - 1) (n_col)
                  }
                , Just "\n")

        (_, n) ->
            let
                prows = List.take row model.contents
                crow  = line row model.contents |> Maybe.withDefault ""
                nrows = List.drop (row + 1) model.contents

                left  = (String.left (col - 1) crow)
                right = (String.dropLeft (col) crow)
            in
                ( { model
                      | contents = prows ++ ((left ++ right) :: nrows)
                      , cursor = Cursor row  (col - 1)
                  }
                , Just (crow |> String.dropLeft (col - 1) |> String.left 1) )


delete_proc: (Int, Int) -> Model -> (Model, Maybe String)
delete_proc (row, col) model =
    let
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
                           , cursor = Cursor row col
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
                           , cursor = Cursor row col
                       }
                     , Just "\n" )


delete_range_proc : Range -> Model -> Model
delete_range_proc sel model =
    let
        bpos = if (isPreviosPos sel.begin sel.end) then sel.begin else sel.end
        epos = if (isPreviosPos sel.begin sel.end) then sel.end else sel.begin

        lcnt = (Tuple.first epos) - (Tuple.first bpos)
    in
        case lcnt of
            0 ->
                let 
                    ln  = line (Tuple.first bpos) model.contents |> Maybe.withDefault ""
                    current = (String.left (Tuple.second bpos) ln) ++ (String.dropLeft (Tuple.second epos) ln)

                    pls = List.take ((Tuple.first bpos)    ) model.contents
                    nls = List.drop ((Tuple.first epos) + 1) model.contents
                in
                    { model
                        | contents = pls ++ (current :: nls)
                        , cursor = Cursor (Tuple.first bpos) (Tuple.second bpos)
                    }
            _ ->
                let
                    bln  = line (Tuple.first bpos) model.contents |> Maybe.withDefault "" |> String.left (Tuple.second bpos)
                    eln  = line (Tuple.first epos) model.contents |> Maybe.withDefault "" |> String.dropLeft (Tuple.second epos)
                    pls = List.take ((Tuple.first bpos)    ) model.contents
                    nls = List.drop ((Tuple.first epos) + 1) model.contents
                in
                    { model
                        | contents = pls ++ ((bln ++ eln) :: nls)
                        , cursor = Cursor (Tuple.first bpos) (Tuple.second bpos)
                    }

    
undo_insert_proc : (Int, Int) -> (Int, Int) -> String -> Model -> Model
undo_insert_proc (bf_row, bf_col) (af_row, af_col) str model =
    -- todo: ちゃんと実装する。
    --       現存の編集イベントを組み合わせて強引に実現している。汚い。
    let
        delete_n = (\ c m ->
                        if c <= 0 then m
                        else backspace_proc (m.cursor.row, m.cursor.column) m
                             |> Tuple.first
                             |> delete_n (c - 1)
                   )
    in
        delete_n (String.length str)
            { model
                | cursor = Cursor af_row af_col
            }

undo_backspace_proc : (Int, Int) -> (Int, Int) -> String -> Model ->Model
undo_backspace_proc (bf_row, bf_col) (af_row, af_col) str model =
    insert_proc (af_row, af_col) str model 

undo_delete_proc : (Int, Int) -> (Int, Int) -> String -> Model ->Model
undo_delete_proc (bf_row, bf_col) (af_row, af_col) str model =
    insert_proc (bf_row, bf_col) str model
        |> (\m -> { m | cursor = Cursor bf_row bf_col })

