module StringExtraTest exposing (..)

import Expect exposing (Expectation)
import Test exposing (..)

import TextEditor.StringExtra as StringExtra

suite : Test
suite =
    describe "StringExtra"
        [ test "nextwordpos, \"This| is| a| pen.\", 0" <|
              \_ ->
                  "This is a pen."
                      |> \s -> StringExtra.nextWordPos s 0
                      |> Expect.equal (Just 4)
        , test "nextwordpos, \"This| is| a| pen.\", 2" <|
              \_ ->
                  "This is a pen."
                      |> \s -> StringExtra.nextWordPos s 2
                      |> Expect.equal (Just 4)
        , test "nextwordpos, \"This| is| a| pen.\", 4" <|
              \_ ->
                  "This is a pen."
                      |> \s -> StringExtra.nextWordPos s 4
                      |> Expect.equal (Just 7)
        , test "nextwordpos, \"This| is| a| pen.\", 5" <|
              \_ ->
                  "This is a pen."
                      |> \s -> StringExtra.nextWordPos s 5
                      |> Expect.equal (Just 7)
        , test "nextwordpos, \"This| is| a| pen.\", 8" <|
              \_ ->
                  "This is a pen."
                      |> \s -> StringExtra.nextWordPos s 8
                      |> Expect.equal (Just 9)
        , test "nextwordpos, \"This| is| a| pen.\", 10" <|
              \_ ->
                  "This is a pen."
                      |> \s -> StringExtra.nextWordPos s 10
                      |> Expect.equal (Just 13)
        , test "nextwordpos, \"This| is| a| pen.\", 13" <|
              \_ ->
                  "This is a pen."
                      |> \s -> StringExtra.nextWordPos s 13
                      |> Expect.equal (Just 14)
        , test "nextwordpos, \"This| is| a| pen.\", 14" <|
              \_ ->
                  "This is a pen."
                      |> \s -> StringExtra.nextWordPos s 14
                      |> Expect.equal Nothing
        , test "nextwordpos, \"This| is| a| pen\", 10" <|
              \_ ->
                  "This is a pen"
                      |> \s -> StringExtra.nextWordPos s 10
                      |> Expect.equal (Just 13)
        , test "nextwordpos, \"This| is| a| pen\", 13" <|
              \_ ->
                  "This is a pen"
                      |> \s -> StringExtra.nextWordPos s 13
                      |> Expect.equal Nothing
        , test "nextwordpos, \"apple|\\tpen\", 10" <|
              \_ ->
                  "apple\tpen"
                      |> \s -> StringExtra.nextWordPos s 10
                      |> Expect.equal Nothing
        , test "nextwordpos, \"あいうえお|　かきくけこ\", 0" <|
              \_ ->
                  "あいうえお　かきくけこ"
                      |> \s -> StringExtra.nextWordPos s 0
                      |> Expect.equal (Just 5)
        , test "nextwordpos, \"あいうえお|　かきくけこ\", 5" <|
              \_ ->
                  "あいうえお　かきくけこ"
                      |> \s -> StringExtra.nextWordPos s 5
                      |> Expect.equal (Just 11)
        , test "nextwordpos, \"あいうえお|　かきくけこ\", 11" <|
              \_ ->
                  "あいうえお　かきくけこ"
                      |> \s -> StringExtra.nextWordPos s 11
                      |> Expect.equal Nothing
        , test "nextwordpos, \"AT|フィールド\", 0" <|
              \_ ->
                  "ATフィールド"
                      |> \s -> StringExtra.nextWordPos s 0
                      |> Expect.equal (Just 2)
        , test "nextwordpos, \"機動戦士|ガンダム\", 0" <|
              \_ ->
                  "機動戦士ガンダム"
                      |> \s -> StringExtra.nextWordPos s 0
                      |> Expect.equal (Just 4)
        , test "nextwordpos, \"ダンジョン|飯\", 0" <|
              \_ ->
                  "ダンジョン飯"
                      |> \s -> StringExtra.nextWordPos s 0
                      |> Expect.equal (Just 5)
        , test "nextwordpos, \"認知する|形\", 0" <|
              \_ ->
                  "認知する形"
                      |> \s -> StringExtra.nextWordPos s 0
                      |> Expect.equal (Just 4)
        , test "nextwordpos, \"認知する|形\", 2" <|
              \_ ->
                  "認知する形"
                      |> \s -> StringExtra.nextWordPos s 2
                      |> Expect.equal (Just 4)
        , test "nextwordpos, \"正解する|カド\", 0" <|
              \_ ->
                  "正解するカド"
                      |> \s -> StringExtra.nextWordPos s 0
                      |> Expect.equal (Just 4)
        , test "nextwordpos, \"正解する|カド\", 2" <|
              \_ ->
                  "正解するカド"
                      |> \s -> StringExtra.nextWordPos s 2
                      |> Expect.equal (Just 4)
        , test "nextwordpos, \"認知|スベシ|形\", 2" <|
              \_ ->
                  "認知スベシ形"
                      |> \s -> StringExtra.nextWordPos s 2
                      |> Expect.equal (Just 5)
        , test "nextwordpos, \"宇宙よりも|遠い|場所\", 0" <|
              \_ ->
                  "宇宙よりも遠い場所"
                      |> \s -> StringExtra.nextWordPos s 0
                      |> Expect.equal (Just 5)
        , test "nextwordpos, \"宇宙よりも|遠い|場所\", 2" <|
              \_ ->
                  "宇宙よりも遠い場所"
                      |> \s -> StringExtra.nextWordPos s 2
                      |> Expect.equal (Just 5)
        , test "nextwordpos, \"宇宙よりも|遠い|場所\", 5" <|
              \_ ->
                  "宇宙よりも遠い場所"
                      |> \s -> StringExtra.nextWordPos s 5
                      |> Expect.equal (Just 7)
        , test "nextwordpos, \"宇宙よりも|遠い|場所\", 6" <|
              \_ ->
                  "宇宙よりも遠い場所"
                      |> \s -> StringExtra.nextWordPos s 6
                      |> Expect.equal (Just 7)
        ]
