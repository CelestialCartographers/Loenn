local entities = require("entities")
local celesteRender = require("celeste_render")

local debugUtils = {}

-- TODO - Reload external entities when supported in entities.lua
function debugUtils.reloadEntities()
    print("! Reloading entities")

    entities.initDefaultRegistry()
    entities.loadInternalEntities()
end

function debugUtils.redrawMap()
    print("! Redrawing map")
    
    celesteRender.invalidateRoomCache()
    celesteRender.clearBatchingTasks()
end

-- TODO - Add as more hotswapping becomes available
function debugUtils.reloadEverything()
    debugUtils.reloadEntities()
    debugUtils.redrawMap()
end

function debugUtils.debug()
    debug.debug()
end

return debugUtils