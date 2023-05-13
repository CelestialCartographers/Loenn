local layerHandlers = require("layer_handlers")
local utils = require("utils")

local selectionItemUtils = {}

local function callHandlerFunction(func, room, layer, item, ...)
    if type(layer) == "table" then
        local result = false

        for _, l in ipairs(layer) do
            result = result or callHandlerFunction(func, room, l, item, ...)
        end

        return result

    else
        local correctLayer = item.layer or layer
        local handler = layerHandlers.getHandler(correctLayer)

        if room and handler and handler[func] then
            return handler[func](room, correctLayer, item, ...)
        end
    end

    return false
end

function selectionItemUtils.canResize(room, layer, target)
    local handler = layerHandlers.getHandler(layer)

    if room and handler and handler.canResize then
        return handler.canResize(room, layer, target.item or target)
    end

    return false, false
end

function selectionItemUtils.canResizeItem(room, layer, item)
    return selectionItemUtils.canResize(room, layer, item)
end

function selectionItemUtils.drawSelected(room, layer, item, color)
    return callHandlerFunction("drawSelected", room, layer, item, color)
end

function selectionItemUtils.moveSelection(room, layer, item, offsetX, offsetY)
    return callHandlerFunction("moveSelection", room, layer, item, offsetX, offsetY)
end

function selectionItemUtils.resizeSelection(room, layer, item, offsetX, offsetY, directionX, directionY)
    return callHandlerFunction("resizeSelection", room, layer, item, offsetX, offsetY, directionX, directionY)
end

function selectionItemUtils.rotateSelection(room, layer, item, direction)
    return callHandlerFunction("rotateSelection", room, layer, item, direction)
end

function selectionItemUtils.flipSelection(room, layer, item, horizontal, vertical)
    return callHandlerFunction("flipSelection", room, layer, item, horizontal, vertical)
end

function selectionItemUtils.deleteSelection(room, layer, item)
    return callHandlerFunction("deleteSelection", room, layer, item)
end

function selectionItemUtils.addNodeToSelection(room, layer, item)
    return callHandlerFunction("addNodeToSelection", room, layer, item)
end

return selectionItemUtils