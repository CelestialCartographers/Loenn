local timeline = require("structs.timeline")
local configs = require("configs")

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
    history.timeline:backward()
end

function history.redo()
    history.timeline:forward()
end

function history.addSnapshot(snapshot)
    history.madeChanges = true
    history.lastChange = os.time()

    history.timeline:addSnapshot(snapshot)
end

return history