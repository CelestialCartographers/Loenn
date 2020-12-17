local layerHandlers = require("layer_handlers")
local utils = require("utils")

local itemMovement = {}

function itemMovement.moveSelection(layer, room, item, x, y)
    local handler = layerHandlers.getHandler(layer)

    if room and handler and handler.moveSelection then
        handler.moveSelection(layer, room, item, x, y)
    end
end

return itemMovement