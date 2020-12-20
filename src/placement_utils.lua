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
        return handler.getDrawable(name, {}, room, data, nil)
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

return placementUtils