local layerHandlers = require("layer_handlers")
local utils = require("utils")
local toolUtils = require("tool_utils")
local state = require("loaded_state")
local snapshot = require("structs.snapshot")

local snapshotUtils = {}

local function getRoomLayerSnapshot(room, layer, description, itemsBefore, itemsAfter)
    local function forward(data)
        local targetRoom = state.getRoomByName(data.room)

        if targetRoom then
            targetRoom[data.layer] = utils.deepcopy(itemsAfter)

            toolUtils.redrawTargetLayer(targetRoom, data.layer)
        end
    end

    local function backward(data)
        local targetRoom = state.getRoomByName(data.room)

        if targetRoom then
            targetRoom[data.layer] = utils.deepcopy(itemsBefore)

            toolUtils.redrawTargetLayer(targetRoom, data.layer)
        end
    end

    local data = {
        room = room.name,
        layer = layer
    }

    return snapshot.create(description, data, backward, forward)
end

function snapshotUtils.roomLayerSnapshot(callback, room, layer, description)
    local handler = layerHandlers.getHandler(layer)
    local targetItems = handler.getRoomItems(room, layer)
    local targetsBefore = utils.deepcopy(targetItems)

    callback()

    local targetsAfter = utils.deepcopy(targetItems)

    return getRoomLayerSnapshot(room, layer, description, targetsBefore, targetsAfter)
end

return snapshotUtils