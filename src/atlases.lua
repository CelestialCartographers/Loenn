local modHandler = require("mods")
local fileLocations = require("file_locations")
local spriteLoader = require("sprite_loader")
local utils = require("utils")

local atlases = {}

local celesteAtlasRelativePath = utils.joinpath("Content", "Graphics", "Atlases")
local gameplayMeta = "Gameplay.meta"

function atlases.loadCelesteAtlases()
    local celesteAtlasPath = utils.joinpath(fileLocations.getCelesteDir(), celesteAtlasRelativePath)

    atlases["gameplay"] = spriteLoader.getCacheOrLoadSpriteAtlas(gameplayMeta, celesteAtlasPath)
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
        atlases[name] = {}
    end

    if not atlases[name][resource] then
        local filename = modHandler.commonModContent .. "/Graphics/Atlases/" .. name .. "/" .. resource .. ".png"
        local sprite = spriteLoader.loadExternalSprite(filename)

        atlases[name][resource] = sprite
    end

    return atlases[name][resource]
end

function atlases.loadExternalAtlases()
    atlases.loadExternalAtlas("gameplay")
end

return atlases