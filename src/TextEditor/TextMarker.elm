module TextEditor.TextMarker exposing
    ( MarkedText(..)
    , deepReverse
    , markupLine
    , markupChank
    , toHtml
    , toString
    )

import Html exposing (..)
import Html.Attributes exposing (..)
import Char

type MarkedText
    = Plane (List Char)
    | Marked String (List Char)


deepReverse : List MarkedText -> List MarkedText
deepReverse lst =
    lst
        |> List.map (\elm -> case elm of
                                 Plane cs -> Plane (List.reverse cs)
                                 Marked tag cs -> Marked tag (List.reverse cs)
                    )
        |> List.reverse

toHtml : List MarkedText -> List (Html msg)
toHtml txts =
    txts
        |> List.map (\ txt ->
                         case txt of
                             Marked tag cs -> span [class tag] [ cs |> String.fromList |> text ]
                             Plane cs      -> cs |> String.fromList |> text
                    )

toString : List MarkedText -> String
toString txts =
    txts
        |> List.map (\ txt ->
                         case txt of
                             Marked tag cs -> String.fromList cs
                             Plane cs      -> String.fromList cs
                    )
        |> String.concat


markupLine : Bool -> Int -> String -> List MarkedText
markupLine showControlCharactor tabOrder line =
    case showControlCharactor of
        True ->
            markupControlChars tabOrder (line ++ "\n")
        False ->
            replaceTab tabOrder line

markupChank : Bool -> Int -> String -> List MarkedText
markupChank showControlCharactor tabOrder line =
    case showControlCharactor of
        True ->
            markupControlChars tabOrder line
        False ->
            replaceTab tabOrder line


markupControlChars : Int -> String -> List MarkedText
markupControlChars tabOrder line =
    let
        f =
            (\ str n outtxts ->
                 case str of
                     '\t' :: xs ->
                         let
                             sp_cnt  = tabOrder - (n % tabOrder)
                             rpl_txt = String.padRight (sp_cnt) ' ' "»"
                                           |> String.toList
                                           |> List.reverse -- 後でdeepReverseでヒックリかえされるので
                         in
                             f xs (n + sp_cnt) ((Marked "tab-face" rpl_txt) :: outtxts)
                     '\n' :: xs ->
                         f xs (n + 1) ((Marked "eol-face" [ '↵' ]) :: outtxts)

                     '　' :: xs ->
                         f xs (n + 1) ((Marked "jaspace-face" [ '□' ]) :: outtxts)
                                  
                     x :: xs ->
                         case outtxts of
                             (Plane cs) :: css ->
                                 f xs (n + 1) ((Plane (x :: cs)) :: css)
                             _ ->
                                 f xs (n + 1) ((Plane [x]) :: outtxts)
                     [] ->
                         outtxts
            )
    in
        f (line |> String.toList) 0 []
            |> deepReverse


replaceTab : Int -> String -> List MarkedText
replaceTab tabOrder line =
    let
        f = 
            (\ str n outchars ->
                 case str of
                     '\t' :: xs ->
                         let
                             sp_cnt  = tabOrder - (n % tabOrder)
                             rpl_txt = String.padRight (sp_cnt) ' ' ""
                                           |> String.toList
                                           |> List.reverse -- 後でdeepReverseでヒックリかえされるので
                         in
                             f xs (n + sp_cnt) ((rpl_txt) ++ outchars)
                     x :: xs ->
                         f xs (n + 1) (x :: outchars)
                     [] ->
                         outchars
            )
    in
        f (line |> String.toList) 0 []
            |> List.reverse
            |> (\cs -> [Plane cs])


