local utils = require("utils")

local entities = {}

local missingEntity = require("defaults/viewer/entity")

local entityRegisteryMT = {
    __index = function() return missingEntity end
}

entities.registeredEntities = setmetatable({}, entityRegisteryMT)

function entities.registerEntity(fn, registerAt, internal)
    local registerAt = registerAt or entities.registeredEntities

    local pathNoExt = utils.stripExtension(fn)
    local filenameNoExt = utils.filename(pathNoExt)

    local handler = require(pathNoExt)
    local name = handler.name or filenameNoExt

    print("! Registered entity '" .. name .. "'")

    registerAt[name] = handler
end

-- TODO - Santize user paths
function entities.loadInternalEntities(registerAt, path)
    local registerAt = registerAt or entities.registeredEntities
    local path = path or "entities"

    for i, file <- love.filesystem.getDirectoryItems(path) do
        entities.registerEntity(path .. "/" .. file, registerAt)

        coroutine.yield()
    end

    coroutine.yield(registerAt)
end

return entities