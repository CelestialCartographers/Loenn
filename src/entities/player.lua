local entities = require("entities")

local player = {}

player.name = "player"

function player.sprite(room, entity)
    local data = {
        x = entity.x,
        y = entity.y,

        jx = 0.5,
        jy = 1.0
    }
    
    local texture = "characters/player/sitDown00"

    return entities.spriteFromTexture(texture, data)
end

return player