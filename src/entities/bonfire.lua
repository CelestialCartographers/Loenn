local drawableSpriteStruct = require("structs.drawable_sprite")

local bonfire = {}

bonfire.depth = -5
bonfire.placements = {
    name = "Bonfire"
}

local function getTexture(entity)
    local mode = entity.mode

    if mode == "lit" then
        return "objects/campfire/fire08"

    elseif mode == "smoking" then
        return "objects/campfire/smoking04"

    else
        return "objects/campfire/fire00"
    end
end

function bonfire.sprite(room, entity)
    local texture = getTexture(entity)
    local sprite = drawableSpriteStruct.spriteFromTexture(texture, entity)

    sprite:setJustification(0.5, 1.0)

    return sprite
end

return bonfire