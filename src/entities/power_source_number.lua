local drawableSprite = require("structs.drawable_sprite")

local powerSourceNumber = {}

powerSourceNumber.name = "powerSourceNumber"
powerSourceNumber.depth = -10010
powerSourceNumber.placements = {
    name = "power_source_number",
    data = {
        number = 1,
        strawberries = "",
        keys = ""
    }
}

local numberTexture = "scenery/powersource_numbers/1"
local glowTexture = "scenery/powersource_numbers/1_glow"

function powerSourceNumber.sprite(room, entity)
    local numberSprite = drawableSprite.fromTexture(numberTexture, entity)
    local glowSprite = drawableSprite.fromTexture(glowTexture, entity)

    local sprites = {
        numberSprite,
        glowSprite
    }

    return sprites
end


return powerSourceNumber