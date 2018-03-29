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
                      |> Buffer.insert (0, 0) "a"
                      |> (.history)
                      |> Expect.equal [Buffer.Cmd_Insert (0, 0) "a"]
        ,  test "backspace one" <|
              \_ ->
                  Buffer.init "abc"
                      |> Buffer.backspace (0, 1)
                      |> (.history)
                      |> Expect.equal [Buffer.Cmd_Backspace (0, 1) "a"]
        ,  test "delete one" <|
              \_ ->
                  Buffer.init "abc"
                      |> Buffer.delete (0, 1)
                      |> (.history)
                      |> Expect.equal [Buffer.Cmd_Delete (0, 1) "b"]
        , test "concat insert" <|
              \_ ->
                  Buffer.init ""
                      |> Buffer.insert (0, 0) "a"
                      |> Buffer.insert (0, 1) "b"
                      |> Buffer.insert (0, 2) "c"
                      |> (.history)
                      |> Expect.equal [Buffer.Cmd_Insert (0, 0) "abc"]

        , test "undo insert one" <|
              \_ ->
                  Buffer.init ""
                      |> Buffer.insert (0, 0) "a"
                      |> Buffer.undo
                      |> Expect.all
                              [ (\m -> Expect.equal [] m.history)
                              , (\m -> Expect.equal [""] m.contents)
                              ]
        ,  test "undo backspace one" <|
              \_ ->
                  Buffer.init "abc"
                      |> Buffer.backspace (0, 1)
                      |> Buffer.undo
                      |> Expect.all
                              [ (\m -> Expect.equal [] m.history)
                              , (\m -> Expect.equal ["abc"] m.contents)
                              ]
        ,  test "undo delete one" <|
              \_ ->
                  Buffer.init "abc"
                      |> Buffer.delete (0, 1)
                      |> Buffer.undo
                      |> Expect.all
                              [ (\m -> Expect.equal [] m.history)
                              , (\m -> Expect.equal ["abc"] m.contents)
                              ]
        ]

