local utils = require("utils")
local drawableSprite = require("structs.drawable_sprite")

local foregroundDebris = {}

foregroundDebris.name = "foregroundDebris"
foregroundDebris.depth = -999900
foregroundDebris.placements = {
    name = "foreground_debris"
}

local rockTextures = {
    {
        "scenery/fgdebris/rock_a00",
        "scenery/fgdebris/rock_a01",
        "scenery/fgdebris/rock_a02"
    },
    {
        "scenery/fgdebris/rock_b00",
        "scenery/fgdebris/rock_b01"
    }
}

function foregroundDebris.sprite(room, entity)
    utils.setSimpleCoordinateSeed(entity.x, entity.y)

    local index = math.random(1, #rockTextures)
    local sprites = {}

    for i, texture in ipairs(rockTextures[index]) do
        local sprite = drawableSprite.spriteFromTexture(texture, entity)

        sprites[i] = sprite
    end

    return sprites
end

function foregroundDebris.selection(room, entity)
    return utils.rectangle(entity.x - 24, entity.y - 24, 48, 48)
end

return foregroundDebris