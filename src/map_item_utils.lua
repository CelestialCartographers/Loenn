-- Utils for adding and removing rooms/fillers with history snapshots

-- TODO - History

local utils = require("utils")
local snapshotUtils = require("snapshot_utils")
local history = require("history")
local sceneHandler = require("scene_handler")
local celesteRender = require("celeste_render")

local mapItemUtils = {}

function mapItemUtils.deleteRoom(map, room)
    for i, r in ipairs(map.rooms) do
        if r.name == room.name then
            celesteRender.invalidateRoomCache(room)
            table.remove(map.rooms, i)
            sceneHandler.sendEvent("editorRoomDeleted", room)

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

function mapItemUtils.deleteItem(map, item)
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

function mapItemUtils.addItem(map, item)
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

function mapItemUtils.moveRoomWith(map, room, getDest)
    for i, r in ipairs(map.rooms) do
        if r.name == room.name then
            local dest = getDest(i)
            -- Prevent moving out of bounds
            if dest <= 0 or dest > #map.rooms then 
                return false
            end
            table.remove(map.rooms, i)
            
            table.insert(map.rooms, dest, r)
            sceneHandler.sendEvent("editorRoomSorted", room, dest)

            return true
        end
    end

    return false
end
function mapItemUtils.moveRoomBy(map, item, n) 
    mapItemUtils.moveRoomWith(map, item, function (i) return i + n end)
end
return mapItemUtils
