local celesteRender = require("celeste_render")
local matrix = require("utils.matrix")
local utils = require("utils")
local autotiler = require("autotiler")
local atlases = require("atlases")
local bit = require("bit")

local brushHelper = {}

-- Returns true if a placement happened, false otherwise
-- A placement doesn't happen if the tile is the same as the brush, it is out of bounds or it is " "
-- This version does not update the drawing, only set the data
-- In the material, "0" is considered the tile air, while " " is considered "no change"
function brushHelper.placeTileRaw(room, x, y, material, layer)
    local tilesMatrix = room[layer].matrix
    local materialType = utils.typeof(material)

    if materialType == "matrix" then
        local res = false
        local materialWidth, materialHeight = material:size()

        for i = 1, materialWidth do
            for j = 1, materialHeight do
                local tx, ty = x + i - 1, y + j - 1
                local target = tilesMatrix:get(tx, ty, "0")
                local mat = material:getInbounds(i, j)

                if mat ~= target and mat ~= " " then
                    tilesMatrix:set(tx, ty, mat)

                    res = res or tilesMatrix:inbounds(tx, ty)
                end
            end
        end

        return res

    else
        local target = tilesMatrix:get(x, y, "0")

        if target ~= material and material ~= " " then
            tilesMatrix:set(x, y, material)

            return tilesMatrix:inbounds(x, y)
        end
    end
end

local function addNeighborIfMissing(x, y, needsUpdate, addedUpdate)
    if not addedUpdate:get(x, y) then
        table.insert(needsUpdate, x)
        table.insert(needsUpdate, y)

        addedUpdate:set(x, y, true)
    end
end

-- Inlined for 3x3 tilesets
local function addMissingNeighbors(x, y, needsUpdate, addedUpdate)
    -- Around the target tile
    addNeighborIfMissing(x - 1, y - 1, needsUpdate, addedUpdate)
    addNeighborIfMissing(x, y - 1, needsUpdate, addedUpdate)
    addNeighborIfMissing(x + 1, y - 1, needsUpdate, addedUpdate)

    addNeighborIfMissing(x - 1, y, needsUpdate, addedUpdate)
    addNeighborIfMissing(x + 1, y, needsUpdate, addedUpdate)

    addNeighborIfMissing(x - 1, y + 1, needsUpdate, addedUpdate)
    addNeighborIfMissing(x, y + 1, needsUpdate, addedUpdate)
    addNeighborIfMissing(x + 1, y + 1, needsUpdate, addedUpdate)

    -- Tiles used to check for center/padding
    addNeighborIfMissing(x + 2, y, needsUpdate, addedUpdate)
    addNeighborIfMissing(x - 2, y, needsUpdate, addedUpdate)

    addNeighborIfMissing(x, y + 2, needsUpdate, addedUpdate)
    addNeighborIfMissing(x, y - 2, needsUpdate, addedUpdate)
end

local function addMissingNeighborsCustomSize(x, y, tileMeta, needsUpdate, addedUpdate)
    local scanWidth, scanHeight = tileMeta.scanWidth, tileMeta.scanHeight
    local offsetX, offsetY = math.floor(scanWidth / 2), math.floor(scanHeight / 2)

    -- Around the target tile
    for tx = x - offsetX, x + offsetX do
        for ty = y - offsetY, y + offsetY do
            addNeighborIfMissing(tx, ty, needsUpdate, addedUpdate)
        end
    end

    -- Tiles used to check for center/padding
    addNeighborIfMissing(x + offsetX + 1, y, needsUpdate, addedUpdate)
    addNeighborIfMissing(x - offsetX - 1, y, needsUpdate, addedUpdate)

    addNeighborIfMissing(x, y + offsetY + 1, needsUpdate, addedUpdate)
    addNeighborIfMissing(x, y - offsetY - 1, needsUpdate, addedUpdate)
end

-- Has some duplication from celesteRender getTilesBatch for performance reasons
-- needsUpdate set up as {x1, y1, x2, y2, ..., xn, yn} for performance reasons, less table creation than {{x1, y1}, ...}
-- In the material, "0" is considered the tile air, while " " is considered "no change"
-- Does not use placeTilesRaw for performance reasons, and because we explicitly need to track what changed
function brushHelper.updateRender(room, x, y, material, layer, randomMatrix)
    local fg = layer == "tilesFg"

    local tiles = room[layer]
    local tilesMatrix = tiles.matrix

    -- Getting upvalues
    local gameplayAtlas = atlases.gameplay
    local cache = celesteRender.tilesSpriteMetaCache
    local autotiler = autotiler
    local meta = fg and celesteRender.tilesMetaFg or celesteRender.tilesMetaBg
    local scenery = fg and room.sceneryFg or room.sceneryBg
    local checkTile = autotiler.checkTile
    local lshift = bit.lshift
    local bxor = bit.bxor
    local band = bit.band

    local airTile = "0"
    local emptyTile = " "
    local wildcard = "*"

    local defaultQuad = {{0, 0}}
    local defaultSprite = ""

    local width, height = tilesMatrix:size()
    local addedUpdate = matrix.filled(nil, width, height)
    local needsUpdate = {}

    local random = randomMatrix or celesteRender.getRoomRandomMatrix(room, layer)
    local roomCache = celesteRender.getRoomCache(room.name, layer)
    local batch = roomCache and roomCache.result

    local sceneryMatrix = scenery and scenery.matrix or matrix.filled(-1, width, height)
    local sceneryMeta = celesteRender.getSceneryMeta()

    if not batch then
        return false
    end

    local materialType = utils.typeof(material)

    if materialType == "matrix" then
        local materialWidth, materialHeight = material:size()
        local tilesWidth, tilesHeight = tilesMatrix:size()

        for i = 1, materialWidth do
            for j = 1, materialHeight do
                local tx, ty = x + i - 1, y + j - 1

                if tx >= 1 and ty >= 1 and tx <= tilesWidth and ty <= tilesHeight then
                    local target = tilesMatrix:get(tx, ty, " ")
                    local mat = material:getInbounds(i, j)

                    if mat ~= target and mat ~= " " then
                        tilesMatrix:set(tx, ty, mat)

                        -- Add the current tile and nearby tiles for redraw
                        -- Use inlined for 3x3 tilesets
                        if not meta[mat] or not meta[mat].customScanSize then
                            addNeighborIfMissing(tx, ty, needsUpdate, addedUpdate)
                            addMissingNeighbors(tx, ty, needsUpdate, addedUpdate)

                        else
                            addMissingNeighborsCustomSize(tx, ty, meta[mat], needsUpdate, addedUpdate)
                        end
                    end
                end
            end
        end

    else
        local target = tilesMatrix:get(x, y, "0")

        if target ~= material and material ~= " " then
            tilesMatrix:set(x, y, material)

            -- Add the current tile and nearby tiles for redraw
            -- Use inlined for 3x3 tilesets
            if not meta[material] or not meta[material].customScanSize then
                addNeighborIfMissing(x, y, needsUpdate, addedUpdate)
                addMissingNeighbors(x, y, needsUpdate, addedUpdate)

            else
                addMissingNeighborsCustomSize(x, y, meta[material], needsUpdate, addedUpdate)
            end
        end
    end

    local updateIndex = 1
    local missingTiles = {}

    while updateIndex < #needsUpdate do
        local x, y = needsUpdate[updateIndex], needsUpdate[updateIndex + 1]

        if tilesMatrix:inbounds(x, y) then
            local rng = random:getInbounds(x, y)
            local tile = tilesMatrix:getInbounds(x, y)
            local sceneryTile = sceneryMatrix:getInbounds(x, y) or -1

            if sceneryTile > -1 then
                local quad = celesteRender.getOrCacheScenerySpriteQuad(sceneryTile)

                if quad then
                    batch:set(x, y, sceneryMeta, quad, x * 8 - 8, y * 8 - 8)
                end

            elseif tile == airTile then
                batch:remove(x, y, sceneryMeta)

            else
                -- TODO - Update overlay sprites
                local tileMeta = meta[tile]

                if tileMeta and tileMeta.path then
                    local quads, sprites = autotiler.getQuads(x, y, tilesMatrix, meta, airTile, emptyTile, wildcard, defaultQuad, defaultSprite, checkTile, lshift, bxor, band)
                    local quadCount = #quads

                    if quadCount > 0 then
                        local randQuad = quads[utils.mod1(rng, quadCount)]
                        local texture = meta[tile].path or emptyTile

                        local spriteMeta = atlases.gameplay[texture]

                        if spriteMeta then
                            local quad = celesteRender.getOrCacheTileSpriteQuad(cache, tile, texture, randQuad, fg)

                            batch:set(x, y, spriteMeta, quad, x * 8 - 8, y * 8 - 8)
                        end
                    end

                else
                    table.insert(missingTiles, {x, y})
                end
            end
        end

        updateIndex += 2
    end

    celesteRender.drawInvalidTiles(batch, missingTiles, fg)

    return batch
end

function brushHelper.placeTile(room, x, y, material, layer)
    brushHelper.updateRender(room, x, y, material, layer)
end

function brushHelper.getTile(room, x, y, layer)
    local tilesMatrix = room[layer].matrix

    return tilesMatrix:get(x, y, "0")
end

function brushHelper.getTilerMeta(layer)
    local tilerMeta = layer == "tilesFg" and celesteRender.tilesMetaFg or celesteRender.tilesMetaBg

    return tilerMeta
end

function brushHelper.getValidTiles(layer, addAir)
    local tilerMeta = brushHelper.getTilerMeta(layer)
    local paths = {}

    for id, tileset in pairs(tilerMeta) do
        paths[id] = tileset.path
    end

    if addAir ~= false then
        paths["0"] = "Air"
    end

    return paths
end

function brushHelper.cleanMaterialPath(path, layer, displayName)
    if displayName then
        return displayName
    end

    -- Remove path and humanize just the filename

    path = utils.filename(utils.convertToUnixPath(path), "/") or path

    if layer == "tilesBg" then
        path = path:match("^bg(.*)") or path
    end

    return utils.humanizeVariableName(path)
end

function brushHelper.getMaterialLookup(layer, addAir)
    local lookup = {}
    local tilesets = brushHelper.getTilerMeta(layer)

    for id, tileset in pairs(tilesets) do
        local cleanPath = brushHelper.cleanMaterialPath(tileset.path, layer, tileset.displayName)

        lookup[cleanPath] = id
    end

    if addAir ~= false then
        lookup["Air"] = "0"
    end

    return lookup
end

return brushHelper