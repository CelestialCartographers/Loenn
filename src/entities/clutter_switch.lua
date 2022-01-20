local drawableSprite = require("structs.drawable_sprite")
local utils = require("utils")

local clutterSwitch = {}

local variants = {"red", "yellow", "green", "lightning"}
local variantOptions = {
    Laundry = "red",
    Books = "green",
    Boxes = "yellow",
    Lightning = "lightning"
}

clutterSwitch.name = "colorSwitch"
clutterSwitch.depth = 0
clutterSwitch.fieldInformation = {
    type = {
        options = variantOptions,
        editable = false
    }
}
clutterSwitch.placements = {}

for i, variant in ipairs(variants) do
    clutterSwitch.placements[i] = {
        name = variant,
        data = {
            ["type"] = variant
        }
    }
end

local buttonTexture = "objects/resortclutter/clutter_button00"
local clutterTexture = "objects/resortclutter/icon_%s"

function clutterSwitch.sprite(room, entity)
    local x, y = entity.x or 0, entity.y or 0
    local variant = entity["type"] or "red"

    local buttonSprite = drawableSprite.fromTexture(buttonTexture, entity)
    local clutterSprite = drawableSprite.fromTexture(string.format(clutterTexture, string.lower(variant)), entity)

    buttonSprite:setJustification(0.5, 1.0)
    buttonSprite:addPosition(16, 16)

    clutterSprite:setJustification(0.5, 0.5)
    clutterSprite:addPosition(16, 8)

    return {
        buttonSprite,
        clutterSprite
    }
end

return clutterSwitch