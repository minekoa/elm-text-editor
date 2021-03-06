module TextEditor.KeyBind exposing
    ( KeyBind
    , find
    , basic
    , gates
    , emacsLike
    )

{-|

# Definition

@docs KeyBind, find

# Default Keybinds

@docs basic, gates, emacsLike
-}


import TextEditor.Commands as EditorCmds
import TextEditor.Core as Core  exposing (Model, Msg)

{-| Keybind Data.
-}
type alias KeyBind =
    { ctrl: Bool
    , alt : Bool
    , shift: Bool
    , code: Int
    , f : EditorCmds.Command
    }

{-| Find a keybind from keycode and modifires.
-}
find : (Bool, Bool, Bool, Int) -> List KeyBind -> Maybe EditorCmds.Command
find (ctrl, alt, shift, keycode) keymap =
    case keymap of
        [] ->
            Nothing
        x :: xs ->
            if (keycode == x.code)
                && (ctrl == x.ctrl) && (alt == x.alt) && (shift == x.shift)
            then Just x.f
            else find (ctrl, alt, shift, keycode) xs

{-| Basic Keybinds. ex) arrow-keys, <Home>, <End>, <Backspace> ..etc.
-}
basic: List KeyBind
basic =
    [ {ctrl=False, alt=False, shift=False, code= 37, f=EditorCmds.moveBackward }    -- '←'
    , {ctrl=False, alt=False, shift=False, code= 39, f=EditorCmds.moveForward }     -- '→'
    , {ctrl=False, alt=False, shift=False, code= 38, f=EditorCmds.movePreviosLine } -- '↑',
    , {ctrl=False, alt=False, shift=False, code= 40, f=EditorCmds.moveNextLine }    -- '↓'
    , {ctrl=False, alt=False, shift=False, code= 36, f=EditorCmds.moveBOL }         -- Home
    , {ctrl=False, alt=False, shift=False, code= 35, f=EditorCmds.moveEOL }         -- End
    , {ctrl=False, alt=False, shift=False, code=  8, f=EditorCmds.backspace }       -- BS
    , {ctrl=False, alt=False, shift=False, code= 46, f=EditorCmds.delete }          -- DEL
    , {ctrl=False, alt=False, shift=False, code=  9, f=EditorCmds.insert "\t" }     -- tab
    , {ctrl=False, alt=False, shift=True , code=  9, f=EditorCmds.unindent }        -- S-tab
    ]

{-| Windows like keybinds 

note: Ctrl-c, Ctrl-x and Ctrl-v are not defined here 
because they want to link with the system 's clipboard and fire the browser' s ClipboardEvent (copy, cut, paste).

-}
gates: List KeyBind
gates =
    [ {ctrl=False, alt=False, shift=True , code= 37, f=EditorCmds.selectBackward }    -- 'S-←'
    , {ctrl=False, alt=False, shift=True , code= 39, f=EditorCmds.selectForward }     -- 'S-→'
    , {ctrl=False, alt=False, shift=True , code= 38, f=EditorCmds.selectPreviosLine } -- 'S-↑'
    , {ctrl=False, alt=False, shift=True , code= 40, f=EditorCmds.selectNextLine }    -- 'S-↓' 
    , {ctrl=False, alt=True , shift=False, code= 37, f=EditorCmds.movePreviosWord }   -- 'M-←'
    , {ctrl=False, alt=True , shift=False, code= 39, f=EditorCmds.moveNextWord }      -- 'M-→'
    , {ctrl=False, alt=True , shift=True , code= 37, f=EditorCmds.selectPreviosWord } -- 'S-M-←'
    , {ctrl=False, alt=True , shift=True , code= 39, f=EditorCmds.selectNextWord }    -- 'S-M-→'

    -- note: C-c, C-x, C-v は、システムのクリップボードと連携したいので、
    --       ブラウザの ClipboardEvent (copy, cut, paste)を発火させるため、ここでは何もしない

    , {ctrl=True , alt=False, shift=False, code= 90, f= EditorCmds.undo }          -- 'C-z'
    ]


{-| Emacs like keybinds
-}
emacsLike: List KeyBind
emacsLike =
    [ {ctrl=True , alt=False, shift=False, code= 70, f=EditorCmds.moveForward }     -- 'C-f'
    , {ctrl=True , alt=False, shift=False, code= 66, f=EditorCmds.moveBackward }    -- 'C-b'
    , {ctrl=True , alt=False, shift=False, code= 78, f=EditorCmds.moveNextLine }    -- 'C-n'
    , {ctrl=True , alt=False, shift=False, code= 80, f=EditorCmds.movePreviosLine } -- 'C-p'
    , {ctrl=False, alt=True , shift=False, code= 70, f=EditorCmds.moveNextWord }    -- 'M-f'
    , {ctrl=False, alt=True , shift=False, code= 66, f=EditorCmds.movePreviosWord } -- 'M-b'
    , {ctrl=True , alt=False, shift=False, code= 65, f=EditorCmds.moveBOL }         -- 'C-a'
    , {ctrl=True , alt=False, shift=False, code= 69, f=EditorCmds.moveEOL }         -- 'C-e'
    , {ctrl=True , alt=False, shift=False, code= 72, f=EditorCmds.backspace }       -- 'C-h'
    , {ctrl=True , alt=False, shift=False, code= 68, f=EditorCmds.delete }          -- 'C-d'
    , {ctrl=False, alt=True , shift=False, code= 87, f=EditorCmds.copy }            -- 'M-w' (注: クリップボード連携なし)
    , {ctrl=True , alt=False, shift=False, code= 87, f=EditorCmds.cut  }            -- 'C-w' (注: クリップボード連携なし)
    , {ctrl=True , alt=False, shift=False, code= 75, f=EditorCmds.killLine }        -- 'C-k' (注: クリップボード連携なし)
    , {ctrl=False, alt=True , shift=False, code= 68, f=EditorCmds.killWord }        -- 'M-d' (注: クリップボード連携なし)
    , {ctrl=True , alt=False, shift=False, code= 77, f=EditorCmds.insert "\n" }     -- 'C-m'
    , {ctrl=True , alt=False, shift=False, code= 89, f=EditorCmds.paste }           -- 'C-y'
    , {ctrl=True , alt=False, shift=False, code= 32, f=EditorCmds.markFlip }        -- 'C-SPE'
    , {ctrl=True , alt=False, shift=False, code=191, f=EditorCmds.undo }            -- 'C-/'
    , {ctrl=True , alt=False, shift=False, code= 73, f=EditorCmds.indent }          -- 'C-i'
    , {ctrl=False, alt=True , shift=False, code= 73, f=EditorCmds.unindent }        -- 'M-i'
    ]

