-- Utils for adding and removing rooms/fillers with history snapshots

local utils = require("utils")
local roomStruct = require("structs.room")
local snapshotStruct = require("structs.snapshot")
local fillerStruct = require("structs.filler")
local snapshotUtils = require("snapshot_utils")
local history = require("history")
local sceneHandler = require("scene_handler")
local celesteRender = require("celeste_render")
local configs = require("configs")

local mapItemUtils = {}

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
        move = {
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
        move = {
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

local directionOffsets = {
    left = {-1, 0},
    right = {1, 0},
    up = {0, -1},
    down = {0, 1},
}

function mapItemUtils.getMapBounds(map)
    local rectangles = {}

    for _, room in ipairs(map.rooms) do
        local rectangle = utils.rectangle(room.x, room.y, room.width, room.height)

        table.insert(rectangles, rectangle)
    end

    return utils.rectangleBounds(rectangles)
end

function mapItemUtils.deleteRoom(map, room)
    for i, r in ipairs(map.rooms) do
        if r.name == room.name then
            celesteRender.invalidateRoomCache(r)
            table.remove(map.rooms, i)
            sceneHandler.sendEvent("editorRoomDeleted", r)

            return true
        end
    end

    return false
end

function mapItemUtils.deleteFiller(map, filler)
    for i, f in ipairs(map.fillers) do
        if f.x == filler.x and f.y == filler.y and f.width == filler.width and f.height == filler.height then
            table.remove(map.fillers, i)
            sceneHandler.sendEvent("editorFillerDeleted", filler)

            return true
        end
    end

    return false
end

local function deleteItemWithHistory(map, item)
    local function forward()
        mapItemUtils.deleteItem(map, item, false)
    end

    local function backward()
        mapItemUtils.addItem(map, item, false)
    end

    return history.addSnapshot(snapshotStruct.create("Remove map items", {}, backward, forward))
end

function mapItemUtils.deleteItem(map, item, useHistory)
    if useHistory ~= false then
        deleteItemWithHistory(map, item)
    end

    local itemType = utils.typeof(item)

    if itemType == "room" then
        return mapItemUtils.deleteRoom(map, item)

    elseif itemType == "filler" then
        return mapItemUtils.deleteFiller(map, item)

    elseif itemType == "table" then
        local result = false

        for subItem, _ in pairs(item) do
            result = result or mapItemUtils.deleteItem(map, subItem)
        end

        return result
    end
end

function mapItemUtils.addRoom(map, room)
    table.insert(map.rooms, room)
    sceneHandler.sendEvent("editorRoomAdded", room)
end

function mapItemUtils.addFiller(map, filler)
    table.insert(map.fillers, filler)
    sceneHandler.sendEvent("editorFillerAdded", filler)
end

local function addItemWithHistory(map, item)
    local function forward()
        mapItemUtils.addItem(map, item, false)
    end

    local function backward()
        mapItemUtils.deleteItem(map, item, false)
    end

    return history.addSnapshot(snapshotStruct.create("Add map items", {}, backward, forward))
end


function mapItemUtils.addItem(map, item, useHistory)
    if useHistory ~= false then
        addItemWithHistory(map, item)
    end

    local itemType = utils.typeof(item)

    if itemType == "room" then
        mapItemUtils.addRoom(map, item)

    elseif itemType == "filler" then
        mapItemUtils.addFiller(map, item)

    elseif itemType == "table" then
        for _, subItem in ipairs(item) do
            mapItemUtils.addItem(map, subItem)
        end
    end
end

function mapItemUtils.sortRoomList(map, force)
    if configs.editor.sortRoomsOnSave or force then
        if map then
            table.sort(map.rooms, function(lhs, rhs)
                return lhs.name < rhs.name
            end)

            sceneHandler.sendEvent("editorRoomOrderChanged", map)
        end
    end
end


local function prepareItemHistoryData(functionName, itemType, item)
    local result = {}
    local fields = historyRelevantFields[itemType][functionName]

    for _, field in ipairs(fields) do
        result[field] = utils.deepcopy(item[field])
    end

    return result
end

local function callStructFunction(functionName, itemType, item, ...)
    local itemStruct = itemStructs[itemType]

    if not item or not itemStruct then
        return
    end

    local func = itemStruct[functionName]

    return func(item, ...)
end

local function callWithoutHistory(functionName, item, ...)
    local itemType = utils.typeof(item)

    if itemType == "table" then
        for tableItem, tableItemType in pairs(item) do
            callStructFunction(functionName, tableItemType, tableItem, ...)
        end

    else
        callStructFunction(functionName, itemType, item, ...)
    end
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

        return snapshot, res
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
                table.insert(snapshots, tableSnapshot)
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

function mapItemUtils.move(item, amountX, amountY, step, useHistory)
    if useHistory == false then
        return callWithoutHistory("move", item, amountX, amountY, step)
    end

    return callWithHistory("move", item, amountX, amountY, step)
end

function mapItemUtils.directionalMove(item, direction, amount, step, useHistory)
    if not directionOffsets[direction] then
        return
    end

    local offsetX, offsetY = unpack(directionOffsets[direction])
    local amountX, amountY = amount * offsetX, amount * offsetY

    return mapItemUtils.move(item, amountX, amountY, step, useHistory)
end

function mapItemUtils.directionalResize(item, direction, amount, step, useHistory)
    if useHistory == false then
        return callWithoutHistory("directionalResize", item, direction, amount, step)
    end

    return callWithHistory("directionalResize", item, direction, amount, step)
end

return mapItemUtils