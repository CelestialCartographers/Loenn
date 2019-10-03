local fakeTilesHelper = {}

function fakeTilesHelper.generateFakeTilesMatrix(room, x, y, material, layer)
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

function fakeTilesHelper.generateFakeTiles(room, x, y, material, layer)
    local fakeTilesMatrix = fakeTilesHelper.generateFakeTilesMatrix(room, x, y, material, layer)
    local fakeTiles = {
        _type = "tiles",
        matrix = fakeTilesMatrix
    }

    return fakeTiles
end

function fakeTilesHelper.generateFakeTilesBatch(room, x, y, fakeTiles, layer)
    local fg = layer == "tilesFg"
    local meta = fg and celesteRender.tilesMetaFg or celesteRender.tilesMetaBg
    local width, height = fakeTiles.matrix:size()
    local random = celesteRender.getRoomRandomMatrix(room, layer)
    local randomSlice = random:getSlice(x - 2, y - 2, x + width - 3, y + height - 3, "0")

    return celesteRender.getTilesBatch(room, fakeTiles, meta, fg, randomSlice)
end

return fakeTilesHelper