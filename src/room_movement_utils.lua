local movementUtils = {}

-- Exists to make hotkeys somewhat sane

local loadedState = require("loaded_state")
local roomStruct = require("structs.room")

local directions = {
    Left = "left",
    Right = "right",
    Up = "up",
    Down = "down"
}

for name, direction in pairs(directions) do
    movementUtils["moveCurrentRoomOneTile" .. name] = function()
        return loadedState.selectedRoom and roomStruct.directionalMove(loadedState.selectedRoom, direction, 1)
    end

    movementUtils["moveCurrentRoomOnePixel" .. name] = function() 
        return loadedState.selectedRoom and roomStruct.directionalMove(loadedState.selectedRoom, direction, 1, 1)
    end
end

return movementUtils