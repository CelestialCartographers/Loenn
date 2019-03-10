local drawableSpriteStruct = require("structs/drawable_sprite")
local colors = require("xna_colors")

local introCar = {}

local barrierTexture = "scenery/car/barrier"
local bodyTexture = "scenery/car/body"
local pavementTexture = "scenery/car/pavement"
local wheelsTexture = "scenery/car/wheels"

function introCar.sprite(room, entity)
    local sprites = $()
    local hasRoadAndBarriers = entity.hasRoadAndBarriers

    local bodySprite = drawableSpriteStruct.spriteFromTexture(bodyTexture, entity)
    bodySprite:setJustification(0.5, 1.0)
    bodySprite.depth = 1

    local wheelSprite = drawableSpriteStruct.spriteFromTexture(wheelsTexture, entity)
    wheelSprite:setJustification(0.5, 1.0)
    wheelSprite.depth = 3
    
    sprites += bodySprite
    sprites += wheelSprite

    if hasRoadAndBarriers then
        local barrier1Sprite = drawableSpriteStruct.spriteFromTexture(barrierTexture, entity)
        barrier1Sprite:addPosition(32, 0)
        barrier1Sprite:setJustification(0.0, 1.0)
        barrier1Sprite.depth = -10

        local barrier2Sprite = drawableSpriteStruct.spriteFromTexture(barrierTexture, entity)
        barrier2Sprite:addPosition(41, 0)
        barrier2Sprite:setJustification(0.0, 1.0)
        barrier2Sprite.depth = 5
        barrier2Sprite.color = colors.DarkGray

        sprites += barrier1Sprite
        sprites += barrier2Sprite

        -- TODO - Add pavement
    end

    return sprites
end

return introCar