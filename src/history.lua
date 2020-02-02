-- TODO - Implement redo/undo

local history = {}

function history.undo()
    print("UNDO")
end

function history.redo()
    print("REDO")
end

return history