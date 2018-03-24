module BufferSelectionTest exposing (..)

import Expect exposing (Expectation)
import Test exposing (..)


import Editor.Buffer as Buffer

suite : Test
suite =
    describe "Selection"
        [ test "default cursor pos" <|
              \_ ->
                  Buffer.init "ABC\nDE\nGHIJ\nK\n"
                      |> (.selection)
                      |> Expect.equal Nothing
        , test "selection start (forward)" <|
              \_ ->
                  Buffer.init "ABC\nDE\nGHIJ\nK\n"
                      |> Buffer.selectForward
                      |> Expect.all [ \m -> Expect.equal (Buffer.Range (0,0) (0,1) |> Just) m.selection
                                    , \m -> Expect.equal (0,1) (Buffer.nowCursorPos m)
                                    ]
        , test "selection start (backward)" <|
              \_ ->
                  Buffer.init "ABC\nDE\nGHIJ\nK\n"
                      |> Buffer.moveForward
                      |> Buffer.selectBackward
                      |> Expect.all [ \m -> Expect.equal (Buffer.Range (0,1) (0,0) |> Just) m.selection
                                    , \m -> Expect.equal (0,0) (Buffer.nowCursorPos m)
                                    ]
        , test "selection start (next)" <|
              \_ ->
                  Buffer.init "ABC\nDE\nGHIJ\nK\n"
                      |> Buffer.selectNext
                      |> Expect.all [ \m -> Expect.equal (Buffer.Range (0,0) (1,0) |> Just) m.selection
                                    , \m -> Expect.equal (1,0) (Buffer.nowCursorPos m)
                                    ]
        , test "selection start (previos)" <|
              \_ ->
                  Buffer.init "ABC\nDE\nGHIJ\nK\n"
                      |> Buffer.moveNext
                      |> Buffer.selectPrevios
                      |> Expect.all [ \m -> Expect.equal (Buffer.Range (1,0) (0,0) |> Just) m.selection
                                    , \m -> Expect.equal (0,0) (Buffer.nowCursorPos m)
                                    ]
        , test "selection extend (forward, inline)" <|
              \_ ->
                  Buffer.init "ABC\nDE\nGHIJ\nK\n"
                      |> Buffer.moveForward
                      |> Buffer.selectForward
                      |> Buffer.selectForward
                      |> Expect.all [ \m -> Expect.equal (Buffer.Range (0,1) (0,3) |> Just) m.selection
                                    , \m -> Expect.equal (0,3) (Buffer.nowCursorPos m)
                                    ]
        , test "selection extend (forward, multiline)" <|
              \_ ->
                  Buffer.init "ABC\nDE\nGHIJ\nK\n"
                      |> Buffer.moveForward
                      |> Buffer.selectForward
                      |> Buffer.selectForward
                      |> Buffer.selectForward
                      |> Expect.all [ \m -> Expect.equal (Buffer.Range (0,1) (1,0) |> Just) m.selection
                                    , \m -> Expect.equal (1,0) (Buffer.nowCursorPos m)
                                    ]
        , test "selection extend (forward, begin=end)" <|
              \_ ->
                  Buffer.init "ABC\nDE\nGHIJ\nK\n"
                      |> Buffer.moveForward
                      |> Buffer.selectBackward
                      |> Buffer.selectForward
                      |> Expect.all [ \m -> Expect.equal (Buffer.Range (0,1) (0,1) |> Just) m.selection
                                    , \m -> Expect.equal (0,1) (Buffer.nowCursorPos m)
                                    ]
        , test "selection extend (forward, EOF)" <|
              \_ ->
                  Buffer.init "ABC\nD"
                      |> Buffer.moveForward
                      |> Buffer.selectForward
                      |> Buffer.selectForward
                      |> Buffer.selectForward
                      |> Buffer.selectForward
                      |> Buffer.selectForward
                      |> Expect.all [ \m -> Expect.equal (Buffer.Range (0,1) (1,1) |> Just) m.selection
                                    , \m -> Expect.equal (1,1) (Buffer.nowCursorPos m)
                                    ]
        , test "selection extend (backward, inline)" <|
              \_ ->
                  Buffer.init "ABC\nDE\nGHIJ\nK\n"
                      |> Buffer.moveForward
                      |> Buffer.moveForward
                      |> Buffer.selectBackward
                      |> Buffer.selectBackward
                      |> Expect.all [ \m -> Expect.equal (Buffer.Range (0,2) (0,0) |> Just) m.selection
                                    , \m -> Expect.equal (0,0) (Buffer.nowCursorPos m)
                                    ]
        , test "selection extend (backword, multiline)" <|
              \_ ->
                  Buffer.init "ABC\nDE\nGHIJ\nK\n"
                      |> Buffer.moveNext
                      |> Buffer.moveForward
                      |> Buffer.selectBackward
                      |> Buffer.selectBackward
                      |> Expect.all [ \m -> Expect.equal (Buffer.Range (1,1) (0,3) |> Just) m.selection
                                    , \m -> Expect.equal (0,3) (Buffer.nowCursorPos m)
                                    ]
        , test "selection extend (backward, BOF)" <|
              \_ ->
                  Buffer.init "ABC"
                      |> Buffer.moveForward
                      |> Buffer.moveForward
                      |> Buffer.selectBackward
                      |> Buffer.selectBackward
                      |> Buffer.selectBackward
                      |> Buffer.selectBackward
                      |> Expect.all [ \m -> Expect.equal (Buffer.Range (0,2) (0,0) |> Just) m.selection
                                    , \m -> Expect.equal (0,0) (Buffer.nowCursorPos m)
                                    ]
        , test "selection extend (next)" <|
              \_ ->
                  Buffer.init "ABC\nDE\nGHIJ\nK\n"
                      |> Buffer.moveForward
                      |> Buffer.selectNext
                      |> Buffer.selectNext
                      |> Expect.all [ \m -> Expect.equal (Buffer.Range (0,1) (2,1) |> Just) m.selection
                                    , \m -> Expect.equal (2,1) (Buffer.nowCursorPos m)
                                    ]
        , test "selection extend (next, shorterline)" <|
              \_ ->
                  Buffer.init "ABC\nDE\nGHIJ\nK\n"
                      |> Buffer.moveForward
                      |> Buffer.moveForward
                      |> Buffer.moveForward
                      |> Buffer.selectNext
                      |> Buffer.selectNext
                      |> Expect.all [ \m -> Expect.equal (Buffer.Range (0,3) (2,2) |> Just) m.selection
                                    , \m -> Expect.equal (2,2) (Buffer.nowCursorPos m)
                                    ]
        , test "selection extend (next, EOF)" <|
              \_ ->
                  Buffer.init "ABC\nDEFG"
                      |> Buffer.moveForward
                      |> Buffer.selectNext
                      |> Buffer.selectNext
                      |> Buffer.selectNext
                      |> Buffer.selectNext
                      |> Expect.all [ \m -> Expect.equal (Buffer.Range (0,1) (1,1) |> Just) m.selection
                                    , \m -> Expect.equal (1,1) (Buffer.nowCursorPos m)
                                    ]
        , test "selection extend (next, EOF, shorterline)" <|
              \_ ->
                  Buffer.init "ABC\nD"
                      |> Buffer.moveForward
                      |> Buffer.moveForward
                      |> Buffer.selectNext
                      |> Buffer.selectNext
                      |> Buffer.selectNext
                      |> Buffer.selectNext
                      |> Expect.all [ \m -> Expect.equal (Buffer.Range (0,2) (1,1) |> Just) m.selection
                                    , \m -> Expect.equal (1,1) (Buffer.nowCursorPos m)
                                    ]
        , test "selection extend (previos)" <|
              \_ ->
                  Buffer.init "ABC\nDE\nGHIJ\nK\n"
                      |> Buffer.moveNext
                      |> Buffer.moveNext
                      |> Buffer.moveForward
                      |> Buffer.selectPrevios
                      |> Buffer.selectPrevios
                      |> Expect.all [ \m -> Expect.equal (Buffer.Range (2,1) (0,1) |> Just) m.selection
                                    , \m -> Expect.equal (0,1) (Buffer.nowCursorPos m)
                                    ]
        , test "selection extend (previos, shorterline)" <|
              \_ ->
                  Buffer.init "ABC\nDE\nGHIJ\nK\n"
                      |> Buffer.moveNext
                      |> Buffer.moveNext
                      |> Buffer.moveForward
                      |> Buffer.moveForward
                      |> Buffer.moveForward
                      |> Buffer.selectPrevios
                      |> Buffer.selectPrevios
                      |> Expect.all [ \m -> Expect.equal (Buffer.Range (2,3) (0,2) |> Just) m.selection
                                    , \m -> Expect.equal (0,2) (Buffer.nowCursorPos m)
                                    ]
        , test "selection extend (previos, BOF)" <|
              \_ ->
                  Buffer.init "ABC\nDE\nGHIJ\nK\n"
                      |> Buffer.moveNext
                      |> Buffer.moveNext
                      |> Buffer.moveForward
                      |> Buffer.selectPrevios
                      |> Buffer.selectPrevios
                      |> Buffer.selectPrevios
                      |> Buffer.selectPrevios
                      |> Buffer.selectPrevios
                      |> Buffer.selectPrevios
                      |> Expect.all [ \m -> Expect.equal (Buffer.Range (2,1) (0,1) |> Just) m.selection
                                    , \m -> Expect.equal (0,1) (Buffer.nowCursorPos m)
                                    ]
        , test "selection extend (previos, BOF, shorterline)" <|
              \_ ->
                  Buffer.init "A\nDE\nGHIJ\nK\n"
                      |> Buffer.moveNext
                      |> Buffer.moveNext
                      |> Buffer.moveForward
                      |> Buffer.moveForward
                      |> Buffer.moveForward
                      |> Buffer.selectPrevios
                      |> Buffer.selectPrevios
                      |> Buffer.selectPrevios
                      |> Buffer.selectPrevios
                      |> Buffer.selectPrevios
                      |> Buffer.selectPrevios
                      |> Expect.all [ \m -> Expect.equal (Buffer.Range (2,3) (0,1) |> Just) m.selection
                                    , \m -> Expect.equal (0,1) (Buffer.nowCursorPos m)
                                    ]

        ]

