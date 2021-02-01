local modHandler = require("mods")
local fileLocations = require("file_locations")
local spriteLoader = require("sprite_loader")
local utils = require("utils")

local atlases = {}

local celesteAtlasRelativePath = utils.joinpath("Content", "Graphics", "Atlases")
local gameplayMeta = "Gameplay.meta"

local function addAtlasMetatable(name)
    local atlas = atlases[name] or {}
    local atlasMt = {
        __index = function(self, key)
            return atlases.getResource(key, name)
        end
    }

    atlases[name] = setmetatable(atlas, atlasMt)
end

function atlases.loadCelesteAtlas(name, meta, path)
    atlases[name] = spriteLoader.getCacheOrLoadSpriteAtlas(meta, path)

    addAtlasMetatable(name)
end

function atlases.loadCelesteAtlases()
    local celesteAtlasPath = utils.joinpath(fileLocations.getCelesteDir(), celesteAtlasRelativePath)

    atlases.loadCelesteAtlas("gameplay", gameplayMeta, celesteAtlasPath)
end

-- Remove everything until after the atlas name
local function getResourceName(filename)
    local parts = filename:split("/")()
    local resourceNameWithExt = table.concat({select(5, unpack(parts))}, "/")

    return utils.stripExtension(resourceNameWithExt)
end

function atlases.loadExternalAtlas(name)
    atlases[name] = atlases[name] or {}

    local atlas = atlases[name]
    local atlasModsDir = modHandler.commonModContent .. "/" .. "Graphics/Atlases/" .. name
    local filenames = {}

    utils.getFilenames(atlasModsDir, true, filenames, function(filename)
        return utils.fileExtension(filename) == "png"
    end)

    for i, filename in ipairs(filenames) do
        local resourceName = getResourceName(filename)
        local sprite = spriteLoader.loadExternalSprite(filename)

        atlas[resourceName] = sprite

        if i > 0 and i % 10 == 0 then
            coroutine.yield()
        end
    end
end

-- TODO - Make it possible to refetch the resource
function atlases.getResource(resource, name)
    name = name or "gameplay"

    if not atlases[name] then
        atlases.createAtlas(name)
    end

    local targetResource = rawget(atlases[name], resource)

    if not targetResource then
        local filename = modHandler.commonModContent .. "/Graphics/Atlases/" .. name .. "/" .. resource .. ".png"
        local sprite = spriteLoader.loadExternalSprite(filename)

        atlases[name][resource] = sprite

        return sprite
    end

    return targetResource
end

function atlases.loadExternalAtlases()
    atlases.loadExternalAtlas("gameplay")
end

return atlases