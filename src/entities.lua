local atlases = require("atlases")
local utils = require("utils")

local entities = {}

local missingEntity = require("missing_entity")

local entityRegisteryMT = {
    __index = function() return missingEntity end
}

entities.registeredEntities = setmetatable({}, entityRegisteryMT)

function entities.spriteFromTexture(texture, data)
    local atlas = data.atlas or "gameplay"
    local spriteMeta = atlases[atlas][texture]

    local res = {
        x = data.x or 0,
        y = data.y or 0,

        jx = data.jx or 0.5,
        jy = data.jy or 0.5,

        sx = data.sx or 1,
        sy = data.sy or 1,

        r = data.r or 0,
        
        depth = data.depth,
        color = data.color,
        
        meta = spriteMeta
    }

    return res
end

-- TODO - Default to filename without ext
function entities.registerEntity(fn, registerAt, internal)
    local registerAt = registerAt or entities.registeredEntities

    local pathNoExt = utils.stripExtension(fn)
    local filenameNoExt = utils.filename(pathNoExt)

    local handler = require(pathNoExt)
    local name = handler.name or filenameNoExt

    print(handler, name)

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