local utils = require("utils")

local entityHandler = require("entities")

local layerHandlers = {}

layerHandlers.layerHandlers = {
    entities = entityHandler
}

function layerHandlers.getHandler(layer)
    return layerHandlers.layerHandlers[layer]
end

return layerHandlers