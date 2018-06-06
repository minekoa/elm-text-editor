module TextEditor.StringExtra exposing
    ( nextWordPos
    )


import Char


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
                        (SpaceChar , _)       -> nextWordPosProc char_t cs (n + 1)
                        (Kanji, Hiragana)     -> nextWordPosProc char_t cs (n + 1)
                        (Katakana, Hiragana)  -> nextWordPosProc char_t cs (n + 1)
                        _                     -> Just n
            
        [] ->
            if prev_char_t == SpaceChar then
                Nothing
            else
                Just n


type CharType
    = AlphaNumericChar
    | SpaceChar
    | SignChar
    | Hiragana
    | Katakana
    | Kanji
    | MultibyteChar


chartype : Char -> CharType
chartype c =
    if      isAlpanumeric c   then AlphaNumericChar
    else if isSpace c         then SpaceChar
    else if isHiragana c      then Hiragana
    else if isKatakana c      then Katakana
    else if isKanji c         then Kanji
    else if isMultiByteChar c then MultibyteChar
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


isMultiByteChar : Char -> Bool
isMultiByteChar c =
    0x7F < (Char.toCode c)
