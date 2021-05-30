local drawableSprite = require("structs.drawable_sprite")
local drawableLine = require("structs.drawable_line")
local utils = require("utils")

local gondola = {}

gondola.name = "gondola"
gondola.depth = -10500
gondola.nodeLimits = {1, 1}
gondola.placements = {
    {
        name = "gondola",
        placementType = "line"
    }
}

local frontTexture = "objects/gondola/front"
local backTexture = "objects/gondola/back"
local topTexture = "objects/gondola/top"
local leverTexture = "objects/gondola/lever01"
local leftTexture = "objects/gondola/cliffsideLeft"
local rightTexture = "objects/gondola/cliffsideRight"

local renderOffsetY = -64

local wireColor = {0, 0, 0, 1}
local wireThickness = 1

function gondola.sprite(room, entity)
    local sprites = {}

    local x, y = entity.x or 0, entity.y or 0
    local nodes = entity.nodes or {{x = 0, y = 0}}
    local nodeX, nodeY = nodes[1].x, nodes[1].y

    local frontSprite = drawableSprite.fromTexture(frontTexture, entity)
    frontSprite:addPosition(0, renderOffsetY)
    frontSprite:setJustification(0.5, 0.0)

    -- Don't rotate, looks weird
    local topSprite = drawableSprite.fromTexture(topTexture, entity)
    topSprite:addPosition(0, renderOffsetY)
    topSprite:setJustification(0.5, 0.0)

    local leverSprite = drawableSprite.fromTexture(leverTexture, entity)
    leverSprite:addPosition(0, renderOffsetY)
    leverSprite:setJustification(0.5, 0.0)

    local backSprite = drawableSprite.fromTexture(backTexture, entity)
    backSprite:addPosition(0, renderOffsetY)
    backSprite:setJustification(0.5, 0.0)
    backSprite.depth = 9000

    local leftSprite = drawableSprite.fromTexture(leftTexture, entity)
    leftSprite:addPosition(-124, 0)
    leftSprite:setJustification(0.0, 1.0)
    leftSprite.depth = 8998

    local rightSprite = drawableSprite.fromTexture(rightTexture, entity)
    rightSprite:addPosition(nodeX - x + 144, nodeY - y - 104)
    rightSprite:setJustification(0.0, 0.5)
    rightSprite:setScale(-1, 1)
    rightSprite.depth = 8998

    local wireLeftX = leftSprite.x + 40
    local wireLeftY = leftSprite.y - 12
    local wireRightX = rightSprite.x - 40
    local wireRightY = rightSprite.y - 4
    local topX = x
    local topY = y + renderOffsetY + topSprite.meta.height

    local leftWire = drawableLine.fromPoints({wireLeftX, wireLeftY, topX, topY}, wireColor, wireThickness)
    local rightWire = drawableLine.fromPoints({wireRightX, wireRightY, topX, topY}, wireColor, wireThickness)

    leftWire.depth = 8999
    rightWire.depth = 8999

    table.insert(sprites, leftWire:getDrawableSprite()[1])
    table.insert(sprites, rightWire:getDrawableSprite()[1])

    table.insert(sprites, frontSprite)
    table.insert(sprites, topSprite)
    table.insert(sprites, leverSprite)
    table.insert(sprites, backSprite)
    table.insert(sprites, leftSprite)
    table.insert(sprites, rightSprite)

    return sprites
end

function gondola.selection(room, entity)
    local x, y = entity.x or 0, entity.y or 0
    local nodes = entity.nodes or {{x = 0, y = 0}}
    local nodeX, nodeY = nodes[1].x, nodes[1].y

    local frontSprite = drawableSprite.fromTexture(frontTexture, entity)
    frontSprite:addPosition(0, renderOffsetY)
    frontSprite:setJustification(0.5, 0.0)

    local topSprite = drawableSprite.fromTexture(topTexture, entity)
    topSprite:addPosition(0, renderOffsetY)
    topSprite:setJustification(0.5, 0.0)

    local rightSprite = drawableSprite.fromTexture(rightTexture, entity)
    rightSprite:addPosition(nodeX - x + 144, nodeY - y - 104)
    rightSprite:setJustification(0.0, 0.5)
    rightSprite:setScale(-1, 1)
    rightSprite.depth = 8998

    local mainRectangle = utils.rectangle(utils.coverRectangles({frontSprite:getRectangle(), topSprite:getRectangle()}))
    local nodeRectangle = rightSprite:getRectangle()

    return mainRectangle, {nodeRectangle}
end

function gondola.nodeSprite(room, entity)
    -- Handled in main sprite function
end

return gondola
