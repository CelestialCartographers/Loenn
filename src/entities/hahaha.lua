local drawableSprite = require("structs.drawable_sprite")

local hahaha = {}

hahaha.name = "hahaha"
hahaha.depth = -10001
hahaha.nodeLineRenderType = "line"
hahaha.nodeLimits = {1, 1}
hahaha.placements = {
    name = "hahaha",
    data = {
        ifset = "",
        triggerLaughSfx = false
    }
}

local texture = "characters/oldlady/ha00"
local spriteOffsets = {
    {-11, -1},
    {0, 0},
    {11, -1}
}

function hahaha.sprite(room, entity)
    local sprites = {}

    for _, offset in ipairs(spriteOffsets) do
        local sprite = drawableSprite.fromTexture(texture, entity)

        sprite:addPosition(offset[1], offset[2])
        table.insert(sprites, sprite)
    end

    return sprites
end

return hahaha