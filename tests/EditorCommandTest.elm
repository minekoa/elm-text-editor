module EditorCommandTest exposing (..)

import Expect exposing (Expectation)
import Test exposing (..)


import TextEditor as Editor
import TextEditor.Core as Core
import TextEditor.Buffer as Buffer

import TextEditor.Commands as EditorCmds


andThen : (Editor.Model -> (Editor.Model, Cmd Editor.Msg)) -> (Editor.Model, Cmd Editor.Msg) -> (Editor.Model, Cmd Editor.Msg)
andThen f (m1, c1) =
    let
        (m2, c2) = f m1
    in
        (m2
        , Cmd.batch [c1, c2]
        )


suite : Test
suite =
    describe "EditorCommands"
        [ test "killline (line-top)" <|
              \_ ->
                  Editor.init "id_string" [] "ABC\nDEFG\nHIJK\nLMN\nOPQ\n"
                      |> andThen (Editor.execCommand <| EditorCmds.moveAt (1, 0))
                      |> andThen (Editor.execCommand <| EditorCmds.killLine )
                      |> Expect.all [ \(m, c) -> Expect.equal "ABC\n\nHIJK\nLMN\nOPQ\n" (m.core.buffer.contents |> String.join "\n")
                                    , \(m, c) -> Expect.equal (1, 0) (m.core.buffer |> Buffer.nowCursorPos)
                                    , \(m, c) -> Expect.equal (Just "killLine") (m.core.lastCommand)
                                    , \(m, c) -> Expect.equal ("DEFG") (m.core.copyStore)
                                    ]
        , test "killline (\\n)" <|
              \_ ->
                  Editor.init "id_string" [] "ABC\nDEFG\nHIJK\nLMN\nOPQ\n"
                      |> andThen (Editor.execCommand <| EditorCmds.moveAt (1, 0))
                      |> andThen (Editor.execCommand <| EditorCmds.killLine )
                      |> andThen (Editor.execCommand <| EditorCmds.killLine )
                      |> Expect.all [ \(m, c) -> Expect.equal "ABC\nHIJK\nLMN\nOPQ\n" (m.core.buffer.contents |> String.join "\n")
                                    , \(m, c) -> Expect.equal (1, 0) (m.core.buffer |> Buffer.nowCursorPos)
                                    , \(m, c) -> Expect.equal (Just "killLine") (m.core.lastCommand)
                                    , \(m, c) -> Expect.equal ("DEFG\n") (m.core.copyStore)
                                    ]
        , test "killline (line middle)" <|
              \_ ->
                  Editor.init "id_string" [] "ABC\nDEFG\nHIJK\nLMN\nOPQ\n"
                      |> andThen (Editor.execCommand <| EditorCmds.moveAt (1, 1))
                      |> andThen (Editor.execCommand <| EditorCmds.killLine )
                      |> Expect.all [ \(m, c) -> Expect.equal "ABC\nD\nHIJK\nLMN\nOPQ\n" (m.core.buffer.contents |> String.join "\n")
                                    , \(m, c) -> Expect.equal (1, 1) (m.core.buffer |> Buffer.nowCursorPos)
                                    , \(m, c) -> Expect.equal (Just "killLine") (m.core.lastCommand)
                                    , \(m, c) -> Expect.equal ("EFG") (m.core.copyStore)
                                    ]
        , test "killline (EOF - 1)" <|
              \_ ->
                  Editor.init "id_string" [] "ABC\nDEFG\nHIJK\nLMN\nOPQ\n"
                      |> andThen (Editor.execCommand <| EditorCmds.moveAt (4, 3))
                      |> andThen (Editor.execCommand <| EditorCmds.killLine )
                      |> Expect.all [ \(m, c) -> Expect.equal "ABC\nDEFG\nHIJK\nLMN\nOPQ" (m.core.buffer.contents |> String.join "\n")
                                    , \(m, c) -> Expect.equal (4, 3) (m.core.buffer |> Buffer.nowCursorPos)
                                    , \(m, c) -> Expect.equal (Just "killLine") (m.core.lastCommand)
                                    , \(m, c) -> Expect.equal ("\n") (m.core.copyStore)
                                    ]
        , test "killline (EOF)" <|
              \_ ->
                  Editor.init "id_string" [] "ABC\nDEFG\nHIJK\nLMN\nOPQ\n"
                      |> andThen (Editor.execCommand <| EditorCmds.moveAt (5, 0))
                      |> andThen (Editor.execCommand <| EditorCmds.killLine )
                      |> Expect.all [ \(m, c) -> Expect.equal "ABC\nDEFG\nHIJK\nLMN\nOPQ\n" (m.core.buffer.contents |> String.join "\n")
                                    , \(m, c) -> Expect.equal (5, 0) (m.core.buffer |> Buffer.nowCursorPos)
                                    , \(m, c) -> Expect.equal (Just "killLine") (m.core.lastCommand)
                                    , \(m, c) -> Expect.equal ("") (m.core.copyStore)
                                    ]
        , test "killline (clipboard (clear -> set \"JK\" -> set(append \"\\n\"))" <|
              \_ ->
                  Editor.init "id_string" [] "ABC\nDEFG\nHIJK\nLMN\nOPQ\n"
                      |> andThen (Editor.execCommand <| EditorCmds.moveAt (2, 1))
                      |> andThen (Editor.execCommand <| EditorCmds.selectForward)
                      |> andThen (Editor.execCommand <| EditorCmds.copy)
                      |> andThen (Editor.execCommand <| EditorCmds.killLine )
                      |> andThen (Editor.execCommand <| EditorCmds.killLine )
                      |> Expect.all [ \(m, c) -> Expect.equal "ABC\nDEFG\nHILMN\nOPQ\n" (m.core.buffer.contents |> String.join "\n")
                                    , \(m, c) -> Expect.equal (2, 2) (m.core.buffer |> Buffer.nowCursorPos)
                                    , \(m, c) -> Expect.equal (Just "killLine") (m.core.lastCommand)
                                    , \(m, c) -> Expect.equal ("JK\n") (m.core.copyStore)
                                    ]
        ]
