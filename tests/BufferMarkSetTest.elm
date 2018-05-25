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


        -- update mark by insert

        , test "mark-update by insert (before row, 1char)" <|
              \_ ->
                  Buffer.init "ABC\nDEF\nGHmIJ\nK\n"
                      |> Buffer.moveAt (2, 2)
                      |> Buffer.markSet
                      |> Buffer.markClear 
                      |> Buffer.insertAt (1, 1) "a"
                      |> .mark
                      |> Expect.equal (Buffer.Mark (2, 2) False |> Just)

        , test "mark-update by insert (before row, 1line)" <|
              \_ ->
                  Buffer.init "ABC\nDEF\nGHmIJ\nK\n"
                      |> Buffer.moveAt (2, 2)
                      |> Buffer.markSet
                      |> Buffer.markClear 
                      |> Buffer.insertAt (1, 1) "a\nb"
                      |> .mark
                      |> Expect.equal (Buffer.Mark (3, 2) False |> Just)

        , test "mark-update by insert (just row, before column, 1char)" <|
              \_ ->
                  Buffer.init "ABC\nDEF\nGHmIJ\nK\n"
                      |> Buffer.moveAt (2, 2)
                      |> Buffer.markSet
                      |> Buffer.markClear 
                      |> Buffer.insertAt (2, 1) "a"
                      |> Expect.all [ \m -> Expect.equal "ABC\nDEF\nGaHmIJ\nK\n" (m.contents |> String.join "\n")
                                    , \m -> Expect.equal (Buffer.Mark (3,0) False  |> Just) m.mark
                                    ]

        , test "mark-update by insert (just row, before column, 1line)" <|
              \_ ->
                  Buffer.init "ABC\nDEF\nGHmIJ\nK\n"
                      |> Buffer.moveAt (2, 2)
                      |> Buffer.markSet
                      |> Buffer.markClear 
                      |> Buffer.insertAt (2, 1) "\n"
                      |> Expect.all [ \m -> Expect.equal "ABC\nDEF\nG\nHmIJ\nK\n" (m.contents |> String.join "\n")
                                    , \m -> Expect.equal (Buffer.Mark (3,0) False  |> Just) m.mark
                                    ]

        , test "mark-update by insert (just row, just column, 1char)" <|
              \_ ->
                  Buffer.init "ABC\nDEF\nGHmIJ\nK\n"
                      |> Buffer.moveAt (2, 2)
                      |> Buffer.markSet
                      |> Buffer.markClear 
                      |> Buffer.insertAt (2, 2) "a"
                      |> Expect.all [ \m -> Expect.equal "ABC\nDEF\nGHamIJ\nK\n" (m.contents |> String.join "\n")
                                    , \m -> Expect.equal (Buffer.Mark (2,3) False  |> Just) m.mark
                                    ]

        , test "mark-update by insert (just row, after column, 1car)" <|
              \_ ->
                  Buffer.init "ABC\nDEF\nGHmIJ\nK\n"
                      |> Buffer.moveAt (2, 2)
                      |> Buffer.markSet
                      |> Buffer.markClear 
                      |> Buffer.insertAt (2, 3) "a"
                      |> Expect.all [ \m -> Expect.equal "ABC\nDEF\nGHmaIJ\nK\n" (m.contents |> String.join "\n")
                                    , \m -> Expect.equal (Buffer.Mark (2,2) False  |> Just) m.mark
                                    ]

        , test "mark-update by insert (just row, after column, 1line)" <|
              \_ ->
                  Buffer.init "ABC\nDEF\nGHmIJ\nK\n"
                      |> Buffer.moveAt (2, 2)
                      |> Buffer.markSet
                      |> Buffer.markClear 
                      |> Buffer.insertAt (2, 3) "\n"
                      |> Expect.all [ \m -> Expect.equal "ABC\nDEF\nGHm\nIJ\nK\n" (m.contents |> String.join "\n")
                                    , \m -> Expect.equal (Buffer.Mark (2,2) False  |> Just) m.mark
                                    ]


        , test "mark-update by insert (after row)" <|
              \_ ->
                  Buffer.init "ABC\nDEF\nGHmIJ\nK\n"
                      |> Buffer.moveAt (2, 2)
                      |> Buffer.markSet
                      |> Buffer.markClear 
                      |> Buffer.insertAt (3, 0) "a\nb"
                      |> .mark
                      |> Expect.equal (Buffer.Mark (2, 2) False |> Just)



        -- update mark by delete one

        , test "mark-update by delete one (before row, 1char)" <|
              \_ ->
                  Buffer.init "ABC\nDEF\nGHmIJ\nK\n"
                      |> Buffer.moveAt (2, 2)
                      |> Buffer.markSet
                      |> Buffer.markClear 
                      |> Buffer.deleteAt (1, 1)
                      |> .mark
                      |> Expect.equal (Buffer.Mark (2, 2) False |> Just)

        , test "mark-update by delete one (before row, 1line)" <|
              \_ ->
                  Buffer.init "ABC\nDEF\nGHmIJ\nK\n"
                      |> Buffer.moveAt (2, 2)
                      |> Buffer.markSet
                      |> Buffer.markClear 
                      |> Buffer.deleteAt (0, 3)
                      |> Expect.all [ \m -> Expect.equal "ABCDEF\nGHmIJ\nK\n" (m.contents |> String.join "\n")
                                    , \m -> Expect.equal (Buffer.Mark (1,2) False  |> Just) m.mark
                                    ]


        , test "mark-update by delete one (before row, concat before and mark line)" <|
              \_ ->
                  Buffer.init "ABC\nDEF\nGHmIJ\nK\n"
                      |> Buffer.moveAt (2, 2)
                      |> Buffer.markSet
                      |> Buffer.markClear 
                      |> Buffer.deleteAt (1, 3)
                      |> Expect.all [ \m -> Expect.equal "ABC\nDEFGHmIJ\nK\n" (m.contents |> String.join "\n")
                                    , \m -> Expect.equal (Buffer.Mark (2,1) False  |> Just) m.mark
                                    ]

        , test "mark-update by delete one (just row, before column, 1char)" <|
              \_ ->
                  Buffer.init "ABC\nDEF\nGHmIJ\nK\n"
                      |> Buffer.moveAt (2, 2)
                      |> Buffer.markSet
                      |> Buffer.markClear 
                      |> Buffer.deleteAt (2, 0)
                      |> Expect.all [ \m -> Expect.equal "ABC\nDEF\nHmIJ\nK\n" (m.contents |> String.join "\n")
                                    , \m -> Expect.equal (Buffer.Mark (2,1) False  |> Just) m.mark
                                    ]

        , test "mark-update by delete one (just row, before column, 1char (pre-char))" <|
              \_ ->
                  Buffer.init "ABC\nDEF\nGHmIJ\nK\n"
                      |> Buffer.moveAt (2, 2)
                      |> Buffer.markSet
                      |> Buffer.markClear 
                      |> Buffer.deleteAt (2, 1)
                      |> Expect.all [ \m -> Expect.equal "ABC\nDEF\nGmIJ\nK\n" (m.contents |> String.join "\n")
                                    , \m -> Expect.equal (Buffer.Mark (2,1) False  |> Just) m.mark
                                    ]

        , test "mark-update by delete one (just row, just column, 1char)" <|
              \_ ->
                  Buffer.init "ABC\nDEF\nGHmIJ\nK\n"
                      |> Buffer.moveAt (2, 2)
                      |> Buffer.markSet
                      |> Buffer.markClear 
                      |> Buffer.deleteAt (2, 2)
                      |> Expect.all [ \m -> Expect.equal "ABC\nDEF\nGHIJ\nK\n" (m.contents |> String.join "\n")
                                    , \m -> Expect.equal (Buffer.Mark (2,2) False  |> Just) m.mark
                                    ]

        , test "mark-update by delete one (just row, after column, 1car)" <|
              \_ ->
                  Buffer.init "ABC\nDEF\nGHmIJ\nK\n"
                      |> Buffer.moveAt (2, 2)
                      |> Buffer.markSet
                      |> Buffer.markClear 
                      |> Buffer.deleteAt (2, 3)
                      |> Expect.all [ \m -> Expect.equal "ABC\nDEF\nGHmJ\nK\n" (m.contents |> String.join "\n")
                                    , \m -> Expect.equal (Buffer.Mark (2,2) False  |> Just) m.mark
                                    ]

        , test "mark-update by delete one (just row, after column, 1line)" <|
              \_ ->
                  Buffer.init "ABC\nDEF\nGHmIJ\nK\n"
                      |> Buffer.moveAt (2, 2)
                      |> Buffer.markSet
                      |> Buffer.markClear 
                      |> Buffer.deleteAt (2, 5)
                      |> Expect.all [ \m -> Expect.equal "ABC\nDEF\nGHmIJK\n" (m.contents |> String.join "\n")
                                    , \m -> Expect.equal (Buffer.Mark (2,2) False  |> Just) m.mark
                                    ]

        , test "mark-update by delete one (after row)" <|
              \_ ->
                  Buffer.init "ABC\nDEF\nGHmIJ\nK\n"
                      |> Buffer.moveAt (2, 2)
                      |> Buffer.markSet
                      |> Buffer.markClear 
                      |> Buffer.deleteAt (3, 0)
                      |> .mark
                      |> Expect.equal (Buffer.Mark (2, 2) False |> Just)


        -- update mark by delete range

        , test "mark-update by delete range (before row, inline)" <|
              \_ ->
                  Buffer.init "ABC\nDEF\nGHmIJ\nKLM\n"
                      |> Buffer.moveAt (2, 2)
                      |> Buffer.markSet
                      |> Buffer.markClear 
                      |> Buffer.deleteRange (Buffer.Range (1, 0) (1, 2))
                      |> Expect.all [ \m -> Expect.equal "ABC\nF\nGHmIJ\nKLM\n" (m.contents |> String.join "\n")
                                    , \m -> Expect.equal (Buffer.Mark (2, 2) False  |> Just) m.mark
                                    ]

        , test "mark-update by delete range (before row, multiline)" <|
              \_ ->
                  Buffer.init "ABC\nDEF\nGHmIJ\nKLM\n"
                      |> Buffer.moveAt (2, 2)
                      |> Buffer.markSet
                      |> Buffer.markClear 
                      |> Buffer.deleteRange (Buffer.Range (0, 1) (1, 1))
                      |> Expect.all [ \m -> Expect.equal "AEF\nGHmIJ\nKLM\n" (m.contents |> String.join "\n")
                                    , \m -> Expect.equal (Buffer.Mark (1,2) False  |> Just) m.mark
                                    ]

        , test "mark-update by delete range (before row, delete -> concat before and markline)" <|
              \_ ->
                  Buffer.init "ABC\nDEF\nGHmIJ\nKLM\n"
                      |> Buffer.moveAt (2, 2)
                      |> Buffer.markSet
                      |> Buffer.markClear 
                      |> Buffer.deleteRange (Buffer.Range (0, 1) (2, 0))
                      |> Expect.all [ \m -> Expect.equal "AGHmIJ\nKLM\n" (m.contents |> String.join "\n")
                                    , \m -> Expect.equal (Buffer.Mark (0,3) False  |> Just) m.mark
                                    ]

        , test "mark-update by delete range (row, multiline, contain mark)" <|
              \_ ->
                  Buffer.init "ABC\nDEF\nGHmIJ\nKLM\n"
                      |> Buffer.moveAt (2, 2)
                      |> Buffer.markSet
                      |> Buffer.markClear 
                      |> Buffer.deleteRange (Buffer.Range (0, 1) (3, 1))
                      |> Expect.all [ \m -> Expect.equal "ALM\n" (m.contents |> String.join "\n")
                                    , \m -> Expect.equal (Buffer.Mark (0,1) False  |> Just) m.mark
                                    ]

        , test "mark-update by delete range (just row, before column, 1char)" <|
              \_ ->
                  Buffer.init "ABC\nDEF\nGHmIJ\nKLM\n"
                      |> Buffer.moveAt (2, 2)
                      |> Buffer.markSet
                      |> Buffer.markClear 
                      |> Buffer.deleteRange (Buffer.Range (2, 0) (2, 2))
                      |> Expect.all [ \m -> Expect.equal "ABC\nDEF\nmIJ\nKLM\n" (m.contents |> String.join "\n")
                                    , \m -> Expect.equal (Buffer.Mark (2,0) False  |> Just) m.mark
                                    ]

        , test "mark-update by delete range (just row, inline, contain mark)" <|
              \_ ->
                  Buffer.init "ABC\nDEF\nGHmIJ\nKLM\n"
                      |> Buffer.moveAt (2, 2)
                      |> Buffer.markSet
                      |> Buffer.markClear 
                      |> Buffer.deleteRange (Buffer.Range (2, 1) (2, 4))
                      |> Expect.all [ \m -> Expect.equal "ABC\nDEF\nGJ\nKLM\n" (m.contents |> String.join "\n")
                                    , \m -> Expect.equal (Buffer.Mark (2,1) False  |> Just) m.mark
                                    ]

        , test "mark-update by delete range (just row, before column, multiline, contain mark)" <|
              \_ ->
                  Buffer.init "ABC\nDEF\nGHmIJ\nKLM\n"
                      |> Buffer.moveAt (2, 2)
                      |> Buffer.markSet
                      |> Buffer.markClear 
                      |> Buffer.deleteRange (Buffer.Range (2, 1) (3, 1))
                      |> Expect.all [ \m -> Expect.equal "ABC\nDEF\nGLM\n" (m.contents |> String.join "\n")
                                    , \m -> Expect.equal (Buffer.Mark (2,1) False  |> Just) m.mark
                                    ]

        , test "mark-update by delete range (just row, just column, 1char)" <|
              \_ ->
                  Buffer.init "ABC\nDEF\nGHmIJ\nKLM\n"
                      |> Buffer.moveAt (2, 2)
                      |> Buffer.markSet
                      |> Buffer.markClear 
                      |> Buffer.deleteRange (Buffer.Range (2, 2) (2, 3))
                      |> Expect.all [ \m -> Expect.equal "ABC\nDEF\nGHIJ\nKLM\n" (m.contents |> String.join "\n")
                                    , \m -> Expect.equal (Buffer.Mark (2,2) False  |> Just) m.mark
                                    ]

        , test "mark-update by delete range (just row, just column, multiline)" <|
              \_ ->
                  Buffer.init "ABC\nDEF\nGHmIJ\nKLM\n"
                      |> Buffer.moveAt (2, 2)
                      |> Buffer.markSet
                      |> Buffer.markClear 
                      |> Buffer.deleteRange (Buffer.Range (2, 2) (3, 1))
                      |> Expect.all [ \m -> Expect.equal "ABC\nDEF\nGHLM\n" (m.contents |> String.join "\n")
                                    , \m -> Expect.equal (Buffer.Mark (2,2) False  |> Just) m.mark
                                    ]

        , test "mark-update by delete range (just row, after column, inline)" <|
              \_ ->
                  Buffer.init "ABC\nDEF\nGHmIJ\nKLM\n"
                      |> Buffer.moveAt (2, 2)
                      |> Buffer.markSet
                      |> Buffer.markClear 
                      |> Buffer.deleteRange (Buffer.Range (2, 3) (2, 5))
                      |> Expect.all [ \m -> Expect.equal "ABC\nDEF\nGHm\nKLM\n" (m.contents |> String.join "\n")
                                    , \m -> Expect.equal (Buffer.Mark (2,2) False  |> Just) m.mark
                                    ]

        , test "mark-update by delete range (just row, after column, multiline)" <|
              \_ ->
                  Buffer.init "ABC\nDEF\nGHmIJ\nKLM\n"
                      |> Buffer.moveAt (2, 2)
                      |> Buffer.markSet
                      |> Buffer.markClear 
                      |> Buffer.deleteRange (Buffer.Range (2, 3) (3, 1))
                      |> Expect.all [ \m -> Expect.equal "ABC\nDEF\nGHmLM\n" (m.contents |> String.join "\n")
                                    , \m -> Expect.equal (Buffer.Mark (2,2) False  |> Just) m.mark
                                    ]

        , test "mark-update by delete range (after row)" <|
              \_ ->
                  Buffer.init "ABC\nDEF\nGHmIJ\nKLM\n"
                      |> Buffer.moveAt (2, 2)
                      |> Buffer.markSet
                      |> Buffer.markClear 
                      |> Buffer.deleteRange (Buffer.Range (3, 0) (3, 2))
                      |> Expect.all [ \m -> Expect.equal "ABC\nDEF\nGHmIJ\nM\n" (m.contents |> String.join "\n")
                                    , \m -> Expect.equal (Buffer.Mark (2,2) False  |> Just) m.mark
                                    ]
        ]



