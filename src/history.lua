local timeline = require("structs.timeline")

local history = {}

history.timeline = timeline.create()

function history.reset()
    history.timeline = timeline.create()
end

function history.undo()
    history.timeline:backward()
end

function history.redo()
    history.timeline:forward()
end

function history.addSnapshot(snapshot)
    history.timeline:addSnapshot(snapshot)
end

return history