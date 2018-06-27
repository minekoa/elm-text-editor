module EditorCommandTest exposing (..)

import Expect exposing (Expectation)
import Test exposing (..)


import TextEditor as Editor
import TextEditor.Core as Core
import TextEditor.Buffer as Buffer

import TextEditor.Commands as EditorCmds


nowCursorPos : Editor.Model -> (Int, Int)
nowCursorPos m =
    let
        cur = m.core.buffer.cursor
    in
        (cur.row, cur.column)

toPos : (Int, Int) -> Buffer.Position
toPos (r, c) =
    Buffer.Position r c


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
                      |> andThen (Editor.execCommand <| (EditorCmds.moveAt << toPos) (1, 0))
                      |> andThen (Editor.execCommand <| EditorCmds.killLine )
                      |> Expect.all [ \(m, c) -> Expect.equal "ABC\n\nHIJK\nLMN\nOPQ\n" (m.core.buffer.contents |> String.join "\n")
                                    , \(m, c) -> Expect.equal (1, 0) (m |> nowCursorPos)
                                    , \(m, c) -> Expect.equal (Just "killLine") (m.core.lastCommand)
                                    , \(m, c) -> Expect.equal ("DEFG") (m.core.copyStore)
                                    ]
        , test "killline (\\n)" <|
              \_ ->
                  Editor.init "id_string" [] "ABC\nDEFG\nHIJK\nLMN\nOPQ\n"
                      |> andThen (Editor.execCommand <| (EditorCmds.moveAt << toPos) (1, 0))
                      |> andThen (Editor.execCommand <| EditorCmds.killLine )
                      |> andThen (Editor.execCommand <| EditorCmds.killLine )
                      |> Expect.all [ \(m, c) -> Expect.equal "ABC\nHIJK\nLMN\nOPQ\n" (m.core.buffer.contents |> String.join "\n")
                                    , \(m, c) -> Expect.equal (1, 0) (m |> nowCursorPos)
                                    , \(m, c) -> Expect.equal (Just "killLine") (m.core.lastCommand)
                                    , \(m, c) -> Expect.equal ("DEFG\n") (m.core.copyStore)
                                    ]
        , test "killline (line middle)" <|
              \_ ->
                  Editor.init "id_string" [] "ABC\nDEFG\nHIJK\nLMN\nOPQ\n"
                      |> andThen (Editor.execCommand <| (EditorCmds.moveAt << toPos) (1, 1))
                      |> andThen (Editor.execCommand <| EditorCmds.killLine )
                      |> Expect.all [ \(m, c) -> Expect.equal "ABC\nD\nHIJK\nLMN\nOPQ\n" (m.core.buffer.contents |> String.join "\n")
                                    , \(m, c) -> Expect.equal (1, 1) (m |> nowCursorPos)
                                    , \(m, c) -> Expect.equal (Just "killLine") (m.core.lastCommand)
                                    , \(m, c) -> Expect.equal ("EFG") (m.core.copyStore)
                                    ]
        , test "killline (EOF - 1)" <|
              \_ ->
                  Editor.init "id_string" [] "ABC\nDEFG\nHIJK\nLMN\nOPQ\n"
                      |> andThen (Editor.execCommand <| (EditorCmds.moveAt << toPos) (4, 3))
                      |> andThen (Editor.execCommand <| EditorCmds.killLine )
                      |> Expect.all [ \(m, c) -> Expect.equal "ABC\nDEFG\nHIJK\nLMN\nOPQ" (m.core.buffer.contents |> String.join "\n")
                                    , \(m, c) -> Expect.equal (4, 3) (m |> nowCursorPos)
                                    , \(m, c) -> Expect.equal (Just "killLine") (m.core.lastCommand)
                                    , \(m, c) -> Expect.equal ("\n") (m.core.copyStore)
                                    ]
        , test "killline (EOF)" <|
              \_ ->
                  Editor.init "id_string" [] "ABC\nDEFG\nHIJK\nLMN\nOPQ\n"
                      |> andThen (Editor.execCommand <| (EditorCmds.moveAt << toPos) (5, 0))
                      |> andThen (Editor.execCommand <| EditorCmds.killLine )
                      |> Expect.all [ \(m, c) -> Expect.equal "ABC\nDEFG\nHIJK\nLMN\nOPQ\n" (m.core.buffer.contents |> String.join "\n")
                                    , \(m, c) -> Expect.equal (5, 0) (m |> nowCursorPos)
                                    , \(m, c) -> Expect.equal (Just "killLine") (m.core.lastCommand)
                                    , \(m, c) -> Expect.equal ("") (m.core.copyStore)
                                    ]
        , test "killline (clipboard (clear -> set \"JK\" -> set(append \"\\n\"))" <|
              \_ ->
                  Editor.init "id_string" [] "ABC\nDEFG\nHIJK\nLMN\nOPQ\n"
                      |> andThen (Editor.execCommand <| (EditorCmds.moveAt << toPos) (2, 1))
                      |> andThen (Editor.execCommand <| EditorCmds.selectForward)
                      |> andThen (Editor.execCommand <| EditorCmds.copy)
                      |> andThen (Editor.execCommand <| EditorCmds.killLine )
                      |> andThen (Editor.execCommand <| EditorCmds.killLine )
                      |> Expect.all [ \(m, c) -> Expect.equal "ABC\nDEFG\nHILMN\nOPQ\n" (m.core.buffer.contents |> String.join "\n")
                                    , \(m, c) -> Expect.equal (2, 2) (m |> nowCursorPos)
                                    , \(m, c) -> Expect.equal (Just "killLine") (m.core.lastCommand)
                                    , \(m, c) -> Expect.equal ("JK\n") (m.core.copyStore)
                                    ]

        -- indent
        , test "indent (BOF)" <|
              \_ ->
                  Editor.init "id_string" [] "ABC\nDEFG\nHIJK\nLMN\nOPQ\n"
                      |> andThen (Editor.execCommand <| EditorCmds.indent)
                      |> Expect.all [ \(m, c) -> Expect.equal "    ABC\nDEFG\nHIJK\nLMN\nOPQ\n" (m.core.buffer.contents |> String.join "\n")
                                    , \(m, c) -> Expect.equal (0, 4) (m |> nowCursorPos)
                                    , \(m, c) -> Expect.equal (Just "indent") (m.core.lastCommand)
                                    ]
        , test "indent-indent (BOF)" <|
              \_ ->
                  Editor.init "id_string" [] "ABC\nDEFG\nHIJK\nLMN\nOPQ\n"
                      |> andThen (Editor.execCommand <| EditorCmds.indent)
                      |> andThen (Editor.execCommand <| EditorCmds.indent)
                      |> Expect.all [ \(m, c) -> Expect.equal "ABC\nDEFG\nHIJK\nLMN\nOPQ\n" (m.core.buffer.contents |> String.join "\n")
                                    , \(m, c) -> Expect.equal (0, 0) (m |> nowCursorPos)
                                    , \(m, c) -> Expect.equal (Just "indent") (m.core.lastCommand)
                                    ]
        , test "indent-indent-indent (BOF)" <|
              \_ ->
                  Editor.init "id_string" [] "ABC\nDEFG\nHIJK\nLMN\nOPQ\n"
                      |> andThen (Editor.execCommand <| EditorCmds.indent)
                      |> andThen (Editor.execCommand <| EditorCmds.indent)
                      |> andThen (Editor.execCommand <| EditorCmds.indent)
                      |> Expect.all [ \(m, c) -> Expect.equal "    ABC\nDEFG\nHIJK\nLMN\nOPQ\n" (m.core.buffer.contents |> String.join "\n")
                                    , \(m, c) -> Expect.equal (0, 4) (m |> nowCursorPos)
                                    , \(m, c) -> Expect.equal (Just "indent") (m.core.lastCommand)
                                    ]
        , test "indent (indented prev-line)" <|
              \_ ->
                  Editor.init "id_string" [] "    ABC\nDEFG\nHIJK\nLMN\nOPQ\n"
                      |> andThen (Editor.execCommand <| EditorCmds.moveNextLine)
                      |> andThen (Editor.execCommand <| EditorCmds.indent)
                      |> Expect.all [ \(m, c) -> Expect.equal "    ABC\n    DEFG\nHIJK\nLMN\nOPQ\n" (m.core.buffer.contents |> String.join "\n")
                                    , \(m, c) -> Expect.equal (1, 4) (m |> nowCursorPos)
                                    , \(m, c) -> Expect.equal (Just "indent") (m.core.lastCommand)
                                    ]
        , test "indent-indent (indented prev-line)" <|
              \_ ->
                  Editor.init "id_string" [] "    ABC\nDEFG\nHIJK\nLMN\nOPQ\n"
                      |> andThen (Editor.execCommand <| EditorCmds.moveNextLine)
                      |> andThen (Editor.execCommand <| EditorCmds.indent)
                      |> andThen (Editor.execCommand <| EditorCmds.indent)
                      |> Expect.all [ \(m, c) -> Expect.equal "    ABC\n        DEFG\nHIJK\nLMN\nOPQ\n" (m.core.buffer.contents |> String.join "\n")
                                    , \(m, c) -> Expect.equal (1, 8) (m |> nowCursorPos)
                                    , \(m, c) -> Expect.equal (Just "indent") (m.core.lastCommand)
                                    ]
        , test "indent-indent-indent (indented prev-line)" <|
              \_ ->
                  Editor.init "id_string" [] "    ABC\nDEFG\nHIJK\nLMN\nOPQ\n"
                      |> andThen (Editor.execCommand <| EditorCmds.moveNextLine)
                      |> andThen (Editor.execCommand <| EditorCmds.indent)
                      |> andThen (Editor.execCommand <| EditorCmds.indent)
                      |> andThen (Editor.execCommand <| EditorCmds.indent)
                      |> Expect.all [ \(m, c) -> Expect.equal "    ABC\n    DEFG\nHIJK\nLMN\nOPQ\n" (m.core.buffer.contents |> String.join "\n")
                                    , \(m, c) -> Expect.equal (1, 4) (m |> nowCursorPos)
                                    , \(m, c) -> Expect.equal (Just "indent") (m.core.lastCommand)
                                    ]
        , test "indent (indented prev-line, cursor is not line head)" <|
              \_ ->
                  Editor.init "id_string" [] "    ABC\nDEFG\nHIJK\nLMN\nOPQ\n"
                      |> andThen (Editor.execCommand <| EditorCmds.moveNextLine)
                      |> andThen (Editor.execCommand <| EditorCmds.moveForward)
                      |> andThen (Editor.execCommand <| EditorCmds.indent)
                      |> Expect.all [ \(m, c) -> Expect.equal "    ABC\n    DEFG\nHIJK\nLMN\nOPQ\n" (m.core.buffer.contents |> String.join "\n")
                                    , \(m, c) -> Expect.equal (1, 5) (m |> nowCursorPos)
                                    , \(m, c) -> Expect.equal (Just "indent") (m.core.lastCommand)
                                    ]
        , test "indent-indent (indented prev-line, cursor is not line head)" <|
              \_ ->
                  Editor.init "id_string" [] "    ABC\nDEFG\nHIJK\nLMN\nOPQ\n"
                      |> andThen (Editor.execCommand <| EditorCmds.moveNextLine)
                      |> andThen (Editor.execCommand <| EditorCmds.moveForward)
                      |> andThen (Editor.execCommand <| EditorCmds.indent)
                      |> andThen (Editor.execCommand <| EditorCmds.indent)
                      |> Expect.all [ \(m, c) -> Expect.equal "    ABC\n        DEFG\nHIJK\nLMN\nOPQ\n" (m.core.buffer.contents |> String.join "\n")
                                    , \(m, c) -> Expect.equal (1, 9) (m |> nowCursorPos)
                                    , \(m, c) -> Expect.equal (Just "indent") (m.core.lastCommand)
                                    ]
        , test "indent (myline is indenting than prev-line)" <|
              \_ ->
                  Editor.init "id_string" [] "    ABC\n            DEFG\nHIJK\nLMN\nOPQ\n"
                      |> andThen (Editor.execCommand <| EditorCmds.moveNextLine)
                      |> andThen (Editor.execCommand <| EditorCmds.indent)
                      |> Expect.all [ \(m, c) -> Expect.equal "    ABC\n    DEFG\nHIJK\nLMN\nOPQ\n" (m.core.buffer.contents |> String.join "\n")
                                    , \(m, c) -> Expect.equal (1, 0) (m |> nowCursorPos)
                                    , \(m, c) -> Expect.equal (Just "indent") (m.core.lastCommand)
                                    ]
        , test "indent-indent (myline is indenting than prev-line)" <|
              \_ ->
                  Editor.init "id_string" [] "    ABC\n            DEFG\nHIJK\nLMN\nOPQ\n"
                      |> andThen (Editor.execCommand <| EditorCmds.moveNextLine)
                      |> andThen (Editor.execCommand <| EditorCmds.indent)
                      |> andThen (Editor.execCommand <| EditorCmds.indent)
                      |> Expect.all [ \(m, c) -> Expect.equal "    ABC\n        DEFG\nHIJK\nLMN\nOPQ\n" (m.core.buffer.contents |> String.join "\n")
                                    , \(m, c) -> Expect.equal (1, 4) (m |> nowCursorPos)
                                    , \(m, c) -> Expect.equal (Just "indent") (m.core.lastCommand)
                                    ]
        , test "indent (myline is indenting than prev-line, col (1, 13) )" <|
              \_ ->
                  Editor.init "id_string" [] "    ABC\n            DEFG\nHIJK\nLMN\nOPQ\n"
                      |> andThen (Editor.execCommand <| EditorCmds.moveNextLine)
                      |> andThen (Editor.execCommand <| EditorCmds.moveForward) -- 1 ' '
                      |> andThen (Editor.execCommand <| EditorCmds.moveForward) -- 2 ' '
                      |> andThen (Editor.execCommand <| EditorCmds.moveForward) -- 3 ' '
                      |> andThen (Editor.execCommand <| EditorCmds.moveForward) -- 4 ' '
                      |> andThen (Editor.execCommand <| EditorCmds.moveForward) -- 5 ' '
                      |> andThen (Editor.execCommand <| EditorCmds.moveForward) -- 6 ' '
                      |> andThen (Editor.execCommand <| EditorCmds.moveForward) -- 7 ' '
                      |> andThen (Editor.execCommand <| EditorCmds.moveForward) -- 8 ' '
                      |> andThen (Editor.execCommand <| EditorCmds.moveForward) -- 9 ' '
                      |> andThen (Editor.execCommand <| EditorCmds.moveForward) -- 10 ' '
                      |> andThen (Editor.execCommand <| EditorCmds.moveForward) -- 11 ' '
                      |> andThen (Editor.execCommand <| EditorCmds.moveForward) -- 12 'D'
                      |> andThen (Editor.execCommand <| EditorCmds.moveForward) -- 13 'E"
                      |> andThen (Editor.execCommand <| EditorCmds.indent)
                      |> Expect.all [ \(m, c) -> Expect.equal "    ABC\n    DEFG\nHIJK\nLMN\nOPQ\n" (m.core.buffer.contents |> String.join "\n")
                                    , \(m, c) -> Expect.equal (1, 5) (m |> nowCursorPos)
                                    , \(m, c) -> Expect.equal (Just "indent") (m.core.lastCommand)
                                    ]
        , test "indent-indent (myline is indenting than prev-line, col (1, 13) )" <|
              \_ ->
                  Editor.init "id_string" [] "    ABC\n            DEFG\nHIJK\nLMN\nOPQ\n"
                      |> andThen (Editor.execCommand <| EditorCmds.moveNextLine)
                      |> andThen (Editor.execCommand <| EditorCmds.moveForward) -- 1 ' '
                      |> andThen (Editor.execCommand <| EditorCmds.moveForward) -- 2 ' '
                      |> andThen (Editor.execCommand <| EditorCmds.moveForward) -- 3 ' '
                      |> andThen (Editor.execCommand <| EditorCmds.moveForward) -- 4 ' '
                      |> andThen (Editor.execCommand <| EditorCmds.moveForward) -- 5 ' '
                      |> andThen (Editor.execCommand <| EditorCmds.moveForward) -- 6 ' '
                      |> andThen (Editor.execCommand <| EditorCmds.moveForward) -- 7 ' '
                      |> andThen (Editor.execCommand <| EditorCmds.moveForward) -- 8 ' '
                      |> andThen (Editor.execCommand <| EditorCmds.moveForward) -- 9 ' '
                      |> andThen (Editor.execCommand <| EditorCmds.moveForward) -- 10 ' '
                      |> andThen (Editor.execCommand <| EditorCmds.moveForward) -- 11 ' '
                      |> andThen (Editor.execCommand <| EditorCmds.moveForward) -- 12 'D'
                      |> andThen (Editor.execCommand <| EditorCmds.moveForward) -- 13 'E"
                      |> andThen (Editor.execCommand <| EditorCmds.indent)
                      |> andThen (Editor.execCommand <| EditorCmds.indent)
                      |> Expect.all [ \(m, c) -> Expect.equal "    ABC\n        DEFG\nHIJK\nLMN\nOPQ\n" (m.core.buffer.contents |> String.join "\n")
                                    , \(m, c) -> Expect.equal (1, 9) (m |> nowCursorPos)
                                    , \(m, c) -> Expect.equal (Just "indent") (m.core.lastCommand)
                                    ]
        ]
