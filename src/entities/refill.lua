local entities = require("entities")

local function getTexture(entity)
    return entity.twoDash and "objects/refillTwo/idle00" or "objects/refill/idle00"
end

refill = {}

refill.depth = -100

function refill.sprite(room, entity)
    local texture = getTexture(entity)

    return entities.spriteFromTexture(texture, entity)
end

return refill