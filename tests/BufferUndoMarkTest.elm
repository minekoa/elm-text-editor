module BufferUndoMarkTest exposing (..)

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
    describe "update Mark (from update by editing)"

        -- update mark from update by insert
        [ test "undo mark from update by insert (before row, 1char)" <|
              \_ ->
                  Buffer.init "ABC\nDEF\nGHmIJ\nK\n"
                      |> Buffer.moveAt (2@ 2)
                      |> Buffer.markSet
                      |> Buffer.markClear 
                      |> Buffer.insertAt (1@ 1) "a"
                      |> Buffer.undo
                      |> .mark
                      |> Expect.equal (Buffer.Mark (2, 2) False |> Just)

        , test "undo mark from update by insert (before row, 1line)" <|
              \_ ->
                  Buffer.init "ABC\nDEF\nGHmIJ\nK\n"
                      |> Buffer.moveAt (2@ 2)
                      |> Buffer.markSet
                      |> Buffer.markClear 
                      |> Buffer.insertAt (1@ 1) "a\nb"
                      |> Buffer.undo
                      |> .mark
                      |> Expect.equal (Buffer.Mark (2, 2) False |> Just)

        , test "undo mark from update by insert (just row, before column, 1char)" <|
              \_ ->
                  Buffer.init "ABC\nDEF\nGHmIJ\nKLM\n"
                      |> Buffer.moveAt (2@ 2)
                      |> Buffer.markSet
                      |> Buffer.markClear 
                      |> Buffer.insertAt (2@ 1) "a"
                      |> Buffer.undo
                      |> Expect.all [ \m -> Expect.equal "ABC\nDEF\nGHmIJ\nKLM\n" (m.contents |> String.join "\n")
                                    , \m -> Expect.equal (Buffer.Mark (2, 2) False  |> Just) m.mark
                                    ]

        , test "undo mark from update by insert (just row, before column, 1line)" <|
              \_ ->
                  Buffer.init "ABC\nDEF\nGHmIJ\nKLM\n"
                      |> Buffer.moveAt (2@ 2)
                      |> Buffer.markSet
                      |> Buffer.markClear 
                      |> Buffer.insertAt (2@ 1) "\n"
                      |> Buffer.undo
                      |> Expect.all [ \m -> Expect.equal "ABC\nDEF\nGHmIJ\nKLM\n" (m.contents |> String.join "\n")
                                    , \m -> Expect.equal (Buffer.Mark (2, 2) False  |> Just) m.mark
                                    ]

        , test "undo mark from update by insert (just row, before column, 1line, double insert <concat history>)" <|
              \_ ->
                  Buffer.init "ABC\nDEF\nGHmIJ\nKLM\n"
                      |> Buffer.moveAt (2 @2)
                      |> Buffer.markSet
                      |> Buffer.markClear 
                      |> Buffer.insertAt (2@ 1) "a"
                      |> Buffer.insertAt (2@ 2) "b"
                      |> Buffer.undo
                      |> Expect.all [ \m -> Expect.equal "ABC\nDEF\nGHmIJ\nKLM\n" (m.contents |> String.join "\n")
                                    , \m -> Expect.equal (Buffer.Mark (2, 2) False  |> Just) m.mark
                                    ]


        , test "undo mark from update by insert (just row, just column, 1char)" <|
              \_ ->
                  Buffer.init "ABC\nDEF\nGHmIJ\nKLM\n"
                      |> Buffer.moveAt (2@ 2)
                      |> Buffer.markSet
                      |> Buffer.markClear 
                      |> Buffer.insertAt (2@ 2) "a"
                      |> Buffer.undo
                      |> Expect.all [ \m -> Expect.equal "ABC\nDEF\nGHmIJ\nKLM\n" (m.contents |> String.join "\n")
                                    , \m -> Expect.equal (Buffer.Mark (2, 2) False  |> Just) m.mark
                                    ]

        , test "undo mark from update by insert (just row, after column, 1car)" <|
              \_ ->
                  Buffer.init "ABC\nDEF\nGHmIJ\nKLM\n"
                      |> Buffer.moveAt (2@ 2)
                      |> Buffer.markSet
                      |> Buffer.markClear 
                      |> Buffer.insertAt (2@ 3) "a"
                      |> Buffer.undo
                      |> Expect.all [ \m -> Expect.equal "ABC\nDEF\nGHmIJ\nKLM\n" (m.contents |> String.join "\n")
                                    , \m -> Expect.equal (Buffer.Mark (2, 2) False  |> Just) m.mark
                                    ]

        , test "undo mark from update by insert (just row, after column, 1line)" <|
              \_ ->
                  Buffer.init "ABC\nDEF\nGHmIJ\nKLM\n"
                      |> Buffer.moveAt (2@ 2)
                      |> Buffer.markSet
                      |> Buffer.markClear 
                      |> Buffer.insertAt (2@ 3) "\n"
                      |> Buffer.undo
                      |> Expect.all [ \m -> Expect.equal "ABC\nDEF\nGHmIJ\nKLM\n" (m.contents |> String.join "\n")
                                    , \m -> Expect.equal (Buffer.Mark (2, 2) False  |> Just) m.mark
                                    ]


        , test "undo mark from update by insert (after row)" <|
              \_ ->
                  Buffer.init "ABC\nDEF\nGHmIJ\nKLM\n"
                      |> Buffer.moveAt (2@ 2)
                      |> Buffer.markSet
                      |> Buffer.markClear 
                      |> Buffer.insertAt (3@ 0) "a\nb"
                      |> Buffer.undo
                      |> .mark
                      |> Expect.equal (Buffer.Mark (2, 2) False |> Just)



        -- update mark from update by delete one

        , test "undo mark from update by delete one (before row, 1char)" <|
              \_ ->
                  Buffer.init "ABC\nDEF\nGHmIJ\nKLM\n"
                      |> Buffer.moveAt (2@ 2)
                      |> Buffer.markSet
                      |> Buffer.markClear 
                      |> Buffer.deleteAt (1@ 1)
                      |> Buffer.undo
                      |> .mark
                      |> Expect.equal (Buffer.Mark (2, 2) False |> Just)

        , test "undo mark from update by delete one (before row, 1line)" <|
              \_ ->
                  Buffer.init "ABC\nDEF\nGHmIJ\nKLM\n"
                      |> Buffer.moveAt (2@ 2)
                      |> Buffer.markSet
                      |> Buffer.markClear 
                      |> Buffer.deleteAt (0@ 3)
                      |> Buffer.undo
                      |> Expect.all [ \m -> Expect.equal "ABC\nDEF\nGHmIJ\nKLM\n" (m.contents |> String.join "\n")
                                    , \m -> Expect.equal (Buffer.Mark (2, 2) False  |> Just) m.mark
                                    ]


        , test "undo mark from update by delete one (before row, concat before and mark line)" <|
              \_ ->
                  Buffer.init "ABC\nDEF\nGHmIJ\nKLM\n"
                      |> Buffer.moveAt (2@ 2)
                      |> Buffer.markSet
                      |> Buffer.markClear 
                      |> Buffer.deleteAt (1@ 3)
                      |> Buffer.undo
                      |> Expect.all [ \m -> Expect.equal "ABC\nDEF\nGHmIJ\nKLM\n" (m.contents |> String.join "\n")
                                    , \m -> Expect.equal (Buffer.Mark (2, 2) False  |> Just) m.mark
                                    ]

        , test "undo mark from update by delete one (just row, before column, 1char)" <|
              \_ ->
                  Buffer.init "ABC\nDEF\nGHmIJ\nKLM\n"
                      |> Buffer.moveAt (2@ 2)
                      |> Buffer.markSet
                      |> Buffer.markClear 
                      |> Buffer.deleteAt (2@ 0)
                      |> Buffer.undo
                      |> Expect.all [ \m -> Expect.equal "ABC\nDEF\nGHmIJ\nKLM\n" (m.contents |> String.join "\n")
                                    , \m -> Expect.equal (Buffer.Mark (2, 2) False  |> Just) m.mark
                                    ]

        , test "undo mark from update by delete one (just row, before column, 1char, double delete <concat history>)" <|
              \_ ->
                  Buffer.init "ABC\nDEF\nGHmIJ\nKLM\n"
                      |> Buffer.moveAt (2@ 2)
                      |> Buffer.markSet
                      |> Buffer.markClear 
                      |> Buffer.deleteAt (2@ 0)
                      |> Buffer.deleteAt (2@ 0)
                      |> Buffer.undo
                      |> Expect.all [ \m -> Expect.equal "ABC\nDEF\nGHmIJ\nKLM\n" (m.contents |> String.join "\n")
                                    , \m -> Expect.equal (Buffer.Mark (2, 2) False  |> Just) m.mark
                                    ]


        , test "undo mark from update by delete one (just row, before column, 1char (pre-char))" <|
              \_ ->
                  Buffer.init "ABC\nDEF\nGHmIJ\nKLM\n"
                      |> Buffer.moveAt (2@ 2)
                      |> Buffer.markSet
                      |> Buffer.markClear 
                      |> Buffer.deleteAt (2@ 1)
                      |> Buffer.undo
                      |> Expect.all [ \m -> Expect.equal "ABC\nDEF\nGHmIJ\nKLM\n" (m.contents |> String.join "\n")
                                    , \m -> Expect.equal (Buffer.Mark (2, 2) False  |> Just) m.mark
                                    ]

        , test "undo mark from update by delete one (just row, just column, 1char)" <|
              \_ ->
                  Buffer.init "ABC\nDEF\nGHmIJ\nKLM\n"
                      |> Buffer.moveAt (2@ 2)
                      |> Buffer.markSet
                      |> Buffer.markClear 
                      |> Buffer.deleteAt (2@ 2)
                      |> Buffer.undo
                      |> Expect.all [ \m -> Expect.equal "ABC\nDEF\nGHmIJ\nKLM\n" (m.contents |> String.join "\n")
                                    , \m -> Expect.equal (Buffer.Mark (2, 2) False  |> Just) m.mark
                                    ]

        , test "undo mark from update by delete one (just row, after column, 1car)" <|
              \_ ->
                  Buffer.init "ABC\nDEF\nGHmIJ\nKLM\n"
                      |> Buffer.moveAt (2@ 2)
                      |> Buffer.markSet
                      |> Buffer.markClear 
                      |> Buffer.deleteAt (2@ 3)
                      |> Buffer.undo
                      |> Expect.all [ \m -> Expect.equal "ABC\nDEF\nGHmIJ\nKLM\n" (m.contents |> String.join "\n")
                                    , \m -> Expect.equal (Buffer.Mark (2, 2) False  |> Just) m.mark
                                    ]

        , test "undo mark from update by delete one (just row, after column, 1line)" <|
              \_ ->
                  Buffer.init "ABC\nDEF\nGHmIJ\nKLM\n"
                      |> Buffer.moveAt (2@ 2)
                      |> Buffer.markSet
                      |> Buffer.markClear 
                      |> Buffer.deleteAt (2@ 5)
                      |> Buffer.undo
                      |> Expect.all [ \m -> Expect.equal "ABC\nDEF\nGHmIJ\nKLM\n" (m.contents |> String.join "\n")
                                    , \m -> Expect.equal (Buffer.Mark (2, 2) False  |> Just) m.mark
                                    ]

        , test "undo mark from update by delete one (after row)" <|
              \_ ->
                  Buffer.init "ABC\nDEF\nGHmIJ\nK\n"
                      |> Buffer.moveAt (2@ 2)
                      |> Buffer.markSet
                      |> Buffer.markClear 
                      |> Buffer.deleteAt (3@ 0)
                      |> Buffer.undo
                      |> .mark
                      |> Expect.equal (Buffer.Mark (2, 2) False |> Just)


        -- update mark from update by delete range

        , test "undo mark from update by delete range (before row, inline)" <|
              \_ ->
                  Buffer.init "ABC\nDEF\nGHmIJ\nKLM\n"
                      |> Buffer.moveAt (2@ 2)
                      |> Buffer.markSet
                      |> Buffer.markClear 
                      |> Buffer.deleteRange (Buffer.makeRange (1, 0) (1, 2))
                      |> Buffer.undo
                      |> Expect.all [ \m -> Expect.equal "ABC\nDEF\nGHmIJ\nKLM\n" (m.contents |> String.join "\n")
                                    , \m -> Expect.equal (Buffer.Mark (2, 2) False  |> Just) m.mark
                                    ]

        , test "undo mark from update by delete range (before row, multiline)" <|
              \_ ->
                  Buffer.init "ABC\nDEF\nGHmIJ\nKLM\n"
                      |> Buffer.moveAt (2@ 2)
                      |> Buffer.markSet
                      |> Buffer.markClear 
                      |> Buffer.deleteRange (Buffer.makeRange (0, 1) (1, 1))
                      |> Buffer.undo
                      |> Expect.all [ \m -> Expect.equal "ABC\nDEF\nGHmIJ\nKLM\n" (m.contents |> String.join "\n")
                                    , \m -> Expect.equal (Buffer.Mark (2, 2) False  |> Just) m.mark
                                    ]

        , test "undo mark from update by delete range (before row, delete -> concat before and markline)" <|
              \_ ->
                  Buffer.init "ABC\nDEF\nGHmIJ\nKLM\n"
                      |> Buffer.moveAt (2@ 2)
                      |> Buffer.markSet
                      |> Buffer.markClear 
                      |> Buffer.deleteRange (Buffer.makeRange (0, 1) (2, 0))
                      |> Buffer.undo
                      |> Expect.all [ \m -> Expect.equal "ABC\nDEF\nGHmIJ\nKLM\n" (m.contents |> String.join "\n")
                                    , \m -> Expect.equal (Buffer.Mark (2, 2) False  |> Just) m.mark
                                    ]

        , test "undo mark from update by delete range (row, multiline, contain mark)" <|
              \_ ->
                  Buffer.init "ABC\nDEF\nGHmIJ\nKLM\n"
                      |> Buffer.moveAt (2@ 2)
                      |> Buffer.markSet
                      |> Buffer.markClear 
                      |> Buffer.deleteRange (Buffer.makeRange (0, 1) (3, 1))
                      |> Buffer.undo
                      |> Expect.all [ \m -> Expect.equal "ABC\nDEF\nGHmIJ\nKLM\n" (m.contents |> String.join "\n")
                                    , \m -> Expect.equal (Buffer.Mark (2, 2) False  |> Just) m.mark
                                    ]

        , test "undo mark from update by delete range (row, multiline, contain mark, double delete <concat history>)" <|
              \_ ->
                  Buffer.init "ABC\nDEF\nGHmIJ\nKLM\n"
                      |> Buffer.moveAt (2@ 2)
                      |> Buffer.markSet
                      |> Buffer.markClear 
                      |> Buffer.deleteRange (Buffer.makeRange (0, 1) (3, 1))
                      |> Buffer.deleteRange (Buffer.makeRange (0, 1) (0, 2))
                      |> Buffer.undo
                      |> Expect.all [ \m -> Expect.equal "ABC\nDEF\nGHmIJ\nKLM\n" (m.contents |> String.join "\n")
                                    , \m -> Expect.equal (Buffer.Mark (2, 2) False  |> Just) m.mark
                                    ]

        , test "undo mark from update by delete range (just row, before column, 1char)" <|
              \_ ->
                  Buffer.init "ABC\nDEF\nGHmIJ\nKLM\n"
                      |> Buffer.moveAt (2@ 2)
                      |> Buffer.markSet
                      |> Buffer.markClear 
                      |> Buffer.deleteRange (Buffer.makeRange (2, 0) (2, 2))
                      |> Buffer.undo
                      |> Expect.all [ \m -> Expect.equal "ABC\nDEF\nGHmIJ\nKLM\n" (m.contents |> String.join "\n")
                                    , \m -> Expect.equal (Buffer.Mark (2, 2) False  |> Just) m.mark
                                    ]

        , test "undo mark from update by delete range (just row, inline, contain mark)" <|
              \_ ->
                  Buffer.init "ABC\nDEF\nGHmIJ\nKLM\n"
                      |> Buffer.moveAt (2@ 2)
                      |> Buffer.markSet
                      |> Buffer.markClear 
                      |> Buffer.deleteRange (Buffer.makeRange (2, 1) (2, 4))
                      |> Buffer.undo
                      |> Expect.all [ \m -> Expect.equal "ABC\nDEF\nGHmIJ\nKLM\n" (m.contents |> String.join "\n")
                                    , \m -> Expect.equal (Buffer.Mark (2, 2) False  |> Just) m.mark
                                    ]

        , test "undo mark from update by delete range (just row, before column, multiline, contain mark)" <|
              \_ ->
                  Buffer.init "ABC\nDEF\nGHmIJ\nKLM\n"
                      |> Buffer.moveAt (2@ 2)
                      |> Buffer.markSet
                      |> Buffer.markClear 
                      |> Buffer.deleteRange (Buffer.makeRange (2, 1) (3, 1))
                      |> Buffer.undo
                      |> Expect.all [ \m -> Expect.equal "ABC\nDEF\nGHmIJ\nKLM\n" (m.contents |> String.join "\n")
                                    , \m -> Expect.equal (Buffer.Mark (2, 2) False  |> Just) m.mark
                                    ]

        , test "undo mark from update by delete range (just row, just column, 1char)" <|
              \_ ->
                  Buffer.init "ABC\nDEF\nGHmIJ\nKLM\n"
                      |> Buffer.moveAt (2@ 2)
                      |> Buffer.markSet
                      |> Buffer.markClear 
                      |> Buffer.deleteRange (Buffer.makeRange (2, 2) (2, 3))
                      |> Buffer.undo
                      |> Expect.all [ \m -> Expect.equal "ABC\nDEF\nGHmIJ\nKLM\n" (m.contents |> String.join "\n")
                                    , \m -> Expect.equal (Buffer.Mark (2, 2) False  |> Just) m.mark
                                    ]

        , test "undo mark from update by delete range (just row, just column, multiline)" <|
              \_ ->
                  Buffer.init "ABC\nDEF\nGHmIJ\nKLM\n"
                      |> Buffer.moveAt (2@ 2)
                      |> Buffer.markSet
                      |> Buffer.markClear 
                      |> Buffer.deleteRange (Buffer.makeRange (2, 2) (3, 1))
                      |> Buffer.undo
                      |> Expect.all [ \m -> Expect.equal "ABC\nDEF\nGHmIJ\nKLM\n" (m.contents |> String.join "\n")
                                    , \m -> Expect.equal (Buffer.Mark (2, 2) False  |> Just) m.mark
                                    ]

        , test "undo mark from update by delete range (just row, after column, inline)" <|
              \_ ->
                  Buffer.init "ABC\nDEF\nGHmIJ\nKLM\n"
                      |> Buffer.moveAt (2@ 2)
                      |> Buffer.markSet
                      |> Buffer.markClear 
                      |> Buffer.deleteRange (Buffer.makeRange (2, 3) (2, 5))
                      |> Buffer.undo
                      |> Expect.all [ \m -> Expect.equal "ABC\nDEF\nGHmIJ\nKLM\n" (m.contents |> String.join "\n")
                                    , \m -> Expect.equal (Buffer.Mark (2, 2) False  |> Just) m.mark
                                    ]

        , test "undo mark from update by delete range (just row, after column, multiline)" <|
              \_ ->
                  Buffer.init "ABC\nDEF\nGHmIJ\nKLM\n"
                      |> Buffer.moveAt (2@ 2)
                      |> Buffer.markSet
                      |> Buffer.markClear 
                      |> Buffer.deleteRange (Buffer.makeRange (2, 3) (3, 1))
                      |> Buffer.undo
                      |> Expect.all [ \m -> Expect.equal "ABC\nDEF\nGHmIJ\nKLM\n" (m.contents |> String.join "\n")
                                    , \m -> Expect.equal (Buffer.Mark (2, 2) False  |> Just) m.mark
                                    ]

        , test "undo mark from update by delete range (after row)" <|
              \_ ->
                  Buffer.init "ABC\nDEF\nGHmIJ\nKLM\n"
                      |> Buffer.moveAt (2@ 2)
                      |> Buffer.markSet
                      |> Buffer.markClear 
                      |> Buffer.deleteRange (Buffer.makeRange (3, 0) (3, 2))
                      |> Buffer.undo
                      |> Expect.all [ \m -> Expect.equal "ABC\nDEF\nGHmIJ\nKLM\n" (m.contents |> String.join "\n")
                                    , \m -> Expect.equal (Buffer.Mark (2, 2) False  |> Just) m.mark
                                    ]


        -- update mark from update by backspace

        , test "undo mark from update by backspace (before row, 1char)" <|
              \_ ->
                  Buffer.init "ABC\nDEF\nGHmIJ\nKLM\n"
                      |> Buffer.moveAt (2@ 2)
                      |> Buffer.markSet
                      |> Buffer.markClear 
                      |> Buffer.backspaceAt (1@ 2)
                      |> Buffer.undo
                      |> .mark
                      |> Expect.equal (Buffer.Mark (2, 2) False |> Just)

        , test "undo mark from update by backspace (before row, 1line)" <|
              \_ ->
                  Buffer.init "ABC\nDEF\nGHmIJ\nKLM\n"
                      |> Buffer.moveAt (2@ 2)
                      |> Buffer.markSet
                      |> Buffer.markClear 
                      |> Buffer.backspaceAt (1@ 0)
                      |> Buffer.undo
                      |> Expect.all [ \m -> Expect.equal "ABC\nDEF\nGHmIJ\nKLM\n" (m.contents |> String.join "\n")
                                    , \m -> Expect.equal (Buffer.Mark (2, 2) False  |> Just) m.mark
                                    ]

        , test "undo mark from update by backspace (before row, concat before and mark line)" <|
              \_ ->
                  Buffer.init "ABC\nDEF\nGHmIJ\nKLM\n"
                      |> Buffer.moveAt (2@ 2)
                      |> Buffer.markSet
                      |> Buffer.markClear 
                      |> Buffer.backspaceAt (2@ 0)
                      |> Buffer.undo
                      |> Expect.all [ \m -> Expect.equal "ABC\nDEF\nGHmIJ\nKLM\n" (m.contents |> String.join "\n")
                                    , \m -> Expect.equal (Buffer.Mark (2, 2) False  |> Just) m.mark
                                    ]

        , test "undo mark from update by backspace (just row, before column, 1char)" <|
              \_ ->
                  Buffer.init "ABC\nDEF\nGHmIJ\nKLM\n"
                      |> Buffer.moveAt (2@ 2)
                      |> Buffer.markSet
                      |> Buffer.markClear 
                      |> Buffer.backspaceAt (2@ 1)
                      |> Buffer.undo
                      |> Expect.all [ \m -> Expect.equal "ABC\nDEF\nGHmIJ\nKLM\n" (m.contents |> String.join "\n")
                                    , \m -> Expect.equal (Buffer.Mark (2, 2) False  |> Just) m.mark
                                    ]

        , test "undo mark from update by backspace (just row, just column, 1char (deleted pre-char))" <|
              \_ ->
                  Buffer.init "ABC\nDEF\nGHmIJ\nKLM\n"
                      |> Buffer.moveAt (2@ 2)
                      |> Buffer.markSet
                      |> Buffer.markClear 
                      |> Buffer.backspaceAt (2@ 2)
                      |> Buffer.undo
                      |> Expect.all [ \m -> Expect.equal "ABC\nDEF\nGHmIJ\nKLM\n" (m.contents |> String.join "\n")
                                    , \m -> Expect.equal (Buffer.Mark (2, 2) False  |> Just) m.mark
                                    ]

        , test "undo mark from update by backspace (just row, after column, (deleted just marked))" <|
              \_ ->
                  Buffer.init "ABC\nDEF\nGHmIJ\nKLM\n"
                      |> Buffer.moveAt (2@ 2)
                      |> Buffer.markSet
                      |> Buffer.markClear 
                      |> Buffer.backspaceAt (2@ 3)
                      |> Buffer.undo
                      |> Expect.all [ \m -> Expect.equal "ABC\nDEF\nGHmIJ\nKLM\n" (m.contents |> String.join "\n")
                                    , \m -> Expect.equal (Buffer.Mark (2, 2) False  |> Just) m.mark
                                    ]

        , test "undo mark from update by backspace (just row, after column, (deleted just marked) , double backspace <concat history>)" <|
              \_ ->
                  Buffer.init "ABC\nDEF\nGHmIJ\nKLM\n"
                      |> Buffer.moveAt (2@ 2)
                      |> Buffer.markSet
                      |> Buffer.markClear 
                      |> Buffer.backspaceAt (2@ 3)
                      |> Buffer.backspaceAt (2@ 2)
                      |> Buffer.undo
                      |> Expect.all [ \m -> Expect.equal "ABC\nDEF\nGHmIJ\nKLM\n" (m.contents |> String.join "\n")
                                    , \m -> Expect.equal (Buffer.Mark (2, 2) False  |> Just) m.mark
                                    ]


        , test "undo mark from update by backspace one (just row, after column, 1car)" <|
              \_ ->
                  Buffer.init "ABC\nDEF\nGHmIJ\nKLM\n"
                      |> Buffer.moveAt (2@ 2)
                      |> Buffer.markSet
                      |> Buffer.markClear 
                      |> Buffer.backspaceAt (2@ 4)
                      |> Buffer.undo
                      |> Expect.all [ \m -> Expect.equal "ABC\nDEF\nGHmIJ\nKLM\n" (m.contents |> String.join "\n")
                                    , \m -> Expect.equal (Buffer.Mark (2, 2) False  |> Just) m.mark
                                    ]

        , test "undo mark from update by backspace (after row, concat mark and after line)" <|
              \_ ->
                  Buffer.init "ABC\nDEF\nGHmIJ\nKLM\n"
                      |> Buffer.moveAt (2@ 2)
                      |> Buffer.markSet
                      |> Buffer.markClear 
                      |> Buffer.backspaceAt (3@ 0)
                      |> Buffer.undo
                      |> Expect.all [ \m -> Expect.equal "ABC\nDEF\nGHmIJ\nKLM\n" (m.contents |> String.join "\n")
                                    , \m -> Expect.equal (Buffer.Mark (2, 2) False  |> Just) m.mark
                                    ]

        , test "undo mark from update by backspace (after row)" <|
              \_ ->
                  Buffer.init "ABC\nDEF\nGHmIJ\nKLM\n"
                      |> Buffer.moveAt (2@ 2)
                      |> Buffer.markSet
                      |> Buffer.markClear 
                      |> Buffer.backspaceAt (3@ 1)
                      |> Buffer.undo
                      |> Expect.all [ \m -> Expect.equal "ABC\nDEF\nGHmIJ\nKLM\n" (m.contents |> String.join "\n")
                                    , \m -> Expect.equal (Buffer.Mark (2, 2) False  |> Just) m.mark
                                    ]
        ]



