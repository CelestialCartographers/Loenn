local utils = require("utils")

local entityHandler = require("entities")
local triggerHandler = require("triggers")
local decalHandler = require("decals")
local tilesHandler = require("tiles")

local layerHandlers = {}

layerHandlers.layerHandlers = {
    entities = entityHandler,
    triggers = triggerHandler,
    decalsFg = decalHandler,
    decalsBg = decalHandler,
    tilesFg = tilesHandler,
    tilesBg = tilesHandler
}

function layerHandlers.getHandler(layer)
    return layerHandlers.layerHandlers[layer]
end

return layerHandlers