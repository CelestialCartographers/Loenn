local modHandler = require("mods")
local fileLocations = require("file_locations")
local spriteLoader = require("sprite_loader")
local utils = require("utils")

local atlases = {}
local atlasNames = {}

local atlasesMt = {}

function atlasesMt.__index(self, key)
    local target = rawget(self, key) or rawget(self, atlasNames[key])

    if target then
        return target

    else
        for name, atlas in pairs(atlases) do
            if name:lower() == key:lower() then
                atlasNames[key] = name

                return atlas
            end
        end
    end
end

setmetatable(atlases, atlasesMt)

local celesteAtlasRelativePath = utils.joinpath("Content", "Graphics", "Atlases")
local gameplayMeta = "Gameplay.meta"
local guiMeta = "Gui.meta"

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
    local atlas = spriteLoader.getCacheOrLoadSpriteAtlas(meta, path)

    spriteLoader.addAtlasToRuntimeAtlas(atlas, path)

    atlases[name] = atlas

    addAtlasMetatable(name)
end

function atlases.createAtlas(name)
    addAtlasMetatable(name)
end

function atlases.loadCelesteAtlases()
    local celesteAtlasPath = utils.joinpath(fileLocations.getCelesteDir(), celesteAtlasRelativePath)

    atlases.loadCelesteAtlas("Gameplay", gameplayMeta, celesteAtlasPath)
    atlases.loadCelesteAtlas("Gui", guiMeta, celesteAtlasPath)
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

function atlases.addInternalPrefix(resource)
    return modHandler.internalModContent .. "/" .. resource
end

function atlases.getInternalResource(resource, name)
    if utils.startsWith(resource, modHandler.internalModContent) then
        -- Remove internal mod prefix and first /
        local internalResource = resource:sub(#modHandler.internalModContent + 2)
        local filename = string.format("assets/atlases/%s/%s.png", name, internalResource)
        local sprite = spriteLoader.loadExternalSprite(filename)

        if sprite then
            atlases[name][resource] = sprite

            return sprite
        end
    end
end

-- TODO - Make it possible to refetch the resource
function atlases.getResource(resource, name)
    name = name or "Gameplay"

    if not atlases[name] then
        atlases.createAtlas(name)
    end

    if resource then
        local targetResource = rawget(atlases[name], resource)

        -- First attempt to see if this is an external resource
        -- Then check if it is an internal one
        if not targetResource then
            local filename = string.format("%s/Graphics/Atlases/%s/%s.png", modHandler.commonModContent, name, resource)
            local sprite = spriteLoader.loadExternalSprite(filename)

            if sprite then
                atlases[name][resource] = sprite

                return sprite

            else
                return atlases.getInternalResource(resource, name)
            end
        end

        return targetResource
    end
end

function atlases.loadExternalAtlases()
    atlases.loadExternalAtlas("Gameplay")
end

return atlases