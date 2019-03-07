local atlases = require("atlases")
local utils = require("utils")

local entities = {}

entities.registeredEntities = {}

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
        
        meta = spriteMeta
    }

    return res
end

-- TODO - Default to filename without ext
function entities.registerEntity(fn, registerAt, internal)
    local registerAt = registerAt or registeredEntities
    local handlerFunction = assert(loadstring(utils.readAll(fn, "rb", true)))

    local handler = handlerFunction()
    local name = handler.name

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

function entities.getNodes(entity)
    local res = $()

    for i, node <- entity.__children or {} do
        if node.__name == "node" then
            res += {
                node.x,
                node.y
            }
        end
    end

    return res
end

return entities