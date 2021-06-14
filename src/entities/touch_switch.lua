local drawableSprite = require("structs.drawable_sprite")
local utils = require("utils")

local touchSwitch = {}

touchSwitch.name = "touchSwitch"
touchSwitch.depth = 2000
touchSwitch.placements = {
    {
        name = "touch_switch",
    }
}

local containerTexture = "objects/touchswitch/container"
local iconTexture = "objects/touchswitch/icon00"

function touchSwitch.sprite(room, entity)
    local containerSprite = drawableSprite.fromTexture(containerTexture, entity)
    local iconSprite = drawableSprite.fromTexture(iconTexture, entity)

    return {containerSprite, iconSprite}
end

return touchSwitch
