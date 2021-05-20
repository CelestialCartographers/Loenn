local drawableRectangle = require("structs.drawable_rectangle")
local drawableSprite = require("structs.drawable_sprite")
local utils = require("utils")

local oshiroDoor = {}

oshiroDoor.name = "oshirodoor"
oshiroDoor.depth = 0
oshiroDoor.fillColor = {74 / 255, 71 / 255, 135 / 255, 153}
oshiroDoor.borderColor = {1.0, 1.0, 1.0, 1.0}
oshiroDoor.placements = {
    name = "oshiro_door"
}

local fillColor = {74 / 255, 71 / 255, 135 / 255, 153}
local borderColor = {1.0, 1.0, 1.0, 1.0}
local oshiroTexture = "characters/oshiro/oshiro24"
local oshiroColor = {1.0, 1.0, 1.0, 0.8}

function oshiroDoor.sprite(room, entity)
    local rectangle = utils.rectangle(entity.x, entity.y, 32, 32)
    local drawableRectangleSprites = drawableRectangle.fromRectangle("bordered", rectangle, fillColor, borderColor):getDrawableSprite()
    local oshiroSprite = drawableSprite.fromTexture(oshiroTexture, entity)

    oshiroSprite:setColor(oshiroColor)
    oshiroSprite:addPosition(16, 16)

    table.insert(drawableRectangleSprites, oshiroSprite)

    return drawableRectangleSprites
end

return oshiroDoor