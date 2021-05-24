local drawableSprite = require("structs.drawable_sprite")

local refill = {}

refill.name = "templeGate"
refill.depth = -9000
refill.placements = {}

local placementPresets = {
    {"theo", "HoldingTheo"},
    {"default", "CloseBehindPlayer"},
    {"mirror", "CloseBehindPlayer"},
    {"default", "NearestSwitch"},
    {"mirror", "NearestSwitch"},
    {"default", "TouchSwitches"}
}

for _, preset in ipairs(placementPresets) do
    table.insert(refill.placements, {
        name = string.format("%s_%s", preset[1], string.lower(preset[2])),
        data = {
            height = 48,
            sprite = preset[1],
            ["type"] = preset[2]
        }
    })
end

local textures = {
    default = "objects/door/TempleDoor00",
    mirror = "objects/door/TempleDoorB00",
    theo = "objects/door/TempleDoorC00"
}

function refill.sprite(room, entity)
    local variant = entity.sprite or "default"
    local texture = textures[variant] or textures["default"]
    local sprite = drawableSprite.fromTexture(texture, entity)

    sprite:setJustification(0.5, 0.0)
    sprite:addPosition(0, -8)

    return sprite
end

return refill