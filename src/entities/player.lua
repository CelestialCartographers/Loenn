local drawableSpriteStruct = require("structs.drawable_sprite")

local player = {}

player.depth = 0
player.placements = {
    name = "player"
}

local texture = "characters/player/sitDown00"

function player.sprite(room, entity)
    local playerSprite = drawableSpriteStruct.spriteFromTexture(texture, entity)
    playerSprite:setJustification(0.5, 1.0)

    return playerSprite
end

return player