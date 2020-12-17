local utils = require("utils")

local entityHandler = require("entities")
local triggerHandler = require("triggers")
local decalHandler = require("decals")

local layerHandlers = {}

layerHandlers.layerHandlers = {
    entities = entityHandler,
    triggers = triggerHandler,
    decalsFg = decalHandler,
    decalsBg = decalHandler
}

function layerHandlers.getHandler(layer)
    return layerHandlers.layerHandlers[layer]
end

return layerHandlers