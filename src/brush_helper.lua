local celesteRender = require("celeste_render")
local viewportHandler = require("viewport_handler")
local matrix = require("matrix")
local utils = require("utils")

local brushHelper = {}

-- Returns true if the placement happened, false otherwise
-- This version does not update the drawing, only set the data
-- TODO - Support matrix of materials when Rectangle tool is made
function brushHelper.placeTileRaw(room, x, y, material, layer)
    local tilesMatrix = room[layer].matrix

    tilesMatrix:set(x, y, material)

    return tilesMatrix:inbounds(x, y)
end

function brushHelper.generateFakeTilesMatrix(room, x, y, material, layer)
    local typ = utils.typeof(material)

    local tilesMatrix = nil
    local width, height = 5, 5

    local roomTiles = room[layer].matrix

    if typ == "matrix" then
        local matrixWidth, matrixHeight = material:size()

        width = matrixWidth + 4
        height = matrixHeight + 4

        tilesMatrix = matrix.filled("0", width, height)

        for tx = 1, matrixWidth do
            for ty = 1, matrixHeight do
                tilesMatrix:setInbounds(tx + 1, ty + 1, material:getInbounds(tx, ty))
            end
        end

    else
        tilesMatrix = matrix.filled(material, width, height)
    end

    for ox = 1, width do
        tilesMatrix:setInbounds(ox, 1, roomTiles:get(x + ox - 3, y - 2, "0"))
        tilesMatrix:setInbounds(ox, 2, roomTiles:get(x + ox - 3, y - 1, "0"))

        tilesMatrix:setInbounds(ox, height, roomTiles:get(x + ox - 3, y + height - 3, "0"))
        tilesMatrix:setInbounds(ox, height - 1, roomTiles:get(x + ox - 3, y + height - 4, "0"))
    end

    for oy = 3, height - 2 do
        tilesMatrix:setInbounds(1, oy, roomTiles:get(x - 2, y + oy - 3, "0"))
        tilesMatrix:setInbounds(2, oy, roomTiles:get(x - 1, y + oy - 3, "0"))

        tilesMatrix:setInbounds(width, oy, roomTiles:get(x + width - 3, y + oy - 3, "0"))
        tilesMatrix:setInbounds(width - 1, oy, roomTiles:get(x + width - 4, y + oy - 3, "0"))
    end

    return tilesMatrix
end

function brushHelper.generateFakeTiles(room, x, y, material, layer)
    local fakeTilesMatrix = brushHelper.generateFakeTilesMatrix(room, x, y, material, layer)
    local fakeTiles = {
        _type = "tiles",
        matrix = fakeTilesMatrix
    }

    return fakeTiles
end

function brushHelper.generateFakeTilesBatch(room, fakeTiles, layer)
    local fg = layer == "tilesFg"
    local meta = fg and celesteRender.tilesMetaFg or celesteRender.tilesMetaBg

    return celesteRender.getTilesBatch(room, fakeTiles, meta, fg)
end

-- TODO - This doesn't use the same random quads as the initial render would
-- Making it inconsistent, and also wasting time on unneeded rerendering
function brushHelper.updateRender(room, x, y, material, layer)
    local batch = celesteRender.getRoomCache(room.name, layer).result

    local fakeTiles = brushHelper.generateFakeTiles(room, x, y, material, layer)
    local fakeBatch = brushHelper.generateFakeTilesBatch(room, fakeTiles, layer)

    local width, height = fakeBatch._matrix:size()

    for ox = 2, width - 1 do
        for oy = 2, height - 1 do
            local value = fakeBatch:get(ox, oy)
            local tx, ty = x + ox - 3, y + oy - 3

            if value then
                local meta, quad = unpack(value)

                batch:set(tx, ty, meta, quad, tx * 8 - 8, ty * 8 - 8)

            else
                batch:set(tx, ty, false)
            end
        end
    end

    if batch.process then 
        batch:process()
    end
end

function brushHelper.placeTile(room, x, y, material, layer)
    if brushHelper.placeTileRaw(room, x, y, material, layer) then
        brushHelper.updateRender(room, x, y, material, layer)
    end
end

function brushHelper.getTile(room, x, y, layer)
    local tilesMatrix = room[layer].matrix

    return tilesMatrix:get(x, y, "0")
end

return brushHelper