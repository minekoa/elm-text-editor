module BufferMoveCursorTest exposing (..)

import Expect exposing (Expectation)
import Test exposing (..)


import TextEditor.Buffer as Buffer

curWithTuple : Buffer.Model -> (Int, Int)
curWithTuple m =
   ( m.cursor.row, m.cursor.column )

ntimesdo : Int -> (a -> a) -> a -> a
ntimesdo  n f v =
    case n of
        0 ->
            v
        _ ->
            ntimesdo (n - 1) f (f v)


suite : Test
suite =
    describe "MoveCursor"
        [ test "default cursor pos" <|
              \_ ->
                  Buffer.init "ABC\nDE\nGHIJ\nK\n" |> curWithTuple
                      |> Expect.equal (0,0)
        , test "move-forward" <|
              \_ ->
                  Buffer.init "ABC\nDE\nGHIJ\nK\n"
                      |> Buffer.moveForward
                      |> curWithTuple
                      |> Expect.equal (0,1)
        , test "move-forward (<cr>)" <|
              \_ ->
                  Buffer.init "ABC\nDE\nGHIJ\nK\n"
                      |> Buffer.moveForward -- B
                      |> Buffer.moveForward -- C
                      |> Buffer.moveForward -- \n
                      |> curWithTuple
                      |> Expect.equal (0,3)
        , test "move-forward (next line)" <|
              \_ ->
                  Buffer.init "ABC\nDE\nGHIJ\nK\n"
                      |> Buffer.moveForward -- B
                      |> Buffer.moveForward -- C
                      |> Buffer.moveForward -- \n
                      |> Buffer.moveForward
                      |> curWithTuple
                      |> Expect.equal (1,0)
        , test "move-forward (EOF)" <|
              \_ ->
                  Buffer.init "A\nB\nC\nD\n"
                      |> ntimesdo 10 Buffer.moveForward
                      |> curWithTuple
                      |> Expect.equal (4,0)
        , test "move-next (normally)" <|
              \_ ->
                  Buffer.init "ABC\nDE\nGHIJ\nK\n"
                      |> Buffer.moveNextLine
                      |> curWithTuple
                      |> Expect.equal (1,0)
        , test "move-next (to shorter line)" <|
              \_ ->
                  Buffer.init "ABCD\nDE\nGHIJ\nK\n"
                      |> ntimesdo 3 Buffer.moveForward
                      |> Buffer.moveNextLine
                      |> curWithTuple
                      |> Expect.equal (1,2)
        , test "move-next (a shorter line caught in between)" <|
              \_ ->
                  Buffer.init "ABCD\nDE\nGHIJ\nK\n"
                      |> ntimesdo 3 Buffer.moveForward
                      |> Buffer.moveNextLine
                      |> Buffer.moveNextLine
                      |> curWithTuple
                      |> Expect.equal (2,2)
        , test "move-next (EOF)" <|
              \_ ->
                  Buffer.init "ABCD\nDE\nGHIJ\nK\n"
                      |> ntimesdo 5 Buffer.moveNextLine
                      |> Buffer.moveNextLine
                      |> curWithTuple
                      |> Expect.equal (4, 0)
        , test "move-backword" <|
            \_ ->
                Buffer.init "ABCDE\nGHIJ\nK\n"
                      |> ntimesdo 4 Buffer.moveForward
                      |> Buffer.moveBackward
                      |> curWithTuple
                      |> Expect.equal (0, 3)
        , test "move-backword (previos line)" <|
            \_ ->
                Buffer.init "ABCDE\nGHIJ\nK\n"
                      |> Buffer.moveNextLine
                      |> Buffer.moveBackward
                      |> curWithTuple
                      |> Expect.equal (0, 5)
        , test "move-backword (BOF)" <|
            \_ ->
                Buffer.init "ABCDE\nGHIJ\nK\n"
                      |> Buffer.moveForward
                      |> ntimesdo 5 Buffer.moveBackward
                      |> curWithTuple
                      |> Expect.equal (0, 0)
        , test "move-previos (normally)" <|
              \_ ->
                  Buffer.init "ABC\nDE\nGHIJ\nK\n"
                      |> Buffer.moveNextLine
                      |> Buffer.moveForward
                      |> Buffer.movePreviosLine
                      |> curWithTuple
                      |> Expect.equal (0,1)
        , test "move-previos (to shorter line)" <|
              \_ ->
                  Buffer.init "ABCD\nEF\nGHIJ\nK\n"
                      |> ntimesdo 2 Buffer.moveNextLine
                      |> ntimesdo 3 Buffer.moveForward
                      |> Buffer.movePreviosLine
                      |> curWithTuple
                      |> Expect.equal (1,2)
        , test "move-previos (a shorter line caught in between)" <|
              \_ ->
                  Buffer.init "ABCD\nEF\nGHIJ\nK\n"
                      |> ntimesdo 2 Buffer.moveNextLine
                      |> ntimesdo 3 Buffer.moveForward
                      |> Buffer.movePreviosLine
                      |> Buffer.movePreviosLine
                      |> curWithTuple
                      |> Expect.equal (0,2)
        , test "move-previos (BOF)" <|
              \_ ->
                  Buffer.init "ABCD\nEF\nGHIJ\nK\n"
                      |> ntimesdo 2 Buffer.moveNextLine
                      |> ntimesdo 5 Buffer.movePreviosLine
                      |> curWithTuple
                      |> Expect.equal (0,0)

        , test "move-next-word" <|
              \_ ->
                  Buffer.init "ABC DE\nHIJ\n"
                      |> Buffer.moveNextWord
                      |> curWithTuple
                      |> Expect.equal (0,3)
        , test "move-next-word (nextline)" <|
              \_ ->
                  Buffer.init "ABC DE\nHIJ\n"
                      |> Buffer.moveNextWord -- "ABC "
                      |> Buffer.moveNextWord -- "DE\n"
                      |> Buffer.moveNextWord -- ""
                      |> curWithTuple
                      |> Expect.equal (1,3)
        , test "move-next-word (nextline (space))" <|
              \_ ->
                  Buffer.init "ABC DE\n HIJ\n"
                      |> Buffer.moveNextWord -- "ABC "
                      |> Buffer.moveNextWord -- "DE\n"
                      |> Buffer.moveNextWord -- " "
                      |> curWithTuple
                      |> Expect.equal (1,4)
        , test "move-next-word (last-line)" <|
              \_ ->
                  Buffer.init "ABC DE\nHIJ\n"
                      |> Buffer.moveNextWord -- "ABC "
                      |> Buffer.moveNextWord -- "DE\n"
                      |> Buffer.moveNextWord -- "HIJ\n"
                      |> Buffer.moveNextWord -- ""
                      |> curWithTuple
                      |> Expect.equal (2,0)
        , test "move-next-word (EOF stop)" <|
              \_ ->
                  Buffer.init "ABC DE\nHIJ\n"
                      |> Buffer.moveNextWord
                      |> Buffer.moveNextWord
                      |> Buffer.moveNextWord
                      |> Buffer.moveNextWord
                      |> curWithTuple
                      |> Expect.equal (2,0)
        , test "move-next-word (next line is the last line)" <|
              \_ ->
                  Buffer.init "宇宙よりも遠い場所\n  abc def, g"
                      |> Buffer.moveNextWord -- "宇宙よりも"
                      |> Buffer.moveNextWord -- "遠い"
                      |> Buffer.moveNextWord -- "場所"
                      |> Buffer.moveNextWord -- "  abc"
                      |> curWithTuple
                      |> Expect.equal (1,5)

        , test "move-previos-word" <|
              \_ ->
                  Buffer.init "ABC DE\nHIJ\n"
                      |> Buffer.moveNextLine
                      |> Buffer.moveNextLine
                      |> Buffer.movePreviosWord
                      |> curWithTuple
                      |> Expect.equal (1,0)
        , test "move-previos-word (BOF)" <|
              \_ ->
                  Buffer.init "ABC DE\nHIJ\n"
                      |> Buffer.movePreviosWord
                      |> curWithTuple
                      |> Expect.equal (0,0)
        , test "move-previos-word (prev-line, space)" <|
              \_ ->
                  Buffer.init "ABC DE\n  HIJ  \n"
                      |> Buffer.moveNextLine
                      |> Buffer.moveNextLine
                      |> Buffer.movePreviosWord
                      |> curWithTuple
                      |> Expect.equal (1,2)


        ]
