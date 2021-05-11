local celesteRender = require("celeste_render")
local utils = require("utils")
local matrix = require("matrix")
local drawableSprite = require("structs.drawable_sprite")
local drawableRectangle = require("structs.rectangle")
local colors = require("colors")

local fakeTilesHelper = {}

function fakeTilesHelper.generateFakeTilesMatrix(room, x, y, material, layer, blendIn)
    local materialType = utils.typeof(material)

    local tilesMatrix = nil
    local width, height = 5, 5

    local roomTiles = room[layer].matrix

    if materialType == "matrix" then
        local matrixWidth, matrixHeight = material:size()

        width = matrixWidth + 4
        height = matrixHeight + 4

        tilesMatrix = matrix.filled("0", width, height)

        for tx = 1, matrixWidth do
            for ty = 1, matrixHeight do
                tilesMatrix:setInbounds(tx + 2, ty + 2, material:getInbounds(tx, ty))
            end
        end

    else
        tilesMatrix = matrix.filled(material, width, height)
    end

    if blendIn ~= false then
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
    end

    return tilesMatrix
end

function fakeTilesHelper.generateFakeTiles(room, x, y, material, layer, blendIn)
    local fakeTilesMatrix = fakeTilesHelper.generateFakeTilesMatrix(room, x, y, material, layer, blendIn)
    local fakeTiles = {
        _type = "tiles",
        matrix = fakeTilesMatrix
    }

    return fakeTiles
end

function fakeTilesHelper.getMaterialMatrix(entity, materialKey)
    local material = entity[materialKey]
    local materialType = utils.typeof(material)

    if materialType == "string" then
        local width, height = math.ceil(entity.width / 8), math.ceil(entity.height / 8)

        return matrix.filled(material, width, height)

    elseif materialType == "matrix" then
        return material
    end
end

function fakeTilesHelper.generateFakeTilesBatch(room, x, y, fakeTiles, layer)
    local fg = layer == "tilesFg"
    local tilerMeta = fg and celesteRender.tilesMetaFg or celesteRender.tilesMetaBg
    local width, height = fakeTiles.matrix:size()
    local random = celesteRender.getRoomRandomMatrix(room, layer)
    local randomSlice = random:getSlice(x - 2, y - 2, x + width - 3, y + height - 3, 0)

    return celesteRender.getTilesBatch(room, fakeTiles, tilerMeta, fg, randomSlice, "canvasGrid", false)
end

function fakeTilesHelper.generateFakeTilesSprites(room, x, y, fakeTiles, layer, offsetX, offsetY)
    offsetX = offsetX or 0
    offsetY = offsetY or 0

    local fg = layer == "tilesFg"
    local tilerMeta = fg and celesteRender.tilesMetaFg or celesteRender.tilesMetaBg
    local tileWidth, tileHeight = fakeTiles.matrix:size()
    local width, height = tileWidth * 8, tileHeight * 8
    local random = celesteRender.getRoomRandomMatrix(room, layer)
    local randomSlice = random:getSlice(x - 2, y - 2, x + tileWidth - 3, y + tileHeight - 3, 0)
    local tiles, missingTiles = celesteRender.getTilesBatch(room, fakeTiles, tilerMeta, fg, randomSlice, "table", false)
    local missingColor = fg and colors.tileFGMissingColor or colors.tileBGMissingColor

    local sprites = {}

    for _, tile in ipairs(tiles) do
        local meta, quad, tileX, tileY = tile[1], tile[2], tile[3], tile[4]

        -- Filter out padding pieces for blending
        if tileX > 8 and tileX < width - 16 and tileY > 8 and tileY < height - 16 then
            local sprite = drawableSprite.spriteFromMeta(meta, {
                justificationX = 0.0,
                justificationY = 0.0,
                x = tileX + offsetX - 16,
                y = tileY + offsetY - 16,
                quad = quad
            })

            table.insert(sprites, sprite)
        end
    end

    for _, missing in ipairs(missingTiles) do
        local tileX, tileY = missing[1], missing[2]

        -- Filter out padding pieces for blending
        if tileX > 1 and tileX < tileWidth - 2 and tileY > 1 and tileX < tileHeight - 2 then
            local drawX, drawY = tileX * 8 + offsetX - 16, tileY * 8 + offsetY - 16
            local sprite = drawableRectangle.fromRectangle(drawX, drawY, 8, 8, missingColor)

            table.insert(sprites, sprite)
        end
    end

    return sprites
end

return fakeTilesHelper