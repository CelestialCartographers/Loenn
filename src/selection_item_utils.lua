local layerHandlers = require("layer_handlers")
local utils = require("utils")

local selectionItemUtils = {}

function selectionItemUtils.moveSelection(room, layer, item, x, y)
    local handler = layerHandlers.getHandler(layer)

    if room and handler and handler.moveSelection then
        return handler.moveSelection(room, layer, item, x, y)
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

return selectionItemUtils