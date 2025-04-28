local xmlHandler = require("lib.xml2lua.xmlhandler.tree")
local xml2lua = require("lib.xml2lua.xml2lua")
local utils = require("utils")
local matrix = require("utils.matrix")
local bit = require("bit")
local utf8 = require("utf8")

local autotiler = {}

-- True for same tile, false for air, nil for any tile
local function convertMaskString(s, width, height)
    local res = matrix.filled(0, width, height)

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
        return not (target == air or ignore[target])
    end

    return target ~= air
end

local function checkMaskFromTiles(mask, checks)
    local halfChecks = math.floor(#checks / 2)

    for i = 1, halfChecks do
        if checks[i] ~= mask[i] and mask[i] ~= nil then
            return false
        end
    end

    for i = halfChecks + 1, #checks do
        if checks[i] ~= mask[i] and mask[i] ~= nil then
            return false
        end
    end

    return true
end

-- Bitwise version of checkMaskFromTiles
local function checkMaskFromTilesWithBitmask(tilemask, bitmask, ignoremask, bxor, band)
    return band(bxor(tilemask, bitmask), ignoremask) == 0
end

local function getTile(tiles, x, y, emptyTile)
    return tiles:get(x, y, emptyTile)
end

local function checkPadding(tiles, x, y, tile, ignores, airTile, emptyTile, wildcard)
    local left = getTile(tiles, x - 2, y, tile)
    local right = getTile(tiles, x + 2, y, tile)
    local up = getTile(tiles, x, y - 2, tile)
    local down = getTile(tiles, x, y + 2, tile)

    -- Special case for tiles with ignores, should treat ignored tiles as "air"
    if ignores and ignores.hasIgnores then
        return not autotiler.checkTile(tile, left, ignores, airTile, wildcard) or
            not autotiler.checkTile(tile, right, ignores, airTile, wildcard) or
            not autotiler.checkTile(tile, up, ignores, airTile, wildcard) or
            not autotiler.checkTile(tile, down, ignores, airTile, wildcard)
    end

    return left == airTile or right == airTile or up == airTile or down == airTile
end

local function getPaddingOrCenterQuad(x, y, tile, tiles, meta, airTile, emptyTile, wildcard, defaultQuad, defaultSprite)
    local ignores = meta[tile].ignores

    if checkPadding(tiles, x, y, tile, ignores, airTile, emptyTile, wildcard) then
        local padding = meta[tile].padding

        return padding and #padding > 0 and padding or defaultQuad, defaultSprite

    else
        local center = meta[tile].center

        return center and #center > 0 and center or defaultQuad, defaultSprite
    end
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


local function getMaskQuadsFromTiles(x, y, masks, tiles, tile, ignore, air, wildcard, checkTile, scanWidth, scanHeight)
    if masks then
        local checkedTiles = {}

        local halfWidth = math.floor(scanWidth / 2)
        local halfHeight = math.floor(scanHeight / 2)

        for offsetY = -halfHeight, halfHeight do
            for offsetX = -halfWidth, halfWidth do
                table.insert(checkedTiles, checkTile(tile, tiles:get(x + offsetX, y + offsetY, tile), ignore, air, wildcard))
            end
        end

        for _, maskData in ipairs(masks) do
            if checkMaskFromTiles(maskData.mask, checkedTiles) then
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
    local tileMeta = meta[tile]

    local masks = tileMeta.masks
    local ignore = tileMeta.ignores

    local scanWidth = tileMeta.scanWidth or 3
    local scanHeight = tileMeta.scanHeight or 3

    local matches, quads, sprites

    if scanWidth == 3 and scanHeight == 3 then
        local lshift = bit.lshift
        local band = bit.band
        local bxor = bit.bxor

        matches, quads, sprites = getMaskQuadsFromTilesWithBitmask(x, y, masks, tiles, tile, ignore, airTile, wildcard, checkTile, lshift, bxor, band)

    else
        matches, quads, sprites = getMaskQuadsFromTiles(x, y, masks, tiles, tile, ignore, airTile, wildcard, checkTile, scanWidth, scanHeight)
    end

    if matches then
        return quads, sprites

    else
        return getPaddingOrCenterQuad(x, y, tile, tiles, meta, airTile, emptyTile, wildcard, defaultQuad, defaultSprite)
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

-- X values are stored as nil in the mask matrix
local function countMaskXs(mask)
    local maskMatrix = mask.mask
    local width, height = maskMatrix:size()
    local count = 0

    for x = 1, width do
        for y = 1, height do
            if maskMatrix:getInbounds(x, y) == nil then
                count += 1
            end
        end
    end

    return count
end

local function maskCompare(lhs, rhs)
    return countMaskXs(lhs) < countMaskXs(rhs)
end

-- Inline mask sort, more X -> later
local function sortTilesetMasks(masks)
    table.sort(masks, maskCompare)

    return masks
end

local function tileStringHashFunction(value)
    return string.format("%s, %s", value[1], value[2])
end

local function getTilesetStructure(id)
    return {
        id = id,
        path = "",
        padding = {},
        center = {},
        masks = {},
        ignores = {}
    }
end

local function readTilesetInfo(tileset, id, element)
    -- Doesn't store single child tags in list, pack it into a table for easier use
    local elementSets = element.set and (#element.set > 0 and element.set or {element.set}) or {}

    for _, child in ipairs(elementSets) do
        local attrs = child._attr or child

        local mask = attrs.mask
        local tiles = attrs.tiles or ""
        local sprites = attrs.sprites or ""

        if mask == "padding" then
            local newPadding = convertTileString(tiles)

            for _, padding in ipairs(newPadding) do
                table.insert(tileset.padding, padding)
            end

            tileset.padding = utils.unique(tileset.padding, tileStringHashFunction)

        elseif mask == "center" then
            local newCenters = convertTileString(tiles)

            for _, center in ipairs(newCenters) do
                table.insert(tileset.center, center)
            end

            tileset.center = utils.unique(tileset.center, tileStringHashFunction)

        else
            local maskMatrix = convertMaskString(mask, tileset.scanWidth, tileset.scanHeight)

            table.insert(tileset.masks, {
                mask = maskMatrix,
                quads = convertTileString(tiles),
                sprites = sprites,
                tilesMask = maskToBitmask(maskMatrix, bit.lshift),
                ignoresMask = maskToIgnoreBitmask(maskMatrix, bit.lshift)
            })
        end
    end

    sortTilesetMasks(tileset.masks)
end

function autotiler.loadTilesetXML(filename)
    local handler = xmlHandler:new()
    local parser = xml2lua.parser(handler)
    local xmlString = utils.readAll(filename, "rb")

    if not xmlString then
        error(string.format("Unable to read tileset xml from '%s'", filename))
    end

    local xml = utils.stripByteOrderMark(xmlString)

    parser:parse(xml)

    local tilesetsMeta =  {}
    local elementLookup = {}
    local tilesetsRoot = handler.root.Data.Tileset

    for _, element in ipairs(tilesetsRoot) do
        local id = element._attr.id

        if utf8.len(id) ~= 1 then
            error(string.format("Invalid ID '%s' for tileset, must be a single character", id))
        end

        local copy = element._attr.copy
        local ignores = element._attr.ignores
        local ignoreExceptions = element._attr.ignoreExceptions
        local path = element._attr.path
        local displayName = element._attr.displayName
        local tileset = getTilesetStructure(id)
        local scanWidth = tonumber(element._attr.scanWidth) or 3
        local scanHeight = tonumber(element._attr.scanHeight) or 3

        tileset.path = "tilesets/" .. path
        tileset.displayName = displayName
        tileset.ignoreExceptions = {}

        tileset.scanWidth = scanWidth
        tileset.scanHeight = scanHeight
        tileset.customScanSize = scanWidth ~= 3 or scanHeight ~= 3

        readTilesetInfo(tileset, id, element)

        if tileset.scanWidth then
            if tileset.scanWidth <= 0 or tileset.scanWidth % 2 ~= 1 then
                error("Custom scan width must be a positive odd number")
            end
        end

        if tileset.scanHeight then
            if tileset.scanHeight <= 0 or tileset.scanHeight % 2 ~= 1 then
                error("Custom scan height must be a positive odd number")
            end
        end

        if copy then
            if not elementLookup[copy] then
                error(string.format("Copied tilesets must be defined before the tileset copying from them: %s copies %s", id, copy))
            end

            readTilesetInfo(tileset, id, elementLookup[copy])
        end

        if ignores then
            local ignoredTiles = $(ignores):split(",")()

            tileset.ignores = table.flip(ignoredTiles)
            tileset.ignores.hasIgnores = #ignoredTiles > 0
        end

        if ignoreExceptions then
            local exceptions = $(ignoreExceptions):split(",")()

            tileset.ignoreExceptions = table.flip(exceptions)
        end

        tilesetsMeta[id] = tileset
        elementLookup[id] = element
    end

    -- Check for ignore wildcards
    for id, tileset in pairs(tilesetsMeta) do
        if tileset.ignores["*"] then
            tileset.ignores["*"] = nil

            -- Add all known tileset ids excluding self
            for ignoreId, _ in pairs(tilesetsMeta) do
                if id ~= ignoreId and not tileset.ignoreExceptions[ignoreId] then
                    tileset.ignores[ignoreId] = true
                end
            end

            tileset.ignores.hasIgnores = true
        end
    end

    return tilesetsMeta
end

return autotiler