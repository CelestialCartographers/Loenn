local drawableSpriteStruct = require("structs.drawable_sprite")

local heart = {}

heart.depth = -2000000
heart.placements = {
    "Crystal Heart"
}

local texture = "collectables/heartGem/0/00"

function heart.sprite(room, entity)
    return drawableSpriteStruct.spriteFromTexture(texture, entity)
end

return heart