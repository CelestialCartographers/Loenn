local drawableSpriteStruct = require("structs/drawable_sprite")

local function getTexture(entity)
    return entity.twoDash and "objects/refillTwo/idle00" or "objects/refill/idle00"
end

local refill = {}

refill.depth = -100

function refill.sprite(room, entity)
    local texture = getTexture(entity)

    return drawableSpriteStruct.spriteFromTexture(texture, entity)
end

return refill