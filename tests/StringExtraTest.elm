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
        , test "nextwordpos, \"舞乙|HiME\", 0" <|
              \_ ->
                  "舞乙HiME"
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
        , test "nextwordpos, \"けもの|フレンズ\", 0" <|
              \_ ->
                  "けものフレンズ"
                      |> \s -> StringExtra.nextWordPos s 0
                      |> Expect.equal (Just 3)
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

        , test "nextwordpos, \"abc|, def|. g\", 0" <|
              \_ ->
                  "abc, def. g"
                      |> \s -> StringExtra.nextWordPos s 0
                      |> Expect.equal (Just 3)
        , test "nextwordpos, \"abc|, def|. g\", 3" <|
              \_ ->
                  "abc, def. g"
                      |> \s -> StringExtra.nextWordPos s 3
                      |> Expect.equal (Just 8)
        , test "nextwordpos, \"abc|, def|. g\", 8" <|
              \_ ->
                  "abc, def. g"
                      |> \s -> StringExtra.nextWordPos s 8
                      |> Expect.equal (Just 11)
        , test "RX-78-2\", 0" <|
              \_ ->
                  "RX-72-2"
                      |> \s -> StringExtra.nextWordPos s 0
                      |> Expect.equal (Just 2)
        , test "RX-78-2\", 2" <|
              \_ ->
                  "RX-72-2"
                      |> \s -> StringExtra.nextWordPos s 2
                      |> Expect.equal (Just 5)




        , test "previoswordpos, \"This| is| a| pen.\", 13" <|
              \_ ->
                  "This is a pen."
                      |> \s -> StringExtra.previosWordPos s 13
                      |> Expect.equal (Just 10)
        , test "previoswordpos, \"This| is| a| pen.\", 12" <|
              \_ ->
                  "This is a pen."
                      |> \s -> StringExtra.previosWordPos s 12
                      |> Expect.equal (Just 10)
        , test "previoswordpos, \"This| is| a| pen.\", 10" <|
              \_ ->
                  "This is a pen."
                      |> \s -> StringExtra.previosWordPos s 10
                      |> Expect.equal (Just 8)
        , test "previoswordpos, \"This| is| a| pen.\", 8" <|
              \_ ->
                  "This is a pen."
                      |> \s -> StringExtra.previosWordPos s 8
                      |> Expect.equal (Just 5)
        , test "previoswordpos, \"This| is| a| pen.\", 5" <|
              \_ ->
                  "This is a pen."
                      |> \s -> StringExtra.previosWordPos s 5
                      |> Expect.equal (Just 0)
        , test "previoswordpos, \"This| is| a| pen.\", 0" <|
              \_ ->
                  "This is a pen."
                      |> \s -> StringExtra.previosWordPos s 0
                      |> Expect.equal Nothing
        , test "previoswordpos, \"あいうえお|　かきくけこ\", 0" <|
              \_ ->
                  "あいうえお　かきくけこ"
                      |> \s -> StringExtra.previosWordPos s 7
                      |> Expect.equal (Just 6)
        , test "previoswordpos, \"あいうえお|　かきくけこ\", 6" <|
              \_ ->
                  "あいうえお　かきくけこ"
                      |> \s -> StringExtra.previosWordPos s 6
                      |> Expect.equal (Just 0)
        , test "previoswordpos, \"AT|フィールド\", 5" <|
              \_ ->
                  "ATフィールド"
                      |> \s -> StringExtra.previosWordPos s 5
                      |> Expect.equal (Just 2)
        , test "previoswordpos, \"AT|フィールド\", 2" <|
              \_ ->
                  "ATフィールド"
                      |> \s -> StringExtra.previosWordPos s 2
                      |> Expect.equal (Just 0)
        , test "previoswordpos, \"舞乙|HiME\", 4" <|
              \_ ->
                  "舞乙HiME"
                      |> \s -> StringExtra.previosWordPos s 5
                      |> Expect.equal (Just 2)
        , test "previoswordpos, \"舞乙|HiME\", 2" <|
              \_ ->
                  "舞乙HiME"
                      |> \s -> StringExtra.previosWordPos s 2
                      |> Expect.equal (Just 0)
        , test "previoswordpos, \"機動戦士|ガンダム\", 8" <|
              \_ ->
                  "機動戦士ガンダム"
                      |> \s -> StringExtra.previosWordPos s 8
                      |> Expect.equal (Just 4)
        , test "previoswordpos, \"機動戦士|ガンダム\", 4" <|
              \_ ->
                  "機動戦士ガンダム"
                      |> \s -> StringExtra.previosWordPos s 4
                      |> Expect.equal (Just 0)
        , test "previoswordpos, \"ダンジョン|飯\", 0" <|
              \_ ->
                  "ダンジョン飯"
                      |> \s -> StringExtra.previosWordPos s 5
                      |> Expect.equal (Just 0)
        , test "previoswordpos, \"グラップラー|刃牙\", 7" <|
              \_ ->
                  "グラップラー刃牙"
                      |> \s -> StringExtra.previosWordPos s 7
                      |> Expect.equal (Just 6)
        , test "previoswordpos, \"グラップラー|刃牙\", 6" <|
              \_ ->
                  "グラップラー刃牙"
                      |> \s -> StringExtra.previosWordPos s 6
                      |> Expect.equal (Just 0)
        , test "previoswordpos, \"正解する|カド\", 5" <|
              \_ ->
                  "正解するカド"
                      |> \s -> StringExtra.previosWordPos s 5
                      |> Expect.equal (Just 4)
        , test "previoswordpos, \"正解する|カド\", 4" <|
              \_ ->
                  "正解するカド"
                      |> \s -> StringExtra.previosWordPos s 4
                      |> Expect.equal (Just 0)
        , test "previoswordpos, \"けもの|フレンズ\", 5" <|
              \_ ->
                  "けものフレンズ"
                      |> \s -> StringExtra.previosWordPos s 5
                      |> Expect.equal (Just 3)
        , test "previoswordpos, \"けもの|フレンズ\", 3" <|
              \_ ->
                  "けものフレンズ"
                      |> \s -> StringExtra.previosWordPos s 3
                      |> Expect.equal (Just 0)
        , test "privioswordpos, \"宇宙よりも|遠い|場所\", 8" <|
              \_ ->
                  "宇宙よりも遠い場所"
                      |> \s -> StringExtra.previosWordPos s 8
                      |> Expect.equal (Just 7)
        , test "privioswordpos, \"宇宙よりも|遠い|場所\", 7" <|
              \_ ->
                  "宇宙よりも遠い場所"
                      |> \s -> StringExtra.previosWordPos s 7
                      |> Expect.equal (Just 5)
        , test "privioswordpos, \"宇宙よりも|遠い|場所\", 5" <|
              \_ ->
                  "宇宙よりも遠い場所"
                      |> \s -> StringExtra.previosWordPos s 5
                      |> Expect.equal (Just 0)
        ]
