local utils = require("utils")

local entityHandler = require("entities")
local triggerHandler = require("triggers")

local layerHandlers = {}

layerHandlers.layerHandlers = {
    entities = entityHandler,
    triggers = triggerHandler
}

function layerHandlers.getHandler(layer)
    return layerHandlers.layerHandlers[layer]
end

return layerHandlers