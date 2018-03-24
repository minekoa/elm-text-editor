module TextEditor.KeyBind exposing
    ( KeyBind
    , find
    , basic
    , gates
    , emacsLike
    )

import TextEditor.Core.Commands as EditorCmds
import TextEditor.Core as Core  exposing (Model, Msg)


type alias KeyBind =
    { ctrl: Bool
    , alt : Bool
    , shift: Bool
    , code: Int
    , f : Model -> (Core.Model, Cmd Core.Msg)
    }


find : (Bool, Bool, Bool, Int) -> List KeyBind -> Maybe (Model -> (Model, Cmd Msg))
find (ctrl, alt, shift, keycode) keymap =
    case keymap of
        [] ->
            Nothing
        x :: xs ->
            if (keycode == x.code)
                && (ctrl == x.ctrl) && (alt == x.alt) && (shift == x.shift)
            then Just x.f
            else find (ctrl, alt, shift, keycode) xs


basic: List KeyBind
basic =
    [ {ctrl=False, alt=False, shift=False, code= 37, f=EditorCmds.moveBackward } -- '←'
    , {ctrl=False, alt=False, shift=False, code= 38, f=EditorCmds.movePrevios }  -- '↑',
    , {ctrl=False, alt=False, shift=False, code= 39, f=EditorCmds.moveForward }  -- '→'
    , {ctrl=False, alt=False, shift=False, code= 40, f=EditorCmds.moveNext }     -- '↓'
    , {ctrl=False, alt=False, shift=False, code= 36, f=EditorCmds.moveBOL }      -- Home
    , {ctrl=False, alt=False, shift=False, code= 35, f=EditorCmds.moveEOL }      -- End
    , {ctrl=False, alt=False, shift=False, code=  8, f=EditorCmds.backspace }    -- BS
    , {ctrl=False, alt=False, shift=False, code= 46, f=EditorCmds.delete }       -- DEL
    ]

gates: List KeyBind
gates =
    [ {ctrl=False, alt=False, shift=True , code= 37, f=EditorCmds.selectBackward } -- 'S-←'
    , {ctrl=False, alt=False, shift=True , code= 38, f=EditorCmds.selectPrevios }  -- 'S-↑'
    , {ctrl=False, alt=False, shift=True , code= 39, f=EditorCmds.selectForward }  -- 'S-→'
    , {ctrl=False, alt=False, shift=True , code= 40, f=EditorCmds.selectNext }     -- 'S-↓' 

    -- note: C-c, C-x, C-v は、システムのクリップボードと連携したいので、
    --       ブラウザの ClipboardEvent (copy, cut, paste)を発火させるため、ここでは何もしない

    , {ctrl=True , alt=False, shift=False, code= 90, f= EditorCmds.undo }          -- 'C-z'
    ]

emacsLike: List KeyBind
emacsLike =
    [ {ctrl=True , alt=False, shift=False, code= 70, f=EditorCmds.moveForward }  -- 'C-f'
    , {ctrl=True , alt=False, shift=False, code= 66, f=EditorCmds.moveBackward } -- 'C-b'
    , {ctrl=True , alt=False, shift=False, code= 78, f=EditorCmds.moveNext }     -- 'C-n'
    , {ctrl=True , alt=False, shift=False, code= 80, f=EditorCmds.movePrevios }  -- 'C-p'
    , {ctrl=True , alt=False, shift=False, code= 65, f=EditorCmds.moveBOL }      -- 'C-a'
    , {ctrl=True , alt=False, shift=False, code= 69, f=EditorCmds.moveEOL }      -- 'C-e'
    , {ctrl=True , alt=False, shift=False, code= 72, f=EditorCmds.backspace }    -- 'C-h'
    , {ctrl=True , alt=False, shift=False, code= 68, f=EditorCmds.delete }       -- 'C-d'
    , {ctrl=False, alt=True , shift=False, code= 87, f=EditorCmds.copy }         -- 'M-w' (注: クリップボード連携なし)
    , {ctrl=True , alt=False, shift=False, code= 87, f=EditorCmds.cut  }         -- 'C-w' (注: クリップボード連携なし)
    , {ctrl=True , alt=False, shift=False, code= 77, f=EditorCmds.insert "\n" } -- 'C-m'
    , {ctrl=True , alt=False, shift=False, code= 89, f=\m -> EditorCmds.paste m.copyStore m } -- 'C-y'
    ]

