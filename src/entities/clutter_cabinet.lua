local drawableSprite = require("structs.drawable_sprite")

local clutterCabinet = {}

clutterCabinet.name = "clutterCabinet"
clutterCabinet.depth = -10001
clutterCabinet.justification = {0.5, 0.5}
clutterCabinet.placements = {
    name = "cabinet"
}

local texture = "objects/resortclutter/cabinet00"

function clutterCabinet.sprite(room, entity)
    local sprite = drawableSprite.spriteFromTexture(texture, entity)

    sprite:addPosition(8, 8)

    return sprite
end

return clutterCabinet