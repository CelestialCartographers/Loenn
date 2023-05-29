local roomHotkeyUtils = {}

-- Exists to make hotkeys somewhat sane

local loadedState = require("loaded_state")
local roomStruct = require("structs.room")
local fillerStruct = require("structs.filler")
local snapshotUtils = require("snapshot_utils")
local history = require("history")
local utils = require("utils")
local sceneHandler = require("scene_handler")
local configs = require("configs")

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

local historyRelevantFields = {
    filler = {
        directionalMove = {
            "x",
            "y"
        },
        directionResize = {
            "x",
            "y",
            "width",
            "height",
        }
    },
    room = {
        directionalMove = {
            "x",
            "y"
        },
        directionResize = {
            "x",
            "y",
            "width",
            "height",
            "tilesFg",
            "tilesBg",
            "sceneryFg",
            "sceneryBg",
            "sceneryObj"
        }
    }
}

local function prepareItemHistoryData(functionName, itemType, item)
    local result = {}
    local fields = historyRelevantFields[itemType][functionName]

    for _, field in ipairs(fields) do
        result[field] = utils.deepcopy(item[field])
    end

    return result
end

local function callWithSnapshot(functionName, itemType, item, ...)
    local itemStruct = itemStructs[itemType]

    if not item or not itemStruct then
        return
    end

    local func = itemStruct[functionName]
    local snapshotFunction = snapshotFunctions[itemType]

    if item then
        local itemBefore = prepareItemHistoryData(functionName, itemType, item)
        local res = func(item, ...)
        local itemAfter = prepareItemHistoryData(functionName, itemType, item)

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
    roomHotkeyUtils["moveCurrentRoomOneTile" .. name] = function()
        local item, itemType = loadedState.getSelectedItem()

        return callWithHistory("directionalMove", item, direction, 1)
    end

    roomHotkeyUtils["moveCurrentRoomOnePixel" .. name] = function()
        if configs.editor.itemAllowPixelPerfect then
            local item, itemType = loadedState.getSelectedItem()

            return callWithHistory("directionalMove", item, direction, 1, 1)
        end
    end

    roomHotkeyUtils["growCurrentRoomOneTile" .. name] = function()
        local item, itemType = loadedState.getSelectedItem()

        return callWithHistory("directionalResize", item, direction, 1)
    end

    roomHotkeyUtils["shrinkCurrentRoomOneTile" .. name] = function()
        local item, itemType = loadedState.getSelectedItem()

        return callWithHistory("directionalResize", item, direction, -1)
    end
end

function roomHotkeyUtils.deleteSelectedRoom()
    local map = loadedState.map
    local item = loadedState.getSelectedItem()

    if map and item then
        sceneHandler.sendEvent("editorRoomDelete", map, item)
    end
end

function roomHotkeyUtils.addRoom()
    local map = loadedState.map
    local item = loadedState.getSelectedItem()

    if map then
        sceneHandler.sendEvent("editorRoomAdd", map, item)
    end
end

function roomHotkeyUtils.configureSelectedRoom()
    local map = loadedState.map
    local item = loadedState.getSelectedItem()

    if map and item then
        sceneHandler.sendEvent("editorRoomConfigure", map, item)
    end
end

return roomHotkeyUtils