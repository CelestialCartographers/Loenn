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

function placementUtils.placeItem(room, layer, item)
    local handler = layerHandlers.getHandler(layer)

    if handler and handler.placeItem then
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