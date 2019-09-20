local utils = require("utils")

local entities = {}

local missingEntity = require("defaults.viewer.entity")

local entityRegisteryMT = {
    __index = function() return missingEntity end
}

entities.registeredEntities = nil

-- Sets the registry to the given table (or empty one) and sets the missing entity metatable
function entities.initDefaultRegistry(t)
    entities.registeredEntities = setmetatable(t or {}, entityRegisteryMT)
end

function entities.registerEntity(fn, registerAt)
    registerAt = registerAt or entities.registeredEntities

    local pathNoExt = utils.stripExtension(fn)
    local filenameNoExt = utils.filename(pathNoExt, "/")

    local handler = utils.rerequire(pathNoExt)
    local name = handler.name or filenameNoExt

    print("! Registered entity '" .. name .. "' for '" .. name .."'")

    registerAt[name] = handler
end

-- TODO - Santize user paths
function entities.loadInternalEntities(registerAt, path)
    registerAt = registerAt or entities.registeredEntities
    path = path or "entities"

    for i, file <- love.filesystem.getDirectoryItems(path) do
        -- Always use Linux paths here
        entities.registerEntity(utils.joinpath(path, file):gsub("\\", "/"), registerAt)

        coroutine.yield()
    end

    coroutine.yield(registerAt)
end

entities.initDefaultRegistry()

return entities