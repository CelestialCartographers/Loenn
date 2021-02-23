-- Used to keep menubar reasonable
-- roomWindow is updated by the room window, allows hotswaping

local loadedState = require("loaded_state")

local roomEditor = {}

roomEditor.roomWindow = nil

function roomEditor.createNewRoom(element)
    if roomEditor.roomWindow then
        roomEditor.roomWindow.createNewRoom()
    end
end

function roomEditor.editExistingRoom(element, room)
    if roomEditor.roomWindow then
        room = room or loadedState.getSelectedRoom()

        roomEditor.roomWindow.editExistingRoom(room)
    end
end

return roomEditor