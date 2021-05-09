local utils = require("utils")
local drawableSprite = require("structs.drawable_sprite")

local breakerBox = {}

breakerBox.name = "lightningBlock"
breakerBox.depth = -10550
breakerBox.texture = "objects/breakerBox/Idle00"
breakerBox.justifications = {0.25, 0.25}
breakerBox.placements = {
    name = "breaker_box",
    data = {
        flipX = false,
        music_progress = -1,
        music_session = false,
        music = "",
        flag = false
    }
}

function breakerBox.scale(room, entity)
    local scaleX = entity.flipX and -1 or 1

    return scaleX, 1
end

return breakerBox