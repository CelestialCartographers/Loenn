local movementUtils = {}

-- Exists to make hotkeys somewhat sane

local loadedState = require("loaded_state")
local roomStruct = require("structs.room")
local fillerStruct = require("structs.filler")

local directions = {
    Left = "left",
    Right = "right",
    Up = "up",
    Down = "down"
}

local function getItemStruct(itemType)
    if itemType == "room" then
        return roomStruct

    elseif itemType == "filler" then
        return fillerStruct
    end
end

for name, direction in pairs(directions) do
    movementUtils["moveCurrentRoomOneTile" .. name] = function()
        local item, itemType = loadedState.getSelectedItem()
        local itemStruct = getItemStruct(itemType)

        return item and itemStruct.directionalMove(item, direction, 1)
    end

    movementUtils["moveCurrentRoomOnePixel" .. name] = function()
        local item, itemType = loadedState.getSelectedItem()
        local itemStruct = getItemStruct(itemType)

        return item and itemStruct.directionalMove(item, direction, 1, 1)
    end

    movementUtils["growCurrentRoomOneTile" .. name] = function()
        local item, itemType = loadedState.getSelectedItem()
        local itemStruct = getItemStruct(itemType)

        return item and itemStruct.directionalResize(item, direction, 1)
    end

    movementUtils["shrinkCurrentRoomOneTile" .. name] = function()
        local item, itemType = loadedState.getSelectedItem()
        local itemStruct = getItemStruct(itemType)

        return item and itemStruct.directionalResize(item, direction, -1)
    end
end

return movementUtils