module BufferMoveCursorTest exposing (..)

import Expect exposing (Expectation)
import Test exposing (..)


import Editor.Buffer as Buffer

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
                  Buffer.init "ABC\nDE\nGHIJ\nK\n" |> Buffer.nowCursorPos
                      |> Expect.equal (0,0)
        , test "move-forward" <|
              \_ ->
                  Buffer.init "ABC\nDE\nGHIJ\nK\n"
                      |> Buffer.moveForward
                      |> Buffer.nowCursorPos
                      |> Expect.equal (0,1)
        , test "move-forward (<cr>)" <|
              \_ ->
                  Buffer.init "ABC\nDE\nGHIJ\nK\n"
                      |> Buffer.moveForward -- B
                      |> Buffer.moveForward -- C
                      |> Buffer.moveForward -- \n
                      |> Buffer.nowCursorPos
                      |> Expect.equal (0,3)
        , test "move-forward (next line)" <|
              \_ ->
                  Buffer.init "ABC\nDE\nGHIJ\nK\n"
                      |> Buffer.moveForward -- B
                      |> Buffer.moveForward -- C
                      |> Buffer.moveForward -- \n
                      |> Buffer.moveForward
                      |> Buffer.nowCursorPos
                      |> Expect.equal (1,0)
        , test "move-forward (EOF)" <|
              \_ ->
                  Buffer.init "A\nB\nC\nD\n"
                      |> ntimesdo 10 Buffer.moveForward
                      |> Buffer.nowCursorPos
                      |> Expect.equal (4,0)
        , test "move-next (normally)" <|
              \_ ->
                  Buffer.init "ABC\nDE\nGHIJ\nK\n"
                      |> Buffer.moveNext
                      |> Buffer.nowCursorPos
                      |> Expect.equal (1,0)
        , test "move-next (to shorter line)" <|
              \_ ->
                  Buffer.init "ABCD\nDE\nGHIJ\nK\n"
                      |> ntimesdo 3 Buffer.moveForward
                      |> Buffer.moveNext
                      |> Buffer.nowCursorPos
                      |> Expect.equal (1,2)
        , test "move-next (a shorter line caught in between)" <|
              \_ ->
                  Buffer.init "ABCD\nDE\nGHIJ\nK\n"
                      |> ntimesdo 3 Buffer.moveForward
                      |> Buffer.moveNext
                      |> Buffer.moveNext
                      |> Buffer.nowCursorPos
                      |> Expect.equal (2,2)
        , test "move-next (EOF)" <|
              \_ ->
                  Buffer.init "ABCD\nDE\nGHIJ\nK\n"
                      |> ntimesdo 5 Buffer.moveNext
                      |> Buffer.moveNext
                      |> Buffer.nowCursorPos
                      |> Expect.equal (4, 0)
        , test "move-backword" <|
            \_ ->
                Buffer.init "ABCDE\nGHIJ\nK\n"
                      |> ntimesdo 4 Buffer.moveForward
                      |> Buffer.moveBackward
                      |> Buffer.nowCursorPos
                      |> Expect.equal (0, 3)
        , test "move-backword (previos line)" <|
            \_ ->
                Buffer.init "ABCDE\nGHIJ\nK\n"
                      |> Buffer.moveNext
                      |> Buffer.moveBackward
                      |> Buffer.nowCursorPos
                      |> Expect.equal (0, 5)
        , test "move-backword (BOF)" <|
            \_ ->
                Buffer.init "ABCDE\nGHIJ\nK\n"
                      |> Buffer.moveForward
                      |> ntimesdo 5 Buffer.moveBackward
                      |> Buffer.nowCursorPos
                      |> Expect.equal (0, 0)
        , test "move-previos (normally)" <|
              \_ ->
                  Buffer.init "ABC\nDE\nGHIJ\nK\n"
                      |> Buffer.moveNext
                      |> Buffer.moveForward
                      |> Buffer.movePrevios
                      |> Buffer.nowCursorPos
                      |> Expect.equal (0,1)
        , test "move-previos (to shorter line)" <|
              \_ ->
                  Buffer.init "ABCD\nEF\nGHIJ\nK\n"
                      |> ntimesdo 2 Buffer.moveNext
                      |> ntimesdo 3 Buffer.moveForward
                      |> Buffer.movePrevios
                      |> Buffer.nowCursorPos
                      |> Expect.equal (1,2)
        , test "move-previos (a shorter line caught in between)" <|
              \_ ->
                  Buffer.init "ABCD\nEF\nGHIJ\nK\n"
                      |> ntimesdo 2 Buffer.moveNext
                      |> ntimesdo 3 Buffer.moveForward
                      |> Buffer.movePrevios
                      |> Buffer.movePrevios
                      |> Buffer.nowCursorPos
                      |> Expect.equal (0,2)
        , test "move-previos (BOF)" <|
              \_ ->
                  Buffer.init "ABCD\nEF\nGHIJ\nK\n"
                      |> ntimesdo 2 Buffer.moveNext
                      |> ntimesdo 5 Buffer.movePrevios
                      |> Buffer.nowCursorPos
                      |> Expect.equal (0,0)
        ]
