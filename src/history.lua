local timeline = require("structs.timeline")
local configs = require("configs")
local sceneHandler = require("scene_handler")

local history = {}

history.madeChanges = false
history.lastChange = 0
history.timeline = timeline.create()

function history.reset()
    history.madeChanges = false
    history.lastChanged = 0
    history.timeline = timeline.create(configs.editor.historyEntryLimit)
end

function history.undo()
    if history.timeline:backward() then
        history.madeChanges = true
        history.lastChange = os.time()

    else
        sceneHandler.sendEvent("editorHistoryUndoEmpty")
    end
end

function history.redo()
    if history.timeline:forward() then
        history.madeChanges = true
        history.lastChange = os.time()

    else
        sceneHandler.sendEvent("editorHistoryRedoEmpty")
    end
end

function history.addSnapshot(snapshot)
    history.madeChanges = true
    history.lastChange = os.time()

    history.timeline:addSnapshot(snapshot)
end

return history