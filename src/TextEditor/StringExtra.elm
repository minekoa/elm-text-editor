module TextEditor.StringExtra exposing
    ( nextWordPos
    , previosWordPos
    , indentString
    , indentLevel
    )


import Char



------------------------------------------------------------
-- Word
------------------------------------------------------------

nextWordPos : String -> Int -> Maybe Int
nextWordPos line column =
    let
        backword_chars = line |> String.toList |> List.drop column
    in
        -- note: line が空のとき、\n を補うのは、業種右端は改行だから
        nextWordPosProc
            (List.head backword_chars |> Maybe.withDefault '\n' |> chartype)
            backword_chars
            column

nextWordPosProc : CharType -> List Char -> Int -> Maybe Int
nextWordPosProc prev_char_t str n =
    case str of
        c :: cs ->
            let
                char_t = chartype c
            in
                if char_t == prev_char_t then
                    nextWordPosProc char_t cs (n + 1)
                else
                    case (prev_char_t, char_t) of
                        (SpaceChar , _)           -> nextWordPosProc char_t cs (n + 1)
                        (PanctuationAndSymbol, _) -> nextWordPosProc char_t cs (n + 1)
                        (Kanji, Hiragana)         -> nextWordPosProc char_t cs (n + 1)
                        (Katakana, Hiragana)      -> nextWordPosProc char_t cs (n + 1)
                        _                         -> Just n
            
        [] ->
            if prev_char_t == SpaceChar then
                Nothing
            else
                Just n

previosWordPos : String -> Int -> Maybe Int
previosWordPos line column =
    let
        forward_chars = line |> String.toList |> List.take column
    in
        previosWordPosProc
            (List.reverse forward_chars |> List.head |> Maybe.withDefault '\n' |> chartype)
            (List.reverse forward_chars)
            column

previosWordPosProc : CharType -> List Char -> Int -> Maybe Int
previosWordPosProc fwd_char_t reversed_str n =
    case reversed_str of
        c :: cs ->
            let
                char_t = chartype c
            in
                if char_t == fwd_char_t then
                    previosWordPosProc char_t cs (n - 1)
                else
                    case (fwd_char_t, char_t) of
                        (SpaceChar , _)           -> previosWordPosProc char_t cs (n - 1)
                        (PanctuationAndSymbol, _) -> previosWordPosProc char_t cs (n - 1)
                        (Hiragana, Kanji)         -> previosWordPosProc char_t cs (n - 1)
                        (Hiragana, Katakana)      -> previosWordPosProc char_t cs (n - 1)
                        _                         -> Just n
            
        [] ->
            if fwd_char_t == SpaceChar then
                Nothing
            else
                Just n

------------------------------------------------------------
-- Indent
------------------------------------------------------------

indentString : String -> String
indentString line =
    let
        getIndentStringProc = (\l indent_str->
                                   case l of
                                       [] ->
                                           indent_str |> List.reverse
                                       x :: xs ->
                                           if (x == ' ') || (x == '\t') then
                                               getIndentStringProc xs (x :: indent_str)
                                           else
                                               indent_str |> List.reverse
                              )
    in
        getIndentStringProc (line |> String.toList) []  |> String.fromList


indentLevel : Int -> String -> Int
indentLevel tabOrder s =
    let
        calcIndentLevel = (\ str n ->
                               case str of
                                   ' '  :: xs -> calcIndentLevel xs (n + 1)
                                   '\t' :: xs -> calcIndentLevel xs (((n // tabOrder) + 1) * tabOrder)
                                   x :: xs -> n
                                   [] -> n
                          )
    in
        calcIndentLevel (s |> String.toList) 0




------------------------------------------------------------
-- CharType
------------------------------------------------------------

type CharType
    = AlphaNumericChar
    | SpaceChar
    | PanctuationAndSymbol
    | SignChar
    | Hiragana
    | Katakana
    | Kanji
    | MultibyteChar


chartype : Char -> CharType
chartype c =
    if      isAlpanumeric c          then AlphaNumericChar
    else if isSpace c                then SpaceChar
    else if isPanctuationAndSymbol c then PanctuationAndSymbol
    else if isHiragana c             then Hiragana
    else if isKatakana c             then Katakana
    else if isKanji c                then Kanji
    else if isMultiByteChar c        then MultibyteChar
    else SignChar

isAlpanumeric: Char -> Bool
isAlpanumeric c =
    isAlpabete c || Char.isDigit c

isAlpabete : Char -> Bool
isAlpabete c =
    Char.isUpper c || Char.isLower c

isSpace : Char -> Bool
isSpace c =
    isJustSpace c
        || case c of
               '\t' -> True
               '\v' -> True
               '\n' -> True
               _    -> False

isJustSpace : Char -> Bool
isJustSpace c =
    case (c |> Char.toCode) of
        0x0020 -> True -- SPACE
        0x00A0 -> True -- NO-BREAK SPACE
        0x1680 -> True -- OGHAM SPACE MAR
        0x180E -> True -- MONGOLIAN VOWEL SEPARATOR
        0x2000 -> True -- EN QUAD
        0x2001 -> True -- EM QUAD
        0x2002 -> True -- EN SPACE
        0x2003 -> True -- EM SPACE
        0x2004 -> True -- THREE-PER-EM SPACE
        0x2005 -> True -- FOUR-PER-EM SPACE
        0x2006 -> True -- SIX-PER-EM SPACE
        0x2007 -> True -- FIGURE SPACE
        0x2008 -> True -- PUNCTUATION SPAC
        0x2009 -> True -- THIN SPACE
        0x200A -> True -- HAIR SPACE
        0x200B -> True -- ZERO WIDTH SPACE
        0x202F -> True -- NARROW NO-BREAK SPACE
        0x205F -> True -- MEDIUM MATHEMATICAL SPACE
        0x3000 -> True -- IDEOGRAPHIC SPACE (CJK)
        0xFEFF -> True -- ZERO WIDTH NO-BREAK SPACE
        _      -> False


isHiragana : Char -> Bool
isHiragana c =
    let
        cd = Char.toCode c
    in
        (0x3040 <= cd) && (cd <= 0x309F)

isKatakana : Char -> Bool
isKatakana c =    
    let
        cd = Char.toCode c
    in
        (0x30A0 <= cd) && (cd <= 0x30FF)

isKanji : Char -> Bool
isKanji c =
    let
        cd = Char.toCode c
    in
        ((0x4E00 <= cd) && (cd <= 0x9FFF))    -- CJK 統合漢字
        || ((0xFA30 <= cd) && (cd <= 0xFA6A)) -- CJK 互換漢字 JIS X 0213



isPanctuationAndSymbol : Char -> Bool
isPanctuationAndSymbol c =
    -- http://www.asahi-net.or.jp/~ax2s-kmtn/ref/unicode/punctuation.html
    (isInCodeRange
         [ (0x0021 , 0x007F ) -- ASCII句読点と記号      ASCII punctuation and symbols
         , (0x003A , 0x0040 )
         , (0x005B , 0x0060 )
         , (0x007B , 0x007F )
         , (0x00A1 , 0x00BF ) -- ラテン1句読点
         , (0x2000 , 0x206F ) -- 一般句読点             General Punctuation                 .. ラテン言語で最も一般的に用いられる句読点
         , (0x2E00 , 0x2E7F ) -- 補助句読点             Supplemental Punctuation            .. 特殊な表記法や古代写本に用いられる、比較的頻度の少ない句読点
         , (0x3000 , 0x303F ) -- CJKの記号及び句読点    CJK Symbols and Punctuation         .. CJK 東アジアの表意文字で用いられる記号と句読点
         , (0x16FE0, 0x16FFF) -- 表意文字の記号と句読点 Ideographic Symbols and Punctuation .. 西夏文字、女書などの東アジアの表意文字で用いられる記号と句読点
         , (0xFE30 , 0xFE4F ) -- CJK互換形              CJK Compatibility Forms             .. 台湾の規格CNS 11643用の互換文字です。
         , (0xFE50 , 0xFE6F ) -- 小字形                 Small Form Variants                 .. 台湾の規格CNS 11643用の互換文字です。
         , (0xFE10 , 0xFE1F ) -- 縦書き形               Vertical Forms                      .. 中国の規格GB 18030用の互換文字です。
         , (0xFF01 , 0xFF0F ) -- 全角ASCII句読点と記号  ASCII Fullwidth punctuation and symbols
         , (0xFF1A , 0xFF20 )
         , (0xFF3B , 0xFF40 )
         , (0xFF5B , 0xFF5D )
         , (0xFF5F , 0xFF60 ) --   全角括弧             Fullwidth brackets
         , (0xFF61 , 0xFF64 ) --   半角CJK句読点        Halfwidth CJK punctuation
         , (0xFFE0 , 0xFFE6 ) --   全角記号             Fullwidth symbol variants
         , (0xFFE8 , 0xFFEE ) --   半角記号             Halfwidth symbol variants

         ]
         c
    ) && not (isSpace c)


isMultiByteChar : Char -> Bool
isMultiByteChar c =
    0x7F < (Char.toCode c)


isInCodeRange : List (Int, Int) -> Char -> Bool
isInCodeRange ranges c =
    let
        cd = Char.toCode c
    in
        List.foldl
            (\ range b ->
                 case b of
                     True  -> True
                     False -> (Tuple.first range) <= cd  && (cd <= Tuple.second range)
            )
            False ranges

