local layerHandlers = require("layer_handlers")
local utils = require("utils")
local toolUtils = require("tool_utils")
local state = require("loaded_state")
local snapshot = require("structs.snapshot")
local matrix = require("utils.matrix")
local celesteRender = require("celeste_render")
local viewportHandler = require("viewport_handler")
local tiles = require("tiles")

local snapshotUtils = {}

local function redrawLayer(room, layer)
    local selected = state.isItemSelected(room)

    if selected then
        toolUtils.redrawTargetLayer(room, layer)

    else
        celesteRender.forceRedrawRoom(room, state, false)
    end
end

local function getRoomLayerSnapshot(room, layer, description, itemsBefore, itemsAfter)
    local function forward(data)
        local targetRoom = state.getRoomByName(data.room)

        if targetRoom then
            targetRoom[layer] = utils.deepcopy(itemsAfter)

            redrawLayer(targetRoom, layer)
        end
    end

    local function backward(data)
        local targetRoom = state.getRoomByName(data.room)

        if targetRoom then
            targetRoom[layer] = utils.deepcopy(itemsBefore)

            redrawLayer(targetRoom, layer)
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
    local snapshotFunction = tiles.tileLayers[layer] and snapshotUtils.roomTilesSnapshot or getRoomLayerSnapshot

    return snapshotFunction(room, layer, description, targetsBefore, targetsAfter), unpack(res)
end

function snapshotUtils.roomLayersSnapshot(callback, room, layers, description)
    local targets = {}
    local befores = {}
    local snapshots = {}

    for _, layer in ipairs(layers) do
        local handler = layerHandlers.getHandler(layer)
        local targetItems = handler.getRoomItems(room, layer)
        local targetsBefore = utils.deepcopy(targetItems)

        targets[layer] = targetItems
        befores[layer] = targetsBefore
    end

    local res = {callback()}

    for _, layer in ipairs(layers) do
        local targetItems = targets[layer]
        local targetsBefore = befores[layer]
        local targetsAfter = utils.deepcopy(targetItems)
        local snapshotFunction = tiles.tileLayers[layer] and snapshotUtils.roomTilesSnapshot or getRoomLayerSnapshot
        local snapshot = snapshotFunction(room, layer, description, targetsBefore, targetsAfter)

        table.insert(snapshots, snapshot)
    end

    return snapshotUtils.multiSnapshot(description, snapshots), unpack(res)
end

function snapshotUtils.roomLayerRevertableSnapshot(forward, backward, room, layer, description, callForward)
    local function snapshotForward(data)
        local targetRoom = state.getRoomByName(data.room)

        if targetRoom then
            forward(targetRoom, layer)

            redrawLayer(targetRoom, layer)
        end
    end

    local function snapshotBackward(data)
        local targetRoom = state.getRoomByName(data.room)

        if targetRoom then
            backward(targetRoom, layer)

            redrawLayer(targetRoom, layer)
        end
    end

    local data = {
        room = room.name
    }

    local res = {}

    if callForward ~= false then
        res = {forward()}
    end

    return snapshot.create(description, data, snapshotBackward, snapshotForward), unpack(res)
end

function snapshotUtils.roomTilesSnapshot(room, layer, description, tilesBefore, tilesAfter)
    local function forward(data)
        local targetRoom = state.getRoomByName(data.room)

        if targetRoom then
            targetRoom[layer].matrix = tiles.restoreRoomSnapshotValue(tilesAfter)

            redrawLayer(targetRoom, layer)
        end
    end

    local function backward(data)
        local targetRoom = state.getRoomByName(data.room)

        if targetRoom then
            targetRoom[layer].matrix = tiles.restoreRoomSnapshotValue(tilesBefore)

            redrawLayer(targetRoom, layer)
        end
    end

    local data = {
        room = room.name,
        width = tilesBefore._width,
        height = tilesBefore._height
    }

    return snapshot.create(description, data, backward, forward)
end

-- TODO - Does this always need to redraw?
local function applyRoomChanges(data, target, clearFirst)
    local targetRoom = state.getRoomByName(data.room)

    if targetRoom then
        if clearFirst then
            table.clear(targetRoom)
        end

        for k, v in pairs(target) do
            targetRoom[k] = utils.deepcopy(v)
        end

        celesteRender.invalidateRoomCache(targetRoom)
        celesteRender.forceRoomBatchRender(targetRoom, state)
    end
end

function snapshotUtils.roomSnapshot(room, description, before, after, clearFirst)
    local function forward(data)
        applyRoomChanges(data, after, clearFirst)
    end

    local function backward(data)
        applyRoomChanges(data, before, clearFirst)
    end

    local data = {
        room = room.name
    }

    return snapshot.create(description, data, backward, forward)
end

local function applyFillerChanges(data, target)
    local filler = data.filler

    if filler then
        filler.x = target.x or filler.x
        filler.y = target.y or filler.y

        filler.width = target.width or filler.width
        filler.height = target.height or filler.height
    end
end

function snapshotUtils.fillerSnapshot(filler, description, before, after, clearFirst)
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
        for i = #snapshots, 1, -1 do
            local snap = snapshots[i]

            snap.backward(snap.data)
        end
    end

    local data = {}

    return snapshot.create(description, data, backward, forward)
end

return snapshotUtils