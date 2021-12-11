local drawableSprite = require("structs.drawable_sprite")
local drawableLine = require("structs.drawable_line")
local utils = require("utils")

local resortPlatforms = {}

local innerColor = {10 / 255, 0 / 255, 6 / 255}
local innerThickness = 1
local innerOffsetX = 2
local innerOffsetY = 1
local innerMagnitudeOffset = 2

local outerColor = {30 / 255, 14 / 255, 25 / 255}
local outerThickness = 3
local outerOffsetX = 2
local outerOffsetY = 2
local outerMagnitudeOffset = 0

local textureLocation = "objects/woodPlatform/%s"

-- Entity and position are both nice to have, as the position can also be a entity node
function resortPlatforms.addPlatformSprites(sprites, entity, position, texture, width)
    texture = texture or string.format(textureLocation, entity.texture or "default")
    width = width or entity.width or 16

    for i = 8, width - 1, 8 do
        local sprite = drawableSprite.fromTexture(texture, position)

        sprite:addPosition(i - 8, 0)
        sprite:useRelativeQuad(8, 0, 8, 8)
        sprite:setJustification(0, 0)

        table.insert(sprites, sprite)
    end

    local leftSprite = drawableSprite.fromTexture(texture, position)
    local rightSprite = drawableSprite.fromTexture(texture, position)
    local middleSprite = drawableSprite.fromTexture(texture, position)

    leftSprite:useRelativeQuad(0, 0, 8, 8)
    leftSprite:setJustification(0, 0)

    rightSprite:useRelativeQuad(25, 0, 8, 8)
    rightSprite:addPosition(width - 8, 0)
    rightSprite:setJustification(0, 0)

    middleSprite:useRelativeQuad(16, 0, 8, 8)
    middleSprite:addPosition(math.floor(width / 2) - 4, 0)
    middleSprite:setJustification(0, 0)

    table.insert(sprites, leftSprite)
    table.insert(sprites, rightSprite)
    table.insert(sprites, middleSprite)

    return sprites
end

function resortPlatforms.addConnectorSprites(sprites, entity, x, y, nodeX, nodeY, width)
    width = width or entity.width or 16

    local halfWidth = math.floor(width / 2)
    local centerX, centerY = x + halfWidth, y + 4
    local centerNodeX, centerNodeY = nodeX + halfWidth, nodeY + 4

    local points = {centerX, centerY, centerNodeX, centerNodeY}

    local outerLine = drawableLine.fromPoints(points, outerColor, outerThickness, outerOffsetX, outerOffsetY, outerMagnitudeOffset)
    local innerLine = drawableLine.fromPoints(points, innerColor, innerThickness, innerOffsetX, innerOffsetY, innerMagnitudeOffset)

    outerLine:setOffset(2, 2)
    outerLine.depth = 9001

    innerLine:setOffset(2, 1)
    innerLine:setMagnitudeOffset(-1)
    innerLine.depth = 9001

    for _, sprite in ipairs(outerLine:getDrawableSprite()) do
        table.insert(sprites, sprite)
    end

    for _, sprite in ipairs(innerLine:getDrawableSprite()) do
        table.insert(sprites, sprite)
    end
end

function resortPlatforms.getSelection(room, entity)
    local x, y = entity.x or 0, entity.y or 0
    local width = entity.width or 16
    local nodes = entity.nodes or {}

    local mainRectangle = utils.rectangle(x, y, width, 8)
    local nodeRectangles = {}

    for i, node in ipairs(nodes) do
        nodeRectangles[i] = utils.rectangle(node.x, node.y, width, 8)
    end

    return mainRectangle, nodeRectangles
end

return resortPlatforms