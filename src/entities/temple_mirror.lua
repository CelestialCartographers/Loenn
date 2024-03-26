local drawableNinePatch = require("structs.drawable_nine_patch")
local drawableRectangle = require("structs.drawable_rectangle")

local templeMirror = {}

templeMirror.name = "templeMirror"
templeMirror.depth = 8995
templeMirror.warnBelowSize = {24, 24}
templeMirror.placements = {
    name = "mirror",
    data = {
        width = 24,
        height = 24,
        reflectX = 0.0,
        reflectY = 0.0
    }
}

local ninePatchOptions = {
    mode = "border",
    borderMode = "repeat"
}

local templeMirrorColor = {5 / 255, 7 / 255, 14 / 255}
local frameTexture = "scenery/templemirror"

function templeMirror.sprite(room, entity)
    local x, y = entity.x or 0, entity.y or 0
    local width, height = entity.width or 24, entity.height or 24

    local ninePatch = drawableNinePatch.fromTexture(frameTexture, ninePatchOptions, x, y, width, height)
    local rectangle = drawableRectangle.fromRectangle("fill", x + 2, y + 2, width - 4, height - 4, templeMirrorColor)

    local sprites = ninePatch:getDrawableSprite()

    table.insert(sprites, 1, rectangle:getDrawableSprite())

    return sprites
end

return templeMirror