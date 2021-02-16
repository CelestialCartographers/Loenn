local layerHandlers = require("layer_handlers")
local utils = require("utils")

local placementUtils = {}

function placementUtils.getPlacements(layer)
    local handler = layerHandlers.getHandler(layer)

    if handler and handler.getPlacements then
        return handler.getPlacements(layer)
    end

    return {}
end

function placementUtils.getDrawable(layer, name, room, data)
    local handler = layerHandlers.getHandler(layer)

    if handler and handler.getDrawable then
        return handler.getDrawable(name, nil, room, data, nil)
    end

    return {}
end

-- Add unique ID to trigger/entity
function placementUtils.finalizePlacement(room, layer, item)
    if layer == "entities" or layer == "triggers" then
        local ids = {}

        if room[layer] then
            for _, target in ipairs(room[layer]) do
                ids[target._id] = true
            end
        end

        for id = 0, math.huge do
            if not ids[id] then
                item._id = id

                return
            end
        end
    end
end

function placementUtils.placeItem(room, layer, item)
    local handler = layerHandlers.getHandler(layer)

    if handler and handler.placeItem then
        placementUtils.finalizePlacement(room, layer, item)

        return handler.placeItem(room, layer, item)
    end

    return false
end

function placementUtils.canResize(room, layer, target)
    local handler = layerHandlers.getHandler(layer)

    if handler and handler.canResize then
        return handler.canResize(room, layer, target)
    end

    return false, false
end

function placementUtils.minimumSize(room, layer, target)
    local handler = layerHandlers.getHandler(layer)

    if handler and handler.minimumSize then
        return handler.minimumSize(room, layer, target)
    end

    return nil, nil
end

function placementUtils.nodeLimits(room, layer, target)
    local handler = layerHandlers.getHandler(layer)

    if handler and handler.nodeLimits then
        return handler.nodeLimits(room, layer, target)
    end

    return 0, 0
end

return placementUtils