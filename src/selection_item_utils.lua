local layerHandlers = require("layer_handlers")
local utils = require("utils")

local selectionItemUtils = {}

function selectionItemUtils.drawSelected(room, layer, item, color)
    local handler = layerHandlers.getHandler(layer)

    if room and handler and handler.drawSelected then
        return handler.drawSelected(room, layer, item, color)
    end

    return false
end

function selectionItemUtils.moveSelection(room, layer, item, offsetX, offsetY)
    local handler = layerHandlers.getHandler(layer)

    if room and handler and handler.moveSelection then
        return handler.moveSelection(room, layer, item, offsetX, offsetY)
    end

    return false
end

function selectionItemUtils.resizeSelection(room, layer, item, offsetX, offsetY, directionX, directionY)
    local handler = layerHandlers.getHandler(layer)

    if room and handler and handler.resizeSelection then
        return handler.resizeSelection(room, layer, item, offsetX, offsetY, directionX, directionY)
    end

    return false
end

function selectionItemUtils.rotateSelection(room, layer, item, direction)
    local handler = layerHandlers.getHandler(layer)

    if room and handler and handler.rotateSelection then
        return handler.rotateSelection(room, layer, item, direction)
    end

    return false
end

function selectionItemUtils.flipSelection(room, layer, item, horizontal, vertical)
    local handler = layerHandlers.getHandler(layer)

    if room and handler and handler.flipSelection then
        return handler.flipSelection(room, layer, item, horizontal, vertical)
    end

    return false
end

function selectionItemUtils.deleteSelection(room, layer, item)
    local handler = layerHandlers.getHandler(layer)

    if room and handler and handler.deleteSelection then
        return handler.deleteSelection(room, layer, item)
    end

    return false
end

function selectionItemUtils.addNodeToSelection(room, layer, item)
    local handler = layerHandlers.getHandler(layer)

    if room and handler and handler.addNodeToSelection then
        return handler.addNodeToSelection(room, layer, item)
    end

    return false
end

return selectionItemUtils