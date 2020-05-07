local celesteRender = require("celeste_render")
local viewportHandler = require("viewport_handler")
local matrix = require("matrix")
local utils = require("utils")
local autotiler = require("autotiler")
local atlases = require("atlases")

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

-- Has some duplication from celesteRender getTilesBatch for performance reasons
-- needsUpdate set up as {x1, y1, x2, y2, ..., xn, yn} for performance reasons, less table creation than {{x1, y1}, ...}
-- In the material, "0" is considered the tile air, while " " is considered "no change"
-- Does not use placeTilesRaw for performance reasons, and because we explicitly need to track what changed
-- TODO - Check for rendering oddities with matrix brushes
function brushHelper.updateRender(room, x, y, material, layer, randomMatrix)
    local fg = layer == "tilesFg"

    local tiles = room[layer]
    local tilesMatrix = tiles.matrix

    -- Getting upvalues
    local gameplayAtlas = atlases.gameplay
    local cache = celesteRender.tilesSpriteMetaCache
    local autotiler = autotiler
    local meta = fg and celesteRender.tilesMetaFg or celesteRender.tilesMetaBg

    local airTile = "0"
    local emptyTile = " "
    local wildcard = "*"

    local defaultQuad = {{0, 0}}
    local defaultSprite = ""

    local width, height = tilesMatrix:size()
    local addedUpdate = matrix.filled(nil, width, height)
    local needsUpdate = {}

    local random = randomMatrix or celesteRender.getRoomRandomMatrix(room, layer)
    local batch = celesteRender.getRoomCache(room.name, layer).result

    local materialType = utils.typeof(material)

    if materialType == "matrix" then
        local materialWidth, materialHeight = material:size()

        for i = 1, materialWidth do
            for j = 1, materialHeight do
                local tx, ty = x + i - 1, y + j - 1
                local target = tilesMatrix:get(tx, ty, "0")
                local mat = material:getInbounds(i, j)

                if mat ~= target and mat ~= " " then
                    tilesMatrix:set(tx, ty, mat)

                    -- Add the current tile and nearby tiles for redraw
                    addNeighborIfMissing(tx, ty, needsUpdate, addedUpdate)
                    addMissingNeighbors(tx, ty, needsUpdate, addedUpdate)
                end
            end
        end

    else
        local target = tilesMatrix:get(x, y, "0")

        if target ~= material and material ~= " " then
            tilesMatrix:set(x, y, material)

            -- Add the current tile and nearby tiles for redraw
            addNeighborIfMissing(x, y, needsUpdate, addedUpdate)
            addMissingNeighbors(x, y, needsUpdate, addedUpdate)
        end
    end

    local updateIndex = 1

    while updateIndex < #needsUpdate do
        local x, y = needsUpdate[updateIndex], needsUpdate[updateIndex + 1]

        if tilesMatrix:inbounds(x, y) then
            local rng = random:getInbounds(x, y)
            local tile = tilesMatrix:getInbounds(x, y)

            if tile == airTile then
                batch:set(x, y, false)

            else
                -- TODO - Updated overlay sprites
                local quads, sprites = autotiler.getQuads(x, y, tilesMatrix, meta, airTile, emptyTile, wildcard, defaultQuad, defaultSprite)
                local quadCount = #quads

                if quadCount > 0 then
                    local randQuad = quads[utils.mod1(rng, quadCount)]
                    local texture = meta.paths[tile] or emptyTile

                    local spriteMeta = atlases.gameplay[texture]
                    local quad = celesteRender.getOrCacheTileSpriteQuad(cache, tile, texture, randQuad, fg)

                    batch:set(x, y, spriteMeta, quad, x * 8 - 8, y * 8 - 8)
                end
            end
        end

        updateIndex += 2
    end

    return batch
end

function brushHelper.placeTile(room, x, y, material, layer)
    brushHelper.updateRender(room, x, y, material, layer)
end

function brushHelper.getTile(room, x, y, layer)
    local tilesMatrix = room[layer].matrix

    return tilesMatrix:get(x, y, "0")
end

return brushHelper