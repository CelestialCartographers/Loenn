local layerHandlers = require("layer_handlers")
local utils = require("utils")
local toolUtils = require("tool_utils")
local state = require("loaded_state")
local snapshot = require("structs.snapshot")
local matrix = require("matrix")
local celesteRender = require("celeste_render")
local viewportHandler = require("viewport_handler")

local snapshotUtils = {}

local function getRoomLayerSnapshot(room, layer, description, itemsBefore, itemsAfter)
    local function forward(data)
        local targetRoom = state.getRoomByName(data.room)

        if targetRoom then
            targetRoom[layer] = utils.deepcopy(itemsAfter)

            toolUtils.redrawTargetLayer(targetRoom, layer)
        end
    end

    local function backward(data)
        local targetRoom = state.getRoomByName(data.room)

        if targetRoom then
            targetRoom[layer] = utils.deepcopy(itemsBefore)

            toolUtils.redrawTargetLayer(targetRoom, layer)
        end
    end

    local data = {
        room = room.name
    }

    return snapshot.create(description, data, backward, forward)
end

function snapshotUtils.roomLayerSnapshot(callback, room, layer, description)
    local handler = layerHandlers.getHandler(layer)
    local targetItems = handler.getRoomItems(room, layer)
    local targetsBefore = utils.deepcopy(targetItems)

    local res = {callback()}

    local targetsAfter = utils.deepcopy(targetItems)

    return getRoomLayerSnapshot(room, layer, description, targetsBefore, targetsAfter), unpack(res)
end

function snapshotUtils.roomTilesSnapshot(room, layer, description, tilesBefore, tilesAfter)
    local function forward(data)
        local targetRoom = state.getRoomByName(data.room)

        if targetRoom then
            targetRoom[layer].matrix = matrix.fromTable(tilesAfter, data.width, data.height)

            toolUtils.redrawTargetLayer(targetRoom, layer)
        end
    end

    local function backward(data)
        local targetRoom = state.getRoomByName(data.room)

        if targetRoom then
            targetRoom[layer].matrix = matrix.fromTable(tilesBefore, data.width, data.height)

            toolUtils.redrawTargetLayer(targetRoom, layer)
        end
    end

    local data = {
        room = room.name,
        width = tilesBefore._width,
        height = tilesBefore._height
    }

    return snapshot.create(description, data, backward, forward)
end

local function applyRoomChanges(data, target)
    local targetRoom = state.getRoomByName(data.room)

    if targetRoom then
        table.clear(targetRoom)

        for k, v in pairs(target) do
            targetRoom[k] = utils.deepcopy(v)
        end

        celesteRender.invalidateRoomCache(targetRoom)
        celesteRender.forceRoomBatchRender(targetRoom, viewportHandler.viewport)
    end
end

function snapshotUtils.roomSnapshot(room, description, before, after)
    local function forward(data)
        applyRoomChanges(data, after)
    end

    local function backward(data)
        applyRoomChanges(data, before)
    end

    local data = {
        room = room.name
    }

    return snapshot.create(description, data, backward, forward)
end

local function applyFillerChanges(data, target)
    local filler = data.filler
    if filler then
        filler.x = target.x
        filler.y = target.y

        filler.width = target.width
        filler.height = target.height
    end
end

function snapshotUtils.fillerSnapshot(filler, description, before, after)
    local function forward(data)
        applyFillerChanges(data, after)
    end

    local function backward(data)
        applyFillerChanges(data, before)
    end

    local data = {
        filler = filler
    }

    return snapshot.create(description, data, backward, forward)
end

function snapshotUtils.multiSnapshot(description, snapshots)
    local function forward(data)
        for _, snap in ipairs(snapshots) do
            snap.forward(snap.data)
        end
    end

    local function backward(data)
        for _, snap in ipairs(snapshots) do
            snap.backward(snap.data)
        end
    end

    local data = {}

    return snapshot.create(description, data, backward, forward)
end

return snapshotUtils