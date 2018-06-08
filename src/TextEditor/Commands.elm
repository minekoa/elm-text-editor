module TextEditor.Commands exposing
    ( moveForward
    , moveBackward
    , movePrevios
    , moveNext
    , moveBOL
    , moveEOL
    , moveAt
    , moveNextWord
    , movePreviosWord
    , selectForward
    , selectBackward
    , selectPrevios
    , selectNext
    , selectAt
    , markSet
    , markClear
    , markFlip
    , gotoMark
    , insert
    , backspace
    , delete
    , undo
    , copy
    , cut
    , paste
    , killLine
    , indent
    , unindent

    , Command

--    , batch
    )

import TextEditor.Core as Core
import TextEditor.Core.Commands as CoreCommands
--import TextEditor exposing (Model, Msg)


type alias Command =
    { id : String
    , f : Core.Model -> (Core.Model, Cmd Core.Msg)
    }


-- batch : List (Model -> (Model, Cmd Msg)) -> (Model -> (Model, Cmd Msg))
-- batch commands =
--     let
--         batch_proc = (\ cmdMsgs editorCmds model ->
--                           case editorCmds of
--                               x :: xs ->
--                                   let
--                                       (m1, c1) = x model
--                                   in
--                                       batch_proc (c1 :: cmdMsgs) xs m1
--                               [] ->
--                                   (model, Cmd.batch cmdMsgs)
--                      )
--     in
--         batch_proc [] commands


-- -- Tools
-- updateMap: Model -> (Core.Model, Cmd Core.Msg) -> (Model, Cmd Msg)
-- updateMap model (em, ec) =
--     ( {model | core = em}
--     , Cmd.map TextEditor.CoreMsg ec)



moveForward : Command
moveForward =
    { id= "moveForward"
    , f = CoreCommands.moveForward
    }

moveBackward : Command
moveBackward =
    { id= "moveBackward"
    , f = CoreCommands.moveBackward
    }

movePrevios : Command
movePrevios =
    { id= "movePrevios"
    , f = CoreCommands.movePrevios
    }

moveNext : Command
moveNext =
    { id= "moveNext"
    , f = CoreCommands.moveNext
    }

moveBOL : Command
moveBOL =
    { id= "moveBOL"
    , f = CoreCommands.moveBOL
    }

moveEOL : Command
moveEOL =
    { id = "moveEOL"
    , f  = CoreCommands.moveEOL
    }

moveAt : (Int, Int) -> Command
moveAt pos =
    { id = "moveAt"
    , f = CoreCommands.moveAt pos
    }

moveNextWord : Command
moveNextWord =
    { id = "moveNextWord"
    , f  = CoreCommands.moveNextWord
    }

movePreviosWord : Command
movePreviosWord =
    { id = "movePreviosWord"
    , f  = CoreCommands.movePreviosWord
    }

selectBackward : Command
selectBackward =
    { id= "selectBackword"
    , f = CoreCommands.selectBackward
    }

selectForward : Command
selectForward =
    { id= "selectForward"
    , f = CoreCommands.selectForward
    }

selectPrevios : Command
selectPrevios =
    { id= "selectPrevios"
    , f = CoreCommands.selectPrevios
    }

selectNext : Command
selectNext =
    { id= "selectNext"
    , f = CoreCommands.selectNext
    }

selectAt: (Int, Int) -> Command
selectAt pos =
    { id= "selectAt"
    , f = CoreCommands.selectAt pos
    }

markSet : Command
markSet = 
    { id="markSet"
    , f=CoreCommands.markSet
    }

markClear : Command
markClear =
    { id= "markClear"
    , f = CoreCommands.markClear
    }

markFlip : Command
markFlip =
    { id= "markFlip"
    , f = CoreCommands.markFlip
    }

gotoMark : Command
gotoMark =
    { id = "gotoMark"
    , f = CoreCommands.gotoMark
    }

insert: String -> Command
insert text =
    { id = "insert " ++ text -- TODO: 良い解決方法が浮かばないので今のところidにエンコードしてしまう
    , f = (CoreCommands.insert text)
    }

backspace: Command
backspace =
    { id = "backspace"
    , f  = CoreCommands.backspace
    }

delete : Command
delete =
    { id ="delete"
    , f= CoreCommands.delete
    }

undo : Command
undo =
    { id = "undo"
    , f = CoreCommands.undo
    }

copy : Command
copy =
    { id= "copy"
    , f = CoreCommands.copy
    }

cut : Command
cut =
    { id = "cut"
    , f = CoreCommands.cut
    }

paste : Command
paste =
    { id = "paste"
    , f = (\m -> CoreCommands.paste m.copyStore m)
    }

killLine : Command
killLine =
    { id = "killLine"
    , f = CoreCommands.killLine
    }

indent : Command
indent =
    { id = "indent"
    , f = CoreCommands.indent
    }

unindent : Command
unindent =
    { id = "unindent"
    , f = CoreCommands.unindent
    }



