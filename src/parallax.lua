local atlases = require("atlases")
local utils = require("utils")
local mods = require("mods")

local parallax = {}

local parallaxTexturePrefix = "bgs/"
local parallaxTexturePath = "Graphics/Atlases/Gameplay/bgs"

local fieldOrder = {
    "texture", "only", "exclude", "tag",
    "flag", "notflag", "blendmode", "color",
    "x", "y", "scrollx", "scrolly",
    "speedx", "speedy", "fadex", "fadey",
    "alpha"
}

local defaultData = {
    x = 0.0,
    y = 0.0,

    scrollx = 1.0,
    scrolly = 1.0,
    speedx = 0.0,
    speedy = 0.0,

    alpha = 1.0,
    color = "FFFFFF",

    only = "*",
    exclude = "",

    texture = "",

    flipx = false,
    flipy = false,
    loopx = true,
    loopy = true,

    flag = "",
    notflag = "",

    blendmode = "alphablend",
    instantIn = false,
    instantOut = false,
    fadeIn = false,

    fadex = "",
    fadey = "",

    tag = ""
}

local fieldInformation = {
    color = {
        fieldType = "color"
    },
    blendmode = {
        options = {
            "additive",
            "alphablend"
        },
        editable = false
    },
    texture = {
        fieldType = "path",
        filePickerExtensions = {"png"},
        -- Must be allowed for Misc atlases, for example purplesunset
        -- This means no validation on "invalid" texture, but its good enough for now
        allowMissingPath = true,
        filenameProcessor = function(filename)
            -- Discard leading "Graphics/Atlases/Gui/" and file extension
            local filename, ext = utils.splitExtension(filename)
            local parts = utils.splitpath(filename, "/")

            return utils.convertToUnixPath(utils.joinpath(unpack(parts, 4)))
        end,
        filenameResolver = function(filename, text, prefix)
            return string.format("%s/Graphics/Atlases/Gameplay/%s.png", prefix, text)
        end
    },
}

function parallax.getParallaxNames()
    local res = {}
    local added = {}

    -- Any loaded sprites
    for name, sprite in pairs(atlases.gameplay) do
        if utils.startsWith(name, parallaxTexturePrefix) then
            added[name] = true
            added[sprite.meta.filename] = true

            table.insert(res, name)
        end
    end

    -- Mod content sprites
    -- Some of these might have already been loaded
    local filenames = mods.findModFiletype(parallaxTexturePath, "png")
    local parallaxPathLength = #parallaxTexturePath

    for i, name in ipairs(filenames) do
        if not added[name] then
            local nameNoExt, ext = utils.splitExtension(name)
            if ext == "png" then
                -- Remove mod specific path, keep bgs/ prefix
                local firstSlashIndex = utils.findCharacter(nameNoExt, "/")
                local resourceName = nameNoExt:sub(firstSlashIndex + parallaxPathLength - 2)

                if not added[resourceName] then
                    table.insert(res, resourceName)
                end
            end

            if yield and i % 100 == 0 then
                coroutine.yield()
            end
        end
    end

    return res
end

function parallax.defaultData(style)
    return defaultData
end

function parallax.fieldOrder(style)
    return fieldOrder
end

function parallax.fieldInformation(style)
    return fieldInformation
end

function parallax.canForeground(style)
    return true
end

function parallax.canBackground(style)
    return true
end

function parallax.languageData(language, style)
    return language.style.parallax
end

-- TODO - Language file
function parallax.displayName(language, style)
    local texture = style.texture

    return string.format("Parallax - %s", texture)
end

function parallax.associatedMods(style)
    local texture = style.texture
    local sprite = atlases.gameplay[texture]

    if sprite then
        -- Skip internal files, they don't belong to a mod
        if sprite.internalFile then
            return
        end

        local filename = sprite.filename
        local modMetadata = mods.getModMetadataFromPath(filename)

        return mods.getModNamesFromMetadata(modMetadata)
    end
end

return parallax