local drawableSprite = require("structs.drawable_sprite")
local drawableLine = require("structs.drawable_line")
local utils = require("utils")

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

local function addPlatformSprites(sprites, entity, texture, x, y, width)
    for i = 8, width - 1, 8 do
        local sprite = drawableSprite.fromTexture(texture, entity)

        sprite:addPosition(i - 8, 0)
        sprite:useRelativeQuad(8, 0, 8, 8)
        sprite:setJustification(0, 0)

        table.insert(sprites, sprite)
    end

    local leftSprite = drawableSprite.fromTexture(texture, entity)
    local rightSprite = drawableSprite.fromTexture(texture, entity)
    local middleSprite = drawableSprite.fromTexture(texture, entity)

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

local function addConnectorSprites(sprites, entity, x, y, nodeX, nodeY, width)
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

local textures = {
    "default", "cliffside"
}

local movingPlatform = {}

movingPlatform.name = "movingPlatform"
movingPlatform.depth = 1
movingPlatform.placements = {}

for i, texture in ipairs(textures) do
    movingPlatform.placements[i] = {
        name = texture,
        data = {
            width = 16,
            texture = texture
        }
    }
end

function movingPlatform.sprite(room, entity)
    local sprites = {}

    local x, y = entity.x or 0, entity.y or 0
    local nodes = entity.nodes or {{x = 0, y = 0}}
    local nodeX, nodeY = nodes[1].x, nodes[1].y
    local width = entity.width or 16
    local variant = entity.texture or "default"
    local texture = "objects/woodPlatform/" .. variant

    addConnectorSprites(sprites, entity, x, y, nodeX, nodeY, width)
    addPlatformSprites(sprites, entity, texture, x, y, width)

    return sprites
end

function movingPlatform.nodeSprite(room, entity)
    local sprites = {}

    local nodes = entity.nodes or {{x = 0, y = 0}}
    local nodeX, nodeY = nodes[1].x, nodes[1].y
    local width = entity.width or 16
    local variant = entity.texture or "default"
    local texture = "objects/woodPlatform/" .. variant

    addPlatformSprites(sprites, entity, texture, nodeX, nodeY, width)

    return sprites
end

function movingPlatform.selection(room, entity)
    local x, y = entity.x or 0, entity.y or 0
    local width = entity.width or 16
    local nodes = entity.nodes or {{x = 0, y = 0}}
    local nodeX, nodeY = nodes[1].x, nodes[1].y

    local mainRectangle = utils.rectangle(x, y, width, 8)
    local nodeRectangle = utils.rectangle(nodeX, nodeY, width, 8)

    return mainRectangle, {nodeRectangle}
end

local sinkingPlatform = {}

sinkingPlatform.name = "sinkingPlatform"
sinkingPlatform.depth = 1
sinkingPlatform.placements = {}

for i, texture in ipairs(textures) do
    sinkingPlatform.placements[i] = {
        name = texture,
        data = {
            width = 16,
            texture = texture
        }
    }
end

function sinkingPlatform.sprite(room, entity)
    local sprites = {}

     -- Prevent visual oddities with too long lines
    local x, y = entity.x or 0, entity.y or 0
    local nodeY = room.height - 2

    local width = entity.width or 16
    local variant = entity.texture or "default"
    local texture = "objects/woodPlatform/" .. variant

    if y > nodeY then
        nodeY = y
    end

    addConnectorSprites(sprites, entity, x, y, x, nodeY, width)
    addPlatformSprites(sprites, entity, texture, x, y, width)

    return sprites
end

function sinkingPlatform.rectangle(room, entity)
    local x, y = entity.x or 0, entity.y or 0
    local width = entity.width or 16

    return utils.rectangle(x, y, width, 8)
end


return {
    movingPlatform,
    sinkingPlatform
}