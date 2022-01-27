local xml2lua = require("lib.xml2lua.xml2lua")
local utils = require("utils")
local matrix = require("utils.matrix")
local bit = require("bit")

local autotiler = {}

-- True for same tile, false for air, nil for any tile
local function convertMaskString(s)
    local res = matrix.filled(0, 3, 3)

    local raw = s:gsub("x", "2")
    local rows = raw:split("-")

    for y, row <- rows do
        for x, v <- row:split(1) do
            local n = tonumber(v)

            res:set(x, y, (n == 2 ? nil : n == 1))
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

function autotiler.checkTile(value, target, ignore, air, wildcard)
    if ignore then
        return not (target == air or ignore[target] or (ignore[wildcard] and value ~= target))
    end

    return target ~= air
end

-- Unrolled
-- Never need to check index 5, it will always be fine
local function checkMaskFromTiles(mask, a, b, c, d, e, f, g, h, i)
    return not (
        a ~= mask[1] and mask[1] ~= nil or
        b ~= mask[2] and mask[2] ~= nil or
        c ~= mask[3] and mask[3] ~= nil or
        d ~= mask[4] and mask[4] ~= nil or
        f ~= mask[6] and mask[6] ~= nil or
        g ~= mask[7] and mask[7] ~= nil or
        h ~= mask[8] and mask[8] ~= nil or
        i ~= mask[9] and mask[9] ~= nil
    )
end

-- Bitwise version of checkMaskFromTiles
local function checkMaskFromTilesWithBitmask(tilemask, Bitmask, ignoremask, bxor, band)
    return band(bxor(tilemask, Bitmask), ignoremask) == 0
end

local function getTile(tiles, x, y, emptyTile)
    return tiles:get(x, y, emptyTile)
end

local function checkPadding(tiles, x, y, airTile, emptyTile)
    return getTile(tiles, x - 2, y, emptyTile) == airTile or getTile(tiles, x + 2, y, emptyTile) == airTile or getTile(tiles, x, y - 2, emptyTile) == airTile or getTile(tiles, x, y + 2, emptyTile) == airTile
end

local function getPaddingOrCenterQuad(x, y, tile, tiles, meta, airTile, emptyTile, defaultQuad, defaultSprite)
    if checkPadding(tiles, x, y, airTile, emptyTile) then
        local padding = meta.padding[tile]

        return padding and #padding > 0 and padding or defaultQuad, defaultSprite

    else
        local center = meta.center[tile]

        return center and #center > 0 and center or defaultQuad, defaultSprite
    end
end

local function getMaskQuads(masks, adjacent)
    if masks then
        for i, maskData in ipairs(masks) do
            if checkMask(adjacent, maskData.mask) then
                return true, maskData.quads, maskData.sprites
            end
        end
    end

    return false, nil, nil
end

local function getAdjacencyBitmask(x, y, tiles, tile, ignore, air, wildcard, checkTile, lshift)
    return
        lshift(checkTile(tile, tiles:get(x - 1, y - 1, tile), ignore, air, wildcard) and 1 or 0, 7) +
        lshift(checkTile(tile, tiles:get(x + 0, y - 1, tile), ignore, air, wildcard) and 1 or 0, 6) +
        lshift(checkTile(tile, tiles:get(x + 1, y - 1, tile), ignore, air, wildcard) and 1 or 0, 5) +
        lshift(checkTile(tile, tiles:get(x - 1, y + 0, tile), ignore, air, wildcard) and 1 or 0, 4) +
        lshift(checkTile(tile, tiles:get(x + 1, y + 0, tile), ignore, air, wildcard) and 1 or 0, 3) +
        lshift(checkTile(tile, tiles:get(x - 1, y + 1, tile), ignore, air, wildcard) and 1 or 0, 2) +
        lshift(checkTile(tile, tiles:get(x + 0, y + 1, tile), ignore, air, wildcard) and 1 or 0, 1) +
        lshift(checkTile(tile, tiles:get(x + 1, y + 1, tile), ignore, air, wildcard) and 1 or 0, 0)
end

local function maskToBitmask(mask, lshift)
    return
        lshift(mask[1] and 1 or 0, 7) +
        lshift(mask[2] and 1 or 0, 6) +
        lshift(mask[3] and 1 or 0, 5) +
        lshift(mask[4] and 1 or 0, 4) +
        lshift(mask[6] and 1 or 0, 3) +
        lshift(mask[7] and 1 or 0, 2) +
        lshift(mask[8] and 1 or 0, 1) +
        (mask[9] and 1 or 0)
end

local function maskToIgnoreBitmask(mask, lshift)
    return
        lshift(mask[1] ~= nil and 1 or 0, 7) +
        lshift(mask[2] ~= nil and 1 or 0, 6) +
        lshift(mask[3] ~= nil and 1 or 0, 5) +
        lshift(mask[4] ~= nil and 1 or 0, 4) +
        lshift(mask[6] ~= nil and 1 or 0, 3) +
        lshift(mask[7] ~= nil and 1 or 0, 2) +
        lshift(mask[8] ~= nil and 1 or 0, 1) +
        (mask[9] ~= nil and 1 or 0)
end


local function getMaskQuadsFromTiles(x, y, masks, tiles, tile, ignore, air, wildcard, checkTile)
    if masks then
        local a, b, c = checkTile(tile, tiles:get(x - 1, y - 1, tile), ignore, air, wildcard), checkTile(tile, tiles:get(x + 0, y - 1, tile), ignore, air, wildcard), checkTile(tile, tiles:get(x + 1, y - 1, tile), ignore, air, wildcard)
        local d, f = checkTile(tile, tiles:get(x - 1, y + 0, tile), ignore, air, wildcard), checkTile(tile, tiles:get(x + 1, y + 0, tile), ignore, air, wildcard)
        local g, h, i = checkTile(tile, tiles:get(x - 1, y + 1, tile), ignore, air, wildcard), checkTile(tile, tiles:get(x + 0, y + 1, tile), ignore, air, wildcard), checkTile(tile, tiles:get(x + 1, y + 1, tile), ignore, air, wildcard)

        for j, maskData in ipairs(masks) do
            if checkMaskFromTiles(maskData.mask, a, b, c, d, nil, f, g, h, i) then
                return true, maskData.quads, maskData.sprites
            end
        end
    end

    return false, nil, nil
end

local function getMaskQuadsFromTilesWithBitmask(x, y, masks, tiles, tile, ignore, air, wildcard, checkTile, lshift, bxor, band)
    if masks then
        local adjacencyBitmask = getAdjacencyBitmask(x, y, tiles, tile, ignore, air, wildcard, checkTile, lshift)

        for j, maskData in ipairs(masks) do
            if checkMaskFromTilesWithBitmask(adjacencyBitmask, maskData.tilesMask, maskData.ignoresMask, bxor, band) then
                return true, maskData.quads, maskData.sprites
            end
        end
    end

    return false, nil, nil
end

function autotiler.getQuads(x, y, tiles, meta, airTile, emptyTile, wildcard, defaultQuad, defaultSprite, checkTile)
    local tile = tiles:get(x, y)

    local masks = meta.masks[tile]
    local ignore = meta.ignores[tile]

    local matches, quads, sprites = getMaskQuadsFromTiles(x, y, masks, tiles, tile, ignore, airTile, wildcard, checkTile)

    if matches then
        return quads, sprites

    else
        return getPaddingOrCenterQuad(x, y, tile, tiles, meta, airTile, emptyTile, defaultQuad, defaultSprite)
    end
end

function autotiler.getQuadsWithBitmask(x, y, tiles, meta, airTile, emptyTile, wildcard, defaultQuad, defaultSprite, checkTile, lshift, bxor, band)
    local tile = tiles:get(x, y)

    local masks = meta.masks[tile]
    local ignore = meta.ignores[tile]

    local matches, quads, sprites = getMaskQuadsFromTilesWithBitmask(x, y, masks, tiles, tile, ignore, airTile, wildcard, checkTile, lshift, bxor, band)

    if matches then
        return quads, sprites

    else
        return getPaddingOrCenterQuad(x, y, tile, tiles, meta, airTile, emptyTile, defaultQuad, defaultSprite)
    end
end

local function convertTileString(s)
    local res = {}
    local parts = $(s):split(";")

    for i, part <- parts do
        local numbers = $(part):split(",")

        table.insert(res, {
            tonumber(numbers[1]),
            tonumber(numbers[2])
        })
    end

    return res
end

function autotiler.loadTilesetXML(fn)
    local handler = require("lib.xml2lua.xmlhandler.tree")
    local parser = xml2lua.parser(handler)
    local xml = utils.stripByteOrderMark(utils.readAll(fn, "rb"))

    parser:parse(xml)

    local paths = {}
    local masks = {}
    local padding = {}
    local center = {}
    local ignores = {}

    local lshift = bit.lshift

    for i, tileset in ipairs(handler.root.Data.Tileset) do
        local id = tileset._attr.id
        local path = tileset._attr.path
        local copy = tileset._attr.copy
        local ignore = tileset._attr.ignores

        paths[id] = "tilesets/" .. path

        if ignore then
            -- TODO - Check assumption, none of the XML files have mutliple ignores without wildcard
            ignores[id] = table.flip($(ignore):split(";"))
        end

        padding[id] = copy and table.shallowcopy(padding[copy]) or {}
        center[id] = copy and table.shallowcopy(center[copy]) or {}
        masks[id] = copy and table.shallowcopy(masks[copy]) or {}

        local currentMasks = {}

        -- Doesn't store single child tags in list, pack it into a table for easier use
        local tilesetSets = tileset.set and (#tileset.set > 0 and tileset.set or {tileset.set}) or {}

        for j, child in ipairs(tilesetSets) do
            local attrs = child._attr or child

            local mask = attrs.mask
            local tiles = attrs.tiles or ""
            local sprites = attrs.sprites or ""

            if mask == "padding" then
                padding[id] = convertTileString(tiles)

            elseif mask == "center" then
                center[id] = convertTileString(tiles)

            else
                local maskMatrix = convertMaskString(mask)

                table.insert(currentMasks, {
                    mask = maskMatrix,
                    quads = convertTileString(tiles),
                    sprites = sprites,
                    tilesMask = maskToBitmask(maskMatrix, lshift),
                    ignoresMask = maskToIgnoreBitmask(maskMatrix, lshift)
                })
            end
        end

        if #currentMasks > 0 then
            masks[id] = currentMasks
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

return autotiler