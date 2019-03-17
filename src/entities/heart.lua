local drawableSpriteStruct = require("structs/drawable_sprite")

local heart = {}

-- TODO find depth
heart.depth = -100

local texture = "collectables/heartGem/0/00.png"

function heart.sprite(room, entity)
    return drawableSpriteStruct.spriteFromTexture(texture, entity)
end

return heart