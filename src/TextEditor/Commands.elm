module TextEditor.Commands exposing
    ( moveForward
    , moveBackward
    , movePrevios
    , moveNext
    , moveBOL
    , moveEOL
    , moveAt
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
    )

import TextEditor.Core as Core
import TextEditor.Core.Commands as CoreCommands
import TextEditor exposing (Model, Msg)


-- Tools
updateMap: Model -> (Core.Model, Cmd Core.Msg) -> (Model, Cmd Msg)
updateMap model (em, ec) =
    ( {model | core = em}
    , Cmd.map TextEditor.CoreMsg ec)



moveForward : Model -> (Model, Cmd Msg)
moveForward model = updateMap model (CoreCommands.moveForward model.core)

moveBackward : Model -> (Model, Cmd Msg)
moveBackward model = updateMap model (CoreCommands.moveBackward model.core)

movePrevios : Model -> (Model, Cmd Msg)
movePrevios model = updateMap model (CoreCommands.movePrevios model.core)

moveNext : Model -> (Model, Cmd Msg)
moveNext model = updateMap model (CoreCommands.moveNext model.core)

moveBOL : Model -> (Model, Cmd Msg)
moveBOL model = updateMap model (CoreCommands.moveBOL model.core)

moveEOL : Model -> (Model, Cmd Msg)
moveEOL model = updateMap model (CoreCommands.moveEOL model.core)

moveAt : (Int, Int) -> Model -> (Model, Cmd Msg)
moveAt pos model = updateMap model (CoreCommands.moveAt pos model.core)


selectBackward: Model -> (Model, Cmd Msg)
selectBackward model = updateMap model (CoreCommands.selectBackward model.core)

selectForward: Model -> (Model, Cmd Msg)
selectForward model = updateMap model (CoreCommands.selectForward model.core)

selectPrevios: Model -> (Model, Cmd Msg)
selectPrevios model = updateMap model (CoreCommands.selectPrevios model.core)

selectNext: Model -> (Model, Cmd Msg)
selectNext model = updateMap model (CoreCommands.selectNext model.core)

selectAt: (Int, Int) -> Model -> (Model, Cmd Msg)
selectAt pos model = updateMap model (CoreCommands.selectAt pos model.core)

markSet : Model -> (Model, Cmd Msg)
markSet model = updateMap model (CoreCommands.markSet model.core)

markClear : Model -> (Model, Cmd Msg)
markClear model = updateMap model (CoreCommands.markFlip model.core)

markFlip : Model -> (Model, Cmd Msg)
markFlip model = updateMap model (CoreCommands.markFlip model.core)

gotoMark : Model -> (Model, Cmd Msg)
gotoMark model = updateMap model (CoreCommands.gotoMark model.core)

insert: String -> Model-> (Model, Cmd Msg)
insert text model = updateMap model (CoreCommands.insert text model.core)

backspace: Model -> (Model, Cmd Msg)
backspace model = updateMap model (CoreCommands.backspace model.core)

delete: Model ->  (Model, Cmd Msg)
delete model = updateMap model (CoreCommands.delete model.core)

undo : Model -> (Model, Cmd Msg)
undo model = updateMap model (CoreCommands.undo model.core)

copy : Model -> (Model, Cmd Msg)
copy model = updateMap model (CoreCommands.copy model.core)

cut : Model -> (Model, Cmd Msg)
cut model = updateMap model (CoreCommands.cut model.core)

paste : Model -> (Model, Cmd Msg)
paste model = updateMap model (CoreCommands.paste model.core.copyStore model.core)

