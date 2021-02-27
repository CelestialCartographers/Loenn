-- Utils for adding and removing rooms/fillers with history snapshots

-- TODO - History

local utils = require("utils")
local snapshotUtils = require("snapshot_utils")
local history = require("history")

local mapItemUtils = {}

function mapItemUtils.deleteRoom(map, room)
    for i, r in ipairs(map.rooms) do
        if r.name == room.name then
            table.remove(map.rooms, i)

            break
        end
    end
end

function mapItemUtils.deleteFiller(map, filler)
    for i, f in ipairs(map.fillers) do
        if f.x == filler.x and f.y == filler.y and f.width == filler.width and f.height == filler.height then
            table.remove(map.fillers, i)

            break
        end
    end
end

function mapItemUtils.deleteItem(map, item)
    local itemType = utils.typeof(item)

    if itemType == "room" then
        mapItemUtils.deleteRoom(map, item)

    elseif itemType == "filler" then
        mapItemUtils.deleteFiller(map, item)

    elseif itemType == "table" then
        for subItem, _ in pairs(item) do
            mapItemUtils.deleteItem(map, subItem)
        end
    end
end

function mapItemUtils.addRoom(map, room)
    table.insert(map.rooms, room)
end

function mapItemUtils.addFiller(map, filler)
    table.insert(map.fillers, filler)
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

return mapItemUtils