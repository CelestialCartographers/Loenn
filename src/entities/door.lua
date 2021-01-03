local drawableSpriteStruct = require("structs.drawable_sprite")
local utils = require("utils")

local door = {}

local textures = {"wood", "metal"}

door.depth = 8998
door.placements = {}

for i, texture in ipairs(textures) do
    door.placements[i] = {
        name = string.format("Door (%s)", utils.humanizeVariableName(texture)),
        data = {
            ["type"] = texture
        }
    }
end

local function getTexture(entity)
    local variant = entity["type"]

    if variant == "wood" then
        return "objects/door/door00"

    else
        return "objects/door/metaldoor00"
    end
end

function door.sprite(room, entity)
    local texture = getTexture(entity)
    local sprite = drawableSpriteStruct.spriteFromTexture(texture, entity)

    sprite:setJustification(0.5, 1.0)

    return sprite
end

return door