module BufferHistoryTest exposing (..)

import Expect exposing (Expectation)
import Test exposing (..)


import TextEditor.Buffer as Buffer

suite : Test
suite =
    describe "History(undo/redo)"
        [ test "insert one" <|
              \_ ->
                  Buffer.init ""
                      |> Buffer.insertAt (0, 0) "a"
                      |> (.history)
                      |> Expect.equal [Buffer.Cmd_Insert (0, 0) (0, 1) "a"]
        ,  test "backspace one" <|
              \_ ->
                  Buffer.init "abc"
                      |> Buffer.backspaceAt (0, 1)
                      |> (.history)
                      |> Expect.equal [Buffer.Cmd_Backspace (0, 1) (0, 0) "a"]
        ,  test "delete one" <|
              \_ ->
                  Buffer.init "abc"
                      |> Buffer.deleteAt (0, 1)
                      |> (.history)
                      |> Expect.equal [Buffer.Cmd_Delete (0, 1) (0, 1) "b"]

        , test "concat insert" <|
              \_ ->
                  Buffer.init ""
                      |> Buffer.insertAt (0, 0) "a"
                      |> Buffer.insertAt (0, 1) "b"
                      |> Buffer.insertAt (0, 2) "c"
                      |> (.history)
                      |> Expect.equal [Buffer.Cmd_Insert (0, 0) (0, 3) "abc"]

        , test "concat backspace" <|
              \_ ->
                  Buffer.init "abcdef"
                      |> Buffer.backspaceAt (0, 3)
                      |> Buffer.backspaceAt (0, 2)
                      |> Buffer.backspaceAt (0, 1)
                      |> (.history)
                      |> Expect.equal [Buffer.Cmd_Backspace (0, 3) (0, 0) "abc"]

        , test "concat delete" <|
              \_ ->
                  Buffer.init "abcdef"
                      |> Buffer.deleteAt (0, 1)
                      |> Buffer.deleteAt (0, 1)
                      |> Buffer.deleteAt (0, 1)
                      |> (.history)
                      |> Expect.equal [Buffer.Cmd_Delete (0, 1) (0, 1) "bcd"]

        , test "delete range" <|
              \_ ->
                  Buffer.init "EEEEEXFFFF\nFFFFFYEEEE"
                      |> Buffer.deleteRange { begin=(0, 6), end=(1,5) }
                      |> (.history)
                      |> Expect.equal [Buffer.Cmd_Delete (0, 6) (0, 6) "FFFF\nFFFFF"]

        , test "insert LF" <|
              \_ ->
                  Buffer.init "abc\ndef"
                      |> Buffer.insertAt (0, 1) "\n"
                      |> Expect.all
                              [ (\m -> Expect.equal [Buffer.Cmd_Insert (0, 1) (1, 0) "\n"] m.history)
                              , (\m -> Expect.equal ["a", "bc","def"] m.contents)
                              , (\m -> Expect.equal (Buffer.Cursor 1 0) m.cursor)
                              ]

        , test "backspace LF" <|
              \_ ->
                  Buffer.init "abc\ndef"
                      |> Buffer.backspaceAt (1, 0)
                      |> Expect.all
                              [ (\m -> Expect.equal [Buffer.Cmd_Backspace (1, 0) (0, 3) "\n"] m.history)
                              , (\m -> Expect.equal ["abcdef"] m.contents)
                              , (\m -> Expect.equal (Buffer.Cursor 0 3) m.cursor)
                              ]

        , test "delete LF" <|
              \_ ->
                  Buffer.init "abc\ndef"
                      |> Buffer.deleteAt (0, 3)
                      |> Expect.all
                              [ (\m -> Expect.equal [Buffer.Cmd_Delete (0, 3) (0, 3) "\n"] m.history)
                              , (\m -> Expect.equal ["abcdef"] m.contents)
                              , (\m -> Expect.equal (Buffer.Cursor 0 3) m.cursor)
                              ]


        , test "undo insert one" <|
              \_ ->
                  Buffer.init ""
                      |> Buffer.insertAt (0, 0) "a"
                      |> Buffer.undo
                      |> Expect.all
                              [ (\m -> Expect.equal [] m.history)
                              , (\m -> Expect.equal [""] m.contents)
                              , (\m -> Expect.equal (Buffer.Cursor 0 0) m.cursor)
                              ]

        ,  test "undo backspace one" <|
              \_ ->
                  Buffer.init "abc"
                      |> Buffer.backspaceAt (0, 1)
                      |> Buffer.undo
                      |> Expect.all
                              [ (\m -> Expect.equal [] m.history)
                              , (\m -> Expect.equal ["abc"] m.contents)
                              , (\m -> Expect.equal (Buffer.Cursor 0 1) m.cursor)
                              ]
        ,  test "undo delete one" <|
              \_ ->
                  Buffer.init "abc"
                      |> Buffer.deleteAt (0, 1)
                      |> Buffer.undo
                      |> Expect.all
                              [ (\m -> Expect.equal [] m.history)
                              , (\m -> Expect.equal ["abc"] m.contents)
                              , (\m -> Expect.equal (Buffer.Cursor 0 1) m.cursor)
                              ]

        , test "undo insert LF" <|
              \_ ->
                  Buffer.init "abc\ndef"
                      |> Buffer.insertAt (0, 1) "\n"
                      |> Buffer.undo
                      |> Expect.all
                              [ (\m -> Expect.equal [] m.history)
                              , (\m -> Expect.equal ["abc","def"] m.contents)
                              , (\m -> Expect.equal (Buffer.Cursor 0 1) m.cursor)
                              ]

        , test "undo backspace LF" <|
              \_ ->
                  Buffer.init "abc\ndef"
                      |> Buffer.backspaceAt (1, 0)
                      |> Buffer.undo
                      |> Expect.all
                              [ (\m -> Expect.equal [] m.history)
                              , (\m -> Expect.equal ["abc","def"] m.contents)
                              , (\m -> Expect.equal (Buffer.Cursor 1 0) m.cursor)
                              ]

        , test "undo delete LF" <|
              \_ ->
                  Buffer.init "abc\ndef"
                      |> Buffer.deleteAt (0, 3)
                      |> Buffer.undo
                      |> Expect.all
                              [ (\m -> Expect.equal [] m.history)
                              , (\m -> Expect.equal ["abc","def"] m.contents)
                              , (\m -> Expect.equal (Buffer.Cursor 0 3) m.cursor)
                              ]


        , test "undo concat insert" <|
              \_ ->
                  Buffer.init ""
                      |> Buffer.insertAt (0, 0) "a"
                      |> Buffer.insertAt (0, 1) "b"
                      |> Buffer.insertAt (0, 2) "c"
                      |> Buffer.undo
                      |> Expect.all
                              [ (\m -> Expect.equal [] m.history)
                              , (\m -> Expect.equal [""] m.contents)
                              , (\m -> Expect.equal (Buffer.Cursor 0 0) m.cursor)
                              ]

        , test "undo concat backspace" <|
              \_ ->
                  Buffer.init "abcdef"
                      |> Buffer.backspaceAt (0, 3)
                      |> Buffer.backspaceAt (0, 2)
                      |> Buffer.backspaceAt (0, 1)
                      |> Buffer.undo
                      |> Expect.all
                              [ (\m -> Expect.equal [] m.history)
                              , (\m -> Expect.equal ["abcdef"] m.contents)
                              , (\m -> Expect.equal (Buffer.Cursor 0 3) m.cursor)
                              ]

        , test "undo concat delete" <|
              \_ ->
                  Buffer.init "abcdef"
                      |> Buffer.deleteAt (0, 1)
                      |> Buffer.deleteAt (0, 1)
                      |> Buffer.deleteAt (0, 1)
                      |> Buffer.undo
                      |> Expect.all
                              [ (\m -> Expect.equal [] m.history)
                              , (\m -> Expect.equal ["abcdef"] m.contents)
                              , (\m -> Expect.equal (Buffer.Cursor 0 1) m.cursor)
                              ]
        , test "undo delete range" <|
              \_ ->
                  Buffer.init "EEEEEXFFFF\nFFFFFYEEEE"
                      |> Buffer.deleteRange { begin=(0, 6), end=(1,5) }
                      |> Buffer.undo
                      |> Expect.all
                              [ (\m -> Expect.equal [] m.history)
                              , (\m -> Expect.equal ["EEEEEXFFFF", "FFFFFYEEEE"] m.contents)
                              , (\m -> Expect.equal (Buffer.Cursor 0 6) m.cursor)
                              ]
        ]

