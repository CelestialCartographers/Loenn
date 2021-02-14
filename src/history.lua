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
    if not history.timeline:backward() then
        sceneHandler.sendEvent("editorHistoryUndoEmpty")
    end
end

function history.redo()
    if not history.timeline:forward() then
        sceneHandler.sendEvent("editorHistoryRedoEmpty")
    end
end

function history.addSnapshot(snapshot)
    history.madeChanges = true
    history.lastChange = os.time()

    history.timeline:addSnapshot(snapshot)
end

return history