local drawableNinePatch = require("structs.drawable_nine_patch")

local templeCrackedBlock = {}

templeCrackedBlock.name = "templeCrackedBlock"
templeCrackedBlock.depth = 0
templeCrackedBlock.warnBelowSize = {24, 24}
templeCrackedBlock.placements = {
    name = "temple_block",
    data = {
        width = 24,
        height = 24,
        persistent = false
    }
}

local ninePatchOptions = {
    mode = "fill",
    borderMode = "repeat",
    fillMode = "repeat"
}

local blockTexture = "objects/temple/breakBlock00"

function templeCrackedBlock.sprite(room, entity)
    local x, y = entity.x or 0, entity.y or 0
    local width, height = entity.width or 24, entity.height or 24

    local ninePatch = drawableNinePatch.fromTexture(blockTexture, ninePatchOptions, x, y, width, height)

    return ninePatch
end

return templeCrackedBlock