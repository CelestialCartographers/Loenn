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

local function callWithSnapshot(functionName, itemType, item, ...)
    local itemStruct = itemStructs[itemType]
    local func = itemStruct[functionName]
    local snapshotFunction = snapshotFunctions[itemType]

    if item then
        local itemBefore = utils.deepcopy(item)
        local res = func(item, ...)
        local itemAfter = utils.deepcopy(item)

        local snapshot = snapshotFunction(item, "Room movement", itemBefore, itemAfter)

        return snapshot
    end
end

-- TODO - Proper snapshot description
local function callWithHistory(functionName, item, ...)
    local itemType = utils.typeof(item)
    local snapshot

    if itemType == "table" then
        local snapshots = {}

        for tableItem, tableItemType in pairs(item) do
            local tableSnapshot = callWithSnapshot(functionName, tableItemType, tableItem, ...)

            if tableSnapshot then
                table.insert(snapshots, callWithSnapshot(functionName, tableItemType, tableItem, ...))
            end
        end

        snapshot = snapshotUtils.multiSnapshot("Room movement", snapshots)

    else
        snapshot = callWithSnapshot(functionName, itemType, item, ...)
    end

    if snapshot then
        history.addSnapshot(snapshot)
    end
end

for name, direction in pairs(directions) do
    movementUtils["moveCurrentRoomOneTile" .. name] = function()
        local item, itemType = loadedState.getSelectedItem()

        return callWithHistory("directionalMove", item, direction, 1)
    end

    movementUtils["moveCurrentRoomOnePixel" .. name] = function()
        local item, itemType = loadedState.getSelectedItem()

        return callWithHistory("directionalMove", item, direction, 1, 1)
    end

    movementUtils["growCurrentRoomOneTile" .. name] = function()
        local item, itemType = loadedState.getSelectedItem()

        return callWithHistory("directionalResize", item, direction, 1)
    end

    movementUtils["shrinkCurrentRoomOneTile" .. name] = function()
        local item, itemType = loadedState.getSelectedItem()

        return callWithHistory("directionalResize", item, direction, -1)
    end
end

return movementUtils