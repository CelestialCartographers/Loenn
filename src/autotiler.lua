local xml2lua = require("xml2lua.xml2lua")
local utils = require("utils")
local serialization = require("serialization")

local function convertMaskString(s)
    local res = table.filled(0, {3, 3})
    local raw = s:gsub("x", "2")
    local rows = $(raw):split("-")

    for y, row <- rows do
        local rowValues = $(row):map(v -> tonumber(v))

        for x, value <- rowValues do
            res[x, y] = value
        end
    end

    return res
end

local function checkMask(adjacent, mask)
    for i = 1, 9 do
        if mask[i] ~= 2 then
            if adjacent[i] ~= (mask[i] == 1) then
                return false
            end
        end
    end

    return true
end

local function getTile(tiles, x, y)
    return tiles[x, y] or " "
end

local function checkPadding(tiles, x, y)
    return getTile(tiles, x - 2, y) == "0" or getTile(tiles, x + 2, y) == "0" or getTile(tiles, x, y - 2) == "0" or getTile(tiles, x, y + 2) == "0"
end

local function checkTile(value, target, ignore)
    return not (target == "0" or $(ignore):contains(target) or ($(ignore):contains("*") and value ~= target))
end

local function sortByScore(masks)
    local res = masks

    -- TODO - TBI

    return res
end

local function getQuads(x, y, tiles, meta)
    local tile = tiles[x, y]

    local masks = meta.masks[tile] or {}
    local ignore = meta.ignores[tile] or {}

    local adjacent = tiles[{x - 1, x + 1}, {y - 1, y + 1}]
    adjacent = adjacent:map(target -> checkTile(tile, target, ignore))

    for i, maskData <- masks do
        if checkMask(adjacent, maskData.mask) then
            return maskData.quads, maskData.sprites
        end
    end

    if checkPadding(tiles, x, y) then
        local padding = meta.padding[tile]
        local paddingLength = padding.len and padding:len or #padding

        return paddingLength > 0 and padding or {{0, 0}}, ""

    else
        local center = meta.center[tile]
        local centerLength = center.len and center:len or #center
        
        return centerLength > 0 and center or {{0, 0}}, ""
    end

    return {{5, 12}}, ""
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
    local handler = require("xml2lua.xmlhandler.tree")
    local parser = xml2lua.parser(handler)
    local xml = utils.stripByteOrderMark(utils.readAll(fn, "rb"))

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

        paths[id] = "tilesets/" .. path

        if ignore then
            ignores[id] = ignore
        end

        padding[id] = copy and table.shallowcopy(padding[copy]()) or {}
        center[id] = copy and table.shallowcopy(center[copy]()) or {}
        masks[id] = copy and table.shallowcopy(masks[copy]()) or {}

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
                    quads = convertTileString(tiles),
                    sprites = sprites
                }
            end
        end

        if currentMasks:len > 0 then
            masks[id] = sortByScore(currentMasks)
        end
    end

    return {
        paths = paths,
        masks = masks,
        center = center,
        padding = padding,
        ignores = ignores
    }
end

return {
    loadTilesetXML = loadTilesetXML,
    getQuads = getQuads
}