module StringExtraTest exposing (..)

import Expect exposing (Expectation)
import Test exposing (..)

import TextEditor.StringExtra as StringExtra

suite : Test
suite =
    describe "StringExtra"
        [ test "nextwordpos, \"This is a pen.\", 0" <|
              \_ ->
                  "This is a pen."
                      |> \s -> StringExtra.nextWordPos s 0
                      |> Expect.equal (Just 4)
        , test "nextwordpos, \"This is a pen.\", 2" <|
              \_ ->
                  "This is a pen."
                      |> \s -> StringExtra.nextWordPos s 2
                      |> Expect.equal (Just 4)
        , test "nextwordpos, \"This is a pen.\", 4" <|
              \_ ->
                  "This is a pen."
                      |> \s -> StringExtra.nextWordPos s 4
                      |> Expect.equal (Just 5)
        , test "nextwordpos, \"This is a pen.\", 5" <|
              \_ ->
                  "This is a pen."
                      |> \s -> StringExtra.nextWordPos s 5
                      |> Expect.equal (Just 7)
        , test "nextwordpos, \"This is a pen.\", 8" <|
              \_ ->
                  "This is a pen."
                      |> \s -> StringExtra.nextWordPos s 8
                      |> Expect.equal (Just 9)
        , test "nextwordpos, \"This is a pen.\", 10" <|
              \_ ->
                  "This is a pen."
                      |> \s -> StringExtra.nextWordPos s 10
                      |> Expect.equal (Just 13)
        , test "nextwordpos, \"This is a pen.\", 13" <|
              \_ ->
                  "This is a pen."
                      |> \s -> StringExtra.nextWordPos s 13
                      |> Expect.equal Nothing
        , test "nextwordpos, \"This is a pen\", 10" <|
              \_ ->
                  "This is a pen"
                      |> \s -> StringExtra.nextWordPos s 10
                      |> Expect.equal Nothing
        , test "nextwordpos, \"あいうえお　かきくけこ\", 0" <|
              \_ ->
                  "あいうえお　かきくけこ"
                      |> \s -> StringExtra.nextWordPos s 0
                      |> Expect.equal (Just 5)
        , test "nextwordpos, \"ATフィールド\", 0" <|
              \_ ->
                  "ATフィールド"
                      |> \s -> StringExtra.nextWordPos s 0
                      |> Expect.equal (Just 2)
        , test "nextwordpos, \"機動戦士ガンダム\", 0" <|
              \_ ->
                  "機動戦士ガンダム"
                      |> \s -> StringExtra.nextWordPos s 0
                      |> Expect.equal (Just 4)
        , test "nextwordpos, \"ダンジョン飯\", 0" <|
              \_ ->
                  "ダンジョン飯"
                      |> \s -> StringExtra.nextWordPos s 0
                      |> Expect.equal (Just 5)
        , test "nextwordpos, \"認知する形\", 0" <|
              \_ ->
                  "認知する形"
                      |> \s -> StringExtra.nextWordPos s 0
                      |> Expect.equal (Just 2)
        , test "nextwordpos, \"認知する形\", 2" <|
              \_ ->
                  "認知する形"
                      |> \s -> StringExtra.nextWordPos s 2
                      |> Expect.equal (Just 4)
        , test "nextwordpos, \"認知スベシ形\", 2" <|
              \_ ->
                  "認知スベシ形"
                      |> \s -> StringExtra.nextWordPos s 2
                      |> Expect.equal (Just 5)
        , test "nextwordpos, \"宇宙よりも遠い場所\", 0" <|
              \_ ->
                  "宇宙よりも遠い場所"
                      |> \s -> StringExtra.nextWordPos s 0
                      |> Expect.equal (Just 2)
        , test "nextwordpos, \"宇宙よりも遠い場所\", 2" <|
              \_ ->
                  "宇宙よりも遠い場所"
                      |> \s -> StringExtra.nextWordPos s 2
                      |> Expect.equal (Just 5)
        , test "nextwordpos, \"宇宙よりも遠い場所\", 5" <|
              \_ ->
                  "宇宙よりも遠い場所"
                      |> \s -> StringExtra.nextWordPos s 5
                      |> Expect.equal (Just 6)
        , test "nextwordpos, \"宇宙よりも遠い場所\", 6" <|
              \_ ->
                  "宇宙よりも遠い場所"
                      |> \s -> StringExtra.nextWordPos s 6
                      |> Expect.equal (Just 7)
        ]
