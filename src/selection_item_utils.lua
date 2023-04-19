local layerHandlers = require("layer_handlers")
local utils = require("utils")

local selectionItemUtils = {}

local function callHandlerFunction(room, layer, func, ...)
    if type(layer) == "table" then
        local result = false

        for _, l in ipairs(layer) do
            result = result or callHandlerFunction(room, l, func, ...)
        end

        return result

    else
        local handler = layerHandlers.getHandler(layer)

        if room and handler and handler[func] then
            return handler[func](room, layer, ...)
        end
    end

    return false
end

function selectionItemUtils.canResize(room, layer, target)
    local handler = layerHandlers.getHandler(layer)

    if room and handler and handler.canResize then
        return handler.canResize(room, layer, target)
    end

    return false, false
end

function selectionItemUtils.canResizeItem(room, layer, item)
    return callHandlerFunction(room, layer, "canResize", item.item)
end

function selectionItemUtils.drawSelected(room, layer, item, color)
    return callHandlerFunction(room, layer, "drawSelected", item, color)
end

function selectionItemUtils.moveSelection(room, layer, item, offsetX, offsetY)
    return callHandlerFunction(room, layer, "moveSelection", item, offsetX, offsetY)
end

function selectionItemUtils.resizeSelection(room, layer, item, offsetX, offsetY, directionX, directionY)
    return callHandlerFunction(room, layer, "resizeSelection", item, offsetX, offsetY, directionX, directionY)
end

function selectionItemUtils.rotateSelection(room, layer, item, direction)
    return callHandlerFunction(room, layer, "rotateSelection", item, direction)
end

function selectionItemUtils.flipSelection(room, layer, item, horizontal, vertical)
    return callHandlerFunction(room, layer, "flipSelection", item, horizontal, vertical)
end

function selectionItemUtils.deleteSelection(room, layer, item)
    return callHandlerFunction(room, layer, "deleteSelection", item)
end

function selectionItemUtils.addNodeToSelection(room, layer, item)
    return callHandlerFunction(room, layer, "addNodeToSelection", item)
end

return selectionItemUtils