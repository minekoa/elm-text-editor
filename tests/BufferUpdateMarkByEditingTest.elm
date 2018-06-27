module BufferUpdateMarkByEditingTest exposing (..)

import Expect exposing (Expectation)
import Test exposing (..)


import TextEditor.Buffer as Buffer exposing ((@))

ntimesdo : Int -> (a -> a) -> a -> a
ntimesdo  n f v =
    case n of
        0 ->
            v
        _ ->
            ntimesdo (n - 1) f (f v)

suite : Test
suite =
    describe "update Mark (by editing)"

        -- update mark by insert
        [ test "mark-update by insert (before row, 1char)" <|
              \_ ->
                  Buffer.init "ABC\nDEF\nGHmIJ\nK\n"
                      |> Buffer.moveAt (2@ 2)
                      |> Buffer.markSet
                      |> Buffer.markClear 
                      |> Buffer.insertAt (1@ 1) "a"
                      |> .mark
                      |> Expect.equal (Buffer.Mark (2, 2) False |> Just)

        , test "mark-update by insert (before row, 1line)" <|
              \_ ->
                  Buffer.init "ABC\nDEF\nGHmIJ\nK\n"
                      |> Buffer.moveAt (2@ 2)
                      |> Buffer.markSet
                      |> Buffer.markClear 
                      |> Buffer.insertAt (1@ 1) "a\nb"
                      |> .mark
                      |> Expect.equal (Buffer.Mark (3, 2) False |> Just)

        , test "mark-update by insert (just row, before column, 1char)" <|
              \_ ->
                  Buffer.init "ABC\nDEF\nGHmIJ\nK\n"
                      |> Buffer.moveAt (2@ 2)
                      |> Buffer.markSet
                      |> Buffer.markClear 
                      |> Buffer.insertAt (2@ 1) "a"
                      |> Expect.all [ \m -> Expect.equal "ABC\nDEF\nGaHmIJ\nK\n" (m.contents |> String.join "\n")
                                    , \m -> Expect.equal (Buffer.Mark (2, 3) False  |> Just) m.mark
                                    ]

        , test "mark-update by insert (just row, before column, 1line)" <|
              \_ ->
                  Buffer.init "ABC\nDEF\nGHmIJ\nK\n"
                      |> Buffer.moveAt (2@ 2)
                      |> Buffer.markSet
                      |> Buffer.markClear 
                      |> Buffer.insertAt (2@ 1) "\n"
                      |> Expect.all [ \m -> Expect.equal "ABC\nDEF\nG\nHmIJ\nK\n" (m.contents |> String.join "\n")
                                    , \m -> Expect.equal (Buffer.Mark (3, 1) False  |> Just) m.mark
                                    ]

        , test "mark-update by insert (just row, just column, 1char)" <|
              \_ ->
                  Buffer.init "ABC\nDEF\nGHmIJ\nK\n"
                      |> Buffer.moveAt (2@ 2)
                      |> Buffer.markSet
                      |> Buffer.markClear 
                      |> Buffer.insertAt (2@ 2) "a"
                      |> Expect.all [ \m -> Expect.equal "ABC\nDEF\nGHamIJ\nK\n" (m.contents |> String.join "\n")
                                    , \m -> Expect.equal (Buffer.Mark (2,3) False  |> Just) m.mark
                                    ]

        , test "mark-update by insert (just row, after column, 1car)" <|
              \_ ->
                  Buffer.init "ABC\nDEF\nGHmIJ\nK\n"
                      |> Buffer.moveAt (2@ 2)
                      |> Buffer.markSet
                      |> Buffer.markClear 
                      |> Buffer.insertAt (2@ 3) "a"
                      |> Expect.all [ \m -> Expect.equal "ABC\nDEF\nGHmaIJ\nK\n" (m.contents |> String.join "\n")
                                    , \m -> Expect.equal (Buffer.Mark (2,2) False  |> Just) m.mark
                                    ]

        , test "mark-update by insert (just row, after column, 1line)" <|
              \_ ->
                  Buffer.init "ABC\nDEF\nGHmIJ\nK\n"
                      |> Buffer.moveAt (2@ 2)
                      |> Buffer.markSet
                      |> Buffer.markClear 
                      |> Buffer.insertAt (2@ 3) "\n"
                      |> Expect.all [ \m -> Expect.equal "ABC\nDEF\nGHm\nIJ\nK\n" (m.contents |> String.join "\n")
                                    , \m -> Expect.equal (Buffer.Mark (2,2) False  |> Just) m.mark
                                    ]


        , test "mark-update by insert (after row)" <|
              \_ ->
                  Buffer.init "ABC\nDEF\nGHmIJ\nK\n"
                      |> Buffer.moveAt (2@ 2)
                      |> Buffer.markSet
                      |> Buffer.markClear 
                      |> Buffer.insertAt (3@ 0) "a\nb"
                      |> .mark
                      |> Expect.equal (Buffer.Mark (2, 2) False |> Just)



        -- update mark by delete one

        , test "mark-update by delete one (before row, 1char)" <|
              \_ ->
                  Buffer.init "ABC\nDEF\nGHmIJ\nK\n"
                      |> Buffer.moveAt (2@ 2)
                      |> Buffer.markSet
                      |> Buffer.markClear 
                      |> Buffer.deleteAt (1@ 1)
                      |> .mark
                      |> Expect.equal (Buffer.Mark (2, 2) False |> Just)

        , test "mark-update by delete one (before row, 1line)" <|
              \_ ->
                  Buffer.init "ABC\nDEF\nGHmIJ\nK\n"
                      |> Buffer.moveAt (2@ 2)
                      |> Buffer.markSet
                      |> Buffer.markClear 
                      |> Buffer.deleteAt (0@ 3)
                      |> Expect.all [ \m -> Expect.equal "ABCDEF\nGHmIJ\nK\n" (m.contents |> String.join "\n")
                                    , \m -> Expect.equal (Buffer.Mark (1,2) False  |> Just) m.mark
                                    ]


        , test "mark-update by delete one (before row, concat before and mark line)" <|
              \_ ->
                  Buffer.init "ABC\nDEF\nGHmIJ\nK\n"
                      |> Buffer.moveAt (2@ 2)
                      |> Buffer.markSet
                      |> Buffer.markClear 
                      |> Buffer.deleteAt (1@ 3)
                      |> Expect.all [ \m -> Expect.equal "ABC\nDEFGHmIJ\nK\n" (m.contents |> String.join "\n")
                                    , \m -> Expect.equal (Buffer.Mark (1, 5) False  |> Just) m.mark
                                    ]

        , test "mark-update by delete one (just row, before column, 1char)" <|
              \_ ->
                  Buffer.init "ABC\nDEF\nGHmIJ\nK\n"
                      |> Buffer.moveAt (2@ 2)
                      |> Buffer.markSet
                      |> Buffer.markClear 
                      |> Buffer.deleteAt (2@ 0)
                      |> Expect.all [ \m -> Expect.equal "ABC\nDEF\nHmIJ\nK\n" (m.contents |> String.join "\n")
                                    , \m -> Expect.equal (Buffer.Mark (2,1) False  |> Just) m.mark
                                    ]

        , test "mark-update by delete one (just row, before column, 1char (pre-char))" <|
              \_ ->
                  Buffer.init "ABC\nDEF\nGHmIJ\nK\n"
                      |> Buffer.moveAt (2@ 2)
                      |> Buffer.markSet
                      |> Buffer.markClear 
                      |> Buffer.deleteAt (2@ 1)
                      |> Expect.all [ \m -> Expect.equal "ABC\nDEF\nGmIJ\nK\n" (m.contents |> String.join "\n")
                                    , \m -> Expect.equal (Buffer.Mark (2,1) False  |> Just) m.mark
                                    ]

        , test "mark-update by delete one (just row, just column, 1char)" <|
              \_ ->
                  Buffer.init "ABC\nDEF\nGHmIJ\nK\n"
                      |> Buffer.moveAt (2@ 2)
                      |> Buffer.markSet
                      |> Buffer.markClear 
                      |> Buffer.deleteAt (2@ 2)
                      |> Expect.all [ \m -> Expect.equal "ABC\nDEF\nGHIJ\nK\n" (m.contents |> String.join "\n")
                                    , \m -> Expect.equal (Buffer.Mark (2,2) False  |> Just) m.mark
                                    ]

        , test "mark-update by delete one (just row, after column, 1car)" <|
              \_ ->
                  Buffer.init "ABC\nDEF\nGHmIJ\nK\n"
                      |> Buffer.moveAt (2@ 2)
                      |> Buffer.markSet
                      |> Buffer.markClear 
                      |> Buffer.deleteAt (2@ 3)
                      |> Expect.all [ \m -> Expect.equal "ABC\nDEF\nGHmJ\nK\n" (m.contents |> String.join "\n")
                                    , \m -> Expect.equal (Buffer.Mark (2,2) False  |> Just) m.mark
                                    ]

        , test "mark-update by delete one (just row, after column, 1line)" <|
              \_ ->
                  Buffer.init "ABC\nDEF\nGHmIJ\nK\n"
                      |> Buffer.moveAt (2@ 2)
                      |> Buffer.markSet
                      |> Buffer.markClear 
                      |> Buffer.deleteAt (2@ 5)
                      |> Expect.all [ \m -> Expect.equal "ABC\nDEF\nGHmIJK\n" (m.contents |> String.join "\n")
                                    , \m -> Expect.equal (Buffer.Mark (2,2) False  |> Just) m.mark
                                    ]

        , test "mark-update by delete one (after row)" <|
              \_ ->
                  Buffer.init "ABC\nDEF\nGHmIJ\nK\n"
                      |> Buffer.moveAt (2@ 2)
                      |> Buffer.markSet
                      |> Buffer.markClear 
                      |> Buffer.deleteAt (3@ 0)
                      |> .mark
                      |> Expect.equal (Buffer.Mark (2, 2) False |> Just)


        -- update mark by delete range

        , test "mark-update by delete range (before row, inline)" <|
              \_ ->
                  Buffer.init "ABC\nDEF\nGHmIJ\nKLM\n"
                      |> Buffer.moveAt (2@ 2)
                      |> Buffer.markSet
                      |> Buffer.markClear 
                      |> Buffer.deleteRange (Buffer.Range (1@ 0) (1@ 2))
                      |> Expect.all [ \m -> Expect.equal "ABC\nF\nGHmIJ\nKLM\n" (m.contents |> String.join "\n")
                                    , \m -> Expect.equal (Buffer.Mark (2, 2) False  |> Just) m.mark
                                    ]

        , test "mark-update by delete range (before row, multiline)" <|
              \_ ->
                  Buffer.init "ABC\nDEF\nGHmIJ\nKLM\n"
                      |> Buffer.moveAt (2@ 2)
                      |> Buffer.markSet
                      |> Buffer.markClear 
                      |> Buffer.deleteRange (Buffer.Range (0@ 1) (1@ 1))
                      |> Expect.all [ \m -> Expect.equal "AEF\nGHmIJ\nKLM\n" (m.contents |> String.join "\n")
                                    , \m -> Expect.equal (Buffer.Mark (1,2) False  |> Just) m.mark
                                    ]

        , test "mark-update by delete range (before row, delete -> concat before and markline)" <|
              \_ ->
                  Buffer.init "ABC\nDEF\nGHmIJ\nKLM\n"
                      |> Buffer.moveAt (2@ 2)
                      |> Buffer.markSet
                      |> Buffer.markClear 
                      |> Buffer.deleteRange (Buffer.Range (0@ 1) (2@ 0))
                      |> Expect.all [ \m -> Expect.equal "AGHmIJ\nKLM\n" (m.contents |> String.join "\n")
                                    , \m -> Expect.equal (Buffer.Mark (0,3) False  |> Just) m.mark
                                    ]

        , test "mark-update by delete range (row, multiline, contain mark)" <|
              \_ ->
                  Buffer.init "ABC\nDEF\nGHmIJ\nKLM\n"
                      |> Buffer.moveAt (2@ 2)
                      |> Buffer.markSet
                      |> Buffer.markClear 
                      |> Buffer.deleteRange (Buffer.Range (0@ 1) (3@ 1))
                      |> Expect.all [ \m -> Expect.equal "ALM\n" (m.contents |> String.join "\n")
                                    , \m -> Expect.equal (Buffer.Mark (0,1) False  |> Just) m.mark
                                    ]

        , test "mark-update by delete range (just row, before column, 1char)" <|
              \_ ->
                  Buffer.init "ABC\nDEF\nGHmIJ\nKLM\n"
                      |> Buffer.moveAt (2@ 2)
                      |> Buffer.markSet
                      |> Buffer.markClear 
                      |> Buffer.deleteRange (Buffer.Range (2@ 0) (2@ 2))
                      |> Expect.all [ \m -> Expect.equal "ABC\nDEF\nmIJ\nKLM\n" (m.contents |> String.join "\n")
                                    , \m -> Expect.equal (Buffer.Mark (2,0) False  |> Just) m.mark
                                    ]

        , test "mark-update by delete range (just row, inline, contain mark)" <|
              \_ ->
                  Buffer.init "ABC\nDEF\nGHmIJ\nKLM\n"
                      |> Buffer.moveAt (2@ 2)
                      |> Buffer.markSet
                      |> Buffer.markClear 
                      |> Buffer.deleteRange (Buffer.Range (2@ 1) (2@ 4))
                      |> Expect.all [ \m -> Expect.equal "ABC\nDEF\nGJ\nKLM\n" (m.contents |> String.join "\n")
                                    , \m -> Expect.equal (Buffer.Mark (2,1) False  |> Just) m.mark
                                    ]

        , test "mark-update by delete range (just row, before column, multiline, contain mark)" <|
              \_ ->
                  Buffer.init "ABC\nDEF\nGHmIJ\nKLM\n"
                      |> Buffer.moveAt (2@ 2)
                      |> Buffer.markSet
                      |> Buffer.markClear 
                      |> Buffer.deleteRange (Buffer.Range (2@ 1) (3@ 1))
                      |> Expect.all [ \m -> Expect.equal "ABC\nDEF\nGLM\n" (m.contents |> String.join "\n")
                                    , \m -> Expect.equal (Buffer.Mark (2,1) False  |> Just) m.mark
                                    ]

        , test "mark-update by delete range (just row, just column, 1char)" <|
              \_ ->
                  Buffer.init "ABC\nDEF\nGHmIJ\nKLM\n"
                      |> Buffer.moveAt (2@ 2)
                      |> Buffer.markSet
                      |> Buffer.markClear 
                      |> Buffer.deleteRange (Buffer.Range (2@ 2) (2@ 3))
                      |> Expect.all [ \m -> Expect.equal "ABC\nDEF\nGHIJ\nKLM\n" (m.contents |> String.join "\n")
                                    , \m -> Expect.equal (Buffer.Mark (2,2) False  |> Just) m.mark
                                    ]

        , test "mark-update by delete range (just row, just column, multiline)" <|
              \_ ->
                  Buffer.init "ABC\nDEF\nGHmIJ\nKLM\n"
                      |> Buffer.moveAt (2@ 2)
                      |> Buffer.markSet
                      |> Buffer.markClear 
                      |> Buffer.deleteRange (Buffer.Range (2@ 2) (3@ 1))
                      |> Expect.all [ \m -> Expect.equal "ABC\nDEF\nGHLM\n" (m.contents |> String.join "\n")
                                    , \m -> Expect.equal (Buffer.Mark (2,2) False  |> Just) m.mark
                                    ]

        , test "mark-update by delete range (just row, after column, inline)" <|
              \_ ->
                  Buffer.init "ABC\nDEF\nGHmIJ\nKLM\n"
                      |> Buffer.moveAt (2@ 2)
                      |> Buffer.markSet
                      |> Buffer.markClear 
                      |> Buffer.deleteRange (Buffer.Range (2@ 3) (2@ 5))
                      |> Expect.all [ \m -> Expect.equal "ABC\nDEF\nGHm\nKLM\n" (m.contents |> String.join "\n")
                                    , \m -> Expect.equal (Buffer.Mark (2,2) False  |> Just) m.mark
                                    ]

        , test "mark-update by delete range (just row, after column, multiline)" <|
              \_ ->
                  Buffer.init "ABC\nDEF\nGHmIJ\nKLM\n"
                      |> Buffer.moveAt (2@ 2)
                      |> Buffer.markSet
                      |> Buffer.markClear 
                      |> Buffer.deleteRange (Buffer.Range (2@ 3) (3@ 1))
                      |> Expect.all [ \m -> Expect.equal "ABC\nDEF\nGHmLM\n" (m.contents |> String.join "\n")
                                    , \m -> Expect.equal (Buffer.Mark (2,2) False  |> Just) m.mark
                                    ]

        , test "mark-update by delete range (after row)" <|
              \_ ->
                  Buffer.init "ABC\nDEF\nGHmIJ\nKLM\n"
                      |> Buffer.moveAt (2@ 2)
                      |> Buffer.markSet
                      |> Buffer.markClear 
                      |> Buffer.deleteRange (Buffer.Range (3@ 0) (3@ 2))
                      |> Expect.all [ \m -> Expect.equal "ABC\nDEF\nGHmIJ\nM\n" (m.contents |> String.join "\n")
                                    , \m -> Expect.equal (Buffer.Mark (2,2) False  |> Just) m.mark
                                    ]


        -- update mark by backspace

        , test "mark-update by backspace (before row, 1char)" <|
              \_ ->
                  Buffer.init "ABC\nDEF\nGHmIJ\nKLM\n"
                      |> Buffer.moveAt (2@ 2)
                      |> Buffer.markSet
                      |> Buffer.markClear 
                      |> Buffer.backspaceAt (1@ 2)
                      |> .mark
                      |> Expect.equal (Buffer.Mark (2, 2) False |> Just)

        , test "mark-update by backspace (before row, 1line)" <|
              \_ ->
                  Buffer.init "ABC\nDEF\nGHmIJ\nKLM\n"
                      |> Buffer.moveAt (2@ 2)
                      |> Buffer.markSet
                      |> Buffer.markClear 
                      |> Buffer.backspaceAt (1@ 0)
                      |> Expect.all [ \m -> Expect.equal "ABCDEF\nGHmIJ\nKLM\n" (m.contents |> String.join "\n")
                                    , \m -> Expect.equal (Buffer.Mark (1,2) False  |> Just) m.mark
                                    ]

        , test "mark-update by backspace (before row, concat before and mark line)" <|
              \_ ->
                  Buffer.init "ABC\nDEF\nGHmIJ\nKLM\n"
                      |> Buffer.moveAt (2@ 2)
                      |> Buffer.markSet
                      |> Buffer.markClear 
                      |> Buffer.backspaceAt (2@ 0)
                      |> Expect.all [ \m -> Expect.equal "ABC\nDEFGHmIJ\nKLM\n" (m.contents |> String.join "\n")
                                    , \m -> Expect.equal (Buffer.Mark (1, 5) False  |> Just) m.mark
                                    ]

        , test "mark-update by backspace (just row, before column, 1char)" <|
              \_ ->
                  Buffer.init "ABC\nDEF\nGHmIJ\nKLM\n"
                      |> Buffer.moveAt (2@ 2)
                      |> Buffer.markSet
                      |> Buffer.markClear 
                      |> Buffer.backspaceAt (2@ 1)
                      |> Expect.all [ \m -> Expect.equal "ABC\nDEF\nHmIJ\nKLM\n" (m.contents |> String.join "\n")
                                    , \m -> Expect.equal (Buffer.Mark (2, 1) False  |> Just) m.mark
                                    ]

        , test "mark-update by backspace (just row, just column, 1char (deleted pre-char))" <|
              \_ ->
                  Buffer.init "ABC\nDEF\nGHmIJ\nKLM\n"
                      |> Buffer.moveAt (2@ 2)
                      |> Buffer.markSet
                      |> Buffer.markClear 
                      |> Buffer.backspaceAt (2@ 2)
                      |> Expect.all [ \m -> Expect.equal "ABC\nDEF\nGmIJ\nKLM\n" (m.contents |> String.join "\n")
                                    , \m -> Expect.equal (Buffer.Mark (2,1) False  |> Just) m.mark
                                    ]

        , test "mark-update by backspace (just row, after column, (deleted just marked))" <|
              \_ ->
                  Buffer.init "ABC\nDEF\nGHmIJ\nKLM\n"
                      |> Buffer.moveAt (2@ 2)
                      |> Buffer.markSet
                      |> Buffer.markClear 
                      |> Buffer.backspaceAt (2@ 3)
                      |> Expect.all [ \m -> Expect.equal "ABC\nDEF\nGHIJ\nKLM\n" (m.contents |> String.join "\n")
                                    , \m -> Expect.equal (Buffer.Mark (2,2) False  |> Just) m.mark
                                    ]

        , test "mark-update by backspace one (just row, after column, 1car)" <|
              \_ ->
                  Buffer.init "ABC\nDEF\nGHmIJ\nKLM\n"
                      |> Buffer.moveAt (2@ 2)
                      |> Buffer.markSet
                      |> Buffer.markClear 
                      |> Buffer.backspaceAt (2@ 4)
                      |> Expect.all [ \m -> Expect.equal "ABC\nDEF\nGHmJ\nKLM\n" (m.contents |> String.join "\n")
                                    , \m -> Expect.equal (Buffer.Mark (2,2) False  |> Just) m.mark
                                    ]

        , test "mark-update by backspace (after row, concat mark and after line)" <|
              \_ ->
                  Buffer.init "ABC\nDEF\nGHmIJ\nKLM\n"
                      |> Buffer.moveAt (2@ 2)
                      |> Buffer.markSet
                      |> Buffer.markClear 
                      |> Buffer.backspaceAt (3@ 0)
                      |> Expect.all [ \m -> Expect.equal "ABC\nDEF\nGHmIJKLM\n" (m.contents |> String.join "\n")
                                    , \m -> Expect.equal (Buffer.Mark (2,2) False  |> Just) m.mark
                                    ]

        , test "mark-update by backspace (after row)" <|
              \_ ->
                  Buffer.init "ABC\nDEF\nGHmIJ\nKLM\n"
                      |> Buffer.moveAt (2@ 2)
                      |> Buffer.markSet
                      |> Buffer.markClear 
                      |> Buffer.backspaceAt (3@ 1)
                      |> Expect.all [ \m -> Expect.equal "ABC\nDEF\nGHmIJ\nLM\n" (m.contents |> String.join "\n")
                                    , \m -> Expect.equal (Buffer.Mark (2,2) False  |> Just) m.mark
                                    ]
        ]


        
