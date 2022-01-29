local utils = require("utils")
local drawing = require("utils.drawing")
local drawableSprite = require("structs.drawable_sprite")

local bridgeSprite = "scenery/bridge"
local bridgeSizes = {
    utils.rectangle(0, 0, 16, 55),
    utils.rectangle(16, 0, 8, 55),
    utils.rectangle(24, 0, 8, 55),
    utils.rectangle(32, 0, 8, 55),
    utils.rectangle(40, 0, 8, 55),
    utils.rectangle(48, 0, 8, 55),
    utils.rectangle(56, 0, 8, 55),
    utils.rectangle(64, 0, 8, 55),
    utils.rectangle(72, 0, 8, 55),
    utils.rectangle(80, 0, 16, 55),
    utils.rectangle(96, 0, 8, 55)
}

local function addBridgeTileSprites(sprites, x, y, size)
    if size.width == 16 then
        local height = 24
        local py = 0

        while py < size.height do
            local sprite = drawableSprite.fromTexture(bridgeSprite)

            sprite:useRelativeQuad(size.x, py, size.width, height)
            sprite:setJustification(0.0, 0.0)
            sprite:addPosition(x, y + py - 3)

            table.insert(sprites, sprite)

            py += height
            height = 12
        end

    else
        local sprite = drawableSprite.fromTexture(bridgeSprite)

        sprite:useRelativeQuad(size.x, size.y, size.width, size.height)
        sprite:setJustification(0.0, 0.0)
        sprite:addPosition(x, y - 3)

        table.insert(sprites, sprite)
    end

    return sprites
end

local function bridgeSelectionWidth(entity)
    local x, y = entity.x or 0, entity.y or 0
    local px, py = x, y
    local width = entity.width or 32
    local nodes = entity.nodes or {}

    if #nodes == 2 then
        utils.setSimpleCoordinateSeed(entity.x, entity.y)

        local index = 1

        while px < x + width do
            local tileSize = (index < 3 or index > 8) and bridgeSizes[index] or bridgeSizes[3 + math.random(0, 6)]

            px += tileSize.width
            index = utils.mod1(index + 1, #bridgeSizes)
        end
    end

    return px - x
end

local bridge = {}

bridge.name = "bridge"
bridge.depth = 0
bridge.nodeLimits = {2, 2}
bridge.placements = {
    name = "bridge",
    data = {
        width = 32
    }
}

function bridge.sprite(room, entity)
    local x, y = entity.x or 0, entity.y or 0
    local width = entity.width or 32
    local nodes = entity.nodes or {}
    local sprites = {}

    if #nodes == 2 then
        utils.setSimpleCoordinateSeed(entity.x, entity.y)

        local gapStartX = nodes[1].x
        local gapEndX = nodes[2].x

        local index = 1
        local px, py = x, y

        while px < x + width do
            local tileSize = (index < 3 or index > 8) and bridgeSizes[index] or bridgeSizes[3 + math.random(0, 6)]

            if px < gapStartX or px >= gapEndX then
                addBridgeTileSprites(sprites, px, py, tileSize)
            end

            px += tileSize.width
            index = utils.mod1(index + 1, #bridgeSizes)
        end
    end

    return sprites
end

function bridge.selection(room, entity)
    local sprite = drawableSprite.fromTexture(bridgeSprite)
    local x, y = entity.x or 0, entity.y or 0
    local nodes = entity.nodes or {}

    if #nodes == 2 then
        local gapStartX = nodes[1].x
        local gapEndX = nodes[2].x
        local bridgeWidth = bridgeSelectionWidth(entity)

        local mainRectangle = utils.rectangle(x, y - 3, bridgeWidth, sprite.meta.height)
        local nodeRectangles = {
            utils.rectangle(gapStartX - 4, y - 16, 8, 32),
            utils.rectangle(gapEndX - 4, y - 16, 8, 32)
        }

        return mainRectangle, nodeRectangles
    end
end

function bridge.drawSelected(room, layer, entity, color)
    local x, y = entity.x or 0, entity.y or 0
    local nodes = entity.nodes or {}

    if #nodes == 2 then
        local gapStartX = nodes[1].x
        local gapEndX = nodes[2].x

        drawing.callKeepOriginalColor(function()
            love.graphics.setColor(1.0, 0.0, 0.0, 1.0)

            love.graphics.rectangle("fill", gapStartX, y - 16, 1, 32)
            love.graphics.rectangle("fill", gapEndX, y - 16, 1, 32)
        end)
    end
end

return bridge