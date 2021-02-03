local drawableSpriteStruct = require("structs.drawable_sprite")

local cloud = {}

cloud.name = "cloud"
cloud.depth = 0
cloud.placements = {
    {
        name = "normal",
        data = {
            fragile = false,
            small = false
        }
    },
    {
        name = "fragile",
        data = {
            fragile = true,
            small = false
        }
    }
}

local normalScale = 1.0
local smallScale = 29 / 35

local function getTexture(entity)
    local fragile = entity.fragile

    if fragile then
        return "objects/clouds/fragile00"

    else
        return "objects/clouds/cloud00"
    end
end

function cloud.sprite(room, entity)
    local texture = getTexture(entity)
    local sprite = drawableSpriteStruct.spriteFromTexture(texture, entity)
    local small = entity.small
    local scale = small and smallScale or normalScale

    sprite:setScale(scale, 1.0)

    return sprite
end

return cloud