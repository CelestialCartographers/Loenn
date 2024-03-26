local utils = require("utils")
local drawableSprite = require("structs.drawable_sprite")
local drawableRectangle = require("structs.drawable_rectangle")
local connectedEntities = require("helpers.connected_entities")

local playbackBillboard = {}

playbackBillboard.name = "playbackBillboard"
playbackBillboard.depth = 9010
playbackBillboard.warnBelowSize = {8, 8}
playbackBillboard.placements = {
    name = "playback_billboard",
    data = {
        width = 8,
        height = 8
    }
}

local fillColor = {0.17, 0.14, 0.33}
local borderTexture = "scenery/tvSlices"

local function getSearchPredicate(entity)
    return function(target)
        return entity._name == target._name
    end
end

local function empty(entity, x, y, rectangles)
    return not connectedEntities.hasAdjacent(entity, x * 8, y * 8, rectangles)
end

local function getTileSprite(entity, x, y, texture, rectangles)
    if empty(entity, x, y, rectangles) then
        local quadX, quadY = false, false

        local centerLeft = not empty(entity, x - 1, y, rectangles)
        local centerRight = not empty(entity, x + 1, y, rectangles)
        local topCenter = not empty(entity, x, y - 1, rectangles)
        local bottomCenter = not empty(entity, x, y + 1, rectangles)
        local topLeft = not empty(entity, x - 1, y - 1, rectangles)
        local topRight = not empty(entity, x + 1, y - 1, rectangles)
        local bottomLeft = not empty(entity, x - 1, y + 1, rectangles)
        local bottomRight = not empty(entity, x + 1, y + 1, rectangles)

        if not centerRight and not bottomCenter and bottomRight then
            quadX, quadY = 0, 0

        elseif not centerLeft and not bottomCenter and bottomLeft then
            quadX, quadY = 16, 0

        elseif not topCenter and not centerRight and topRight then
            quadX, quadY = 0, 16

        elseif not topCenter and not centerLeft and topLeft then
            quadX, quadY = 16, 16

        elseif centerRight and bottomCenter then
            quadX, quadY = 24, 0

        elseif centerLeft and bottomCenter then
            quadX, quadY = 32, 0

        elseif centerRight and topCenter then
            quadX, quadY = 24, 16

        elseif centerLeft and topCenter then
            quadX, quadY = 32, 16

        elseif bottomCenter then
            quadX, quadY = 8, 0

        elseif centerRight then
            quadX, quadY = 0, 8

        elseif centerLeft then
            quadX, quadY = 16, 8

        elseif topCenter then
            quadX, quadY = 8, 16
        end

        if quadX and quadY then
            local sprite = drawableSprite.fromTexture(texture, entity)

            sprite:addPosition(x * 8, y * 8)
            sprite:useRelativeQuad(quadX, quadY, 8, 8, nil, true)

            return sprite
        end
    end
end

local function addTileSprite(sprites, entity, x, y, texture, rectangles)
    local sprite = getTileSprite(entity, x, y, texture, rectangles)

    if sprite then
        table.insert(sprites, sprite)
    end
end

function playbackBillboard.sprite(room, entity)
    local relevantBlocks = utils.filter(getSearchPredicate(entity), room.entities)

    connectedEntities.appendIfMissing(relevantBlocks, entity)

    local rectangles = connectedEntities.getEntityRectangles(relevantBlocks)

    local sprites = {}

    local x, y = entity.x or 0, entity.y or 0
    local width, height = entity.width or 32, entity.height or 32
    local tileWidth, tileHeight = math.ceil(width / 8), math.ceil(height / 8)

    local backgroundRectangle = drawableRectangle.fromRectangle("fill", x, y, width, height, fillColor)

    table.insert(sprites, backgroundRectangle:getDrawableSprite())

    for i = -1, tileWidth do
        addTileSprite(sprites, entity, i, -1, borderTexture, rectangles)
        addTileSprite(sprites, entity, i, tileHeight, borderTexture, rectangles)
    end

    for j = 0, tileHeight - 1 do
        addTileSprite(sprites, entity, -1, j, borderTexture, rectangles)
        addTileSprite(sprites, entity, tileWidth, j, borderTexture, rectangles)
    end

    return sprites
end

return playbackBillboard