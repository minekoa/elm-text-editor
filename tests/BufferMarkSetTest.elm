module BufferMarkSetTest exposing (..)

import Expect exposing (Expectation)
import Test exposing (..)


import TextEditor.Buffer as Buffer

ntimesdo : Int -> (a -> a) -> a -> a
ntimesdo  n f v =
    case n of
        0 ->
            v
        _ ->
            ntimesdo (n - 1) f (f v)

suite : Test
suite =
    describe "MarkSet"
        [ test "default mark pos" <|
              \_ ->
                  Buffer.init "ABC\nDE\nGHIJ\nK\n"
                      |> (.mark)
                      |> Expect.equal Nothing

        , test "mark-set" <|
              \_ ->
                  Buffer.init "ABC\nDE\nGHIJ\nK\n"
                      |> Buffer.moveForward
                      |> Buffer.markSet
                      |> Expect.all [ \m -> Expect.equal (Buffer.Mark (0,1) True  |> Just) m.mark
                                    , \m -> Expect.equal (Buffer.Range (0,1) (0,1) |> Just) m.selection
                                    ]
        , test "mark-set -> mark-clear" <|
              \_ ->
                  Buffer.init "ABC\nDE\nGHIJ\nK\n"
                      |> Buffer.moveForward
                      |> Buffer.markSet
                      |> Buffer.markClear
                      |> Expect.all [ \m -> Expect.equal (Buffer.Mark (0,1) False  |> Just) m.mark
                                    , \m -> Expect.equal Nothing m.selection
                                    ]
        , test "mark-set -> mark-set" <|
              \_ ->
                  Buffer.init "ABC\nDE\nGHIJ\nK\n"
                      |> Buffer.moveForward
                      |> Buffer.markSet
                      |> Buffer.moveForward
                      |> Buffer.markSet
                      |> Expect.all [ \m -> Expect.equal (Buffer.Mark (0,2) True  |> Just) m.mark
                                    , \m -> Expect.equal (Buffer.Range (0,2) (0,2) |> Just) m.selection
                                    ]

        , test "move-forward(momark)" <|
              \_ ->
                  Buffer.init "ABC\nDE\nGHIJ\nK\n"
                      |> Buffer.moveForward
                      |> (.selection)
                      |> Expect.equal Nothing

        , test "move-backward(momark)" <|
              \_ ->
                  Buffer.init "ABC\nDE\nGHIJ\nK\n"
                      |> \b -> {b| cursor = Buffer.Cursor 0 1 }
                      |> Buffer.moveBackward
                      |> (.selection)
                      |> Expect.equal Nothing

        , test "move-next(momark)" <|
              \_ ->
                  Buffer.init "ABC\nDE\nGHIJ\nK\n"
                      |> Buffer.moveNext
                      |> (.selection)
                      |> Expect.equal Nothing

        , test "move-previos(momark)" <|
              \_ ->
                  Buffer.init "ABC\nDE\nGHIJ\nK\n"
                      |> \b -> {b| cursor = Buffer.Cursor 1 0 }
                      |> Buffer.movePrevios
                      |> (.selection)
                      |> Expect.equal Nothing

        , test "move-at(momark)" <|
              \_ ->
                  Buffer.init "ABC\nDE\nGHIJ\nK\n"
                      |> \b -> {b| cursor = Buffer.Cursor 1 0 }
                      |> Buffer.moveAt (2, 3)
                      |> (.selection)
                      |> Expect.equal Nothing

        , test "move-forward(mark: 1char)" <|
              \_ ->
                  Buffer.init "ABC\nDE\nGHIJ\nK\n"
                      |> Buffer.moveForward
                      |> Buffer.markSet
                      |> Buffer.moveForward
                      |> Expect.all [ \m -> Expect.equal (Buffer.Mark (0,1) True  |> Just) m.mark
                                    , \m -> Expect.equal (Buffer.Range (0,1) (0,2) |> Just) m.selection
                                    ]

        , test "move-backward(mark: 1char)" <|
              \_ ->
                  Buffer.init "ABC\nDE\nGHIJ\nK\n"
                      |> Buffer.moveForward
                      |> Buffer.markSet
                      |> Buffer.moveBackward
                      |> Expect.all [ \m -> Expect.equal (Buffer.Mark (0,1) True  |> Just) m.mark
                                    , \m -> Expect.equal (Buffer.Range (0,1) (0,0) |> Just) m.selection
                                    ]

        , test "move-next(mark: line)" <|
              \_ ->
                  Buffer.init "ABC\nDE\nGHIJ\nK\n"
                      |> Buffer.moveForward
                      |> Buffer.markSet
                      |> Buffer.moveNext
                      |> Expect.all [ \m -> Expect.equal (Buffer.Mark (0,1) True  |> Just) m.mark
                                    , \m -> Expect.equal (Buffer.Range (0,1) (1,1) |> Just) m.selection
                                    ]

        , test "move-previos(mark: line)" <|
              \_ ->
                  Buffer.init "ABC\nDE\nGHIJ\nK\n"
                      |> Buffer.moveNext
                      |> Buffer.markSet
                      |> Buffer.movePrevios
                      |> Expect.all [ \m -> Expect.equal (Buffer.Mark (1,0) True  |> Just) m.mark
                                    , \m -> Expect.equal (Buffer.Range (1,0) (0,0) |> Just) m.selection
                                    ]

        , test "move-at(mark)" <|
              \_ ->
                  Buffer.init "ABC\nDE\nGHIJ\nK\n"
                      |> Buffer.moveForward
                      |> Buffer.markSet
                      |> Buffer.moveAt (2, 3)
                      |> Expect.all [ \m -> Expect.equal (Buffer.Mark (0,1) True  |> Just) m.mark
                                    , \m -> Expect.equal (Buffer.Range (0,1) (2,3) |> Just) m.selection
                                    ]

        , test "mark-clear by select-forward" <|
              \_ ->
                  Buffer.init "ABC\nDE\nGHIJ\nK\n"
                      |> Buffer.moveForward
                      |> Buffer.markSet
                      |> Buffer.moveForward
                      |> Buffer.selectForward
                      |> Expect.all [ \m -> Expect.equal (Buffer.Mark (0,1) False  |> Just) m.mark
                                    , \m -> Expect.equal (Buffer.Range (0,2) (0,3) |> Just) m.selection
                                    ]

        , test "mark-clear by select-backward" <|
              \_ ->
                  Buffer.init "ABC\nDE\nGHIJ\nK\n"
                      |> ntimesdo 2 Buffer.moveForward
                      |> Buffer.markSet
                      |> Buffer.moveBackward
                      |> Buffer.selectBackward
                      |> Expect.all [ \m -> Expect.equal (Buffer.Mark (0,2) False  |> Just) m.mark
                                    , \m -> Expect.equal (Buffer.Range (0,1) (0,0) |> Just) m.selection
                                    ]

        , test "mark-clear by select-next" <|
              \_ ->
                  Buffer.init "ABC\nDE\nGHIJ\nK\n"
                      |> Buffer.moveNext
                      |> Buffer.markSet
                      |> Buffer.moveNext
                      |> Buffer.selectNext
                      |> Expect.all [ \m -> Expect.equal (Buffer.Mark (1,0) False  |> Just) m.mark
                                    , \m -> Expect.equal (Buffer.Range (2,0) (3,0) |> Just) m.selection
                                    ]

        , test "mark-clear by select-previos" <|
              \_ ->
                  Buffer.init "ABC\nDE\nGHIJ\nK\n"
                      |> ntimesdo 3 Buffer.moveNext
                      |> Buffer.markSet
                      |> Buffer.movePrevios
                      |> Buffer.selectPrevios
                      |> Expect.all [ \m -> Expect.equal (Buffer.Mark (3,0) False  |> Just) m.mark
                                    , \m -> Expect.equal (Buffer.Range (2,0) (1,0) |> Just) m.selection
                                    ]

        , test "mark-clear by select-at" <|
              \_ ->
                  Buffer.init "ABC\nDE\nGHIJ\nK\n"
                      |> Buffer.moveAt (2,3)
                      |> Buffer.markSet
                      |> Buffer.moveAt (3,0)
                      |> Buffer.selectAt (1,0)
                      |> Expect.all [ \m -> Expect.equal (Buffer.Mark (2,3) False  |> Just) m.mark
                                    , \m -> Expect.equal (Buffer.Range (3,0) (1,0) |> Just) m.selection
                                    ]


        , test "goto mark" <|
              \_ ->
                  Buffer.init "ABC\nDE\nGHIJ\nK\n"
                      |> Buffer.moveAt (3, 0)
                      |> Buffer.markSet
                      |> Buffer.moveAt (2, 1)
                      |> Buffer.gotoMark
                      |> Buffer.nowCursorPos
                      |> Expect.equal (3, 0)

        ]



