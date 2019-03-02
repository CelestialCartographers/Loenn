local xml2lua = require("xml2lua.xml2lua")
local utils = require("utils")
local serialization = require("serialization")

local function convertMaskString(s)
    local res = table.filled(0, {3, 3})
    local rows = $(s):split("-")

    for y, row <- rows do
        local rowValues = $(row):map(v -> tonumber(v))

        for x = 1, 3 do
            res[x, y] = rowValues[x]
        end
    end

    return res
end

local function convertTileString(s)
    local res = $()
    local parts = $(s):split(";")

    for i, part <- parts do
        local numbers = $(part):split(",")

        res += {
            tonumber(numbers[1]),
            tonumber(numbers[2])
        }
    end

    return res
end

local function loadTilesetXML(fn)
    local fh = io.open(fn, "rb")

    local handler = require("xml2lua.xmlhandler.tree")
    local parser = xml2lua.parser(handler)
    local xml = utils.stripByteOrderMark(fh:read("*a"))

    parser:parse(xml)

    local paths = {}
    local masks = {}
    local padding = {}
    local center = {}
    local ignores = {}

    -- TODO - sort tilesets that copy others to the end?

    for i, tileset <- handler.root.Data.Tileset do
        local id = tileset._attr.id
        local path = tileset._attr.path
        local copy = tileset._attr.copy
        local ignore = tileset._attr.ignores

        print(id, path, copy, ignore)

        paths[id] = "tilesets/" .. path

        if ignore then
            ignores[id] = ignore
        end

        if copy then
            padding[id] = table.shallowcopy(padding[copy])
            center[id] = table.shallowcopy(center[copy])
            masks[id] = table.shallowcopy(masks[copy])
        end

        currentMasks = $()

        for j, child <- tileset.set or {} do
            local attrs = child._attr or child

            local mask = attrs.mask
            local tiles = attrs.tiles or ""
            local sprites = attrs.sprites or ""

            if mask == "padding" then
                padding[id] = convertTileString(tiles)

            elseif mask == "center" then
                center[id] = convertTileString(tiles)

            else
                currentMasks += {
                    mask = convertMaskString(mask),
                    tiles = convertTileString(tiles),
                    sprites = sprites
                }
            end
        end

        if #currentMasks > 0 then
            masks[id] = currentMasks

            -- TODO - Sort masks by "score"
        end
    end

    fh:close()

    return {
        paths = paths,
        masks = masks,
        center = center,
        padding = padding,
        ignores = ignores
    }
end

return {
    loadTilesetXML = loadTilesetXML
}