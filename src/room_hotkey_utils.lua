local movementUtils = {}

-- Exists to make hotkeys somewhat sane

local loadedState = require("loaded_state")
local roomStruct = require("structs.room")
local fillerStruct = require("structs.filler")
local snapshotUtils = require("snapshot_utils")
local history = require("history")
local utils = require("utils")

local directions = {
    Left = "left",
    Right = "right",
    Up = "up",
    Down = "down"
}

local itemStructs = {
    room = roomStruct,
    filler = fillerStruct
}

local snapshotFunctions = {
    room = snapshotUtils.roomSnapshot,
    filler = snapshotUtils.fillerSnapshot
}

-- TODO - Proper snapshot description
local function callWithHistory(func, itemType, item, ...)
    local snapshotFunction = snapshotFunctions[itemType]

    if item then
        local itemBefore = utils.deepcopy(item)
        local res = func(item, ...)
        local itemAfter = utils.deepcopy(item)

        local snapshot = snapshotFunction(item, "Room movement", itemBefore, itemAfter)

        history.addSnapshot(snapshot)

        return true
    end

    return false
end

for name, direction in pairs(directions) do
    movementUtils["moveCurrentRoomOneTile" .. name] = function()
        local item, itemType = loadedState.getSelectedItem()
        local itemStruct = itemStructs[itemType]

        return callWithHistory(itemStruct.directionalMove, itemType, item, direction, 1)
    end

    movementUtils["moveCurrentRoomOnePixel" .. name] = function()
        local item, itemType = loadedState.getSelectedItem()
        local itemStruct = itemStructs[itemType]

        return callWithHistory(itemStruct.directionalMove, itemType, item, direction, 1, 1)
    end

    movementUtils["growCurrentRoomOneTile" .. name] = function()
        local item, itemType = loadedState.getSelectedItem()
        local itemStruct = itemStructs[itemType]

        return callWithHistory(itemStruct.directionalResize, itemType, item, direction, 1)
    end

    movementUtils["shrinkCurrentRoomOneTile" .. name] = function()
        local item, itemType = loadedState.getSelectedItem()
        local itemStruct = itemStructs[itemType]

        return callWithHistory(itemStruct.directionalResize, itemType, item, direction, -1)
    end
end

return movementUtils