local drawableRectangle = require("structs.drawable_rectangle")
local drawableSprite = require("structs.drawable_sprite")
local utils = require("utils")

local clutterDoor = {}

clutterDoor.name = "clutterDoor"
clutterDoor.depth = 0
clutterDoor.fillColor = {74 / 255, 71 / 255, 135 / 255, 153}
clutterDoor.borderColor = {1.0, 1.0, 1.0, 1.0}
clutterDoor.placements = {}

local variants = {"red", "yellow", "green"}

for i, variant in ipairs(variants) do
    clutterDoor.placements[i] = {
        name = variant,
        data = {
            width = 24,
            height = 24,
            ["type"] = variant
        }
    }
end

local fillColor = {74 / 255, 71 / 255, 135 / 255, 153}
local borderColor = {1.0, 1.0, 1.0, 1.0}

function clutterDoor.sprite(room, entity)
    local variant = entity["type"] or "red"
    local width, height = entity.width or 24, entity.height or 24

    local rectangle = utils.rectangle(entity.x, entity.y, width, height)
    local drawableRectangleSprites = drawableRectangle.fromRectangle("bordered", rectangle, fillColor, borderColor):getDrawableSprite()
    local doorTexture = string.format("objects/resortclutter/icon_%s", string.lower(variant))
    local doorSprite = drawableSprite.spriteFromTexture(doorTexture, entity)

    doorSprite:addPosition(math.floor(width / 2), math.floor(height / 2))

    table.insert(drawableRectangleSprites, doorSprite)

    return drawableRectangleSprites
end

return clutterDoor