local drawableSpriteStruct = require("structs.drawable_sprite")

local springDepth = -8501
local springTexture = "objects/spring/00"

local springUp = {}

springUp.name = "spring"
springUp.placements = {
    name = "up"
}

function springUp.sprite(room, entity)
    local sprite = drawableSpriteStruct.spriteFromTexture(springTexture, entity)

    sprite.depth = springDepth
    sprite:setJustification(0.5, 1.0)

    return sprite
end

local springRight = {}

springRight.name = "wallSpringLeft"
springRight.placements = {
    name = "right"
}

function springRight.sprite(room, entity)
    local sprite = drawableSpriteStruct.spriteFromTexture(springTexture, entity)

    sprite.depth = springDepth
    sprite.rotation = math.pi / 2
    sprite:setJustification(0.5, 1.0)

    return sprite
end

local springLeft = {}

springLeft.name = "wallSpringRight"
springLeft.placements = {
    name = "left"
}

function springLeft.sprite(room, entity)
    local sprite = drawableSpriteStruct.spriteFromTexture(springTexture, entity)

    sprite.depth = springDepth
    sprite.rotation = -math.pi / 2
    sprite:setJustification(0.5, 1.0)

    return sprite
end

return {
    springUp,
    springRight,
    springLeft
}